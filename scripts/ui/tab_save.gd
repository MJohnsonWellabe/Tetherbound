extends "res://scripts/ui/menu_tab.gd"

## R3.1. Five save slots. Slot 1 is the autosave `camp.gd` writes on every
## rest; slots 2-5 are the player's own. Save and Load are separate buttons on
## purpose — a single "do the obvious thing" button on a slot that already
## holds a save would have to guess whether the player wants to overwrite it
## or return to it, and guessing wrong there is the one mistake in this whole
## screen that actually costs progress.

const SLOT_COUNT := 5

var _rows: Array = []
var _status: Array = []


func build() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()
	_status.clear()

	var header := Label.new()
	header.text = "Save / Load"
	header.add_theme_font_size_override("font_size", 24)
	add_child(header)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	add_child(list)

	for i in SLOT_COUNT:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var label := Label.new()
		label.custom_minimum_size = Vector2(420, 0)
		label.add_theme_font_size_override("font_size", 22)
		row.add_child(label)
		_status.append(label)

		var save_button := Button.new()
		save_button.text = "Save"
		save_button.custom_minimum_size = Vector2(140, 56)
		save_button.focus_mode = Control.FOCUS_ALL
		var slot := i
		save_button.pressed.connect(func() -> void: _on_save(slot))
		row.add_child(save_button)

		var load_button := Button.new()
		load_button.text = "Load"
		load_button.custom_minimum_size = Vector2(140, 56)
		load_button.focus_mode = Control.FOCUS_ALL
		load_button.pressed.connect(func() -> void: _on_load(slot))
		row.add_child(load_button)

		list.add_child(_panel(row, 12))
		_rows.append({"save": save_button, "load": load_button})

	poll()


func first_focus() -> Control:
	return (_rows[0].get("save") as Control) if not _rows.is_empty() else null


## Slot files change from outside `GameState.revision`-style counters (a save
## button writes straight to disk), so this tab just re-reads the disk every
## poll rather than trying to track a revision for it — five `file_exists`
## checks a frame is not worth inventing a signal to avoid.
func poll() -> void:
	var game := state()
	if game == null or _status.is_empty():
		return
	for i in SLOT_COUNT:
		var label: Label = _status[i]
		var slot_name := "Slot %d (Autosave)" % (i + 1) if i == 0 else "Slot %d" % (i + 1)
		if bool(game.call("has_save", i)):
			var info: Dictionary = game.call("save_slot_info", i)
			label.text = "%s — Day %s, %s pals" % [
				slot_name, str(info.get("day", "?")), str(info.get("party_size", "?"))
			]
		else:
			label.text = "%s — empty" % slot_name
		(_rows[i].get("load") as Button).disabled = not bool(game.call("has_save", i))


func _on_save(slot: int) -> void:
	var game := state()
	if game == null:
		return
	if bool(game.call("save_game", slot)):
		say("Saved to slot %d." % (slot + 1))
	else:
		say("Could not save to slot %d." % (slot + 1))
	poll()


func _on_load(slot: int) -> void:
	var game := state()
	if game == null:
		return
	if bool(game.call("load_game", slot)):
		say("Loaded slot %d." % (slot + 1))
	else:
		say("Slot %d has nothing to load." % (slot + 1))
	poll()
