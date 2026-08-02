# D31. Distant landmarks do not cast shadows

Kind: implementation

The Hall sits 900 to 1200m from the village and the standing stones 500 to
700m. Registering them and their NPCs as shadow casters took the scene from 30
casters to 94.

There is one directional light with a 512px shadow map on mobile and 1024 on
desktop, spanning the whole visible world. At that span a building 900m away
contributes nothing a player can resolve, while costing a shadow-map draw every
frame. Measured 94 casters down to 65 by dropping the far landmarks.

Hollowbrook still casts, because that is where the player stands at boot and
where the shadow map has resolution to spend.

The real fix is a cascaded or player-following shadow volume, which is an M5
lighting-pass problem. Until then the rule is: only register a caster within
roughly the village-sized radius the map can actually resolve.
