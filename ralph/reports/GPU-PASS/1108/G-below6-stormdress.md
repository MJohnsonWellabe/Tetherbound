# G-below6-stormdress: cloth banners and aged split wood (F41#1, F41#15; GPU High)

## Verdict
**The arm passes the ship rule on all three sets, but every gain is under 0.5, so it rides along rather than landing alone.**
- Marrow frames: +0.48 (3/3).
- The split-facing frame: +0.47 (3/3).
- The F41#1 four-frame set: +0.10 (2/3, one tie).
- Nothing loses.
- **Before it rides,** pull the aged split wood off rose-pink toward neutral grey-brown.

## Frames and sides

**Frames:** `tb/gpu-frames-1108`, High, captured on `tb/below6` 61caaf5a9 on both sides with no import.

**Sides:**
- **base:** overlay off.
- **arm:** `BELOW6-STORMDRESS/overlay.json`, which sets `banner_cloth_1112` and `aged_heartwood_1112`. The log confirms both.
- 0 blank frames, 0 script errors.

| Section | Commit | Frames | Note | Mean difference | Pixels changed |
|---|---|---|---|---|---|
| `G-below6-stormdress-marrow` | b408f836f | the 2 Marrow `__dialogue` frames | `BELOW6-MARROW/overlay.json` is on **both** sides (#918 is still in CI). Only the split-wood face behind Marrow changes. Blend 1.000. | 1.8 | 4.4% |
| `G-below6-stormdress-f41-1` | 62e417920 | stormheart_tree and dynamo_core, approach and close | The new approach stand is on the tree. Banners show only in the close views. | 1.1 | 1.5% |
| `G-below6-stormdress-split` | d5fd5922b | one `--spot` frame from the old approach stand, facing the split | Base split face measures rgb 165,67,16 (hue 22°). The arm measures about 132,92,105 (hue 332°, sat 0.32), per the GPU lane. | 5.1 | 9.8% |

## Batch `G-sd`
- Three code-blind judges, standard prompt, three sets.
- Briefs and defects:
  - Marrow frames: F41#15's.
  - The four-frame set and the split frame: F41#1's.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.5815, intercept −2.9753, r 0.948, RMSE 0.441. No warnings.

## Results

| Set | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm |
|---|---|---|---|---|
| F41#15 Marrow dialogue (2 frames) | 5.0, 5.2, 5.2 → 5.14 | 5.3, 5.5, 5.5 → **5.62** | +0.48 | 3/3 |
| F41#1 split-facing frame | 4.3, 4.5, 4.3 → 3.93 | 4.5, 4.8, 4.7 → **4.40** | +0.47 | 3/3 |
| F41#1 approach and close (4 frames) | 6.0, 5.9, 6.2 → 6.57 | 6.1, 6.0, 6.2 → **6.67** | +0.10 | 2/3 (1 tie) |

**Why the arm wins**
- **Marrow frames (3/3):** base has "a jarring, oversaturated orange tree trunk at the left edge". Two judges say it "leans toward the reserved red family". The arm removes it.
- **Split frame (3/3):** base's "garish orange streaky surface" becomes pink on the arm. Judges call it "less loud" and "less jarring", but still "off-family" and "still a stretched-texture artefact".
- **Banners:** in the four-frame set, judge a says "B's banners are slightly better shaded". The banners appear only in the close views, so the set barely moves.

**On the GPU lane's red-family question:** no judge calls the arm's pink oxblood or Team Tether red. All three still read it as off-family pink, and they want it gone. Pulling it to a neutral grey-brown should remove the last complaint about this surface and keep it clear of the reserved red.

**Recorded defects**
- F41#15 obstruction: FIXED 3/3 on both sides. Marrow is unobstructed, and on both sides he is on the glow fix.
- F41#1 "ring with a hole": PARTIAL 3/3 on both sides in both sets. "It now reads as a trunk, but not as a living tree with a crown and core."
- The split frame "reads as a cliff of bark".

## What still holds F41#1 and F41#15 down (3/3)
1. **Stormheart crown and core.** The crown is cropped in the approach views. The split-facing frame is "a frame-filling bark wall" with no crown, no core and no sky. Judges ask for a branching crown mesh (new art) and a stand pulled back and up.
2. **Stormwood dialogue staging.** The deck is "flat, saturated pink-lilac planking". The sky is "smeared" and "blocky", and the water is flat. A white bloom halo remains on Marrow's head (2/3) and on the player.
3. **Stormheart materials.** The roots and bark are "smooth and rubbery, with a pinkish-brown cast". A black path with a thin yellow line runs across a flat green ground.

## Recommendation
1. Retune `aged_heartwood_1112` from rose-pink to neutral grey-brown.
2. Then let the stormdress overlay ride inside the next Stormwood swing (crown or stand, deck and sky regrade), or alongside #918 (the Marrow glow fix, +1.40).
3. The cloth banners are a safe ride-along. They are slightly better, with no downside.
