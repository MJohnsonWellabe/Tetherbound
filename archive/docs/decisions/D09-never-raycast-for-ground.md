# D09 — Never raycast for ground height

> Vocabulary note: written when the game called its creatures "pals"; R1.1 (2026-08-14) renamed the term to "creature" throughout the codebase without rewriting this historical record.
**Status:** accepted
**Found during:** M3, while spawning a second wild pal

## The decision

Anything that needs to stand something on the ground asks the world for the
height — `playground_world.ground_height_at(x, z)`, which reads Terrain3D's own
data. A downward raycast is a fallback for surfaces the terrain does not know
about, never the primary method.

## What happened

M3 added a second wild creature. It never appeared. No error, no body, no
encounter — the spawn simply did nothing, and the milestone's first smoke test
failed with "the player has no pal to fight with" because the director was stuck
retrying a placement that could not succeed.

The placement was a downward raycast. Measured across the playground, **roughly
a quarter of downward rays against Terrain3D's heightmap collision return no hit
at points where the ground is unquestionably present.** At the same coordinates:

- `data.get_height()` returns a sane value.
- A sphere query at ground level collides.
- The character walks over it without falling.

The pattern is stable, and is unaffected by `collision_mode`,
`collision_shape_size`, `collision_radius`, camera position, ray length, or an
explicit `Terrain3DCollision.build()`.

## Why nothing had caught it

`move_and_slide` uses **shape casts, not rays.** The world has always been solid
to walk on, so the M1 traversal smoke — which walks 266m in four directions and
asserts the player never falls through — passed honestly and still does. Rays
were the only thing lying, and until M3 nothing except the player's own spawn
depended on one.

The player's spawn never broke because `playground_world._place_player()`
already used `data.get_height()`. That was written for a different reason and
accidentally sidestepped the whole problem for a milestone and a half.

## The lesson, which is not about Terrain3D

The M1 traversal test walked four legs from spawn and reported the ground solid.
It was right, and it would also have been right if half the map had been missing,
because the legs it walks stay in one quadrant. A test that samples one path
through a world cannot say anything about the world.

The general form: **when a check and the thing it is checking use different
mechanisms, the check is testing the mechanism.** A raycast probe does not verify
what a shape-cast character will experience, in either direction.

## What this does not claim

Terrain3D is not at fault in any way this project has established. The behaviour
was reproduced and worked around; it was not root-caused into the extension, and
the version here is pinned (see `D05`). If a future version behaves differently,
the fallback path already exists and the primary path is still correct.

## Consequence for later milestones

M8 builds structures, and M7 adds rocks and props. Those are not in the
heightfield, so a ray is the only way to stand something on top of one — which
is why the fallback stays rather than being deleted. The rule is about ORDER, not
about banning raycasts: ask the terrain first, and fall back to a ray only for
what the terrain has never heard of.
