# G-below6-marrow: Captain Marrow's head glow (F41#15, lowest row 4.49; GPU High)

**Verdict: SHIP.** The arm lifts the Marrow frames by **+1.40**, from 4.55 to 5.95, and all three judges prefer it.

## Frames
`tb/gpu-frames-1108` 7e6ba2d5a, High, `--fixed-fps 20`, captured on `tb/below6` 917e71d59 (one import, for the captain_a floor1 texture).
- **base:** overlay off.
- **arm:** `BELOW6-MARROW/overlay.json`. The log confirms both flags: `character_body_flags below6_marrow_self_lit_off` and `identity_floor_1112`.
- **Dialogue tool:** `tb/below6` predates PR #910, so the GPU lane swapped in main 8df122a83's `phase2_capture_dialogue.gd` on both sides. All four `__dialogue` frames are at blend 1.000.
- **Render check:** 8 frames, 0 blank, 0 script errors. The two dialogue frames differ by a mean of 2.1, with 5.2% of pixels changed (Marrow's head and coat).
- **Not shown:** the plain inventory frames do not show Marrow, so they are not judged.

## Set
- Both Marrow `__dialogue` frames, stacked at full size: `captain_marrow` and `captain_marrow_dynamo_core`.
- Brief and defect: F41#15's from job.json.
- **Coverage gap:** F41#15's third job.json frame, `officer_nysa_deepwood_rod__dialogue`, was not in this section. The verdict covers 2 of the row's 3 frames.

## Batch `G-mw`
- Three code-blind judges with the standard prompt.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.3104, intercept −1.3445, r 0.934, RMSE 0.494. No warnings.

## Result

| Set | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm |
|---|---|---|---|---|
| F41#15 Marrow dialogue (2 frames) | 4.6, 4.5, 4.4 → 4.55 | 5.6, 5.5, 5.6 → **5.95** | **+1.40** | 3/3 |

- **Base (3/3):** "a strong white bloom or glow halo covers Marrow's head and face ... blown out to near white". Judge b calls it "effectively a new obstruction" and marks the defect PARTIAL on base.
- **Arm (3/3):** "the face, eye patch and hair read cleanly", with only "a milder white rim glow on the hair".
- **Recorded defect** ("foreground creatures or geometry hide the speaker"): FIXED 3/3 on the arm. No creature or geometry covers Marrow in these frames.

## What still holds F41#15 and the Stormwood dialogue rows down (3/3)
1. **Grade.** One flat lavender mid-tone covers the sky, treeline, planks and coat. The distant forest is a single cut-out band with no fog depth.
2. **Materials.** The planks are a large, flat tiled texture with a pink-lilac cast. The left trunk is a saturated orange, which judge c places "near" oxblood; the right trunk is flat mauve. Judges a and b also call a flat blue slab at the left edge a placeholder.
3. **Framing.** The dialogue box covers Marrow from the chest or belt down on both sides.
4. **Nysa.** F41#15's Nysa frame was not captured. Earlier batches (`G-things-convclear-other-biomes.md`) found her blocked by the blue storm creature, so the row needs that frame before it can be re-scored.

## Recommendation
1. Land the overlay. A gain of +1.40 lifts the lowest-row Marrow frames well clear of the floor-tier deficit.
2. For a row score, capture all three F41#15 frames, including Nysa.
3. The next Stormwood dialogue change is the grade and plank material. It is a scene change, and it touches F41#7, #11, #15 and #20.
