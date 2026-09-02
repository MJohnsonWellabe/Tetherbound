extends SceneTree

## One-off: why S03's wood gathers at (40.5,-28) and (6,-34) yield nothing
## despite a correct axe equip, while the other five wood nodes succeed.
## Lists every harvest_node.gd instance in the built world near each target
## coordinate: position, resource kind, remaining state, and distance from
## the script's own walk target.
##
##   godot --headless --path . --script tools/_probe_wood_node_gap.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300

var _world: Node

const TARGETS := {
	"S03-65 (16,-28) wood, no equip -- explained": Vector2(16.0, -28.0),
	"S03-79 (40.5,-28) wood, FAIL, equipped": Vector2(40.5, -28.0),
	"S03-91 (6,-34) wood, FAIL, equipped": Vector2(6.0, -34.0),
	"S03-75 (36,-16) wood, PASS": Vector2(36.0, -16.0),
	"S03-87 (26,-44) wood, PASS": Vector2(26.0, -44.0),
}


func _init() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	var nodes: Array[Node3D] = []
	_collect(_world, nodes)
	print("total harvest_node.gd instances in world: %d" % nodes.size())

	for label: String in TARGETS.keys():
		var target: Vector2 = TARGETS[label]
		var nearest: Node3D = null
		var nearest_d := INF
		var within10: Array[String] = []
		for n in nodes:
			var d := Vector2(n.global_position.x, n.global_position.z).distance_to(target)
			if d < nearest_d:
				nearest_d = d
				nearest = n
			if d <= 10.0:
				var kind := str(n.call("resource_item")) if n.has_method("resource_item") else "?"
				var respawn_left := float(n.get("_respawn_left")) if n.get("_respawn_left") != null else -1.0
				within10.append("  %s at (%.2f,%.2f,%.2f) kind=%s dist=%.2fm respawn_left=%.1f" % [
					n.name, n.global_position.x, n.global_position.y, n.global_position.z,
					kind, d, respawn_left])
		print("")
		print("=== %s -- target (%.1f,%.1f) ===" % [label, target.x, target.y])
		if nearest != null:
			var kind2 := str(nearest.call("resource_item")) if nearest.has_method("resource_item") else "?"
			print("  NEAREST: %s at (%.2f,%.2f,%.2f) kind=%s dist=%.2fm" % [
				nearest.name, nearest.global_position.x, nearest.global_position.y,
				nearest.global_position.z, kind2, nearest_d])
		else:
			print("  NEAREST: none found at all")
		print("  within 10m (%d):" % within10.size())
		for line in within10:
			print(line)

	quit(0)


func _collect(node: Node, out: Array[Node3D]) -> void:
	var script: Script = node.get_script()
	if script != null and str(script.resource_path).ends_with("harvest_node.gd"):
		out.append(node as Node3D)
	for child in node.get_children():
		_collect(child, out)
