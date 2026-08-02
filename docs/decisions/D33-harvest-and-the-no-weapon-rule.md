# D33. The no-weapon rule is an allowlist, not an absence

Kind: implementation

CLAUDE.md hard constraint 2 says the player never wields a weapon and tools
"cannot target pals or people". Until M2 that was true only because no pal
existed to swing at, which is not enforcement, it is luck.

`Harvest.canTarget()` is now an explicit allowlist: `node` is the only permitted
target kind, and both unknown tools and unknown target kinds are refused. Adding
an entity type later therefore cannot quietly make it hittable; it stays
unhittable until somebody deliberately changes this function, and six tests fail
if they do.

Drops are seeded from the node key and the in-game day rather than
`Math.random()`, for the same reason world generation is seeded: a reload must
not reroll the tree the player just chopped, and a bush must give something
different after it regrows.
