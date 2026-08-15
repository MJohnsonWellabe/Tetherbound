extends SceneTree

## A recorded fight: what the animator is actually playing against what the
## body is actually doing, sampled every physics frame.
##
##   godot --headless --path . --script tools/diag_combat_animation.gd
##
## R4.11 (ralph/BACKLOG.md): the owner reported creatures "static posed and
## sliding around" in combat. `tools/diag_animation_moves.gd` already ruled
## out the two causes that look identical in game (a clip that never plays,
## or one that drives no bones) — the clips are real and move real bones.
## This is the next step the backlog item itself asks for: a real fight,
## logging the animator's resolved role against the body's velocity, so the
## gap (if any) is read off real numbers instead of guessed at again.
##
## Reuses tests/smoke_combat.gd's own setup (load the playground, adopt a
## starter, walk to the wild creature, engage) because that is already the
## proven path to a real fight; only the logging during the fight is new.

const MATH := preload("res://scripts/combat/combat_math.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"

## `AI.Intent`'s own enum values, by name — `_wild._intent` is stored as the
## int, and printing an int tells nobody which beat the creature was in.
const INTENT_NAMES := ["CLOSE", "TELEGRAPH", "RECOVER", "REPOSITION", "IDLE"]

const SETTLE_FRAMES := 240
const LOG_FRAMES := 900

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _wild: Node3D = null
var _ally: Node3D = null

## clip name -> role, inverted from each body's own `_animator._clips`, so the
## log can say "walk" instead of an opaque per-pack clip string like
## `Armature|Frog_Attack`.
var _wild_roles: Dictionary = {}
var _ally_roles: Dictionary = {}

## role -> total physics frames the body's SPEED said it should be moving
## (>= STILL_SPEED) while the animator's resolved clip was still a one-shot
## (attack/hit/faint) or idle — i.e. the body is sliding but the pose is not
## a locomotion pose. This is what "static posed and sliding around" would
## look like in the numbers.
var _anomaly_frames := 0
var _total_sample_frames := 0
var _anomaly_examples: Array[String] = []

## A single lunge/knockback frame at high speed is normal — attacks and hits
## deliberately move the body while their own pose plays. What the owner's
## report describes is a SUSTAINED freeze: many consecutive frames of real
## speed with no locomotion pose, which reads as "the model stopped
## animating." Tracked per body so a one-frame blip and an eleven-frame slide
## are not the same finding.
var _streak: Dictionary = {"ally": 0, "wild": 0}
var _longest_streak: Dictionary = {"ally": 0, "wild": 0}


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	_leave_the_farmhouse()
	if not _collect_nodes():
		quit(1)
		return

	await _walk_to_the_wild_creature()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		print("could not enter combat; nothing to log")
		quit(1)
		return

	_ally = _director.call("ally_body") as Node3D
	_wild_roles = _invert_clip_map(_wild)
	_ally_roles = _invert_clip_map(_ally)

	await _fight_and_log()
	_report()
	quit(0)


func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


func _leave_the_farmhouse() -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		return
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _manager == null or _director == null or _rig == null:
		print("scene is missing required nodes")
		return false
	_wild = _director.call("wild_creature") as Node3D
	if _wild == null or _director.call("ally_instance") == null:
		print("no wild creature or no ally creature to fight with")
		return false
	return true


func _walk_to_the_wild_creature() -> void:
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	for i in 1800:
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.6:
			break
		_aim_camera_along(to)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame


func _aim_camera_along(direction: Vector3) -> void:
	_rig.set("yaw", atan2(-direction.x, -direction.z))


func _engage() -> void:
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 30:
		await physics_frame


## `_animator._clips` is `{role: clip_name}`. Inverted so a resolved clip
## name (what `_animator._current` actually holds) can be read back as a
## role for the log.
func _invert_clip_map(body: Node3D) -> Dictionary:
	var out := {}
	if body == null:
		return out
	var animator = body.get("_animator")
	if animator == null:
		return out
	var clips: Dictionary = animator.get("_clips")
	for role in clips:
		out[str(clips[role])] = str(role)
	return out


func _role_of(body: Node3D, roles: Dictionary) -> String:
	var animator = body.get("_animator")
	if animator == null:
		return "(no animator)"
	var current := str(animator.get("_current"))
	if current == "":
		return "(none)"
	return str(roles.get(current, current))


func _is_one_shot_or_idle(role: String) -> bool:
	return role == "idle" or role == "attack" or role == "hit" or role == "faint" or role == "(none)"


## The fight loop itself is `tests/smoke_combat.gd::_fight_to_a_finish`,
## copied rather than shared — this tool needs to sample every physics frame
## between input steps, which the test's own loop does not need to do.
func _fight_and_log() -> void:
	var foe: RefCounted = _manager.call("enemy")
	var frames := 0
	print("frame,who,speed,still_speed,role,current_clip,hold,fight_intent")
	while bool(_manager.call("is_fighting")) and frames < LOG_FRAMES:
		var creature: RefCounted = _manager.call("active_creature")
		if creature != null and creature.hp_fraction() < 0.4:
			creature.hp = creature.max_hp

		var to := _wild.global_position - _ally.global_position
		to.y = 0.0
		_aim_camera_along(to)
		if to.length() > 2.0:
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("charged_ready")):
			await _press("combat_charged")
		elif bool(_manager.call("quick_ready")):
			await _press("combat_quick")
		else:
			await physics_frame
		_sample(frames)
		frames += 1
		if foe.fainted:
			break


func _sample(frame: int) -> void:
	_sample_one(frame, "ally", _ally, _ally_roles)
	_sample_one(frame, "wild", _wild, _wild_roles)


func _sample_one(frame: int, who: String, body: Node3D, roles: Dictionary) -> void:
	if body == null or not (body is CharacterBody3D):
		return
	var velocity: Vector3 = (body as CharacterBody3D).velocity
	var speed := Vector3(velocity.x, 0.0, velocity.z).length()
	var animator = body.get("_animator")
	var current := str(animator.get("_current")) if animator != null else ""
	var hold := float(animator.get("_hold")) if animator != null else -1.0
	var role := _role_of(body, roles)
	var intent := ""
	if who == "wild":
		var raw_intent = _wild.get("_intent")
		if raw_intent != null and int(raw_intent) >= 0 and int(raw_intent) < INTENT_NAMES.size():
			intent = INTENT_NAMES[int(raw_intent)]
		elif raw_intent != null:
			intent = str(raw_intent)

	_total_sample_frames += 1
	# STILL_SPEED is `creature_animator.gd`'s own threshold (0.35) — matched
	# here rather than re-derived, since a body sliding fast enough to be
	# visible but under that threshold is by definition not what this is
	# looking for.
	var still_speed := 0.35
	if speed >= still_speed and _is_one_shot_or_idle(role):
		_anomaly_frames += 1
		_streak[who] = int(_streak[who]) + 1
		_longest_streak[who] = maxi(int(_longest_streak[who]), int(_streak[who]))
		if _anomaly_examples.size() < 20:
			_anomaly_examples.append(
				"frame %d %s: speed=%.2f role=%s clip=%s hold=%.2f intent=%s" % [
					frame, who, speed, role, current, hold, intent
				]
			)
	else:
		_streak[who] = 0
	if frame % 15 == 0:
		print("%d,%s,%.2f,%.2f,%s,%s,%.2f,%s" % [
			frame, who, speed, still_speed, role, current, hold, intent
		])


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _report() -> void:
	print("")
	print("=== summary ===")
	print("sampled %d frames, %d anomalous (speed >= 0.35 while role was idle/one-shot/none)" % [
		_total_sample_frames, _anomaly_frames
	])
	if _total_sample_frames > 0:
		print("anomaly rate: %.1f%%" % (100.0 * float(_anomaly_frames) / float(_total_sample_frames)))
	# The number that actually matters: a single frame of anomaly is a lunge
	# or a knockback playing correctly against its own one-shot pose. Many
	# CONSECUTIVE anomalous frames is a creature stuck showing a pose that no
	# longer matches what its body is doing — the reported bug.
	print("longest consecutive-frame freeze-while-moving: ally=%d frames (%.2fs), wild=%d frames (%.2fs)" % [
		int(_longest_streak["ally"]), int(_longest_streak["ally"]) / 60.0,
		int(_longest_streak["wild"]), int(_longest_streak["wild"]) / 60.0,
	])
	print("")
	print("first examples:")
	for line in _anomaly_examples:
		print("  " + line)
