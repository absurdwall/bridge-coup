import Foundation
import BridgeDomain

public struct RuntimeIdentity: Codable, Equatable, Sendable {
    public let requestedModel: String
    public let requestedEffort: String
    public let runtimeVersion: String
    /// Observable runtime acknowledgement, not proof of the remote service's internal identity.
    public let observedModel: String?
    public let threadID: String
    public let turnID: String
    public init(requestedModel: String, requestedEffort: String, runtimeVersion: String, observedModel: String?, threadID: String, turnID: String) {
        self.requestedModel = requestedModel; self.requestedEffort = requestedEffort; self.runtimeVersion = runtimeVersion
        self.observedModel = observedModel; self.threadID = threadID; self.turnID = turnID
    }
}

public struct PlayingRequest: Sendable {
    public let instructions: String
    public let input: String
    public let outputSchema: String
    public let timeoutSeconds: Double
}

public struct PlayingReply: Sendable {
    public let rawOutput: String
    public let identity: RuntimeIdentity
    public init(rawOutput: String, identity: RuntimeIdentity) { self.rawOutput = rawOutput; self.identity = identity }
}

/// External model boundary. Production uses Codex app-server; tests may supply recorded replies.
public protocol PlayingTransport: Sendable {
    func respond(to request: PlayingRequest) async throws -> PlayingReply
}

public struct PlanChange: Codable, Equatable, Sendable {
    public enum Update: String, Codable, Sendable { case keep, replace, withdraw }
    public let update: Update
    public let text: String?
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

public enum ExpertSessionError: Error, Equatable { case overlappingDecision, staleSnapshot, differentBoardOrController, changedHistory, endedSession, changedThreadOrRepeatedTurn, invalidExecutionEvidence }

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
}

public struct ExpertFailure: Error, Sendable {
    public enum Category: String, Codable, Sendable { case runtime, invalidOutput, identity }
    public let category: Category
    public let input: String
    public let rawOutput: String
    public let detail: String
    public let elapsedSeconds: Double
}

/// The App-independent Expert entry: one board/controller owns one continuing transport.
public actor ExpertSession {
    private let transport: any PlayingTransport
    private var planAssociation: PlanAssociation?
    private var previousIdentity: RuntimeIdentity?
    private var usedTurnIDs: Set<String> = []
    private var inFlight = false
    private var ended = false
    private var boundBoard: UUID?
    private var boundController: Seat?
    private var previousSnapshot: DecisionSnapshot?

    public init(transport: any PlayingTransport) { self.transport = transport }

    public func decide(_ snapshot: DecisionSnapshot, executions: [ActualExecution] = [], timeoutSeconds: Double = 180) async throws -> DecisionRecord {
        guard !inFlight else { throw ExpertSessionError.overlappingDecision }
        guard !ended else { throw ExpertSessionError.endedSession }
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
        let session = DecisionSession(id: UUID(), snapshotID: snapshot.id)
        let input = try snapshotInput(snapshot, initial: previousSnapshot == nil)
        let start = Date()
        let reply: PlayingReply
        do { reply = try await transport.respond(to: PlayingRequest(instructions: Self.instructions, input: input, outputSchema: try Self.outputSchema(for: snapshot, initialPlan: previousSnapshot == nil), timeoutSeconds: timeoutSeconds)) }
        catch { ended = true; throw ExpertFailure(category: .runtime, input: input, rawOutput: "", detail: String(describing: error), elapsedSeconds: Date().timeIntervalSince(start)) }
        let elapsed = Date().timeIntervalSince(start)
        if let previousIdentity, (reply.identity.threadID != previousIdentity.threadID || usedTurnIDs.contains(reply.identity.turnID)) {
            ended = true
            throw ExpertFailure(category: .identity, input: input, rawOutput: reply.rawOutput, detail: String(describing: ExpertSessionError.changedThreadOrRepeatedTurn), elapsedSeconds: elapsed)
        }
        let advice: PublicAdvice
        do {
            let data = Data(reply.rawOutput.utf8)
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  Set(object.keys) == ["selectedCard", "publicReason", "plan"],
                  let plan = object["plan"] as? [String: Any], Set(plan.keys) == ["update", "text"] else { throw ValidationError.unexpectedFields }
            advice = try JSONDecoder().decode(PublicAdvice.self, from: data)
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
            ended = true
            throw ExpertFailure(category: .invalidOutput, input: input, rawOutput: reply.rawOutput, detail: String(describing: error), elapsedSeconds: elapsed)
        }
        switch advice.plan.update {
        case .keep: break
        case .replace: planAssociation = PlanAssociation(boardID: snapshot.boardID, controller: snapshot.controller, sourceSnapshotID: snapshot.id, sourceSessionID: session.id, text: advice.plan.text!)
        case .withdraw: planAssociation = nil
        }
        previousSnapshot = snapshot
        previousIdentity = reply.identity
        usedTurnIDs.insert(reply.identity.turnID)
        return DecisionRecord(session: session, planAssociation: planAssociation, wireContractVersion: Self.wireContractVersion, snapshot: snapshot, instructions: Self.instructions, input: input, rawOutput: reply.rawOutput,
                              identity: reply.identity, advice: advice, action: CurrentAction(snapshot: snapshot, card: advice.currentCard),
                              effectivePlan: planAssociation?.text, elapsedSeconds: elapsed)
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

    private enum ValidationError: Error { case emptyReason, missingInitialPlan, missingReplacement, ambiguousPlan, unexpectedFields }

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
