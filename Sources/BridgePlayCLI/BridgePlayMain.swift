import Foundation
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeCodex

private struct BoardInput: Codable {
    let contract: Contract
    let vulnerability: String
    let scoring: String
    let objective: String
    let publicBackground: String?
    let hands: [Hand]
    let openingLead: Card
}

@main struct BridgePlayMain {
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard arguments.count % 2 == 0 else { fail("Usage: bridge-play --fixture FILE --output DIR --codex EXECUTABLE [--timeout SECONDS]") }
        var options: [String: String] = [:]
        for index in stride(from: 0, to: arguments.count, by: 2) { options[arguments[index]] = arguments[index + 1] }
        guard let fixture = options["--fixture"], let outputPath = options["--output"], let codex = options["--codex"] else {
            fail("Usage: bridge-play --fixture FILE --output DIR --codex EXECUTABLE [--timeout SECONDS]")
        }
        let output = URL(fileURLWithPath: outputPath, isDirectory: true)
        if FileManager.default.fileExists(atPath: output.path),
           ((try? FileManager.default.contentsOfDirectory(atPath: output.path))?.isEmpty != true) {
            fail("Evidence output directory must be new or empty: \(output.path)")
        }
        do {
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            let fixtureData = try Data(contentsOf: URL(fileURLWithPath: fixture))
            let supplied = try JSONDecoder().decode(BoardInput.self, from: fixtureData)
            guard supplied.hands.count == 4, Set(supplied.hands.map(\.seat)).count == 4 else { throw DomainError.invalidDeal }
            let deal = Dictionary(uniqueKeysWithValues: supplied.hands.map { ($0.seat, $0.cards) })
            var board = try BoardState(deal: deal, contract: supplied.contract, vulnerability: supplied.vulnerability,
                                       scoring: supplied.scoring, objective: supplied.objective, publicBackground: supplied.publicBackground)
            try board.play(supplied.openingLead, by: supplied.contract.declarer.next)
            let snapshot = try board.snapshot(controller: supplied.contract.declarer)
            let authHome = ProcessInfo.processInfo.environment["CODEX_HOME"] ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex").path
            let transport = try CodexPlayingTransport(executable: URL(fileURLWithPath: codex),
                authenticationFile: URL(fileURLWithPath: authHome).appendingPathComponent("auth.json"), evidenceDirectory: output,
                timeoutSeconds: Double(options["--timeout"] ?? "180") ?? 180)
            let expert = ExpertSession(transport: transport)
            let decision = try await expert.decide(snapshot)
            try save(decision, to: output.appendingPathComponent("decision.json"))
            try board.apply(decision.action)
            try save(board.events, to: output.appendingPathComponent("events.json"))
            print("Applied \(decision.action.card) from \(decision.action.actingSeat.rawValue); evidence: \(output.path)")
        } catch {
            var failure: [String: Any] = ["status": "failed", "error": String(describing: error)]
            if let expert = error as? ExpertFailure {
                failure["input"] = expert.input; failure["rawOutput"] = expert.rawOutput
                failure["error"] = expert.detail; failure["elapsedSeconds"] = expert.elapsedSeconds
            }
            if let data = try? JSONSerialization.data(withJSONObject: failure, options: [.prettyPrinted, .sortedKeys]) {
                try? data.write(to: output.appendingPathComponent("failure.json"))
            }
            fail(String(describing: error))
        }
    }

    private static func save<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: url)
    }
    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data((message + "\n").utf8)); exit(1)
    }
}
