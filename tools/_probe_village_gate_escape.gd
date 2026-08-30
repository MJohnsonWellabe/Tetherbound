extends SceneTree

## OP-0830-1 reproduction: can the player leave the village without the key?
##
##   godot --headless --path . --script tools/_probe_village_gate_escape.gd
##
## The owner's report is "the village gate is pointless. it doesn't keep you
## in." Every existing check walks the player AT the gate and asks whether they
## crossed its own plane -- which the gate passes. This asks the question the
## owner actually asked: standing in the village square with no key, how far can
## a player get in ANY direction?
##
## Diagnostic only. Prints; never asserts.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const SQUARE := Vector3(10.0, 0.0, -10.0)
## How far from the square counts as "out of the village". The furthest village
## structure (`village.json`) sits ~22m from the well; 60m is unambiguously out.
const OUT_M := 60.0
const FAN_FRAMES := 900

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		print("no player/rig; probe cannot run")
		quit(1)
		return

	var game := root.get_node_or_null(^"Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	var progression: RefCounted = game.get("progression") if game != null else null

	# The opening owns the player until the first catch: locomotion is locked and
	# the house door is shut. This probe is about the VILLAGE gate, which the
	# player meets after that, so hand control back the way a finished opening
	# does -- the beat flag the director itself restores from.
	var director := _world.get_node_or_null(^"SequenceDirector")
	if director == null:
		for child: Node in _world.get_children():
			if child.get_script() != null and str(child.get_script().resource_path).ends_with("sequence_director.gd"):
				director = child
				break
	if director != null and progression != null:
		progression.call("set_flag", "opening:beat:free_play")
		director.call("restore_progression_from_game", game)
		for i in 30:
			await physics_frame
		print("opening beat forced to '%s'" % str(director.call("beat")))

	print("key held: %d   road_gate_open: %s" % [
		int(inventory.call("count", "castle_gate_key")) if inventory != null else -1,
		str(progression.call("has", "road_gate_open")) if progression != null else "?"])

	var gate := _world.get_node_or_null(^"RoadGate") as Node3D
	if gate != null:
		print("RoadGate at %s   open=%s" % [
			str(gate.global_position.snapped(Vector3.ONE * 0.1)), str(gate.call("is_open"))])
		var across := gate.global_transform.basis.x
		print("  fence line runs along %s (world)" % str(Vector3(across.x, 0.0, across.z).normalized().snapped(Vector3.ONE * 0.01)))

	# The controller's entombment failsafe rewinds to a breadcrumb the body
	# actually stood on -- which, after a teleport, is still inside the house.
	# Off for the probe: this measures barriers, not the failsafe.
	_player.set("_unstick_enabled", false)

	# Every direction a player might wander, from the square itself.
	print("\n--- walking out of the village on 16 bearings, no key ---")
	var escaped: Array[String] = []
	for step in 16:
		var deg := float(step) * 22.5
		var dir := Vector3(sin(deg_to_rad(deg)), 0.0, cos(deg_to_rad(deg)))
		# Five metres out along the bearing, not the square's own centre:
		# village.json stands the well on [10,-10] exactly, and a body dropped
		# inside its collider cannot walk anywhere at all.
		await _teleport(SQUARE + dir * 5.0)
		var target: Vector3 = SQUARE + dir * (OUT_M + 40.0)
		await _walk_toward(target, FAN_FRAMES)
		var here := _player.global_position
		var out: float = Vector2(here.x - SQUARE.x, here.z - SQUARE.z).length()
		var verdict := "OUT" if out >= OUT_M else "held"
		if out >= OUT_M:
			escaped.append("%.0f deg" % deg)
		print("  bearing %5.1f deg -> %5.1fm from the square at %s   %s" % [
			deg, out, str(here.snapped(Vector3.ONE * 0.1)), verdict])

	print("\nescaped the village on %d of 16 bearings: %s" % [escaped.size(), str(escaped)])
	quit(0)


func _teleport(to: Vector3) -> void:
	var ground: float = float(_world.call("ground_height_at", to.x, to.z))
	_player.global_position = Vector3(to.x, (ground if not is_nan(ground) else 0.0) + 1.0, to.z)
	_player.velocity = Vector3.ZERO
	print("  [tp] asked %s -> immediately %s" % [
		str(to.snapped(Vector3.ONE * 0.1)), str(_player.global_position.snapped(Vector3.ONE * 0.1))])
	for i in 20:
		await physics_frame
	print("  [tp] after 20 frames %s" % str(_player.global_position.snapped(Vector3.ONE * 0.1)))


func _walk_toward(point: Vector3, frames: int) -> void:
	for i in frames:
		var to := point - _player.global_position
		to.y = 0.0
		if to.length() <= 0.8:
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 5:
		await physics_frame
