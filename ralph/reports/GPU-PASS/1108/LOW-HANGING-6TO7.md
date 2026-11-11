# LOW-HANGING-6TO7: the 6.0–6.99 band, ranked by gain per effort

LANE-SCOUT, 11 Nov 2026, coordinator request. Read-only; no game files changed.

## Source and count
- **Board:** main 0058b0d6, `criteria.json` generated 10 Nov 17:37 UTC.
- **Rows in the band:** 112 of 231 visual rows sit at 6.00–6.99 on the latest score I rebuilt with `build_dashboard.py`, not the 135 in the request:
  - 37 F36 (1) poses and 10 F36 (0) models;
  - F38: 19; F39: 22; F40: 9; F41: 11;
  - 3 others: F04#6, F08#3 and F17#6.
- **Board scores already out of date** (GPU-PASS/1108 reports dated after 10 Nov):
  - **F38:** #5 has closed; #27 has closed (High 7.84, Medium 8.25); #31 is 7.20; #26 is 6.85; #8 is 7.14; #30 is 6.02.
  - **F39:** #6 is 7.79 High / 7.46 Medium; #30 is 6.70.
  - **F40:** #5 is 7.06; #8 is 6.77; #6 is 6.33; #11 is 6.97; #9 set-only is 6.48.
  - **F41:** #13 is 6.66; #9 is 6.81; #3 is 6.23.
- **Gains below:**
  - Gains are my estimates from the judges' named causes and from comparable arms already judged.
  - "Shares" counts the other rows in the band that have the same cause.

## The two suspected clusters
**(1) Creature pose rows were scored on the old, too-small stage before #901: REFUTED on the cause. A re-score is still worth doing.**
- **Wrong stage.** The F36 (1) rows were captured with `tools/art_pipeline/capture_f36_poses.gd --whole-body --context`. That stage fits the camera to each creature: distance = radius / tan(FOV/2), with a trainer ruler. #901's `creature_ruler_depth` only changed `tools/phase2_capture_creatures.gd`, which serves the biome creature rows (F38#5, #26, #31, F39#6).
- **The named causes are not size.** The 24 Oct roster verdict (`GPU-PASS/F36-1/roster-base-1e83cafa0/VERDICT.md`) names these per species:
  - materials that read as chrome, vinyl, flat or neon;
  - faint poses that stay upright or clip through the trainer;
  - dark values with no rim light.
  None of these is camera distance.
- **Why re-score anyway.** About 20 of the 37 pose rows date from that 24 Oct roster, before the owner's 1 Nov switch-on of all 49 remakes. So they score meshes the game no longer ships:
  - abyssal guardian, cannonback, cragclaw, fulgocobra, galewisp, glimmermoth, mangrove monitor;
  - reedwing, ribbonray, skyrill, stormbrush, tempestwing, veridian, voltarach;
  - the water_* variants.
  Most of the rest come from the CO8–CO16 batches (26 Oct–1 Nov). Three are CPU-only: Pebbik 6.07, Mosshock 6.55, Stormraven 6.94.
- **Expected gain is uncertain in both directions.** A remake can score lower than the mesh it replaced.

**(2) Dialogue foreground obstruction or framing across biomes: REFUTED as one cause. Two different causes are mixed together.**
- **(a) F39#18, F39#26, F39#27 and F39#29 were held down by ghost-white, translucent speakers.** The fix is already on main: `water_character_rim.json` soft rim (energy 0.3, power 3.5, fill 0).
  - One-sided GPU High on main plus soft rim (`G-confirm-f39-26.md`): F39#18 **7.07**, F39#26 **6.88**.
  - The board still shows 6.16 and 6.01, so those two only need a re-score.
- **(b) The remaining gap is the conversation shot itself.** The judges converge on a tighter shot: the speaker filling about half the frame height above the panel, with the player's shoulder pushed to the edge.
  - That one camera change is shared by F39#18, F39#26, F38#36 speaker occlusion 6.26, F38#16 tournament subject 6.75, F40#10 foreground composition 6.74, and F40#12 6.95 (near the bar).
  - **F38#37 (6.75):** the rock obstruction was a separate cause and is already fixed (4.64 → 6.75 on High).
- **F41#15 is 5.71, below this band, and has a separate cause.** Captain Marrow's head blooms to white. Two arm families have failed on it:
  - lowering the key light, and turning NPC emission off: 0.00;
  - the NPC floor arms: −0.14.
  Under the two-failure rule it is parked until there is a new idea. F41#20 (6.99, Fenn's face blooms) shares this cause.

## Ranked list (clusters first)
| # | Fix (type) | Rows (board score) | Shares | Est. gain | Effort |
|---|---|---|---|---|---|
| 1 | **Re-score Tidewake dialogue on main** (re-score only; soft rim already landed) | F39#18 6.16→7.07, F39#26 6.01→6.88 measured; F39#27 6.57, F39#29 6.61 (paired 6.43/6.53, so expect level) | 4 | +0.9 ×2 (measured) | one batch |
| 2 | **Re-score the remade creatures on the F36 pose stage** (capture-stand / re-score only) | ~20 pre-1-Nov pose rows (6.24–6.92); sample 6 first: Skyrill 6.33, Fulgocobra 6.38, Cragclaw 6.40, Glimmermoth 6.43, Ribbonray 6.48, Veridian 6.63 | 20 | +0.3 average, ±0.8 per row | 2–3 batches |
| 3 | **Tighter conversation shot** (config: `camera.json` conversation camera) | F39#18, F39#26 (after #1), F38#36 6.26, F38#16 6.75, F40#10 6.74, F40#12 6.95 | 6 | +0.3–0.5 each; would take F40#12 and probably F39#18 over 7.5 | one arm |
| 4 | **Thin or soften the flat white fight dust/smoke puffs** (config / VFX) | F38#3 6.49 and F38#11 6.89 ("puffs bury both fighters"); F41#3 6.23 (dust trail over Sparkit); F40#5 7.06 (dust over the exchange) | 4 | +0.3–0.5 each | one arm |
| 5 | **Stormwood storm-light pass**: phase key, white-violet bolts, layered fog in place of the flat purple wall (shared scene / lighting; named 3/3 judges) | F41#2 Surge phases 6.10 (phases differ only by rain), F41#5 6.06, F41#4 6.37, F41#12 6.60, F41#19 6.56, F41#6 6.80, F41#13 6.66 | 7 | +0.3–0.6 each | 1–2 arms; F41#13 glow lines already tried |
| 6 | **Tone down toy pickups**: scale and saturation of caps, candy and potions (config) | F38#6 6.10, F40#16 6.19, F40#17 6.08, F41#14 6.35 | 4 | +0.3–0.5 each | one arm |
| 7 | **Clear the stale "broke free" message when the chance plate shows** (small code fix) | F40#13 6.19 | 0 | +0.5–0.8 | small |
| 8 | **Single visible bugs** (scene / config) | F39#13 6.23 (black square sprites by the bench, 3/3); F38#22 6.10 (broken first glyph of "TRAIL CAMP", 3/3); F40#15 6.08 (dark strip still in the F40#8 bridge frames) | 0 each | +0.3–0.6 each | small each |
| 9 | **Capture stand shows no subject** (capture-stand only) | F39#22 6.19 (Aquaryn in no frame; defect FIXED 3/3) | 0 | +0.5 | small |
| 10 | **UI readability** (config / UI) | F38#10 menu panels 6.58; F38#38 6.49 | 2 | +0.3 each | medium |
| 11 | **Cloudreach terraces**: stratified ledges in place of lawn discs with extruded rims (scene; new art per 1 of 3 judges) | F40#4 6.12, F40#7 6.26 (plus F40#6 6.33 and F40#11 6.97, already on the cloud-sea arm) | 4 | +0.3–0.5 | medium-large |
| 12 | **Tidewake current payoff**: break up the identical oval sandbars, make the current readable (scene) | F39#17 6.27, F39#16 6.88, F39#14 6.37 (stamped foam wake), F39#15 6.27 (disc chain) | 4 | +0.3 | medium |
| 13 | **New art: landmarks** (Meshy) | F39#2 Veilfall 6.48, F39#3 6.10, F39#15; F41#10 Glass Sink 6.02; F40#2 aviary 6.15; F38#20 stronghold 6.02 | 2–3 per landmark | +0.5–1.0 | large |
| 14 | **New art: poses and idles** (Meshy / animation) | F38#35 NPC idles 6.31, F38#29 defeated slump 6.05, F39#5 swim legs 6.06, F38#2 hurt poses 6.00 | 2 | +0.5 | large |
| 15 | **New art: F36 (0) model rows** (Meshy) | Mirejaw 6.13, Galewisp 6.33, Riverdrake 6.60, Veridian 6.63, Terrapup 6.69, Abyssal Guardian 6.73, Cannonback 6.73, Fulgocobra 6.77, grunt family 6.84, Voltarach 6.97 | 10 | unknown; re-score first, as in #2 | large |

## Recommended order
1. **Run #1 and #2 together** as one GPU re-score batch on main, with no code change.
   - #1 is a measured +1.8 total.
   - #2 tests whether the remakes moved the pose band. Judge the sample of 6 first, then decide whether to re-score all 20.
2. **Ship #3, #4 and #6 as config-flag arms in one tree,** so one GPU import judges all three.
3. **Put #7, #8 and #9 under the close-out exception.** They are small fixes, so they ride inside the #3/#4/#6 arms rather than standing alone.
4. **Give the big floor-raising swing to #5,** the Stormwood storm light: 7 rows share it, and it is a scene change.
5. **Leave #13–#15 for the Meshy lane.**

## Update, 11 Nov evening: today's re-scores
See `CLUSTERS-6TO7.md` for the THINGS/PLACES split. The rows above that changed:

**#1, Tidewake dialogue re-score:** done (`G-rescore-tier2-batch-1.md`).
- F39#18 7.06, F39#26 6.49, F39#29 6.41, F39#27 6.16.
- The coordinator reports a dialogue blend fault. Re-capture all dialogue once the fix lands.

**#2, pose re-score:** 19 rows done (batches 1 and 2). The mean change is −0.15.
- **Up:**
  - stormbrush, **closed** (7.68 High, 7.75 Medium);
  - skyrill 7.47;
  - reedwing 7.26;
  - cannonback 7.21;
  - cragclaw 6.94;
  - water cragclaw 6.92.
- **Down, now below 6:** voltarach 5.11, water mirejaw 5.52, abyssal guardian 5.54, ribbonray 5.68, water mosshell 5.81, water abyssal guardian 5.85.
- **Shared cause:** ungrounded faints (10 of 19 rows), then broken travel poses and the tail around the trainer.
- **Still to re-score:** 18 pose rows (T4) and the 10 model rows.

**#11, Cloudreach:** F40#0 over all 384 frames is 6.54. The skyroad arch scored 6.05, with rain sheets at 5.45–5.74.

**#5, Stormwood:** see `STORMWOOD-LIGHT-ASKS.md`. A3 key light and groves are shipped; four approaches are parked.

**Other rows:**
- F38#32 camp r2 at 6.91 (passes; game frames level).
- F41#8 distinct bodies: +0.29, flag-off, to ride inside the Stormwood light pass.
