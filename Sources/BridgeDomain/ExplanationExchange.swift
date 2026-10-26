import Foundation

public struct ExplanationSettings: Codable, Equatable, Sendable {
    public let nsSystem: String
    public let ewSystem: String
    public let conditions: String
    public let handRecordReference: String?
    public init(nsSystem: String, ewSystem: String, conditions: String, handRecordReference: String? = nil) {
        self.nsSystem = nsSystem; self.ewSystem = ewSystem; self.conditions = conditions; self.handRecordReference = handRecordReference
    }
}

/// A local lookup retains the original observation's source; it is not a new platform observation.
public struct ExplanationResult: Codable, Equatable, Sendable {
    public enum Provider: String, Codable, Sendable { case knowledge, environment }
    public enum Status: String, Codable, Sendable { case found, noMatch, unavailable }
    public let candidate: AuctionCall
    public let provider: Provider
    public let status: Status
    public let references: [ExplanationMatch]
    public let detail: String
    public let context: ExplanationContext?
    public init(candidate: AuctionCall, provider: Provider, status: Status, references: [ExplanationMatch], detail: String, context: ExplanationContext? = nil) {
        self.candidate = candidate; self.provider = provider; self.status = status; self.references = references; self.detail = detail; self.context = context
    }
}

/// Inspecting these candidates never submits an auction event or authorizes execution.
public struct ExplanationRequest: Codable, Equatable, Sendable {
    public let id: UUID
    public let snapshotID: String
    public let context: ExplanationContext
    public let candidates: [AuctionCall]
    public let reason: String
    public let localResults: [ExplanationResult]
    public init(id: UUID = UUID(), snapshotID: String, context: ExplanationContext, candidates: [AuctionCall], reason: String, localResults: [ExplanationResult] = []) {
        self.id = id; self.snapshotID = snapshotID; self.context = context; self.candidates = candidates; self.reason = reason; self.localResults = localResults
    }
}

public struct ExplanationRequestNeeded: Error, Sendable {
    public let request: ExplanationRequest
    public init(request: ExplanationRequest) { self.request = request }
}
public enum ExplanationExchangeError: Error { case invalidRequest, staleRequest, invalidResult, missingStore, exhaustedInformationBudget }
