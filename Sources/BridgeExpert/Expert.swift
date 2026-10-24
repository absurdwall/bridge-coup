import Foundation
import BridgeDomain

public struct RuntimeIdentity: Codable, Equatable, Sendable {
    public let requestedModel: String
    public let requestedEffort: String
    public let runtimeVersion: String
    /// Observable runtime acknowledgement, not proof of the remote service's internal identity.
    public let observedModel: String?
    public let observedEffort: String?
    public let threadID: String
    public let turnID: String
    public init(requestedModel: String, requestedEffort: String, runtimeVersion: String, observedModel: String?, observedEffort: String? = nil, threadID: String, turnID: String) {
        self.requestedModel = requestedModel; self.requestedEffort = requestedEffort; self.runtimeVersion = runtimeVersion
        self.observedModel = observedModel; self.observedEffort = observedEffort; self.threadID = threadID; self.turnID = turnID
    }
}

public struct PlayingRequest: Sendable {
    public let id = UUID()
    public let instructions: String
    public let input: String
    public let outputSchema: String
    public let timeoutSeconds: Double
}

public struct PlayingReply: Sendable {
    public let rawOutput: String
    public let identity: RuntimeIdentity
    public let requestID: UUID?
    public let usage: TokenUsage?
    public init(rawOutput: String, identity: RuntimeIdentity, requestID: UUID? = nil, usage: TokenUsage? = nil) { self.rawOutput = rawOutput; self.identity = identity; self.requestID = requestID; self.usage = usage }
}

/// External model boundary. Production uses Codex app-server; tests may supply recorded replies.
public protocol PlayingTransport: Sendable {
    func respond(to request: PlayingRequest) async throws -> PlayingReply
}

public struct PlanChange: Codable, Equatable, Sendable {
    public enum Update: String, Codable, Sendable { case keep, replace, withdraw }
    public let update: Update
    public let text: String?
    private enum CodingKeys: String, CodingKey { case update, text }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(update, forKey: .update)
        // Keep/withdraw are exact JSON proposals too: preserve the required null.
        if let text { try container.encode(text, forKey: .text) }
        else { try container.encodeNil(forKey: .text) }
    }
}

public struct PublicAdvice: Codable, Equatable, Sendable {
    public let currentCard: Card
    private enum CodingKeys: String, CodingKey { case currentCard = "selectedCard", publicReason, plan }
    public let publicReason: String
    public let plan: PlanChange
}

public struct DecisionSession: Codable, Equatable, Sendable {
    public let id: UUID
    public let snapshotID: String
}

public struct PlanAssociation: Codable, Equatable, Sendable {
    public let boardID: UUID
    public let controller: Seat
    public let sourceSnapshotID: String
    public let sourceSessionID: UUID
    public let text: String
}

public struct ActualExecution: Codable, Equatable, Sendable {
    public enum Source: String, Codable, Sendable { case model, forced, opponent, external }
    public let event: PlayEvent
    public let source: Source
    public init(event: PlayEvent, source: Source) { self.event = event; self.source = source }
}

public enum ExpertSessionError: Error, Equatable { case automaticBudgetExpired, overlappingDecision, staleSnapshot, differentBoardOrController, changedHistory, endedSession, changedThreadOrRepeatedTurn, invalidExecutionEvidence }

public struct DecisionRecord: Codable, Sendable {
    public let session: DecisionSession
    public let planAssociation: PlanAssociation?
    public let wireContractVersion: String
    public let snapshot: DecisionSnapshot
    public let instructions: String
    public let input: String
    public let rawOutput: String
    public let identity: RuntimeIdentity
    public let advice: PublicAdvice
    public let action: CurrentAction
    public let effectivePlan: String?
    public let elapsedSeconds: Double
    /// Nil only for historical direct-play records predating review integration.
    public let pending: PendingDeclarerDecision?
    public let review: ReviewRecord?
    public let canonicalInput: String?
    public let reviewRounds: [ReviewRound]?
    public let executionDisposition: ExecutionDisposition?
    public let requestEvidence: [RequestEvidence]?
    public let humanWaitingSeconds: Double?
}

public struct ExpertFailure: Error, Sendable {
    public enum Category: String, Codable, Sendable { case runtime, invalidOutput, identity, reviewRejected, needsInput }
    public let category: Category
    public let input: String
    public let rawOutput: String
    public let detail: String
    public let elapsedSeconds: Double
    public var reviewRounds: [ReviewRound] = []
    public var requestEvidence: [RequestEvidence] = []
}

/// The App-independent Expert entry: one board/controller owns one continuing transport.
public actor ExpertSession {
    private let journal = RequestJournal()
    private let transport: any PlayingTransport
    private let reviewer: any PlayingTransport
    private var pending: PendingDeclarerDecision?
    private var authorized: DecisionRecord?
    private var authorizedDeadline: Date?
    private var planAssociation: PlanAssociation?
    private var previousIdentity: RuntimeIdentity?
    private var usedTurnIDs: Set<String> = []
    private var inFlight = false
    private var ended = false
    private var boundBoard: UUID?
    private var boundController: Seat?
    private var previousSnapshot: DecisionSnapshot?
    private var waiting: NeedsInputState?
    private var humanWaitingSeconds: Double = 0

    public init(transport: any PlayingTransport, reviewer: any PlayingTransport) {
        self.transport = transport; self.reviewer = reviewer
    }

    public func needsInputState() -> NeedsInputState? { waiting }
    public func waitingSeconds() -> Double { humanWaitingSeconds + (waiting.map { Date().timeIntervalSince($0.waitingSince) } ?? 0) }

    public func requestEvidence() async -> [RequestEvidence] { await journal.read() }

    public func activePlan() -> PlanAssociation? { planAssociation }
    public func pendingDecision() -> PendingDeclarerDecision? { pending }

    /// Called by the canonical driver only after the matching actual play succeeds.
    public func commit(_ decision: DecisionRecord, execution: ActualExecution) throws {
        if let authorizedDeadline, Date() >= authorizedDeadline { ended = true; throw ExpertSessionError.automaticBudgetExpired }
        guard let authorized, let pending,
              decision.session == authorized.session, decision.pending == pending,
              decision.advice == authorized.advice, decision.action == authorized.action,
              decision.snapshot == authorized.snapshot,
              execution.source == .model,
              execution.event.sequence == decision.snapshot.events.count,
              execution.event.seat == decision.action.actingSeat,
              execution.event.card == decision.action.card else { throw ExpertSessionError.invalidExecutionEvidence }
        planAssociation = authorized.planAssociation
        previousSnapshot = authorized.snapshot
        self.pending = nil; self.authorized = nil; authorizedDeadline = nil
    }

    public func abandonPending() {
        if let waiting { humanWaitingSeconds += Date().timeIntervalSince(waiting.waitingSince); self.waiting = nil }
        pending = nil; authorized = nil; authorizedDeadline = nil; ended = true
    }


    public func decide(_ snapshot: DecisionSnapshot, executions: [ActualExecution] = [], timeoutSeconds: Double = 180, automaticDeadline: Date? = nil) async throws -> DecisionRecord {
        guard !inFlight else { throw ExpertSessionError.overlappingDecision }
        guard !ended else { throw ExpertSessionError.endedSession }
        guard pending == nil else { throw ExpertSessionError.overlappingDecision }
        let suspended = waiting
        if let suspended {
            guard Self.completes(suspended.snapshot, with: snapshot) else {
                humanWaitingSeconds += Date().timeIntervalSince(suspended.waitingSince)
                waiting = nil; ended = true
                throw ExpertSessionError.changedHistory
            }
            humanWaitingSeconds += Date().timeIntervalSince(suspended.waitingSince)
            waiting = nil
        }
        if let boundBoard {
            guard snapshot.boardID == boundBoard, snapshot.controller == boundController else { throw ExpertSessionError.differentBoardOrController }
        }
        if let previousSnapshot {
            guard snapshot.revision > previousSnapshot.revision else { throw ExpertSessionError.staleSnapshot }
            guard snapshot.events.starts(with: previousSnapshot.events),
                  snapshot.contract == previousSnapshot.contract,
                  snapshot.scoring == previousSnapshot.scoring,
                  snapshot.vulnerability == previousSnapshot.vulnerability,
                  snapshot.objective == previousSnapshot.objective,
                  snapshot.publicBackground == previousSnapshot.publicBackground else { throw ExpertSessionError.changedHistory }
        }
        let delta = Array(snapshot.events.dropFirst(previousSnapshot?.events.count ?? 0))
        guard executions.isEmpty || executions.map(\.event) == delta else { throw ExpertSessionError.invalidExecutionEvidence }
        guard snapshot.controller == snapshot.contract.declarer,
              snapshot.actingSeat == snapshot.controller || snapshot.actingSeat == snapshot.controller.partner else {
            throw DomainError.invalidController
        }
        boundBoard = snapshot.boardID; boundController = snapshot.controller
        inFlight = true
        defer { inFlight = false }
        let session = suspended?.session ?? DecisionSession(id: UUID(), snapshotID: snapshot.id)
        let start = Date()
        let deadline = automaticDeadline ?? start.addingTimeInterval(1800)
        func remainingRequestSeconds() throws -> Double {
            let remaining = deadline.timeIntervalSinceNow
            guard remaining > 0, timeoutSeconds.isFinite, timeoutSeconds > 0 else {
                throw ExpertFailure(category: .runtime, input: "", rawOutput: "", detail: "Automatic runtime budget expired or invalid request limit", elapsedSeconds: Date().timeIntervalSince(start))
            }
            return min(180, timeoutSeconds, remaining)
        }
        if let conflict = Self.invalidPositionFacts(snapshot) {
            ended = true
            throw ExpertFailure(category: .invalidOutput, input: String(decoding: try JSONEncoder().encode(snapshot), as: UTF8.self), rawOutput: "", detail: conflict, elapsedSeconds: Date().timeIntervalSince(start))
        }
        if let gap = Self.missingPositionFacts(snapshot) {
            waiting = NeedsInputState(session: session, snapshot: snapshot, priorPlan: planAssociation, detail: gap, waitingSince: Date(), semanticRounds: 0)
            throw ExpertFailure(category: .needsInput, input: String(decoding: try JSONEncoder().encode(snapshot), as: UTF8.self), rawOutput: "", detail: gap, elapsedSeconds: Date().timeIntervalSince(start))
        }
        let input = try snapshotInput(snapshot, initial: previousSnapshot == nil)
        var playerInput = input
        var rounds: [ReviewRound] = []
        do {
            for round in 1...5 {
                let playerStarted = Date()
                let playerRequest = PlayingRequest(instructions: Self.instructions, input: playerInput, outputSchema: try Self.outputSchema(for: snapshot, initialPlan: previousSnapshot == nil), timeoutSeconds: try remainingRequestSeconds())
                let reply: PlayingReply
                do { reply = try await recordedReply(transport: transport, request: playerRequest, role: .player, decisionID: session.id, candidateID: nil, round: round, attempt: 1) }
                catch { ended = true; throw ExpertFailure(category: error is PlayingBoundaryFailure || (error as? PlayingTransportFailure)?.fatal == true ? .identity : .runtime, input: playerInput, rawOutput: (error as? PlayingTransportFailure)?.rawOutput ?? "", detail: String(describing: error), elapsedSeconds: Date().timeIntervalSince(start)) }
                let playerElapsed = Date().timeIntervalSince(playerStarted)
                do {
                    try Self.validateIdentity(reply.identity)
                    if let previousIdentity, (reply.identity.threadID != previousIdentity.threadID || usedTurnIDs.contains(reply.identity.turnID)) {
                        throw ExpertSessionError.changedThreadOrRepeatedTurn
                    }
                    guard !ended, reply.requestID == playerRequest.id else { throw ExpertSessionError.staleSnapshot }
                } catch { await journal.mark(playerRequest.id, .identityFailure, detail: String(describing: error)); ended = true; throw ExpertFailure(category: .identity, input: playerInput, rawOutput: reply.rawOutput, detail: String(describing: error), elapsedSeconds: Date().timeIntervalSince(start)) }
                // Each revision is a new turn in the same player conversation, even before execution.
                previousIdentity = reply.identity
                usedTurnIDs.insert(reply.identity.turnID)
                let advice: PublicAdvice
                do {
                    let data = Data(reply.rawOutput.utf8)
                    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          Set(object.keys) == ["selectedCard", "publicReason", "plan"],
                          let plan = object["plan"] as? [String: Any], Set(plan.keys) == ["update", "text"] else { throw ValidationError.unexpectedFields }
                    advice = try JSONDecoder().decode(PublicAdvice.self, from: data)
                    guard snapshot.legalCards.contains(advice.currentCard) else { throw ValidationError.illegalCard }
                    guard !advice.publicReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        throw ValidationError.emptyReason
                    }
                    if previousSnapshot == nil && (advice.plan.update != .replace || advice.plan.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false) {
                        throw ValidationError.missingInitialPlan
                    }
                    if advice.plan.update == .replace && advice.plan.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                        throw ValidationError.missingReplacement
                    }
                    if advice.plan.update != .replace && advice.plan.text != nil { throw ValidationError.ambiguousPlan }
                } catch {
                    await journal.mark(playerRequest.id, .protocolFailure, detail: String(describing: error))
                    ended = true
                    throw ExpertFailure(category: .invalidOutput, input: playerInput, rawOutput: reply.rawOutput, detail: String(describing: error), elapsedSeconds: Date().timeIntervalSince(start))
                }
                await journal.mark(playerRequest.id, .valid)
                let proposedAssociation: PlanAssociation?
                switch advice.plan.update {
                case .keep: proposedAssociation = planAssociation
                case .replace: proposedAssociation = PlanAssociation(boardID: snapshot.boardID, controller: snapshot.controller, sourceSnapshotID: snapshot.id, sourceSessionID: session.id, text: advice.plan.text!)
                case .withdraw: proposedAssociation = nil
                }
                let candidate = PendingDeclarerDecision(id: session.id, candidateID: UUID(), snapshot: snapshot,
                    priorPlan: planAssociation, candidate: advice, proposedEffectivePlan: proposedAssociation?.text)
                pending = candidate

                let reviewInput = try Self.reviewInput(snapshotInput: input, pending: candidate)
                var reviewReply: PlayingReply?
                var verdict: PlayReview?
                var finalRequest: PlayingRequest?
                let reviewStarted = Date()
                for attempt in 1...4 {
                    let request = PlayingRequest(instructions: Self.reviewerInstructions, input: reviewInput, outputSchema: Self.reviewOutputSchema, timeoutSeconds: try remainingRequestSeconds())
                    finalRequest = request
                    do {
                        let received = try await recordedReply(transport: reviewer, request: request, role: .reviewer, decisionID: session.id, candidateID: candidate.candidateID, round: round, attempt: attempt)
                        do {
                            try Self.validateIdentity(received.identity)
                            guard !ended, received.requestID == request.id,
                                  received.identity.threadID != reply.identity.threadID,
                                  pending == candidate else { throw ExpertSessionError.staleSnapshot }
                        } catch {
                            await journal.mark(request.id, .identityFailure, detail: String(describing: error))
                            ended = true
                            throw ExpertFailure(category: .identity, input: reviewInput, rawOutput: received.rawOutput, detail: String(describing: error), elapsedSeconds: Date().timeIntervalSince(start))
                        }
                        do { verdict = try Self.parseReview(received.rawOutput) }
                        catch {
                            await journal.mark(request.id, .protocolFailure, detail: String(describing: error))
                            if attempt == 4 {
                                ended = true
                                throw ExpertFailure(category: .invalidOutput, input: reviewInput, rawOutput: received.rawOutput, detail: "Reviewer protocol exhausted: \(error)", elapsedSeconds: Date().timeIntervalSince(start))
                            }
                            continue
                        }
                        await journal.mark(request.id, .valid)
                        reviewReply = received
                        break
                    } catch let failure as ExpertFailure { throw failure }
                    catch let fatal as PlayingBoundaryFailure {
                        ended = true
                        throw ExpertFailure(category: .identity, input: reviewInput, rawOutput: "", detail: String(describing: fatal), elapsedSeconds: Date().timeIntervalSince(start))
                    } catch {
                        if let failure = error as? PlayingTransportFailure, failure.fatal {
                            ended = true
                            throw ExpertFailure(category: .identity, input: reviewInput, rawOutput: failure.rawOutput ?? "", detail: failure.detail, elapsedSeconds: Date().timeIntervalSince(start))
                        }
                        if attempt == 4 {
                            ended = true
                            throw ExpertFailure(category: .runtime, input: reviewInput, rawOutput: "", detail: "Reviewer technical attempts exhausted: \(error)", elapsedSeconds: Date().timeIntervalSince(start))
                        }
                    }
                }
                guard let reviewReply, let verdict, let request = finalRequest else { preconditionFailure("Bounded reviewer loop has no outcome") }
                let review = ReviewRecord(requestID: request.id, pendingDecisionID: candidate.id, candidateID: candidate.candidateID,
                    instructions: Self.reviewerInstructions, input: reviewInput, rawOutput: reviewReply.rawOutput, identity: reviewReply.identity, result: verdict,
                    elapsedSeconds: Date().timeIntervalSince(reviewStarted))
                rounds.append(ReviewRound(number: round, playerRequestID: playerRequest.id, playerInput: playerInput,
                    playerRawOutput: reply.rawOutput, playerIdentity: reply.identity, playerElapsedSeconds: playerElapsed,
                    pending: candidate, review: review))
                if verdict.verdict == .approve || round == 5 {
                    _ = try remainingRequestSeconds()
                    let record = DecisionRecord(session: session, planAssociation: proposedAssociation, wireContractVersion: Self.wireContractVersion, snapshot: snapshot, instructions: Self.instructions, input: playerInput, rawOutput: reply.rawOutput,
                        identity: reply.identity, advice: advice, action: CurrentAction(snapshot: snapshot, card: advice.currentCard),
                        effectivePlan: proposedAssociation?.text, elapsedSeconds: Date().timeIntervalSince(start), pending: candidate, review: review,
                        canonicalInput: input, reviewRounds: rounds, executionDisposition: verdict.verdict == .approve ? .reviewApproved : .contested, requestEvidence: await journal.read().filter { $0.decisionID == session.id }, humanWaitingSeconds: humanWaitingSeconds)
                    authorized = record
                    authorizedDeadline = deadline
                    return record
                }
                playerInput = try Self.feedbackInput(snapshotInput: input, pending: candidate, review: review, rawCandidate: reply.rawOutput)
            }
            ended = true
            throw ExpertFailure(category: .reviewRejected, input: playerInput, rawOutput: "", detail: "Semantic review cap reached", elapsedSeconds: Date().timeIntervalSince(start))
        } catch var failure as ExpertFailure {
            if failure.category != .needsInput { ended = true }
            failure.reviewRounds = rounds
            failure.requestEvidence = await journal.read().filter { $0.decisionID == session.id }
            throw failure
        }
    }

    private func recordedReply(transport: any PlayingTransport, request: PlayingRequest, role: RequestEvidence.Role, decisionID: UUID, candidateID: UUID?, round: Int, attempt: Int) async throws -> PlayingReply {
        let start = Date()
        let journal = self.journal
        return try await boundedReply(transport: transport, request: request) { result, outcome in
            let reply: PlayingReply?
            let detail: String?
            switch result {
            case let .success(value): reply = value; detail = nil
            case let .failure(error):
                if let failure = error as? PlayingTransportFailure, let identity = failure.identity {
                    reply = PlayingReply(rawOutput: failure.rawOutput ?? "", identity: identity, requestID: request.id, usage: failure.usage)
                    detail = failure.detail
                } else { reply = nil; detail = String(describing: error) }
            }
            await journal.append(RequestEvidence(role: role, requestID: request.id, decisionID: decisionID, candidateID: candidateID, semanticRound: round, technicalAttempt: attempt, instructions: request.instructions, input: request.input, outputSchema: request.outputSchema, timeoutSeconds: request.timeoutSeconds, rawOutput: reply?.rawOutput, identity: reply?.identity, replyRequestID: reply?.requestID, usage: reply?.usage, elapsedSeconds: Date().timeIntervalSince(start), outcome: outcome, detail: detail))
        }
    }

    private func snapshotInput(_ snapshot: DecisionSnapshot, initial: Bool) throws -> String {
        func seat(_ value: Seat) -> String { String(value.rawValue.prefix(1)).uppercased() }
        func play(_ event: PlayEvent) -> [String: String] { ["seat": seat(event.seat), "card": event.card.description] }
        let hands = Dictionary(uniqueKeysWithValues: snapshot.hands.map { hand in
            (seat(hand.seat), Dictionary(uniqueKeysWithValues: Suit.allCases.map { suit in
                (suit.code, hand.cards.filter { $0.suit == suit }.sorted { $0.rank > $1.rank }
                    .map { String($0.description.dropFirst()) }.joined())
            }))
        })
        let completed = snapshot.completedTricks ?? []
        guard completed.count * 4 + snapshot.currentTrick.count == snapshot.events.count else {
            throw ExpertSessionError.changedHistory
        }
        let input: [String: Any] = [
            "type": initial ? "initial" : "update",
            "contract": ["level": snapshot.contract.level, "strain": snapshot.contract.strain.trump?.code ?? "NT",
                         "doubling": snapshot.contract.doubling.rawValue, "declarer": seat(snapshot.contract.declarer)],
            "scoring": snapshot.scoring, "vulnerability": snapshot.vulnerability,
            "objective": snapshot.objective, "publicBackground": snapshot.publicBackground as Any? ?? NSNull(),
            "controller": seat(snapshot.controller), "hands": hands,
            "completedTricks": completed.map { ["plays": $0.plays.map(play), "winner": seat($0.winner)] as [String: Any] },
            "currentTrick": snapshot.currentTrick.map(play),
            "current": ["toAct": seat(snapshot.actingSeat),
                        "winningPlay": snapshot.currentWinningPlay.map(play) as Any? ?? NSNull(),
                        "tricksWon": ["declarer": snapshot.declarerTricks, "defenders": snapshot.defenderTricks]],
            "effectivePlan": planAssociation?.text as Any? ?? NSNull()
        ]
        return String(decoding: try JSONSerialization.data(withJSONObject: input, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self)
    }

    private enum ValidationError: Error { case illegalCard, emptyReason, missingInitialPlan, missingReplacement, ambiguousPlan, unexpectedFields }

    public static let wireContractVersion = "stage1-full-snapshot-v5"

    /// One bundled source, loaded explicitly as the thread's base instructions.
    public static let instructions: String = {
        guard let url = Bundle.module.url(forResource: "DeclarerInstructions", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            preconditionFailure("Missing bundled declarer instructions")
        }
        return text
    }()

    private static func outputSchema(for snapshot: DecisionSnapshot, initialPlan: Bool) throws -> String {
        var schema = try JSONSerialization.jsonObject(with: Data(outputSchema.utf8)) as! [String: Any]
        var properties = schema["properties"] as! [String: Any]
        properties["selectedCard"] = ["type": "string", "enum": snapshot.legalCards.map(\.description)]
        if initialPlan {
            var plan = properties["plan"] as! [String: Any]
            let variants = plan["anyOf"] as! [[String: Any]]
            plan["anyOf"] = variants.filter { variant in
                let fields = variant["properties"] as! [String: Any]
                let update = fields["update"] as! [String: Any]
                return update["enum"] as? [String] == ["replace"]
            }
            properties["plan"] = plan
        }
        schema["properties"] = properties
        func json(_ value: Any) throws -> String {
            if let object = value as? [String: Any] {
                // Select the plan operation before generating its corresponding payload.
                let keys = Set(object.keys) == ["update", "text"] ? ["update", "text"] : object.keys.sorted()
                let members = try keys.map { key in
                    try json(key) + ":" + json(object[key]!)
                }.joined(separator: ",")
                return "{" + members + "}"
            }
            if let array = value as? [Any] {
                return "[" + (try array.map { try json($0) }.joined(separator: ",")) + "]"
            }
            return String(decoding: try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]), as: UTF8.self)
        }
        // Match the decision process: plan, current card, then its reason.
        let orderedProperties = try ["plan", "selectedCard", "publicReason"].map { key in
            try json(key) + ":" + json(properties[key]!)
        }.joined(separator: ",")
        let members = try schema.keys.sorted().map { key in
            let value = key == "properties" ? "{" + orderedProperties + "}" : try json(schema[key]!)
            return try json(key) + ":" + value
        }.joined(separator: ",")
        return "{" + members + "}"
    }

    public static let outputSchema = #"{"type":"object","additionalProperties":false,"required":["plan","publicReason","selectedCard"],"properties":{"selectedCard":{"type":"string","pattern":"^[SHDC][2-9TJQKA]$"},"publicReason":{"type":"string"},"plan":{"anyOf":[{"type":"object","additionalProperties":false,"required":["update","text"],"properties":{"update":{"type":"string","enum":["replace"]},"text":{"type":"string","pattern":"\\S"}}},{"type":"object","additionalProperties":false,"required":["update","text"],"properties":{"update":{"type":"string","enum":["keep"]},"text":{"type":"null"}}},{"type":"object","additionalProperties":false,"required":["update","text"],"properties":{"update":{"type":"string","enum":["withdraw"]},"text":{"type":"null"}}}]}}}"#
}
