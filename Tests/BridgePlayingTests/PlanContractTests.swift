import XCTest
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeCodex

final class PlanContractTests: XCTestCase {
    func testPublicExpertReceivesRuleDerivedCurrentWinningPlay() async throws {
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let expert = ExpertSession(transport: SequencePlayTransport(outputs: [
            #"{"plan":{"update":"replace","text":"Establish clubs while preserving entries."},"publicReason":"Follow the diamond lead.","selectedCard":"D3"}"#,
            #"{"plan":{"update":"keep","text":null},"publicReason":"Follow under partner's ace.","selectedCard":"C2"}"#
        ]))
        let initial = try await expert.decide(board.snapshot(controller: .south))
        XCTAssertTrue(initial.input.contains("Current winning play so far: West DQ."), initial.input)
        try board.apply(initial.action)
        try board.play(Card("D4"), by: .east)
        try board.play(Card("DK"), by: .south)
        try board.play(Card("CA"), by: .south)
        try board.play(board.legalCards()[0], by: .west)
        let continuation = try await expert.decide(board.snapshot(controller: .south))
        XCTAssertTrue(continuation.input.contains("Current winning play so far: South CA."), continuation.input)
        XCTAssertFalse(continuation.input.contains("South (declarer):"))
        XCTAssertFalse(continuation.input.contains("North (dummy):"))
    }

    func testFourHistoricalAmbiguousPlansRemainFailuresWithOriginalOutputAndNoRetry() async throws {
        let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let matrix = repository.appendingPathComponent("evals/stage1/evidence/ticket42/matrix")
        for attempt in ["short-3-r2", "short-4-r1", "short-4-r3", "short-5-r3"] {
            let directory = matrix.appendingPathComponent(attempt)
            let trace = try JSONDecoder().decode(SavedTrace.self, from: Data(contentsOf: directory.appendingPathComponent("play/trace.json")))
            let specification = try JSONDecoder().decode(SavedAttempt.self, from: Data(contentsOf: directory.appendingPathComponent("attempt.json")))
            let fixture = try JSONDecoder().decode(SavedFixture.self, from: Data(contentsOf: repository.appendingPathComponent("evals/stage1/corpus/" + specification.board)))
            let failure = try JSONDecoder().decode(SavedFailure.self, from: Data(contentsOf: directory.appendingPathComponent("play/failure.json")))
            let records = trace.steps.compactMap(\.decision)
            let expert = ExpertSession(transport: SequencePlayTransport(outputs: records.map(\.rawOutput) + [failure.rawOutput]))
            for record in records { _ = try await expert.decide(record.snapshot) }
            var board = try BoardState(id: trace.boardID, deal: Dictionary(uniqueKeysWithValues: fixture.hands.map { ($0.seat, $0.cards) }), contract: fixture.contract, vulnerability: fixture.vulnerability, scoring: fixture.scoring, objective: fixture.objective, publicBackground: fixture.publicBackground)
            for event in trace.initialEvents + trace.steps.map({ $0.execution.event }) { try board.play(event.card, by: event.seat) }
            let eventsBefore = board.events
            let snapshot = try board.snapshot(controller: .south)
            do {
                _ = try await expert.decide(snapshot)
                XCTFail("Historical keep with text must not be repaired or executed: \(attempt)")
            } catch let rejected as ExpertFailure {
                XCTAssertEqual(rejected.category, .invalidOutput, attempt)
                XCTAssertEqual(rejected.detail, "ambiguousPlan", attempt)
                XCTAssertEqual(rejected.rawOutput, failure.rawOutput, attempt)
                XCTAssertEqual(board.events, eventsBefore, attempt)
            }
            do { _ = try await expert.decide(snapshot); XCTFail("Failure must end the session") }
            catch { XCTAssertEqual(error as? ExpertSessionError, .endedSession, attempt) }
        }
    }

    func testPublicContextIdentifiesLeadAndThirdHandWithoutRepeatingHoldings() async throws {
        let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let matrix = repository.appendingPathComponent("evals/stage1/evidence/ticket42/matrix")
        for (attempt, decision, expectedPhase, expectedChoices) in [
            ("short-2-r3", 7, "Current action: South (declarer) leads a new trick.", "Legal current choices: SA, S9, S4, H6, H3, DK, CA, CK, C8, C6."),
            ("full-reserved-r1", 4, "Current action: North (dummy) plays third in the current trick; clubs were led.", "Legal current choices: CA, C6, C5.")
        ] {
            let play = matrix.appendingPathComponent(attempt + "/play")
            let first = try JSONDecoder().decode(DecisionRecord.self, from: Data(contentsOf: play.appendingPathComponent("decision-0001/decision.json")))
            let current = try JSONDecoder().decode(DecisionRecord.self, from: Data(contentsOf: play.appendingPathComponent(String(format: "decision-%04d/decision.json", decision))))
            let reply = try JSONSerialization.data(withJSONObject: ["plan": ["update": "keep", "text": NSNull()], "selectedCard": current.action.card.description, "publicReason": "Play the current legal card from the acting hand."])
            let expert = ExpertSession(transport: SequencePlayTransport(outputs: [first.rawOutput, String(decoding: reply, as: UTF8.self)]))
            let initial = try await expert.decide(first.snapshot)
            XCTAssertTrue(initial.input.contains("diamonds: DA DK") || initial.input.contains("diamonds: DA D7 D2"))
            let result = try await expert.decide(current.snapshot)
            XCTAssertTrue(result.input.contains(expectedPhase), result.input)
            XCTAssertTrue(result.input.contains(expectedChoices), result.input)
            if decision == 4 { XCTAssertTrue(result.input.contains("Current trick: South C3; West C4.")) }
            XCTAssertFalse(result.input.contains("South (declarer):"))
            XCTAssertFalse(result.input.contains("North (dummy):"))
            XCTAssertFalse(result.input.contains("East ("))
            XCTAssertFalse(result.input.contains("West ("))
            XCTAssertFalse(result.input.contains(first.effectivePlan!))
        }
    }

    func testSerializedAppServerSchemaExcludesAmbiguousPlansAndKeepsLifecycle() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let python = try schemaValidationPython()
        let runtime = root.appendingPathComponent("schema-checking-app-server")
        let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let historical = try ["short-3-r2", "short-4-r1", "short-4-r3", "short-5-r3"].map { attempt in
            try JSONDecoder().decode(SavedFailure.self, from: Data(contentsOf: repository.appendingPathComponent("evals/stage1/evidence/ticket42/matrix/" + attempt + "/play/failure.json"))).rawOutput
        }
        try JSONEncoder().encode(historical).write(to: root.appendingPathComponent("historical-replies.json"))
        let script = "#!\(python)\n" + #"""
        import json, sys
        if '--version' in sys.argv:
            print('schema-checking external boundary')
            sys.exit(0)
        import jsonschema, pathlib
        historical = json.loads(pathlib.Path(__file__).with_name('historical-replies.json').read_text())
        turn = 0
        replies = [
            {'plan': {'update': 'replace', 'text': 'Establish clubs with entries.'}, 'publicReason': 'Follow low.', 'selectedCard': 'D3'},
            {'plan': {'update': 'keep', 'text': None}, 'publicReason': 'Win in South.', 'selectedCard': 'DA'},
            {'plan': {'update': 'replace', 'text': 'Start clubs while keeping entries.'}, 'publicReason': 'Lead a club.', 'selectedCard': 'C4'},
            {'plan': {'update': 'withdraw', 'text': None}, 'publicReason': 'Win from dummy while reassessing.', 'selectedCard': 'CQ'},
        ]
        for line in sys.stdin:
            request = json.loads(line)
            if 'id' not in request:
                continue
            method = request.get('method')
            result = {}
            if method == 'model/list':
                result = {'data': [{'model': 'gpt-6-luna', 'supportedReasoningEfforts': [{'reasoningEffort': 'medium'}]}]}
            elif method == 'thread/start':
                result = {'thread': {'id': 'schema-thread'}, 'model': 'gpt-6-luna'}
            elif method == 'turn/start':
                # Validate the actual serialized public Codex request, not a Swift schema constant.
                schema = request['params']['outputSchema']
                jsonschema.Draft202012Validator.check_schema(schema)
                validator = jsonschema.Draft202012Validator(schema)
                plan_validator = jsonschema.Draft202012Validator(schema['properties']['plan'])
                for raw in historical:
                    if plan_validator.is_valid(json.loads(raw)['plan']):
                        print(json.dumps({'id': request['id'], 'error': {'message': 'actual serialized schema permits a historical ambiguous plan'}}), flush=True)
                        sys.exit(1)
                card = schema['properties']['selectedCard']['enum'][0]
                cases = [
                    ('keep', 'new text', False), ('withdraw', 'new text', False),
                    ('replace', '', False), ('replace', '   ', False), ('replace', None, False),
                    ('replace', 'Concrete route.', True),
                    ('keep', None, turn != 0), ('withdraw', None, turn != 0),
                ]
                for update, text, expected in cases:
                    answer = {'plan': {'update': update, 'text': text}, 'publicReason': 'Current choice.', 'selectedCard': card}
                    actual = validator.is_valid(answer)
                    if actual != expected:
                        print(json.dumps({'id': request['id'], 'error': {'message': f'plan contract mismatch: {update}/{text!r}, accepted={actual}, expected={expected}'}}), flush=True)
                        sys.exit(1)
                reply = replies[turn]
                validator.validate(reply)
                turn += 1
                result = {'turn': {'id': f'turn-{turn}'}}
            print(json.dumps({'id': request['id'], 'result': result}), flush=True)
            if method == 'turn/start':
                print(json.dumps({'method': 'turn/completed', 'params': {'threadId': 'schema-thread', 'turn': {'id': f'turn-{turn}', 'status': 'completed', 'items': [{'type': 'agentMessage', 'text': json.dumps(reply)}]}}}), flush=True)
        """#
        try script.write(to: runtime, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: runtime.path)
        let auth = root.appendingPathComponent("auth.json")
        try Data("{}".utf8).write(to: auth)
        let transport = try CodexPlayingTransport(executable: runtime, authenticationFile: auth, evidenceDirectory: root.appendingPathComponent("evidence"), timeoutSeconds: 10)
        let expert = ExpertSession(transport: transport)
        var board = try BoardState(deal: syntheticDeal(), contract: .init(level: 3, strain: .noTrump, declarer: .south))
        try board.play(Card("DQ"), by: .west)
        let initial = try await expert.decide(board.snapshot(controller: .south))
        try board.apply(initial.action)
        try board.play(board.legalCards()[0], by: .east)
        let kept = try await expert.decide(board.snapshot(controller: .south))
        XCTAssertEqual(kept.planAssociation, initial.planAssociation)
        try board.apply(kept.action)
        let replaced = try await expert.decide(board.snapshot(controller: .south))
        XCTAssertEqual(replaced.effectivePlan, "Start clubs while keeping entries.")
        XCTAssertNotEqual(replaced.planAssociation?.sourceSessionID, initial.planAssociation?.sourceSessionID)
        try board.apply(replaced.action)
        try board.play(board.legalCards()[0], by: .west)
        let withdrawn = try await expert.decide(board.snapshot(controller: .south))
        XCTAssertNil(withdrawn.planAssociation)
        XCTAssertNil(withdrawn.effectivePlan)
    }
}

private func schemaValidationPython() throws -> String {
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [ProcessInfo.processInfo.environment["BRIDGE_TEST_PYTHON"] ?? "python3", "-c", "import jsonschema, sys; print(sys.executable)"]
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    try process.run(); process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "BridgeTestDependencies", code: 1, userInfo: [NSLocalizedDescriptionKey: "Set BRIDGE_TEST_PYTHON to Python with evals/stage1/requirements-test.txt installed (jsonschema is required)."])
    }
    return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
}

private struct SavedAttempt: Decodable { let board: String }
private struct SavedFailure: Decodable { let rawOutput: String }
private struct SavedFixture: Decodable {
    let contract: Contract
    let hands: [Hand]
    let vulnerability: String
    let scoring: String
    let objective: String
    let publicBackground: String?
}
private struct SavedTrace: Decodable {
    let boardID: UUID
    let initialEvents: [PlayEvent]
    let steps: [SavedStep]
}
private struct SavedStep: Decodable {
    let execution: ActualExecution
    let decision: DecisionRecord?
}
