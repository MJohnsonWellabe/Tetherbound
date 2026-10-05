# F17#0 overhead plan and topology — R1 (tb/f17 f63bac26)

    godot --headless --path . --script tests/run_tests.gd -- --only=test_village_redesign_topology,test_village_road_topology,test_village_boundary

Result: 33 tests, 3691 assertions, 0 failed (`unit.txt`). `test_village_redesign_topology` asserts the straight
road from the farm door (8.3, 14) to the Hall (91 → 107, 14), 8–10 houses facing it on both sides, the homestead at
the road's start and the Hall nave at its end.

F17 changes since the audit (the Hall tower, gables, lights and retint, and the interior ambient) add modules, lights
and materials only. No house, road, door or Hall placement moved. The real-world walk witnesses
(`../reproof-r1/`, `../f01-2-visits-day-r2/`) pass on that layout. The overhead frame
(`tests/capture_village_overhead.gd`) was not re-captured.
