extends SceneTree

## Production Fly input at clear ground stands outside Cloudreach, after an
## in-memory unlock and a legal Galecrest carrier. Records real launch/glide/
## landing or a manifest with the controller's refusal reason.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SCENES := {
	"meadows": "res://scenes/world/meadows_playground.tscn",
	"tidewake": "res://scenes/world/water_archipelago.tscn",
	"stormwood": "res://scenes/world/stormwood.tscn",
}
const STANDS := {
	"meadows": [Vector2(-25.0, 1300.0), Vector2(48.0, 1400.0)],
	"tidewake": [Vector2(35.707, 98.104), Vector2(7.0, 142.0)],
	"stormwood": [Vector2(-320.0, 240.0), Vector2(-520.0, 1660.0)],
}
var _biome := ""
var _output := ""
var _seed := 2042
var _records: Array[Dictionary] = []
var _failures: Array[String] = []
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node3D
var _fly: Node


func _init() -> void:
	_run.call_deferred()


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _action(name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="):
			_biome = arg.trim_prefix("--biome=")
		elif arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
	if not SCENES.has(_biome) or not _output.begins_with("res://ralph/reports/VISUAL/phase2/%s/" % _biome):
		quit(1)
		return
	seed(_seed)
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	var game := root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water" if _biome == "tidewake" else _biome
	game.progression.set_flag("fly_traversal_unlocked")
	if _biome == "stormwood":
		game.progression.set_flag("stormwood:canopy_flight_forbidden")
	game.party.add(SPECIES.spawn("galecrest"))
	_world = (load(SCENES[_biome]) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in 600:
		if bool(_world.call("shell_build_complete")):
			break
		await physics_frame
	if not bool(_world.call("shell_build_complete")):
		_failures.append("World shell did not build")
		_finish()
		return
	_player = _world.get_node("Player")
	_rig = _world.get_node("CameraRig")
	_fly = _player.get("fly_controller")
	for layer: Node in _world.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = false
	var succeeded := false
	for stand: Vector2 in STANDS[_biome]:
		for offset: Vector2 in [Vector2.ZERO, Vector2(16, 0), Vector2(-16, 0), Vector2(0, 16), Vector2(0, -16), Vector2(32, 32), Vector2(-32, -32)]:
			if await _attempt(stand + offset):
				succeeded = true
				break
		if succeeded:
			break
	_finish()


func _attempt(xz: Vector2) -> bool:
	var start_count := _records.size()
	var ground := float(_world.call("ground_height_at", xz.x, xz.y))
	if not is_finite(ground):
		_failures.append("No ground at %s" % str(xz))
		return false
	_player.global_position = Vector3(xz.x, ground + 0.3, xz.y)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", 0.0)
	_rig.set("pitch", deg_to_rad(-8.0))
	_rig.call("set_target", _player)
	await _frames(80)
	var blockers := str(_fly.call("launch_blockers"))
	var elevated := false
	if (_biome == "meadows" and blockers == "Find a clear launch with room for your companion overhead.") or _biome == "stormwood":
		# A fixture ledge provides clearance and airtime while the actual
		# Jump, Fly restriction checks, glide and descend remain production code.
		_player.global_position += Vector3.UP * 60.0
		_player.velocity = Vector3.ZERO
		await _frames(4)
		blockers = str(_fly.call("launch_blockers"))
		elevated = true
	if not blockers.is_empty():
		_failures.append("At %s: %s" % [str(xz), blockers])
		return false
	if not elevated:
		_action("jump", true)
		await _frames(3)
		_action("jump", false)
		await _frames(6)
	_action("jump", true)
	await _frames(3)
	_action("jump", false)
	if not bool(_fly.call("is_flying")):
		_failures.append("At %s: double Jump denied: %s" % [str(xz), str(_fly.get("last_denial"))])
		return false
	if elevated:
		# Let the normal follow camera catch up with the fixture ledge before
		# naming this a launch frame; the immediate image contains only scenery.
		await _frames(24)
	await _save("launch")
	await _frames(80)
	if bool(_fly.call("is_flying")):
		await _save("glide")
	_action("fly_descend", true)
	for i in 900:
		if not bool(_fly.call("is_flying")):
			break
		await physics_frame
	_action("fly_descend", false)
	await _frames(18)
	if not bool(_fly.call("is_flying")) and _player.is_on_floor():
		await _save("landed")
	else:
		_failures.append("At %s: flight did not land cleanly" % str(xz))
	return _records.size() - start_count == 3


func _save(id: String) -> void:
	await RenderingServer.frame_post_draw
	var file := "%s/%02d-%s.png" % [_output, _records.size() + 1, id]
	if root.get_texture().get_image().save_png(file) == OK:
		_records.append({"id": id, "file": file, "state": str(_fly.get("state")),
			"time": "day", "position": str(_player.global_position)})
		_write_manifest(false)


func _write_manifest(complete: bool) -> void:
	var manifest := {"biome": _biome, "system": "flying", "scene": SCENES[_biome],
		"seed": _seed, "display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"resolution": [root.size.x, root.size.y],
		"fixture": "In-memory Fly unlock and one Galecrest carrier; actual Jump, glide and descend input at realm stands. Meadows adds 60 m fixture height above a grounded safe anchor for clearance/airtime. Stormwood also lifts its sealed canopy flag in memory and adds 60 m fixture height, so those frames show possible carrier art rather than reachable campaign traversal. No campaign progression proof",
		"repro_args": ["--biome=%s" % _biome, "--seed=%d" % _seed],
		"output_option": "--output", "frames": _records,
		"failures": _failures, "complete": complete}
	var stream := FileAccess.open(_output + "/manifest.json", FileAccess.WRITE)
	if stream != null:
		stream.store_string(JSON.stringify(manifest, "\t") + "\n")
		stream.close()


func _finish() -> void:
	var complete := _records.size() >= 3 and _records.any(func(frame: Dictionary) -> bool: return frame.id == "glide")
	_write_manifest(complete)
	print("PHASE2 %s FLIGHT frames=%d failures=%s" % [_biome, _records.size(), str(_failures)])
	quit(0 if complete else 1)
