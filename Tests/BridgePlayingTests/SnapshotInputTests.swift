import XCTest
import BridgeDomain
import BridgeEngine
import BridgeExpert
import BridgeDriver

final class SnapshotInputTests: XCTestCase {
    func testDriverCarriesCurrentWinningPlayOnOpeningLeadAndPartnerContinuation() async throws {
        var board = try fixtureBoard()
        try board.play(Card("DQ"), by: .west)
        let driver = BoardDriver(board: board, expert: ExpertSession(transport: SequencePlayTransport(outputs: [
            try response(card: "D3", update: "replace", text: "Preserve entries."),
            try response(card: "DA", update: "keep"),
            try response(card: "C4", update: "keep"),
            try response(card: "CQ", update: "keep"),
            try response(card: "HK", update: "keep"),
            try response(card: "H6", update: "keep")
        ])), opponent: .lowLegal)
        var decisions: [DecisionRecord] = []
        for _ in 0..<10 {
            let step = try await driver.advance()
            if let decision = step.decision { decisions.append(decision) }
        }
        XCTAssertEqual(decisions.count, 6)
        guard decisions.count == 6 else { return }
        let opening = try jsonInput(decisions[0])
        XCTAssertEqual(opening["type"] as? String, "initial")
        XCTAssertEqual((opening["current"] as! [String: Any])["winningPlay"] as? [String: String],
                       ["seat": "W", "card": "DQ"])
        let onLead = try jsonInput(decisions[2])
        XCTAssertEqual(onLead["type"] as? String, "update")
        XCTAssertEqual((onLead["currentTrick"] as! [Any]).count, 0)
        XCTAssertTrue((onLead["current"] as! [String: Any])["winningPlay"] is NSNull)
        let partnerWinning = try jsonInput(decisions[5])
        XCTAssertEqual(partnerWinning["currentTrick"] as? [[String: String]], [
            ["seat": "N", "card": "HK"], ["seat": "E", "card": "H2"]
        ])
        XCTAssertEqual((partnerWinning["current"] as! [String: Any])["winningPlay"] as? [String: String],
                       ["seat": "N", "card": "HK"])
        XCTAssertEqual(decisions[5].action.card, try Card("H6"))
        XCTAssertEqual(decisions[5].identity.threadID, decisions[0].identity.threadID)
    }

    func testDriverPreservesPublicBackgroundAndOfficialObjectiveAcrossSnapshots() async throws {
        let background = "West opened 1NT; defensive carding agreements are unknown."
        let objective = "Maximize the chance of making the contract."
        var board = try fixtureBoard(objective: objective, publicBackground: background)
        try board.play(Card("DQ"), by: .west)
        let driver = BoardDriver(board: board, expert: ExpertSession(transport: SequencePlayTransport(outputs: [
            try response(card: "D3", update: "replace", text: "Preserve entries."),
            try response(card: "DA", update: "keep")
        ])))
        let initial = try await driver.advance()
        _ = try await driver.advance()
        let update = try await driver.advance()
        for step in [initial, update] {
            let input = try jsonInput(XCTUnwrap(step.decision))
            XCTAssertEqual(input["publicBackground"] as? String, background)
            XCTAssertEqual(input["objective"] as? String, objective)
        }
        XCTAssertEqual(update.execution.event.card, try Card("DA"))
    }

    func testMatchpointBoardWithoutExplicitObjectiveUsesScoringNeutralAim() async throws {
        var board = try fixtureBoard(scoring: "MP")
        try board.play(Card("DQ"), by: .west)
        let driver = BoardDriver(board: board, expert: ExpertSession(transport: RecordedPlayTransport(
            output: try response(card: "D3", update: "replace", text: "Preserve entries."))))
        let step = try await driver.advance()
        let input = try jsonInput(XCTUnwrap(step.decision))
        XCTAssertEqual(input["scoring"] as? String, "MP")
        XCTAssertEqual(input["objective"] as? String,
                       "Choose a line that aims for the best expected result under the stated scoring conditions.")
    }

    func testDoublingFromStoredContractReachesActualExpertInput() async throws {
        for doubling in ["undoubled", "doubled", "redoubled"] {
            let data = Data("{\"level\":3,\"strain\":\"noTrump\",\"declarer\":\"south\",\"doubling\":\"\(doubling)\"}".utf8)
            let contract = try JSONDecoder().decode(Contract.self, from: data)
            var board = try fixtureBoard(contract: contract)
            try board.play(Card("DQ"), by: .west)
            let decision = try await ExpertSession(transport: RecordedPlayTransport(output: response(card: "D3", update: "replace", text: "Preserve entries.")))
                .decide(board.snapshot(controller: .south))
            let sentContract = try jsonInput(decision)["contract"] as! [String:Any]
            XCTAssertEqual(sentContract["doubling"] as? String, doubling)
            let stored = try JSONSerialization.jsonObject(with: JSONEncoder().encode(contract)) as! [String:Any]
            XCTAssertEqual(stored["doubling"] as? String, doubling)
        }
    }

    func testPlanOperationsCarryExactTextThenClearItWhileFactsAdvance() async throws {
        var board = try fixtureBoard()
        try board.play(Card("DQ"), by: .west)
        let firstPlan = " Preserve entries.\nDevelop clubs later. "
        let replacement = " Cash the remaining diamond winner, then reassess clubs. "
        let expert = ExpertSession(transport: SequencePlayTransport(outputs: [
            try response(card: "D3", update: "replace", text: firstPlan),
            try response(card: "DA", update: "keep"),
            try response(card: "DK", update: "replace", text: replacement),
            try response(card: "D5", update: "withdraw"),
            try response(card: "CA", update: "keep")
        ]))
        let first = try await expert.decide(board.snapshot(controller: .south))
        try board.apply(first.action)
        try await expert.commit(first, execution: ActualExecution(event: board.events.last!, source: .model))
        try board.play(Card("D4"), by: .east)
        let second = try await expert.decide(board.snapshot(controller: .south))
        XCTAssertEqual(try jsonInput(second)["effectivePlan"] as? String, firstPlan)
        try board.apply(second.action)
        try await expert.commit(second, execution: ActualExecution(event: board.events.last!, source: .model))
        let third = try await expert.decide(board.snapshot(controller: .south))
        XCTAssertEqual(try jsonInput(third)["effectivePlan"] as? String, firstPlan)
        try board.apply(third.action)
        try await expert.commit(third, execution: ActualExecution(event: board.events.last!, source: .model))
        try board.play(Card("D2"), by: .west)
        let fourth = try await expert.decide(board.snapshot(controller: .south))
        XCTAssertEqual(try jsonInput(fourth)["effectivePlan"] as? String, replacement)
        try board.apply(fourth.action)
        try await expert.commit(fourth, execution: ActualExecution(event: board.events.last!, source: .model))
        try board.play(Card("D7"), by: .east)
        let fifth = try await expert.decide(board.snapshot(controller: .south))
        let input = try jsonInput(fifth)
        XCTAssertTrue(input["effectivePlan"] is NSNull)
        XCTAssertEqual((input["hands"] as! [String:[String:String]])["S"]?["D"], "")
        XCTAssertEqual((input["completedTricks"] as! [Any]).count, 2)
        XCTAssertEqual(fifth.identity.threadID, first.identity.threadID)
        XCTAssertNotEqual(fifth.identity.turnID, fourth.identity.turnID)
        XCTAssertNil(fifth.effectivePlan)
        try board.apply(fifth.action)
        try await expert.commit(fifth, execution: ActualExecution(event: board.events.last!, source: .model))
    }

    func testCompleteUpdateAfterTwoTricksRetainsAllActualPlaysAndRemainingHands() async throws {
        var board = try fixtureBoard()
        try board.play(Card("DQ"), by: .west)
        let plan = " Cash diamond winners.\nThen develop clubs while keeping entries. "
        let expert = ExpertSession(transport: SequencePlayTransport(outputs: [
            try response(card: "D3", update: "replace", text: plan),
            try response(card: "SA", update: "keep")
        ]))
        let initial = try await expert.decide(board.snapshot(controller: .south))
        try board.apply(initial.action)
        try await expert.commit(initial, execution: ActualExecution(event: board.events.last!, source: .model))
        for (seat, code) in [(Seat.east,"D4"),(.south,"DA"),(.south,"CA"),(.west,"C3"),(.north,"C2"),(.east,"C5")] {
            try board.play(Card(code), by: seat)
        }
        let update = try await expert.decide(board.snapshot(controller: .south))
        let input = try jsonInput(update)
        XCTAssertEqual(input["type"] as? String, "update")
        XCTAssertEqual(input["effectivePlan"] as? String, plan)
        let hands = input["hands"] as! [String: [String: String]]
        XCTAssertEqual(hands["S"], ["S":"A94", "H":"A63", "D":"K", "C":"K864"])
        XCTAssertEqual(hands["N"], ["S":"862", "H":"K74", "D":"865", "C":"Q7"])
        XCTAssertEqual(Set(hands.keys), ["S", "N"])
        XCTAssertEqual((input["currentTrick"] as? [Any])?.count, 0)
        let tricks = input["completedTricks"] as! [[String: Any]]
        XCTAssertEqual(tricks.count, 2)
        guard tricks.count == 2 else { return }
        XCTAssertEqual(tricks.map { $0["winner"] as! String }, ["S", "S"])
        XCTAssertEqual(tricks[0]["plays"] as? [[String:String]], [
            ["seat":"W","card":"DQ"], ["seat":"N","card":"D3"],
            ["seat":"E","card":"D4"], ["seat":"S","card":"DA"]])
        XCTAssertEqual(tricks[1]["plays"] as? [[String:String]], [
            ["seat":"S","card":"CA"], ["seat":"W","card":"C3"],
            ["seat":"N","card":"C2"], ["seat":"E","card":"C5"]])
        XCTAssertEqual((input["current"] as! [String:Any])["tricksWon"] as? [String:Int], ["declarer":2,"defenders":0])
        XCTAssertEqual(initial.identity.threadID, update.identity.threadID)
        XCTAssertNotEqual(initial.session.id, update.session.id)
        try board.apply(update.action)
        try await expert.commit(update, execution: ActualExecution(event: board.events.last!, source: .model))
        XCTAssertEqual(board.events.count, 9)
    }
}

private func fixtureBoard(contract: Contract? = nil, scoring: String = "IMP", objective: String? = nil, publicBackground: String? = nil) throws -> BoardState {
    let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let data = try Data(contentsOf: repository.appendingPathComponent("evals/stage1/corpus/boards/synthetic.json"))
    let fixture = try JSONDecoder().decode(SnapshotFixture.self, from: data)
    let deal = Dictionary(uniqueKeysWithValues: fixture.hands.map { ($0.seat, $0.cards) })
    if let objective {
        return try BoardState(deal: deal, contract: contract ?? fixture.contract, scoring: scoring, objective: objective, publicBackground: publicBackground)
    }
    return try BoardState(deal: deal, contract: contract ?? fixture.contract, scoring: scoring, publicBackground: publicBackground)
}
private struct SnapshotFixture: Decodable { let hands: [Hand]; let contract: Contract }
private func jsonInput(_ decision: DecisionRecord) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: Data(decision.input.utf8)) as! [String: Any]
}
private func response(card: String, update: String, text: String? = nil) throws -> String {
    let value: [String:Any] = ["publicReason":"Play the legal current card.", "selectedCard":card,
                              "plan":["update":update, "text":text as Any? ?? NSNull()]]
    return String(decoding: try JSONSerialization.data(withJSONObject: value), as: UTF8.self)
}
