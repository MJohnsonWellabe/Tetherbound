# Handover — T2-GATEF-RIGFIXES (2026-08-30)

Lane 3 of the four spawned from `ralph/reports/SPAWN_REQUEST-T2-GATEF-2026-08-30.md`. Scope: `tools/gate_f/segments/X04.json` (RIG-19) and `tools/gate_f/segments/X05.json` (RIG-22) only. Not gated on the other three lanes; did not touch `S03.json`, `S10.json`, or `operator_harness.gd`.

Branch `ralph/T2-GATEF-RIGFIXES` off `origin/main`, two commits, both pushed:

- `6cab3c63` — RIG-19 fix (`X04.json`)
- `c7b76deb` — RIG-22 fix (`X05.json`)

## RIG-19 — `X04.json`'s `move_to` budgets

### What changed

All seven `move_to` steps (`X04-019`, `X04-030`, `X04-058`, `X04-066`, `X04-078`, `X04-094`, `X04-111`) now carry an explicit `budget_frames`, replacing the harness's ~2400-frame default (`walk_budget_frames` in `tools/gate_f/operator_harness.gd`):

| step | target | entry save | measured distance | budget_frames |
|---|---|---|---|---|
| X04-019 | (14, 1314) south_bridge_grunt | S04-exit | 1301.3 m | 60000 |
| X04-030 | (195, 905) band 1 field | S04-exit (post-respawn, unknown exact start) | ≥909.5 m floor | 60000 |
| X04-058 | (195, 905) | mid-segment, expected already close | — | 20000 |
| X04-066 | (195, 905) | mid-segment, expected already close | — | 20000 |
| X04-078 | (195, 905) | mid-segment, expected already close | — | 20000 |
| X04-094 | (-420, 2470) Warrens mouth | S06-exit | 1225.5 m | 60000 |
| X04-111 | (150, 7595) Hall threshold | S09-exit | 6278.1 m | 70000 |

Distances were measured directly from the real `player_pose.position` recorded in `ralph/reports/gate-f-run-20260828T183531Z/{S04,S06,S09}/saves/*-exit.json`, not estimated. X04-094's and X04-111's budgets were cross-checked against this project's own precedent for the identical coordinates: `S06.json`'s `S06-50` walks to the same Warrens-mouth coordinate (44100 frames for a shorter 1065 m leg of the same trip), and `S09.json`'s `S09-17` walks a comparable 6081 m causeway leg toward the same approach (49500 frames). Each of my seven budgets was sized generously above what that calibration implies, on the stated principle that `move_to` (`operator_harness.gd:_walk_loop`) stops the instant it is `close_enough`, so an oversized budget costs nothing when arrival comes early.

### Validation performed

Godot 4.7 (linux editor binary) was installed and the project imported in this container. A throwaway step-script (not committed; lived at `/tmp/claude-.../scratchpad/RIG19-VALIDATE.json`, deleted after use) repeated each of the three *novel-distance* `move_to` calls — `X04-019`, `X04-094`, `X04-111` — against a scratch run directory seeded from the *real* `S04-exit.json` / `S06-exit.json` / `S09-exit.json` in `gate-f-run-20260828T183531Z`, through the same `boot → Load Game → wait 180s → creature_recall` sequence X04.json itself uses, run via `tools/gate_f/run_segment.sh` in logic mode with the run directory's own `RUN_METADATA.json` copied in so the harness's headless/display-server pre-flight matched. `X04-030`'s cluster was proxied by chaining a second `move_to` to (195,905) immediately after the first leg (not a true repro of the post-respawn start point, but exercises the same budget from a comparable distance).

**Confirmed arriving (this is what RIG-19 asked for — reach the target, no more "did not reach" FAILs):**

```
walked 1300.2 m to (14, 1314) in 17171 walking frames (0 held)      -- X04-019, from S04-exit
walked 445.1 m to (195, 905) in 5887 walking frames (0 held)        -- X04-030 proxy
```

Both arrived using well under a third of their assigned budget (60000), which is itself evidence the sizing is not just "enough" but comfortably enough — the earlier ~2400-frame default was undershooting by roughly an order of magnitude, not by a small margin.

**Did NOT arrive, and here is the important part — it is not a budget problem:**

```
FAIL did not reach (-420, 2470) in 60000 walking frames; stopped 1229.0 m short at (8.0, -3.0, 1318.0) (0 held)
```

This is `X04-094` from `S06-exit`. The player moved only a few metres from its exact spawn position over the *entire* 60000-frame budget. `run.log` explains why — dozens of repeated lines while this step was running:

```
[severed_spokes] player went over the edge at 13, -7, 1325 -- back to the road
[severed_spokes] player went over the edge at 5, -7, 1325 -- back to the road
[severed_spokes] player went over the edge at 1, -7, 1326 -- back to the road
...
```

`scripts/world/severed_spokes.gd` is SA4's deliberate world-edge mechanic — the seven old roads out of the Meadows, each permanently blocked by carved terrain/collision (spec §1E/§29), by design, with no UI explanation. `S06-exit`'s saved position (13.08, -4.14, 1323.54) sits right next to one of these boundaries (near the South Bridge crossing), and `move_to`'s straight-line-seeking navigator keeps steering toward it, gets bounced back to the road by the boundary's own recovery logic every time, and nets zero forward progress no matter how large `budget_frames` is. **No `budget_frames` value fixes this** — it is a routing problem (the navigator does not know to route around a world-edge boundary the way it detours around ordinary geometry), not a distance-budget problem, and it is outside RIG-19's scope (and outside my file-ownership scope for this fix, which is sizing budgets, not rewriting navigation). Flagging this as a new, separate finding rather than claiming X04-094 fixed.

**Not live-validated — X04-111 (Hall threshold, from S09-exit):** the validation run was stopped (time-boxed) after loading S09-exit and before this leg completed. Two things worth recording instead of a live result:

1. `S09-exit.json` in `gate-f-run-20260828T183531Z` is **byte-identical** to `S08-exit.json` (confirmed: both have `player_pose.position` = `[8.82593536376953, -2.89915490150452, 1318.49340820312]`) — S09 was never actually completed in that run directory (consistent with `RESUMED_RUN_20260829.md` and `RUN_INCOMPLETE.md`, which list S01-S09 as of that point with S09 not among the finished ones at freeze time). So the "6278.1 m" distance my budget was sized against is a distance from a **stale placeholder** position, not a genuine post-S09 state. Once S09 actually completes in a real run, its exit save will very likely sit much closer to the Hall — `S09.json`'s own internal `S09-56` step, which walks this *same* (150, 7595) coordinate from a point already inside band 5, only needs 9000 frames. So 70000 is very likely a large over-provision against the real future distance, not a tight one — safe either way, but its "confirmation" here is by precedent rather than a live arrival.
2. `S09-exit`'s spawn shares the same `region: "corridor"` signature and a similar negative-Y position as `S06-exit`'s problem case above. There is a real chance `X04-111` will hit the same severed-spoke bounce-back once a genuine S09-exit exists and/or once run against the real target — this could not be confirmed or ruled out in the time available and should be re-checked live once the upstream party-health fix lands and a fresh, real `S09-exit.json` exists.

### What remains gated on the upstream party-health issue

All three entry saves used here (`S04-exit`, `S06-exit`, `S09-exit`) carry the same single fainted creature (`Moss`, `hp: 0.0`, `fainted: true`) that `T2-BUILDPLACE` is separately fixing. One incidental, useful data point from this validation: the fainted party did **not** block ordinary movement in either of the two successful legs — `creature_recall` on an all-fainted party appears to no-op cleanly rather than hang input, so whatever T2-BUILDPLACE finds is unlikely to also explain the severed-spokes issue above (that is a genuinely separate mechanism, confirmed by `run.log`). Untested and still blocked, as anticipated: whether a fight actually **starts** once the player arrives at a combat site (`X04-020` onward), since a fainted-only party cannot deploy a healthy fighter. That question is unchanged from before this fix and is not something the budget-sizing fix could address either way.

## RIG-22 — `X05.json`'s save-tab navigation

### What changed

All nine save-verification blocks (one per journey exit save, S02 through S10 — `X05-014`/`015`, `040`/`041`, `066`/`067`, `092`/`093`, `118`/`119`, `144`/`145`, `171`/`172`, `197`/`198`, `223`/`224`) changed from:

```json
"action": "open_menu", "args": {}
...
"action": "press", "args": {"control": "menu_tab_right", "times": 5, ...}
```

to:

```json
"action": "open_menu", "args": {"tab": "map"}
...
"action": "press", "args": {"control": "menu_tab_right", "times": 3, ...}
```

This is a byte-for-byte match of the pattern already fixed and proven for the identical defect (there called RIG-14) in `S06.json` (`S06-90`/`S06-91`) and `S08.json` (`S08-121`/`S08-122`): `game_menu.gd` reopens the pause shell on whichever tab was last used, not Backpack, so a fixed 5-press count from an assumed Backpack start (index 0) lands wherever the shell last was. `map` is one of only two tabs with a shortcut in `data/config/menu.json` (`shortcuts.map`), so opening onto it is the only deterministic starting point available. From `map` (index 2 in `menu.json`'s `tabs` list) to `save` (index 5), 3 presses of `menu_tab_right` is correct; the stale "five RB presses reach Save" `expected` text on the cycle steps was also corrected to say three, from the map tab.

### Validation performed

Not run live — a full X05 pass is nine cold loads at ~180 s of in-game wait each plus nine boot-to-title round trips, and time did not allow it in this lane alongside RIG-19's validation. Confidence instead comes from exact precedent: the fix is not a new mechanism, it is the literal pattern `S06.json` and `S08.json` already carry for this same defect class, verified index-for-index against `data/config/menu.json`'s `tabs` list (`backpack=0, creatures=1, map=2, quest_log=3, build=4, save=5, settings=6`), which is the same reasoning `S06-91`'s own `observation` field documents for its `times 5 -> 3` change. I did not invent a new fix shape; I ported one already shipped and (per `S06`/`S08`'s own commit history) already reasoned through for this exact class of defect.

**What this means for a real run:** the pre-existing failure mode — "at least 7 of 8 completed save-verification blocks landed on the wrong tab" and the downstream `FAIL slot N has no file... did the Save tab actually write?` assertion firing for the wrong reason — should no longer occur, because every block now opens on a known tab (`map`) rather than an assumed one. Whether the underlying Save tab write itself succeeds is a question this fix doesn't touch and was never in question for RIG-22 (RIG-22 is specifically "does the harness reach `menu_save`", not "does saving work") — that remains to be seen honestly once a real run reaches these steps, which needs either a live pass I did not have time to run here, or the next full Gate F run to answer for real.

## Reproduce

```bash
# Environment (fresh container)
curl -fL -o g.zip https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip \
  && unzip -o g.zip && chmod +x Godot_v4.7-stable_linux.x86_64 \
  && mkdir -p ~/.cache/tetherbound-art && mv Godot_v4.7-stable_linux.x86_64 ~/.cache/tetherbound-art/godot
~/.cache/tetherbound-art/godot --headless --path . --import   # ~5 min, once

# RIG-19: re-run the real X04 segment (needs S04-exit/S06-exit/S09-exit already
# present in the target run directory, e.g. by pointing --run-dir at an existing
# gate-f-run-*/ directory that has them, or by seeding a scratch one)
tools/gate_f/run_segment.sh --run-dir <a run dir with S04/S06/S09 exit saves> X04

# RIG-22: re-run the real X05 segment the same way (needs all nine S0n-exit saves)
tools/gate_f/run_segment.sh --run-dir <a run dir with S02-S10 exit saves> X05
```

To reproduce this lane's own scratch validation exactly, copy `S04/saves/S04-exit.json`, `S06/saves/S06-exit.json`, `S09/saves/S09-exit.json`, and the run root's own `RUN_METADATA.json` from `ralph/reports/gate-f-run-20260828T183531Z/` into a fresh scratch run directory (the `RUN_METADATA.json` copy is required — without it the harness's freeze-record pre-flight falls back to the packaged `ralph/reports/gate-f-candidate/RUN_METADATA.json`, which claims an X11 display server, and BLOCKs a headless run before step 1 regardless of `evidence_lane`), then drive `move_to` with the same `at`/`budget_frames` pairs as `X04-019`, `X04-094`, `X04-111` from a `evidence_lane: "logic"` step-script through the same boot → Load Game → wait 180 s → `creature_recall` sequence X04.json itself uses.

## Summary

| | status |
|---|---|
| RIG-19: budget_frames added to all 7 `move_to` steps | done, committed |
| RIG-19: arrival confirmed live (2 of 3 novel-distance legs) | confirmed |
| RIG-19: X04-094 (Warrens mouth) arrival | **NOT achieved — separate severed-spokes routing issue, not a budget problem, flagged not fixed** |
| RIG-19: X04-111 (Hall threshold) arrival | not live-tested; budget is safely oversized by precedent, and S09-exit itself is a stale placeholder in this run directory |
| RIG-22: named-tab fix applied to all 9 blocks | done, committed |
| RIG-22: live-validated | not run (time); is an exact, verified port of S06/S08's already-shipped fix for the identical defect |
| Real combat / real save-write outcomes | still gated on the separate upstream party-health fix (T2-BUILDPLACE), as expected going in |
