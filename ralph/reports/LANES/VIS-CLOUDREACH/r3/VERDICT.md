# VIS-CLOUDREACH round 3: P2-068 NPC post readability arm vs main, CPU

- **Arm:** `data/config/cloudreach_npc_runtime.json:post_readability` via `--cloudreach-npc-posts-candidate` (ground cover cleared on a 3.2 m disc at every named-NPC post; soft warm fill light on each NPC).
- **Capture:** `phase2_capture_dialogue.gd --biome=cloudreach --seed=2042`, one boot per arm with `--job` for Tavi, Sora and Maela; CPU llvmpipe Compatibility 1280x720, same tree.
- **Judging:** standard prompt verbatim, `anchor_tiles.py --pairs 3 --include craft --seed 110403`, three fresh code-blind judges in parallel, `calibrate.py` linear (r 0.81, slope 1.15, anchor RMSE 0.49, confirming batch).

| Item | Board | CPU base | CPU arm | Delta |
|---|---|---|---|---|
| P2-068 named NPC post readability | F40#9 | 5.16 | 5.20 | +0.04 |

**Verdict: flat (two judges scored the sides identically, one +0.1); stays OFF.** The clearing shows only as a small worn patch around Tavi; the fill light does not read.

**What all three judges asked for:** each named NPC unoccluded by the trainer, nearer and larger in frame, with a role prop and an idle pose that says who they are; posts dressed in Cloudreach stratified stone rather than a grass carpet. Next idea (new approach, not a retune): role-prop posts kitbashed from installed families (stone plinth/flag/perch per role) and NPC placement offset so the production approach does not stand the trainer between camera and NPC.
