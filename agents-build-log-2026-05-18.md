# Agents Build Log - 2026-05-18

## Security Remediation

- Connected local repository to `https://github.com/raltman2_uhg/MDViewer.git`.
- Pushed the initial upstream code and tags before adding security-review artifacts.
- Added `SECURITY_REVIEW.md` as a separate documentation commit.
- Changed update checks from automatic launch egress to a user-initiated menu action.
- Narrowed `WKWebView` file read access from `/` to the generated preview directory.
- Tightened preview CSP to block remote HTTP/HTTPS image and media loads from Markdown.
- Added URL scheme allowlisting for clicked Markdown links.
- Refactored build hash verification through a single helper for clearer failure behavior.

## Verification Notes

- Static verification only.
- No app launch, install, dependency install, package script, or build execution was performed.
- Fetching pinned npm tarballs to compute complete archive hashes failed because `registry.npmjs.org` could not be resolved from this environment.

## Rollback

- Revert the remediation commit to restore the previous runtime behavior.
- Revert the security-review commit separately if the review artifact should not remain in repository history.
