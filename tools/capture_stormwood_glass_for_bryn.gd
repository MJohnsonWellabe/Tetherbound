extends "res://tools/catalogue_survey.gd"

## Player-camera evidence for Stormwood F10 WO-F10-09, "Glass for Bryn": Bryn's
## lure, the delivery request and moment, the shelter before the chain, the
## inspect step, and the shelter after it (care point and creature bed).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_stormwood_glass_for_bryn.gd -- \
##     [--out=res://ralph/reports/STORMWOOD-PROGRESS/visual/f10_bryn]
##
## Camera: the production CameraRig/Camera3D following the real Player, placed
## as tools/capture_stormwood_f09_pockets_roads.gd does. The HUD stays on.
## Dialogue opens through the real arbiter and Bryn's live greeting branches;
## the delivery goes through GlassForBryn.request_delivery() (Session ->
## encounter hub -> host commit), and the inspection through the live prompt.
##
## STAGED, and written per frame to frames.json: the day clock and a Calm Surge
## are pinned; Bryn's Act-I facts (`rodline_linked`, `bryn_met`) are set
## directly; the delivered materials are added to the satchel. The earned
## route itself is proved by `smoke_stormwood_continuous.gd --through-bryn`.

const GLASS := preload("res://scripts/world/stormwood_glass_for_bryn.gd")
const FRAME_W := 1280
const FRAME_H := 720
const SETTLE_TICKS := 90
const SETTLE_RENDERS := 10
const BANNER_MAX_TICKS := 900
const CALM_PIN_SECONDS := 60.0
const COARSE_STEPS := 20
const BRYN_XZ := Vector2(-700.0, 2300.0)

var _game: Node
var _arbiter: Node
var _surge: Node
var _glass: Node3D
var _panel: Node
var _frames: Array[Dictionary] = []
var _staged: Array[String] = []
var _t0 := 0


func _run() -> void:
	_t0 = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless":
		push_error("glass-for-bryn capture requires a rendering display; never use --headless")
		quit(1)
		return
	_biome_id = "stormwood"
	_character_id = "trainer"
	_output_dir = "res://ralph/reports/STORMWOOD-PROGRESS/visual/f10_bryn"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_output_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not await _mount_production_world() or not _prepare_capture_shell():
		_done()
		return
	_game = root.get_node(^"Game")
	_game.world.world_id = "capture-glass-for-bryn"
	_arbiter = _world.get_node_or_null(^"InteractionArbiter")
	_surge = _world.get_node_or_null(^"StormwoodSurge")
	_glass = _world.get_node_or_null(^"GlassForBryn") as Node3D
	_panel = _world.get_node_or_null(^"DialoguePanel")
	if _glass == null or _panel == null:
		_failures.append("GlassForBryn or DialoguePanel is not mounted in the production world")
		_done()
		return
	for flag: String in ["stormwood:chapter_started", "stormwood:lantern_pools_linked",
			"stormwood:rodline_linked", "stormwood:bryn_met", "stormwood:act_i_complete"]:
		_flag(flag)
	var shelter := GLASS.shelter_at()
	# The rod crews' shelter is the Rodline workshop's open bay: frame the bay
	# from about 9 m out in front of it, slightly to its right.
	var bay := Vector2(-718.6, 2309.5)
	var shelter_focus := Vector3(bay.x, _ground(bay.x, bay.y) + 0.8, bay.y)
	var shelter_stand := Vector2(-711.6, 2305.3)

	# 1. The shelter before the chain: tent and drained rod, no supplies, no bed.
	await _stand(shelter_stand, shelter_focus, -10.0)
	await _capture("01_shelter_before", "The rod crews' shelter (Rodline workshop bay) before the chain: no supplies, no bed, no prompt")

	# 2. Bryn's lure: his live greeting after meeting him is the offer.
	await _talk_to_bryn()
	await _capture("02_bryn_lure", "Bryn's offer through the live greeting branch (%s)" % _panel_id())
	await _finish_conversation()
	_log("step 1 set: %s" % str(_game.progression.has(GLASS.STEP_1)))

	# 3. The request, then the delivery moment through the host path.
	_game.inventory.add("stormglass", 4)
	_game.inventory.add("conductor_vine", 3)
	_staged.append("satchel: +4 stormglass, +3 conductor_vine")
	await _talk_to_bryn()
	await _capture("03_bryn_request", "Bryn names the exact delivery (%s)" % _panel_id(),
		{"satchel": _satchel()})
	var before := _satchel()
	await _finish_conversation()
	for _frame in 20:
		await physics_frame
	await _capture("04_delivery_moment", "Delivery committed: HUD message and the satchel change",
		{"satchel_before": before, "satchel_after": _satchel(),
			"step_2": _game.progression.has(GLASS.STEP_2)})

	# 4. The inspect step at the shelter, prompt in range.
	var inspect := _glass.get("inspect_prompt") as Node3D
	var inspect_xz := Vector2(inspect.global_position.x, inspect.global_position.z)
	var inspect_stand := inspect_xz + Vector2(1.6, 0.4)
	await _stand(inspect_stand, inspect.global_position, -16.0, 20.0)
	_arbiter.call("_recompute")
	await _capture("05_inspect_supplies", "Repaired supplies at the shelter with the live inspect prompt",
		{"supplies_visible": (_glass.get("supplies") as Node3D).visible})
	_arbiter.call("_recompute")
	var inspected := bool(_arbiter.call("activate"))
	for _frame in 20:
		await physics_frame
	_log("inspected via prompt: %s complete: %s" % [str(inspected), str(_game.progression.has(GLASS.COMPLETE))])
	if not _game.progression.has(GLASS.COMPLETE):
		_failures.append("the live inspect prompt did not complete the chain")

	# 5. The shelter after: care point and creature bed, same stand as before.
	await _stand(shelter_stand, shelter_focus, -10.0)
	await _capture("06_shelter_after", "Same stand after the chain: supplies, the shelter's creature bed and its rest prompt",
		{"care_point": _glass.get("care_point") != null})
	var care := _glass.get("care_point") as Node3D
	var bed := care.get_node_or_null(^"CampCreatureBed") as Node3D if care != null else null
	if bed != null:
		var bed_xz := Vector2(bed.global_position.x, bed.global_position.z)
		# Just inside the arch, facing the bed; the rig sits behind in the arch.
		var bed_stand := bed_xz + Vector2(0.94, -0.342) * 1.5
		await _stand(bed_stand, bed.global_position, -24.0, 0.0)
		_arbiter.call("_recompute")
		await _capture("07_bed_prompt", "The shelter's creature bed with its live Rest a Creature prompt",
			{"bed_index": int(bed.call("build_index"))})
	else:
		_failures.append("no creature bed after the chain")

	# 6. Bryn's acknowledgement.
	await _talk_to_bryn()
	await _capture("08_bryn_thanks", "Bryn's acknowledgement after completion (%s)" % _panel_id())
	await _finish_conversation()
	_done()


func _talk_to_bryn() -> void:
	var stand := BRYN_XZ + Vector2(0.0, -2.6)
	var bryn := _world.find_child("Warden-Elect Bryn", true, false) as Node3D
	var face := bryn.global_position + Vector3.UP * 1.4 if bryn != null \
		else Vector3(BRYN_XZ.x, _ground(BRYN_XZ.x, BRYN_XZ.y) + 1.4, BRYN_XZ.y)
	await _stand(stand, face, -8.0, 28.0)
	for _attempt in 3:
		_arbiter.call("_recompute")
		var label := str(_arbiter.call("prompt"))
		if label.to_lower().contains("bryn"):
			break
		# The route-07 reward shares Bryn's prompt cluster; take it first as a
		# player would.
		_arbiter.call("activate")
		for _frame in 20:
			await physics_frame
	_arbiter.call("_recompute")
	if not str(_arbiter.call("prompt")).to_lower().contains("bryn") or not bool(_arbiter.call("activate")):
		_failures.append("the arbiter did not offer Bryn (prompt '%s')" % str(_arbiter.call("prompt")))
	for _frame in 12:
		await physics_frame
	for _frame in 4:
		await process_frame


func _finish_conversation() -> void:
	for _line in 8:
		if not bool(_panel.call("is_open")):
			break
		_panel.call("advance")
		for _frame in 6:
			await physics_frame


func _panel_id() -> String:
	var runner: RefCounted = _panel.call("runner")
	return str(runner.call("conversation_id")) if runner != null and bool(_panel.call("is_open")) else "closed"


func _satchel() -> Dictionary:
	return {"stormglass": int(_game.inventory.count("stormglass")),
		"conductor_vine": int(_game.inventory.count("conductor_vine"))}


func _log(text: String) -> void:
	print("F10 BRYN CAPTURE [%6.1fs] %s" % [(Time.get_ticks_msec() - _t0) / 1000.0, text])


func _done() -> void:
	var file := FileAccess.open("%s/frames.json" % _output_dir, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"frames": _frames, "failures": _failures}, "\t") + "\n")
		file.close()
	for failure: String in _failures:
		push_error("f10 bryn capture: " + failure)
	_log("DONE %d frames, %d failures" % [_frames.size(), _failures.size()])
	quit(0 if _failures.is_empty() else 1)


func _flag(id: String) -> void:
	var flags: RefCounted = _game.get("progression")
	if not bool(flags.call("has", id)):
		_game.ledger.submit({"kind": "set_world_flag", "realm": "stormwood", "id": id, "value": true})
	if not _staged.has(id):
		_staged.append(id)


func _set_surge_elapsed(seconds: float) -> void:
	var environment: Dictionary = _game.get("realm_environment")
	var storm: Dictionary = (environment.get("stormwood", {}) as Dictionary).duplicate(true)
	storm["elapsed"] = seconds
	storm["schema_version"] = 1
	environment["stormwood"] = storm
	_game.set("realm_environment", environment)


func _day_calm() -> void:
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", false)
	_look.call("apply_time", "day")
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	_set_surge_elapsed(CALM_PIN_SECONDS)


func _ground(x: float, z: float) -> float:
	return float(_world.call("ground_height_at", x, z))


func _floor_at(x: float, z: float) -> float:
	var terrain := _ground(x, z)
	var top := terrain + 4.0
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, top - 400.0, z), 1)
	query.exclude = [_player.get_rid()]
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return float((hit.position as Vector3).y)
	return resolve_capture_ground(_player, x, z, terrain)


## Stand the real trainer at `xz` facing `look_at` and let the production rig
## settle behind them (tools/capture_stormwood_f09_pockets_roads.gd::_stand).
func _stand(xz: Vector2, look_at: Vector3, pitch_deg: float, yaw_offset_deg: float = 0.0) -> void:
	_day_calm()
	Engine.max_physics_steps_per_frame = COARSE_STEPS
	if not bool(_game.call("debug_teleport_to", xz.x, xz.y, "stormwood", "")):
		_failures.append("debug_teleport_to refused %s" % str(xz))
	for _frame in 10:
		await physics_frame
	var ground := _floor_at(xz.x, xz.y)
	var forward := Vector2(look_at.x - xz.x, look_at.z - xz.y).normalized()
	_player.global_position = Vector3(xz.x, ground + TRAINER_CLEARANCE, xz.y)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = atan2(forward.x, forward.y)
	_rig.call("set_target", _player)
	var yaw := capture_yaw(forward) + deg_to_rad(yaw_offset_deg)
	var pitch := deg_to_rad(pitch_deg)
	_rig.set("yaw", yaw)
	_rig.set("pitch", pitch)
	_rig.rotation = Vector3(pitch, yaw, 0.0)
	_rig.global_position = _player.global_position
	_camera.make_current()
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in SETTLE_TICKS:
		await physics_frame
	for _frame in SETTLE_RENDERS:
		await process_frame
	var banner := _world.find_child("RegionBanner", true, false) as CanvasItem
	var waited := 0
	while banner != null and banner.visible and waited < BANNER_MAX_TICKS:
		await physics_frame
		waited += 1
	Engine.max_physics_steps_per_frame = 8
	_set_surge_elapsed(CALM_PIN_SECONDS)
	for _frame in 2:
		await process_frame


func _capture(frame_id: String, description: String, extra: Dictionary = {}) -> void:
	for _frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_failures.append("%s: empty viewport image" % frame_id)
		return
	if image.get_width() != FRAME_W or image.get_height() != FRAME_H:
		image.resize(FRAME_W, FRAME_H, Image.INTERPOLATE_LANCZOS)
	var path := "%s/%s.jpg" % [_output_dir, frame_id]
	if image.save_jpg(ProjectSettings.globalize_path(path), 0.85) != OK:
		_failures.append("%s: save_jpg failed" % frame_id)
		return
	var record := {
		"id": frame_id, "file": path.get_file(), "description": description,
		"camera": "player camera (production CameraRig/Camera3D)",
		"player": _vec3(_player.global_position), "camera_pos": _vec3(_camera.global_position),
		"prompt": str(_arbiter.call("prompt")) if _arbiter != null else "",
		"dialogue": _panel_id(),
		"surge_phase": str(_surge.get("phase")) if _surge != null else "",
		"flags": {"step_1": _game.progression.has(GLASS.STEP_1), "step_2": _game.progression.has(GLASS.STEP_2),
			"complete": _game.progression.has(GLASS.COMPLETE)},
		"staged": _staged.duplicate(),
	}
	record.merge(extra, true)
	_frames.append(record)
	_log("captured %s prompt='%s' dialogue=%s" % [frame_id, record.prompt, record.dialogue])
