# G-floor2-storm-glow-lines: glow in the species' lines and eyes, not a whole-body wash (F41#13; GPU High)

Frames: `tb/gpu-frames-1108` b95706464, High, seed 2042, `tb/floor2` 8c831ccd4.
- The creature stage (`creature_ruler_depth`, #901) is ON on both sides.
- Capture: `phase2_capture_creatures.gd --biome=stormwood --only=stormraven,fulgocobra,sparkit --poses=idle,hurt`.
- base = tree as is (charged_1105).
- arm = base + `FLOOR2-STORMGLOW/overlay_lines_not_wash.json`:
  - stormraven: accent_energy 1.6 → 0.4, accent_source_value 0.18 → 0.52, rim 0.4 → 0.25;
  - fulgocobra: accent_energy 1.4 → 0.46, coat emission_energy 2.0 → 1.3.
- GPU lane pre-check: raven near-white pixels fall from 12.8% to 1.2% (idle), with no red.

Sets, on F41#13's brief and recorded defect, as in `G-stage-r3-f41-13-f39-6.md`. Each is stacked at full size.

| Set | Frames | Role |
|---|---|---|
| Arm | fulgocobra idle above stormraven idle | the change |
| Hurt | fulgocobra hurt above stormraven hurt | no-loss |
| Control | sparkit idle | unchanged; sparkit is not in the overlay |

Render check: 2.7–3.8% of pixels changed on the cobra and raven frames, 0.7–0.8% on sparkit (noise). Blank frames: 0 of 6 per side.

Batch `G-sg`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22, so this is a confirming batch.

Fit: linear, slope 1.3797, intercept −1.7131, r 0.959, anchor RMSE 0.281. No warnings.

## Verdict: SHIP. +0.64 on both creature sets, 3/3 on each, and the control is identical.

| Set | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| **F41#13 idle** (fulgocobra, stormraven) | 6.06 | **6.70** | **+0.64** | **3/3** |
| F41#13 hurt (no-loss) | 5.97 | 6.61 | +0.64 | 3/3 |
| Control (sparkit idle) | 6.61 | 6.61 | 0.00 | 3 ties |
| **F41#13 row (idle + hurt)** | 6.02 | **6.66** | **+0.64** | — |

Raw Bar A, base → arm (judges a, b, c):
- Idle: 5.8, 5.5, 5.6 → 6.2, 5.9, 6.2.
- Hurt: 5.8, 5.4, 5.5 → 6.2, 5.7, 6.2.
- Control: 6.2, 5.6, 6.3 on both sides.

Against the stage baseline: base on this stage was 6.46 in `G-stage-r3-f41-13-f39-6.md`, a different batch; 6.06 here. The arm takes F41#13 to 6.66–6.70. The board has 5.14.

Recorded defect: PARTIAL on both sides from all three judges on the creature sets. Base is blown out; the arm reads but is faint on the raven.

**This is a different approach from the parked charge-lines rounds** (`G-newapproach-charge-lines-r2.md`). Those confined the accent at far range and lost. This lowers the whole-body wash with the creature now staged near, and wins.

## What the judges see
- **Base, both creature sets (3/3):**
  - the stormraven is "a full-body white-blue glow ... an effect hull, not a bird", with face, eye and feathers lost;
  - the cobra's gold bands are "blown out into hot white blobs ... light sources, not markings".
  - This breaks the owner's one-elemental-trait rule.
- **Arm:**
  - the cobra's bands "keep their scale texture", with a glowing blue eye and a white-blue lightning edge on the hood;
  - the raven shows "fine white lightning veins" with readable eye and beak.
- **What remains on the arm (3/3):**
  - **Raven:** body a saturated royal or cobalt blue that reads "toy-like" or "plastic". The board shows a near-black raven with violet-blue charge. The veins are faint at view distance.
  - **Palette drift:** the cobra is navy where the board shows olive-black with gold veins.
  - **Hurt poses:** neither creature reads as hurt; the cobra stays fully upright.
  - **Stormwood staging:** the black path reads as a void, the purple sky is a flat painted band, and the cottage is over-warm orange.
  - **Sparkit (control):** no visible electric trait (no glowing eyes or lines), and its dark legs merge into the black ground. Not in this overlay.

Note on the control's recorded defect: it names Fulgocobra and Stormraven, but the control shows sparkit. All three judges said so and scored its charge as PRESENT on both sides. The tie is unaffected.

## What would add the most (all scene)
1. **Board colours:** a near-black stormraven with violet-blue rim light and arcs, and an olive-black fulgocobra with gold veins, with the emission kept at this arm's level.
2. **Sparkit:** give it the board's glowing eyes and fine lightning lines.
3. **Stormwood staging:**
   - lift the black path into reflective dark pools with value;
   - replace the flat sky band with a layered storm sky and lightning;
   - cool the cottage.
