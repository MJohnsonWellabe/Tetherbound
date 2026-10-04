extends SceneTree

## F32#1: the actual mounted homestead Forge refines all four canonical
## outputs (Rootiron, Tidesteel, Skyglass ingots and Stormglass plate):
##
##   godot --headless --path . --script tests/smoke_f32_forge_plates.gd
##
## Disclosed fixtures: isolated save root; new game with one owned Terrapup,
## opening free-play flag, fixed character/world ids; trainer teleported to
## the open homestead yard used by smoke_f31_station_paid_path; the Forge's
## settled build price and each recipe's raw inputs (cost + 1 spare per input)
## seeded into the local inventory; one pre-refine owner/world save so the
## disk baseline exists. Nothing else is granted: recipe eligibility comes
## from the four prerequisite-free source recipes as production reads them.
## Production paths: paid build placement, StationPiece mount of ManualForge,
## the Forge panel's "Refine <name>" button -> Session.homestead_start_refining
## -> ForgeHost.start -> station_forge tap-start present channel (physics time)
## -> ForgeHost.commit_unit -> FoundationActions station_craft journal ->
## owner save and ACK. Assertions read the decoded on-disk saves.
## Local host only; not an ENet guest or earned-campaign proof.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SAVE := preload("res://scripts/save/save_game.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const DELIVERY := preload("res://scripts/net/homestead_building_delivery.gd")
const REFINING := preload("res://scripts/world/homestead_refining.gd")
const RECIPES := "res://data/recipes/recipes_forge.json"
const STANCE := Vector2(-6.0, 22.0)
const ORDER := ["rootiron_ingot", "tidesteel_ingot", "skyglass_ingot", "stormglass_plate"]

var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _saver: RefCounted
var _output := ""
var _failed := false
var _finished := false
var _completed: Array = []
var _stopped: Array = []


func _init() -> void:
	_run.call_deferred()


func _check(value: bool, label: String) -> bool:
	_failed = _failed or not value
	print("F32 FORGE %s: %s" % ["PASS" if value else "FAIL", label])
	return value


func _frames(count: int) -> void:
	for frame in count: await physics_frame


func _run() -> void:
	_output = "user://f32_forge_plates_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(_output)
	create_timer(300.0).timeout.connect(func() -> void:
		if not _finished:
			_check(false, "watchdog expired")
			_finish())
	_game = root.get_node_or_null(^"Game")
	if not _check(_game != null, "production Game autoload exists"): _finish(); return
	_saver = SAVE.new(_output.path_join("working"))
	_game.set("save_system", _saver)
	_game.call("reset_for_new_game")
	_game.set("current_realm", "meadows")
	_game.get("local").set("character_id", "f32-forge-owner")
	_game.get("world").set("world_id", "f32-forge-world")
	_game.get("party").call("add", preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	_game.get("progression").call("set_flag", "opening:beat:free_play")
	if not _check(change_scene_to_file(SCENE) == OK, "request actual Meadows scene"): _finish(); return
	for frame in 2400:
		await process_frame
		if current_scene != null and current_scene.has_method("shell_build_complete") \
			and current_scene.call("shell_build_complete") == true:
			_world = current_scene as Node3D
			break
	if not _check(_world != null, "Meadows build completed"): _finish(); return
	_player = _game.call("find_player") as CharacterBody3D
	if not _check(_player != null and _world.get_node_or_null(^"BuildPlacer") != null, "player and BuildPlacer exist"):
		_finish(); return
	var ground := float(_world.call("ground_height_at", STANCE.x, STANCE.y))
	_player.global_position = Vector3(STANCE.x, (ground if is_finite(ground) else 0.9) + 0.4, STANCE.y)
	_player.velocity = Vector3.ZERO
	await _frames(30)
	var forge := await _place_forge()
	if forge == null: _finish(); return
	var manual: Node = forge.get_node_or_null(^"ManualForge")
	if not _check(manual != null and manual.get_script() == preload("res://scripts/build/station_forge.gd"),
		"StationPiece mounted the production ManualForge actor"): _finish(); return
	manual.connect("unit_completed", func(recipe: String, units: int) -> void: _completed.append([recipe, units]))
	manual.connect("channel_stopped", func(code: String, reason: String) -> void: _stopped.append([code, reason]))
	# Stand beside the Forge's interaction origin, inside the recipe radius.
	var origin: Vector3 = forge.call("interaction_origin")
	_player.global_position = Vector3(origin.x, _player.global_position.y, origin.z + 1.2)
	_player.velocity = Vector3.ZERO
	await _frames(20)
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RECIPES))
	for recipe_id: String in ORDER:
		await _refine(forge, manual, recipe_id, source.recipes[recipe_id])
	_finish()


func _place_forge() -> Node3D:
	var cost := DELIVERY.cost("forge")
	for need: Dictionary in cost: _game.get("inventory").call("add", need.id, int(need.n))
	var uid := "b%d" % int(_game.get("world").next_building_uid)
	_game.set("pending_build", "forge")
	await _frames(30)
	Input.action_press("build_place")
	await _frames(2)
	Input.action_release("build_place")
	var node: Node3D = null
	for frame in 240:
		await physics_frame
		for candidate: Node in get_nodes_in_group("placed_building"):
			if candidate.get_meta("building_uid", "") == uid and _world.is_ancestor_of(candidate): node = candidate as Node3D
		if node != null and node.get_node_or_null(^"ManualForge") != null: break
	if not _check(node != null, "paid Forge placed through build_place (%s)" % uid): return null
	Input.action_press("build_cancel")
	await _frames(2)
	Input.action_release("build_cancel")
	await _frames(10)
	return node


func _refine(forge: Node3D, manual: Node, recipe_id: String, recipe: Dictionary) -> void:
	var inventory: RefCounted = _game.get("inventory")
	# Fixture: cost + one spare of every input, so an over-debit is visible.
	for need: Dictionary in recipe.cost: inventory.call("add", need.id, int(need.n) + 1)
	_saver.call("finish_fallback")
	if not _check(_saver.call("save_world_prepared", _game, str(_game.get("world").world_id)) == true \
		and _saver.call("save_character_prepared", _game, str(_game.get("local").character_id)) == true,
		recipe_id + " pre-refine fixture saved to isolated disk"): return
	var before := _disk()
	var receipts_before: Array = before.character.get("redesign_character", {}).get("transaction_receipts", []).duplicate()
	_completed.clear()
	_stopped.clear()
	# The Forge's own panel button is the tap-start the player presses.
	forge.call("_open")
	await _frames(4)
	var button: Button = null
	for node: Node in root.find_children("*", "Button", true, false):
		if node.get_meta("station_focus_key", "") == "refine:" + recipe_id: button = node as Button
	if not _check(button != null, recipe_id + " Forge panel offers its Refine button"): return
	button.pressed.emit()
	var started_frame := Engine.get_physics_frames()
	if not _check(manual.get("_running") == true or not manual.get("_pending").is_empty(),
		recipe_id + " tap started one present channel (stops: %s)" % str(_stopped)): return
	var saved := false
	for frame in 900:
		await physics_frame
		if not _completed.is_empty() and manual.get("_running") != true and manual.get("_pending").is_empty():
			saved = true
			break
		if not _stopped.is_empty(): break
	var elapsed := float(Engine.get_physics_frames() - started_frame) / float(Engine.physics_ticks_per_second)
	if not _check(saved and _completed == [[recipe_id, 1]],
		recipe_id + " channel completed one canonical unit after %.2fs (completed %s, stops %s)" % [elapsed, str(_completed), str(_stopped)]): return
	_check(elapsed >= float(REFINING.manual_channel(JSON.parse_string(FileAccess.get_file_as_string(RECIPES))).seconds_per_unit),
		recipe_id + " unit waited the configured present-channel time")
	var after := _disk()
	var deltas := {}
	for need: Dictionary in recipe.cost:
		deltas[need.id] = _count(after.character, need.id) - _count(before.character, need.id)
		_check(deltas[need.id] == -int(need.n) and _count(after.character, need.id) == 1,
			"%s debited exactly %d %s on disk (delta %d, left %d)" % [recipe_id, int(need.n), need.id, deltas[need.id], _count(after.character, need.id)])
	var out: Dictionary = recipe.output
	var gained := _count(after.character, out.id) - _count(before.character, out.id)
	_check(gained == int(out.n), "%s yielded exactly %d %s on disk (delta %d)" % [recipe_id, int(out.n), out.id, gained])
	var row: Dictionary = {}
	for value: Variant in after.world.get("reward_deliveries", {}).values():
		if value is Dictionary and value.get("action") == "station_craft" and value.get("intent", {}).get("recipe_id") == recipe_id: row = value
	var craft_id := str(row.get("intent", {}).get("craft_id", ""))
	var receipt := "craft:%s:%s" % [str(_game.get("local").character_id), craft_id]
	var receipts: Array = after.character.get("redesign_character", {}).get("transaction_receipts", [])
	_check(row.get("status") == "accepted" and craft_id.length() == 32 and row.get("receipt") == receipt,
		"%s saved world journal row accepted with receipt %s" % [recipe_id, str(row.get("receipt", "<none>"))])
	_check(receipts.has(receipt) and not receipts_before.has(receipt) and receipts.size() == receipts_before.size() + 1,
		"%s saved character holds exactly one new receipt" % recipe_id)
	print("F32 FORGE UNIT %s: debits %s, +%d %s, receipt %s" % [recipe_id, str(deltas), gained, out.id, receipt])


func _disk() -> Dictionary:
	_saver.call("finish_fallback")
	var result := {}
	var paths := {"world": _saver.call("worlds").call("path_for", str(_game.get("world").world_id)),
		"character": _saver.call("characters").call("path_for", str(_game.get("local").character_id))}
	for kind: String in paths:
		# Saves are codec envelopes; decode exactly as the production loader does.
		var decoded: Variant = DOCUMENT.parse(FileAccess.get_file_as_string(paths[kind]))
		result[kind] = decoded if decoded is Dictionary else {}
	return result


func _count(character: Dictionary, item: String) -> int:
	var count := 0
	for slot: Variant in character.get("inventory", []):
		if slot is Dictionary and slot.get("id") == item: count += int(slot.get("n", 0))
	return count


func _finish() -> void:
	if _finished: return
	_finished = true
	print("")
	print("F32 forge plates smoke %s" % ("FAILED" if _failed else "passed"))
	quit(1 if _failed else 0)
