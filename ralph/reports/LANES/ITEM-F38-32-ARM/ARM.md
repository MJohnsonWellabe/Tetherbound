# F38#32 camp and workshop prop legibility: config-only arm

**Overlay:** `overlay_camp_spacing.json`. This is a path-patch: each key is a JSON path into the named file, and only those fields change.
**Capture:** F38#32 frames (camp_tent, camp_bed, bonfire_fire), live main vs arm, High.

## What the current frames show (checked before writing the arm)

The GPU F38#32 frames (`manifest-B`) were shot on tree be95950b. A CPU capture of `meadows__inventory__prop__camp_tent` on current main data (camp files identical to origin/main 4af7d07a) shows a different picture.

**The big CAMP sign is no longer in the stand's foreground.**
- The approach stand is at (338.5, 930.9), looking north at the player at (338.5, 936.0).
- The TRAIL CAMP threshold (`clusters[6].roadside_threshold`, at (346.3, 926.3)) is behind the camera.
- So the sign needs no move, and moving it would affect the road threshold for nothing.

**Two overlaps remain in the stand's view:**
1. **The "trail_*" stores sit dead on the camera-to-player line.** These are `meadows_catalog_presentation.json` placements 81–84: the water barrel, bucket, provision crate and cook pot. The barrel stands between the lens and the trainer, with the pot and bucket at its feet.
2. **The camp Bench overlaps the camp bed.** The Bench is `props.json` `clusters[6].props[2]`, at (341.7, 936.0). It lies across the camera's line to the camp bed, so the plank reads stacked on the bed.

**The "white row on the horizon" is not scatter.** At full resolution it is a line of wild creatures on the far hillside: pale coyotes, deer and fuzzy white owl-like creatures. These are spawns, so the arm leaves them alone. Moving spawns is a gameplay change. If they still read as a row after this arm, it is a spawn-layout question for the build lane.

## The arm

| Item | From | To |
|---|---|---|
| `trail_water_barrel` (placements[81]) | (338.2, 934.6) | (340.6, 939.6) |
| `trail_water_bucket` (placements[82]) | (337.35, 934.0) | (340.0, 939.0) |
| `trail_provision_crate` (placements[83]) | (337.9, 935.7) | (341.3, 940.3) |
| `trail_cook_pot` (placements[84]) | (338.95, 935.7) | (340.2, 940.4) |
| Bench (clusters[6].props[2]) | (341.7, 936.0), yaw 113.5 | (345.2, 933.0), yaw 200 |

- **Stores:** they become one group on the trodden camp floor beside the tent, off the stand line and clear of the bed's sightline.
- **Bench:** it moves to the open south-east side of the fire, still inside the rest circle: 3.7 m from the rest centre (344.3, 936.6), radius 4.6. It is 2.1 m from the creature bed and clear of the tree-log seat and the firewood.

No red. No camera or stand change. No change to the rest radius, craft point, creature bed, threshold or spawns.

## CPU check

`_sheet_cpu_before_after.png` shows the camp_tent stand on CPU (opengl3, Compatibility): live on the left, the arm applied locally on the right. With the arm:
- The foreground is clear.
- The camp bed reads on its own in front of the tent.
- The stores read as one group by the tent.

The local edit was reverted after the capture; this branch carries no game-file change. The CPU check covers only the camp_tent stand. The camp_bed and bonfire_fire frames were not re-shot, so check them in the GPU capture.

## GPU result (G-scout-arms.md): −0.35, 1/3; not shipped

- **The CPU stand check did not match the GPU stand.** On the GPU capture of main 4af7d07a9, the CAMP threshold board is in the camp_tent frame's foreground on both sides. So "the sign needs no move" is wrong for the GPU stand.
- **Moving the stores away from the lens made the props read smaller and less legible,** so the arm lost.
