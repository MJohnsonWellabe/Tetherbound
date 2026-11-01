extends RefCounted

## UI-R2 follow-up (GPU UI-R2, 31 Oct 2026): the game-menu tabs set their own
## secondary-text sizes and colours, so the shared UITokens floors never
## reached them; the Satchel's worn-equipment list cut its fifth row; and the
## quick-bindings page cut its "Fighting" group at the bottom of the panel.
##
## One flag-off key, `menu.json` `menu_text_floors.enabled`, switches all of
## it. Off (the default) every tab draws exactly as before.

const MENU_PATH := "res://data/config/menu.json"

static var _cached: Dictionary = {}
static var _loaded := false


static func config() -> Dictionary:
	if not _loaded:
		_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MENU_PATH))
		var entry: Variant = parsed.get("menu_text_floors", {}) if parsed is Dictionary else {}
		_cached = entry if entry is Dictionary else {}
	return _cached


static func on() -> bool:
	return config().get("enabled") == true


## Secondary/explanatory text: at least the reading floor, in the secondary
## colour. Larger authored sizes are kept.
static func secondary(label: Control, authored_px: int) -> void:
	var px := maxi(UITokens.FONT_READ, authored_px) if on() else authored_px
	label.add_theme_font_size_override("font_size", px)
	if on():
		label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)


## A pressable row or button: at least the prompt floor.
static func prompt_px(authored_px: int) -> int:
	return maxi(UITokens.FONT_PROMPT, authored_px) if on() else authored_px


## A label that reads as body text (headers over lists): the reading floor.
static func read_px(authored_px: int) -> int:
	return maxi(UITokens.FONT_READ, authored_px) if on() else authored_px


## Test seam.
static func reset_for_tests(value: Variant = null) -> void:
	_loaded = value != null
	_cached = {"enabled": value} if value != null else {}
