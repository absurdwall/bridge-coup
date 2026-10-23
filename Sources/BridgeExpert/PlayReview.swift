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
}

extension ExpertSession {
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
