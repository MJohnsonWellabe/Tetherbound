extends SceneTree

## Which trainers are actually STANDING in the world, and which only exist in
## trainers.json? The BAND1-D1 evidence run walked band1's spine and met one
## trainer body, so this asks the question directly rather than through a
## route walk that could simply have passed too far away.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame

	var standing := {}
	for node: Variant in _all(world):
		var n := node as Node3D
		if n != null and n.has_meta("trainer_id"):
			standing[str(n.get_meta("trainer_id"))] = n.global_position

	print("%-26s %-16s %s" % ["trainer", "placed_by", "standing in the world?"])
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		var id := str(spec.get("id", ""))
		var by := str(spec.get("placed_by", ""))
		var here: String = "no"
		if standing.has(id):
			var p: Vector3 = standing[id]
			here = "yes  at (%.0f, %.0f)" % [p.x, p.z]
		print("%-26s %-16s %s" % [id, by if by != "" else "(world pass)", here])
	quit(0)


## No default `into: Array = []` parameter here, deliberately. GDScript
## evaluates a default array argument ONCE and shares that same instance
## across every call, exactly like Python -- so a second `_all(world)` in the
## same run returns the first call's contents with the whole tree appended
## again. This probe called it twice and the second list came back doubled
## and reordered, which is how a trainer that is demonstrably standing in the
## world went missing from one report and not the other.
func _all(node: Node) -> Array:
	var out: Array = []
	_collect_all(node, out)
	return out


func _collect_all(node: Node, into: Array) -> void:
	into.append(node)
	for c in node.get_children():
		_collect_all(c, into)
