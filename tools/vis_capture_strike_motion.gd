extends "res://tools/capture_stormwood_reduced_motion.gd"

## VIS lane, F10#3 (Stormwood lightning, MOTION half): one Stormwood ground
## strike as a timed frame sequence, from the first frame of its 1.2 s warning
## through impact to ~0.5 s after, sampled every 0.1 s of GAME time (plus one
## extra frame 0.05 s after impact), with the production CameraRig/Camera3D
## following the real Player (1.80 m trainer) at the Surge strip stand, HUD
## CanvasLayers hidden, in Break.
##
##   render.yml: script=tools/vis_capture_strike_motion.gd
##     args="--motion=normal --hours=12 --out=res://shots/vis_f10_3_motion/seqA --label=seqA --only=quick"
##
## `--motion=normal|reduced` sets Settings -> Accessibility -> Reduced motion
## (motion_prefs.gd) before any staging (base tool). `--hours=H` sets the
## WorldLook clock to that exact hour and freezes it.
##
## TIMING: a software-GL render runs far below 60 fps, and without
## --fixed-fps Godot's process delta is wall time while physics is capped, so
## tweens (the ring's progress, the flash decay) would jump by seconds per
## frame. This script therefore relaunches itself once as a child Godot with
## `--fixed-fps 60` (same executable, project, renderer and window size, on
## the same X display) and waits for it: every rendered frame is then exactly
## 1/60 s of game time for process and physics alike, so frame N of the
## sequence is exactly N/60 s after the warning. The child is marked
## `--vis-child`.
##
## STAGED STRIKE (disclosed): one warning+impact pair played through the
## lightning node's own client path, StormwoodLightning._receive, with the
## same events the host publishes, aimed where the host aims (the trainer's
## position, at ground_height_near + 0.08), impact exactly 72 ticks (1.2 s)
## after the warning, `hits` empty (no damage). The host's own random strike
## schedule is pushed out (StormwoodLightning._next) so no second, natural
## strike lands in the window; the surge's distant-flash timer is pushed past
## the window and its sky/flash RNGs are seeded identically, so every
## sequence gets the same decorative sky events apart from what reduced
## motion itself changes. Presentation only; combat and damage untouched.

const SEQ_ROOT := "res://shots/vis_f10_3_motion"
const IMPACT_TICK := 72
const SAMPLE_TICKS: Array[int] = [0, 6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 75, 78, 84, 90, 96, 102]
const STRIKE_ID := 910001
const SKY_SEED := 20260927

var _vis_hours: Array[float] = [12.0]
var _ticks := 0


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--vis-child"):
		_launch_child(args)
		return
	for arg: String in args:
		if arg.begins_with("--hours="):
			_vis_hours.clear()
			for part: String in arg.trim_prefix("--hours=").split(",", false):
				_vis_hours.append(float(part))
	await super._run()


## Parent: relaunch this script under --fixed-fps 60 and mirror its exit code.
func _launch_child(args: PackedStringArray) -> void:
	var size := DisplayServer.window_get_size()
	var child_args := PackedStringArray([
		"--path", ProjectSettings.globalize_path("res://"),
		"--rendering-driver", "opengl3",
		"--resolution", "%dx%d" % [size.x, size.y],
		"--fixed-fps", "60",
		"--script", "res://tools/vis_capture_strike_motion.gd", "--"])
	child_args.append_array(args)
	child_args.append("--vis-child")
	print("VIS STRIKE launcher: %s %s" % [OS.get_executable_path(), " ".join(child_args)])
	var pid := OS.create_process(OS.get_executable_path(), child_args)
	if pid <= 0:
		push_error("VIS STRIKE launcher: create_process failed")
		quit(1)
		return
	while OS.is_process_running(pid):
		await create_timer(2.0).timeout
	var code := OS.get_process_exit_code(pid)
	print("VIS STRIKE launcher: child exit=%d" % code)
	quit(code)


func _count_tick() -> void:
	_ticks += 1


## Replaces the base `--only=quick` group: one strike sequence per hour.
func _quick() -> void:
	physics_frame.connect(_count_tick)
	if _lightning != null:
		_lightning.set("_next", 1.0e9)
		_lightning.set("_pending", [] as Array[Dictionary])
		_note("host strike schedule pushed out (StormwoodLightning._next = 1e9); only the staged strike lands")
	for hour: float in _vis_hours:
		_set_hour(hour)
		for _frame in 20:
			await physics_frame
		await _enter_phase("break", false)
		for _frame in 60:
			await physics_frame
		_hud_visible(false)
		await _sequence(hour)
	physics_frame.disconnect(_count_tick)


func _ring_progress() -> float:
	var visuals: Variant = _lightning.get("_visuals")
	if visuals is Dictionary:
		for ring: Variant in (visuals as Dictionary).values():
			if is_instance_valid(ring):
				var material := (ring as MeshInstance3D).material_override as ShaderMaterial
				if material != null:
					return float(material.get_shader_parameter("progress"))
	return -1.0


func _strike_nodes() -> Dictionary:
	var state := {"bolt": false, "light_energy": 0.0, "ring": false}
	for child: Node in _lightning.get_children():
		if child.name.begins_with("StrikeBolt") and not child.is_queued_for_deletion():
			state.bolt = true
		elif child is OmniLight3D and child.name.begins_with("StrikeLight") and not child.is_queued_for_deletion():
			state.light_energy = snappedf(maxf(float(state.light_energy), (child as OmniLight3D).light_energy), 0.01)
		elif child.name.begins_with("StrikeTelegraph") and not child.is_queued_for_deletion():
			state.ring = true
	return state


func _sequence(hour: float) -> void:
	_fine(1)
	# Same decorative sky from here on in every sequence.
	_surge.set("_flash_next", 60.0)
	_surge.set("_flash_echo", -1.0)
	(_surge.get("_sky_rng") as RandomNumberGenerator).seed = SKY_SEED
	(_surge.get("_flash_rng") as RandomNumberGenerator).seed = SKY_SEED
	_surge.set("_sky_next", 0.4)
	_note("surge distant-flash timer pushed past the window; sky/flash RNG seeded %d; _sky_next = 0.4 s" % SKY_SEED)
	var at := _player.global_position
	at.y = float(_world.call("ground_height_near", at)) + 0.08
	_note("strike staged through StormwoodLightning._receive at the trainer's position (the host's aim), impact at tick %d" % IMPACT_TICK)
	var out := "%s/%s" % [SEQ_ROOT, _label]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var seq := "%s_h%02d" % [_label, int(hour)]
	var tick0 := _ticks
	var msec0 := Time.get_ticks_msec()
	_lightning.call("_receive", {"id": STRIKE_ID + int(hour), "kind": "warning", "at": at})
	var impacted := false
	for target: int in SAMPLE_TICKS:
		while _ticks - tick0 < target:
			await physics_frame
			if not impacted and _ticks - tick0 >= IMPACT_TICK:
				_lightning.call("_receive", {"id": STRIKE_ID + int(hour), "kind": "impact", "at": at, "hits": {}})
				impacted = true
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var ticks := _ticks - tick0
		var name := "%s_t%03d" % [seq, int(round(ticks * 100.0 / 60.0))]
		var path := ProjectSettings.globalize_path("%s/%s.png" % [out, name])
		if image == null or image.is_empty() or image.save_png(path) != OK:
			_failures.append("%s: could not save frame" % name)
			continue
		var record := {"id": name, "file": name + ".png", "label": _label, "world_hour": hour,
			"motion_mode": _motion_mode, "reduced_motion": MOTION_PREFS.reduced_motion(),
			"target_tick": target, "ticks_since_warning": ticks, "t_s": snappedf(ticks / 60.0, 0.001),
			"impact_sent": impacted, "ring_progress": snappedf(_ring_progress(), 0.001),
			"strike_nodes": _strike_nodes(), "size": [image.get_width(), image.get_height()],
			"player": _vec3(_player.global_position), "camera_pos": _vec3(_camera.global_position),
			"camera_player_m": snappedf(_camera.global_position.distance_to(_player.global_position), 0.01),
			"strike_at": _vec3(at), "surge_phase": str(_surge.get("phase")),
			"presentation": _presentation_state(), "wall_ms": Time.get_ticks_msec() - msec0,
			"hud": false, "camera": "player camera (production CameraRig/Camera3D)",
			"staged": _staged.duplicate()}
		_frames.append(record)
		_log("VIS frame %s ticks=%d ring=%.3f nodes=%s flash=%s" % [name, ticks, float(record.ring_progress),
			str(record.strike_nodes), str(record.presentation.get("flash_level", -1.0))])
	for _frame in 30:
		await physics_frame
	_coarse()
