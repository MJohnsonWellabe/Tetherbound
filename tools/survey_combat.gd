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
const CATCH := preload("res://scripts/combat/catch_math.gd")
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
	_log_phase("settle")

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
	await _drive_pal_towards_enemy(120, 2.8)
	await _press("combat_quick")
	await _capture_the_impact("05-quick-attack-lands")

	# The charged attack. It costs a full meter and roots you for half a second,
	# so it has to look heavier than a quick attack or there was no decision.
	#
	# This loop used to have no bound at all — every other wait in this file caps
	# its iteration count and records a failure on timeout; this one didn't, so a
	# charged meter that never filled (a quick attack that keeps missing, say)
	# would spin forever rather than fail loudly. 24 iterations is generous: at
	# `energy_per_quick` 26 and `charged_cost` 100, four LANDED quick attacks
	# fill the meter, and each iteration is one attempt.
	var charge_waited := 0
	while not bool(_manager.call("charged_ready")) and bool(_manager.call("is_fighting")) and charge_waited < 24:
		await _drive_pal_towards_enemy(30, 2.8)
		await _press("combat_quick")
		for j in 24:
			await physics_frame
		charge_waited += 1
		if charge_waited % 4 == 0:
			_log_phase("charging (%d/24 attempts)" % charge_waited)
	if not bool(_manager.call("charged_ready")):
		_failures.append("06-charged-attack-lands: energy never reached charged_cost after %d quick-attack attempts" % charge_waited)
	await _drive_pal_towards_enemy(60, 2.8)
	await _press("combat_charged")
	await _capture_the_impact("06-charged-attack-lands")

	# Aim mode. The camera leaves the pal and goes over the trainer's shoulder,
	# and this frame answers whether that reads as aiming at all — a reticle over
	# a creature several metres away, with your own pal standing undefended in
	# shot.
	if await _open_the_aim():
		await _capture("07-aiming-the-orb")

		# The orb in flight. It is a placeholder sphere, so this checks that a
		# small fast object stays readable against sunlit grass — the background
		# of every throw in the Meadows — and nothing about how the orb looks.
		await _press("combat_throw")
		for i in 7:
			await physics_frame
		await _capture("08-orb-in-flight")
	else:
		_failures.append("could not open the aim; no throw frames captured")



	print("")
	print("%d frames -> %s" % [_written.size(), OUT_DIR])
	print("Placeholder capsules and software rendering: composition and readability only.")
	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## Wait for the pal to finish whatever it is committed to, then open the aim and
## wait until it is actually open.
##
## Waiting on STATE rather than counting frames. A fixed wait captured the tail
## of the charged attack's recovery, during which the throw press is correctly
## ignored — so the survey came back with two frames of ordinary combat labelled
## as aiming.
func _open_the_aim() -> bool:
	for i in 240:
		if not bool(_manager.call("is_fighting")):
			return false
		if not bool(_manager.call("player_is_committed")):
			break
		await physics_frame

	await _press("combat_throw")
	for i in 240:
		if bool(_manager.call("is_aiming")):
			break
		await physics_frame
	if not bool(_manager.call("is_aiming")):
		return false

	# Let the rig arrive behind the trainer. Under software rendering the camera
	# blends on PROCESS frames, of which there are only a few per second.
	for i in 8:
		await process_frame
		_aim_at_the_enemy()
	return true


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


## Lead the target so a thrown orb would land on it. The orb flies a real arc,
## so pointing straight at the creature aims under it.
func _aim_at_the_enemy() -> void:
	var rig := _world.get_node_or_null(^"CameraRig")
	if rig == null or _wild == null:
		return
	var cfg: Dictionary = CATCH.config().get("throw", {})
	var speed := float(cfg.get("speed", 17.0))
	var gravity := float(cfg.get("gravity", 14.0))

	var origin := _player.global_position + Vector3.UP * float(cfg.get("spawn_height", 1.5))
	var to: Vector3 = (_wild.call("centre") as Vector3) - origin
	var flat := Vector2(to.x, to.z).length()
	var flight := flat / maxf(speed, 0.01)

	rig.set("yaw", atan2(-to.x, -to.z))
	rig.set("pitch", atan2(to.y + 0.5 * gravity * flight * flight, maxf(flat, 0.01)))


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


## `R9.4-remainder-6` found this survey burn ~50 minutes and write zero frames
## running concurrently with another Godot process, with no way to tell
## afterward whether that was a real hang or just the cost of software
## rendering under contention. This is the fix for "do not guess": every phase
## boundary logs how long it took, so a future stall shows exactly which wait
## it died in instead of a bare timeout.
func _log_phase(label: String) -> void:
	print("  [phase] %-18s +%.1fs" % [label, (Time.get_ticks_msec() - _start_ms) / 1000.0])


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
	print("  %-22s -> %s  (+%.1fs)" % [name, path, (Time.get_ticks_msec() - _start_ms) / 1000.0])


## Shoot the frame the blow actually lands on, not a guess at it.
##
## These two frames used to capture a fixed number of physics frames after the
## button press — 8 for the quick attack, whose wind-up alone is 0.18s, so the
## frame named "quick attack lands" was reliably taken BEFORE the hit. The blind
## critic measured 10 warm pixels of impact in it and concluded that a blow
## produces no visual event; part of what it was measuring was the survey
## photographing the wrong moment.
##
## So wait for `hit_landed`, then give the burst a few frames to open. A timing
## guess has no place in a harness whose whole job is to show what a moment
## looks like.
const IMPACT_FRAMES := 5
const IMPACT_TIMEOUT := 240


func _capture_the_impact(name: String) -> void:
	var landed := [false]
	var handler := func(_on_enemy: bool, _amount: float) -> void: landed[0] = true
	_manager.connect("hit_landed", handler)

	var waited := 0
	while not landed[0] and waited < IMPACT_TIMEOUT and bool(_manager.call("is_fighting")):
		await physics_frame
		waited += 1
	if _manager.is_connected("hit_landed", handler):
		_manager.disconnect("hit_landed", handler)

	if not landed[0]:
		_failures.append("%s: no hit landed within %d frames; the frame shows the lull, not the blow" % [
			name, IMPACT_TIMEOUT
		])

	# Let the burst open, THEN stop the clock before composing the shot.
	#
	# Both halves are needed and each was wrong on its own. A node added
	# mid-frame does not run its first `_physics_process` until the next tick, so
	# pausing immediately freezes an effect that has not drawn anything yet. And
	# without pausing, a single frame under software rendering costs an
	# appreciable fraction of a second of REAL time while physics keeps ticking,
	# so a 0.3-second effect is long dead by the time the shutter opens.
	#
	# That combination is why four separate explanations for "the impact flash is
	# invisible" — the render clock, the culling bounds, the parent node, the
	# blend mode — were all wrong. Nothing was ever wrong with the effect. The
	# camera was slower than the thing it was photographing.
	for i in IMPACT_FRAMES:
		await physics_frame
	paused = true
	await _capture(name)
	paused = false
