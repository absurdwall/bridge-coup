import Foundation

/// The actual auction prefix and table conditions under which a meaning was observed.
public struct ExplanationContext: Codable, Equatable, Sendable {
    public let dealer: Seat
    public let actingSeat: Seat
    public let auction: [AuctionEvent]
    public let vulnerability: String
    public let nsSystem: String
    public let ewSystem: String
    public let conditions: String
    public let handRecordReference: String?

    public init(dealer: Seat, actingSeat: Seat, auction: [AuctionEvent], vulnerability: String,
                nsSystem: String, ewSystem: String, conditions: String, handRecordReference: String? = nil) {
        self.dealer = dealer; self.actingSeat = actingSeat; self.auction = auction
        self.vulnerability = vulnerability; self.nsSystem = nsSystem; self.ewSystem = ewSystem
        self.conditions = conditions; self.handRecordReference = handRecordReference
    }
}

/// An attributed observation is a reference, not an automatically adopted agreement.
public struct ExplanationObservation: Codable, Equatable, Sendable {
    public let id: UUID
    public let context: ExplanationContext
    public let candidate: AuctionCall
    public let text: String
    public let source: String
    public let observedAt: String
    public let sourceVersion: String
    public let evidence: [String]
    public let notes: String
    public let isTestData: Bool

    public init(id: UUID = UUID(), context: ExplanationContext, candidate: AuctionCall, text: String,
                source: String, observedAt: String, sourceVersion: String = "unknown", evidence: [String],
                notes: String = "", isTestData: Bool = false) {
        self.id = id; self.context = context; self.candidate = candidate; self.text = text; self.source = source
        self.observedAt = observedAt; self.sourceVersion = sourceVersion; self.evidence = evidence
        self.notes = notes; self.isTestData = isTestData
    }
}

public struct ExplanationMatch: Codable, Equatable, Sendable {
    public enum Status: String, Codable, Sendable { case exact, related }
    public let observation: ExplanationObservation
    public let status: Status
    public let differences: [String]

    public init(observation: ExplanationObservation, status: Status, differences: [String]) {
        self.observation = observation; self.status = status; self.differences = differences
    }
}
