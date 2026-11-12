# CLUSTERS-6TO7: the 6.0–6.99 band split into THINGS and PLACES, grouped by shared named cause

LANE-SCOUT, 11 Nov 2026, for LANE-THINGS and LANE-PLACES. Read-only. This updates `LOW-HANGING-6TO7.md` (10 Nov board) with today's GPU High re-scores:
- `G-rescore-tier2-batch-1.md` and `-batch-2.md`: dialogue rows plus 19 pose rows;
- `G-f40-0-skyroad-arch-recapture.md`;
- `G-floor2-camp-r2.md`;
- `G-meshy-f41-8-distinct-bodies.md`;
- `STORMWOOD-LIGHT-ASKS.md`.

"Shares" counts the rows in the group. Gains are estimates from comparable judged arms.

## What moved today
- **Closed:** F36#72 Stormbrush (High 7.68, Medium 7.75).
- **Out of the band, upward:** reedwing 7.26, cannonback 7.21, F39#18 7.06, skyrill 7.47 (close-out exception).
- **Out of the band, now below 6 (hand to LANE-BELOW6):**
  - voltarach 5.11;
  - water mirejaw 5.52;
  - abyssal guardian 5.54;
  - ribbonray 5.68;
  - water mosshell 5.81;
  - water abyssal guardian 5.85.
  All are remakes that regressed.
- **Still in the band, re-scored:** cragclaw 6.94, water cragclaw 6.92, glimmermoth 6.90, galewisp 6.88, tempestwing 6.84, fulgocobra 6.78, veridian 6.33, water mangrove monitor 6.26, mangrove monitor 6.25. F38#32 camp is 6.91 with r2 landed.
- **F40#0 over all 384 frames: 6.54** (was 6.58 from 352). The 10 Nov sample under-weights rain: half the matrix is rain, but the sample had 1 rain sheet in 7.
- **Dialogue rows on main:**
  - F39#18 7.06, F39#26 6.49, F39#29 6.41, F39#27 6.16;
  - the speaker look is fixed by the soft rim;
  - the coordinator reports a dialogue blend fault, so a full dialogue re-capture is due once that fix lands.

## THINGS (creatures, characters, poses, UI, dialogue)

| # | Shared cause (judges' words) | Rows (latest) | Fix type | Est. gain |
|---|---|---|---|---|
| T1 | **The faint does not ground.** Neck, hood, sail, wings or antlers stay up, or the body sits up "like a frog". | glimmermoth 6.90, fulgocobra 6.78, veridian 6.33, water mangrove monitor 6.26, cragclaw 6.94, water cragclaw 6.92, tempestwing 6.84 (stiff wing fan); plus skyrill 7.47 and cannonback 7.21 (rigid roll) near the bar; plus 4 below-6 rows | pose data / faint clip (one pass) | +0.3–0.6 each; would likely close skyrill |
| T2 | **Tail around the trainer on the pose stage.** "Trainer inside the tail coil." | mangrove monitor 6.25 (3/3 every frame), water mangrove monitor 6.26, stormbrush (closed, PARTIAL) | capture-stand spacing or tail pose | +0.4 |
| T3 | **Travel poses broken.** "Carry carries nothing"; rider "doll-sized". | galewisp 6.88 (fly-grip 3/3), veridian 6.33 (tiny rider 3/3); water mosshell's ride (below 6) is with NEWAPPROACH | pose data / attach | +0.3–0.5 |
| T4 | **Not yet re-scored since the 1 Nov remakes.** Old meshes. | sparkit 6.03 (CPU), riftfrill 6.04, shadelet 6.06, pebbik 6.07 (CPU), mirejaw 6.23, thundertunnel 6.47, paddlenewt 6.49, mosshock 6.55 (CPU), brooktail 6.63, trailpup 6.64, solmane 6.68, cliffspike 6.72, voltwig 6.79, stormtrail 6.82, duskhush 6.85, breezetail 6.89, stormraven 6.94 (CPU), ashtusk 6.96 | re-score only (two batches) | ±0.8 per row; mean −0.15 so far |
| T5 | **F36 (0) model rows.** | Mirejaw 6.13, Galewisp 6.33, Riverdrake 6.60, Veridian 6.63, Terrapup 6.69, Abyssal Guardian 6.73, Cannonback 6.73, Fulgocobra 6.77, grunt family 6.84, Voltarach 6.97 | re-score first; abyssal and voltarach remakes regressed (new_art) | unknown |
| T6 | **Conversation shot.** Player shoulder fills the left; speaker small or behind the panel. | F39#26 6.49, F39#29 6.41, F38#36 6.26, F38#16 6.75, F40#10 6.74, F40#12 6.95 (and F39#18 7.06) | config (`camera.json` conversation camera), with NEWAPPROACH | +0.3–0.5 |
| T7 | **Portrait and speaker mismatches.** | F39#26 (Adair shows Iona), F39#18 (Bex and Irva share one), F39#29 (Nerissa reads as a bearded man, 1/3) | data | +0.2 each; ride along |
| T8 | **Flat white fight dust and smoke** bury the fighters. | F38#3 6.49, F38#11 6.89, F41#3 6.23 | config / VFX | +0.3–0.5 |
| T9 | **Toy pickups**: oversized, saturated caps, candy and potions. | F38#6 6.10, F40#16 6.19, F40#17 6.08, F41#14 6.35 | config (scale and saturation) | +0.3–0.5 |
| T10 | **Small UI bugs.** | F40#13 6.19 (stale "broke free"), F38#22 6.10 (broken "TRAIL CAMP" glyph), F38#10 6.58 and F38#38 6.49 (panel rows) | code / UI | +0.3–0.8 |
| T11 | **NPC presentation.** Speakers unlit, near-white, "glow against the scene"; idles and defeated slump. | F41#8 (5.72 arm, below 6), F38#35 6.31, F38#29 6.05, F41#18 6.10, F41#20 6.99 (Fenn's face blooms) | rim light / grade (scene); idles are new_art | +0.3 |

## PLACES (world, terrain, light, weather)

| # | Shared cause | Rows (latest) | Fix type | Est. gain |
|---|---|---|---|---|
| P1 | **Stormwood storm light** (see `STORMWOOD-LIGHT-ASKS.md`): per-phase key light with white-violet bolts, a layered storm sky in place of the "flat lilac card", layered fog in place of the single purple fog wall, black pools lifted to dark pools with value. Lift, don't darken. Write to `light_pass_1101`. | F41#2 6.15, F41#4 6.50, F41#5 6.28, F41#12 6.41, F41#19 6.56, F41#6 6.80, F41#13 6.66; F41#8 rides along | shared scene / config | +0.3–0.6 each |
| P2 | **Rain rendered as thick white overlay streaks**; night rain reads as day; golden-hour rain loses the golden light. | F40#0 6.54 (half the matrix is rain), F41#12, F41#13, F39 rain frames | shared weather config | +0.4 on rain frames; F40#0 most |
| P3 | **Empty plateaus without biome identity**: "generator test pad", no cloud sea or sky islands; lawn discs with extruded rims. | F40#0 6.54, F40#4 6.12, F40#7 6.26, F40#6 6.33, F40#11 6.97 (cloud sea), F40#2 aviary 6.15 | scene, with new_art for the landmarks | +0.3–0.5 |
| P4 | **Dark foregrounds at dawn and night.** The trainer sinks in; the ground crushes. | F40#0 (dawn and night sheets), F39#30 6.70 | grade (scene) | +0.3 |
| P5 | **Bare Tidewake dunes near characters.** Evenly scattered tufts, flat-lit sand, no clumps. | F39#27 6.16, F39#26, F39#29, F39#17 6.27, F39#14 6.37, F39#15 6.27 | scene dressing | +0.3–0.4 |
| P6 | **Smeared Meadows ground and wall textures.** | F38#20 6.02, F38#22 6.10, F04#6 6.50 (aftermath sites), F38#30 6.02 | material resolution (scene) | +0.3 |
| P7 | **Camp props.** Flat flame card, grass swallowing prop bases, floating planks. | F38#32 6.91 (r2), F39#13 6.23 (black square sprites), F39#12 6.80 | new_art fire, plus a grass-clear radius | +0.3–0.5 |
| P8 | **Landmarks needing new art** (to BELOW6/MESHY if they stay low). | F39#2 Veilfall 6.48, F39#3 6.10, F41#10 Glass Sink 6.02, F40#2 6.15, F38#20 6.02 | new_art | +0.5–1.0 |

## Suggested starts
1. **THINGS:** T1 faint grounding (FLOOR2, already queued) and T4 re-score (no code). Then T6 conversation shot with T7 portraits riding along.
2. **PLACES:** P1 storm light, with P2 rain inside the same arm where Stormwood rain is in frame. Then P2 for F40#0 on its own.
3. **Parked; do not repeat:**
   - in-cloud sheet lightning;
   - line-only charge accents on F41#13;
   - fight-distance rim light;
   - the Glass Sink lip;
   - NPC emission-off and floor arms for Marrow;
   - the card-white edge cards on F40#11.
