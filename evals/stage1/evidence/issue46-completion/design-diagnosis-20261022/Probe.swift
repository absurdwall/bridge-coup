import Foundation
@testable import BridgeExpert
import BridgeCodex

@main
struct Probe {
    static func main() async throws {
        let arguments = CommandLine.arguments
        guard arguments.count == 5 else { fatalError("usage: probe request.json output-dir codex auth-file") }
        let requestURL = URL(fileURLWithPath: arguments[1])
        let directory = URL(fileURLWithPath: arguments[2], isDirectory: true)
        let document = try JSONSerialization.jsonObject(with: Data(contentsOf: requestURL)) as! [String: Any]
        let request = PlayingRequest(instructions: document["instructions"] as! String,
            input: document["input"] as! String, outputSchema: document["outputSchema"] as! String,
            timeoutSeconds: 180)
        let transport = try CodexPlayingTransport(executable: URL(fileURLWithPath: arguments[3]),
            authenticationFile: URL(fileURLWithPath: arguments[4]), evidenceDirectory: directory,
            timeoutSeconds: 180)
        let started = Date()
        let reply = try await transport.respond(to: request)
        try reply.rawOutput.write(to: directory.appendingPathComponent("raw-output.txt"), atomically: true, encoding: .utf8)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(reply.identity).write(to: directory.appendingPathComponent("identity.json"))
        let timing: [String: Any] = ["elapsedSeconds": Date().timeIntervalSince(started)]
        try JSONSerialization.data(withJSONObject: timing, options: [.prettyPrinted, .sortedKeys])
            .write(to: directory.appendingPathComponent("timing.json"))
    }
}
