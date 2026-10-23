extends RefCounted

## BOSSES §4.11: Captain Nerissa's side-channel sweeps, as pure rules. The
## Heart Chamber controller (water_nerissa_channels.gd) feeds the current
## send-out, whether a creature tell is running and the creatures' positions;
## everything here is deterministic and node-free so its timing and damage
## rules are unit-tested directly. Positions are 2D, relative to the fight
## ring's centre: x across the chamber (lane side), y along it.
##
## One wave: announce (the tell) -> active (strikes once) -> drain -> gap.
## Channel Cycle (Cannonback, Mirejaw) and Pressure Rise (Riverdrake) differ
## only in cadence and side alternation; Riptusk fights without sweeps.

const CONFIG_PATH := "res://data/config/water_nerissa_channels.json"
static var _config: Dictionary = {}

var config: Dictionary
var state := "off"
var side := 0
var serial := 0
var _left := 0.0
var _send_out := -1
var _phase := ""
var _waves_in_phase := 0
## A creature tell ran while this wave was announced or active: it may not
## force a combo, so the wave strikes nobody.
var overlapped := false
## Ids exempted at the announce by the full-tell exit test.
var exempt: Dictionary = {}


static func load_config() -> Dictionary:
	if _config.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if parsed is Dictionary:
			_config = parsed
	return _config


func _init(cfg: Dictionary = {}) -> void:
	config = cfg if not cfg.is_empty() else load_config()


static func phase_for(cfg: Dictionary, send_out: int) -> String:
	var phases: Dictionary = cfg.get("phases", {})
	for name: String in ["channel_cycle", "pressure_rise"]:
		var row: Dictionary = phases.get(name, {})
		if send_out in (row.get("send_outs", []) as Array).map(func(v: Variant) -> int: return int(v)):
			return name
	return ""


func phase() -> String:
	return _phase


func _row() -> Dictionary:
	return (config.get("phases", {}) as Dictionary).get(_phase, {})


## A new opponent is out. Sweeps restart from a quiet entry beat; a send-out
## with no phase (Riptusk) switches them off.
func set_send_out(index: int) -> void:
	if index == _send_out:
		return
	_send_out = index
	var next := phase_for(config, index)
	if next != _phase:
		_waves_in_phase = 0
	_phase = next
	exempt.clear()
	overlapped = false
	if _phase.is_empty():
		state = "off"
		_left = 0.0
		return
	state = "idle"
	_left = float(config.get("first_wave_delay_s", 3.0))


## True when a creature at `local` (relative to the ring centre) stands in
## `lane_side`'s channel (-1 left, +1 right).
func in_lane(local: Vector2, lane_side: int) -> bool:
	var lane: Dictionary = config.get("lane", {})
	var across := local.x * float(lane_side)
	return across >= float(lane.get("inner_m", 2.6)) and across <= float(lane.get("outer_m", 8.6)) \
		and absf(local.y) <= float(lane.get("half_length_m", 12.0))


## BOSSES §4.11 full-tell exit test: from `local`, can a creature at
## escape_speed leave the announced lane before the tell ends? The inner edge
## (toward the ring centre) is always a legal exit; the outer edge only when
## `outer_legal` (it is not against a wall).
func can_escape(local: Vector2, lane_side: int, outer_legal: bool = true) -> bool:
	if not in_lane(local, lane_side):
		return true
	var lane: Dictionary = config.get("lane", {})
	var across := local.x * float(lane_side)
	var distance := across - float(lane.get("inner_m", 2.6))
	if outer_legal:
		distance = minf(distance, float(lane.get("outer_m", 8.6)) - across)
	distance = minf(distance, float(lane.get("half_length_m", 12.0)) - absf(local.y))
	return distance <= float(config.get("escape_speed_mps", 5.6)) * float(_row().get("announce_s", 1.2))


## Advance by `delta`. `tell_active`: a creature tell is running now.
## `ally_local`: the side reference for the first wave of a phase.
## `creatures`: {id: Vector2 local} for the exit test at announce.
## Returns the transition this step made: "", "announce", "fire", "drain", "idle".
func advance(delta: float, tell_active: bool, ally_local: Vector2 = Vector2.ZERO,
		creatures: Dictionary = {}, outer_legal: Dictionary = {}) -> String:
	if state == "off":
		return ""
	if state in ["announce", "active"] and tell_active:
		overlapped = true
	_left -= maxf(0.0, delta)
	if _left > 0.0:
		return ""
	match state:
		"idle":
			# Never start a wave over a creature tell (BOSSES §4.11).
			if tell_active:
				_left = 0.0
				return ""
			_begin_wave(ally_local, creatures, outer_legal)
			return "announce"
		"announce":
			state = "active"
			_left = float(_row().get("active_s", 0.8))
			return "fire"
		"active":
			state = "drain"
			_left = float(_row().get("drain_s", 1.6))
			return "drain"
		"drain":
			state = "idle"
			_left = float(config.get("gap_s", 1.4))
			return "idle"
	return ""


func _begin_wave(ally_local: Vector2, creatures: Dictionary, outer_legal: Dictionary) -> void:
	var alternate := bool(_row().get("alternate_sides", false))
	if _waves_in_phase == 0 or not alternate:
		side = 1 if ally_local.x >= 0.0 else -1
	else:
		side = -side
	_waves_in_phase += 1
	serial += 1
	overlapped = false
	exempt.clear()
	for id: Variant in creatures:
		if not can_escape(creatures[id], side, bool(outer_legal.get(id, true))):
			exempt[id] = true
	state = "announce"
	_left = float(_row().get("announce_s", 1.2))


## Damage the active wave deals to a creature at `local` with `max_hp`, once
## per wave (the caller calls this once, at "fire"). 0 when the wave overlapped
## a creature tell, the creature was exempted at the announce, or it is clear.
func damage_for(id: Variant, local: Vector2, max_hp: float) -> float:
	if state != "active" or overlapped or exempt.has(id) or not in_lane(local, side):
		return 0.0
	return maxf(0.0, max_hp) * clampf(float(config.get("damage_max_health_fraction", 0.1)), 0.0, 0.1)


## The synced presentation state a client mirrors.
func snapshot() -> Dictionary:
	return {"state": state, "side": side, "serial": serial, "phase": _phase, "left": _left}
