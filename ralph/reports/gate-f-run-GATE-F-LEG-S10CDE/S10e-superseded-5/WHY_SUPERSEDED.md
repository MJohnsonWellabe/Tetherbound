# S10e, attempt 5 -- superseded

`INVENTORY.json`: `complete: false`, 19 pass / 2 fail / 15 skipped,
DERAILED at `S10e-105`. Restart 4's fix held cleanly for the village leg:
`S10e-102` (`advance_dialogue_until_closed` against Tam's `village_tam_freed`)
opened and closed the conversation in three ticks with no over/under-press,
and `S10e-102w`'s "world owns input" assert passed for the first time in
this lane.

## New defect: the Grandpa leg walked around the house instead of through the door

`S10e-103` (straight `move_to` at Grandpa's real marker, `(-24.4,-14.8)`,
the restart-3 fix) failed outright this time: "did not reach (-24, -15) in
12000 walking frames; stopped 4.8 m short at (-27.0, 1.0, -11.0)". That
stop position is OUTSIDE the house's own footprint on both axes
(`grandpa_house.gd`'s `INNER_W`/`INNER_D` put the house's world footprint
at roughly x in [-26.7,-17.3], z in [-18.7,-13.3]; -27.0,-11.0 is past the
west wall and past the north wall) -- `stick_navigator.gd` (a local
wall-follower, not a pathfinder) walked around the OUTSIDE of the house
toward the target instead of through the doorway on the east wall, and
stalled at the north-west exterior corner it could not route past.

Not a game defect: the door is confirmed open (`_refresh_door_gate()` holds
it for any beat at or after `walk_out`) and nothing about the house's
collision changed between attempt 4 (which took the same straight-line
target and got lucky) and this one -- it is the same class of "aimed at
the abstract destination instead of the real passage point" failure
`S10e-98g`'s own header already diagnosed for the village gate, this time
against a doorway rather than a gate opening. `S10e-105` then correctly
BLOCKERed rather than mis-firing: `advance_dialogue_until_closed` found
`input_context: world` (nobody's dialogue was open, because `S10e-104`'s
interact never landed near Grandpa) and refused to press a button into the
world.

## Fix applied

`tools/gate_f/segments/S10e.json`: split `S10e-103` behind a new
`S10e-103d` waypoint at `grandpa_house.gd::marker("door")`
(`(-15.7,-16.0)`), the same shape `S10e-98g`/`S10e-99` already use for the
village gate. Budgets rebalanced 12000 -> 6000/6000 now that each leg only
covers its own short distance (the village-to-door approach, then the
~8.8 m interior walk from the door to Grandpa's marker) rather than one
leg covering both.

Re-running S10e (attempt 6) from the same `S10d-exit.json` seed.
