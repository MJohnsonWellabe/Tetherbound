extends SceneTree

## P2-073/074/075 evidence through the production arbiter and actual Interact.
## Native Windows launcher (Godot executable supplied by the caller):
## & $Godot --path D:\tetherbound\x04-tidewake --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 1920x1080 --fullscreen --script res://tools/phase2_capture_tidewake_dialogue_interaction.gd -- --output=res://.artifacts/phase2/tidewake_dialogue_interaction --only=water_venn,water_nerissa,water_trainer_rune,water_trainer_odan
## The initial player stand is staged once per actor, outside the normal prompt
## radius. Subsequent approach uses ordinary movement input. This is local
## interaction/camera evidence, NOT an earned route, campaign or visual pass.
## No dialogue start, camera pose/target, encounter, collider or flag overrides.
## Water trainer challenges can refuse or enter combat instead of dialogue;
## those outcomes remain diagnostic failures, never fabricated dialogue proof.

const SCENE := "res://scenes/world/water_archipelago.tscn"
const CAST := "res://data/config/water_characters.json"
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SIZE := Vector2i(1920, 1080)
const SEED := 2042
const DEFAULT_IDS := [
	"water_trainer_daro", "water_trainer_bex", "water_trainer_irva",
	"water_trainer_lysa", "water_trainer_oswin", "water_trainer_tovin",
	"water_trainer_yara", "water_trainer_vera", "water_nalia",
	"water_venn", "water_nerissa", "water_tovin", "water_trainer_venn",
	"water_trainer_nerissa", "water_trainer_rune", "water_trainer_odan",
	"water_adair", "water_iona", "water_rowan", "water_otto",
]
const MOVE_ACTIONS := ["move_left", "move_right", "move_forward", "move_back"]

var _output := "res://.artifacts/phase2/tidewake_dialogue_interaction"
var _ids: Array[String] = []
var _specs: Dictionary = {}
var _manifest: Dictionary = {}
var _failures: Array[String] = []
var _frames: Array[Dictionary] = []
var _results: Array[Dictionary] = []
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node3D
var _camera: Camera3D
var _arbiter: Node
var _panel: Node
var _watcher: Node
var _director: Node
var _activated: Object
var _manifest_io_failed := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _prepare():
		quit(1)
		return
	seed(SEED)
	# The runtime spawn resolver reads this process-local override. It does not
	# write a seed into a durable save, unlike modifying Game.world_seed.
	OS.set_environment("TB_WORLD_SEED", str(SEED))
	_manifest = {
		"schema_version": 1, "biome_id": "water", "scene": SCENE,
		"seed": SEED, "seed_scope": "Global RNG and process-local TB_WORLD_SEED",
		"capture_started_utc": Time.get_datetime_string_from_system(true),
		"adapter": RenderingServer.get_video_adapter_name(),
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"resolution": [root.size.x, root.size.y], "requested_actor_ids": _ids,
		"fixture_disclosure": "Fresh new-game state mounted directly into production Water; not an earned chapter arrival. One staged player stand per actor outside the unchanged prompt radius, then real movement and Interact. No route, progression or visual acceptance claim. Production dialogue may have ordinary gameplay side effects. Weather, HUD, camera, colliders and encounters remain active. Panel.close only tears down each observation; dialogue is never started directly.",
		"complete": false, "frames": _frames, "actor_results": _results, "failures": _failures,
	}
	if not _write_manifest():
		quit(1)
		return
	if not await _boot():
		_finish()
		return
	for id: String in _ids:
		await _capture_actor(id)
		await _close_panel()
		_write_manifest()
		if _manifest_io_failed:
			break
	_finish()


func _prepare() -> bool:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=").trim_suffix("/")
		elif arg.begins_with("--only="):
			for id: String in arg.trim_prefix("--only=").split(",", false):
				id = id.strip_edges()
				if not id.is_empty() and not _ids.has(id):
					_ids.append(id)
	if _ids.is_empty():
		_ids.assign(DEFAULT_IDS)
	if not _output.begins_with("res://.artifacts/phase2/") or _output.contains("..") or _output.contains("\\"):
		push_error("Choose a fresh --output=res://.artifacts/phase2/<round> directory")
		return false
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_output)):
		push_error("Refusing an existing output directory: " + _output)
		return false
	if DisplayServer.get_name() == "headless" or root.size != SIZE or DisplayServer.window_get_mode() not in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]:
		push_error("Requires actual 1920x1080 fullscreen rendering; use the documented launcher")
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAST))
	if not parsed is Dictionary:
		push_error("Missing or invalid authored Water cast")
		return false
	for group: String in ["npcs", "trainers"]:
		for raw: Dictionary in parsed.get(group, []):
			var spec := raw.duplicate(true)
			spec["source_group"] = group
			_specs[str(spec.id)] = spec
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output)) == OK


func _boot() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null or not game.has_method("reset_for_new_game"):
		_failures.append("Game/reset_for_new_game missing")
		return false
	# Normal fallback autosaves and any genuine interaction side effects may
	# run throughout this fixture. Keep both slot and split saves in a unique
	# scratch namespace BEFORE reset establishes the fresh world's identity.
	var save_dir := "user://phase2_dialogue_interaction_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	var absolute_save_dir := ProjectSettings.globalize_path(save_dir)
	if DirAccess.dir_exists_absolute(absolute_save_dir) or DirAccess.make_dir_recursive_absolute(absolute_save_dir) != OK:
		_failures.append("Could not reserve a fresh isolated capture save directory")
		return false
	game.set("save_system", SAVE_GAME.new(save_dir))
	_manifest["isolated_save_directory"] = save_dir
	_manifest["isolated_save_directory_absolute"] = absolute_save_dir
	if not _write_manifest():
		return false
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	var packed := load(SCENE) as PackedScene
	if packed == null:
		_failures.append("Production Water scene missing")
		return false
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + 900000
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			_failures.append("Production world build timed out")
			return false
		await process_frame
	await _physics(240)
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	_arbiter = get_first_node_in_group("interaction_arbiter")
	_panel = get_first_node_in_group("dialogue_panel")
	_watcher = get_first_node_in_group("conversation_camera")
	for node: Node in _world.find_children("*", "", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path == "res://scripts/combat/water_encounter_director.gd":
			_director = node
			break
	if _player == null or _rig == null or _camera == null or _arbiter == null or _panel == null or _watcher == null or _director == null:
		_failures.append("Production player, camera, dialogue, arbiter or Water director missing")
		return false
	if root.get_camera_3d() != _camera:
		_failures.append("Production CameraRig camera is not current; capture refused")
		return false
	_arbiter.connect("activated", _on_activated)
	_manifest["resolved_runtime_world_seed"] = _director.call("world_seed")
	return true


func _capture_actor(id: String) -> void:
	var failures_before := _failures.size()
	var result := {"actor_id": id, "success": false, "expected_spec": _specs.get(id, {})}
	_results.append(result)
	if not _specs.has(id):
		await _fail(result, "Unknown authored actor ID")
		return
	var spec: Dictionary = _specs[id]
	var challenge := str(spec.source_group) == "trainers"
	result["interaction_path"] = "trainer_challenge" if challenge else "npc_greeting"
	if challenge:
		result["dialogue_path_limitation"] = "WaterChallenge is a combat offer, not a greeting. Fresh state has no deployed ally; disabled/refused/combat outcomes are unsupported dialogue-path diagnostics, not camera failures."
	var actor: Node3D
	var prompt: Node3D
	if str(spec.source_group) == "trainers":
		var bodies: Dictionary = _director.get("trainer_nodes")
		var prompts: Dictionary = _director.get("trainer_prompts")
		actor = bodies.get(id) as Node3D
		prompt = prompts.get(id) as Node3D
	else:
		for node: Node in _world.find_children("*", "", true, false):
			if str(node.get_meta("water_npc_id", "")) == id:
				actor = node as Node3D
				break
		if actor != null and actor.has_method("prompt_node"):
			prompt = actor.call("prompt_node") as Node3D
	if actor == null or prompt == null:
		await _fail(result, "Authored actor or normal prompt missing")
		return
	result["expected_actor"] = _node_record(actor)
	result["expected_provider"] = _node_record(prompt)
	result["normal_prompt_radius_m"] = float(prompt.get("radius"))
	result["provider_enabled_before_approach"] = bool(prompt.get("enabled"))
	if bool(_panel.call("is_open")) or bool(_director.call("trainer_battle_active")):
		await _fail(result, "Existing dialogue or trainer battle prevents isolated observation", actor)
		return
	var route := _local_route(actor, prompt)
	result["staged_approach"] = _json(route)
	if route.is_empty():
		await _fail(result, "No sampled dry nearby ground approach; no placement changes made", actor)
		return
	# The sole staging assignment. The camera follows by its production logic.
	_player.global_position = route.start + Vector3.UP * 0.25
	_player.velocity = Vector3.ZERO
	await _physics(120)
	var start := _player.global_position
	var found := false
	for tick in 600:
		var winner: Object = _arbiter.call("winning_provider")
		if winner == prompt and _player.global_position.distance_to(start) >= 0.5:
			found = true
			break
		if bool(_panel.call("is_open")) or bool(_director.call("trainer_battle_active")):
			break
		var delta: Vector3 = route.end - _player.global_position
		delta.y = 0.0
		if delta.length() < 0.25:
			break
		_walk(delta.normalized())
		await physics_frame
	_stop_walk()
	await _physics(12)
	result["walk_displacement_m"] = _player.global_position.distance_to(start)
	result["before_interact"] = _state(actor)
	if not found or _arbiter.call("winning_provider") != prompt:
		result["provider_enabled_after_approach"] = bool(prompt.get("enabled"))
		if challenge:
			await _fail(result, "Trainer challenge did not become the winning offer in fresh state; no supported dialogue path was exercised", actor, "unsupported_dialogue_path")
		else:
			await _fail(result, "Expected prompt did not win after physical approach (occlusion, ground, input ownership or competing offer possible)", actor, "approach_failure")
		return
	if not await _frame(id, "before", actor):
		result["classification"] = "capture_failure"
		return
	# Recheck after the render await; never activate a different winner.
	if _arbiter.call("winning_provider") != prompt:
		await _fail(result, "Expected prompt changed before Interact", actor)
		return
	_activated = null
	_action("interact", 1.0)
	await _physics(1)
	_action("interact", 0.0)
	await _physics(5)
	result["activated_provider"] = _node_record(_activated)
	if challenge:
		result["observed_challenge_outcome"] = "combat" if bool(_director.call("trainer_battle_active")) else ("dialogue_open" if bool(_panel.call("is_open")) else "refused_or_no_dialogue")
		await _fail(result, "Observed actual trainer challenge outcome; this provider is not an authored greeting/dialogue path", actor, "unsupported_dialogue_path")
		return
	if not await _frame(id, "during", actor):
		result["classification"] = "capture_failure"
		return
	if _activated != prompt or not bool(_panel.call("is_open")):
		await _fail(result, "Actual Interact did not open dialogue for the expected provider; inspect actual battle/refusal state", actor, "interaction_failure")
		return
	var settled := false
	for tick in 180:
		if float(_rig.call("conversation_blend")) >= 0.999:
			settled = true
			break
		await physics_frame
	if not settled:
		await _fail(result, "Conversation blend did not complete", actor, "camera_failure")
		return
	await _physics(60)
	result["after_blend_plus_60_physics"] = _state(actor)
	if not await _frame(id, "after", actor):
		result["classification"] = "capture_failure"
		return
	if root.get_camera_3d() != _camera or not bool(_panel.call("is_open")) or _watcher.call("current_speaker") != actor or float(_rig.call("conversation_blend")) < 0.999:
		await _fail(result, "Settled dialogue lost its production camera, expected speaker, panel or completed blend", actor, "camera_failure")
		return
	result["success"] = _failures.size() == failures_before
	result["classification"] = "dialogue_observed" if bool(result.success) else "capture_failure"
	print("NORMAL INTERACTION CAPTURE %s complete (visual judgment still required)" % id)


func _local_route(actor: Node3D, prompt: Node3D) -> Dictionary:
	var radius := float(prompt.get("radius"))
	var offset := prompt.global_position - actor.global_position
	offset.y = 0.0
	# Shared Venn/Nerissa have a challenge east of their greeting. Start on the
	# prompt's side of the body so the two distinct offers remain distinguishable.
	var outward := offset.normalized() if offset.length() > 0.1 else Vector3.LEFT
	var sea := float((_world.get("config") as Dictionary).get("terrain", {}).get("sea_level_m", 0.0))
	for angle: float in [0.0, 45.0, -45.0, 90.0, -90.0, 135.0, -135.0, 180.0]:
		var direction := outward.rotated(Vector3.UP, deg_to_rad(angle))
		var start := prompt.global_position + direction * (radius + 2.0)
		var end := prompt.global_position + direction * minf(2.0, radius * 0.5)
		var previous := Vector3.INF
		var valid := true
		for sample in 17:
			var point := start.lerp(end, float(sample) / 16.0)
			point.y = float(_world.call("ground_height_at", point.x, point.z))
			if not is_finite(point.y) or point.y < sea + 0.2:
				valid = false
				break
			var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.5, point - Vector3.UP * 1.5)
			ray.exclude = [_player.get_rid()]
			var hit := _world.get_world_3d().direct_space_state.intersect_ray(ray)
			if hit.is_empty() or absf(float(hit.position.y) - point.y) > 0.35 or float(hit.normal.y) < cos(_player.floor_max_angle):
				valid = false
				break
			if previous.is_finite():
				var span := Vector2(point.x - previous.x, point.z - previous.z).length()
				if absf(point.y - previous.y) > span * tan(_player.floor_max_angle):
					valid = false
					break
			if sample == 0:
				start.y = point.y
			if sample == 16:
				end.y = point.y
			previous = point
		if valid:
			return {"start": start, "end": end, "sampled_ground_points": 17, "direction_deg": angle,
				"limitation": "Heightfield and physical floor rays screen the approach; real movement still tests capsule clearance, obstructions and winning prompt. One local approach, not exhaustive reachability proof."}
	return {}


func _walk(direction: Vector3) -> void:
	var basis: Basis = _rig.call("planar_basis")
	var relative := basis.inverse() * direction
	_action("move_left", maxf(-relative.x, 0.0))
	_action("move_right", maxf(relative.x, 0.0))
	_action("move_forward", maxf(-relative.z, 0.0))
	_action("move_back", maxf(relative.z, 0.0))


func _action(action: String, strength: float) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = strength > 0.01
	event.strength = strength
	Input.parse_input_event(event)


func _stop_walk() -> void:
	for action: String in MOVE_ACTIONS:
		_action(action, 0.0)


func _on_activated(provider: Object) -> void:
	_activated = provider


func _physics(count: int) -> void:
	for tick in count:
		await physics_frame
	# physics_frame is emitted BEFORE node physics callbacks. In particular,
	# hold Interact until the arbiter has actually processed its pressed tick.
	await process_frame


func _close_panel() -> void:
	_stop_walk()
	_action("interact", 0.0)
	if _panel != null and bool(_panel.call("is_open")):
		_panel.call("close")
	# Record normal teardown, including any gameplay side effect of closing.
	await _physics(90)
	if not _results.is_empty():
		_results[-1]["after_teardown"] = _state(null)


func _state(actor: Node3D) -> Dictionary:
	var runner: Object = _panel.call("runner")
	return {"player": _node_record(_player), "actor": _node_record(actor),
		"camera": _node_record(_camera), "rig": _node_record(_rig),
		"camera_current": root.get_camera_3d() == _camera, "camera_fov": _camera.fov,
		"arbiter_winner": _node_record(_arbiter.call("winning_provider")), "prompt": _arbiter.call("prompt"),
		"current_speaker": _node_record(_watcher.call("current_speaker")),
		"dialogue_open": _panel.call("is_open"), "dialogue_id": runner.call("conversation_id"),
		"dialogue_speaker": _panel.call("current_speaker"), "dialogue_portrait": _panel.call("current_portrait"),
		"conversation_active": _rig.call("is_in_conversation"), "blend": _rig.call("conversation_blend"),
		"shot": _json(_rig.call("conversation_shot")), "fallback": _rig.call("conversation_used_fallback"),
		"trainer_battle_active": _director.call("trainer_battle_active"), "physics_frame": Engine.get_physics_frames()}


func _node_record(value: Object) -> Dictionary:
	if not is_instance_valid(value) or not value is Node:
		return {}
	var node := value as Node
	var record := {"path": str(node.get_path()), "name": str(node.name),
		"water_npc_id": str(node.get_meta("water_npc_id", "")), "trainer_id": str(node.get_meta("trainer_id", ""))}
	if node is Node3D:
		record["transform"] = _json((node as Node3D).global_transform)
	return record


func _json(value: Variant) -> Variant:
	if value is Vector3:
		return [value.x, value.y, value.z]
	if value is Vector2:
		return [value.x, value.y]
	if value is Transform3D:
		return {"origin": _json(value.origin), "basis": [_json(value.basis.x), _json(value.basis.y), _json(value.basis.z)]}
	if value is Dictionary:
		var result := {}
		for key: Variant in value:
			result[str(key)] = _json(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value:
			result.append(_json(item))
		return result
	return value


func _frame(id: String, view: String, actor: Node3D) -> bool:
	await RenderingServer.frame_post_draw
	var state := _state(actor)
	var camera_current := root.get_camera_3d() == _camera
	# Diagnostics preserve genuine combat/refusal frames. Accepted dialogue
	# observations require the same production camera that boot verified.
	if view != "diagnostic" and not camera_current:
		_failures.append("%s %s: production CameraRig camera is not current; observation refused" % [id, view])
		return false
	var measured_view := view
	if view == "during":
		var blend := float(state.get("blend", 0.0))
		measured_view = "during_blend" if blend > 0.0 and blend < 0.999 else ("during_already_settled" if blend >= 0.999 else "during_no_blend")
	var image := root.get_texture().get_image()
	var frame_id := "%02d_%s__%s" % [_ids.find(id), id.validate_filename(), measured_view]
	var path := "%s/%s.png" % [_output, frame_id]
	if image == null or image.is_empty() or image.get_size() != SIZE or image.save_png(path) != OK:
		_failures.append("%s: native 1920x1080 frame save failed" % frame_id)
		return false
	_frames.append({"frame_id": frame_id, "identity": frame_id, "file": path,
		"actor_id": id, "view": measured_view, "requested_view": view,
		"observation_camera_verified": camera_current, "diagnostic": view == "diagnostic",
		"captured_utc": Time.get_datetime_string_from_system(true),
		"resolution": [SIZE.x, SIZE.y], "state": state})
	return _write_manifest()


func _fail(result: Dictionary, reason: String, actor: Node3D = null, classification: String = "fixture_failure") -> void:
	result["failure"] = reason
	result["classification"] = classification
	_failures.append("%s: %s" % [result.actor_id, reason])
	print("NORMAL INTERACTION FAILURE %s: %s" % [result.actor_id, reason])
	await _frame(str(result.actor_id), "diagnostic", actor)
	_write_manifest()


func _write_manifest() -> bool:
	# Keep the last complete write intact if a later write fails partway. A
	# failed final write cannot leave a truncated manifest claiming completion.
	var temporary := _output + "/manifest.json.tmp"
	var destination := _output + "/manifest.json"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		_manifest_error("Cannot open capture manifest: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(_manifest, "\t") + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		_manifest_error("Cannot store capture manifest: %s" % error_string(error))
		return false
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(destination))
	if error != OK:
		_manifest_error("Cannot publish capture manifest: %s" % error_string(error))
		return false
	return true


func _manifest_error(message: String) -> void:
	_manifest_io_failed = true
	_manifest["complete"] = false
	if not _failures.has(message):
		_failures.append(message)
	push_error(message)


func _finish() -> void:
	_stop_walk()
	_manifest["complete"] = not _manifest_io_failed and _failures.is_empty() and _results.size() == _ids.size()
	_manifest["capture_finished_utc"] = Time.get_datetime_string_from_system(true)
	var written := _write_manifest()
	print("NORMAL INTERACTION EVIDENCE %d frames, %d failures: %s" % [_frames.size(), _failures.size(), _output])
	quit(0 if written and not _manifest_io_failed and bool(_manifest.complete) else 1)
