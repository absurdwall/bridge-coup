import XCTest
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeCodex
import BridgeDriver

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
        let expert = ExpertSession(transport: RecordedPlayTransport(output: #"{"selectedCard":"D3","publicReason":"Follow low from dummy, preserving the diamond winners in South.","plan":{"update":"replace","text":"Establish clubs for the ninth trick, retaining a heart entry to South."}}"#))
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

    func testContinuationUsesActualDeltaAndRetainsPlanSourceWithFreshDecisionSession() async throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let expert = ExpertSession(transport: SequencePlayTransport(outputs: [
            #"{"plan":{"update":"replace","text":"Establish clubs while retaining entries."},"publicReason":"Follow low from dummy.","selectedCard":"D3"}"#,
            #"{"plan":{"update":"keep","text":null},"publicReason":"Win the diamond lead.","selectedCard":"DA"}"#
        ]))
        let first = try await expert.decide(board.snapshot(controller: .south))
        try board.apply(first.action)
        try board.play(board.legalCards()[0], by: .east)
        let second = try await expert.decide(board.snapshot(controller: .south))
        XCTAssertEqual(first.identity.threadID, second.identity.threadID)
        XCTAssertNotEqual(first.identity.turnID, second.identity.turnID)
        XCTAssertNotEqual(first.session.id, second.session.id)
        XCTAssertEqual(second.session.snapshotID, second.snapshot.id)
        XCTAssertEqual(second.planAssociation, first.planAssociation)
        XCTAssertEqual(second.planAssociation?.sourceSnapshotID, first.snapshot.id)
        XCTAssertTrue(second.input.contains("Previous suggestion actually executed: yes"))
        XCTAssertTrue(second.input.contains("North D3"))
        XCTAssertFalse(second.input.contains("S A94 /"))
        XCTAssertFalse(second.input.contains("Establish clubs while"))
        XCTAssertFalse(second.input.contains("0: West DQ"))
        try board.apply(second.action)
    }

    func testAmbiguousExtraExecutableFieldFailsWithoutApplyingAnything() async throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let expert = ExpertSession(transport: RecordedPlayTransport(output: #"{"selectedCard":"D3","action":"D8","publicReason":"Follow low.","plan":{"update":"replace","text":"Establish clubs."}}"#))
        do {
            _ = try await expert.decide(board.snapshot(controller: .south))
            XCTFail("Unreadable or ambiguous output must fail visibly")
        } catch let failure as ExpertFailure {
            XCTAssertTrue(failure.rawOutput.contains("action"))
            XCTAssertEqual(board.events.count, 1)
        }
    }

    func testPublicDriverExecutesEveryDummyChoiceAndRecordsOpponentDelta() async throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let expert = ExpertSession(transport: SequencePlayTransport(outputs: [
            #"{"plan":{"update":"replace","text":"Establish clubs."},"publicReason":"Follow low.","selectedCard":"D3"}"#,
            #"{"plan":{"update":"keep","text":null},"publicReason":"Win with the ace.","selectedCard":"DA"}"#
        ]))
        let driver = BoardDriver(board: board, expert: expert, opponent: .lowLegal)
        let dummy = try await driver.advance()
        XCTAssertEqual(dummy.execution.event.card, try Card("D3"))
        XCTAssertEqual(dummy.execution.source, .model)
        let opponent = try await driver.advance()
        XCTAssertEqual(opponent.execution.source, .opponent)
        let declarer = try await driver.advance()
        XCTAssertEqual(declarer.execution.source, .model)
        XCTAssertTrue(declarer.decision!.input.contains("(opponent)"))
        XCTAssertEqual(declarer.decision!.snapshot.events.count, 3)
        let trace = await driver.trace()
        XCTAssertEqual(trace.modelRequests, 2)
        XCTAssertEqual(trace.controlledActions, 2)
        XCTAssertEqual(trace.opponentActions, 1)
    }

    func testOneThreadRejectsOverlapStaleAndCrossBoardRequests() async throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let snapshot = try board.snapshot(controller: .south)
        let transport = GatedPlayTransport()
        let expert = ExpertSession(transport: transport)
        let first = Task { try await expert.decide(snapshot) }
        await transport.waitUntilEntered()
        do { _ = try await expert.decide(snapshot); XCTFail("Overlap must fail") }
        catch { XCTAssertEqual(error as? ExpertSessionError, .overlappingDecision) }
        await transport.release()
        _ = try await first.value
        do { _ = try await expert.decide(snapshot); XCTFail("Old snapshot must fail") }
        catch { XCTAssertEqual(error as? ExpertSessionError, .staleSnapshot) }
        var other = try BoardState(deal: syntheticDeal(), contract: board.contract)
        try other.play(Card("DQ"), by: .west)
        do { _ = try await expert.decide(other.snapshot(controller: .south)); XCTFail("Cross-board must fail") }
        catch { XCTAssertEqual(error as? ExpertSessionError, .differentBoardOrController) }
    }

    func testPlanReplacementChangesSourceAndWithdrawalClearsIt() async throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let expert = ExpertSession(transport: SequencePlayTransport(outputs: [
            #"{"plan":{"update":"replace","text":"Establish clubs."},"publicReason":"Follow low.","selectedCard":"D3"}"#,
            #"{"plan":{"update":"replace","text":"Win the diamond and reconsider entries."},"publicReason":"Take the ace.","selectedCard":"DA"}"#,
            #"{"plan":{"update":"withdraw","text":null},"publicReason":"Start a low club while reassessing.","selectedCard":"C4"}"#
        ]))
        let first = try await expert.decide(board.snapshot(controller: .south))
        // A real different legal dummy card is authoritative; the recommendation is not an event.
        try board.play(Card("D5"), by: .north)
        try board.play(board.legalCards()[0], by: .east)
        let second = try await expert.decide(board.snapshot(controller: .south))
        XCTAssertTrue(second.input.contains("Previous suggestion actually executed: no"))
        XCTAssertEqual(second.planAssociation?.sourceSnapshotID, second.snapshot.id)
        XCTAssertNotEqual(first.planAssociation?.sourceSnapshotID, second.planAssociation?.sourceSnapshotID)
        try board.apply(second.action)
        let third = try await expert.decide(board.snapshot(controller: .south))
        XCTAssertNil(third.effectivePlan)
        XCTAssertNil(third.planAssociation)
    }

    func testIllegalCurrentActionStopsDriverWithOriginalOutputAndNoExecution() async throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let output = #"{"plan":{"update":"replace","text":"Establish clubs."},"publicReason":"Win the ace.","selectedCard":"DA"}"#
        let driver = BoardDriver(board: board, expert: ExpertSession(transport: RecordedPlayTransport(output: output)))
        do { _ = try await driver.advance(); XCTFail("North does not hold DA") }
        catch let failure as DriverFailure {
            XCTAssertEqual(failure.decision.rawOutput, output)
            XCTAssertEqual(failure.detail, "cardNotHeld")
        }
        let trace = await driver.trace()
        XCTAssertEqual(trace.modelRequests, 1)
        XCTAssertEqual(trace.controlledActions, 0)
        do { _ = try await driver.advance(); XCTFail("Failure must not retry") }
        catch { XCTAssertEqual(error as? ExpertSessionError, .endedSession) }
    }

    func testChangedObjectiveCannotSilentlyReuseContinuingThread() async throws {
        let deal = try syntheticDeal()
        let identifier = UUID()
        var board = try BoardState(id: identifier, deal: deal, contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let expert = ExpertSession(transport: RecordedPlayTransport(output: #"{"plan":{"update":"replace","text":"Establish clubs."},"publicReason":"Follow low.","selectedCard":"D3"}"#))
        let first = try await expert.decide(board.snapshot(controller: .south))
        var changed = try BoardState(id: identifier, deal: deal, contract: board.contract, objective: "Pure contract safety.")
        try changed.play(Card("DQ"), by: .west)
        try changed.apply(first.action)
        try changed.play(changed.legalCards()[0], by: .east)
        do { _ = try await expert.decide(changed.snapshot(controller: .south)); XCTFail("New objective requires a new session") }
        catch { XCTAssertEqual(error as? ExpertSessionError, .changedHistory) }
    }

    func testNonAdjacentTurnReuseCannotBecomeAThirdDecision() async throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let expert = ExpertSession(transport: SequencePlayTransport(outputs: [
            #"{"plan":{"update":"replace","text":"Establish clubs."},"publicReason":"Follow low.","selectedCard":"D3"}"#,
            #"{"plan":{"update":"keep","text":null},"publicReason":"Win the ace.","selectedCard":"DA"}"#,
            #"{"plan":{"update":"keep","text":null},"publicReason":"Lead a club.","selectedCard":"C4"}"#
        ], turnIDs: ["turn-A", "turn-B", "turn-A"]))
        let first = try await expert.decide(board.snapshot(controller: .south))
        try board.apply(first.action)
        try board.play(board.legalCards()[0], by: .east)
        let second = try await expert.decide(board.snapshot(controller: .south))
        try board.apply(second.action)
        do { _ = try await expert.decide(board.snapshot(controller: .south)); XCTFail("Each decision needs a previously unused turn") }
        catch let failure as ExpertFailure { XCTAssertEqual(failure.detail, "changedThreadOrRepeatedTurn") }
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

actor SequencePlayTransport: PlayingTransport {
    let outputs: [String]
    var index = 0
    let turnIDs: [String]?
    init(outputs: [String], turnIDs: [String]? = nil) { self.outputs = outputs; self.turnIDs = turnIDs }
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        let output = outputs[index]; index += 1
        return PlayingReply(rawOutput: output, identity: RuntimeIdentity(requestedModel: "gpt-6-luna", requestedEffort: "medium", runtimeVersion: "recorded boundary", observedModel: nil, threadID: "one-thread", turnID: turnIDs?[index - 1] ?? "turn-\(index)"))
    }
}

actor GatedPlayTransport: PlayingTransport {
    private var entered = false
    private var observer: CheckedContinuation<Void, Never>?
    private var gate: CheckedContinuation<Void, Never>?
    func waitUntilEntered() async {
        if entered { return }
        await withCheckedContinuation { observer = $0 }
    }
    func release() { gate?.resume(); gate = nil }
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        entered = true
        observer?.resume(); observer = nil
        await withCheckedContinuation { gate = $0 }
        return PlayingReply(rawOutput: #"{"plan":{"update":"replace","text":"Establish clubs."},"publicReason":"Follow low.","selectedCard":"D3"}"#, identity: RuntimeIdentity(requestedModel: "gpt-6-luna", requestedEffort: "medium", runtimeVersion: "recorded boundary", observedModel: nil, threadID: "one-thread", turnID: "one-turn"))
    }
}
