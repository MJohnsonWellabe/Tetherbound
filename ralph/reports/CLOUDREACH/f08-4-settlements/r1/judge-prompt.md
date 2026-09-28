# Verbatim prompt given to the code-blind judge (general-purpose subagent, no conversation context)

You are a code-blind readability judge for a third-person creature action RPG. You judge ONLY rendered game frames. Do NOT open, read or search any source code, JSON, config, test, tool, manifest, markdown or report file in the repository, and do not look at git history. Open only the image files named below, one at a time with the Read tool.

Context you may use: the region is a sky-high cliff country. The player (a trainer about 1.8 m tall, often with one companion creature beside them) walks roads between six areas and can later glide. Every frame is the game's ordinary third-person camera following the trainer; HUD is hidden. File names give the area and the kind of view (approach = arriving toward the area's landmark; route = looking along the road; reverse = looking back; detail/lure = a close point of interest; settlement-* = a village; finale/postfinale = the final stronghold).

Frames (open each one; paths are relative to the Base directory):
Base: /home/user/Tetherbound/ralph/reports/CLOUDREACH/f08-4-settlements/
Regions (day unless the name says night):
r1/01_gate_lower_cliffs_approach_day.jpg
r1/02_gate_lower_cliffs_route_day.jpg
r1/03_gate_lower_cliffs_reverse_day.jpg
r1/04_gate_lower_cliffs_detail-crag_day.jpg
r1/06_broken_causeways_approach_day.jpg
r1/07_broken_causeways_route_day.jpg
r1/08_broken_causeways_reverse_day.jpg
r1/09_broken_causeways_detail-ropebridge_day.jpg
r1/10_broken_causeways_lure-bells_day.jpg
r1/11_windscar_ravine_approach_day.jpg
r1/12_windscar_ravine_route_day.jpg
r1/13_windscar_ravine_reverse_day.jpg
r1/14_windscar_ravine_detail-beacon_day.jpg
r1/15_high_roost_sky_shrine_approach_day.jpg
r1/17_high_roost_sky_shrine_reverse_day.jpg
r1/19_high_roost_sky_shrine_perch-landing_day.jpg
r1/20_high_roost_sky_shrine_perch-vista_day.jpg
r1/21_upper_cloudreach_approach_day.jpg
r1/22_upper_cloudreach_route_day.jpg
r1/23_upper_cloudreach_reverse_day.jpg
r1/24_upper_cloudreach_detail-observatory_day.jpg
r1/26_summit_final_stronghold_approach_day.jpg
r1/27_summit_final_stronghold_route_day.jpg
r1/28_summit_final_stronghold_reverse_day.jpg
r1/29_summit_final_stronghold_detail-aviary_day.jpg
r1/30_gate_lower_cliffs_approach_night.jpg
r1/31_broken_causeways_route_night.jpg
r1/32_upper_cloudreach_approach_night.jpg
r1/33_summit_final_stronghold_finale400_day.jpg
r1/34_summit_final_stronghold_finale100_day.jpg
r1/35_summit_final_stronghold_postfinale_day.jpg
Villages:
r1c/05_gate_lower_cliffs_settlement-galefoot_day.jpg
r1c/36_gate_lower_cliffs_postfinale-galefoot_day.jpg
r1c/37_gate_lower_cliffs_settlement-galefoot-approach_day.jpg
r1c/night/05_gate_lower_cliffs_settlement-galefoot_night.jpg
r1c/night/37_gate_lower_cliffs_settlement-galefoot-approach_night.jpg
r1d/25_upper_cloudreach_settlement-cliffhold_day.jpg
r1d/night/25_upper_cloudreach_settlement-cliffhold_night.jpg

List any file you could not open.

Judge ONLY function and readability, NOT art quality, beauty, polish, materials or finish (those are explicitly out of scope; do not fail anything for looking unpolished).

A. Settlements. There are two villages: Galefoot (files 05_*settlement-galefoot*, 37_*settlement-galefoot-approach*, 36_*postfinale-galefoot*) and Cliffhold (25_*settlement-cliffhold*). For each village, day and night, answer YES / PARTLY / NO with one sentence of evidence:
 A1 Occupied: are people visibly there?
 A2 Activity: does it look like people live/work there (someone doing something, work spots, camp/hearth, supplies), not an empty set?
 A3 Navigable layout: can a player tell where to walk, where the centre/entrance/camp is?
 A4 Reads as its place: from the approach, does it read as a village/settlement (not ruins or random props), and do the two villages read as distinct places?
B. Cliffs as routes and landmarks. For each of the six areas (gate_lower_cliffs, broken_causeways, windscar_ravine, high_roost_sky_shrine, upper_cloudreach, summit_final_stronghold), using its approach/route/reverse/detail frames:
 B1 Route: can a player tell where the walkable road or path goes next?
 B2 Landmark: is there a landmark or silhouette to navigate by?
 B3 Cliffs read as cliffs/terrain the route climbs through (not as unreadable walls that hide where to go)?
C. Night route cues (night frames): can a player still follow the route and find the village at night?

Give each question a per-village/per-area verdict and then an overall FUNCTION verdict for A, B and C: PASS (every village/area YES or PARTLY with nothing that would stop a player finding their way or seeing the village as lived-in) or FAIL. Finish with the worst 5 functional defects, each naming its frame file. Keep it under 900 words.
