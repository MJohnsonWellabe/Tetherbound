STATUS: parked
BRANCH: tb/item-f38-30-hill  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, F38#30 / F38#24 Burrow Warrens hill (art row, coordinator 8 Nov). No config, code or asset ships. The capture-stand fix landed separately (`tb/item-f38-30-stands`).

## v1: Blender reskin of the live Bank, vertices locked (built, not judged)
- The live procedural Bank visual mesh was exported in warrens space (headless GLTFDocument).
- Blender kept every vertex position (a 1 mm weld only), so the existing Bank collider matched exactly. The bake uses installed textures only (`terrain/stylised` meadow_grass, wet_earth, rock_scree and dirt_path), box-projected: grass on gentle slopes, wobbling earth/scree strata bands on steep flanks, AO, and a dirt lip at the slope break.
- Script: `blender/warrens_bank_hill.py`. Preview script: `blender/render_preview.py`.
- Preview and 1.80 m scale check: `blender/_v1_preview_scale.jpg`. Baked albedo: `blender/_v1_albedo_small.jpg`.
- **Why not judged:** the Bank's shape is a union of rectangular chamber boxes with 20-30 m near-vertical walls; the walk_03 collider normal is y 0.26, about 75°. Locked to that shape, the hill reads as a striped mesa or blockout fortress. That is the look judges rejected on F40#1 and #4 ("flat stacked-slab walls with regular strata"), and what LANE-MS saw with the Bank unhidden. The look problem is the shape, and the shape is the collision.

## v2 feasibility: a smoothed mound with collision rebuilt (computed, not built)
- Data: `blender/probe_warrens_feas.gd.txt` (live chamber boxes, terrain and Bank height grid at 2 m in warrens space). Computation: `blender/v2_feasibility.py`.
- Method:
  - Required cover is every live Bank plateau cell that reaches the chamber roof + 1.5 m clearance, with the mouth excluded because it is the dug entrance.
  - The minimal mound with a given maximum flank is the cone dilation of that requirement; its footprint is where it stands above the terrain.
  - Each exterior-ring point is then checked for whether it would be buried, and by how much horizontal room is missing.
- Plot (40° flank): `_v2_feasibility_40deg.png`. Brown is mound and current Bank, tan is mound only, blue is current Bank only, dots are required cover, red marks the ring.

| Ring point (warrens local x, z) | side | 35° | 40° | 45° |
|---|---|---|---|---|
| burrowback cluster (-14.1, 7.1), r 10 | front-west, beside the mouth | buried, 26.0 m short | 20.4 m short | 15.8 m short |
| pickup mushroom (-24.7, -0.7) | front-west | 19.6 m short | 13.7 m short | 8.9 m short |
| prop (5.5, -3.0) | front, at the mouth | 12.9 m short | 7.8 m short | 3.6 m short |
| harvest node (35.2, 14.3) | east | 21.3 m short | 15.1 m short | 10.1 m short |
| pickup candy (36.1, 26.2) | east | 17.3 m short | 11.8 m short | 7.3 m short |
| cluster 2049 (-63.6, 35.4), r 14 | west | 1.8 m short | clear, 5.0 m margin | clear, 9.7 m |
| cluster (57.3, -0.7) | east-front | clear, 1.5 m | clear, 8.7 m | clear, 14.2 m |

- Per side:
  - **front (mouth side):** fails by 8-20 m at 40°.
  - **east:** fails by 12-15 m.
  - **west:** fits at 40° and above.
  - **back:** no ring points, so it is unconstrained.
- **It does not fit.** The ring content stands right against the Bank's steep walls. No mound gentler than those walls can cover the chambers without burying five of the seven ring points, and even 45° flanks leave 4-16 m shortfalls. A small local steepening cannot close gaps that large.

## What would unlock this row (owner decisions)
- Move the five front and east ring items (the burrowback cluster, the two pickups, the harvest node and the prop) 10-20 m outward. That is a world-layout change.
- Or accept steep earth-bank walls as the design, and fix their read with a hand-modelled dug face instead of a height-field reskin. That is new art, keeping today's collision.

## Files
`ralph/reports/LANES/ITEM-F38-30/**` only.
