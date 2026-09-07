# Common rules for the 0905 follow-up wave

You are one lane in a second wave, picking up concrete findings that today's 24 "0904" lanes
found, documented, and correctly did NOT fix because the fix was outside their file ownership.
Every item in your brief is quoted or closely paraphrased from the lane that found it — read
your brief's "Source" line for which lane and report to consult for full context
(`ralph/reports/<LANE>-0904/REPORT.md` — these branches may be merged/deleted; if so, find the
report at that same path on `origin/main`).

Follow `ralph/briefs/0904/COMMON.md` in full for the operating rules (git, Godot install,
testing discipline, visual-judge process, report format, hard rules). This file only adds
what's different for this wave:

- **Base every branch on `origin/main` at `f8a47ee4` or later** (`git fetch origin main && git
  checkout -B ralph/<LANE>-0905 origin/main`) — all 24 base lanes have landed; you are working
  on top of finished, merged work, not the old `ralph/W*-0904` branches.
- **Branch/report naming:** `ralph/<LANE>-0905`, report at `ralph/reports/<LANE>-0905/REPORT.md`.
- **Next free decision number is D87.** Check `docs/decisions/` on `origin/main` again yourself
  before writing one, in case a sibling lane in this same wave already took it.
- **Known red on `main` at your start**, not yours to fix: `verify-terrain-bake-freshness` and
  the matching unit-test shard fail because `data/terrain/playground/manifest.json` is stale
  against `data/config/terrain_playground.json` (the scatter half of this was already fixed on
  `main`). One lane in this wave (N10) owns the re-bake; everyone else should expect this one
  red and not chase it.
- **Multiple lanes in this wave may run concurrently and could touch adjacent areas** (e.g.
  N02 and N03 both touch `scripts/world/` files, N04 and N05 both touch UI/world dressing).
  Stay inside your own brief's file list exactly. If you find you need a file another lane in
  this wave owns, record it as a routed finding exactly as the 0904 lanes did — do not touch it.
- **This is real, previously-documented work, not speculative.** Every item was already
  root-caused or precisely specified by the lane that found it. Your job is largely to execute
  the fix that's already been described, verify it properly, and write it up — not to
  re-investigate from scratch. Read the cited report section first.
