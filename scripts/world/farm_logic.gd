extends RefCounted

## What one farm plot is doing, and what changes it.
##
## R7.6's berry loop is preserved. RD-05 / HOMESTEAD §5.3 adds eight type
## crops and a Greenhouse gate, using the same manual plant/wait/pick cycle.
## There is no irrigation, fertiliser, soil quality or automatic harvest.
## These rules only stage detached results; the host ledger owns seed costs,
## plot revisions and inventory payouts together. A client cannot commit one
## of these candidates by itself.
##
## Pure and node-free on purpose (docs/decisions/D02): `scripts/world/
## farm_plot.gd` is the Node3D that draws a plot and offers its prompt, and
## every rule about what a plot may do next lives here where
## `tests/test_farming.gd` can pin it without booting a world. Same split
## `day_cycle.gd`/`world_look.gd` and `harvest_logic.gd`/`harvest_node.gd`
## already use.
##
## ## The plot is a Dictionary, not a class
##
## `{"state": "sown", "ripe_on_day": 4}` -- three states plus one integer, and
## that is the whole of it. A Dictionary because this is also exactly what
## `autoload/game_state.gd::farm_plots` saves and `scripts/save/save_game.gd`
## writes to disk, and R3.1's `placed_buildings` already set the rule that
## world state the player made is a plain JSON-shaped Array of Dictionaries
## independent of whatever node currently renders it.
##
## ## Why the clock is `Game.day` and not seconds
##
## The done-when is "harvest berries from it on a LATER DAY", and the day
## counter (`game_state.gd::day`, advanced by `scripts/build/camp.gd`'s rest)
## is the only clock in this project that means a day. `world_look.gd`'s
## `_elapsed_seconds` is a 600-second art cycle that wraps and is snapped
## backwards by every camp rest -- a crop timed off it would ripen four times
## between two sleeps and go backwards when the player rested.

## Unworked ground. Needs the hoe.
const FALLOW := "fallow"
## Worked soil, empty. Needs seeds.
const TILLED := "tilled"
## Sown and growing. Needs the day to advance.
const SOWN := "sown"
## Ready to pick, bare-handed.
const RIPE := "ripe"

## The verbs a plot can offer, or "" for a plot the player cannot act on yet.
const ACTION_TILL := "till"
const ACTION_SOW := "sow"
const ACTION_HARVEST := "harvest"
const ACTION_NONE := ""

## The tool that turns fallow ground into a seedbed.
##
## docs/decisions/D50: this is the ONLY thing the hoe gates. Sowing and picking
## are both bare-handed, and `berries` keeps no `gathered_with` entry in
## data/items/items.json -- see that file's own line 9 note, which records
## berries as the one resource that is never tool-gated, and D50 for why
## farming did not change it.
const TILL_TOOL := "hoe"

## What a plot with no saved state is.
static func fresh() -> Dictionary:
	return {"state": FALLOW, "ripe_on_day": 0}


## A saved plot, cleaned up. Anything unrecognised comes back fallow rather
## than erroring: a save written by a future build that grew a fifth state
## should cost the player a re-till, not a broken farm.
static func sanitised(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return fresh()
	var plot := value as Dictionary
	var state := str(plot.get("state", FALLOW))
	if not [FALLOW, TILLED, SOWN, RIPE].has(state):
		return fresh()
	var clean := {"state": state, "ripe_on_day": int(plot.get("ripe_on_day", 0))}
	# Older berry plots remain byte-shaped as before. A typed plot must keep
	# its selected crop across ripening, save/load and rejoin reconciliation.
	if plot.get("crop_id") is String and not str(plot["crop_id"]).is_empty():
		clean["crop_id"] = str(plot["crop_id"])
	if plot.has("planted_on_day"):
		clean["planted_on_day"] = int(plot["planted_on_day"])
	if plot.has("revision"):
		clean["revision"] = maxi(0, int(plot["revision"]))
	return clean


## The plot as of `day`. A sown plot whose ripening day has arrived is ripe;
## everything else is itself.
##
## Recomputed from the day rather than pushed by a timer, the same
## "recomputed, never pushed" rule `grandpa_house.gd::set_door_open`'s own
## comment argues for: a crop that ripens on a signal is a crop that stays
## green forever if the player was in a menu, in a fight, or reloading a save
## on the frame the day turned.
static func ripened(plot: Dictionary, day: int) -> Dictionary:
	var clean := sanitised(plot)
	if clean["state"] == SOWN and day >= int(clean["ripe_on_day"]):
		clean["state"] = RIPE
	return clean


static func state_of(plot: Dictionary, day: int) -> String:
	return str(ripened(plot, day)["state"])


## What pressing interact (or swinging) on this plot would do right now, given
## what the player is carrying. "" means nothing -- a crop still growing, or a
## step the player has not got the hoe or the seeds for.
##
## `has_hoe` and `seed_count` are passed in rather than read from the satchel
## here because this file owns no autoloads; `farm_plot.gd` looks both up.
static func action_for(plot: Dictionary, day: int, has_hoe: bool, seed_count: int) -> String:
	match state_of(plot, day):
		FALLOW:
			return ACTION_TILL if has_hoe else ACTION_NONE
		TILLED:
			return ACTION_SOW if seed_count > 0 else ACTION_NONE
		RIPE:
			return ACTION_HARVEST
		_:
			return ACTION_NONE


## The prompt line, in the imperative and already containing its subject --
## `interactable.gd`'s own rule for `label`.
##
## A plot the player cannot act on still gets a line, because the alternative
## is a farm that goes silent exactly when the player is asking it what is
## wrong. "Needs a Hoe" and "Ripens tomorrow" are both answers; no prompt at
## all is not. `farm_plot.gd` marks those two non-actionable so the arbiter
## draws them without a button glyph (`prompt_arbiter.gd::offer`).
static func label_for(plot: Dictionary, day: int, has_hoe: bool, seed_count: int) -> String:
	match state_of(plot, day):
		FALLOW:
			return "Till the ground" if has_hoe else "Needs a Hoe"
		TILLED:
			return "Sow berry seeds" if seed_count > 0 else "Needs Berry Seeds"
		SOWN:
			var left := int(sanitised(plot)["ripe_on_day"]) - day
			return "Ripens tomorrow" if left <= 1 else "Ripens in %d days" % left
		RIPE:
			return "Pick berries"
		_:
			return ""


## Whether the prompt for this plot is a button press or a statement.
static func is_actionable(plot: Dictionary, day: int, has_hoe: bool, seed_count: int) -> bool:
	return action_for(plot, day, has_hoe, seed_count) != ACTION_NONE


## --- the three transitions ---------------------------------------------------
##
## Each returns a NEW plot dictionary and never edits the one passed in: the
## caller holds the copy `game_state.gd` saves, and a transition that mutated
## its argument would write the new state into the save before the caller had
## decided the action actually succeeded (no seeds in the satchel, a broken
## hoe).

static func tilled(plot: Dictionary) -> Dictionary:
	return {"state": TILLED, "ripe_on_day": 0}


## `grow_days` is data (data/config/farm.json), minimum 1 -- a crop that
## ripened the same day it was sown would make "on a later day" false and the
## whole wait meaningless.
static func sown(plot: Dictionary, day: int, grow_days: int) -> Dictionary:
	return {"state": SOWN, "ripe_on_day": day + maxi(1, grow_days)}


## Picked. Back to TILLED, not FALLOW -- the soil stays worked.
##
## D50 again: re-tilling after every single crop is a chore, and §21 says
## there are no chores in this. It also means the hoe is a one-off cost per
## plot rather than a durability tax the player pays forever, which is what
## keeps a five-plot farm from being worse than walking to a wild bush.
static func harvested(plot: Dictionary) -> Dictionary:
	return {"state": TILLED, "ripe_on_day": 0}


## F32: definitions come from the HOST's farm.json, never from the intent.
## An unknown crop is refused rather than silently becoming berries.
static func crop_definition(config: Dictionary, crop_id: String) -> Dictionary:
	var crops: Variant = config.get("crops", {})
	if not crops is Dictionary:
		return {}
	var raw: Variant = crops.get(crop_id)
	if not raw is Dictionary:
		return {}
	var definition: Dictionary = raw
	if str(definition.get("seed_item", "")).is_empty() \
			or int(definition.get("grow_days", 0)) < 1:
		return {}
	var outputs: Variant = definition.get("outputs")
	if not outputs is Dictionary or outputs.is_empty():
		return {}
	for item: Variant in outputs:
		if not item is String or str(item).is_empty() \
				or not (typeof(outputs[item]) in [TYPE_INT, TYPE_FLOAT]) \
				or float(outputs[item]) != float(int(outputs[item])) or int(outputs[item]) < 1:
			return {}
	return definition.duplicate(true)


## Native crops work outside; other types need the one Farm Greenhouse.
## Presence is supplied by the host's built-world state, not a client flag.
static func can_grow(config: Dictionary, crop_id: String, greenhouse_built: bool) -> bool:
	var definition := crop_definition(config, crop_id)
	if definition.is_empty():
		return false
	var type_id := str(definition.get("type", ""))
	if type_id.is_empty():
		return crop_id == str(config.get("default_crop", "berries"))
	var native: Variant = config.get("native_types", [])
	return greenhouse_built or (native is Array and native.has(type_id))


## Ordered, deterministic choices for a bounded tap-driven crop selector.
## Seed counts are read from the actor's inventory; this spends nothing.
static func available_crops(config: Dictionary, seed_counts: Dictionary,
		greenhouse_built: bool) -> Array[String]:
	var result: Array[String] = []
	var order: Variant = config.get("crop_order", [])
	if not order is Array:
		return result
	for raw_id: Variant in order:
		if not raw_id is String or result.has(raw_id):
			continue
		var crop_id := str(raw_id)
		var definition := crop_definition(config, crop_id)
		if can_grow(config, crop_id, greenhouse_built) \
				and int(seed_counts.get(str(definition.get("seed_item", "")), 0)) > 0:
			result.append(crop_id)
	return result


## Host-only staging seam. The caller checks proximity, actor identity,
## expected plot revision, seed inventory and greenhouse state before the
## ledger commits this new plot and one seed debit as a single transaction.
static func planted_crop(plot: Dictionary, day: int, crop_id: String,
		config: Dictionary, greenhouse_built: bool) -> Dictionary:
	if day < 1 or state_of(plot, day) != TILLED \
			or not can_grow(config, crop_id, greenhouse_built):
		return {}
	var definition := crop_definition(config, crop_id)
	var candidate := sown(plot, day, int(definition["grow_days"]))
	candidate["crop_id"] = crop_id
	candidate["planted_on_day"] = day
	return candidate


## One manual harvest pays every output atomically. No partial attuned/
## essence payout if the inventory is full; no wall-clock/offline growth.
## The definition is looked up from saved crop identity in host config.
static func harvest_candidate(plot: Dictionary, day: int, config: Dictionary) -> Dictionary:
	if day < 1 or state_of(plot, day) != RIPE:
		return {}
	var clean := sanitised(plot)
	var crop_id := str(clean.get("crop_id", config.get("default_crop", "berries")))
	var definition := crop_definition(config, crop_id)
	if definition.is_empty():
		return {}
	return {"plot": harvested(clean), "crop_id": crop_id,
		"outputs": (definition["outputs"] as Dictionary).duplicate(true)}


## Prompt adapter for typed plots. crop_id is the player's selected seed on
## an empty bed; once planted, the world plot's saved identity takes priority.
## This is presentation only; the host independently validates a sow intent.
static func crop_label_for(plot: Dictionary, day: int, has_hoe: bool, seed_count: int,
		config: Dictionary, crop_id: String, greenhouse_built: bool) -> String:
	var clean := sanitised(plot)
	var state := state_of(clean, day)
	if state == FALLOW:
		return label_for(clean, day, has_hoe, seed_count)
	if state == SOWN or state == RIPE:
		crop_id = str(clean.get("crop_id", config.get("default_crop", "berries")))
	var definition := crop_definition(config, crop_id)
	if definition.is_empty():
		return "Choose seeds" if state == TILLED else "Crop unavailable"
	match state:
		TILLED:
			if not can_grow(config, crop_id, greenhouse_built):
				return "Needs a Greenhouse"
			if seed_count < 1:
				return "Needs %s seeds" % str(definition.get("name", crop_id))
			return str(definition.get("sow_label", "Sow seeds"))
		SOWN:
			return label_for(clean, day, has_hoe, seed_count)
		RIPE:
			return str(definition.get("harvest_label", "Pick crop"))
	return ""


static func crop_action_for(plot: Dictionary, day: int, has_hoe: bool, seed_count: int,
		config: Dictionary, crop_id: String, greenhouse_built: bool) -> String:
	match state_of(plot, day):
		FALLOW:
			return ACTION_TILL if has_hoe else ACTION_NONE
		TILLED:
			return ACTION_SOW if seed_count > 0 and can_grow(config, crop_id, greenhouse_built) else ACTION_NONE
		RIPE:
			return ACTION_HARVEST if not harvest_candidate(plot, day, config).is_empty() else ACTION_NONE
	return ACTION_NONE
