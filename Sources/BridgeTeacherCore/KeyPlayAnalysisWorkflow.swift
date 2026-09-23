import Combine
import Foundation

@MainActor
public final class KeyPlayAnalysisWorkflow: ObservableObject {
    @Published public private(set) var draft: KeyPlayAnalysisDraft
    @Published public private(set) var state: PlanGenerationState = .idle
    @Published public private(set) var result: DeclarerPlanResponse?
    @Published public private(set) var resultIsOutdated = false

    private let runtime: any DeclarerTeachingRuntime
    private var revision = 0

    public init(draft: KeyPlayAnalysisDraft = KeyPlayAnalysisDraft(), runtime: any DeclarerTeachingRuntime) {
        self.draft = draft
        self.runtime = runtime
    }

    public func updateDraft(_ draft: KeyPlayAnalysisDraft) {
        guard draft != self.draft else { return }
        self.draft = draft
        invalidate()
    }

    /// Invalidates this mode's result when shared hand material or the selected mode changes.
    public func invalidate() {
        revision += 1
        if result != nil {
            resultIsOutdated = true
        }
        if state == .generating {
            state = .idle
        }
    }

    public func generate(from review: DeclarerPlanDraft) async {
        let request: DeclarerPlanRequest
        do {
            request = try KeyPlayAnalysisRequestBuilder.build(
                from: review,
                node: draft
            )
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
