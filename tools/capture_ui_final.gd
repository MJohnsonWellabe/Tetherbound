extends SceneTree

## Final three suite frames + one retake, in ONE world boot (the machine is
## slow right now; a meadows boot costs minutes, so this tool never boots
## twice). Cribs the working phases from tools/capture_ui_suite.gd (READ
## FULLY before touching) but fixes the two things that pass found slow or
## broken there:
##
##   ui_catch_low / ui_catch_high  - the suite's catch phase walked the player
##     to the encounter (up to 1800 physics frames). Here the player is
##     teleported straight into the wild-creature cluster and the fight is started
##     through encounter_director's own entry point
##     (`_start_fight` -> `CombatManager.begin`), the same one-way-in
##     _on_wild_wants_to_engage() and the trainer's own interact prompt both
##     end up calling -- no walk, no interact-button press.
##
##   ui_place_invalid_retake  - the suite's original ui_place_invalid shot
##     teleported onto the steep flank and armed the ghost 15 physics frames
##     later; build_placer.gd's `_ground_height_at` can read NaN for a frame
##     or several right after a teleport (terrain streaming), which forces
##     the ghost invisible (`_ghost.visible = false`) rather than red/invalid.
##     This retake waits ~120 physics frames after the teleport, before
##     arming anything, and inspects `_ghost_ok` / ghost visibility before
##     shooting so the frame's state is known, not assumed.
##
##   ui_ally_720  - unchanged in spirit: resize, settle, shoot.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     ~/godot-bin/godot --path . --rendering-driver opengl3 \
##     --script tools/capture_ui_final.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 10

## Same steep flank tools/capture_ui_suite.gd uses (rise centred [140,-90],
## measured 62.78deg slope at the peak).
const STEEP_SPOT := Vector2(140.0, -90.0)

## Physics frames to wait after the steep-flank teleport before arming the
## ghost at all -- long enough for ground_height_at() to stop reading NaN.
const POST_TELEPORT_SETTLE_FRAMES := 120

var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _hud: CanvasLayer = null
var _field: RefCounted = null

var _written: Array[String] = []
var _failures: Array[String] = []
var _start_ms: int = 0


func _init() -> void:
	_run()


func _run() -> void:
	_start_ms = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	_world = packed.instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_log("world settled")

	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_hud = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	_field = HEIGHTFIELD.new()

	if _game == null or _player == null or _rig == null:
		_failures.append("missing Game autoload, Player or CameraRig -- cannot proceed")
		_finish()
		return

	await _phase_catch()
	await _phase_place_invalid_retake()
	await _phase_720p()

	_finish()


# --- phase 1: catch pair, teleport + direct engage --------------------------


func _phase_catch() -> void:
	print("[catch] teleporting into the wild-creature cluster...")
	var director := _world.get_node_or_null(^"EncounterDirector")
	var manager := _world.get_node_or_null(^"CombatManager")
	if director == null or manager == null:
		_failures.append("catch: no EncounterDirector or CombatManager in the world")
		return

	if director.call("ally_instance") == null:
		await director.call("adopt_starter", "terrapup")

	var cluster := _cluster_centre(director, "practice", Vector3(30.0, 0.0, -40.0))
	_player.global_position = Vector3(
		cluster.x, float(_world.call("ground_height_at", cluster.x, cluster.z)) + 1.0, cluster.z
	)
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame

	var debug_hud: CanvasLayer = _hud
	if debug_hud != null:
		debug_hud.visible = false

	var inventory: RefCounted = _game.get("inventory")
	if inventory != null:
		inventory.call("add", "orb_basic", 10)

	var wild: Node3D = director.call("wild_creature") as Node3D
	if wild == null:
		_failures.append("catch: no practice-role wild creature found near the cluster -- cannot engage")
		if debug_hud != null:
			debug_hud.visible = true
		return

	# The one way in every real engage route (player interact prompt,
	# aggressive-creature ambush) already funnels through: encounter_director's
	# own `_start_fight`, which calls CombatManager.begin() directly. No
	# walk, no interact button -- this IS the entry point, not a shortcut
	# around it.
	director.call("_start_fight", wild)
	for i in 20:
		await physics_frame

	if not bool(manager.call("is_fighting")):
		_failures.append("catch: _start_fight did not enter combat; no frames to show")
		if debug_hud != null:
			debug_hud.visible = true
		return
	print("[catch] fighting; capturing the aim-chance stills...")

	await _capture_chance_frame(manager, wild, 1.0, "ui_catch_low")
	await _capture_chance_frame(manager, wild, 0.05, "ui_catch_high")

	if bool(manager.call("is_fighting")):
		Input.action_press("combat_run")
		await physics_frame
		await physics_frame
		Input.action_release("combat_run")
		for i in 60:
			await physics_frame

	if debug_hud != null:
		debug_hud.visible = true


## Reads data/config/spawns.json through the director's own cached accessor
## (spawns_config()) rather than re-parsing the file, so this always agrees
## with whatever the director actually spawned. `role` is a spawns.json
## roles key ("practice", "aggressor"); `fallback` covers a missing/renamed
## entry so this tool degrades to a fixed spot instead of failing outright.
func _cluster_centre(director: Node, role: String, fallback: Vector3) -> Vector3:
	var cfg: Dictionary = director.call("spawns_config") as Dictionary
	var roles: Dictionary = cfg.get("roles", {}) as Dictionary
	var species := str(roles.get(role, ""))
	if species.is_empty():
		return fallback
	for raw in (cfg.get("spawns", []) as Array):
		var entry := raw as Dictionary
		if str(entry.get("species", "")) != species:
			continue
		var centre: Array = entry.get("centre", [])
		if centre.size() >= 3:
			return Vector3(float(centre[0]), float(centre[1]), float(centre[2]))
	return fallback


## Same shape as capture_ui_suite.gd::_capture_chance_frame.
func _capture_chance_frame(manager: Node, wild: Node3D, hp_fraction: float, frame_name: String) -> void:
	if not bool(manager.call("is_fighting")):
		_failures.append("%s: fight already over" % frame_name)
		return
	var inventory: RefCounted = _game.get("inventory")
	if inventory != null:
		inventory.call("add", "orb_basic", 10)
	var creature: RefCounted = manager.call("active_creature")
	if creature != null:
		creature.hp = creature.max_hp
	var foe: RefCounted = manager.call("enemy")
	foe.hp = clampf(foe.max_hp * hp_fraction, 1.0, foe.max_hp)

	if not await _open_aim(manager):
		_failures.append("%s: could not open aim" % frame_name)
		return
	for i in 15:
		await physics_frame
	_aim_at(wild)
	for i in 6:
		await physics_frame
	await _shoot(frame_name)
	Input.action_press("combat_run")
	await physics_frame
	await physics_frame
	Input.action_release("combat_run")
	for i in 20:
		await physics_frame


func _open_aim(manager: Node) -> bool:
	for i in 240:
		if not bool(manager.call("is_fighting")):
			return false
		if not bool(manager.call("player_is_committed")):
			break
		await physics_frame
	var cooldown := float(CATCH.config().get("throw", {}).get("cooldown", 0.9))
	var budget := int(ceil(cooldown * float(Engine.physics_ticks_per_second))) + 120
	while budget > 0:
		Input.action_press("combat_throw")
		await physics_frame
		await physics_frame
		Input.action_release("combat_throw")
		await physics_frame
		budget -= 4
		for i in 6:
			await physics_frame
			budget -= 1
		if bool(manager.call("is_aiming")):
			return true
	return false


func _aim_at(wild: Node3D) -> void:
	var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return
	var eye := camera.global_position
	var velocity := Vector3.ZERO
	if wild is CharacterBody3D:
		velocity = (wild as CharacterBody3D).velocity
	var release_windup := float(CATCH.config().get("throw", {}).get("release_windup", 0.18))
	var lead_time := 8.0 / float(Engine.physics_ticks_per_second) + release_windup
	var predicted: Vector3 = (wild.call("centre") as Vector3) + velocity * lead_time
	var to := predicted - eye
	_rig.set("yaw", atan2(-to.x, -to.z))
	var flat := Vector2(to.x, to.z).length()
	_rig.set("pitch", atan2(to.y, maxf(flat, 0.01)))


# --- phase 2: ui_place_invalid retake ----------------------------------------


func _phase_place_invalid_retake() -> void:
	print("[placement] retaking the invalid-slope ghost with a settle wait...")
	var placer := _world.get_node_or_null(^"BuildPlacer")
	if placer == null:
		_failures.append("ui_place_invalid_retake: no BuildPlacer in the world")
		return

	_game.set("free_build", true)
	_game.set("pending_build", "")

	_player.global_position = Vector3(
		STEEP_SPOT.x - 3.0, _field.height_at(STEEP_SPOT.x - 3.0, STEEP_SPOT.y) + 0.4, STEEP_SPOT.y
	)
	_player.velocity = Vector3.ZERO
	var to := STEEP_SPOT - Vector2(_player.global_position.x, _player.global_position.z)
	_rig.set("yaw", atan2(-to.x, -to.y))
	for i in 10:
		await physics_frame

	# The fix under test: wait for ground_height_at() to stop reading NaN
	# BEFORE arming a ghost at all, rather than the 15-frame wait the
	# original suite used.
	for i in POST_TELEPORT_SETTLE_FRAMES:
		await physics_frame

	_game.set("pending_build", "wall")
	for i in POSE_FRAMES * 3:
		await physics_frame

	var ghost_ok := bool(placer.get("_ghost_ok"))
	var ghost: Node3D = placer.get("_ghost") as Node3D
	var ghost_visible := ghost != null and is_instance_valid(ghost) and ghost.visible
	print(
		(
			"  placer state: _ghost_ok=%s  ghost=%s  ghost.visible=%s"
			% [ghost_ok, "null" if ghost == null else ghost.name, ghost_visible]
		)
	)
	if ghost_ok:
		_failures.append("ui_place_invalid_retake: ghost reads as VALID at the steep spot -- terrain not steep enough")
	if not ghost_visible:
		_failures.append(
			(
				"ui_place_invalid_retake: ghost still hidden %d frames after teleport (_ghost_ok=%s) -- capturing anyway"
				% [POST_TELEPORT_SETTLE_FRAMES, ghost_ok]
			)
		)

	await _shoot("ui_place_invalid_retake")

	_game.set("pending_build", "")
	_game.set("free_build", false)
	for i in 10:
		await physics_frame


# --- phase 3: 720p exploration frame -----------------------------------------


func _phase_720p() -> void:
	print("[720p] resizing the window for the Ally readability proxy...")
	root.size = Vector2i(1280, 720)
	for i in 3:
		await process_frame
	await _shoot("ui_ally_720")


# --- plumbing ----------------------------------------------------------------


func _log(label: String) -> void:
	print("  [phase] %-28s +%.1fs" % [label, (Time.get_ticks_msec() - _start_ms) / 1000.0])


func _shoot(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		_failures.append("%s: save_png failed (%d)" % [name, error])
		return
	_written.append(path)
	print("  %-24s -> %s  (+%.1fs)" % [name, path, (Time.get_ticks_msec() - _start_ms) / 1000.0])


func _finish() -> void:
	print("")
	print("%d/4 frames -> %s" % [_written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	if not _failures.is_empty():
		print("")
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
