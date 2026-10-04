extends SceneTree

## F21#0/#1 in-engine frames: a real Meadows fight, driven by the ordinary
## combat actions, captured at the confirmed contact of each hit class.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/capture_f21_hit_presentation.gd -- --out=/abs/dir
##
## Shots (each at contact +2 frames, and +14 frames as the number rises):
##   quick      an ordinary quick hit (light weight)
##   charged    a charged hit (heavy weight: larger knockback, shake)
##   crit       a quick hit into a staggered foe (stagger-crit)
##   incoming   the foe's blow landing on the player's creature (own 0.85x)
##
## Disclosed shortcuts (ACCEPTANCE §6.1): the same farmhouse-exit teleport as
## `tools/capture_combat_actions.gd`; energy is primed for the charged shot;
## the crit shot breaks the foe's poise through `apply_poise_damage` instead
## of fighting for it. Every hit itself is an ordinary input press resolved by
## the shipping combat path. `receipts.json` records each receipt and frame.
##
## F21#5 matched A/B: `--sequence` saves seven frames per hit (contact -2 ..
## +24 process frames) instead of two, and `--baseline` turns the F21 impact
## layer off in memory before the world boots (weighted knockback, reaction
## recoil, damage numbers, class flash/shake styling), keeping the legacy
## hitstop and plain impact flash. Same build, seed, route and inputs, so the
## only difference between the two runs is that layer. `frame_times` records
## live drawn fight process-frame intervals (300, or 60 with `--fast`)
## before the first shot.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
const SETTLE_FRAMES := 240

var _out := ""
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _log: Array[Dictionary] = []
var _failures: Array[String] = []
var _last_impact: Dictionary = {}
var _missed := false
var _baseline := false
var _sequence := false
var _frame_times: Array[float] = []
var _timing := false
var _last_tick := 0
var _fast := false


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		elif arg == "--baseline": _baseline = true
		elif arg == "--sequence": _sequence = true
		elif arg == "--fast": _fast = true
	# In-container software GL: run with `--fixed-fps 60` so every frame is
	# 1/60 s of game time, and `--fast` so frames outside a capture or timing
	# window are simulated without being drawn.
	if _fast: RenderingServer.render_loop_enabled = false
	if _baseline: _disable_impact_layer()
	if _out.is_empty(): _out = ProjectSettings.globalize_path("res://shots/_diag/f21")
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES: await physics_frame
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director != null and director.call("ally_instance") == null:
		await director.call("adopt_starter", "terrapup")
	_leave_the_farmhouse()
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _rig == null or _manager == null or _director == null:
		_failures.append("scene is missing the player, rig, manager or director")
		_finish()
		return
	_wild = _director.call("wild_creature") as Node3D
	if _wild == null:
		_failures.append("no wild creature spawned")
		_finish()
		return
	var debug_hud := _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if debug_hud != null: debug_hud.visible = false
	_manager.connect("impact_confirmed", func(on_enemy: bool, receipt: Dictionary, where: Vector3) -> void:
		_last_impact = {"on_enemy": on_enemy, "receipt": receipt, "where": where, "frame": Engine.get_process_frames()})
	_manager.connect("attack_missed", func(by_player: bool) -> void:
		if by_player: _missed = true)
	await _walk_to_the_wild()
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 45: await physics_frame
	if not bool(_manager.call("is_fighting")):
		_failures.append("could not enter combat")
		_finish()
		return
	_wild = _manager.get("_wild") as Node3D
	# Frame time: live drawn fight frames before any PNG readback can stall one.
	RenderingServer.render_loop_enabled = true
	await process_frame
	_timing = true
	_last_tick = Time.get_ticks_usec()
	process_frame.connect(_tick_timing)
	for i in (60 if _fast else 300): await process_frame
	_timing = false
	if _fast: RenderingServer.render_loop_enabled = false

	await _strike("quick", "combat_quick")
	_prime_energy()
	await _strike("charged", "combat_charged")
	if is_instance_valid(_wild) and _wild.has_method("apply_poise_damage"):
		_wild.call("apply_poise_damage", 10000.0, true)
	await _strike("crit", "combat_quick")
	await _incoming()
	_finish()


func _tick_timing() -> void:
	if not _timing: return
	var now := Time.get_ticks_usec()
	_frame_times.append(float(now - _last_tick) / 1000.0)
	_last_tick = now


## The F21 layer off, in the cached config every reader shares. Hitstop keeps
## its pre-F21 values (COMBAT-1: quick 30 ms, charged 70 ms, crit 120 ms).
func _disable_impact_layer() -> void:
	var feedback: Dictionary = MATH.config().get("impact", {}).get("feedback", {})
	for spec: Dictionary in (feedback.get("weights", {}) as Dictionary).values():
		for key: String in ["knockback_m", "recoil_m", "recoil_up_m", "recoil_degrees"]:
			spec[key] = 0.0
	(feedback.get("numbers", {}) as Dictionary)["enabled"] = false
	for style: Dictionary in (feedback.get("flashes", {}) as Dictionary).values():
		style.erase("colour")
		for key: String in ["radius_scale", "strength_scale", "duration_scale"]:
			style[key] = 1.0
	var shake: Dictionary = feedback.get("shake_scale", {})
	for key: String in shake: shake[key] = 1.0 if key == "heavy" else 0.0
	feedback["rumble"] = {}


func _leave_the_farmhouse() -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null: return
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO


func _walk_to_the_wild() -> void:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for i in 1800:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.6: break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10: await physics_frame


func _prime_energy() -> void:
	var creature: RefCounted = _manager.call("active_creature")
	if creature != null: creature.energy = MATH.max_energy()


## Press like a player, retrying with a short step in if the swing whiffs.
func _strike(label: String, action: String) -> void:
	for attempt in 8:
		if not bool(_manager.call("is_fighting")): break
		_last_impact = {}
		_missed = false
		Input.action_press(action)
		await process_frame
		Input.action_release(action)
		for i in 150:
			if not _last_impact.is_empty() and bool(_last_impact.on_enemy): break
			if _missed: break
			await process_frame
		if not _last_impact.is_empty() and bool(_last_impact.on_enemy):
			await _capture_contact(label)
			for i in 60: await process_frame
			return
		Input.action_press("move_forward")
		for i in 18: await physics_frame
		Input.action_release("move_forward")
	_failures.append("%s: no confirmed contact after 8 presses" % label)


func _incoming() -> void:
	_last_impact = {}
	for i in 900:
		if not bool(_manager.call("is_fighting")): break
		if not _last_impact.is_empty() and not bool(_last_impact.on_enemy):
			await _capture_contact("incoming")
			return
		await process_frame
	_failures.append("incoming: the foe never landed a hit in 900 frames")


func _capture_contact(label: String) -> void:
	var row := {"shot": label, "contact_frame": int(_last_impact.frame),
		"on_enemy": bool(_last_impact.on_enemy), "receipt": _plain(_last_impact.receipt)}
	RenderingServer.render_loop_enabled = true
	if _sequence:
		# contact frame is already past; offsets are frames after it.
		var shots: Array[String] = []
		var at := 0
		for offset: int in [0, 2, 4, 6, 10, 16, 24]:
			for i in offset - at: await process_frame
			at = offset
			shots.append(await _save("%s-%02d" % [label, offset]))
		row["sequence_png"] = shots
	else:
		for i in 2: await process_frame
		row["contact_png"] = await _save("%s-contact" % label)
		for i in 12: await process_frame
		row["rise_png"] = await _save("%s-rise" % label)
	var hud := _world.get_node_or_null(^"CombatHUD")
	var texts: Array[String] = []
	if hud != null:
		for number: Label in hud.get("_damage_numbers"):
			if is_instance_valid(number): texts.append("%s@%d" % [number.text, number.get_theme_font_size("font_size")])
	row["live_numbers"] = texts
	if _fast: RenderingServer.render_loop_enabled = false
	_log.append(row)
	print("[f21] %s %s" % [label, JSON.stringify(row)])


func _plain(receipt: Dictionary) -> Dictionary:
	var out := {}
	for key: String in receipt:
		var value: Variant = receipt[key]
		out[key] = str(value) if value is Vector3 else value
	return out


func _save(name: String) -> String:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return ""
	var path := _out.path_join("%s.png" % name)
	image.save_png(path)
	return path


func _finish() -> void:
	var file := FileAccess.open(_out.path_join("receipts.json"), FileAccess.WRITE)
	if file != null:
		var sorted := _frame_times.duplicate()
		sorted.sort()
		var summary := {}
		if not sorted.is_empty():
			var total := 0.0
			for ms: float in sorted: total += ms
			summary = {"frames": sorted.size(), "mean_ms": total / sorted.size(),
				"p50_ms": sorted[sorted.size() / 2], "p95_ms": sorted[int(sorted.size() * 0.95)],
				"p99_ms": sorted[int(sorted.size() * 0.99)], "max_ms": sorted[-1]}
		file.store_string(JSON.stringify({"renderer": RenderingServer.get_current_rendering_method(),
			"baseline": _baseline, "video_adapter": RenderingServer.get_video_adapter_name(),
			"frame_time_summary": summary, "frame_times_ms": _frame_times,
			"shots": _log, "failures": _failures}, "  "))
	for failure in _failures: printerr("[f21] FAIL ", failure)
	quit(1 if not _failures.is_empty() else 0)
