import Foundation
import XCTest
@testable import BridgeTeacherMac

final class CodexRuntimeDiscoveryTests: XCTestCase {
    func testInvalidSavedExecutableAndUnavailableProtocolDoNotBlockLaterCandidate() async {
        let urls = ["/saved/codex", "/blocked/codex", "/wrong-protocol/codex", "/desktop/codex"].map(URL.init(fileURLWithPath:))
        let discovery = CodexRuntimeDiscovery(candidates: urls, fileState: {
            switch $0.path {
            case "/saved/codex": .missing
            case "/blocked/codex": .notExecutable
            default: nil
            }
        }, probe: { url in
            if url.path == "/wrong-protocol/codex" { throw CodexRuntimeSetupError.protocolUnavailable("unsupported app-server") }
            return CodexRuntimeConnection(info: CodexRuntimeInfo(executableURL: url, version: "0.159.2"), isSignedIn: false)
        })

        let result = await discovery.search()

        XCTAssertEqual(result.connection?.info.executableURL, urls.last)
        XCTAssertEqual(result.connection?.isSignedIn, false, "Login is a recoverable state for a valid runtime.")
        XCTAssertEqual(result.hints.map(\.failure), [.missing, .notExecutable, .protocolUnavailable("unsupported app-server"), nil])
    }

    func testSearchPreservesWorkingManualCandidateBeforeAutomaticInstallation() async throws {
        let candidates = CodexRuntimeDiscovery.candidateURLs(savedPath: "/custom/codex", environment: ["PATH": "/automatic/bin"], home: URL(fileURLWithPath: "/home/test"), bundle: URL(fileURLWithPath: "/app/Bridge.app"), directoryContents: { _ in [] })
        let result = await CodexRuntimeDiscovery(candidates: candidates, fileState: { _ in nil }, probe: { url in
            CodexRuntimeConnection(info: CodexRuntimeInfo(executableURL: url, version: "0.159.2"), isSignedIn: true)
        }).search()
        XCTAssertEqual(result.connection?.info.executableURL.path, "/custom/codex")
        XCTAssertEqual(result.hints.count, 1)
        XCTAssertTrue(candidates.contains(URL(fileURLWithPath: "/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex")))
        XCTAssertTrue(candidates.contains(URL(fileURLWithPath: "/home/test/Applications/Codex.app/Contents/Resources/codex")))
        XCTAssertTrue(candidates.contains(URL(fileURLWithPath: "/automatic/bin/codex")))
    }

    func testNoRuntimeReturnsConcreteSuggestionsMarkedAsMissing() async {
        let urls = ["/Applications/Codex.app/Contents/Resources/codex", "/opt/homebrew/bin/codex"].map(URL.init(fileURLWithPath:))
        let result = await CodexRuntimeDiscovery(candidates: urls, fileState: { _ in .missing }, probe: { _ in
            XCTFail("Missing files must not be launched")
            throw CodexRuntimeSetupError.runtimeNotFound
        }).search()
        XCTAssertNil(result.connection)
        XCTAssertNil(result.failure)
        XCTAssertEqual(result.hints.map(\.url), urls)
        XCTAssertEqual(result.hints.map(\.failure), [.missing, .missing])
    }

    func testCannotRunFailureIsDifferentFromProtocolFailureAndCandidatesAreDeduplicated() async {
        let url = URL(fileURLWithPath: "/bad/codex")
        let result = await CodexRuntimeDiscovery(candidates: [url, url], fileState: { _ in nil }, probe: { _ in
            throw CodexRuntimeSetupError.runtimeNotExecutable("exit 126")
        }).search()
        XCTAssertEqual(result.failure, .cannotRun("exit 126"))
        XCTAssertEqual(result.hints.count, 1)
    }

    func testActualExecutableHandshakeAndLoginProbe() async throws {
        let fixture = try makeRuntime()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let service = CodexTeachingService(appSupportURL: fixture.root.appendingPathComponent("support"))
        let result = await CodexRuntimeDiscovery(candidates: [fixture.executable], probe: { url in
            let info = try await service.configure(executableURL: url)
            return CodexRuntimeConnection(info: info, isSignedIn: try await service.isChatGPTSignedIn())
        }).search()
        XCTAssertEqual(result.connection?.info.version, "codex-cli 0.159.2")
        XCTAssertEqual(result.connection?.isSignedIn, false)
        XCTAssertNil(result.hints.first?.failure)
    }

    func testActualExecutableWithMalformedProtocolIsRejectedAndSearchContinues() async throws {
        let bad = try makeRuntime(malformed: true)
        let good = try makeRuntime()
        defer {
            try? FileManager.default.removeItem(at: bad.root)
            try? FileManager.default.removeItem(at: good.root)
        }
        let service = CodexTeachingService(appSupportURL: good.root.appendingPathComponent("support"))
        _ = try await service.configure(executableURL: good.executable)
        do {
            _ = try await service.configure(executableURL: bad.executable)
            XCTFail("Malformed candidate must not replace the current working client")
        } catch {}
        let previousClientStillWorks = try await service.isChatGPTSignedIn()
        XCTAssertFalse(previousClientStillWorks)
        let result = await CodexRuntimeDiscovery(candidates: [bad.executable, good.executable], probe: { url in
            let info = try await service.configure(executableURL: url)
            return CodexRuntimeConnection(info: info, isSignedIn: try await service.isChatGPTSignedIn())
        }).search()
        XCTAssertEqual(result.connection?.info.executableURL, good.executable)
        guard case .protocolUnavailable = result.hints.first?.failure else { return XCTFail("Expected protocol failure") }
    }

    func testProtocolThatNeverRepliesTimesOutAndSearchContinues() async throws {
        let bad = try makeRuntime(silent: true)
        let good = try makeRuntime()
        defer {
            try? FileManager.default.removeItem(at: bad.root)
            try? FileManager.default.removeItem(at: good.root)
        }
        let service = CodexTeachingService(appSupportURL: good.root.appendingPathComponent("support"))
        let start = Date()
        let result = await CodexRuntimeDiscovery(candidates: [bad.executable, good.executable], probe: { url in
            let info = try await service.configure(executableURL: url)
            return CodexRuntimeConnection(info: info, isSignedIn: try await service.isChatGPTSignedIn())
        }).search()
        XCTAssertEqual(result.connection?.info.executableURL, good.executable)
        XCTAssertLessThan(Date().timeIntervalSince(start), 12)
        guard case .protocolUnavailable = result.hints.first?.failure else { return XCTFail("Expected protocol timeout") }
    }

    private func makeRuntime(malformed: Bool = false, silent: Bool = false) throws -> (root: URL, executable: URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("bridge-runtime-test-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let executable = root.appendingPathComponent("codex")
        let script = """
        #!/usr/bin/python3
        import json, sys, time
        if '--version' in sys.argv:
            print('codex-cli 0.159.2')
            sys.exit(0)
        for line in sys.stdin:
            message = json.loads(line)
            if 'id' not in message: continue
            if \(silent ? "True" : "False"):
                time.sleep(30)
                continue
            result = None if \(malformed ? "True" : "False") else ({'account': None} if message['method'] == 'account/read' else {'userAgent': 'test-runtime'})
            print(json.dumps({'id': message['id'], 'result': result}), flush=True)
        """
        try script.write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        return (root, executable)
    }
}
