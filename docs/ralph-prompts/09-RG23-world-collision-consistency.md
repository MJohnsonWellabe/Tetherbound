# RG23 — World collision must match visible geometry

## Goal
Fix the Meadows collision inconsistency reported by the owner: some substantial rocks can be walked through while the player can also become blocked by things they cannot see.

The player-facing rule is simple and must hold everywhere in normal Meadows traversal:

> If world geometry visually reads as a substantial solid object, collision should match what the player sees. Empty-looking space must never block the player.

Do not over-apply collision to tiny decorative clutter. Grass, flowers, small shrubs, tiny ground dressing, etc. remain non-colliding unless an existing explicit design says otherwise.

## Owner report / desired state
Owner report:
- Some rocks can be walked straight through.
- Sometimes movement is blocked by something invisible.

Owner decision:
- Solid-looking world geometry such as substantial rocks, trees, walls, cliffs, buildings, etc. should collide where it visibly exists.
- Empty-looking space must never block the player.
- Tiny decorative clutter should not become collidable just because it is visible.

## Important current-repo context
Read current `main` before editing.

Relevant systems include at minimum:
- `scripts/world/vegetation.gd`
- `scripts/world/scatter_rules.gd`
- the vegetation/scatter configuration that provides each layer's `collides` and `collision_radius`
- terrain/corridor carve and traversal systems
- recent SPINE-WEDGE / RIVER-GATE / CORRIDOR-FIX work
- `tests/smoke_traversal.gd` or equivalent current traversal smoke

Current `vegetation.gd` architecture matters:
- Terrain3D instancing is visual only.
- Collision is created separately.
- `_add_collision()` only creates collision for a layer whose config says `collides: true`.
- Collision bodies are streamed around the player rather than inherent to every rendered instance.

Therefore a visible rock can exist with no physical collider if its layer/config/batch/streaming path does not line up correctly.

Also note that the backlog explicitly says the invisible-blocker family has had several recent fixes already: CarveFailsafe volumes, terrain/corridor trench issues, etc. Do NOT assume those old blockers still exist on current `main`.

## Required approach
### 1. Reproduce before changing
Treat the two reported symptoms separately:

A. Visible substantial geometry with missing collision.
B. Collision in visually empty space.

Reproduce each on current `main` before writing a fix.

For invisible blockers, instrument the actual movement collision result and identify the collider the player hits. Use the runtime collision object / collider identity from movement (`get_slide_collision()` or the project's current equivalent). Do not infer an invisible blocker by sampling terrain height or by guessing from map geometry.

For missing rock collision, identify the actual rendered rock instance/layer/model and trace its collision path:
- authored layer
- `collides` value
- collision radius/shape
- collision batch creation
- current streaming residency
- distance from player / stream-centre update
- harvest-state interactions if relevant

### 2. Fix the shared mechanism, not individual coordinates
Do not hand-place ad hoc invisible walls or one-off colliders around owner-reported locations unless the object itself is a unique authored landmark whose geometry requires that.

If multiple rocks share the same bad layer/model/config path, fix that shared layer/path.

If collision streaming creates gaps, fix streaming/residency logic rather than pinning all collision permanently resident unless measurements prove the existing approach cannot work.

If an old invisible terrain/helper collider is still present, remove or correct the actual helper that causes the collision rather than masking the route.

### 3. Preserve intentional non-collision
Do not make every visible thing solid.

Keep non-blocking decorative content non-blocking, including ordinary small vegetation/clutter where collision would only make traversal frustrating.

Collision should correspond to what a player reasonably reads as a traversal obstacle.

### 4. Preserve harvest and streaming behavior
The vegetation collision path is also tied to harvestable trees/rocks and streamed collision. Do not regress:
- chop → felled → gather flow
- permanently harvested vegetation staying gone
- felled resource state
- collision removal when a harvestable object is chopped
- collision returning/restoring appropriately when world state says the object exists
- Terrain3D instancing / corridor streaming architecture
- handheld performance

## Diagnostics to add/use
During implementation, add temporary or reusable diagnostics sufficient to answer:
- Which visible layer/model does this object come from?
- Does its config claim it collides?
- Was a collision body/shape created for this placement?
- Is that collider currently resident?
- What collider identity stops the player in each invisible-blocker reproduction?

Do not leave noisy per-frame logging in production.

## Tests / verification
Extend current traversal coverage rather than inventing a parallel harness.

At minimum verify:
1. A representative substantial scattered rock from every collidable rock layer blocks the player.
2. Representative substantial tree/solid vegetation layers still block where intended.
3. Decorative non-colliding layers remain passable.
4. Walking the previously problematic corridor/terrain areas produces no collision against visually empty space.
5. Collision remains correct while crossing the collision-streaming boundary rather than only when spawned beside the object.
6. Chopping a collidable harvestable removes its collider together with the visible standing object.
7. Save/load restoration of harvested vegetation does not resurrect collision for a permanently removed object.
8. Existing `smoke_traversal` and relevant harvest tests pass.

Where feasible, include a regression that obtains the actual collider identity on contact so a future invisible helper volume cannot silently return.

## Acceptance criteria
- The player cannot walk through substantial rocks that visually read as solid.
- Other substantial solid-looking Meadows objects collide consistently with their visible footprint.
- The player does not hit invisible blockers during ordinary traversal.
- Tiny decorative clutter remains appropriately non-colliding.
- Collision streaming does not create obvious nearby holes in collision.
- Harvesting correctly removes collision with the removed standing object.
- No regression to terrain traversal, scatter rendering, harvesting, save restoration, or handheld performance.

## Definition of done
This item is done when collision communicates the same world the renderer does: substantial visible obstacles are physically there, and nothing physically blocks the player without a visible reason.

If the invisible-blocker half cannot be reproduced on current `main`, record that evidence and do not fabricate a fix for an already-landed problem; still complete and verify the missing-collision half if it reproduces.