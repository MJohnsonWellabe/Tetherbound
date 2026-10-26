# b42: dog3 Terrapup with the plate lumps flattened (vertex-only) vs r1 and main (CPU, three judges)

Candidate: 4df82f73 (`candidate_dog3/source/flatten_plates.py`, approved by the coordinator as a vertex-only edit). The back and shoulder vertices under the r1 plate mask move 70% toward a Laplacian-smoothed body surface, feathered into the coat. 5810 of 19936 vertices move, max 0.105 m. Height and length are unchanged, as are the rig, weights, clips, UVs and the r1 texture. GLB sha256 b55d6805… -> 3cf5181b…. Sheet `_sheet_b42.jpg`: r1 | flattened.

Anchors: f36_0_npc:C2, f10_2_r3_capacitor, f36_0_gap:C6. Fit: slope 0.70, r 0.69, RMSE 0.72. **Not a confirming batch** (r below the confirming threshold); compare sides within a set only.

| set | side | raw (j1, j2, j3) | mapped | plates strapped on | coat orange-red |
|---|---|---|---|---|---|
| flat vs r1 | r1 | 6.0, 5.6, 6.0 | 6.40 | PRESENT x3 | PARTIAL, PRESENT, PRESENT |
| | flattened | 6.0, 5.6, 6.0 | 6.40 | PRESENT x3 | PARTIAL, PRESENT, PRESENT |
| flat vs main | flattened | 6.0, 5.6, 6.0 | 6.40 | PRESENT x3 | |
| | main badger | 6.3, 6.3, 5.6 | 6.54 | PARTIAL x3 | FIXED x3 |

Call: every judge scored the flattened mesh exactly as r1 and called the two sides "almost identical". At stage scale the silhouette change (the spiky ridge gone) does not register. The "pack" read comes from the large dark plate mass painted over the shoulder blades and its hard outline against the orange coat, not from the lumps. Reverted (the flatten commit is reverted). With r3 (b41, -0.06) this is the second dog3 round under 0.5, so the approach switches (see the note). r1 at ebec8e36 remains the dog3 candidate. Judges again flag the badger as off-identity (two of three), but in this non-confirming batch they rate its finish slightly higher.
