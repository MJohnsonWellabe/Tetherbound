# D29. The Hall meets the terrain, the terrain does not meet the Hall

Kind: implementation

The Meadows Hall is placed on a seeded search for flat ground, which is allowed
to settle for the flattest candidate it saw rather than failing. The first
version handled the leftover unevenness by raising the floor onto a plinth
sitting at the highest ground under the footprint.

That looked right in a screenshot and was unplayable. The character controller
is a capsule against the heightfield with no physics engine, by design
(`ARCHITECTURE.md`), so it knows nothing about a platform mesh. The player and
every combat pal stood on the terrain, more than a metre below the floor they
could see, inside the plinth. Two of the three Hall fights happen in that room.

The floor now sits at the terrain height of the Hall's centre and the plinth
hangs downward from it, deep enough to bridge a dip. The building meets the
ground the player actually walks on. Residual slope shows as a stone floor set
slightly into the earth at one end, which reads as age rather than as a bug.

The general rule this establishes: without a physics engine, anything the
player stands on has to be the heightfield. A structure may decorate the ground
but may not replace it.
