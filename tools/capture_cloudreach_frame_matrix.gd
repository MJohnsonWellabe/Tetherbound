extends SceneTree

## The Cloudreach chapter frame matrix: ART_DIRECTION §9's representative set
## (arrival/approach, player-facing route, reverse route, close detail/material
## view, optional lure, key settlement, finale at about 400 m and 100 m,
## post-finale change, day and night) and ACCEPTANCE §4's per-region review
## (approach, ordinary player-camera view, reverse, detail, day/night, 30 s of
## motion), for card C2 / row F08: high-perch production-camera footage, cliff
## silhouettes, settlements and day/night route cues.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_cloudreach_frame_matrix.gd
##   ... --script tools/capture_cloudreach_frame_matrix.gd -- --motion
##   ... --script tools/capture_cloudreach_frame_matrix.gd -- --only=1,7,34
##
## Never combine `--headless` with a rendering driver (WORKFLOW §7).
##
## CAMERA. Every frame comes from the PRODUCTION `CameraRig` (a SpringArm3D on
## `scripts/player/camera_rig.gd`) following the real trainer. It is aimed only
## through the rig's public `yaw`/`pitch` (radians), the two numbers a player's
## right stick moves: forward is -Z of `Basis(UP, yaw)`. The pitch is the rig's
## resting pitch (movement.json `pitch_start_deg`), tilted up only as far as
## keeps the row's target inside the top of the frame and never past the rig's
## own limits, so a landmark higher than a player can tilt to is shown only as
## far as a player could see it and the trainer always stays on the optical
## axis (lower-middle of frame). No free camera, no FOV change, no spring-arm
## override. After a teleport the rig is snapped to where its follow would
## settle (pivot on the trainer, arm at its resting length) instead of being
## left to glide a kilometre, which is the state a walking player would see.
##
## STANDS. Every stand is data, not invented: a point on a `cloudreach_world.json`
## route polyline (2 m right of the centreline, inside the 7 m collision
## ribbon), a polyline vertex / landing pad, or a stand an existing, proven
## Cloudreach capture tool already used (named per row below). Each row lists
## fallback stands. A stand is used only when
##   1. `ground_height_near(stand + UP*3)` gives a registered surface,
##   2. that surface is not more than 3 m under a DRAWN surface at the same x/z
##      (the summit crown is drawn without a floor over the final road --
##      ralph/reports/CLOUDREACH-PLAYER-CAMERA/REPORT.md),
##   3. a physics ray (the trainer's own collision mask) finds a floor within
##      1.5 m of it -- the trainer is HELD on the stand until that collider
##      exists, bounded -- and the trainer is still on it after settling,
##   4. the rig's camera is not under a drawn surface, and the trainer's chest
##      projects inside the frame.
## A stand that fails is printed (`SEAT-FAIL`) and the next one is tried; a row
## with no passing stand is printed (`SKIP`) and NOT captured.
##
## DISCLOSED FIXTURE (evidence setup, not play):
##   - `Game.reset_for_new_game()`, `current_realm = "cloudreach"`, the scene is
##     instantiated directly (no Meadows travel), saves go to
##     user://capture_cloudreach_frame_matrix/.
##   - Party of five added directly: galecrest (active; the Fly carrier, so the
##     companion in frame is the chapter's flyer), bramblebun, mudsnout,
##     terrapup, brooktail. The active creature is summoned through
##     `EncounterDirector.summon_active_creature()` and placed beside the
##     trainer on a verified floor at each stand.
##   - Progression flags set before boot (`BOOT_FLAGS`): the realm key and gate,
##     the chapter entry flags and every Act I and Act II flag
##     (cloudreach_chapter.json `persistent_flags`), so the counterweight gate,
##     Fly-only High Roost, Upper Cloudreach and the Summit all exist. Before the
##     finale rows `PRE_FINALE_FLAGS` (the final encounter's `requires_flags`:
##     upper anchors disabled, extraction engine reached) are added; before the
##     post-finale rows `POST_FINALE_FLAGS` (captain_veyra_defeated, the three
##     summit relays, storm_anchor_network_disabled, cloudreach_winds_restored,
##     stormward_route_revealed). The fight itself is not played.
##   - The trainer is teleported onto each stand and held there until a floor
##     collider exists under it; the rig is snapped behind it (see CAMERA).
##   - WorldLook's clock is pinned (world_look.gd `_apply_blended`, the path the
##     live clock uses; gate_f `_step_pin_clock`'s method) to 10:00 for day and
##     23:00 (the `night` preset's hour) for night, then frozen.
##   - Every CanvasLayer (HUD, prompts, toasts) is hidden: environment evidence.
##   - ORDINARY COMBAT IS SKIPPED: no clean director call opens an ordinary wild
##     fight on the production camera without scripting the engagement; combat
##     framing is covered by other lane evidence.
##
## OUTPUT: res://ralph/reports/CLOUDREACH-LANE/captures/frame_matrix/
##   NN_<region>_<row>_<day|night>.png, manifest.txt (one line per frame, also
##   printed as `MANIFEST ...`), `_sheet_frame_matrix.png` plus group sheets.
##   `--motion` writes motion/mNN_*.png, motion/manifest.txt and
##   `_sheet_frame_matrix_motion.png`: a frame every 0.5 s of simulated time for
##   30 s while the trainer walks the arrival road by real move input
##   (Input.action_press through the rig's planar_basis, as
##   tests/smoke_cloudreach_arrival_walk.gd does) with the camera steered by
##   yaw the way a player's stick would.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const LANE := preload("res://tools/capture_cloudreach_lane_common.gd")
const OUT := "res://ralph/reports/CLOUDREACH-LANE/captures/frame_matrix"
const MOTION_OUT := OUT + "/motion"

const DAY_HOUR := 10.0
const NIGHT_HOUR := 23.0
const BOOT_MAX_FRAMES := 900
const FLOOR_WAIT_MAX := 600
const SETTLE_PHYSICS := 12
const POSE_FRAMES := 14
## Of POSE_FRAMES, how many are actually drawn. Software GL takes seconds per
## drawn frame, so seating and settling run with the render loop off and only
## the last few frames before a capture are rendered (enough for shadows,
## visibility notifiers and the spring arm to catch up).
const RENDERED_FRAMES := 5
const FLOOR_TOLERANCE_M := 1.5
const DRAWN_OVER_STAND_M := 3.0
const DRAWN_OVER_CAMERA_M := 2.0
const MOTION_SECONDS := 30.0
const MOTION_INTERVAL_S := 0.5

const PARTY := ["galecrest", "bramblebun", "mudsnout", "terrapup", "brooktail"]
const BOOT_FLAGS := [
	"realm_key_cloudreach", "realm_gate_cloudreach_unlocked", "cloudreach_chapter_started",
	"cloudreach_crisis_learned", "storm_anchor_lower_west_mapped", "storm_anchor_lower_east_mapped",
	"cloudreach_lower_anchors_investigated", "causeway_survivors_reconnected", "windscar_aerie_prepared",
	"cloudreach_act_i_complete", "fly_traversal_unlocked", "fly_tutorial_completed", "sky_shrine_reached",
	"cloudreach_shrine_vane_west_aligned", "cloudreach_shrine_vane_east_aligned",
	"cloudreach_shrine_vane_crown_aligned", "storm_anchor_engine_truth_learned",
	"cloudreach_upper_route_unlocked", "cloudreach_act_ii_complete"]
const PRE_FINALE_FLAGS := [
	"storm_anchor_upper_west_disabled", "storm_anchor_upper_east_disabled",
	"storm_anchor_summit_feed_disabled", "cloudreach_upper_anchors_disabled",
	"summit_extraction_engine_reached"]
const POST_FINALE_FLAGS := [
	"captain_veyra_defeated", "cloudreach_summit_relay_west_disabled",
	"cloudreach_summit_relay_crown_disabled", "cloudreach_summit_relay_east_disabled",
	"storm_anchor_network_disabled", "cloudreach_winds_restored", "stormward_route_revealed"]

## Arrival road waypoints for `--motion` (arrival_gate_road polyline after its
## first vertex, the Meadows arrival anchor it starts from).
const MOTION_START := Vector3(0.0, 105.0, -260.0)
const MOTION_WAYPOINTS := [Vector3(-80.0, 130.0, 40.0), Vector3(-300.0, 145.0, 200.0),
	Vector3(-280.0, 180.0, 490.0)]

## One row per frame. `stands` are tried in order (y is the expected floor, used
## only to pick between stacked surfaces). `target` is what the rig's yaw points
## at; its y only lifts the pitch (see CAMERA). `target_ground` replaces the
## target's y with the registered ground there plus that many metres.
## `reuse_stand_of` tries the stand that row actually used first. `flags` adds a
## flag set before the row. `sheet` groups the row into a contact sheet.
const ROWS := [
	# --- Cloudreach Gate / Lower Cliffs ---------------------------------------
	{"n": 1, "region": "gate_lower_cliffs", "row": "approach", "time": "day", "sheet": "regions",
		"stands": [Vector3(-8.0, 105.0, -248.0), Vector3(0.0, 105.0, -260.0)],
		"target": Vector3(-24.0, 130.0, -159.0),
		"why": "Arrival from the Meadows gate (transition point 0,105,-260) toward Realm Gate Crag; stand from capture_cloudreach_realm_gate_crag.gd `arrival`."},
	{"n": 2, "region": "gate_lower_cliffs", "row": "route", "time": "day", "sheet": "regions",
		"stands": [Vector3(-191.2, 137.5, 118.4), Vector3(-190.0, 137.5, 120.0)],
		"target": Vector3(-300.0, 146.5, 200.0),
		"why": "arrival_gate_road segment 2 midpoint, 2 m right of centre, looking along the road toward Galefoot."},
	{"n": 3, "region": "gate_lower_cliffs", "row": "reverse", "time": "day", "sheet": "regions",
		"stands": [Vector3(-191.2, 137.5, 118.4), Vector3(-190.0, 137.5, 120.0)],
		"target": Vector3(-80.0, 131.5, 40.0),
		"why": "Same stand, looking back down the road toward the gate crag and arrival."},
	{"n": 4, "region": "gate_lower_cliffs", "row": "detail-crag", "time": "day", "sheet": "regions",
		"stands": [Vector3(-15.5, 110.0, -202.0), Vector3(-8.0, 105.0, -248.0)],
		"target": Vector3(-24.0, 130.0, -159.0),
		"why": "Close material view of the Realm Gate Crag masonry and strata; stand from capture_cloudreach_realm_gate_crag.gd `approach`."},
	{"n": 5, "region": "gate_lower_cliffs", "row": "settlement-galefoot", "time": "day", "sheet": "hero",
		"stands": [Vector3(-286.0, 180.0, 535.0), Vector3(-280.0, 180.0, 496.0)],
		"target": Vector3(-276.0, 186.0, 518.0),
		"why": "Key settlement Galefoot Waycamp (camp -280,180,520) on its terrace toward the hearth; stand from capture_cloudreach_galefoot_waycamp.gd."},
	# --- Broken Causeways --------------------------------------------------------
	{"n": 6, "region": "broken_causeways", "row": "approach", "time": "day", "sheet": "regions",
		"stands": [Vector3(-303.9, 280.5, 964.5), Vector3(-302.0, 280.5, 965.0)],
		"target": Vector3(-485.0, 345.0, 1320.0),
		"why": "lower_cliff_road final climb (t=0.7) toward Three Bells Bridge, the causeway's first landmark."},
	{"n": 7, "region": "broken_causeways", "row": "route", "time": "day", "sheet": "regions",
		"stands": [Vector3(-365.9, 363.6, 1451.4), Vector3(-364.5, 363.6, 1450.0)],
		"target": Vector3(-260.0, 391.5, 1560.0),
		"why": "broken_causeway_main past the rope bridge (t=0.45), looking up the causeway toward the stone viaduct."},
	{"n": 8, "region": "broken_causeways", "row": "reverse", "time": "day", "sheet": "regions",
		"stands": [Vector3(-365.9, 363.6, 1451.4), Vector3(-364.5, 363.6, 1450.0)],
		"target": Vector3(-450.0, 343.5, 1360.0),
		"why": "Same stand, looking back to the rope bridge's east landing."},
	{"n": 9, "region": "broken_causeways", "row": "detail-ropebridge", "time": "day", "sheet": "regions",
		"stands": [Vector3(-515.0, 333.3, 1302.2), Vector3(-534.0, 331.0, 1285.3)],
		"target": Vector3(-450.0, 343.0, 1360.0),
		"why": "On the first_rope_span deck (t=0.28 of its endpoints) looking along planks, rails and rope; fallback is the tested bridge approach."},
	{"n": 10, "region": "broken_causeways", "row": "lure-bells", "time": "day", "sheet": "hero",
		"stands": [Vector3(-454.0, 342.0, 1357.0), Vector3(-535.0, 330.0, 1274.5)],
		"target": Vector3(-477.0, 345.0, 1320.0),
		"why": "Optional lure: the lower bell of three_bells_against_silence; stands from capture_cloudreach_three_bells_bridge.gd."},
	# --- Windscar Ravine ------------------------------------------------------------
	{"n": 11, "region": "windscar_ravine", "row": "approach", "time": "day", "sheet": "regions",
		"stands": [Vector3(-86.0, 462.0, 2351.6), Vector3(-84.0, 462.0, 2352.0)],
		"target": Vector3(-260.0, 500.0, 2680.0), "target_ground": 6.0,
		"why": "broken_causeway_main last segment (t=0.6) entering the ravine, toward the Windscar Beacon."},
	{"n": 12, "region": "windscar_ravine", "row": "route", "time": "day", "sheet": "regions",
		"stands": [Vector3(-332.1, 448.0, 2592.3), Vector3(-331.0, 448.0, 2594.0)],
		"target": Vector3(-520.0, 431.5, 2720.0),
		"why": "windscar_floor_loop (t=0.55) along the ravine floor toward the chain bridge."},
	{"n": 13, "region": "windscar_ravine", "row": "reverse", "time": "day", "sheet": "regions",
		"stands": [Vector3(-332.1, 448.0, 2592.3), Vector3(-331.0, 448.0, 2594.0)],
		"target": Vector3(-100.0, 471.5, 2440.0),
		"why": "Same stand, looking back to the counterweight-gate junction."},
	{"n": 14, "region": "windscar_ravine", "row": "detail-beacon", "time": "day", "sheet": "regions",
		"stands": [Vector3(-250.9, 500.0, 2687.8), Vector3(-269.1, 500.0, 2672.2),
			Vector3(-248.0, 500.0, 2672.0), Vector3(-272.0, 500.0, 2688.0)],
		"target": Vector3(-260.0, 500.0, 2680.0), "target_ground": 5.0,
		"why": "Close view of the open Windscar Beacon, 12 m off its anchor (_capture_cloudreach_windscar_beacon_site.gd stand05 anchor/heading)."},
	# --- High Roost / Sky Shrine (Fly-only) ---------------------------------------
	{"n": 15, "region": "high_roost_sky_shrine", "row": "approach", "time": "day", "sheet": "regions",
		"stands": [Vector3(373.0, 610.0, 3262.5357), Vector3(330.0, 610.0, 3282.5)],
		"target": Vector3(1110.0, 1058.0, 2940.0),
		"why": "Windscar aerie road vertex (windscar_floor_loop) looking up at the Fly-only Sky Shrine cliff; fallback is production-integration `04-high-roost-before-fly`."},
	{"n": 16, "region": "high_roost_sky_shrine", "row": "route", "time": "day", "sheet": "regions",
		"stands": [Vector3(906.0, 1020.0, 2706.0), Vector3(907.0, 1020.0, 2700.0), Vector3(900.0, 1020.0, 2700.0)],
		"target": Vector3(1110.0, 1058.0, 2940.0),
		"why": "The Fly route's next hop as a landed player sees it: High Perches landing pad toward the Sky Shrine."},
	{"n": 17, "region": "high_roost_sky_shrine", "row": "reverse", "time": "day", "sheet": "regions",
		"stands": [Vector3(1087.0, 1050.0, 2896.0), Vector3(1110.0, 1050.0, 2885.0)],
		"target": Vector3(400.0, 615.0, 3250.0),
		"why": "Sky Shrine crown edge looking back down the windscar_to_high_roost_flight line to the aerie; stands from capture_cloudreach_sky_shrine.gd."},
	{"n": 18, "region": "high_roost_sky_shrine", "row": "detail-shrine", "time": "day", "sheet": "regions",
		"stands": [Vector3(1110.0, 1050.0, 2885.0), Vector3(1087.0, 1050.0, 2896.0)],
		"target": Vector3(1110.0, 1062.0, 2940.0),
		"why": "Sky Shrine heartstone, pillars and lintel close; capture_cloudreach_sky_shrine.gd `south-overview`."},
	{"n": 19, "region": "high_roost_sky_shrine", "row": "perch-landing", "time": "day", "sheet": "hero",
		"stands": [Vector3(900.0, 1020.0, 2689.0), Vector3(907.0, 1020.13, 2700.0)],
		"target": Vector3(900.0, 1028.0, 2700.0),
		"why": "High perch, correct camera: trainer on the High Perches landing (south Fly arrival, capture_cloudreach_high_perches.gd) with the rig behind at normal distance, toward the needles."},
	{"n": 20, "region": "high_roost_sky_shrine", "row": "perch-vista", "time": "day", "sheet": "hero",
		"stands": [Vector3(895.0, 1020.0, 2706.0), Vector3(900.0, 1020.0, 2700.0)],
		"target": Vector3(-340.0, 830.0, 3970.0),
		"why": "High perch, correct camera, looking out over the drop at stacked cliff silhouettes toward Upper Cloudreach / Cliffhold."},
	# --- Upper Cloudreach ------------------------------------------------------------
	{"n": 21, "region": "upper_cloudreach", "row": "approach", "time": "day", "sheet": "regions",
		"stands": [Vector3(-545.1, 744.0, 3797.2), Vector3(-543.0, 744.0, 3798.0)],
		"target": Vector3(-340.0, 840.0, 3970.0),
		"why": "windscar_counterweight_pass last climb (t=0.55) toward Cliffhold."},
	{"n": 22, "region": "upper_cloudreach", "row": "route", "time": "day", "sheet": "regions",
		"stands": [Vector3(95.2, 909.0, 4622.9), Vector3(94.5, 909.0, 4621.0)],
		"target": Vector3(430.0, 925.0, 4500.0),
		"why": "upper_plateau_circuit (t=0.45) across the broad plateau toward the Old Wind Observatory."},
	{"n": 23, "region": "upper_cloudreach", "row": "reverse", "time": "day", "sheet": "regions",
		"stands": [Vector3(95.2, 909.0, 4622.9), Vector3(94.5, 909.0, 4621.0)],
		"target": Vector3(-180.0, 901.5, 4720.0),
		"why": "Same stand, looking back west along the circuit."},
	{"n": 24, "region": "upper_cloudreach", "row": "detail-observatory", "time": "day", "sheet": "regions",
		"stands": [Vector3(430.0, 920.0, 4484.0), Vector3(414.0, 920.0, 4512.0), Vector3(445.0, 920.0, 4511.0)],
		"target": Vector3(430.0, 932.0, 4500.0),
		"why": "Old Wind Observatory dial court close; ObservatoryWalkableCrown stands from capture_cloudreach_old_wind_observatory.gd."},
	{"n": 25, "region": "upper_cloudreach", "row": "settlement-cliffhold", "time": "day", "sheet": "hero",
		"stands": [Vector3(-309.2, 830.0, 3991.2), Vector3(-352.0, 830.0, 3954.0)],
		"target": Vector3(-340.0, 838.0, 3970.0),
		"why": "Key settlement Cliffhold from its east arrival; production-integration `08-upper-cliffhold-east-arrival` / `12-cliffhold-ground-connection`."},
	# --- Summit / Stronghold ------------------------------------------------------------
	{"n": 26, "region": "summit_final_stronghold", "row": "approach", "time": "day", "sheet": "regions",
		"stands": [Vector3(339.2, 917.0, 4534.9), Vector3(338.5, 917.0, 4533.0)],
		"target": Vector3(100.0, 1190.0, 5350.0),
		"why": "upper_plateau_circuit near the observatory (t=0.85), ~850 m from the domed aviary on the summit."},
	{"n": 27, "region": "summit_final_stronghold", "row": "route", "time": "day", "sheet": "regions",
		"stands": [Vector3(483.1, 940.0, 4765.6), Vector3(485.0, 940.0, 4765.0)],
		"target": Vector3(520.0, 981.5, 4870.0),
		"why": "upper_summit_road climb (segment 2 midpoint) looking up the road."},
	{"n": 28, "region": "summit_final_stronghold", "row": "reverse", "time": "day", "sheet": "regions",
		"stands": [Vector3(483.1, 940.0, 4765.6), Vector3(485.0, 940.0, 4765.0)],
		"target": Vector3(450.0, 901.5, 4660.0),
		"why": "Same stand, looking back down over Upper Cloudreach."},
	{"n": 29, "region": "summit_final_stronghold", "row": "detail-aviary", "time": "day", "sheet": "regions",
		"stands": [Vector3(100.0, 1160.15, 5395.0), Vector3(100.0, 1160.15, 5388.0), Vector3(100.0, 1160.15, 5410.0)],
		"target": Vector3(100.0, 1190.0, 5350.0),
		"why": "Aviary drum, arches and lattice dome from the collision-bearing SummitArenaApproach (cloudreach_summit_presentation.gd)."},
	# --- Night twins (same stand and yaw as their day row) ---------------------------------
	{"n": 30, "region": "gate_lower_cliffs", "row": "approach", "time": "night", "sheet": "night", "twin": 1,
		"reuse_stand_of": 1, "stands": [Vector3(-8.0, 105.0, -248.0), Vector3(0.0, 105.0, -260.0)],
		"target": Vector3(-24.0, 130.0, -159.0),
		"why": "Night arrival route cue: row 01 at 23:00."},
	{"n": 31, "region": "broken_causeways", "row": "route", "time": "night", "sheet": "night", "twin": 7,
		"reuse_stand_of": 7, "stands": [Vector3(-365.9, 363.6, 1451.4), Vector3(-364.5, 363.6, 1450.0)],
		"target": Vector3(-260.0, 391.5, 1560.0),
		"why": "Night causeway route cue: row 07 at 23:00."},
	{"n": 32, "region": "upper_cloudreach", "row": "approach", "time": "night", "sheet": "night", "twin": 21,
		"reuse_stand_of": 21, "stands": [Vector3(-545.1, 744.0, 3797.2), Vector3(-543.0, 744.0, 3798.0)],
		"target": Vector3(-340.0, 840.0, 3970.0),
		"why": "Night Cliffhold approach: row 21 at 23:00."},
	# --- Finale and post-finale ---------------------------------------------------------------
	{"n": 33, "region": "summit_final_stronghold", "row": "finale400", "time": "day", "sheet": "finale",
		"flags": "pre_finale",
		"stands": [Vector3(353.9, 1054.9, 5040.8), Vector3(355.4, 1054.8, 5042.0)],
		"target": Vector3(100.0, 1190.0, 5350.0),
		"why": "upper_summit_road segment 3, 400 m (straight line) from the aviary at (100,1160,5350), Officer Voss's approach."},
	{"n": 34, "region": "summit_final_stronghold", "row": "finale100", "time": "day", "sheet": "finale",
		"flags": "pre_finale",
		"stands": [Vector3(162.5, 1135.0, 5271.9), Vector3(192.7, 1171.0, 5387.5), Vector3(100.0, 1160.15, 5440.0)],
		"target": Vector3(100.0, 1190.0, 5350.0),
		"why": "100 m from the aviary: first the final road (under the drawn summit crown on main -- rejected there by the drawn-surface check), then summit_overlook_loop at 100 m, then the arena deck (90 m)."},
	{"n": 35, "region": "summit_final_stronghold", "row": "postfinale", "time": "day", "sheet": "finale",
		"flags": "post_finale", "reuse_stand_of": 34,
		"stands": [Vector3(162.5, 1135.0, 5271.9), Vector3(192.7, 1171.0, 5387.5), Vector3(100.0, 1160.15, 5440.0)],
		"target": Vector3(100.0, 1190.0, 5350.0),
		"why": "Post-finale change at the row-34 stand: cloudreach_winds_restored (anchors freed, relays off, drone gone)."},
	{"n": 36, "region": "gate_lower_cliffs", "row": "postfinale-galefoot", "time": "day", "sheet": "finale",
		"flags": "post_finale", "reuse_stand_of": 5,
		"stands": [Vector3(-286.0, 180.0, 535.0), Vector3(-280.0, 180.0, 496.0)],
		"target": Vector3(-276.0, 186.0, 518.0),
		"why": "Post-finale Galefoot: returning travelers (Aila, Neri, Orrin) against row 05."},
]

var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _look: Node
var _director: Node
var _frames: Array = []
var _frame_by_row: Dictionary = {}
var _used_stand: Dictionary = {}
var _skips: Array[String] = []
var _manifest: FileAccess
var _hour := DAY_HOUR
var _rest_pitch_deg := -12.0
var _only: Dictionary = {}
var _motion := false
var _flag_state := ""


func _init() -> void:
	# Deferred: the Game autoload joins the tree only after _init returns.
	_run.call_deferred()


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--motion":
			_motion = true
		elif arg.begins_with("--only="):
			for part: String in arg.substr("--only=".length()).split(",", false):
				_only[int(part)] = true


func _run() -> void:
	_parse_args()
	if DisplayServer.get_name() == "headless":
		print("frame matrix: headless has no renderer; run under xvfb-run with --rendering-driver opengl3")
		quit(1)
		return
	var booted: bool = await _boot()
	if not booted:
		quit(1)
		return
	if _motion:
		await _run_motion()
	else:
		await _run_matrix()


## --- boot ---------------------------------------------------------------------

func _boot() -> bool:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		push_error("frame matrix: Game autoload is missing")
		return false
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE.new("user://capture_cloudreach_frame_matrix/"))
	_game.set("current_realm", "cloudreach")
	var party: RefCounted = _game.get("party")
	for species: String in PARTY:
		party.call("add", SPECIES.spawn(species))
	for index in (party.call("members") as Array).size():
		var member: RefCounted = party.call("at", index)
		if member != null and str(member.get("species_id")) == "galecrest":
			party.call("set_active", index)
			break
	var flags: RefCounted = _game.get("progression")
	for flag: String in BOOT_FLAGS:
		flags.call("set_flag", flag)
	_flag_state = "boot"
	_rest_pitch_deg = float(_camera_config().get("pitch_start_deg", -12.0))

	_world = SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	_look = _world.get_node_or_null(^"WorldLook")
	if _player == null or _rig == null or _camera == null:
		push_error("frame matrix: production Player/CameraRig/Camera3D missing")
		return false
	_set_render(false)
	# Boot by polling for the runtime's EncounterDirector (and its mount flag),
	# not a fixed frame count.
	var booted := false
	for i in BOOT_MAX_FRAMES:
		await process_frame
		_director = _world.get_node_or_null(^"EncounterDirector")
		var runtime := _world.get_node_or_null(^"CloudreachRuntime")
		var mounted := runtime == null or bool(runtime.get("_mounted"))
		if _director != null and mounted and i >= 20:
			booted = true
			print("frame matrix: world booted after %d frames" % i)
			break
	if not booted:
		push_error("frame matrix: EncounterDirector never appeared; refusing partial-scene evidence")
		return false
	for i in 10:
		await physics_frame
	_camera.make_current()
	_pin_hour(DAY_HOUR)
	await _summon_companion()
	return true


func _camera_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/movement.json"))
	if not parsed is Dictionary:
		return {}
	return (parsed as Dictionary).get("camera", {}) as Dictionary


func _summon_companion() -> void:
	if _director == null or not _director.has_method("summon_active_creature"):
		print("frame matrix: no summon_active_creature(); frames carry no companion")
		return
	if _ally() == null:
		_director.call("summon_active_creature")
	for i in 120:
		if _ally() != null:
			return
		await physics_frame
	print("frame matrix: active creature did not come out; frames carry no companion")


func _ally() -> Node3D:
	if _director == null or not _director.has_method("ally_body"):
		return null
	var body := _director.call("ally_body") as Node3D
	return body if body != null and is_instance_valid(body) else null


## --- the matrix ------------------------------------------------------------------

func _run_matrix() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_manifest = FileAccess.open(OUT + "/manifest.txt", FileAccess.WRITE)
	_manifest_line("# Cloudreach frame matrix -- tools/capture_cloudreach_frame_matrix.gd (production CameraRig; fixture in the tool header)")
	_manifest_line("# name | row | trainer feet | yaw/pitch deg | target | hour | stand (candidate) | camera | trainer on screen | companion | flags")
	for row: Dictionary in ROWS:
		if not _only.is_empty() and not _only.has(int(row["n"])):
			continue
		await _apply_row_flags(str(row.get("flags", "")))
		await _capture_row(row)
	_write_sheets()
	_finish(_frames.size())


func _apply_row_flags(kind: String) -> void:
	var wanted: Array = []
	if kind == "pre_finale" and _flag_state == "boot":
		wanted = PRE_FINALE_FLAGS
	elif kind == "post_finale" and _flag_state != "post_finale":
		wanted = PRE_FINALE_FLAGS + POST_FINALE_FLAGS
	if wanted.is_empty():
		return
	_set_render(false)
	var flags: RefCounted = _game.get("progression")
	for flag: String in wanted:
		flags.call("set_flag", flag)
	_flag_state = kind
	for node in get_nodes_in_group("progression_restore"):
		if node.has_method("restore_progression_from_game"):
			node.call("restore_progression_from_game", _game)
	for i in 30:
		await physics_frame
	if paused:
		paused = false
		print("frame matrix: the tree paused after the %s flags; unpaused for capture" % kind)
	print("frame matrix: fixture flags now %s (%s)" % [kind, ", ".join(PackedStringArray(wanted))])


func _capture_row(row: Dictionary) -> void:
	var n := int(row["n"])
	var time := str(row.get("time", "day"))
	var name := "%02d_%s_%s_%s" % [n, str(row["region"]), str(row["row"]), time]
	_pin_hour(NIGHT_HOUR if time == "night" else DAY_HOUR)
	var stands: Array = []
	if row.has("reuse_stand_of") and _used_stand.has(int(row["reuse_stand_of"])):
		stands.append(_used_stand[int(row["reuse_stand_of"])])
	for stand: Vector3 in row.get("stands", []):
		if not stands.has(stand):
			stands.append(stand)
	for i in stands.size():
		var stand: Vector3 = stands[i]
		var pose: Dictionary = await _pose(stand, row)
		if not bool(pose.get("ok", false)):
			_manifest_line("SEAT-FAIL %s candidate %d/%d at %s: %s" % [name, i + 1, stands.size(), _fmt(stand), str(pose.get("why", "?"))])
			continue
		_hide_overlays()
		await process_frame
		await RenderingServer.frame_post_draw
		var path: String = LANE.save_frame(self, OUT, name, _frames)
		if path.is_empty():
			_skips.append("%s: PNG write failed" % name)
			return
		var frame: Dictionary = _frames[_frames.size() - 1]
		frame["n"] = n
		frame["sheet"] = str(row.get("sheet", ""))
		_frame_by_row[n] = frame
		_used_stand[n] = stand
		_manifest_line("MANIFEST %s | %s | trainer %s | yaw %.1f pitch %.1f | target %s | hour %.2f | stand %s (%d/%d) | camera %s | trainer on screen %s | companion %s | flags %s | %s" % [
			name, str(row["row"]), _fmt(pose["feet"]), rad_to_deg(float(pose["yaw"])),
			rad_to_deg(float(pose["pitch"])), _fmt(pose["target"]), _clock_hour(), _fmt(stand), i + 1,
			stands.size(), _fmt(pose["camera"]), str(pose["screen"]), str(pose["companion"]), _flag_state,
			str(row.get("why", ""))])
		return
	var skip := "SKIP %s: no candidate stand passed the seat/camera checks" % name
	print(skip)
	_skips.append(skip)
	_manifest_line(skip)


## Seat the trainer, aim the production rig, and check what it sees.
func _pose(stand: Vector3, row: Dictionary) -> Dictionary:
	var seat: Dictionary = await _seat(stand)
	if not bool(seat.get("ok", false)):
		return seat
	var feet: Vector3 = seat["feet"]
	var target := _resolve_target(row)
	var yaw: float = LANE.yaw_towards(feet, target)
	var pitch := _pitch_for(feet, target, row)
	_face_model(yaw)
	_snap_rig(feet, yaw, pitch)
	var companion := _place_companion(feet, yaw)
	for i in POSE_FRAMES - RENDERED_FRAMES:
		await process_frame
	_set_render(true)
	for i in RENDERED_FRAMES:
		await process_frame
	# Re-assert the stick values (nothing should have moved them; a tracking
	# target or a conversation would, and is reported below).
	_rig.set("yaw", yaw)
	_rig.set("pitch", pitch)
	await process_frame
	await process_frame
	var settled := _player.global_position
	if Vector2(settled.x, settled.z).distance_to(Vector2(feet.x, feet.z)) > 0.75 or absf(settled.y - feet.y) > 0.6:
		return {"ok": false, "why": "trainer slid off the stand to %s" % _fmt(settled)}
	var cam := _camera.global_position
	var drawn := float(_world.call("ground_height_at", cam.x, cam.z))
	if is_finite(drawn) and drawn > cam.y + DRAWN_OVER_CAMERA_M:
		return {"ok": false, "why": "camera at %s is %.1f m under a drawn surface (y %.1f)" % [_fmt(cam), drawn - cam.y, drawn]}
	var chest := settled + Vector3.UP * 1.0
	if _camera.is_position_behind(chest):
		return {"ok": false, "why": "trainer is behind the camera"}
	var screen := _camera.unproject_position(chest)
	var rect := _camera.get_viewport().get_visible_rect()
	if not rect.has_point(screen):
		return {"ok": false, "why": "trainer chest projects outside the frame at %s" % screen}
	var screen_note := "(%.0f%%, %.0f%%)" % [100.0 * screen.x / rect.size.x, 100.0 * screen.y / rect.size.y]
	if not _rig.is_processing():
		screen_note += " WARN rig suspended (dialogue?)"
	return {"ok": true, "feet": settled, "yaw": yaw, "pitch": pitch, "target": target,
		"camera": cam, "screen": screen_note, "companion": companion}


## Hold the trainer on `stand` until a real floor collider is under it, then let
## it settle and confirm it stayed.
func _seat(stand: Vector3) -> Dictionary:
	_set_render(false)
	var y := float(_world.call("ground_height_near", stand + Vector3.UP * 3.0))
	if is_nan(y):
		return {"ok": false, "why": "no registered ground near the stand"}
	var drawn := float(_world.call("ground_height_at", stand.x, stand.z))
	if is_finite(drawn) and drawn > y + DRAWN_OVER_STAND_M:
		return {"ok": false, "why": "stand ground %.1f lies %.1f m under a drawn surface (y %.1f)" % [y, drawn - y, drawn]}
	var spot := Vector3(stand.x, y, stand.z)
	var floor_y := NAN
	var waited := 0
	while waited < FLOOR_WAIT_MAX:
		_hold_player(spot + Vector3.UP * 0.3)
		floor_y = _floor_hit(spot)
		if not is_nan(floor_y):
			break
		waited += 1
		await physics_frame
	if is_nan(floor_y):
		return {"ok": false, "why": "no physics floor within %.1f m of ground %.2f after %d frames" % [FLOOR_TOLERANCE_M, y, waited]}
	_hold_player(Vector3(stand.x, floor_y + 0.05, stand.z))
	for i in SETTLE_PHYSICS:
		await physics_frame
	var feet := _player.global_position
	if Vector2(feet.x, feet.z).distance_to(Vector2(stand.x, stand.z)) > 0.75 or absf(feet.y - floor_y) > 0.6:
		return {"ok": false, "why": "trainer did not stay on the stand: settled at %s, floor %.2f" % [_fmt(feet), floor_y]}
	return {"ok": true, "feet": feet, "floor": floor_y}


func _hold_player(at: Vector3) -> void:
	_player.global_position = at
	_player.velocity = Vector3.ZERO


## The floor under `spot` on the trainer's own collision mask, or NAN.
func _floor_hit(spot: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(
		spot + Vector3.UP * FLOOR_TOLERANCE_M, spot + Vector3.DOWN * (FLOOR_TOLERANCE_M + 1.5))
	query.collision_mask = _player.collision_mask
	var exclude: Array[RID] = [_player.get_rid()]
	var ally := _ally()
	if ally is CollisionObject3D:
		exclude.append((ally as CollisionObject3D).get_rid())
	query.exclude = exclude
	var hit := _world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return NAN
	var at: Vector3 = hit["position"]
	if absf(at.y - spot.y) > FLOOR_TOLERANCE_M:
		return NAN
	return at.y


func _resolve_target(row: Dictionary) -> Vector3:
	var target: Vector3 = row["target"]
	if row.has("target_ground"):
		var ground := float(_world.call("ground_height_near", target))
		if is_finite(ground):
			target.y = ground + float(row["target_ground"])
	return target


## The rig's resting pitch, lifted only as far as keeps `target` inside the top
## of the frame, clamped to the rig's own range.
func _pitch_for(feet: Vector3, target: Vector3, row: Dictionary) -> float:
	var pitch_min := deg_to_rad(float(_rig.get("_pitch_min")))
	var pitch_max := deg_to_rad(float(_rig.get("_pitch_max")))
	if row.has("pitch_deg"):
		return clampf(deg_to_rad(float(row["pitch_deg"])), pitch_min, pitch_max)
	var pivot_y := feet.y + float(_rig.get("_height"))
	var flat := maxf(Vector2(target.x - feet.x, target.z - feet.z).length(), 0.01)
	var to_target := atan2(target.y - pivot_y, flat)
	var pitch := maxf(deg_to_rad(_rest_pitch_deg), to_target - deg_to_rad(_camera.fov * 0.5 - 6.0))
	return clampf(pitch, pitch_min, pitch_max)


## The trainer faces where the stick points the camera, as after walking there.
func _face_model(yaw: float) -> void:
	var model := _player.get_node_or_null(^"Model") as Node3D
	if model == null:
		return
	var forward := Basis(Vector3.UP, yaw) * Vector3.FORWARD
	model.rotation.y = atan2(forward.x, forward.z)


## Put the rig where its own follow settles (pivot at trainer + height, arm at
## rest length) and set the stick values.
func _snap_rig(feet: Vector3, yaw: float, pitch: float) -> void:
	_rig.set("yaw", yaw)
	_rig.set("pitch", pitch)
	_rig.rotation = Vector3(pitch, yaw, 0.0)
	_rig.global_position = feet + Vector3.UP * float(_rig.get("_height"))
	_rig.spring_length = float(_rig.get("_distance"))


## The active creature beside and slightly ahead of the trainer, on a verified
## floor, so it reads in frame the way a following companion does.
func _place_companion(feet: Vector3, yaw: float) -> String:
	var ally := _ally()
	if ally == null:
		return "none"
	var basis := Basis(Vector3.UP, yaw)
	var forward := basis * Vector3.FORWARD
	var right := basis * Vector3.RIGHT
	for offset: Vector3 in [right * 1.8 + forward * 1.6, -right * 1.8 + forward * 1.6,
			forward * 2.6, right * 2.2, -right * 2.2]:
		var spot := feet + offset
		var floor_y := _floor_hit(Vector3(spot.x, feet.y, spot.z))
		if is_nan(floor_y):
			continue
		ally.global_position = Vector3(spot.x, floor_y + 0.05, spot.z)
		if ally is CharacterBody3D:
			(ally as CharacterBody3D).velocity = Vector3.ZERO
		return "placed %s" % _fmt(ally.global_position)
	return "no floor beside the trainer; left where it was %s" % _fmt(ally.global_position)


## Pin WorldLook's clock the way the live clock applies an hour, then freeze it.
func _pin_hour(hour: float) -> void:
	_hour = hour
	if _look == null:
		return
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	var cycle: Variant = _look.get("_cycle")
	if cycle != null and _look.has_method("_apply_blended"):
		_look.set("_elapsed_seconds", float((cycle as Object).call("elapsed_for_hour", hour)))
		_look.call("_apply_blended", hour)
	else:
		_look.call("apply_time", "night" if hour >= 20.0 or hour < 5.0 else "day")


func _clock_hour() -> float:
	if _look != null and _look.has_method("hour"):
		return float(_look.call("hour"))
	return _hour


func _set_render(on: bool) -> void:
	RenderingServer.render_loop_enabled = on


func _hide_overlays() -> void:
	for node in root.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false


## --- sheets, manifest, finish ---------------------------------------------------------

func _write_sheets() -> void:
	LANE.contact_sheet(_frames, OUT + "/_sheet_frame_matrix.png", 4, 480)
	var regions: Array = []
	var hero: Array = []
	for frame: Dictionary in _frames:
		if str(frame.get("sheet", "")) == "regions":
			regions.append(frame)
	for n: int in [5, 25, 19, 20, 10]:
		if _frame_by_row.has(n):
			hero.append(_frame_by_row[n])
	var day_night: Array = []
	for row: Dictionary in ROWS:
		if row.has("twin") and _frame_by_row.has(int(row["n"])) and _frame_by_row.has(int(row["twin"])):
			day_night.append(_frame_by_row[int(row["twin"])])
			day_night.append(_frame_by_row[int(row["n"])])
	var finale: Array = []
	for n: int in [33, 34, 35, 5, 36]:
		if _frame_by_row.has(n):
			finale.append(_frame_by_row[n])
	LANE.contact_sheet(regions, OUT + "/_sheet_frame_matrix_regions.png", 4, 480)
	LANE.contact_sheet(hero, OUT + "/_sheet_frame_matrix_hero.png", 3, 640)
	LANE.contact_sheet(day_night, OUT + "/_sheet_frame_matrix_day_night.png", 2, 640)
	LANE.contact_sheet(finale, OUT + "/_sheet_frame_matrix_finale.png", 3, 640)


func _manifest_line(line: String) -> void:
	print(line)
	if _manifest != null:
		_manifest.store_line(line)
		_manifest.flush()


func _fmt(v: Variant) -> String:
	if v is Vector3:
		var p: Vector3 = v
		return "(%.1f, %.2f, %.1f)" % [p.x, p.y, p.z]
	return str(v)


func _finish(written: int) -> void:
	_set_render(true)
	for line in _skips:
		print(line)
	var summary := "frame matrix: %d frames written, %d rows skipped" % [written, _skips.size()]
	_manifest_line("# " + summary)
	if _manifest != null:
		_manifest.close()
	quit(0 if written > 0 else 1)


## --- motion witness -------------------------------------------------------------------

## Thirty simulated seconds of the arrival road by real move input: a frame every
## half second, the camera steered by yaw toward the road ahead the way a player
## eases the stick, pitch at the rig's rest.
func _run_motion() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MOTION_OUT))
	_manifest = FileAccess.open(MOTION_OUT + "/manifest.txt", FileAccess.WRITE)
	_manifest_line("# Cloudreach 30 s motion witness -- arrival_gate_road, real move input, production CameraRig")
	_pin_hour(DAY_HOUR)
	var seat: Dictionary = await _seat(MOTION_START)
	if not bool(seat.get("ok", false)):
		print("SEAT-FAIL motion start %s: %s" % [_fmt(MOTION_START), str(seat.get("why", "?"))])
		_finish(0)
		return
	var feet: Vector3 = seat["feet"]
	var yaw: float = LANE.yaw_towards(feet, MOTION_WAYPOINTS[0])
	var pitch := deg_to_rad(_rest_pitch_deg)
	_face_model(yaw)
	_snap_rig(feet, yaw, pitch)
	_place_companion(feet, yaw)
	for i in 20:
		await process_frame
	_hide_overlays()
	# Between captures the render loop is off so simulated time runs at the
	# physics rate instead of the software renderer's; each capture draws one
	# frame of the state at that tick.
	_set_render(false)

	var hz := Engine.physics_ticks_per_second
	var total_ticks := int(round(MOTION_SECONDS * hz))
	var every := maxi(1, int(round(MOTION_INTERVAL_S * hz)))
	var start := Engine.get_physics_frames()
	var next_shot := every
	var shot := 0
	var waypoint := 0
	var motion_frames: Array = []
	var stop_reason := ""
	while shot < int(MOTION_SECONDS / MOTION_INTERVAL_S):
		var here := _player.global_position
		var goal: Vector3 = MOTION_WAYPOINTS[waypoint]
		var offset := Vector3(goal.x - here.x, 0.0, goal.z - here.z)
		if offset.length() < 3.0 and waypoint < MOTION_WAYPOINTS.size() - 1:
			waypoint += 1
			continue
		# Camera: ease the yaw toward the road ahead, as a stick would.
		var wanted: float = LANE.yaw_towards(here, goal)
		_rig.set("yaw", lerp_angle(float(_rig.get("yaw")), wanted, 0.06))
		_rig.set("pitch", pitch)
		# Movement: the direction to the waypoint in the rig's planar basis.
		var local: Vector3 = (_rig.call("planar_basis") as Basis).inverse() * offset.normalized()
		Input.action_press("move_right", maxf(local.x, 0.0))
		Input.action_press("move_left", maxf(-local.x, 0.0))
		Input.action_press("move_back", maxf(local.z, 0.0))
		Input.action_press("move_forward", maxf(-local.z, 0.0))
		await physics_frame
		var ground := float(_world.call("ground_height_near", _player.global_position))
		if not is_nan(ground) and _player.global_position.y < ground - 4.0:
			stop_reason = "trainer left the road at %s" % _fmt(_player.global_position)
			break
		var ticks := Engine.get_physics_frames() - start
		if ticks >= total_ticks + every:
			break
		if ticks >= next_shot:
			_hide_overlays()
			_set_render(true)
			await RenderingServer.frame_post_draw
			shot += 1
			var t := float(Engine.get_physics_frames() - start) / float(hz)
			var name := "m%02d_gate_lower_cliffs_walk_day" % shot
			var path: String = LANE.save_frame(self, MOTION_OUT, name, motion_frames)
			_set_render(false)
			if not path.is_empty():
				# Keep a small copy for the sheet; the full frame is on disk.
				var small: Image = motion_frames[motion_frames.size() - 1]["image"]
				small.resize(int(small.get_width() / 4.0), int(small.get_height() / 4.0), Image.INTERPOLATE_BILINEAR)
			var ally := _ally()
			_manifest_line("MANIFEST %s | t %.2f s | trainer %s | yaw %.1f pitch %.1f | waypoint %s | hour %.2f | camera %s | companion %s" % [
				name, t, _fmt(_player.global_position), rad_to_deg(float(_rig.get("yaw"))),
				rad_to_deg(float(_rig.get("pitch"))), _fmt(goal), _clock_hour(), _fmt(_camera.global_position),
				_fmt(ally.global_position) if ally != null else "none"])
			next_shot += every
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
	if not stop_reason.is_empty():
		_skips.append("motion stopped early: " + stop_reason)
	LANE.contact_sheet(motion_frames, OUT + "/_sheet_frame_matrix_motion.png", 6, 320)
	_finish(motion_frames.size())
