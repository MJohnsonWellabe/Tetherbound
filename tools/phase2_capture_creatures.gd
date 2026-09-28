extends SceneTree

## Phase 2 creature pose inventory in the production biome, with the trainer
## as a scale ruler and the production camera. This is a visual fixture: pose
## calls do not claim that a combat or traversal path was played.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const SCENES := {
	"meadows": "res://scenes/world/meadows_playground.tscn",
	"water": "res://scenes/world/water_archipelago.tscn",
	"cloudreach": "res://scenes/world/cloudreach_cliffs.tscn",
	"stormwood": "res://scenes/world/stormwood.tscn",
}
const STAGES := {
	"meadows": Vector2(-430.0, 470.0),
	"water": Vector2(35.0, 110.0),
	"cloudreach": Vector2(-286.0, 535.0),
	"stormwood": Vector2(-350.0, 450.0),
}
const SPECIES := {
	"meadows": ["terrapup", "bramblebun", "mudsnout", "trailpup", "burrowback",
		"meadowhart", "paddlenewt", "mosshell", "brooktail", "galecrest", "duskhush",
		"pipwing", "reedwing", "nightburrow", "stormtrail", "riftfrill", "veridian"],
	"water": ["ripplet", "cannonback", "riptusk", "mirejaw", "aquaryn", "torrentoad", "mosshell",
		"cragclaw", "riverdrake", "sirenseal", "mangrove_monitor", "tidecoil", "abyssal_guardian"],
	"cloudreach": ["galewisp", "glimmermoth", "stormcapra", "skyrill", "aeriex",
		"ribbonray", "breezetail", "cloudfang", "cliffspike", "tempestwing", "solmane",
		"craghorn", "pebbik", "galecrest"],
	"stormwood": ["stormtrail", "voltwig", "mosshock", "staticub", "voltarach",
		"fulgocobra", "stormraven", "pebbik", "craghorn", "stormbrush",
		"tanglevolt", "thundertunnel", "sparkit", "glimmermoth"],
}
const POSES := ["idle", "moving", "attacking", "hurt", "resting", "fainted"]

var _biome := ""
var _output := ""
var _seed := 2042
var _only := ""
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _records: Array[Dictionary] = []
var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Phase 2 creature capture needs a rendering display")
		quit(1)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="):
			_biome = arg.trim_prefix("--biome=")
		elif arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
	if not SCENES.has(_biome) or not _output.begins_with("res://ralph/reports/VISUAL/phase2/"):
		push_error("Use --biome and a Phase 2 evidence output")
		quit(1)
		return
	seed(_seed)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Game autoload missing")
		quit(1)
		return
	if game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
	game.set("current_realm", _biome)
	_world = (load(str(SCENES[_biome])) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + 900000
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			push_error("Production world build timed out")
			quit(1)
			return
		await process_frame
	for frame in 24:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	if _player == null or _rig == null or _camera == null:
		push_error("Production trainer or camera missing")
		quit(1)
		return
	var stage: Vector2 = STAGES[_biome]
	if not bool(game.call("debug_teleport_to", stage.x, stage.y, _biome, "")):
		push_error("Stage teleport refused")
		quit(1)
		return
	var ground := float(_world.call("ground_height_at", stage.x, stage.y))
	_player.global_position = Vector3(stage.x, ground + 0.3, stage.y)
	_player.velocity = Vector3.ZERO
	_rig.call("set_target", _player)
	_rig.set("yaw", PI)
	_rig.rotation.y = PI
	_rig.global_position = _player.global_position
	_camera.make_current()
	var terrain := _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)
	var look := _world.get_node_or_null(^"WorldLook")
	if look != null and look.has_method("apply_time"):
		look.call("apply_time", "day")
		look.set_process(false)
	for node: Node in _world.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false
	for frame in 45:
		await physics_frame
	for species: String in SPECIES[_biome]:
		if not _only.is_empty() and species != _only:
			continue
		for pose: String in POSES:
			await _capture_pose(species, pose, false, 1.0)
		await _capture_pose(species, "shiny_idle", true, 1.0)
		var alpha_scale := _alpha_scale(species)
		if alpha_scale > 1.0:
			await _capture_pose(species, "alpha_idle", false, alpha_scale)
	var manifest := {"biome": _biome, "scene": SCENES[_biome], "seed": _seed,
		"stage_xz": [stage.x, stage.y], "display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [root.size.x, root.size.y],
		"fixture": "Production scene, trainer and camera; direct visual pose fixture, not combat or traversal proof",
		"frames": _records, "failures": _failures, "complete": _failures.is_empty()}
	var file := FileAccess.open("%s/manifest.json" % _output, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.close()
	quit(0 if _failures.is_empty() else 1)


func _capture_pose(species: String, pose: String, shiny: bool, scale_factor: float) -> void:
	var stage: Vector2 = STAGES[_biome]
	var ground := float(_world.call("ground_height_at", stage.x, stage.y + 14.0))
	var body := CREATURE_SCENE.instantiate() as Node3D
	body.name = "Phase2_%s_%s" % [species, pose]
	body.set_script(BODY)
	_world.add_child(body)
	body.call("setup", species, shiny)
	if scale_factor > 1.0 and body.has_method("apply_size_multiplier"):
		body.call("apply_size_multiplier", scale_factor)
	body.global_position = Vector3(stage.x, ground, stage.y + 14.0)
	body.rotation.y = PI
	body.set_process(false)
	body.set_physics_process(false)
	_seat(body, ground)
	var animator: Variant = body.get("_animator")
	if pose == "moving" and animator is Object:
		(animator as Object).call("tick", 0.0, 4.0, 8.0)
	elif pose == "attacking":
		body.call("play_attack")
	elif pose == "hurt":
		body.call("play_hit")
	elif pose == "resting":
		body.call("play_rest")
	elif pose == "fainted":
		body.call("play_faint")
	elif animator is Object:
		(animator as Object).call("tick", 0.0, 0.0, 8.0)
	for frame in 5:
		await process_frame
	var players := body.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		var player := players[0] as AnimationPlayer
		if not str(player.current_animation).is_empty():
			var length := player.get_animation(player.current_animation).length
			player.seek(length * (0.9 if pose == "fainted" else 0.45), true)
			player.pause()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var frame_id := "%s__%s__%s" % [_biome, species, pose]
	var path := "%s/%s.jpg" % [_output, frame_id]
	if image == null or image.is_empty() or image.get_width() != 1920 or image.get_height() != 1080:
		_failures.append("%s: wrong-sized or empty image" % frame_id)
	elif image.save_jpg(path, 0.87) != OK:
		_failures.append("%s: save failed" % frame_id)
	else:
		_records.append({"id": frame_id, "species": species, "pose": pose,
			"shiny": shiny, "alpha_scale": scale_factor, "path": path,
			"animation": str((players[0] as AnimationPlayer).current_animation) if not players.is_empty() else "",
			"trainer_visible_intent": true, "camera": "production CameraRig/Camera3D"})
		print("PHASE2 CREATURE %s -> %s" % [frame_id, path])
	body.queue_free()
	await process_frame


func _seat(body: Node3D, ground: float) -> void:
	var pivot := body.get_node_or_null(^"Model") as Node3D
	if pivot == null:
		return
	var bounds: AABB = RENDER_BOUNDS.measure(pivot)
	if bounds.size == Vector3.ZERO:
		return
	var foot := bounds.position.y * pivot.global_transform.basis.get_scale().y
	body.global_position.y = ground - foot


func _alpha_scale(species: String) -> float:
	if _biome != "meadows":
		return 1.0
	for band: String in ["band1_lower_meadows", "band2_stone_and_root",
		"band3_the_river_lock", "band4_upper_meadows_ironwood", "band5_stronghold_approach"]:
		var path := "res://data/config/bands/%s/spawns.json" % band
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			continue
		for raw: Variant in (parsed as Dictionary).get("spawns", []):
			if raw is Dictionary and str((raw as Dictionary).get("species", "")) == species:
				var alpha: Variant = (raw as Dictionary).get("alpha", {})
				if alpha is Dictionary:
					var factor := float((alpha as Dictionary).get("scale", 1.0))
					if factor > 1.0:
						return factor
	return 1.0
