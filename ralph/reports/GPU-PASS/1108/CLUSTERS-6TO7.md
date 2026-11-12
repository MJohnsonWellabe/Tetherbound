# CLUSTERS-6TO7: the 6.0–6.99 band grouped by shared named cause

LANE-SCOUT, 12 Nov 2026. Read-only. This replaces the 11 Nov version.
- **Sources:**
  - the board: main b3dc2139, 104 rows in 6.0–6.99;
  - each row's job.json defect;
  - the causes judges named in tonight's GPU batches: stormrim, ruler re-score, speakercentre, wetpath, glidebank, Medium ashtusk/brooktail and toys-ui.
- **Re-score list for the GPU lane:** `RESCORE-6TO7.md`.

## How to read it
- **Rank** = rows touched × expected gain per row. The gain is estimated from comparable judged arms.
- **The pattern to copy.** Tonight's wins each came from one cause touching several rows:
  - Stormwood player rim off: 4 sets gained, F41#18 cleared 6.
  - Pose-stage ruler: 6 rows gained, 2 met the bar at High.
  - Wild-post clearance: F41#15 plus 3 dialogue sets.
  Single-row tweaks mostly came back level.
- **Lanes:**
  - **THINGS:** creatures, characters, dialogue, UI.
  - **PLACES:** world, light, weather.
  - **BELOW6:** pickups, catch, Cloudreach props.

## Ranked groups

| Rank | Group | Lane | Rows (board, or tonight's score) | Fix kind | Gain/row | Rows × gain |
|---|---|---|---|---|---|---|
| 1 | **P-GROUND: smeared ground material, flat grass carpet, even scatter.** Judges' words: "blurry, smeared ground", "uniform olive carpet", "grass reaches the waist around characters". Named 3/3 in wetpath, toys-ui (aftermath), glidebank and stormrim. | PLACES | F38#20 6.02, F38#22 6.10, F38#30 6.02, F38#26 6.85, F40#7 6.26, F40#21 6.68, F41#5 6.06, F41#4 6.37, F39#3 6.10, F39#27 6.16 | material resolution and filtering, grass clumping and clearings (scene) | +0.3 | **3.0** |
| 2 | **P-STORMSKY: flat lavender sky card, flat ground grade, no storm light in Stormwood.** Named 3/3 in stormrim and in the G-wp Stormwood fight sheet. | PLACES | F41#4 6.37, F41#5 6.06, F41#6 6.80, F41#12 6.60, F41#13 6.66, F41#19 6.56, F41#1 6.81, F41#22 6.96; dialogue rows F41#7, #11, #18 and #20 ride along | layered storm sky, depth fog, rim on characters (scene, `light_pass_1101`) | +0.35 | **2.8** |
| 3 | **T-DARKRIM: dark-bodied creatures with no rim light; glossy or near-black materials.** Named 3/3 in ruler-rescore and Medium ashtusk/brooktail. Five of these are already ≥7.0 at High, so this is the fastest closer. | THINGS | Ashtusk 7.28 Medium, Brooktail 7.03 Medium, Riftfrill 7.31, Mirejaw 7.26, Shadelet 7.07, Sparkit 7.26, F41#13 6.66 (fulgocobra, stormraven), Stormraven 6.37, Duskhush 6.53 | cool rim or back light plus a slight albedo lift on the pose stage and in the world (scene) | +0.3 | **2.7**, and could close 4–5 rows under the close-out exception |
| 4 | **T-CONVCONE: companion, trainer or props inside the line to the speaker.** speakercentre: Hess +1.16, Rae −1.60 when the companion filled the frame. | THINGS | F38#16 6.32, F38#17 6.97, F38#37 6.90, F39#26 6.94, F40#9 6.48, F40#10 6.77 | keep the companion and trainer out of the cone to the speaker (config), then speaker_centre per post | +0.4 | **2.4** |
| 5 | **T-UI: small text, low contrast, clipped labels.** | THINGS | F38#10 6.58, F38#19 6.89, F39#19 6.85, F39#23 6.80, F40#14 6.99 (label clipped), F41#16 6.28 (CPU arm 7.44) | code/UI; F40#14 is a wrap fix | +0.4 | **2.4**, with F40#14 likely closing |
| 6 | **P-WATER: Tidewake water depth, streaks and foam.** | PLACES | F39#10 6.30 (6.99 seen), F39#14 6.37, F39#16 6.88, F39#17 6.27, F39#15 6.27, F13#5 6.28 | water shader and foam (scene); re-score first, since G-exposure lifted F39#1, #2 and #10 to about 7 | +0.3 | **1.8** |
| 7 | **B-PICKUPS: pickups that read as toys or as one shape.** Parked: saturation tone_down (F38#6 −0.84, 0/3). | BELOW6 | F38#6 6.10, F40#16 6.19, F41#14 6.35, F38#12 6.06, F41#9 6.81 | distinct silhouette per item or tier (new_art or scale), not colour | +0.35 | **1.75** |
| 8 | **T-FIGHTSTAGE: actors overlap; ally fills the view.** | THINGS | F38#3 6.49 (7.11 seen), F39#7 6.61, F41#3 6.23, F39#22 6.19, F39#20 6.37 | fight camera spacing (config) | +0.3 | **1.5** |
| 9 | **T-IDENTITY: portrait, line or subject mismatch.** | THINGS | F38#16, F41#7 6.24, F41#11 6.91, F41#20 6.41, F41#18 rank trim | data | +0.3 | **1.5**, riding with T-CONVCONE |
| 10 | **B-CLOUDPROPS: floating and unfinished Cloudreach props.** | BELOW6 | F40#15 6.08, F40#17 6.08, F40#4 6.12, F40#11 6.97, F40#8 6.77 | ground the props, finish the undersides (scene or new_art) | +0.3 | **1.5** |
| 11 | **T-HUMANPOSE: same neutral stance; defeated NPCs stay upright.** | THINGS | F38#29 6.05, F38#35 6.31, F39#5 6.06, F40#6 6.33, F38#2 6.00, F38#1 6.58 | new animation (new_art); low gain per scene change | +0.25 | **1.5** |
| 12 | **B-CATCH: magenta ring, flat orb, catch camera and HUD.** ghost-glow arm reached 7.11 / 7.26 on two of three frames. | BELOW6 | F38#14 6.06, F39#9 6.65, F39#23 6.80 | VFX and camera config | +0.4 | **1.2** |
| 13 | **T-TELEGRAPH: flat magenta danger rings and slabs.** Named 3/3 in the G-wp Stormwood fight sheet. | THINGS | F38#11 6.89, F41#6 6.80 | physical effects (dust, stone, lightning) in place of flat rings (VFX) | +0.4 | **0.8** |
| 14 | **P-RAINTRAIL: wetpath follow-up.** The clear-weather tone wins (+0.6); the rain darkening overshoots at night. | PLACES | F40#0 6.54, F40#19 6.66 | trail tone with a rain floor (config) | +0.3 | **0.6** |

**Not a shared cause (one asset each, new art):**
- F39#2 Veilfall, F40#2 aviary, F41#10 Glass Sink, F41#1 Stormheart, F38#20 stronghold, F38#24 mountains, F39#15 shallows discs, F38#34 placed wall, F39#12 bed, F39#13 workbench, F38#32 camp props.
- Score each with its row; do not batch them as one arm.

## Top 3 per lane
- **THINGS:**
  1. T-DARKRIM: rim light and albedo lift, one arm across the pose stage and the world. It can close Ashtusk, Brooktail, Riftfrill, Mirejaw and Sparkit.
  2. T-CONVCONE: clear the cone, with T-IDENTITY data riding along.
  3. T-UI: F40#14 wrap first.
- **PLACES:**
  1. P-GROUND: ground material and grass clumping across Meadows, Cloudreach and Stormwood.
  2. P-STORMSKY: sky and fog for Stormwood. Stormrim already removed the character glare.
  3. P-WATER: re-score after G-exposure, then the water shader.
- **BELOW6:**
  1. B-PICKUPS: silhouettes, not saturation.
  2. B-CLOUDPROPS.
  3. B-CATCH: build on ghost-glow.

## Parked; do not repeat
- **Pickups:** saturation tone_down.
- **Stormwood:**
  - in-cloud sheet lightning;
  - line-only charge accents (F41#13);
  - fight-distance rim light;
  - trunk dither and occlusion fade (level).
- **Landmarks:** Glass Sink lip.
- **NPCs:**
  - NPC emission-off and floor arms (Marrow);
  - named-post lanterns (F41#8).
- **Cloudreach:** card-white edge cards (F40#11).
- **Conversations:** speaker_centre as one global arm. Ship it per post instead.
