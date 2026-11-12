# G-newapproach-charge-lines: charge accent kept to scale and feather edges (F41#13; GPU High)

Frames: `tb/gpu-frames-1108` 395ccec66, High, seed 2042.
- base = `tb/newapproach` 7d54c3874, with charged_1105 as shipped.
- arm = base + `overlay_charge_lines.json`. charged_lines_1111 keeps the accent on the texture's own scale and feather lines, with lower glow and a stronger rim.

Sheets, base against arm:
- F41#13: fulgocobra idle above stormraven idle, full-size frames stacked. At half size each creature was only a few pixels tall.
- Control: sparkit idle, under the same brief. Sparkit is not in charged_lines_1111.

Render check:
- fulgocobra 0.66% of pixels changed;
- stormraven 1.24%;
- sparkit 0.79% (sub-pixel noise; the judges saw it as identical).

Blank frames: 0 of 3 per side.

Batch `G-chl`:
- three code-blind judges, standard prompt, F41#13 brief;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22, so this is a confirming batch.

Fit: linear, slope 1.5444, intercept −2.7427, r 0.986, anchor RMSE 0.164. No warnings.

The coordinator asked for the judges to be told to say whether the raven marks read as feather edges or noise. That question was not added, because the standard prompt takes no hints. Their unprompted descriptions are quoted below.

## Verdict: DO NOT SHIP. F41#13 loses 0/3; the control is flat.

| Set | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F41#13 (fulgocobra, stormraven) | 6.11 | 5.49 | **−0.62** | **0/3** |
| Control (sparkit) | 5.19 | 5.24 | +0.05 | 0/3 prefer, 2 ties, 1 a +0.1 for the arm |

Raw Bar A, base → arm (judges a, b, c):
- F41#13: 5.8, 5.8, 5.6 → 5.4, 5.2, 5.4.
- Control: 5.3, 5.1, 5.0 → 5.3, 5.2, 5.0.

Recorded defect, base / arm:
- judge a: PARTIAL / PRESENT;
- judge b: FIXED / PARTIAL;
- judge c: PARTIAL / PARTIAL.

The base scores 6.11 here against the board's 5.14 (`G-recheck-1111.md`). That gap is scale scatter between batches; read the paired gain.

## Why the arm loses
- **Stormraven, arm: too dark, and the charge no longer reads.**
  - Judge a: "a dark saturated blue with almost no glow. It sinks against the dark ground, and only its silhouette and eye area read".
  - Judge b: "dark blue with faint flecks and sinks into the dark grass at 30% size".
  - Judge c: "a believable bird ... almost no charged contrast against the dark grass, and the eyes are not visible".
- **Feather edges or noise?** The marks register as faint feather edges or flecks, not as noise. Judge c: "faint pale feather edges". But at view distance they are too weak to read as charge.
- **Stormraven, base: overdone, but it reads.** All three judges call the base raven a blown-out white-blue aura or halo that "washes out the feather form, beak and eye". They still prefer it, because the charge is visible and it separates from the ground.
- **Fulgocobra:**
  - Judges a and b find the arm's bands "warmer and duller" and say the coil "merges into the dark grass".
  - Judge c sees no difference.
  - All three accept the base cobra's navy body with gold-white bands as reading clearly charged. Judge b notes it drifts from the board's olive body with gold veins.

## What the judges ask for
- **Target between the two sides:**
  - controlled emission on the eyes and feather-edge or vein lines, bright enough to read at view distance (blue or cyan on the raven, not pale white);
  - no full-body bloom;
  - a white-violet rim light to separate the dark bodies from the Stormwood ground.
- **All three judges name the Stormwood ground as the subject's drag on both sides:** posterised grass with black blotches, a flat black path slab, a flat lavender sky card, and a Meadows-style cottage.

## Parking
This is the first failure of the charge-lines approach on F41#13, so it is not parked. The judges point to a middle setting rather than a different technique: keep the line placement, raise the line and eye emission to a saturated blue, and keep the rim.
