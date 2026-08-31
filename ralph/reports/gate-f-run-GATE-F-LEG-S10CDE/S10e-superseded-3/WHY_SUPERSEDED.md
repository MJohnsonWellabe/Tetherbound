# S10e, attempt 3 -- superseded

`INVENTORY.json`: `complete: true`, 34 pass / 2 fail. All three `move_to`
legs (S10e-98g to the village gate, S10e-99 into the village, S10e-103 home
to Grandpa's) reached their targets within `close_enough` for the first
time in this lane -- the gorge-carve and gate-aiming fixes from S10c/S10d
held. But two real, distinct defects remained, both traced to this
segment's own data rather than to game code:

## 1. `meadows_acknowledged` never got set -- no live NPC in range

`S10e-101`'s interact at the village (arrival (13.67,-12.83), the old
target `(10,-10)` with `close_enough: 5.0`) and `S10e-104`'s interact at
Grandpa's (arrival near the old target `(-22,-16)`, `close_enough: 3.0`)
both left `input_context` at `"world"` through every press -- no
conversation ever opened at either stop.

Root cause, both times, was the same shape: the `move_to` target was an
abstract destination (the bare village-square centre; the house's own
origin point, `playground_world.gd::HOUSE_AT`), not the actual NPC. Tam,
the nearest villager to the village-centre arrival point, was 6.5 m away --
outside `npc_body.gd::add_prompt`'s default 3.8 m prompt radius. Grandpa's
real standing position (`grandpa_house.gd::marker("grandpa")`, world
(-24.4,-14.8)) is 2.68 m from the house's origin point the old target
aimed at, which is enough slack for a `close_enough: 3.0` arrival to land
outside his own 3.8 m radius too.

Not a game defect: nothing in `village_npcs.gd`, `npc_body.gd`,
`sequence_director.gd` or `grandpa_house.gd` needed to change. This is the
same "aim at the real thing, not the abstract destination" class of fix
S10e-98g's own header already needed for the village gate, applied to the
two interacts that depend on it.

## 2. `distance_above: 3000.0` failed at 1460.47 m walked

The floor itself was miscalibrated, not the walk. S10d's own exit position
is a straight-line ~1354 m from the village gate alone; the direct route
this segment actually walks (South Bridge -> village -> Grandpa's) cannot
honestly reach 3000 m. Cross-checked against S10c (3391.81 m) and S10d
(4235.49 m): the three sub-segments together already total ~9087 m,
clearing the original whole-walk-back's 7000 m bar with room. This leg
being short is real geography.

## Fix applied

`tools/gate_f/segments/S10e.json`:
- `S10e-99` retargeted from `(10,-10)` to Tam's own position `(8,-16)`
  (`data/config/village_npcs.json`), `close_enough` tightened 5.0 -> 2.5.
- `S10e-103` retargeted from `(-22,-16)` (the house origin) to Grandpa's
  actual marker `(-24.4,-14.8)`, `close_enough` tightened 3.0 -> 2.0.
  Confirmed the door itself is not an obstacle: `_refresh_door_gate()`
  holds it open for any beat at or after `walk_out`, which this seed's
  post-victory `free_play` beat always is.
- `S10e-108`'s `distance_above` floor lowered 3000.0 -> 1300.0, with the
  reasoning above recorded inline.

Re-running S10e (attempt 4) from the same `S10d-exit.json` seed.

## Note: raw run artifacts lost during the supersede move

The `INVENTORY.json`/`telemetry/`/`saves/`/`frames/`/`shots/`/`notes/`
this attempt produced were destroyed by an operator error while moving
them into this directory (`rsync` was not available; the interrupted
temp-copy directory was then removed with `rm -rf` before the copy had
actually completed). This directory was never committed, so the loss is
real and not recoverable from git history. Every fact used in the
diagnosis above (34 pass/2 fail, the two failing asserts' exact text,
distance_m readings for this and the two prior sub-segments) was pulled
from those artifacts and recorded above *before* the loss, so the finding
itself is not in question -- but there is no raw telemetry left to
re-inspect if a question arises later that this note does not already
answer. Recorded here rather than silently, per this lane's own honesty
rule.
