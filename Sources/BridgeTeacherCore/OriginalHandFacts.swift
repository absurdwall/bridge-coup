import Foundation

/// The entered board is immutable input to derived play/DDS positions. Visibility
/// controls teaching projection separately and never changes this source version.
public struct OriginalHandFacts: Codable, Equatable, Sendable {
    public let boardID: UUID
    public let version: Int
    public let hands: [Seat: [Suit: String]]
    public let decisionTimeConfirmed: Bool

    public init(boardID: UUID = UUID(), version: Int = 0, hands: [Seat: [Suit: String]] = [:], decisionTimeConfirmed: Bool = true) {
        self.boardID = boardID
        self.version = version
        self.hands = hands
        self.decisionTimeConfirmed = decisionTimeConfirmed
    }

    public func updating(from draft: DeclarerPlanDraft) -> Self {
        guard hands != draft.hands || decisionTimeConfirmed != draft.decisionTimeConfirmed else { return self }
        return Self(boardID: boardID, version: version + 1, hands: draft.hands, decisionTimeConfirmed: draft.decisionTimeConfirmed)
    }

    /// Uses existing validation without inventing missing cards or turning unknown into void.
    public func validatedHands() throws -> [VisibleHand] {
        guard decisionTimeConfirmed else { throw DeclarerPlanInputError.decisionTimeNotConfirmed }
        var draft = DeclarerPlanDraft()
        draft.hands = hands
        return try DeclarerPlanRequestBuilder.visibleHands(in: draft)
    }
}
