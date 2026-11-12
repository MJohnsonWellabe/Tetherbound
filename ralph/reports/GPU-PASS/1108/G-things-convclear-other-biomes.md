# G-things-convclear-other-biomes: conversation-camera clearance in Tidewake, Cloudreach and Stormwood (GPU High)

## Verdict

**SPLIT.**
- **Tidewake and Cloudreach:** level. The overlay barely changes them and nothing loses.
- **Stormwood:** mixed. F41#15 gains +0.56 (3/3). On the set of the nine most-changed frames, 2 of 3 judges prefer the stand. The arm's Lieutenant Sera frame regresses, so Stormwood fails the "no frame loses" rule.
- **Meadows:** the ship verdict in `G-things-convclear-meadows.md` stands.

Fix the Sera regression, or keep the overlay off in Stormwood, before the overlay lands there.

## Frames

`tb/gpu-frames-1108`, High, from `tb/things` a90645724. Captured with `phase2_capture_dialogue.gd --seed=2042`.

| Biome | Commit | Rows per side |
|---|---|---|
| Tidewake | 5b45b864a | 39 |
| Cloudreach | a8d50f20a | 11 |
| Stormwood | e15fcad3e | 43 |

**Sides:**
- **stand:** `--sight-stand`.
- **arm:** `--sight-stand` plus `overlay_clearance.json`.
- **base:** the `G-dialogue-recapture-<biome>` frames.

**Capture notes:**
- Every frame has blend 1.0, except `water_trainer_rune`, which is panel-only on both sides, as in the base recapture.
- No stand exists for Mara, the Pell trial or Kestrel ×2, so they have no frame.
- `cloudreach__…captain_veyra__defeated__dialogue`, one of F40#12's job.json frames, was not captured. F40#12 is judged on its other two frames.

## Render check

Mean absolute difference, arm vs stand:
- **Tidewake:** 3–9 on every frame. These are small framing shifts; fen is the largest at 8.9.
- **Cloudreach:** 4–5 on three frames; the rest are lower.
- **Stormwood:**

  | Frame | Arm vs stand | Arm vs base |
  |---|---|---|
  | officer_nysa | 69 | 69 |
  | outerworks_lieutenant_sera | 55 | 68 |
  | stormreader_tamsin | 52 | — |
  | tamsin_surge_lesson | 44 | — |
  | trainer_ivo | 19 | — |
  | tamsin_ash_ring | 8 | 63 |

  Many Stormwood frames differ from base by 10–40 on both stand and arm, so the sight-stand itself moves the Stormwood framings.

## Sets

15 sets:
- each dialogue board row (F39#18, #26, #29; F40#10, #12; F41#7, #11, #15, #20), stand vs arm;
- the four Stormwood rows also base vs arm;
- one 3×3 sheet each for Tidewake and Stormwood, made of the nine frames that changed most between stand and arm (`samples.json`).

**Batch `G-cc3`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.

**Fit:** linear, slope 0.9307, intercept 1.0785, r 0.875, anchor RMSE 0.670. No warnings. This is the loosest fit of the run, so read small gains as level.

## Results

| Set | Other side → arm (mapped) | Gain | Prefer arm |
|---|---|---|---|
| **F41#15** Stormwood foreground obstruction, base vs arm | 5.14 → **5.82** | **+0.68** | 3/3 |
| **F41#15**, stand vs arm | 5.14 → **5.70** | **+0.56** | 3/3 |
| **Stormwood changed-nine**, stand vs arm | 5.82 → 5.86 | +0.04 | **1/3** (a and b prefer the stand) |
| Tidewake changed-nine, stand vs arm | 6.76 → 6.79 | +0.03 | 2/3 (one judge prefers the stand) |
| F39#26, stand vs arm | 7.03 → 7.07 | +0.04 | 2/3 |
| F39#18, F39#29, F40#10, F40#12, F41#7 ×2, F41#11 ×2, F41#20 ×2 | identical scores on both sides | 0 | tie |

### Recorded defects
- **F41#15:** FIXED is never given. Judges mark the arm PARTIAL 3/3, against PRESENT 3/3 on the side without the overlay. The arm shows Officer Nysa "between the creature masses"; without it she is "almost entirely hidden behind the blue creature".
- **All other rows:** the dialogue-row defects (distinct lines, matching portraits, a speaker present, mid-shot framing) are FIXED on both sides, 3/3.

### Stormwood changed-nine: why it loses
On the arm, Lieutenant Sera is hidden by "the wolf's head" or "a close creature head" (2/3). Judge b also has the storm bird hiding Tamsin. This matches the GPU lane's flag: base had a purple creature off to the right with the speaker clear, and the arm puts a large white-and-blue creature across the frame. Nysa improves on the arm (3/3).

## What still holds these rows down (all 3 judges)

1. **Stormwood creatures in the dialogue cone:** the blue storm bird and the white-and-blue wolf. Nysa, Sera and Tamsin are blocked on one side or the other. The clearance rule does not yet push wild or party creatures out of the cone in Stormwood.
2. **Captain Marrow's head is blown out to a white glow** in every Marrow frame (F41#7 and F41#15, 3/3). This was raised before in `G-dialogue-recapture-stormwood.md`.
3. **The player's head blooms white at the left edge** in Stormwood frames (Oswin, Maud, Wen, Senn, Lio; judge c).
4. **Shared meshes (3/3):**
   - Fenn, Oswin, Rowan and Kelm share one hooded, bearded mesh;
   - Captain Veyra uses Captain Nerissa's male mesh;
   - Bex, Irva, Oswin and Solm share one grunt mesh.
5. **Tidewake:** Corin faces away from the camera, and Edda's portrait is a tiny full-body figure (3/3).

## Recommendation
1. **Do not land the clearance overlay for Stormwood as it stands.** It fails the no-loss rule on the Sera frame. Either extend the clearance so it moves wild and party creatures out of the speaker cone, which fixes Sera, Tamsin and Nysa together, or keep the overlay off in Stormwood.
2. **Tidewake and Cloudreach:** the overlay makes no material difference. Landing it there is harmless.
3. **Next for Stormwood dialogue:** Marrow's emissive and bloom, and the player-head bloom at the frame edge. Both are scene fixes and affect four rows.
