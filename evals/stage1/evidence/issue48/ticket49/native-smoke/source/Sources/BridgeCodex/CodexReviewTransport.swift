import Foundation
import BridgeExpert

/// Independent reviewer conversation for each candidate; never shares player history.
public struct CodexReviewTransport: PlayingTransport {
    private let executable: URL
    private let authenticationFile: URL
    private let evidenceDirectory: URL
    private let timeoutSeconds: Double
    public init(executable: URL, authenticationFile: URL, evidenceDirectory: URL, timeoutSeconds: Double = 180) {
        self.executable = executable; self.authenticationFile = authenticationFile
        self.evidenceDirectory = evidenceDirectory; self.timeoutSeconds = timeoutSeconds
    }
    public func respond(to request: PlayingRequest) async throws -> PlayingReply {
        let transport = try CodexPlayingTransport(executable: executable, authenticationFile: authenticationFile,
            evidenceDirectory: evidenceDirectory.appendingPathComponent(request.id.uuidString), timeoutSeconds: timeoutSeconds)
        return try await transport.respond(to: request)
    }
}
