# b55: dog3 Terrapup r4 (grown spine plates, pad filled, chestnut coat) vs main's badger (CPU, three judges)

Candidate r4 (`candidate_dog3/retex/grade_r4.py`, on the Meshy r1 retexture; species.json moves Terrapup to the dog3 mesh with the 2.36 m seat):
- the r1 plate pad, and its rim and outline remnants, are filled with fur copied from the flank below in model space;
- the normal map is flattened over the same region;
- the coat is desaturated (hue 24-29, sat at most 0.42, value x0.86);
- 24 small stone plates grow along the spine in three staggered rows, shingled toward the tail, with crevice edges, fur over the rims and contact shadow.
Reserved red 0.002%.

Tiles: standing, hit-050, faint-100, ride-050. Sheet `_sheet_b55.jpg`: badger | dog.

Anchors: f36_0_npc:C4, p2_094_r4, f36_0_gap:C7. Fit: slope 1.29, r 0.91, RMSE 0.47. Not confirming (top anchor reference under 7.0); ranking within the set holds.

| side | mapped (j1, j2, j3) | mean | plates strapped on | coat orange |
|---|---|---|---|---|
| main badger | 6.05, 5.92, 5.28 | 5.75 | PARTIAL, PRESENT, PRESENT | FIXED x3 |
| dog r4 | 6.69, 6.44, 6.57 | **6.57** | PRESENT, PARTIAL, PARTIAL | PARTIAL, PRESENT, PRESENT |

Call: +0.82. All three judges read "clearly a large shaggy dog with good canine anatomy". The coat still reads orange-tan (3/3), and that is what sank r1 on GPU (-1.82). So r4 is not sent to GPU; the next round (r5) changes only the coat value and saturation.
