# THINGS-BEDROOMWOOD: calmer wood in Grandpa's loft (F38#19 close-out)

**Row.** F38#19 exploration HUD, 7.17 at Medium (`G-closeout-meadows-ui.md`). Judges, 3/3: "the HUD is now moderate. What holds it is the bedroom scene: oversaturated orange ceiling and floor, and blown windows."

**Change** (overlay only, one value): `building_prefabs.json prefabs.farmhouse_shell.interior_floor_material.tint` `#c9b49b` to `#7f8a92`. The floor, loft slab, stair treads and flat ceiling of Grandpa's house all take this one tint over the same wood-grain texture; a cool grey-blue multiply pulls the orange down to a mid brown and darkens it a little. Texture, geometry and collision unchanged.

**CPU** (`_sheet_bedroom_wood_cpu.jpg`; left main, right arm): the ceiling and floor go from saturated orange to brown; the grain still reads; the walls, window frames, bed and HUD are unchanged. (Both CPU frames are dim overall; that is the CPU capture, not the arm.) A milder tint (`#8f8a82`) was tried first and still read orange.

**Not addressed.** The blown-out windows.

**Scope.** `farmhouse_shell` is Grandpa's house; this is the first room a player sees.

**Ask.** `meadows__exploration_hud`, base vs arm, High; Medium if it reaches 7.5.
