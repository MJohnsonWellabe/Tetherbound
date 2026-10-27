# b57: dog3 Terrapup r7 (pad remnants cleared in model space + shoulder lumps flattened) vs r5 and vs main's badger (CPU, three judges)

Candidate r7 (83e2b5b7):
- `grade_r4.py` also fills dark, cool-hued or desaturated texels within 0.35 m of the old pad on the body. This clears the dark withers slab.
- `flatten_plates.py` (the b42 vertex-only edit, now on grade_r4's pad mask) moves the back and shoulder vertices under the pad 70% toward a smoothed surface. Height and length are unchanged.
- Coat as r5.
- A pixel probe found that the thin outline loops still visible on the shoulder are not in the albedo, normal or metallic-roughness maps. They are mesh shading along Meshy's old pad edges.

Sheet `_sheet_b57.jpg`: badger | r5 | r7.

Anchors: f36_0_gap:C5, f36_0_npc:C9, f10_2_r3_capacitor. Fit: offset method (r 0.47), RMSE 0.94. **Not confirming**; within-set only.

| set | side | raw (j1, j2, j3) | mapped | plates strapped on | coat orange |
|---|---|---|---|---|---|
| r7 vs r5 | r5 | 6.2, 6.3, 6.3 | 6.60 | PRESENT x3 | PARTIAL, PRESENT, PARTIAL |
| | r7 | 6.3, 6.4, 6.4 | **6.70** | **PARTIAL x3** | PARTIAL x3 |
| r7 vs badger | r7 | 6.2, 6.3, 6.3 | 6.60 | PRESENT x3 | PARTIAL, PRESENT, PARTIAL |
| | badger | 6.3, 6.0, 6.6 | 6.64 | PARTIAL x3 | FIXED x3 |

Call: r7 +0.10 over r5 (plates PRESENT -> PARTIAL x3); level with the badger.
- With r5's +0.34 this is the second dog3 round under 0.5, so the texture/vertex approach to the plates is **parked**. r7 stays on tb/creatures-land; no new GPU arm (CO10 carries r5).
- All three judges still see "one grey-green saddle on the back", worst in the faint end.
- New ideas, if CO10 shows the dog worth pursuing:
  - plates broken into scattered, varied sizes at the shoulders only, rather than three rows down the spine;
  - or a Meshy retexture that paints no plates at all, with the plates added in model space as here.
