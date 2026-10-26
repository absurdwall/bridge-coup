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
    public static func phase(_ phase: BoardPhase) -> String {
        switch phase {
        case .bidding: return load("Bidding")
        case .declarer: return load("Declarer") + """

CURRENT CONTINUOUS PROTOCOL ADAPTER (unchanged play action shape)
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

CURRENT CONTINUOUS REVIEW PROTOCOL ADAPTER
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

/// Internal continuous-board coordinator behind the existing ExpertSession production entry.
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
    private struct Workflow {
        let id: UUID
        let snapshot: ContinuousSnapshot
        let context: ExplanationContext
        let start: Date
        let deadline: Date
        let phaseInitial: Bool
        let plan: String?
        var envelope: [String: Any]
        var rounds: [ContinuousReviewRound] = []
        var informationRequests = 0
        var waiting: ExplanationRequest?
    }
    private var workflow: Workflow?
    init(transport: any PlayingTransport, reviewer: any PlayingTransport) { self.transport = transport; self.reviewer = reviewer }

    func commit(_ record: ContinuousDecisionRecord) throws {
        guard let authorized, authorized.id == record.id, authorized.snapshot == record.snapshot,
              authorized.advice == record.advice else { throw ExpertSessionError.invalidExecutionEvidence }
        activePlan = authorized.effectivePlan; last = authorized.snapshot; self.authorized = nil; workflow = nil
    }
    func restore(snapshot: ContinuousSnapshot?, plan: String?) throws {
        guard last == nil, authorized == nil, !busy else { throw ExpertSessionError.invalidExecutionEvidence }
        last = snapshot; activePlan = plan
    }
    func evidence() async -> [RequestEvidence] { await journal.read() }
    func plan() -> String? { activePlan }

    func provideExplanations(requestID: UUID, evidence: [ExplanationResult]) throws {
        guard !busy, var work = workflow, work.waiting?.id == requestID else { throw ExplanationExchangeError.staleRequest }
        guard Date() < work.deadline else { ended = true; throw ExpertSessionError.automaticBudgetExpired }
        work.envelope["explanationEvidence"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(evidence))
        work.waiting = nil; workflow = work
    }

    func inspect(_ snapshot: ContinuousSnapshot, context: ExplanationContext, candidates: [AuctionCall], reason: String,
                 deadline: Date, evidence: [ExplanationResult]) throws -> ExplanationRequest {
        guard !ended, !busy else { throw ExpertSessionError.endedSession }
        var work = try currentWorkflow(snapshot, context: context, deadline: deadline, evidence: evidence)
        guard work.waiting == nil, work.rounds.count < 5 else { throw ExplanationExchangeError.exhaustedInformationBudget }
        let request = try informationRequest(candidates: candidates, reason: reason, work: &work)
        authorized = nil; workflow = work
        return request
    }

    private func currentWorkflow(_ snapshot: ContinuousSnapshot, context: ExplanationContext, deadline: Date,
                                 evidence: [ExplanationResult]) throws -> Workflow {
        if let workflow {
            guard snapshot == workflow.snapshot, context == workflow.context else { throw ExplanationExchangeError.staleRequest }
            return workflow
        }
        if let last {
            guard snapshot.boardID == last.boardID, snapshot.userSeat == last.userSeat,
                  snapshot.revision > last.revision, snapshot.auction.starts(with: last.auction),
                  snapshot.events.starts(with: last.events), snapshot.scoring == last.scoring,
                  snapshot.objective == last.objective, snapshot.agreements == last.agreements,
                  snapshot.vulnerability == last.vulnerability else { throw ExpertSessionError.changedHistory }
        }
        guard snapshot.actingSeat != nil, snapshot.phase != .finished,
              !snapshot.legalCalls.isEmpty || !snapshot.legalCards.isEmpty else { throw DomainError.invalidController }
        let phaseInitial = last == nil || group(last!.phase) != group(snapshot.phase)
        let plan = phaseInitial ? nil : activePlan
        let encoder = JSONEncoder()
        return Workflow(id: UUID(), snapshot: snapshot, context: context, start: Date(), deadline: deadline,
            phaseInitial: phaseInitial, plan: plan, envelope: ["wireContractVersion": "continuous-board-v7", "phase": snapshot.phase.rawValue,
                "phaseInitial": phaseInitial, "currentPhaseGuidance": PlayerInstructions.phase(snapshot.phase),
                "latestSnapshot": try JSONSerialization.jsonObject(with: encoder.encode(snapshot)),
                "effectivePlan": plan as Any? ?? NSNull(),
                "explanationEvidence": try JSONSerialization.jsonObject(with: encoder.encode(evidence))])
    }

    private func informationRequest(candidates: [AuctionCall], reason: String, work: inout Workflow) throws -> ExplanationRequest {
        guard work.snapshot.phase == .bidding, !candidates.isEmpty, candidates.count <= 3,
              Set(candidates).count == candidates.count, candidates.allSatisfy(work.snapshot.legalCalls.contains),
              !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ExplanationExchangeError.invalidRequest }
        guard work.informationRequests < 2, Date() < work.deadline else { throw ExplanationExchangeError.exhaustedInformationBudget }
        let request = ExplanationRequest(snapshotID: work.snapshot.id, context: work.context, candidates: candidates, reason: reason)
        work.informationRequests += 1; work.waiting = request
        return request
    }

    func decide(_ snapshot: ContinuousSnapshot, deadline: Date, context: ExplanationContext, evidence: [ExplanationResult]) async throws -> ContinuousDecisionRecord {
        guard !ended else { throw ExpertSessionError.endedSession }
        guard !busy, authorized == nil else { throw ExpertSessionError.overlappingDecision }
        var work = try currentWorkflow(snapshot, context: context, deadline: deadline, evidence: evidence)
        if let waiting = work.waiting { throw ExplanationRequestNeeded(request: waiting) }
        busy = true; defer { busy = false }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let choices = snapshot.phase == .bidding ? snapshot.legalCalls.map(\.description) : snapshot.legalCards.map(\.description)
        func text(_ object: Any) throws -> String { String(decoding: try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted,.sortedKeys]), as: UTF8.self) }
        func seconds() throws -> Double {
            guard work.deadline.timeIntervalSinceNow > 0 else { throw ExpertSessionError.automaticBudgetExpired }
            return min(180, work.deadline.timeIntervalSinceNow)
        }
        do {
            while work.rounds.count < 5 {
                let round = work.rounds.count + 1
                let mayQuery = snapshot.phase == .bidding && work.informationRequests < 2
                let request = PlayingRequest(instructions: "", input: try text(work.envelope),
                    outputSchema: try outputSchema(choices: choices, initial: work.phaseInitial, mayQuery: mayQuery), timeoutSeconds: try seconds())
                let reply = try await recordedReply(transport: transport, request: request, journal: journal, role: .player, decisionID: work.id, candidateID: nil, round: round, attempt: 1)
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
                let requestedInformation: ExplanationRequest?
                do {
                    if let query = try query(reply.rawOutput, allowed: mayQuery) {
                        requestedInformation = try informationRequest(candidates: query.candidates, reason: query.reason, work: &work)
                    } else { requestedInformation = nil }
                } catch {
                    await journal.mark(request.id, .protocolFailure, detail: String(describing: error))
                    throw ContinuousAdviceError.invalid
                }
                if let info = requestedInformation {
                    await journal.mark(request.id, .valid); workflow = work
                    throw ExplanationRequestNeeded(request: info)
                }
                let advice: ContinuousAdvice
                do { advice = try parse(reply.rawOutput, choices: choices, initial: work.phaseInitial) }
                catch { await journal.mark(request.id, .protocolFailure, detail: String(describing: error)); throw ContinuousAdviceError.invalid }
                await journal.mark(request.id, .valid)
                let effective: String?
                switch advice.plan.update { case .keep: effective = work.plan; case .replace: effective = advice.plan.text; case .withdraw: effective = nil }
                let candidateID = UUID()
                var reviewEnvelope = work.envelope
                reviewEnvelope["candidate"] = try JSONSerialization.jsonObject(with: encoder.encode(advice))
                reviewEnvelope["proposedEffectivePlan"] = effective as Any? ?? NSNull()
                reviewEnvelope.removeValue(forKey: "reviewFeedback")
                let reviewInput = try text(reviewEnvelope)
                var reviewRecord: ReviewRecord?
                for attempt in 1...4 {
                    let reviewRequest = PlayingRequest(instructions: PlayerInstructions.review(snapshot.phase), input: reviewInput, outputSchema: ExpertSession.reviewOutputSchema, timeoutSeconds: try seconds())
                    let reviewStart = Date()
                    do {
                        let response = try await recordedReply(transport: reviewer, request: reviewRequest, journal: journal, role: .reviewer, decisionID: work.id, candidateID: candidateID, round: round, attempt: attempt)
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
                        catch { await journal.mark(reviewRequest.id, .protocolFailure, detail: String(describing: error)); throw ContinuousAdviceError.invalid }
                        await journal.mark(reviewRequest.id, .valid)
                        reviewRecord = ReviewRecord(requestID: reviewRequest.id, pendingDecisionID: work.id, candidateID: candidateID,
                            instructions: reviewRequest.instructions, input: reviewInput, rawOutput: response.rawOutput, identity: response.identity, result: verdict, elapsedSeconds: Date().timeIntervalSince(reviewStart))
                        break
                    } catch {
                        if error is PlayingBoundaryFailure || (error as? PlayingTransportFailure)?.fatal == true { throw error }
                        await journal.mark(reviewRequest.id, .protocolFailure, detail: String(describing: error))
                        if attempt == 4 { throw error }
                    }
                }
                guard let reviewRecord else { throw ExpertSessionError.endedSession }
                work.rounds.append(.init(number: round, candidateID: candidateID, candidate: advice, playerIdentity: reply.identity, review: reviewRecord))
                if reviewRecord.result.verdict == .uncertain {
                    throw ExpertFailure(category: .needsInput, input: reviewInput, rawOutput: reviewRecord.rawOutput,
                        detail: reviewRecord.result.advisorySuggestions.joined(separator: "\n"), elapsedSeconds: Date().timeIntervalSince(work.start))
                }
                if reviewRecord.result.verdict == .approve || round == 5 {
                    _ = try seconds()
                    let result = ContinuousDecisionRecord(id: work.id, wireContractVersion: "continuous-board-v7", snapshot: snapshot, advice: advice,
                        effectivePlan: effective, identity: reply.identity, rounds: work.rounds,
                        executionDisposition: reviewRecord.result.verdict == .approve ? .reviewApproved : .contested, elapsedSeconds: Date().timeIntervalSince(work.start),
                        requestEvidence: await journal.read().filter { $0.decisionID == work.id })
                    authorized = result; workflow = work; return result
                }
                work.envelope["reviewFeedback"] = try JSONSerialization.jsonObject(with: encoder.encode(reviewRecord.result))
                work.envelope["candidate"] = try JSONSerialization.jsonObject(with: encoder.encode(advice))
            }
            throw ExpertSessionError.endedSession
        } catch let needed as ExplanationRequestNeeded { throw needed }
        catch {
            ended = true
            let evidence = await journal.read().filter { $0.decisionID == work.id }
            if var failure = error as? ExpertFailure { failure.requestEvidence = evidence; throw failure }
            let category: ExpertFailure.Category = error is PlayingBoundaryFailure || (error as? PlayingTransportFailure)?.fatal == true ? .identity : error is ContinuousAdviceError ? .invalidOutput : .runtime
            throw ExpertFailure(category: category, input: (try? text(work.envelope)) ?? "", rawOutput: (error as? PlayingTransportFailure)?.rawOutput ?? evidence.last?.rawOutput ?? "", detail: String(describing: error), elapsedSeconds: Date().timeIntervalSince(work.start), requestEvidence: evidence)
        }
    }
    private func group(_ phase: BoardPhase) -> String { phase == .openingLead ? "defense" : phase.rawValue }
    private func parse(_ raw: String, choices: [String], initial: Bool) throws -> ContinuousAdvice {
        let data = Data(raw.utf8)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String:Any], (Set(object.keys) == ["selectedAction","publicReason","plan"] || Set(object.keys) == ["selectedAction","publicReason","plan","requestExplanations"]),
              let p = object["plan"] as? [String:Any], Set(p.keys) == ["update","text"] else { throw ContinuousAdviceError.invalid }
        if let queries = object["requestExplanations"] as? [String], !queries.isEmpty { throw ContinuousAdviceError.invalid }
        let result = try JSONDecoder().decode(ContinuousAdvice.self, from: data)
        guard choices.contains(result.selectedAction), !result.publicReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !initial || result.plan.update == .replace,
              result.plan.update != .replace || result.plan.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              result.plan.update == .replace || result.plan.text == nil else { throw ContinuousAdviceError.invalid }
        return result
    }
    private func query(_ raw: String, allowed: Bool) throws -> (candidates: [AuctionCall], reason: String)? {
        guard let object = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any] else { throw ContinuousAdviceError.invalid }
        guard object["selectedAction"] as? String == "REQUEST_EXPLANATIONS" else { return nil }
        guard allowed, Set(object.keys) == ["selectedAction", "publicReason", "plan", "requestExplanations"],
              let calls = object["requestExplanations"] as? [String], let reason = object["publicReason"] as? String,
              let plan = object["plan"] as? [String: Any], Set(plan.keys) == ["update", "text"],
              plan["update"] as? String == "keep", plan["text"] is NSNull else { throw ContinuousAdviceError.invalid }
        return (try calls.map(AuctionCall.init), reason)
    }
    private func outputSchema(choices: [String], initial: Bool, mayQuery: Bool) throws -> String {
        var schema = try JSONSerialization.jsonObject(with: Data(ExpertSession.outputSchema.utf8)) as! [String:Any]
        var properties = schema["properties"] as! [String:Any]
        properties.removeValue(forKey: "selectedCard"); properties["selectedAction"] = ["type":"string","enum":choices + (mayQuery ? ["REQUEST_EXPLANATIONS"] : [])]
        if initial && !mayQuery {
            var plan = properties["plan"] as! [String:Any]
            plan["anyOf"] = (plan["anyOf"] as! [[String:Any]]).prefix(1).map { $0 }
            properties["plan"] = plan
        }
        if mayQuery { properties["requestExplanations"] = ["type":"array", "items":["type":"string", "enum":choices], "maxItems":3] }
        schema["properties"] = properties; schema["required"] = ["plan","selectedAction","publicReason"] + (mayQuery ? ["requestExplanations"] : [])
        return String(decoding: try JSONSerialization.data(withJSONObject: schema, options: [.sortedKeys]), as: UTF8.self)
    }
}
private enum ContinuousAdviceError: Error { case invalid }
