# Local package verification — 2026-10-02

Historical pre-bundled-runtime package evidence. The hashes below identify
local packages from this earlier stage, not the integrated candidate in
`acceptance-v1.0.0-beta.1.md`.

Environment: Apple Silicon (`arm64`), macOS 27.0.1, Xcode 26.6
(17F113), Apple Swift 6.3.3. DDS source was pinned to
`37c8a79f4c67c55d1a309ccb66dd00cb58af464a`.

| Local artifact | Embedded identity | Size | SHA-256 |
| --- | --- | ---: | --- |
| `.build/macos/Bridge-Coup-v1.0.0-beta.1-arm64.dmg` | 1.0.0 Beta 1, build 10001 | 6,150,101 bytes | `61b564f4c02738423db18e478a40364d5b896a380de5cc6924808eec4c285713` |
| `.build/macos/Bridge-Coup-v0.9.0-beta.1-arm64.dmg` | 0.9.0 Beta 1, build 9001, external test manifest | 6,150,120 bytes | `cb288d871a64eb9af690bf09546b0f2eb8a2bc9223262218ff3b8392154b6ed4` |

Both DMGs were built by `Scripts/build-macos-dmg.sh` and passed
`Scripts/verify-macos-dmg.sh`: read-only mount and eject, Applications
shortcut, metadata, arm64-only executable files, macOS 14 minimum for the app
and DDS helper, executable permissions, artwork and DDS license, ad hoc
signatures, and a complete-deal DDS result with thirteen spade tricks.

The 1.0.0 Beta 1 app was also copied from its mounted DMG into an isolated
`Applications` directory, the image was ejected, and the copied helper
returned `{"moves":[{"suit":0,"rank":14,"equals":16380,"tricks":13}]}`
for the complete deal. The copied app signature verified.

The final beta DMG was mounted again, copied into a separate temporary
`Applications` directory, and ejected. On this Mac, launching that copied
app opened the Bridge Coup workspace. Its About Bridge Coup menu opened a
standard About window that visibly read **Version 1.0.0 Beta 1 (build 10001)**,
matching the copied app's embedded version/build metadata. The test app was
closed afterward; the previously running user-installed copy was left alone.

The locally built DMG and copied app had no `com.apple.quarantine` extended
attribute. The copied app opened without a Gatekeeper prompt, so this run
could not exercise the documented **Privacy & Security → Open Anyway**
override. The copied path was isolated, but the GUI showed existing account
state; changing `HOME` for one launch did not establish an isolated macOS
user profile. This launch does not establish clean first use.

`BRIDGE_TEACHER_DDS_HELPER` pointed to the copied helper for
`swift test --filter DoubleDummySolverIntegrationTests`; all six real-solver
integration tests passed.

This was a local package and GUI check. A browser-downloaded quarantined DMG,
the first-launch security override, clean-profile runtime/login/teaching use,
and an older-to-newer installed-app replacement have not yet been exercised.
These local DMGs were not published and did not include a bundled Codex
runtime. Later bundled-runtime and integrated candidates are recorded
separately; neither this package check nor its hashes establish release
acceptance.
