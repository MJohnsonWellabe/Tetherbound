# G-rescore-f41-2-breakonly: F41#2 row score with the lightning confined to Break (GPU High)

## Score: F41#2 = 6.19 mapped
- **Raw scores (a, b, c):** 6.0, 5.6, 6.0.
- **Mapped per judge:** 6.36, 5.85, 6.36.
- **Board score:** 6.15. In this batch the row is level with it.
- **Recorded defect:** PARTIAL from all three judges.
- **Status:** the row is in the 6.0–6.99 band. It is not near the bar.

**Batch file note:** the one-sided set holds the same image on both sides, so `batch.json` lists each judge's score twice (once per side). The mean is unchanged.

## Frames
`tb/gpu-frames-1108` 76e698f09, High, one side, no arm.
- **Build:** a2ce48f7b, which is main 3b7d04b5e plus PR #919. #919 puts the lightning out when Break ends.
- **Capture:** `phase2_capture_storm_phases.gd` at the struck_sentinel close stand, phases calm, building, break and fading.
- **Pre-check:** passed. 0 blank, 0 script errors.
- **Sky brightness per phase (sky L, from the GPU lane):**

  | Phase | Sky L | Notes |
  |---|---|---|
  | Calm | 130 | |
  | Building | 109 | |
  | Break | 117 | bolts |
  | Fading | 129 | no bolt |

- **What this replaces:** the held swing2 storm set. That set's Fading bolt was carried over by capture timing (`G-fading-bolt-motion-probe`, a diagnostic that was not judged).

**Set:** four phases in a 2×2, with the order given in the brief. F41#2's brief and recorded defect.

**Batch `G-r2`:** three code-blind judges with the standard prompt. Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.

**Fit:** linear, slope 1.2844, intercept −1.3429, r 0.927, RMSE 0.521. No warnings.

## What the judges see (3/3)
- **Fading is now distinct:** "a pinker sky and low mist". No judge saw a bolt in Fading.
- **The phases still don't separate well enough:**
  - Calm and Building "differ mainly by an overall darkening" (judges a and b).
  - Judge c reads Calm and Break as "nearly the same frame". Break "does not land as the climax: no visible lightning strike on the subject, no flash or grade change".
- **Fading mist:** "white-pink blobs drifting at waist height" that "look like flat sprites more than fog" (3/3).
- **Ground and sky:** the ground is "a uniform flat green carpet with dark smudge decals", and the sky is "a painted-looking swirl" (3/3).
- **What works:** the glowing split tree, read as "the strongest storm landmark", and the purple sky, which matches Stormwood.

## Next for F41#2 (the judges' top changes, all scene)
1. **Make Break the climax:** a lightning strike on the tree, a white-violet flash grade and heavier sky motion.
2. **Separate Calm from Building:** Calm brighter and clearer with soft light shafts; Building colder, with rolling cloud and distant flicker.
3. **Replace the sprite mist** with volumetric ground fog. Break up the grass carpet with moss, black pools and grove edges.
