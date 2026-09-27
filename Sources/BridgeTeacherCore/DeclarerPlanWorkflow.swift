import Combine
import Foundation

public struct DeclarerPlanResponse: Codable, Equatable, Sendable {
    public let text: String
    public let model: String?
    public let runtimeVersion: String?
    public let requestedModel: String?
    public let reasoningEffort: String?

    public init(
        text: String,
        model: String? = nil,
        runtimeVersion: String? = nil,
        requestedModel: String? = nil,
        reasoningEffort: String? = nil
    ) {
        self.text = text
        self.model = model
        self.runtimeVersion = runtimeVersion
        self.requestedModel = requestedModel
        self.reasoningEffort = reasoningEffort
    }
}

public protocol DeclarerTeachingRuntime: Sendable {
    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse
    func respondToFollowUp(_ request: DeclarerFollowUpRequest) async throws -> DeclarerPlanResponse
}

public enum PlanGenerationState: Codable, Equatable, Sendable {
    case idle
    case invalid(String)
    case generating
    case succeeded
    case failed(String)

    public var message: String? {
        switch self {
        case .idle, .generating, .succeeded:
            nil
        case let .invalid(message), let .failed(message):
            message
        }
    }
}

public enum PlanRuntimeError: Error, Equatable, LocalizedError, Sendable {
    case runtimeNotFound
    case unsupportedRuntime(found: String, minimum: String)
    case chatGPTSignInRequired
    case temporarilyUnavailable
    case usageLimited(String)
    case requestFailed(String)
    case timedOut
    case emptyResponse

    public var errorDescription: String? {
        switch self {
        case .runtimeNotFound:
            "找不到 Codex runtime。请先安装 Codex CLI，或在设置中选择 codex 可执行文件。"
        case let .unsupportedRuntime(found, minimum):
            "当前 Codex runtime 版本为 \(found)，此应用需要 \(minimum) 或更高版本。"
        case .chatGPTSignInRequired:
            "尚未通过 ChatGPT 登录。请先连接账号，再生成做庄计划。"
        case .temporarilyUnavailable:
            "Codex 当前暂不可用，请检查网络或稍后重试。"
        case let .usageLimited(message):
            "ChatGPT 账号当前额度或速率受限：\(message)"
        case let .requestFailed(message):
            "Codex 请求失败：\(message)"
        case .timedOut:
            "等待 Codex 响应超时；你的输入已保留，可以重试。"
        case .emptyResponse:
            "Codex 没有返回可显示的教学内容，请重试。"
        }
    }
}

@MainActor
public final class DeclarerPlanWorkflow: ObservableObject {
    @Published public private(set) var draft: DeclarerPlanDraft
    @Published public private(set) var state: PlanGenerationState = .idle
    @Published public private(set) var informationVersion = 0
    @Published public private(set) var planAnalyses: [DeclarerPlanAnalysis] = []
    @Published public private(set) var followUpExchanges: [DeclarerFollowUpExchange] = []
    @Published public private(set) var followUpQuestion = ""
    @Published public private(set) var followUpAssumptions = ""

    private let runtime: any DeclarerTeachingRuntime
    private var currentPlanID: UUID?
    private var failedPlanRequest: DeclarerPlanRequest?
    private var planOperationRevision = 0
    private var followUpOperationRevision = 0

    public var result: DeclarerPlanResponse? { planAnalyses.last?.response }

    public var resultIsOutdated: Bool {
        guard let latest = planAnalyses.last else { return false }
        return latest.informationVersion != informationVersion
    }

    public var isSendingFollowUp: Bool {
        followUpExchanges.contains { $0.status == .sending }
    }

    public func makeArchive() -> DeclarerPlanWorkflowArchive {
        DeclarerPlanWorkflowArchive(
            draft: draft,
            state: state,
            informationVersion: informationVersion,
            planAnalyses: planAnalyses,
            currentPlanID: currentPlanID,
            followUpExchanges: followUpExchanges,
            followUpQuestion: followUpQuestion,
            followUpAssumptions: followUpAssumptions
        )
    }

    public var canFollowUp: Bool {
        guard let plan = currentPlan,
              plan.informationVersion == informationVersion,
              !resultIsOutdated,
              state != .generating,
              !isSendingFollowUp else { return false }
        return true
    }

    private var currentPlan: DeclarerPlanAnalysis? {
        guard let currentPlanID else { return nil }
        return planAnalyses.last(where: { $0.id == currentPlanID })
    }

    public init(draft: DeclarerPlanDraft = DeclarerPlanDraft(), runtime: any DeclarerTeachingRuntime) {
        self.draft = draft.normalizingOpeningLead()
        self.runtime = runtime
    }

    public func updateDraft(_ draft: DeclarerPlanDraft) {
        let normalizedDraft = draft.normalizingOpeningLead()
        guard normalizedDraft != self.draft else { return }
        self.draft = normalizedDraft
        informationVersion += 1
        planOperationRevision += 1
        invalidatePendingFollowUps()
        failedPlanRequest = nil
        if state == .generating {
            state = .idle
        }
    }

    public func markCurrentResultOutdated() {
        informationVersion += 1
        planOperationRevision += 1
        invalidatePendingFollowUps()
        failedPlanRequest = nil
        if state == .generating {
            state = .idle
        }
    }

    public func generatePlan() async {
        guard state != .generating else { return }
        let request: DeclarerPlanRequest
        if let failedPlanRequest, failedPlanRequest.informationVersion == informationVersion, case .failed = state {
            request = failedPlanRequest
        } else {
            do {
                request = try DeclarerPlanRequestBuilder.build(
                    from: draft,
                    informationVersion: informationVersion
                )
            } catch {
                state = .invalid(error.localizedDescription)
                return
            }
        }

        planOperationRevision += 1
        let operationRevision = planOperationRevision
        let requestedVersion = informationVersion
        state = .generating

        do {
            let response = try await runtime.generatePlan(for: request)
            guard planOperationRevision == operationRevision,
                  informationVersion == requestedVersion else { return }
            let analysis = DeclarerPlanAnalysis(
                requestID: request.requestID,
                informationVersion: request.informationVersion,
                response: response
            )
            invalidatePendingFollowUps()
            planAnalyses.append(analysis)
            currentPlanID = analysis.id
            failedPlanRequest = nil
            state = .succeeded
        } catch {
            guard planOperationRevision == operationRevision,
                  informationVersion == requestedVersion else { return }
            failedPlanRequest = request
            state = .failed(error.localizedDescription)
        }
    }

    public func setFollowUpQuestion(_ question: String) {
        followUpQuestion = question
    }

    public func setFollowUpAssumptions(_ assumptions: String) {
        followUpAssumptions = assumptions
    }

    public func sendFollowUp() async {
        guard canFollowUp,
              let plan = currentPlan else { return }
        let question = followUpQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        let assumptions = followUpAssumptions.trimmingCharacters(in: .whitespacesAndNewlines)

        if followUpExchanges.contains(where: { exchange in
            exchange.planID == plan.id
                && exchange.informationVersion == informationVersion
                && exchange.question == question
                && exchange.assumptions == (assumptions.isEmpty ? nil : assumptions)
                && isFailed(exchange.status)
        }) {
            return
        }

        let exchange = DeclarerFollowUpExchange(
            informationVersion: informationVersion,
            planID: plan.id,
            question: question,
            assumptions: assumptions.isEmpty ? nil : assumptions,
            status: .sending
        )
        followUpExchanges.append(exchange)
        await runFollowUp(exchangeID: exchange.id, plan: plan)
    }

    public func retryFollowUp(_ exchangeID: UUID) async {
        guard canFollowUp,
              let plan = currentPlan,
              let index = followUpExchanges.firstIndex(where: { $0.id == exchangeID }),
              isRetryable(followUpExchanges[index], for: plan) else { return }
        followUpExchanges[index].status = .sending
        await runFollowUp(exchangeID: exchangeID, plan: plan)
    }

    public func isOutdated(_ plan: DeclarerPlanAnalysis) -> Bool {
        plan.informationVersion != informationVersion
    }

    public func isOutdated(_ exchange: DeclarerFollowUpExchange) -> Bool {
        exchange.informationVersion != informationVersion || exchange.planID != currentPlanID
    }

    public func restore(from archive: DeclarerPlanWorkflowArchive) {
        draft = archive.draft.normalizingOpeningLead()
        state = archive.state == .generating ? .idle : archive.state
        informationVersion = archive.informationVersion
        planAnalyses = archive.planAnalyses
        currentPlanID = archive.currentPlanID
        followUpExchanges = archive.followUpExchanges.map { exchange in
            var restored = exchange
            if restored.status == .sending {
                restored.status = .failed("应用关闭前这次追问尚未完成，可以重新发送。")
            }
            return restored
        }
        followUpQuestion = archive.followUpQuestion
        followUpAssumptions = archive.followUpAssumptions
        failedPlanRequest = nil
        planOperationRevision += 1
        followUpOperationRevision += 1
    }

    public func canRetry(_ exchange: DeclarerFollowUpExchange) -> Bool {
        guard let plan = currentPlan else { return false }
        return isRetryable(exchange, for: plan) && canFollowUp
    }

    private func invalidatePendingFollowUps() {
        followUpOperationRevision += 1
        for index in followUpExchanges.indices where followUpExchanges[index].status == .sending {
            followUpExchanges[index].status = .outdated
        }
    }

    private func isRetryable(_ exchange: DeclarerFollowUpExchange, for plan: DeclarerPlanAnalysis) -> Bool {
        exchange.planID == plan.id
            && exchange.informationVersion == informationVersion
            && isFailed(exchange.status)
    }

    private func runFollowUp(exchangeID: UUID, plan: DeclarerPlanAnalysis) async {
        guard let index = followUpExchanges.firstIndex(where: { $0.id == exchangeID }) else { return }
        let exchange = followUpExchanges[index]
        let context: DeclarerPlanRequest
        let request: DeclarerFollowUpRequest
        do {
            context = try DeclarerPlanRequestBuilder.build(
                from: draft,
                informationVersion: informationVersion,
                requestID: plan.requestID
            )
            let previous = Array(followUpExchanges[..<index])
            request = try DeclarerFollowUpRequestBuilder.build(
                context: context,
                currentPlan: plan,
                priorExchanges: previous,
                question: exchange.question,
                assumptions: exchange.assumptions ?? "",
                requestID: exchange.id
            )
        } catch {
            followUpExchanges[index].status = .failed(error.localizedDescription)
            return
        }

        followUpOperationRevision += 1
        let operationRevision = followUpOperationRevision
        let requestedVersion = informationVersion
        do {
            let response = try await runtime.respondToFollowUp(request)
            guard followUpOperationRevision == operationRevision,
                  informationVersion == requestedVersion,
                  currentPlanID == plan.id,
                  let currentIndex = followUpExchanges.firstIndex(where: { $0.id == exchangeID }),
                  followUpExchanges[currentIndex].status == .sending else { return }
            followUpExchanges[currentIndex].status = .answered(response)
            if followUpQuestion.trimmingCharacters(in: .whitespacesAndNewlines) == exchange.question,
               followUpAssumptions.trimmingCharacters(in: .whitespacesAndNewlines) == (exchange.assumptions ?? "") {
                followUpQuestion = ""
                followUpAssumptions = ""
            }
        } catch {
            guard followUpOperationRevision == operationRevision,
                  informationVersion == requestedVersion,
                  currentPlanID == plan.id,
                  let currentIndex = followUpExchanges.firstIndex(where: { $0.id == exchangeID }),
                  followUpExchanges[currentIndex].status == .sending else { return }
            followUpExchanges[currentIndex].status = .failed(error.localizedDescription)
        }
    }

    private func isFailed(_ status: DeclarerFollowUpStatus) -> Bool {
        if case .failed = status { return true }
        return false
    }
}
