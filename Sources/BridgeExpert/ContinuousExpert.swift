import Foundation
import BridgeDomain

public struct ContinuousAdvice: Codable, Equatable, Sendable {
    public let selectedAction: String
    public let publicReason: String
    public let plan: PlanChange
}

public struct ContinuousReviewRound: Codable, Sendable {
    public let number: Int
    public let candidateID: UUID
    public let candidate: ContinuousAdvice
    public let playerIdentity: RuntimeIdentity
    public let review: ReviewRecord
}

public struct ContinuousDecisionRecord: Codable, Sendable {
    public let id: UUID
    public let wireContractVersion: String
    public let snapshot: ContinuousSnapshot
    public let advice: ContinuousAdvice
    public let effectivePlan: String?
    public let identity: RuntimeIdentity
    public let rounds: [ContinuousReviewRound]
    public let executionDisposition: ExecutionDisposition
    public let elapsedSeconds: Double
    public let requestEvidence: [RequestEvidence]
}

/// Current guidance is included in each turn, because base instructions load only at thread creation.
public enum PlayerInstructions {
    public static func load(_ name: String) -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty else {
            preconditionFailure("Missing required BridgeExpert instruction: \(name)")
        }
        return text
    }
    public static var common: String { load("PlayerCommon") }
    public static func phase(_ phase: BoardPhase) -> String {
        switch phase {
        case .bidding: return load("Bidding")
        case .declarer: return load("Declarer") + """

V6 PROTOCOL ADAPTER (current format)
The preceding strategic guidance is unchanged. Use this mapping for its v5
input/output references: selectedAction replaces selectedCard, with the legal
enum from the response schema. latestSnapshot is the current authorized position;
phaseInitial replaces type=initial and requires a replacement play plan.
effectivePlan is at the top of the envelope. latestSnapshot.actingSeat replaces
current.toAct; currentWinningPlay replaces current.winningPlay; declarerTricks
and defenderTricks replace current.tricksWon. hands is an array of seat/cards
objects containing remaining cards, rather than a seat/suit dictionary. Seats
and strains use full names. agreements and actual auction replace publicBackground.
currentTrick and completedTricks retain their meaning. Review feedback is in
reviewFeedback; candidate remains unplayed. Return plan, selectedAction and
publicReason only. This adapter defines the current wire names for all examples.
"""
        case .openingLead, .defense: return load("Defense")
        case .finished: preconditionFailure("Finished board has no decision instructions")
        }
    }
    public static func review(_ phase: BoardPhase) -> String {
        let name: String
        switch phase {
        case .bidding: name = "ReviewBidding"
        case .declarer: name = "ReviewDeclarer"
        case .openingLead, .defense: name = "ReviewDefense"
        case .finished: preconditionFailure("Finished board has no review")
        }
        let adapter = phase == .declarer ? """

V6 REVIEW PROTOCOL ADAPTER
The preceding declarer strategy checks retain their meaning. candidate has
selectedAction instead of selectedCard. latestSnapshot.legalCards replaces
legalCurrentCards; effectivePlan is top-level, while proposedEffectivePlan is
the pending result. phaseInitial replaces an initial type. latestSnapshot.hands
contains seat/cards arrays of remaining cards, seats/strains use full names,
actingSeat replaces current.toAct, currentWinningPlay replaces winningPlay,
and declarerTricks/defenderTricks give the actual score of completed tricks.
Actual auction and supplied agreements are present in latestSnapshot. Use the
current snapshot and candidate only; the original declarer examples use old names.
""" : ""
        return load("ReviewCommon") + "\n" + load(name) + adapter
    }
}

/// Internal v6 coordinator behind the existing ExpertSession production entry.
actor ContinuousExpertSession {
    let transport: any PlayingTransport
    let reviewer: any PlayingTransport
    let journal = RequestJournal()
    var previousIdentity: RuntimeIdentity?
    var usedTurns: Set<String> = []
    var usedReviewerThreads: Set<String> = []
    var last: ContinuousSnapshot?
    var activePlan: String?
    var authorized: ContinuousDecisionRecord?
    var busy = false
    var ended = false
    init(transport: any PlayingTransport, reviewer: any PlayingTransport) { self.transport = transport; self.reviewer = reviewer }

    func commit(_ record: ContinuousDecisionRecord) throws {
        guard let authorized, authorized.id == record.id, authorized.snapshot == record.snapshot,
              authorized.advice == record.advice else { throw ExpertSessionError.invalidExecutionEvidence }
        activePlan = authorized.effectivePlan; last = authorized.snapshot; self.authorized = nil
    }
    func restore(snapshot: ContinuousSnapshot?, plan: String?) throws {
        guard last == nil, authorized == nil, !busy else { throw ExpertSessionError.invalidExecutionEvidence }
        last = snapshot; activePlan = plan
    }
    func evidence() async -> [RequestEvidence] { await journal.read() }
    func plan() -> String? { activePlan }

    func decide(_ snapshot: ContinuousSnapshot, deadline: Date) async throws -> ContinuousDecisionRecord {
        guard !ended else { throw ExpertSessionError.endedSession }
        guard !busy, authorized == nil else { throw ExpertSessionError.overlappingDecision }
        if let last {
            guard snapshot.boardID == last.boardID, snapshot.userSeat == last.userSeat,
                  snapshot.revision > last.revision, snapshot.auction.starts(with: last.auction),
                  snapshot.events.starts(with: last.events), snapshot.scoring == last.scoring,
                  snapshot.objective == last.objective, snapshot.agreements == last.agreements,
                  snapshot.vulnerability == last.vulnerability else { throw ExpertSessionError.changedHistory }
        }
        guard snapshot.actingSeat != nil, snapshot.phase != .finished,
              !snapshot.legalCalls.isEmpty || !snapshot.legalCards.isEmpty else { throw DomainError.invalidController }
        busy = true; defer { busy = false }
        let id = UUID(); let start = Date()
        let phaseInitial = last == nil || group(last!.phase) != group(snapshot.phase)
        let plan = phaseInitial ? nil : activePlan
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let facts = try JSONSerialization.jsonObject(with: encoder.encode(snapshot))
        var envelope: [String: Any] = ["wireContractVersion": "continuous-board-v6", "phase": snapshot.phase.rawValue,
            "phaseInitial": phaseInitial, "currentPhaseGuidance": PlayerInstructions.phase(snapshot.phase),
            "latestSnapshot": facts, "effectivePlan": plan as Any? ?? NSNull()]
        var rounds: [ContinuousReviewRound] = []
        let choices = snapshot.phase == .bidding ? snapshot.legalCalls.map(\.description) : snapshot.legalCards.map(\.description)
        let schema = try outputSchema(choices: choices, initial: phaseInitial)
        func text(_ object: Any) throws -> String { String(decoding: try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted,.sortedKeys]), as: UTF8.self) }
        func seconds() throws -> Double {
            guard deadline.timeIntervalSinceNow > 0 else { throw ExpertSessionError.automaticBudgetExpired }
            return min(180, deadline.timeIntervalSinceNow)
        }
        do {
            for round in 1...5 {
                let request = PlayingRequest(instructions: PlayerInstructions.common, input: try text(envelope), outputSchema: schema, timeoutSeconds: try seconds())
                let reply = try await recorded(transport, request, role: .player, decision: id, candidate: nil, round: round, attempt: 1)
                do {
                    try ExpertSession.validateIdentity(reply.identity)
                    guard reply.requestID == request.id,
                          previousIdentity == nil || previousIdentity?.threadID == reply.identity.threadID,
                          !usedTurns.contains(reply.identity.turnID) else { throw ExpertSessionError.changedThreadOrRepeatedTurn }
                } catch {
                    await journal.mark(request.id, .identityFailure, detail: String(describing: error))
                    throw PlayingBoundaryFailure.identity(String(describing: error))
                }
                previousIdentity = reply.identity; usedTurns.insert(reply.identity.turnID)
                let advice: ContinuousAdvice
                do { advice = try parse(reply.rawOutput, choices: choices, initial: phaseInitial) }
                catch { await journal.mark(request.id, .protocolFailure, detail: String(describing: error)); throw ContinuousAdviceError.invalid }
                await journal.mark(request.id, .valid)
                let effective: String?
                switch advice.plan.update { case .keep: effective = plan; case .replace: effective = advice.plan.text; case .withdraw: effective = nil }
                let candidateID = UUID()
                var reviewEnvelope = envelope
                reviewEnvelope["candidate"] = try JSONSerialization.jsonObject(with: encoder.encode(advice))
                reviewEnvelope["proposedEffectivePlan"] = effective as Any? ?? NSNull()
                // A review is independent of prior review verdicts, though revision input retains them for the player.
                reviewEnvelope.removeValue(forKey: "reviewFeedback")
                let reviewInput = try text(reviewEnvelope)
                var reviewRecord: ReviewRecord?
                for attempt in 1...4 {
                    let reviewRequest = PlayingRequest(instructions: PlayerInstructions.review(snapshot.phase), input: reviewInput, outputSchema: ExpertSession.reviewOutputSchema, timeoutSeconds: try seconds())
                    let reviewStart = Date()
                    do {
                        let response = try await recorded(reviewer, reviewRequest, role: .reviewer, decision: id, candidate: candidateID, round: round, attempt: attempt)
                        do {
                            try ExpertSession.validateIdentity(response.identity)
                            guard response.requestID == reviewRequest.id, response.identity.threadID != reply.identity.threadID,
                                  !usedReviewerThreads.contains(response.identity.threadID) else { throw ExpertSessionError.changedThreadOrRepeatedTurn }
                        } catch {
                            await journal.mark(reviewRequest.id, .identityFailure, detail: String(describing: error))
                            throw PlayingBoundaryFailure.identity(String(describing: error))
                        }
                        usedReviewerThreads.insert(response.identity.threadID)
                        let verdict: PlayReview
                        do { verdict = try ExpertSession.parseReview(response.rawOutput) }
                        catch {
                            await journal.mark(reviewRequest.id, .protocolFailure, detail: String(describing: error))
                            throw ContinuousAdviceError.invalid
                        }
                        await journal.mark(reviewRequest.id, .valid)
                        reviewRecord = ReviewRecord(requestID: reviewRequest.id, pendingDecisionID: id, candidateID: candidateID,
                            instructions: reviewRequest.instructions, input: reviewInput, rawOutput: response.rawOutput, identity: response.identity, result: verdict, elapsedSeconds: Date().timeIntervalSince(reviewStart))
                        break
                    } catch {
                        if error is PlayingBoundaryFailure || (error as? PlayingTransportFailure)?.fatal == true { throw error }
                        await journal.mark(reviewRequest.id, .protocolFailure, detail: String(describing: error))
                        if attempt == 4 { throw error }
                    }
                }
                guard let reviewRecord else { throw ExpertSessionError.endedSession }
                rounds.append(.init(number: round, candidateID: candidateID, candidate: advice, playerIdentity: reply.identity, review: reviewRecord))
                if reviewRecord.result.verdict == .uncertain {
                    throw ExpertFailure(category: .needsInput, input: reviewInput, rawOutput: reviewRecord.rawOutput,
                        detail: reviewRecord.result.advisorySuggestions.joined(separator: "\n"), elapsedSeconds: Date().timeIntervalSince(start))
                }
                if reviewRecord.result.verdict == .approve || round == 5 {
                    _ = try seconds()
                    let result = ContinuousDecisionRecord(id: id, wireContractVersion: "continuous-board-v6", snapshot: snapshot, advice: advice,
                        effectivePlan: effective, identity: reply.identity, rounds: rounds,
                        executionDisposition: reviewRecord.result.verdict == .approve ? .reviewApproved : .contested, elapsedSeconds: Date().timeIntervalSince(start),
                        requestEvidence: await journal.read().filter { $0.decisionID == id })
                    authorized = result; return result
                }
                envelope["reviewFeedback"] = try JSONSerialization.jsonObject(with: encoder.encode(reviewRecord.result))
                envelope["candidate"] = try JSONSerialization.jsonObject(with: encoder.encode(advice))
            }
            throw ExpertSessionError.endedSession
        } catch {
            ended = true
            let evidence = await journal.read().filter { $0.decisionID == id }
            if var failure = error as? ExpertFailure { failure.requestEvidence = evidence; throw failure }
            let category: ExpertFailure.Category = error is PlayingBoundaryFailure || (error as? PlayingTransportFailure)?.fatal == true ? .identity : error is ContinuousAdviceError ? .invalidOutput : .runtime
            throw ExpertFailure(category: category, input: (try? text(envelope)) ?? "", rawOutput: (error as? PlayingTransportFailure)?.rawOutput ?? evidence.last?.rawOutput ?? "", detail: String(describing: error), elapsedSeconds: Date().timeIntervalSince(start), requestEvidence: evidence)
        }
    }
    private func group(_ phase: BoardPhase) -> String { phase == .openingLead ? "defense" : phase.rawValue }
    private func recorded(_ transport: any PlayingTransport, _ request: PlayingRequest, role: RequestEvidence.Role, decision: UUID, candidate: UUID?, round: Int, attempt: Int) async throws -> PlayingReply {
        let started = Date(); let journal = journal
        return try await boundedReply(transport: transport, request: request) { result, outcome in
            let reply: PlayingReply?
            switch result {
            case .success(let value): reply = value
            case .failure(let error):
                if let failure = error as? PlayingTransportFailure, let identity = failure.identity {
                    reply = PlayingReply(rawOutput: failure.rawOutput ?? "", identity: identity, requestID: request.id, usage: failure.usage)
                } else { reply = nil }
            }
            await journal.append(RequestEvidence(role: role, requestID: request.id, decisionID: decision, candidateID: candidate,
                semanticRound: round, technicalAttempt: attempt, instructions: request.instructions, input: request.input,
                outputSchema: request.outputSchema, timeoutSeconds: request.timeoutSeconds, rawOutput: reply?.rawOutput,
                identity: reply?.identity, replyRequestID: reply?.requestID, usage: reply?.usage,
                elapsedSeconds: Date().timeIntervalSince(started), outcome: outcome, detail: reply == nil ? String(describing: result) : nil))
        }
    }
    private func parse(_ raw: String, choices: [String], initial: Bool) throws -> ContinuousAdvice {
        let data = Data(raw.utf8)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String:Any], Set(object.keys) == ["selectedAction","publicReason","plan"],
              let p = object["plan"] as? [String:Any], Set(p.keys) == ["update","text"] else { throw ContinuousAdviceError.invalid }
        let result = try JSONDecoder().decode(ContinuousAdvice.self, from: data)
        guard choices.contains(result.selectedAction), !result.publicReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !initial || result.plan.update == .replace,
              result.plan.update != .replace || result.plan.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              result.plan.update == .replace || result.plan.text == nil else { throw ContinuousAdviceError.invalid }
        return result
    }
    private func outputSchema(choices: [String], initial: Bool) throws -> String {
        var schema = try JSONSerialization.jsonObject(with: Data(ExpertSession.outputSchema.utf8)) as! [String:Any]
        var properties = schema["properties"] as! [String:Any]
        properties.removeValue(forKey: "selectedCard"); properties["selectedAction"] = ["type":"string","enum":choices]
        if initial {
            var plan = properties["plan"] as! [String:Any]
            plan["anyOf"] = (plan["anyOf"] as! [[String:Any]]).prefix(1).map { $0 }
            properties["plan"] = plan
        }
        schema["properties"] = properties; schema["required"] = ["plan","selectedAction","publicReason"]
        return String(decoding: try JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys]), as: UTF8.self)
    }
}
private enum ContinuousAdviceError: Error { case invalid }
