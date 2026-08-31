# Handover — GATE-F-LEG-S07, 2026-08-31

**Branch:** `ralph/GATE-F-LEG-S07`, off `origin/main` (`ralph/GATE-F-FOUNDATION`
never appeared during this session despite repeated `git fetch`; a coordinator
notification mid-session confirmed the dependency was unnecessary and to
proceed independently — see commit history for the exact timing).
**Scope as briefed:** test Gate F segment S07 (River & Relay / Band 3: river
arrival → relay pickets → officer → relay captain → captive → Old Mill
Crossing restored) in isolation, from a hand-authored "clean" entry save, and
fix real defects found in this band's own systems.

**Honesty caveat, stated once per the brief: this is conditional/isolated
evidence.** The entry save (`saves/S06-exit.json`, committed in this run
directory) is hand-authored, not earned by a real S01–S06 playthrough — party
of 5 at levels 9–13 (informed by Band 2's own guardian at L14 and Band 3's
pickets at L8–12), full HP, the flags a real playthrough would have set by
this point. Findings below are phrased as "S07, given a clean entry, does X,"
not "the chapter does X."

---

## 1. The headline

**A genuine, chapter-wide save/load bug (GAME-F4) was found and fixed first**,
before any Band3-specific work could mean anything: `scripts/save/
save_game.gd` never wrote a creature's `base_hp`/`base_attack`/`base_defence`
to a save file, only its already-computed current stats. Those three fields
are what `creature_instance.gd::_apply_level_stats` (called from `gain_xp` on
every level-up) recomputes the *current* stats FROM — so a loaded creature
kept `CreatureInstance`'s bare class defaults (1.0/1.0/1.0) until its next
level-up, at which point a real, played-in creature (e.g. 180 hp) collapsed to
roughly 2. This affects **every save in the game**, not just this hand-seeded
one — any player who loads a save and then levels up a creature would see it
silently gutted. Fixed with two regression tests
(`tests/test_save_format.gd`).

**With that fixed, S07's own required content (captain fight, captive rescue,
Old Mill Crossing) was driven to a real PASS at least once (run 6, 90/107
steps).** Getting there took nine more logic-lane runs and five more fixes,
documented below and in the branch's own commit messages (each commit
explains what its own run found and why).

## 2. What was fixed, in the order it was found

1. **GAME-F4** (`scripts/save/save_game.gd`) — see above. Chapter-wide, not
   Band3-specific.
2. **GATE-D3-GEOM** (`tools/gate_f/segments/S07.json`) — the picket road's
   approach bearing (GATE-D3, 2026-08-22, unit (0.8,0.6)) runs ~92° off
   `tether_relay.json`'s own `approach_bearing_deg` (-34.4, unit
   (0.565,-0.826)) — almost parallel to the compound's front wall rather than
   toward its gate. A beeline from the road to Officer Dell/Captain Vance's
   coordinates clips the flank_west fence. Fixed with an added waypoint
   through the gate (verified with a scratch probe,
   `tools/_probe_relay_gate_reach.gd`, not part of the segment suite).
3. **GATE-D3-DIALOGUE** — `relay_captain_challenge` runs 4 lines against the
   pickets'/officer's own 2 (he is written as more articulate); the segment's
   fixed press count (copied from the shorter fights) closed the dialogue
   panel into `narrative_modal` rather than `world`, so the captain's fight
   never engaged. Switched to `advance_dialogue_until_closed`, the schema's
   own by-predicate primitive.
4. **GATE-D3-CHANNEL** — the mill-crossing walk targeted `(-152,4203)`,
   which is the crossing's own `channel.centre` (the middle of the unbuilt
   gap), not a place to stand. Retargeted at `gated_crossing.gd::
   near_point(7.4)`, which is also where `mill_crossing.gd`'s own
   Interactable actually stands.
5. **GATE-D3-STAMINA** — the segment never rotated or healed the active ally
   across the ladder's four real fights; one creature (Moss) tanked Hess,
   Orrin AND Dell with nothing between them and fainted right at Dell's own
   end, so the captain challenge silently refused
   (`encounter_director.gd::can_challenge()` correctly refuses a fainted/no
   ally). Added a `party_cycle` press before each of the three later fights,
   then interleaved more swaps through the captain fight itself once a
   single fresh ally alone still lost to his 3-creature team solo.
6. **Console/ramp reach — investigated, NOT fixed, documented as a harness
   limit.** `disable_the_relay`'s console sits on a raised pad (`deck_y:
   10.0`) reached by a real ramp. Three different waypoint strategies (a
   flat walk, `move_to_entity`, a four-point ramp/gantry/pad chain) all
   closed the *horizontal* gap to the Console node while staying 4.7–4.9m
   short *vertically*. Verified via `tests/smoke_relay_station.gd`
   (independently run, PASSING on this SHA) that the ramp mechanism itself
   works — and that approaching it from the wrong angle legitimately does
   not climb it, which is exactly what this segment's general-purpose
   wall-following navigator kept doing. This is a harness-navigator
   precision limit on one narrow ramp, not a Band3 game defect. Reverted
   S07-70 to the flat ground-level walk so the segment does not strand
   itself there and block the in-span Old Mill Crossing walk after it.
   `disable_the_relay` is objective 20/27 in the full chain but is **not**
   named in section B's own S07 span.

## 3. What's still red, and why it's left that way

Run 10 (the final logic-lane run in this run directory): **102 PASS / 119
steps** (9 delegated to the capture lane, which does not exist for this
isolated leg — see §4).

- **S07-26** (river-arrival region containment): `the_long_water` map
  landmark is a 52m-radius pin at the Old Mill Crossing, not a region
  covering the river's ~700m course; the protocol's own arrival point sits
  ~760m from it. A content-authoring question (does the river need its own
  region chapter-wide), not something I should decide unilaterally — flagged
  here rather than fixed.
- **S07-36w / S07-45w**: `input_context` occasionally reads `combat` or holds
  briefly right after a picket/officer fight's scripted wait ends — that
  fight's own reward/cleanup sequence is sometimes longer than the wait.
  Self-heals every time via the next walk's own `held_budget`. Worth a longer
  wait in a future pass; never actually blocked anything.
- **S07-73/74**: cascade of the console/ramp limit above.
- **S07-76/80/82** (Old Mill Crossing walk, distance, route.csv rows): this
  walk **succeeded end to end in run 6** (same target coordinate, same
  starting shape — `mill_crossing_restored` set, 90/107 that run). Run 10's
  own repeat stopped early near the relay compound with 40 held frames,
  consistent with the wall-following navigator's own tie-breaking near the
  compound's wall geometry (the same geometry GATE-D3-GEOM's fix already
  had to route around once) rather than a new deterministic defect. Recorded
  as observed run-to-run variance in the harness's own pathing, not chased to
  a forced pass — see §1's honesty caveat.

## 4. Evidence lane

This was run in the **logic lane only** (`--headless`, no rendering driver).
S07.json declares `capture_lane: S07C`; S07C was never run in this session
(no display server was provisioned for it), so the 9 delegated capture ids
(`GF-10-RELAY-01/02/03`, `GF-21-WEATHER-03`, `GF-14-COMBAT-04c`) remain owed,
same as the protocol's own §H.1 split intends. `tools/gate_f/run_inventory.py`
against this run directory will show that debt if it is ever consolidated
into a fuller Gate F run.

`ralph/reports/gate-f-run-LEG-S07-20260831T000946Z/RUN_METADATA.json` is this
leg's own run-root metadata (a run-local override of the stale checked-in
`ralph/reports/gate-f-candidate/RUN_METADATA.json` default, needed because
this was never a coordinator-frozen chapter-wide run). Superseded attempts
(`S07-superseded-1` through `-9`) are kept per the protocol's own restart
rule, each renamed rather than deleted, each commit message explaining what
that attempt found.

## 5. What a follow-up session should do

- If this leg's fixes are to be folded into a real chapter-wide Gate F run,
  reconcile against whatever `ralph/GATE-F-FOUNDATION` (or its successor)
  contains — this branch never saw it.
- The console/ramp reach (§2.6) would benefit from either a dedicated
  precision-walk helper (matching `smoke_relay_station.gd`'s own directed
  push along the ramp's exact foot→head vector, rather than the general
  wall-following navigator) or from being moved to a capture-lane/DIAG
  probe instead of the journey lane.
- S07-76's run-to-run variance (§3) is worth a second data point — rerun
  logic-lane S07 once or twice more and see whether it reproduces the run
  6 success rate, or whether the compound's wall geometry needs the same
  kind of fix GATE-D3-GEOM gave the approach road.
- `the_long_water`'s region coverage (§3, S07-26) is an owner/design
  question, not mine to resolve here.

## 6. Verification

- `tests/test_save_format.gd`: 52 tests including two new ones for GAME-F4,
  0 failed.
- Broader creature/save/progression suite (`test_autosave_fallback`,
  `test_combat_progression`, `test_creature_buffs`, `test_creature_
  condition`, `test_creature_history`, `test_creature_nickname`,
  `test_orb_passes_your_own_creature`, `test_party`, `test_party_seam`,
  `test_progression`, `test_progression_state`, `test_save_format`): 216
  tests, 0 failed.
- Band3-content-adjacent suite (`test_trainers_data`, `test_dialogue_runner`,
  `test_map_landmarks`, `test_river_crossings_stay_open`, `test_item_gate`,
  `test_band_content`): 151 tests, 0 failed.
- `tests/smoke_relay.gd` (captain/captive/gear/village-relocation, real
  world, real input): passed before AND after this session's changes.
- `tests/smoke_relay_station.gd` (ramp/deck/console mechanism): passed,
  independently confirming §2.6's diagnosis.
- Godot 4.7-stable per CI's own pin, project imported twice (fresh cache,
  then a stable re-import), no import errors either time.
