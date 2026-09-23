import Combine
import Foundation

public struct DeclarerPlanResponse: Equatable, Sendable {
    public let text: String
    public let model: String?
    public let runtimeVersion: String?

    public init(text: String, model: String? = nil, runtimeVersion: String? = nil) {
        self.text = text
        self.model = model
        self.runtimeVersion = runtimeVersion
    }
}

public protocol DeclarerTeachingRuntime: Sendable {
    func generatePlan(for request: DeclarerPlanRequest) async throws -> DeclarerPlanResponse
}

public enum PlanGenerationState: Equatable, Sendable {
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
    @Published public private(set) var result: DeclarerPlanResponse?
    @Published public private(set) var resultIsOutdated = false

    private let runtime: any DeclarerTeachingRuntime
    private var revision = 0

    public init(draft: DeclarerPlanDraft = DeclarerPlanDraft(), runtime: any DeclarerTeachingRuntime) {
        self.draft = draft
        self.runtime = runtime
    }

    public func updateDraft(_ draft: DeclarerPlanDraft) {
        guard draft != self.draft else { return }
        self.draft = draft
        revision += 1
        if result != nil {
            resultIsOutdated = true
        }
        if state == .generating {
            state = .idle
        }
    }

    public func generatePlan() async {
        let request: DeclarerPlanRequest
        do {
            request = try DeclarerPlanRequestBuilder.build(from: draft)
        } catch let error as DeclarerPlanInputError {
            state = .invalid(error.localizedDescription)
            return
        } catch {
            state = .invalid(error.localizedDescription)
            return
        }

        revision += 1
        let requestRevision = revision
        state = .generating

        do {
            let response = try await runtime.generatePlan(for: request)
            guard revision == requestRevision else { return }
            result = response
            resultIsOutdated = false
            state = .succeeded
        } catch {
            guard revision == requestRevision else { return }
            state = .failed(error.localizedDescription)
        }
    }
}
