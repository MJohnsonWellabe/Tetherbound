# G-below6-namedfaces: face tint for the Stormwood named villagers (F41#8; GPU High)

## Verdict: LEVEL, do not ship as a change
- **F41#8 row:** 5.57 on both sides, identical raw scores from all three judges.
- **Dialogue frames:** 6.39 → 6.43 (+0.04). One judge prefers the arm; two tie.

The judges cannot see the change at these camera distances.

## Frames
- **Source:** `tb/gpu-frames-1108` b4a5c03c6, High, `phase2_capture_dialogue.gd` seed 2042, same selector as `G-below6-namedposts`.
- **Build:** `tb/below6` 8a0f9c733 on both sides. Hesk's portrait fix is on both sides by design.
- **Sides:**
  - **base:** overlay off.
  - **arm:** `BELOW6-NAMEDFACES/overlay.json`, which turns on `named_tint_1112`, read by `stormwood_character_presentation.gd`.
- 0 script errors.
- **GPU lane pre-check:** mean brightness in each villager's box drops, and so does the share of near-white pixels.

  | Villager | Mean L, base → arm | Near-white, base → arm |
  |---|---|---|
  | Maud | 130 → 109 | 5.5% → 1.0% |
  | Hesk | 110 → 93 | — |
  | Bryn | 102 → 86 | — |

- **Render check:** the row changes by a mean of 1.8 (3.1% of pixels), and the dialogue frames by 3.7 (8.0%).

## Batch
`G-nf`, shared with `G-galeland2.md`. Fit: slope 1.3588, intercept −1.6769, r 0.984, RMSE 0.180.

## Results

| Set | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm |
|---|---|---|---|---|
| F41#8 row | 5.5, 5.0, 5.5 → 5.57 | 5.5, 5.0, 5.5 → 5.57 | 0.00 | 0/3 (all tie) |
| F41#8 dialogue | 6.0, 6.0, 5.8 → 6.39 | 6.0, 6.1, 5.8 → 6.43 | +0.04 | 1/3 (2 ties) |

- **Row (3/3):** "nearly identical", "the figures are tiny in frame".
- **Dialogue (3/3):** "nearly identical". All three judges still name problems on **both** sides:
  - "Warden-Elect Bryn's face is blown out to white";
  - "Rodkeeper Hesk's face texture is blotchy and posterised".

  The tint does not remove what the judges see as the face problem.
- **Recorded defect** (repeated silhouettes): PARTIAL 3/3 on both sides.

## What holds F41#8 down (3/3)
1. **Crushed black ground.** Posterised black and green patches, a flat pasted-on lavender sky, and pink-washed bears.
2. **Tiny named figures** in the inventory frames. The trainer's shoulder intrudes at the left edge of the dialogue frames.
3. **Blown or posterised face textures** (Bryn, Hesk). These may need texture work, not a tint.

## Recommendation
1. Keep `named_tint_1112` off as a standalone change. It is harmless and could ride along, but it earns nothing.
2. The F41#8 lever is the Stormwood ground and grade, which every judge names first.
