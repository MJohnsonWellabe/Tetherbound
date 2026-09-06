extends "res://scripts/ui/menu_tab.gd"

## Five stable rows, readable at handheld resolution and navigable with the
## existing menu focus system. Values update without rebuilding focused rows.
const SKILLS := preload("res://scripts/player/player_skills.gd")
var _rows: Dictionary = {}
var _bars: Dictionary = {}
var _first: Control
var _selected: String = "running"
var _candy_buttons: Dictionary = {}
const ACTIVITY := preload("res://scripts/player/skills_activity.gd")


func build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_rows.clear()
	_bars.clear()
	_candy_buttons.clear()
	_first = null
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SKILLS.CONFIG_PATH))
	var title := Label.new()
	title.text = "Skills grow as you travel and catch creatures."
	title.add_theme_font_size_override("font_size", 24)
	add_child(title)
	for id: String in SKILLS.IDS:
		var row := VBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Button.new()
		label.text = str(config.skills[id].name)
		label.alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.custom_minimum_size.y = 42
		label.add_theme_font_size_override("font_size", 24)
		var description := str(config.skills[id].description)
		label.pressed.connect(func() -> void:
			_selected = id
			say(description)
			poll())
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 12
		bar.show_percentage = false
		bar.max_value = 1.0
		row.add_child(bar)
		add_child(_panel(row, 10))
		_rows[id] = label
		_bars[id] = bar
		if _first == null:
			_first = label
	var candy_row := HBoxContainer.new()
	for item_id: String in config.candy_levels:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 42
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_consume.bind(item_id))
		candy_row.add_child(button)
		_candy_buttons[item_id] = button
	add_child(candy_row)
	poll()


func poll() -> void:
	var game := state()
	if game == null:
		return
	var local: RefCounted = game.get("local")
	if local == null:
		return
	var skills: RefCounted = local.get("skills")
	if skills == null:
		return
	for id: String in SKILLS.IDS:
		if not _rows.has(id):
			continue
		_rows[id].text = "%s    Level %d / %d" % [id.capitalize(), skills.level(id), skills.cap()]
		_bars[id].value = skills.fraction(id)
	for item_id: String in _candy_buttons:
		var count: int = local.inventory.count(item_id)
		_candy_buttons[item_id].text = "%s → %s (%d)" % [item_id.trim_prefix("skill_").capitalize(), _selected.capitalize(), count]
		_candy_buttons[item_id].disabled = count <= 0 or not skills.can_use_candy(_selected, item_id)


func _consume(item_id: String) -> void:
	var game := state()
	if game == null:
		return
	var local: RefCounted = game.get("local")
	var activity := ACTIVITY.new(local.skills)
	if activity.consume_candy(local.inventory, item_id, _selected):
		say("%s is now level %d." % [_selected.capitalize(), local.skills.level(_selected)])
	else:
		say("Keep this Candy: its full award must fit below the skill cap.")
	poll()


func first_focus() -> Control:
	return _first
