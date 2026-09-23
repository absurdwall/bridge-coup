import Foundation

public struct DeclarerPlanAnalysis: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let requestID: UUID
    public let informationVersion: Int
    public let response: DeclarerPlanResponse

    public init(id: UUID = UUID(), requestID: UUID, informationVersion: Int, response: DeclarerPlanResponse) {
        self.id = id
        self.requestID = requestID
        self.informationVersion = informationVersion
        self.response = response
    }
}

public enum DeclarerFollowUpStatus: Codable, Equatable, Sendable {
    case sending
    case answered(DeclarerPlanResponse)
    case failed(String)
    case outdated
}

public struct DeclarerFollowUpExchange: Codable, Equatable, Identifiable, Sendable {
    /// Stable across retries so one question has one effective answer in the review history.
    public let id: UUID
    public let informationVersion: Int
    public let planID: UUID
    public let question: String
    public let assumptions: String?
    public var status: DeclarerFollowUpStatus

    public init(
        id: UUID = UUID(),
        informationVersion: Int,
        planID: UUID,
        question: String,
        assumptions: String?,
        status: DeclarerFollowUpStatus
    ) {
        self.id = id
        self.informationVersion = informationVersion
        self.planID = planID
        self.question = question
        self.assumptions = assumptions
        self.status = status
    }
}

public struct DeclarerFollowUpRequest: Equatable, Sendable {
    public let requestID: UUID
    public let informationVersion: Int
    public let planID: UUID
    public let context: DeclarerPlanRequest
    public let currentPlan: DeclarerPlanAnalysis
    public let priorExchanges: [DeclarerFollowUpExchange]
    public let question: String
    public let assumptions: String?
    public let prompt: String

    public init(
        requestID: UUID,
        informationVersion: Int,
        planID: UUID,
        context: DeclarerPlanRequest,
        currentPlan: DeclarerPlanAnalysis,
        priorExchanges: [DeclarerFollowUpExchange],
        question: String,
        assumptions: String?,
        prompt: String
    ) {
        self.requestID = requestID
        self.informationVersion = informationVersion
        self.planID = planID
        self.context = context
        self.currentPlan = currentPlan
        self.priorExchanges = priorExchanges
        self.question = question
        self.assumptions = assumptions
        self.prompt = prompt
    }
}

public enum DeclarerFollowUpRequestBuilder {
    public static func build(
        context: DeclarerPlanRequest,
        currentPlan: DeclarerPlanAnalysis,
        priorExchanges: [DeclarerFollowUpExchange],
        question: String,
        assumptions: String,
        requestID: UUID = UUID()
    ) throws -> DeclarerFollowUpRequest {
        let question = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else {
            throw DeclarerPlanInputError.emptyFollowUpQuestion
        }
        let assumptions = assumptions.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentExchanges = priorExchanges.filter { exchange in
            exchange.planID == currentPlan.id
                && exchange.informationVersion == currentPlan.informationVersion
                && exchange.informationVersion == context.informationVersion
                && isAnswered(exchange.status)
        }
        let normalizedAssumptions = assumptions.isEmpty ? nil : assumptions
        let prompt = makePrompt(
            context: context,
            currentPlan: currentPlan,
            priorExchanges: currentExchanges,
            question: question,
            assumptions: normalizedAssumptions
        )

        return DeclarerFollowUpRequest(
            requestID: requestID,
            informationVersion: context.informationVersion,
            planID: currentPlan.id,
            context: context,
            currentPlan: currentPlan,
            priorExchanges: currentExchanges,
            question: question,
            assumptions: normalizedAssumptions,
            prompt: prompt
        )
    }

    private static func isAnswered(_ status: DeclarerFollowUpStatus) -> Bool {
        if case .answered = status { return true }
        return false
    }

    private static func makePrompt(
        context: DeclarerPlanRequest,
        currentPlan: DeclarerPlanAnalysis,
        priorExchanges: [DeclarerFollowUpExchange],
        question: String,
        assumptions: String?
    ) -> String {
        var sections = [
            "当前决策时信息（确认事实与未知项）：\n\(context.prompt)",
            "当前做庄计划（先前模型分析，不是额外确认的牌局事实）：\n\(currentPlan.response.text)"
        ]

        for (index, exchange) in priorExchanges.enumerated() {
            guard case let .answered(response) = exchange.status else { continue }
            var exchangeText = "第\(index + 1)次追问：\(exchange.question)"
            if let assumptions = exchange.assumptions {
                exchangeText += "\n该次条件假设（不是已确认事实）：\n\(assumptions)"
            }
            exchangeText += "\n回答（仅为既有分析，不是新确认事实）：\n\(response.text)"
            sections.append(exchangeText)
        }

        sections.append("本次追问：\n\(question)")
        if let assumptions {
            sections.append("本次条件假设（不是已确认事实）\n仅在该条件成立时讨论：\n\(assumptions)\n不得将该假设写入已确认牌面或事实。")
        }
        sections.append("请结合当前计划和上面的决策时信息回答。明确区分用户确认的事实、推断与条件假设；未知手牌仍保持未知。")
        return sections.joined(separator: "\n\n")
    }
}
