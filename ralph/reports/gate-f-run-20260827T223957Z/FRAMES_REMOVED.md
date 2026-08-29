# Frames removed from this run — 2026-08-29

This Gate F run is **superseded by run 3**
(`ralph/reports/gate-f-run-20260828T183531Z`).

Its captured frames (PNG/JPG) were deleted from the working tree during the
2026-08-29 documentation cleanup. **Everything else was kept**: every
`INVENTORY.json`, `RUN_METADATA.json`, step log, `BLOCKER.md`,
`WHY_INCOMPLETE.md` and markdown finding is still here, so every citation
of this run in `ralph/GATE_F_MASTER_PROTOCOL.md`, `gate-f-lane-log.md`,
`gate-f-rig-log.md` and `gate-f-defects-log.md` still resolves.

Why: the three superseded runs held 1,286 image files totalling ~2.26 GB
against ~41 MB of metadata. The frames are the evidence for defects that
have since been fixed and re-verified, or superseded by run 3's own capture.
The reasoning about them lives in the logs, which are text.

**This does not shrink the git history.** The blobs remain reachable in
earlier commits, so clone size is unchanged. Removing them from history
would mean a filter-repo and a force-push over shared history, which was
deliberately not done. If clone size ever becomes the actual problem, that
is the conversation to have — with the owner, deliberately.

To recover any frame: `git log --all --diff-filter=D -- <path>` then
`git checkout <commit>^ -- <path>`.
