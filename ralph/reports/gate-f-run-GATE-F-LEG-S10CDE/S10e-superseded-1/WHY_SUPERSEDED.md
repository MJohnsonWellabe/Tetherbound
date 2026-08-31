S10e attempt 1: completed (32 pass/3 fail/0 delegated) but never actually
finished the chapter -- meadows_acknowledged was NOT set. Root cause: the
single-leg move_to at S10e-99 (straight to the village centre, 10,-10) does
not cross the village fence anywhere near its one gate
(playground_world.gd::GATE_AT, 27.5,-16.0), so stick_navigator.gd (a local
wall-follower, not a pathfinder) oscillated against the fence for its whole
60750-frame budget, stopping 28.4m short -- too far from any villager to
open a conversation, so no flag:meadows_acknowledged ever fired. The
Grandpa leg (S10e-103) then also fell 6.5m short of its own target because
it started from much further away than intended (the village-centre miss
above) with too little budget (3000 frames) to close a since-unexpectedly-
large gap -- that leg was steadily making real progress, not stuck.

Fixed in tools/gate_f/segments/S10e.json: split S10e-99 into a new
S10e-98g (walk to the gate first) + the original S10e-99 (gate to village
centre), the same "aim at a real waypoint, not straight at the final
target" fix S05-19's own outbound leg already uses; and doubled
S10e-103's budget_frames (3000 -> 6000) for margin. Re-running S10e fresh
from the same S10d-exit.
