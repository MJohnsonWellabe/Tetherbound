extends "res://tests/test_case.gd"

## D33's one icon vocabulary. Every landmark in `data/config/map_landmarks.json`
## names an icon by a bare word (`"icon": "home"`); `scripts/ui/tab_map.gd`
## turns that word into `assets/ui/icons/map/<word>.png` with a plain string
## format, no fallback and no error if the file is missing — it just draws
## nothing. A landmark shipped with a typo'd icon name would be invisible on
## the full map and nobody would know until they went looking for a building
## that never showed up. `"objective"`, `"question"` and `"camp"` are not
## landmark entries — they are the diamond marker, the undiscovered-silhouette
## fallback, and a dynamic marker's own icon — so they are checked by name
## rather than discovered by walking the landmark table.

const LANDMARKS_PATH := "res://data/config/map_landmarks.json"
const MENU_PATH := "res://data/config/menu.json"
const ICON_DIR := "res://assets/ui/icons/map/"

## D33/spec §6A.12: names that must resolve to a real icon file even though
## `map_landmarks.json` never mentions them — `objective` is the tracked-
## objective diamond, `question` is the undiscovered-silhouette fallback
## (`autoload/map_state.gd`'s `silhouette` flag), `camp` is the trainer camp's
## dynamic marker icon (`docs/MEADOWS_PROGRESSION_SPEC.md`'s camp beats add
## markers through `MapState.add_dynamic_marker()`, never through the static
## landmark table).
const ALWAYS_REQUIRED: Array[String] = ["objective", "question", "camp"]


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _landmark_icons() -> Array[String]:
	var out: Array[String] = []
	for entry: Variant in (_json(LANDMARKS_PATH).get("landmarks", []) as Array):
		var icon := str((entry as Dictionary).get("icon", ""))
		if not icon.is_empty() and not out.has(icon):
			out.append(icon)
	return out


func test_every_landmark_icon_resolves_to_a_vendored_file() -> void:
	var icons := _landmark_icons()
	assert_false(icons.is_empty(), "map_landmarks.json named no icons at all")
	for icon in icons:
		var path := "%s%s.png" % [ICON_DIR, icon]
		assert_true(ResourceLoader.exists(path),
			"landmark icon '%s' has no file at %s" % [icon, path])


func test_the_always_required_icons_are_vendored() -> void:
	for icon in ALWAYS_REQUIRED:
		var path := "%s%s.png" % [ICON_DIR, icon]
		assert_true(ResourceLoader.exists(path),
			"'%s' is drawn by tab_map.gd directly (not via map_landmarks.json) and needs %s" % [icon, path])


func test_every_vendored_icon_actually_loads_as_a_texture() -> void:
	# A file that exists but fails to import (corrupt PNG, wrong extension
	# masquerading as one) passes ResourceLoader.exists() and then draws
	# nothing — load() and a type check catch that the existence check alone
	# would miss.
	var icons := _landmark_icons()
	for icon in ALWAYS_REQUIRED:
		if not icons.has(icon):
			icons.append(icon)
	for icon in icons:
		var path := "%s%s.png" % [ICON_DIR, icon]
		var tex: Texture2D = load(path) as Texture2D
		assert_ne(tex, null, "%s exists but did not load as a Texture2D" % path)


func test_the_map_tab_is_registered_in_the_menu() -> void:
	var tabs: Array = _json(MENU_PATH).get("tabs", [])
	var found := false
	for entry: Variant in tabs:
		var tab := entry as Dictionary
		if str(tab.get("id", "")) == "map":
			found = true
			assert_eq(str(tab.get("script", "")), "res://scripts/ui/tab_map.gd",
				"the map tab points at the wrong script")
			assert_true(ResourceLoader.exists(str(tab.get("script", ""))),
				"the map tab's script does not exist")
	assert_true(found, "menu.json has no 'map' tab entry")


func test_the_map_tab_extends_the_menu_tab_contract() -> void:
	var script: GDScript = load("res://scripts/ui/tab_map.gd")
	assert_ne(script, null)
	var base: Script = script.get_base_script()
	assert_ne(base, null, "tab_map.gd extends nothing")
	assert_eq(base.resource_path, "res://scripts/ui/menu_tab.gd",
		"tab_map.gd must extend menu_tab.gd")


## Every icon file this tab (or any dynamic marker) could ever ask for must
## actually be a square-ish silhouette, not e.g. an accidental 1x1 placeholder
## — a cheap sanity check that vendoring did not truncate a file.
func test_every_vendored_icon_has_real_pixel_dimensions() -> void:
	var icons := _landmark_icons()
	for icon in ALWAYS_REQUIRED:
		if not icons.has(icon):
			icons.append(icon)
	for icon in icons:
		var path := "%s%s.png" % [ICON_DIR, icon]
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			continue
		assert_true(tex.get_width() >= 16 and tex.get_height() >= 16,
			"%s is only %dx%d, too small to read as an icon" % [path, tex.get_width(), tex.get_height()])
