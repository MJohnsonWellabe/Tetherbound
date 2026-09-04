extends SpringArm3D

## Third-person orbit camera.
##
## A SpringArm3D so terrain intrusion is handled by the engine rather than by
## hand-written raycasts, which is the kind of thing the previous prototype
## reimplemented badly. The arm shortens instantly when something gets between
## the camera and the player, and eases back out, because the reverse reads as
## the camera lunging at your back.
##
## Yaw lives here rather than on the player: the player turns to face travel,
## and the camera turns to face where the player is looking. Coupling them makes
## the character spin when you look around while standing still.

const CONFIG_PATH := "res://data/config/movement.json"

## The conversation push-in (D73 §6 / CL-G10). It resolves who is being talked
## to and solves the framing; the blend, the arm and the occlusion probe stay
## here, because they are this rig's own state.
const CONVERSATION := preload("res://scripts/player/conversation_camera.gd")

## `dialogue_panel.gd` and `tab_map.gd`-style callers find the rig through this
## rather than through a NodePath, because the rig is a sibling of the world's
## UI layers and every scene spells that path differently.
const GROUP := "camera_rig"

var yaw: float = 0.0
var pitch: float = 0.0

var _distance: float = 5.2
var _height: float = 1.75
var _pitch_min: float = -60.0
var _pitch_max: float = 32.0
var _gamepad_sensitivity: float = 190.0
var _mouse_sensitivity: float = 0.16
var _deadzone: float = 0.18
var _invert_y: bool = false
var _follow_lag: float = 14.0
var _recover_speed: float = 4.0

## How far the arm stops short of whatever it hit. SpringArm3D's own property;
## kept here as a named default so it is data-driven like the rest of the rig
## instead of a bare number sitting in the .tscn.
##
## The scene shipped this at 0.3, which is standoff-from-the-hit-surface, not
## standoff-from-the-player. A tree trunk directly behind the player (the
## `trees`/`grove`/`rocks` vegetation layers collide, `scripts/world/vegetation.gd`
## `_add_collision()`, radius up to 1.1m) can leave the arm barely longer than
## the trunk's own radius, and the render is a close-up of whatever the arm
## stopped against filling the frame — the same failure this file's own header
## already names happening to the combat camera against a bush, now hit by the
## exploration camera against the denser Meadows scatter. Raising the margin
## does not stop the collapse; it stops the collapse from reading as the
## camera being INSIDE the obstruction.
var _collision_margin: float = 0.6

## Radius of the ball the arm sweeps along itself, in metres.
##
## SpringArm3D only shape-casts if it has been given a `shape`. Nothing ever
## assigned one — not the .tscn, not this file — so the arm fell back to its
## default single, infinitely thin raycast down the centre line, and a
## third-person camera indoors behaved exactly the way that implies. It slipped
## between a chair back and a table edge and then drew the camera inside them,
## and when the one ray did hit something nearer than `margin` the arm collapsed
## to about zero length and put the camera inside the player's head. Both were
## reported by the same blind playtest as one symptom ("the camera collapses
## into the character indoors"), and neither is reachable by tuning distance or
## margin, because a ray that misses reports no hit at all.
##
## Small on purpose: the ball is a stand-in for the camera's near plane, not for
## the player. Too large and the arm shortens for doorframes it would have fitted
## through. TUNABLE.
var _probe_radius: float = 0.25

var _target: Node3D = null
var _mouse_delta := Vector2.ZERO

## Defaults from movement.json, kept so a combat profile can be handed back.
var _base_distance: float = 5.2
var _base_height: float = 1.75
var _base_pitch_min: float = -60.0
var _base_pitch_max: float = 32.0

## Profile-scoped look tuning. catching.json's aim profile carried
## `sensitivity_scale: 0.55` and pitch bounds from the day it was written, and
## nothing read them — aim mode ran at the full 190 deg/s exploration turn
## rate, which is most of what "aiming is fiddly on the stick" was. A profile
## may now scale sensitivity, bend the stick response (exponent > 1 gives a
## fine-aim centre without costing full-deflection speed), and narrow pitch.
var _sensitivity_scale: float = 1.0
var _response_exponent: float = 1.0

## An extra, per-frame scale pushed in by whoever owns the current aim (the
## throw slows the stick further when the reticle is near the target). Reset
## to 1.0 by every set_target.
var _assist_scale: float = 1.0

## The target assist is for the last, careful part of lining up a throw. It
## must not reduce a fully-deflected stick: a close creature can circle the
## trainer faster than the assisted turn rate, leaving the reticle permanently
## behind it even though the player is holding the stick all the way over.
## Blend the assist away across the outer part of the stick so fine aim keeps
## its slowdown and deliberate tracking keeps the profile's full turn speed.
const ASSIST_FULL_SPEED_START := 0.55
const ASSIST_FULL_SPEED_END := 0.92

## While a fight is running the rig follows the player's creature instead of the
## trainer, at a shorter creature's height. Combat is piloted (D07), and a
## piloted creature wants exactly this camera — so it is re-pointed rather than
## replaced by a second one that would have to be kept in sync.
var _retarget_lag: float = 0.0

## The camera hanging off the end of the arm. A combat profile narrows its lens:
## the exploration 70 is right for looking at a landscape and wrong for looking
## at two creatures four metres away.
@onready var _camera: Camera3D = get_node_or_null(^"Camera3D") as Camera3D
var _base_fov: float = 70.0

## Over-the-shoulder offset, in metres, applied to the ARM's pivot rather than
## to the camera hanging off it.
##
## The obvious implementation — sliding the child Camera3D sideways — silently
## does nothing. SpringArm3D rewrites its children's transforms every frame to
## place them at the end of the arm, so the offset was wiped before it was ever
## drawn, and combat spent a whole survey with the camera dead behind the creature
## while the config confidently said 1.5.
var _shoulder: float = 0.0


## --- the conversation push-in ------------------------------------------------
##
## While a conversation is on screen the rig stops orbiting the player and
## blends to a two-shot on the speaker (`conversation_camera.gd` solves it).
## Look input is ignored for the duration: the shot is the composition, and a
## player who nudges the stick while reading should not end up looking at a
## hedge.
##
## The pose the rig had before the push-in is saved here and blended back to on
## close, rather than recomputed — the exploration yaw is a player-authored
## value and guessing it back is how a camera "snaps somewhere else" every time
## you finish talking to somebody.
var _talk_speaker: Node3D = null
var _talk_cfg: Dictionary = {}
var _talk_shot: Dictionary = {}
var _talk_active: bool = false
var _talk_leaving: bool = false
var _talk_blend_time: float = 0.45
## 0 is the exploration orbit, 1 is the two-shot. Moves toward whichever end the
## current state wants, so a conversation reopened mid-exit picks up where the
## blend had got to instead of jumping.
var _talk_blend: float = 0.0
var _talk_saved_yaw: float = 0.0
var _talk_saved_pitch: float = 0.0
var _talk_saved_distance: float = 5.2
var _talk_saved_fov: float = 70.0
var _talk_used_fallback: bool = false
## Mirror of the arm's exclusion list while a conversation is up — see
## `_exclude_conversation_bodies()`.
var _talk_excluded: Array[RID] = []

## How far the camera may stand from the framing pivot before world geometry is
## in the way, in metres. Replaced by tests with a fixture that describes a wall
## analytically: `tests/run_tests.gd` has no live SceneTree, so it has no physics
## space to put a real wall in, and a fallback that only ever ran indoors in a
## booted scene would be covered by nothing that runs on every push.
var _occlusion_probe: Callable = Callable()


func _ready() -> void:
	_load_config()
	top_level = true          # the arm follows the player by code, not by parenting
	spring_length = _distance
	margin = _collision_margin
	# Set here rather than in the .tscn for the same reason `margin` is: the rig
	# is configured from movement.json in one place, and the scene carrying half
	# the values is how `collision_margin` sat in the config being ignored.
	if shape == null:
		var probe := SphereShape3D.new()
		probe.radius = _probe_radius
		shape = probe
	pitch = deg_to_rad(clampf(pitch, _pitch_min, _pitch_max))
	add_to_group(GROUP)
	# The push-in's watcher, created here rather than placed in the two scenes
	# that carry a rig, so a rig instanced anywhere — a capture fixture, a test —
	# has one without anybody remembering to add a node. It is a plain `Node`:
	# SpringArm3D rewrites the transform of every Node3D child every frame to put
	# it at the end of the arm, so a Node3D helper would be dragged around the
	# world by the very camera it is advising.
	if get_node_or_null(^"ConversationCamera") == null:
		var watcher: Node = CONVERSATION.new()
		watcher.name = "ConversationCamera"
		add_child(watcher)


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("movement.json missing; camera using built-in defaults")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var cfg: Dictionary = (parsed as Dictionary).get("camera", {})
	_distance = float(cfg.get("distance", _distance))
	_height = float(cfg.get("height", _height))
	_pitch_min = float(cfg.get("pitch_min_deg", _pitch_min))
	_pitch_max = float(cfg.get("pitch_max_deg", _pitch_max))
	_base_pitch_min = _pitch_min
	_base_pitch_max = _pitch_max
	pitch = float(cfg.get("pitch_start_deg", -12.0))
	_gamepad_sensitivity = float(cfg.get("gamepad_sensitivity", _gamepad_sensitivity))
	_mouse_sensitivity = float(cfg.get("mouse_sensitivity", _mouse_sensitivity))
	_deadzone = float(cfg.get("stick_deadzone", _deadzone))
	_invert_y = bool(cfg.get("invert_y", false))
	_follow_lag = float(cfg.get("follow_lag", _follow_lag))
	_recover_speed = float(cfg.get("collision_recover_speed", _recover_speed))
	_collision_margin = float(cfg.get("collision_margin", _collision_margin))
	_probe_radius = float(cfg.get("collision_probe_radius", _probe_radius))
	_base_distance = _distance
	_base_height = _height
	if _camera != null:
		_base_fov = _camera.fov


## Follow a new target, optionally with an override profile.
##
## An empty profile restores the exploration defaults, which is how combat hands
## the camera back. The first call has no previous target and snaps; later calls
## ease, because a fight opening with a hard cut loses the connection between
## "the animal I walked up to" and "the animal I am fighting".
func set_target(target: Node3D, profile: Dictionary = {}) -> void:
	# A fight, a mount or a thrown orb taking the camera outranks a conversation
	# push-in that is still blending: whoever calls this is about to overwrite
	# every value the push-in is interpolating, and a half-finished blend left
	# running on top of it drags the new shot back toward a villager's chest.
	if _talk_active or _talk_leaving:
		_abandon_conversation()
	var had_target := _target != null
	_target = target

	_distance = float(profile.get("distance", _base_distance))
	_height = float(profile.get("height", _base_height))
	_retarget_lag = float(profile.get("retarget_lag", 0.0))
	_shoulder = float(profile.get("shoulder_offset", 0.0))
	_sensitivity_scale = float(profile.get("sensitivity_scale", 1.0))
	_response_exponent = maxf(float(profile.get("response_exponent", 1.0)), 0.1)
	_pitch_min = float(profile.get("pitch_min_deg", _base_pitch_min))
	_pitch_max = float(profile.get("pitch_max_deg", _base_pitch_max))
	_assist_scale = 1.0
	if _camera != null:
		_camera.fov = float(profile.get("fov", _base_fov))
	if profile.has("pitch_start_deg"):
		pitch = clampf(deg_to_rad(float(profile["pitch_start_deg"])),
			deg_to_rad(_pitch_min), deg_to_rad(_pitch_max))

	# The arm has to ignore whatever it is following.
	#
	# SpringArm3D excludes its own parent automatically, and this rig is
	# `top_level` so it has no parent to exclude. Following the player's creature put
	# the arm's origin inside that creature's capsule, the arm collided with it
	# on the first cast and collapsed to nothing, and the whole fight was played
	# from a camera buried in the back of your own creature.
	clear_excluded_objects()
	if target is CollisionObject3D:
		add_excluded_object((target as CollisionObject3D).get_rid())

	if target != null and not had_target:
		CONVERSATION.set_world_position(
			self, CONVERSATION.world_position(target) + Vector3.UP * _height)
		spring_length = _distance


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta += (event as InputEventMouseMotion).relative


func _process(delta: float) -> void:
	# The freed check matters now that the rig can follow a thrown orb through
	# the catch resolution: the orb is freed with the fight, and a rig holding
	# the stale reference would crash on the next frame's follow.
	if _target == null or not is_instance_valid(_target):
		_target = null
		return
	if _talk_active or _talk_leaving:
		# Look input is ignored for the duration, and the accumulated mouse
		# motion is DROPPED rather than kept: a mouse moved across a whole
		# conversation would otherwise be replayed as one flick the frame the
		# box closes.
		_mouse_delta = Vector2.ZERO
		_conversation_follow(delta)
		return
	_apply_look(delta)
	_follow(delta)


## CONTROLLER-MAP: R3 (or Home) swings the camera back behind whatever it is
## following. Written as a snap rather than a glide because the verb the owner
## authored is "recentre", and a camera that takes half a second to arrive
## reads as drift rather than as a button doing something. Pitch is left alone:
## the complaint a recentre answers is "I am looking at the back of my own
## head", which is a yaw problem.
##
## `_target.global_basis.z` is the direction the followed body faces; the rig
## sits BEHIND it, so the yaw that puts the camera at its back is that vector's
## own heading. A target with no meaningful facing (a spinning creature body
## mid-attack) still gets a defined answer, which is better than refusing.
func _recentre_behind_target() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var forward := -_target.global_transform.basis.z
	if Vector2(forward.x, forward.z).length() < 0.001:
		return
	yaw = wrapf(atan2(-forward.x, -forward.z), -PI, PI)
	rotation = Vector3(pitch, yaw, 0.0)


func _apply_look(delta: float) -> void:
	if Input.is_action_just_pressed(&"camera_recenter"):
		_recentre_behind_target()

	# Gamepad, in degrees per second so sensitivity is frame-rate independent.
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick.length() < _deadzone:
		stick = Vector2.ZERO
	elif _response_exponent != 1.0:
		# Bend the response so small deflections move slowly and full
		# deflection keeps its speed — a fine-aim centre for the throw camera.
		stick = stick.normalized() * pow(stick.length(), _response_exponent)
	var turn := _gamepad_sensitivity * _sensitivity_scale \
		* aim_assist_scale(stick.length(), _assist_scale)
	var yaw_change := -stick.x * turn * delta
	var pitch_change := -stick.y * turn * delta

	# Mouse, in degrees per pixel. Not scaled by delta: the motion event already
	# describes distance moved, and multiplying it by frame time makes fast
	# frames turn less than slow ones for the same physical movement.
	yaw_change += -_mouse_delta.x * _mouse_sensitivity
	pitch_change += -_mouse_delta.y * _mouse_sensitivity
	_mouse_delta = Vector2.ZERO

	if _invert_y:
		pitch_change = -pitch_change

	yaw = wrapf(yaw + deg_to_rad(yaw_change), -PI, PI)
	pitch = clampf(pitch + deg_to_rad(pitch_change), deg_to_rad(_pitch_min), deg_to_rad(_pitch_max))
	rotation = Vector3(pitch, yaw, 0.0)


func _follow(delta: float) -> void:
	var desired := _target.global_position + Vector3.UP * _height
	if not is_zero_approx(_shoulder):
		# Sideways relative to where the camera is looking, so the offset stays
		# on the same shoulder as you turn.
		desired += Basis(Vector3.UP, yaw).x * _shoulder
	# Exponential smoothing written frame-rate independently. A raw lerp by
	# `lag * delta` changes behaviour with frame rate, which shows up as the
	# camera feeling different on the handheld than on the desktop.
	#
	# `retarget_lag` slows the follow while a fight is opening or closing, so the
	# swap between trainer and creature is a glide rather than a snap.
	var lag := _retarget_lag if _retarget_lag > 0.0 else _follow_lag
	var weight := 1.0 - exp(-lag * delta)
	global_position = global_position.lerp(desired, weight)

	# Once the rig has arrived, hand pacing back to the normal follow lag —
	# otherwise the whole fight is played through a camera that lags behind
	# every dodge.
	if _retarget_lag > 0.0 and global_position.distance_to(desired) < 0.3:
		_retarget_lag = 0.0

	# The spring arm collapses instantly on intrusion (SpringArm3D's own
	# behaviour) and is eased back out here, so leaving cover is smooth.
	spring_length = move_toward(spring_length, _distance, _recover_speed * delta)


## --- the conversation push-in -----------------------------------------------

## Blend to the two-shot on `speaker`. Returns false, and leaves the camera
## exactly where it was, when there is nothing worth pushing in on.
##
## Called from `scripts/ui/dialogue_panel.gd` by way of
## `conversation_camera.gd::begin()` — one call in, one call out, so there is a
## single place that knows a conversation moves the camera at all.
func enter_conversation(speaker: Node3D, cfg: Dictionary) -> bool:
	if speaker == null or not is_instance_valid(speaker):
		return false
	if _target == null or not is_instance_valid(_target):
		return false
	if _talk_active:
		return false

	var anchor := CONVERSATION.speaker_anchor(speaker, cfg)
	# A conversation opened from across a field is not the shot this is for —
	# the road gate calls its lock message from wherever you are standing, and a
	# 3.5m two-shot on a person 20m away frames a patch of grass between you.
	if CONVERSATION.world_position(_target).distance_to(anchor) \
			> float(cfg.get("max_speaker_distance", 9.0)):
		return false

	# Only save the exploration pose on a genuine entry. Re-entering while the
	# exit blend is still running (two villagers in one press, the stronghold's
	# back-to-back beats) must keep the ORIGINAL saved pose, or the second
	# conversation blends back to the two-shot the first one left behind.
	if not _talk_leaving:
		_talk_saved_yaw = yaw
		_talk_saved_pitch = pitch
		_talk_saved_distance = _distance
		_talk_saved_fov = _camera.fov if _camera != null else _base_fov
		_talk_blend = 0.0

	_talk_speaker = speaker
	_talk_cfg = cfg
	_talk_blend_time = maxf(float(cfg.get("blend_time", 0.45)), 0.01)
	_talk_active = true
	_talk_leaving = false
	_exclude_conversation_bodies()
	_talk_shot = _solve_conversation_shot()
	return true


## Blend back to the pose the rig had before the push-in. Safe when nothing
## pushed in.
func exit_conversation() -> void:
	if not _talk_active:
		return
	_talk_active = false
	_talk_leaving = true


func is_in_conversation() -> bool:
	return _talk_active


## True when the two-shot did not fit and the closer over-shoulder was used
## instead. Read by `tests/test_conversation_camera.gd`; nothing in the game
## branches on it.
func conversation_used_fallback() -> bool:
	return _talk_used_fallback


## How far the push-in has got: 0 is the exploration orbit, 1 is the two-shot.
## Read by `tests/test_conversation_camera.gd` to step the blend to its end
## rather than guessing a frame count.
func conversation_blend() -> float:
	return _talk_blend


## The shot currently being blended toward, in `conversation_camera.gd::solve`'s
## own terms. For tests and for the capture tool.
func conversation_shot() -> Dictionary:
	return _talk_shot.duplicate()


## Test seam. `probe.call(pivot, dir, limit) -> float` answers "how many metres
## of clear space are there from `pivot` along `dir`", the same question the
## physics query below answers.
func set_occlusion_probe_for_tests(probe: Callable) -> void:
	_occlusion_probe = probe


## Drop the push-in immediately, with no blend, and put back everything it
## changed. Used when something with a better claim takes the camera.
func _abandon_conversation() -> void:
	_talk_active = false
	_talk_leaving = false
	_talk_blend = 0.0
	_talk_speaker = null
	_talk_shot = {}
	_talk_used_fallback = false
	_talk_excluded.clear()
	yaw = _talk_saved_yaw
	pitch = _talk_saved_pitch
	rotation = Vector3(pitch, yaw, 0.0)
	spring_length = _talk_saved_distance
	if _camera != null:
		_camera.fov = _talk_saved_fov


## Drive the blend, in either direction. Called instead of `_apply_look` and
## `_follow`, never alongside them.
func _conversation_follow(delta: float) -> void:
	if _talk_active:
		# Re-solved every frame rather than once on open: the speaker turns to
		# face you as you arrive (`npc_body.gd` TURN_SPEED), the player is still
		# settling on the ground, and a shot frozen on the opening frame drifts
		# visibly off both of them during the fade.
		var solved := _solve_conversation_shot()
		if not solved.is_empty():
			_talk_shot = solved

	var wanted := 1.0 if _talk_active else 0.0
	_talk_blend = move_toward(_talk_blend, wanted, delta / _talk_blend_time)
	var weight := smoothstep(0.0, 1.0, _talk_blend)

	# The far end of the blend is the exploration orbit as it would be RIGHT
	# NOW, not as it was when the conversation opened. The player can be shoved
	# by a creature mid-sentence, and blending back to a stale point would walk
	# the camera to where they used to be.
	var explore_pivot := CONVERSATION.world_position(_target) + Vector3.UP * _height
	var pivot: Vector3 = _talk_shot.get("pivot", explore_pivot)
	var shot_yaw: float = float(_talk_shot.get("yaw", _talk_saved_yaw))
	var shot_pitch: float = float(_talk_shot.get("pitch", _talk_saved_pitch))
	var shot_distance: float = float(_talk_shot.get("distance", _talk_saved_distance))
	var shot_fov: float = float(_talk_shot.get("fov", _talk_saved_fov))

	CONVERSATION.set_world_position(self, explore_pivot.lerp(pivot, weight))
	yaw = lerp_angle(_talk_saved_yaw, shot_yaw, weight)
	pitch = lerpf(_talk_saved_pitch, shot_pitch, weight)
	rotation = Vector3(pitch, yaw, 0.0)
	spring_length = lerpf(_talk_saved_distance, shot_distance, weight)
	if _camera != null:
		_camera.fov = lerpf(_talk_saved_fov, shot_fov, weight)

	if _talk_leaving and is_zero_approx(_talk_blend):
		_talk_leaving = false
		_talk_speaker = null
		_talk_shot = {}
		_talk_used_fallback = false
		# Hand the arm back to `_follow`'s own recovery, and give the exclusion
		# list back to the plain "ignore whatever I am following" rule.
		_talk_excluded.clear()
		clear_excluded_objects()
		if _target is CollisionObject3D:
			add_excluded_object((_target as CollisionObject3D).get_rid())


## Solve the two-shot, then find out whether it fits, then take the closer
## over-shoulder if it does not. Empty when the speaker has gone (a villager
## removed by a progression flag mid-sentence), in which case the caller keeps
## the last good shot rather than snapping to nothing.
func _solve_conversation_shot() -> Dictionary:
	if _talk_speaker == null or not is_instance_valid(_talk_speaker):
		return {}
	var trainer_anchor := CONVERSATION.world_position(_target) \
		+ Vector3.UP * float(_talk_cfg.get("trainer_anchor_height", 1.45))
	var speaker_anchor := CONVERSATION.speaker_anchor(_talk_speaker, _talk_cfg)
	var forward := -CONVERSATION.world_basis(self).z

	var shot := CONVERSATION.solve(trainer_anchor, speaker_anchor, forward, _talk_cfg)
	var room := _free_distance_behind(shot["pivot"], shot["dir"], float(shot["distance"]))
	if CONVERSATION.is_blocked(shot, room, _talk_cfg):
		var tighter := CONVERSATION.fallback_config(_talk_cfg)
		shot = CONVERSATION.solve(trainer_anchor, speaker_anchor, forward, tighter)
		shot["fallback"] = true
		var tighter_room := _free_distance_behind(
			shot["pivot"], shot["dir"], float(shot["distance"]))
		shot = CONVERSATION.clamp_to_room(shot, tighter_room, tighter)
	_talk_used_fallback = bool(shot.get("fallback", false))
	return shot


## Metres of clear space from `pivot` out along `dir`, capped at `limit`.
##
## A swept ball rather than a ray, for the reason `_probe_radius` above gives at
## length: indoors a single hairline ray slips between a chair back and a table
## edge and reports a room that is not there.
func _free_distance_behind(pivot: Vector3, dir: Vector3, limit: float) -> float:
	if _occlusion_probe.is_valid():
		return float(_occlusion_probe.call(pivot, dir, limit))
	var world := get_world_3d()
	if world == null:
		return limit
	var space := world.direct_space_state
	if space == null:
		return limit
	var query := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = _probe_radius
	query.shape = ball
	query.transform = Transform3D(Basis(), pivot)
	query.motion = dir * limit
	query.exclude = _talk_excluded
	var travel: Array = space.cast_motion(query)
	if travel.size() < 1:
		return limit
	return float(travel[0]) * limit


## The trainer and the person they are talking to are both excluded from the
## arm's sweep for the whole conversation.
##
## Both matter and for different reasons. The framing pivot sits most of the way
## along the line to the speaker, so the TRAINER stands between that pivot and
## the camera — an arm that collided with them would collapse onto the back of
## their own head every single time. And the pivot can end up inside the
## SPEAKER's capsule when the player walks right into a villager to greet them,
## which a sweep starting in contact reports as zero room and the fallback then
## reads as a wall.
func _exclude_conversation_bodies() -> void:
	# SpringArm3D exposes add/remove/clear for its exclusion list but no getter,
	# so the same RIDs are mirrored here for the shape query below to reuse.
	_talk_excluded.clear()
	clear_excluded_objects()
	if _target is CollisionObject3D:
		_talk_excluded.append((_target as CollisionObject3D).get_rid())
	for body: CollisionObject3D in _collision_bodies_of(_talk_speaker):
		_talk_excluded.append(body.get_rid())
	for rid: RID in _talk_excluded:
		add_excluded_object(rid)


## The colliders belonging to a body. `npc_body.gd` builds its StaticBody3D as a
## direct child, so the node itself and one level of children is the whole
## answer. Deliberately NOT recursive and deliberately not walking upward: a
## villager's parent is the node holding every OTHER villager, and excluding
## that whole level would let the camera sweep straight through the rest of the
## square.
static func _collision_bodies_of(node: Node) -> Array[CollisionObject3D]:
	var found: Array[CollisionObject3D] = []
	if node == null or not is_instance_valid(node):
		return found
	if node is CollisionObject3D:
		found.append(node as CollisionObject3D)
	for child in node.get_children():
		if child is CollisionObject3D:
			found.append(child as CollisionObject3D)
	return found


## Forward direction on the horizontal plane, for translating stick input into
## world movement. Kept here so the controller never has to know how the camera
## is oriented.
func planar_basis() -> Basis:
	return Basis(Vector3.UP, yaw)


## Per-frame extra look scaling from whoever owns the current aim — the throw
## slows the stick further while the reticle is near its target. Reset by
## every set_target, so a profile change cannot inherit a stale slowdown.
func set_look_scale(scale_value: float) -> void:
	_assist_scale = clampf(scale_value, 0.1, 1.0)


static func aim_assist_scale(stick_strength: float, requested_scale: float) -> float:
	var fine_scale := clampf(requested_scale, 0.1, 1.0)
	var full_speed_weight := smoothstep(
		ASSIST_FULL_SPEED_START, ASSIST_FULL_SPEED_END, clampf(stick_strength, 0.0, 1.0))
	return lerpf(fine_scale, 1.0, full_speed_weight)
