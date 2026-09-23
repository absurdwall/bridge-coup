import Combine
import Foundation

public enum ScreenshotRecognitionNoteKind: String, CaseIterable, Codable, Equatable, Sendable {
    case notShown
    case visibleButUnclear
    case ambiguous
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

/// Model output stays a candidate until the player checks the image and the decision point.
public struct ScreenshotRecognitionCandidate: Codable, Equatable, Sendable {
    public var hands: [Seat: [Suit: String]]
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
        notes: [ScreenshotRecognitionNote]
    ) {
        self.hands = hands
        self.declarerSeat = declarerSeat
        self.contractLevel = contractLevel
        self.contractStrain = contractStrain
        self.openingLead = openingLead
        self.otherDecisionTimeFacts = otherDecisionTimeFacts
        self.notes = notes
    }

    private enum CodingKeys: String, CodingKey {
        case hands
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

    public init(candidate: ScreenshotRecognitionCandidate, model: String? = nil, runtimeVersion: String? = nil) {
        self.candidate = candidate
        self.model = model
        self.runtimeVersion = runtimeVersion
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

    private let runtime: any ScreenshotRecognitionRuntime
    private var recognitionRevision = 0

    public func makeArchive() -> ScreenshotReviewWorkflowArchive {
        ScreenshotReviewWorkflowArchive(
            state: state,
            candidate: candidate,
            response: recognitionResponse,
            sourceFilename: screenshotFilename
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
    }

    public func selectScreenshot(at url: URL) {
        recognitionRevision += 1
        screenshotURL = url
        screenshotFilename = url.lastPathComponent
        state = .idle
        candidate = nil
        recognitionResponse = nil

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
        if state == .recognizing {
            recognitionRevision += 1
            state = .stale
        }
        planWorkflow.updateDraft(draft)
    }

    public func recognizeScreenshot() async {
        guard let screenshotURL else {
            state = .failed("请先导入一张截图。")
            return
        }

        recognitionRevision += 1
        let requestRevision = recognitionRevision
        state = .recognizing
        do {
            let response = try await runtime.recognizeScreenshot(at: screenshotURL)
            guard recognitionRevision == requestRevision,
                  self.screenshotURL == screenshotURL else { return }
            recognitionResponse = response
            candidate = response.candidate
            planWorkflow.updateDraft(Self.merge(response.candidate, into: planWorkflow.draft))
            state = .succeeded
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
        into current: DeclarerPlanDraft
    ) -> DeclarerPlanDraft {
        var merged = current

        if current.declarerSeat == nil, let recognizedSeat = candidate.declarerSeat {
            merged.declarerSeat = recognizedSeat
        }
        if current.contractLevel == nil {
            merged.contractLevel = candidate.contractLevel
        }
        if current.contractStrain == nil {
            merged.contractStrain = candidate.contractStrain
        }
        if current.openingLead.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let openingLead = candidate.openingLead {
            merged.openingLead = openingLead
        }
        if current.otherDecisionTimeFacts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merged.otherDecisionTimeFacts = candidate.otherDecisionTimeFacts
        }

        for seat in Seat.allCases {
            for suit in Suit.allCases {
                let currentValue = current.hands[seat]?[suit] ?? ""
                if currentValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
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
}
