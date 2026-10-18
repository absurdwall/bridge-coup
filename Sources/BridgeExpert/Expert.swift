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
    public let publicReason: String
    public let plan: PlanChange
}

public struct DecisionRecord: Codable, Sendable {
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
    public let input: String
    public let rawOutput: String
    public let detail: String
    public let elapsedSeconds: Double
}

/// The App-independent Expert entry: one board/controller owns one continuing transport.
public actor ExpertSession {
    private let transport: any PlayingTransport
    private var effectivePlan: String?
    private var previousSnapshot: DecisionSnapshot?

    public init(transport: any PlayingTransport) { self.transport = transport }

    public func decide(_ snapshot: DecisionSnapshot) async throws -> DecisionRecord {
        guard snapshot.actingSeat == snapshot.controller || snapshot.actingSeat == snapshot.controller.partner else {
            throw DomainError.invalidController
        }
        let input = Self.initialInput(snapshot)
        let start = Date()
        let reply: PlayingReply
        do { reply = try await transport.respond(to: PlayingRequest(instructions: Self.instructions, input: input, outputSchema: Self.outputSchema)) }
        catch { throw ExpertFailure(input: input, rawOutput: "", detail: String(describing: error), elapsedSeconds: Date().timeIntervalSince(start)) }
        let elapsed = Date().timeIntervalSince(start)
        let advice: PublicAdvice
        do {
            let data = Data(reply.rawOutput.utf8)
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  Set(object.keys) == ["currentCard", "publicReason", "plan"],
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
            throw ExpertFailure(input: input, rawOutput: reply.rawOutput, detail: String(describing: error), elapsedSeconds: elapsed)
        }
        switch advice.plan.update {
        case .keep: break
        case .replace: effectivePlan = advice.plan.text
        case .withdraw: effectivePlan = nil
        }
        previousSnapshot = snapshot
        return DecisionRecord(snapshot: snapshot, instructions: Self.instructions, input: input, rawOutput: reply.rawOutput,
                              identity: reply.identity, advice: advice, action: CurrentAction(snapshot: snapshot, card: advice.currentCard),
                              effectivePlan: effectivePlan, elapsedSeconds: elapsed)
    }

    private static func initialInput(_ snapshot: DecisionSnapshot) -> String {
        func name(_ seat: Seat) -> String { seat.rawValue.capitalized }
        func role(_ seat: Seat) -> String { seat == snapshot.contract.declarer ? "declarer" : "dummy" }
        let strain = snapshot.contract.strain == .noTrump ? "NT" : snapshot.contract.strain.rawValue
        var lines = [
            "Contract: \(snapshot.contract.level)\(strain) by \(name(snapshot.contract.declarer)). Scoring: \(snapshot.scoring). Vulnerability: \(snapshot.vulnerability).",
            "Objective: \(snapshot.objective)",
            "Decision controller: \(name(snapshot.controller)) (declarer).",
            "Acting hand: \(name(snapshot.actingSeat)) (\(role(snapshot.actingSeat)))."
        ]
        for hand in snapshot.hands {
            let holding = Suit.allCases.map { suit in
                let ranks = hand.cards.filter { $0.suit == suit }.sorted { $0.rank > $1.rank }.map { String($0.description.dropFirst()) }.joined()
                return "\(suit.code) \(ranks.isEmpty ? "-" : ranks)"
            }.joined(separator: " / ")
            lines.append("\(name(hand.seat)) (\(role(hand.seat))): \(holding)")
        }
        lines.append("Actual plays in order: " + snapshot.events.map { "\(name($0.seat)) \($0.card)" }.joined(separator: "; ") + ".")
        lines.append("Tricks won: declarer \(snapshot.declarerTricks), defenders \(snapshot.defenderTricks).")
        lines.append("Additional public background: " + (snapshot.publicBackground ?? "Auction and defensive methods are not provided."))
        return lines.joined(separator: "\n")
    }

    private enum ValidationError: Error { case emptyReason, missingInitialPlan, missingReplacement, ambiguousPlan, unexpectedFields }

    public static let instructions = """
    Play declarer and dummy using the supplied decision-time information. Write in English and pursue the stated objective. currentCard is the single card from actingSeat to play now; publicReason briefly explains it. A plan is advice, not an observed event. plan.update replace installs plan.text, keep retains the previous plan, and withdraw removes it; use null text for keep or withdraw. Provide an initial concrete plan before dummy's first play. Unknown cards remain unknown.
    """

    public static let outputSchema = #"{"type":"object","additionalProperties":false,"required":["currentCard","publicReason","plan"],"properties":{"currentCard":{"type":"string","pattern":"^[SHDC][2-9TJQKA]$"},"publicReason":{"type":"string"},"plan":{"type":"object","additionalProperties":false,"required":["update","text"],"properties":{"update":{"type":"string","enum":["keep","replace","withdraw"]},"text":{"type":["string","null"]}}}}}"#
}
