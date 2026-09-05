extends SceneTree

## Live cache removal, next-day resource regrowth and replacement-scene
## regression for the shared two-layer pickup glow field.
const GLOW := preload("res://scripts/world/pickup_glow.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const PATCH := preload("res://scripts/world/cloudreach_resource_patch.gd")
var _failures: Array[String] = []
var _assertions := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "cloudreach"
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var cache := CACHE.new()
	world.add_child(cache)
	cache.setup("good_candy", "Take candy", "res://assets/props/candy_pickup/candy_pickup.glb", 1.0, "lifecycle_candy", "cloudreach")
	var field := world.get_node(NodePath(GLOW.FIELD_NAME))
	await process_frame
	field.call("_process", 0.0)
	_check(field.highlight_count() == 1, "real cache registers a live highlight")
	var original_transform: Transform3D = field.get("_motes").multimesh.get_instance_transform(0)
	cache.visible = false
	field.call("_process", 0.0)
	_check(field.highlight_count() == 1, "hidden live emitter remains registered")
	_check(not bool(field.get("_entries")[0]["shown"]), "hidden emitter retains existing visibility projection")
	cache.visible = true
	field.call("_process", 0.0)
	_check(field.get("_motes").multimesh.get_instance_transform(0) == original_transform, "live emitter transform remains unchanged")
	cache.call("_on_picked_up")
	await process_frame
	field.call("_process", 0.0)
	_check(field.highlight_count() == 0, "taken cache detaches highlight")
	var discarded := Node3D.new()
	world.add_child(discarded)
	GLOW.attach(discarded, Color.WHITE)
	discarded.free()
	field.call("_process", 0.0)
	_check(field.highlight_count() == 0, "freed reference is pruned before casting")
	var detached := Node3D.new()
	world.add_child(detached)
	GLOW.attach(detached, Color.WHITE)
	world.remove_child(detached)
	field.call("_process", 0.0)
	_check(field.highlight_count() == 0, "out-of-tree reference is pruned without reading global transform")
	detached.free()
	var patch := PATCH.new()
	world.add_child(patch)
	var node_spec: Dictionary = {}
	for spec: Dictionary in PATCH.gatherable_nodes():
		if spec["resource_id"] == "cloudberry":
			node_spec = spec
			break
	patch.setup(node_spec)
	await process_frame
	field.call("_process", 0.0)
	var before_regrow: int = field.highlight_count()
	_check(before_regrow > 0, "real Cloudberry crop registered before next-day replacement")
	game.day += 1
	patch.call("_refresh", game)
	await process_frame
	await process_frame
	field.call("_process", 0.0)
	_check(field.highlight_count() == before_regrow, "day-advance resource replacement prunes the old crop and retains the new one")
	_check(field.highlight_positions().size() == before_regrow, "position query sees only live emitters")
	var next_world := Node3D.new()
	root.add_child(next_world)
	current_scene = next_world
	world.queue_free()
	await process_frame
	await process_frame
	var replacement := Node3D.new()
	next_world.add_child(replacement)
	GLOW.attach(replacement, Color.GOLD)
	var next_field := next_world.get_node(NodePath(GLOW.FIELD_NAME))
	next_field.call("_process", 0.0)
	_check(next_field.highlight_count() == 1, "replacement scene has one fresh field without stale previous-scene references")
	for failure: String in _failures:
		printerr("FAIL: " + failure)
	print("PICKUP GLOW LIFECYCLE: %d assertions, %d failures" % [_assertions, _failures.size()])
	next_world.free()
	quit(0 if _failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		_failures.append(message)
