extends RefCounted

## Every rebindable control, what it is bound to now, and what it started as.
##
## `project.godot` IS THE DEFAULTS AND IS NEVER WRITTEN TO. The input map that
## Godot loads at boot is snapshotted here on the first frame, the player's
## overrides are applied on top, and only the differences are saved. Two reasons
## this is not negotiable: an editor pass over `project.godot` strips its
## documentation comments (which has already cost this project once — see
## docs/decisions/D14), and a default that is only ever a default can be changed
## later and will actually reach players who never touched that action.
##
## Two slots per action, keyboard and gamepad, because the game ships on a
## desktop and on an ROG Ally and both have to be legible on the same screen at
## the same time. A slot holds ONE event; the input map has exactly one of each
## kind per action today. Anything else already on an action is kept verbatim in
## `extra` so a third binding added upstream is never silently eaten by a rebind.
##
## The class is a plain RefCounted with no scene, no autoload and no node in it,
## following autoload/inventory.gd and autoload/party.gd: the rules live in
## something that can be tested headlessly, and the thing that holds one of them
## is somebody else's job.

## Bumped when the on-disk shape changes. docs/TECHNICAL_START.md asks for
## versioned data from the start, and this is the project's first file in
## user:// — getting a version field in before there is anything to migrate is
## the whole point of the requirement.
const FORMAT_VERSION := 1

## Preferences, not a save. Game saves are going to `user://saves/`, which this
## deliberately does not create — see docs/decisions/D15.
const SETTINGS_PATH := "user://settings.json"

const SLOT_KEYBOARD := "keyboard"
const SLOT_GAMEPAD := "gamepad"
const SLOTS := [SLOT_KEYBOARD, SLOT_GAMEPAD]

## How far a stick has to be pushed before a rebind counts it. Well above the
## input map's 0.2 deadzone so a resting stick can never bind itself.
const AXIS_CAPTURE := 0.6

const LOAD_OK := 0
const LOAD_MISSING := 1
const LOAD_UNREADABLE := 2
const LOAD_FUTURE := 3

## Human names for gamepad buttons and stick directions, from
## data/config/menu.json. Empty is legal — the engine's own numbering is used
## instead, which is ugly but never wrong. Kept as data because "button 2 is X"
## is true of an Xbox-layout pad and false of a PlayStation one, and swapping
## glyph sets should be a JSON edit.
var glyphs: Dictionary = {}

var _path: String = SETTINGS_PATH
## action -> {keyboard: InputEvent|null, gamepad: InputEvent|null, extra: Array}
var _defaults: Dictionary = {}
var _current: Dictionary = {}


func _init(path: String = SETTINGS_PATH) -> void:
	_path = path
	capture_defaults()


## Snapshot the input map as Godot loaded it from project.godot.
##
## Must run before any override is applied, which in practice means at autoload
## time. `ui_*` actions are skipped on purpose: they are Godot's built-in focus
## navigation, they are what drives this very screen with a stick, and a player
## who rebound `ui_down` could not reach the control that would undo it.
func capture_defaults() -> void:
	_defaults.clear()
	for action in InputMap.get_actions():
		var name := str(action)
		if name.begins_with("ui_"):
			continue
		var slots := {SLOT_KEYBOARD: null, SLOT_GAMEPAD: null, "extra": []}
		for event in InputMap.action_get_events(name):
			var slot := slot_for(event)
			if slot.is_empty() or slots[slot] != null:
				(slots["extra"] as Array).append(event)
			else:
				slots[slot] = event
		_defaults[name] = slots
	_current = _copy(_defaults)


func actions() -> Array:
	var out: Array = _defaults.keys()
	out.sort()
	return out


func has(action: String) -> bool:
	return _defaults.has(action)


func binding(action: String, slot: String) -> InputEvent:
	var slots: Variant = _current.get(action)
	return slots[slot] if slots != null else null


func default_binding(action: String, slot: String) -> InputEvent:
	var slots: Variant = _defaults.get(action)
	return slots[slot] if slots != null else null


func is_overridden(action: String, slot: String) -> bool:
	return code(binding(action, slot)) != code(default_binding(action, slot))


func any_overridden() -> bool:
	for action in _defaults.keys():
		for slot in SLOTS:
			if is_overridden(str(action), str(slot)):
				return true
	return false


# --- changing a binding -----------------------------------------------------


## Which slot an event belongs in, or "" for something neither column can show.
##
## Mouse buttons are keyboard-side because that is where a desktop player looks
## for them: `combat_quick` ships bound to left click.
static func slot_for(event: InputEvent) -> String:
	if event is InputEventKey or event is InputEventMouseButton:
		return SLOT_KEYBOARD
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return SLOT_GAMEPAD
	return ""


## Set one slot of one action. Returns false if the event does not belong in
## that slot, so a caller cannot quietly file a gamepad button under keyboard.
##
## Conflicts are NOT refused here. See `conflicts()`.
func set_binding(action: String, slot: String, event: InputEvent) -> bool:
	if not _current.has(action) or event == null:
		return false
	if slot_for(event) != slot:
		return false
	_current[action][slot] = normalise(event)
	_apply(action)
	return true


## Put one action back to what project.godot says.
func reset_action(action: String) -> void:
	if not _defaults.has(action):
		return
	_current[action] = _copy_slots(_defaults[action])
	_apply(action)


## Put everything back. This is the safety net: a player can rebind themselves
## out of opening the menu, and something has to be able to undo that.
func reset_all() -> void:
	_current = _copy(_defaults)
	for action in _current.keys():
		_apply(str(action))


## Which other actions already answer to this event in this slot.
##
## Returns names, never a verdict. Duplicates are ALLOWED — the shipped defaults
## contain four of them (jump/combat_quick/menu_confirm all sit on A, and
## menu_cancel/combat_run both on B) because the world, a fight and a menu are
## different contexts and a button means different things in each. Refusing a
## duplicate would make the game's own defaults unreachable from this screen.
## The caller's job is to say out loud what else the button now does.
func conflicts(action: String, slot: String, event: InputEvent) -> Array:
	var wanted := code(event)
	var out: Array = []
	if wanted.is_empty():
		return out
	for other in actions():
		var name := str(other)
		if name == action:
			continue
		if code(binding(name, slot)) == wanted:
			out.append(name)
	return out


## Everything currently sharing a binding with this one, in either slot.
func current_conflicts(action: String) -> Array:
	return _clashes(_current, action)


## The clashes the PLAYER made, as opposed to the ones the game shipped with.
##
## This is what a row is marked on. A is `jump` and `combat_quick` and
## `menu_confirm` out of the box, so marking every clash would paint four rows
## amber on a fresh install and teach the player to ignore the colour — which is
## the exact opposite of what a warning is for.
func new_conflicts(action: String) -> Array:
	var shipped := _clashes(_defaults, action)
	var out: Array = []
	for other in current_conflicts(action):
		if not shipped.has(other):
			out.append(other)
	return out


func _clashes(table: Dictionary, action: String) -> Array:
	var out: Array = []
	if not table.has(action):
		return out
	for slot in SLOTS:
		var wanted := code(table[action][slot])
		if wanted.is_empty():
			continue
		for other in table.keys():
			var name := str(other)
			if name == action or out.has(name):
				continue
			if code(table[other][slot]) == wanted:
				out.append(name)
	out.sort()
	return out


func _apply(action: String) -> void:
	if not InputMap.has_action(action):
		return
	var slots: Dictionary = _current[action]
	InputMap.action_erase_events(action)
	for slot in SLOTS:
		if slots[slot] != null:
			InputMap.action_add_event(action, slots[slot])
	for event in slots["extra"] as Array:
		InputMap.action_add_event(action, event)


## A captured event comes off one physical pad (device 0) and would then only
## work on that pad. Every binding is stored for all devices.
static func normalise(event: InputEvent) -> InputEvent:
	var copy: InputEvent = event.duplicate()
	copy.device = -1
	if copy is InputEventJoypadMotion:
		var motion := copy as InputEventJoypadMotion
		motion.axis_value = 1.0 if motion.axis_value >= 0.0 else -1.0
	if copy is InputEventKey:
		var key := copy as InputEventKey
		key.pressed = false
		key.echo = false
	if copy is InputEventMouseButton:
		(copy as InputEventMouseButton).pressed = false
	if copy is InputEventJoypadButton:
		(copy as InputEventJoypadButton).pressed = false
	return copy


# --- naming and serialising -------------------------------------------------


## The stored form of an event, and also its identity for comparison.
##
## One string does both jobs deliberately: two events are the same binding
## exactly when they would be written to disk the same way, which is a rule that
## cannot drift out of step with the file format.
static func code(event: InputEvent) -> String:
	if event == null:
		return ""
	if event is InputEventKey:
		var key := event as InputEventKey
		var scancode: int = key.physical_keycode if key.physical_keycode != 0 else key.keycode
		return "key:%d" % scancode
	if event is InputEventMouseButton:
		return "mouse:%d" % (event as InputEventMouseButton).button_index
	if event is InputEventJoypadButton:
		return "pad:%d" % (event as InputEventJoypadButton).button_index
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return "axis:%d:%s" % [motion.axis, "+" if motion.axis_value >= 0.0 else "-"]
	return ""


static func from_code(text: String) -> InputEvent:
	var parts := text.split(":")
	if parts.size() < 2:
		return null
	match parts[0]:
		"key":
			var key := InputEventKey.new()
			key.physical_keycode = int(parts[1])
			return key
		"mouse":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = int(parts[1])
			return mouse
		"pad":
			var button := InputEventJoypadButton.new()
			button.button_index = int(parts[1])
			return button
		"axis":
			if parts.size() < 3:
				return null
			var motion := InputEventJoypadMotion.new()
			motion.axis = int(parts[1])
			motion.axis_value = -1.0 if parts[2] == "-" else 1.0
			return motion
	return null


## What the player reads on the button. Never empty, so a row can never look
## like it failed to draw.
func describe(event: InputEvent) -> String:
	if event == null:
		return "unbound"
	var id := code(event)
	if event is InputEventKey:
		var key := event as InputEventKey
		var scancode: int = key.physical_keycode if key.physical_keycode != 0 else key.keycode
		var name := OS.get_keycode_string(scancode)
		return name if not name.is_empty() else "key %d" % scancode
	var parts := id.split(":")
	var glyph_key := "_".join(parts) if parts[0] == "axis" else "%s_%s" % [parts[0], parts[1]]
	if glyphs.has(glyph_key):
		return str(glyphs[glyph_key])
	if event is InputEventMouseButton:
		return "mouse %s" % parts[1]
	if event is InputEventJoypadButton:
		return "button %s" % parts[1]
	return "axis %s%s" % [parts[1], parts[2]]


# --- the file ---------------------------------------------------------------


func path() -> String:
	return _path


## Write the overrides. Only the differences from project.godot go in, so a
## default that changes upstream still reaches a player who has a settings file.
func save() -> bool:
	var controls: Dictionary = {}
	for action in actions():
		var name := str(action)
		var entry: Dictionary = {}
		for slot in SLOTS:
			if is_overridden(name, str(slot)):
				entry[slot] = code(binding(name, str(slot)))
		if not entry.is_empty():
			controls[name] = entry

	# Named sections from the first write, so display and audio join this file
	# rather than each inventing one of their own.
	var payload := {
		"version": FORMAT_VERSION,
		"controls": controls,
	}
	var directory := _path.get_base_dir()
	if not directory.is_empty() and not DirAccess.dir_exists_absolute(directory):
		DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		push_warning("could not write settings: %s" % _path)
		return false
	file.store_string(JSON.stringify(payload, "  "))
	return true


## Read the overrides and apply them on top of the defaults.
##
## NOTHING HERE MAY STOP THE GAME BOOTING. A missing file is the normal first
## run; a corrupt or future-versioned one is a bad day that ends with default
## controls and a warning in the log, not with a game that will not start.
## Returns one of the LOAD_* codes so a test can tell the four cases apart.
func load_overrides() -> int:
	reset_all()
	if not FileAccess.file_exists(_path):
		return LOAD_MISSING

	var file := FileAccess.open(_path, FileAccess.READ)
	if file == null:
		push_warning("settings file could not be opened, using defaults: %s" % _path)
		return LOAD_UNREADABLE
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("settings file is not a JSON object, using defaults: %s" % _path)
		return LOAD_UNREADABLE

	var data := parsed as Dictionary
	var version := int(data.get("version", 0))
	if version > FORMAT_VERSION:
		# Written by a newer build. Read nothing rather than guess, and do not
		# overwrite it either — the player may go back to that build.
		push_warning("settings file is version %d, this build reads %d; using defaults" % [
			version, FORMAT_VERSION
		])
		return LOAD_FUTURE
	if version < FORMAT_VERSION:
		push_warning("settings file is version %d; there is no migration yet, using defaults" % version)
		return LOAD_UNREADABLE

	var controls: Variant = data.get("controls", {})
	if typeof(controls) != TYPE_DICTIONARY:
		return LOAD_UNREADABLE
	for action in (controls as Dictionary).keys():
		var name := str(action)
		# An action the file names but the game no longer has is skipped, not
		# fatal. Renaming an action must not brick everyone's settings.
		if not _current.has(name):
			continue
		var entry: Variant = (controls as Dictionary)[action]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		for slot in SLOTS:
			var text := str((entry as Dictionary).get(slot, ""))
			if text.is_empty():
				continue
			var event := from_code(text)
			if event != null:
				set_binding(name, str(slot), event)
	return LOAD_OK


func _copy(table: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for action in table.keys():
		out[action] = _copy_slots(table[action])
	return out


func _copy_slots(slots: Dictionary) -> Dictionary:
	return {
		SLOT_KEYBOARD: slots[SLOT_KEYBOARD],
		SLOT_GAMEPAD: slots[SLOT_GAMEPAD],
		"extra": (slots["extra"] as Array).duplicate(),
	}
