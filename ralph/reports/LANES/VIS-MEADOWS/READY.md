# VIS-MEADOWS (4 Nov 2026): running status

Lane: tb/vis-meadows-1104 (from origin/main 98879e2e1). Scope: the Meadows F38 items in the coordinator brief (briefs-1104/vis_meadows.md), excluding the arms creatures-ralph has in flight (F38#24 ridge, F38#19 HUD, creature rim for F38#1/#2/#26).

Yardstick: CPU llvmpipe Low/Compatibility 1280x720, base and candidate in the same run on the same stands; tools/visual_judge (JUDGE_PROMPT verbatim, anchor_tiles --pairs 3, three code-blind judges, calibrate.py). Recorded as "CPU <base> -> <cand>". Owner rule 4 Nov: any judged gain ships ON; flat or worse stays OFF.

## Landing-ready

- **F38#20 P2-003 Team Tether stronghold: CPU 5.67 -> 6.38** (r1a). ON: `stronghold.json approach_pylons.p2_003_unlit_candidate_enabled` and band5 `wd_stronghold_courtyard` `candidate`; the score is appended to `p2_003_candidate._why_on` (that flag is already ON from #808).
- **F38#22 P2-006 mill and settlements: CPU 5.67 -> 6.38** (r1a). ON: `meadows_hero_pieces.json clearings_wd`, `meadows_doorstep_seat.json doorstep_seat_enabled`, band1 `wd_village_market` `candidate`.
- Test: `tests/test_vis_meadows_1104_on.gd` (asserts each ON with "CPU 5.67 -> 6.38"). **Tests PENDING:** the r1 capture chain holds the only Godot slot until about 04:15 UTC. Do not land this commit until this line reads PASSED. The run will cover that test, `test_stronghold_arena_conduits.gd`, `test_meadows_tier1_art_gates.gd`, the props-reading tests (`test_trail_camp_arrival_identity`, `test_village_road_topology`, `test_stronghold_approach_visual_identity`, `test_tournament_ground_presentation`, `test_grandpa_yard_visual_identity`, `test_rise_visual_identity`, `test_meadows_banner_*`) and `test_texture_import_policy.gd`.
- Already at 6.0 or above as shipped (no change): F38#17 6.66, F38#37 6.52, F38#35 6.09, F38#23 6.38 (arms flat, OFF).

## In flight

- **r1 (started ~01:45 UTC 4 Nov):** base vs all 25 existing OFF arms that earlier judges asked for on these items (stronghold P2-003/087, Burrow hill shell r2 and cliffs_wd P2-012, relay yard P2-013, mill/village/camp P2-006, dialogue_open P2-079, aftermath speaker frame P2-087, post stances P2-050, beaten stance and grunt clip P2-065, catch framed_camera r2, catch orb and catch card P2-059/061, item identity props and potion arms P2-033, camp flame P2-035, wing fold P2-069). Eight capture boots per side: dialogue, routes, location close and approach views, catch, fights, inventory, flight. Items are judged one by one; a flat or worse item gets its arms split in r2.

## Blockers

- Setup: the disk was full (21 GB full-history pack). With the owner's OK the clone is now shallow and blob-less (depth 1, `blob:none`), which leaves 21 GB free.

## Notes for the coordinator (messages from this lane are refused as an untrusted device)

- The shallow .git is done (depth 1, `blob:none`, 21 GB free). Harness fix for any lane that does the same: in a `blob:none` clone, `git commit` lazily fetches every blob and hangs. Commit with `GIT_NO_LAZY_FETCH=1 git write-tree --missing-ok`, then `git commit-tree <tree> -p HEAD -m ...` and `git update-ref HEAD <commit>`. Push works normally.
- Harness fix: this cloud container is reclaimed (all processes killed) whenever the session has no harness-tracked task. That happened twice, at about 01:35 and 02:00 UTC. A `nohup setsid` chain does NOT keep it alive. Run long capture chains as a tracked background Bash (`run_in_background`, timeout ≤ 2 h) and make them resumable (a per-group `.done` marker; re-applying an overlay is idempotent). Relaunch the chain from each check-in.
