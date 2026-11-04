# VIS-MEADOWS (4 Nov 2026): running status

Lane: tb/vis-meadows-1104 (from origin/main 98879e2e1). Scope: the Meadows F38 items in the coordinator brief (briefs-1104/vis_meadows.md), excluding the arms creatures-ralph has in flight (F38#24 ridge, F38#19 HUD, creature rim for F38#1/#2/#26).

Yardstick: CPU llvmpipe Low/Compatibility 1280x720, base and candidate in the same run on the same stands; tools/visual_judge (JUDGE_PROMPT verbatim, anchor_tiles --pairs 3, three code-blind judges, calibrate.py). Recorded as "CPU <base> -> <cand>". Owner rule 4 Nov: any judged gain ships ON; flat or worse stays OFF.

## Landing-ready

- **F38#20 P2-003 Team Tether stronghold: CPU 5.67 -> 6.38** (r1a). ON: `stronghold.json approach_pylons.p2_003_unlit_candidate_enabled` and band5 `wd_stronghold_courtyard` `candidate`; the score is appended to `p2_003_candidate._why_on` (that flag is already ON from #808).
- **F38#22 P2-006 mill and settlements: CPU 5.67 -> 6.38** (r1a). ON: `meadows_hero_pieces.json clearings_wd`, `meadows_doorstep_seat.json doorstep_seat_enabled`, band1 `wd_village_market` `candidate`.
- Test: `tests/test_vis_meadows_1104_on.gd` (asserts each ON with "CPU 5.67 -> 6.38"). **Tests PASSED (05:03 UTC, on f992ed15):** `run_tests.gd --only=` test_vis_meadows_1104_on, test_stronghold_arena_conduits, test_meadows_tier1_art_gates, test_trail_camp_arrival_identity, test_village_road_topology, test_stronghold_approach_visual_identity, test_tournament_ground_presentation, test_grandpa_yard_visual_identity, test_rise_visual_identity, test_meadows_banner_*, test_texture_import_policy: **77 tests, 5837 assertions, 0 failed**. The coordinator put these in batch 3 (#811).
- Already at 6.0 or above as shipped (no change): F38#17 6.66, F38#37 6.52, F38#35 6.09, F38#23 6.38 (arms flat, OFF).

- **F38#13 P2-059 catch camera: CPU 6.22 -> 7.19; F38#33 P2-061 catch result: CPU 6.02 -> 6.88** (r1b). ON: `catching.json framed_camera.r2`, `camfx.json catch_orb`, `hud.json catch_card`.
- **F38#15 P2-069 flight and landing: CPU 5.99 -> 6.33** (r1b). ON: `fly_traversal.json landing_presentation.wing_fold_enabled`.
- r1b tests: `test_vis_meadows_1104_on` (new catch test), `test_camfx_candidates`, `test_uiposes_fly_hang_body` and `test_capture_readout_side` now assert ON with the score and keep their OFF-path checks. **r1b tests PASSED (05:40 UTC):** `--only=` test_vis_meadows_1104_on, test_camfx_candidates, test_uiposes_fly_hang_body, test_capture_readout_side, test_catch_math, test_fly_traversal, test_hud_widgets, test_tutorial_orb_floor, test_texture_import_policy, test_hud_presentation_lifecycle, test_catch_arbitration. The first run had 139 tests and 1 failure: `test_every_camfx_block_ships_off`, which the change was expected to break. It now takes a JUDGED_ON map (catch_orb must be ON with its score; flame and fight_fade must still be OFF). Re-run of the touched files: 23 tests, 118 assertions, 0 failed.
- r1b flat or already at 6.0 or above as shipped (arms OFF): F38#7 6.99-7.15, F38#6 6.64, F38#32 6.37, F38#29 6.18.

- **Unscored rows now scored (CPU subset, r1c):** F38#0 **6.16** and F38#41 **5.68**, from 14 frames at 2 of 22 sites. A full ≥200-frame matrix needs the GPU rig (CPU takes about 4 min a frame). F38#41's named defect is the old-quarry ruin floor tiles showing through as a dark slab (see r1c VERDICT).

## Parked

- **F38#30 Burrow hillside (CPU 4.23): parked after two approaches; needs an owner-level choice.** (1) `capture_stands buried_stand_guard`: frames unchanged. (2) New `hill_shell.skirt` arm (OFF, `3678f7513`): visibly worse (stretched curtains), not judged. Cause, from `tests/probe_warrens_float.gd`: the Warrens chambers and their hill-shell mound are built for a raised site, but the meadow under the route stands is about 18 m lower. The chambers' collider sits at y 21 over ground at about 3, and the shell (about 263 m across, no collider) hangs over walkable grass, so a walking player can stand under the cave. Real fixes are gameplay changes: raise the terrain under the Warrens footprint (Terrain3D sculpt), or give the shell a trimesh collider and keep spawns and routes out of its footprint. Either one changes traversal, so this lane does not make it alone.

## In flight

- **r1 (started ~01:45 UTC 4 Nov):** base vs all 25 existing OFF arms that earlier judges asked for on these items (stronghold P2-003/087, Burrow hill shell r2 and cliffs_wd P2-012, relay yard P2-013, mill/village/camp P2-006, dialogue_open P2-079, aftermath speaker frame P2-087, post stances P2-050, beaten stance and grunt clip P2-065, catch framed_camera r2, catch orb and catch card P2-059/061, item identity props and potion arms P2-033, camp flame P2-035, wing fold P2-069). Eight capture boots per side: dialogue, routes, location close and approach views, catch, fights, inventory, flight. Items are judged one by one; a flat or worse item gets its arms split in r2.

## Blockers

- Setup: the disk was full (21 GB full-history pack). With the owner's OK the clone is now shallow and blob-less (depth 1, `blob:none`), which leaves 21 GB free.

## Notes for the coordinator (messages from this lane are refused as an untrusted device)

- The shallow .git is done (depth 1, `blob:none`, 21 GB free). Harness fix for any lane that does the same: in a `blob:none` clone, `git commit` lazily fetches every blob and hangs. Commit with `GIT_NO_LAZY_FETCH=1 git write-tree --missing-ok`, then `git commit-tree <tree> -p HEAD -m ...` and `git update-ref HEAD <commit>`. Push works normally.
- Harness fix: this cloud container is reclaimed (all processes killed) whenever the session has no harness-tracked task. That happened twice, at about 01:35 and 02:00 UTC. A `nohup setsid` chain does NOT keep it alive. Run long capture chains as a tracked background Bash (`run_in_background`, timeout ≤ 2 h) and make them resumable (a per-group `.done` marker; re-applying an overlay is idempotent). Relaunch the chain from each check-in.
