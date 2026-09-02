# Coordinator handover: landing `ralph/LAND-0830J`

**Written 2026-08-30 by the outgoing landing coordinator, at the owner's
instruction to archive and hand over.** Read this before touching the branch.

## Where it stands

- **`ralph/LAND-0830J` = `841cdd42`** is the consolidation. It carries every
  lane's work — about 896 files and +55,000 lines from ~20 lanes — plus the
  fixes below. `main` is still `24fc81cb` and is a day stale.
- **CI run 3251 (`33331269328`) is in flight on that tip.** Expect ONE failure,
  `verify-owner-regressions-shard (party_count_after_catches)`, and nothing else.
- The branch is ready to land the moment you accept that one red job.

## Read the job list across BOTH pages, every time

The single most reliable way to mis-declare this run green. The job list pages
at 30 against 59 jobs, and on **three separate runs today page 1 read all-green
while page 2 held the failures**. `get_job_logs(failed_only)` is worse — it only
reads page 1 and once reported "0 failed, total_jobs: 30" on a run with four.

Expected skips, both fine: `verify-continuous-core-known-red`, `export`.

## `curl` to the GitHub API returns 403 here

Every bash CI watcher armed today died silently on this. Its output looks
identical to "still watching", which is how a completed failing run went
unnoticed for 26 minutes. **Use the `mcp__github__actions_*` tools, or a
`send_later` check-in that calls them.** Do not arm curl-based watchers.

## The one red job, and why it is not the consolidation's

`party_count_after_catches` has failed on EVERY run of this branch — 3231, 3246,
3248, 3249, 3250 — including before any of my changes. The full diagnosis,
measurements and four failed fix attempts are in
`ralph/reports/PARTY_COUNT_STRADDLE_2026-08-30.md`. The short version: the
Practice Meadow spawn cluster straddles the village outline T5-OPENING added,
`tools/_probe_catch_stand.gd` proves no staging point reaches all three members
(1/3 from outside, 2/3 from inside), and the fix is a boundary change or a
cluster split — **not** a relocation, because the opening's own walk depends on
the cluster staying where it is.

**Do not attempt it on the landing branch.** I tried four times; three of those
attempts broke a job that had been green, and each round costs a full CI run.

## What this session actually fixed, and should not be undone

- **A pebble blocked the route to the chapter's climax.** Baked corridor scatter
  stood inside the Hall's rooms; the player was hard-stopped against
  `Pebble_Round_3_Collision` on the walk from the Warden Arena to the Legendary
  Chamber. Fixed by clearing scatter per chamber via `vegetation.gd::clear_area()`
  — the mechanism `burrow_warrens.gd` already uses for the identical defect.
  **86 props were standing inside the five rooms.**
- **`stronghold.gd::_visual_bounds()`** read `global_transform` on props not yet
  in the tree, so `_fit_to_height` sized things from bounds that were never
  measured. Six errors per boot, now zero.
- **The scatter bake** was refreshed by running the real bake, not by editing the
  hash: one file changed, only its `config_fingerprint`. Note that ANY edit to
  `terrain_playground.json` invalidates it, a comment included, and the six-minute
  bake is the only refresh.
- Two probes worth keeping: `tools/_probe_hall_chamber_passage.gd` and
  `tools/_probe_catch_stand.gd`.

## Open, and not this branch's

**The arbiter shows a prompt that the press does not activate.** Three sightings
today: T5-CARE's build verb near a harvestable node, the engage prompt
(investigated and cleared by LAND-FIX-2), and `smoke_authored_camps` at
`trail_camp` (346, 935) — prompt offered, press does nothing, failed twice and
passed twice. One lane, not three write-ups.

## Owner asks still outstanding

Reference art for the two unrecoverable humanoids; a ROG Ally playtest
(OP-0830-6); someone to LISTEN to the 73 synthesised audio files; and whether
Mira/Tam/Oskar/Bram get bespoke bodies (T1-VILLAGERS' handover puts the case).

## Branch cleanup, once landed

31 remote branches are fully contained in this consolidation and safe to delete.
Keep exactly two: **`ralph/LAND-0830J`** and **`ralph-status`** — the latter is
not a work branch, it carries `ralph/NOTES.md`, a cross-container notepad that by
design "merges into nothing and runs no CI".

## The next effort's brief

`ralph/NEXT_COORDINATOR_FULL_STATE_AUDIT.md`, on this branch, is the owner's
written instruction for what comes after the landing: one lane per exit criterion
A–K, one for a full Gate F playthrough, one that photographs everything in the
game, no game-code changes, feeding a plan written by Fable.
