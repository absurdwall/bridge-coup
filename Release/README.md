# Bridge Coup Mac package

The first planned release is **Bridge Coup 1.0.0 Beta 1**, build **10001**, tag
`v1.0.0-beta.1`. `release.env` is the declared identity for the app metadata
and DMG filename. Keep the tag, release notes, and website aligned with it.
Increase `RELEASE_BUILD` for every distributed build, including a rebuild of
the same beta. Keep `CFBundleShortVersionString` numeric; the beta channel,
label, and tag are embedded separately in `Info.plist`.

For a two-version upgrade rehearsal, copy `release.env` outside the checkout,
change its version, beta number, label, tag, build, and asset name, then set
`BRIDGE_COUP_RELEASE_FILE` to that **absolute path** for the build and
verification commands. For example, an older test identity can use
`0.9.0 Beta 1`, `v0.9.0-beta.1`, build `9001`, and
`Bridge-Coup-v0.9.0-beta.1-arm64.dmg`. Keep the test DMG separate from the
public release artifact. The scripts validate agreement among identity fields
and embed the test identity into that app; they do not edit the tracked release
declaration. A future stable release uses channel `stable`, a plain
`v<version>` tag and matching label.

## Build and verify

Run on an Apple Silicon Mac with Xcode command-line tools, Swift, and network
access for the pinned DDS source, Bazelisk, and official Codex CLI download:

```sh
./Scripts/build-macos-dmg.sh
```

This produces `.build/macos/Bridge-Coup-v1.0.0-beta.1-arm64.dmg`.
The build script runs `verify-macos-dmg.sh` after creating it. Recheck an
existing artifact with:

```sh
./Scripts/verify-macos-dmg.sh .build/macos/Bridge-Coup-v1.0.0-beta.1-arm64.dmg
shasum -a 256 .build/macos/Bridge-Coup-v1.0.0-beta.1-arm64.dmg
```

Verification mounts the DMG read-only, checks the Applications shortcut,
bundle identifier, version/build/beta fields, macOS 14 minimum, arm64-only
executables, executable permissions, required artwork and DDS/Codex notices,
ad hoc signature, an isolated signed-out Codex app-server handshake, and a
real complete-deal DDS solve from the mounted helper. The
script detaches the image on exit. The DMG is a local build artifact and is
not committed to the repository.

## Release gates and publication

Use this order for each beta. `release.env` is the source for the version,
build, tag, and asset name; change all four together for later betas. Never
reuse a distributed build number for a changed package. The current release
notes file is `Release/notes-v1.0.0-beta.1.md`. Confirm its version,
prerequisites, and limitations against the final package before using it.

1. Start from the integrated commit intended for the tag and a clean worktree.
   Record its commit, macOS version, chip, Xcode/Swift versions, app label/build,
   bundled Codex version, DDS version, DMG size, and SHA-256 in a dated
   acceptance record. Check that the Codex archive contains no extra notice
   payload and inspect the final app resources. Run relevant Swift tests,
   `./Scripts/build-macos-dmg.sh`, and the verifier above. A package created
   before the final source change must be rebuilt and reverified.
2. Before advertising a release, use a clean macOS user on an Apple Silicon
   Mac running macOS 14 or later. Install the candidate by opening the DMG,
   copying the app to Applications, ejecting, and launching the copied app.
   Exercise the actual security prompt and **Open Anyway** path if macOS
   presents it. Check the About label/build, bundled runtime selection,
   browser login with the tester's account, a real teaching response, and a
   complete-deal DDS solve. Record any skipped or failed observation as open.
   A temporary `HOME` or `CFFIXED_USER_HOME` in the same account is not a
   clean user because macOS preferences can leak across it.
3. Build a distinct older test package from an external release manifest as
   described above. In an isolated user profile, save a representative review
   and screenshot, set preferences, and connect the app-owned login in the
   older installed app. Replace that app in Applications with the candidate,
   reopen it, and inspect each item. Record both package identities and
   whether login state survived separately from any account expiry or service
   error. This rehearsal can precede public publication; it cannot prove the
   real GitHub update result yet.
4. Only after those local and installed-app gates pass, create the tag at the
   verified commit and publish the DMG as a GitHub **prerelease** with the
   checked notes. For the first beta, the commands are:

   ```sh
   git tag v1.0.0-beta.1 <verified-commit>
   git push origin v1.0.0-beta.1
   gh release create v1.0.0-beta.1 \
     .build/macos/Bridge-Coup-v1.0.0-beta.1-arm64.dmg \
     --repo absurdwall/bridge-coup --prerelease \
     --title 'Bridge Coup 1.0.0 Beta 1' \
     --notes-file Release/notes-v1.0.0-beta.1.md
   ```

   Inspect the published tag, prerelease flag, asset name and size, and notes
   with `gh release view v1.0.0-beta.1 --repo absurdwall/bridge-coup`.
5. Download the **versioned asset URL** through a real browser into the clean
   user, verify its SHA-256 against the candidate, and repeat mount, copy,
   eject, launch, first use, and DDS as needed for browser quarantine. From a
   distinct older installed test package, use **Check for Updates…** against
   real published metadata; confirm the beta label, notes, and official
   versioned release page. Check that the current beta reports up to date.
   This update action must not replace the app or clear saved work.
6. Only after the public asset and installed-app checks pass, activate the
   website's exact beta asset and release-note links in `docs/index.html`,
   replacing its forthcoming state. Use the tag-specific URLs documented in
   `docs/README.md`, never `/releases/latest` for a prerelease. Deploy the
   website through the `main` Pages workflow, then verify its live download
   and feedback links, release identity, and desktop/narrow-screen layout.
   Record the live URL and downloaded hash in the acceptance record.

Stop on any failed or unobserved gate. Leave the website download as
forthcoming and Issue #28 incomplete; state the exact failure in the
acceptance record. If a published asset fails verification, remove any active
site link immediately, investigate, and prepare a corrected package with a
new build number before advertising it. A local package check, fixture,
same-account temporary home, or source preview never substitutes for a
browser-downloaded installed app in a clean macOS user.

The helper is built from DDS 3.0.0 at the pinned source commit. Its Apache
License 2.0 notice is copied into the app's Resources directory. The bundle
also includes official Apple Silicon Codex CLI 0.156.1 from OpenAI's
`rust-v0.156.1` release. `Scripts/fetch-codex-runtime.sh` verifies the
published release archive SHA-256 before extraction. Tagged upstream
`LICENSE` and `NOTICE` are copied from `ThirdPartyNotices/` into the bundle.
This source notice review does not establish a complete binary dependency
license audit; confirm the selected release has no separately bundled notices
before publication. The checked binary links only system dynamic libraries.
No credentials are bundled. The bundle identifier remains
`app.tortillaflat.bridge-teacher`; saved reviews,
screenshots, runtime login state, and preferences continue using their
existing `~/Library/Application Support/Bridge Teacher/` location.

## Install and first launch check

On a macOS 14 or newer Apple Silicon Mac, download the DMG, open it, drag
`Bridge Coup.app` onto its `Applications` shortcut, then eject the mounted
image. Start the copy in Applications, not the app inside the mounted image.
Because this build is ad hoc signed and unnotarized, macOS may block the first
launch. Try opening the copied app, then use **System Settings → Privacy &
Security → Open Anyway** for Bridge Coup if macOS offers that choice. Confirm
the macOS prompt and reopen from Applications. Managed-device policy may
prevent an override; do not disable Gatekeeper globally.

The app includes Codex. Open **连接状态** in the model area. If it reports
**需要 ChatGPT 登录**, click **连接 ChatGPT**, complete browser login with your
own account, return to Bridge Coup, and click **检查连接**. Choose an available
model and thinking effort, enter the bridge information visible at the
decision point, and request a teaching plan. Internet access and an account
with available AI access are required; the app download does not include
unrestricted AI service. Retry controls preserve entered bridge work.

Record the exact macOS version, chip, DMG SHA-256, release label/build shown in
About Bridge Coup, security prompt and override outcome, copy/eject/launch
outcome, bundled Codex version/path, browser login, a completed real teaching
response, and a DDS run with a complete deal. A passing package verification
script does not establish clean-machine first use or a successful upgrade;
those require the separate release acceptance work.
