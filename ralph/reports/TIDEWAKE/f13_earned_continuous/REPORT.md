# F13#0: Tidewake continuous from the earned S3 save

**Verdict: NOT MET.** No earned S3 → Tidewake save exists, so no run could start from one.

- Base: main 1aa84d1e3, branch `ralph/tidewake-f13-earned-continuous`, 2026-09-26.
- Both runs were headless, each with its own XDG_DATA_HOME. There were no renders.

## 1. The earned S3 save does not exist

### Saved states found
- `tools/net/proof_saves/` holds only `host_meadows_stormwood_route_open`. That is a Meadows save with the Stormwood route open and an empty party: it comes *before* Stormwood, not before Tidewake.
- `tests/fixtures/` has no realm save, and there is no `four_biome_fresh*` scratch save anywhere.

### Chains that could produce one
- **`tools/earned_saves/earned_chain_runner.gd`** writes earned saves from a fresh game only as far as Cloudreach arrival. It is blocked at Meadows Hall: `tools/earned_saves/BLOCKERS.md` lists B5, blocking after the 3-attempt cap.
- **`tests/smoke_four_biome_continuous.gd`** is the only fresh-save path into Tidewake, and it runs as a single process.
  - It keeps S3 in memory only: `reached = "water_arrived"` at line 219, with no `--through` stop there.
  - The Waterward helper's source guard forbids `save_world(` (`tests/test_stormwood_earned_waterward_handoff.gd:62-64`).
  - No genuine run has reached Stormwood (`ralph/reports/FOUR-BIOME-BUILD/STORMWOOD-NEXT-PLAYER-PATH.md`).
- **Chapter-entry substitute:** `tests/smoke_stormwood_continuous.gd -- --through-aftermath --witness-dir=…` saves after Waterward (`_write_witness_save`, line 247).
  - It starts from its own in-memory fixture at lines 136-156: nine Cloudreach flags, a level-44 party of five, and knife/axe/pickaxe.
  - Its best runs (`ralph/reports/STORMWOOD-PROGRESS/LANE-F09-F11.md`, runs 15-18) take about 1,050-1,250 s for the prefix, then about 970-1,070 s more before failing at Crown gathering.
  - Rootgate, Dynamo, Marrow and the aftermath have never run.
  - It cannot be generated here in about 20 minutes, so it was not started.

## 2. What ran instead: the existing Tidewake harnesses, fixture-seated

### Run A: opening harness, through Iona's recipe
- Command: `godot --headless --path . --script tests/smoke_water_opening_continuous.gd -- --through-tidal-recipe`
- **Result: exit 1 after 1037 s**, with 0 SCRIPT ERROR.
- Passed:
  - arrival, Pell, and the physical swim lesson (64.49 m);
  - the Reedhaven crossing, four harvests and the paid repair;
  - the Brine Steps crossing (107.09 m) and Tovin's trial (two opponents);
  - the Shellwatch crossing (93.32 m), a camp rest, Solm (two opponents), residents freed, and a second camp rest.
- **FAIL:** "water_trainer_irva combat ended without durable victory defeated_water_trainer_irva". This route passed on 2026-09-08. Regression or variance is not yet diagnosed.

### Run B: late harness
- Command: `godot --headless --path . --script tests/smoke_water_continuous.gd`
- **Result: exit 1 after 876 s**; 20 checks, 1 failure, 0 SCRIPT ERROR.
- Passed:
  - DEPARTED at +59.1 s, then the mounted crossing to Salt Crown at +122.4 s;
  - the Salt Crown spine and chart at +293.9 s;
  - remount and landing on Sluice at +355.9 s;
  - Bex (two opponents) and the west control at +496.4 s;
  - a bed rest, then Sluice waypoints 2-5 at +671.7 s.
- **FAIL:** "water_trainer_calder combat exceeded 180 seconds after 3 opponents". This is the harness's time limit, not a crash. Calder was beaten at +687 s on 2026-09-08.

## 3. Segment table

| Class | Count | Rows |
|---|---|---|
| EARNED (from the S3 save) | 0 | none |
| EARNED† (real input after a disclosed fixture seat; not F13 evidence) | 13 | See the list below. |
| FIXTURE-SEATED | 4 | See the list below. |
| NOT COVERED | 24 | See the list below. |

**EARNED† rows:**
- the swim lesson;
- the crossings to Reedhaven, Brine Steps, Shellwatch and Salt Crown;
- the Reedhaven dock repair;
- the Brine Steps trial;
- Shellwatch residents freed;
- the Salt Crown chart;
- the Sluice landing;
- Bex;
- the west control;
- the Salt Crown spine walk (part of the circuit, not the full loop).

**FIXTURE-SEATED rows:**
- **S3 arrival state:** `smoke_water_opening_continuous.gd:50-55` resets and sets the realm to water. Line 79 instantiates the world directly instead of using the Waterward gate.
- **Carried tools:** the knife and axe at `smoke_water_opening_continuous.gd:60-65`.
- **Carried party:** a synthetic level-44 party of five at `smoke_water_opening_continuous.gd:70-76`.
- **Tidal Cradle late seat:**
  - `smoke_water_continuous.gd:69-72` sets `water_aquaryn_resolved`, `water_swim_stone_earned` and `water_swim_saddle_recipe_learned`, and grants a swim_saddle.
  - Lines 73-75 give a level-60 Aquaryn.
  - Line 96 places the player at the departure anchor, and line 103 mounts.

**NOT COVERED rows:**
- **Shellwatch finish:** Irva, the pump and the dock.
- **Tidal Cradle:** the crossing, the Aquaryn, the Swim Stone, Iona's recipe, and the swimmer capture with saddle.
- **Late route:** Calder, the east control, the Sluice→Veilfall crossing, Venn, the Veilfall controls, Nerissa, and the Guardian and ending.
- **Side islands:** Lantern Cove, Gull Rest, Drowned Garden and Deep Watch.
- **The four land loops:** no `*_circuit` polyline is walked.
- **The three shortcuts:** only Reedhaven's unlock is earned, and none is travelled.
- **The eight pockets:** none is claimed on a continuous route.
- **The six local chains:** none runs on a continuous route.

**Coverage outside the continuous route:**
- **Pockets:** reached only by per-island teleports (`tests/smoke_water_pocket_walk_claim.gd:219`).
- **Local chains:** covered only by their own teleporting, flag-seeded smokes:
  - `smoke_water_lantern_return.gd:44,99`
  - `smoke_water_gull_research.gd:45,101-102`
  - `smoke_water_cradle_care.gd:49,144,163`
  - `smoke_water_garden_records.gd:49,109,175-176`
  - `smoke_water_lastlight_shelter.gd:48,142,167-168`
  - `smoke_water_deep_watch_chart.gd:46,98-100`
- **Wired but never reached:** the four-biome composition calls SWIMMER, LATE_WATER and WATER_ENDING (`smoke_four_biome_continuous.gd:219-259`), but it has never run that far.

## 4. Next steps, in priority order
1. **Add a save boundary at `water_arrived`.** Either:
   - a `--through-water-arrival` stop in `smoke_four_biome_continuous.gd` that calls the production `Game.save_game()` into a named directory; or
   - a `waterward` segment in `earned_chain_runner.gd` that loads the Stormwood `--witness-dir` save.
2. **Unblock Stormwood `--through-aftermath`** (Stormwood lane): Crown gathering, then Rootgate, Dynamo and Marrow.
3. **Add `--from-save=<dir>` to `smoke_water_opening_continuous.gd`.** It loads through the production Load path and drops the knife/axe and level-44 fixtures. This is Water-lane work.
4. **Diagnose the Irva loss and the Calder 180 s timeout.** Both passed on 2026-09-08. Log the ally's HP and state per fight.
5. **Compose the whole route in one run from the loaded save:** opening → Tidal → SWIMMER → LATE_WATER → ending. This retires `smoke_water_continuous.gd:69-103`.
6. **Extend the route:** walk the four circuits, travel the three shortcuts, and visit the four side islands, with their local chains and pockets played on the route and no teleports.
