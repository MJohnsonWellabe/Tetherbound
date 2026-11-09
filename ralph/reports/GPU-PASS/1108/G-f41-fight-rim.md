# GPU arm round 1108, G-f41-fight-rim: F41#3 and F41#6 Stormwood fight rim (tb/item-f41-fight-read files): arm and armTone (live vs arm, GPU High, mapped)

## Correction (9 Nov ~06:10 UTC): the "sky regression" below is withdrawn, and the rim is re-judged against live2

The first live run filmed the other side of the fight. That was the GPU lane's caution, and `G-f41-fight-rim-live2` (e8982d7a) confirms it:
- A second unmodified run of main shows the **same grey-blue tiled sky**, the same distant pylons and the same row of small white creatures as the arm frames.
- So the tiled sky is a live-world artefact on that side of the Stormwood capacitor arena, not something the arm causes. I was wrong to call it a regression from `world_look.gd`.
- Treat that tiled sky behind the canopy as its own Stormwood defect. All three judges in both batches called it "a missing skybox".

**Re-judge, live2 vs arm on the two comparable frames (i01, tell1-a-start; batch `G-rim2`):**

| Pair | Live2 | Arm | Gain | Prefer arm | Ship rule |
|---|---|---|---|---|---|
| F41#3 arm (rim, overlay_b) | 5.16 | 5.16 | 0.00 | 0/3 (3 level) | No |
| F41#3 armTone (rim 0.35/3.0) | 5.16 | 5.16 | 0.00 | 0/3 (3 level) | No |

- **Per judge, mapped (raw), identical on every side:** 5.25 / 4.84 / 5.39 (4.9 / 4.6 / 5.0).
- **Fit:** slope 1.3788, intercept −1.5028, r 0.900, anchor RMSE 0.502. Confirming batch; no warnings.

**Verdict, replacing the one below:**
- **Neither rim arm ships.** Against the matched control the rim makes no visible difference at this distance, for either strength.
- F41#6 (tell1-e-impact only) was not re-judged, because its framing differs in every pair.
- All three judges again say Voltarach is over-bloomed into a gold-white mass that hides its body, eyes and plates. The next lever is cutting its emissive and bloom, not adding rim, which matches the per-species allowance idea in ITEM-F41-FIGHT-READ.

---

## Original round (superseded): its live control showed a different camera side


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
