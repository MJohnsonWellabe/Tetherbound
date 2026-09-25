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

var world: Node3D
var player: CharacterBody3D
var swimming: Node
var assertions := 0
var finished := false


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
	var riding: Node = world.get_node_or_null("RidingController")
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
	finished = true
	print("WATER DISMOUNT STATE OK assertions=%d" % assertions)
	quit(0)


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
	finished = true
	push_error("WATER DISMOUNT STATE: " + message)
	quit(1)
	return false
