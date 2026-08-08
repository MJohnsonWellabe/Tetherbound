extends RefCounted

## The one place a user setting is read from or written to.
##
## Two files, two jobs. `res://data/config/settings.json` ships the DEFAULTS and
## never changes at runtime — D14 is emphatic that `res://` is read-only on a
## deployed build, and the smokes wipe `user://` between runs precisely because
## runtime state does not belong beside the code. `user://settings.json` holds
## what THIS player changed, and only the keys they changed, so a default that
## moves in a later build reaches every player who never touched that setting.
##
## Static, like `ui_style.gd`, and for its reason: a screen that needs to know
## whether building is free should not also need a singleton to have booted.
## CLAUDE.md keeps a deliberately high bar for autoloads, and this is a
## dictionary with opinions, not a system.
##
## Who calls what:
##   - `screen_stack._ready()` calls `apply()` once at boot: volume onto the
##     Master bus, saved rebinds onto the InputMap. The stack is in every world
##     scene and every preview, which is what makes it the boot seam.
##   - the Settings screen reads and writes values; the remap screen reads and
##     writes bindings. Both go through here, so the user file has one author.
##   - `build_mode._purse()` asks `free_build()` — the ONE line of that file the
##     settings system owns, documented there and in D26.
##   - combat reads `speed_scale()` at fight start. Coordinated by the key name
##     in settings.json, nothing more.

const CONFIG_PATH := "res://data/config/settings.json"
const USER_PATH := "user://settings.json"

## Where the user file lives. A variable so a test can point it at a scratch
## path and never touch the player's real choices; everything else leaves it be.
static var user_path: String = USER_PATH

static var _defaults: Dictionary = {}
static var _user: Dictionary = {}
static var _loaded: bool = false


# ------------------------------------------------------------------- values

static func value(key: String, fallback: Variant = null) -> Variant:
	_load_if_needed()
	if _user.has(key):
		return _user[key]
	return _defaults.get(key, fallback)


## Write one setting and persist it immediately. Persisting per change rather
## than on some later "apply" press, because a handheld can lose power or be
## force-closed at any moment and a settings screen that silently forgot is
## indistinguishable from one that never worked.
static func set_value(key: String, new_value: Variant) -> void:
	_load_if_needed()
	_user[key] = new_value
	_write_user()


static func free_build() -> bool:
	return bool(value("free_build", false))


static func speed_scale() -> float:
	return float(value("speed_scale", 1.0))


static func master_volume() -> float:
	return clampf(float(value("master_volume", 1.0)), 0.0, 1.0)


## The combat-speed selector's positions, from data. Falls back to a lone
## "Normal" rather than an empty list, so a missing config renders as a selector
## with nothing to change instead of a row that errors.
static func speed_choices() -> Array:
	var choices: Variant = value("speed_choices", [])
	if choices is Array and not (choices as Array).is_empty():
		return choices
	return [{"label": "Normal", "value": 1.0}]


# ------------------------------------------------------------------ applying

## Put the persisted choices into effect. Called once at boot by
## `screen_stack._ready()`; safe to call again (idempotent), safe headless.
static func apply() -> void:
	_load_if_needed()
	apply_master_volume()
	apply_bindings()


static func apply_master_volume() -> void:
	var linear := master_volume()
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	# Mute at zero rather than -infinity dB: "off" should be OFF, not a value
	# that rounds back to a whisper.
	AudioServer.set_bus_mute(bus, linear <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(linear, 0.0001)))


# ------------------------------------------------------------------ bindings

## Saved rebinds, `{action: {"keys": [physical keycodes], "buttons": [joypad
## button indices]}}`. Each entry is the action's FULL key/button set, not a
## delta — a full set survives the defaults changing underneath it, where a
## delta would half-apply.
static func bindings() -> Dictionary:
	_load_if_needed()
	var stored: Variant = _user.get("bindings", {})
	return stored if stored is Dictionary else {}


## Replace one action's key and button events, remember it, persist it.
## Joypad MOTION events (sticks, triggers) are left alone: the remap screen
## rebinds buttons and keys, and erasing an axis binding because someone
## remapped the key next to it is how `move_forward` loses its stick.
static func set_binding(action: String, keys: Array, buttons: Array) -> void:
	_load_if_needed()
	var stored := bindings().duplicate()
	stored[action] = {"keys": keys.duplicate(), "buttons": buttons.duplicate()}
	_user["bindings"] = stored
	_apply_binding(action, keys, buttons)
	_write_user()


## Forget every rebind and put the InputMap back to what project.godot ships.
static func reset_bindings() -> void:
	_load_if_needed()
	_user.erase("bindings")
	InputMap.load_from_project_settings()
	_write_user()


## Applied at boot, on top of the project defaults the InputMap already holds.
## An action the map no longer has is skipped with a warning rather than
## recreated: a stale rebind must not resurrect a deleted action.
static func apply_bindings() -> void:
	for action: String in bindings().keys():
		if not InputMap.has_action(action):
			push_warning("saved rebind for unknown action '%s'; ignoring it" % action)
			continue
		var entry: Dictionary = bindings()[action]
		_apply_binding(action, entry.get("keys", []), entry.get("buttons", []))


static func _apply_binding(action: String, keys: Array, buttons: Array) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(StringName(action)):
		if event is InputEventKey or event is InputEventJoypadButton:
			InputMap.action_erase_event(StringName(action), event)
	for keycode: Variant in keys:
		var key := InputEventKey.new()
		key.physical_keycode = int(keycode) as Key
		InputMap.action_add_event(StringName(action), key)
	for index: Variant in buttons:
		var button := InputEventJoypadButton.new()
		button.button_index = int(index) as JoyButton
		InputMap.action_add_event(StringName(action), button)


## Every action a player may rebind, in a stable, grouped order: the groups as
## settings.json lists them, then anything the InputMap has that the data has
## never heard of. That last clause is the contract — a NEW action appears on
## the remap screen the moment it exists, without anyone editing the screen or
## this file. Engine `ui_*` actions are not the game's and are excluded.
static func remappable_actions() -> Array[String]:
	var known: Array[String] = []
	var groups: Variant = value("remap_groups", {})
	if groups is Dictionary:
		for group: String in (groups as Dictionary).keys():
			for action: Variant in (groups as Dictionary)[group]:
				if InputMap.has_action(StringName(str(action))) and not known.has(str(action)):
					known.append(str(action))
	for action: StringName in InputMap.get_actions():
		var name := str(action)
		if name.begins_with("ui_") or known.has(name):
			continue
		known.append(name)
	return known


## The player's words for an action, from data, else prettified from the id.
static func action_label(action: String) -> String:
	var labels: Variant = value("action_labels", {})
	if labels is Dictionary and (labels as Dictionary).has(action):
		return str((labels as Dictionary)[action])
	return action.capitalize()


## The conflict group an action belongs to, or "" for one no group claims.
static func group_of(action: String) -> String:
	var groups: Variant = value("remap_groups", {})
	if not groups is Dictionary:
		return ""
	for group: String in (groups as Dictionary).keys():
		if (groups as Dictionary)[group].has(action):
			return group
	return ""


## Which action already holds this key or button, where it matters — or "".
##
## `kind` is "key" or "button"; `code` a physical keycode or a joypad button
## index. Only actions in the SAME conflict group as `action` count: two
## actions read in the same game state on one button means one press fires
## both, which is the two-actions-one-button collision this project has now
## shipped twice (inventory + party_menu both on Y; mount nearly on interact).
## Actions in different groups share buttons on purpose — A confirms in menus
## and jumps in the world — and are not conflicts. An action in NO group is
## checked against everything, conservatively.
static func conflicting_holder(action: String, kind: String, code: int) -> String:
	var mine := group_of(action)
	for other in remappable_actions():
		if other == action:
			continue
		var theirs := group_of(other)
		if mine != "" and theirs != "" and mine != theirs:
			continue
		for event in InputMap.action_get_events(StringName(other)):
			if kind == "key" and event is InputEventKey \
					and int((event as InputEventKey).physical_keycode) == code:
				return other
			if kind == "button" and event is InputEventJoypadButton \
					and int((event as InputEventJoypadButton).button_index) == code:
				return other
	return ""


# ------------------------------------------------------------- free building

## An inventory that always says yes. `build_mode._purse()` returns this when
## free building is on — the ONE line of that file the settings system owns —
## so the cost gate, the payment and the refund all run their normal code
## against a purse that never runs out, instead of three systems each growing
## an `if free` branch that can disagree.
##
## Not a fallback: build_mode's own header forbids a second inventory, and this
## is not one. It holds nothing, records nothing, and exists only while the
## player has explicitly said building is free. Note one honest consequence:
## removing a piece while free building is on refunds into this purse, i.e.
## nowhere — you paid nothing, you get nothing back.
class BottomlessPurse:
	func count_of(_item: String) -> int:
		return 999999

	func remove(_item: String, _count: int) -> bool:
		return true

	func add(_item: String, _count: int) -> bool:
		return true


static var _purse: BottomlessPurse = null


static func bottomless_purse() -> Object:
	if _purse == null:
		_purse = BottomlessPurse.new()
	return _purse


# ---------------------------------------------------------------------- files

static func _load_if_needed() -> void:
	if _loaded:
		return
	_loaded = true
	_defaults = _read_json(CONFIG_PATH)
	if _defaults.is_empty():
		push_warning("settings defaults missing or unreadable: %s" % CONFIG_PATH)
	_user = _read_json(user_path)


## For tests, and only tests: drop everything cached so the next read reloads.
static func reset_cache_for_tests() -> void:
	_loaded = false
	_defaults = {}
	_user = {}


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## Only what the player changed goes to disk. `_comment*` keys never land in
## `_user` because nothing writes them, so the user file stays a short honest
## list of choices rather than a stale copy of the defaults.
static func _write_user() -> void:
	var file := FileAccess.open(user_path, FileAccess.WRITE)
	if file == null:
		push_warning("could not write %s; settings will not survive this session" % user_path)
		return
	file.store_string(JSON.stringify(_user, "  "))
