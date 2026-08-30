# GATE-F-FULL — defects, live log

Run: `ralph/reports/gate-f-full`, branch `ralph/GATE-F-FULL`, candidate
`453107fb` (LAND-0830J landed on `main` 2026-08-30).

Severity words follow the Gate F protocol: **BLOCKER** (the chain cannot
proceed), **SHIP** (a player-facing defect a real player would report),
**RIG** (the instrument, not the game).

Per `ralph/NEXT_COORDINATOR_FULL_STATE_AUDIT.md` this lane may fix the RIG and
may not touch the GAME. Every GAME entry below is therefore written down and
left alone, with the fix proposed rather than made.

---

## GAME-F1 — two of the first day's twenty harvest nodes now stand outside the village fence

**Severity:** SHIP, minor-but-real. **Found from config, before the run
reached it.** **Not fixed** — `data/config/` is frozen for this lane.

`data/config/bands/band1_lower_meadows/harvest.json` places twenty gathering
nodes in the village area — the first day's tutorial gathering, and the exact
list `tools/gate_f/segments/S03.json` walks in steps S03-65 … S03-103.
Tested point-by-point against the outline in
`data/config/village_boundary.json`:

| node | inside the fence? |
|---|---|
| eighteen of them | yes |
| **(44, −24)** | **no** |
| **(52, −30)** | **no** |

The boundary was authored on 2026-08-30 (`OP-0830-1`, then rerouted the same
day by the straddle fix). Its own test, `tests/test_village_boundary.gd`,
carries a hand-written `MUST_BE_INSIDE` list — the farmhouse, the well, four
named villagers, the tournament board, the practice bramblebun, the farm
plots — and the harvest nodes are not on it. Nothing else checks them either.
The comment above that list says why the list is hand-written: *"a loader would
silently start including whatever moved into range later."* The cost of that
choice is this: the line moved, and two nodes it was never asked about fell
outside.

**What it costs a player.** The gate is open by the time S03's gathering ladder
runs, so neither node is strictly unreachable — but the chapter's first
gathering lesson sends the player through their own village gate and back for
two of its twenty stops, and the fence is a hard `StaticBody3D`, so the
straight walk between them does not exist. A player who has not yet found the
key cannot reach either node at all.

**Suggested fix (game-side, not made here).** Either move the two nodes inside
the line — they are on the fence's own doorstep, (44,−24) is 4.6 m outside and
(52,−30) 3.9 m — or add the twenty nodes to `MUST_BE_INSIDE` and accept that
the outline must contain them. The second is the one that stops it recurring.

**Expected rig consequence, recorded before it happened:** the leg S03-81 →
S03-83 crosses the fence at (48.5, −31.5), **15.2 m from the RoadGate**, so the
harness's straight-line walk has a fence between it and its target. Whether
`stick_navigator.gd`'s wall-slide finds its way round is the run's to answer.
