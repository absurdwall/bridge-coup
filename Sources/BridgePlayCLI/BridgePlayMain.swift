import Foundation
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeCodex
import BridgeDriver

private struct BoardInput: Codable {
    let contract: Contract
    let vulnerability: String
    let scoring: String
    let objective: String
    let publicBackground: String?
    let hands: [Hand]
    let openingLead: Card?
    let initialEvents: [PlayEvent]?
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
            if let events = supplied.initialEvents {
                for (index, event) in events.enumerated() {
                    guard event.sequence == index else { throw DomainError.invalidDeal }
                    try board.play(event.card, by: event.seat)
                }
            } else if let lead = supplied.openingLead {
                try board.play(lead, by: supplied.contract.declarer.next)
            } else { throw DomainError.invalidDeal }
            guard let limit = Int(options["--decisions"] ?? "1"), (1...26).contains(limit),
                  let policy = OpponentPolicy(rawValue: options["--opponent"] ?? "low-legal") else {
                throw CodexPlayingError.failure("Invalid decision limit or opponent policy")
            }
            let authHome = ProcessInfo.processInfo.environment["CODEX_HOME"] ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex").path
            let transport = try CodexPlayingTransport(executable: URL(fileURLWithPath: codex),
                authenticationFile: URL(fileURLWithPath: authHome).appendingPathComponent("auth.json"), evidenceDirectory: output,
                timeoutSeconds: Double(options["--timeout"] ?? "180") ?? 180)
            let expert = ExpertSession(transport: transport)
            let driver = BoardDriver(board: board, expert: expert, opponent: policy,
                                     mechanicalSoleLegal: options["--sole-legal"] == "true")
            var decisionCount = 0
            do {
                while decisionCount < limit {
                    let step = try await driver.advance()
                    if let decision = step.decision {
                        decisionCount += 1
                        let directory = limit == 1 ? output : output.appendingPathComponent(String(format: "decision-%04d", decisionCount))
                        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                        try save(decision, to: directory.appendingPathComponent("decision.json"))
                        try save(step.actualEvents, to: directory.appendingPathComponent("events.json"))
                        print("Applied \(decision.action.card) from \(decision.action.actingSeat.rawValue); decision \(decisionCount)")
                    }
                    let trace = await driver.trace()
                    try save(trace, to: output.appendingPathComponent("trace.json"))
                    if trace.complete { break }
                }
            } catch {
                if let failure = error as? DriverFailure {
                    let directory = limit == 1 ? output : output.appendingPathComponent(String(format: "decision-%04d", decisionCount + 1))
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                    try save(failure.decision, to: directory.appendingPathComponent("decision.json"))
                    let data = try JSONSerialization.data(withJSONObject: ["status": "failed", "error": failure.detail], options: [.prettyPrinted, .sortedKeys])
                    try data.write(to: directory.appendingPathComponent("failure.json"))
                }
                try save(await driver.trace(), to: output.appendingPathComponent("trace.json"))
                throw error
            }
            print("Saved \(decisionCount) decisions; evidence: \(output.path)")
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
