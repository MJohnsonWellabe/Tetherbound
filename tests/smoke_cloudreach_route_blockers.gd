extends "res://tests/smoke_cloudreach_continuous.gd"

## Route blockers B1-B3 (Cloudreach-B, #294): three places the ordinary ground
## route stalled, walked on the production scene with the real controller and
## the production encounter director (wild sites spawn by proximity and are
## NOT parked: two of the three blockers were wild bodies).
##
##   B1 (-128.4, 205.5, 704.5) arrival -> lower_west_anchor: an overhanging
##      `VegetatedGeologicalShelf` collider inside a drawn-only RockShoulder.
##   B2 (223.6, 556.5, 3331.9) aerie -> grounded counterweight: the
##      `ravine_wind` pair standing on the floor-loop ribbon.
##   B3 (500.5, 986.4, 4890.0) Upper Summit road toward Voss: the
##      `roost_perches` pair, bound there 1.5 km from its authored point; it
##      now stands on High Roost ground, so none of its bodies may be here.
##
## Fixture (declared): post-shrine flags so the grounded counterweight/upper
## routes are open, and the player is placed once at each leg's start. Every
## metre after that is stick input over collision via the continuous harness's
## `_navigate`/`_walk` (stall = no 0.4 m progress in 3 x 120 frames).
##
##   godot --headless --path . --script tests/smoke_cloudreach_route_blockers.gd
##
## Prints `CLOUDREACH ROUTE BLOCKERS {...}`; exit 0 only when every leg reaches
## its target through a point within PASS_NEAR_M of its blocker with no
## mobile-obstacle walk-around, B2/B3's named wild pair was actually there, and
## the B1 shelf is gone.

const FLAGS: Array[String] = ["warden_defeated", "realm_key_cloudreach",
	"realm_heart_meadows_earned", "realm_heart_meadows_placed", "realm_gate_cloudreach_unlocked",
	"fly_traversal_unlocked", "windscar_aerie_prepared", "sky_shrine_reached",
	"cloudreach_upper_route_unlocked"]
const PASS_NEAR_M := 12.0
const LEGS := [
	{"id": "B1", "blocker": Vector3(-128.4, 205.5, 704.5), "start": Vector3(-280.0, 180.0, 508.0),
		"target_node": "lower_west"},
	{"id": "B2", "blocker": Vector3(223.6, 556.5, 3331.9), "start": Vector3(400.0, 610.0, 3250.0),
		"target": Vector3(-720.0, 700.0, 3680.0), "wild_prefix": "ravine_wind_"},
	{"id": "B3", "blocker": Vector3(500.5, 986.4, 4890.0), "start": Vector3(491.9854, 951.379, 4793.862),
		"target": Vector3(302.8, 1078.7, 5097.0), "absent_prefix": "roost_perches_"},
]

var _nearest := INF
var _blocker := Vector3.INF
var _wilds_near := {}
var _detours := 0


func _run() -> void:
	start_usec = Time.get_ticks_usec()
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	accelerated = true
	output_dir = "user://cloudreach_route_blockers"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = root.get_node("Game")
	game.reset_for_new_game()
	for flag: String in FLAGS:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(25, PROGRESSION.config())
		game.party.add(member)
	game.current_realm = "cloudreach"
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.physical_runtime()
	runtime = world.get_node("CloudreachRuntime")
	director = runtime.director
	manager = runtime.manager
	fly = player.fly_controller
	physics_frame.connect(_record_frame)
	physics_frame.connect(_track_blocker)
	await _frames(20)
	var results: Array = []
	var all_ok := true
	for leg: Dictionary in LEGS:
		stage = "route_blocker_" + str(leg.id)
		failed = false
		_detours = 0
		_nearest = INF
		_blocker = leg.blocker
		var start: Vector3 = leg.start
		var ground := float(world.call("ground_height_near", start))
		player.global_position = Vector3(start.x, (ground if is_finite(ground) else start.y) + 1.2, start.z)
		player.velocity = Vector3.ZERO
		await _frames(30)
		var target: Vector3 = chapter.get_node(str(leg.target_node)).global_position \
			if leg.has("target_node") else leg.target
		var before := distance_m
		var reached := await _navigate(target)
		_release()
		# A leg only proves its blocker when the walker went straight through
		# it: no mobile-obstacle walk-around (how main can squeeze past a pair),
		# and, for the wild blockers, the named pair actually standing there.
		var wild_prefix := str(leg.get("wild_prefix", ""))
		var named_present := wild_prefix.is_empty()
		var absent_prefix := str(leg.get("absent_prefix", ""))
		for seen: String in _wilds_near.get(leg.id, []):
			named_present = named_present or seen.begins_with(wild_prefix)
			# B3 (#340): roost_perches now lives on High Roost ground; its
			# bodies must no longer stand on the Upper Summit road at all.
			if not absent_prefix.is_empty() and seen.begins_with(absent_prefix):
				named_present = false
		var ok := reached and not failed and _nearest <= PASS_NEAR_M and _detours == 0 and named_present
		all_ok = all_ok and ok
		results.append({"id": leg.id, "ok": ok, "reached_target": reached, "nearest_to_blocker_m": snappedf(_nearest, 0.1),
			"walked_m": snappedf(distance_m - before, 0.1), "wild_bodies_within_15m": _wilds_near.get(leg.id, []),
			"named_wilds_present": named_present, "mobile_obstacle_detours": _detours,
			"player": str(player.global_position)})
		await _frames(10)
	var skipped: Variant = world.get("shelves_skipped_for_routes")
	var shelves := int(skipped) if skipped != null else -1
	var b1_shelf := world.find_child("Ridge002RockShoulder38", true, false)
	var shelf_present := b1_shelf != null and b1_shelf.find_child("VegetatedGeologicalShelf2", true, false) != null
	all_ok = all_ok and not shelf_present
	print("CLOUDREACH ROUTE BLOCKERS " + JSON.stringify({"verdict": "PASS" if all_ok else "FAIL",
		"legs": results, "shelves_skipped_for_routes": shelves,
		"b1_shelf2_present": shelf_present}))
	quit(0 if all_ok else 1)


func _log(kind: String, details: Dictionary = {}) -> void:
	if kind.begins_with("mobile_obstacle_detour"):
		_detours += 1
	super._log(kind, details)


func _track_blocker() -> void:
	if not _blocker.is_finite() or not is_instance_valid(player):
		return
	_nearest = minf(_nearest, player.global_position.distance_to(_blocker))
	if Engine.get_physics_frames() % 30 != 0:
		return
	var seen: Array = _wilds_near.get(stage.trim_prefix("route_blocker_"), [])
	for wild: Variant in director.get("_wild_creatures"):
		if is_instance_valid(wild) and (wild as Node3D).global_position.distance_to(_blocker) <= 15.0 \
				and not seen.has(str((wild as Node).name)):
			seen.append(str((wild as Node).name))
	_wilds_near[stage.trim_prefix("route_blocker_")] = seen
