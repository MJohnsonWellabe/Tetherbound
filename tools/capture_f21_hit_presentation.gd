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


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
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

	await _strike("quick", "combat_quick")
	_prime_energy()
	await _strike("charged", "combat_charged")
	if is_instance_valid(_wild) and _wild.has_method("apply_poise_damage"):
		_wild.call("apply_poise_damage", 10000.0, true)
	await _strike("crit", "combat_quick")
	await _incoming()
	_finish()


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
	var file := FileAccess.open(_out.path_join("receipts.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"renderer": RenderingServer.get_current_rendering_method(),
			"shots": _log, "failures": _failures}, "  "))
	for failure in _failures: printerr("[f21] FAIL ", failure)
	quit(1 if not _failures.is_empty() else 0)
