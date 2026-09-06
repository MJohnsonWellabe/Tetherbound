extends SceneTree

## Diagnostic: ray/shape-cast around the two stuck coordinates the walk
## smokes report, printing every collider (name, path, hit height) so the
## geometry standing in the walker's way is named rather than guessed.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
var world: Node3D
var space: PhysicsDirectSpaceState3D


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node(^"Game")
	game.current_realm = "cloudreach"
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 6:
		await physics_frame
	space = world.get_world_3d().direct_space_state
	var probes := [
		{"label": "arrival", "at": Vector3(-80.45, 128.97, 26.51), "pad": Vector3(-80, 130, 40), "from": Vector3(0, 105, -260)},
		{"label": "summit", "at": Vector3(109, 1158, 5339), "pad": Vector3(100, 1160, 5350), "from": Vector3(300, 1080, 5100)},
	]
	for probe: Dictionary in probes:
		var at: Vector3 = probe["at"]
		var pad: Vector3 = probe["pad"]
		var from: Vector3 = probe["from"]
		var dir := Vector3(pad.x - from.x, 0, pad.z - from.z).normalized()
		print("=== %s: stuck=%s pad=%s dir=%s" % [probe["label"], at, pad, dir])
		# Down-rays along the approach line: every 1 m from 24 m before the pad to the pad centre.
		for step in range(-24, 3):
			var p := pad + dir * float(step)
			var stack := _down_stack(p + Vector3.UP * 6.0, 12.0)
			print("  d=%+3d xz=(%.1f,%.1f) %s" % [step, p.x, p.z, stack])
		# Lateral profile at the stuck point's radial distance.
		var right := Vector3.UP.cross(dir)
		var radial := Vector2(at.x - pad.x, at.z - pad.z).length()
		for lat: float in [-10.0, -6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0, 10.0]:
			var p := pad - dir * radial + right * lat
			print("  lateral=%+.0f at r=%.1f xz=(%.1f,%.1f) %s" % [lat, radial, p.x, p.z, _down_stack(p + Vector3.UP * 6.0, 12.0)])
		# Forward rays from the stuck point at several heights.
		for h: float in [0.1, 0.3, 0.5, 0.8, 1.2, 1.6]:
			var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * h, at + Vector3.UP * h + dir * 5.0)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				print("  forward h=%.1f: clear" % h)
			else:
				print("  forward h=%.1f: %s at %s n=%s" % [h, _name(hit["collider"]), hit["position"], hit["normal"]])
	quit(0)


func _down_stack(from: Vector3, length: float) -> String:
	var out := ""
	var start := from
	for _attempt in 6:
		var q := PhysicsRayQueryParameters3D.create(start, from + Vector3.DOWN * length)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			break
		out += "%s@y=%.2f " % [_name(hit["collider"]), (hit["position"] as Vector3).y]
		start = (hit["position"] as Vector3) - Vector3.UP * 0.02
	return out if out != "" else "HOLE"


func _name(collider: Object) -> String:
	if collider is Node:
		var node := collider as Node
		var parent := node.get_parent()
		return str(parent.name) if parent != null else str(node.name)
	return str(collider)
