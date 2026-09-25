extends SceneTree

## F11 (WO-F11-04) reload captures for a later code-blind judge.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##       --resolution 1280x720 --script tools/capture_stormwood_f11_proof.gd -- \
##       --witness-dir=user://f11_witness --out=res://ralph/reports/STORMWOOD-PROGRESS/visual/f11_proof
##
## Loads the earned witness's disk save through the real title screen's Load
## (the same `_load_slot` path a player presses), so the reopened Stormwood is
## the reloaded state, and frames it through the production CameraRig with
## ordinary look input. Disclosed instrumentation: the trainer is moved between
## vantage points (debug travel), and the Meadows home circle is reached by
## `Game.enter_realm("meadows")` rather than walking back through Cloudreach.
## Nothing here writes progression or saves.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const CORE := Vector3(-100.0, 262.21, 5470.0)

var _out := ""
var _records: Array = []
var _failures: Array[String] = []
var _game: Node
var _world: Node3D
var _rig: Node3D
var _camera: Camera3D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var witness := "user://f11_witness"
	_out = "res://ralph/reports/STORMWOOD-PROGRESS/visual/f11_proof"
	for raw: String in OS.get_cmdline_user_args():
		if raw.begins_with("--witness-dir="):
			witness = raw.substr(14)
		elif raw.begins_with("--out="):
			_out = raw.substr(6)
	if DisplayServer.get_name() == "headless":
		push_error("F11 captures need a rendering display")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	_game = root.get_node_or_null(^"Game")
	await process_frame
	_game.set("save_system", SAVE_GAME.new(witness))
	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for _i in 30:
		await process_frame
	title.set("_host_port", 0)
	title.call("_load_slot", int(_game.call("autosave_slot")))
	if not await _await_realm("Stormwood"):
		_finish()
		return
	for _i in 600:
		await physics_frame
	var ending := _world.get_node("StormwoodEnding") as Node3D
	var dynamo := _world.get_node("StormwoodDynamo") as Node3D
	var view := ending.get_node("WaterwardView") as Node3D
	var state := {"dynamo_phase": str(dynamo.get("phase")),
		"cage_visible": (ending.get("_cage") as Node3D).visible,
		"captive_visible": (ending.get("_legendary") as Node3D).visible,
		"waterward_sea_visible": (ending.get("_waterward_sea") as Node3D).visible,
		"offer_prompt_enabled": bool(ending.get_node("StormheartOffer").get("enabled")),
		"clock": _game.get("time_of_day") if "time_of_day" in _game else null}
	print("F11 CAPTURE reloaded state %s" % JSON.stringify(state))

	# 1. The resolved Dynamo core, from the loaded pose on the core ring.
	await _aim(CORE + Vector3(0.0, 2.0, -6.0))
	await _capture("01_dynamo_resolved_core", "Reloaded save: the Dynamo core after Marrow and the four conduits; containment arcs gone", state)
	# 2. The kept Stormheart beside its trainer: LB to it, then Call out.
	var summoned := await _call_out_stormheart()
	await _aim_at_ally()
	await _capture("02_stormheart_kept", "The Stormheart kept at five, called out on the core after reload", {"called_out": summoned})
	# 3. The Long Storm aftermath: the cleared sky and the Waterward sea beyond.
	var player := _world.get_node("Player") as Node3D
	await _aim(player.global_position + Vector3(0.0, -25.0, 400.0))
	await _capture("03_long_storm_aftermath_waterward", "Long Storm aftermath from the Waterward view platform after reload", {})
	await _aim(player.global_position + Vector3(-300.0, 60.0, -500.0))
	await _capture("04_long_storm_aftermath_canopy", "The quieted forest canopy below the core after reload", {})
	# 4. The Spark shrine: the Meadows home circle's Stormwood socket.
	var crossed: bool = await _game.call("enter_realm", "meadows", "")
	if not crossed or not await _await_realm(""):
		_failures.append("Meadows home circle unreachable for the Spark shrine frame")
		_finish()
		return
	for _i in 600:
		await physics_frame
	var slot := _world.get_node_or_null("MeadowsRealmHeartShrine/RelicSlot_stormwood") as Node3D
	if slot == null:
		_failures.append("no Spark socket in the Meadows home circle")
		_finish()
		return
	var body := _world.get_node("Player") as CharacterBody3D
	var toward: Vector3 = slot.global_position - (_world.get_node("MeadowsRealmHeartShrine") as Node3D).global_position
	toward.y = 0.0
	body.global_position = slot.global_position + toward.normalized() * 5.0 + Vector3.UP * 1.0
	body.velocity = Vector3.ZERO
	for _i in 120:
		await physics_frame
	await _aim(slot.global_position + Vector3.UP * 1.0)
	await _capture("05_spark_shrine", "Meadows home circle: the Spark of the Stormwood socket after reload",
		{"shrine_state": str(slot.call("current_state"))})
	_finish()


func _await_realm(name: String) -> bool:
	for _frame in 14400:
		var scene := current_scene as Node3D
		if scene != null and (scene.name == name or (name.is_empty() and scene.name != "Stormwood" \
				and scene.get_node_or_null("MeadowsRealmHeartShrine") != null)) \
				and (not scene.has_method("shell_build_complete") or bool(scene.call("shell_build_complete"))):
			_world = scene
			_rig = scene.get_node("CameraRig") as Node3D
			_camera = _rig.get_viewport().get_camera_3d()
			return true
		await physics_frame
	_failures.append("scene '%s' never became current" % name)
	return false


## Ordinary look input on the production CameraRig until it frames `target`.
func _aim(target: Vector3) -> Dictionary:
	var frames := 0
	var yaw_error := 0.0
	var pitch_error := 0.0
	while frames < 360:
		_camera = _rig.get_viewport().get_camera_3d()
		var delta := target - _camera.global_position
		var desired_yaw := atan2(-delta.x, -delta.z)
		var desired_pitch := clampf(atan2(delta.y, Vector2(delta.x, delta.z).length()), -1.2, 1.2)
		yaw_error = wrapf(desired_yaw - float(_rig.get("yaw")), -PI, PI)
		pitch_error = desired_pitch - float(_rig.get("pitch"))
		if absf(yaw_error) < deg_to_rad(2.0) and absf(pitch_error) < deg_to_rad(3.0):
			break
		var yaw_action: StringName = &"look_left" if yaw_error > 0.0 else &"look_right"
		var pitch_action: StringName = &"look_up" if pitch_error > 0.0 else &"look_down"
		if absf(yaw_error) >= deg_to_rad(2.0):
			Input.action_press(yaw_action, 0.5)
		if absf(pitch_error) >= deg_to_rad(3.0):
			Input.action_press(pitch_action, 0.5)
		await physics_frame
		Input.action_release(yaw_action)
		Input.action_release(pitch_action)
		frames += 1
	for _i in 30:
		await physics_frame
	return {"frames": frames, "yaw_error_deg": rad_to_deg(yaw_error), "pitch_error_deg": rad_to_deg(pitch_error)}


## LB (party_cycle) until the Stormheart is active, then Call out (creature_recall).
func _call_out_stormheart() -> bool:
	var party: RefCounted = _game.get("party")
	for _i in 6:
		var active: RefCounted = party.call("active")
		if active != null and str(active.get("species_id")) == "fulgocobra":
			break
		await _tap(&"party_cycle")
	var director := _world.get_node("EncounterDirector")
	if director.call("ally_instance") != null and str((director.call("ally_instance") as RefCounted).get("species_id")) != "fulgocobra":
		await _tap(&"creature_recall")
	if director.call("ally_instance") == null:
		await _tap(&"creature_recall")
	for _i in 120:
		await physics_frame
	var ally: RefCounted = director.call("ally_instance")
	return ally != null and str(ally.get("species_id")) == "fulgocobra"


func _aim_at_ally() -> void:
	var body := _world.get_node("EncounterDirector").call("ally_body") as Node3D
	if is_instance_valid(body):
		await _aim(body.global_position + Vector3.UP * 1.5)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	for _i in 3:
		await physics_frame
	Input.action_release(action)
	for _i in 20:
		await physics_frame


func _capture(id: String, caption: String, extra: Dictionary) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var path := _out.path_join(id + ".png")
	image.save_png(ProjectSettings.globalize_path(path))
	var player := _world.get_node("Player") as Node3D
	_records.append({"id": id, "path": path, "caption": caption, "extra": extra,
		"player": [player.global_position.x, player.global_position.y, player.global_position.z],
		"camera": [_camera.global_position.x, _camera.global_position.y, _camera.global_position.z],
		"camera_path": str(_camera.get_path()), "realm": str(_game.get("current_realm"))})
	print("F11 CAPTURE %s -> %s %s" % [id, path, JSON.stringify(extra)])


func _finish() -> void:
	var manifest := {"frames": _records, "failures": _failures,
		"source": "earned F11 witness save reloaded through the title screen Load",
		"camera": "production CameraRig, ordinary look input"}
	var file := FileAccess.open(_out.path_join("frames_f11.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	for line in _failures:
		print("F11 CAPTURE FAIL: " + line)
	print("F11 CAPTURE %s: %d frames" % ["OK" if _failures.is_empty() else "FAILED", _records.size()])
	quit(0 if _failures.is_empty() else 1)
