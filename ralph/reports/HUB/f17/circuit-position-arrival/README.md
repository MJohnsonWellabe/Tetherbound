# F17#2 Hall circuit: legs end on position (5/5)

Fix 4c480579, on code at 4c480579. Before the fix, 2 of 5 local runs failed: after open-floor sidesteps, the leg to the Shrine
doorway ended on arc progress with the body 0.855–1.02 m to the side, and the unchanged 0.75 m gate refused it. A
standing-capsule probe found no collider at any sidestep point.

Change: `capture_village_walk.gd` gains an opt-in `_arrive_within_m`, which defaults to 0 and leaves every other walk
unchanged. When it is set, a leg completes only within that distance of the path end, and closing on the end counts as
progress for the stall clock. The circuit sets 0.6 m per leg. The 0.75 m gate, the tolerances and the refusal reasons
are unchanged.

Result: `tests/smoke_crossing_hall_circuit.gd`, run five times headless, **5/5 exit 0**. Runs 3, 4 and 5 each include one sidestep,
the case that used to fail (`runs.txt`, `key-lines.txt`).
