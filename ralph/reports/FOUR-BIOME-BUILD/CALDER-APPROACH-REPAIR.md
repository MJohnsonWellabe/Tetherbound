# Calder approach repair — 2026-09-08

The continuous late-Tidewake diagnostic reached the authored Twin Pumps spine
point at (904.068,93.162,2864.590), but the direct approach to Calder's former
central-crown position ended at (788.349,62.516,2870.969), 92.7 m in 3D from
his prompt at (836,115.767,2930). This proves that direct tested approach stood
below Calder across the graded cut; it does not claim every possible island
loop was impassable.

`data/config/water_characters.json` moves only Calder's island-local X/Z offset
from (-18,-30) to (-107,216). His new world X/Z (743,3176) is 15.2 m upstream
of the authored departure-spine waypoint beside the east control. His three-
creature team, level, rank, dialogue, combat profile, rewards and defeat flag
are unchanged. No terrain or combat rule changed.

Runtime evidence:

- Log: `C:/Users/mattj/AppData/Local/Temp/water-continuous-calder-instrumented.log`.
- +558.0 s and +615.8 s: ordinary player input reached departure-spine
  waypoints 4 and 5 respectively.
- Between Bex and Calder, real GUI input assigned Aquaryn to the authored
  Sluice creature bed; ordinary overnight-rest input advanced the day, fully
  recovered it, and controller input redeployed it. No HP injection occurred.
- +687.4 s: all three Calder opponents were defeated through real combat input.
- +690.4 s: the east control completed the combined-control flag and the
  diagnostic verified the final crossing barrier was removed.
- Focused Water encounter runtime-data suite: 9 tests passed; JSON, parse and
  diff checks were clean.

This is a synthetic-start late-route diagnostic: its initial level-60 Aquaryn
and prerequisite state are disclosed fixtures supplied before departure. The
evidence proves Calder's encounter and east-control progression are playable;
it does not prove the ordinary level-49 Mosshell path or a fresh-save journey.
The same run then found the next separate suffix blocker: production mounting
was refused at Sluice departure. No Water-ending completion is asserted here.
