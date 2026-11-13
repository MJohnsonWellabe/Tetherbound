# BELOW6-TERRACES (F40#1, 5.46 on the row): built, three CPU rounds, NOT SENT

**Flag:** `cloudreach_visual.json landmass.terrace_mesas_1112` (OFF). **Code:** `cloudreach_world.gd _build_terrace_mesas` (called from `_build_routes`). The code and flag stay in the tree, off.

**Idea:** eight prop arms on this row were read as pasted on the grass, so use the world's own `_mesa` builder (collider included) to put low terraces, near and far, either side of the three scored stands, so the ground steps up from lawn to terrace to cliff.

**What the three CPU rounds showed** (`_sheet_cpu_base_top_arm_bottom.jpg` is round 3; base above, arm below; Realm Gate Crag approach, Heartstone approach, Sky Shrine close):
1. Rugged crown, default materials: near-black hulls with grass patches. The rugged crown adds the dark earth bank, and `_mesa` draws every wall band in the brown `cliff_high` material whatever side material it is given.
2. A pale `side_tint` passed as the side material: no change, for the reason above.
3. Flat crown, pale material applied to the wall surfaces after the build: the terraces are now plain pale-grey drums with a noisy scree texture and a ruler-flat top. They have no strata, ledges or broken edge, so beside the installed shelf cliffs they read as generated cylinders, which is the defect class the judges already name on this row ("generator output").

**Why not sent:** I expect round 3 to be level or worse, not a gain. The pale banded cliffs the judges like in these frames are the installed `cloudreach_cliff_shelf_edge` modules from the stand pattern, not `_mesa` output, so the native builder cannot match them without new geometry (banded insets and a broken lip) inside `_mesa` itself.

**Also found:** the Sky Shrine island ends at about x 1074-1146, z 2862-2873 (settlement life warns "no ground" there), so two of the shrine entries stand partly off the island.

**What would be a new idea, not built:** terrace geometry in `_mesa` (two or three inset bands with a 0.3-0.6 m lip each and a turf top that follows a wavy outline), or re-using the installed shelf module itself at 2-4 m visible height with its lip hidden. The second was tried by NEAR6-CR as `shelf_edge_soften` and judged worse. So the row is parked on my side until there is one.
