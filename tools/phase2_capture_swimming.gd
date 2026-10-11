extends SceneTree

## Walk the production first-shore lesson with real input and capture dry,
## entry, surface crossing, and exit states. No game resources are changed.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
var output := "res://ralph/reports/VISUAL/phase2/tidewake/swimming_main"
var _seed := 2042
var _records: Array[Dictionary] = []
var world: Node3D
var player: CharacterBody3D
var rig: Node3D
var swimming: Node
var _entry_saved := false
## trainer|kael|sera|lyra: written to Game.local.chosen_character before the
## world loads, as the title screen does, so each playable body can be judged.
var _character := ""

func _init() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)

func _vector(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))

func _anchor(config: Dictionary, id: String) -> Vector3:
	for raw: Dictionary in config.anchors:
		if str(raw.id) == id:
			return _vector(raw.safe_position)
	return Vector3.INF

func _write_manifest(complete: bool) -> void:
	var file := FileAccess.open(output + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"biome":"tidewake", "system":"swimming",
		"scene":"res://scenes/world/water_archipelago.tscn", "seed":_seed,
		"display_server":DisplayServer.get_name(),
		"rendering_method":RenderingServer.get_current_rendering_method(),
		"resolution":[root.size.x,root.size.y], "frames":_records,
		"complete":complete, "repro_args":["--seed=%d" % _seed]}, "\t") + "\n")
	file.close()

func _save(id: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [output,id]
	if root.get_texture().get_image().save_png(path) == OK:
		_records.append({"id":id,"file":path,"time":"day",
			"state": "swimming" if swimming.is_swimming() else "dry",
			"player_position":str(player.global_position),
			"stamina":float(player.get("vitals").stamina)})
		_write_manifest(false)

func _move_to(target: Vector3, tolerance: float, limit: int) -> bool:
	for frame in limit:
		var offset := target - player.global_position
		offset.y = 0.0
		if offset.length() <= tolerance:
			_action(false)
			await _frames(2)
			return true
		rig.set("yaw", atan2(-offset.x, -offset.z))
		_action(true)
		await physics_frame
		if frame == 10 and swimming.is_swimming() and not _entry_saved:
			await _save("entry")
			_entry_saved = true
		if frame == 180 and swimming.is_swimming():
			await _save("surface_mid")
		if frame == 360 and swimming.is_swimming():
			await _save("surface_far")
	_action(false)
	push_error("Swimming movement timed out toward %s at %s" % [target,player.global_position])
	return false

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--character="):
			_character = arg.trim_prefix("--character=")
	if not output.begins_with("res://ralph/reports/VISUAL/phase2/tidewake/"):
		quit(1)
		return
	seed(_seed)
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i(1920,1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var game := root.get_node("Game")
	if not _character.is_empty():
		(game.get("local") as Object).set("chosen_character", _character)
	game.call("reset_for_new_game")
	game.set("current_realm","water")
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 600:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not bool(world.call("shell_build_complete")):
		push_error("Water shell did not build")
		quit(1)
		return
	player = world.get_node("Player")
	rig = world.get_node("CameraRig")
	swimming = player.get("swim_controller")
	for layer: Node in world.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = false
	var config: Dictionary = world.get("config")
	var lesson: Dictionary = config.swim_lesson
	var west := _anchor(config,str(lesson.start_anchor))
	var east := _anchor(config,str(lesson.end_anchor))
	west.y = float(world.call("ground_height_at",west.x,west.z)) + 0.15
	player.global_position = west
	player.velocity = Vector3.ZERO
	await _frames(45)
	await _save("west_dry_approach")
	if not await _move_to(_vector(lesson.surface_polyline[0]),0.4,900):
		quit(1)
		return
	if not swimming.is_swimming():
		push_error("Did not enter swimming mode")
		quit(1)
		return
	await _save("surface_west")
	if not await _move_to(_vector(lesson.surface_polyline[-1]),0.4,1500):
		quit(1)
		return
	await _save("surface_east")
	if not await _move_to(east,0.8,900):
		quit(1)
		return
	await _frames(10)
	await _save("east_dry_exit")
	_write_manifest(true)
	print("SWIM CAPTURE PASS frames=",_records.size())
	quit(0)
