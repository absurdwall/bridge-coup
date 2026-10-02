import Combine
import Foundation

public enum ScreenshotRecognitionNoteKind: String, CaseIterable, Codable, Equatable, Sendable {
    case notShown
    case visibleButUnclear
    case ambiguous
}

public enum ScreenshotRecognitionEditedField: Codable, Hashable, Sendable {
    case vulnerability
    case auction
    case declarerSeat
    case contractLevel
    case contractStrain
    case openingLead
    case otherDecisionTimeFacts
    case hand(seat: Seat, suit: Suit)
}

public struct ScreenshotRecognitionNote: Codable, Equatable, Sendable {
    public let field: String
    public let kind: ScreenshotRecognitionNoteKind
    public let message: String

    public init(field: String, kind: ScreenshotRecognitionNoteKind, message: String) {
        self.field = field
        self.kind = kind
        self.message = message
    }
}

public enum ScreenshotAuctionAction: String, CaseIterable, Codable, Equatable, Sendable {
    case bid
    case pass
    case double
    case redouble
    case unknown
}

/// A single call the recognizer can read from the screenshot. `unknown` is
/// reserved for a visibly occupied call position whose symbol cannot be read;
/// the recognizer must omit positions that are not shown.
public struct ScreenshotAuctionEntryCandidate: Codable, Equatable, Sendable {
    public var seat: Seat?
    public var action: ScreenshotAuctionAction
    public var level: Int?
    public var strain: ContractStrain?

    public init(
        seat: Seat? = nil,
        action: ScreenshotAuctionAction,
        level: Int? = nil,
        strain: ContractStrain? = nil
    ) {
        self.seat = seat
        self.action = action
        self.level = level
        self.strain = strain
    }

    public var auctionCall: AuctionCall {
        switch action {
        case .bid:
            guard let level, (1...7).contains(level), let strain else { return .unknown }
            return .bid(level: level, strain: strain)
        case .pass:
            return .pass
        case .double:
            return .double
        case .redouble:
            return .redouble
        case .unknown:
            return .unknown
        }
    }
}

/// Ordered calls visible in the image. An empty list is an empty candidate,
/// not confirmation that the board had no auction; `nil` on the parent
/// recognition candidate means the image supplied no auction candidate.
public struct ScreenshotAuctionCandidate: Codable, Equatable, Sendable {
    public var startingSeat: Seat?
    public var entries: [ScreenshotAuctionEntryCandidate]
    public var isPartial: Bool

    public init(
        startingSeat: Seat? = nil,
        entries: [ScreenshotAuctionEntryCandidate] = [],
        isPartial: Bool = false
    ) {
        self.startingSeat = startingSeat
        self.entries = entries
        self.isPartial = isPartial
    }

    private enum CodingKeys: String, CodingKey {
        case startingSeat
        case entries
        case isPartial
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startingSeat = try container.decodeIfPresent(Seat.self, forKey: .startingSeat)
        entries = try container.decodeIfPresent([ScreenshotAuctionEntryCandidate].self, forKey: .entries) ?? []
        isPartial = try container.decodeIfPresent(Bool.self, forKey: .isPartial) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(startingSeat, forKey: .startingSeat)
        try container.encode(entries, forKey: .entries)
        try container.encode(isPartial, forKey: .isPartial)
    }

    public var auctionRecord: AuctionRecord {
        let firstPosition: Int?
        if !isPartial, let startingSeat {
            firstPosition = Seat.allCases.firstIndex(of: startingSeat)
        } else {
            firstPosition = nil
        }
        return AuctionRecord(
            startingSeat: startingSeat,
            entries: entries.enumerated().map { index, entry in
                let sequentialSeat = firstPosition.map { Seat.allCases[($0 + index) % Seat.allCases.count] }
                let inferredSeat = entry.seat == nil ? sequentialSeat : nil
                return AuctionEntry(
                    seat: entry.seat ?? sequentialSeat,
                    seatIsSequenceDerived: inferredSeat != nil,
                    call: entry.auctionCall
                )
            },
            isPartial: isPartial
        )
    }
}

/// Model output stays a candidate until the player checks the image and the decision point.
public struct ScreenshotRecognitionCandidate: Codable, Equatable, Sendable {
    public var hands: [Seat: [Suit: String]]
    public var vulnerability: Vulnerability?
    public var auction: ScreenshotAuctionCandidate?
    public var declarerSeat: Seat?
    public var contractLevel: Int?
    public var contractStrain: ContractStrain?
    public var openingLead: String?
    public var otherDecisionTimeFacts: String
    public var notes: [ScreenshotRecognitionNote]

    public init(
        hands: [Seat: [Suit: String]],
        declarerSeat: Seat?,
        contractLevel: Int?,
        contractStrain: ContractStrain?,
        openingLead: String?,
        otherDecisionTimeFacts: String,
        notes: [ScreenshotRecognitionNote],
        vulnerability: Vulnerability? = nil,
        auction: ScreenshotAuctionCandidate? = nil
    ) {
        self.hands = hands
        self.vulnerability = vulnerability
        self.auction = auction
        self.declarerSeat = declarerSeat
        self.contractLevel = contractLevel
        self.contractStrain = contractStrain
        self.openingLead = openingLead
        self.otherDecisionTimeFacts = otherDecisionTimeFacts
        self.notes = notes
    }

    private enum CodingKeys: String, CodingKey {
        case hands
        case vulnerability
        case auction
        case declarerSeat
        case contractLevel
        case contractStrain
        case openingLead
        case otherDecisionTimeFacts
        case notes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let encodedHands = try container.decode([String: [String: String]].self, forKey: .hands)
        var decodedHands: [Seat: [Suit: String]] = [:]

        for (seatName, holdings) in encodedHands {
            guard let seat = Seat(rawValue: seatName) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: container.codingPath + [CodingKeys.hands],
                    debugDescription: "Unknown seat in screenshot recognition result."
                ))
            }
            var decodedHoldings: [Suit: String] = [:]
            for (suitName, cards) in holdings {
                guard let suit = Suit(rawValue: suitName) else {
                    throw DecodingError.dataCorrupted(.init(
                        codingPath: container.codingPath + [CodingKeys.hands],
                        debugDescription: "Unknown suit in screenshot recognition result."
                    ))
                }
                decodedHoldings[suit] = cards
            }
            decodedHands[seat] = decodedHoldings
        }

        hands = decodedHands
        vulnerability = try container.decodeIfPresent(Vulnerability.self, forKey: .vulnerability)
        auction = try container.decodeIfPresent(ScreenshotAuctionCandidate.self, forKey: .auction)
        declarerSeat = try container.decodeIfPresent(Seat.self, forKey: .declarerSeat)
        contractLevel = try container.decodeIfPresent(Int.self, forKey: .contractLevel)
        contractStrain = try container.decodeIfPresent(ContractStrain.self, forKey: .contractStrain)
        openingLead = try container.decodeIfPresent(String.self, forKey: .openingLead)
        otherDecisionTimeFacts = try container.decode(String.self, forKey: .otherDecisionTimeFacts)
        notes = try container.decode([ScreenshotRecognitionNote].self, forKey: .notes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let encodedHands = Dictionary(uniqueKeysWithValues: hands.map { seat, holdings in
            (seat.rawValue, Dictionary(uniqueKeysWithValues: holdings.map { ($0.key.rawValue, $0.value) }))
        })
        try container.encode(encodedHands, forKey: .hands)
        try container.encodeIfPresent(vulnerability, forKey: .vulnerability)
        try container.encodeIfPresent(auction, forKey: .auction)
        try container.encode(declarerSeat?.rawValue, forKey: .declarerSeat)
        try container.encode(contractLevel, forKey: .contractLevel)
        try container.encode(contractStrain?.rawValue, forKey: .contractStrain)
        try container.encode(openingLead, forKey: .openingLead)
        try container.encode(otherDecisionTimeFacts, forKey: .otherDecisionTimeFacts)
        try container.encode(notes, forKey: .notes)
    }
}

public struct ScreenshotRecognitionResponse: Codable, Equatable, Sendable {
    public let candidate: ScreenshotRecognitionCandidate
    public let model: String?
    public let runtimeVersion: String?
    public let requestedModel: String?
    public let reasoningEffort: String?

    public init(
        candidate: ScreenshotRecognitionCandidate,
        model: String? = nil,
        runtimeVersion: String? = nil,
        requestedModel: String? = nil,
        reasoningEffort: String? = nil
    ) {
        self.candidate = candidate
        self.model = model
        self.runtimeVersion = runtimeVersion
        self.requestedModel = requestedModel
        self.reasoningEffort = reasoningEffort
    }
}

public protocol ScreenshotRecognitionRuntime: Sendable {
    func recognizeScreenshot(at imageURL: URL) async throws -> ScreenshotRecognitionResponse
}

public enum ScreenshotRecognitionState: Codable, Equatable, Sendable {
    case idle
    case recognizing
    case succeeded
    case stale
    case failed(String)
}

@MainActor
public final class ScreenshotReviewWorkflow: ObservableObject {
    @Published public private(set) var screenshotURL: URL?
    @Published public private(set) var screenshotFilename: String?
    @Published public private(set) var state: ScreenshotRecognitionState = .idle
    @Published public private(set) var candidate: ScreenshotRecognitionCandidate?
    @Published public private(set) var recognitionResponse: ScreenshotRecognitionResponse?

    public let planWorkflow: DeclarerPlanWorkflow
    /// The application can stage recognized facts behind its cancellable reset
    /// boundary. Without an application policy, the existing core workflow applies them.
    public var onRecognizedDraft: ((DeclarerPlanDraft, @escaping () -> Void) -> Bool)?

    private let runtime: any ScreenshotRecognitionRuntime
    private var recognitionRevision = 0
    private var manuallyEditedFields: Set<ScreenshotRecognitionEditedField> = []

    public func makeArchive() -> ScreenshotReviewWorkflowArchive {
        ScreenshotReviewWorkflowArchive(
            state: state,
            candidate: candidate,
            response: recognitionResponse,
            sourceFilename: screenshotFilename,
            manuallyEditedFields: manuallyEditedFields
        )
    }

    public init(planWorkflow: DeclarerPlanWorkflow, runtime: any ScreenshotRecognitionRuntime) {
        self.planWorkflow = planWorkflow
        self.runtime = runtime
    }

    public func restore(from archive: ScreenshotReviewWorkflowArchive, screenshotURL: URL?) {
        recognitionRevision += 1
        self.screenshotURL = screenshotURL
        screenshotFilename = archive.sourceFilename ?? screenshotURL?.lastPathComponent
        candidate = archive.candidate
        recognitionResponse = archive.response
        state = archive.state == .recognizing ? .idle : archive.state
        manuallyEditedFields = archive.manuallyEditedFields
        inferManualEdits(from: archive.candidate, draft: planWorkflow.draft)
    }

    public func selectScreenshot(at url: URL) {
        recognitionRevision += 1
        screenshotURL = url
        screenshotFilename = url.lastPathComponent
        state = .idle
        candidate = nil
        recognitionResponse = nil
        manuallyEditedFields = []

        var freshDraft = DeclarerPlanDraft()
        freshDraft.declarerSeat = nil
        freshDraft.decisionTimeVisibleSeats = []
        freshDraft.decisionTimeConfirmed = false
        if freshDraft == planWorkflow.draft {
            planWorkflow.markCurrentResultOutdated()
        } else {
            planWorkflow.updateDraft(freshDraft)
        }
    }

    public func updateDraft(_ draft: DeclarerPlanDraft) {
        recordManualEdits(from: planWorkflow.draft, to: draft)
        invalidatePendingRecognition()
        planWorkflow.updateDraft(draft)
    }

    /// Supersedes an in-flight response or staged recognition commit without
    /// applying an unconfirmed edit to the current facts or manual merge tracking.
    public func invalidatePendingRecognition() {
        recognitionRevision += 1
        if state == .recognizing { state = .stale }
    }

    public func recognizeScreenshot() async {
        guard let screenshotURL else {
            state = .failed("请先导入一张截图。")
            return
        }

        let alreadyHasCandidate = candidate != nil || recognitionResponse != nil
        recognitionRevision += 1
        let requestRevision = recognitionRevision
        state = .recognizing
        do {
            let response = try await runtime.recognizeScreenshot(at: screenshotURL)
            guard recognitionRevision == requestRevision,
                  self.screenshotURL == screenshotURL else { return }
            let commitRecognition: () -> Void = { [weak self] in
                guard let self, self.recognitionRevision == requestRevision,
                      self.screenshotURL == screenshotURL else { return }
                self.recognitionResponse = response
                self.candidate = response.candidate
                self.state = .succeeded
            }
            if !alreadyHasCandidate {
                let proposedDraft = Self.merge(
                    response.candidate,
                    into: planWorkflow.draft,
                    manuallyEditedFields: manuallyEditedFields
                )
                if let onRecognizedDraft {
                    if onRecognizedDraft(proposedDraft, commitRecognition) { commitRecognition() }
                    else { state = .idle } // Cancel leaves the first recognition retryable.
                } else {
                    planWorkflow.updateDraft(proposedDraft)
                    commitRecognition()
                }
            } else { commitRecognition() }
        } catch {
            guard recognitionRevision == requestRevision,
                  self.screenshotURL == screenshotURL else { return }
            state = .failed(error.localizedDescription)
        }
    }

    public func generatePlan() async {
        await planWorkflow.generatePlan()
    }

    private static func merge(
        _ candidate: ScreenshotRecognitionCandidate,
        into current: DeclarerPlanDraft,
        manuallyEditedFields: Set<ScreenshotRecognitionEditedField>
    ) -> DeclarerPlanDraft {
        var merged = current

        if !manuallyEditedFields.contains(.vulnerability), current.vulnerability == nil,
           let recognizedVulnerability = candidate.vulnerability {
            merged.vulnerability = recognizedVulnerability
        }
        if !manuallyEditedFields.contains(.auction), current.auction == nil, let recognizedAuction = candidate.auction {
            merged.auction = recognizedAuction.auctionRecord
        }
        if !manuallyEditedFields.contains(.declarerSeat), current.declarerSeat == nil,
           let recognizedSeat = candidate.declarerSeat {
            merged.declarerSeat = recognizedSeat
        }
        if !manuallyEditedFields.contains(.contractLevel), current.contractLevel == nil {
            merged.contractLevel = candidate.contractLevel
        }
        if !manuallyEditedFields.contains(.contractStrain), current.contractStrain == nil {
            merged.contractStrain = candidate.contractStrain
        }
        if !manuallyEditedFields.contains(.openingLead),
           current.openingLead.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let openingLead = candidate.openingLead {
            merged.openingLead = openingLead
        }
        if !manuallyEditedFields.contains(.otherDecisionTimeFacts),
           current.otherDecisionTimeFacts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.otherDecisionTimeFacts = candidate.otherDecisionTimeFacts
        }

        for seat in Seat.allCases {
            for suit in Suit.allCases {
                let currentValue = current.hands[seat]?[suit] ?? ""
                if !manuallyEditedFields.contains(.hand(seat: seat, suit: suit)),
                   currentValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let recognizedValue = candidate.hands[seat]?[suit] {
                    merged.hands[seat, default: [:]][suit] = recognizedValue
                }
            }
        }

        // Recognition can never decide what the player knew at the chosen time.
        merged.decisionTimeVisibleSeats = current.decisionTimeVisibleSeats ?? []
        merged.decisionTimeConfirmed = false
        return merged
    }

    private func recordManualEdits(from current: DeclarerPlanDraft, to draft: DeclarerPlanDraft) {
        if current.vulnerability != draft.vulnerability { manuallyEditedFields.insert(.vulnerability) }
        if current.auction != draft.auction { manuallyEditedFields.insert(.auction) }
        if current.declarerSeat != draft.declarerSeat { manuallyEditedFields.insert(.declarerSeat) }
        if current.contractLevel != draft.contractLevel { manuallyEditedFields.insert(.contractLevel) }
        if current.contractStrain != draft.contractStrain { manuallyEditedFields.insert(.contractStrain) }
        if current.openingLead != draft.openingLead { manuallyEditedFields.insert(.openingLead) }
        if current.otherDecisionTimeFacts != draft.otherDecisionTimeFacts { manuallyEditedFields.insert(.otherDecisionTimeFacts) }

        for seat in Seat.allCases {
            for suit in Suit.allCases {
                let currentValue = current.hands[seat]?[suit] ?? ""
                let editedValue = draft.hands[seat]?[suit] ?? ""
                if currentValue != editedValue {
                    manuallyEditedFields.insert(.hand(seat: seat, suit: suit))
                }
            }
        }
    }

    private func inferManualEdits(from candidate: ScreenshotRecognitionCandidate?, draft: DeclarerPlanDraft) {
        guard let candidate else { return }

        if let value = candidate.vulnerability, draft.vulnerability != value {
            manuallyEditedFields.insert(.vulnerability)
        }
        if let value = candidate.auction, draft.auction != value.auctionRecord {
            manuallyEditedFields.insert(.auction)
        }
        if let value = candidate.declarerSeat, draft.declarerSeat != value {
            manuallyEditedFields.insert(.declarerSeat)
        }
        if let value = candidate.contractLevel, draft.contractLevel != value {
            manuallyEditedFields.insert(.contractLevel)
        }
        if let value = candidate.contractStrain, draft.contractStrain != value {
            manuallyEditedFields.insert(.contractStrain)
        }
        if let value = candidate.openingLead, draft.openingLead != value {
            manuallyEditedFields.insert(.openingLead)
        }
        if draft.otherDecisionTimeFacts != candidate.otherDecisionTimeFacts {
            manuallyEditedFields.insert(.otherDecisionTimeFacts)
        }
        for seat in Seat.allCases {
            for suit in Suit.allCases {
                guard let value = candidate.hands[seat]?[suit], draft.hands[seat]?[suit] != value else { continue }
                manuallyEditedFields.insert(.hand(seat: seat, suit: suit))
            }
        }
    }
}
