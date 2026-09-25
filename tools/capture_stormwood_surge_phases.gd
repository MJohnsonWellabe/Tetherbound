extends "res://tools/catalogue_survey.gd"

## Player-camera evidence for Stormwood Surge phase readability (ACCEPTANCE
## §6.1 F10 / S2): Calm, Building, Break and Fading must be nameable from the
## normal camera without HUD phase text, and the Long Storm aftermath must
## read as a restored sky.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_stormwood_surge_phases.gd -- \
##     --out=res://ralph/reports/STORMWOOD-PROGRESS/visual/surge/after \
##     [--label=after] [--only=strips,night,motion,aftermath | --only=views | --only=quick] \
##     [--motion-out=/abs/scratch/dir] [--motion-phases=calm,break] \
##     [--strip-phases=break,fading] [--coarse-steps=30]
##
## Groups: strips (6 frames 5 s apart per phase, 640x360, plus a full-size
## Break telegraph and flash), night (one frame per phase at the night
## preset), motion (62 frames 0.5 s apart per phase to a
## scratch dir for a contact sheet; delete afterwards), aftermath (the
## Long Storm aftermath at the strip, rod-line and Deepwood stands). Explicit
## only: views (rod-line pylon and Deepwood matrix stands in Calm, Break and
## aftermath Calm) and quick (one settled frame per phase, for tuning).
##
## Camera: the production CameraRig/Camera3D following the real Player (never
## a free or survey camera), placed by one Game.debug_teleport_to plus a
## Player transform at the stand point; the rig settles on its own.
##
## Stand: the Cinder Verge marked clearing verge_glass_01 beside the Verge Rod
## Station, the same stand as tools/capture_stormwood_lane_evidence.gd's Surge
## strips, so these frames compare directly with that tool's.
##
## State: the day clock is pinned to "day"; the surge clock is pinned to
## `<phase start> + 2 s` and then runs on its own. When the build under test
## exposes `settle_presentation()` the tool calls it after the pin so frame 1
## is not mid cross-fade from the phase the pin jumped away from; this is
## recorded per frame. The aftermath/views groups set
## `stormwood:long_storm_ended`. HUD CanvasLayers are hidden for every frame.
## Player health is restored between Break frames. Engine
## max_physics_steps_per_frame is raised (--coarse-steps) so game time keeps
## pace under software GL; ticks stay 1/60 s. Everything staged is written to
## frames_<label>.json.
##
## The same tool runs on a checkout without this lane's presentation (for
## "before" frames): every newer hook is looked up with has_method/get.

const STRIP_W := 640
const STRIP_H := 360
const STAND := Vector2(-604.0, 772.0)
const PHASES := ["calm", "building", "break", "fading"]

var _label := "after"
var _only: Array[String] = []
var _motion_out := ""
var _motion_phases: Array[String] = []
var _strip_phases: Array[String] = []
var _coarse_steps := 30
var _game: Node
var _surge: Node
var _lightning: Node
var _frames: Array[Dictionary] = []
var _staged: Array[String] = []
var _t0 := 0


func _run() -> void:
	_t0 = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless":
		push_error("surge capture requires a rendering display; never use --headless")
		quit(1)
		return
	_biome_id = "stormwood"
	_character_id = "trainer"
	_output_dir = "res://ralph/reports/STORMWOOD-PROGRESS/visual/surge/after"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_output_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
		elif arg.begins_with("--only="):
			for part: String in arg.trim_prefix("--only=").split(",", false):
				_only.append(part.strip_edges())
		elif arg.begins_with("--motion-out="):
			_motion_out = arg.trim_prefix("--motion-out=")
		elif arg.begins_with("--strip-phases="):
			for part: String in arg.trim_prefix("--strip-phases=").split(",", false):
				_strip_phases.append(part.strip_edges())
		elif arg.begins_with("--coarse-steps="):
			_coarse_steps = int(arg.trim_prefix("--coarse-steps="))
		elif arg.begins_with("--motion-phases="):
			for part: String in arg.trim_prefix("--motion-phases=").split(",", false):
				_motion_phases.append(part.strip_edges())
	if _motion_phases.is_empty():
		_motion_phases.assign(PHASES)
	if _strip_phases.is_empty():
		_strip_phases.assign(PHASES)
	# Software GL renders this world at well under 1 fps, and Godot advances
	# game time by at most max_physics_steps_per_frame physics ticks per
	# rendered frame, so the default 8 turns 25 s of Surge into ~10 minutes.
	# Coarse waits take bigger (still fixed 1/60 s) ticks per frame; the
	# telegraph and flash captures drop back to fine steps (see _fine()).
	_coarse()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not await _mount_production_world() or not _prepare_capture_shell():
		_done()
		return
	_game = root.get_node(^"Game")
	_surge = _world.get_node_or_null(^"StormwoodSurge")
	_lightning = _world.get_node_or_null(^"StormwoodLightning")
	if _surge == null:
		_failures.append("StormwoodSurge node missing")
		_done()
		return
	_log("world mounted")
	_pin_day()
	await _stand(STAND, _station_focus(), 2.0)
	_hud_visible(false)
	if _only.has("quick"):
		await _quick()
	if _want("strips"):
		await _strips()
	if _want("motion"):
		await _motion()
	if _want("night"):
		await _night()
	if _only.has("views"):
		await _views(false)
	# Last: the aftermath flag cannot be unset within one run.
	if _want("aftermath"):
		await _aftermath()
	if _only.has("views"):
		await _views(true)
	_done()


func _want(group: String) -> bool:
	return (_only.is_empty() and group != "quick") or _only.has(group)


func _log(text: String) -> void:
	print("SURGE CAPTURE [%6.1fs] %s" % [(Time.get_ticks_msec() - _t0) / 1000.0, text])


func _done() -> void:
	var file := FileAccess.open("%s/frames_%s.json" % [_output_dir, _label], FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"label": _label, "frames": _frames,
			"failures": _failures}, "\t") + "\n")
		file.close()
	for failure: String in _failures:
		push_error("surge capture: " + failure)
	_log("DONE %d frames, %d failures" % [_frames.size(), _failures.size()])
	quit(0 if _failures.is_empty() else 1)


# ---------------------------------------------------------------- staging

func _pin_day() -> void:
	_pin_clock("day")


func _pin_clock(time_name: String) -> void:
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", false)
	_look.call("apply_time", time_name)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	_note("%s clock pinned (WorldLook.apply_time('%s') + set_clock_frozen)" % [time_name, time_name])


func _coarse() -> void:
	Engine.max_physics_steps_per_frame = _coarse_steps


func _fine(steps: int = 1) -> void:
	Engine.max_physics_steps_per_frame = steps


func _note(text: String) -> void:
	if not _staged.has(text):
		_staged.append(text)


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


func _hud_visible(on: bool) -> void:
	for layer: Node in _world.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = on
	for layer: Node in _surge.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = on


func _heal() -> void:
	var vitals: Variant = _player.get("vitals")
	if vitals is RefCounted and float(vitals.get("health")) < float(vitals.get("max_health")):
		vitals.set("health", float(vitals.get("max_health")))
		_note("player health restored between Break frames")


func _region() -> String:
	return str(_surge.call("region_at", _player.global_position))


func _rod_disabled(region: String) -> bool:
	var rules: RefCounted = _surge.get("rules")
	var rod_flag := str((rules.get("config").regions as Dictionary).get(region, {}).get("rod_flag", ""))
	return not rod_flag.is_empty() and bool(_game.get("progression").call("has", rod_flag))


func _phase_start(phase: String, aftermath: bool) -> float:
	var rules: RefCounted = _surge.get("rules")
	var region := _region()
	var disabled := _rod_disabled(region)
	var t := 0.0
	while t < 6000.0:
		var row: Dictionary = rules.call("phase_at", t, region, disabled, aftermath)
		if str(row.get("phase", "")) == phase:
			return t
		t += 1.0
	return 0.0


## Pin the surge clock into `phase` and let the surge node notice it.
func _enter_phase(phase: String, aftermath: bool) -> float:
	var start := _phase_start(phase, aftermath)
	_set_surge_elapsed(start + 2.0)
	# Process frames, not physics ticks: the surge node reads its phase in
	# _process, and one rendered frame can hold 30 ticks here.
	for _frame in 3:
		await process_frame
	if _surge.has_method("settle_presentation"):
		_surge.call("settle_presentation")
		_note("settle_presentation() after each surge-clock pin (skips the cross-fade the pin would start)")
	for _frame in 24:
		await physics_frame
	return start


# ---------------------------------------------------------------- placement

func _floor_at(x: float, z: float) -> float:
	var terrain := float(_world.call("ground_height_at", x, z))
	var top := terrain + 4.0
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, top - 400.0, z), 1)
	query.exclude = [_player.get_rid()]
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return float((hit.position as Vector3).y)
	return resolve_capture_ground(_player, x, z, terrain)


func _stand(xz: Vector2, look_at: Vector3, pitch_deg: float) -> void:
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
	var yaw := capture_yaw(forward)
	var pitch := deg_to_rad(pitch_deg)
	_rig.set("yaw", yaw)
	_rig.set("pitch", pitch)
	_rig.rotation = Vector3(pitch, yaw, 0.0)
	_rig.global_position = _player.global_position
	_camera.make_current()
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in 75:
		await physics_frame
	var banner := _world.find_child("RegionBanner", true, false) as CanvasItem
	var waited := 0
	while banner != null and banner.visible and waited < 900:
		await physics_frame
		waited += 1
	_hud_visible(false)


func _station_focus() -> Vector3:
	var node := _world.get_node_or_null(^"StormwoodRodStations/verge_rod_station") as Node3D
	var at := node.global_position if node != null else Vector3(-650.0, float(_world.call("ground_height_at", -650.0, 830.0)), 830.0)
	return at + Vector3.UP * 6.0


# ---------------------------------------------------------------- capture

func _grab() -> Image:
	for _frame in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _save(image: Image, path: String, width: int, height: int) -> bool:
	if image == null or image.is_empty():
		_failures.append("%s: empty viewport image" % path)
		return false
	if image.get_width() != width or image.get_height() != height:
		image.resize(width, height, Image.INTERPOLATE_BILINEAR)
	var absolute := path if path.begins_with("/") else ProjectSettings.globalize_path(path)
	if image.save_jpg(absolute, 0.78) != OK:
		_failures.append("%s: save_jpg failed" % path)
		return false
	return true


func _presentation_state() -> Dictionary:
	var state := {}
	var rain: Variant = _surge.get("_rain")
	if rain is GPUParticles3D:
		state["rain_visible"] = (rain as GPUParticles3D).is_visible_in_tree()
		state["rain_emitting"] = (rain as GPUParticles3D).emitting
		state["rain_amount_ratio"] = (rain as GPUParticles3D).amount_ratio
	if _surge.has_method("flash_level"):
		state["flash_level"] = float(_surge.call("flash_level"))
	if _surge.has_method("presentation_key"):
		state["presentation_key"] = str(_surge.call("presentation_key"))
	return state


func _capture(frame_id: String, description: String, full_size: bool, extra: Dictionary = {}) -> void:
	var image := await _grab()
	var width := FRAME_W_FULL if full_size else STRIP_W
	var height := FRAME_H_FULL if full_size else STRIP_H
	if not _save(image, "%s/%s.jpg" % [_output_dir, frame_id], width, height):
		return
	var record := {
		"id": frame_id, "file": frame_id + ".jpg", "label": _label, "description": description,
		"size": [width, height],
		"camera": "player camera (production CameraRig/Camera3D)", "hud": false,
		"player": _vec3(_player.global_position), "camera_pos": _vec3(_camera.global_position),
		"region": _region(),
		"surge_phase": str(_surge.get("phase")), "surge_elapsed": _surge_elapsed(),
		"time_of_day": str(_look.call("time_of_day")) if _look.has_method("time_of_day") else "",
		"long_storm_ended": bool(_game.get("progression").call("has", "stormwood:long_storm_ended")),
		"presentation": _presentation_state(),
		"staged": _staged.duplicate(),
	}
	record.merge(extra, true)
	_frames.append(record)
	_log("captured %s phase=%s %s" % [frame_id, record.surge_phase, str(record.presentation)])


const FRAME_W_FULL := 1280
const FRAME_H_FULL := 720


func _ring_visible() -> bool:
	if _lightning == null:
		return false
	var visuals: Variant = _lightning.get("_visuals")
	return visuals is Dictionary and not (visuals as Dictionary).is_empty()


# ---------------------------------------------------------------- groups

## Six frames 5 s apart per phase, the surge clock free-running between them.
## During Break the first visible strike telegraph and the first bright flash
## (when the build has one) are captured full size on their own.
func _strips() -> void:
	for phase: String in PHASES:
		if not _strip_phases.has(phase):
			continue
		var start: float = await _enter_phase(phase, false)
		for index in 6:
			var target := start + 3.0 + index * 5.0
			while _surge_elapsed() < target:
				await physics_frame
			_heal()
			await _capture("surge_%s_%02d" % [phase, index + 1],
				"%s, t+%d s into the phase" % [phase.capitalize(), int(target - start)], false,
				{"phase_offset_s": target - start})
		if phase == "break":
			await _break_events(start)


## After the Break strip, still in Break: wait (at 8 ticks per frame, then
## single ticks once seen) for the first strike telegraph ring and, when the
## build has one, the first bright flash, and capture each full size.
func _break_events(start: float) -> void:
	var limit := start + 100.0
	_fine(8)
	while not _ring_visible() and _surge_elapsed() < limit:
		await physics_frame
	_fine(1)
	if _ring_visible():
		_heal()
		await _capture("surge_break_telegraph", "Break: lightning ground telegraph ring (1.2 s, 3 m) at the marked clearing", true)
	else:
		_frames.append({"id": "surge_break_telegraph", "missing": "no strike telegraph within 100 s of Break"})
	if _surge.has_method("flash_level"):
		_fine(8)
		while float(_surge.call("flash_level")) < 0.5 and _surge_elapsed() < limit:
			await physics_frame
		_fine(1)
		if float(_surge.call("flash_level")) > 0.0:
			await _capture("surge_break_flash", "Break: white-violet lightning flash (distant or strike) in progress", true)
		else:
			_frames.append({"id": "surge_break_flash", "missing": "no flash within 100 s of Break"})
	else:
		_frames.append({"id": "surge_break_flash", "missing": "this build has no flash hook (before)"})
	_coarse()


## One frame per phase at the strip stand with the clock pinned to art.json's
## `night` preset (hour 23), then back to day.
func _night() -> void:
	_pin_clock("night")
	for phase: String in PHASES:
		await _enter_phase(phase, false)
		for _frame in 20:
			await physics_frame
		_heal()
		await _capture("night_%s" % phase, "%s at night (art.json night preset, hour 23)" % phase.capitalize(), false)
	_pin_day()


## Tuning pass only (--only=quick): one settled frame per phase.
func _quick() -> void:
	for phase: String in PHASES:
		await _enter_phase(phase, false)
		await _capture("quick_%s" % phase, "%s, settled (tuning)" % phase.capitalize(), false)


## ≥30 s per phase at 2 fps, 640x360, to a scratch directory outside the repo;
## a contact sheet is built from it afterwards and the frames deleted.
func _motion() -> void:
	if _motion_out.is_empty():
		_log("motion skipped: no --motion-out")
		return
	DirAccess.make_dir_recursive_absolute(_motion_out)
	for phase: String in _motion_phases:
		var start: float = await _enter_phase(phase, false)
		var times: Array[float] = []
		var index := 0
		while index < 62:
			var target := start + 3.0 + index * 0.5
			while _surge_elapsed() < target:
				await physics_frame
			_heal()
			await RenderingServer.frame_post_draw
			times.append(snappedf(_surge_elapsed() - start, 0.01))
			_save(root.get_texture().get_image(), "%s/%s_%s_%03d.jpg" % [_motion_out, _label, phase, index], STRIP_W, STRIP_H)
			index += 1
		_frames.append({"id": "motion_%s" % phase, "phase": phase, "frames": index,
			"phase_offset_s": times, "presentation": _presentation_state(), "staged": _staged.duplicate()})
		_log("motion %s done: %s" % [phase, str(times.slice(0, 6))])


## Matrix views (explicit --only=views): the rod line (Verge Rod Station
## pylon from 30 m on its Ash Road side, the lane tool's matrix_rod_line
## stand) and the Deepwood forest stand, in storm Calm and Break, then again
## in the aftermath Calm once the flag is set.
func _views(aftermath: bool) -> void:
	if aftermath:
		var flags: RefCounted = _game.get("progression")
		if not bool(flags.call("has", "stormwood:long_storm_ended")):
			flags.call("set_flag", "stormwood:long_storm_ended", true)
		_note("flag stormwood:long_storm_ended set (aftermath)")
	var rod_node := _world.get_node_or_null(^"StormwoodRodStations/verge_rod_station") as Node3D
	var station := rod_node.global_position if rod_node != null else Vector3(-650.0, float(_world.call("ground_height_at", -650.0, 830.0)), 830.0)
	var rod := Vector2(station.x, station.z) + Vector2(46.0, -58.0).normalized() * 30.0
	var forest := Vector2(-470.0, 3905.0)
	var forest_focus := Vector3(-430.0, float(_world.call("ground_height_at", -430.0, 3990.0)) + 6.0, 3990.0)
	var stands := [
		{"id": "rod_line", "at": rod, "focus": station + Vector3.UP * 5.0, "pitch": 6.0, "text": "Verge Rod Station pylon (rod line), 30 m"},
		{"id": "forest", "at": forest, "focus": forest_focus, "pitch": 4.0, "text": "Deepwood forest near Lantern Hollow"},
	]
	var phases: Array = ["calm"] if aftermath else ["calm", "break"]
	for stand: Dictionary in stands:
		await _stand(stand.at, stand.focus, float(stand.pitch))
		for phase: String in phases:
			await _enter_phase(phase, aftermath)
			var id := "view_%s_%s%s" % [stand.id, "aftermath_" if aftermath else "", phase]
			await _capture(id, "%s, %s%s" % [stand.text, "aftermath " if aftermath else "", phase.capitalize()], true,
				{"station_node_found": rod_node != null})


## After the Long Storm: the aftermath cycle's Calm and Break at the strip
## stand, plus the rod-line and Deepwood stands with the camera raised to the
## sky, for the "restored sky" matrix row.
func _aftermath() -> void:
	var flags: RefCounted = _game.get("progression")
	if not bool(flags.call("has", "stormwood:long_storm_ended")):
		flags.call("set_flag", "stormwood:long_storm_ended", true)
	_note("flag stormwood:long_storm_ended set (aftermath)")
	await _stand(STAND, _station_focus(), 2.0)
	await _enter_phase("calm", true)
	await _capture("aftermath_calm_strip_stand", "Aftermath Calm at the strip stand (same framing as the Calm strip)", false)
	await _stand(STAND, _station_focus(), 12.0)
	await _capture("aftermath_calm_rod_line_sky", "Aftermath Calm, rod-line stand, camera raised to the sky", true)
	var forest := Vector2(-470.0, 3905.0)
	var forest_focus := Vector3(-430.0, float(_world.call("ground_height_at", -430.0, 3990.0)) + 6.0, 3990.0)
	await _stand(forest, forest_focus, 12.0)
	await _enter_phase("calm", true)
	await _capture("aftermath_calm_forest_sky", "Aftermath Calm, Deepwood forest stand, camera raised", true)
	await _stand(STAND, _station_focus(), 2.0)
	await _enter_phase("break", true)
	await _capture("aftermath_break_strip_stand", "Aftermath Break (rare, 45 s) at the strip stand", false)
