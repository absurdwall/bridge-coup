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
        object.removeValue(forKey: "seatIsSequenceDerived")
        object.removeValue(forKey: "meaningNote")
        let priorSchemaData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(AuctionEntry.self, from: priorSchemaData)

        XCTAssertNotEqual(decoded.id, priorEntry.id)
        XCTAssertEqual(decoded.seat, .north)
        XCTAssertTrue(decoded.seatIsSequenceDerived)
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

    func testPartialRecordWithKnownStartDoesNotInferSeatsOrMissingCalls() throws {
        let northCall = AuctionEntry(seat: .north, call: .bid(level: 1, strain: .clubs))
        let eastCall = AuctionEntry(seat: .east, call: .pass)
        let record = AuctionRecord(
            startingSeat: .west,
            entries: [northCall, eastCall],
            isPartial: true
        )

        XCTAssertNil(record.sequenceSeat(at: 0))
        XCTAssertNil(record.sequenceSeat(at: 1))
        let rows = try XCTUnwrap(record.layoutRows)
        XCTAssertEqual(rows.count, 2, "Each visible item keeps order without inferring intervening turns.")
        XCTAssertEqual(rows[0][.north], .entry(northCall))
        XCTAssertEqual(rows[0][.west], .layoutBlank)
        XCTAssertEqual(rows[1][.east], .entry(eastCall))
        XCTAssertEqual(record.entries.map(\.call), [.bid(level: 1, strain: .clubs), .pass])

        XCTAssertTrue(record.promptDescription.contains("部分可见片段"))
        XCTAssertTrue(record.promptDescription.contains("可见记录项 1（北家）：1♣"))
        XCTAssertTrue(record.promptDescription.contains("可见记录项 2（东家）：Pass"))
        XCTAssertTrue(record.promptDescription.contains("不得推断缺口中的叫品、Pass 或座位"))
        XCTAssertFalse(record.promptDescription.contains("第1次行动"))
        XCTAssertFalse(record.promptDescription.contains("第2次行动"))
    }

    func testPartialRecordKeepsUnknownSeatUnknownAndRequiresPerItemReview() {
        let record = AuctionRecord(
            startingSeat: .west,
            entries: [
                AuctionEntry(seat: .south, call: .bid(level: 1, strain: .diamonds)),
                AuctionEntry(call: .unknown),
            ],
            isPartial: true
        )

        XCTAssertNil(record.sequenceSeat(at: 1))
        XCTAssertNil(record.layoutRows)
        XCTAssertTrue(record.promptDescription.contains("可见记录项 2（位置未知）：未知叫品"))
        XCTAssertFalse(record.promptDescription.contains("第2次行动"))
    }

    func testPartialCompleteRoundTripRestoresSequenceDerivedSeatsForTableAndRequest() throws {
        var record = AuctionRecord(
            startingSeat: .north,
            entries: [
                AuctionEntry(seat: .north, seatIsSequenceDerived: true, call: .bid(level: 1, strain: .clubs)),
                AuctionEntry(seat: .east, seatIsSequenceDerived: true, call: .pass),
            ]
        )

        record.setIsPartial(true)

        XCTAssertEqual(record.entries.map(\.seat), [nil, nil])
        XCTAssertEqual(record.entries.map(\.seatIsSequenceDerived), [true, true])
        XCTAssertNil(record.layoutRows)
        XCTAssertTrue(record.promptDescription.contains("可见记录项 1（位置未知）：1♣"))

        let archivedPartialRecord = try JSONDecoder().decode(
            AuctionRecord.self,
            from: JSONEncoder().encode(record)
        )
        XCTAssertEqual(archivedPartialRecord.entries.map(\.seat), [nil, nil])
        XCTAssertEqual(archivedPartialRecord.entries.map(\.seatIsSequenceDerived), [true, true])

        var restored = archivedPartialRecord
        restored.setIsPartial(false)

        XCTAssertEqual(restored.entries.map(\.seat), [.north, .east])
        XCTAssertEqual(restored.entries.map(\.seatIsSequenceDerived), [true, true])
        XCTAssertTrue(restored.promptDescription.contains("第1次行动（北家）：1♣"))
        XCTAssertTrue(restored.promptDescription.contains("第2次行动（东家）：Pass"))

        let rows = try XCTUnwrap(restored.layoutRows)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0][.north], .entry(restored.entries[0]))
        XCTAssertEqual(rows[0][.east], .entry(restored.entries[1]))

        var draft = DeclarerPlanDraft()
        draft.contractLevel = 3
        draft.contractStrain = .noTrump
        draft.hands[.south, default: [:]][.spades] = "A2"
        draft.auction = restored
        let request = try DeclarerPlanRequestBuilder.build(from: draft)

        XCTAssertEqual(request.auction?.layoutRows, restored.layoutRows)
        XCTAssertTrue(request.prompt.contains("第1次行动（北家）：1♣"))
        XCTAssertTrue(request.prompt.contains("第2次行动（东家）：Pass"))
    }

    func testChangingStartingSeatRecomputesDerivedSeats() throws {
        var record = AuctionRecord(
            startingSeat: .north,
            entries: [
                AuctionEntry(seat: .north, seatIsSequenceDerived: true, call: .bid(level: 1, strain: .clubs)),
                AuctionEntry(seat: .east, seatIsSequenceDerived: true, call: .pass),
                AuctionEntry(seat: .south, seatIsSequenceDerived: true, call: .bid(level: 1, strain: .diamonds)),
            ]
        )

        record.setStartingSeat(.east)

        XCTAssertEqual(record.entries.map(\.seat), [.east, .south, .west])
        XCTAssertEqual(record.sequenceSeat(at: 0), .east)
        XCTAssertEqual(record.sequenceSeat(at: 1), .south)
        XCTAssertEqual(record.sequenceSeat(at: 2), .west)
        XCTAssertNotNil(record.layoutRows)
        XCTAssertTrue(record.promptDescription.contains("第1次行动（东家）：1♣"))
        XCTAssertTrue(record.promptDescription.contains("第3次行动（西家）：1♦"))
    }

    func testChoosingStartingSeatInfersPreviouslyUnassignedCompleteEntries() {
        var record = AuctionRecord(entries: [
            AuctionEntry(call: .pass),
            AuctionEntry(call: .unknown),
        ])

        record.setStartingSeat(.south)

        XCTAssertEqual(record.entries.map(\.seat), [.south, .west])
        XCTAssertEqual(record.entries.map(\.seatIsSequenceDerived), [true, true])
        XCTAssertTrue(record.promptDescription.contains("第2次行动（西家）：未知叫品"))
    }

    func testLegacyAuctionRecordDefaultsToCompleteSequenceBehavior() throws {
        let record = AuctionRecord(
            startingSeat: .west,
            entries: [
                AuctionEntry(seat: .west, call: .pass),
                AuctionEntry(seat: .north, call: .bid(level: 1, strain: .clubs)),
            ]
        )
        let encoded = try JSONEncoder().encode(record)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "isPartial")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(AuctionRecord.self, from: legacyData)

        XCTAssertFalse(decoded.isPartial)
        XCTAssertEqual(decoded.sequenceSeat(at: 0), .west)
        XCTAssertEqual(decoded.sequenceSeat(at: 1), .north)
        XCTAssertNotNil(decoded.layoutRows)
        XCTAssertTrue(decoded.promptDescription.contains("第2次行动（北家）"))
    }
}
