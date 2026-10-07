extends SceneTree

## F21#0/#1 in-engine frames: a real Meadows fight, driven by the ordinary
## combat actions, captured at the confirmed contact of each hit class.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/capture_f21_hit_presentation.gd -- --out=/abs/dir
## Optional --medium requires a native Forward+ run and selects authored Medium
## before world loading. Its frame timings include screenshot readback/write
## stalls; this capture alone supplies neither a matched before nor an FPS pass.
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

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
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
var _medium := false
var _frame_samples: Array[Dictionary] = []
var _frame_sampler := Callable()
var _entry: Dictionary = {}


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		if arg == "--medium": _medium = true
	if _out.is_empty(): _out = ProjectSettings.globalize_path("res://shots/_diag/f21")
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(_out)
	if _medium:
		if DisplayServer.get_name() == "headless" or RenderingServer.get_current_rendering_method() != "forward_plus" \
				or GRAPHICS.choose("Medium") != OK or GRAPHICS.selected() != "Medium" or GRAPHICS.restart_required():
			_failures.append("--medium requires a native Forward+ renderer and the actual authored Medium preset before world load")
			_finish()
			return
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
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
	if _medium:
		var clock := {"last_usec":Time.get_ticks_usec(),"last_frame":Engine.get_process_frames(),"was_fighting":false}
		_frame_sampler = func() -> void:
			var now: int = Time.get_ticks_usec()
			var fighting: bool = is_instance_valid(_manager) and bool(_manager.call("is_fighting"))
			# Include every whole process-frame wall interval begun in combat,
			# including its exit boundary and any intervening PNG readback/write.
			if bool(clock.was_fighting):
				_frame_samples.append({"from_process_frame":int(clock.last_frame),"process_frame":Engine.get_process_frames(),
					"wall_end_usec":now,"wall_dt_ms":float(now-int(clock.last_usec))/1000.0,"fighting_at_end":fighting})
			clock.last_usec = now
			clock.last_frame = Engine.get_process_frames()
			clock.was_fighting = fighting
		process_frame.connect(_frame_sampler)
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
	if not await _walk_to_the_wild():
		_failures.append("ordinary Engage entry preconditions not ready after walk")
		_finish()
		return
	# Match the working combat-camera smoke's physical X delivery across both
	# input clocks. Action state alone bypasses the ordinary controller event.
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = JOY_BUTTON_X
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = JOY_BUTTON_X
	up.pressed = false
	Input.parse_input_event(up)
	for i in 45: await physics_frame
	if not bool(_manager.call("is_fighting")):
		_failures.append("could not enter combat")
		_finish()
		return
	_wild = _manager.get("_wild") as Node3D

	await _strike("quick", "combat_quick")
	_prime_energy()
	await _strike("charged", "combat_charged")
	if is_instance_valid(_wild) and _wild.has_method("apply_poise_damage"):
		_wild.call("apply_poise_damage", 10000.0, true)
	await _strike("crit", "combat_quick")
	await _incoming()
	# Observe the process-frame boundary after the final PNG write as well.
	if _medium: await process_frame
	_finish()


func _leave_the_farmhouse() -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null: return
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO


func _walk_to_the_wild() -> bool:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	var arbiter := get_first_node_in_group("interaction_arbiter")
	if arbiter == null: return false
	for i in 1800:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		# A nearby harvest/NPC can win even inside engage range. Walk until the
		# published provider AND its actual target agree, without forcing either.
		if to.length() <= engage_range * 0.6 and arbiter.call("winning_provider") == _director \
				and _director.call("_engageable") == _wild: break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10: await physics_frame
	var winner := arbiter.call("winning_provider") as Node
	var candidate := _director.call("_engageable") as Node
	var owner := preload("res://scripts/ui/input_owner.gd").current(self)
	var canonical: Dictionary = _director.call("_canonical_wild_start_state", _wild)
	_entry = {"winner": str(winner.get_path()) if winner != null else "",
		"target": str(candidate.get_path()) if candidate != null else "",
		"selected": str(_wild.get_path()), "input_owner": str(owner.get_path()) if owner != null else "",
		"canonical_enabled": canonical.get("enabled", false), "canonical_ready": canonical.get("ready", false),
		"distance": _player.global_position.distance_to(_wild.global_position)}
	print("[f21] entry ", JSON.stringify(_entry))
	return owner == null and winner == _director and candidate == _wild \
		and (not bool(canonical.get("enabled", false)) or bool(canonical.get("ready", false)))


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
	if _frame_sampler.is_valid() and process_frame.is_connected(_frame_sampler):
		process_frame.disconnect(_frame_sampler)
	var sorted: Array[float] = []
	for sample: Dictionary in _frame_samples: sorted.append(float(sample.wall_dt_ms))
	sorted.sort()
	var performance := {"sampling_requested":_medium,"sample_count":sorted.size(),
		"metric":"process-frame wall milliseconds; intervals begin while is_fighting is true; exit boundary included",
		"includes_screenshot_readback_and_png_write_stalls":true,"percentile_method":"nearest rank",
		"p50_ms":null,"p95_ms":null,"p99_ms":null,"raw_active_fight_frames":_frame_samples}
	if not sorted.is_empty():
		for percentile: int in [50,95,99]:
			performance["p%d_ms" % percentile] = sorted[clampi(ceili(float(sorted.size())*float(percentile)/100.0)-1,0,sorted.size()-1)]
	elif _medium:
		_failures.append("Medium capture observed no active-fight process-frame wall intervals")
	var resolution: Vector2 = root.get_visible_rect().size
	var file := FileAccess.open(_out.path_join("receipts.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"renderer": RenderingServer.get_current_rendering_method(),
			"preset":GRAPHICS.selected(),"requested_preset":"Medium" if _medium else "unchanged",
			"resolution":[int(resolution.x),int(resolution.y)],"performance":performance,
			"entry": _entry, "shots": _log, "failures": _failures}, "  "))
	for failure in _failures: printerr("[f21] FAIL ", failure)
	quit(1 if not _failures.is_empty() else 0)
