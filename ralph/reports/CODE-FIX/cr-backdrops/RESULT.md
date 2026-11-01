# P2-076: Cloudreach Kelm/Veyra dialogue backdrops (STOPPED after two attempts)

**Branch:** `tb/world-cr-backdrops`, from main 902671a0.

**Flag:** `cloudreach_look.json` → `dialogue_backdrops.enabled`, which ships `false`.

**Builder:** `scripts/world/cloudreach_dialogue_backdrops.gd`, called from `cloudreach_look.gd`. It lays installed Quaternius `Floor_UnevenBrick` slabs and installed props behind each speaker. Everything is visual only: there is no collision, and speakers and cameras are not moved.

## Result (CPU, flag off vs on, `phase2_capture_dialogue.gd --biome=cloudreach`)

**Props work.**
- Kelm: barrels, crates and a bag now stand behind him.
- Veyra: crates, a barrel and a weapon stand stand by the plaza wall. They read small at that distance.

**Paving does not read.**

| Attempt | Change | Result |
|---|---|---|
| 1 | Slabs sunk 2 cm | Invisible. The mesh is only ±1 cm thick, so the slabs were buried under the ground. |
| 2 | Slabs lifted 3.5 cm | Still nothing behind Kelm. Behind Veyra, only a pale strip at the far edge. |

Two likely causes:
- The flatness test (±0.18 m across a 2 m slab against `ground_height_at`) is rejecting most tiles on these mesa tops.
- The analytic ground and the visible crown surface may differ.

Per the stop rule, I'm parking this until there is a new idea. The next idea would be to place slabs by raycast onto the actual crown collider, instead of using `ground_height_at`, and to log the placed and rejected tile counts.

**Not READY.**
