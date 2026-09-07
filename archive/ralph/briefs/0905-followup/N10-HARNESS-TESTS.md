# N10-HARNESS-TESTS

**Source:** W03-S08-FREEZE-0904, W20-SMALL-FIXES-0904, W21-HARNESS-FIGHTS-0904 reports; cross-
referenced against `docs/GATE2_GATE3_CLOSURE_PLAN.md` rows CL-H1, CL-H4, CL-H8, CL-H14, 2.9,
2.14.

## Why
This wave's harness/test-infrastructure fixes. All three source lanes gave exact reproductions
and, in most cases, the exact fix.

## Owns
`tests/helpers/stick_navigator.gd`, `tools/gate_f/operator_harness.gd`,
`tools/gate_f/segments/S04.json`, `S05.json`, `S06.json`, `tools/gate_f/build_s09_entry_synthetic.gd`,
and `docs/GATE2_GATE3_CLOSURE_PLAN.md` (status rows only, with cited evidence — do not touch
its content beyond the rows named below).

## Do

**1. `stick_navigator.gd`'s foot-height probe misses low geometry (W03).** `_free_space()`'s
lowest probe ray sits 45cm above the feet, missing root flare/low obstacles, so the walker can
commit to a detour into a flank the body physically cannot enter and only escapes by noticing
zero progress rather than seeing the obstacle. Add a foot-height probe ray. **This constant has
a measured regression behind every value in this file** — after the change, run the FULL Gate
B/F smoke suite (not just the harness's own tests) to confirm nothing that depended on the old
probe height silently breaks.

**2. Re-verify the Gate 2 "Pond stall" is actually fixed (W03).** `docs/CURRENT_STATE.md` §3
item 2.9 has an identical freeze signature to the now-fixed S08-22 defect (same coordinate
`(-328.7, -14.2, 505.3)` pinned to the centimetre across three runs). Very likely the same
navigator mechanism, already fixed on `main` by W03's S08-22 fix — but not re-verified. Re-run
that leg (check `docs/GATE2_GATE3_CLOSURE_PLAN.md` row 2.9 / `probe_pond_stranding.gd` for the
exact repro) against current `main` and close the row with cited evidence if it now passes.

**3. `S04.json`/`S05.json` carry the same stale threshold defect S02 already had fixed (W20).**
S04 wants 1,200 rows, S05 wants 3,000 — both derived the same wrong way S02's 900 was (already
fixed there to 450, i.e. 80% of the shortest healthy completion). Re-derive S04 and S05's
`route_rows_at_least` the same way: run each segment's real play clock at 2 Hz and set the
threshold to 80% of the shortest healthy completion, matching the S02 fix's method exactly.

**4. Delete the invented workbench beat, S06-31 through S06-49 (W20/W21 — may already be
done; verify first).** W20 proved by live probe that the workbench interact never enters
`build_catalogue` at all (it opens `craft_panel.gd`, cancels cleanly to `world`) — the "stuck
catalogue" S06 was scripted around is a transcriber's invention, not a game bug. W21's own
report says it executed this exact deletion already — **check `tools/gate_f/segments/S06.json`
on `origin/main` first; if `S06-31`..`S06-49` are already gone, skip this item.** If they're
still present, delete them, while preserving protocol requirement L.3 ("S06 orb_greater +
reinforced tools — each paid at real cost") by giving it a new home in a segment whose band has
an authored crafting site (check with the density lanes' work for where one exists).

**5. `fight_until_resolved` false-passes when no fight ever ran (W21).** In
`operator_harness.gd`, steps `S06-64`/`S06-74` report "0 quick … no fight running" as PASS.
This step should FAIL when no fight was ever observed rather than passing on an absence.

**6. `_predict_frames` mis-prices `chip_to_floor` (W21).** No case exists for this step type;
it's mispriced at 1 frame. Harmless at current budgets but wrong — add the correct case.

**7. `build_s09_entry_synthetic.gd`'s declared inventory isn't landing (W21).** The declared
`{"id": "revive", "count": 2}` block doesn't apply — loaded state reports `revive: 0`, and
every satchel line except `potion_small`/`coin` reads 0. Find why the seed-building loop skips
these entries and fix it.

**8. S06's seed carries too few Revives for its scripted fights (W21).** Once the single
Revive is spent, a later `focus_item` recovery step FAILs on an empty bag. Widen the seed's
recovery budget to cover the segment's actual fight count (check how many fights S06 now
scripts after item 4 above, and size the Revive count to survive them with margin, same
convention as other segments' seeds).

**9. Bare `press interact` engage steps should be `interact_with` (W21) — S06/S07 only, time
permitting.** Every "engage" step in the segment files is a bare `press interact` rather than
the safer `interact_with` (presses only when the arbiter has a live prompt, and names what it
saw). This is what would have caught the S08-27 pipwing failure (item 10) in one line. Convert
S06 and S07's engage steps first (S08/S09 if time remains) — this is optional/best-effort
within this lane's time budget; if you run out of time, convert what you can and note exactly
which segments remain in the old form.

**10. Band 4 grove pipwing encounter never actually starts combat (W03 + W21, same site,
independently reproduced).** `S08-27`'s `interact` press never starts a fight with the grove's
pipwing — telemetry shows zero combat events for 768 of 773 sampled rows (W03), and W21
independently reproduced the identical site (`S08-29 FAIL chip_to_floor: no live enemy to
chip`, `S08-31 input_context=world (wanted combat_aim)`). This is very likely a real encounter-
director bug, not a harness bug (two independent lanes converged on the exact same site by two
different methods). Investigate `scripts/combat/encounter_director.gd`'s pipwing trigger at
this specific location — if the fix is inside that file, make it (this file is in this lane's
ownership for this one investigation); if it needs a change to Band 4 encounter data outside
your ownership, document the exact root cause and route it precisely rather than guessing.

**11. `S06-50`'s navigator gets stuck in a tiny box right after a workbench placement
(W21).** The walk into the Warrens mouth pins the body inside a 2.7m × 2.5m box for its entire
711s budget one step after a workbench was placed at the player's feet — yet the identical
`move_to` call from that same position escapes cleanly moments later. This points at
navigator STATE (something about the just-placed workbench confusing pathing state), not
terrain. Investigate alongside item 1's navigator work, in `stick_navigator.gd`.

**12. `S09-33`'s walk to Warder Ness stops short at an authored terrain carve (W21).** Stops
81.3m short at `(18.0, 4.0, 7363.0)` after burning its full 15,300-frame budget, driving into
`sigil_gate_gorge_west`, an 11m-deep authored terrain carve that blocks the intended path.
Either correct the segment's waypoint to route around the carve, or — if the carve itself is
wrongly placed relative to the intended route — flag that as a routed finding for whoever owns
that terrain carve (do not resize/move authored terrain yourself without checking ownership
first).

**13. Update `docs/GATE2_GATE3_CLOSURE_PLAN.md` status rows with cited evidence, once the
above land:** CL-H14 (W03, already fixed — cite the S08-22 fix), CL-H13 (W02, already fixed —
cite the input-context guard), CL-H8 (this lane, item 4 — cite the probe and the decision), CL-
H4 (this lane, item 3 — cite the re-derived thresholds), CL-H1 (W21 fixed 4 of 6 segment
fights; this lane does not need to touch the remaining 6 unless item 9's audit above surfaces
something — cite W21's own report for exactly which fights converted and which remain
blocked), 2.9 (this lane, item 2), 2.14 (this lane, item 3). Rewrite each row in place with the
real status and a citation (branch/commit/test), matching the existing row format exactly —
do not append new rows or duplicate content.

## Verify
- Every code change gets its own red-then-green test per COMMON.md's discipline.
- After ALL changes, run the harness against S06, S07, S08, S09 end to end and confirm no new
  regression versus each segment's last known-good run (cite the run IDs from the source
  reports).
- CI on the push must show the harness/segment jobs (`verify-gate-b-core`,
  `verify-gate-evidence-shard` or equivalent) green, or explicitly document why a specific red
  is pre-existing on `main` (per COMMON.md's rule — never assume, always diff against `main`).

## Acceptance
Items 1–12 verified with real repro-then-fix evidence. Item 13's doc rows are rewritten in
place with citations, not appended. The Band 4 pipwing bug (item 10) gets a real root cause,
not a guess — if it's not fully closed, the exact next step is named precisely.
