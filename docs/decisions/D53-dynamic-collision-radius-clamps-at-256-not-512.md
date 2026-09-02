# D53 — Dynamic terrain collision: the vendored addon clamps `collision_radius` to 256, not the 512 §8.2 assumed

**Date:** 2026-08-16 · **Decided by:** `ralph/BAKE-GUARDS`, correcting
`docs/specs/MEADOWS_MACRO_LAYOUT.md` §8.2

## The finding

`MEADOWS_MACRO_LAYOUT.md` §8.2 recommended `collision_mode = 1` (Dynamic/Game),
`collision_radius = 512`, `collision_shape_size = 64`, reasoning that 512 m is
"59 seconds at `sprint_speed` 8.6 — the player cannot outrun it by any margin
that matters." That reasoning assumed the requested value is what gets applied.

Verified against the vendored Terrain3D build with `tools/_probe_terrain_
collision.gd` (sets a value, reads it back, in-tree): `collision_radius` is
**silently clamped to [16, 256] step 16**, and `collision_shape_size` to
**[8, 64] step 8**. Neither setter errors or warns on an out-of-range request;
it just returns a different number than the one set. Requesting 512 gets 256.
Requesting 64 for shape_size lands exactly, because 64 is already the max.

`scripts/world/playground_world.gd`'s `_apply_dynamic_collision()` now reads
both values back after setting them rather than trusting the requested
constants (`COLLISION_RADIUS_REQUESTED`, `COLLISION_SHAPE_SIZE`), and
`tests/smoke_traversal.gd` asserts on the readback, not the request.

## What this changes about §8.2's margin

At the actual granted radius (256 m, not 512), the "player cannot outrun it"
margin is **256 / 8.6 = 29.8 s at sprint**, not 59 s. Still comfortably more
than any single incremental-rebuild hitch, and the margin the corridor's
±1024 m width and 8192 m length need is about outrunning a *radius*, not a
world dimension, so this does not by itself invalidate dynamic collision as
the streaming answer for the corridor bake. It does mean:

- Anyone re-deriving the "cannot outrun it" argument for the corridor should
  use 256 m, not 512 m, as the granted radius.
- If 256 m turns out to be too tight once the corridor exists (a mount at
  higher sprint speed, a burst of forward movement after a settle), the fix is
  not "ask for a bigger radius" — 256 is the addon's hard ceiling on this
  vendored version. It would need either a version bump (unverified whether a
  newer Terrain3D raises the ceiling) or a different mitigation entirely (e.g.
  a camera-ahead bias on `set_camera`, or accepting FULL_GAME only on the
  bands already loaded).

## Not yet measured

The frame cost of an incremental dynamic rebuild step at radius 256 / shape
size 64 is still unmeasured on real hardware — §8.2's own caveat. This
decision fixes the *ceiling* number, not the runtime cost of hitting it.
