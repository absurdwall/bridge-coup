import Combine
import Foundation

public enum PlayCardResultsState: Equatable, Sendable {
    case hidden
    case unavailable
    case awaitingCollection
    case complete
    case calculating
    case ready
    case failed(String)
}

/// Current-position DDS labels are separate from editable legacy verification and
/// from the original-board table. Every update clears labels before starting work.
@MainActor
public final class PlayCardResultsWorkflow: ObservableObject {
    @Published public private(set) var isEnabled = false
    @Published public private(set) var state: PlayCardResultsState = .hidden
    @Published public private(set) var labels: [DoubleDummyCard: Int] = [:]
    @Published public private(set) var actingSeat: Seat?
    public private(set) var positionRevision = 0

    private let solver: any DoubleDummySolving
    private var session: BridgePlaySession?
    private var generation = UUID()
    private var task: Task<Void, Never>?

    public init(solver: any DoubleDummySolving) { self.solver = solver }

    public func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled
        refreshPosition()
    }

    public func updatePosition(_ session: BridgePlaySession?, revision: Int) {
        guard revision != positionRevision || session != self.session else { return }
        self.session = session
        positionRevision = revision
        refreshPosition()
    }

    public func retry() { refreshPosition() }

    public func label(for card: DoubleDummyCard, by seat: Seat) -> String? {
        guard isEnabled, state == .ready, actingSeat == seat, let delta = labels[card] else { return nil }
        return delta == 0 ? "=" : (delta > 0 ? "+\(delta)" : "\(delta)")
    }

    private func refreshPosition() {
        generation = UUID()
        task?.cancel()
        task = nil
        labels = [:]
        actingSeat = nil
        guard isEnabled else { state = .hidden; return }
        guard let session else { state = .unavailable; return }
        guard !session.isComplete else { state = .complete; return }
        guard !session.awaitingCollection else { state = .awaitingCollection; return }
        guard let actor = session.actingSeat, !session.legalCards.isEmpty else { state = .unavailable; return }
        let request = generation
        let revision = positionRevision
        actingSeat = actor
        state = .calculating
        task = Task { [weak self, solver] in
            do {
                guard !Task.isCancelled else { return }
                let position = try DoubleDummyVerificationPositionBuilder.build(from: session.doubleDummyDraft())
                let moves = try await solver.solve(position: position)
                guard let self, self.generation == request, self.positionRevision == revision, self.isEnabled else { return }
                let result = try DoubleDummyVerificationResultBuilder.build(from: moves, position: position, solverVersion: solver.version)
                var labels: [DoubleDummyCard: Int] = [:]
                for move in result.moves {
                    guard let delta = move.contractDelta else { throw DoubleDummyResultError.missingLegalMove }
                    for card in move.cards { labels[card] = delta }
                }
                self.labels = labels
                self.state = .ready
            } catch {
                guard let self, self.generation == request, self.positionRevision == revision, self.isEnabled else { return }
                self.labels = [:]
                self.state = .failed(error.localizedDescription)
            }
        }
    }
}
