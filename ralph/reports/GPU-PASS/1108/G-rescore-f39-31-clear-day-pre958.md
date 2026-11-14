# G-rescore-f39-31-clear-day-pre958: F39#31 Veilfall, first clear-day baseline (GPU High, one-sided, PRE-#958)

## Score: F39#31 clear day = 5.93 mapped (PRE-#958 baseline; the rain-rider read was 6.02)

| | Value |
|---|---|
| Raw a / b / c | 4.8, 5.55, 6.05 |
| Mapped per judge | 5.10, 6.04, 6.66 |
| Recorded defect | none recorded ("Veilfall reads at distance and up close") |

- **Label:** this is a PRE-#958 baseline. It lacks the Veilfall spray-mist fix, so use it as the before side for the post-#958 re-shoot.
- **Scatter:** the judges spread widely (5.1 to 6.7), so read the score as about 5.9 ± 0.6.
- **Fit:** linear, slope 1.248, intercept −0.890, r 0.912, anchor RMSE 0.57. No warnings.
- **Content:** tb/land-mt 5ef7e327e with lane code flag-off. High, frames veilfall-vista and veilfall-near.

## What the judges see (3/3)
- **Distance frame:**
  - The fall is "a blocky, pixelated white column with stepped or square tiling artefacts" down a "faceted low-poly rock" cone.
  - There is **no mist or spray at the base**.
  - Vegetation is almost absent (judge a).
  - The island silhouette, cyan and navy shallows and pale sand fit the Tidewake board.
- **Close frame:**
  - The fall is "a smooth white sheet / flat ribbon" over a beige terrain mass with "stretched striped texture".
  - It ends in a hard edge on sand: **no plunge pool, splash or foam**.
  - A rock cluster with a sapling seems to float on the sheet.
  - Dark untextured faces or a crevice void show on the left cliff.
- **Judge a (lowest):** the board's grey stratified stone, multiple tiers of falls, greenery and stronghold arch are all missing. It "reads as placeholder geometry".
- **Judge c:** the quest card and HUD crowd the top right of both frames.

## Next asks (LANE-LAND-MT)
1. **#958's mist and spray at the base** answers 3/3. Re-shoot the same two frames once it merges, and judge base (this) against post-#958 as an arm.
2. **Plunge pool and foam** where the fall meets the sand in the close frame, instead of a hard edge (3/3). Scene/VFX.
3. **Replace the blocky tiled fall texture** with an animated layered water material, and break up the faceted, stretch-striped rock with the stratified-stone material. new_art for a hero fall, scene for material.
4. **Fix the floating rock-and-sapling cluster** on the close sheet and the untextured faces on the left cliff. Scene.
