STATUS: land
BRANCH: tb/item-f38-20  HEAD: see `git log -1 origin/tb/item-f38-20` (origin/main merged in on 7 Nov, then 06e88b6e; tests below re-run after the merge)

**Row:** F38#20 Team Tether stronghold (P2-003), Blender/terrain row. Live ~6.20 (board). Lane LANE-SW.

**Result:** CPU 6.38 -> **6.78** mapped (r2, keep hill + curtain wall, ON). Stopped under the stop rule (two consecutive rounds gaining under 0.5: r1 +0.00, r2 +0.40).

| Round | Arm | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand | Dir |
|---|---|---|---|---|---|---|
| r1 | `stronghold.json keep_hill_1107`: Blender grass-and-rock hill under the keep | 6.32 | 6.32 | +0.00 (3/3 identical) | 5.5 5.9 5.4 / 5.5 5.9 5.4 | `ralph/reports/LANES/LANE-SW/qj/F38-20-09cbce8089d6-11072205/` |
| r2 | `keep_hill_1107` + `keep_walls_1107` (crenellated curtain wall and towers on the hill) | 6.38 | **6.78** | +0.40 (3/3 higher) | 5.6 5.6 5.8 / 5.9 5.9 6.1 | `ralph/reports/LANES/LANE-SW/qj/F38-20-7117b2d2ef08-11072224/` |

CPU llvmpipe, Compatibility, quick_judge, three code-blind judges, pinned anchors (anchor RMSE 0.61 / 0.57). r2 judges: "flanking curtain walls widen the footprint, so it reads more like a fortress compound"; "grounds it on the hill".

**Flags turned ON:** `data/config/stronghold.json:keep_hill_1107` and `:keep_walls_1107` (CPU 6.38 -> 6.78, r2, judged together). **Tests:** `tests/test_stronghold_keep_hill.gd` (new) asserts both ON with the score, that each joins the keep's companions only when ON, no collider, and per vertex that neither enters the hall footprint (|x| < 70 m, z < 125 m) above 2.5 m under the hall floor. Run after the merge: `test_stronghold_keep_hill`, `test_vis_meadows_1104_on`, `test_stronghold_arena_conduits` and `test_texture_import_policy`, all 0 failed. The extracted textures were set to VRAM compressed by `tools/art_pipeline/texture_import_policy.py --apply` after judging. The judged frames used the lossless import; expect a negligible difference at 700 m.

**What it is:** 
- **Hill:** 856 x 560 m with its crown 78 m above its base, 200 m behind the gate mouth. Grass slopes fall to the horizon either side of the keep, with 26 half-buried rock outcrops. The base sits 14 m under the hall floor. The hall footprint is notched 3 m under the floor, and nothing rises in front of the mouth.
- **Curtain wall:** 23 m high with 34 m round towers, on the hill contour (an ellipse of 255 x 175 m), open at the front (|x| < 125 m, z < 150 m) so the hall and the keep's face stay in view.
- **Placement:** both go through the existing hero-gatehouse companion loader (`stronghold.gd::p2_003_gatehouse`, a two-key loop). Both resist the depth fog, like the keep and crag. Presentation only, no collider, no route or save change.

**Files touched:** `scripts/world/stronghold.gd`, `data/config/stronghold.json` (two keys), `assets/props/blender-1107/meadows_keep_hill/` and `meadows_keep_walls/` (GLB, extracted textures, .import, provenance.json), `tests/test_stronghold_keep_hill.gd`, and this dir (Blender scripts `build_keep_hill.py`, `build_keep_walls.py` and `hill_height.py`; `_ref_keyart.jpg`; `_scale_check_hill.jpg`).

**Provenance:** Blender 4.2.3 procedural geometry (seed 1107), no Meshy. Textures are embedded copies of the installed terrain `Grass004` and `Rock030`.

**Flags left OFF:** none from this row.

**Judges' remaining asks:**
- The keep is still small in frame from the 500-700 m approach stand. They ask for "closer or higher placement" or a bigger hero keep with a gate and approach dressing.
- At night the keep is a black cut-out with no rim light.
- Up close the courtyard props are scattered evenly across a broad flat floor, with a flat back wall.

**Next idea:**
- A lit gatehouse and approach road dressing on the hill's front slope: torches, and banners on the wall towers in Team Tether red.
- A night rim light on the keep and walls (a moonlit fill).
- Clustered courtyard dressing.
