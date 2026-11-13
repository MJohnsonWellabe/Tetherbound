# G-below6-uniforms: uniform separation, emission floor 0 plus a pale rim and shoulder knots (F41#18; GPU High)

## Verdict: DO NOT SHIP, and PARK this lighting approach for F41#18. The row's own frames lose 3/3; only the dialogue sets gain.

| Set | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|
| **F41#18 row** (Dace, Varga, Sable at the normal camera; job frames) | **6.05** | 5.59 | **−0.46** | 0/3 | 5.68, 5.68, 5.41 |
| F41#18 dialogue (same three) | 6.14 | **6.55** | +0.41 | 3/3 | 6.64, 6.78, 6.23 |
| Officer dialogue (Sera, Maren, Nysa) | 6.41 | 6.55 | +0.14 | 2/3 | 6.64, 6.92, 6.09 |
| Civilian dialogue (Ivo, Tamsin, Wen; no-loss) | 7.06 | 7.19 | +0.13 | 2/3 (1 tie) | 7.06, 7.47, 7.06 |

## Why
- **At the normal camera the arm's coats sink back into the ground (3/3).** On the arm "the dark-uniformed officer ... blend[s] into the dark mud and purple mist", and the recorded defect is PRESENT (3/3).
  - Base's emission floor gives "pale, silvery, ghostly" figures that at least "separate from the ground" (PARTIAL 3/3).
  - The 0.6 rim and the knots do not show at this distance (render difference 0.10–0.14 for Dace and Varga), so removing the floor costs separation and nothing replaces it.
- **In conversation the arm wins (3/3).** "The uniforms are slightly lifted and rim-lit (Dace row 1, Varga row 2), so the silhouettes separate a little better." For the officers the arm keeps "plausible dark leather", where base reads "washed ... chalky" (2/3).
  - Rank markers are still "not legible" on either side (3/3). None of the judges named the shoulder knots.
- **Stop rule.** G-things-stormuniform (floor to 0) moved the row +0.04. This round moves it −0.46. Two rounds have gained under 0.5, so park lighting-only arms on this row until there is a new idea.

## What the row needs (3/3 unless noted)
1. **Dark cloth that is lit, not emissive.** "Mid-value cloth and armour materials with a cool rim light", strong enough to read at the normal camera, "avoiding both A's blend and B's ghost wash". The arm's 0.6 rim is too weak at distance.
2. **One readable rank or faction accent per uniform**, in a bright copper, glass or steel (not ivory, and not red). Shoulder insignia or piping, sized to read at the normal camera.
3. **Faces (new art, 3/3):** Varga's and Nysa's faces are "blotchy", "untextured mannequin" or "low-res, orange-tinted"; Sable's is "pale and smeared".
4. **Background (3/3):** the bears behind Nysa and Wen are flat salmon pink and unlit (not oxblood, but among the worst assets on screen).
   - Other shared notes: the flat path crack decals, Sable's plain white cottage gable (1/3), and the player head cut off at the left edge in dialogue (1/3).

## Confounds
- **Sable inventory frame:** a background Staticub is mid-stride on one side only (animation timing, as the GPU lane noted). The row loses on Dace and Varga too, so this does not drive the verdict.

## Pooled current-main lines (High)
- **F41#18 row:** G-things-stormuniform's base read 5.56 on a different tree (rim off). This base reads 6.05, so ≈ 5.8.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-below6-uniforms` (53f78cee6), High, `tb/below6` 52830ac12, `--fixed-fps 20`, every Stormwood post plus dialogue (86 frames per side, 0 script errors).
  - **base:** no overlay.
  - **arm:** `BELOW6-UNIFORMS/overlay.json` (`uniform_separation_1113`: four uniformed ranks get emission floor 0, a pale rim at 0.6, and shoulder knots plus a collar ring at 62%).
- **Render check:** inventory frames 0.10–0.70, dialogue 0.27–1.55. Captain Marrow is unchanged (0.02, per the GPU lane).
- **Sets:**
  - The row uses the job frames (`character__grunt_lieutenant_dace`, `character__tether_lieutenant_varga`, `character__defector_sable`) stacked top to bottom.
  - The other sets are those of G-things-stormuniform: row dialogue, officer dialogue and civilian dialogue.
  - The row carries F41#18's recorded defect; the rest have none.

## Batch `G-un`
- Three code-blind judges, standard prompt, four candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.374, intercept −2.014, r 0.936, anchor RMSE 0.49. No warnings.
- Yardstick: `yardstick_g_below6_uniforms/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F41#18 row | 6.0, 5.8, 5.8 | 5.6, 5.6, 5.4 |
| F41#18 dialogue | 6.0, 6.2, 5.6 | 6.3, 6.4, 6.0 |
| Officer dialogue | 6.1, 6.2, 6.1 | 6.3, 6.5, 5.9 |
| Civilian dialogue | 6.6, 6.8, 6.4 | 6.6, 6.9, 6.6 |

Bar B: no on every candidate set (3/3).
