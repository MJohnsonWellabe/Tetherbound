# Stormwood rain thinning: config-only arm (F41 cross-row)

**Overlay:** `overlay_rain_thin.json`, a deep merge into `data/config/stormwood_surge.json` `presentation.soft_rain_1101.overlay.rain`.
**Capture:** live main vs arm at High, on rows whose frames carry rain:
- F41#11 (portrait identity: Rook, Lio, Maud)
- F41#17 (Crown Arch)
- F41#20 (dialogue reuse: Fenn, Oswin, Maud)
- F41#8 (named character silhouettes)

## Defect (GPU, repeated)

Rain renders as thick, opaque white bars or sticks crossing the characters (3/3 judges):
- G-occlusion-fade-off-wide: Nx, Vf and Iv.
- G-f41-8: Uv.
- G-confirm-75 and G-med-occl: F41#17, "oversized white rain spikes" and "needle-like streaks".

It appears on almost every Stormwood frame.

## Cause

The shipped `soft_rain_1101` overlay (ON 3 Nov, from a CPU judgement) widened the near streaks from 0.018 m to **0.07 m** and lengthened them to 1.15 m at alpha 0.3, relying on the streak shader's `soft_edge` to blur them. On the GPU frames those 7 cm streaks, nearest the lens, read as solid bars. The base `near_fade_m` [2.2, 4.5] still lets full-strength streaks sit about 4–5 m from the camera, which is exactly the dialogue and post-view subject distance.

## The arm

| Key (soft_rain_1101.overlay.rain) | Live | Arm |
|---|---|---|
| `streak_width_m` | 0.07 | 0.03 |
| `streak_length_m` | 1.15 | 1.4 (longer and thinner reads as motion, not sticks) |
| `alpha` | 0.3 | 0.2 |
| `scale_max` | 1.35 (base) | 1.1 |
| `near_fade_m` | [2.2, 4.5] (base) | [3.5, 7.0] (streaks fade out before the subject plane) |
| `far_layer.streak_width_m` / `alpha` | 0.045 / 0.15 | 0.025 / 0.12 |
| `curtain_layer.streak_width_m` / `alpha` | 0.14 / 0.1 | 0.08 / 0.08 |

Drop counts, lifetimes, colour, wind slant, roof and hollow masks and the phase `rain_amount` are unchanged, so rain still reads as heavy in Break. Presentation only.

**Risk:** rain could read as too faint in the Surge phase frames. If F41#2 is captured as well, it is the check for that.
