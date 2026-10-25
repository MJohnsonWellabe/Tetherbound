# Veilfall cliff facade: placement note (close-1024, 24 Oct 2026)

- **Wall:** the west wall of the veilfall-near gully. That is the right-hand side of the F39-look `veilfall-near` frame, low x.
- **Where the trail is:** the `veilfall_exploration_spine` hike (4 m wide) runs up the gully floor at x 372-375. Its last leg comes in from the west to the gate at (335.2, 139.4, 3885.7).

| Property | Value |
|---|---|
| Centre (world x, z) | (338.0, 3836.0) |
| Facing normal (xz) | (0.902, -0.431), between the trail (+x) and the veilfall-near stand at (387.3, 3799.4) |
| `yaw_deg` | 115.5 (the asset's front faces local +Z) |
| Ends of the 35 m face | (330.5, 3820.2) and (345.5, 3851.8) |
| Ground under the face | about 30-40 m at the south end, about 60-65 m at the north end (terrain probe). The facade stands on its base with its flat back against the rising slope. |
| Clearance from the hike centreline | 35.8 m at the centre; 24.8 m minimum from the front face (base corners plus a 3 m front offset) |

The test `test_veilfall_hero_pieces_stay_clear_of_the_hike` (15 m minimum) applies once the facade is added to `veilfall_hero_candidate`.

- **Scale:** 35 m wide, 30 m tall, 6 m deep, about 17 times the 1.80 m trainer (`scale_check.png`).
  - Fit by height, uniformly, never stretched.
  - Sink about 2 m so the base meets the slope.
- **Gate:** presentation only, with no collider needed, because it sits off the trail on an unwalkable slope.
  - It stays OFF until a judged round on veilfall-near/rain beats the shipping close-up.
  - The Venn fight frames also need judging as matched moments.

## Inputs

- `board_right_cliffs_falls.png`, `board_left_cliffs_falls.png`: crops from the owner's Veilfall exterior board, with the caption, trainer, companion, bridge, arch and hut removed.
- `board_stone_swatches.png`: the board's stone, mossy stone and wet rock swatches, labels removed.
- `prompt.txt`
- `scale_check.png`
