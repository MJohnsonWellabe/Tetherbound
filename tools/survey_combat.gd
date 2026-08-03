extends SceneTree

## Capture a fight in progress, for the visual critic loop.
##
##   tools/survey_combat.sh
##
## Separate from tools/survey.gd on purpose. That one has fixed viewpoints chosen
## to match panels on the key art, and every frame it produces is comparable with
## every earlier sheet. A fight cannot be shot from a fixed viewpoint — it has to
## be shot through the arena camera, which is one of the things being judged — so
## mixing them would quietly break that comparability.
##
## HONEST LIMITS, which belong in any critique made from these frames:
##   * The creatures are coloured capsules. CLAUDE.md forbids judging creature
##     appeal on placeholders and that is not what these are for. What they DO
##     support: is the arena readable, are both fighters visible and
##     distinguishable, is the trainer still in shot, do the health bars sit
##     where the eye is already looking.
##   * Software rendering under the Compatibility pipeline. Composition and
##     colour are trustworthy; lighting quality and frame times are not.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
const OUT_DIR := "res://shots/combat"

const SETTLE_FRAMES := 240
## Rendered frames between posing and the shutter.
##
## Deliberately tiny. Software rendering runs at a few frames a second, so each
## `process_frame` here can be a fifth of a second of game time — longer than the
## enemy's whole wind-up. At six, every frame of a transient beat was captured
## after the beat had passed, and the telegraph text never once appeared in a
## shot of the enemy telegraphing.
const POSE_FRAMES := 2

var _world: Node = null
var _player: CharacterBody3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null

var _written: Array[String] = []
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
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

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _manager == null or _director == null:
		push_error("scene is missing the player, the combat manager or the encounter director")
		quit(1)
		return
	_wild = _director.call("wild_pal") as Node3D

	# The M1 debug readout covers a third of the frame and is not part of what a
	# critic should be looking at. The combat HUD stays: whether the fight is
	# readable is exactly the question.
	var debug_hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if debug_hud != null:
		debug_hud.visible = false

	await _approach()
	await _capture("01-approach")

	await _press("interact")
	for i in 40:
		await physics_frame
	_ally = _director.call("ally_body") as Node3D
	await _capture("02-arena-opens")

	# Piloting the pal towards the opponent. This frame is the one that answers
	# whether the arena boundary reads, whether the camera at a creature's height
	# is legible, and whether you can tell which capsule you are driving.
	await _drive_pal_towards_enemy(90, 2.6)
	await _capture("03-closing-in")

	# The enemy's wind-up: the fight's only warning, and now something the player
	# can act on by moving. If this frame is not obviously a wind-up, the whole
	# telegraph mechanic is invisible.
	var waited := 0
	while not bool(_manager.call("enemy_is_winding_up")) and bool(_manager.call("is_fighting")) and waited < 900:
		await _drive_pal_towards_enemy(1, 2.4)
		waited += 1
	await _capture("04-enemy-winds-up")

	# A quick attack landing. Catching the impact rather than the lull is the
	# point: the frame has to show whether a hit reads as a hit.
	await _drive_pal_towards_enemy(120, 1.9)
	await _press("combat_quick")
	for i in 8:
		await physics_frame
	await _capture("05-quick-attack-lands")

	# The charged attack. It costs a full meter and roots you for half a second,
	# so it has to look heavier than a quick attack or there was no decision.
	while not bool(_manager.call("charged_ready")) and bool(_manager.call("is_fighting")):
		await _drive_pal_towards_enemy(30, 1.9)
		await _press("combat_quick")
		for j in 24:
			await physics_frame
	await _drive_pal_towards_enemy(60, 1.9)
	await _press("combat_charged")
	# Past the wind-up, onto the frame the hit lands.
	for i in 34:
		await physics_frame
	await _capture("06-charged-attack-lands")

	print("")
	print("%d frames -> %s" % [_written.size(), OUT_DIR])
	print("Placeholder capsules and software rendering: composition and readability only.")
	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _approach() -> void:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	var rig := _world.get_node_or_null(^"CameraRig")
	for i in 1200:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.55:
			break
		if rig != null:
			rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 30:
		await physics_frame


## Pilot the player's pal towards the opponent for a while, stopping once it is
## inside `stop_at` metres. Steered through the camera, which is the same path
## the player's stick takes.
func _drive_pal_towards_enemy(frames: int, stop_at: float) -> void:
	if _ally == null:
		for i in frames:
			await physics_frame
		return
	var rig := _world.get_node_or_null(^"CameraRig")
	for i in frames:
		if not bool(_manager.call("is_fighting")):
			return
		var to := _wild.global_position - _ally.global_position
		to.y = 0.0
		if rig != null:
			rig.set("yaw", atan2(-to.x, -to.z))
		if to.length() > stop_at:
			Input.action_press("move_forward")
		else:
			Input.action_release("move_forward")
		await physics_frame
	Input.action_release("move_forward")


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _capture(name: String) -> void:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % name)
		return
	_written.append(path)
	print("  %-22s -> %s" % [name, path])
