import XCTest
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeCodex

final class PlayingCoreTests: XCTestCase {
    func testOpeningLeadExposesDummyAndCurrentActionAppliesOnlyToItsSnapshot() throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let snapshot = try board.snapshot(controller: .south)
        XCTAssertEqual(snapshot.actingSeat, .north)
        XCTAssertEqual(Set(snapshot.hands.map(\.seat)), [.north, .south])
        XCTAssertEqual(try board.legalCards(), [try Card("D8"), try Card("D6"), try Card("D5"), try Card("D3")])
        let action = CurrentAction(snapshot: snapshot, card: try Card("D3"))
        try board.apply(action)
        XCTAssertEqual(board.events.count, 2)
        XCTAssertEqual(board.actingSeat, .east)
        XCTAssertThrowsError(try board.apply(action))
        XCTAssertEqual(board.events.count, 2)
    }
    func testPublicExpertInitialDecisionKeepsFactsSeparateFromAdvice() async throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let snapshot = try board.snapshot(controller: .south)
        let expert = ExpertSession(transport: RecordedPlayTransport(output: #"{"currentCard":"D3","publicReason":"Follow low from dummy, preserving the diamond winners in South.","plan":{"update":"replace","text":"Establish clubs for the ninth trick, retaining a heart entry to South."}}"#))
        let decision = try await expert.decide(snapshot)
        XCTAssertTrue(decision.input.contains("Acting hand: North (dummy)"))
        XCTAssertTrue(decision.input.contains("North (dummy): S 862 / H K74 / D 8653 / C Q72"))
        XCTAssertFalse(decision.input.contains("East: S"))
        XCTAssertEqual(decision.action.card, try Card("D3"))
        XCTAssertEqual(decision.effectivePlan, "Establish clubs for the ninth trick, retaining a heart entry to South.")
        XCTAssertEqual(board.events.count, 1)
        try board.apply(decision.action)
        XCTAssertEqual(board.events.last?.card, try Card("D3"))
    }

    func testAmbiguousExtraExecutableFieldFailsWithoutApplyingAnything() async throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let expert = ExpertSession(transport: RecordedPlayTransport(output: #"{"currentCard":"D3","action":"D8","publicReason":"Follow low.","plan":{"update":"replace","text":"Establish clubs."}}"#))
        do {
            _ = try await expert.decide(board.snapshot(controller: .south))
            XCTFail("Unreadable or ambiguous output must fail visibly")
        } catch let failure as ExpertFailure {
            XCTAssertTrue(failure.rawOutput.contains("action"))
            XCTAssertEqual(board.events.count, 1)
        }
    }

    func testRuntimeTimeoutAlsoBoundsVersionProbeAndPreservesFailure() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let executable = root.appendingPathComponent("slow-runtime")
        try "#!/bin/sh\nif [ \"$1\" = \"--version\" ]; then exec /bin/sleep 2; fi\nexit 0\n".write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        let auth = root.appendingPathComponent("auth.json")
        try Data("{}".utf8).write(to: auth)
        let transport = try CodexPlayingTransport(executable: executable, authenticationFile: auth, evidenceDirectory: root.appendingPathComponent("evidence"), timeoutSeconds: 0.1)
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        do {
            _ = try await ExpertSession(transport: transport).decide(board.snapshot(controller: .south))
            XCTFail("Timed out runtime must fail")
        } catch let failure as ExpertFailure {
            XCTAssertLessThan(failure.elapsedSeconds, 1)
            XCTAssertFalse(failure.input.isEmpty)
            XCTAssertEqual(board.events.count, 1)
        }
    }

}

func syntheticDeal() throws -> [Seat: [Card]] {
    func cards(_ codes: String) throws -> [Card] { try codes.split(separator: " ").map { try Card(String($0)) } }
    let south = try cards("SA S9 S4 HA H6 H3 DA DK CA CK C8 C6 C4")
    let north = try cards("S8 S6 S2 HK H7 H4 D8 D6 D5 D3 CQ C7 C2")
    let remaining = try Suit.allCases.flatMap { suit in try ["A","K","Q","J","T","9","8","7","6","5","4","3","2"].map { try Card(suit.code + $0) } }.filter { !south.contains($0) && !north.contains($0) && $0 != (try? Card("DQ")) }
    return [.south: south, .north: north, .west: [try Card("DQ")] + Array(remaining.prefix(12)), .east: Array(remaining.dropFirst(12))]
}

struct RecordedPlayTransport: PlayingTransport {
    let output: String
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        _ = try JSONSerialization.jsonObject(with: Data(request.outputSchema.utf8))
        return PlayingReply(rawOutput: output, identity: RuntimeIdentity(requestedModel: "gpt-6-luna", requestedEffort: "medium", runtimeVersion: "recorded boundary", observedModel: nil, threadID: "recorded", turnID: "recorded"))
    }
}
