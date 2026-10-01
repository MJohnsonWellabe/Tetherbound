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
	for biome: String in BIOMES:
		button(body, ("● " if biome == _biome else "") + biome.capitalize(), _select.bind(biome), "biome:" + biome)
	var raw: Variant = _view.call(_biome)
	_last_view = JSON.stringify(raw)
	if not raw is Dictionary or raw.get("ready") != true:
		status.text = "Research records are unavailable."
		finish(focus)
		return
	status.text = "%s · %d%% complete%s" % [_biome.capitalize(), int(raw.get("completion_percent", 0)),
		" · " + str(raw.get("title", "")) if int(raw.get("completion_percent", 0)) == 100 else ""]
	for row: Dictionary in raw.get("species", []):
		var seen: bool = row.get("seen") == true
		var key := str(row.get("species_id", ""))
		button(body, "%s · %s" % [str(row.get("name", "")) if seen else "Unseen creature", "Caught" if row.get("caught") == true else "Seen" if seen else "Unknown"], _inspect.bind(key), "species:" + key)
		if not seen or key != _species: continue
		for task: Dictionary in row.get("tasks", []):
			var rewards: Array[String] = []
			for stack: Dictionary in task.get("rewards", []):
				rewards.append("%s ×%d" % [str(stack.id).replace("_", " ").capitalize(), int(stack.n)])
			if rewards.is_empty():
				rewards.append("%s ×%d" % [str(task.get("reward_item", "")).replace("_", " ").capitalize(), int(task.get("reward_count", 0))])
			line(body, "%s · %d / %d · %s%s" % [str(task.get("label", "Task")), int(task.get("progress", 0)),
				int(task.get("required", 0)), ", ".join(rewards), " · Paid ✓" if task.get("paid") == true else ""])
			if task.get("claimable") == true:
				button(body, "Claim reward" if raw.get("claims_enabled") == true else "Rewards unavailable",
					_claim.bind(key, str(task.get("id", ""))), "claim:" + key + ":" + str(task.get("id", "")),
					raw.get("claims_enabled") == true and claim_task.is_valid())
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
	_species = species
	_rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if _shown and (event.is_action_pressed("menu_tab_left") or event.is_action_pressed("menu_tab_right")):
		var direction := -1 if event.is_action_pressed("menu_tab_left") else 1
		_select(BIOMES[(BIOMES.find(_biome) + direction + BIOMES.size()) % BIOMES.size()])
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)
