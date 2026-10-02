# Bridge Coup website

This static website is published from `docs/` to GitHub Pages by `.github/workflows/deploy-pages.yml`. The public URL is `https://absurdwall.github.io/bridge-coup/`. GitHub Pages uses the repository name as the URL path; keep asset paths relative so the local preview and deployed site agree.

## Update content

Edit `index.html` and `styles.css` directly. The gallery screenshots in `assets/` are unchanged captures from this repository's Mac acceptance evidence. The hero `app-teaching-example.png` was captured on 2026-10-02 from the user-selected real 6♦ session, without altering the app contents. It includes the app's own stale-analysis and screenshot-confirmation labels; it is a product illustration, not a new acceptance result. The logo and wordmark are copies of the approved `AppResources` images. If screenshots are replaced, use actual app captures and keep their captions/alt text accurate.

Preview with `python3 -m http.server 8000 --directory docs` and visit `http://localhost:8000/`. Check desktop and narrow widths. A push to `main` deploys the site.

The site offers the explicit `v1.0.0-beta.1` Apple Silicon DMG (build 10002), with known early-beta limits visible. The user authorized sharing this beta on 2026-10-02 before full clean-user and upgrade acceptance. Issue #28 remains open. Its first-use text matches `Release/README.md` and the bundled Codex route, but clean-user browser-download acceptance is still required. Follow the early-beta exception and full acceptance procedure in `Release/README.md`. The exact versioned asset URL is (`https://github.com/absurdwall/bridge-coup/releases/download/v1.0.0-beta.1/Bridge-Coup-v1.0.0-beta.1-arm64.dmg`) and the release-note URL is (`https://github.com/absurdwall/bridge-coup/releases/tag/v1.0.0-beta.1`). Do not use GitHub's stable-only `/releases/latest` shortcut for a beta. Verify the public link and downloaded DMG before advertising it. DMGs belong in GitHub Releases, never in `docs/`.
