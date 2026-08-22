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
##   - manually, via the `torch_toggle` action (L; keyboard only since
##     CONTROLLER-MAP made the torch a hotbar tool with no pad button) -- an
##     explicit override that wins over the automatic behaviour until toggled
##     again, for a player who wants it on before dusk or off at night.
##
## Both are gated on the torch actually being the EQUIPPED tool (RG22 below) --
## an unequipped torch is an inert satchel row, same as an unequipped axe.
##
## The SpotLight3D throw stays a SpotLight3D: a torch lights the ground ahead
## of you, not a sphere around your whole body, and D06's own renderer caveat
## (Compatibility, not Forward+) is exactly why this stays unshadowed and
## modest in energy -- a shadow-casting light glued to the player at all times
## is the wrong place to spend a handheld's frame budget.
##
## RG22, owner directive: "The torch doesn't go in your hand like a axe does.
## It should." OW12 (2026-08-16) made the torch a satchel item, `kind: "tool"`
## like axe/pickaxe/knife, meant to reach the hand through `tool_hold.gd`'s
## generic hand-attachment (`items.json`'s `held_model`/`held_offset`/
## `held_rotation_deg` on the `torch` entry) the exact way a tool does -- and
## `tool_hold.gd`'s own header already claimed this file had been "retired" in
## favour of that. It had not: `_build_visible_prop()` below still built and
## bone-attached its OWN SEPARATE copy of the torch prop to the rig's `Hips`,
## unconditionally, whether or not the torch was ever equipped -- a torch
## permanently strapped to the belt, invisible only because `_process()`
## toggled `.visible` on the WRONG object while `equipped_tool` was never even
## read. `tool_hold.gd` was quietly building a second, correct, in-hand copy
## the whole time (its own smoke check found a prop named "TorchProp" and
## passed -- against the hip one, since both instance the same scene under the
## same name). This file now owns only the light: a flame position synced
## every frame to wherever `tool_hold.gd::prop_node()` says the in-hand mesh
## actually is, and nothing lights at all unless the torch is truly equipped
## -- see `_is_equipped()`.
##
## RG22 also asked the torch to "light up a little more" -- brightness values
## are `NIGHT-LIGHT`'s lane (coordinating on `ralph/NOTES.md`), not touched
## here.

const CONFIG_PATH := "res://data/config/movement.json"
const ARBITER_NODE := preload("res://scripts/world/interaction_arbiter.gd")

var _light: SpotLight3D = null
var _auto_at_night: bool = true
var _manual_override: bool = false
var _manual_on: bool = false
var _world_look: Node = null
var _arbiter: Node = null
var _tool_hold: Node = null

## The flicker, still owned here -- see the header on why the PROP moved to
## `tool_hold.gd` but the light stayed.
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
	# A child of THIS node so it travels with the scene tree normally, but
	# positioned in global space every frame (`_sync_flame_position`) rather
	# than at a fixed local offset -- there is no fixed offset that makes
	# sense any more, since the thing it has to track (`tool_hold.gd`'s prop)
	# is rebuilt from scratch by a different system on every equip change.
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


## `player_controller.gd`'s own `tool_hold` child -- looked up lazily and
## re-checked with `is_instance_valid`, the same OF25-established pattern
## `_world_input_suppressed()` above uses for `_arbiter`, for the identical
## reason: this node can run before a sibling's own `_ready()` if node order
## ever shifts, and a one-shot `_ready()`-time lookup has already cost this
## file one silently-dead feature (OF18).
func _tool_hold_node() -> Node:
	if _tool_hold == null or not is_instance_valid(_tool_hold):
		var parent := get_parent()
		_tool_hold = parent.get("tool_hold") if parent != null else null
	return _tool_hold


## RG22: nothing lights, manual or automatic, unless the torch is genuinely
## the equipped tool -- OW12's own design ("an unequipped torch is an inert
## satchel row, same as an unequipped axe"), which this file never actually
## enforced until now.
func _is_equipped() -> bool:
	var hold := _tool_hold_node()
	return hold != null and str(hold.call("equipped")) == "torch"


## The in-hand torch prop `tool_hold.gd` built for the equipped torch, or
## null when the torch is not equipped (nothing there to point a light at)
## or carries no `held_model` at all.
func _hand_prop() -> Node3D:
	if not _is_equipped():
		return null
	var hold := _tool_hold_node()
	return hold.call("prop_node") as Node3D


## Keeps the flame-light glued to wherever the in-hand prop actually is, every
## frame -- the prop itself is rebuilt by `tool_hold.gd` on every equip
## change (queue_free + a fresh instance), so there is no fixed local offset
## to parent under any more. `global_position`, not `position`: this node's
## own transform is a fixed chest-height offset for the SpotLight above, and
## the two lights no longer share a common local space.
func _sync_flame_position(prop: Node3D) -> void:
	if prop == null:
		return
	var flame_local: Vector3 = prop.call("flame_local_position") if prop.has_method("flame_local_position") else Vector3.ZERO
	_omni.global_position = prop.global_transform * flame_local


func _process(delta: float) -> void:
	if not _world_input_suppressed() and Input.is_action_just_pressed(&"torch_toggle"):
		_manual_override = true
		_manual_on = not _is_on()
	var on := _is_on()
	if _light != null:
		_light.visible = on
	var prop := _hand_prop() if on else null
	if _omni != null:
		_omni.visible = on and prop != null
		if on and prop != null:
			_sync_flame_position(prop)
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
	# OF18-found: this used to be looked up once in `_ready()`, the same
	# frame `player_controller.gd::_ready()` builds this node -- and the
	# Player node sits BEFORE WorldLook in every playground scene's own
	# tree (meadows_playground.tscn), so `_ready()` here always ran before
	# `world_look.gd::_ready()` had added itself to the "day_cycle" group.
	# `_world_look` cached null permanently, every run, and the auto-at-
	# night feature this whole file exists for (see the header: "the fix
	# must not be... it has to already be there") silently never fired --
	# caught by tools/capture_torch_night.gd printing `is_on() == false`
	# at night with zero difference in frame luminance across every shot.
	# `_world_input_suppressed()` right below already lazy-looks-up
	# `_arbiter` for exactly this class of ordering race; this now does
	# the same instead of trusting a one-shot `_ready()`-time lookup.
	if _world_look == null or not is_instance_valid(_world_look):
		_world_look = get_tree().get_first_node_in_group(&"day_cycle")
	return _world_look != null and _world_look.has_method("is_dark") and bool(_world_look.call("is_dark"))


## For the HUD prompt and tests -- whether the torch is currently lit, by
## either mechanism above.
func is_on() -> bool:
	return _is_on()


## The visible prop node, or null if the torch is not currently equipped (see
## `_hand_prop()`). Public so a smoke test can assert "a lit torch is a
## visible PROP, not just a light" without reaching past this node into a
## private field -- unchanged contract from before RG22, only the node it
## actually returns changed (the real in-hand prop, not a hip-mounted
## duplicate).
func prop_node() -> Node3D:
	return _hand_prop()
