S10c attempt 3, run against the FIRST (buggy, backwards-direction) version
of the gorge-carve failsafe fix. Both move_to legs still failed, pinned at
(19.0,-7.0,7372.0) -- inside sigil_gate_gorge_west's own diagonal carve.
Diagnosed and fixed for real in a follow-up commit (recovery-direction bug
in road_gate.gd::_hang_gorge_failsafes -- see that commit's message and the
_hang_gorge_failsafes doc comment). Verified with
tools/_probe_gorge_failsafe.gd against this exact pin point: the corrected
fix now lands the player on genuinely safe, walkable ground (terrain-carve
depth 0.79m, ~13 degrees, comfortably under the 45-degree floor_max_angle --
confirmed by direct calculation against terrain_playground.json's own carve
profile), not still inside the trench. Re-running S10c fresh.
