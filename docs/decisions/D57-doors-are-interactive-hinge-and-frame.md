# D57. A door is a leaf on a hinge pivot, separate from its frame

Kind: implementation

`wood_door` is a new build piece, distinct from `wood_doorway` (an open
frame with no leaf — GAME_DESIGN.md section 8 lists them as two different
pieces, and only the frame had ever been implemented). Placing a door gives
you something you can open and close, not just walk through.

**The shape:** the piece's own box (used for every other piece) is built but
disabled for a door — the frame is not what the player sees. A separate leaf
mesh is parented to a `TransformNode` pivot positioned at the piece's hinge
edge. Rotating the pivot swings the leaf like a real door; rotating the leaf
itself would spin it around its own centre, which reads as a rotating slab,
not a door opening.

**The swing:** `src/building/Door.ts` is pure, engine-free hinge-angle math
(`stepHinge`/`targetAngle`/`hingeSettled`), tested before the mesh code that
uses it, per the working agreement. The angle eases linearly in TIME rather
than in angle-remaining, so the swing takes the configured `doorSwingMs`
whichever direction it is going and however far through a reversal it is
interrupted — a linear-in-angle version would finish instantly if reversed
near the target, which reads as a snap.

**Doors animate independent of build mode.** `BuildMode.updateDoors(dt)` runs
every fixed step unconditionally, not gated by `hammerEquipped` the way
placement is. A door has to keep swinging, and stay interactable, after the
player puts the hammer away and walks up to it — which is the entire point of
a door.

**Interaction priority:** a door within `doorInteractReach` claims the
interact button for that press, ahead of a harvest swing, the same way
`busyTalking` already claims it ahead of harvest. Standing at a door with a
harvestable bush behind it must open the door, not chop the bush.

**Save:** `PlacedPiece.open` is optional and absent means closed, so an old
save with no door in it (or a door piece added before this field existed)
loads without a migration. `restore()` reconstructs an already-open door at
its resting angle directly — it does not replay the opening animation on
boot, which would mean every door in a base swings open the instant you load.

**Sound is stubbed**, per the pattern the harvest system already uses:
`doorToggled` carries the door's world position on the event bus for a future
audio layer to place a 3D open/close sound, same shape as `harvestSwing`.

**Not done, and deliberately not attempted here:** built pieces (walls,
floors, doors — all of them) do not currently participate in the character
controller's collision system at all; `BuildMode`'s meshes are `isPickable =
false` and never registered with `world.collidersNear`. Making a door's
collider open and close with it, as the brief asked, would be adding new
behaviour to one piece type while every other wall in the game stays
walk-through, which is a stranger inconsistency than the one it would fix.
Collision for built pieces in general is the real gap and is a separate,
larger piece of work than a door hinge.
