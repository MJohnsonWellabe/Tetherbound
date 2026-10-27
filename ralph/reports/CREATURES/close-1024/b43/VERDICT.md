# b43: dog3 Terrapup, spine ridge only (shoulder plates painted to coat) vs r1 and main (CPU, three judges)

Candidate cdb7e6e6, approved by the coordinator under the owner's 24 Oct light-touch ruling. `grade_retex.py` rasterises the mesh into UV space. Plate texels off a short spine ridge (|x| > 0.13 m, outside z -1.2..1.0 m or below 2.35 m) take the inverse-distance colour of the nearest real coat in 3D, brightness matched to the open coat on the back. 22% of plate texels stay stone. The head is untouched. Sheet `_sheet_b43.jpg`: main | r1 | ridge.

Anchors: craft, f36_0_npc:C1, f10_2_r3_capacitor. Fit: slope 1.53, r 0.95, RMSE 0.44, confirming.

| set | side | raw (j1, j2, j3) | mapped | plates strapped on | coat orange-red |
|---|---|---|---|---|---|
| ridge vs main | ridge | 6.1, 6.4, 6.3 | 6.72 | PRESENT x3 | PRESENT, PARTIAL, PRESENT |
| | main badger | 5.9, 5.6, 6.5 | 6.31 | PRESENT, PRESENT, PARTIAL | FIXED x3 |
| ridge vs r1 | ridge | 6.1, 6.4, 6.3 | 6.72 | PRESENT x3 | PRESENT, PARTIAL, PRESENT |
| | r1 | 6.0, 6.6, 6.4 | **6.82** | PRESENT, PARTIAL, PARTIAL | PRESENT, PARTIAL, PRESENT |

Call: the ridge ties r1 (-0.10) and its plate defect reads worse: the coat-filled shoulders, still shaded by the mesh's shoulder lumps, read as "dark muddy patches… a smeared saddle-pack". Reverted. Third dog3 round under 0.5 (r3 b41, flatten b42, ridge b43), so dog3 plate work stops until the GPU verdict on r1 (ebec8e36). Both dog3 sides stay ahead of main's badger here (+0.41 / +0.51), and judges again flag the badger as off-identity. Judge 3 notes the hit-react tail streak (dog3 clip) again.
