import Foundation

public struct DeclarerPlanWorkflowArchive: Codable, Equatable, Sendable {
    public let draft: DeclarerPlanDraft
    public let state: PlanGenerationState
    public let informationVersion: Int
    public let planAnalyses: [DeclarerPlanAnalysis]
    public let currentPlanID: UUID?
    public let followUpExchanges: [DeclarerFollowUpExchange]
    public let followUpQuestion: String
    public let followUpAssumptions: String

    public init(
        draft: DeclarerPlanDraft,
        state: PlanGenerationState,
        informationVersion: Int,
        planAnalyses: [DeclarerPlanAnalysis],
        currentPlanID: UUID?,
        followUpExchanges: [DeclarerFollowUpExchange],
        followUpQuestion: String,
        followUpAssumptions: String
    ) {
        self.draft = draft
        self.state = state
        self.informationVersion = informationVersion
        self.planAnalyses = planAnalyses
        self.currentPlanID = currentPlanID
        self.followUpExchanges = followUpExchanges
        self.followUpQuestion = followUpQuestion
        self.followUpAssumptions = followUpAssumptions
    }
}

public struct ScreenshotReviewWorkflowArchive: Codable, Equatable, Sendable {
    public let state: ScreenshotRecognitionState
    public let candidate: ScreenshotRecognitionCandidate?
    public let response: ScreenshotRecognitionResponse?
    public let sourceFilename: String?

    public init(
        state: ScreenshotRecognitionState,
        candidate: ScreenshotRecognitionCandidate?,
        response: ScreenshotRecognitionResponse?,
        sourceFilename: String? = nil
    ) {
        self.state = state
        self.candidate = candidate
        self.response = response
        self.sourceFilename = sourceFilename
    }
}

public struct KeyPlayAnalysisWorkflowArchive: Codable, Equatable, Sendable {
    public let draft: KeyPlayAnalysisDraft
    public let state: PlanGenerationState
    public let result: DeclarerPlanResponse?
    public let resultIsOutdated: Bool
    public let resultInformationVersion: Int?

    public init(
        draft: KeyPlayAnalysisDraft,
        state: PlanGenerationState,
        result: DeclarerPlanResponse?,
        resultIsOutdated: Bool,
        resultInformationVersion: Int?
    ) {
        self.draft = draft
        self.state = state
        self.result = result
        self.resultIsOutdated = resultIsOutdated
        self.resultInformationVersion = resultInformationVersion
    }
}

public struct DoubleDummyVerificationWorkflowArchive: Codable, Equatable, Sendable {
    public let draft: DoubleDummyVerificationDraft
    public let state: DoubleDummyVerificationState
    public let result: DoubleDummyVerificationResult?
    public let hasOutdatedResult: Bool

    public init(
        draft: DoubleDummyVerificationDraft,
        state: DoubleDummyVerificationState,
        result: DoubleDummyVerificationResult?,
        hasOutdatedResult: Bool
    ) {
        self.draft = draft
        self.state = state
        self.result = result
        self.hasOutdatedResult = hasOutdatedResult
    }
}

public struct ReviewSessionSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public let createdAt: Date
    public var teachingMode: TeachingMode
    public var declarerPlan: DeclarerPlanWorkflowArchive
    public var screenshot: ScreenshotReviewWorkflowArchive
    public var keyPlay: KeyPlayAnalysisWorkflowArchive
    public var doubleDummy: DoubleDummyVerificationWorkflowArchive
    public var screenshotAssetName: String?

    public init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        teachingMode: TeachingMode,
        declarerPlan: DeclarerPlanWorkflowArchive,
        screenshot: ScreenshotReviewWorkflowArchive,
        keyPlay: KeyPlayAnalysisWorkflowArchive,
        doubleDummy: DoubleDummyVerificationWorkflowArchive,
        screenshotAssetName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.teachingMode = teachingMode
        self.declarerPlan = declarerPlan
        self.screenshot = screenshot
        self.keyPlay = keyPlay
        self.doubleDummy = doubleDummy
        self.screenshotAssetName = screenshotAssetName
    }
}

public struct ReviewSessionListItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let createdAt: Date
    public let teachingMode: TeachingMode

    public init(snapshot: ReviewSessionSnapshot) {
        id = snapshot.id
        title = snapshot.title
        createdAt = snapshot.createdAt
        teachingMode = snapshot.teachingMode
    }
}

public struct OpenedReviewSession: Equatable, Sendable {
    public let snapshot: ReviewSessionSnapshot
    public let screenshotURL: URL?

    public init(snapshot: ReviewSessionSnapshot, screenshotURL: URL?) {
        self.snapshot = snapshot
        self.screenshotURL = screenshotURL
    }
}

public enum ReviewSessionStoreError: Error, LocalizedError, Equatable, Sendable {
    case recordNotFound
    case corruptRecord(String)
    case missingScreenshot
    case invalidScreenshotReference
    case writeFailed(String)
    case readFailed(String)

    public var errorDescription: String? {
        switch self {
        case .recordNotFound:
            "找不到这份本地复盘。"
        case let .corruptRecord(reason):
            "本地复盘无法读取：\(reason)"
        case .missingScreenshot:
            "这份复盘引用的原始截图不在本机；为避免打开不完整记录，已保留当前复盘。"
        case .invalidScreenshotReference:
            "复盘中的截图文件名无效，已拒绝读取该记录。"
        case let .writeFailed(reason):
            "本地复盘保存失败；当前复盘仍保留。\(reason)"
        case let .readFailed(reason):
            "本地复盘读取失败；当前复盘仍保留。\(reason)"
        }
    }
}

/// Stores review snapshots and their original screenshots only in the local Application Support folder.
public struct LocalReviewSessionStore {
    public let directoryURL: URL
    private let fileManager: FileManager

    public init(directoryURL: URL? = nil, fileManager: FileManager = .default) {
        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent(
                    "Library/Application Support",
                    isDirectory: true
                )
            self.directoryURL = supportDirectory
                .appendingPathComponent("Bridge Teacher", isDirectory: true)
                .appendingPathComponent("Reviews", isDirectory: true)
        }
        self.fileManager = fileManager
    }

    @discardableResult
    public func save(_ snapshot: ReviewSessionSnapshot, screenshotURL: URL?) throws -> ReviewSessionSnapshot {
        let recordsDirectory = directoryURL
        let assetsDirectory = recordsDirectory.appendingPathComponent("Assets", isDirectory: true)
        do {
            try fileManager.createDirectory(at: recordsDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)
        } catch {
            throw ReviewSessionStoreError.writeFailed(error.localizedDescription)
        }

        let manifestURL = recordURL(for: snapshot.id)
        let previousSnapshot: ReviewSessionSnapshot?
        if fileManager.fileExists(atPath: manifestURL.path) {
            do {
                previousSnapshot = try JSONDecoder().decode(ReviewSessionSnapshot.self, from: Data(contentsOf: manifestURL))
            } catch {
                throw ReviewSessionStoreError.corruptRecord(error.localizedDescription)
            }
        } else {
            previousSnapshot = nil
        }

        var storedSnapshot = ReviewSessionSnapshot(
            id: snapshot.id,
            title: snapshot.title,
            createdAt: previousSnapshot?.createdAt ?? snapshot.createdAt,
            teachingMode: snapshot.teachingMode,
            declarerPlan: snapshot.declarerPlan,
            screenshot: snapshot.screenshot,
            keyPlay: snapshot.keyPlay,
            doubleDummy: snapshot.doubleDummy,
            screenshotAssetName: snapshot.screenshotAssetName
        )
        var newAssetName: String?
        if let screenshotURL {
            do {
                let name = try copyScreenshot(screenshotURL, to: assetsDirectory)
                newAssetName = name
                storedSnapshot.screenshotAssetName = name
            } catch {
                throw ReviewSessionStoreError.writeFailed(error.localizedDescription)
            }
        } else if storedSnapshot.screenshotAssetName == nil {
            storedSnapshot.screenshotAssetName = previousSnapshot?.screenshotAssetName
        }

        if let assetName = storedSnapshot.screenshotAssetName, !isSafeAssetName(assetName) {
            if let newAssetName { try? fileManager.removeItem(at: assetsDirectory.appendingPathComponent(newAssetName)) }
            throw ReviewSessionStoreError.invalidScreenshotReference
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let encoded = try encoder.encode(storedSnapshot)
            try encoded.write(to: manifestURL, options: .atomic)
        } catch {
            if let newAssetName { try? fileManager.removeItem(at: assetsDirectory.appendingPathComponent(newAssetName)) }
            throw ReviewSessionStoreError.writeFailed(error.localizedDescription)
        }

        if let previousAsset = previousSnapshot?.screenshotAssetName,
           previousAsset != storedSnapshot.screenshotAssetName,
           isSafeAssetName(previousAsset) {
            try? fileManager.removeItem(at: assetsDirectory.appendingPathComponent(previousAsset))
        }
        return storedSnapshot
    }

    public func open(id: UUID) throws -> OpenedReviewSession {
        let manifestURL = recordURL(for: id)
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw ReviewSessionStoreError.recordNotFound
        }
        let snapshot: ReviewSessionSnapshot
        do {
            snapshot = try JSONDecoder().decode(ReviewSessionSnapshot.self, from: Data(contentsOf: manifestURL))
        } catch {
            throw ReviewSessionStoreError.readFailed(error.localizedDescription)
        }
        guard snapshot.id == id else {
            throw ReviewSessionStoreError.corruptRecord("记录编号与文件名不一致。")
        }

        let screenshotURL: URL?
        if let assetName = snapshot.screenshotAssetName {
            guard isSafeAssetName(assetName) else { throw ReviewSessionStoreError.invalidScreenshotReference }
            let resolvedURL = directoryURL.appendingPathComponent("Assets", isDirectory: true).appendingPathComponent(assetName)
            guard fileManager.fileExists(atPath: resolvedURL.path) else { throw ReviewSessionStoreError.missingScreenshot }
            screenshotURL = resolvedURL
        } else {
            screenshotURL = nil
        }
        return OpenedReviewSession(snapshot: snapshot, screenshotURL: screenshotURL)
    }

    public func list() throws -> [ReviewSessionListItem] {
        guard fileManager.fileExists(atPath: directoryURL.path) else { return [] }
        let urls: [URL]
        do {
            urls = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension.lowercased() == "json" }
        } catch {
            throw ReviewSessionStoreError.readFailed(error.localizedDescription)
        }

        do {
            return try urls.map { url in
                let snapshot = try JSONDecoder().decode(ReviewSessionSnapshot.self, from: Data(contentsOf: url))
                return ReviewSessionListItem(snapshot: snapshot)
            }.sorted { $0.createdAt > $1.createdAt }
        } catch {
            throw ReviewSessionStoreError.readFailed(error.localizedDescription)
        }
    }

    private func recordURL(for id: UUID) -> URL {
        directoryURL.appendingPathComponent("\(id.uuidString.lowercased()).json", isDirectory: false)
    }

    private func copyScreenshot(_ sourceURL: URL, to assetsDirectory: URL) throws -> String {
        let sourceExtension = sourceURL.pathExtension.lowercased()
        let safeExtension = sourceExtension.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) }
            ? sourceExtension
            : ""
        let name = "\(UUID().uuidString.lowercased()).\(safeExtension.isEmpty ? "image" : safeExtension)"
        let destination = assetsDirectory.appendingPathComponent(name, isDirectory: false)
        let temporary = assetsDirectory.appendingPathComponent(".\(UUID().uuidString.lowercased()).partial", isDirectory: false)
        do {
            try fileManager.copyItem(at: sourceURL, to: temporary)
            try fileManager.moveItem(at: temporary, to: destination)
            return name
        } catch {
            try? fileManager.removeItem(at: temporary)
            throw error
        }
    }

    private func isSafeAssetName(_ name: String) -> Bool {
        !name.isEmpty
            && name != "."
            && name != ".."
            && URL(fileURLWithPath: name).lastPathComponent == name
            && !name.contains("/")
            && !name.contains("\\")
    }
}
