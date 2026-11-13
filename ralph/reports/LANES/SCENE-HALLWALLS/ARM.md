# SCENE-HALLWALLS: the Warden arena's inside walls stop growing exterior moss (F38#28 close-out)

Row: F38#28, High 7.47 and Medium 7.55 after TELLDUST; 0.03 short at High. `G-things-telldust.md`, 2/3: "a translucent green vertical plane behind the dog in the Warden hall, read as exposed geometry". THINGS-HALLMOSS was held by the GPU's by-eye check: it lightened only the pilasters and left the green rectangles unchanged.

## Cause, and how it was confirmed

A ray probe at the Warden fight camera (a 96 by 54 grid of rays from the lens at frames 01, 03 and 05; each ray names the nearest render mesh and its material; it needs no light, so the dark CPU hall does not matter):

- The arena's wall panels and tower piers (`Stronghold/@MeshInstance3D…`, `TowerPier_warden_arena_1`) wear `hall_stone.gdshader` with **moss 0.78**: the EXTERIOR stone. At frame 03 they are the largest surfaces in view.
- Only the pilasters (`InteriorStructure/shaft_*`) wear the interior stone, moss 0.46. That is the only thing HALLMOSS changed, which matches the GPU report exactly.
- Why: `stronghold.gd` builds each chamber wall as one box with `_wall_material(true)`, the exterior material, on both faces. Exterior moss is 0.78 at scale 0.26, so patches are about 4 m across: one patch fills one wall panel between two pilasters and stops at them. That is the flat green rectangle.
- No green light is involved: the two teal lights in range (containment and machine core) are 23 m away; nothing green is aimed at that wall.

## Arm

Overlay (`overlay.json`): `stronghold.json site.weathering.roofed_room_walls_1113.enabled` true (`moss_mul` 0.3).

Flag-off code on `tb/scene`: walls and tower piers of roofed chambers wear a copy of the same exterior material with three extra shader values (the room's footprint in stronghold-local metres). Fragments inside that footprint, which are the inside faces, scale moss by 0.3. Outside faces of the same boxes, the open yards (`outer_works`, `courtyard`) and every other surface keep their moss. With the flag off the shader term is a no-op and no material is copied.

Checked with the same probe, flag on: at frame 03, 1,845 of 5,184 rays land on the copied material inside a room footprint and 24 land on it outside (wall ends in doorways). No shader error in the log.

## Not shown on CPU

As HALLMOSS found, the hall is too dark on CPU (Compatibility, Low) to see moss on either side. The CPU frames differ by a mean of 0.2 in red and under 0.1 in green and blue. The evidence here is the probe, not the picture.

## By-eye line for the GPU lane

Warden 03 at High, camera-matched: the large green rectangles on the wall panels behind the dog are gone or reduced to moss in the mortar joints, and the wall reads as warm brown stone like the wall to its left. The pilasters are unchanged from base. If the rectangles are unchanged, hold the arm and tell me: the next suspect is then the exterior massing piece the probe saw through the roof breach (`@MeshInstance3D@67314`, moss 0.78, on the right wall).

## Risks and no-loss frames

- Every roofed chamber changes inside (Warden arena, tether approach, legendary chamber), not only the arena. No-loss: any stronghold interior frame in the F38#20 set, and F38#17 Keeper Hald's corridor.
- The outside of the Hall must be identical (F38#20 closed at 7.50 with no margin): the term only applies inside a room footprint, but check one approach frame.
- Less moss inside may read as flatter stone. `moss_mul` is one overlay value if the judges want some back.
