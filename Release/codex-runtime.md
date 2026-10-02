# Bundled Codex runtime decision — 2026-10-02

Bridge Coup's Apple Silicon package uses the official standalone Codex CLI
**0.156.1** from OpenAI's [`rust-v0.156.1` release](https://github.com/openai/codex/releases/tag/rust-v0.156.1).
The release asset is
[`codex-aarch64-apple-darwin.tar.gz`](https://github.com/openai/codex/releases/download/rust-v0.156.1/codex-aarch64-apple-darwin.tar.gz),
94,626,816 bytes. GitHub release API metadata reports SHA-256
`2bd64af14dedd47795f2f6bfd5d125cf79199acc2c7ba222144e08127111a5ca`.
The build script requires that exact digest. The archive contains one
`codex-aarch64-apple-darwin` executable; it is renamed `codex` in the app's
Resources directory. No executable is copied from a maintainer installation.

The extracted binary reports `codex-cli 0.156.1`, has only an arm64 Mach-O
slice, declares macOS 11.0 as its minimum, and dynamically links only
`/usr/lib` and `/System/Library` paths. Its upstream Developer ID signature
verified before repackaging. The assembled Bridge Coup package is then ad hoc
signed as a whole; package verification checks its final signature, architecture,
minimum OS, version, and live app-server `initialize` plus signed-out
`account/read` responses with a fresh `CODEX_HOME`.

OpenAI's source at the selected tag provides [Apache 2.0
`LICENSE`](https://github.com/openai/codex/blob/rust-v0.156.1/LICENSE) and
[`NOTICE`](https://github.com/openai/codex/blob/rust-v0.156.1/NOTICE).
Copies are tracked as `ThirdPartyNotices/Codex-LICENSE.txt` (SHA-256
`d17f227e4df5da1600391338865ce0f3055211760a36688f816941d58232d8dc`)
and `ThirdPartyNotices/Codex-NOTICE.txt` (SHA-256
`9d71575ecfd9a843fc1677b0efb08053c6ba9fd686a0de1a6f5382fd3c220915`).
The notice includes the Ratatui-derived MIT attribution. Package verification
checks that both files survive into the DMG. This records the tagged project's
published terms, not an exhaustive independent audit of binary dependencies.
Before publication, confirm the chosen release asset has no separate notice
payload beyond this one-file archive and inspect the final app resources.

Bundling eliminates a terminal prerequisite for the intended user. Bridge Coup
still uses its own browser login and separate app-owned Codex Home; no account
or credential is included. This decision does not imply OpenAI endorses
Bridge Coup or that an account has unrestricted AI access. A real teaching
response on a clean user environment remains a separate release gate.
