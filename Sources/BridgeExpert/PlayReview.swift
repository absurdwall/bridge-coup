import Foundation
import BridgeDomain

public struct PendingDeclarerDecision: Codable, Equatable, Sendable {
    public let id: UUID
    public let candidateID: UUID
    public let snapshot: DecisionSnapshot
    public let priorPlan: PlanAssociation?
    public let candidate: PublicAdvice
    public let proposedEffectivePlan: String?
}

public struct PlayReview: Codable, Equatable, Sendable {
    public enum Verdict: String, Codable, Sendable { case approve, revise, uncertain }
    public struct Finding: Codable, Equatable, Sendable {
        public let claim: String
        public let evidence: String
        public let requestedChange: String
    }
    public let verdict: Verdict
    public let blockingFindings: [Finding]
    public let advisorySuggestions: [String]
}

public struct ReviewRecord: Codable, Sendable {
    public let requestID: UUID
    public let pendingDecisionID: UUID
    public let candidateID: UUID
    public let instructions: String
    public let input: String
    public let rawOutput: String
    public let identity: RuntimeIdentity
    public let result: PlayReview
    public let elapsedSeconds: Double?
}

public enum ExecutionDisposition: String, Codable, Sendable { case reviewApproved, contested }

/// All proposals remain evidence; only the final authorized round is delivered advice.
public struct ReviewRound: Codable, Sendable {
    public let number: Int
    public let playerRequestID: UUID
    public let playerInput: String
    public let playerRawOutput: String
    public let playerIdentity: RuntimeIdentity
    public let playerElapsedSeconds: Double
    public let pending: PendingDeclarerDecision
    public let review: ReviewRecord
}

extension ExpertSession {
    /// Check completeness of supplied public facts, without inferring unseen holdings.
    static func missingPositionFacts(_ snapshot: DecisionSnapshot) -> String? {
        let required: Set<Seat> = [snapshot.controller, snapshot.controller.partner]
        guard snapshot.hands.count == 2, Set(snapshot.hands.map(\.seat)) == required else {
            return "Complete remaining declarer and dummy hands are required; defender hands stay unknown."
        }
        guard hasConsistentPublicCardHistory(snapshot) else {
            return "Authorized holdings and public play history contain conflicting cards or event sequences."
        }
        for hand in snapshot.hands {
            guard hand.cards.count + snapshot.events.filter({ $0.seat == hand.seat }).count == 13 else {
                return "A controlled hand's remaining-card count conflicts with its public plays."
            }
        }
        guard let completed = snapshot.completedTricks,
              completed.allSatisfy({ $0.plays.count == 4 }),
              completed.flatMap(\.plays) + snapshot.currentTrick == snapshot.events,
              snapshot.currentTrick.count < 4,
              (snapshot.currentTrick.isEmpty && snapshot.currentWinningPlay == nil) ||
                (snapshot.currentWinningPlay.map { snapshot.currentTrick.contains($0) } == true) else {
            return "Complete public trick history and current winning play are required."
        }
        guard !snapshot.legalCards.isEmpty, Set(snapshot.legalCards).count == snapshot.legalCards.count,
              let actingHand = snapshot.hands.first(where: { $0.seat == snapshot.actingSeat }),
              Set(snapshot.legalCards).isSubset(of: actingHand.cards) else {
            return "The complete Engine-authorized current legal choices and acting hand are required."
        }
        return nil
    }

    static func feedbackInput(snapshotInput: String, pending: PendingDeclarerDecision, review: ReviewRecord, rawCandidate: String) throws -> String {
        var value = try JSONSerialization.jsonObject(with: Data(reviewInput(snapshotInput: snapshotInput, pending: pending).utf8)) as! [String: Any]
        value["type"] = review.result.verdict == .uncertain ? "clarification" : "revision"
        value["review"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(review.result))
        value["rawReview"] = review.rawOutput
        value["rawCandidate"] = rawCandidate
        return String(decoding: try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self)
    }

    static func validateIdentity(_ identity: RuntimeIdentity) throws {
        guard identity.requestedModel == "gpt-6.1-sol", identity.observedModel == "gpt-6.1-sol",
              identity.requestedEffort == "medium", identity.observedEffort == "medium",
              !identity.threadID.isEmpty, !identity.turnID.isEmpty else { throw ReviewContractError.identity }
    }

    static func reviewInput(snapshotInput: String, pending: PendingDeclarerDecision) throws -> String {
        let value: [String: Any] = [
            "latestSnapshot": try JSONSerialization.jsonObject(with: Data(snapshotInput.utf8)),
            "legalCurrentCards": pending.snapshot.legalCards.map(\.description),
            "candidate": try JSONSerialization.jsonObject(with: JSONEncoder().encode(pending.candidate)),
            "proposedEffectivePlan": pending.proposedEffectivePlan as Any? ?? NSNull()
        ]
        return String(decoding: try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self)
    }

    static func parseReview(_ output: String) throws -> PlayReview {
        let data = Data(output.utf8)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String:Any],
              Set(object.keys) == ["verdict", "blockingFindings", "advisorySuggestions"],
              let findings = object["blockingFindings"] as? [[String:Any]],
              findings.allSatisfy({ Set($0.keys) == ["claim", "evidence", "requestedChange"] }) else { throw ReviewContractError.fields }
        let review = try JSONDecoder().decode(PlayReview.self, from: data)
        guard (review.verdict == .revise) == !review.blockingFindings.isEmpty,
              review.blockingFindings.allSatisfy({ [$0.claim, $0.evidence, $0.requestedChange].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }),
              review.verdict != .uncertain || review.advisorySuggestions.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { throw ReviewContractError.verdict }
        return review
    }

    public static let reviewerInstructions: String = {
        guard let url = Bundle.module.url(forResource: "ReviewerInstructions", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { preconditionFailure("Missing bundled reviewer instructions") }
        return text
    }()

    public static let reviewOutputSchema = #"{"type":"object","additionalProperties":false,"required":["verdict","blockingFindings","advisorySuggestions"],"properties":{"verdict":{"type":"string","enum":["approve","revise","uncertain"]},"blockingFindings":{"type":"array","items":{"type":"object","additionalProperties":false,"required":["claim","evidence","requestedChange"],"properties":{"claim":{"type":"string"},"evidence":{"type":"string"},"requestedChange":{"type":"string"}}}},"advisorySuggestions":{"type":"array","items":{"type":"string"}}}}"#
}
private enum ReviewContractError: Error { case identity, fields, verdict }
