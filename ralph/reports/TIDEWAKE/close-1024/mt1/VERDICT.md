# Tidewake close-1024 round mt1: MESHY 10 crown on the capped Veilfall summit, CPU pre-judge (25 Oct 2026, CT)

## What  turns on (OFF in play)

- **Crown:** `veilfall_terraced_mountain` (tb/meshy-1024 7a5f3318a). Render mesh with trimesh collision that follows the drawn mesh (`trimesh_collider`).
  - Fit: 460 m tall, stretched 1.6 x 1.7 in plan.
  - Seated on the plateau facing the landing sector.
- **Summit cap:** `water_world.json` `terrain.veilfall_summit_cap`, a soft clamp identity below 210 m that rounds to a ~240 m plateau.
  - Every walked height (max 196.9 m), anchor and the gate are unchanged (`test_veilfall_summit_cap_leaves_every_walked_height_and_caps_the_peak`).
  - The capped terrain is baked to `data/terrain/water_veilfall_cap`. Only the four summit regions differ in height (max 380 m).
  - The candidate switches the baked directory and the analytic field together, so the drawn terrain and its collision match.
- **Crag heap:** the render-only crag kitbash is hidden while ON.

## Mapped Bar A

- **Views:** `veilfall-vista` and `veilfall-vista-rain`.
- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 13397).
- **Calibration:** `calibrate.py` slope 1.25, r 0.95, anchor RMSE 0.34.

| Arm | Mapped |
|---|---|
| Shipping | 3.52 |
| t1e + falls f2 | 4.14 |
| **Crown + cap** (+ t1e, falls f2, rain fog) | **4.64** (+1.12 vs shipping, +0.50 vs t1e + falls; higher x3) |

## Read this honestly

- **The crown is mostly out of frame.** The vista stand (200 m offshore, pitch 11 degrees) crops the summit, so the judges scored the lower island.
  - They describe a "smooth symmetric cone with one cleft", which they prefer to the faceted block heap.
  - They still mark it PRESENT for "smooth cone rather than terraced cliff mountain".
- **From further out the crown does read:** see the far frame on `_sheet_mt1.jpg`, terraced tiers, falls, arch and pines on a grounded base.
- **The rain arm includes `rain_fog_candidate`.** The fog read is part of the +0.50.
- **Known losses while ON:**
  - The big existing main fall disappears with the hidden crag heap. The crown carries its own falls.
  - The slopes below the crown are a plain smooth cone.

## Next

1. **Framing:** the judges ask for the whole landmark framed from offshore. Either pitch the vista stand up (a yardstick change for the coordinator) or capture a second far view.
2. **Lower slopes:** dress them (terrace relief, vegetation bands) so the cone stops reading as smooth.
3. **Main fall:** bring it back as a column on the capped face.

## GPU capture (`tb/tidewake` 42300a3af or later)

`F39-look.json --views=veilfall-vista,veilfall-vista-rain`, shipping vs `--tidewake-look-sections=current_flow,veilfall_falls_candidate,rain_fog_candidate,veilfall_mountain_candidate`.
