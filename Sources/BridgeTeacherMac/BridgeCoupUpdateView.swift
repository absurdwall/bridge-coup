import SwiftUI

struct BridgeCoupUpdateView: View {
    @ObservedObject var workflow: BridgeCoupUpdateWorkflow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bridge Coup Updates")
                .font(.title2.bold())
            Text(workflow.state.message)
                .accessibilityIdentifier("update-check-status")

            if case let .available(candidate) = workflow.state {
                Text("Release notes")
                    .font(.headline)
                ScrollView {
                    Text(candidate.notes.isEmpty ? "No release notes provided." : candidate.notes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 140, maxHeight: 280)
                .accessibilityIdentifier("update-release-notes")
                Text("The release page opens in your browser. Download and replace the app manually.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Check Again") { Task { await workflow.check() } }
                    .disabled(workflow.state == .checking)
                    .accessibilityIdentifier("update-check-retry")
                Spacer()
                if case .available = workflow.state {
                    Button("Open Release Page") { workflow.openAvailableRelease() }
                        .accessibilityIdentifier("update-open-release")
                }
                Button("Close") { dismiss() }
            }
        }
        .padding(24)
        .frame(width: 490)
        .accessibilityIdentifier("bridge-coup-update-check")
    }
}
