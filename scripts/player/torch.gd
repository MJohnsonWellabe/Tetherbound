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
## The light itself is a SpotLight3D rather than an OmniLight3D: a torch lights
## the ground ahead of you, not a sphere around your whole body, and D06's own
## renderer caveat (Compatibility, not Forward+) is exactly why this stays
## unshadowed and modest in energy -- a shadow-casting light glued to the
## player at all times is the wrong place to spend a handheld's frame budget.

const CONFIG_PATH := "res://data/config/movement.json"
const ARBITER_NODE := preload("res://scripts/world/interaction_arbiter.gd")

var _light: SpotLight3D = null
var _auto_at_night: bool = true
var _manual_override: bool = false
var _manual_on: bool = false
var _world_look: Node = null
var _arbiter: Node = null


func _ready() -> void:
	var cfg := _load_config()
	_auto_at_night = bool(cfg.get("auto_at_night", true))

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


func _process(_delta: float) -> void:
	if not _world_input_suppressed() and Input.is_action_just_pressed(&"torch_toggle"):
		_manual_override = true
		_manual_on = not _is_on()
	if _light != null:
		_light.visible = _is_on()


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
