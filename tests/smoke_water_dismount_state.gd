extends SceneTree

## Production Water scene smoke for the rider's aquatic state after leaving a
## mount (F12, ROADMAP Phase 4 step 20). A trainer who is not mounted must
## never keep publishing MOUNTED: remote peers draw the ride from it and a save
## records it. Covers the band the dismount override skipped (depth between
## the human exit and entry thresholds) and deep water.
##
## Disclosed fixture: the MOUNTED swim state is set directly on an unmounted
## trainer at measured depths, standing in for the moment a real dismount
## hands control back. Placement is the only position write per case; the
## state change is observed through ordinary physics frames.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const STATE := preload("res://scripts/player/swim_state.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

var world: Node3D
var player: CharacterBody3D
var swimming: Node
var assertions := 0
var finished := false
var camera: Node3D
var riding: Node
var director: Node
var real_path := []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(180.0).timeout.connect(func() -> void:
		if not finished:
			_fail("180 second watchdog expired"))
	var game: Node = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://smoke_water_dismount_state_fixture")
	game.current_realm = "water"
	# Real-path fixture, as smoke_water_mounted_swimming.gd: a saddled owned
	# Aquaryn and the personal Swim Stone fact.
	game.local.flags.set_flag("water_swim_stone_earned")
	game.local.flags.set_flag("water_swim_saddle_recipe_taught")
	game.local.inventory.add("swim_saddle", 1)
	if not _expect(game.local.party.add(SPECIES.spawn("water_aquaryn")), "owned Aquaryn fixture"):
		return
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 600:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not _expect(bool(world.call("shell_build_complete")), "Water shell failed to build"):
		return
	player = world.get_node("Player")
	swimming = player.get("swim_controller")
	riding = world.get_node_or_null("RidingController")
	if not _expect(swimming != null and riding != null and not bool(riding.call("is_mounted")),
		"production swim controller and an unmounted riding controller are required"):
		return
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
	var exit_depth := float(config.human.exit_depth_m)
	var entry_depth := float(config.human.entry_depth_m)
	for case: Dictionary in [
		{"name": "shallow band", "depth": (exit_depth + entry_depth) * 0.5},
		{"name": "deep water", "depth": 3.0},
	]:
		var spot := _spot_with_depth(float(case.depth))
		if not _expect(spot.is_finite(), "no water found at %.2f m depth" % float(case.depth)):
			return
		player.global_position = Vector3(spot.x, float(world.field.water_level()) + float(config.human.surface_body_offset_m), spot.z)
		player.velocity = Vector3.ZERO
		swimming.state.enter_water(true, float(world.field.water_level()))
		if not _expect(int(swimming.state.mode) == STATE.Mode.MOUNTED, "fixture did not set MOUNTED"):
			return
		await _frames(6)
		var depth := float(world.call("water_depth_at", player.global_position))
		if not _expect(int(swimming.state.mode) == STATE.Mode.HUMAN,
			"%s: unmounted trainer kept aquatic mode %d at depth %.2f" % [case.name, int(swimming.state.mode), depth]):
			return
		if not _expect(int(swimming.snapshot().mode) == STATE.Mode.HUMAN,
			"%s: published snapshot still says mode %d" % [case.name, int(swimming.snapshot().mode)]):
			return
		if not _expect(int(swimming.save_data().mode) != STATE.Mode.MOUNTED,
			"%s: save would record MOUNTED without a mount" % case.name):
			return
	if not await _real_dismounts(config):
		return
	finished = true
	print("WATER DISMOUNT STATE OK assertions=%d real_path=%s" % [assertions, JSON.stringify(real_path)])
	quit(0)


## The production mount and dismount at several depths off the lesson beach:
## the rider's state must match where the real dismount puts them, in the same
## frame and after settling, and never remain MOUNTED.
func _real_dismounts(config: Dictionary) -> bool:
	camera = world.get_node("CameraRig")
	director = world.get_node("EncounterDirector")
	riding = world.get_node("RidingController")
	var exit_depth := float(config.human.exit_depth_m)
	var lesson: Dictionary = world.get("config").swim_lesson
	var start_raw: Array = world.get("config").anchors.filter(func(row: Dictionary) -> bool:
		return str(row.id) == str(lesson.start_anchor))[0].safe_position
	var shore := Vector3(float(start_raw[0]), 0.0, float(start_raw[2]))
	shore.y = float(world.call("ground_height_at", shore.x, shore.z)) + 0.2
	var deep := _spot_with_depth(3.0)
	# Negative depths mean "arrive from deep water": the ride keeps MOUNTED
	# while the mount comes back in toward the shore.
	for target_depth: float in [0.5, 0.8, 1.0, 1.5, 3.0, -1.1, -1.2, -1.3, -1.4]:
		var from_deep := target_depth < 0.0
		target_depth = absf(target_depth)
		var spot := _spot_with_depth(target_depth)
		if not _expect(spot.is_finite(), "no water at %.2f m for the real dismount" % target_depth):
			return false
		director.dismiss_active_creature()
		player.global_position = shore
		player.velocity = Vector3.ZERO
		swimming.state.leave_water()
		await _frames(30)
		if not _expect(bool(director.summon_active_creature()), "production summon of the owned Aquaryn"):
			return false
		await _frames(30)
		if not _expect(bool(riding.call("mount")), "production mount from dry shore"):
			return false
		if from_deep and not await _ride_to(deep, 0.8, 1200):
			return false
		if not await _ride_to(spot, 0.8, 1200):
			return false
		await _frames(10)
		var before := int(swimming.state.mode)
		if not _expect(bool(riding.call("dismount")), "production dismount at %.2f m" % target_depth):
			return false
		var depth := float(world.call("water_depth_at", player.global_position))
		var same_frame := int(swimming.state.mode)
		await _frames(8)
		var settled := int(swimming.state.mode)
		var settled_depth := float(world.call("water_depth_at", player.global_position))
		real_path.append({"target": target_depth, "from_deep": from_deep, "mode_before": before, "dismount_depth": snappedf(depth, 0.01),
			"same_frame_mode": same_frame, "settled_mode": settled, "settled_depth": snappedf(settled_depth, 0.01)})
		# Deep water swims and wading depth stands. Between the thresholds the
		# swim state's hysteresis keeps whichever of HUMAN or LAND the trainer
		# arrived in; only a leftover MOUNTED is wrong.
		var entry_depth := float(config.human.entry_depth_m)
		var allowed: Array = [STATE.Mode.HUMAN] if depth >= entry_depth else \
			([STATE.Mode.LAND] if depth <= exit_depth else [STATE.Mode.HUMAN, STATE.Mode.LAND])
		# A live ride handed back in the band keeps swimming as a human.
		if before == STATE.Mode.MOUNTED and depth > exit_depth and depth < entry_depth:
			allowed = [STATE.Mode.HUMAN]
		if not _expect(allowed.has(same_frame),
			"real dismount at %.2f m (mode before %d) left mode %d in the same frame" % [depth, before, same_frame]):
			return false
		if not _expect(settled != STATE.Mode.MOUNTED and int(swimming.snapshot().mode) != STATE.Mode.MOUNTED,
			"real dismount at %.2f m published MOUNTED after settling" % depth):
			return false
	# The defect path: a live ride (MOUNTED) handed back where a human does not
	# swim-enter (below the entry depth). Main left MOUNTED in that frame.
	var shallow := real_path.filter(func(row: Dictionary) -> bool:
		return int(row.mode_before) == STATE.Mode.MOUNTED and float(row.dismount_depth) < float(config.human.entry_depth_m))
	if not _expect(not shallow.is_empty(), "no real MOUNTED dismount below the entry depth: %s" % JSON.stringify(real_path)):
		return false
	return true


func _ride_to(target: Vector3, tolerance: float, limit: int) -> bool:
	var body: Node3D = riding.call("mount_body")
	for _frame in limit:
		var offset := target - body.global_position
		offset.y = 0.0
		if offset.length() <= tolerance:
			_action(false)
			await _frames(2)
			return true
		camera.set("yaw", atan2(-offset.x, -offset.z))
		_action(true)
		await physics_frame
		if not bool(riding.call("is_mounted")):
			return _fail("unexpected dismount while riding toward %s" % target)
	_action(false)
	return _fail("mounted approach timed out toward %s at %s" % [target, body.global_position])


func _action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


## Nearest point off the First Shore lesson beach at the requested depth,
## found by marching seaward along the authored lesson course.
func _spot_with_depth(target: float) -> Vector3:
	var lesson: Dictionary = world.get("config").swim_lesson
	var start: Array = lesson.surface_polyline[0]
	var from := Vector3(float(start[0]), 0.0, float(start[2]))
	var seaward := (from - Vector3(0, 0, 0)).normalized()
	seaward.y = 0.0
	for step in 4000:
		var at := from + seaward * (float(step) * 0.05 - 40.0)
		var depth := float(world.call("water_depth_at", at))
		if absf(depth - target) < 0.03:
			return at
	return Vector3.INF


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _expect(condition: bool, message: String) -> bool:
	assertions += 1
	return true if condition else _fail(message)


func _fail(message: String) -> bool:
	_action(false)
	finished = true
	push_error("WATER DISMOUNT STATE: " + message)
	quit(1)
	return false
