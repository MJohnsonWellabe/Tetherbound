extends RefCounted

const MATH := preload("res://scripts/combat/combat_math.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TYPES := preload("res://scripts/combat/type_chart.gd")

## Pure conservative bound from the SAME rolled_damage used by production.
## Include either wind state and a possible stagger critical during windup.
## Never consumes RNG, wind, critical readiness, or HP.
static func upper_bound(power: float, attack: float, defence: float,
		move_power: float, type_mult: float) -> float:
	var config := MATH.config()
	var wind: Dictionary = config.get("wind", {})
	var poise: Dictionary = config.get("poise", {})
	var strongest_power := power * maxf(1.0, float(wind.get("exhausted_power_scale", 0.6)))
	var rolled := maxf(MATH.rolled_damage(strongest_power, attack, defence, 0.0, move_power, type_mult),
		MATH.rolled_damage(strongest_power, attack, defence, 1.0, move_power, type_mult))
	return rolled * maxf(1.0, float(poise.get("crit_scale", 1.5)))


static func decision(hp: float, max_hp: float, upper: float, floor_fraction: float) -> Dictionary:
	if not is_finite(hp) or not is_finite(max_hp) or not is_finite(upper) \
			or not is_finite(floor_fraction) or hp <= 0.0 or max_hp <= 0.0 or upper <= 0.0 \
			or floor_fraction < 0.0 or floor_fraction >= 1.0:
		return {"ok": false, "safe": false, "why": "invalid live HP/damage/floor readback"}
	var floor_hp := max_hp * floor_fraction
	return {"ok": true, "safe": hp - upper > floor_hp, "hp": hp,
		"upper_damage": upper, "floor_hp": floor_hp,
		"why": "next quick hit must leave HP strictly above the authored floor"}


## Call immediately before EVERY physical quick tap, including the first.
## A not-ready result is a wait/re-observe decision, never permission to queue
## another attack behind an unresolved one. This guard covers solo authority.
static func observe(manager: Node, floor_fraction: float = 0.01) -> Dictionary:
	if not is_instance_valid(manager) or not bool(manager.call("is_fighting")):
		return {"ok": false, "safe": false, "why": "no live encounter"}
	if manager.get("_encounter_link") != null:
		return {"ok": false, "safe": false, "why": "hosted damage requires host-authoritative card readback"}
	var pilot: RefCounted = manager.call("active_creature")
	var foe: RefCounted = manager.call("enemy")
	var moves: RefCounted = manager.get("_moves")
	if pilot == null or foe == null or moves == null or float(pilot.get("hp")) <= 0.0:
		return {"ok": false, "safe": false, "why": "live pilot/foe/move database unavailable"}
	if not bool(manager.call("quick_ready")) or not str(manager.get("_buffered_attack")).is_empty():
		return {"ok": true, "safe": false, "ready": false,
			"why": "wait for outstanding attack/cooldown, then re-read HP before input"}
	var move_id := str(pilot.get("move_quick"))
	var cfg := PROGRESSION.config()
	var power := float((MATH.config().get("player_quick", {}) as Dictionary).get("power", 9.0))
	var attack := float(pilot.call("effective_attack", cfg))
	var defence := float(foe.call("effective_defence", cfg))
	var move_power := float(moves.call("power", move_id))
	var type_mult := TYPES.multiplier_dual(str(moves.call("type_of", move_id)),
		str(foe.get("creature_type")), str(foe.get("secondary_type")))
	var result := decision(float(foe.get("hp")), float(foe.get("max_hp")),
		upper_bound(power, attack, defence, move_power, type_mult), floor_fraction)
	result.ready = true
	result.move_id = move_id
	result.attack = attack
	result.defence = defence
	result.move_power = move_power
	result.type_mult = type_mult
	return result
