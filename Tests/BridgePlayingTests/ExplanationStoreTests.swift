import XCTest
import BridgeDomain
import BridgeKnowledge

final class ExplanationStoreTests: XCTestCase {
    func testSavedChineseObservationIsQueryableAfterReopeningWithoutOverwritingProvenance() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("explanations-\(UUID()).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        let context = try context(dealer: .north, vulnerability: "NS", calls: ["1S", "P"])
        let first = ExplanationObservation(context: context, candidate: try AuctionCall("2C"), text: "测试资料：13点以上，进局逼叫。",
            source: "synthetic-provider", observedAt: "2026-10-25T10:00:00Z", sourceVersion: "unknown",
            evidence: ["test-fixture-1"], isTestData: true)
        let store = try ExplanationStore(url: url, testData: true)
        try await store.save(first)
        let reopened = try ExplanationStore(url: url, testData: true)
        let matches = try await reopened.lookup(context: context, candidate: AuctionCall("2C"))
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.observation, first)
        XCTAssertEqual(matches.first?.status, .exact)
    }

    func testRotationMapsBothPartnershipSystemsAndVulnerabilityWithoutChangingMeaning() async throws {
        let (store, url) = try temporaryStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let original = try context(dealer: .north, vulnerability: "NS", calls: ["1S", "P"])
        try await store.save(observation(original))
        let rotated = try context(dealer: .east, vulnerability: "EW", calls: ["1S", "P"], nsSystem: "test-natural", ewSystem: "test-2/1")
        let matches = try await store.lookup(context: rotated, candidate: AuctionCall("2C"))
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0].status, .exact)
        XCTAssertTrue(matches[0].differences.isEmpty)
        XCTAssertEqual(matches[0].observation.context.dealer, .north, "Original compass provenance remains intact")
        let unrotatedSystems = try context(dealer: .east, vulnerability: "NS", calls: ["1S", "P"])
        let related = try await store.lookup(context: unrotatedSystems, candidate: AuctionCall("2C"))
        XCTAssertEqual(related.first?.status, .related)
        XCTAssertEqual(Set(related[0].differences), ["partnership systems differ", "vulnerability differs"])
        let changedConditions = try context(dealer: .north, vulnerability: "NS", calls: ["1S", "P"], conditions: "IMP")
        let conditional = try await store.lookup(context: changedConditions, candidate: AuctionCall("2C"))
        XCTAssertEqual(conditional.first?.status, .related)
        XCTAssertEqual(conditional.first?.differences, ["table conditions differ"])
    }

    func testPassesCompetitionAndOpeningPositionStayInTheIndexedPrefix() async throws {
        let (store, url) = try temporaryStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let firstSeat = try context(dealer: .north, vulnerability: "neither", calls: ["1S", "P"])
        try await store.save(observation(firstSeat))
        let thirdSeat = try context(dealer: .north, vulnerability: "neither", calls: ["P", "P", "1S", "P"])
        let competition = try context(dealer: .north, vulnerability: "neither", calls: ["1S", "X"])
        let thirdMatches = try await store.lookup(context: thirdSeat, candidate: AuctionCall("2C"))
        let competitiveMatches = try await store.lookup(context: competition, candidate: AuctionCall("2C"))
        XCTAssertTrue(thirdMatches.isEmpty)
        XCTAssertTrue(competitiveMatches.isEmpty)
        let differentCandidate = try await store.lookup(context: firstSeat, candidate: AuctionCall("2D"))
        XCTAssertTrue(differentCandidate.isEmpty)
    }

    func testLongObservedPrefixRetainsDoubleRedoubleAndChineseAtNonterminalNode() async throws {
        let (store, url) = try temporaryStore()
        defer { try? FileManager.default.removeItem(at: url) }
        // A long, legal ascending competitive path; no fixed call-position columns.
        let calls = ["P", "P"] + AuctionCall.bids.prefix(25).flatMap { [$0, "X", "XX"] }
        let long = try context(dealer: .west, vulnerability: "both", calls: calls)
        let entry = try observation(long, candidate: "6D", text: "测试资料：长叫牌前缀的解释。")
        try await store.save(entry)
        let matches = try await store.lookup(context: long, candidate: AuctionCall("6D"))
        XCTAssertEqual(matches.first?.observation.text, "测试资料：长叫牌前缀的解释。")
        XCTAssertEqual(matches.first?.observation.context.auction.count, 77)
        XCTAssertEqual(matches.first?.status, .exact)
    }

    func testSourceVersionsConflictsAndRepeatedObservationsAreRetainedAndLookupIsBounded() async throws {
        let (store, url) = try temporaryStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let prefix = try context(dealer: .south, vulnerability: "none", calls: ["1S", "P"])
        let first = try observation(prefix, text: "测试资料：自然含义。", source: "source-one", version: "v1")
        let changed = try observation(prefix, text: "测试资料：不同含义待核实。", source: "source-two", version: "v2")
        try await store.save(first); try await store.save(changed); try await store.save(first)
        let results = try await store.lookup(context: prefix, candidate: AuctionCall("2C"))
        XCTAssertEqual(Set(results.map(\.observation.id)), [first.id, changed.id])
        XCTAssertEqual(Set(results.map(\.observation.sourceVersion)), ["v1", "v2"])
        let limited = try await store.lookup(context: prefix, candidate: AuctionCall("2C"), limit: 1)
        XCTAssertEqual(limited.count, 1)
        let conflict = ExplanationObservation(id: first.id, context: prefix, candidate: first.candidate,
            text: "overwrite attempt", source: first.source, observedAt: first.observedAt, sourceVersion: "v3", evidence: ["test"], isTestData: true)
        do { try await store.save(conflict); XCTFail("Existing identity must not replace original text") }
        catch { XCTAssertEqual(error as? ExplanationStoreError, .conflictingObservation) }
        let after = try await store.lookup(context: prefix, candidate: AuctionCall("2C"))
        XCTAssertEqual(Set(after.map(\.observation.text)), [first.text, changed.text])
    }

    func testSyntheticFixturesCannotEnterOrOpenAnObservationDatabase() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("actual-observations-\(UUID()).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try ExplanationStore(url: url)
        let prefix = try context(dealer: .north, vulnerability: "none", calls: [])
        do { try await store.save(observation(prefix)); XCTFail("Synthetic fixtures are isolated") }
        catch { XCTAssertEqual(error as? ExplanationStoreError, .dataKindMismatch) }
        do { _ = try ExplanationStore(url: url, testData: true); XCTFail("Database purpose is persistent") }
        catch { XCTAssertEqual(error as? ExplanationStoreError, .dataKindMismatch) }
        let empty = try await store.lookup(context: prefix, candidate: AuctionCall("2C"))
        XCTAssertTrue(empty.isEmpty)
    }

    func testUnknownSystemsAndUnmappedVulnerabilityStayRelatedEvenWhenLabelsRepeat() async throws {
        let (store, url) = try temporaryStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let unknown = try context(dealer: .north, vulnerability: "unknown", calls: ["1S", "P"], nsSystem: "unknown", ewSystem: "unknown")
        try await store.save(observation(unknown))
        let matches = try await store.lookup(context: unknown, candidate: AuctionCall("2C"))
        XCTAssertEqual(matches.first?.status, .related)
        XCTAssertEqual(Set(matches[0].differences), ["partnership system is unknown", "vulnerability is not normalized"])
    }

    private func temporaryStore() throws -> (ExplanationStore, URL) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("synthetic-explanations-\(UUID()).sqlite")
        return (try ExplanationStore(url: url, testData: true), url)
    }

    private func observation(_ context: ExplanationContext, candidate: String = "2C", text: String = "测试资料：中文解释。", source: String = "synthetic-provider", version: String = "unknown") throws -> ExplanationObservation {
        ExplanationObservation(context: context, candidate: try AuctionCall(candidate), text: text, source: source,
            observedAt: "2026-10-25T10:00:00Z", sourceVersion: version, evidence: ["synthetic-test-fixture"], isTestData: true)
    }

    private func context(dealer: Seat, vulnerability: String, calls: [String], nsSystem: String = "test-2/1", ewSystem: String = "test-natural", conditions: String = "MP") throws -> ExplanationContext {
        var seat = dealer
        let auction = try calls.enumerated().map { index, value in
            defer { seat = seat.next }
            return AuctionEvent(sequence: index, seat: seat, call: try AuctionCall(value))
        }
        return ExplanationContext(dealer: dealer, actingSeat: seat, auction: auction,
            vulnerability: vulnerability, nsSystem: nsSystem, ewSystem: ewSystem, conditions: conditions)
    }
}
