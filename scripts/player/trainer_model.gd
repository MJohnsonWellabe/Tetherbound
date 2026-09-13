extends "res://scripts/characters/character_model.gd"

## The trainer's body and its animation.
##
## The loading, fitting and clip-merging all live in the base class now, because
## Grandpa needs exactly the same thing done to exactly the same rig. What is
## left here is the only part that is about the TRAINER: deciding what his body
## should be doing from what the controller is doing.
##
## Reads state rather than being told about it — the same arrangement as the
## combat HUD. A body that keeps its own idea of whether it is running can
## disagree with the character that is running.

@export var player_path: NodePath
## Remote spawns set this before the node enters the tree. The local rig leaves
## it empty and resolves the body from Game.local, the project's sole autoload.
@export var appearance_id: String = ""

var _player: CharacterBody3D = null
## Set while the trainer is aiming a throw, so the body reads as throwing rather
## than as standing still watching its creature be hit.
var _throwing_for: float = 0.0
## Gate A gathering: a held axe/pick/knife must visibly move when used. Held
## for the length of the swing so the body commits to the clip rather than
## flickering back to idle a frame later.
##
## OP21-24: this used to borrow the THROW clip, because the trainer asset had
## no chop of its own — and the owner, playing the shipped build, reported he
## "still does not see a convincing chopping swing". He was right, and the
## reason is that a throw is the wrong motion, not a slightly-off one: it
## turns the chest AWAY from the target, opens the hand at the top of the arc,
## and carries nothing downward through the wood. `animate_humanoid.py::
## author_chop()` now authors a real overhead two-handed chop on the same rig
## (`CLIPS["chop"]`, baked into `trainer_lod0.glb`), and the swing role is its
## own role rather than a second name for throwing.
var _tool_swing_for: float = 0.0

## How far from where the lying pose was applied still counts as being in the
## bed. Same 3.2 m `sequence_director.gd` uses for walking off the mattress.
const LYING_ANCHOR_RADIUS_M := 3.2

## Where the body was when the lying pose was applied. `Vector3.INF` means
## "not lying", so a standing trainer never carries a stale anchor.
var _lying_anchor: Vector3 = Vector3.INF
## W14-RIDING / CL-O3. True while the trainer is sitting on a mount. See
## `set_riding()` for what that actually does to the rig.
var _riding: bool = false
## Metres the art was dropped so the rider's hips, not their feet, land on the
## species' `mount_offset`. Measured from the live rig when riding begins (the
## selectable trainer bodies do not share one Hips height), and remembered so
## dismount restores the exact pre-ride position.
var _seat_drop: float = 0.0
## The visual node that received `_seat_drop`. Terrain adaptation owns this
## Model node's Y every walking frame, so rider fit belongs on the fitted art
## root instead; `self` is retained only for the missing-art fallback.
var _seat_drop_target: Node3D = null
## bone index -> the pose rotation that was there before the seated pose was
## written over it. Restored on dismount so nothing of the ride is left on the
## skeleton if the animation player is slow to write its first frame.
var _pose_before_riding: Dictionary = {}
## Production-only riding gaiters that keep the posed legs visible outside a
## broad mount. They are authored around the live rig after the hips are seated,
## move with this trainer in local and remote play, and are removed on dismount.
var _riding_leg_fit: Node3D = null
## movement.json's `gait_feel` block (MQ1A, TUNABLE) — momentum-tilt limits for
## character_model.gd's apply_momentum_tilt(). Read once at ready.
var _gait_feel: Dictionary = {}
var _fly_hang := false
var _fly_pose: Dictionary = {}


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	_gait_feel = _load_gait_feel()
	var chosen := resolved_appearance_id(appearance_id, get_node_or_null(^"/root/Game"))
	if chosen.is_empty() or not build(chosen):
		if chosen != "trainer":
			push_warning("no '%s' body (falling back to trainer)" % chosen)
		if not build("trainer"):
			# The scene's capsule stays visible, so a missing trainer is a
			# trainer that looks wrong rather than a trainer who is not there.
			push_error("no trainer model; falling back to the placeholder capsule")


static func resolved_appearance_id(explicit_id: String, game: Object) -> String:
	if not explicit_id.is_empty():
		return explicit_id
	var local: Variant = game.get("local") if game != null else null
	if local is Object:
		var selected := str((local as Object).get("chosen_character"))
		if not selected.is_empty():
			return selected
	return "trainer"


static func _load_gait_feel() -> Dictionary:
	var file := FileAccess.open("res://data/config/movement.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var feel: Variant = (parsed as Dictionary).get("gait_feel", {})
	return feel if feel is Dictionary else {}


# Physics tick, not _process: every input here — ground_speed, is_on_floor,
# is_sprinting — is produced by the player's _physics_process, and the gait
# scale must never lag it by more than one physics frame. On a loaded machine
# render frames stall while physics keeps its fixed step, and a gait update
# living in _process holds a stale speed (and the 0.5x clamp floor) for as
# many physics frames as the renderer skips — long enough to read as
# slow-motion in play and to trip smoke_input's cadence streak in CI.
func _physics_process(delta: float) -> void:
	if animation_player() == null or _player == null:
		return
	# W14-RIDING: a seated rider is posed, not animated. Everything below drives
	# the body from the trainer's OWN locomotion -- gait role, cadence, momentum
	# tilt, terrain adaptation -- and while carried the trainer has no
	# locomotion of its own (`player_controller._ride()`: no gravity, no
	# friction, no move_and_slide). Running any of it here would read the
	# mount's motion as the rider's and swing the legs of somebody sitting
	# still.
	#
	# Landing lane: W14's ride pose and Cloudreach's fly-hang are both authored
	# poses that suppress the gait, and they are not alternatives -- a rider is
	# seated on a mount, a hanging trainer is carried under one. Both are kept.
	# CLOUDREACH IS TESTED FIRST, per the owner's standing rule that Cloudreach
	# wins: if a build ever reaches a state where both flags are set, the fly
	# hang is the pose that draws, and W14's seated pose yields to it.
	if _fly_hang:
		_apply_fly_hang()
		return
	if _riding:
		return
	_throwing_for = maxf(0.0, _throwing_for - delta)
	_tool_swing_for = maxf(0.0, _tool_swing_for - delta)
	# OF8's other exit from the bed: `sequence_director.gd` clears lying on
	# the "Get up" prompt, but its own soft-lock fallback (`smoke_wake_
	# softlock.gd`) lets the player just walk off the mattress instead, and
	# that beat change only fires once they cross a 3.2m radius. Without this,
	# the body would keep sliding across the floor in the flat bed pose for
	# every metre of that radius. Speed alone, not `is_on_floor()`: the
	# trainer isn't reliably grounded the instant it starts moving off a
	# raised mattress, and the thing that actually means "getting up now" is
	# the player asking to move, not where physics has settled them yet.
	# ...and a THIRD exit, added 2026-09-03: the body was moved off the bed
	# without walking. `ground_speed` stays 0 through a teleport, so a harness
	# (or a debug warp, or any future fast travel) that sets `global_position`
	# directly used to carry the flat bed pose to the far side of the map with
	# nothing to clear it. That went unnoticed while `set_lying(true)` rendered
	# a collapsed lump; once OPENING-BED-0903 made the pose a real lying body,
	# `smoke_gate_a_rest_torch` caught it at once — the trainer drew a torch
	# while still lying, so the flame sat beside the prop origin instead of
	# above it.
	#
	# Measured from where the pose was APPLIED, not frame to frame: the wake
	# beat teleports the player into the bed and poses them there, so a bare
	# "position jumped" rule clears the pose it was setting (it did, once —
	# `smoke_opening` went red on "the trainer is not lying down at the start
	# of the wake beat"). The radius is the one `sequence_director.gd` already
	# uses for walking off the mattress, so both exits agree on how far from
	# the bed still counts as in it.
	if is_lying():
		if _lying_anchor == Vector3.INF:
			_lying_anchor = _player.global_position
	else:
		_lying_anchor = Vector3.INF
	var left_the_bed := _lying_anchor != Vector3.INF \
		and _player.global_position.distance_to(_lying_anchor) > LYING_ANCHOR_RADIUS_M
	if is_lying() and (float(_player.call("ground_speed")) > 0.4 or left_the_bed):
		set_lying(false)
	# Only the throw and the chop are committed one-shots (timed by
	# _throwing_for / _tool_swing_for); idle,
	# walk, sprint and jump are all states the trainer can hold indefinitely
	# and must loop — see character_model.gd's play() for why that matters.
	var role := _role_for_state()
	# The looping flag is per-ROLE, not per-clip: a one-shot played on loop
	# rewinds and swings again for as long as the state holds. Before OP21-24
	# this read `_throwing_for <= 0.0`, which was complete while the throw was
	# the only one-shot and would have quietly looped the chop.
	play(_clip_for_role(role), _throwing_for <= 0.0 and _tool_swing_for <= 0.0)
	# OF5: gait cadence tracks how fast the body is actually covering ground,
	# not the one speed the clip was baked at. No-op (resets to 1x) for every
	# non-gait role — see character_model.gd's match_gait_rate().
	match_gait_rate(role, _player.call("ground_speed"))
	# MQ1A: the body tips into starts, stops and turns. Grounded only — in
	# the air the jump clip owns the silhouette and a tilt reads as tumbling.
	var planar := Vector3(_player.velocity.x, 0.0, _player.velocity.z) \
		if _player.is_on_floor() else Vector3.ZERO
	apply_momentum_tilt(planar, delta, _gait_feel)
	# MQ1B: terrain adaptation ADDS to the momentum tilt just applied above,
	# so a launch on a slope both leans into the acceleration and banks into
	# the hill — see character_model.gd::apply_terrain_adaptation's own
	# header for why this runs second. Grounded only, same reasoning as the
	# momentum tilt: mid-air the jump clip owns the silhouette.
	if _player.is_on_floor():
		_apply_terrain_adaptation(delta)


## MQ1B. Samples the world's own `ground_height_at()` (found by walking up
## the tree the same way village.gd::_ground_height() does — a component
## should not be handed a world reference it can then hold stale) at four
## points around the trainer's own feet plus the feet themselves, and hands
## the raw numbers to character_model.gd::apply_terrain_adaptation(), which
## stays free of any Node-tree lookup itself (matches apply_momentum_tilt's
## own "read state rather than being told about it" split: this is the
## reading, that is the reacting).
func _apply_terrain_adaptation(delta: float) -> void:
	var world: Node = get_parent()
	while world != null and not world.has_method("ground_height_at"):
		world = world.get_parent()
	if world == null:
		return

	var stance: float = float(_gait_feel.get("terrain_stance_width", 0.18))
	var stride: float = float(_gait_feel.get("terrain_probe_ahead", 0.22))
	var origin := _player.global_position
	var yaw := rotation.y
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))

	var h_centre: float = world.call("ground_height_at", origin.x, origin.z)
	var h_left: float = world.call(
		"ground_height_at", origin.x - right.x * stance, origin.z - right.z * stance)
	var h_right: float = world.call(
		"ground_height_at", origin.x + right.x * stance, origin.z + right.z * stance)
	var h_forward: float = world.call(
		"ground_height_at", origin.x + forward.x * stride, origin.z + forward.z * stride)
	var h_back: float = world.call(
		"ground_height_at", origin.x - forward.x * stride, origin.z - forward.z * stride)

	apply_terrain_adaptation(
		h_centre - origin.y, h_left, h_right, h_forward, h_back,
		stance, stride, delta, _gait_feel)


## What the trainer's body should be doing, from what the trainer is doing.
func _role_for_state() -> String:
	# Chop is checked first: a swing started while a throw is still settling
	# should show the tool the player just used, not the orb they threw before
	# it. The two are never both wanted, and the newer one is the honest one.
	if _tool_swing_for > 0.0:
		return "chop"
	if _throwing_for > 0.0:
		return "throw"
	if not _player.is_on_floor():
		return "jump"

	var speed: float = _player.call("ground_speed")
	if speed < 0.4:
		return "idle"
	return "sprint" if bool(_player.call("is_sprinting")) else "walk"


func _clip_for_role(role: String) -> String:
	# The throw's fallback predates the authored clip set; every other role
	# falls back to a clip of its own name, jump to idle.
	match role:
		"throw":
			return clip_for("throw", "pick-up")
		"chop":
			# Falls back to the throw, which is what this role played before
			# OP21-24 authored a chop -- so a rig baked before that clip
			# existed (or a stand-in with a partial clip set) still shows arm
			# motion rather than a frozen body swinging an invisible axe.
			return clip_for("chop", clip_for("throw", "pick-up"))
		"jump":
			return clip_for("jump")
		_:
			return clip_for(role, role)


## Called when a throw is released, so the body commits to the animation for its
## duration rather than for exactly one frame.
func play_throw(seconds: float = 0.6) -> void:
	_throwing_for = seconds


## Called when a swing starts, so the body commits to the chop for the clip's
## own length. `tool_hold.gd` passes `art.json`'s `tool_swing.seconds`.
func play_tool_swing(seconds: float = 0.625) -> void:
	_tool_swing_for = maxf(_tool_swing_for, seconds)


## --- W14-RIDING / CL-O3: the rider is on the creature ------------------------
##
## Owner, playing the shipped build: *"When you ride your person didn't show up
## on the creature."* He was right, and it was deliberate — `player_controller.
## set_carrier()` hid the trainer's art outright, with a comment saying why:
## there is no seated clip on this rig, so a visible trainer rode the Meadowhart
## standing bolt upright on its back.
##
## The clip still does not exist and cannot be bought: `animate_humanoid.py`'s
## `CLIPS` bakes idle/walk/sprint/jump/throw/chop, and CLAUDE.md forbids
## spending a Meshy generation without owner-supplied reference art. So the pose
## is authored here, on the skeleton, the same way `set_lying()` authors the bed
## pose in the base class rather than waiting for a clip that is never coming.
##
## AXES, MEASURED, NOT ASSUMED (`tools/_probe_ride_pose.gd`, this lane).
## `animate_humanoid.py`'s own AXES table is stated in BLENDER pose-euler terms
## and glTF's axis conversion sits between it and the game, so it was re-derived
## from the clips that actually shipped: for every joint below, the probe read
## the delta between the authored walk/jump extremes and the bone's rest pose
## and reported the axis-angle. Every one of them came back on the bone's own
## LOCAL X, to three decimal places (`LeftLeg max 69.2 deg about (1.00, 0.00,
## 0.00)`), and the signs match the Blender table verbatim:
##
##   thigh   -X = swing forward (jump's landing crouch: -39.7 deg)
##   shin    +X = knee flexion  (walk's swing phase: +69.2 deg)
##   foot    +X = plantarflex   (toes down)
##   arm     -X = swing forward (jump's tuck: -63.6 deg)
##   forearm -X = elbow flexion (walk: -62.0 deg)
##
## So a seated pose is: thighs flexed forward to roughly horizontal, knees bent
## down under them, ankles a little plantarflexed into the stirrups, arms
## forward on the reins, and a slight forward lean at the spine. Every angle is
## TUNABLE in `data/config/riding.json`.
##
## The animation player is switched OFF (`AnimationMixer.active`) rather than
## fought: it writes every one of these bones every frame, so a pose written
## underneath a running mixer is a pose that lasts until the next tick. Off, the
## skeleton holds what it is given, and turning it back on resumes the clip it
## was already playing, at the position it had — which is why nothing here has
## to remember what the trainer was doing before they got on.

const RIDING_CONFIG_PATH := "res://data/config/riding.json"
const RIDING_LEG_FIT_NODE := "RidingLegFit"

## Bone name -> what a seated body does with it, in degrees about the bone's own
## local X, positive as the probe measured it. `key` names the riding.json entry
## the magnitude comes from; `sign` is the direction the measurement above says
## that flexion actually lives on for THAT joint.
const RIDE_POSE := [
	{"bone": "LeftUpLeg", "key": "hip_flexion_deg", "sign": -1.0, "spread": 1.0},
	{"bone": "RightUpLeg", "key": "hip_flexion_deg", "sign": -1.0, "spread": -1.0},
	{"bone": "LeftLeg", "key": "knee_flexion_deg", "sign": 1.0, "spread": 0.0},
	{"bone": "RightLeg", "key": "knee_flexion_deg", "sign": 1.0, "spread": 0.0},
	{"bone": "LeftFoot", "key": "ankle_flexion_deg", "sign": 1.0, "spread": 0.0},
	{"bone": "RightFoot", "key": "ankle_flexion_deg", "sign": 1.0, "spread": 0.0},
	# The shipped +X sign reclined the torso away from the reins in the actual
	# Meadowhart capture. The imported rig's forward trunk flexion is -X (the
	# same sign as its forward arm/thigh swing), so keep the rider over the seat.
	{"bone": "Spine", "key": "torso_lean_deg", "sign": -1.0, "spread": 0.0},
	{"bone": "LeftArm", "key": "shoulder_flexion_deg", "sign": -1.0, "spread": 0.0},
	{"bone": "RightArm", "key": "shoulder_flexion_deg", "sign": -1.0, "spread": 0.0},
	{"bone": "LeftForeArm", "key": "elbow_flexion_deg", "sign": -1.0, "spread": 0.0},
	{"bone": "RightForeArm", "key": "elbow_flexion_deg", "sign": -1.0, "spread": 0.0},
]


## Sit on the mount, or get off it. Called by `player_controller.set_carrier()`,
## which is the one place in the project that knows a body is being carried.
##
## Safe to call twice with the same value, and safe to call before the art has
## loaded — a trainer with no skeleton simply stays standing, which is the same
## failure mode `build()` already has.
func set_riding(riding: bool, thigh_spread_override_deg: float = -1.0,
		rider_leg_fit: Dictionary = {}) -> void:
	if _riding == riding:
		# A repeated live/network riding fact may arrive after its visual fit.
		# Preserve idempotence for the pose and seat drop while repairing only a
		# missing production node instead of freezing that partial state forever.
		if riding and not rider_leg_fit.is_empty() and not riding_leg_fit_present():
			_build_riding_leg_fit(skeleton(), rider_leg_fit)
		return
	_riding = riding
	var skeleton_node := skeleton()
	var anim := animation_player()
	if riding:
		# The bed pose and the saddle are mutually exclusive states of one body;
		# whichever is asked for last wins, and getting on a creature is the
		# clearer statement of the two.
		set_lying(false)
		# MQ1A's momentum tilt is the trainer leaning into their own
		# acceleration. A passenger has none, and a leftover tilt reads as a
		# rider slowly falling off the side.
		rotation.x = 0.0
		rotation.z = 0.0
		if anim != null:
			anim.active = false
		_apply_ride_pose(skeleton_node, thigh_spread_override_deg)
		_seat_drop = _measured_seat_drop(skeleton_node)
		_seat_drop_target = _art if _art != null else self
		_seat_drop_target.position.y -= _seat_drop
		_build_riding_leg_fit(skeleton_node, rider_leg_fit)
		return
	_clear_riding_leg_fit()
	_restore_ride_pose(skeleton_node)
	if anim != null:
		anim.active = true
	if _seat_drop_target != null and is_instance_valid(_seat_drop_target):
		_seat_drop_target.position.y += _seat_drop
	_seat_drop_target = null
	_seat_drop = 0.0


## Distance from the current art's Hips bone to the Player/carrier anchor in
## the Player's local frame. `mount_offset` seats the Player node; lowering this
## Model by the live value puts the pelvis on that same point. A single fixed
## number worked only while the original trainer was the sole playable rig.
## Keep the authored value as a defensive fallback for partial/missing rigs.
func _measured_seat_drop(skeleton_node: Skeleton3D) -> float:
	var fallback := float(_rider_config().get("seat_drop_m", 0.92))
	if skeleton_node == null or not skeleton_node.is_inside_tree():
		return fallback
	var hips_index := skeleton_node.find_bone("Hips")
	var parent_body := get_parent() as Node3D
	if hips_index < 0 or parent_body == null:
		return fallback
	var hips_world := skeleton_node.global_transform \
		* skeleton_node.get_bone_global_pose(hips_index).origin
	var hips_in_body := parent_body.to_local(hips_world)
	if is_nan(hips_in_body.y) or is_inf(hips_in_body.y) or hips_in_body.y <= 0.0:
		return fallback
	return hips_in_body.y


func is_riding() -> bool:
	return _riding


## True when the seated pose actually reached the skeleton. The rider being
## VISIBLE is not the same claim as the rider being SEATED, and
## `tests/smoke_riding.gd` asserts both — a standing trainer drawn on a
## creature's back is the bug this lane was given, wearing a different mask.
func ride_pose_applied() -> bool:
	return _riding and not _pose_before_riding.is_empty()


static func _rider_config() -> Dictionary:
	var file := FileAccess.open(RIDING_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var rider: Variant = (parsed as Dictionary).get("rider", {})
	return rider if rider is Dictionary else {}


func _apply_ride_pose(skeleton_node: Skeleton3D, thigh_spread_override_deg: float = -1.0) -> void:
	_pose_before_riding.clear()
	if skeleton_node == null:
		return
	var cfg := _rider_config()
	# A mount may be materially wider than the default ride body.  Its data can
	# widen only the thighs so the near leg clears the flank and reaches the
	# stirrup; pelvis height/position remains the measured physical seat.
	var spread_deg := thigh_spread_override_deg if thigh_spread_override_deg >= 0.0 \
		else float(cfg.get("thigh_spread_deg", 0.0))
	var spread := deg_to_rad(spread_deg)
	for entry: Dictionary in RIDE_POSE:
		var index := skeleton_node.find_bone(str(entry["bone"]))
		if index < 0:
			continue
		_pose_before_riding[index] = skeleton_node.get_bone_pose_rotation(index)
		var flex := deg_to_rad(float(cfg.get(str(entry["key"]), 0.0))) * float(entry["sign"])
		# Rest-relative, never absolute: the rest pose already carries the
		# rig's own limb orientation, and writing an absolute rotation would
		# throw that away and splay the legs sideways on any rig whose bones
		# are not axis-aligned at rest.
		var rest: Quaternion = skeleton_node.get_bone_rest(index).basis.get_rotation_quaternion()
		skeleton_node.set_bone_pose_rotation(index,
			rest * Quaternion.from_euler(Vector3(flex, 0.0, spread * float(entry["spread"]))))


## The source skins' legs are narrow enough to disappear inside Meadowhart's
## replacement torso at ordinary camera distance. This adds neutral riding
## trousers/gaiters around the live seated joints, not a capture prop: both the
## local and remote trainer call this same method, and the geometry remains on
## the trainer for the entire ride. The foot target is authored relative to the
## unchanged physical seat so the boot occupies the visible saddle stirrup.
func _build_riding_leg_fit(skeleton_node: Skeleton3D, fit: Dictionary) -> void:
	_clear_riding_leg_fit()
	if skeleton_node == null or fit.is_empty() or _art == null:
		return
	var hips_index := skeleton_node.find_bone("Hips")
	if hips_index < 0:
		return
	# PlayerController seats this Model node's parent exactly at mount_offset,
	# then the fitted art is dropped until its Hips bone reaches that origin.
	# The physical seat in Model-local metre space is therefore ZERO. Reading a
	# global bone transform in the same frame as that drop used its stale
	# pre-propagation height and floated the added leg above the real thigh.
	var seat := Vector3.ZERO
	var outset := float(fit.get("outset_m", 0.48))
	var hip_ratio := float(fit.get("hip_outset_ratio", 0.38))
	var knee_drop := float(fit.get("knee_drop_m", 0.31))
	var stirrup_drop := float(fit.get("stirrup_drop_m", 0.58))
	var knee_forward := float(fit.get("knee_forward_m", 0.08))
	var stirrup_forward := float(fit.get("stirrup_forward_m", 0.03))
	var radius := float(fit.get("limb_radius_m", 0.095))
	if outset <= 0.0 or knee_drop <= 0.0 or stirrup_drop <= knee_drop or radius <= 0.0:
		return
	_riding_leg_fit = Node3D.new()
	_riding_leg_fit.name = RIDING_LEG_FIT_NODE
	add_child(_riding_leg_fit)
	var trouser := _riding_fit_material(Color(str(fit.get("trouser_colour", "#52677d"))))
	var leather := _riding_fit_material(Color(str(fit.get("boot_colour", "#593823"))))
	var boot_size := _fit_vector3(fit.get("boot_size_m", []), Vector3(0.19, 0.18, 0.34))
	for side: float in [-1.0, 1.0]:
		var hip := seat + Vector3(side * outset * hip_ratio, -0.035, 0.0)
		var knee := seat + Vector3(side * outset, -knee_drop, knee_forward)
		var ankle := seat + Vector3(side * outset, -stirrup_drop, stirrup_forward)
		_add_riding_limb_segment(_riding_leg_fit, "Thigh", side, hip, knee, radius, trouser)
		_add_riding_limb_segment(_riding_leg_fit, "Shin", side, knee, ankle,
			radius * 0.88, trouser)
		_add_riding_boot(_riding_leg_fit, side, ankle, boot_size, leather)


func _clear_riding_leg_fit() -> void:
	if _riding_leg_fit != null and is_instance_valid(_riding_leg_fit):
		_riding_leg_fit.free()
	_riding_leg_fit = null


func riding_leg_fit_present() -> bool:
	return _riding and _riding_leg_fit != null and is_instance_valid(_riding_leg_fit) \
		and _riding_leg_fit.get_child_count() == 6


func riding_leg_fit_receipt() -> Dictionary:
	var receipt := {"complete": riding_leg_fit_present(), "parts": {}}
	if not bool(receipt.complete):
		return receipt
	var parts: Dictionary = receipt.parts
	for child: Node in _riding_leg_fit.get_children():
		if not child is MeshInstance3D:
			continue
		var row := {"centre_local": _vector3_array((child as Node3D).position)}
		if child.has_meta(&"segment_start_local"):
			row["start_local"] = _vector3_array(child.get_meta(&"segment_start_local") as Vector3)
			row["end_local"] = _vector3_array(child.get_meta(&"segment_end_local") as Vector3)
		if child.has_meta(&"stirrup_anchor_local"):
			row["stirrup_anchor_local"] = _vector3_array(child.get_meta(&"stirrup_anchor_local") as Vector3)
		parts[child.name] = row
	# Prove each visible insert is a continuous authored chain from thigh through
	# shin to the occupied stirrup anchor. These values come from the real nodes;
	# the capture harness does not reconstruct or fabricate the geometry.
	for side: String in ["Left", "Right"]:
		var thigh := _riding_leg_fit.get_node_or_null(NodePath("%s_Thigh" % side))
		var shin := _riding_leg_fit.get_node_or_null(NodePath("%s_Shin" % side))
		var boot := _riding_leg_fit.get_node_or_null(NodePath("%sBoot" % side))
		var continuous: bool = thigh != null and shin != null and boot != null \
			and thigh.get_meta(&"segment_end_local", Vector3.INF) \
				== shin.get_meta(&"segment_start_local", Vector3.ZERO) \
			and shin.get_meta(&"segment_end_local", Vector3.INF) \
				== boot.get_meta(&"stirrup_anchor_local", Vector3.ZERO)
		receipt["continuous_%s" % side.to_lower()] = continuous
		receipt.complete = bool(receipt.complete) and continuous
	return receipt


static func _add_riding_limb_segment(parent: Node3D, label: String, side: float,
		start_point: Vector3, end_point: Vector3, radius: float, material: Material) -> void:
	var delta := end_point - start_point
	if delta.length() <= radius * 2.0:
		return
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = delta.length() + radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 4
	var instance := MeshInstance3D.new()
	instance.name = "%s_%s" % ["Left" if side < 0.0 else "Right", label]
	instance.mesh = mesh
	instance.material_override = material
	instance.position = (start_point + end_point) * 0.5
	instance.basis = _basis_along_y(delta)
	instance.set_meta(&"segment_start_local", start_point)
	instance.set_meta(&"segment_end_local", end_point)
	parent.add_child(instance)


static func _add_riding_boot(parent: Node3D, side: float, ankle: Vector3,
		size: Vector3, material: Material) -> void:
	# A low-poly wedge reads as a planted riding boot from the side without the
	# oversized rectangular block exposed by R7.  Its narrow instep occupies the
	# stirrup while the broader toe projects forward from the same proven ankle.
	var mesh := PrismMesh.new()
	mesh.size = size
	mesh.left_to_right = side > 0.0
	var instance := MeshInstance3D.new()
	instance.name = "%sBoot" % ("Left" if side < 0.0 else "Right")
	instance.mesh = mesh
	instance.material_override = material
	# The ankle sits inside the stirrup loop; the smaller wedge extends down and
	# forward from it, leaving the loop readable around the upper foot.
	instance.position = ankle + Vector3(0.0, -size.y * 0.28, -size.z * 0.18)
	instance.set_meta(&"stirrup_anchor_local", ankle)
	parent.add_child(instance)


static func _basis_along_y(direction: Vector3) -> Basis:
	var y := direction.normalized()
	var reference := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := reference.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


static func _fit_vector3(raw: Variant, fallback: Vector3) -> Vector3:
	if raw is Array and (raw as Array).size() == 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return fallback


static func _vector3_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


static func _riding_fit_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	material.metallic = 0.0
	return material


func _restore_ride_pose(skeleton_node: Skeleton3D) -> void:
	if skeleton_node != null:
		for index: int in _pose_before_riding:
			if index < skeleton_node.get_bone_count():
				skeleton_node.set_bone_pose_rotation(index, _pose_before_riding[index])
	_pose_before_riding.clear()


## Installed humanoid rig, both hands above the head. This pose is procedural
## because final species-specific Fly clips remain deferred. Keep the trainer
## visible and retain the ordinary player collision shape throughout.
func set_fly_hang(enabled: bool, pose: Dictionary = {}) -> void:
	_fly_hang = enabled
	_fly_pose = pose
	if animation_player() != null:
		animation_player().stop()
	_current = "" # the base clip cache must not suppress the resumed gait
	var rig := skeleton()
	if rig != null:
		rig.reset_bone_poses()
	if enabled:
		set_lying(false)
		_apply_fly_hang()


func _apply_fly_hang() -> void:
	var rig := skeleton()
	if rig == null:
		return
	# Aim each arm chain toward the creature's grip points. Bone rest axes are
	# read from the actual installed rig, not assumed to be Mixamo or KayKit.
	for side: String in ["Left", "Right"]:
		var side_sign := 1.0 if side == "Left" else -1.0
		_aim_hang_bone(rig, side + "Arm", side + "ForeArm", Vector3(side_sign * float(_fly_pose.get("upper_lateral", 0.8)), 1.0, 0.08))
		_aim_hang_bone(rig, side + "ForeArm", side + "Hand", Vector3(side_sign * float(_fly_pose.get("forearm_lateral", 0.65)), 1.0, 0.0))


func _aim_hang_bone(rig: Skeleton3D, bone_name: String, child_name: String, direction: Vector3) -> void:
	var bone := rig.find_bone(bone_name)
	var child := rig.find_bone(child_name)
	if bone < 0 or child < 0:
		return
	var parent := rig.get_bone_parent(bone)
	var parent_basis := rig.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var rest_basis := rig.get_bone_rest(bone).basis
	var rest_axis := rig.get_bone_rest(child).origin.normalized()
	var target := (parent_basis.inverse() * direction).normalized()
	if rest_axis.length_squared() > 0.5:
		# Godot's pose rotation replaces the local rest rotation; it is not an
		# additive delta. Preserve rest roll while aiming the actual limb axis.
		var aim := Quaternion((rest_basis * rest_axis).normalized(), target)
		rig.set_bone_pose_rotation(bone, aim * rest_basis.get_rotation_quaternion())
