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

var _player: CharacterBody3D = null
## Set while the trainer is aiming a throw, so the body reads as throwing rather
## than as standing still watching its creature be hit.
var _throwing_for: float = 0.0
## movement.json's `gait_feel` block (MQ1A, TUNABLE) — momentum-tilt limits for
## character_model.gd's apply_momentum_tilt(). Read once at ready.
var _gait_feel: Dictionary = {}


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	_gait_feel = _load_gait_feel()
	if not build("trainer"):
		# The scene's capsule stays visible, so a missing trainer is a trainer
		# that looks wrong rather than a trainer who is not there.
		push_error("no trainer model; falling back to the placeholder capsule")


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
	_throwing_for = maxf(0.0, _throwing_for - delta)
	# OF8's other exit from the bed: `sequence_director.gd` clears lying on
	# the "Get up" prompt, but its own soft-lock fallback (`smoke_wake_
	# softlock.gd`) lets the player just walk off the mattress instead, and
	# that beat change only fires once they cross a 3.2m radius. Without this,
	# the body would keep sliding across the floor in the flat bed pose for
	# every metre of that radius. Speed alone, not `is_on_floor()`: the
	# trainer isn't reliably grounded the instant it starts moving off a
	# raised mattress, and the thing that actually means "getting up now" is
	# the player asking to move, not where physics has settled them yet.
	if is_lying() and float(_player.call("ground_speed")) > 0.4:
		set_lying(false)
	# Only the throw is a committed one-shot (timed by _throwing_for); idle,
	# walk, sprint and jump are all states the trainer can hold indefinitely
	# and must loop — see character_model.gd's play() for why that matters.
	var role := _role_for_state()
	play(_clip_for_role(role), _throwing_for <= 0.0)
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
		"jump":
			return clip_for("jump")
		_:
			return clip_for(role, role)


## Called when a throw is released, so the body commits to the animation for its
## duration rather than for exactly one frame.
func play_throw(seconds: float = 0.6) -> void:
	_throwing_for = seconds
