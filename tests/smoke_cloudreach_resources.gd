extends SceneTree

## Small live-scene harvest lifecycle. Uses the production Game, inventory,
## progression store, imported gather prop, prompt and harvest implementation.
## Direct gather() calls prove payout/lifecycle, not controller reachability or
## Cloudreach world placement. Never writes the owner's save file.

const PATCH := preload("res://scripts/world/cloudreach_resource_patch.gd")
const BAG := preload("res://autoload/inventory.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	await process_frame
	var game: Node = root.get_node("Game")
	game.set_process(false)
	game.inventory = BAG.new(game.items)
	game.progression = PROGRESSION.new()
	game.day = 4
	var spec: Dictionary = {}
	for candidate: Dictionary in PATCH.gatherable_nodes():
		if str(candidate.resource_id) == "cloudberry":
			spec = candidate
			break
	_check(not spec.is_empty(), "Cloudberry authored source missing")
	var patch: Node3D = PATCH.new()
	root.add_child(patch)
	patch.call("setup", spec)
	await process_frame
	var crop: Node3D = patch.get_node_or_null("DailyHarvest")
	_check(crop != null, "Ready crop missing")
	if crop == null:
		quit(1)
		return
	_check(crop.get_node_or_null("Interactable") != null, "Production gather prompt missing")
	while not game.inventory.is_full():
		game.inventory.add("axe", 1)
	crop.call("gather", "")
	_check(game.inventory.count("cloudberry") == 0, "Full bag credited berries")
	_check(not game.progression.has(PATCH.depletion_flag(spec, 4)), "Full bag depleted crop")
	game.inventory = BAG.new(game.items)
	crop.call("gather", "")
	_check(game.inventory.count("cloudberry") == int(spec.amount), "Gather did not pay exactly authored amount")
	_check(game.progression.has(PATCH.depletion_flag(spec, 4)), "Gather did not persist day identity")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(game.progression.save_data()))
	await process_frame
	await process_frame
	game.progression = PROGRESSION.new()
	game.progression.load_data(saved)
	patch.call("restore_progression_from_game", game)
	_check(patch.get_node_or_null("DailyHarvest") == null, "Same-day reload respawned consumed crop")
	game.day = 5
	patch.call("_process", 1.1)
	crop = patch.get_node_or_null("DailyHarvest")
	_check(crop != null, "New world day did not regrow crop")
	if crop != null:
		crop.call("gather", "")
	_check(game.inventory.count("cloudberry") == 2 * int(spec.amount), "Second-day yield missing")
	_check(game.progression.has(PATCH.depletion_flag(spec, 5)), "Second-day depletion missing")
	patch.queue_free()
	await process_frame
	print("CLOUDREACH RESOURCES %s — gather, full-bag refusal, saved depletion, day regrow" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
