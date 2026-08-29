extends RefCounted

## Type effectiveness: how much a move of one type is worth against a creature
## of another.
##
## Static, config-driven and with no dependency on the scene tree, the same
## split combat_math.gd already uses -- so it is testable headlessly and a
## rebalance is an edit to data/config/type_chart.json rather than a code
## change. The full design argument for the chart's shape, its keying and its
## magnitudes lives in ralph/reports/TYPECHART_DESIGN_2026-08-30.md and is
## summarised in that JSON file's own comments; this file deliberately does not
## restate it.
##
## THE ONE THING TO KNOW HERE: this is keyed on the ATTACKING MOVE's type
## against the DEFENDING CREATURE's species type, never attacker-species
## against defender-species. data/moves/moves.json gives every move its own
## `type` independent of who wields it, so type coverage is a property of what
## a party can DO (ten move slots across five creatures) rather than of which
## five bodies it contains. Against a species-keyed chart the correct play is
## "carry one of each and switch"; against this one it is "make sure your five
## can hit everything", and the TM economy is what changes the answer.
##
## Nothing in this file enumerates ground/water/air. The three live types are
## data, and the six the owner's board plans (fire, ice, nature, light, shadow,
## electric) need no code here -- an unnamed pairing resolves to neutral, so a
## new type is playable the moment it exists and becomes interesting when
## somebody authors its rows.

const CONFIG_PATH := "res://data/config/type_chart.json"

## What a pairing the table does not name is worth. Also the answer for an
## empty or unknown type on either side, which is the important case: a species
## with a typo'd `type`, a move with none, or a creature built by a test that
## never set one must read as ORDINARY rather than as free damage or as a
## silent penalty. `move_db.gd::UNKNOWN_POWER` takes exactly this position for
## exactly this reason.
const NEUTRAL := 1.0

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("type_chart.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


## Drop the cached config so the next read re-parses. Tests that write a chart
## and expect it to be seen need this; nothing in the game calls it.
static func reload() -> void:
	_config = {}


static func neutral() -> float:
	return float(config().get("neutral", NEUTRAL))


## The damage multiplier for a move of `move_type` landing on a creature of
## `defender_type`.
##
## Case-insensitive and whitespace-tolerant on both sides, because these
## strings come from hand-authored JSON (`species.json`'s `type`,
## `moves.json`'s `type`) where "Ground" and "ground" are the same intent and a
## capital letter should not silently switch a mechanic off.
##
## Either side empty or unnamed gives `neutral()`. See NEUTRAL's comment for
## why that is the deliberate answer rather than an error.
static func multiplier(move_type: String, defender_type: String) -> float:
	var attacking := move_type.strip_edges().to_lower()
	var defending := defender_type.strip_edges().to_lower()
	if attacking.is_empty() or defending.is_empty():
		return neutral()

	var matchups: Dictionary = config().get("matchups", {})
	var row: Variant = matchups.get(attacking, {})
	if typeof(row) != TYPE_DICTIONARY:
		return neutral()
	return float((row as Dictionary).get(defending, neutral()))


## Is this pairing an advantage, a disadvantage, or neither? Returns 1, -1 or
## 0.
##
## Exists so the HUD does not have to compare floats itself and so "what counts
## as strong" is decided in exactly one place. A UI that wrote
## `mult > 1.0` would start lying the day somebody authors a 1.05 chip
## matchup that is not worth a banner; a UI that wrote `mult >= 1.25` would
## start lying the day the magnitude is tuned. Both failure modes are the kind
## this repo has collected before.
static func effectiveness(move_type: String, defender_type: String) -> int:
	return classify(multiplier(move_type, defender_type))


## The same verdict for a multiplier already in hand -- what combat_manager has
## after it has resolved a hit, and what it hands the HUD, so the value the
## player is told about is the value that was actually applied rather than a
## second lookup that could disagree with it.
static func classify(mult: float) -> int:
	var mid := neutral()
	if is_equal_approx(mult, mid):
		return 0
	return 1 if mult > mid else -1
