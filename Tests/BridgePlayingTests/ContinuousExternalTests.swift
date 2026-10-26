import XCTest
import BridgeDomain
import BridgeDriver
import BridgeExpert

final class ContinuousExternalTests: XCTestCase {
    func testAuctionAdviceRequiresMatchingActualConfirmationAndCurrentBiddingGuidance() async throws {
        let player = ContinuousBoundary(outputs: [
            #"{"selectedAction":"P","publicReason":"No opening values.","plan":{"update":"replace","text":"Pass and reassess partner's action."}}"#,
            #"{"selectedAction":"S2","publicReason":"Lead a low spade.","plan":{"update":"replace","text":"Develop spades while retaining the ace."}}"#
        ], role: "player")
        let reviewer = ContinuousBoundary(outputs: Array(repeating: #"{"verdict":"approve","blockingFindings":[],"advisorySuggestions":[]}"#, count: 2), role: "review")
        let config = ContinuousBoardConfiguration(boardID: UUID(), userSeat: .north, dealer: .north,
            vulnerability: "neither", scoring: "IMP", objective: "Best IMP result", agreements: "Natural; other agreements unknown",
            initialHand: Hand(seat: .north, cards: try ["S2","S3","S4","S5","H2","H3","H4","D2","D3","D4","C2","C3","C4"].map(Card.init)))
        let session = try ExternalBoardSession(continuous: config, transport: player, reviewer: reviewer)
        let advice = try await session.decideContinuous()
        XCTAssertEqual(advice.decision?.snapshot.phase, .bidding)
        let before = try await session.continuousStatus()
        XCTAssertEqual(before.snapshot.auction.count, 0)
        do {
            _ = try await session.observeCall(.init(sequence: 0, seat: .north, call: AuctionCall("1C")), authorization: advice.authorization)
            XCTFail("A pass authorization cannot submit another call")
        } catch {}
        _ = try await session.observeCall(.init(sequence: 0, seat: .north, call: AuctionCall("P")), authorization: advice.authorization)
        _ = try await session.observeCall(.init(sequence: 1, seat: .east, call: AuctionCall("1NT")))
        _ = try await session.observeCall(.init(sequence: 2, seat: .south, call: AuctionCall("P")))
        _ = try await session.observeCall(.init(sequence: 3, seat: .west, call: AuctionCall("P")))
        let requests = await player.requests
        XCTAssertEqual(requests.count, 1)
        XCTAssertTrue(requests[0].input.contains("BIDDING TASK"))
        XCTAssertFalse(requests[0].input.contains("DEFENSE TASK"))
    }
}

actor ContinuousBoundary: PlayingTransport {
    var outputs: [String]
    let role: String
    var requests: [PlayingRequest] = []
    init(outputs: [String], role: String) { self.outputs = outputs; self.role = role }
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        requests.append(request)
        guard !outputs.isEmpty else { throw NSError(domain: "No recorded response", code: 1) }
        return PlayingReply(rawOutput: outputs.removeFirst(), identity: .init(requestedModel: "gpt-6.1-sol", requestedEffort: "medium", runtimeVersion: "recorded", observedModel: "gpt-6.1-sol", observedEffort: "medium", threadID: role == "player" ? "continuous-player" : UUID().uuidString, turnID: UUID().uuidString), requestID: request.id)
    }
}
