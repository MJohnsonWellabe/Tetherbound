# G-scene-rosternames: F39#19 compact roster names (GPU High + Medium, base vs arm, + F38#38 control)

## Verdict: DO NOT SHIP. F39#7 loses at Medium (−1.19, 3/3). F39#19 is NOT CLOSED: arm 6.97 on both presets.

| Set | Base | Arm | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect (base → arm) |
|---|---|---|---|---|---|---|
| **F39#19 High** | 6.88 | 6.97 | +0.09 | 2/3 | 6.0→6.2, 6.1→6.4, 6.3→6.0 | FIXED → **PRESENT** 3/3 |
| **F39#19 Medium** | 6.88 | 6.97 | +0.09 | 2/3 | 6.0→6.2, 6.1→6.4, 6.3→6.0 | FIXED → **PRESENT** 3/3 |
| F39#7 High (no-loss) | 6.41 | 7.26 | +0.85 | 3/3 | 5.9→6.5, 5.9→6.5, 5.5→6.3 | a, c PARTIAL → PARTIAL; b PRESENT → PARTIAL |
| **F39#7 Medium (no-loss)** | 7.31 | **6.12** | **−1.19** | **0/3** | 6.4→5.6, 6.6→5.6, 6.4→5.4 | FIXED / PARTIAL → **PRESENT 3/3** |
| Control F38#38 (High \| Medium) | 7.98 | 7.98 | n/a | n/a | 6.9, 7.2, 6.9 | FIXED 3/3 |

All scores are mapped. The control reads 7.98 against 8.16 and 8.30, a normal panel.

## Why the arm fails
- **F39#7 loses at Medium (3/3).** The wider strip moves the fight camera, as the GPU lane disclosed: deterministic, 4 to 16 m at Medium.
  - With the new framing, the player trainer stands inside Ripplet's back in frames 2 and 3 (t-024 and t-025): "the trainer stands inside / merges into Ripplet's back".
  - At High the shift happens to help F39#7: sea-facing frames, actors on a diagonal. At Medium it breaks it.
  - That is a judged row losing, so the ship rule fails. Camera position should not depend on HUD width.
- **F39#19's own defect comes back on the arm (3/3).** In the t-003.02 stagger frame the named roster "fades to pale ghost text against the sand", the GPU lane's contrast note.
  - Base (icon-only rows on solid dark cells) stays opaque in every frame, so the defect is FIXED there. The judges note that base has no names, so you must recognise the portraits.
  - Two of three judges still slightly prefer the named arm. The row does not move past 7.0 on either side.

## Other things the judges see
- **Dark slab (3/3):** a large dark untextured cliff or sky wedge at the top of the Tidewake fight frames, on both sides.
- **Ripplet (judges b and c):** smooth and plasticky next to the style bar, with faint glow lines and a weak face at small size.
- **Pink sparkle (judge c):** a stray pink sparkle beside roster slot 1 in base frame 1.

## Next asks (LANE-SCENE)
1. **Decouple the fight camera from roster width.** Whatever drives the shift (screen-safe area, HUD occlusion margin), the camera must frame identically with either roster. That alone removes the F39#7 loss.
2. **Keep the named rows, but keep them opaque.** Use the base's solid dark cell backing in every combat state, including stagger and recovering. Never fade the roster. This is the F39#19 close route: names (2/3 prefer them) plus no fade (3/3).
3. **Texture or remove the dark untextured cliff wedge** over the Venn fight cameras. 3/3, and it costs both rows. Scene.
4. **Re-capture** at High and Medium with matched cameras, and close in one batch with the control.
