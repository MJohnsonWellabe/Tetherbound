extends "res://scripts/ui/system_screen.gd"

## Read-only F45 service projection, never inferred from current party or
## invented from seen species. Released/never-kept task history is preserved
## by the canonical service. Unseen rows carry no locations.
const BIOMES: Array[String] = ["meadows", "tidewake", "cloudreach", "stormwood"]
var _view := Callable()
var _biome := "meadows"
var _species := ""

func open(personal_view: Callable) -> bool:
	if config().get("enabled") != true or not personal_view.is_valid(): return false
	_view = personal_view
	if not begin("Research log", "A Inspect · LB/RB Biome · B Back"): return false
	_rebuild()
	return true

func _rebuild() -> void:
	var focus := clear_body()
	for biome: String in BIOMES:
		button(body, ("● " if biome == _biome else "") + biome.capitalize(), _select.bind(biome), "biome:" + biome)
	var raw: Variant = _view.call(_biome)
	if not raw is Dictionary or raw.get("ready") != true:
		status.text = "Research records are unavailable."
		finish(focus)
		return
	status.text = "%s · %d%% complete%s" % [_biome.capitalize(), int(raw.get("completion_percent", 0)),
		" · " + str(raw.get("title", "")) if int(raw.get("completion_percent", 0)) == 100 else ""]
	for row: Dictionary in raw.get("species", []):
		var seen := row.get("seen") == true
		var key := str(row.get("species_id", ""))
		button(body, "%s · %s" % [str(row.get("name", "")) if seen else "Unseen creature", "Caught" if row.get("caught") == true else "Seen" if seen else "Unknown"], _inspect.bind(key), "species:" + key)
		if not seen or key != _species: continue
		for task: Dictionary in row.get("tasks", []):
			line(body, "%s · %d / %d · %s ×%d%s" % [str(task.get("label", "Task")), int(task.get("progress", 0)),
				int(task.get("required", 0)), str(task.get("reward_item", "")).replace("_", " ").capitalize(),
				int(task.get("reward_count", 0)), " · Paid ✓" if task.get("paid") == true else ""])
	finish(focus)

func _select(biome: String) -> void:
	_biome = biome
	_species = ""
	_rebuild()

func _inspect(species: String) -> void:
	_species = species
	_rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if _shown and (event.is_action_pressed("menu_tab_left") or event.is_action_pressed("menu_tab_right")):
		var direction := -1 if event.is_action_pressed("menu_tab_left") else 1
		_select(BIOMES[(BIOMES.find(_biome) + direction + BIOMES.size()) % BIOMES.size()])
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)
