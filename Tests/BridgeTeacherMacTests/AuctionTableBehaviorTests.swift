import XCTest
import BridgeTeacherCore
@testable import BridgeTeacherMac

final class AuctionTableBehaviorTests: XCTestCase {
    func testProjectionKeepsCallIdentityAndNoteMarkerInTheAssignedRoundColumn() throws {
        let id = UUID()
        let record = AuctionRecord(
            startingSeat: .west,
            entries: [
                AuctionEntry(
                    id: id,
                    seat: .west,
                    call: .bid(level: 1, strain: .clubs),
                    meaningNote: "自然梅花开叫"
                )
            ]
        )

        let row = try XCTUnwrap(AuctionTablePresentation(record: record).rows?.first)
        XCTAssertEqual(row.compactMap(\.seat), Seat.allCases)
        XCTAssertEqual(row[0].content, .layoutBlank)
        XCTAssertEqual(row[1].content, .layoutBlank)
        XCTAssertEqual(row[2].content, .layoutBlank)
        XCTAssertEqual(row[3].content, .call(id: id, text: "1♣", ink: .clubs, hasMeaningNote: true))
    }

    func testLongAuctionProjectsAllEntriesAcrossFixedSeatColumns() throws {
        let entries = (0..<36).map { index in
            AuctionEntry(
                seat: Seat.allCases[(3 + index) % Seat.allCases.count],
                call: index.isMultiple(of: 2) ? .pass : .bid(level: 1, strain: .hearts)
            )
        }
        let record = AuctionRecord(startingSeat: .west, entries: entries)
        let rows = try XCTUnwrap(AuctionTablePresentation(record: record).rows)

        XCTAssertEqual(rows.count, 10)
        XCTAssertTrue(rows.allSatisfy { $0.count == Seat.allCases.count })
        let visibleCalls = rows.flatMap { $0.compactMap { cell -> String? in
            guard case let .call(_, text, _, _) = cell.content else { return nil }
            return text
        } }
        XCTAssertEqual(visibleCalls.count, 36)
        XCTAssertEqual(visibleCalls.first, "Pass")
        XCTAssertEqual(visibleCalls.last, "1♥")
        XCTAssertEqual(rows[0].compactMap(\.seat), Seat.allCases)
        XCTAssertEqual(rows[0].prefix(3).map(\.content), Array(repeating: .layoutBlank, count: 3))
        XCTAssertEqual(rows[9][3].content, .layoutBlank)
        XCTAssertLessThan(AuctionTableView.compactTableMaxHeight, CGFloat(36 * 23))
    }

    func testUnassignedPartialAuctionDoesNotInventAColumnLayout() {
        let record = AuctionRecord(entries: [AuctionEntry(call: .unknown)])

        XCTAssertNil(AuctionTablePresentation(record: record).rows)
    }

    func testPartialTranscriptProjectsExplicitSeatsAsSparseRowsInVisibleOrder() throws {
        let north = AuctionEntry(seat: .north, call: .bid(level: 1, strain: .clubs))
        let east = AuctionEntry(seat: .east, call: .pass)
        let record = AuctionRecord(
            startingSeat: .west,
            entries: [north, east],
            isPartial: true
        )

        let rows = try XCTUnwrap(AuctionTablePresentation(record: record).rows)

        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0][0].seat, .north)
        XCTAssertEqual(rows[0][0].content, .call(id: north.id, text: "1♣", ink: .clubs, hasMeaningNote: false))
        XCTAssertEqual(rows[0].dropFirst().map(\.content), Array(repeating: .layoutBlank, count: 3))
        XCTAssertEqual(rows[1][1].seat, .east)
        XCTAssertEqual(rows[1][1].content, .call(id: east.id, text: "Pass", ink: .pass, hasMeaningNote: false))
        XCTAssertEqual(rows[1].enumerated().filter { $0.offset != 1 }.map(\.element.content), Array(repeating: .layoutBlank, count: 3))
    }

    func testCallInkUsesSuitColorsAndGreenPass() {
        XCTAssertEqual(AuctionCallInk.forCall(.pass), .pass)
        XCTAssertEqual(AuctionCallInk.forCall(.bid(level: 1, strain: .clubs)), .clubs)
        XCTAssertEqual(AuctionCallInk.forCall(.bid(level: 1, strain: .diamonds)), .diamonds)
        XCTAssertEqual(AuctionCallInk.forCall(.bid(level: 1, strain: .hearts)), .hearts)
        XCTAssertEqual(AuctionCallInk.forCall(.bid(level: 1, strain: .spades)), .spades)
        XCTAssertEqual(AuctionCallInk.forCall(.bid(level: 1, strain: .noTrump)), .noTrump)
        XCTAssertEqual(AuctionCallInk.forCall(.double), .neutral)
        XCTAssertEqual(AuctionCallInk.forCall(.redouble), .neutral)
        XCTAssertEqual(AuctionCallInk.forCall(.unknown), .neutral)
    }
}
