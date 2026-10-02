# Local package verification — 2026-10-02

Environment: Apple Silicon (`arm64`), macOS 27.0.1, Xcode 26.6
(17F113), Apple Swift 6.3.3. DDS source was pinned to
`37c8a79f4c67c55d1a309ccb66dd00cb58af464a`.

| Local artifact | Embedded identity | Size | SHA-256 |
| --- | --- | ---: | --- |
| `.build/macos/Bridge-Coup-v1.0.0-beta.1-arm64.dmg` | 1.0.0 Beta 1, build 10001 | 6,150,111 bytes | `13ec01285aaa8c0b5ed6071c869e7e0c18f949dc72a4e3c6e961e8e277aa7268` |
| `.build/macos/Bridge-Coup-v0.9.0-beta.1-arm64.dmg` | 0.9.0 Beta 1, build 9001, external test manifest | 6,150,104 bytes | `c82e67fffdba22368ddbc9cf0a6509afe289979fcbe360774f930b2bafd57c72` |

Both DMGs were built by `Scripts/build-macos-dmg.sh` and passed
`Scripts/verify-macos-dmg.sh`: read-only mount and eject, Applications
shortcut, metadata, arm64-only executable files, macOS 14 minimum for the app
and DDS helper, executable permissions, artwork and DDS license, ad hoc
signatures, and a complete-deal DDS result with thirteen spade tricks.

The 1.0.0 Beta 1 app was also copied from its mounted DMG into an isolated
`Applications` directory, the image was ejected, and the copied helper
returned `{"moves":[{"suit":0,"rank":14,"equals":16380,"tricks":13}]}`
for the complete deal. The copied app signature verified.

`BRIDGE_TEACHER_DDS_HELPER` pointed to the copied helper for
`swift test --filter DoubleDummySolverIntegrationTests`; all six real-solver
integration tests passed.

This was a local package check. A browser-downloaded quarantined DMG, an
actual first GUI launch and security override, a visual About check, clean
profile runtime/login/teaching use, and an older-to-newer installed-app
replacement have not yet been exercised. The local DMGs have not been
published and do not include a bundled Codex runtime; subsequent release work
must rebuild and reverify artifacts before publication.
