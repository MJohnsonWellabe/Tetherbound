extends RefCounted

## UX §8's accessibility minimum: subtitle/dialogue text size and background
## opacity. `dialogue_panel.gd` reads these each time a conversation opens (the
## pause menu cannot open over one, so a change always lands before the next
## line is shown).
##
## Static, like `motion_prefs.gd`, and stored in the same `user://settings.json`
## `accessibility` section that `key_bindings.gd` alone writes (D15). Local
## presentation only.

## Text size steps, percent of the authored sizes. The first is the default.
const TEXT_SIZES: Array[int] = [100, 125, 150]
## The panel's authored opacity, 93%, is the default; 100% is fully opaque.
const DEFAULT_BACKGROUND_PERCENT := 93
const MIN_BACKGROUND_PERCENT := 40

static var _text_percent := 100
static var _background_percent := DEFAULT_BACKGROUND_PERCENT


static func text_percent() -> int:
	return _text_percent


static func text_scale() -> float:
	return float(_text_percent) / 100.0


## Snaps to the nearest offered size, so a hand-edited file cannot ask for a
## size the panel was never laid out for.
static func set_text_percent(value: int) -> void:
	var best := TEXT_SIZES[0]
	for size: int in TEXT_SIZES:
		if absi(size - value) < absi(best - value):
			best = size
	_text_percent = best


## The next offered size after the current one, wrapping, for a toggle row.
static func next_text_percent() -> int:
	var at := TEXT_SIZES.find(_text_percent)
	return TEXT_SIZES[(at + 1) % TEXT_SIZES.size()]


static func background_percent() -> int:
	return _background_percent


static func background_alpha() -> float:
	return float(_background_percent) / 100.0


static func set_background_percent(value: int) -> void:
	_background_percent = clampi(value, MIN_BACKGROUND_PERCENT, 100)


static func reset() -> void:
	_text_percent = TEXT_SIZES[0]
	_background_percent = DEFAULT_BACKGROUND_PERCENT


static func load_from(prefs: RefCounted) -> void:
	if prefs == null:
		return
	var stored: Variant = prefs.get("accessibility")
	if typeof(stored) != TYPE_DICTIONARY:
		return
	var table := stored as Dictionary
	set_text_percent(int(table.get("dialogue_text_percent", TEXT_SIZES[0])))
	set_background_percent(int(table.get("dialogue_background_percent", DEFAULT_BACKGROUND_PERCENT)))


static func store_to(prefs: RefCounted) -> void:
	if prefs == null:
		return
	var table: Variant = prefs.get("accessibility")
	var out: Dictionary = (table as Dictionary).duplicate() if typeof(table) == TYPE_DICTIONARY else {}
	out["dialogue_text_percent"] = _text_percent
	out["dialogue_background_percent"] = _background_percent
	prefs.set("accessibility", out)
