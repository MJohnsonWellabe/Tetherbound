# B1: runtime-filled MultiMeshes and the detail cull

**The blocker (review of `cc22c6c5`):** `detail_cull.gd` ranged a MultiMesh that was empty when measured as if it were narrow. `pickup_glow.gd` builds its Motes and Auras layers empty and fills them later with every glowing pickup in the realm. Both layers were therefore ranged by one 2 m quad, at about 617 m. Godot tests that range against the centre of the layer's whole box, so a pickup far from the centre of all pickups lost its halo, on host and guest alike.

**The fix (`25f3fce2`):**
- A MultiMesh with fewer than two instances when measured, or with several instances that all read one origin, has an unknown spread and is never ranged.
- pickup_glow's layers and the move/ultimate VFX motes carry `detail_cull_skip`.
- A ranged MultiMesh's range is pushed out by its half-diagonal, so its nearest instance never stops drawing before its own reach.
- The spread maths is a pure function, unit-tested on transforms in `tests/test_detail_cull.gd`. The empty-at-apply and single-instance tests fail on `cc22c6c5` and pass at `25f3fce2`.

## Evidence

**Subject:** the glowing pickup at (-48, 7492), 3,877 m from the centre of Meadows' 211 glowing pickups. The camera is about 7 m from it. Captured in the production Meadows scene, Compatibility renderer under xvfb, 1280x720, clear weather, time pinned.

| Run | Motes / Auras `visibility_range_end` |
|---|---|
| `cc22c6c5` | 617 m / 617 m |
| `25f3fce2`, cull on | 0 (unranged) |
| `25f3fce2`, cull off | 0 |

The values are in `cc22c6c5.json`, `cull_on.json` and `cull_off.json`.

## Code-blind judge

The four pairs were relabelled X/Y at random (`judge_key.json`, frames in `judge/`). The judge saw only the images.

| Pair | Comparison | Verdict |
|---|---|---|
| 1 | cull on vs cull off, day | EQUIVALENT (only cloud drift) |
| 2 | cull on vs cull off, night | EQUIVALENT |
| 3 | fixed vs `cc22c6c5`, night | Fixed better: `cc22c6c5` loses the halo and light pool |
| 4 | fixed vs `cc22c6c5`, day | Fixed better: `cc22c6c5` has no halo |

**Result:** with the fix, the cull no longer changes the glow, and the old build's missing glow is reproduced and fixed.

## Batching cost of the review hardening

`static_mesh_batch.gd` no longer merges:
- materials that depend on per-object space;
- meshes with anything drawn beneath them.

The Meadows village now folds 768 module meshes, down from 797. At Meadows stand_0, draws rose from 5,388 (`../probe/meadows_cull.json`) to 5,584 (`../probe/meadows_b1.json`), about +3.6%, against 8,648 before batching. The probe was stopped at its time limit after stand_0, so only stand_0 was measured.
