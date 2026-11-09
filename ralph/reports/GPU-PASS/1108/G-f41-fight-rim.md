# GPU arm round 1108, G-f41-fight-rim: F41#3 and F41#6 Stormwood fight rim (tb/item-f41-fight-read files): arm and armTone (live vs arm, GPU High, mapped)

**Verdict:**
- **Neither arm ships, and the result is confounded.** Both arms lose: F41#3 −0.51 on both arms, F41#6 −0.89 (arm) and −0.99 (armTone), with 0 of 3 judges preferring an arm on any pair.
- **The loss comes mostly from a sky regression, not the rim.** In every arm frame the purple Stormwood storm sky is replaced by a grey-blue tiled noise texture. I checked i01 for live, arm and armTone myself.
  - All three judges called it out unprompted, as "a missing skybox", "a wallpaper-like artefact" and "a noise-patterned sky", and only on the arm side.
  - The arm frames also show a different camera and background: more distant pylons, and a row of small white creatures.
  - The imported `world_look.gd` change, which now passes the world scene, probably makes Stormwood load a realm look that drops its sky. That is an inference, not root-caused.
- **Fix that before the rim can be judged.** Arm and armTone differ in bytes, but the judges scored them identically, so the toned rim (0.35/3.0) did not visibly change anything at this distance.

| Pair | Live | Arm | Gain | Prefer arm | Ship rule |
|---|---|---|---|---|---|
| F41#3 actor spacing (3 frames), arm | 6.09 | 5.58 | −0.51 | 0/3 | No |
| F41#3 actor spacing, armTone (rim 0.35/3.0) | 6.09 | 5.58 | −0.51 | 0/3 | No |
| F41#6 danger and opening cues (1 frame), arm | 6.94 | 6.05 | −0.89 | 0/3 | No |
| F41#6 danger and opening cues, armTone | 6.94 | 5.95 | −0.99 | 0/3 | No |

- **Per judge, mapped (raw):**

  | Row | Live | Arm | armTone |
  |---|---|---|---|
  | F41#3 | 6.14 / 5.86 / 6.28 (5.6 / 5.4 / 5.7) | 5.72 / 5.29 / 5.72 (5.3 / 5.0 / 5.3) | same as arm |
  | F41#6 | 7.13 / 6.42 / 7.27 (6.3 / 5.8 / 6.4) | 6.14 / 5.72 / 6.28 | 6.00 / 5.58 / 6.28 |

**What the judges saw:**
- **Live:**
  - Voltarach reads strongly against the purple storm sky, with gold-charged legs and a violet core.
  - The F41#6 cue conflict is FIXED: no magenta slab shows during the opening.
- **Arm side:**
  - The tiled sky described above.
  - The boss is over-bloomed into a white-gold blob with little leg structure.
  - Sparkit and the trainer are buried under its legs.
- **Both sides:** Sparkit sits under the boss's legs (F41#3 PRESENT), and there is a white impact puff.
- **Next:**
  1. Re-run with the sky fixed. Restrict `realm_scenes` so it changes only the rim, or keep the world_look change out of Stormwood.
  2. A per-species rim allowance (rim only on dark creatures) before the rim is judged again, because Voltarach blooms.

## Method
- **Frames:** `tb/gpu-frames-1108` (0c9cd0ce), section `G-f41-fight-rim`. GTX 1060, Forward+ High 1920x1080, JPEG q85, main ba6778f45. No frames missing.
- **Judging:** one shared batch for all six parked-arm sections, `G-parked`. It had 11 live-vs-arm pairs and 3 pinned anchor pairs (craft, f10_2_r3_capacitor, f04_6_r22). `anchor_tiles.py` shuffled the sides and kept the key outside the judge folder. Three fresh code-blind judges used the standard JUDGE_PROMPT.
- **Fit:** `calibrate.py` linear, slope 1.4119, intercept -1.7663, r 0.8965, anchor RMSE 0.511. Confirming batch (top anchor 7.35); no warnings.
- **Scale:** mapped scores are on this batch's scale. Read gains within the batch.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~05:40 UTC. Judge folders and replies stayed local.
