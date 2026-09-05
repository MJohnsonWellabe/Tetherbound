extends RefCounted

## Stamina, health, satiety and fall damage, with no dependency on the scene
## tree.
##
## Kept free of Node so it can be tested headlessly. Everything here is pure
## arithmetic over its own state: give it the same inputs and it produces the
## same outputs, with no physics, no input and no rendering involved. That is
## the whole of what docs/decisions/D02-test-harness.md says tests cover, and
## the reason this file exists separately from player_controller.gd.
##
## GAME_DESIGN.md §18: stamina is spent by movement and world actions, and
## health only moves on a landing. D29 adds satiety, the light hunger meter:
## it drains slowly and on its own, over real time, and food restores it plus
## grants a temporary buff. Low satiety softens the player with mild debuffs —
## slower stamina regen, then slightly slower movement once critical — and
## never kills. There is no starvation death here and there must never be one
## added under a "tuning" pretext; that is a design decision, not a number.
## Stamina and health remain exactly as before: they do not decay on their own.

var max_stamina: float = 100.0
var _base_max_stamina: float = 100.0
var max_health: float = 100.0
var max_satiety: float = 100.0

var stamina: float = 100.0
var health: float = 100.0
var satiety: float = 100.0

## Active food buffs. Each entry is `{ "id": String, "stat": String,
## "amount": float, "remaining_s": float }`. `stat` names what the buff
## multiplies (currently "stamina_regen_scale" or "move_speed_scale"); a
## second eat of the same `id` refreshes `remaining_s` rather than stacking.
var active_buffs: Array[Dictionary] = []

var _sprint_drain: float = 12.0
var _jump_cost: float = 8.0
var _regen: float = 18.0
var _regen_delay: float = 1.1
var _exhausted_below: float = 10.0

var _fall_safe_speed: float = 12.0
var _fall_lethal_speed: float = 34.0
var _fall_curve: float = 2.0
var _fall_max_damage: float = 100.0

## Seconds remaining before stamina begins recovering.
var _regen_cooldown: float = 0.0
## Latches once stamina bottoms out, and clears only above `_exhausted_below`.
## Without it, a player can tap sprint at zero stamina and keep the sprint speed
## while the meter flickers.
var _exhausted: bool = false

var _satiety_drain_per_minute: float = 0.8
var _hungry_below: float = 0.35
var _critical_below: float = 0.15
var _hungry_stamina_regen_scale: float = 0.6
var _critical_stamina_regen_scale: float = 0.35
var _critical_move_speed_scale: float = 0.92


func configure(config: Dictionary) -> void:
	var stamina_cfg: Dictionary = config.get("stamina", {})
	_base_max_stamina = float(stamina_cfg.get("max", 100.0))
	max_stamina = _base_max_stamina
	_sprint_drain = float(stamina_cfg.get("sprint_drain_per_second", 12.0))
	_jump_cost = float(stamina_cfg.get("jump_cost", 8.0))
	_regen = float(stamina_cfg.get("regen_per_second", 18.0))
	_regen_delay = float(stamina_cfg.get("regen_delay", 1.1))
	_exhausted_below = float(stamina_cfg.get("exhausted_below", 10.0))

	var health_cfg: Dictionary = config.get("health", {})
	max_health = float(health_cfg.get("max", 100.0))

	var fall_cfg: Dictionary = config.get("fall_damage", {})
	_fall_safe_speed = float(fall_cfg.get("safe_speed", 12.0))
	_fall_lethal_speed = float(fall_cfg.get("lethal_speed", 34.0))
	_fall_curve = float(fall_cfg.get("curve", 2.0))
	_fall_max_damage = float(fall_cfg.get("max_damage", 100.0))

	stamina = max_stamina
	health = max_health


## Recompute capacity from the authored baseline, never from the already-
## modified value.  Preserving fill fraction makes equip/unequip deterministic
## and prevents swapping a Heart from becoming a free stamina refill.
func set_stamina_capacity_multiplier(multiplier: float) -> void:
	var fraction := stamina_fraction()
	max_stamina = _base_max_stamina * maxf(1.0, multiplier)
	stamina = max_stamina * fraction


## D29. Kept separate from configure() so movement.json stays the sole owner
## of stamina/health/fall/jump tuning and data/config/vitals.json owns
## satiety on its own; pass it the whole parsed vitals.json.
func configure_satiety(config: Dictionary) -> void:
	var satiety_cfg: Dictionary = config.get("satiety", {})
	max_satiety = float(satiety_cfg.get("max", 100.0))
	_satiety_drain_per_minute = float(satiety_cfg.get("drain_per_minute", 0.8))
	_hungry_below = float(satiety_cfg.get("hungry_below", 0.35))
	_critical_below = float(satiety_cfg.get("critical_below", 0.15))

	var debuffs: Dictionary = satiety_cfg.get("debuffs", {})
	var hungry_cfg: Dictionary = debuffs.get("hungry", {})
	_hungry_stamina_regen_scale = float(hungry_cfg.get("stamina_regen_scale", 0.6))
	var critical_cfg: Dictionary = debuffs.get("critical", {})
	_critical_stamina_regen_scale = float(critical_cfg.get("stamina_regen_scale", 0.35))
	_critical_move_speed_scale = float(critical_cfg.get("move_speed_scale", 0.92))

	satiety = max_satiety
	active_buffs.clear()


## A night's sleep: everything back to full. Called by the camp's rest.
func rest() -> void:
	stamina = max_stamina
	health = max_health
	satiety = max_satiety
	_exhausted = false


## True when the player has enough stamina to start or continue sprinting.
func can_sprint() -> bool:
	return not _exhausted and stamina > 0.0


## Advance one frame. `sprinting` should be what the player is ACTUALLY doing,
## not what they asked for; the caller resolves that with can_sprint().
func tick(delta: float, sprinting: bool) -> void:
	if sprinting:
		_spend(_sprint_drain * delta)
	elif _regen_cooldown > 0.0:
		_regen_cooldown = maxf(0.0, _regen_cooldown - delta)
	else:
		# D29: hunger and food buffs scale how fast stamina comes back, never
		# whether it does.
		stamina = minf(max_stamina, stamina + _regen * stamina_regen_scale() * delta)

	if _exhausted and stamina >= _exhausted_below:
		_exhausted = false


## Spend for a jump. Returns false and spends nothing if there is not enough,
## so the caller can refuse the jump rather than allowing a negative meter.
func try_spend_jump() -> bool:
	if stamina < _jump_cost:
		return false
	_spend(_jump_cost)
	return true


func _spend(amount: float) -> void:
	stamina = maxf(0.0, stamina - amount)
	_regen_cooldown = _regen_delay
	if stamina <= 0.0:
		_exhausted = true


## Damage for landing at `impact_speed` metres/second downward.
##
## Driven by speed rather than by fall distance so a landing costs the same
## however the player got moving. Below safe_speed it is free; above
## lethal_speed it is capped at max_damage.
func fall_damage_for(impact_speed: float) -> float:
	if impact_speed <= _fall_safe_speed:
		return 0.0
	var span := _fall_lethal_speed - _fall_safe_speed
	if span <= 0.0:
		return _fall_max_damage
	var t := clampf((impact_speed - _fall_safe_speed) / span, 0.0, 1.0)
	return pow(t, _fall_curve) * _fall_max_damage


## Apply a landing. `defense` is R7.7's armour fraction (0..1,
## player_equipment.gd::total_defense()) — 0.0 (the default) is the pre-R7.7
## behaviour, unchanged for every existing caller. Returns the damage
## actually dealt (post-armour), so the caller can react (screen shake, a
## sound) without recomputing it.
func apply_landing(impact_speed: float, defense: float = 0.0) -> float:
	var damage := fall_damage_for(impact_speed) * (1.0 - clampf(defense, 0.0, 1.0))
	if damage > 0.0:
		health = maxf(0.0, health - damage)
	return damage


func is_dead() -> bool:
	return health <= 0.0


func stamina_fraction() -> float:
	return 0.0 if max_stamina <= 0.0 else clampf(stamina / max_stamina, 0.0, 1.0)


func health_fraction() -> float:
	return 0.0 if max_health <= 0.0 else clampf(health / max_health, 0.0, 1.0)


func satiety_fraction() -> float:
	return 0.0 if max_satiety <= 0.0 else clampf(satiety / max_satiety, 0.0, 1.0)


## "ok" / "hungry" / "critical", by the thresholds in vitals.json. Never
## anything else, and never a reason to die.
func hunger_state() -> String:
	var frac := satiety_fraction()
	if frac < _critical_below:
		return "critical"
	if frac < _hungry_below:
		return "hungry"
	return "ok"


## Restore satiety (clamped to max) and, if `buff` is non-empty, add or
## refresh a food buff. `buff` is the item data's own `{ "id", "stat",
## "amount", "duration_s" }` dictionary — eating the same food again refreshes
## the timer instead of stacking a second copy.
func eat(satiety_amount: float, buff: Dictionary = {}) -> void:
	satiety = clampf(satiety + satiety_amount, 0.0, max_satiety)
	if not buff.is_empty():
		_apply_buff(buff)


func _apply_buff(buff: Dictionary) -> void:
	var id: String = String(buff.get("id", ""))
	var entry := {
		"id": id,
		"stat": String(buff.get("stat", "")),
		"amount": float(buff.get("amount", 1.0)),
		"remaining_s": float(buff.get("duration_s", 0.0)),
	}
	for existing: Dictionary in active_buffs:
		if existing["id"] == id:
			existing["stat"] = entry["stat"]
			existing["amount"] = entry["amount"]
			existing["remaining_s"] = entry["remaining_s"]
			return
	active_buffs.append(entry)


## Drain satiety by real time and age out expired buffs. Called every physics
## frame alongside tick(); split out because satiety has nothing to do with
## sprinting or jumping, the things tick() is actually about.
func tick_satiety(delta: float) -> void:
	var drain := (_satiety_drain_per_minute / 60.0) * delta
	satiety = maxf(0.0, satiety - drain)

	var i := active_buffs.size() - 1
	while i >= 0:
		var buff: Dictionary = active_buffs[i]
		buff["remaining_s"] = float(buff["remaining_s"]) - delta
		if float(buff["remaining_s"]) <= 0.0:
			active_buffs.remove_at(i)
		i -= 1


## Multiplier on stamina regeneration: the hungry/critical debuff tier, then
## any active buff naming "stamina_regen_scale". 1.0 when fed and unbuffed.
func stamina_regen_scale() -> float:
	var scale := 1.0
	match hunger_state():
		"hungry":
			scale *= _hungry_stamina_regen_scale
		"critical":
			scale *= _critical_stamina_regen_scale
	for buff: Dictionary in active_buffs:
		if buff["stat"] == "stamina_regen_scale":
			scale *= float(buff["amount"])
	return scale


## Multiplier on ground move speed: only critical hunger slows the player
## down (hungry alone does not), then any active "move_speed_scale" buff.
func move_speed_scale() -> float:
	var scale := 1.0
	if hunger_state() == "critical":
		scale *= _critical_move_speed_scale
	for buff: Dictionary in active_buffs:
		if buff["stat"] == "move_speed_scale":
			scale *= float(buff["amount"])
	return scale
