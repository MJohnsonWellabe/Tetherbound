# THINGS-WETPATH3: Cloudreach wet ground and trail, round 3 (night stands down)

**History.** LANE-PLACES built `cloudreach_visual.json ground_wet_path_1112` (flag-off). Round 1 and round 2 were both splits; the verdict for round 2 was routed to this lane (`G-places-wetpath-r2`, 4baf68e3): gate clear 6.41 -> 7.06 (+0.65), gate rain +0.56, summit day rain +0.56 (3/3 each), overlook rain level, **summit night rain -0.12** ("a dark soot-like smear"). LANE-SCOUT: "make the darkening skip night completely, re-capture p88 to confirm the night L values match base, and then it ships on the day gains."

**Rows.** F40#0, F40#19 (and F40#21 through the same matrix).

**Why round 2 still darkened at night.** Its fade followed the sky's value against day, which left part of the darkening at 23:00, and the duller trail tone was not faded at all.

**Change (round 3).** The clock gates the arm first: `wet_hours` [5, 7, 18, 20]. Outside those hours the wet darkening, the duller trail tone and the wider feather are all zero, so a night frame is main's; they ease in over dawn and out over dusk. Day behaviour is round 2's, unchanged. The PLACES code (weather script, four shaders, one shader global, config, test) is carried onto `tb/things` unchanged apart from the gate.

**CPU.** Night rain at the realm gate (matrix piece 8), flag on against main, ground band of each of the four views: mean brightness identical (54.7, 64.0, 69.1, 78.1 on both sides), mean pixel difference 0.03 to 0.07 (rain streak noise). Day rain at the same stand (piece 4; `_sheet_wet_day_off_vs_on_cpu.jpg`, left main, right arm): the ground darkens (ground band brightness 73 -> 53 and 80 -> 59) and the trail is a duller earth with a soft edge, as in round 2. No script or shader errors on either run.

**Tests.** `tests/test_places_storm_phase_rain_grade.gd` (10, one new: the clock gate).

**Ask.** Same pieces as round 2: 4 (gate day rain), 84, 88 (summit night rain), 92 (overlook rain), plus 3 (clear control). High. Check first that p88 matches base; if it does, the day gains decide.
