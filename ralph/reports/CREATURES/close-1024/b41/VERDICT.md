# b41: dog3 Terrapup r3 retexture vs r1 and main (CPU, three judges)

Source: coordinator Meshy r3 (tb/meshy-1024 6c63dfa6d, task 01a1754c-cf45-740b-af22-98daf1886f75): "small separate stones ringed by fur". Graded with the same coat grade as r1 (`grade_retex.py --source r3`, which also seeds the plate mask from grey stone texels). Same stage and tiles as b40; the r1 and main sides are b40's tiles. Sheet `_sheet_b41.jpg`: main badger | r1 | r3.

Anchors: f36_0_gap:C1, f04_6_r22, f36_0_npc:C1. Fit: slope 0.91, r 0.90, RMSE 0.35, confirming.

| set | side | mapped | plates strapped on | coat orange-red |
|---|---|---|---|---|
| r3 vs main | main badger | 6.38 | PARTIAL x2, PRESENT | FIXED x3 |
| | dog3 r3 | 6.95 | PRESENT x3 | PARTIAL x3 |
| r3 vs r1 | dog3 r1 | **6.95** | PRESENT x3 | PARTIAL x3 |
| | dog3 r3 | 6.89 | PRESENT x2, PARTIAL | PARTIAL x3 |

Call: r3 ties r1 (-0.06), so r1 stays the candidate (b6129230 reverted in a9e286d3). Two judges read r3's lighter grey stones as "more stuck-on" and r1's darker plates as "slightly better integrated". Separate stones in the texture did not change the read: all three judges still describe slabs "sitting on top of the fur" over the shoulders. As the coordinator predicted, the cause is the mesh's raised shoulder lumps, not the texture. The next step is a mesh fix (see the note), not another retexture.

Both dog3 sides beat main's badger by about +0.57 in this batch (b40: +0.45). Judges again read the badger as off-identity ("a badger or bear, not a large dog") and its top-down faint as a turtle shell.
