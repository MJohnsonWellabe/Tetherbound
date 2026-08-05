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
##
## FOOD, ADDED IN M9, IS A BONUS AND NEVER A PENALTY. `eat()` raises the two
## ceilings and the regeneration for a while; when the meal runs out the numbers
## return to exactly what they were before it. There is no state below "has eaten
## nothing", nothing counts down towards one, and the words hunger, satiation and
## starving do not appear in this file. CLAUDE.md makes that a hard rule and lists
## mandatory hunger among the decisions an agent may not take on its own.

## The trainer's own numbers, before anything they ate. `max_health` and
## `max_stamina` below are these plus whatever is currently in effect, which is
## why these are what `configure()` writes and nothing else does.
var base_max_stamina: float = 100.0
var base_max_health: float = 100.0

## What the meters are actually measured against right now. Read by the HUD, by
## `*_fraction()` and by every clamp here.
##
## Properties rather than plain fields so that a caller cannot be holding a stale
## maximum from before the last bite, and so that adding a buff is one place
## rather than a fan-out of "and also update max_health".
var max_stamina: float:
	get:
		return base_max_stamina + _bonus("max_stamina")
var max_health: float:
	get:
		return base_max_health + _bonus("max_health")

var stamina: float = 100.0
var health: float = 100.0

## Meals in effect. One entry per item id — eating the same thing twice refreshes
## its timer instead of stacking a second copy of its bonus, which is the only
## honest reading of "a berry's worth of vigour" and the only one that cannot be
## turned into an infinite ceiling by holding a full stack.
var _food: Array[Dictionary] = []

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
	base_max_stamina = float(stamina_cfg.get("max", 100.0))
	_sprint_drain = float(stamina_cfg.get("sprint_drain_per_second", 12.0))
	_jump_cost = float(stamina_cfg.get("jump_cost", 8.0))
	_regen = float(stamina_cfg.get("regen_per_second", 18.0))
	_regen_delay = float(stamina_cfg.get("regen_delay", 1.1))
	_exhausted_below = float(stamina_cfg.get("exhausted_below", 10.0))

	var health_cfg: Dictionary = config.get("health", {})
	base_max_health = float(health_cfg.get("max", 100.0))

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
	# Meals first, so a bonus that ends this frame has ended before the meters are
	# clamped against the ceiling it was holding up.
	_tick_food(delta)

	if sprinting:
		_spend(_sprint_drain * delta)
	elif _regen_cooldown > 0.0:
		_regen_cooldown = maxf(0.0, _regen_cooldown - delta)
	else:
		stamina = minf(max_stamina, stamina + (_regen + _bonus("stamina_regen")) * delta)

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
	return take_damage(fall_damage_for(impact_speed))


## Damage from anything at all. Returns how much was actually taken, which is
## less than asked for when it would have gone below zero and nothing when the
## player is already down.
##
## Falling was the only thing in the game that could hurt the trainer until M6.
## It is no longer: `GAME_DESIGN.md` §14's trainer-safety rule holds while the
## player has a pal that can fight, and the owner has amended it for the case
## where they do not — a trainer with every pal fainted is a target in the world.
## See `encounter_director.Hunt`.
##
## The trainer STILL CANNOT FIGHT BACK. This is a function that takes damage, and
## there is deliberately no counterpart anywhere that deals it on the human's
## behalf: CLAUDE.md's "human cannot fight" is untouched, and the amendment is
## that the trainer can be hurt, not that they can hurt anything.
##
## No armour term. §18's equipment slots are M9's, and when they land the
## reduction belongs on the way in — here — rather than at each of the places
## that can hurt you.
func take_damage(amount: float) -> float:
	if amount <= 0.0 or health <= 0.0:
		return 0.0
	var before := health
	health = maxf(0.0, health - amount)
	return before - health


func is_dead() -> bool:
	return health <= 0.0


func stamina_fraction() -> float:
	return 0.0 if max_stamina <= 0.0 else clampf(stamina / max_stamina, 0.0, 1.0)


func health_fraction() -> float:
	return 0.0 if max_health <= 0.0 else clampf(health / max_health, 0.0, 1.0)


## Back on your feet after dying. §22 takes the player's carried items and their
## position; it takes nothing off their meters that a night's sleep would not fix,
## so this is a fraction of maximum rather than a penalty that accumulates.
##
## Meals are cleared. A buff eaten before the fight should not outlive the fight
## killing you, and a respawn that kept them would make eating first free.
func revive(health_at: float = 1.0, stamina_at: float = 1.0) -> void:
	clear_food()
	health = base_max_health * clampf(health_at, 0.01, 1.0)
	stamina = base_max_stamina * clampf(stamina_at, 0.0, 1.0)
	_regen_cooldown = 0.0
	_exhausted = false


## --- food -----------------------------------------------------------------
##
## GAME_DESIGN.md §18, in full: "Valheim-like buff philosophy: No starvation
## death. Eating improves health/stamina/regeneration or other preparation
## stats." Three bonuses, therefore, and a clock — and NOTHING on the other side
## of zero. A trainer who never eats has exactly the numbers in movement.json,
## forever, and is never told off for it.
##
## No instant heal. Food raises the ceiling and the climb rate and lets the
## trainer walk up to it; a meal that healed on the spot is a potion, and a potion
## is drunk at 5 HP rather than eaten before setting out, which is the opposite of
## the preparation §18 is describing.

## What one meal is worth, as bonuses. `seconds` is already scaled by the caller.
const FOOD_BONUSES := ["max_health", "max_stamina", "stamina_regen"]


## Eat something. `block` is the item's `food` definition from
## data/items/consumables.json; this file does not read item data itself, so a
## test can hand it a meal that is not in any JSON.
##
## Returns false for a block with no duration — an item that is not food, or one
## whose data is wrong. Refusing rather than applying a zero-second buff keeps
## "nothing happened" out of the UI's vocabulary.
func eat(item_id: String, block: Dictionary, seconds_scale: float = 1.0) -> bool:
	var seconds := float(block.get("seconds", 0.0)) * maxf(0.0, seconds_scale)
	if seconds <= 0.0:
		return false
	var meal: Dictionary = {"item": item_id, "seconds": seconds, "left": seconds}
	for key: String in FOOD_BONUSES:
		meal[key] = float(block.get(key, 0.0))

	var existing := _food_index(item_id)
	if existing >= 0:
		# REFRESHED, not stacked. Eating a second berry while the first is still in
		# effect resets the clock; it does not give twice the bonus, because a full
		# stack of thirty would otherwise be a ceiling with no top.
		_food[existing] = meal
	else:
		_food.append(meal)
	return true


## Every meal in effect, newest last: `{item, seconds, left, max_health,
## max_stamina, stamina_regen}`. Copies, so a HUD cannot edit the buff it draws.
func food_buffs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for meal in _food:
		out.append(meal.duplicate())
	return out


func is_fed() -> bool:
	return not _food.is_empty()


func food_seconds_left(item_id: String) -> float:
	var at := _food_index(item_id)
	return 0.0 if at < 0 else float(_food[at]["left"])


func clear_food() -> void:
	if _food.is_empty():
		return
	_food.clear()
	_clamp_to_maximums()


func _food_index(item_id: String) -> int:
	for i in _food.size():
		if str(_food[i]["item"]) == item_id:
			return i
	return -1


func _bonus(key: String) -> float:
	var total := 0.0
	for meal in _food:
		total += float(meal.get(key, 0.0))
	return total


func _tick_food(delta: float) -> void:
	if _food.is_empty():
		return
	var kept: Array[Dictionary] = []
	var expired := false
	for meal in _food:
		meal["left"] = float(meal["left"]) - delta
		if float(meal["left"]) > 0.0:
			kept.append(meal)
		else:
			expired = true
	_food = kept
	if expired:
		_clamp_to_maximums()


## A meal ending must not leave the meters above their own ceiling.
##
## Health is clamped DOWN rather than left at 112/100, which would read as a bar
## overflowing its frame, and it never clamps below 1: a buff running out is not
## allowed to kill the trainer. Losing the last point of health to a berry timer
## is a death nobody could explain, and §18 gives food no downside at all.
func _clamp_to_maximums() -> void:
	if health > max_health:
		health = maxf(1.0, max_health)
	stamina = minf(stamina, max_stamina)


## --- persistence ----------------------------------------------------------
##
## The meters and the meals, as a Dictionary for whoever owns the trainer's save
## domain. No path and no version of its own: `autoload/save_manager.gd` keeps ONE
## envelope for the whole game (D14) and this is a payload inside somebody's.

func to_record() -> Dictionary:
	return {
		"health": health,
		"stamina": stamina,
		"food": food_buffs(),
	}


func from_record(record: Dictionary) -> void:
	_food.clear()
	for entry: Variant in record.get("food", []):
		if not entry is Dictionary:
			continue
		var meal: Dictionary = (entry as Dictionary).duplicate()
		# A meal with no time left is dropped rather than restored at zero, and one
		# whose bonuses are missing restores as no bonus. A save file is a text file
		# that will eventually be hand-edited; one bad meal is not worth the save.
		if float(meal.get("left", 0.0)) <= 0.0:
			continue
		meal["item"] = str(meal.get("item", ""))
		for key: String in FOOD_BONUSES:
			meal[key] = float(meal.get(key, 0.0))
		_food.append(meal)
	# After the meals, so the ceilings they hold up are already in place — a
	# trainer saved at 108/108 health under a berry must not come back on 100.
	health = clampf(float(record.get("health", health)), 0.0, max_health)
	stamina = clampf(float(record.get("stamina", stamina)), 0.0, max_stamina)
