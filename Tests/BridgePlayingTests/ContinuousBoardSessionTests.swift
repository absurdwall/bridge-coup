import XCTest
import BridgeDomain
import BridgeDriver
import BridgeExpert

/// Synthetic holdings and recorded replies exercise the shipped external session boundary.
final class ContinuousBoardSessionTests: XCTestCase {
    private let approve = #"{"verdict":"approve","blockingFindings":[],"advisorySuggestions":[]}"#
    private let revise = #"{"verdict":"revise","blockingFindings":[{"claim":"Plan needs clarification","evidence":"Recorded test objection","requestedChange":"Clarify the continuation"}],"advisorySuggestions":[]}"#

    private func hand(_ seat: Seat, _ suit: String) throws -> Hand {
        .init(seat: seat, cards: try ["2","3","4","5","6","7","8","9","T","J","Q","K","A"].map { try Card(suit + $0) })
    }
    private func auction(_ calls: [String], dealer: Seat) throws -> [AuctionEvent] {
        try calls.enumerated().map { index, call in
            .init(sequence: index, seat: (0..<index % 4).reduce(dealer) { seat, _ in seat.next }, call: try AuctionCall(call))
        }
    }
    private func config(user: Seat = .north, dealer: Seat = .north, calls: [String] = [], events: [PlayEvent] = [],
                        revealed: [Hand] = [], contract: Contract? = nil) throws -> ContinuousBoardConfiguration {
        .init(boardID: UUID(), userSeat: user, dealer: dealer, vulnerability: "neither", scoring: "MP",
              objective: "Best MP result including overtricks", agreements: "Synthetic natural test agreement; carding unknown",
              initialHand: try hand(user, "S"), auction: try auction(calls, dealer: dealer), events: events,
              revealedHands: revealed, confirmedContract: contract)
    }
    private func advice(_ action: String, plan: String? = "Synthetic conditional test plan") -> String {
        let change: [String: Any] = plan.map { ["update": "replace", "text": $0] } ?? ["update": "keep", "text": NSNull()]
        return String(decoding: try! JSONSerialization.data(withJSONObject: ["selectedAction": action, "publicReason": "Synthetic recorded public rationale", "plan": change]), as: UTF8.self)
    }
    private func session(_ configuration: ContinuousBoardConfiguration, actions: [String], verdicts: [String]? = nil, started: Date = Date()) throws -> (ExternalBoardSession, ContinuousBoundary, ContinuousBoundary) {
        let player = ContinuousBoundary(outputs: actions, role: "player")
        let reviewer = ContinuousBoundary(outputs: verdicts ?? Array(repeating: approve, count: actions.count), role: "review")
        return (try ExternalBoardSession(continuous: configuration, transport: player, reviewer: reviewer, started: started), player, reviewer)
    }
    private func rejects(_ operation: () async throws -> Void, file: StaticString = #filePath, line: UInt = #line) async {
        do { try await operation(); XCTFail("Expected rejection", file: file, line: line) } catch {}
    }

    func testActualCompetitiveAuctionValidatesCallsAndFindsFirstPartnershipStrainBidder() async throws {
        let (board, _, _) = try session(config(user: .north, dealer: .east, calls: ["1H", "P", "2H"]), actions: [advice("X"), advice("P", plan: nil)])
        let before = try await board.continuousStatus()
        XCTAssertTrue(before.snapshot.legalCalls.map(\.description).contains("X"))
        XCTAssertFalse(before.snapshot.legalCalls.map(\.description).contains("XX"))
        let double = try await board.decideContinuous()
        await rejects { _ = try await board.observeCall(.init(sequence: 3, seat: .north, call: AuctionCall("2D")), authorization: double.authorization) }
        _ = try await board.observeCall(.init(sequence: 3, seat: .north, call: AuctionCall("X")), authorization: double.authorization)
        _ = try await board.observeCall(.init(sequence: 4, seat: .east, call: AuctionCall("XX")))
        _ = try await board.observeCall(.init(sequence: 5, seat: .south, call: AuctionCall("P")))
        _ = try await board.observeCall(.init(sequence: 6, seat: .west, call: AuctionCall("P")))
        let redoubled = try await board.continuousStatus()
        XCTAssertFalse(redoubled.snapshot.legalCalls.map(\.description).contains("X"))
        let pass = try await board.decideContinuous()
        _ = try await board.observeCall(.init(sequence: 7, seat: .north, call: AuctionCall("P")), authorization: pass.authorization)
        let result = try await board.continuousStatus()
        let actual = try Contract(level: 2, strain: .hearts, declarer: .east, doubling: .redoubled)
        XCTAssertEqual(result.snapshot.contract, actual)
        XCTAssertNil(result.snapshot.actingSeat)
        await rejects { try await board.confirmContract(Contract(level: 2, strain: .hearts, declarer: .west, doubling: .redoubled)) }
        try await board.confirmContract(actual)
        let confirmed = try await board.continuousStatus()
        XCTAssertEqual(confirmed.snapshot.actingSeat, .south)
        XCTAssertTrue(confirmed.snapshot.contractConfirmed)
    }

    func testFourActualPassesFinishWithoutInventingAContractOrPlayStage() async throws {
        let (board, player, _) = try session(config(), actions: [advice("P")])
        let pass = try await board.decideContinuous()
        _ = try await board.observeCall(.init(sequence: 0, seat: .north, call: AuctionCall("P")), authorization: pass.authorization)
        for (sequence, seat) in [(1, Seat.east), (2, .south), (3, .west)] {
            _ = try await board.observeCall(.init(sequence: sequence, seat: seat, call: AuctionCall("P")))
        }
        let status = try await board.continuousStatus()
        XCTAssertEqual(status.snapshot.phase, .finished)
        XCTAssertNil(status.snapshot.contract)
        XCTAssertNil(status.snapshot.actingSeat)
        XCTAssertEqual(status.snapshot.events.count, 0)
        await rejects { _ = try await board.decideContinuous() }
        let requests = await player.requests
        XCTAssertEqual(requests.count, 1)
    }

    func testDefenseExposesDummyAfterLeadAndNeverControlsVisibleDummyOrPartner() async throws {
        let contract = try Contract(level: 1, strain: .noTrump, declarer: .west)
        let (board, _, _) = try session(config(dealer: .west, calls: ["1NT", "P", "P", "P"]), actions: [advice("S2"), advice("S3", plan: nil)])
        try await board.confirmContract(contract)
        await rejects { try await board.reveal(self.hand(.east, "D")) }
        let lead = try await board.decideContinuous()
        XCTAssertEqual(lead.decision?.snapshot.phase, .openingLead)
        XCTAssertEqual(lead.decision?.snapshot.hands.map(\.seat), [.north])
        await rejects { _ = try await board.observeContinuousPlay(.init(sequence: 0, seat: .north, card: Card("S2")), authorization: UUID()) }
        _ = try await board.observeContinuousPlay(.init(sequence: 0, seat: .north, card: Card("S2")), authorization: lead.authorization)
        await rejects { _ = try await board.observeContinuousPlay(.init(sequence: 0, seat: .north, card: Card("S2")), authorization: lead.authorization) }
        try await board.reveal(hand(.east, "D"))
        await rejects { try await board.reveal(self.hand(.south, "H")) }
        await rejects { _ = try await board.decideContinuous() }
        await rejects { _ = try await board.observeContinuousPlay(.init(sequence: 1, seat: .east, card: Card("D2")), authorization: lead.authorization) }
        _ = try await board.observeContinuousPlay(.init(sequence: 1, seat: .east, card: Card("D2")))
        _ = try await board.observeContinuousPlay(.init(sequence: 2, seat: .south, card: Card("H2")))
        _ = try await board.observeContinuousPlay(.init(sequence: 3, seat: .west, card: Card("C2")))
        let defense = try await board.decideContinuous()
        XCTAssertEqual(defense.decision?.snapshot.phase, .defense)
        XCTAssertEqual(defense.decision?.snapshot.controller, .north)
        XCTAssertEqual(Set(defense.decision!.snapshot.hands.map(\.seat)), [.north, .east])
        XCTAssertEqual(defense.decision?.effectivePlan, lead.decision?.effectivePlan)
        await rejects { _ = try await board.observeContinuousPlay(.init(sequence: 4, seat: .north, card: Card("S3")), authorization: lead.authorization) }
        _ = try await board.observeContinuousPlay(.init(sequence: 4, seat: .north, card: Card("S3")), authorization: defense.authorization)
    }

    func testPartnerDeclarerSwitchesControllerAndAuthorizesBothPartnershipHands() async throws {
        let actual = try Contract(level: 1, strain: .noTrump, declarer: .south)
        let (board, player, reviewer) = try session(config(dealer: .south, calls: ["1NT", "P", "P", "P"]), actions: [advice("S2"), advice("D2", plan: nil)])
        let unconfirmed = try await board.continuousStatus()
        XCTAssertEqual(unconfirmed.snapshot.controller, .north)
        try await board.confirmContract(actual)
        _ = try await board.observeContinuousPlay(.init(sequence: 0, seat: .west, card: Card("C2")))
        try await board.reveal(hand(.south, "D"))
        let dummy = try await board.decideContinuous()
        XCTAssertEqual(dummy.decision?.snapshot.controller, .south)
        XCTAssertEqual(dummy.actingSeat, .north)
        XCTAssertEqual(Set(dummy.decision!.snapshot.hands.map(\.seat)), [.north, .south])
        _ = try await board.observeContinuousPlay(.init(sequence: 1, seat: .north, card: Card("S2")), authorization: dummy.authorization)
        _ = try await board.observeContinuousPlay(.init(sequence: 2, seat: .east, card: Card("H2")))
        let declarer = try await board.decideContinuous()
        XCTAssertEqual(declarer.actingSeat, .south)
        XCTAssertEqual(declarer.decision?.snapshot.controller, .south)
        _ = try await board.observeContinuousPlay(.init(sequence: 3, seat: .south, card: Card("D2")), authorization: declarer.authorization)
        let playerRequests = await player.requests
        let reviewRequests = await reviewer.requests
        XCTAssertEqual(playerRequests.count, 2)
        XCTAssertEqual(reviewRequests.count, 2)
        for (index, request) in playerRequests.enumerated() {
            let input = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(request.input.utf8)) as? [String: Any])
            let snapshot = try XCTUnwrap(input["latestSnapshot"] as? [String: Any])
            let holdings = try XCTUnwrap(snapshot["hands"] as? [[String: Any]])
            XCTAssertEqual(snapshot["controller"] as? String, "south")
            XCTAssertEqual(snapshot["actingSeat"] as? String, index == 0 ? "north" : "south")
            XCTAssertEqual(Set(holdings.compactMap { $0["seat"] as? String }), ["north", "south"])
            XCTAssertTrue(holdings.allSatisfy { $0["cards"] is [String] })
            XCTAssertTrue(input.keys.contains("effectivePlan"))
            if index == 0 { XCTAssertTrue(input["effectivePlan"] is NSNull) }
            else { XCTAssertEqual(input["effectivePlan"] as? String, dummy.decision?.effectivePlan) }
            let guidance = try XCTUnwrap(input["currentPhaseGuidance"] as? String)
            XCTAssertTrue(guidance.contains("CURRENT CONTINUOUS PROTOCOL ADAPTER"))
            XCTAssertFalse(guidance.contains("DEFENSE TASK"))
            let schema = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(request.outputSchema.utf8)) as? [String: Any])
            let properties = try XCTUnwrap(schema["properties"] as? [String: Any])
            XCTAssertNotNil(properties["selectedAction"])
            XCTAssertNil(properties["selectedCard"])
            let review = reviewRequests[index]
            XCTAssertTrue(review.instructions.contains("CURRENT CONTINUOUS REVIEW PROTOCOL ADAPTER"))
            XCTAssertFalse(review.instructions.contains("DEFENSE TASK"))
            let reviewInput = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(review.input.utf8)) as? [String: Any])
            let candidate = try XCTUnwrap(reviewInput["candidate"] as? [String: Any])
            XCTAssertEqual(candidate["selectedAction"] as? String, index == 0 ? "S2" : "D2")
            XCTAssertNil(candidate["selectedCard"])
            XCTAssertEqual(reviewInput["currentPhaseGuidance"] as? String, guidance)
            XCTAssertTrue(reviewInput.keys.contains("effectivePlan"))
            let reviewedSnapshot = try XCTUnwrap(reviewInput["latestSnapshot"] as? [String: Any])
            XCTAssertEqual(NSDictionary(dictionary: reviewedSnapshot), NSDictionary(dictionary: snapshot))
        }
    }

    func testBiddingToDefenseKeepsPlayerThreadAndOnlyCurrentPhaseGuidance() async throws {
        let (board, player, reviewer) = try session(config(dealer: .east, calls: ["1NT", "P", "P"]), actions: [advice("P", plan: "Bidding intention"), advice("S2", plan: "New defensive plan")])
        let pass = try await board.decideContinuous()
        _ = try await board.observeCall(.init(sequence: 3, seat: .north, call: AuctionCall("P")), authorization: pass.authorization)
        try await board.confirmContract(Contract(level: 1, strain: .noTrump, declarer: .east))
        // South leads. North first gets a defensive decision at third hand after actual dummy exposure.
        _ = try await board.observeContinuousPlay(.init(sequence: 0, seat: .south, card: Card("C2")))
        try await board.reveal(hand(.west, "D"))
        _ = try await board.observeContinuousPlay(.init(sequence: 1, seat: .west, card: Card("D2")))
        let defense = try await board.decideContinuous()
        XCTAssertEqual(pass.decision?.identity.threadID, defense.decision?.identity.threadID)
        XCTAssertEqual(defense.decision?.effectivePlan, "New defensive plan")
        let requests = await player.requests
        XCTAssertEqual(requests.count, 2)
        XCTAssertTrue(requests[0].input.contains("BIDDING TASK"))
        XCTAssertFalse(requests[0].input.contains("DEFENSE TASK"))
        XCTAssertTrue(requests[1].input.contains("DEFENSE TASK"))
        XCTAssertFalse(requests[1].input.contains("BIDDING TASK"))
        XCTAssertTrue(requests[1].input.contains("1NT"))
        let reviews = await reviewer.requests
        XCTAssertEqual(reviews.count, 2)
        XCTAssertTrue(reviews[1].input.contains("New defensive plan"))
    }

    func testSafeResumePreservesPlanAndAutomaticDeadlineButNeverPendingAuthorization() async throws {
        let started = Date().addingTimeInterval(-30)
        let (board, _, _) = try session(config(), actions: [advice("P", plan: "Retained public bidding intention")], started: started)
        let pass = try await board.decideContinuous()
        let pending = try await board.continuousCheckpoint()
        XCTAssertFalse(pending.safeToResume)
        await rejects { _ = try await ExternalBoardSession.resume(pending, reconciled: pending.configuration, transport: ContinuousBoundary(outputs: [], role: "player"), reviewer: ContinuousBoundary(outputs: [], role: "review")) }
        _ = try await board.observeCall(.init(sequence: 0, seat: .north, call: AuctionCall("P")), authorization: pass.authorization)
        let checkpoint = try await board.continuousCheckpoint()
        XCTAssertTrue(checkpoint.safeToResume)
        let resumed = try await ExternalBoardSession.resume(checkpoint, reconciled: checkpoint.configuration, transport: ContinuousBoundary(outputs: [], role: "player"), reviewer: ContinuousBoundary(outputs: [], role: "review"))
        let status = try await resumed.continuousStatus()
        XCTAssertTrue(status.reconstructed)
        XCTAssertNil(status.pendingAuthorization)
        XCTAssertEqual(status.activePlan, "Retained public bidding intention")
        let restored = try await resumed.continuousCheckpoint()
        XCTAssertEqual(restored.automaticDeadline, checkpoint.automaticDeadline)
        XCTAssertEqual(restored.automaticDeadline.timeIntervalSince(started), 1800, accuracy: 0.001)
        await rejects { _ = try await resumed.observeCall(.init(sequence: 1, seat: .east, call: AuctionCall("1C")), authorization: pass.authorization) }
    }

    func testFiveSemanticRevisionsReleaseContestedAdviceWithoutCallingItApproved() async throws {
        let (board, player, reviewer) = try session(config(), actions: Array(repeating: advice("P"), count: 5), verdicts: Array(repeating: revise, count: 5))
        let result = try await board.decideContinuous()
        XCTAssertEqual(result.decision?.rounds.count, 5)
        XCTAssertEqual(result.decision?.executionDisposition, .contested)
        XCTAssertEqual(result.decision?.rounds.last?.review.result.verdict, .revise)
        XCTAssertEqual(result.decision?.snapshot.auction.count, 0)
        _ = try await board.observeCall(.init(sequence: 0, seat: .north, call: AuctionCall("P")), authorization: result.authorization)
        let playerRequests = await player.requests
        let reviewRequests = await reviewer.requests
        XCTAssertEqual(playerRequests.count, 5)
        XCTAssertEqual(reviewRequests.count, 5)
    }

    func testReviewerTechnicalExhaustionStopsAfterInitialPlusThreeRetries() async throws {
        let (board, player, reviewer) = try session(config(), actions: [advice("P")], verdicts: Array(repeating: "not valid JSON", count: 4))
        await rejects { _ = try await board.decideContinuous() }
        let status = try await board.continuousStatus()
        XCTAssertTrue(status.stopped)
        XCTAssertNil(status.pendingAuthorization)
        XCTAssertEqual(status.snapshot.auction.count, 0)
        let playerRequests = await player.requests
        let reviewRequests = await reviewer.requests
        XCTAssertEqual(playerRequests.count, 1)
        XCTAssertEqual(reviewRequests.count, 4)
        await rejects { _ = try await board.decideContinuous() }
        let checkpoint = try await board.continuousCheckpoint()
        XCTAssertFalse(checkpoint.safeToResume)
    }

    func testCriticalReviewerUncertaintyStopsForFactsInsteadOfBecomingContested() async throws {
        let uncertain = #"{"verdict":"uncertain","blockingFindings":[],"advisorySuggestions":["Confirm whether the supplied 1NT agreement is forcing; this critical fact is unresolved."]}"#
        let (board, player, reviewer) = try session(config(), actions: [advice("P")], verdicts: [uncertain])
        do {
            _ = try await board.decideContinuous()
            XCTFail("Critical uncertainty must not authorize execution")
        } catch let failure as ExpertFailure {
            XCTAssertEqual(failure.category, .needsInput)
            XCTAssertTrue(failure.detail.contains("forcing"))
            XCTAssertEqual(failure.requestEvidence.count, 2)
        }
        let status = try await board.continuousStatus()
        XCTAssertTrue(status.stopped)
        XCTAssertNil(status.pendingAuthorization)
        XCTAssertTrue(status.snapshot.auction.isEmpty)
        let playerRequests = await player.requests
        let reviewerRequests = await reviewer.requests
        XCTAssertEqual(playerRequests.count, 1)
        XCTAssertEqual(reviewerRequests.count, 1)
    }

    func testMalformedPlayerOutputPreservesOriginalFailureEvidenceAndStops() async throws {
        let malformed = "This is not a structured bridge action"
        let (board, _, reviewer) = try session(config(), actions: [malformed])
        do {
            _ = try await board.decideContinuous()
            XCTFail("Malformed output must fail")
        } catch let failure as ExpertFailure {
            XCTAssertEqual(failure.category, .invalidOutput)
            XCTAssertEqual(failure.rawOutput, malformed)
            XCTAssertEqual(failure.requestEvidence.count, 1)
            XCTAssertEqual(failure.requestEvidence.first?.outcome, .protocolFailure)
            XCTAssertEqual(failure.requestEvidence.first?.rawOutput, malformed)
            XCTAssertEqual(failure.requestEvidence.first?.identity?.requestedModel, "gpt-6.1-sol")
        }
        let status = try await board.continuousStatus()
        XCTAssertTrue(status.stopped)
        XCTAssertNil(status.pendingAuthorization)
        let reviews = await reviewer.requests
        XCTAssertTrue(reviews.isEmpty)
    }

    func testPlayerIdentityMismatchIsFatalAndPreservesObservedIdentity() async throws {
        let player = ContinuousWrongIdentityBoundary(output: advice("P"))
        let board = try ExternalBoardSession(continuous: config(), transport: player,
            reviewer: ContinuousBoundary(outputs: [approve], role: "review"))
        do {
            _ = try await board.decideContinuous()
            XCTFail("Model identity mismatch must fail")
        } catch let failure as ExpertFailure {
            XCTAssertEqual(failure.category, .identity)
            XCTAssertEqual(failure.requestEvidence.first?.identity?.observedModel, "unexpected-model")
            XCTAssertEqual(failure.requestEvidence.first?.outcome, .identityFailure)
            XCTAssertFalse(failure.rawOutput.isEmpty)
        }
        let status = try await board.continuousStatus()
        XCTAssertTrue(status.stopped)
        XCTAssertNil(status.pendingAuthorization)
    }

    func testPlayerTransportFailureRetainsPublicDiagnosticsWithObservedIdentity() async throws {
        let identity = RuntimeIdentity(requestedModel: "gpt-6.1-sol", requestedEffort: "medium",
            runtimeVersion: "recorded", observedModel: "gpt-6.1-sol", observedEffort: "medium",
            threadID: "failed-player", turnID: "failed-turn")
        let usage = TokenUsage(inputTokens: 31, cachedInputTokens: 0, outputTokens: 5,
            reasoningOutputTokens: 2, totalTokens: 36)
        let diagnostic = "Recorded upstream connection closed after a partial public reply"
        let player = ContinuousTransportFailureBoundary(failure: PlayingTransportFailure(
            detail: diagnostic, identity: identity, rawOutput: "partial public reply", usage: usage))
        let board = try ExternalBoardSession(continuous: config(), transport: player,
            reviewer: ContinuousBoundary(outputs: [approve], role: "review"))
        do {
            _ = try await board.decideContinuous()
            XCTFail("A failed request cannot authorize an action")
        } catch let failure as ExpertFailure {
            let evidence = try XCTUnwrap(failure.requestEvidence.first)
            XCTAssertEqual(evidence.detail, diagnostic)
            XCTAssertEqual(evidence.rawOutput, "partial public reply")
            XCTAssertEqual(evidence.identity, identity)
            XCTAssertEqual(evidence.usage, usage)
            XCTAssertEqual(evidence.outcome, .transportFailure)
        }
        let status = try await board.continuousStatus()
        XCTAssertTrue(status.stopped)
        XCTAssertNil(status.pendingAuthorization)
        XCTAssertTrue(status.snapshot.auction.isEmpty)
    }

    func testSafeResumeAfterSeveralDecisionsUsesOnlyExecutionSuffixSinceLatestDecision() async throws {
        let (board, _, _) = try session(config(), actions: [advice("P"), advice("P", plan: nil)])
        let first = try await board.decideContinuous()
        _ = try await board.observeCall(.init(sequence: 0, seat: .north, call: AuctionCall("P")), authorization: first.authorization)
        _ = try await board.observeCall(.init(sequence: 1, seat: .east, call: AuctionCall("1C")))
        _ = try await board.observeCall(.init(sequence: 2, seat: .south, call: AuctionCall("P")))
        _ = try await board.observeCall(.init(sequence: 3, seat: .west, call: AuctionCall("P")))
        let second = try await board.decideContinuous()
        _ = try await board.observeCall(.init(sequence: 4, seat: .north, call: AuctionCall("P")), authorization: second.authorization)
        let checkpoint = try await board.continuousCheckpoint()
        XCTAssertTrue(checkpoint.safeToResume)
        let resumed = try await ExternalBoardSession.resume(checkpoint, reconciled: checkpoint.configuration,
            transport: ContinuousBoundary(outputs: [], role: "player"), reviewer: ContinuousBoundary(outputs: [], role: "review"))
        let status = try await resumed.continuousStatus()
        XCTAssertEqual(status.snapshot.auction.count, 5)
        XCTAssertEqual(status.activePlan, first.decision?.effectivePlan)
    }

    func testResumeRejectsChangedPriorFactsAndMissingActualExecutionSuffix() async throws {
        let (board, _, _) = try session(config(dealer: .east, calls: ["1NT", "P", "P"]), actions: [advice("P")])
        let pass = try await board.decideContinuous()
        _ = try await board.observeCall(.init(sequence: 3, seat: .north, call: AuctionCall("P")), authorization: pass.authorization)
        let checkpoint = try await board.continuousCheckpoint()
        let data = try JSONEncoder().encode(checkpoint)
        let original = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        for kind in ["scoring", "dealer", "hands", "history", "missing-executions"] {
            var object = original
            if kind == "missing-executions" {
                object["executions"] = []
            } else {
                var previous = object["lastCommittedSnapshot"] as! [String: Any]
                switch kind {
                case "scoring": previous["scoring"] = "IMP"
                case "dealer": previous["dealer"] = "west"
                case "hands": previous["hands"] = []
                default:
                    var calls = previous["auction"] as! [[String: Any]]
                    calls[0]["call"] = "1H"
                    previous["auction"] = calls
                }
                object["lastCommittedSnapshot"] = previous
            }
            let altered = try JSONDecoder().decode(ContinuousExternalCheckpoint.self, from: JSONSerialization.data(withJSONObject: object))
            do {
                _ = try await ExternalBoardSession.resume(altered, reconciled: altered.configuration,
                    transport: ContinuousBoundary(outputs: [], role: "player"), reviewer: ContinuousBoundary(outputs: [], role: "review"))
                XCTFail("Resume accepted altered checkpoint: \(kind)")
            } catch {}
        }
    }

}


private actor ContinuousWrongIdentityBoundary: PlayingTransport {
    let output: String
    init(output: String) { self.output = output }
    func respond(to request: PlayingRequest) async throws -> PlayingReply {
        PlayingReply(rawOutput: output, identity: .init(requestedModel: "gpt-6.1-sol", requestedEffort: "medium",
            runtimeVersion: "recorded", observedModel: "unexpected-model", observedEffort: "medium",
            threadID: "identity-test", turnID: UUID().uuidString), requestID: request.id)
    }
}

private struct ContinuousTransportFailureBoundary: PlayingTransport {
    let failure: PlayingTransportFailure
    func respond(to request: PlayingRequest) async throws -> PlayingReply { throw failure }
}
