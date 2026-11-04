# VIS-MEADOWS r1a: Meadows dialogue, routes and location items (CPU, 4 Nov 2026)

Yardstick: CPU llvmpipe Compatibility 1280x720, base = tb/vis-meadows-1104 at 98879e2e (main), candidate = the same tree with r1's 25 existing OFF arms on (overlay, reverted after). Same run and stands for both sides. tools/visual_judge: JUDGE_PROMPT verbatim, anchor_tiles `--pairs 3 --seed 11041 --include craft` (6 anchor tiles), three fresh code-blind judges in parallel, calibrate.py: linear slope 1.40, r 0.93, anchor RMSE 0.30, confirming batch (top anchor 7.35).

| Item | Subject | CPU base | CPU cand | Verdict |
|---|---|---|---|---|
| F38#20 P2-003 | Team Tether stronghold | 5.67 | **6.38** | gain +0.71: ship the stronghold arms ON |
| F38#22 P2-006 | mill and settlements | 5.67 | **6.38** | gain +0.71: ship the mill/village/camp arms ON |
| F38#17 P2-087 | named trainer dialogue | 6.66 | 6.66 | flat; already above 6 as shipped (speaker FIXED 3/3); arms stay OFF |
| F38#37 P2-079 | dialogue rock obstruction | 6.52 | 6.52 | flat; already above 6 as shipped (PARTIAL 3/3, foreman overhang); arms stay OFF |
| F38#35 P2-050 | human post poses | 6.09 | 6.09 | flat; above 6 as shipped; stances stay OFF |
| F38#23 P2-013 | Tether Relay yard | 6.38 | 6.47 | +0.09 (noise); above 6 as shipped; arms stay OFF |
| F38#30 P2-012 | Burrow Warrens hillside | 4.23 | 4.23 | flat; hill_shell r2 / cliffs_wd do nothing here (cliff_b is not built on main) |

Arms behind each gain (judged together; the item's frames are only reached by its own arms):
- F38#20: `stronghold.json` `p2_003_candidate` (keep 170 m, darker stone, hotter windows, courtyard bricks), `approach_pylons.p2_003_unlit_candidate_enabled`, `bands/band5_stronghold_approach/props.json` clusters[5] `candidate` (courtyard dressing: braziers, barrels, crates). The judges credit the courtyard fires and dressing ("B's campfires add life up close"); the approach still reads the keep as small and pale (next ask).
- F38#22: `meadows_hero_pieces.json` `clearings_wd`, `meadows_doorstep_seat.json` `doorstep_seat_enabled`, `bands/band1_lower_meadows/props.json` clusters[23] `candidate`. The gain is the trail-camp frame: the base camera stands between two huge trunks (all three judges), and the candidate clears them.

Judges' remaining asks (top_changes, all three agree):
1. Camera and geometry: the Burrow walk_02/walk_03 stands put the player inside the earth-bank shell (terrain underside and floating slabs overhead, 3/3). That is the stand defect `capture_stands.json buried_stand_guard` was written for: the shell has collision, so a walking player cannot be there. It goes into r2. Also the foreman's rock overhang (F38#37).
2. Value: the stronghold courtyard floor is still a dark void, the relay's right-hand timber mass reads black, and the night grade is flat blue.
3. The village has no visible people; the mill water is a sliver behind trees.

Stand note: the F38#35 villager frames aim at the catalogue's authored positions (Oskar (25, 4)). The game now places Oskar 41.8 m away, so the villagers are tiny or absent and the pose arm cannot show. This is a stand-data issue, recorded here and not fixed by reframing.
