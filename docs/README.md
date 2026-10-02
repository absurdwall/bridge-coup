# Bridge Coup website

This static website is published from `docs/` to GitHub Pages by `.github/workflows/deploy-pages.yml`. The public URL is `https://absurdwall.github.io/bridge-coup/`. GitHub Pages uses the repository name as the URL path; keep asset paths relative so the local preview and deployed site agree.

## Update content

Edit `index.html` and `styles.css` directly. The three app screenshots in `assets/` are unchanged captures from this repository's Mac acceptance evidence. The logo and wordmark are copies of the approved `AppResources` images. If screenshots are replaced, use actual app captures and keep their captions/alt text accurate.

Preview with `python3 -m http.server 8000 --directory docs` and visit `http://localhost:8000/`. Check desktop and narrow widths. A push to `main` deploys the site.

The site currently states that the download is forthcoming. Its first-use text matches `Release/README.md` and the bundled Codex route, but clean-user browser-download acceptance is still required. Follow `Release/README.md` before activating a download. After Issue #28 publishes and verifies `v1.0.0-beta.1`, replace the forthcoming state with the exact versioned asset URL (`https://github.com/absurdwall/bridge-coup/releases/download/v1.0.0-beta.1/Bridge-Coup-v1.0.0-beta.1-arm64.dmg`) and release-note URL (`https://github.com/absurdwall/bridge-coup/releases/tag/v1.0.0-beta.1`). Do not use GitHub's stable-only `/releases/latest` shortcut for a beta. Verify the public link and downloaded DMG before advertising it. DMGs belong in GitHub Releases, never in `docs/`.
