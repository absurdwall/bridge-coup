# Bridge Coup 1.0.0 Beta 1

This is the first public beta for Apple Silicon Macs running macOS 14 or
later. It brings the bridge deal workspace, declarer-play teaching, local
review and screenshot saving, and separate double-dummy checks for a
complete deal.

## Before you download

- The download is an Apple Silicon DMG. Install by dragging **Bridge Coup.app**
  to **Applications**, ejecting the DMG, and starting the copy in Applications.
- Codex CLI 0.156.1 is included in the app. AI teaching and screenshot
  recognition need internet access and your own ChatGPT account with
  available access. The app download does not include AI service or guarantee
  account availability.
- This beta is ad hoc signed and **not Apple notarized**. If macOS blocks the
  copied app, first attempt to open it, then use **System Settings → Privacy &
  Security → Open Anyway** if offered, confirm the prompt, and reopen it from
  Applications. Managed-device policy may prevent an override. Do not
  disable Gatekeeper system-wide.

## First use and updates

In the app, open **连接状态** in the model area. If it says **需要 ChatGPT 登录**,
click **连接 ChatGPT**, complete browser login with your own account, return
to Bridge Coup, and click **检查连接**. Choose an available model and thinking
effort, enter the bridge information visible at the decision point, and
request a teaching plan. Retry controls preserve entered bridge work if
setup fails.

Use **Check for Updates…** from the app menu to read published release notes.
Downloads and installation are manual; the app does not replace itself or
restart automatically. Existing reviews, screenshots, settings, and app-owned
login data retain their existing app identifiers and storage when replacing
the app. Do not remove the user's Bridge Coup data during replacement.

## Current limits

- Intel Macs and macOS versions earlier than 14 are unsupported.
- An account or network failure can make AI functions unavailable even when
  the app opens. Double-dummy checks require a valid complete deal.
- This beta has no Developer ID signature or Apple notarization. Managed
  Macs may prohibit the security override.

Report problems at https://github.com/absurdwall/bridge-coup/issues and
include the version and build shown in **About Bridge Coup**. The installer
asset for this release must be named
`Bridge-Coup-v1.0.0-beta.1-arm64.dmg`.
