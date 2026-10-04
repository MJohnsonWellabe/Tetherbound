extends SceneTree

## DIAGNOSTIC ONLY: actual standalone BuildMenu and retained genuine host
## World/Player admission, without a terrain scene, socket or paid mutation.
## This can attribute catalogue/layout/resource CPU work, not prove the full
## co-op F48 route or explain a world-only stall by absence of one here.
## Run with TB_BUILD_PHASE_TRACE=1 and -- --save-dir=<retained host root>.
const MENU := preload("res://scripts/ui/build_menu.gd")
const PHASE := preload("res://scripts/ui/build_phase_observer.gd")
var _failures: Array[String] = []
var _completed := 0

func _initialize() -> void:
	_run.call_deferred()

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_failures.append("Missing original retained document: " + path)
		return {}
	var parsed: Variant = preload("res://scripts/save/save_document.gd").parse(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_failures.append("Invalid original retained document: " + path)
		return {}
	return parsed as Dictionary

func _run() -> void:
	await process_frame
	var source := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="): source = argument.trim_prefix("--save-dir=")
	if source.is_empty() or not PHASE.enabled():
		_failures.append("Exact retained save directory and explicit TB_BUILD_PHASE_TRACE=1 required")
		_finish()
		return
	var snapshot := _read(source.path_join("saves/redesign-v28/slot_0.json"))
	var locator: Variant = snapshot.get("split_locator")
	if not locator is Dictionary or not locator.get("character_id") is String or not locator.get("world_id") is String \
		or locator.character_id.is_empty() or locator.world_id.is_empty() \
		or locator.character_id.get_file() != locator.character_id or locator.world_id.get_file() != locator.world_id:
		_failures.append("Exact original split locator required")
		_finish()
		return
	var personal := _read(source.path_join("characters/redesign-v28").path_join(locator.character_id).path_join("character.json"))
	var world := _read(source.path_join("worlds/redesign-v28").path_join(locator.world_id).path_join("world.json"))
	if not _failures.is_empty() or personal.get("character_id") != locator.character_id or world.get("world_id") != locator.world_id \
		or personal.get("version") != 28 or world.get("version") != 28:
		_failures.append("Matching retained v28 personal/world identities required")
		_finish()
		return
	var game: Node = root.get_node_or_null(^"Game")
	if game == null:
		_failures.append("Actual initialized Game unavailable")
		_finish()
		return
	var loaded := PHASE.begin("fixture.retained_carriers", {"source": source})
	game.get("world").call("load_data", world)
	game.get("local").call("load_data", personal)
	game.set("current_realm", str(personal.get("realm", "meadows")))
	PHASE.finish("fixture.retained_carriers", loaded)
	var session: Node = game.get("session")
	var admission_started := PHASE.begin("fixture.actual_admission")
	var admitted: Dictionary = session.call("admitted_character_state", session.call("local_peer_id"))
	PHASE.finish("fixture.actual_admission", admission_started)
	if admitted.is_empty() or game.get("local").get("character_id") != locator.character_id \
		or game.get("world").get("world_id") != locator.world_id:
		_failures.append("Original actual host admission refused")
		_finish()
		return
	var before_personal: String = JSON.stringify(game.get("local").call("save_data"))
	var before_world: String = JSON.stringify(game.get("world").call("save_data"))
	var before_build: String = str(game.get("pending_build"))
	var menu: CanvasLayer = MENU.get_or_make(self)
	menu.call("open")
	var categories: Array = menu.get("_categories")
	print("BUILD_DIAGNOSTIC_CONFIGURATION ", JSON.stringify({"category_count": categories.size(),
		"stations_sha256": FileAccess.get_sha256("res://data/config/stations.json"),
		"essence_sha256": FileAccess.get_sha256("res://data/config/essence.json"),
		"paid_mutation": false, "terrain_loaded": false, "acceptance_credit": false}))
	if not menu.call("is_open") or categories.is_empty(): _failures.append("Actual populated catalogue did not open")
	for index: int in categories.size():
		var category_started := PHASE.begin("fixture.category", {"category": categories[index]})
		menu.call("_select_category", index)
		for _frame: int in 30: await process_frame
		PHASE.finish("fixture.category", category_started)
		if not menu.call("is_open"): _failures.append("Actual catalogue unexpectedly closed")
		_completed += 1
	var sampled_idle_callbacks := int(menu.get("_diagnostic_frames"))
	if sampled_idle_callbacks != 12: _failures.append("Twelve actual ordinary menu idle callbacks did not complete")
	print("BUILD_DIAGNOSTIC_IDLE ", JSON.stringify({"actual_sampled_callbacks": sampled_idle_callbacks}))
	menu.call("close", false)
	await process_frame
	if JSON.stringify(game.get("local").call("save_data")) != before_personal \
		or JSON.stringify(game.get("world").call("save_data")) != before_world \
		or str(game.get("pending_build")) != before_build:
		_failures.append("Diagnostic menu changed original personal/world/build state")
	menu.free()
	_finish()

func _finish() -> void:
	print("BUILD_MENU_DIAGNOSTIC ", JSON.stringify({"completed_categories": _completed,
		"failures": _failures, "acceptance_credit": false, "terrain_loaded": false}))
	quit(0 if _failures.is_empty() and _completed > 0 else 1)
