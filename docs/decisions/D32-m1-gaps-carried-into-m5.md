# D32. Building, stations and harvest nodes are deferred, and M4 shipped without them

Kind: spec-conflict

`ROADMAP.md` puts harvest nodes, tools with durability, the workbench, campfire,
bed, cooking, snap-grid build mode and the satchel drop in M1, before M2. M4
shipped with several of those still missing.

What exists: vitals, inventory, crafting resolution, the faint and satchel
drop, and the save. What does not: harvest nodes on scatter props, tool
durability being spent, placeable stations, cooking, and build mode.

The reason is that none of them are on the path to M4's bar, which is "the game
has a beginning, a middle, and a win state". Orin hands over three Worn Pact
Orbs and a stone axe, and three orbs plus the starter are enough to reach and
beat the Hall. The recipes, the station gating and the `badge_meadow` flag that
unlocks the Orb Bench and the Truestone Orb are all already in `recipes.json`
and honoured by `Crafting.canCraft`, so the systems are waiting on a placement
UI rather than on design.

The cost is real and should be stated plainly: a player cannot currently gather,
cook, build a shack, or craft a better orb. The loop is walk, fight, catch,
progress. Picking those up is the first thing M5 should do, before the polish
pass, because they are what make the world worth crossing rather than a corridor
to the Hall.
