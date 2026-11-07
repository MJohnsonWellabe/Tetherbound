STATUS: parked
BRANCH: tb/item-f38-30b  HEAD: see origin (verdict and READY only; no config change ships)

Lane LANE-MS. Rows F38#30 and F38#24, coordinator order 7 Nov (Warrens rim re-seat plus `buried_stand_guard`).

**Diagnosis correction.** There is no cavity, so the rim-blend was not built.
- `burrow_warrens.gd _bank_surfaces` already puts every Bank vertex at `_site_ground(x,z) + bump_h`, and `bump_h` is 0 at the rim, so the Bank meets the terrain.
- The 19.25 m collider over walk_03's stand is the Bank's own surface on the hall's flank. That stand is inside the solid hill.
- What the camera actually sees there: the Meshy hill shell (247 m wide, against the Bank's 145 m) overhangs walkable meadow beyond the Bank's collision, and the Bank's visuals are hidden. A player there is under the shell's culled underside, so nothing covers the chamber undersides.

**Screened (captured, inspected; not committed):**

| Arm | Result |
|---|---|
| guard ON (window 30, offsets [18, 26, 40, 55]) | The guard fires on walk_03 and moves it to offset 12, but it is still under the shell; the floating chambers remain. |
| shell `scale_xyz` x 1.9 -> 1.2, plus guard | walk_01 and walk_02 become clean (mound meets grass, no overhang), but the route view exposes the warren chamber box. |
| x 1.2 plus Bank unhidden (`hide_nodes: []`) | Worse: the Bank's steep flat procedural faces poke out in the route view and loom in walk_03. |
| x 1.45 plus guard | The route keeps the mound; walk_02 is cleaner; walk_03 is unchanged. |

**Judged:** round `ralph/reports/LANES/LANE-MS/qj/F38-30_F38-24-bde88113b20a-11072156/`, arm guard plus x 1.45.
- F38#30: CPU 4.48 -> 4.06 (-0.42). F38#24: 4.41 -> 4.16 (-0.25).
- All three judges named new artefacts: the guard's new walk_03 stand puts a black unlit boulder beside the trainer, and the narrower shell shows a stretched tree mass at the left of walk_02.
- **Stays OFF:** `capture_stands.json buried_stand_guard` is unchanged (OFF), and so is `hill_shell.scale_xyz`.
- Second consecutive round under +0.5 on these rows (+0.56 before this round, then -0.42), so the rows are parked.

**What would actually fix walk_03 (new art):** a hill mesh made in Blender, the procedural Bank's own footprint and height field with the shell's grass and earth treatment, so the visible hill equals the collision hill. Nobody can then stand inside it, and from outside it covers every chamber. The Meshy shell's overhang and the Bank's flat faces are both symptoms of using two different hills.
