# LANE-PLACES NOTE (branch `tb/places`)

## NOW THE RE-SCORING LANE (owner direction via coordinator, 12 Nov about 12:30)
Job: an up-to-date GPU High score on current main for every visual row; judged here with `tools/visual_judge` (standard prompt, at least 3 anchor pairs, three code-blind judges, `calibrate.py`); write-ups as `ralph/reports/GPU-PASS/1108/G-rescore-<batch>.md` on `tb/places`.

### 13 Nov: coverage check against the board (main b8622117)
**`tb/places` was deleted after landing, and main got an old 18-line copy of this NOTE.** It is restored from 652cad03. The parked flag-off arms dropped at landing (`road_value_1112`, road current `thin_1112`) stay on commit 652cad03; `ground_wet_path_1112` is on main.

**Board gaps: the board never took these re-scores.** All are from G-rescore-stale-ext-cloudreach, main 90ffeb663, 12 Nov. The coordinator should write them into `gpu_scores`:
- F40#2: board 6.15, re-score 6.93
- F40#4: board 6.12, re-score 6.47
- F40#7: board 6.26, re-score 6.80
- F40#11: board 6.97, re-score 6.52 (after #906; the judges named PARTIAL 3/3)
- F40#14: board 6.99, re-score 7.21
- F40#16: board 6.19, re-score 6.93
- F40#18: board 7.10, re-score 7.49 (just under the bar; it needs Medium only if a confirming read crosses 7.5)

**Superseded:** my F41#13 5.97 (stale-d) was on main 90ffeb663, before #938 (near-black Stormraven). The board's G-closeout-f41-13-main 6.91 is the current number.

**Checked, not gaps:** F39#21's 4.34 (G-rescore-f39-21-f41-13) was on main 306239e9f (#885, 10 Nov 08:03), before the #893 win at 7.06. F38#20, #21 and #22 differences are partial-frame cross-checks or later closes.

**Stale on main b8622117: scores that predate landings in their frames.** These are requested from the GPU lane as `PLACES-RESCORE/CAPTURE-D-1113.json`:
- **F40#0, F40#19, F40#21** (5.98 sample at 90ffeb663): #939 (Stormward Overlook amber pane and beacon balls) and #941 (High Perches court placeholder grass) changed two of the twelve stands. The overlook was the lowest stand in that sample. Same 192-frame sample, so it compares directly.
- **F39#21** (7.06, 10 Nov): #947 removed the world-verb prompt from fight HUDs outside Meadows, and #942 tightened the conversation shot.
- **F40#1** (5.90, 8-9 Nov) and **F13#5** (6.28, 10 Nov): oldest scores on the board with no later re-score.
- **F38#1** (6.58, 11 Nov audit): NPC floor, scored before #942's conversation shot.
- **F38#0** (6.60, 10 Nov, 268 frames): Meadows had #937, #945, #949 and the bedroom wood since. Lowest priority because it is the largest set.
- Still unscoreable (no job.json entry): F38#41, F39#32, F22#4.

**G-rescore-1113** (`ralph/reports/GPU-PASS/1108/G-rescore-1113.md`; main b8622117, High; fit r 0.855, RMSE 0.575, five anchor pairs, read as +/-0.6):
- F39#21: 7.06 -> 5.84 (13 Nov; BELOW 6). In the Venn win frame, a flat untextured grey plane covers the lower half of the screen (3/3). Its far edge follows the beach grass, so it looks like a water or fill plane at one height drawn over a dip in the dune. The GPU lane confirms it is a regression since 10 Nov: the 9-10 Nov captures have no plane, and today's two runs match each other. It is for whoever owns F39#21; the Nerissa frames read clean.
- F40#1: 5.90 -> 5.84 (13 Nov; still below 6; defect PRESENT 3/3: flat empty lawn, terrain-disc edge)
- F40#17: 6.18 -> 5.61 (13 Nov; BELOW 6; toy-like glow mushrooms, night grade off-palette navy)
- F38#1: 6.58 -> 6.26 (13 Nov; fainted poses still stiff or hovering, Veridian worst)
- F40#4: cross-check on 1 of 3 frames, 6.07 (board 6.12, my 12 Nov 6.47)
- F13#5: 6.28 -> 5.38 (13 Nov, G-rescore-1113-f13-5; all four T2 swim views as one set; fit r 0.958, RMSE 0.40; BELOW 6). The crescent current cue reads as decals or a debug overlay, defect PRESENT 3/3. The ask is one aligned field of soft foam streaks running downstream past the swimmer.
- Still to come: F40#0/#19/#21 stands 1, 7 and 12 from TURFGRAIN's base (tb/land-cs, main plus flag-off files), then a full 12-stand main run after TURFGRAIN and SOILOFF land. F38#0 is skipped (queue).

### Re-score results (one line per row: row, old board score, new mapped score, date and batch)
**G-rescore-stale-tier2** (`ralph/reports/GPU-PASS/1108/G-rescore-stale-tier2.md`; fit r 0.893, RMSE in the report):
- F38#2: 6.0 -> 6.35 (12 Nov, G-rescore-stale-tier2)
- F38#6: 6.1 -> 6.52 (12 Nov, G-rescore-stale-tier2)
- F38#12: 6.06 -> 5.89 (12 Nov, G-rescore-stale-tier2)
- F38#13: 7.16 -> 6.94 (12 Nov, G-rescore-stale-tier2)
- F38#14: 6.06 -> 6.94 (12 Nov, G-rescore-stale-tier2)
- F38#20: 6.02 -> 5.72 (12 Nov, G-rescore-stale-tier2)
- F38#21: 7.0 -> 6.23 (12 Nov, G-rescore-stale-tier2)
- F38#22: 6.1 -> 6.06 (12 Nov, G-rescore-stale-tier2)
- F38#29: 6.05 -> 6.35 (12 Nov, G-rescore-stale-tier2)
- F39#5: 6.06 -> 5.64 (12 Nov, G-rescore-stale-tier2)
- F39#14: 6.37 -> 6.44 (12 Nov, G-rescore-stale-tier2)
- F40#15: 6.08 -> 5.89 (12 Nov, G-rescore-stale-tier2)
- F40#17: 6.08 -> 6.18 (12 Nov, G-rescore-stale-tier2)
- F41#10: 6.02 -> 6.01 (12 Nov, G-rescore-stale-tier2)
- F41#18: 6.1 -> 5.93 (12 Nov, G-rescore-stale-tier2)
**Flags:** none at 7.5 or above. Below 6 now: F38#12 5.89; F38#20 5.72; F39#5 5.64; F40#15 5.89; F41#18 5.93. F38#21 was judged on 2 of its job frames (it rode along); re-judge it in the Meadows batch.

**G-rescore-stale-ext-meadows** (`ralph/reports/GPU-PASS/1108/G-rescore-stale-ext-meadows.md`; fit r 0.867, RMSE 0.58). **Caveat: this batch reads about 0.6 above tier2 on the five rows judged in both, and every score above 7.35 is extrapolated.**
- F38#3: 6.49 -> 8.09 (12 Nov, G-rescore-stale-ext-meadows)
- F38#4: 7.21 -> 8.09 (12 Nov, G-rescore-stale-ext-meadows)
- F38#7: 7.26 -> 7.52 (12 Nov, G-rescore-stale-ext-meadows)
- F38#9: 7.32 -> 8.29 (12 Nov, G-rescore-stale-ext-meadows)
- F38#10: 6.58 -> 7.38 (12 Nov, G-rescore-stale-ext-meadows)
- F38#11: 6.89 -> 7.47 (12 Nov, G-rescore-stale-ext-meadows)
- F38#13: 7.16 -> 7.66 (12 Nov, G-rescore-stale-ext-meadows)
- F38#15: 6.84 -> 7.23 (12 Nov, G-rescore-stale-ext-meadows)
- F38#18: 7.95 -> 8.24 (12 Nov, G-rescore-stale-ext-meadows)
- F38#19: 6.89 -> 7.62 (12 Nov, G-rescore-stale-ext-meadows)
- F38#21: 7.0 -> 6.95 (12 Nov, G-rescore-stale-ext-meadows)
- F38#23: 7.58 -> 6.57 (12 Nov, G-rescore-stale-ext-meadows)
- F38#25: 6.23 -> 7.23 (12 Nov, G-rescore-stale-ext-meadows)
- F38#33: 7.32 -> 8.14 (12 Nov, G-rescore-stale-ext-meadows)
- F38#34: 6.75 -> 7.76 (12 Nov, G-rescore-stale-ext-meadows)
- F38#35: 6.31 -> 6.33 (12 Nov, G-rescore-stale-ext-meadows)
- F38#38: 8.16 -> 8.52 (12 Nov, G-rescore-stale-ext-meadows)
**Flags:** eleven rows map at 7.5 or above (F38#3, #4, #7, #9, #13, #14 partial, #18, #19, #33, #34, #38): candidates for a Medium capture plus a confirming two-sided judgement, not High passes yet. F38#23 dropped 7.58 → 6.57 (its defect is fixed; the yard is now an empty stretched-cobble plane). None below 6.

**G-rescore-stale-ext-tidewake** (`ralph/reports/GPU-PASS/1108/G-rescore-stale-ext-tidewake.md`; fit r 0.940, RMSE 0.39, the tightest so far; all 21 rows on full frame sets):
- F39#1: 6.42 -> 6.14 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#2: 6.48 -> 6.79 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#3: 6.1 -> 7.26 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#4: 7.28 -> 7.81 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#7: 6.61 -> 7.07 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#8: 5.66 -> 5.82 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#9: 6.65 -> 6.42 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#10: 6.3 -> 7.02 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#12: 6.8 -> 6.98 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#13: 6.23 -> 6.14 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#14: 6.37 -> 6.75 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#15: 6.27 -> 6.14 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#16: 6.88 -> 6.56 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#17: 6.27 -> 5.50 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#19: 6.85 -> 6.56 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#20: 6.37 -> 6.42 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#22: 6.19 -> 6.70 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#23: 6.8 -> 7.35 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#24: 7.18 -> 7.77 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#25: 7.28 -> 7.07 (12 Nov, G-rescore-stale-ext-tidewake)
- F39#28: 7.33 -> 7.30 (12 Nov, G-rescore-stale-ext-tidewake)
**Flags:** at 7.5 or above, need Medium: **F39#4 7.81, F39#24 7.77** (defects FIXED 3/3). Below 6: **F39#17 5.50** (was 6.27; restoration shows no visible change, PRESENT 3/3) and F39#8 5.82 (was 5.66). Out of the 6–7 band upward: F39#3 7.26, F39#7 7.07, F39#10 7.02, F39#23 7.35.
**F39#17 for a build lane (below 6 now):** the GPU lane checked the frames: live and restored differ by 0.58% of pixels at the same camera, so the row needs a game change (stronger live flow streaks, or a larger visible change on restoration), not a capture change. **Medium for F39#4 and F39#24 is queued** as G-closeout-tidewake-medium.
**Meadows Medium (G-closeout-meadows-ui-medium @ e92acfdc9: F38#3 #4 #7 #9 #19 #33 #34) is left to LANE-SCOUT for the close decisions**, so the same frames are not judged twice. I am not judging it unless the coordinator asks for a second panel. The -medium-2 section was dropped by the coordinator (F38#18 and #38 closed on 9 Nov; F38#13 pools to about 7.3).
**Requests for the GPU lane (it reads this NOTE through you if my message does not arrive):** Medium for F39#4 and F39#24, same frames.

**G-rescore-stale-ext-cloudreach** (`ralph/reports/GPU-PASS/1108/G-rescore-stale-ext-cloudreach.md`, frames @ d5a3a57b2; fit r 0.859, RMSE 0.59):
- F40#2: 6.15 -> 6.93 (12 Nov, G-rescore-stale-ext-cloudreach)
- F40#4: 6.12 -> 6.47 (12 Nov, G-rescore-stale-ext-cloudreach)
- F40#7: 6.26 -> 6.80 (12 Nov, G-rescore-stale-ext-cloudreach)
- F40#11: 6.97 -> 6.52 (12 Nov, G-rescore-stale-ext-cloudreach)
- F40#14: 6.99 -> 7.21 (12 Nov, G-rescore-stale-ext-cloudreach)
- F40#16: 6.19 -> 6.93 (12 Nov, G-rescore-stale-ext-cloudreach)
- F40#18: 7.1 -> 7.49 (12 Nov, G-rescore-stale-ext-cloudreach)
**Flags:** none at 7.5 or above, none below 6. **F40#18 7.49** is a close-out candidate (defect FIXED / FIXED / PARTIAL). **F40#11 is on 2 of 3 frames**: its job.json lists a ride still (`phase2_18_terrace_02.0s`) that the tool no longer produces; whoever owns job.json should point it at `phase2_18_terrace_after`. All four world rows share one cause 3/3: flat single-tone lawn, faceted brown cliffs and extruded disc shelves with knife-straight edges.

**G-closeout-tidewake-medium** (`ralph/reports/GPU-PASS/1108/G-closeout-tidewake-medium.md`; two-sided High against Medium, fit r 0.843, RMSE 0.62, confirming batch):
- F39#4: High 8.03, Medium 8.03 (12 Nov); the one-sided panel had High 7.81. Defect FIXED 3/3.
- F39#24: High 7.99, Medium 7.99 (12 Nov); the one-sided panel had High 7.77. Defect FIXED 3/3.
**CLOSE CANDIDATES for the coordinator: F39#4 and F39#24** meet 7.5 on both Medium and High across two panels. Scores are extrapolated above the top anchor (7.35), as every score in this range is.

**G-rescore-stale-ext-stormwood** (`ralph/reports/GPU-PASS/1108/G-rescore-stale-ext-stormwood.md`, frames @ d41014666; **fit r 0.792, RMSE 0.70, the loosest batch: changes under about 0.7 are inside its error**; all 16 rows on full frame sets):
- F41#1: 6.81 -> 7.62 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#3: 6.23 -> 7.06 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#4: 6.37 -> 7.02 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#5: 6.06 -> 6.53 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#6: 6.8 -> 6.83 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#7: 6.24 -> 7.02 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#9: 6.81 -> 7.17 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#11: 6.91 -> 7.55 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#12: 6.6 -> 6.90 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#14: 6.35 -> 7.59 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#15: 4.49 -> 6.87 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#16: 6.28 -> 6.37 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#17: 7.03 -> 7.40 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#19: 6.56 -> 7.25 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#20: 6.41 -> 6.68 (12 Nov, G-rescore-stale-ext-stormwood)
- F41#21: 7.13 -> 7.25 (12 Nov, G-rescore-stale-ext-stormwood)
**Flags:** clear moves: F41#15 4.49 → 6.87 (out of below-6; defect FIXED 3/3) and F41#14 6.35 → 7.59. Marginal 7.5-or-above (extrapolated, want a second panel before Medium): F41#1 7.62, F41#11 7.55, F41#14 7.59. None below 6. F41#12's thick-gold-stripe defect is FIXED 3/3 on main as it is.
**Method note for the coordinator:** across today's five batches the same rows moved 0.6 to 0.9 between batches (anchor RMSE 0.39 to 0.70 with three pinned anchor pairs). Row changes smaller than that are not real. I am using five anchor pairs from the next batch; rows near 7.5 should close only on a pooled or two-sided confirming panel, as F39#4 and F39#24 did.

**G-rescore-f40-0-sample** (`ralph/reports/GPU-PASS/1108/G-rescore-f40-0-sample.md`, frames @ 6b2bfe3ef; 192 frames, 24 sets, five anchor pairs; fit r 0.730, RMSE 0.66, so about ±0.6):
- F40#0: 6.54 -> 5.98 (12 Nov, G-rescore-f40-0-sample; clear 6.29, rain 5.68; sample of day and night only)
- F40#19: 6.66 -> 5.98 at High (same matrix mean; realm gate rain set 5.59)
- F40#21: 6.68 -> 5.98 (matrix mean; its defect FIXED 3/3 at 4 of 12 stands, PARTIAL at 7)
**Flags:** F40#0 reads about 6 (5.98, inside the batch's error of the below-6 line). **Rain is 0.6 below clear at every stand.** Lowest stands: stormward overlook, windscar flight aerie, broken skyroad arch, old wind observatory (thin landmarks, new art). Judges' next rain asks: brighter broken overcast in place of the striped grey sky, pale stone kept pale, wet sheen, fog layers; at night a moon key and warm lamp pools in place of the cobalt wash.

- F41#22: 6.96 -> 6.46 (12 Nov, G-rescore-f41-22-24; five stands x three storm states; anchor RMSE 0.75, read as +/-0.75; giant 5.51, forest 6.06, rod_line 6.49, glass 6.98, stormheart 7.28)
- F41#24: 7.08 -> 6.46 (same mean; its defect FIXED 3/3 at glass and stormheart, PARTIAL 3/3 at giant and forest: grey slab at the trainer's feet in Break)
- Not scoreable: F38#41, F39#32, F22#4 have no job.json capture entry, so there are no frames to request.
- F38#8: 7.14 -> 6.18 (12 Nov, G-rescore-stale-d, full set; defect PRESENT 3/3: trainer hangs rigidly under Galecrest; batch reads +/-0.7)
- F41#13: 6.66 -> 5.97 (same batch; BELOW 6; Fulgocobra reads, Stormraven is a flat cobalt shape with no face or charge contrast)
- Re-score queue is empty as of G-rescore-stale-d. Rows below 6 on current main at High: F38#12 5.89, F38#20 5.72, F39#5 5.64, F39#8 5.82, F39#17 5.50, F40#15 5.89, F41#18 5.93, F41#13 5.97, F40#0/#19/#21 5.98.

### Build work handed over
| Item | State | Goes to |
|---|---|---|
| `ground_wet_path_1112` round 2 (Cloudreach wet ground, duller frayed trail) | On the GPU queue (`PLACES-WETPATH/`, ARM Round 2). Round 1 was a split: clear +0.60/+0.57, gate rain +0.65; summit night rain −0.34, overlook rain −0.09. Round 2 halves the soil darkening, keeps it warm, none at night. Never captured. Flag-off code is on `tb/places` (four Cloudreach shaders, `cloudreach_weather.gd`, `project.godot` global, `cloudreach_visual.json`, a test). | LANE-THINGS (owns 6–7); cut the landing from current main if it ships |
| `road_value_1112` umber road (Stormwood) | Won twice against the black road (3/3); held because every gold-line variant on it lost or failed pre-check. Flag-off on `tb/places` (`stormwood_ground_zones.gd`, `stormwood_ground_finish.json`, `stormwood_road_current.gd/.json` with `thin_1112`). | Parked pending the owner's charge-colour answer (white-violet or gold) |
| F40#1 open terrain | No arm expected to gain 0.5 without real ledges (terrain with collision). | LANE-BELOW6 |
| `fading_clear_1112` | Not needed (Fading is fine on GPU once #919 landed); removed from `tb/places`. | dropped |
Landed from this lane: storm light + distinct bodies (#914), rain time grade (#915), Break-only lightning (#919), gate paving scoped (#920), storm phase tool settle.
Flags for whoever takes Stormwood next: lightning is Break-only (owner); puddles parked; F41#2 judges want a strike on the tree in Break, clearer Calm, colder Building, softer Fading mist.

### Re-score list (from `status.json gpu_scores` on main b3dc2139)
- **Tier 1, running on the GPU lane (47 rows, 6–7 band, scores dated 8–9 Nov):** G-rescore-stale-tier2, -ext-meadows, -ext-tidewake, -ext-cloudreach, -ext-stormwood. I judge each as it lands.
- **Tier 1b, requested (`PLACES-RESCORE/CAPTURE-B-stale-rest.json`, 17 rows):** the other 8–9 Nov rows: F38#4, #7, #9, #13, #15, #18, #21, #23, #33, #38; F39#4, #8, #24, #25, #28; F40#18; F41#17. F38#41 has no job.json entry. Likely Medium candidates: F38#18, #23, #38.
- **Tier 2, requested (`PLACES-RESCORE/CAPTURE-C-after-landings.json`, 14 rows):** scores from 10–11 Nov that predate landings in their frames: F41#1, #3, #7, #9, #11, #15, #20, #21, #22, #24; F40#19, #21, #11, #0 (a sample).
- F41#2 waits for the storm phase tool fix to be on main.
- **Judging rules to hold to:** on the creature pose stage (`capture_f36_poses.gd`) High and Medium frames are effectively identical (LANE-SCOUT, `G-things-creature-closeout`), so a pose-stage row is one score with pooled panels; one panel's High pass does not close a row. Board updates LANE-SCOUT says need no capture: F38#15 High 7.70 / Medium 7.37; F36#33 8.03 / 7.28; F36#36 7.69 / 7.03; F36#52 7.26; F36#62 7.31; F36#70 7.26; F36#66 7.07; F41#18 6.22.
- **Routes:** this session can message the GPU lane (owner approved on a trusted device, 12 Nov); the coordinator session still refuses it, so the coordinator reads this NOTE. Requests B and C were delivered to the GPU lane. As of 12:40 no `G-rescore-stale-*` section is on `tb/gpu-frames-1108` yet.

## RESTARTED (owner direction via coordinator, 12 Nov 2026)
- **For the coordinator (LANE-SCOUT cannot reach you): `G-places-wetpath` (49169c37) was a SPLIT.** Clear controls +0.60 and +0.57, gate rain +0.65 (3/3 each); summit night rain −0.34 and overlook rain −0.09; F40#1 level (needs ledges). **Round 2 is sent** (`PLACES-WETPATH/` ARM Round 2, CAPTURE r2): wet soil darkens half as far and stays warm, no rain darkening at night, clear tone unchanged. Not re-captured on CPU. It is the only arm waiting.
- **Gate paving (scoped) landed in #920**; main a4ad0486 is merged into `tb/places`.
- **Sent to GPU (the only arm waiting): `PLACES-WETPATH/`** (`ground_wet_path_1112`): Cloudreach ground and trail darken with a sheen in rain; trail duller with a frayed, wider shoulder. Cause: rain wetness only ever reached the Meadows terrain material. Rows F40#0, F40#19, F40#1. CPU: clear and rain gate frames both show it.
- **send_later:** not used; this session only acts on reminders the owner asks for. Coordinator: please nudge instead.
- **Gate paving judged SPLIT; scoped landing cut.** `G-places-gatepaving` (555ebf04): F40#0 gate clear +0.93, rain +0.79 (3/3 each); F40#1 grass stands −0.61 (0/3, stones nearly invisible on grass). Landing `tb/places-gatepaving-land` (35ec8545), `PLACES-GATEPAVING/READY.md` STATUS: land: flag ON only at the dirt-road stands, grass stands as on main. The scoped form was checked on CPU, not re-judged on GPU.
- **Sent to GPU (the only arm waiting): gate paving round 2, scoped** (`PLACES-GATEPAVING/` ARM Round 2, CAPTURE r2), same frames, for a re-judge. The landing branch above waits on it: land only if the gate gain holds and F40#1 does not lose.
- Open at the gate (judges): orange path too saturated with unblended edges; rain has no wet darkening or sheen. F40#1 still needs real ledges.
- **Swing 3 failed the GPU pre-check and is withdrawn.** Road yellow share rose at 3 of 8 stands and all 3 dialogue frames; the line was the shipped width with a stronger core, so "thin" was not true (my r2 values, not a reader fault: `thin_1112` is read in `stormwood_road_current.gd config()`). r1 (really thin) vanished on CPU. That is two failures for the thin gold line, after too-faint and too-bright: **the gold line on the umber road is parked.** The umber road (won twice, 3/3) stays flag-off and held until the owner decides the charge colour (white-violet, as the judges ask, or gold).
- **Capture tool fix, landing cut:** `tb/places-phasetool-land`, `PLACES-PHASETOOL/READY.md` (STATUS: land). The storm phase stills now settle two seconds after each pin, time Break on a bolt and fail if lightning shows in any other phase. CPU: four distinct stills. F41#2 needs a base re-capture after it lands.
- **Sent to GPU (the only arm waiting): `PLACES-GATEPAVING/`** (`paving_scale_1112`) for F40#1 (5.90, now this lane's) and the F40#0 gate stands. Expected gain is small and said so in the ARM.
- **F40#1: no arm I expect to gain 0.5.** I read `BELOW6-F40-1/NOT-SENT.md` and agree with it and with LANE-NEWAPPROACH before it: dressing at the stands is exhausted (eight candidates, pad on/off); the row needs real ground (pale ledges or a terrace edge with collision along the gate approach, or the island side wall's top band given strata). That is a multi-hour terrain change needing a design for one stand first; not started. Cloudreach ground colour variation (sage retint, clustering) and the cause package are already judged flat or lost, so I am not repeating them as "ground variation".
- **Swing 2 was judged: DO NOT SHIP** (`G-places-swing2`, 7e327f36). F41#12 −0.71 ("thick, bright, saturated gold stripes"), F41#4 −0.17, F41#5 −0.16; F41#8 +0.38. The umber road has now won twice against the black slab; the gold line is the problem at both strengths. Gold brightness alone is parked; `contrast_1112` is removed.
- **OWNER QUESTION (please relay): the judges ask for the road charge in white-violet.** The road current is yellow-gold by owner direction (WO-F09-04: "yellow electricity flowing through them"; the config says yellow/gold only). I have not changed the colour. `thin_1112` keeps it gold and makes it one thin sparse line with no web and almost no halo. If the owner wants white-violet, it is a two-colour config change on top.
- **Fading bolt: settled as capture timing** (GPU motion probe 93b455abe), and fixed in the game so it cannot recur: live lightning goes out the moment Break ends. **Landing branch `tb/places-breakonly-land` (a2ce48f7), `PLACES-BREAKONLY/READY.md`, STATUS: land.** F41#2 needs a fresh base after it lands. `fading_clear_1112` is not needed (GPU Fading on main is already brighter than Building, L 139 vs 107); it stays flag-off and unused.
- **Sent to GPU (the only arm waiting): swing 3**, `PLACES-STORMWOOD3/` = umber road + `thin_1112` (one thin gold line, no web). CPU r1 made the line vanish; r2 reads as one thin line on F41#4's stands. Rows F41#12, #4, #5, #8, #2. Not included: bear and tree-card recolours, layered treeline.
- **F41#2 re-scored on main + #919: 6.19** (`G-rescore-f41-2-breakonly`, f146e7dd; defect PARTIAL 3/3). Fading reads as its own phase. Judges' next asks, all scene work and not started: (1) Break is not a climax: a strike on the sentinel tree with a white-violet flash grade; (2) Calm brighter and clearer, Building colder with rolling cloud; (3) Fading's steam reads as "flat sprite blobs at waist height": lower, softer ground fog; (4) flat green carpet and painted sky.
- **Break-only fix confirmed on GPU** (`G-rescore-f41-2-breakonly` 76e698f09: no bolt in Fading, Break keeps its lightning); it is PR #919. The pale fog puffs in Fading are the authored Fading steam.
- `tb/places` was deleted on the remote; recovered from the lane container and re-cut from main d777b905 with `road_value_1112` (flag-off, puddles parked) and this NOTE.
- **Working on:** Stormwood swing 2 = road value done right (gold path line contrast restored on the umber road) riding inside a bigger pass: a Fading phase that differs from Building, layered treeline and depth steps. Then Cloudreach F40#0 gate cobbles, ground and fog. Then near-bar close-outs (F41#17, #24, #21, F40#18, F39#24, #25, #4).
- **Sent to GPU (arm 1 of 2):** `PLACES-STORMWOOD2/` (two overlays): judged no-puddles road + gold line contrast + a clearer Fading. Rows F41#2, #4, #5, #12, #8. CPU: the gold line reads clearly on the umber road.
- **Finding:** the CPU phase tool's Fading still repeats a Break frame (bolts, dark deck) on main and on every arm, so Fading cannot be checked on CPU. On GPU the judges did see Fading (steam), so this looks CPU-only; not chased further.
- **Next:** Cloudreach F40#0 gate cobbles, ground and fog; then near-bar close-outs.
- **Built, held (not sent): `paving_scale_1112`** (`cloudreach_f40_items.json`, `cloudreach_settlement_life.gd`; overlay and CPU sheet in `PLACES-GATEPAVING/`). Cause found: the gate's stone-trail pieces are sized by a 0.28 m height, which scales the model about 2.5x and stands its top a shin's height proud. On: 0.12 m pieces sunk 55%. CPU (gate approach, day clear): the torso-sized pad becomes a line of boot-sized stepping stones flush with the path. It touches the gate, gate-road and shrine stands only, so it is under 0.5 alone; it waits to ride with Cloudreach ground colour variation and layered fog (not built yet).
- Main 2ac7ab84 (#917) is merged into `tb/places`.
- Standing rules for this lane: lightning is Break-only (owner); puddles parked; check older test pins and `texture_import_policy.py` before a landing; no unrelated `.uid` files.

## WRAPPED (owner direction via coordinator, 12 Nov 2026). Handoff.
No new arms are started. Everything is pushed. The lane stops here except for one conditional step: **if the road-value arm ships, cut its landing from current main** (flip `road_value_1112` ON with `_why_on`, with the judged overlay's puddle setting, add a pin, READY.md).

### State
| Item | Where | Status |
|---|---|---|
| P1 storm light (`storm_phase_1111`) + `distinct_bodies_1111` | main, PR #914 | **Landed.** GPU F41#2 +0.80, F41#8 +0.58, F41#13 +0.23. Building far bolts removed by owner decision. |
| P2 Cloudreach rain (`rain_time_grade`) | `tb/places-raintime-land` d0e0b9c0, PR #915 | **Judged win, landing in PR.** All 12 rain sets 3/3, mean +0.70. |
| Stormwood road value (`road_value_1112`) | `tb/places`, flag-off; `PLACES-ROADVALUE/` | **On the GPU queue**, two overlays (with and without puddles). Not judged. |

### LANE IS WRAPPED. Final state (12 Nov 2026)
- **Road value (no puddles) was judged: do not land alone** (`G-places-roadvalue.md`, tb/item-scout-1108 4061fd99). F41#12 6.01 → 6.44, F41#5 5.78 → 6.17, F41#2 6.09 → 6.40, F41#8 6.01 → 6.25, each 3/3. F41#4 loses twice (−0.23 at 0/3, then −0.09 at 0/3 with one tie): the gold path line loses contrast on the lighter road; judges praise the road itself. Every gain is under 0.5, so it does not stand alone (owner, 25 Oct).
- **No landing is cut, and under the wrap-up no new arm is started.** `road_value_1112` stays flag-off on `tb/places` (two files: `scripts/world/stormwood_ground_zones.gd`, `data/config/stormwood_ground_finish.json`). Coordinator's call: carry it flag-off to main for the next Stormwood swing, or drop it so the branch has nothing ahead but reports.
- **To finish it later (LANE-SCOUT's list):** restore the gold line's contrast on the umber road (more emission or a dark edge), then ride the road inside a bigger Stormwood swing: layered treeline and depth steps, groves in place of even turf, recolour the salmon stumps and peach bears, glow and branching on the road charge, separate Calm from Building. Puddles stay parked.

### Road value update (12 Nov, from the GPU lane via the coordinator)
- **Puddles are parked.** The puddle overlay failed the GPU pre-check (lilac and white slabs on the road at 5 stands) and was not judged; CPU round 1 showed the same. Two failures on one approach, so `road_value_1112` now carries puddles off by default (`puddle` [0, 0]), the same values as `overlay_no_puddles.json`.
- **The no-puddles arm passed the pre-check** (umber wet road, no slabs) and is with LANE-SCOUT. If it ships: cut the landing from current main with `road_value_1112` ON and puddles off. If it does not ship, the lane is done.

### Not on main that should be
- `tb/places-raintime-land` (PR #915): the rain flag ON, its pin and READY.md. Judged win.
- Nothing else is a judged win. The lane NOTE and the arm folders (`PLACES/`, `PLACES-ROADVALUE/`, `PLACES-RAINTIME/READY.md`) are records only.

### On `tb/places` only, flag-off and unjudged (listed, not for main unless judged)
- `road_value_1112`: `scripts/world/stormwood_ground_zones.gd` (puddle uniforms, `blend_sharpness`, candidate list) and `data/config/stormwood_ground_finish.json`. Inert while OFF. If it loses, drop both files' changes; `tb/places` then has nothing ahead of main but reports.

### Open candidates (not started)
- Stormwood: brighten and clear Fading (judges: too close to Building); fix the F41#19 stand (a trunk fills half the frame, the trainer clips into the cluster).
- Cloudreach F40#0: gate cobbles as large as the trainer's torso, burying the trainer to the shins; flat single-green ground and flat grey fog. New art for BELOW6: overlook slab walls, black sky islands, billboard cloud slab.
- P4 dark dawn and night foregrounds, P5 Tidewake dunes, P3, P6, P7 grass-clear radius.

### What worked
- Finding the cause before tuning: shafts culled away from the origin; weather presets being absolute colours.
- Sending to the GPU early with a variant overlay instead of more CPU rounds. CPU Low cannot rank glow, fog or puddles.
- Checking older tests with the flag ON before landing (the F10#3 lightning rule surfaced that way).

### What did not
- Mirror puddles on the road read as lilac slabs on CPU (round 1). Cut to small satin patches, unverified.
- Mist banks and sky layering alone were level on F41#4, #5, #12, #19: the ground holds those rows.

## Status, 12 Nov 2026
- **JUDGED, landing cut:** P2 Cloudreach rain SHIPS (`G-places-raintime`: all 12 rain sets 3/3, mean +0.70; night up to +1.50). Landing branch `tb/places-raintime-land` (d0e0b9c0, from main 328c598a): flag ON with `_why_on`, pin updated, `PLACES-RAINTIME/READY.md` (STATUS: land). 413 tests pass.
- **Storm light landed** in #914. `tb/places` now carries main 328c598a's tree (taken in as one ordinary commit, because the shallow clone cannot merge) with the unlanded road-value work on top.
- **One arm on the GPU now:** `PLACES-ROADVALUE` (two overlays).
- **F40#0 next (judges):** gate cobbles as large as the trainer's torso that bury the trainer to the shins (scene, mine); flat single-green ground and flat grey fog. Overlook slab walls, black sky islands and the billboard cloud slab are new art (BELOW6/MESHY).
- **JUDGED, landing cut:** P1 storm light SHIPS (`G-places-stormlight`, F41#2 +0.80, F41#8 +0.58, F41#13 +0.23; others level). Landing branch `tb/places-stormlight-land` (41a70edb, from main 4e35bfbd): both flags ON with `_why_on`, pinning tests, `PLACES-STORMLIGHT/READY.md` (STATUS: land). 628 Stormwood, surge and villager tests pass with the flags ON.
- **For the coordinator to accept or strip:** the older F10#3 test "only Break shows sky lightning" now allows Building's faint far-horizon bolts (part of the judged frames). Details in READY.md.
- **Owner decision (via coordinator, 12 Nov): no far bolts in Building.** Lightning stays the Break-only danger cue. The coordinator set `far_bolts` 0 and restored the F10#3 test on the landing (PR #914). Do not re-add.
- **Sent to GPU (arm 2 of 2):** `PLACES-ROADVALUE/` (road_value_1112: lifted wet road, softer blend, lifted pools; two overlays, with and without puddles). Rows F41#12, #4, #5, #8, #2. CPU round 1 showed mirror puddles as lilac slabs; they are cut to small satin patches, unverified in frames.
- **One arm on the GPU:** P2 `PLACES-RAINTIME` (Cloudreach rain time grade, F40#0 and F40#19).
- **Next swing (judges' shared ceiling):** Stormwood ground and road value: wet dark-umber road with puddle highlights and blended edges instead of near-black mud with cut-out edges; brighten and clear Fading; fix the F41#19 stand. Then P4, P5.
- **Housekeeping:** an early commit on this branch swept in unrelated generated `.uid` files; they are left out of the landing branch.

## Status, 11 Nov 2026 (superseded above)
- **Sent to GPU (arm 1 of 2):** `PLACES-STORMLIGHT/ARM.md` + `CAPTURE.json` + `overlay.json`. P1 Stormwood storm light: `storm_phase_1111` (layered storm sky, held white-violet bolts with a bolt key light, far bolts in Building, mist banks, shafts un-culled) with `distinct_bodies_1111` riding for F41#8. Rows F41#2, #4, #5, #12, #19, #8; riders #6, #13. All code is flag-off on the branch.
- **Sent to GPU (arm 2 of 2):** `PLACES-RAINTIME/ARM.md` + `CAPTURE.json` + `overlay.json`. P2 Cloudreach `rain_time_grade`: rain sky, cloud and fog follow the clock (night rain is night), golden hour keeps warm light, streaks fine and translucent. Rows F40#0, F40#19. CPU: 23:00 and 18:00 rain at the Realm Gate, clear change on both.
- **Two arms are waiting on the GPU, so no third is sent until one is judged.** Building next arms flag-off meanwhile.
- **Next:** P4 dark dawn and night foregrounds, P5 Tidewake dunes, P3, P6, P7 (grass-clear radius).

## Findings worth keeping
- **Stormwood light shafts never drew away from the world origin.** `stormwood_storm_shafts.gd` sets a custom AABB centred on a node that stays at the origin, so the MultiMesh is culled along most of the route (it draws round Cinder Verge only). Judges kept saying "no shafts" after `storm_sky_1101` shipped them. The fix (`shafts.follow_camera`) is inside `storm_phase_1111`.
- **Stormwood Break already shows crawler veins and bolts on main at Cinder Verge** (CPU). The phases differ in the sky but not on the ground, which is what the bolt key light addresses.
- **The "black pools" in F41#8 frames are the dark wet path** filling the lower half of the settlement stands, not the zone pools. Lighter wet earth lost on GPU (swing-1), so this arm leaves it.
- **Cloudreach weather presets are absolute colours** (`world_look.gd _layer_weather`): any weather sky replaces the night or golden sky outright. That is the cause of "night rain reads as day".

## Runbook additions
- Stormwood matrix screening: `.artifacts/places/cap_matrix.sh` pattern (flip the flag, run `capture_stormwood_f10_matrix.gd --stands=… --phases=calm,building,break --no-aftermath`, restore the config). Break frames wait up to 150 fine frames for a bolt; under giant trees on CPU that is about 10 minutes a frame, so screen Break at the open stands.
- `quick_judge.py capture <row> --overlay <file>` gives base and arm frames for a row under `.artifacts/qj/cache/<tree>/{base,<overlay>}/`; untracked new files do not change the cache key, tracked edits do.
- Write scratch frames under `.artifacts/`, not `ralph/reports/VISUAL/` (that path is not ignored).
- **New runtime 3D texture sidecars (from the coordinator, 12 Nov):** PR #914 failed `test_texture_import_policy` because `meshy_f41_8_bryn_albedo.png.import` was `compress/mode=0` (the coordinator fixed it on the PR). Before a landing, run `tools/art_pipeline/texture_import_policy.py --check` on every new texture sidecar; `--apply` skips untracked files, so set the sidecar by hand (mode 2 plus the s3tc path and metadata) and re-check.
