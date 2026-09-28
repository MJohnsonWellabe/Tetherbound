# Verbatim prompt given to the second code-blind judge (fresh general-purpose subagent, no conversation context)

You are a code-blind readability judge for a third-person creature action RPG. You judge ONLY rendered game frames. Do NOT open, read or search any source code, JSON, config, test, tool, manifest, markdown or report file in the repository, and do not look at git history. Open only the image files named below, one at a time with the Read tool.

Context you may use: the region is a sky-high cliff country with six areas. The player (a trainer about 1.8 m tall, usually with one companion creature beside them) walks roads between five of the areas. The sixth, high_roost_sky_shrine, is a sheer-cliff destination that has NO walking road by design: it is reached only by gliding (the trainer hangs from a large bird carrier) between landing pads, so its "route" is the glide line from one landing to the next. Every frame is the game's ordinary third-person camera following the trainer; HUD is hidden. File names give the area and the kind of view (approach = arriving toward the area's landmark; route = looking along the way on; reverse = looking back; detail/lure = a close point of interest).

Frames (paths relative to /home/user/Tetherbound/ralph/reports/CLOUDREACH/):
gate_lower_cliffs: f08-4-settlements/r1/01_gate_lower_cliffs_approach_day.jpg, f08-4-settlements/r1/02_gate_lower_cliffs_route_day.jpg, f08-4-settlements/r1/03_gate_lower_cliffs_reverse_day.jpg, f08-4-settlements/r1/04_gate_lower_cliffs_detail-crag_day.jpg, f08-4-settlements/r1/30_gate_lower_cliffs_approach_night.jpg
broken_causeways: f08-4-settlements/r1f/06_broken_causeways_approach_day.jpg, f08-4-settlements/r1f/07_broken_causeways_route_day.jpg, f08-4-settlements/r1f/08_broken_causeways_reverse_day.jpg, f08-4-settlements/r1f/09_broken_causeways_detail-ropebridge_day.jpg, f08-4-settlements/r1f/10_broken_causeways_lure-bells_day.jpg, f08-4-settlements/r1f/31_broken_causeways_route_night.jpg
windscar_ravine: f08-4-settlements/r1/11_windscar_ravine_approach_day.jpg, f08-4-settlements/r1/12_windscar_ravine_route_day.jpg, f08-4-settlements/r1/13_windscar_ravine_reverse_day.jpg, f08-4-settlements/r1/14_windscar_ravine_detail-beacon_day.jpg
high_roost_sky_shrine: f08-4-settlements/r1/15_high_roost_sky_shrine_approach_day.jpg, f08-4-settlements/r1/17_high_roost_sky_shrine_reverse_day.jpg, f08-4-settlements/r1/19_high_roost_sky_shrine_perch-landing_day.jpg, f08-4-settlements/r1/20_high_roost_sky_shrine_perch-vista_day.jpg, and a glide onto and off one landing pad: f08-3-high-perch-camera/r5/high-perches-arrival-far-day.jpg, f08-3-high-perch-camera/r5/high-perches-arrival-lip-day.jpg, f08-3-high-perch-camera/r5/high-perches-arrival-landed-day.jpg, f08-3-high-perch-camera/r5/high-perches-crown-rim-out-day.jpg, f08-3-high-perch-camera/r5/high-perches-departure-lookback-day.jpg, f08-3-high-perch-camera/r5/high-perches-arrival-far-night.jpg, f08-3-high-perch-camera/r5/high-perches-departure-lookback-night.jpg
upper_cloudreach: f08-4-settlements/r1/21_upper_cloudreach_approach_day.jpg, f08-4-settlements/r1/22_upper_cloudreach_route_day.jpg, f08-4-settlements/r1/23_upper_cloudreach_reverse_day.jpg, f08-4-settlements/r1/24_upper_cloudreach_detail-observatory_day.jpg, f08-4-settlements/r1/32_upper_cloudreach_approach_night.jpg
summit_final_stronghold: f08-4-settlements/r1/26_summit_final_stronghold_approach_day.jpg, f08-4-settlements/r1/27_summit_final_stronghold_route_day.jpg, f08-4-settlements/r1/28_summit_final_stronghold_reverse_day.jpg, f08-4-settlements/r1/29_summit_final_stronghold_detail-aviary_day.jpg, f08-4-settlements/r1/33_summit_final_stronghold_finale400_day.jpg, f08-4-settlements/r1/34_summit_final_stronghold_finale100_day.jpg

List any file you could not open.

Judge ONLY function and readability, NOT art quality, beauty, polish, materials or finish (those are explicitly out of scope; do not fail anything for looking unpolished).

B. Cliffs as routes and landmarks. For each of the six areas answer YES / PARTLY / NO with one sentence of evidence (name the frame):
 B1 Route: can a player tell where the way on goes next (the road or path on foot; for high_roost_sky_shrine, where to glide/land and where they came from)?
 B2 Landmark: is there a landmark or silhouette to navigate by?
 B3 Cliffs read as cliffs/terrain the route climbs through or around (not as unreadable walls that hide where to go)?
C. Night route cues (the *_night frames): can a player still follow the route at night?

Give an overall FUNCTION verdict for B and for C: PASS (every area YES or PARTLY with nothing that would stop a player finding their way) or FAIL. A single frame with a poor composition does not fail an area if the area's other frames show the way. Finish with the worst 5 functional defects, each naming its frame file. Keep it under 800 words.
