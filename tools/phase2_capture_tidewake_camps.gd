extends SceneTree

## Normal-camera views of three authored Water camps and their separate sleep
## and craft props. The fixture moves the player only; it does not sleep,
## craft, place a building, spend resources or save progression.

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const CAMPS := ["water_camp_first_shore", "water_camp_brine_steps", "water_camp_salt_crown"]
var _output := "res://ralph/reports/VISUAL/phase2/tidewake/camps_main"
var _seed := 2042
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node3D
var _records: Array[Dictionary] = []
var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
	if not _output.begins_with("res://ralph/reports/VISUAL/phase2/tidewake/"):
		quit(1)
		return
	seed(_seed)
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	var game := root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	_world = WORLD.instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in 600:
		if bool(_world.call("shell_build_complete")):
			break
		await physics_frame
	if not bool(_world.call("shell_build_complete")):
		_failures.append("Water shell did not build")
		_finish()
		return
	_player = _world.get_node("Player")
	_rig = _world.get_node("CameraRig")
	for layer: Node in _world.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = false
	var camps: Node = _world.get_node("WaterCamps")
	for id: String in CAMPS:
		for entry: Array in [
			["camp", id + "_shelter"],
			["bed", id + "_creature_bed"],
			["crafting", id + "_workbench"],
		]:
			var target := camps.get_node_or_null(NodePath(entry[1])) as Node3D
			if target == null:
				_failures.append("Missing %s" % entry[1])
				continue
			await _shoot(id, entry[0], target)
	_finish()


func _shoot(camp_id: String, system: String, target: Node3D) -> void:
	var at := target.global_position
	var stand := Vector3(at.x + 4.0, 0.0, at.z - 5.0)
	stand.y = float(_world.call("ground_height_at", stand.x, stand.z)) + 0.2
	if not is_finite(stand.y):
		_failures.append("No stand ground for %s %s" % [camp_id, system])
		return
	_player.global_position = stand
	_player.velocity = Vector3.ZERO
	var heading := at - stand
	heading.y = 0.0
	_rig.set("yaw", atan2(-heading.x, -heading.z))
	_rig.set("pitch", deg_to_rad(-10.0))
	_rig.call("set_target", _player)
	await _frames(25)
	await RenderingServer.frame_post_draw
	var id := "%s__%s" % [camp_id, system]
	var file := "%s/%s.png" % [_output, id]
	if root.get_texture().get_image().save_png(file) != OK:
		_failures.append("Could not save %s" % id)
		return
	_records.append({"id": id, "file": file, "system": system, "state": "authored %s station" % system,
		"time": "day", "camp": camp_id, "player_position": str(_player.global_position),
		"target_position": str(target.global_position)})
	_write_manifest(false)


func _write_manifest(complete: bool) -> void:
	var manifest := {"biome": "tidewake", "system": "authored_camps",
		"scene": "res://scenes/world/water_archipelago.tscn", "seed": _seed,
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"resolution": [root.size.x, root.size.y],
		"fixture": "Player repositioned beside three built-in camp, creature-bed and workbench props. No rest, recipe, placement, cost or save action shown.",
		"repro_args": ["--seed=%d" % _seed], "output_option": "--output",
		"frames": _records, "failures": _failures, "complete": complete}
	var stream := FileAccess.open(_output + "/manifest.json", FileAccess.WRITE)
	if stream != null:
		stream.store_string(JSON.stringify(manifest, "\t") + "\n")
		stream.close()


func _finish() -> void:
	var done := _failures.is_empty() and _records.size() == CAMPS.size() * 3
	_write_manifest(done)
	print("PHASE2 TIDEWAKE CAMPS frames=%d failures=%s" % [_records.size(), str(_failures)])
	quit(0 if done else 1)
