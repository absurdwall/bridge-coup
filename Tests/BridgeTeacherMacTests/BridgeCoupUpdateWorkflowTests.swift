import Foundation
import XCTest
@testable import BridgeTeacherMac

@MainActor
final class BridgeCoupUpdateWorkflowTests: XCTestCase {
    func testBetaOffersHighestNumberedBetaThenStableAndOpensOnlyOfficialPage() async throws {
        let opened = OpenedPages()
        let workflow = makeWorkflow(tag: "v1.0.0-beta.1", channel: "beta", releases: [
            release("v1.0.0-beta.2", notes: "Second beta fixes login."),
            release("v1.0.0-beta.10", notes: "Tenth beta improves DDS."),
            release("v1.0.0", prerelease: false, notes: "Stable release."),
            release("v2.0.0-beta.1", draft: true)
        ], opened: opened)

        await workflow.check()

        guard case let .available(candidate) = workflow.state else {
            return XCTFail("Expected a visible update offer, got \(workflow.state.message)")
        }
        XCTAssertEqual(candidate.tag, "v1.0.0")
        XCTAssertEqual(candidate.notes, "Stable release.")
        XCTAssertEqual(workflow.state.message, "Bridge Coup 1.0.0 is available.")
        workflow.openAvailableRelease()
        XCTAssertEqual(opened.urls.map(\.absoluteString), ["https://github.com/absurdwall/bridge-coup/releases/tag/v1.0.0"])
    }

    func testNumericBetaOrderingAndNoDowngrade() async throws {
        let feed = [release("v1.0.0-beta.2"), release("v1.0.0-beta.10")]
        let older = makeWorkflow(tag: "v1.0.0-beta.1", channel: "beta", releases: feed)
        await older.check()
        guard case let .available(candidate) = older.state else { return XCTFail(older.state.message) }
        XCTAssertEqual(candidate.tag, "v1.0.0-beta.10")
        XCTAssertEqual(older.state.message, "Bridge Coup 1.0.0 Beta 10 is available.")

        let newer = makeWorkflow(tag: "v1.0.0-beta.11", channel: "beta", releases: feed)
        await newer.check()
        XCTAssertEqual(newer.state.message, "Bridge Coup is up to date.")
    }

    func testStableChannelSkipsBetasAndSameVersionIsUpToDate() async throws {
        let workflow = makeWorkflow(tag: "v1.0.0", channel: "stable", releases: [
            release("v1.0.0" , prerelease: false),
            release("v1.1.0-beta.4")
        ])
        await workflow.check()
        XCTAssertEqual(workflow.state.message, "Bridge Coup is up to date.")
    }

    func testNoReleasesOrCompatibleDMGReportsNoEligibleRelease() async throws {
        let empty = makeWorkflow(tag: "v1.0.0-beta.1", channel: "beta", releases: [])
        await empty.check()
        XCTAssertEqual(empty.state.message, "No eligible release with an Apple Silicon DMG is available yet.")

        let incompatible = makeWorkflow(tag: "v1.0.0-beta.1", channel: "beta", releases: [
            release("v2.0.0-beta.1", asset: "Bridge-Coup-v2.0.0-beta.1-x86_64.dmg"),
            release("v2.0.0-beta.2", asset: nil),
            release("v3.0.0-rc.1"),
            release("v3.0.0-beta.1", prerelease: false),
            release("v4.0.0-beta.1", draft: true)
        ])
        await incompatible.check()
        XCTAssertEqual(incompatible.state.message, "No eligible release with an Apple Silicon DMG is available yet.")
    }

    func testInvalidReleasePageFailsWithoutOpeningBrowser() async throws {
        let opened = OpenedPages()
        let workflow = makeWorkflow(tag: "v1.0.0-beta.1", channel: "beta", releases: [
            release("v1.0.0-beta.2", url: "https://github.com.evil.test/absurdwall/bridge-coup/releases/tag/v1.0.0-beta.2")
        ], opened: opened)
        await workflow.check()
        XCTAssertEqual(workflow.state.message, "Update check failed: A release has an invalid download page.")
        workflow.openAvailableRelease()
        XCTAssertTrue(opened.urls.isEmpty)
    }

    func testMalformedMetadataTimeoutOfflineAndRateLimitRemainFailuresAndCanRetry() async throws {
        let attempts = AttemptCounter()
        let valid = try json([release("v1.0.0-beta.2")])
        let workflow = BridgeCoupUpdateWorkflow(
            identity: .init(tag: "v1.0.0-beta.1", channel: "beta"),
            fetch: { _ in
                attempts.count += 1
                switch attempts.count {
                case 1: return (Data("{broken".utf8), Self.response(200))
                case 2: throw URLError(.timedOut)
                case 3: throw URLError(.notConnectedToInternet)
                case 4: return (Data(), Self.response(403, headers: ["X-RateLimit-Remaining": "0"]))
                default: return (valid, Self.response(200))
                }
            }, openPage: { _ in XCTFail("No browser action during check"); return false })

        await workflow.check()
        XCTAssertEqual(workflow.state.message, "Update check failed: GitHub returned malformed release metadata. Please retry.")
        await workflow.check()
        XCTAssertEqual(workflow.state.message, "Update check failed: The request timed out. Please retry.")
        await workflow.check()
        XCTAssertEqual(workflow.state.message, "Update check failed: The network is unavailable. Check your connection and retry.")
        await workflow.check()
        XCTAssertEqual(workflow.state.message, "Update check failed: GitHub's request limit was reached. Please retry later.")
        await workflow.check()
        XCTAssertEqual(workflow.state.message, "Bridge Coup 1.0.0 Beta 2 is available.")
    }

    func testBrowserFailureIsVisibleAndDoesNotChangeInstalledIdentity() async throws {
        let workflow = makeWorkflow(tag: "v1.0.0-beta.1", channel: "beta", releases: [
            release("v1.0.0-beta.2")
        ], openPage: { _ in false })
        await workflow.check()
        workflow.openAvailableRelease()
        XCTAssertEqual(workflow.state.message, "Update check failed: Could not open the release page in your browser.")
        await workflow.check()
        XCTAssertEqual(workflow.state.message, "Bridge Coup 1.0.0 Beta 2 is available.")
    }

    func testMenuActionShowsUpdateSheetWhileControlledCheckRuns() async throws {
        let opened = OpenedPages()
        let workflow = makeWorkflow(tag: "v1.0.0-beta.1", channel: "beta", releases: [
            release("v1.0.0-beta.2", notes: "A controlled test release")
        ], opened: opened)
        let coordinator = BridgeCoupUpdateCoordinator(workflow: workflow)

        let check = coordinator.checkFromMenu()
        XCTAssertTrue(coordinator.isShowingUpdates)
        await check.value
        XCTAssertEqual(coordinator.workflow.state.message, "Bridge Coup 1.0.0 Beta 2 is available.")
        coordinator.workflow.openAvailableRelease()
        XCTAssertEqual(opened.urls.count, 1)
        XCTAssertEqual(opened.urls.first?.host, "github.com")
    }

    private func makeWorkflow(tag: String, channel: String, releases: [[String: Any]],
                              opened: OpenedPages = OpenedPages(),
                              openPage: ((URL) -> Bool)? = nil) -> BridgeCoupUpdateWorkflow {
        let payload = try! json(releases)
        return BridgeCoupUpdateWorkflow(identity: .init(tag: tag, channel: channel),
            fetch: { url in
                XCTAssertEqual(url.absoluteString, "https://api.github.com/repos/absurdwall/bridge-coup/releases?per_page=100")
                return (payload, Self.response(200))
            }, openPage: openPage ?? { url in opened.urls.append(url); return true })
    }

    private func release(_ tag: String, prerelease: Bool? = nil, draft: Bool = false,
                         asset: String? = "default", url: String? = nil,
                         notes: String = "Release notes") -> [String: Any] {
        ["tag_name": tag,
         "html_url": url ?? "https://github.com/absurdwall/bridge-coup/releases/tag/\(tag)",
         "body": notes,
         "draft": draft,
         "prerelease": prerelease ?? tag.contains("-beta."),
         "assets": asset.map { [["name": $0 == "default" ? "Bridge-Coup-\(tag)-arm64.dmg" : $0]] } ?? []]
    }

    private func json(_ releases: [[String: Any]]) throws -> Data {
        try JSONSerialization.data(withJSONObject: releases)
    }

    private static func response(_ status: Int, headers: [String: String] = [:]) -> HTTPURLResponse {
        HTTPURLResponse(url: BridgeCoupUpdateWorkflow.releasesURL, statusCode: status,
                        httpVersion: "HTTP/1.1", headerFields: headers)!
    }
}

private final class OpenedPages { var urls: [URL] = [] }
private final class AttemptCounter { var count = 0 }
