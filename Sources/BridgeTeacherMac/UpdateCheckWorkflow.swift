import AppKit
import Combine
import Foundation

/// The release tag, rather than CFBundleShortVersionString, retains the beta number.
struct BridgeCoupVersion: Comparable, Equatable {
    let major: Int
    let minor: Int
    let patch: Int
    let beta: Int?

    init?(tag: String) {
        let pattern = #"^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-beta\.([1-9][0-9]*))?$"#
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: tag, range: NSRange(tag.startIndex..., in: tag)),
              match.range == NSRange(tag.startIndex..., in: tag) else { return nil }
        func number(_ index: Int) -> Int? {
            guard let range = Range(match.range(at: index), in: tag) else { return nil }
            return Int(tag[range])
        }
        guard let major = number(1), let minor = number(2), let patch = number(3) else { return nil }
        self.major = major
        self.minor = minor
        self.patch = patch
        beta = number(4)
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
        switch (lhs.beta, rhs.beta) {
        case (nil, nil): return false
        case (nil, _?): return false
        case (_?, nil): return true
        case let (left?, right?): return left < right
        }
    }
}

enum BridgeCoupReleaseChannel: String {
    case beta
    case stable

    func matchesInstalled(_ version: BridgeCoupVersion) -> Bool {
        switch self {
        case .beta: version.beta != nil
        case .stable: version.beta == nil
        }
    }

    func allows(_ version: BridgeCoupVersion) -> Bool {
        self == .beta || version.beta == nil
    }
}

struct BridgeCoupReleaseIdentity {
    let tag: String
    let channel: BridgeCoupReleaseChannel?

    static func installed(bundle: Bundle = .main) -> Self {
        let info = bundle.infoDictionary ?? [:]
        return Self(tag: info["BridgeCoupReleaseTag"] as? String ?? "",
                    channel: BridgeCoupReleaseChannel(
                        rawValue: info["BridgeCoupReleaseChannel"] as? String ?? ""
                    ))
    }
}

struct BridgeCoupUpdateCandidate: Equatable {
    let tag: String
    let notes: String
    let pageURL: URL

    var displayVersion: String {
        tag.dropFirst().replacingOccurrences(of: "-beta.", with: " Beta ")
    }
}

enum BridgeCoupUpdateState: Equatable {
    case idle
    case checking
    case available(BridgeCoupUpdateCandidate)
    case upToDate
    case noEligibleRelease
    case incompleteRelease(String)
    case failed(String)

    var message: String {
        switch self {
        case .idle: "Check for a newer Bridge Coup release when you are ready."
        case .checking: "Checking official Bridge Coup releases…"
        case let .available(candidate): "Bridge Coup \(candidate.displayVersion) is available."
        case .upToDate: "Bridge Coup is up to date."
        case .noEligibleRelease: "No eligible release with an Apple Silicon DMG is available yet."
        case let .incompleteRelease(tag):
            "A newer release (\(tag)) is published, but its Apple Silicon DMG is unavailable. Please retry later."
        case let .failed(reason): "Update check failed: \(reason)"
        }
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL
    let body: String?
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]

    struct Asset: Decodable { let name: String }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name", htmlURL = "html_url", body, draft, prerelease, assets
    }
}

@MainActor
final class BridgeCoupUpdateWorkflow: ObservableObject {
    typealias Fetch = (URL) async throws -> (Data, HTTPURLResponse)
    typealias OpenPage = (URL) -> Bool

    static let releasesURL = URL(string: "https://api.github.com/repos/absurdwall/bridge-coup/releases?per_page=100")!

    @Published private(set) var state: BridgeCoupUpdateState = .idle
    private let identity: BridgeCoupReleaseIdentity
    private let fetch: Fetch
    private let openPage: OpenPage

    init(identity: BridgeCoupReleaseIdentity = .installed(),
         fetch: @escaping Fetch = { url in
             var request = URLRequest(url: url)
             request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
             request.setValue("Bridge-Coup-update-check", forHTTPHeaderField: "User-Agent")
             request.timeoutInterval = 15
             let (data, response) = try await URLSession.shared.data(for: request)
             guard let response = response as? HTTPURLResponse else { throw UpdateError.invalidResponse }
             return (data, response)
         },
         openPage: @escaping OpenPage = { NSWorkspace.shared.open($0) }) {
        self.identity = identity
        self.fetch = fetch
        self.openPage = openPage
    }

    func check() async {
        guard state != .checking else { return }
        state = .checking
        guard let installed = BridgeCoupVersion(tag: identity.tag),
              let channel = identity.channel,
              channel.matchesInstalled(installed) else {
            state = .failed("This app has invalid release identity.")
            return
        }
        do {
            let (data, response) = try await fetch(Self.releasesURL)
            switch response.statusCode {
            case 200: break
            case 403 where response.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0", 429:
                throw UpdateError.rateLimited
            default: throw UpdateError.server(response.statusCode)
            }
            let releases: [GitHubRelease]
            do { releases = try JSONDecoder().decode([GitHubRelease].self, from: data) }
            catch { throw UpdateError.invalidResponse }

            var eligible: [(BridgeCoupVersion, BridgeCoupUpdateCandidate)] = []
            var incomplete: [(version: BridgeCoupVersion, tag: String)] = []
            for release in releases where !release.draft {
                guard let version = BridgeCoupVersion(tag: release.tagName) else { continue }
                guard (version.beta != nil) == release.prerelease else { continue }
                guard channel.allows(version) else { continue }
                let assetName = "Bridge-Coup-\(release.tagName)-arm64.dmg"
                guard release.assets.contains(where: { $0.name == assetName }) else {
                    if version > installed { incomplete.append((version, release.tagName)) }
                    continue
                }
                guard Self.isOfficialPage(release.htmlURL, tag: release.tagName) else {
                    throw UpdateError.invalidDestination
                }
                eligible.append((version, BridgeCoupUpdateCandidate(
                    tag: release.tagName, notes: release.body ?? "No release notes provided.",
                    pageURL: release.htmlURL
                )))
            }
            let newest = eligible.max(by: { $0.0 < $1.0 })
            if let newest, newest.0 > installed {
                state = .available(newest.1)
            } else if let missing = incomplete.max(by: { $0.version < $1.version }) {
                state = .incompleteRelease(missing.tag)
            } else {
                state = newest == nil ? .noEligibleRelease : .upToDate
            }
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    func openAvailableRelease() {
        guard case let .available(candidate) = state else { return }
        guard Self.isOfficialPage(candidate.pageURL, tag: candidate.tag) else {
            state = .failed("The release page is not an official Bridge Coup destination.")
            return
        }
        if !openPage(candidate.pageURL) {
            state = .failed("Could not open the release page in your browser.")
        }
    }

    private static func isOfficialPage(_ url: URL, tag: String) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        return components.scheme == "https" && components.host == "github.com" &&
            components.port == nil && components.user == nil && components.password == nil &&
            components.query == nil && components.fragment == nil &&
            components.path == "/absurdwall/bridge-coup/releases/tag/\(tag)"
    }

    private static func message(for error: Error) -> String {
        if let updateError = error as? UpdateError { return updateError.message }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut: return "The request timed out. Please retry."
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
                return "The network is unavailable. Check your connection and retry."
            default: break
            }
        }
        return "Could not read releases. Please retry."
    }

    private enum UpdateError: Error {
        case invalidResponse, invalidDestination, rateLimited, server(Int)

        var message: String {
            switch self {
            case .invalidResponse: "GitHub returned malformed release metadata. Please retry."
            case .invalidDestination: "A release has an invalid download page."
            case .rateLimited: "GitHub's request limit was reached. Please retry later."
            case let .server(code): "GitHub returned HTTP \(code). Please retry."
            }
        }
    }
}

@MainActor
final class BridgeCoupUpdateCoordinator: ObservableObject {
    @Published var isShowingUpdates = false
    let workflow: BridgeCoupUpdateWorkflow

    convenience init() {
        self.init(workflow: BridgeCoupUpdateWorkflow())
    }

    init(workflow: BridgeCoupUpdateWorkflow) {
        self.workflow = workflow
    }

    @discardableResult
    func checkFromMenu() -> Task<Void, Never> {
        isShowingUpdates = true
        return Task { await workflow.check() }
    }
}
