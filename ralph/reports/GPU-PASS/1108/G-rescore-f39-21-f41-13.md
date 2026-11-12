# G-rescore-f39-21-f41-13: one-sided re-score on current main (F39#21, F41#13)

Frames: `tb/gpu-frames-1108` 4c295499a, High, seed 2042, main 306239e9f, no overlay.
- **F39#21:** Venn win, Venn aftermath and Nerissa win frames (job ids map to the untimed source files, per the manifest). This comes after the hero card #876.
- **F41#13:** fulgocobra and stormraven idles, after charged_1105.

**GPU lane's flag:** in the Nerissa win frame the camera sits inside translucent crystal or building geometry. Scored as is.

## Judged
Batch `G-res2`:
- Three code-blind judges and the standard prompt. The sets are one-sided, with each raw score the mean of the identical halves.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.5883, intercept −2.651, r 0.916, anchor RMSE 0.462. No warnings.

| Row | Mapped | Raw (per judge) | Mapped (per judge) | Recorded defect |
|---|---|---|---|---|
| **F39#21** named-fight victory hierarchy | **4.34** | 4.3, 4.6, 4.3 | 4.18, 4.66, 4.18 | PRESENT 2/3, PARTIAL 1/3 |
| **F41#13** electric creature finish | **5.00** | 4.95, 4.7, 4.8 | 5.21, 4.81, 4.97 | PARTIAL 3/3 (one judge PRESENT on one half) |

Neither row closes. Both are below 6, so both sit in the owner's first tier (raise everything to 6 first).

## F39#21: what the judges saw
- **The Nerissa win frame is unusable.** All three describe a camera "inside grey translucent slab and crystal geometry", a "washed-out haze" in which "the reward panel floats over nothing". This frame alone drags the row down. The camera fix comes before any look work.
- **The reward panel is too small.** In the Venn frames it is a small plain text box at top centre ("Officer Venn defeated / 110 Coin, 1 Revive"), with no reward icons, gold emphasis or framing of the beaten officer, and the fighters are tiny on a flat dune.
- **The roster and hotbar are gone,** which is the #876 effect and counts as progress. The health and food block and the "Put Bramblebun away" prompt are still up.
- **Asks from all three judges:**
  - hide the exploration HUD during the reward;
  - make the reward panel a larger warm-gold card with reward icons;
  - frame the defeated trainer;
  - keep the camera out of geometry.
- **Other:** one judge notes untextured, stretched cliff faces at the right of the Venn frames.

## F41#13: what the judges saw
- **Fulgocobra** reads as "a dark navy coil with pale yellow bands" whose charged material "barely separates" at this distance.
- **Stormraven** reads as "a blown-out blue-white glowing silhouette … an emissive ghost rather than a black raven with lightning in its feathers", with no feather or face detail. Its value is close to the rain streaks.
- **Framing:** both creatures are small, behind the trainer and the companion. Two judges question whether they read as taller than the trainer at this framing. The warm Meadows-style cottage pulls the eye away.
- **Asks, matching the 1 Nov creature rule:**
  - Stormraven: cut the emissive to feather edges, glowing eyes and lightning lines.
  - Fulgocobra: crisp arc veins and lit eyes.
  - Add a rim light, and frame the creature as the subject.
