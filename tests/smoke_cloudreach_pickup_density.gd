extends SceneTree

## Focused production-world density/persistence smoke. This intentionally does
## not claim route-play evidence; the placement audit separately validates every
## authored point against the production surface registry.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const RULES := preload("res://scripts/world/cloudreach_physical_rules.gd")
const PHYSICAL := preload("res://scripts/world/cloudreach_physical_runtime.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	var flags: RefCounted = game.get("progression")
	flags.call("set_flag", "realm_key_cloudreach")
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 12:
		await physics_frame
	var chapter_node := world.get_node(^"CloudreachChapter")
	var physical := chapter_node.call("physical_runtime") as Node3D
	var chapter := RULES.read(PHYSICAL.CHAPTER_PATH)
	_expect(_present_count(physical, chapter["pickups"]) == _available_count(flags, chapter["pickups"]),
		"opening state builds exactly its unlocked density")
	flags.call("set_flag", "fly_traversal_unlocked")
	flags.call("set_flag", "cloudreach_upper_route_unlocked")
	physical.call("sync_progression")
	for _frame in 3:
		await process_frame
	_expect(_present_count(physical, chapter["pickups"]) == 178,
		"late chapter builds all 100 candy, 75 recovery and three TM placements")
	var first := physical.get_node_or_null(^"cr_candy_gate_route_good_01") as Node3D
	var second := physical.get_node_or_null(^"cr_candy_gate_route_good_02") as Node3D
	_expect(first != null and second != null, "two independent same-item density placements exist")
	if first != null:
		first.call("_on_picked_up")
		await process_frame
	_expect(CACHE.was_taken(game, "good_candy", "cr_candy_gate_route_good_01", "cloudreach"),
		"first density placement writes its realm-qualified cache flag")
	_expect(not CACHE.was_taken(game, "good_candy", "cr_candy_gate_route_good_02", "cloudreach"),
		"second same-item placement keeps an independent flag")
	physical.call("restore_progression_from_game", game)
	for _frame in 3:
		await process_frame
	var rebuilt: Dictionary = physical.get("_placements")
	_expect(not rebuilt.has("cr_candy_gate_route_good_01"),
		"taken density placement stays absent after progression rebuild")
	_expect(rebuilt.has("cr_candy_gate_route_good_02") \
		and is_instance_valid(rebuilt["cr_candy_gate_route_good_02"]),
		"untaken same-item placement survives progression rebuild")
	_expect(_present_count(physical, chapter["pickups"]) == 177,
		"only the collected world placement is removed")
	for failure: String in _failures:
		push_error("CLOUDREACH PICKUP DENSITY: " + failure)
	print("CLOUDREACH PICKUP DENSITY: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)


func _available_count(flags: RefCounted, specs: Array) -> int:
	var count := 0
	for spec: Dictionary in specs:
		var required := str(spec.get("requires_unlock", ""))
		if required.is_empty() or bool(flags.call("has", required)):
			count += 1
	return count


func _present_count(physical: Node, specs: Array) -> int:
	var count := 0
	var placements: Dictionary = physical.get("_placements")
	for spec: Dictionary in specs:
		if placements.has(str(spec["id"])) and is_instance_valid(placements[str(spec["id"])]):
			count += 1
	return count


func _expect(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)
