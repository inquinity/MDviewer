# Agents Build Log - 2026-05-19

## Recently Opened Menu

- Added a File > Open Recent submenu backed by `NSDocumentController` recent document URLs.
- Added a Clear Menu action that clears the same recent-document list.
- Added a focused source-level regression check for the recent-menu wiring.

## Verification Notes

- Confirmed `tests/recent-menu.sh` failed before implementation because the File menu did not expose Open Recent.
- Confirmed `bash tests/recent-menu.sh` passes after implementation.
- Confirmed `clang -fobjc-arc -Wall -Wextra -Wno-unused-parameter -fsyntax-only ... src/main.m` exits 0 after implementation.
- Full app bundle build was not run because `build.sh` removes and recreates ignored `dist/` outputs and also may fetch npm packages if caches are incomplete.

## Rollback

- Revert the recent-menu changes in `src/main.m`, remove `tests/recent-menu.sh`, and remove this log entry.
