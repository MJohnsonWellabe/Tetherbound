# FLOOR2-STORMGLOW: storm creatures glow on lines and eyes, not the whole body (F41#13 P2-044)

**Ask:** GPU High, base vs arm, `CAPTURE.json`, on the landed round 3 creature stage. Config only: one overlay on two config files, no code, no assets.

## What the judges said (G-stage-r3-f41-13-f39-6, 3/3)
- The stormraven "blooms to a near-white ghost" at close range and loses its feather detail.
- The fulgocobra's bands bloom into white-hot spots or amber "light bulbs".
- Owner's creature rule (1 Nov): mostly real feathers, fur or scales with ONE elemental trait, glowing eyes plus glowing lines, veins or markings. No full-body glow.

## Reference check (coordinator ask: confirm colours before recolouring anything)
Both references agree with the roster board, so **no recolour is needed**:
- Stormraven: `assets/creatures/tetherbound/stormraven/reference/` (front, side) and the remake's `candidate_owner1101/source/ref_a.png` show a black / blue-black raven with thin blue lightning lines and glowing eyes.
- Fulgocobra: `fulgocobra/reference/front.png` shows black with gold lightning cracks; the remake's `ref_b.png` shows black with gold bands and blue hood lines.
The in-game near-white raven is a finish stacking fault, not the model's colours.

## Cause (measured)
`creature_surface_finishes.json charged_1105` (ON since batch 25; its own `_why_on` records the judges' next ask as "lines or veins on the animal instead of a whole-body wash"):
- **Stormraven:** it widened the accent mask to blue hue, saturation ≥ 0.12, value ≥ 0.18, and set the accent to full value at energy 1.6. On the raven's value-lifted albedo that mask matches **94%** of the feather texture (the species' own mask, saturation ≥ 0.3 and value ≥ 0.52, matches 2%), so the whole body emits pale cyan. It is a white bird even on CPU, with no bloom at all.
- The raven's real trait is its glow map (`creatures_ralph_stormraven_charge`, lines and eyes, 5% of the texture), which the wash buries.
- **Fulgocobra:** the same flag takes every gold band pixel (value ≥ 0.32) to energy 1.4, over three times the species' base 0.42, on top of the gold-vein glow map at 2.0 (10% of the texture).

## Change (overlay `overlay_lines_not_wash.json`)
| Key | Live | Arm |
|---|---|---|
| `charged_1105.species.stormraven` accent_energy / accent_value | 1.6 / 1.0 | 0.4 / 0.82 |
| … accent_source_value / accent_source_saturation | 0.18 / 0.12 | 0.52 / 0.3 (the species' own mask) |
| … rim_amount | 0.4 | 0.25 |
| `charged_1105.species.fulgocobra` accent_energy / accent_source_value | 1.4 / 0.32 | 0.46 / 0.44 (the species' own mask) |
| … rim_amount | 0.45 | 0.3 |
| `creature_coat_flags` `creatures_ralph_fulgocobra_goldvein` and `lanekit_face_read_fulgocobra` emission_energy | 2.0 | 1.3 |

The raven's line-and-eye glow map stays at 2.6. Accents stay just above the species' base (0.36 / 0.42), so `charged_1105` still "glows brighter" as its test requires.

## CPU proof (llvmpipe, Compatibility, 1920×1080, round 3 stage)
`_sheet_cpu_base_vs_arm.jpg`: stormraven, fulgocobra, sparkit idle; base above, arm below.
- **Stormraven:** base is a flat white silhouette. Arm is a blue-black raven with feather detail, a glowing eye and pale-lit feather edges.
- **Fulgocobra:** base bands are washed near-white; arm bands are gold with their scale pattern, hood lines and eye still lit.
- **Sparkit:** identical (control; it has no `charged_1105` row).
- The sheet was rendered with the accents at 0.36 / 0.42; the overlay as sent has 0.4 / 0.46 (see Tests). The difference is about a tenth on an accent that covers 2% of the texture and was not re-rendered.
- CPU has no bloom. The raven's glow-map lines at 2.6 and the cobra's veins at 1.3 will bloom on GPU High; whether they read as thin lines or still as "light bulbs" is for the GPU.

## Risks
- G-f41-13-charged scored the wash +0.61 over no finish (5.53 → 6.14) on the OLD stage, where the subject stood 7 m beyond the trainer and a brighter body helped it read. On the new stage the same wash is the named defect. The arm could still lose some distance read in fight frames.
- The cobra's head is pale lilac in both arms (the face-read albedo lift), unchanged here.
- The raven is dark again, so "dark creatures merge into the ground" (a Medium judges' note on other species) could apply; its rim stays at 0.25.

## Tests
- `stormwood_charged_finish`, `creature_coat`, `surface_finish` with the overlay OFF and ON: 8 tests, 768 assertions, 0 failed each.
- A first version set the accents exactly equal to the species' base and failed `test_charged_finish_lifts_only_the_storm_species` ("glows brighter"); the values were raised to 0.4 / 0.46 rather than touching the test.

## Expected gain
More than 0.5 on F41#13: the named defect on both species is the wash this removes.
