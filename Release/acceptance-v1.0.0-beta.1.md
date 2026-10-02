# Bridge Coup 1.0.0 Beta 1 release acceptance — open

Recorded 2026-10-02 for Issue #28. This is an evidence ledger, not a release
approval. No GitHub prerelease or public DMG download existed when this file
was written. Keep this record current through publication and installed-app
checks before closing the issue.

## Integrated candidate

- Source commit: `7634742` (Issue #23 review fixes integrated).
- Local candidate: `Bridge-Coup-v1.0.0-beta.1-arm64.dmg`, 109,466,866 bytes,
  SHA-256 `a44920543563e7a4a1bd752f142293f159f2b7d865e13e3ccb77b0a08bf5736e`.
- Declared identity: 1.0.0 Beta 1, build 10001, tag `v1.0.0-beta.1`.
- The integrated candidate was rebuilt and passed `build-macos-dmg.sh` package
  verification after the review fixes. The local artifact hash above was
  independently checked in the maintainer workspace. This artifact is not a
  browser download or published release.
- The earlier bundled-runtime package at the pre-fix source commit had a
  different hash; see `first-use-2026-10-02.md`. That evidence must not be
  attributed to this integrated candidate.

### Packaged GUI teaching on the integrated candidate

The final local candidate above was copied to the temporary
`/tmp/bridge-coup-issue-23-acceptance/Applications` directory and launched
with `CFFIXED_USER_HOME=/tmp/bridge-coup-issue-23-first-use-home`. A
command-line override selected its **bundled Codex 0.156.1** executable.
The app first showed signed-out guidance. Clicking **连接 ChatGPT** opened
Chrome at `auth.openai.com/choose-an-account`; that page then closed through
an existing browser session. After **检查连接**, Bridge Coup showed ChatGPT
connected and `gpt-6-astra` with Medium thinking effort available.

With a synthetic 3NT South position (South: ♠ AKQJ, ♥ 543, ♦ A432, ♣ K2;
other hands unknown), the installed app generated a real Codex teaching
response. It conditionally discussed five sure tricks and the missing North
hand and opening lead. This establishes a packaged-app, real-service teaching
turn on the integrated candidate. It was still the maintainer's macOS account:
the browser or Keychain may have reused existing authentication, and the
bundled runtime was selected by override rather than unmodified discovery.
It does not establish clean-user login, first launch from a browser download,
quarantine handling, or login-state preservation after an upgrade.

In the same installed final candidate, the DDS panel's **已知结果例牌** action
populated a complete 52-card, four-hand position with North holding thirteen
spades. DDS 3.0.0 displayed a verified result of **行牌方搭档 13 / 13 墩** for
each spade lead. This verifies packaged DDS execution through the GUI on the
local installed app. It still does not establish the clean-user,
browser-downloaded DDS release gate.

## Earlier two-version local rehearsal

The 2026-10-02 local rehearsal used two packages built from **`362e1d7`**,
before the integrated review-fix commit. Both package scripts passed their
full arm64/macOS-minimum/signature/runtime/DDS verification on an arm64 Mac
running macOS 27.0.1:

| Role | Version and build | SHA-256 |
| --- | --- | --- |
| Older, private test package | 0.9.0 Beta 1, build 9001 | `4fd67a778b499f21e743476084cec4327bf888ca3fbc114678d2d9f2bb685d4a` |
| Newer local candidate | 1.0.0 Beta 1, build 10001 | `87426e7fdb48e8c7585aa2312a67aae6d474eadbc9c1c06e365c47e8fbd418f1` |

The older app was copied from a mounted DMG into a temporary Applications
directory, launched, and used to save a review with a nonpersonal PNG. The
review and image appeared in the temporary Application Support directory.
After copying the newer app over it, About displayed **1.0.0 Beta 1 (build
10001)**. The saved review reopened; its screenshot filename remained and
its image viewer opened. A complete-deal DDS example in the older copied app
returned DDS 3.0.0's 13-trick result. Before any public release existed,
**Check for Updates…** correctly reported no eligible Apple Silicon DMG.

This rehearsal did **not** prove a clean-user upgrade. It ran under the same
macOS account with a temporary home, and a UserDefaults runtime path from the
main account leaked into the app. It did not establish preference preservation,
browser login, login-state preservation, real teaching, browser quarantine,
or the security override. The test PNG was not a bridge board and was left
unconfirmed. The newer package did not include the final review fixes.

## Release gates still to record

- [ ] Recheck final candidate tag/commit, app and DMG metadata, notices,
      package verification, SHA-256, and release notes together.
- [ ] Clean macOS user: browser-downloaded quarantined DMG, mount, copy to
      Applications, eject, first launch, and security override if offered.
- [ ] Clean user: bundled Codex 0.156.1 selected, own-account browser login,
      connection check, real teaching response, and valid complete-deal DDS.
- [ ] Isolated two-version installation: review, screenshot, preferences, and
      existing app-owned login state preserved after replacing the older app;
      record any external account expiry or service failure separately.
- [ ] Publish `v1.0.0-beta.1` as a GitHub prerelease with verified DMG and
      checked notes; record exact release and asset URLs and downloaded hash.
- [ ] From an older test app, confirm the real published beta update result,
      notes and official destination; from the current beta, confirm the
      up-to-date result without installation changes.
- [ ] Activate and deploy the website's explicit beta asset and release-note
      links only after public download verification. Check live desktop and
      narrow-screen pages plus the feedback link.

If any gate fails or cannot be observed, record it here and leave Issue #28
open. The local checks above are useful supporting evidence only.

## Shared early beta — 2026-10-02

The user explicitly authorized merging PR #29, replacing the website hero with
a real teaching example, and making the beta downloadable for friends before
full release acceptance. PR #29 merged at `b1d2738`; release source and identity
are pinned to `676979b5f5e918242152c5d58c450d606b44a3cb`. This changes the
publication timing only. Issue #28 and all unobserved installed-app gates remain
open. The exception is recorded in `Release/README.md` and the public notes.

- Final artifact: `Bridge-Coup-v1.0.0-beta.1-arm64.dmg`, version 1.0.0 Beta 1,
  build **10002**, **110,293,727 bytes**.
- SHA-256: `f5cdc53ff39da52fe6fac6e3baaa5009da6e267494447b93b8e6a0e5dbbd6272`.
- `build-macos-dmg.sh` rebuilt from the above source and completed its full
  package gate: release metadata, arm64/macOS minimum, executable permissions,
  final signatures, required notices, isolated signed-out Codex handshake, and
  complete-deal DDS solve. It contains both fixes from `0c5a324`.
- Published as a **prerelease**, not stable, at
  https://github.com/absurdwall/bridge-coup/releases/tag/v1.0.0-beta.1.
  The tag resolves to the exact source commit above.
- An unauthenticated HTTPS download of the complete public asset returned 200
  and matched the byte count and SHA-256 above. This is public transport proof;
  it is not clean-user installation or security-override acceptance.
- The website hero was captured from the user's current real 6♦ teaching
  session without changing its content. The desktop and 390px narrow preview
  passed visual checks; no horizontal page overflow was observed.
- The website's download activation retains an explicit early-beta notice.
  Clean-user installation/login/teaching/DDS, isolated two-version preservation,
  and installed-app checks against real release metadata remain unverified.

The earlier build 10001 evidence above is historical and must not be relabeled
as validation of build 10002. The user's currently open application was left
running with its unsaved bridge work; it was not replaced by this release.
