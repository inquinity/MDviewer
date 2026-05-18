# MDviewer Security Review

Date: 2026-05-18
Scope: Static review of the local source tree at commit `b36b6670ff84d93e88b45092b5441250a619147e`.

No app code, build scripts, install scripts, dependency installs, or network calls were executed as part of this review.

## Findings

### Medium: App makes startup network egress despite local-first claim

- Evidence: `src/main.m` defines GitHub release URLs and calls `checkForUpdates` during `applicationDidFinishLaunching`.
- Evidence: `README.md` describes the app as local-first with no network calls.
- Impact: Every launch checks GitHub releases, exposing user IP, timing, app version context, and standard request metadata without an obvious opt-out.
- Fix: Make update checks opt-in or user-initiated, document the egress, and avoid claiming no network calls unless disabled by default.

### Medium: Preview WebView is granted filesystem read access to `/`

- Evidence: `src/main.m` loads preview HTML with `allowingReadAccessToURL:[NSURL fileURLWithPath:@"/"]`.
- Evidence: `src/MarkdownViewer.sh` allows `file:` images and media in the generated CSP.
- Impact: The current renderer has strong mitigations, but the WebView capability is broader than needed. A sanitizer or vendor bypass, or a future renderer change, would have broad local file read reach.
- Fix: Scope read access to the opened document directory or another narrow resource boundary.

### Medium: Untrusted Markdown can trigger remote image/media loads

- Evidence: `src/MarkdownViewer.sh` permits `http:` and `https:` for `img-src` and `media-src`.
- Impact: Opening a Markdown file can contact attacker-controlled URLs through image or media references, leaking IP, timing, and possibly document-derived URL parameters.
- Fix: Default to `data:` and scoped `file:` only, with an explicit prompt or preference before remote media.

### Low: Clicked links can open broad URL schemes through macOS

- Evidence: `src/main.m` passes non-Markdown links directly to `NSWorkspace openURL`.
- Impact: A malicious document can present links that invoke local files or registered URL handlers when clicked.
- Fix: Allowlist expected external schemes and confirm or block other schemes and non-Markdown local files.

### Low: Build supply chain is mostly pinned, but not fully integrity-covered

- Evidence: `build.sh` pins package versions and hashes individual runtime assets, but copies the KaTeX fonts directory and licenses from downloaded archives without verifying those artifacts or the complete archive.
- Impact: Runtime JavaScript and CSS are hash-checked, which is good. Some extracted artifacts still depend on unverified tarball content.
- Fix: Verify complete downloaded tarballs or hash every extracted artifact.

## Access Map

| Area | Observed access | Risk |
| --- | --- | --- |
| Credentials | No credential reads found in reviewed source. | No finding in static review. |
| Filesystem | Reads selected Markdown file; writes temp preview HTML; exports PDFs; watches source directory; WebView read scope is `/`. | Broad WebView file permission is the main least-privilege gap. |
| Network | GitHub release check on startup; remote Markdown images/media allowed. | Undocumented egress contradicts README. |
| Clipboard | Copy-code feature writes selected code block text to clipboard. | User-initiated, low risk. |
| System commands | Native app launches bundled `MarkdownViewer.sh`; build/install scripts call toolchain and mutate app/default handler when run. | Expected, but install script is privileged-behavior surface. |
| Supply chain | `build.sh` downloads npm tarballs with pinned versions and partial hashes. | Mostly controlled, incomplete artifact coverage. |

## Coverage

Reviewed local source, shell scripts, release workflow, README, `.gitignore`, and security-sensitive patterns. Vendor bundles are downloaded at build time and were not present in the repository, so their runtime internals were not reviewed.
