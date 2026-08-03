extends RefCounted

## Stamina, health and fall damage, with no dependency on the scene tree.
##
## Kept free of Node so it can be tested headlessly. Everything here is pure
## arithmetic over its own state: give it the same inputs and it produces the
## same outputs, with no physics, no input and no rendering involved. That is
## the whole of what docs/decisions/D02-test-harness.md says tests cover, and
## the reason this file exists separately from player_controller.gd.
##
## GAME_DESIGN.md §18: stamina is spent by movement and world actions. There is
## no starvation meter and food is a buff system, so nothing here drains on its
## own over time.

var max_stamina: float = 100.0
var max_health: float = 100.0

var stamina: float = 100.0
var health: float = 100.0

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


func configure(config: Dictionary) -> void:
	var stamina_cfg: Dictionary = config.get("stamina", {})
	max_stamina = float(stamina_cfg.get("max", 100.0))
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
		stamina = minf(max_stamina, stamina + _regen * delta)

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


## Apply a landing. Returns the damage dealt, so the caller can react (screen
## shake, a sound) without recomputing it.
func apply_landing(impact_speed: float) -> float:
	var damage := fall_damage_for(impact_speed)
	if damage > 0.0:
		health = maxf(0.0, health - damage)
	return damage


func is_dead() -> bool:
	return health <= 0.0


func stamina_fraction() -> float:
	return 0.0 if max_stamina <= 0.0 else clampf(stamina / max_stamina, 0.0, 1.0)


func health_fraction() -> float:
	return 0.0 if max_health <= 0.0 else clampf(health / max_health, 0.0, 1.0)
