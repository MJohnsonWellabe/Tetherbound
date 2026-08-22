extends RefCounted

## RG19-spec / D68: what "rested, fed and happy" mean, in one file.
##
## The owner's tournament proposal gates entry on creature condition, and the
## backlog's own note on it is the reason it exists at all: condition is the
## mechanic that gives the five-creature cap and D29's satiety a reason to
## matter early. Both existed without pressure before this.
##
## Same split as `scripts/creatures/progression.gd` and
## `scripts/combat/combat_math.gd`: pure static functions over a creature
## instance and a config dictionary, no Node, no scene tree, headlessly
## testable (D02). Every number comes from
## `data/config/creature_condition.json` and every threshold is interpreted
## HERE and nowhere else -- 26-RG19's own rule is that the organizer's
## dialogue, the team screen and the tournament may not each carry a copy of
## what "well fed" means.
##
## Three states, three different verbs the opening already teaches:
##
## - RESTED is a bool the creature bed has owned since Gate A. Earned by
##   staying in a bed through the player's sleep; forfeited by waking early.
##   This file only adds an expiry and a faint-clears-it rule.
## - FED is `nourishment`, a 0..100 meter that drains on real time and is
##   restored by feeding an item that carries a `creature_food` block.
## - HAPPY is `happiness`, a 0..100 mood, raised by feeding, resting, winning
##   and levelling, lowered by drift, hunger and fainting.
##
## D29's light-hunger rule extends here: an empty nourishment meter makes a
## creature unhappy and tournament-ineligible. It never damages it and never
## kills it. There is no starvation death for creatures either.

const CONFIG_PATH := "res://data/config/creature_condition.json"

static var _config: Dictionary = {}


## The shipped creature_condition.json, cached after the first read. Same
## contract `progression.gd::config()` gives: a test that wants to pin a
## threshold passes its own dictionary in instead.
static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("creature_condition.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


# --- starting state ----------------------------------------------------------

## Put a newly caught/created creature at its configured starting condition.
##
## Called from `creature_instance.from_species()`, so every creature that
## enters the game -- caught, gifted, spawned by a fixture, rolled for a
## trainer -- starts somewhere honest instead of at a silent 0 (permanently
## starving) or a silent max (the mechanic never appears).
static func start(creature: RefCounted, cfg: Dictionary = {}) -> void:
	if creature == null:
		return
	var use := cfg if not cfg.is_empty() else config()
	creature.set("nourishment", _nourishment_start(use))
	creature.set("happiness", _happiness_start(use))
	creature.set("rested", false)
	creature.set("rested_seconds_left", 0.0)


# --- the clock ---------------------------------------------------------------

## One creature's condition, `delta` seconds later. Called for every party
## member from `game_state.gd::_process` -- benched creatures included, which
## is the point: a five that only the active companion feeds is a five in
## name only.
##
## Everything here is a no-op at `delta <= 0`, so a paused menu costs no
## nourishment and a test can tick a deliberate amount without a frame.
static func tick(creature: RefCounted, cfg: Dictionary, delta: float) -> void:
	if creature == null or delta <= 0.0:
		return
	var minutes := delta / 60.0
	var resting := bool(creature.get("resting"))

	var nourishment_cfg: Dictionary = cfg.get("nourishment", {})
	var drain := float(nourishment_cfg.get("drain_per_minute", 1.1)) * minutes
	if resting:
		drain *= float(nourishment_cfg.get("resting_drain_scale", 0.0))
	var maximum := _nourishment_max(cfg)
	creature.set("nourishment", clampf(float(creature.get("nourishment")) - drain, 0.0, maximum))

	var happiness_cfg: Dictionary = cfg.get("happiness", {})
	var drift := float(happiness_cfg.get("drift_per_minute", -0.15))
	if is_hungry(creature, cfg):
		drift += float(happiness_cfg.get("hungry_drift_per_minute", -0.6))
	_add_happiness(creature, cfg, drift * minutes)

	# Rest expiry runs only while awake: a creature still in its bed is not
	# spending rest it has not been given yet.
	if resting:
		return
	var left := float(creature.get("rested_seconds_left"))
	if left <= 0.0:
		return
	left -= delta
	creature.set("rested_seconds_left", maxf(left, 0.0))
	if left <= 0.0:
		creature.set("rested", false)


# --- the events that move it -------------------------------------------------

## Feed `creature` one use of a food item. `food` is an item definition's
## `creature_food` block: `{ nourishment: float, happiness: float }`.
##
## Returns what actually landed: `{ accepted, nourishment, happiness }`.
## `accepted` is false when the creature is already full and the food carries
## no happiness of its own, so a caller can refuse to spend the item rather
## than quietly eating it for nothing.
static func feed(creature: RefCounted, cfg: Dictionary, food: Dictionary) -> Dictionary:
	var refused := {"accepted": false, "nourishment": 0.0, "happiness": 0.0}
	if creature == null or food.is_empty():
		return refused
	var maximum := _nourishment_max(cfg)
	var before := clampf(float(creature.get("nourishment")), 0.0, maximum)
	var after := clampf(before + float(food.get("nourishment", 0.0)), 0.0, maximum)
	var gained := after - before
	var mood := float(food.get("happiness", float(cfg.get("happiness", {}).get("on_feed", 8.0))))
	if gained <= 0.0 and mood <= 0.0:
		return refused
	creature.set("nourishment", after)
	return {"accepted": true, "nourishment": gained,
		"happiness": _add_happiness(creature, cfg, mood)}


## A night in a creature bed completed. `game_state.complete_creature_bed_rests()`
## already sets `rested` itself; this starts the expiry clock and pays the
## mood, so the bed does not need to know the numbers.
static func note_rest_completed(creature: RefCounted, cfg: Dictionary) -> void:
	if creature == null:
		return
	creature.set("rested", true)
	creature.set("rested_seconds_left", _rested_seconds(cfg))
	_add_happiness(creature, cfg, float(cfg.get("happiness", {}).get("on_rest_completed", 12.0)))


## This creature helped win a fight -- the cheapest honest source of happiness
## in the game, and the one tournament preparation produces naturally.
static func note_victory(creature: RefCounted, cfg: Dictionary) -> void:
	if creature == null or bool(creature.get("fainted")):
		return
	_add_happiness(creature, cfg, float(cfg.get("happiness", {}).get("on_victory", 5.0)))


static func note_level_up(creature: RefCounted, cfg: Dictionary) -> void:
	if creature == null:
		return
	_add_happiness(creature, cfg, float(cfg.get("happiness", {}).get("on_level_up", 6.0)))


## This creature was knocked out. Costs mood, and -- unless the config says
## otherwise -- spends its rest: a creature carried off the field is not one
## anybody would describe as well rested.
static func note_faint(creature: RefCounted, cfg: Dictionary) -> void:
	if creature == null:
		return
	_add_happiness(creature, cfg, float(cfg.get("happiness", {}).get("on_faint", -12.0)))
	if bool(cfg.get("rest", {}).get("clear_on_faint", true)):
		creature.set("rested", false)
		creature.set("rested_seconds_left", 0.0)


# --- the questions the gate and the UI ask ------------------------------------

static func nourishment_fraction(creature: RefCounted, cfg: Dictionary) -> float:
	if creature == null:
		return 0.0
	var maximum := _nourishment_max(cfg)
	return clampf(float(creature.get("nourishment")) / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0


static func happiness_fraction(creature: RefCounted, cfg: Dictionary) -> float:
	if creature == null:
		return 0.0
	var maximum := _happiness_max(cfg)
	return clampf(float(creature.get("happiness")) / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0


static func is_fed(creature: RefCounted, cfg: Dictionary) -> bool:
	return nourishment_fraction(creature, cfg) \
		>= float(cfg.get("nourishment", {}).get("fed_at", 0.55))


static func is_hungry(creature: RefCounted, cfg: Dictionary) -> bool:
	return nourishment_fraction(creature, cfg) \
		< float(cfg.get("nourishment", {}).get("hungry_below", 0.3))


static func is_happy(creature: RefCounted, cfg: Dictionary) -> bool:
	return happiness_fraction(creature, cfg) \
		>= float(cfg.get("happiness", {}).get("happy_at", 0.6))


static func is_rested(creature: RefCounted, _cfg: Dictionary = {}) -> bool:
	return creature != null and bool(creature.get("rested"))


## Whether this creature is in a state to be entered into the tournament, and
## why not when it is not. `{ ready, rested, fed, happy, fainted, reasons }`,
## where `reasons` are short player-facing phrases naming what to go and fix.
static func summary(creature: RefCounted, cfg: Dictionary) -> Dictionary:
	var rested := is_rested(creature, cfg)
	var fed := is_fed(creature, cfg)
	var happy := is_happy(creature, cfg)
	var fainted := creature != null and bool(creature.get("fainted"))
	var reasons: Array[String] = []
	if fainted:
		reasons.append("needs reviving")
	if not rested:
		reasons.append("needs a night in a creature bed")
	if not fed:
		reasons.append("needs feeding")
	if not happy:
		reasons.append("is unhappy")
	return {
		"ready": rested and fed and happy and not fainted,
		"rested": rested, "fed": fed, "happy": happy, "fainted": fainted,
		"nourishment": nourishment_fraction(creature, cfg),
		"happiness": happiness_fraction(creature, cfg),
		"reasons": reasons,
	}


## One short line for a team row: "Rested · Fed · Happy", with the failing
## halves NAMED rather than omitted, because a gate the player cannot read is
## a gate they cannot act on.
static func label(creature: RefCounted, cfg: Dictionary) -> String:
	var state := summary(creature, cfg)
	var parts: Array[String] = []
	parts.append("Rested" if bool(state["rested"]) else "Tired")
	if bool(state["fed"]):
		parts.append("Fed")
	else:
		parts.append("Hungry" if is_hungry(creature, cfg) else "Peckish")
	parts.append("Happy" if bool(state["happy"]) else "Restless")
	return " · ".join(parts)


# --- internals ---------------------------------------------------------------

static func _add_happiness(creature: RefCounted, cfg: Dictionary, amount: float) -> float:
	if creature == null or is_zero_approx(amount):
		return 0.0
	var maximum := _happiness_max(cfg)
	var before := clampf(float(creature.get("happiness")), 0.0, maximum)
	var after := clampf(before + amount, 0.0, maximum)
	creature.set("happiness", after)
	return after - before


static func _nourishment_max(cfg: Dictionary) -> float:
	return maxf(float(cfg.get("nourishment", {}).get("max", 100.0)), 0.0)


static func _happiness_max(cfg: Dictionary) -> float:
	return maxf(float(cfg.get("happiness", {}).get("max", 100.0)), 0.0)


static func _nourishment_start(cfg: Dictionary) -> float:
	return clampf(float(cfg.get("nourishment", {}).get("start", 70.0)), 0.0, _nourishment_max(cfg))


static func _happiness_start(cfg: Dictionary) -> float:
	return clampf(float(cfg.get("happiness", {}).get("start", 55.0)), 0.0, _happiness_max(cfg))


static func _rested_seconds(cfg: Dictionary) -> float:
	return maxf(float(cfg.get("rest", {}).get("stays_rested_minutes", 45.0)), 0.0) * 60.0
