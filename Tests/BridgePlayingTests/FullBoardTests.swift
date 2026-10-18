import XCTest
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeDriver
import BridgeCodex

final class FullBoardTests: XCTestCase {
    func testWorkedTrumpAndNotrumpWinnersAndNoObligationToRuffOrOverruff() throws {
        for (strain, variant, plays, winner) in [
            (Strain.noTrump, "A", ["H2", "SA", "DA", "CA"], Seat.west),
            (.spades, "A", ["H2", "S2", "DA", "CA"], .north),
            (.spades, "A", ["H2", "S2", "DA", "S3"], .south),
            (.spades, "U2", ["H2", "C3", "S9", "S3"], .east),
            (.spades, "U2", ["H2", "C3", "S9", "CA"], .east),
            (.spades, "U2", ["H2", "C3", "S9", "SJ"], .south),
            (.spades, "F", ["H2", "H3", "DA", "CA"], .north)
        ] {
            var board = try ruleBoard(strain: strain, variant: variant)
            for (seat, code) in zip([Seat.west, .north, .east, .south], plays) { try board.play(Card(code), by: seat) }
            XCTAssertEqual(board.actingSeat, winner, "\(variant): \(plays)")
            XCTAssertEqual(board.currentTrick.count, 0)
            XCTAssertEqual(board.declarerTricks, [.north, .south].contains(winner) ? 1 : 0)
            XCTAssertEqual(board.events.count, 4)
            XCTAssertTrue(board.hands.values.allSatisfy { $0.count == 12 })
        }
        var follow = try ruleBoard(strain: .spades, variant: "F")
        try follow.play(Card("H2"), by: .west)
        XCTAssertThrowsError(try follow.play(Card("CA"), by: .south)) { XCTAssertEqual($0 as? DomainError, .wrongTurn) }
        XCTAssertThrowsError(try follow.play(Card("SA"), by: .north)) { XCTAssertEqual($0 as? DomainError, .mustFollowSuit) }
        XCTAssertEqual(try follow.legalCards(), [try Card("H3")])
        XCTAssertEqual(follow.events.count, 1)
    }

    func testLiteralThirteenTricksConsumeAllCardsAndFinishedBoardRejectsMoreWork() throws {
        var board = try ruleBoard(strain: .noTrump)
        let tricks = ["H2 S2 D2 C2", "H3 S4 D3 C4", "H4 S5 D4 C5", "H5 S6 D5 C6", "H6 S7 D6 C7", "H7 S8 D7 C8", "H8 S9 D8 C9", "H9 ST D9 CT", "HT SJ DT CJ", "HJ SQ DJ CQ", "HQ SK DQ CK", "HK SA DK CA", "HA C3 DA S3"]
        for (index, trick) in tricks.enumerated() {
            for (seat, code) in zip([Seat.west, .north, .east, .south], trick.split(separator: " ")) { try board.play(Card(String(code)), by: seat) }
            XCTAssertEqual(board.defenderTricks, index + 1)
            XCTAssertTrue(board.hands.values.allSatisfy { $0.count == 12 - index })
        }
        XCTAssertTrue(board.isComplete)
        XCTAssertNil(board.actingSeat)
        XCTAssertEqual(board.declarerTricks, 0)
        XCTAssertEqual(Set(board.events.map(\.card)).count, 52)
        XCTAssertEqual(board.events.map(\.sequence), Array(0...51))
        XCTAssertThrowsError(try board.play(Card("S3"), by: .south)) { XCTAssertEqual($0 as? DomainError, .finished) }
        XCTAssertThrowsError(try board.legalCards())
        XCTAssertThrowsError(try board.snapshot(controller: .south))
        XCTAssertEqual(board.events.count, 52)
    }

    func testFullDriverRequiresInitialPlanThenLabelsForcedActionsAndCountsPrefix() async throws {
        var board = try ruleBoard(strain: .noTrump, variant: "F")
        try board.play(Card("H2"), by: .west)
        let driver = BoardDriver(board: board, expert: ExpertSession(transport: FirstLegalTransport()), mechanicalSoleLegal: true)
        let first = try await driver.advance()
        XCTAssertEqual(first.execution.event.card, try Card("H3"))
        XCTAssertEqual(first.execution.source, .model)
        for _ in 0..<50 { _ = try await driver.advance() }
        let trace = await driver.trace()
        XCTAssertTrue(trace.complete)
        XCTAssertEqual(trace.initialEvents.count, 1)
        XCTAssertEqual(trace.initialControlledActions, 0)
        XCTAssertEqual(trace.initialOpponentActions, 1)
        XCTAssertEqual(trace.steps.count, 51)
        XCTAssertEqual(trace.controlledActions, 26)
        XCTAssertEqual(trace.opponentActions, 25)
        XCTAssertEqual(trace.modelActions + trace.mechanicalActions, 26)
        XCTAssertEqual(trace.modelRequests, trace.modelActions)
        XCTAssertGreaterThan(trace.mechanicalActions, 0)
        XCTAssertEqual(trace.declarerTricks + trace.defenderTricks, 13)
        XCTAssertNotNil(trace.lastControlledActionSeconds)
        XCTAssertEqual(Set(trace.steps.last!.actualEvents.map(\.card)).count, 52)
        XCTAssertTrue(trace.steps.compactMap(\.decision).dropFirst().contains { $0.input.contains("(forced)") })
    }

    func testRunBudgetStopsBeforeExecutionAndPreservesUnexecutedDecision() async throws {
        var board = try ruleBoard(strain: .noTrump, variant: "F")
        try board.play(Card("H2"), by: .west)
        let driver = BoardDriver(board: board, expert: ExpertSession(transport: DelayedTransport()), requestTimeoutSeconds: 1, runTimeoutSeconds: 0.02)
        do { _ = try await driver.advance(); XCTFail("Budget exhaustion cannot execute a late action") }
        catch let failure as DriverFailure { XCTAssertTrue(failure.detail.contains("budget expired")); XCTAssertEqual(failure.decision.action.card, try Card("H3")) }
        let trace = await driver.trace()
        XCTAssertFalse(trace.complete)
        XCTAssertEqual(trace.steps.count, 0)
        XCTAssertEqual(trace.modelRequests, 1)
        XCTAssertNotNil(trace.failure)
        XCTAssertEqual(trace.initialEvents.count, 1)
        do { _ = try await driver.advance(); XCTFail("No retry") } catch { XCTAssertEqual(error as? ExpertSessionError, .endedSession) }
    }

    func testPavlicekPolicyDucksFirstHonorButCoversNineAgainstActualLegalState() throws {
        let file = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("evals/stage1/corpus/boards/pavlicek-deep-finesse.json")
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        let hands = try JSONDecoder().decode([Hand].self, from: JSONSerialization.data(withJSONObject: object["hands"]!))
        for (north, expected) in [("DK", "D8"), ("DQ", "D8"), ("D9", "DJ")] {
            var board = try BoardState(deal: Dictionary(uniqueKeysWithValues: hands.map { ($0.seat, $0.cards) }), contract: .init(level: 3, strain: .noTrump, declarer: .south))
            for (seat, card) in [(Seat.west,"SJ"),(.north,"S3"),(.east,"SK"),(.south,"SA"),(.south,"D3"),(.west,"D2"),(.north,north)] { try board.play(Card(card), by: seat) }
            let chosen = try OpponentPolicy.pavlicekEntry.choose(in: board)
            XCTAssertEqual(chosen, try Card(expected))
            try board.play(chosen, by: .east)
            XCTAssertEqual(board.events.last?.card, try Card(expected))
        }
    }

    func testUnresponsiveRuntimeCannotIgnoreRequestDeadline() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let executable = root.appendingPathComponent("ignore-termination")
        try "#!/bin/sh\ntrap '' TERM\nwhile :; do :; done\n".write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        let auth = root.appendingPathComponent("auth.json")
        try Data("{}".utf8).write(to: auth)
        let transport = try CodexPlayingTransport(executable: executable, authenticationFile: auth, evidenceDirectory: root.appendingPathComponent("evidence"), timeoutSeconds: 1)
        var board = try ruleBoard(strain: .noTrump, variant: "F")
        try board.play(Card("H2"), by: .west)
        let driver = BoardDriver(board: board, expert: ExpertSession(transport: transport), requestTimeoutSeconds: 1, runTimeoutSeconds: 0.05)
        do { _ = try await driver.advance(); XCTFail("Unresponsive runtime must fail") }
        catch let failure as ExpertFailure { XCTAssertLessThan(failure.elapsedSeconds, 0.6); XCTAssertFalse(failure.input.isEmpty) }
        let trace = await driver.trace()
        XCTAssertFalse(trace.complete)
        XCTAssertEqual(trace.controlledActions, 0)
        XCTAssertNotNil(trace.failure)
    }

    func testNestedRuntimeCannotHoldOutputPipePastRequestDeadline() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let executable = root.appendingPathComponent("nested-runtime")
        let childPID = root.appendingPathComponent("child.pid")
        let script = """
        #!/usr/bin/python3
        import os, signal, subprocess, sys, time
        if '--version' in sys.argv:
            print('recorded nested boundary')
            sys.exit(0)
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        child = subprocess.Popen(['/usr/bin/python3', '-c', 'import signal,time; signal.signal(signal.SIGTERM, signal.SIG_IGN); time.sleep(2.5)'])
        with open('\(childPID.path)', 'w') as saved:
            saved.write(str(child.pid))
        time.sleep(2.5)
        """
        try script.write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        let auth = root.appendingPathComponent("auth.json")
        try Data("{}".utf8).write(to: auth)
        let transport = try CodexPlayingTransport(executable: executable, authenticationFile: auth, evidenceDirectory: root.appendingPathComponent("evidence"), timeoutSeconds: 0.8)
        var board = try ruleBoard(strain: .noTrump, variant: "F")
        try board.play(Card("H2"), by: .west)
        do { _ = try await ExpertSession(transport: transport).decide(board.snapshot(controller: .south)); XCTFail("Nested runtime must time out") }
        catch let failure as ExpertFailure { XCTAssertLessThan(failure.elapsedSeconds, 1.3) }
        // The child is finite even on the red implementation, so this regression cannot leave a hung fixture.
        XCTAssertTrue(FileManager.default.fileExists(atPath: childPID.path))
        let inspection = Process(); let pipe = Pipe()
        inspection.executableURL = URL(fileURLWithPath: "/bin/ps")
        inspection.arguments = ["-o", "stat=", "-p", try String(contentsOf: childPID, encoding: .utf8)]
        inspection.standardOutput = pipe; inspection.standardError = FileHandle.nullDevice
        try inspection.run(); inspection.waitUntilExit()
        let state = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(state.isEmpty || state.hasPrefix("Z"), "Timed-out runtime must not leave an active descendant: \(state)")
    }

    func testFullTrumpDriverConsumesFiftyTwoCardsAndCreditsAllThirteenTricks() async throws {
        var board = try ruleBoard(strain: .spades)
        try board.play(Card("H2"), by: .west)
        let driver = BoardDriver(board: board, expert: ExpertSession(transport: FirstLegalTransport()), mechanicalSoleLegal: true)
        for _ in 0..<51 { _ = try await driver.advance() }
        let trace = await driver.trace()
        XCTAssertTrue(trace.complete)
        XCTAssertEqual(trace.declarerTricks, 13)
        XCTAssertEqual(trace.defenderTricks, 0)
        XCTAssertEqual(Set(trace.steps.last!.actualEvents.map(\.card)).count, 52)
        do { _ = try await driver.advance(); XCTFail("Completed driver rejects further play") } catch { XCTAssertEqual(error as? DomainError, .finished) }
        let unchanged = await driver.trace()
        XCTAssertTrue(unchanged.complete)
    }

    func testLegalChoiceSchemaUsesCompleteAuthoritativeFollowSuitSet() async throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let transport = SchemaCheckingTransport(expected: ["D8", "D6", "D5", "D3"], card: "D3")
        let decision = try await ExpertSession(transport: transport).decide(board.snapshot(controller: .south))
        XCTAssertEqual(decision.wireContractVersion, "stage1-legal-selectedCard-v3")
        XCTAssertEqual(decision.snapshot.legalCards.map(\.description), ["D8", "D6", "D5", "D3"])
    }
}

struct SchemaCheckingTransport: PlayingTransport {
    let expected: [String]
    let card: String
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        let schema = try JSONSerialization.jsonObject(with: Data(request.outputSchema.utf8)) as! [String: Any]
        let properties = schema["properties"] as! [String: Any]
        let selected = properties["selectedCard"] as! [String: Any]
        XCTAssertEqual(selected["enum"] as? [String], expected)
        return PlayingReply(rawOutput: "{\"plan\":{\"update\":\"replace\",\"text\":\"Use the actual available entries.\"},\"publicReason\":\"Follow suit.\",\"selectedCard\":\"\(card)\"}", identity: .init(requestedModel: "gpt-6-luna", requestedEffort: "medium", runtimeVersion: "recorded boundary", observedModel: nil, threadID: "schema", turnID: "1"))
    }
}

func ruleBoard(strain: Strain, variant: String = "A") throws -> BoardState {
    func cards(_ text: String) throws -> [Card] { try text.split(separator: " ").map { try Card(String($0)) } }
    var deal: [Seat: [Card]] = [
        .west: try cards("HA HK HQ HJ HT H9 H8 H7 H6 H5 H4 H3 H2"),
        .north: try cards("SA SK SQ SJ ST S9 S8 S7 S6 S5 S4 S2 C3"),
        .east: try cards("DA DK DQ DJ DT D9 D8 D7 D6 D5 D4 D3 D2"),
        .south: try cards("CA CK CQ CJ CT C9 C8 C7 C6 C5 C4 C2 S3")]
    func swap(_ a: Seat, _ ac: String, _ b: Seat, _ bc: String) throws {
        let x = try Card(ac), y = try Card(bc)
        deal[a]![deal[a]!.firstIndex(of: x)!] = y
        deal[b]![deal[b]!.firstIndex(of: y)!] = x
    }
    if variant == "U2" { try swap(.north, "SJ", .south, "C4"); try swap(.north, "S9", .east, "D2") }
    if variant == "F" { try swap(.north, "C3", .west, "H3") }
    return try BoardState(deal: deal, contract: .init(level: 3, strain: strain, declarer: .south))
}

actor FirstLegalTransport: PlayingTransport {
    var turn = 0
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        let schema = try JSONSerialization.jsonObject(with: Data(request.outputSchema.utf8)) as! [String: Any]
        let selected = (schema["properties"] as! [String: Any])["selectedCard"] as! [String: Any]
        let card = (selected["enum"] as! [String])[0]
        turn += 1
        let plan = turn == 1 ? "{\"update\":\"replace\",\"text\":\"Use actual legal cards.\"}" : "{\"update\":\"keep\",\"text\":null}"
        return PlayingReply(rawOutput: "{\"plan\":\(plan),\"publicReason\":\"Play an available card.\",\"selectedCard\":\"\(card)\"}", identity: .init(requestedModel: "gpt-6-luna", requestedEffort: "medium", runtimeVersion: "rule fixture only", observedModel: nil, threadID: "rules", turnID: "\(turn)"))
    }
}

struct DelayedTransport: PlayingTransport {
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        XCTAssertLessThanOrEqual(request.timeoutSeconds, 0.02)
        try await Task.sleep(for: .milliseconds(40))
        return try await SchemaCheckingTransport(expected: ["H3"], card: "H3").respond(to: request)
    }
}
