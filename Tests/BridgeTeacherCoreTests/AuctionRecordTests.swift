import XCTest
@testable import BridgeTeacherCore

final class AuctionRecordTests: XCTestCase {
    func testEntryIDsAndMeaningNotesStayWithTheirOccurrenceAcrossEdits() throws {
        let first = AuctionEntry(
            seat: .west,
            call: .pass,
            meaningNote: "可能表示某种邀叫；仅在双方约定适用时。"
        )
        let repeated = AuctionEntry(seat: .north, call: .pass, meaningNote: "另一条独立备注。")
        let inserted = AuctionEntry(seat: .east, call: .double)
        var record = AuctionRecord(startingSeat: .west, entries: [first, repeated])

        XCTAssertNotEqual(first.id, repeated.id)
        XCTAssertTrue(record.insertEntry(inserted, at: 1))
        XCTAssertEqual(record.entries.map(\.id), [first.id, inserted.id, repeated.id])

        XCTAssertTrue(record.updateCall(forEntryID: first.id, to: .unknown))
        XCTAssertEqual(record.entries[0].id, first.id)
        XCTAssertEqual(record.entries[0].call, .unknown)
        XCTAssertEqual(record.entries[0].meaningNote, first.meaningNote)

        XCTAssertTrue(record.setMeaningNote("   \n", forEntryID: first.id))
        XCTAssertNil(record.entries[0].meaningNote)
        XCTAssertEqual(record.entries[2].meaningNote, "另一条独立备注。")

        XCTAssertTrue(record.removeEntry(id: inserted.id))
        XCTAssertEqual(record.entries.map(\.id), [first.id, repeated.id])
        XCTAssertNil(record.entries.first(where: { $0.id == first.id })?.meaningNote)
        XCTAssertEqual(record.entries.first(where: { $0.id == repeated.id })?.meaningNote, "另一条独立备注。")
        XCTAssertFalse(record.removeEntry(id: inserted.id))
    }

    func testOldAuctionEntryWithoutIdentityOrMeaningNoteDecodesSafely() throws {
        let priorEntry = AuctionEntry(seat: .north, call: .bid(level: 1, strain: .clubs), meaningNote: "discarded")
        let encoded = try JSONEncoder().encode(priorEntry)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "id")
        object.removeValue(forKey: "meaningNote")
        let priorSchemaData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(AuctionEntry.self, from: priorSchemaData)

        XCTAssertNotEqual(decoded.id, priorEntry.id)
        XCTAssertEqual(decoded.seat, .north)
        XCTAssertEqual(decoded.call, .bid(level: 1, strain: .clubs))
        XCTAssertNil(decoded.meaningNote)
    }

    func testMeaningNotesAreConditionalUserContextAndBlankNotesDoNotBlockRequests() throws {
        let recorded = AuctionEntry(seat: .west, call: .pass, meaningNote: "Only if the opponents used this agreement.")
        let blank = AuctionEntry(seat: .north, call: .pass, meaningNote: " \n ")
        let record = AuctionRecord(startingSeat: .west, entries: [recorded, blank])
        var draft = DeclarerPlanDraft()
        draft.contractLevel = 3
        draft.contractStrain = .noTrump
        draft.hands[.south, default: [:]][.spades] = "A2"
        draft.auction = record

        let request = try DeclarerPlanRequestBuilder.build(from: draft)

        XCTAssertEqual(request.auction?.entries.map(\.id), [recorded.id, blank.id])
        XCTAssertNil(request.auction?.entries[1].meaningNote)
        XCTAssertTrue(request.prompt.contains("用户提供的叫品含义与适用条件备注"))
        XCTAssertTrue(request.prompt.contains("未核实，不得表述为已确认的约定"))
        XCTAssertTrue(request.prompt.contains("Only if the opponents used this agreement."))
        XCTAssertFalse(request.prompt.contains("<user-call-meaning-note>\n\n</user-call-meaning-note>"))
    }
}
