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

## Attempt 3 (coordinator-approved, final)

**Change:**
- Slabs and props are placed by a ray cast down onto the real static ground collider, skipping characters and creatures.
- The ray cast waits two physics frames so the colliders the realm just built can be queried.
- Placed and rejected counts are logged.
- Veyra's props moved nearer (27–29 m) and scaled to 1.25–1.3.

**Log:** `Backdrop_kelm paving placed=40 rejected=0`, `Backdrop_veyra paving placed=162 rejected=0`.

**CPU capture:** the paving is still not visible behind either speaker. Veyra's props now read a little better at the wall, and Kelm's props are unchanged.

Every tile was placed, so placement is no longer the problem. What remains is how the slab renders here. Possible causes:
- The Floor_UnevenBrick material or colour blends into the plaza ground at this distance.
- The slab draws under the realm's crown surface.
- The mesh is culled from this view angle.

**Stopped as agreed; no further attempts. Not READY.**
