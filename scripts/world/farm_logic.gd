extends RefCounted

## What one farm plot is doing, and what changes it.
##
## R7.6. `GAME_DESIGN.md` §21 scopes Meadows farming to four words -- "plant,
## wait, harvest", berries only, "no watering chores" -- and §32 excludes
## *deep* farming. So there is no irrigation, no fertiliser, no soil quality
## and no crop varieties in here, and adding any of them is a design change,
## not a follow-up.
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
	return {"state": state, "ripe_on_day": int(plot.get("ripe_on_day", 0))}


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
