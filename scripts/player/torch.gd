extends Node3D

## The torch's light -- SpotLight throw plus a flickering OmniLight -- on
## whenever the torch is the equipped tool.
##
## History: OF24 made the torch an always-on kit fixture, built and attached
## unconditionally the moment player_controller stood up, deliberately NOT an
## inventory item -- "the fix must not be 'the player discovers that in the
## dark and then has to craft a torch'". OW12 (owner, 2026-08-16: "torches
## need to be a carry able item not placeable one") supersedes that: the torch
## is now `data/items/items.json`'s own `torch` entry, `kind: "tool"`,
## equipped off the hotbar/backpack exactly like an axe or pickaxe, and its
## MESH reaches the trainer's hand through `scripts/player/tool_hold.gd`'s
## existing generic `held_model`/`held_offset`/`held_rotation_deg` pattern --
## not a second hand-attachment system built here. (OW12 also retired OF24's
## placeable ground torch, `data/items/buildables.json`'s old `torch` entry;
## that file's own `_comment_free` records the reversal.)
##
## This node's whole remaining job is the LIGHT tool_hold.gd does not know
## how to draw: the same SpotLight forward-throw and OmniLight flame-glow OF24
## built, now gated on `GameState.equipped_tool == "torch"` rather than
## always on. Two ways it turns on, once equipped, per
## data/config/movement.json's `torch` block:
##   - automatically, the instant world_look.gd's is_dark() goes true
##     (`auto_at_night`)
##   - manually, via the `torch_toggle` action (L / gamepad Start), an
##     override that wins until toggled again
## An unequipped torch is an inert satchel row, the same as an unequipped axe
## -- neither of the above does anything until the torch is actually in hand.
##
## The SpotLight3D throw stays a SpotLight3D: a torch lights the ground ahead
## of you, not a sphere around your whole body, and D06's own renderer caveat
## (Compatibility, not Forward+) is exactly why this stays unshadowed and
## modest in energy -- a shadow-casting light glued to the player at all times
## is the wrong place to spend a handheld's frame budget.

const CONFIG_PATH := "res://data/config/movement.json"
const ARBITER_NODE := preload("res://scripts/world/interaction_arbiter.gd")
const ITEM_ID := "torch"

var _light: SpotLight3D = null
var _auto_at_night: bool = true
var _manual_override: bool = false
var _manual_on: bool = false
var _world_look: Node = null
var _arbiter: Node = null
var _game: Node = null

## The trainer's `ToolHold` sibling (scripts/player/tool_hold.gd), whose
## `prop_node()` is wherever the equipped torch mesh actually lives. Looked up
## lazily, not cached once in `_ready()`, the same reason `_arbiter` below is:
## player_controller.gd builds `Torch` before it builds `ToolHold`
## (player_controller.gd::_ready()), so a lookup made once at THIS node's own
## `_ready()` would permanently miss its sibling.
var _tool_hold: Node = null

## The prop's own warm point light -- see `_process()`, which keeps it synced
## to wherever `_tool_hold.prop_node()` currently sits so the glow reads as
## coming from the mesh in the trainer's hand rather than from a fixed point
## on the chest.
var _omni: OmniLight3D = null
var _flicker_base_energy: float = 0.0
var _flicker_amount: float = 0.0
var _flicker_speed: float = 0.0
var _flicker_time: float = 0.0


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
	_game = get_node_or_null(^"/root/Game")

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
	add_child(_omni)


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


## Lazily resolves the `ToolHold` sibling -- see the field's own comment for
## why this cannot be a one-time `_ready()` lookup.
func _find_tool_hold() -> Node:
	if _tool_hold != null and is_instance_valid(_tool_hold):
		return _tool_hold
	var parent := get_parent()
	if parent == null:
		return null
	_tool_hold = parent.get_node_or_null(^"ToolHold")
	return _tool_hold


func _is_equipped() -> bool:
	if _game == null or not is_instance_valid(_game):
		_game = get_node_or_null(^"/root/Game")
	return _game != null and str(_game.get("equipped_tool")) == ITEM_ID


func _process(delta: float) -> void:
	if not _world_input_suppressed() and Input.is_action_just_pressed(&"torch_toggle"):
		_manual_override = true
		_manual_on = not _is_on()
	var on := _is_on()
	if _light != null:
		_light.visible = on
	if _omni != null:
		_omni.visible = on
		if on:
			# Track wherever tool_hold.gd actually put the equipped torch mesh
			# so the glow reads as coming from the prop in hand, not a fixed
			# point on the chest. Left wherever it last was if the prop is not
			# built yet (e.g. the equip and this light landed in the same
			# frame) rather than snapping to the origin.
			var prop := prop_node()
			if prop != null:
				_omni.global_position = prop.global_position
			if _flicker_amount > 0.0:
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
	if not _is_equipped():
		return false
	if _manual_override:
		return _manual_on
	if not _auto_at_night:
		return false
	return _world_look != null and _world_look.has_method("is_dark") and bool(_world_look.call("is_dark"))


## For the HUD prompt and tests -- whether the torch is currently lit, by
## either mechanism above. Always false while the torch is not the equipped
## tool, per this file's own header.
func is_on() -> bool:
	return _is_on()


## The visible mesh, drawn by `scripts/player/tool_hold.gd` when the torch is
## the equipped tool -- null whenever it is not (tool_hold.gd has nothing to
## draw) or the trainer has no `ToolHold` sibling (a stripped-down test rig).
## Public for the reason it always was: a smoke test needs to assert "a lit
## torch is a visible PROP, not just a light" without reaching past this node
## into a private field on a DIFFERENT node.
func prop_node() -> Node3D:
	if not _is_equipped():
		return null
	var hold := _find_tool_hold()
	if hold == null or not hold.has_method("prop_node"):
		return null
	return hold.call("prop_node") as Node3D
