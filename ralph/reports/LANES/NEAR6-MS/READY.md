# NEAR6-MS (4 Nov 2026): running status

## Round 2 (coordinator, 4 Nov 17:09): UI rows taken

All earlier gains are on main. Branch `tb/near6-ms-1104` now equals main a8320228 (#827) via a merge commit that takes main's tree (`4f47609e`). Items taken (no new art; quick_judge; any judged gain ships ON with its score and tests):

| Board row | Item | Board | Note |
|---|---|---|---|
| F38#4 | P2-002 map canvas headings and markers | 5.95 | |
| F38#9 | P2-001 menu shell | 5.93 | v1/ui1a: menu.json arms make no visible change |
| F38#19 | P2-004 exploration HUD | 5.64 | hud_lean ON; judges still see many dark boxed panels |
| F41#21 | P2-111 Hollows victory reward tiles | 4.92 | `hud.victory_focus` OFF, never captured on CPU (Hollows capture timed out before the win) |
| F41#16 | P2-110 Hollows fight-loss result clarity | 5.05 | `hud.loss_card` ON; judged frame shows no loss state |
| F39#23 | P2-114 catch-chance HUD contrast | 5.65 | |

## Handoff (4 Nov ~15:50 UTC)

- **State:** branch `tb/near6-ms-1104` rebuilt on main `60f2df27` (#823). Landed on main from this lane: F41#20 camfx fade + dialogue open (CPU 4.72 -> 5.64), F38#29 beaten kneel + silent victory shot (5.76 -> 6.18). Landing-ready on the branch: **F38#32 trail camp keep-clear (5.61 -> 5.81, `773e609b`, tests pass)**.
- **Open candidates / ideas:** F38#6 needs a real item-identity cue (tier shapes never show in its frames: only one sweet per pickup); F41#3 overlap happens inside the boss lunge, which spacing exempts by design (would need a lunge stop-short, combat feel); F41#9 parked (needs new art: copper/glass cues, solid glowmoss model); F41#15 speakers already clear with the fade ON, Marrow's face is white from the model material; F38#7 wireframe aim silhouette (source unknown).
- **What worked:** reading earlier judges' defect text, then fixing the *staging* rather than the asset (camera fade, victory push-in, keeping wild creatures out of a camp). Pure retunes of shipped values (grass radius, speaker light, glow energy) were flat or no-ops; check a pixel diff before spending a judge round.
- **Runbook:** TECHNICAL §8.1 + `tools/visual_judge/quick_judge.py` (plan / run --overlay / finish). Lessons: never `git fetch` a branch without `--depth=1` on this shallow clone (15 GB pack fills the disk); `pgrep -f` waiters must not match their own command line (use `[q]uick_judge`); background Bash is killed at its timeout (2 h max), so re-arm long queues; any tracked edit (tests too) changes the base cache key; job.json repro commands can be narrowed locally (restore before commit).


Lane: tb/near6-ms-1104 (from origin/main 12e76f2a, #813; rebuilt on main 60f2df27, #823, at 13:55 UTC, which already carries F41#20 and F38#29). Items F38#29, #6, #26, #7, #32 and F41#9, #20, #15, #3 (board 5.4-6.0). Yardstick: `tools/visual_judge/quick_judge.py` (CPU llvmpipe Low/Compatibility, base and candidate on the same stands, JUDGE_PROMPT verbatim, 3+ anchor pairs, three code-blind judges, calibrate.py). Owner 4 Nov: any judged CPU gain ships ON; flat or worse stays OFF.

## Landing-ready (flag, score, test, commit)

- **F41#20 P2-084 named character dialogue: CPU 4.72 -> 5.64** (`qj/F41-20-afe828ee024f-11040806/`). ON: `camfx.json fight_fade` and `camfx.json dialogue_open` (judged together; `_why_on` carries the score). Fenn's dialogue frame was black (camera inside a dark blocker); with the fade it shows Fenn. Test: `test_camfx_candidates.gd` (JUDGED_ON map; OFF paths still checked with the block forced off). **Tests passed (10:00 UTC):** test_camfx_candidates, test_conversation_camera, test_fight_camera, test_foliage_fight_fade, test_storm_cams_candidates, test_combat_camera_clear_orbit, test_texture_import_policy, test_near6_ms_1104, test_capacitor_spacing_override: 90 tests, 2102 assertions, 0 failed. Commit: see `git log` (flip commit after 4cebe0eb).

- **F38#29 P2-065 trainer defeated presentation: CPU 5.76 -> 6.18** (`qj/F38-29-88df037c89f6-11041137/`; round 2, after the kneel alone was flat in round 1). ON: `npc_post_stances.json beaten_trainer_stance.immediate_1104` (beaten trainer drops to both knees, head bowed, the moment they lose; `post_stance.gd` rows take an optional hip drop) and `trainer_aftermath.json silent_victory_shot_1104` (a trainer beaten without victory lines gets the existing `aftermath` push-in for 5 s; `encounter_director.gd::_present_silent_victory`). All three judges scored the candidate higher. Test: `test_near6_ms_1104.gd` (asserts both ON with the score; OFF path still checked). **Tests passed (13:00 UTC):** test_near6_ms_1104, test_uiposes_post_stance, test_trainer_aftermath, test_trainer_aftermath_lifetime, test_trainer_aftermath_world_change, test_conversation_camera, test_texture_import_policy: 55 tests, 1929 assertions, 0 failed. Commit `f4748d0b`.

- ~~F38#26 creature_rim ON (CPU 5.95 -> 6.07)~~ **Withdrawn (coordinator, 4 Nov 13:47):** it duplicated the visual lane's stronger rim10 rim, ON on main since #817 (batch 16 keeps main's). The branch was rebuilt on main `60f2df27` (#823) without it; further F38#26 work is judged on top of rim10. The verdict stays in `qj/F38-26-662667cd3005-11041311/` as evidence that a Meadows creature rim reads.

- **F38#32 P2-035 camp and workshop prop legibility: CPU 5.61 -> 5.81** (`qj/F38-32-48f121f0ded9-11041358/`; judged on main 60f2df27). ON: `combat.json arena.wild_keep_clear` entry `trail_camp_1104` (14 m around the trail camp floor; wild bodies neither spawn nor settle a wander target there) plus a 3-line `enabled` check in `encounter_director.gd::_wild_keep_clear_zones` (zones without the key stay on). All three judges scored the camp without the coyote and hare higher. Test: `test_near6_ms_1104.gd test_f38_32_trail_camp_keep_clear_ships_on`. **Tests passed (14:50 UTC):** test_near6_ms_1104, test_wild_once, test_capacitor_spacing_override, test_texture_import_policy: 24 tests, 1696 assertions, 0 failed. Commit `773e609b`.

## Arms built (OFF until judged)

- (landed) F38#29 P2-065: `npc_post_stances.json beaten_trainer_stance.immediate_1104` (the beaten trainer drops to both knees, head bowed, the moment they lose; `post_stance.gd` rows take an optional hip drop). Test `test_near6_ms_1104.gd`. First candidate run was cut off by a timeout; rerun queued.
- F41#3 P2-092: `combat.json contact_spacing.named_overrides.capacitor_alpha` (taken from VIS-STORMWOOD `ea108029`). Test `test_capacitor_spacing_override.gd`.

## Judged flat or worse (stay OFF)

- **F38#7 P2-058 catch aim: no arm; camfx fight_fade not implicated.** Base frames on main (CPU ~7 per VIS-MEADOWS r1b) show the target and the player's creature drawn as a pale wireframe silhouette through the trainer in every aim frame. A capture with `camfx.json fight_fade` OFF shows the same silhouette in 01/07/catch_high/catch_low (only the hare's position varies run to run), so the F41#20 fade did not cause it. The silhouette, not the readout, is now the main read problem; its source is not a data flag this lane found. Not pursued further (base already above 6).

- **F41#15 P2-083: no-op, not judged.** With `camfx fight_fade` ON (F41#20 flip) the three dialogue frames already show Captain Marrow and Officer Nysa unobstructed. Candidate: softer conversation speaker light (`camera.json conversation.speaker_light_candidate` key 0.9 -> 0.45, rim 1.5 -> 1.0) aimed at Marrow's white-blown face. Under 0.2% of pixels changed (mean |diff| < 1/255), so the speaker light is not what blows the face out on CPU; no config change kept. Remaining defect on these frames is Marrow's near-white face (model material) and a pale deck post at the left edge.

- **Round 3** (`qj/F38-6_F38-26_F41-9-9c1d0cc52d13-11041219/`), each item judged on its own frames:
  - **F38#6 P2-033: CPU 5.95 -> 6.15 (+0.20) but treated as flat.** Arm `pickup_grounding.json tier_candidate`. All three judges described the pickups as identical on both sides; the only difference they saw was the distant background creatures in frame 1 (white untextured on one side), which is render variance, not the arm. Good candy is a single sweet in both arms, so the tier shapes never appear in these frames. Stays OFF.
  - **F38#26 P2-020: CPU 5.78 -> 5.78 (flat).** Overlay `creature_grass_clear.json radius_scale` 1.6 -> 2.6 changed nothing visible: the creature-stage frames came out identical, so the clearing does not reach the grass that hides these creatures (midground tufts and tree shadow, creatures small in frame). No config change kept.
  - **F41#9 P2-046: CPU 5.45 -> 5.42 (flat).** Overlay: `stormwood_harvest_hero2.json` glowmoss only (darker moss mound, fungi glow #2fae7e at 0.5). Glowmoss still reads as a white blob on CPU; the judges want a copper or violet-glass material cue on the stormglass nodes and a solid model in place of the blob. With VIS-STORMWOOD's hero2 round (4.76 -> 4.59) this is the second flat round on this item, so it is **parked** until there is a new idea (likely new art).

- **F41#3 P2-092 round 1: CPU 4.70 -> 4.75 (+0.05, flat)** (`qj/F41-3-df06580591bf-11041108/`). Arm: `combat.json contact_spacing.named_overrides.capacitor_alpha` (VIS-STORMWOOD's render-box footprint). The tell-start and impact frames are during a lunge or burst, which the spacing rule exempts by design, so the overlap stays. Judges also mark the fight's daylight-green grade off the Stormwood board. Next idea: the base contact spacing itself is fine at i01; the defect is in the exempt burst, so a change would have to touch the boss's lunge target (stop short of the ally's body), which is combat feel, not presentation.

- **F38#29 P2-065 round 1: CPU 6.14 -> 6.22 (+0.08, flat)** (`qj/F38-29-6d8f80b7ac71-11040957/`). Arms: `npc_post_stances.json beaten_trainer_stance.immediate_1104` (beaten kneel) + `art.json grunt_a.clip_candidate`. One judge saw the hunched grunt (PARTIAL); the others saw no change because the grunt is a few pixels tall, behind or beside the player, in all three frames. All three judges asked for a camera beat that frames the defeated trainer. Next idea: a short post-victory shot on the beaten trainer (game presentation, not a capture stand change).

## Blockers / notes

- Harness note: a plain `git fetch origin <branch>` on this shallow clone pulled a 15 GB temp pack and filled the disk; `git fetch --depth=1 origin <branch>:refs/remotes/origin/<branch>` takes the same branches in seconds.
- **For the coordinator:** `send_message` from this lane is refused (untrusted device), so this file is the handoff. The F41#20 flip you asked for is on `tb/near6-ms-1104` at `f07442cc` with the touched tests passing.
- F38#29 kneel checked by render (`tools/_probe_beaten_kneel.gd`, grunt_a on a stage: knees flex back and rest on the floor, hips lowered, head bowed) before its round.
