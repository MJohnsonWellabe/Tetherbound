# b28 (24 Oct 2026, CPU candidate pick): Grandpa eyes (F36#0 Grandpa sub-row)

What was compared, all on the same installed head, mesh, rig, UVs and clips:
- Candidate `eyes`:
  - Grandpa's face albedo with the solid black "bead" eyes repainted as a pupil, a warm hazel iris, a darker limbal ring and a catch-light.
  - Script: `assets/characters/grandpa/candidate/source/add_eye_detail.py`. The iris is laid out in model space by rasterising each eye texel's 3D position, so it stays continuous across the UV seam that splits the left eye.
- Arms:
  - `ship`: the main candidate (close-1020 facial-skin albedo).
  - `lod0`: the installed grandpa_lod0, by an art.json swap.
- Capture: `tools/_capture_character_cast.gd` (CPU, Compatibility, 1280x800).
- Sides: two face close-ups (front and three-quarter, cropped and upscaled) plus both full-body frames.

How it was judged:
- Standard prompt verbatim, three fresh code-blind judges.
- Anchors: craft, f36_0_npc:C6, f36_0_gap:C7. The f36_0_npc:C1 group (Grandpa itself) is excluded. This is a confirming batch.
- Fit: linear, slope 1.197, intercept -1.029, anchor RMSE 0.58.

| Set | Candidate | Comparison | Mapped |
|---|---|---|---|
| Ol | eyes **6.87** | lod0 6.27 | +0.60 (CPU-provisional at or above 6.7) |
| Av | eyes vs ship | **excluded** | |

Why Av is excluded: all three judges said Av and Ol were "the same image" and copied Ol's scores onto Av. The two tiles differ (md5 1051db8… vs c3001ab…), and the sides are swapped between them (Av: A=ship, B=eyes; Ol: A=eyes, B=lod0). So Av's per-side scores describe the wrong arms. The raw scores are kept in raw_scores.json, and the valid set is in raw_scores_valid.json. Per the GPU re-confirm, ship and lod0 are within noise (7.21 vs 7.18).

What the judges said about the eyes side:
- "eyes larger, glossier and have catchlights, so the face reads alive".
- The lod0 side reads as "flat black dots without catchlight, a dull, doll-like stare".

Still open:
- Noisy hair and beard textures, and a blotchy, camouflage-like scarf.
- The face is more toon than the creatures.
- Flat grey-stage light.
