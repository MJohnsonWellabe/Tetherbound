extends SceneTree

## Live single-host proof for the existing ledger path: a reachable opening
## Stormwood cache grants exactly once, sets its stable world flag, and is not
## rebuilt. Multiplayer races use this same ItemCachePickup -> ledger seam.
const RUNTIME := preload("res://scripts/world/stormwood_pickup_runtime.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const POCKETS := preload("res://scripts/world/stormwood_pockets.gd")

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
	_expect(placements.size() == 123, "opening flags mount the route caches and the available Static Snap TM")
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
		var static_snap := placements.get("stormwood_pickup_pocket_202") as Node3D
		_expect(static_snap != null, "available Static Snap TM mounts as a regular Stormwood cache")
		if static_snap != null:
			var tm_before := int(game.get("inventory").count("tm_static_snap"))
			static_snap.call("_on_picked_up")
			await process_frame
			_expect(CACHE.was_taken(game, "tm_static_snap", "stormwood_pickup_pocket_202", "stormwood"),
				"Static Snap TM claim commits its realm-qualified stable flag")
			_expect(int(game.get("inventory").count("tm_static_snap")) == tm_before + 1,
				"Static Snap TM reaches the satchel through the host ledger")
			runtime.restore_progression_from_game(game)
			await process_frame
			placements = runtime.get("_placements")
			_expect(not placements.has("stormwood_pickup_pocket_202"), "claimed Static Snap TM is absent after rebuild")
		game.get("progression").set_flag("stormwood:crown_reached")
		game.get("progression").set_flag("stormwood:rootgate_released")
		runtime.sync_progression()
		await process_frame
		placements = runtime.get("_placements")
		_expect(placements.size() == 224, "late unlocks mount every remaining defined ordinary item")
		_expect(_all_have_meshes(placements), "every late-unlocked pickup has a populated visual child")
		_expect(placements.has("stormwood_pickup_pocket_203"), "Crown-gated Voltaic Whip TM mounts after crown progress")
		_expect(placements.has("stormwood_pickup_pocket_204"), "Rootgate-gated Thunder Break TM mounts after rootgate progress")
		_expect(placements.has("stormwood_pickup_pocket_205"), "Rootgate-gated Stormfall TM mounts after rootgate progress")
		_expect(not placements.has("stormwood_pickup_pocket_208"), "story reward remains event-owned and unmounted")
		await _reward_shafts_are_unclaimed_only(game, runtime)
	world.queue_free()
	_finish()


## WO-F09-05 round 5: each pocket reward's light shafts (over the reward and
## at its gateway) exist only while that reward is unclaimed. An ordinary
## route cache has none (control); claiming one reward removes exactly its
## two shafts and leaves every other mounted pocket reward's pair.
func _reward_shafts_are_unclaimed_only(game: Node, runtime: Node) -> void:
	var rewards: Array[String] = []
	for pocket: Dictionary in POCKETS.config().pockets:
		rewards.append(str(pocket.reward_pickup_id))
	var placements: Dictionary = runtime.get("_placements")
	var mounted := 0
	for id: String in rewards:
		var reward := placements.get(id) as Node3D
		if reward == null:
			continue
		mounted += 1
		_expect(reward.get_node_or_null("RewardShaft") != null and reward.get_node_or_null("GateShaft") != null,
			"unclaimed pocket reward %s carries its reward and gate shafts" % id)
	_expect(mounted == rewards.size(), "all five pocket rewards are mounted once unlocked (%d)" % mounted)
	var route := placements.get("stormwood_pickup_route_01") as Node3D
	_expect(route != null and route.get_node_or_null("RewardShaft") == null, "control: an ordinary route cache has no shaft")
	_expect(_shafts(runtime).size() == 2 * mounted, "two shafts per unclaimed pocket reward, none elsewhere")
	var claimed := placements.get(rewards[0]) as Node3D
	var item := str(claimed.get("_item_id")) if claimed.get("_item_id") != null else ""
	claimed.call("_on_picked_up")
	await process_frame
	await process_frame
	runtime.restore_progression_from_game(game)
	await process_frame
	var left := _shafts(runtime)
	_expect(left.size() == 2 * (mounted - 1), "claiming %s removes exactly its two shafts (%d left)" % [rewards[0], left.size()])
	for shaft: Node in left:
		_expect(str(shaft.get_parent().name) != rewards[0], "no shaft remains for the claimed %s" % rewards[0])
	print("REWARD SHAFTS mounted=%d before=%d after_claim=%d claimed=%s item=%s" % [mounted, 2 * mounted, left.size(), rewards[0], item])


func _shafts(runtime: Node) -> Array[Node]:
	var out: Array[Node] = []
	for node: Node in runtime.find_children("*", "MeshInstance3D", true, false):
		if str(node.name) in ["RewardShaft", "GateShaft"] and is_instance_valid(node) and not node.is_queued_for_deletion():
			out.append(node)
	return out


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
