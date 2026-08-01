# D07. Reconciliation chooses a winner; it never merges

Kind: implementation

GolfModel's `mergeProfiles` blends two copies of a profile field by field:
grow-only counters take `max`, collections union, coins derive from earned
minus spent. That is correct there because a golf profile is an accumulation of
independent facts.

A Tetherbound save is a world snapshot. Blending two divergent copies produces
a world that never existed: a house standing where the player never built, an
inventory holding wood they already spent. So `SaveReconcile.reconcile()` is a
pure, total function that picks a winner, and when it genuinely cannot tell, it
asks the player.
