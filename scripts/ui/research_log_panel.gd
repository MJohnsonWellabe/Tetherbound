extends "res://scripts/ui/system_screen.gd"

## Read-only F45 service projection, never inferred from current party or
## invented from seen species. Released/never-kept task history is preserved
## by the canonical service. Unseen rows carry no locations.
const BIOMES: Array[String] = ["meadows", "tidewake", "cloudreach", "stormwood"]
var _view := Callable()
var _biome := "meadows"
var _species := ""
var claim_task := Callable()
var _refresh_left := 0.0
var _last_view := ""

func open(personal_view: Callable) -> bool:
	if config().get("enabled") != true or not personal_view.is_valid(): return false
	_view = personal_view
	if not begin("Research log", "A Inspect · LB/RB Biome · B Back"): return false
	_rebuild()
	return true

func _rebuild() -> void:
	var focus := clear_body()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	body.add_child(tabs)
	for biome: String in BIOMES:
		button(tabs, ("● " if biome == _biome else "") + biome.capitalize(), _select.bind(biome), "biome:" + biome)
	var raw: Variant = _view.call(_biome)
	_last_view = JSON.stringify(raw)
	if not raw is Dictionary or raw.get("ready") != true:
		status.text = "Research records are unavailable."
		finish(focus)
		return
	status.text = "%s · %d%% complete%s" % [_biome.capitalize(), int(raw.get("completion_percent", 0)),
		" · " + str(raw.get("title", "")) if int(raw.get("completion_percent", 0)) == 100 else ""]
	# Keep tasks beside the species list. Scrolling the catalogue must not
	# push the selected creature's progress below the journal viewport.
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	body.add_child(columns)
	var species_scroll := ScrollContainer.new()
	species_scroll.custom_minimum_size = Vector2(340, 260)
	species_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	species_scroll.follow_focus = true
	columns.add_child(species_scroll)
	var species_list := VBoxContainer.new()
	species_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	species_list.add_theme_constant_override("separation", 8)
	species_scroll.add_child(species_list)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 12)
	columns.add_child(details)
	var has_details := false
	for row: Dictionary in raw.get("species", []):
		var seen: bool = row.get("seen") == true
		var key := str(row.get("species_id", ""))
		var species_button := button(species_list, "%s\n%s" % [str(row.get("name", "")) if seen else "Unseen creature", "Caught" if row.get("caught") == true else "Seen" if seen else "Unknown"], _inspect.bind(key), "species:" + key)
		species_button.focus_entered.connect(_inspect.bind(key))
		if not seen or key != _species: continue
		has_details = true
		line(details, str(row.get("name", "")), TOKENS.FONT_PROMPT)
		for task: Dictionary in row.get("tasks", []):
			var rewards: Array[String] = []
			for stack: Dictionary in task.get("rewards", []):
				rewards.append("%s ×%d" % [str(stack.id).replace("_", " ").capitalize(), int(stack.n)])
			if rewards.is_empty():
				rewards.append("%s ×%d" % [str(task.get("reward_item", "")).replace("_", " ").capitalize(), int(task.get("reward_count", 0))])
			var task_row := HBoxContainer.new()
			task_row.add_theme_constant_override("separation", 12)
			details.add_child(task_row)
			var progress := line(task_row, "%s · %d / %d · %s%s" % [str(task.get("label", "Task")), int(task.get("progress", 0)),
				int(task.get("required", 0)), ", ".join(rewards), " · Paid ✓" if task.get("paid") == true else ""])
			progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if task.get("claimable") == true:
				button(task_row, "Claim" if raw.get("claims_enabled") == true else "Unavailable",
					_claim.bind(key, str(task.get("id", ""))), "claim:" + key + ":" + str(task.get("id", "")),
					raw.get("claims_enabled") == true and claim_task.is_valid())
	if not has_details:
		line(details, "Choose a seen creature to inspect its research tasks.")
	finish(focus)

func _claim(species: String, task: String) -> void:
	if not claim_task.is_valid(): return
	var result: Variant = claim_task.call(species, task)
	status.text = "Claim submitted · waiting for confirmation" if result is Dictionary and result.get("ok") == true else str(result.get("code", "Research reward unavailable")) if result is Dictionary else "Research reward unavailable"

func _process(delta: float) -> void:
	super._process(delta)
	if not _shown or not _view.is_valid(): return
	_refresh_left -= delta
	if _refresh_left > 0.0: return
	_refresh_left = 0.5
	if JSON.stringify(_view.call(_biome)) != _last_view: _rebuild()

func _select(biome: String) -> void:
	_biome = biome
	_species = ""
	_rebuild()

func _inspect(species: String) -> void:
	# Rebuilding keeps the same focused row. Its new focus signal must not
	# start another rebuild; A on an already inspected row is also a no-op.
	if _species == species: return
	_species = species
	_rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if _shown and (event.is_action_pressed("menu_tab_left") or event.is_action_pressed("menu_tab_right")):
		var direction := -1 if event.is_action_pressed("menu_tab_left") else 1
		_select(BIOMES[(BIOMES.find(_biome) + direction + BIOMES.size()) % BIOMES.size()])
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)
