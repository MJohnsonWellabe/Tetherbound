STATUS: land
BRANCH: tb/item-f38-5  HEAD: see the commit that adds this section (pushed head)

## LANE-MESHY CI fixes, 8 Nov 2026 (coordinator-approved root causes)

origin/main 3bf4ec80 merged in. The judged scale flags are unchanged; two CI failures are fixed.

**A) `tests/smoke_catching.gd` "the creature moved 4.6-4.8 m on the stick while aiming" (gameplay fix).**
- Cause (instrumented, not a guess): not the stick and not a collision shove. The P2-113 companion-aside hop (`combat_manager.gd _step_companion_aside`, `begin_combat_burst`) moves the abandoned companion to a spot fixed when the aim opens. With Bramblebun x1.3 the companion holds a wider contact spacing from the foe, so it starts 1.6 m behind its trainer; the hop pushed into the trainer's capsule and stalled (velocity 0, continuous `Player` contact) until the trainer moved, then completed (two bursts, ~12.7 m/s), so the companion sat beside the lens (the P2-113 defect) and then jumped.
- Fix: during the hop the companion ignores **its own trainer's** collision only (`add_collision_exception_with(_player)`). Co-op: other players' trainers keep their collision (code comment says why). `_maintain_companion_aside_exception()` runs first in every `_physics_process` and drops the exception when the burst ends, the aim closes, the fight leaves ACTIVE (won/lost/fled/caught), the companion changes or is recalled/despawned, or the trainer changes; `_exit_tree()` drops it on scene change (`stormwood_authoritative_fight.gd _exit_tree` now calls `super`).
- New focused test `tests/test_companion_aside_exception.gd`: held during the hop; gone after the burst ends, after an aim cancel mid-hop, when the fight leaves ACTIVE, when the companion changes, on `_exit_tree`; another trainer is never excepted. 5 tests, 22 assertions, 0 failed.
- smoke_catching assertion unchanged; it passes ("catching: OK").

**B) `tools/aim_cancel_windup_probe.gd` "legacy stale commit" (probe setup).**
- Cause: eligibility is `reticle_offset <= body_radius * fraction` (`throw_aim.gd reticle_body_geometry`). The x1.3 foe's allowance (2.155 m) covered the 10 m shift's 2.04 m offset, so the commit stayed eligible.
- Fix: the disclosed initial shift is 14 m (comment in the probe). Assertions unchanged.
- `bash tools/ci/verify-earned-aim.sh`, F38#5 ON (x1.3): windup `PHASE_PROOF checks=19 failures=[]`, hud 8/8, eight-tick 5/5, natural-guard 8/8, no ERROR lines. Stale commits ineligible: reticle 2.69-2.86 vs allowance 2.155.
- Same script with F38#5 OFF (main's `creature_scale_flags.json`, restored afterwards): all four cases pass (19, 8, 5, 8); stale commits ineligible at 2.72-2.86 vs allowance 1.657. The steering-budget (acquisition) checks pass in both.

**Pre-ready check (merged tree):**
- Unit: every `tests/test_*.gd` that greps `combat_manager`, `_step_companion_aside`, `begin_combat_burst`, `stormwood_authoritative_fight`, `aim_cancel_windup_probe`, `creature_scale_flags` or `companion_aside` (64 files) plus the new test: **551 tests, 8531 assertions, 0 failed**.
- Smokes that grep `combat_manager.gd` / `_step_companion_aside` / `begin_combat_burst` / `companion_aside`, plus smoke_catching: **pass** smoke_catching, smoke_arena_contain, smoke_audio, smoke_boss, smoke_catch_aim_slowdown, smoke_charger_lunge, smoke_cloudreach_encounters, smoke_combat, smoke_combat_burst, smoke_combat_trainer_staging_clearance, smoke_local_requests, smoke_named_fight_hit_avoid, smoke_playground, smoke_stormwood_finalized_death, smoke_throw_preview_occlusion, smoke_tournament_bracket, smoke_trainer_battle, smoke_trainer_battle_camera, smoke_water_alpha_retirement.
- **Not caused by this branch** (each re-run with fix A reverted AND with main's scale flags; same result):
  - smoke_controller_catching ("parsed controller attacks did not naturally weaken the target"), smoke_f23_live_moves (three mounted-HUD Ultimate meter checks), smoke_stronghold_battle_camera (shoulder composition / exploration camera restore): fail on main's flags with the fix reverted too.
  - smoke_combat_camera (render-corner crop at the 3 m/9 m framing fixture): intermittent on main. It failed 3/3 with the fix, but also 1/3 with the fix reverted (x1.3) and 1/3 with main's flags; the framing distance varies per run (13.7-20.7 m).
- Co-op net smokes (`tools/net/run_net_smoke.sh`): catch_race, shared_boss, shared_wild_fight, owner_passive_rejoin: all pass (`ALL CHECKS PASSED`).
- No JSON or creature_model_flags change in this fix.

**Files touched in this fix:** `scripts/combat/combat_manager.gd`, `scripts/combat/stormwood_authoritative_fight.gd`, `tools/aim_cancel_windup_probe.gd`, `tests/test_companion_aside_exception.gd`, this READY.

## Earlier READY (LANE-MS / coordinator, 7 Nov)
APPROVED: owner OK 7 Nov (via coordinator) for the 1914 radius cap 3.0 -> 4.0, 1914 only, farthest member <= 10 m from the road.

## Coordinator fix, 7 Nov (smoke_net_f48_cut_key spacing WARNING)

- `origin/main` merged in (no history rewrite).
- **Cause:** with bramblebun at x1.3 (body radius about 1.27 m, plus the 1.25 m gap), three members need about 3.5 m between them. They did not resolve inside cluster 1914's 3 m disc (`encounter_director.gd` resolve_cluster_spot).
- **Audit:** a real Meadows boot (`godot --headless --script res://tests/probe_warrens_float.gd`, grep `cannot fit`) found 1914 as the only spacing warning across all bands. I listed every cluster holding bramblebun, duskhush, pipwing or brooktail (about 110 across band1–5), and the boot is what checks them: only 1914 fails.
- **Search at 3 m:** the 3 m disc still warned at five centres (the original, the 2 m outward move, and +/-3 m along the spine).
- **Fix** (`data/config/bands/band1_lower_meadows/spawns.json` order 1914, `_why_f38_5_spacing`):
  - Centre moved 2.0 m straight away from the band1 spine (3.67 -> 5.67 m).
  - Radius 3 -> 4 m.
  - Nearest possible member is now 1.67 m from the spine centreline (was 0.67 m); farthest is 9.67 m.
  - Nothing shrinks.
- **Test change, flagged for the coordinator:** `tests/test_meadows_south_trail_pulls_0912.gd` capped this sightline group at radius <= 3.0. 1914 now has a cap of 4.0 plus a new, stricter bound: centre distance plus radius <= 10 m from the spine. 1913 (trailpup) keeps the 3.0 cap. This loosens one threshold under your order; drop that one commit if you want a different approach.
- **Proof:**
  - Boot: 0 `cannot fit` warnings. The only WARNING left is the engine's `instance_reset_physics_interpolation() is deprecated`.
  - `GODOT_BIN=/usr/local/bin/godot tools/net/run_net_smoke.sh f48_cut_key --out=<absolute dir>`: rc 0, no FAILURES.
  - Gotcha: a relative `--out` adds an `XDG_DATA_HOME is a relative path` WARNING and fails the check, so use an absolute path.
  - Ran test_meadows_south_trail_pulls_0912, test_capture_meadows_0912_wayfinding_and_pulls, test_trail_camp_arrival_identity, test_creature_grass_and_height_candidates and test_remake_owner1101_finish: 26 tests, 626 assertions, 0 failed.

Lane LANE-MS (Meadows). Row F38#5 (P2-017 normal creature scale, grow only). Board 6.19 (GPU 5.16 in item-scores).

All scores are CPU (llvmpipe, Compatibility), from quick_judge with three code-blind judges, anchors pinned, mapped with calibrate.py. Verdicts are in `ralph/reports/LANES/LANE-MS/qj/`.

| Round | Arm | Base -> cand (mapped) | Judges |
|---|---|---|---|
| r1 `F38-5-40dd78cf633f-11071816` | `creatures_f36_taller_than_trainer_4` (bramblebun x1.3, duskhush x1.15) | **6.59 -> 7.37 (+0.78)** | 3/3 prefer; defect PRESENT -> FIXED/PARTIAL |
| r2 `F38-5-6a59b14720f3-11071825` | new `creatures_f36_taller_than_trainer_5` (pipwing x1.15, brooktail x1.15), over r1 ON | **7.14 -> 7.40 (+0.26)** | 3/3 prefer |

The r2 base maps higher than r1's candidate because each batch maps differently. Best: CPU 7.40.

- **Flags turned ON:**
  - `data/config/creature_scale_flags.json:flags.creatures_f36_taller_than_trainer_4.enabled` (r1, 6.59 -> 7.37, `_why_on`).
  - `data/config/creature_scale_flags.json:flags.creatures_f36_taller_than_trainer_5.enabled` (r2, 7.14 -> 7.40, `_why_on`; new grow-only batch).
- **Rules checked:**
  - Every factor is ≥ 1.0 (grow only).
  - None of these four species has an evolution line, so the evolution-order check is not affected.
  - No creature is shrunk.
- **Tests flipped:** in `tests/test_creature_grass_and_height_candidates.gd`, `test_height_batch_4_ships_off_and_only_grows` became `..._ships_on_...`, and I added `test_height_batch_5_ships_on_and_only_grows`.
  - Ran test_creature_grass_and_height_candidates and test_remake_owner1101_finish: **9 tests, 369 assertions, 0 failed**.
- **Files touched:** `data/config/creature_scale_flags.json`, that test, and the qj verdicts.
- **Flags left OFF in this file (not mine to judge here):** `remake_owner1101_body_line` and `remake_owner1101_judged_short`. The second would grow Terrapup past the owner's 3.20 m decision.
- **Judges' remaining asks:**
  - The creatures are pale and low-contrast against the bright trees, and need rim light. That lives in creature coat or material files, which are not this lane's files.
  - A big foreground bush sits in the scale camera. The camera is a fixed stand; no reframing.
  - The quadruped otter and the hare body still read near trainer head height (ears and back line).
- **Next idea:** rim and value separation on the Meadows creatures (creature_coat_flags owner). The row is at 7.40 CPU and needs only +0.10 for the bar. Ask: put this row in the 8 Nov GPU re-judge.
- **Smoke note:** brooktail is a starter, and it is 1.15x taller now. On landing, the coordinator may want one `tests/smoke_arena_contain.gd` run. I did not run it here (RD-36); no test references these flags.

## Hold (coordinator, 7 Nov)

- STATUS is blocked until the owner decides on the test-cap change above. The branch carries the 4 m radius, the moved centre and the test change as they are.
- **No fix with radius <= 3.0 found.** Bramblebun is x1.3, three members need about 3.5 m between centres (body radius about 1.27 m plus the 1.25 m gap), and the seeded resolver did not resolve them at five centres: the original, 2 m out from the spine, and +/-3 m along it. A 3 m disc is geometrically feasible only if all three sit almost exactly on its rim, which the sampler does not find. With no shrinking, the same species and count >= 3, the only fixes are a bigger disc or a resolver change (`encounter_director.gd`, not this lane's file).
- `origin/main` is merged in (merge, not rebase), per the standing rule.
