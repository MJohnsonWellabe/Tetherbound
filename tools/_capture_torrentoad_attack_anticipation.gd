extends SceneTree

## One fixed production-body A/B sequence for Torrentoad attack timing. Both
## lanes use WildCreature, the installed model, and the same stage/camera. A
## removes only the optional contact metadata from its animator; B uses the
## production animation map unchanged.

const BODY_SCENE := preload("res://scenes/creatures/creature.tscn")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const ANIMATOR := preload("res://scripts/creatures/creature_animator.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")

const DEFAULT_OUT := "res://shots/creatures-attack-anticipation/torrentoad-corrected"
const STEP := 1.0 / 60.0
const TELEGRAPH_SECONDS := 1.0

var _world: Node3D
var _camera: Camera3D
var _records: Array[Dictionary] = []
var _out := DEFAULT_OUT
var _appearance_path := ""
var _appearance_sha := ""
var _appearance_overrides := 0
var _appearance_surface_facts: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			_out = argument.trim_prefix("--output=")
		elif argument.begins_with("--appearance="):
			_appearance_path = argument.trim_prefix("--appearance=")
	if _appearance_path != "":
		_appearance_sha = FileAccess.get_sha256(_appearance_path)
	_world = Node3D.new()
	root.add_child(_world)
	_build_stage()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))

	for lane: String in ["A", "B"]:
		await _capture_lane(lane)

	var manifest := {
		"captured_utc": Time.get_datetime_string_from_system(true, true),
		"viewport": root.get_viewport().get_visible_rect().size,
		"species": "torrentoad",
		"telegraph_seconds": TELEGRAPH_SECONDS,
		"appearance_path": _appearance_path,
		"appearance_sha256": _appearance_sha,
		"appearance_surface_overrides": _appearance_overrides,
		"appearance_surface_facts": _appearance_surface_facts,
		"records": _records,
	}
	var manifest_path := ProjectSettings.globalize_path(_out + "/manifest.json")
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		push_error("cannot write %s" % manifest_path)
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  "))
	file.close()
	print("[attack-capture] RESULT=" + JSON.stringify({"images": _records.size(), "manifest": manifest_path}))
	quit(0 if _records.size() == 8 else 1)


func _capture_lane(lane: String) -> void:
	var wild := BODY_SCENE.instantiate() as CharacterBody3D
	wild.name = "Torrentoad_%s" % lane
	wild.set_script(WILD)
	_world.add_child(wild)
	var target := Node3D.new()
	target.name = "Target_%s" % lane
	target.position = Vector3(0.0, 0.0, 2.0)
	_world.add_child(target)
	assert(wild.call("populate", "torrentoad", target))
	if _appearance_path != "":
		_apply_appearance(wild, _appearance_path)
	wild.position = Vector3.ZERO
	wild.rotation.y = deg_to_rad(25.0)
	wild.set_physics_process(false)

	var player := _animation_player(wild)
	assert(player != null)
	if lane == "A":
		var clips: Dictionary = (SPECIES.table()["torrentoad"]["placeholder"]["animations"] as Dictionary).duplicate(true)
		clips.erase("attack_contact_phase")
		clips.erase("_comment_attack_contact_phase")
		wild.set("_animator", ANIMATOR.new(player, clips))
	var animator: RefCounted = wild.get("_animator")
	animator.call("tick", 0.0, 0.0, 1.0)
	player.seek(0.0, true)
	_pause_for_capture(player)

	var events := {"telegraph": [], "strikes": 0}
	wild.telegraph_started.connect(func(seconds: float) -> void:
		(events["telegraph"] as Array).append(seconds)
	)
	wild.strike_ready.connect(func() -> void:
		events["strikes"] = int(events["strikes"]) + 1
		wild.call("play_attack")
	)
	await _shutter(lane, "t000", wild, player, events, 0.0)

	wild.call("set_engaged", true, target)
	var cfg: Dictionary = (wild.get("_combat_cfg") as Dictionary).duplicate(true)
	cfg["telegraph"] = TELEGRAPH_SECONDS
	wild.set("_combat_cfg", cfg)
	wild.call("_enter", AI.Intent.TELEGRAPH)
	_pause_for_capture(player)
	_step_state(wild, animator, player, 30)
	await _shutter(lane, "t050", wild, player, events, 0.5)

	_step_state(wild, animator, player, 29)
	# The last WildCreature state step emits strike_ready. Photograph before the
	# animator's same-frame recovery advance so this is the actual contact pose.
	player.play()
	wild.call("_tick_combat", STEP)
	_pause_for_capture(player)
	await _shutter(lane, "t100", wild, player, events, 1.0)

	_step_state(wild, animator, player, 12)
	await _shutter(lane, "t120", wild, player, events, 1.2)

	wild.queue_free()
	target.queue_free()
	await process_frame


func _step_state(wild: Node, animator: RefCounted, player: AnimationPlayer, frames: int) -> void:
	player.play()
	for _frame in frames:
		wild.call("_tick_combat", STEP)
		animator.call("tick", STEP, 0.0, 1.0)
		player.advance(STEP)
	_pause_for_capture(player)


func _pause_for_capture(player: AnimationPlayer) -> void:
	# Retain the real effective speed before pausing freezes the exact pose for
	# the shutter. `get_playing_speed()` itself correctly returns zero afterward.
	player.set_meta("capture_playing_speed", player.get_playing_speed())
	player.pause()


func _shutter(lane: String, stamp: String, wild: Node, player: AnimationPlayer,
		events: Dictionary, seconds: float) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s-%s.png" % [_out, lane, stamp]
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(path)) if image != null else ERR_CANT_CREATE
	var record := {
		"lane": lane,
		"stamp": stamp,
		"seconds": seconds,
		"captured_utc": Time.get_datetime_string_from_system(true, true),
		"path": path,
		"save_error": error,
		"intent": int(wild.get("_intent")),
		"beat_left": float(wild.get("_beat_left")),
		"telegraph_events": (events["telegraph"] as Array).duplicate(),
		"strike_events": int(events["strikes"]),
		# `pause()` clears current_animation but retains the assigned clip and
		# exact pose. Record the property that survives the controlled shutter.
		"animation": player.assigned_animation,
		"animation_position": player.current_animation_position,
		"speed_scale": player.speed_scale,
		"playing_speed_before_pause": float(player.get_meta("capture_playing_speed", 0.0)),
	}
	_records.append(record)
	print("[attack-capture] " + JSON.stringify(record))
	if error != OK:
		push_error("failed to save %s: %s" % [path, error])


func _animation_player(node: Node) -> AnimationPlayer:
	var players: Array[Node] = node.find_children("*", "AnimationPlayer", true, false)
	return null if players.is_empty() else players[0] as AnimationPlayer


func _apply_appearance(node: Node, path: String) -> void:
	var image := Image.load_from_file(path)
	assert(image != null and not image.is_empty())
	var texture := ImageTexture.create_from_image(image)
	assert(not image.has_mipmaps())
	for child: Node in node.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface in instance.mesh.get_surface_count():
			var material := instance.get_active_material(surface) as BaseMaterial3D
			if material == null or material.albedo_texture == null:
				continue
			if not material.albedo_texture.resource_path.contains("torrentoad_extracted_base_color_vivid"):
				continue
			var copy := material.duplicate(true) as BaseMaterial3D
			var filter_before := int(material.texture_filter)
			if copy.emission_texture == copy.albedo_texture:
				copy.emission_texture = texture
			copy.albedo_texture = texture
			instance.set_surface_override_material(surface, copy)
			_appearance_surface_facts.append({
				"lane_body": node.name,
				"mesh": instance.name,
				"surface": surface,
				"source_texture": material.albedo_texture.resource_path,
				"override_mipmaps": image.has_mipmaps(),
				"filter_before": filter_before,
				"filter_after": int(copy.texture_filter),
			})
			_appearance_overrides += 1


func _build_stage() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("30373b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.76, 0.80)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_node.environment = env
	_world.add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-38.0), deg_to_rad(-28.0), 0.0)
	sun.light_energy = 0.72
	sun.shadow_enabled = true
	_world.add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(18.0, 12.0)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("657069")
	floor.material_override = floor_material
	_world.add_child(floor)
	_camera = Camera3D.new()
	_camera.position = Vector3(3.0, 3.4, 10.0)
	_camera.fov = 42.0
	_world.add_child(_camera)
	_camera.look_at(Vector3(0.0, 1.8, 0.0), Vector3.UP)
	_camera.make_current()
