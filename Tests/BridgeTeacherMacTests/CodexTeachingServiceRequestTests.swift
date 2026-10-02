import Foundation
import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

final class CodexTeachingServiceRequestTests: XCTestCase {
    func testTeachingRequestUsesTheSelectedModelAndEffortAtTurnStart() async throws {
        let fixture = try makeService()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        try await configure(fixture)
        try await fixture.service.setRequestSelection(selection(.astra, .ultra))

        let response = try await fixture.service.generatePlan(for: makePlanRequest())

        let params = try XCTUnwrap(fixture.client.requests(for: "turn/start").last)
        XCTAssertEqual(params["model"] as? String, "gpt-6-astra")
        XCTAssertEqual(params["effort"] as? String, "ultra")
        XCTAssertEqual(response.requestedModel, "gpt-6-astra")
        XCTAssertEqual(response.reasoningEffort, "ultra")
        XCTAssertEqual(response.runtimeVersion, "codex-cli 0.156.1")
    }

    func testChangingSelectionDuringARequestOnlyChangesTheNextRequest() async throws {
        let fixture = try makeService()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        try await configure(fixture)
        try await fixture.service.setRequestSelection(selection(.luna, .medium))
        fixture.client.holdNextTurnStart()

        let runningRequest = Task {
            try await fixture.service.generatePlan(for: makePlanRequest())
        }
        await fixture.client.waitForHeldTurnStart()
        try await fixture.service.setRequestSelection(selection(.sol, .high))
        fixture.client.resumeHeldTurnStart()

        let response = try await runningRequest.value
        XCTAssertEqual(response.requestedModel, "gpt-6-luna")
        XCTAssertEqual(response.reasoningEffort, "medium")

        _ = try await fixture.service.generatePlan(for: makePlanRequest())
        let turnParams = fixture.client.requests(for: "turn/start")
        XCTAssertEqual(turnParams.map { $0["model"] as? String }, ["gpt-6-luna", "gpt-6.1-sol"])
        XCTAssertEqual(turnParams.map { $0["effort"] as? String }, ["medium", "high"])
    }

    func testScreenshotRecognitionUsesTheSelectedConfigurationAndRecordsIt() async throws {
        let screenshotReply = """
        {"hands":{"north":{"spades":"","hearts":"","diamonds":"","clubs":""},"east":{"spades":"","hearts":"","diamonds":"","clubs":""},"south":{"spades":"","hearts":"","diamonds":"","clubs":""},"west":{"spades":"","hearts":"","diamonds":"","clubs":""}},"vulnerability":"eastWest","auction":{"startingSeat":"north","entries":[{"seat":"north","action":"bid","level":1,"strain":"clubs"},{"seat":"east","action":"unknown","level":null,"strain":null}],"isPartial":false},"declarerSeat":null,"contractLevel":null,"contractStrain":null,"openingLead":null,"otherDecisionTimeFacts":"","notes":[]}
        """
        let fixture = try makeService(assistantReply: screenshotReply)
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        try await configure(fixture)
        try await fixture.service.setRequestSelection(selection(.sol, .high))
        let imageURL = fixture.root.appendingPathComponent("deal.png")
        try Data([0x89, 0x50, 0x4e, 0x47]).write(to: imageURL)

        let response = try await fixture.service.recognizeScreenshot(at: imageURL)

        let params = try XCTUnwrap(fixture.client.requests(for: "turn/start").last)
        XCTAssertEqual(params["model"] as? String, "gpt-6.1-sol")
        XCTAssertEqual(params["effort"] as? String, "high")
        XCTAssertEqual(response.requestedModel, "gpt-6.1-sol")
        XCTAssertEqual(response.reasoningEffort, "high")
        XCTAssertEqual(response.candidate.vulnerability, .eastWest)
        XCTAssertEqual(response.candidate.auction?.entries.map(\.auctionCall), [
            .bid(level: 1, strain: .clubs), .unknown,
        ])

        let outputSchema = try XCTUnwrap(params["outputSchema"] as? [String: Any])
        let required = try XCTUnwrap(outputSchema["required"] as? [String])
        XCTAssertTrue(required.contains("auction"))
        XCTAssertTrue(required.contains("vulnerability"))
        let properties = try XCTUnwrap(outputSchema["properties"] as? [String: Any])
        let auctionSchema = try XCTUnwrap(properties["auction"] as? [String: Any])
        let auctionRequired = try XCTUnwrap(auctionSchema["required"] as? [String])
        XCTAssertTrue(auctionRequired.contains("isPartial"))
        let auctionProperties = try XCTUnwrap(auctionSchema["properties"] as? [String: Any])
        let partialSchema = try XCTUnwrap(auctionProperties["isPartial"] as? [String: Any])
        XCTAssertEqual(partialSchema["type"] as? String, "boolean")
        let entriesSchema = try XCTUnwrap(auctionProperties["entries"] as? [String: Any])
        let entrySchema = try XCTUnwrap(entriesSchema["items"] as? [String: Any])
        let entryProperties = try XCTUnwrap(entrySchema["properties"] as? [String: Any])
        let actionSchema = try XCTUnwrap(entryProperties["action"] as? [String: Any])
        XCTAssertEqual(actionSchema["enum"] as? [String], ScreenshotAuctionAction.allCases.map(\.rawValue))
    }

    func testScreenshotRecognitionStopsWhenSelectedModelDoesNotAdvertiseImageInput() async throws {
        let fixture = try makeService()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        try await configure(fixture)
        try await fixture.service.setRequestSelection(selection(.astra, .medium))
        let imageURL = fixture.root.appendingPathComponent("deal.png")
        try Data([0x89, 0x50, 0x4e, 0x47]).write(to: imageURL)

        do {
            _ = try await fixture.service.recognizeScreenshot(at: imageURL)
            XCTFail("Screenshot recognition should be blocked for a text-only model.")
        } catch let error as CodexRuntimeSetupError {
            XCTAssertEqual(error, .imageInputNotSupported)
        }
        XCTAssertTrue(fixture.client.requests(for: "thread/start").isEmpty)
    }

    func testFollowUpRequestUsesTheCurrentSelection() async throws {
        let fixture = try makeService()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        try await configure(fixture)
        try await fixture.service.setRequestSelection(selection(.astra, .xhigh))
        let context = try makePlanRequest()
        let plan = DeclarerPlanAnalysis(
            requestID: context.requestID,
            informationVersion: context.informationVersion,
            response: DeclarerPlanResponse(text: "上一次的计划")
        )
        let followUp = DeclarerFollowUpRequest(
            requestID: UUID(),
            informationVersion: context.informationVersion,
            planID: plan.id,
            context: context,
            currentPlan: plan,
            priorExchanges: [],
            question: "为什么先处理将牌？",
            assumptions: nil,
            prompt: "回答追问"
        )

        let response = try await fixture.service.respondToFollowUp(followUp)

        let params = try XCTUnwrap(fixture.client.requests(for: "turn/start").last)
        XCTAssertEqual(params["model"] as? String, "gpt-6-astra")
        XCTAssertEqual(params["effort"] as? String, "xhigh")
        XCTAssertEqual(response.requestedModel, "gpt-6-astra")
        XCTAssertEqual(response.reasoningEffort, "xhigh")
    }

    func testUnavailableOrLegacySelectionIsRejectedBeforeAnyRequest() async throws {
        let fixture = try makeService()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        try await configure(fixture)
        for choice in [
            CodexModelSelection(family: .sol, modelIdentifier: "gpt-6-sol", effort: .high),
            selection(.astra, .max),
        ] {
            do {
                try await fixture.service.setRequestSelection(choice)
                XCTFail("Unavailable selection must not be applied.")
            } catch let error as CodexRuntimeSetupError {
                XCTAssertEqual(error, .modelConfigurationUnavailable)
            }
        }
        XCTAssertTrue(fixture.client.requests(for: "thread/start").isEmpty)
    }

    func testCatalogRefreshInvalidatesSavedRequestConfiguration() async throws {
        let fixture = try makeService()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        try await configure(fixture)
        try await fixture.service.setRequestSelection(selection(.astra, .ultra))
        fixture.client.useUnavailableCatalog()
        _ = try await fixture.service.listRuntimeModels()
        do {
            _ = try await fixture.service.generatePlan(for: makePlanRequest())
            XCTFail("A selection removed from the refreshed catalog must be blocked.")
        } catch let error as CodexRuntimeSetupError {
            XCTAssertEqual(error, .modelConfigurationUnavailable)
        }
        XCTAssertTrue(fixture.client.requests(for: "thread/start").isEmpty)
    }

    func testRuntimeModelOrEffortMismatchCannotBecomeASuccessfulTeachingResult() async throws {
        for (model, effort) in [("gpt-6-sol", nil), (nil, "medium")] as [(String?, String?)] {
            let fixture = try makeService(reportedTurnModel: model, reportedTurnEffort: effort)
            defer { try? FileManager.default.removeItem(at: fixture.root) }
            try await configure(fixture)
            try await fixture.service.setRequestSelection(selection(.astra, .ultra))
            do {
                _ = try await fixture.service.generatePlan(for: makePlanRequest())
                XCTFail("A different runtime configuration must be reported as a failure.")
            } catch let error as CodexRuntimeSetupError {
                guard case .request(let message) = error else { return XCTFail("Unexpected error: \(error)") }
                XCTAssertTrue(message.contains("不同"))
            }
        }
    }

    func testAbsentRuntimeModelDoesNotInventAnEffectiveModelIdentity() async throws {
        let fixture = try makeService(reportsThreadModel: false)
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        try await configure(fixture)
        try await fixture.service.setRequestSelection(selection(.astra, .ultra))
        let response = try await fixture.service.generatePlan(for: makePlanRequest())
        XCTAssertNil(response.model)
        XCTAssertEqual(response.requestedModel, "gpt-6-astra")
        XCTAssertEqual(response.reasoningEffort, "ultra")
    }

    private func configure(_ fixture: (service: CodexTeachingService, client: FakeCodexRPCClient, root: URL)) async throws {
        let executable = fixture.root.appendingPathComponent("codex")
        try "#!/bin/sh\nprintf 'codex-cli 0.156.1\\n'\n".write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        _ = try await fixture.service.configure(executableURL: executable)
        let signedIn = try await fixture.service.isChatGPTSignedIn()
        let models = try await fixture.service.listRuntimeModels()
        XCTAssertTrue(signedIn)
        XCTAssertEqual(models.count, 3)
    }

    private func makeService(
        assistantReply: String = "计划已根据当前请求生成。",
        reportedTurnModel: String? = nil,
        reportedTurnEffort: String? = nil,
        reportsThreadModel: Bool = true
    ) throws -> (
        service: CodexTeachingService,
        client: FakeCodexRPCClient,
        root: URL
    ) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("Bridge-Service-Test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let client = FakeCodexRPCClient(
            assistantReply: assistantReply,
            reportedTurnModel: reportedTurnModel,
            reportedTurnEffort: reportedTurnEffort,
            reportsThreadModel: reportsThreadModel
        )
        let appSupport = root.appendingPathComponent("Application Support", isDirectory: true)
        let service = CodexTeachingService(appSupportURL: appSupport) { _, _, _ in client }
        return (service, client, root)
    }

    private func makePlanRequest() throws -> DeclarerPlanRequest {
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 4
        draft.contractStrain = .hearts
        draft.hands[.south] = [.spades: "AK"]
        return try DeclarerPlanRequestBuilder.build(from: draft)
    }

    private func selection(_ family: CodexModelFamily, _ effort: CodexReasoningEffort) -> CodexModelSelection {
        CodexModelSelection(family: family, modelIdentifier: family.modelIdentifier, effort: effort)
    }
}

private final class FakeCodexRPCClient: CodexRPCClientProtocol, @unchecked Sendable {
    private struct HeldTurn {
        let continuation: CheckedContinuation<[String: Any], Error>
        let threadID: String
        let turnID: String
        let reply: String
    }

    private let lock = NSLock()
    private let assistantReply: String
    private let reportedTurnModel: String?
    private let reportedTurnEffort: String?
    private let reportsThreadModel: Bool
    private var unavailableCatalog = false
    private let notificationStream: AsyncStream<CodexServerNotification>
    private var notificationContinuation: AsyncStream<CodexServerNotification>.Continuation!
    private var requestLog: [(String, [String: Any])] = []
    private var turnStartWaiters: [CheckedContinuation<Void, Never>] = []
    private var shouldHoldNextTurnStart = false
    private var heldTurn: HeldTurn?
    private var nextThreadNumber = 1
    private var nextTurnNumber = 1

    init(assistantReply: String, reportedTurnModel: String?, reportedTurnEffort: String?, reportsThreadModel: Bool) {
        self.assistantReply = assistantReply
        self.reportedTurnModel = reportedTurnModel
        self.reportedTurnEffort = reportedTurnEffort
        self.reportsThreadModel = reportsThreadModel
        var savedContinuation: AsyncStream<CodexServerNotification>.Continuation!
        notificationStream = AsyncStream { streamContinuation in
            savedContinuation = streamContinuation
        }
        notificationContinuation = savedContinuation
    }

    func start() throws {}
    func stop() {}
    func notify(_ method: String, params: [String: Any]) throws {}
    func notifications() -> AsyncStream<CodexServerNotification> { notificationStream }

    func request(_ method: String, params: [String: Any]) async throws -> [String: Any] {
        switch method {
        case "initialize":
            return [:]
        case "account/read":
            return ["account": ["type": "chatgpt"]]
        case "model/list":
            return modelCatalog
        case "thread/start":
            let threadID = "thread-\(nextThreadNumber)"
            nextThreadNumber += 1
            let model = params["model"] as? String
            record(method, params)
            if reportsThreadModel {
                return ["thread": ["id": threadID, "model": model as Any], "model": model as Any]
            }
            return ["thread": ["id": threadID]]
        case "turn/start":
            record(method, params)
            let threadID = params["threadId"] as? String ?? "thread-unknown"
            let turnID = "turn-\(nextTurnNumber)"
            nextTurnNumber += 1
            let shouldHold = consumeHoldFlag()
            if shouldHold {
                return try await withCheckedThrowingContinuation { continuation in
                    lock.lock()
                    heldTurn = HeldTurn(continuation: continuation, threadID: threadID, turnID: turnID, reply: assistantReply)
                    let waiters = turnStartWaiters
                    turnStartWaiters.removeAll()
                    lock.unlock()
                    waiters.forEach { $0.resume() }
                }
            }
            let waiters = takeTurnStartWaiters()
            waiters.forEach { $0.resume() }
            finishTurn(threadID: threadID, turnID: turnID, reply: assistantReply)
            return ["turn": ["id": turnID]]
        default:
            return [:]
        }
    }

    func useUnavailableCatalog() {
        lock.lock()
        unavailableCatalog = true
        lock.unlock()
    }

    func holdNextTurnStart() {
        lock.lock()
        shouldHoldNextTurnStart = true
        lock.unlock()
    }

    func waitForHeldTurnStart() async {
        await withCheckedContinuation { continuation in
            lock.lock()
            if heldTurn != nil {
                lock.unlock()
                continuation.resume()
            } else {
                turnStartWaiters.append(continuation)
                lock.unlock()
            }
        }
    }

    func resumeHeldTurnStart() {
        lock.lock()
        let held = heldTurn
        heldTurn = nil
        lock.unlock()
        guard let held else { return }
        held.continuation.resume(returning: ["turn": ["id": held.turnID]])
        finishTurn(threadID: held.threadID, turnID: held.turnID, reply: held.reply)
    }

    func requests(for method: String) -> [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        return requestLog.filter { $0.0 == method }.map(\.1)
    }

    private func record(_ method: String, _ params: [String: Any]) {
        lock.lock()
        requestLog.append((method, params))
        lock.unlock()
    }

    private func consumeHoldFlag() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let shouldHold = shouldHoldNextTurnStart
        shouldHoldNextTurnStart = false
        return shouldHold
    }

    private func takeTurnStartWaiters() -> [CheckedContinuation<Void, Never>] {
        lock.lock()
        defer { lock.unlock() }
        let waiters = turnStartWaiters
        turnStartWaiters.removeAll()
        return waiters
    }

    private func finishTurn(threadID: String, turnID: String, reply: String) {
        var turn: [String: Any] = [
            "id": turnID,
            "status": "completed",
            "items": [["type": "agentMessage", "text": reply]],
        ]
        if let reportedTurnModel { turn["model"] = reportedTurnModel }
        if let reportedTurnEffort { turn["effort"] = reportedTurnEffort }
        notificationContinuation.yield(CodexServerNotification(
            method: "turn/completed",
            params: [
                "threadId": threadID,
                "turn": turn,
            ]
        ))
    }

    private var modelCatalog: [String: Any] {
        lock.lock()
        defer { lock.unlock() }
        if unavailableCatalog {
            return ["data": [[
                "model": "gpt-6-luna", "displayName": "GPT-6 Luna",
                "supportedReasoningEfforts": [["reasoningEffort": "medium"]],
                "inputModalities": ["text"],
            ]]]
        }
        return [
            "data": [
                [
                    "id": "luna-picker-id", "model": "gpt-6-luna", "displayName": "GPT-6 Luna",
                    "supportedReasoningEfforts": [["reasoningEffort": "low"], ["reasoningEffort": "medium"], ["reasoningEffort": "high"], ["reasoningEffort": "max"], ["reasoningEffort": "ultra"]],
                    "defaultReasoningEffort": "medium", "inputModalities": ["text", "image"],
                ],
                [
                    "id": "sol-picker-id", "model": "gpt-6.1-sol", "displayName": "GPT-6 Sol",
                    "supportedReasoningEfforts": [["reasoningEffort": "low"], ["reasoningEffort": "medium"], ["reasoningEffort": "high"]],
                    "defaultReasoningEffort": "medium", "inputModalities": ["text", "image"],
                ],
                [
                    "id": "astra-picker-id", "model": "gpt-6-astra", "displayName": "GPT-6 Astra",
                    "supportedReasoningEfforts": [["reasoningEffort": "medium"], ["reasoningEffort": "high"], ["reasoningEffort": "xhigh"], ["reasoningEffort": "ultra"]],
                    "defaultReasoningEffort": "high", "inputModalities": ["text"],
                ],
            ],
        ]
    }
}
