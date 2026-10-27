# b49: Galecrest matte finish vs main (CPU, three judges)

Candidate (owner ruling 26 Oct: replace the chrome-white with bright edges with a matte slate/tan finish; texture/material only):
- `species.json` drops Galecrest's `field_emission` x1.35 value lift. The albedo is already slate-blue and tan, and the lift pushed it to chrome-white.
- `field_rim` falls from 0.25 to 0.1.
- Mesh, pose, clips and albedo are unchanged.

Stage: `capture_f36_poses.gd --whole-body --context`; tiles are standing, hit-050, faint-050, faint-100. Sheet `_sheet_b49.jpg`: main | matte.

Anchors: f36_0_npc:C2, f36_0_gap:C2, f36_0_gap:C7. Fit: offset method (the anchors' raw order disagreed with the references, r -0.55), RMSE 0.52. **Not confirming**; the absolute mapped values are loose. Every judge scored the matte side 1.0-1.5 raw above main.

| side | mapped (j1, j2, j3) | mean | chrome-white with bright edges (halo) |
|---|---|---|---|
| main | 5.63, 5.73, 5.83 | 5.73 | PRESENT x3 |
| matte | 6.93, 7.13, 6.83 | **6.96** | FIXED, PARTIAL, PARTIAL |

Call: **+1.23, READY for the GPU bundle.** Judges' read of the matte side: "matches the style-bar Galecrest: dark slate feathers, gold accents and a readable head and beak".
- Remaining: two judges still see "white streaks along the wing edges" in the faint frames. The 0.1 rim is GPU-only, so the GPU decides it.
- Every judge flags the hit-react as "a thin vertical sliver" (the wing straight up, side-on).
- Scale reads "only modestly taller than the trainer".

Check: `smoke_creature_field_brightness` used Galecrest as its probe species (field_emission > 0 with field_rim). Galecrest no longer ships field_emission, so the probe moves to Voltarach, the one species that still ships both. Same assertions: PASS. `run_tests --only=species,creature_body,field,colourway`: 102 tests, 0 failed.
