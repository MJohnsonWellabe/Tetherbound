# Routes close-1020: work note (F49#0 + F19#5, F49#3, F47#0)

Cloud container, Godot 4.7 headless. Branch tb/routes merged with origin/main 2124b1f6c.

## training_t1_altar_1 stall (17 Oct): diagnosis and fix
- Symptom: `EARNED WALK START purpose=harvest rootstone final target=(399,-0.5,1792)` from home (-22.7,2.1,22.7), then ~20 min silent until killed.
- Cause (helper routing, not a game bug, not only a timeout): the Altar costs stone 10, rootstone 4, ironwood 2. Rootstone exists only in the quarry beyond the South Bridge gully (`terrain_playground.json` crossing carve: centre (8,1330), axis 0, half_length 1040, i.e. a gully across the whole meadow at z≈1330). `meadows_earned_material_segment.gd` admits supplies past the crossing once the bridge is open, but `_walk_target` only routed the village fence. The straight line home→quarry meets the gully near x≈286, 280 m east of the span; the navigator's confined-reset watchdog never fails a leg, so it circled at the rim for the whole 106k-frame budget (240 + 60/m × 1770 m).
- Fix (smallest): `_walk_target` inserts the authored bridge approach, near bank and far bank (the same points `altar_training_piece.return_to_bridge` uses) when the player and the supply are on opposite sides of the open bridge, in either direction. Same-side and closed-bridge walks are unchanged (camp/tournament paths unaffected).
- Focused test: `tests/test_material_bridge_legs.gd` (2 tests, 9 assertions, pass).
- Alternatives checked: no existing helper path routes homestead gathering over the bridge; the Fights altar helper reuses this material segment.

## Pieces
| Piece | Root | SHA | Wall | Result |
|---|---|---|---|---|
