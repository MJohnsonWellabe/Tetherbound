extends SceneTree

## Scratch diagnostic for OWNER-0902-VILLAGE-GATE-REGRESSION. Fast iteration on
## the ONE corner (index 3, (18,21)) the exhaustive PART 6 sweep caught
## jumping out, after widening `village_boundary.gd::_build_corner_guards`'s
## POST_HALF from 0.6 to 1.1 -- re-tests just this corner (plus its two
## neighbours as a margin check) instead of paying for the full ~45-panel +
## 22-corner sweep again before committing to a full re-run.
##
##   godot --headless --path . --script tools/_diag_corner3_jump.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const SQUARE := Vector3(10.0, 0.0, -10.0)
const JUMP_TIMING_FRAMES: Array[int] = [24, 30, 36, 42, 48, 54, 60]

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _outline: PackedVector2Array


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
		print("no player/rig")
		quit(1)
		return

	var boundary_cfg := _load_json("res://data/config/village_boundary.json")
	const VILLAGE_BOUNDARY := preload("res://scripts/world/village_boundary.gd")
	_outline = VILLAGE_BOUNDARY.outline(boundary_cfg)

	var game := root.get_node_or_null(^"Game")
	var progression: RefCounted = game.get("progression") if game != null else null
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

	_player.set("_unstick_enabled", false)

	for idx in [2, 3, 4]:
		var corner: Vector2 = _outline[idx]
		await _try_jump_escape("Corner[%d]@%s" % [idx, str(corner)], corner)

	quit(0)


func _try_jump_escape(label: String, at: Vector2) -> void:
	var out_dir := (at - Vector2(SQUARE.x, SQUARE.z)).normalized()
	var start := Vector3(at.x, 0.0, at.y) - Vector3(out_dir.x, 0.0, out_dir.y) * 4.0
	var target := Vector3(at.x, 0.0, at.y) + Vector3(out_dir.x, 0.0, out_dir.y) * 20.0
	var best_out := false
	var best_pos := start
	for jump_at: int in JUMP_TIMING_FRAMES:
		await _teleport(start)
		for i in 75:
			var to := target - _player.global_position
			to.y = 0.0
			_rig.set("yaw", atan2(-to.x, -to.z))
			Input.action_press("move_forward")
			if i == jump_at:
				Input.action_press("jump")
			else:
				Input.action_release("jump")
			await physics_frame
		Input.action_release("move_forward")
		Input.action_release("jump")
		for i in 10:
			await physics_frame
		var here := _player.global_position
		const VILLAGE_BOUNDARY := preload("res://scripts/world/village_boundary.gd")
		var inside: bool = VILLAGE_BOUNDARY.contains(_outline, Vector2(here.x, here.z))
		if not inside:
			best_out = true
			best_pos = here
			print("    jump_at=%d -> OUT at %s" % [jump_at, str(here.snapped(Vector3.ONE * 0.1))])
		else:
			best_pos = here
	print("  jump attempts at %-14s from %s -> best result %s  %s" % [
		label, str(start.snapped(Vector3.ONE * 0.1)), str(best_pos.snapped(Vector3.ONE * 0.1)),
		("JUMPED OUT (outside polygon)" if best_out else "held (inside) on every timing tried")])


func _teleport(to: Vector3) -> void:
	var ground: float = float(_world.call("ground_height_at", to.x, to.z))
	_player.global_position = Vector3(to.x, (ground if not is_nan(ground) else 0.0) + 1.0, to.z)
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
