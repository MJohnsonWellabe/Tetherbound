extends Node3D

## A torch, carried from the first frame of the game.
##
## Owner playtest report: night was too dark to play comfortably, and the fix
## must not be "the player discovers that in the dark and then has to craft a
## torch" -- it has to already be there. So this is not an inventory item with
## a recipe; it is a fixed part of the trainer's kit, the same way the belt
## and the starting orbs are, created and attached the moment player_controller
## stands up (see player_controller.gd::_ready()).
##
## Two ways it turns on, per data/config/movement.json's `torch` block:
##   - automatically, the instant world_look.gd's is_dark() goes true
##     (`auto_at_night`) -- covers "available immediately" with zero input,
##     so a player who never touches the control still is not left in the
##     dark.
##   - manually, via the `torch_toggle` action (L / gamepad Start) -- an
##     explicit override that wins over the automatic behaviour until toggled
##     again, for a player who wants it on before dusk or off at night.
##
## The SpotLight3D throw stays a SpotLight3D: a torch lights the ground ahead
## of you, not a sphere around your whole body, and D06's own renderer caveat
## (Compatibility, not Forward+) is exactly why this stays unshadowed and
## modest in energy -- a shadow-casting light glued to the player at all times
## is the wrong place to spend a handheld's frame budget.
##
## OF24, owner clarification after seeing this SpotLight and nothing else:
## "what I was really talking about is one you carry around to light the
## way" -- the owner had never actually SEEN a torch, because nothing here
## drew one. `_build_visible_prop()` below adds the actual prop
## (scripts/world/torch_prop.gd -- D24: built from primitives, no vendored
## torch mesh exists anywhere in assets/) bone-attached to the trainer rig,
## plus a warm, flickering OmniLight3D that reads as the light genuinely
## coming FROM that prop. The SpotLight above stays exactly as it was, "the
## forward throw" this file's own history already argued for.

const CONFIG_PATH := "res://data/config/movement.json"
const ARBITER_NODE := preload("res://scripts/world/interaction_arbiter.gd")
const TORCH_PROP_SCENE := "res://assets/props/built/torch_prop.tscn"

var _light: SpotLight3D = null
var _auto_at_night: bool = true
var _manual_override: bool = false
var _manual_on: bool = false
var _world_look: Node = null
var _arbiter: Node = null

## The visible prop (scripts/world/torch_prop.gd) and its own point light --
## see `_build_visible_prop()`. `_prop_root` is whatever the prop actually
## got parented under (a `BoneAttachment3D` on the rig, or a plain fallback
## node) so both the prop and the light can be positioned there without
## re-deriving that choice twice.
var _prop_root: Node3D = null
var _prop: Node3D = null
var _omni: OmniLight3D = null
var _prop_bone: String = "Hips"
var _flicker_base_energy: float = 0.0
var _flicker_amount: float = 0.0
var _flicker_speed: float = 0.0
var _flicker_time: float = 0.0


func _ready() -> void:
	var cfg := _load_config()
	_auto_at_night = bool(cfg.get("auto_at_night", true))
	_prop_bone = str(cfg.get("prop_bone", "Hips"))

	_light = SpotLight3D.new()
	_light.name = "TorchLight"
	_light.light_color = Color(str(cfg.get("colour", "#ffb366")))
	_light.spot_range = float(cfg.get("range_m", 9.0))
	_light.spot_angle = float(cfg.get("spot_angle_deg", 46.0))
	_light.light_energy = float(cfg.get("energy", 3.2))
	_light.spot_attenuation = float(cfg.get("attenuation", 1.4))
	_light.shadow_enabled = bool(cfg.get("shadows", false))
	_light.visible = false
	add_child(_light)

	position = Vector3(0.0, float(cfg.get("height", 1.3)), float(cfg.get("forward_offset", 0.35)))
	rotation = Vector3(deg_to_rad(float(cfg.get("pitch_deg", -35.0))), 0.0, 0.0)

	_world_look = get_tree().get_first_node_in_group(&"day_cycle")
	_build_visible_prop(cfg)


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	return (parsed as Dictionary).get("torch", {}) as Dictionary


## OF25: `L` is also a letter. Without this, typing an "l" while naming a
## creature toggled the torch under the panel. Looked up lazily (not cached
## once in `_ready()`) because `torch.gd` is built in code from
## `player_controller._ready()` and can run before the arbiter's own
## `_ready()` has added it to its group -- a caller that only tried once could
## permanently miss it. Reuses the arbiter's `enabled` flag, the same one
## `sequence_director._refresh_lockout` already clears for a conversation, the
## naming prompt or the starter picker, rather than a second copy of "is
## something modal open" invented here.
func _world_input_suppressed() -> bool:
	if _arbiter == null or not is_instance_valid(_arbiter):
		_arbiter = get_tree().get_first_node_in_group(ARBITER_NODE.GROUP)
	return _arbiter != null and is_instance_valid(_arbiter) and not bool(_arbiter.call("enabled"))


## Bone-attaches the visible prop to the trainer rig's `Hips` (TUNABLE via
## `prop_bone`) rather than a hand: `RightHand` is where the `throw` clip
## lives (creature-catching), and a torch riding the hand doing the throwing
## would swing through that pose every time. Hips stays a fixed offset from
## the pelvis across idle/walk/sprint/jump/throw alike -- reads as a torch
## carried at the belt, the "hip-mounted" option OF24's own brief offered as
## the fallback the rig actually supports cleanly.
##
## Falls back to a fixed offset off the player root (no bone, no swing to
## avoid, so a plain upright pose near chest height) when no `Model`/skeleton
## is reachable -- an isolated test rig or a stripped-down capture scene --
## so the prop is never silently absent for want of a rig to hang it on.
func _build_visible_prop(cfg: Dictionary) -> void:
	if not ResourceLoader.exists(TORCH_PROP_SCENE):
		push_warning("torch prop scene missing: %s" % TORCH_PROP_SCENE)
		return
	var scene: PackedScene = load(TORCH_PROP_SCENE)
	_prop = scene.instantiate() as Node3D
	if _prop == null:
		return

	var skeleton := _find_player_skeleton()
	var offset: Vector3
	var rot_deg: Vector3
	if skeleton != null and skeleton.find_bone(_prop_bone) >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.name = "TorchAttachment"
		attachment.bone_name = _prop_bone
		skeleton.add_child(attachment)
		_prop_root = attachment
		offset = _vector3_from(cfg.get("prop_offset", [0.14, -0.05, 0.06]))
		rot_deg = _vector3_from(cfg.get("prop_rotation_deg", [0.0, 20.0, 26.0]))
	else:
		_prop_root = get_parent() if get_parent() != null else self
		offset = Vector3(0.30, -0.35, 0.10)
		rot_deg = Vector3(0.0, 20.0, 16.0)

	_prop_root.add_child(_prop)
	_prop.position = offset
	_prop.rotation_degrees = rot_deg
	_prop.visible = false

	_omni = OmniLight3D.new()
	_omni.name = "TorchOmni"
	_omni.light_color = Color(str(cfg.get("colour", "#ffb366")))
	_flicker_base_energy = float(cfg.get("omni_energy", 1.6))
	_omni.light_energy = _flicker_base_energy
	_omni.omni_range = float(cfg.get("omni_range", 6.0))
	_omni.shadow_enabled = false
	_omni.visible = false
	_flicker_amount = clampf(float(cfg.get("flicker_amount", 0.35)), 0.0, 1.0)
	_flicker_speed = float(cfg.get("flicker_speed", 9.0))

	var flame_local: Vector3 = _prop.call("flame_local_position") if _prop.has_method("flame_local_position") else Vector3.ZERO
	_prop_root.add_child(_omni)
	_omni.position = offset + flame_local


## `character_model.gd::skeleton()` off the player's own `Model` child --
## null for anything that has no such rig (see `_build_visible_prop`'s own
## fallback for what happens then).
func _find_player_skeleton() -> Skeleton3D:
	var parent := get_parent()
	if parent == null:
		return null
	var model := parent.get_node_or_null(^"Model")
	if model == null or not model.has_method("skeleton"):
		return null
	return model.call("skeleton") as Skeleton3D


func _vector3_from(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() == 3:
		var a: Array = raw
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO


func _process(delta: float) -> void:
	if not _world_input_suppressed() and Input.is_action_just_pressed(&"torch_toggle"):
		_manual_override = true
		_manual_on = not _is_on()
	var on := _is_on()
	if _light != null:
		_light.visible = on
	if _prop != null:
		_prop.visible = on
	if _omni != null:
		_omni.visible = on
		if on and _flicker_amount > 0.0:
			# Two out-of-phase sine terms rather than one -- a single sine
			# flicker reads as a strobe/pulse (mechanical, regular); summing a
			# slow and a fast term with an odd phase offset is the same cheap
			# trick a real flame's irregularity gets approximated with
			# without reaching for actual noise sampling for a light this
			# minor.
			_flicker_time += delta
			var noise := sin(_flicker_time * _flicker_speed) * 0.6 \
				+ sin(_flicker_time * _flicker_speed * 2.7 + 1.3) * 0.4
			_omni.light_energy = _flicker_base_energy * (1.0 + noise * _flicker_amount)


func _is_on() -> bool:
	if _manual_override:
		return _manual_on
	if not _auto_at_night:
		return false
	return _world_look != null and _world_look.has_method("is_dark") and bool(_world_look.call("is_dark"))


## For the HUD prompt and tests -- whether the torch is currently lit, by
## either mechanism above.
func is_on() -> bool:
	return _is_on()


## The visible prop node, or null if none was built (see
## `_build_visible_prop`'s own early-return on a missing scene). Public so a
## smoke test can assert "a lit torch is a visible PROP, not just a light"
## without reaching past this node into a private field.
func prop_node() -> Node3D:
	return _prop
