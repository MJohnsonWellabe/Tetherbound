# b50: grounded flinch for Cloudfang, Breezetail and Stormcapra vs main (CPU, three judges)

Candidate: 80200d1f. GPU CO-1 (4/6 judges) read the hit as "a pounce, not a flinch". The live held shove (gain 1.5: pivot pitch 18.8 degrees, forelegs 24/36) is regenerated at gain 0.75 with the same hold, hit role only. The generator reproduces the live clip byte for byte at gain 1.5.

Tiles: standing, then hit 025 / 050 / 075 (blow landing, held, recovering). Sheet `_sheet_b50.jpg`: main | flinch, rows Cloudfang, Breezetail, Stormcapra.

Anchors: f36_0_npc:C6, f36_0_gap:C3, f36_0_gap:C4. Fit: offset method (the gap anchors' raw order again ran against the references, r -0.81), RMSE 0.74. **Not confirming**; the gains below are within-set. Every judge preferred the flinch in every set.

| species | main (mapped) | flinch (mapped) | gain | pounce, not a flinch (main / flinch) |
|---|---|---|---|---|
| Cloudfang | 5.93 | **6.70** | **+0.77** | PRESENT x3 / PARTIAL x3 |
| Stormcapra | 6.73 | **7.20** | +0.47 | PARTIAL x3 / **FIXED x3** |
| Breezetail | 6.46 | **6.90** | +0.44 | PARTIAL x3 / **FIXED x3** |

Call: **GPU READY as one bundle** (+0.56 mean, 9/9 judge-set preferences).
- Cloudfang's flinch still "rears with the forelegs raised, hind feet planted". That is half the old lift; a lower gain is the next step if the GPU agrees.
- Judges' other repeated reads, not this candidate's: the faint end of the white wolf and Tanglevolt anchors turns to camera, and Breezetail "only just clears the ruler".

Checks: `run_tests --only=f36_pose,creature_pose,rest_pose,companion,creature_body`: 72 tests, 0 failed.
