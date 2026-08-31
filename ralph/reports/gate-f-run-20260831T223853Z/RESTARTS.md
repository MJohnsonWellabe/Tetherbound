# Restarts

## S02, S03 -- superseded-1 (2026-08-31)

**Reason:** not a code/data fix -- an operator entry-save provenance error.

The initial S02 (inherited, not run this session) and S03 (run) attempts were
seeded from `S02-exit.json` fetched from `ralph/GATE-F-CAPSTONE-2`'s run
directory, per the task briefing's instruction. That save's inventory is
`{orb_basic: 12, revive: 2}` -- no `potion_small`, no `berries`. It was
produced by CAPSTONE-2's own S02 run at candidate `679f990c` (CAP-1 fix
present, CAP-2 fix not yet landed). Loading a save does not retroactively
grant items a later data-file fix would have added; the save is a frozen
snapshot of what the gift beat actually gave at the time it ran.

Seeding S03 from it reproduced CAP-2's exact wall: 315 PASS / 29 FAIL / 9
SKIP, identical to the pre-fix capstone-2 numbers, for the identical reason
(starter takes training-fight damage with nothing in the kit able to heal a
merely-hurt creature) -- except this time the fix for that exact gap is
present in the running candidate and simply never reached the save.

**Old SHA (as recorded in the superseded attempt's telemetry):** the segment
runner stamps `--gatef-sha` from `git rev-parse HEAD` at invocation time,
which by then was this run's own checkpoint commit `9c2716af` (game code/data
identical to candidate `4ef01e40`; the diff between them is `ralph/reports/**`
only). The save itself is what carries the actual code-provenance defect,
not the SHA stamp.

**New SHA:** same candidate (`4ef01e40`, carried on this branch). No code or
data changed. S01 and S02 are being re-run fresh (production title -> New
Game -> opening beats) to produce an uncontaminated `S02-exit.json`, then S03
is re-attempted from that save.

Superseded directories preserved at `S02-superseded-1/` (the fetched save
only; no segment was actually run for S02 in the first attempt) and
`S03-superseded-1/` (full segment output, INVENTORY.json, telemetry, notes).
