extends CharacterBody3D

## Third-person locomotion: walk, sprint, jump, stamina, fall damage.
##
## M1's whole job. Nothing here knows about creatures, combat or the world beyond the
## ground it stands on, and it should stay that way until traversal feels good
## on the Ally (docs/specs/MEADOWS_VERTICAL_SLICE.md M1 acceptance).
##
## Every number comes from data/config/movement.json. If a value is typed into
## this file, that is a bug: the owner's feedback in M1 is going to be "too
## floaty", "sprint too slow", "camera too close", and each of those has to be
## answerable by editing data, not code.

const CONFIG_PATH := "res://data/config/movement.json"
const VITALS_CONFIG_PATH := "res://data/config/vitals.json"
const VITALS := preload("res://scripts/player/player_vitals.gd")
const TORCH := preload("res://scripts/player/torch.gd")
const TOOL_HOLD := preload("res://scripts/player/tool_hold.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

signal landed(impact_speed: float, damage: float)
signal died()

var vitals: RefCounted = VITALS.new()
## The torch's light (scripts/player/torch.gd) -- built here from the first
## frame like `tool_hold` below, but only actually lit while `torch` is the
## equipped tool (OW12; see that file's own header). Exposed the same way
## `vitals` is, so the HUD can read `torch.is_on()` without reaching past
## this node.
var torch: Node3D = null

## The tool in the trainer's hand, and the swing that harvests with it. Held
## here for the same reason `torch` and `vitals` are: the HUD and the harvest
## nodes ask the player for it rather than hunting the tree for it.
var tool_hold: Node3D = null

@export var camera_rig_path: NodePath
var _camera_rig: Node3D = null
var _model: Node3D = null

var _walk_speed: float = 4.2
var _sprint_speed: float = 7.6
var _ground_accel: float = 42.0
var _ground_friction: float = 38.0
var _air_accel: float = 9.0
var _turn_speed: float = 11.0
## The runaway ceiling. See `_clamp_runaway_velocity()`.
var _max_speed: float = 120.0

var _jump_velocity: float = 7.0
var _gravity: float = 26.0
var _fall_multiplier: float = 1.35
var _coyote_time: float = 0.12
var _buffer_time: float = 0.12

## Time since last leaving the ground, for coyote time.
var _airborne_for: float = 0.0
## Time since jump was pressed, for input buffering.
var _jump_buffered_for: float = INF
## Downward speed on the frame before landing, since velocity.y is zeroed by
## the time is_on_floor() reports true.
var _fall_speed: float = 0.0
var _was_on_floor: bool = true
var _sprinting: bool = false

## Cleared while a fight is running. Gravity, landing and stamina keep ticking —
## the trainer is still a body standing in the world, and switching them off
## leaves the player hovering wherever combat happened to open.
var _locomotion_enabled: bool = true

## R6.1. Something else is carrying this body: a node whose transform this one
## rides on, plus the local offset to sit at.
##
## Deliberately a bare Node3D rather than "the mount". This file's own header
## promises it knows nothing about creatures, and it still does not — it knows
## that a body can be carried, which is the same statement a lift or a cart
## would need. `riding_controller.gd` is the thing that knows the carrier is a
## Meadowhart.
##
## While carried, the trainer runs NO locomotion of its own: no gravity, no
## friction, no jump, no move_and_slide. Two things writing one transform in one
## frame is one of them silently losing, the same rule `_set_exploration_active`
## states for the ally body.
var _carrier: Node3D = null
## Whether this body is currently being carried, tracked separately from
## `_carrier` because a FREED Object reference compares equal to null in
## GDScript. `if _carrier != null` therefore goes false the instant the mount is
## deleted, which silently skips the one branch written to handle exactly that —
## measured, not guessed (tests/smoke_riding.gd's despawn case caught it leaving
## the trainer invisible and collisionless).
var _carried: bool = false
var _carry_offset: Vector3 = Vector3.ZERO
## Saved so dismounting restores exactly what mounting took, rather than
## assuming the layer this scene happened to ship with.
var _carry_saved_layer: int = 0
var _carry_saved_mask: int = 0

# --- entombment failsafe (GATE-F-DEFECT-FIX) --------------------------------
# See `_recover_if_entombed` below and movement.json's own `unstick` comment
# for the measurement this exists to answer.
var _unstick_enabled: bool = true
var _unstick_after: float = 2.0
var _unstick_progress_m: float = 0.08
var _unstick_probe_m: float = 0.45
var _breadcrumb_spacing_m: float = 2.5
var _breadcrumb_count: int = 10
var _unstick_min_distance_m: float = 6.0
var _unstick_lift_max_m: float = 8.0
var _unstick_lift_step_m: float = 0.4

## The direction `_apply_movement` resolved this frame, kept so the failsafe can
## tell "the player is asking to go somewhere and is not going" from "the player
## let go of the stick". Without this the timer would run while nobody is
## pressing anything, which is a standing player, not a trapped one.
var _wanted_dir: Vector3 = Vector3.ZERO
## Where the body was when it stopped making progress, and for how long.
var _stuck_anchor: Vector3 = Vector3.ZERO
var _stuck_for: float = 0.0
var _has_stuck_anchor: bool = false
## Ground the body actually stood on and walked away from, newest last.
var _breadcrumbs: Array[Vector3] = []
## Counts recoveries for the smoke test and for anyone reading a run log.
var _unstick_count: int = 0


func _ready() -> void:
	_load_config()
	_camera_rig = get_node_or_null(camera_rig_path) as Node3D
	_model = get_node_or_null(^"Model") as Node3D
	if _camera_rig != null and _camera_rig.has_method("set_target"):
		_camera_rig.call("set_target", self)

	torch = TORCH.new()
	torch.name = "Torch"
	add_child(torch)

	tool_hold = TOOL_HOLD.new()
	tool_hold.name = "ToolHold"
	add_child(tool_hold)
	if tool_hold.has_signal("swing_started"):
		tool_hold.connect("swing_started", _on_tool_swing_started)

	# RG7: if a slot was loaded before this scene existed (title -> Load), Game
	# retained the pose and can finally apply it now that Player/CameraRig exist.
	var game := get_node_or_null(^"/root/Game")
	if game != null and game.has_method("apply_loaded_player_pose"):
		game.call_deferred("apply_loaded_player_pose")


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("movement.json missing at %s" % CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("movement.json is not valid JSON")
		return
	var config: Dictionary = parsed

	var loco: Dictionary = config.get("locomotion", {})
	_walk_speed = float(loco.get("walk_speed", _walk_speed))
	_sprint_speed = float(loco.get("sprint_speed", _sprint_speed))
	_max_speed = float(loco.get("max_speed", _max_speed))
	_ground_accel = float(loco.get("ground_acceleration", _ground_accel))
	_ground_friction = float(loco.get("ground_friction", _ground_friction))
	_air_accel = float(loco.get("air_acceleration", _air_accel))
	_turn_speed = float(loco.get("turn_speed", _turn_speed))

	var unstick: Dictionary = config.get("unstick", {})
	_unstick_enabled = bool(unstick.get("enabled", _unstick_enabled))
	_unstick_after = float(unstick.get("detect_after_s", _unstick_after))
	_unstick_progress_m = float(unstick.get("progress_m", _unstick_progress_m))
	_unstick_probe_m = float(unstick.get("probe_m", _unstick_probe_m))
	_breadcrumb_spacing_m = float(unstick.get("breadcrumb_spacing_m", _breadcrumb_spacing_m))
	_breadcrumb_count = int(unstick.get("breadcrumb_count", _breadcrumb_count))
	_unstick_min_distance_m = float(unstick.get("min_recovery_distance_m", _unstick_min_distance_m))
	_unstick_lift_max_m = float(unstick.get("lift_max_m", _unstick_lift_max_m))
	_unstick_lift_step_m = float(unstick.get("lift_step_m", _unstick_lift_step_m))

	var jump: Dictionary = config.get("jump", {})
	_gravity = float(jump.get("gravity", _gravity))
	_fall_multiplier = float(jump.get("fall_gravity_multiplier", _fall_multiplier))
	_coyote_time = float(jump.get("coyote_time", _coyote_time))
	_buffer_time = float(jump.get("buffer_time", _buffer_time))
	# Derived from height so retuning gravity does not silently change how high
	# the character jumps, which is the usual way this pair drifts apart.
	_jump_velocity = sqrt(2.0 * _gravity * float(jump.get("height", 1.35)))

	vitals.configure(config)
	_load_vitals_config()


## D29 satiety. Separate file from movement.json so hunger tuning does not
## get mixed into the locomotion sheet it has nothing to do with.
func _load_vitals_config() -> void:
	var file := FileAccess.open(VITALS_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("vitals.json missing at %s" % VITALS_CONFIG_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("vitals.json is not valid JSON")
		return
	vitals.configure_satiety(parsed as Dictionary)


func _physics_process(delta: float) -> void:
	if _carried:
		_ride(delta)
		return
	# RG5 (owner playtest, 2026-08-18): "when the building menu is up, pressing
	# directions and pressing a still controls the character too as the menu."
	# `build_menu.gd` is the one panel that deliberately does not pause the
	# tree (its own header explains why), so this node kept polling movement
	# and jump underneath it -- and `jump` and the menu's own `ui_accept`
	# (picking a piece) are bound to the SAME physical button (project.godot:
	# joypad button 0), so confirming a piece also jumped the trainer. Every
	# other world-verb poll already asks `input_owner.gd` this same question
	# (`build_placer.gd`, `interaction_arbiter.gd`); this was the one that
	# never had, despite being the most obviously affected by a leak.
	var input_owned := INPUT_OWNER.current(get_tree()) != null
	_track_airborne(delta, input_owned)
	_apply_gravity(delta)
	_toggle_auto_run(input_owned)
	_apply_movement(delta, input_owned)
	_try_jump(input_owned)

	_clamp_runaway_velocity()

	var falling_speed := -velocity.y
	# Captured BEFORE move_and_slide: sliding against a wall zeroes the
	# into-wall component of velocity, which is precisely the motion the
	# step-up probe needs to test.
	var planned_motion := Vector3(velocity.x, 0.0, velocity.z) * delta
	var before := global_position
	move_and_slide()
	_try_step_up(planned_motion)
	_unwedge(planned_motion, before, delta)
	_recover_if_entombed(delta)
	_resolve_landing(falling_speed)

	vitals.tick(delta, _sprinting and velocity.length() > 0.5)
	vitals.tick_satiety(delta)


## T5-CARE. A ceiling on how fast this body can be travelling, whatever put the
## number there.
##
## Measured, not theorised. Booting the real Meadows with `opening:beat:
## free_play` set -- the ordinary post-opening state -- put the player at the
## world origin while `playground_world.gd` was still building the settlement
## around them, and `tools/_probe_t5_launch.gd` caught what happened next:
##
##   frame  14  pos (0.0, 2.90, 0.0)            vel (0, 0, 0)      on_floor=false
##   frame  17  pos (-23721.0, 3079.46, 7468.8) vel (-1444690, 368, 454877) on_floor=true
##
## 1.44 MILLION metres per second, arriving in one frame with the body reporting
## `on_floor`. That is Godot's platform-velocity inheritance: the body was
## resting on a collider at the instant the world moved it, and 24km of collider
## motion in one 60Hz frame is exactly 1.44e6 m/s. Three frames later the player
## is past the perimeter guard, which prints "player fell below the world ...
## returning to spawn", and the run never recovers.
##
## The cost of that is not academic: it is why
## `tests/smoke_gate_a_build_segment_meadows.gd` -- the canonical proof that a
## controller can BUILD in the real Meadows -- cannot complete a run on this
## branch, and therefore why exit-criterion section H had no evidence behind it.
##
## Deliberately a CLAMP and not a fix to whatever moved the collider. The race
## is between world construction and the physics step, there is more than one
## thing in the Meadows that gets built under a standing body, and a body in
## this game has no legitimate reason to exceed this speed: sprint is 8.6 m/s
## (`movement.json`) and `vitals.json` calls a 34 m/s landing lethal. So this is
## the general guard, and the direction is preserved rather than zeroed -- a
## clamp keeps a real fall falling, where a zero would hang the player in the
## air. TUNABLE via `movement.json::locomotion.max_speed`.
func _clamp_runaway_velocity() -> void:
	var speed := velocity.length()
	if speed <= _max_speed:
		return
	push_warning("[player] velocity %.0f m/s exceeded the %.0f m/s ceiling at %.1f, %.1f, %.1f; clamped" % [
		speed, _max_speed, global_position.x, global_position.y, global_position.z])
	velocity = velocity / speed * _max_speed


## OF15: slide around what you walk into instead of pinning against it.
##
## Owner ruling (2026-08-25): "when you hit a rock you should slide around it",
## paired with "gates have to be physically sealed -- there needs to actually be
## something keeping a player from walking around it". The two halves belong
## together and neither is safe alone. Sliding without sealed gates lets a
## player walk round a gate; sealed gates without sliding leaves them stuck on
## boulders. `road_gate.gd`'s `seal_half_width` is the other half.
##
## `move_and_slide` already handles a glancing contact, and `_try_step_up`
## below handles anything low enough to step onto. What neither handles is a
## POCKET: contacts whose normals oppose, where every component of the desired
## motion cancels and the body sits still with the stick held. Reproduced by
## `smoke_traversal.gd`, measured by `tools/_probe_wedge.gd` -- boulders 3.0-3.5m
## across, sited close enough to touch.
##
## ONE `move_and_slide()` PER FRAME. An earlier attempt called it a second time
## here, which applies another whole frame of motion and pushed the body clean
## past the village road gate. This only changes the DIRECTION the next frame's
## single move pass is asked for; collision still gets the final say, so nothing
## here can move the body through anything.
##
## Horizontal only -- nothing lifts the body, so `STEP_HEIGHT`'s note ("every
## barrier in the game was sized against players who cannot climb") still holds.
const UNWEDGE_AFTER := 0.2
## Below this fraction of the motion planned for the frame, the body is not
## making progress. Not zero: a pocket usually leaks a millimetre or two.
const UNWEDGE_PROGRESS := 0.25
## How long a deflection steers once triggered. Long enough to clear a boulder,
## and it lapses the moment the player stops asking to go anywhere.
const DEFLECT_FOR := 0.3
## How far along the tangent to check for floor before deflecting -- about one
## step: far enough to catch a ledge the deflection would carry the body over,
## near enough that ordinary ground never reads as a drop.
const DEFLECT_PROBE_M := 0.8
## How far below that step still counts as ground. Deeper than a kerb, much
## shallower than anything that would hurt.
const DEFLECT_DROP_M := 1.2

var _wedged_for := 0.0
var _deflect := Vector3.ZERO
var _deflect_left := 0.0
## The direction the player was ASKING for when the deflection triggered. A
## deflection is only valid for that request: `smoke_input.gd` caught the
## alternative, where a deflection earned while walking forward into something
## was still live when the next input came and steered it instead -- "holding
## move_right moved the player 0.00m".
var _deflect_wanted := Vector3.ZERO


## Is there floor within `DEFLECT_DROP_M` of where `offset` would put the body?
##
## Swept through the physics server rather than raycast from the centre, so a
## body half over an edge is judged by the same shape that has to stand there.
func _ground_under(offset: Vector3) -> bool:
	if test_move(global_transform, offset):
		return false  # solid in the way: not a drop, and the step would not happen
	var params := PhysicsTestMotionParameters3D.new()
	params.from = global_transform.translated(offset)
	params.motion = Vector3.DOWN * DEFLECT_DROP_M
	return PhysicsServer3D.body_test_motion(get_rid(), params, PhysicsTestMotionResult3D.new())


func _unwedge(planned: Vector3, before: Vector3, delta: float) -> void:
	var wanted := Vector2(planned.x, planned.z)
	if not is_on_floor() or not is_on_wall() or wanted.length() < 0.0001:
		_wedged_for = 0.0
		return
	var moved := Vector2(global_position.x - before.x, global_position.z - before.z)
	if moved.length() >= wanted.length() * UNWEDGE_PROGRESS:
		_wedged_for = 0.0
		return

	_wedged_for += delta
	if _wedged_for < UNWEDGE_AFTER:
		return

	# Along the wall, not into it. Both tangents are valid; take the one that
	# keeps more of what the player asked for, so pushing left round a boulder
	# leaves you travelling left rather than doubling back.
	var normal := get_wall_normal()
	var tangent := Vector2(-normal.z, normal.x)
	if tangent.length() < 0.0001:
		_wedged_for = 0.0
		return
	tangent = tangent.normalized()
	if tangent.dot(wanted.normalized()) < 0.0:
		tangent = -tangent
	# A deflection must not walk you off anything. In the open this never
	# mattered; underground the body is in near-constant wall contact so this
	# fires continuously, and CI's smoke_warrens reported the player "2669.9m"
	# from the vault -- which is not short of it, that is a fall and a respawn
	# back at world spawn. Probe that the step lands on ground before steering.
	var side := Vector3(tangent.x, 0.0, tangent.y)
	if not _ground_under(side * DEFLECT_PROBE_M):
		_wedged_for = 0.0
		return
	_deflect = side
	_deflect_wanted = Vector3(wanted.x, 0.0, wanted.y).normalized()
	_deflect_left = DEFLECT_FOR
	_wedged_for = 0.0


## Step up small ledges instead of stopping dead against them.
##
## Godot 4's CharacterBody3D has no built-in step offset, and the gap has been
## a documented constraint since the loft bug: "a CharacterBody3D cannot step
## UP a ledge: run it across the stair head and the loft is a cell"
## (grandpa_house.gd, which shortened a beam rather than fix this). The
## owner's brief asked for the traversal audit that finally fixes it.
##
## Shape: only when grounded, moving, and pressed against a wall. Three probes
## through the physics server's own sweep (`test_move`), never a teleport into
## unchecked space: (1) headroom straight up by the step height, (2) forward at
## the raised height by this frame's motion, (3) back down onto the step. The
## landing must be walkable ground (normal within `floor_max_angle`), so a
## steep bank does not become climbable by being approached in 0.35m slices.
##
## STEP_HEIGHT is deliberately small. Kerbs, stair treads, bridge lips and
## rock shelves are in; every intentional barrier stays a barrier -- the
## terrain carves are 11m walls, the arena ring is code, and a fence rail is
## over a metre. TUNABLE, but raise it knowing every barrier in the game was
## sized against players who cannot climb.
const STEP_HEIGHT := 0.35
## Minimum forward advance of the step probe. Far enough past the lip that the
## landing contact is walkable (sin(0.25/0.4) = 38.7 degrees, inside the 45 the
## body accepts), small enough that a step never reads as a lunge. TUNABLE.
const STEP_FORWARD_PROBE := 0.25


func _try_step_up(motion: Vector3) -> void:
	if not is_on_wall() or not is_on_floor():
		return
	if motion.length() < 0.001:
		return

	# One frame of walk motion is ~7cm -- nowhere near enough to carry the
	# capsule's 0.4m-radius bottom OVER a ledge lip, so a frame-sized probe
	# lands on the edge at a wall-steep contact normal forever (measured: the
	# first version fired every frame and never once stepped). The probe
	# advances at least far enough that the landing contact sits inside the
	# capsule's walkable cone. The whole path is swept at the raised height
	# first, so this can never push the body through geometry.
	var probe := motion.normalized() * maxf(motion.length(), STEP_FORWARD_PROBE)
	var up := Vector3.UP * STEP_HEIGHT
	if test_move(global_transform, up):
		return
	var raised := global_transform.translated(up)
	if test_move(raised, probe):
		return
	var forward := raised.translated(probe)
	var drop := PhysicsTestMotionResult3D.new()
	var params := PhysicsTestMotionParameters3D.new()
	params.from = forward
	params.motion = Vector3.DOWN * STEP_HEIGHT
	if not PhysicsServer3D.body_test_motion(get_rid(), params, drop):
		return
	if drop.get_collision_normal().angle_to(Vector3.UP) > floor_max_angle:
		return
	global_position = forward.origin + Vector3.DOWN * drop.get_travel().length()
	# The step ate this frame's forward motion; killing the upward remnant of
	# the slide keeps the camera from popping.
	velocity.y = minf(velocity.y, 0.0)


## The player can become PERMANENTLY immobile in the open world. This is the
## failsafe for that, and it is the only thing in this file that ever moves the
## body somewhere it did not walk.
##
## MEASURED, not theorised. Gate F segment S05 logged 1,019 consecutive route
## rows -- over eight minutes -- at exactly (91.39, -6.00, 821.68), region
## `corridor`, `input_context: world`, with the heading column swinging through
## more than twenty distinct values across those rows. Heading only changes in
## `_face`, which only runs when `_apply_movement` resolved a non-zero
## direction: the stick was held the whole time and the body moved less than two
## centimetres. Two separate walks in that segment stopped at that identical
## coordinate, and the harness's own `selfcheck_walk` froze the same way at
## (-161.03, 2.13, 286.01) for its full 120s. Two sites is a class, not a one-
## off, and neither was recoverable without reloading the game.
##
## WHY `_unwedge` DOES NOT ALREADY COVER IT. `_unwedge` steers along ONE tangent
## of the wall normal, and gives up (`_wedged_for = 0.0`) the moment
## `_ground_under` says that one step is not clear. In a pocket whose contacts
## oppose, that tangent is into the opposite face, so the deflection is
## rejected every frame and the timer never survives to try anything else. It
## is the right tool for a boulder and has nothing left to offer a box.
##
## THE PREDICATE IS WHAT MAKES THIS SAFE. Time-without-progress alone would fire
## on a player leaning into a cliff, and teleporting them would be far worse
## than the bug. So no-progress only opens the question; `_entombed_at` decides
## it, by sweeping eight compass directions through the physics server from
## `STEP_HEIGHT` up -- the same height `_try_step_up` probes from, so ordinary
## ground never reads as a blocker. If ANY of the eight is clear the body can
## still walk out of wherever it is, and nothing happens. Only a body with no
## way out in any direction is recovered.
##
## RECOVERY REWINDS, IT DOES NOT INVENT. The first choice is always a breadcrumb
## -- ground this body stood on and walked away from -- so a recovery can never
## grant access to anywhere the player had not already legitimately reached.
## Lifting is the fallback for when there is no usable breadcrumb, and it is
## bounded by `lift_max_m`.
func _recover_if_entombed(delta: float) -> void:
	if not _unstick_enabled or _carried or not _locomotion_enabled:
		_stuck_for = 0.0
		_has_stuck_anchor = false
		return

	var here := global_position
	if not _has_stuck_anchor or here.distance_to(_stuck_anchor) > _unstick_progress_m:
		# Moving. This is also the only place breadcrumbs are dropped, so the
		# trail is by construction a list of places the body left under its own
		# power rather than places it merely occupied.
		_drop_breadcrumb(here)
		_stuck_anchor = here
		_stuck_for = 0.0
		_has_stuck_anchor = true
		return

	if _wanted_dir == Vector3.ZERO:
		# Standing still because nobody is asking for anything. Hold the anchor
		# (so letting go of the stick does not reset a real entombment that is
		# already being timed) but do not accumulate against it.
		return

	_stuck_for += delta
	if _stuck_for < _unstick_after:
		return
	_stuck_for = 0.0

	if not _entombed_at(global_transform):
		# Pressed against something, not sealed in it. Nothing to do -- this is
		# the branch a player walking into a cliff face takes, every time.
		return

	_unstick_count += 1
	var found := _recovery_position()
	if found.is_empty():
		push_warning("[player] entombed at %.2f, %.2f, %.2f with no recovery position" % [here.x, here.y, here.z])
		return
	var landing: Vector3 = found[0]
	print("[player] entombed at %.2f, %.2f, %.2f -- recovering to %.2f, %.2f, %.2f" % [
		here.x, here.y, here.z, landing.x, landing.y, landing.z
	])
	global_position = landing
	velocity = Vector3.ZERO
	_deflect_left = 0.0
	_wedged_for = 0.0
	_has_stuck_anchor = false
	_breadcrumbs.clear()


## Is there no way out of `from` in any direction?
##
## Swept through the physics server with this body's own shape, from
## `STEP_HEIGHT` up, so the answer is about the capsule that actually has to fit
## rather than a ray from its centre.
func _entombed_at(from: Transform3D) -> bool:
	var raised := from.translated(Vector3.UP * STEP_HEIGHT)
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var dir := Vector3(sin(angle), 0.0, cos(angle))
		if not test_move(raised, dir * _unstick_probe_m):
			return false
	return true


## Where to put a body that has no way out. One element, or empty if there is
## nowhere -- an Array rather than a nullable Vector3 because GDScript has no
## null Vector3 and a NaN sentinel is exactly the shape of bug this branch is
## here to remove.
##
## Newest breadcrumb first, so a recovery costs the player as little ground as
## it can while still landing clear of the pocket. `min_recovery_distance_m` is
## what stops it handing the body straight back to whatever swallowed it.
func _recovery_position() -> Array[Vector3]:
	var here := global_position
	for i in range(_breadcrumbs.size() - 1, -1, -1):
		var candidate: Vector3 = _breadcrumbs[i]
		if candidate.distance_to(here) < _unstick_min_distance_m:
			continue
		var at := global_transform
		at.origin = candidate
		if not _entombed_at(at):
			return [candidate] as Array[Vector3]

	# No usable breadcrumb: entombed within seconds of a load, or the trail is
	# all inside the same pocket. Rise until the eight-direction probe comes
	# back clear and let gravity do the rest.
	var lifted := 0.0
	while lifted < _unstick_lift_max_m:
		lifted += _unstick_lift_step_m
		var at := global_transform
		at.origin = here + Vector3.UP * lifted
		if not _entombed_at(at):
			return [at.origin] as Array[Vector3]
	return [] as Array[Vector3]


func _drop_breadcrumb(here: Vector3) -> void:
	if not is_on_floor():
		return
	if not _breadcrumbs.is_empty() and _breadcrumbs[-1].distance_to(here) < _breadcrumb_spacing_m:
		return
	_breadcrumbs.append(here)
	while _breadcrumbs.size() > _breadcrumb_count:
		_breadcrumbs.remove_at(0)


## How many times this body has had to be recovered. Read by
## tests/smoke_unstick.gd; a run that never touches it reads zero.
func unstick_count() -> int:
	return _unstick_count



func _track_airborne(delta: float, input_owned: bool) -> void:
	if is_on_floor():
		_airborne_for = 0.0
	else:
		_airborne_for += delta

	# A jump press swallowed while a panel owns input must not sit BUFFERED
	# either -- the buffer window (`_buffer_time`) would otherwise fire the
	# jump the instant the panel closed, the same leak one frame later.
	if not input_owned and Input.is_action_just_pressed("jump"):
		_jump_buffered_for = 0.0
	else:
		_jump_buffered_for += delta


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		# A small downward bias keeps the body pinned to slopes; without it the
		# character skips off the crest of every hill it walks over.
		velocity.y = -2.0
		return
	var scale := _fall_multiplier if velocity.y < 0.0 else 1.0
	velocity.y -= _gravity * scale * delta


## OP23-13 (owner playtest 2026-08-23): "Auto-run is needed." A toggle, not a
## hold — `is_action_just_pressed` flips `Game.auto_run` and writes it down,
## the same "gate on input_owned" discipline `jump`/movement already use so a
## menu open underneath can't also flip the toggle (see `_physics_process`'s
## own RG5 comment on that leak class).
func _toggle_auto_run(input_owned: bool) -> void:
	if input_owned or not Input.is_action_just_pressed("auto_run"):
		return
	var game := get_node_or_null(^"/root/Game")
	if game != null and game.has_method("set_auto_run"):
		game.call("set_auto_run", not bool(game.get("auto_run")))


func _apply_movement(delta: float, input_owned: bool) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if not _locomotion_enabled or input_owned:
		# Read as no input rather than skipped entirely, so the existing friction
		# brings the trainer to a stop instead of freezing them mid-stride.
		input = Vector2.ZERO
	var direction := Vector3.ZERO
	if input != Vector2.ZERO and _camera_rig != null and _camera_rig.has_method("planar_basis"):
		var basis_value: Basis = _camera_rig.call("planar_basis")
		direction = (basis_value * Vector3(input.x, 0.0, input.y)).normalized()

	# OF15: while a deflection is live, a held direction resolves ALONG the
	# obstacle instead of into it. Lapses as soon as the player stops pushing,
	# so it can never carry anyone somewhere they stopped asking to go.
	if _deflect_left > 0.0:
		if direction == Vector3.ZERO or direction.dot(_deflect_wanted) < 0.7:
			# Let go, or asked for somewhere meaningfully different. The
			# deflection was for the old request; it has no claim on this one.
			_deflect_left = 0.0
		else:
			_deflect_left -= delta
			direction = _deflect

	# The failsafe below reads this, not `input`: a deflection can be steering
	# while the raw stick reads the same, and what matters to it is whether the
	# body was asked to go anywhere at all this frame.
	_wanted_dir = direction

	var game := get_node_or_null(^"/root/Game")
	var auto_running := game != null and bool(game.get("auto_run"))
	var wants_run := Input.is_action_pressed("sprint") or auto_running
	_sprinting = wants_run and vitals.can_sprint() and input != Vector2.ZERO
	# D29: critical hunger softens ground speed a little; never below that,
	# and never enough on its own to strand the player.
	var target_speed: float = (_sprint_speed if _sprinting else _walk_speed) * vitals.move_speed_scale()

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var accel := _ground_accel if is_on_floor() else _air_accel

	if direction == Vector3.ZERO:
		# Friction only on the ground. Air-braking to a stop mid-jump is the
		# other half of what reads as "floaty".
		if is_on_floor():
			horizontal = horizontal.move_toward(Vector3.ZERO, _ground_friction * delta)
	else:
		horizontal = horizontal.move_toward(direction * target_speed, accel * delta)
		_face(direction, delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _face(direction: Vector3, delta: float) -> void:
	if _model == null:
		return
	var target_yaw := atan2(direction.x, direction.z)
	_model.rotation.y = rotate_toward(_model.rotation.y, target_yaw, _turn_speed * delta)


func _try_jump(input_owned: bool) -> void:
	if not _locomotion_enabled or input_owned:
		return
	var grounded_enough := is_on_floor() or _airborne_for <= _coyote_time
	var asked_recently := _jump_buffered_for <= _buffer_time
	if not (grounded_enough and asked_recently):
		return
	if not vitals.try_spend_jump():
		return
	velocity.y = _jump_velocity
	_jump_buffered_for = INF
	_airborne_for = _coyote_time + 1.0   # consume coyote so one press is one jump


## OP21-24. The body commits to the chop for the clip's OWN length, asked of
## `tool_hold.gd` rather than restated here -- the hard-coded 0.45 this used to
## pass was a second copy of a swing duration that lives in `art.json`, and it
## expired before the clip finished, so the trainer snapped back to idle
## mid-arc every chop.
func _on_tool_swing_started() -> void:
	if _model == null or not _model.has_method("play_tool_swing"):
		return
	var seconds := 0.45
	if tool_hold != null and tool_hold.has_method("swing_seconds"):
		seconds = float(tool_hold.call("swing_seconds"))
	_model.call("play_tool_swing", seconds)


func _resolve_landing(falling_speed: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		var damage: float = vitals.apply_landing(maxf(falling_speed, 0.0), _armor_defense())
		landed.emit(falling_speed, damage)
		if vitals.is_dead():
			died.emit()
	_was_on_floor = on_floor
	_fall_speed = falling_speed


## R7.7. `player_equipment.gd`'s own total_defense(), same lookup pattern
## tool_hold.gd already uses for `equipped_tool` -- a headless caller (a test,
## a capture tool with no Game autoload) reads 0.0, unarmoured, same as
## every fall-damage call before this task.
func _armor_defense() -> float:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return 0.0
	var equipment: Variant = game.get("player_equipment")
	return float(equipment.call("total_defense")) if equipment is RefCounted else 0.0


## Horizontal speed, read by the HUD and by trainer_model.gd's
## `_clip_for_state()` to pick idle/walk/sprint.
func ground_speed() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length()


func is_sprinting() -> bool:
	return _sprinting


## Suspend or restore walking and jumping. Called by the encounter director when
## a fight opens and closes; nothing here knows what combat is.
func set_locomotion_enabled(enabled: bool) -> void:
	_locomotion_enabled = enabled
	if not enabled:
		_jump_buffered_for = INF


func locomotion_enabled() -> bool:
	return _locomotion_enabled


## --- being carried (R6.1) ---------------------------------------------------

## Ride `node`, seated at `offset` in that node's local frame. Pass null to be
## put down again; the caller is responsible for where the body lands, because
## only it knows what there is to stand on beside whatever was carrying it.
##
## Physics layers are dropped while carried. A 0.4m capsule sitting inside a
## creature's capsule is two solid CharacterBody3Ds aimed at each other, which
## is the exact overlap that once launched the player off the playground at
## 500 m/s (encounter_director._spawn_ally_body's own comment) — and the reason
## `follower_creature.gd` already zeroes its layer while following.
func set_carrier(node: Node3D, offset: Vector3 = Vector3.ZERO) -> void:
	if node != null and not _carried:
		_carry_saved_layer = collision_layer
		_carry_saved_mask = collision_mask
		collision_layer = 0
		collision_mask = 0
	elif node == null and _carried:
		collision_layer = _carry_saved_layer
		collision_mask = _carry_saved_mask
	_carrier = node
	_carried = node != null
	_carry_offset = offset
	# The trainer's ART is hidden while carried, not the node: the torch is a
	# child of this body (scripts/player/torch.gd) and a rider who loses their
	# light at dusk because they got on a deer is a bug. Hiding is tied to the
	# carrier here, in ONE place, rather than left to the caller — that is what
	# makes "the player is never left invisible" an invariant of clearing the
	# carrier rather than a step somebody can forget on one of the exit paths.
	#
	# There is no seated pose in the trainer rig (M11's clips are idle/walk/
	# sprint/throw), so a visible standing trainer would ride the Meadowhart
	# standing bolt upright on its back. Hidden is the honest placeholder until
	# a sit clip exists; the mount offset is already authored for where the
	# rider belongs, so that swap is art, not code.
	if _model != null:
		_model.visible = node == null
	if node == null:
		# Nothing about the ride carries over into standing up: no leftover
		# velocity, no buffered jump from a button pressed in the saddle.
		velocity = Vector3.ZERO
		_jump_buffered_for = INF
		_was_on_floor = true
		_airborne_for = 0.0
		_sprinting = false


func carrier() -> Node3D:
	return _carrier if _carried else null


## Is the trainer's own art on screen? False only while carried. Read by
## tests/smoke_riding.gd, which exists mostly to prove this comes back true.
func rider_visible() -> bool:
	return _model == null or _model.visible


func is_carried() -> bool:
	return _carried


## Sit where the carrier says, and keep the trainer's own clocks running.
##
## STAMINA DECISION (R6.1): riding costs the PLAYER nothing and the mount has no
## stamina meter of its own. The honest reasons, in order — the trainer is
## sitting down, so a drain would be modelling exertion nobody is doing; a
## second stamina bar on the creature is a whole HUD element and a whole tuning
## problem for a system whose value (spec §3) is "revisiting known areas is less
## of a chore", which a meter that ends the ride directly undermines; and the
## creature's stamina is already spoken for by combat energy, which is a
## different resource with a different meaning. So the meter simply REGENERATES
## while mounted: `tick` is still called, with sprinting false, which is exactly
## what standing still does. Satiety still drains — riding is not a pause button
## on the day (D29).
func _ride(delta: float) -> void:
	if not is_instance_valid(_carrier):
		# The carrier was freed out from under us. Put the body back under its
		# own power immediately rather than following a dangling reference — it
		# stays exactly where it was, falls under gravity from the next frame,
		# and `riding_controller.gd` moves it somewhere sensible when it notices.
		set_carrier(null)
		return
	velocity = Vector3.ZERO
	global_position = _carrier.to_global(_carry_offset)
	# Face the way the mount faces, so dismounting does not spin the trainer.
	if _model != null:
		_model.global_rotation.y = _carrier.global_rotation.y
	_sprinting = false
	vitals.tick(delta, false)
	vitals.tick_satiety(delta)
