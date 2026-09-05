extends SceneTree

## Real production geometry placement audit, separate from continuous walking.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const RULES := preload("res://scripts/world/cloudreach_physical_rules.gd")
const PHYSICAL := preload("res://scripts/world/cloudreach_physical_runtime.gd")
var failures: Array[String] = []
var checked := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node("Game")
	game.current_realm = "cloudreach"
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for i in 5:
		await physics_frame
	var data := RULES.read(PHYSICAL.DATA_PATH)
	var chapter := RULES.read(PHYSICAL.CHAPTER_PATH)
	for spec: Dictionary in data["interactions"]:
		_check(world, spec["id"], RULES.vec(spec["position"]))
	for spec: Dictionary in data["landing_objectives"] + data["ground_triggers"]:
		_check(world, spec["id"], RULES.vec(spec["position"]))
	for spec: Dictionary in chapter["pickups"]:
		_check(world, spec["id"], RULES.vec(data["pickup_overrides"][spec["id"]]))
	for spec: Dictionary in chapter["camping_contract"]["camps"]:
		_check(world, spec["id"], RULES.vec(spec["position"]))
	for spec: Dictionary in RULES.npc_specs(chapter, RULES.read(PHYSICAL.NPC_PATH), game.progression, data.get("npc_position_overrides", {})):
		_check(world, spec["id"], RULES.vec(spec["position"]))
	for failure: String in failures:
		printerr("PLACEMENT: " + failure)
	print("CLOUDREACH PHYSICAL PLACEMENTS: %d checked, %d failures" % [checked, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check(world: Node, id: String, at: Vector3) -> void:
	checked += 1
	var height := float(world.call("ground_height_near", at))
	if is_nan(height) or absf(height - at.y) > 8.0:
		failures.append("%s at %s has ground %s" % [id, at, height])
