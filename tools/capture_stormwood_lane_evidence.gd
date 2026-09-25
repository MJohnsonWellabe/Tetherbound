extends "res://tools/catalogue_survey.gd"

## Player-camera evidence for the Stormwood lane's player-visible changes
## (Crown records, Pim's parcels, Hesk's report, dark arches, Raise a Road,
## the Stormheart offer) plus the ACCEPTANCE §4 Stormwood matrix frames.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_stormwood_lane_evidence.gd -- \
##     --out=res://ralph/reports/STORMWOOD-PROGRESS/visual/after [--label=after] \
##     [--only=crown,parcels,hesk,arch,footing,offer,matrix,surge,sky]
##
## Camera: always the production CameraRig/Camera3D following the real Player
## (never a free or survey camera). Placement is one Game.debug_teleport_to
## plus a Player transform at the stand point; the rig is given its target,
## yaw and pitch and then left to settle on its own. A dialogue frame is taken
## after the production conversation camera has pushed in.
##
## State: every progression flag, the surge clock and the day/night clock the
## tool writes is recorded per frame in `frames.json` under "staged". A frame
## with any staged entry is staged state, not earned play.
##
## The same tool runs unchanged on a checkout without the lane (for "before"
## frames): every lane node is looked up by name and its absence is recorded.

const FRAME_W := 1280
const FRAME_H := 720
const SETTLE_FRAMES := 75
const DIALOGUE_SETTLE_FRAMES := 45
const BANNER_MAX_FRAMES := 900
const CALM_PIN_SECONDS := 60.0

## Crown record seats (scripts/world/stormwood_crown_records.gd RECORDS).
## Kept as literals so the "before" checkout frames the same spots.
const CROWN_RECORDS := [
	{"id": "rain_ledger", "at": Vector2(672.0, 2732.0), "yaw": 35.0},
	{"id": "root_census", "at": Vector2(733.0, 2716.0), "yaw": -70.0},
	{"id": "reversal_mark", "at": Vector2(690.0, 2684.0), "yaw": 160.0},
]

var _label := "after"
var _only: Array[String] = []
var _game: Node
var _panel: Node
var _arbiter: Node
var _surge: Node
var _lightning: Node
var _frames: Array[Dictionary] = []
var _staged_flags: Array[String] = []
var _clock := {"time": "day", "surge_elapsed": CALM_PIN_SECONDS}
var _t0 := 0


func _run() -> void:
	_t0 = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless":
		push_error("lane evidence requires a rendering display; never use --headless")
		quit(1)
		return
	_biome_id = "stormwood"
	_character_id = "trainer"
	_output_dir = "res://ralph/reports/STORMWOOD-PROGRESS/visual/after"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_output_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
		elif arg.begins_with("--only="):
			for part: String in arg.trim_prefix("--only=").split(",", false):
				_only.append(part.strip_edges())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not await _mount_production_world() or not _prepare_capture_shell():
		_done()
		return
	_game = root.get_node(^"Game")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	_arbiter = _world.get_node_or_null(^"InteractionArbiter")
	_surge = _world.get_node_or_null(^"StormwoodSurge")
	_lightning = _world.get_node_or_null(^"StormwoodLightning")
	_log("world mounted")
	if _want("crown"):
		await _crown()
	if _want("parcels"):
		await _parcels()
	if _want("hesk"):
		await _hesk()
	if _want("arch"):
		await _arch()
	if _want("footing"):
		await _footing()
	if _want("offer"):
		await _offer()
	if _want("matrix"):
		await _matrix()
	if _want("surge"):
		await _surge_strips()
	if _want("sky"):
		await _restored_sky()
	_done()


func _want(group: String) -> bool:
	return _only.is_empty() or _only.has(group)


func _log(text: String) -> void:
	print("LANE EVIDENCE [%6.1fs] %s" % [(Time.get_ticks_msec() - _t0) / 1000.0, text])


func _done() -> void:
	var file := FileAccess.open("%s/frames_%s.json" % [_output_dir, _label], FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"label": _label, "frames": _frames,
			"failures": _failures}, "\t") + "\n")
		file.close()
	for failure: String in _failures:
		push_error("lane evidence: " + failure)
	_log("DONE %d frames, %d failures" % [_frames.size(), _failures.size()])
	quit(0 if _failures.is_empty() else 1)


# ---------------------------------------------------------------- staging

func _flag(id: String) -> void:
	var flags: RefCounted = _game.get("progression")
	if not bool(flags.call("has", id)):
		flags.call("set_flag", id, true)
	if not _staged_flags.has(id):
		_staged_flags.append(id)


func _set_surge_elapsed(seconds: float) -> void:
	var environment: Dictionary = _game.get("realm_environment")
	var storm: Dictionary = (environment.get("stormwood", {}) as Dictionary).duplicate(true)
	storm["elapsed"] = seconds
	storm["schema_version"] = 1
	environment["stormwood"] = storm
	_game.set("realm_environment", environment)


func _surge_elapsed() -> float:
	var environment: Dictionary = _game.get("realm_environment")
	return float((environment.get("stormwood", {}) as Dictionary).get("elapsed", 0.0))


func _apply_clock(time_name: String) -> void:
	_clock["time"] = time_name
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", false)
	_look.call("apply_time", time_name)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)


func _hud_visible(on: bool) -> void:
	for layer: Node in _world.find_children("*", "CanvasLayer", true, false):
		if layer == _panel:
			continue
		(layer as CanvasLayer).visible = on


# ---------------------------------------------------------------- placement

func _floor_at(x: float, z: float, from_y: float = NAN) -> float:
	var terrain := float(_world.call("ground_height_at", x, z))
	var top := (terrain + 4.0) if is_nan(from_y) else from_y
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, top - 400.0, z), 1)
	query.exclude = [_player.get_rid()]
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return float((hit.position as Vector3).y)
	return resolve_capture_ground(_player, x, z, terrain)


## Stand the real trainer at `xz`, facing `look_at`, and let the production
## rig settle behind them.
func _stand(xz: Vector2, look_at: Vector3, pitch_deg: float, from_y: float = NAN, yaw_offset_deg: float = 0.0) -> void:
	var moved := bool(_game.call("debug_teleport_to", xz.x, xz.y, "stormwood", ""))
	if not moved:
		_failures.append("debug_teleport_to refused %s" % str(xz))
	for _frame in 10:
		await physics_frame
	var ground := _floor_at(xz.x, xz.y, from_y)
	var forward := Vector2(look_at.x - xz.x, look_at.z - xz.y).normalized()
	_player.global_position = Vector3(xz.x, ground + TRAINER_CLEARANCE, xz.y)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = atan2(forward.x, forward.y)
	_rig.call("set_target", _player)
	# A close prompt view orbits the rig off the trainer's back so the trainer
	# does not hide the subject; the trainer still faces it.
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
	for _frame in SETTLE_FRAMES:
		await physics_frame
	var banner := _world.find_child("RegionBanner", true, false) as CanvasItem
	var waited := 0
	while banner != null and banner.visible and waited < BANNER_MAX_FRAMES:
		await physics_frame
		waited += 1


func _press_interact() -> void:
	Input.action_press(&"interact", 1.0)
	await physics_frame
	await physics_frame
	Input.action_release(&"interact")
	for _frame in 4:
		await physics_frame


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
	if image.save_jpg(ProjectSettings.globalize_path(path), 0.8) != OK:
		_failures.append("%s: save_jpg failed" % frame_id)
		return
	var staged := {"flags": _staged_flags.duplicate(), "clock": _clock.duplicate(),
		"placement": "debug_teleport_to + Player transform at stand point"}
	var combat := _world.get_node_or_null(^"CombatManager")
	var record := {
		"id": frame_id, "file": path.get_file(), "label": _label, "description": description,
		"camera": "player camera (production CameraRig/Camera3D)",
		"conversation_camera": _panel != null and bool(_panel.call("is_open")),
		"player": _vec3(_player.global_position), "camera_pos": _vec3(_camera.global_position),
		"camera_player_m": _camera.global_position.distance_to(_player.global_position),
		"prompt": str(_arbiter.call("prompt")) if _arbiter != null else "",
		"dialogue_open": _panel != null and bool(_panel.call("is_open")),
		"dialogue_speaker": str(_panel.call("current_speaker")) if _panel != null else "",
		"surge_phase": str(_surge.get("phase")) if _surge != null else "",
		"surge_elapsed": _surge_elapsed(),
		"time_of_day": str(_look.call("time_of_day")) if _look.has_method("time_of_day") else "",
		"in_fight": combat != null and combat.has_method("is_fighting") and bool(combat.call("is_fighting")),
		"staged": staged,
	}
	if _panel != null and bool(_panel.call("is_open")):
		var line: Dictionary = (_panel.call("runner") as RefCounted).call("line")
		record["dialogue_line"] = str(line.get("text", ""))
	record.merge(extra, true)
	_frames.append(record)
	_log("captured %s prompt='%s' dialogue=%s phase=%s" % [frame_id, record.prompt,
		str(record.dialogue_open), record.surge_phase])


func _close_dialogue() -> void:
	if _panel != null and bool(_panel.call("is_open")):
		_panel.call("close")
	for _frame in 30:
		await physics_frame


func _day_calm() -> void:
	_apply_clock("day")
	_set_surge_elapsed(CALM_PIN_SECONDS)
	_clock["surge_elapsed"] = CALM_PIN_SECONDS


# ---------------------------------------------------------------- 1. Crown

func _crown() -> void:
	_flag("stormwood:crown_reached")
	_flag("stormwood:named:crown_guardian:cleared")
	for record: Dictionary in CROWN_RECORDS:
		_day_calm()
		var seat: Vector2 = record.at
		var yaw := deg_to_rad(float(record.yaw))
		# The reading face is the seat's local -Z; the prompt hangs 0.9 m out.
		var face := Vector2(-sin(yaw), -cos(yaw))
		var seat_y := float(_world.call("ground_height_at", seat.x, seat.y))
		var focus := Vector3(seat.x, seat_y + 0.9, seat.y)
		var id := str(record.id)
		await _stand(seat + face * 13.0, focus, -10.0)
		await _capture("crown_%s_approach" % id, "Crown record %s, approach from 13 m" % id)
		await _stand(seat + face * 2.2, focus, -14.0, NAN, 28.0)
		await _capture("crown_%s_prompt" % id, "Crown record %s, close with interaction prompt" % id)
		await _press_interact()
		if _panel != null and not bool(_panel.call("is_open")) and _arbiter != null:
			_arbiter.call("activate")
		for _frame in DIALOGUE_SETTLE_FRAMES:
			await physics_frame
		await _capture("crown_%s_dialogue" % id, "Crown record %s after pressing interact" % id)
		await _close_dialogue()


# ---------------------------------------------------------------- 2. Parcels

func _npc(display_name: String, fallback: Vector3) -> Node3D:
	var people := _world.get_node_or_null(^"StormwoodPeople")
	var body := people.get_node_or_null(NodePath(display_name)) as Node3D if people != null else null
	if body == null:
		_failures.append("NPC %s not found; using authored position" % display_name)
	return body


func _parcels() -> void:
	_day_calm()
	_flag("stormwood:lantern_pools_linked")
	_flag("stormwood:side_pims_parcels_1")
	_flag("stormwood:side_pims_parcels_delivered:cook_marl")
	var marl := _npc("Marl", Vector3(-360, 31, 443))
	var at := marl.global_position if marl != null else Vector3(-360.0, 30.97, 443.0)
	# Crate stands at +1.6 x, +1.2 z of the resident; frame both from the -z side.
	var focus := at + Vector3(0.8, 0.8, 0.6)
	await _stand(Vector2(at.x + 0.2, at.z - 2.6), focus, -12.0, NAN, -22.0)
	await _capture("parcels_marl_prompt", "Marl at Ashfoot with delivered parcel crate and talk prompt")


# ---------------------------------------------------------------- 3. Hesk

func _hesk() -> void:
	_day_calm()
	_flag("stormwood:rootgate_released")
	_flag("stormwood:side_dark_arches_1")
	_flag("stormwood:side_dark_arches_2")
	var hesk := _npc("Rodkeeper Hesk", Vector3(-350, 30.3, 450))
	var at := hesk.global_position if hesk != null else Vector3(-350.0, 30.31, 450.0)
	await _stand(Vector2(at.x, at.z + 2.4), at + Vector3.UP * 1.2, -10.0, NAN, 25.0)
	await _capture("hesk_report_prompt", "Rodkeeper Hesk with talk prompt, dark-arches report owed")
	await _press_interact()
	if _panel != null and not bool(_panel.call("is_open")) and _arbiter != null:
		_arbiter.call("activate")
	for _frame in DIALOGUE_SETTLE_FRAMES:
		await physics_frame
	await _capture("hesk_report_dialogue", "Hesk conversation after pressing interact")
	await _close_dialogue()


# ---------------------------------------------------------------- 4. Arch + footing

func _arch() -> void:
	_day_calm()
	_flag("stormwood:rootgate_released")
	# c_rodline (-720, 2260), yaw 0: the Relight prompt hangs at local (0,1,-1.5).
	var arch := Vector2(-720.0, 2260.0)
	var ground := float(_world.call("ground_height_at", arch.x, arch.y))
	var focus := Vector3(arch.x, ground + 2.0, arch.y)
	await _stand(Vector2(arch.x, arch.y - 16.0), focus, -4.0)
	await _capture("arch_c_rodline_approach", "Dark Rodline Long Road Arch (pair C), approach from 16 m")
	await _stand(Vector2(arch.x, arch.y - 3.6), focus, -6.0, NAN, 20.0)
	await _capture("arch_c_rodline_prompt", "Dark Rodline Long Road Arch, close with relight/inspect prompt")


func _footing() -> void:
	_day_calm()
	_flag("stormwood:arch_recipe_known")
	# verge_road footing (-630, 800): prompt hangs at (0, 0.8, -5) from its centre.
	var centre := Vector2(-630.0, 800.0)
	var ground := float(_world.call("ground_height_at", centre.x, centre.y))
	await _stand(Vector2(centre.x, centre.y - 7.2), Vector3(centre.x, ground + 0.3, centre.y), -18.0, NAN, 20.0)
	await _capture("footing_verge_road_prompt", "Verge road arch footing with Raise-a-Road footing prompt")


# ---------------------------------------------------------------- 5. Offer

func _offer() -> void:
	_day_calm()
	_flag("stormwood:legendary_freed")
	var core := Vector3(-100.0, 262.21, 5470.0)
	var creature := core + Vector3(0.0, 3.0, 8.0)
	# Freeing plays Marrow's release conversation on its own; let it open and
	# close it so the prompt frame shows the offer prompt, not that panel.
	for _frame in 120:
		await physics_frame
	await _close_dialogue()
	await _stand(Vector2(core.x + 2.0, core.z + 22.0), creature, 4.0, core.y + 12.0, 12.0)
	await _close_dialogue()
	await _capture("stormheart_offer_prompt", "Freed Stormheart with its offer prompt")
	if _panel == null or not bool(_panel.call("start", "stormwood_stormheart_offer")):
		_failures.append("stormwood_stormheart_offer did not start")
		return
	var guard := 0
	var runner: RefCounted = _panel.call("runner")
	while guard < 12 and bool(_panel.call("is_open")):
		var line: Dictionary = runner.call("line")
		if bool(line.get("confirmation", false)) or line.has("confirm_effect"):
			break
		if bool(line.get("is_last", false)):
			break
		for _frame in 8:
			await physics_frame
		_panel.call("advance")
		guard += 1
	for _frame in DIALOGUE_SETTLE_FRAMES:
		await physics_frame
	await _capture("stormheart_offer_yes_no", "Stormheart offer conversation at its final Yes/No line",
		{"conversation_started": "DialoguePanel.start (staged; real path needs a host participant claim)"})
	await _close_dialogue()


# ---------------------------------------------------------------- 6. Matrix

func _matrix() -> void:
	# Forest: Lantern Hollow road, Deepwood.
	_day_calm()
	var forest := Vector2(-470.0, 3905.0)
	var forest_focus := Vector3(-430.0, float(_world.call("ground_height_at", -430.0, 3990.0)) + 6.0, 3990.0)
	await _stand(forest, forest_focus, -2.0)
	await _capture("matrix_forest_day", "Deepwood forest near Lantern Hollow, day")
	_apply_clock("night")
	for _frame in 20:
		await physics_frame
	await _capture("matrix_forest_night", "Deepwood forest near Lantern Hollow, night (same stand)")
	# Rod line: the Verge Rod Station pylon, from 30 m on its Ash Road side.
	_day_calm()
	var rod_node := _world.get_node_or_null(^"StormwoodRodStations/verge_rod_station") as Node3D
	var station := rod_node.global_position if rod_node != null else Vector3(-650.0, float(_world.call("ground_height_at", -650.0, 830.0)), 830.0)
	var rod_dir := Vector2(46.0, -58.0).normalized()
	var rod := Vector2(station.x, station.z) + rod_dir * 30.0
	var rod_info := {"station_node_found": rod_node != null, "station_pos": _vec3(station),
		"station_visible": rod_node != null and rod_node.is_visible_in_tree()}
	await _stand(rod, station + Vector3.UP * 5.0, 6.0)
	await _capture("matrix_rod_line_day", "Verge Rod Station pylon on the rod line, day", rod_info)
	_apply_clock("night")
	for _frame in 20:
		await physics_frame
	await _capture("matrix_rod_line_night", "Verge Rod Station pylon on the rod line, night (same stand)", rod_info)
	# Giant trunks: Fallen Giant catalogue stand.
	_day_calm()
	var giant := Vector2(-240.0, 4463.6)
	var gh := deg_to_rad(92.3)
	var giant_focus := Vector3(giant.x + sin(gh) * 80.0, float(_world.call("ground_height_at", -160.0, 4460.0)) + 14.0, giant.y + cos(gh) * 80.0)
	await _stand(giant, giant_focus, 6.0)
	await _capture("matrix_giant_trunks_day", "Fallen Giant catalogue stand facing the landmark (Deepwood trunks), day")
	# Glass scars: Glass Field stand, facing the Stormheart.
	var glass := Vector2(-310.0, 5050.0)
	var glass_focus := Vector3(-100.0, float(_world.call("ground_height_at", -310.0, 5050.0)) + 20.0, 5470.0)
	await _stand(glass, glass_focus, 2.0)
	await _capture("matrix_glass_scars_day", "Glass Field glass scars toward the Stormheart, day")
	# Giant trunk: the Stormheart from the southern road, 80 m out.
	var road := Vector2(-100.0, 5390.0)
	var trunk_focus := Vector3(-100.0, float(_world.call("ground_height_at", -100.0, 5390.0)) + 45.0, 5470.0)
	await _stand(road, trunk_focus, 14.0)
	await _capture("matrix_stormheart_trunk_day", "Stormheart giant trunk from the southern approach road, 80 m, day")


## Surge phase strips at the Verge Rod Station marked clearing (verge_glass_01),
## where Cinder Verge lightning may strike. No HUD. Six frames 5 s apart per
## phase, the surge clock running on its own between frames.
func _surge_strips() -> void:
	_apply_clock("day")
	var stand := Vector2(-604.0, 772.0)
	var focus := _station_focus()
	await _stand(stand, focus, 2.0)
	_hud_visible(false)
	var region := str(_surge.call("region_at", _player.global_position))
	var rules: RefCounted = _surge.get("rules")
	var rod_flag := str((rules.get("config").regions as Dictionary).get(region, {}).get("rod_flag", ""))
	var rod_disabled := not rod_flag.is_empty() and bool(_game.get("progression").call("has", rod_flag))
	var telegraphed := false
	for phase: String in ["calm", "building", "break", "fading"]:
		var start := _phase_start(rules, phase, region, rod_disabled, false)
		_set_surge_elapsed(start + 2.0)
		_clock["surge_elapsed"] = "pinned to %s start + 2 s, then free-running" % phase
		for _frame in 30:
			await physics_frame
		for index in 6:
			var target := start + 3.0 + index * 5.0
			while _surge_elapsed() < target:
				await physics_frame
				if phase == "break" and not telegraphed and _ring_visible():
					telegraphed = true
					await _capture("surge_break_telegraph", "Lightning telegraph ring during Break, no HUD",
						{"hud": false, "region": region})
			_heal()
			await _capture("surge_%s_%02d" % [phase, index + 1],
				"%s phase, t+%d s into phase, no HUD" % [phase.capitalize(), int(target - start)],
				{"hud": false, "region": region, "phase_offset_s": target - start})
	if not telegraphed:
		_log("no natural strike telegraph during Break strip")
	_hud_visible(true)


func _station_focus() -> Vector3:
	var node := _world.get_node_or_null(^"StormwoodRodStations/verge_rod_station") as Node3D
	var at := node.global_position if node != null else Vector3(-650.0, float(_world.call("ground_height_at", -650.0, 830.0)), 830.0)
	return at + Vector3.UP * 6.0


func _ring_visible() -> bool:
	if _lightning == null:
		return false
	var visuals: Variant = _lightning.get("_visuals")
	return visuals is Dictionary and not (visuals as Dictionary).is_empty()


func _heal() -> void:
	var vitals: Variant = _player.get("vitals")
	if vitals is RefCounted and float(vitals.get("health")) < float(vitals.get("max_health")):
		vitals.set("health", float(vitals.get("max_health")))
		if not _staged_flags.has("(player health restored between Break frames)"):
			_staged_flags.append("(player health restored between Break frames)")


func _phase_start(rules: RefCounted, phase: String, region: String, rod_disabled: bool, aftermath: bool) -> float:
	var t := 0.0
	while t < 4000.0:
		var row: Dictionary = rules.call("phase_at", t, region, rod_disabled, aftermath)
		if str(row.get("phase", "")) == phase:
			return t
		t += 1.0
	return 0.0


## Post-Long-Storm: the aftermath cycle (2400 s calm) at the same rod-line
## stand and the same forest stand, day, no HUD for comparison with Calm.
func _restored_sky() -> void:
	_flag("stormwood:long_storm_ended")
	_apply_clock("day")
	_set_surge_elapsed(CALM_PIN_SECONDS)
	_clock["surge_elapsed"] = CALM_PIN_SECONDS
	var stand := Vector2(-604.0, 772.0)
	var focus := _station_focus()
	await _stand(stand, focus, 12.0)
	await _capture("sky_restored_rod_line_day", "After the Long Storm (aftermath cycle), rod-line stand, camera raised to the sky")
	var forest := Vector2(-470.0, 3905.0)
	var forest_focus := Vector3(-430.0, float(_world.call("ground_height_at", -430.0, 3990.0)) + 6.0, 3990.0)
	await _stand(forest, forest_focus, 12.0)
	await _capture("sky_restored_forest_day", "After the Long Storm (aftermath cycle), Deepwood forest stand, camera raised")
