extends SceneTree

## Live single-host proof for the existing ledger path: a reachable opening
## Stormwood cache grants exactly once, sets its stable world flag, and is not
## rebuilt. Multiplayer races use this same ItemCachePickup -> ledger seam.
const RUNTIME := preload("res://scripts/world/stormwood_pickup_runtime.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	_expect(game != null, "Game autoload is available")
	if game == null:
		_finish()
		return
	game.call("reset_for_new_game")
	game.set("current_realm", "stormwood")
	var world := Node3D.new()
	world.name = "StormwoodPickupRuntimeSmokeWorld"
	root.add_child(world)
	var runtime := RUNTIME.new()
	runtime.name = "StormwoodPickupRuntime"
	world.add_child(runtime)
	runtime.mount(world)
	await process_frame
	var placements: Dictionary = runtime.get("_placements")
	_expect(placements.size() == 122, "opening flags mount all 122 currently reachable defined items")
	_expect(_all_have_meshes(placements), "every opening pickup has a populated visual child")
	var first := placements.get("stormwood_pickup_route_02") as Node3D
	_expect(first != null, "arrival route cache exists at its authored coordinate")
	if first != null:
		_expect(first.global_position == Vector3(-370.0, 29.646551, 500.0), "roadside cache preserves its moved authored coordinate")
		var before := int(game.get("inventory").count("good_candy"))
		first.call("_on_picked_up")
		await process_frame
		_expect(CACHE.was_taken(game, "good_candy", "stormwood_pickup_route_02", "stormwood"), "claim commits the realm-qualified stable flag")
		_expect(int(game.get("inventory").count("good_candy")) == before + 1, "host ledger grants exactly one item")
		var duplicate: Dictionary = game.get("ledger").call("submit", {
			"kind": "claim_pickup", "realm": "stormwood",
			"flag": CACHE.flag_id("good_candy", "stormwood_pickup_route_02", "stormwood"),
			"item": "good_candy", "count": 1,
		})
		_expect(not bool(duplicate.get("ok", false)) and str(duplicate.get("code", "")) == "already_taken",
			"second host claim is refused by the existing authority")
		_expect(int(game.get("inventory").count("good_candy")) == before + 1, "repeat claim cannot duplicate the item")
		runtime.restore_progression_from_game(game)
		await process_frame
		placements = runtime.get("_placements")
		_expect(not placements.has("stormwood_pickup_route_02"), "claimed placement is absent after rebuild")
		_expect(placements.has("stormwood_pickup_route_01"), "a neighboring same-item placement remains")
		game.get("progression").set_flag("stormwood:crown_reached")
		game.get("progression").set_flag("stormwood:rootgate_released")
		runtime.sync_progression()
		await process_frame
		placements = runtime.get("_placements")
		_expect(placements.size() == 221, "late unlocks mount every remaining defined ordinary item")
		_expect(_all_have_meshes(placements), "every late-unlocked pickup has a populated visual child")
		_expect(not placements.has("stormwood_pickup_pocket_202"), "undefined Stormwood TM remains withheld")
		_expect(not placements.has("stormwood_pickup_pocket_208"), "story reward remains event-owned and unmounted")
	world.queue_free()
	_finish()


func _expect(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)


func _all_have_meshes(placements: Dictionary) -> bool:
	for pickup: Variant in placements.values():
		if not _has_mesh(pickup as Node):
			return false
	return true


func _has_mesh(node: Node) -> bool:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return true
	for child: Node in node.get_children():
		if _has_mesh(child):
			return true
	return false


func _finish() -> void:
	for failure: String in _failures:
		push_error("STORMWOOD PICKUP RUNTIME: " + failure)
	print("STORMWOOD PICKUP RUNTIME: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
