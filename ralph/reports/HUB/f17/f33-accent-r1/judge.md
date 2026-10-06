# Code-blind visual judgement — creature gear accent (f33-accent-r1)

Judged only from the four PNGs in this folder (row_day.png, row_night.png, close_day.png, close_night.png). No source code, tests or docs were read.

All frames show the creatures from behind (rear three-quarter, normal third-person camera). Creatures are numbered left to right.

## 1. Per image

### row_day.png (08:00, all five in frame)
- **C1:** No coloured band. Base brown fur, green-tinted shell plates, grey rump disc. Only the natural green moss on the shell. **Guess: ungeared.**
- **C2:** Broad translucent **yellow/gold** band across the hips and rump disc, plus a thin yellow line at the neck/shoulders behind the ears. **Guess: geared.**
- **C3:** Same layout in **teal/cyan**, slightly more saturated than C2. **Guess: geared.**
- **C4:** Same layout in **light/sky blue**. **Guess: geared.**
- **C5:** Same layout in **violet/lavender**. **Guess: geared.**

### row_night.png (23:00)
- **C1:** No band. It reads as the plain creature. **Guess: ungeared.**
- **C2:** The yellow band stays bright and is the clearest of the four. **Guess: geared.**
- **C3:** The band reads **mint/aqua**. Clearly visible. **Guess: geared.**
- **C4:** The band reads **very pale blue, close to white**. Visible, but it is the weakest hue at night and is close to C3. **Guess: geared.**
- **C5:** The band reads **pink/lilac**. Clearly visible. **Guess: geared.**

### close_day.png (closer, C1 mostly cropped at the left edge)
- **Leftmost partial (C1):** No band visible on the part in frame. **Guess: ungeared.**
- **Yellow (C2):** A wide translucent gold slab across the hip, with a thin gold line at the neck. **Guess: geared.**
- **Teal (C3):** Same, in teal. **Guess: geared.**
- **Blue (C4):** Same, in sky blue. **Guess: geared.**
- **Violet (C5):** Same, in violet. **Guess: geared.**
- At this range the band is plainly a flat horizontal tint. It cuts straight across the shell plates, the rump disc and the fur at one height. It does not follow the strap or seam shapes.

### close_night.png
- Same reading as close_day. Yellow, mint, pale blue and pink bands are all visible against the night-lit fur. Pale blue (C4) is close to white/frost and could be mistaken for moonlight sheen or snow.
- The leftmost partial creature has no band. **Guess: ungeared.**

## 2. Pass/fail on the criterion

> "Equipped gear shows on the creature as a trim or glow accent: at the normal camera, by day and at night, a geared creature is visibly distinguishable from an ungeared one, and different gear tiers are distinguishable from each other. No accent uses red or oxblood."

| Clause | Result | Note |
|---|---|---|
| Geared vs ungeared at the normal camera, by day | **Pass** | C1 is plainly bare and C2–C5 are plainly marked. |
| Geared vs ungeared at night | **Pass** | Every band survives the night grade. |
| Tiers distinguishable from each other, by day | **Pass** | Four distinct hues. |
| Tiers distinguishable from each other, at night | **Marginal pass** | Teal and pale blue converge toward mint and near-white. They can still be told apart side by side, less reliably alone. Nothing in the frames shows which tier ranks higher: hue is the only cue, with no brightness, width or glow progression. |
| Reads as a "trim or glow accent" | **Partial** | It is neither a trim that follows the gear nor a glow. It reads as a flat translucent colour slab sliced through the body at a fixed height. |
| No red or oxblood | **Pass** | The colours are yellow, teal, blue and violet. Violet drifts to pink at night but never to red or oxblood. |

## 3. Problems that would undermine the accent in play

1. **It reads as a texture or overlay glitch rather than gear.** The wide band is a horizontal, semi-transparent tint plane. It cuts through shell plates, the rump disc and fur alike, with no edge, strap shape or relation to a harness. The thin neck line separately floats as a ring. A player would more likely read it as a selection highlight, a debug volume or a z-fighting tint than as an equipped harness and charm.
2. **The tier order is invisible.** Four hues show that tiers differ, but nothing says which one is better.
3. **Night convergence.** Pale blue tends toward white/frost at night and sits close to the mint tier.
4. **The creature's identity is partly covered.** The wide band washes over the rump disc and shell pattern, the species' most recognisable rear features.
5. **It is only verified from behind.** No frame shows the side or front, so visibility from other angles is unproven.

**Single most effective fix:** Replace the wide body-slab tint with a narrow emissive trim that follows a real harness strap line (girth strap and neck collar), and drop the slab. Encode tier by emissive intensity plus hue, rising from a dim strap to a bright pulsing strap. A narrow edge that follows the surface reads as gear rather than a glitch, leaves the creature's markings visible and holds up at night because it is emissive. Capture a side-on frame as well.

## 4. Final verdict

**PARTIAL**: the ungeared creature is clearly distinguishable, the tiers are distinguishable by hue and no colour is red. The accent reads as a flat translucent tint slab rather than a trim or glow, the tier order is not legible and the teal and pale-blue tiers converge at night.
