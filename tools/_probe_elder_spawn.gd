extends SceneTree

## Verifies the PW2 elder descriptor actually reaches the creature: level
## bonus applied on top of the region's own roll, nameplate prefixed, gameplay
## size scaled (which is what drives reach and catch odds, not the art), and
## the behaviour overrides landed on this individual and on nobody else.
## The last clause is the one worth checking -- `configure()` is handed a
## dictionary derived from the shared wild config, and a merge that mutated
## the shared dict would quietly turn every wild in the meadow into an elder.

const SCENE := "res://scenes/world/meadows_playground.tscn"


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 200:
		await physics_frame

	var elders: Array = []
	var ordinary: Array = []
	for node in _all(world):
		# Matched on the species property, NOT the node name. Godot
		# auto-renames duplicate siblings, and `Wild_<species>_<n>` collides
		# across clusters the moment two clusters of one species exist -- the
		# first cut of this probe filtered by name and silently lost exactly
		# the two renamed nodes, one of which was the elder it was written to
		# find. Worth knowing: those names are also what encounter_director's
		# own comment says log lines get matched against.
		var instance: Variant = node.get("instance")
		if instance == null:
			continue
		if str(node.get("species_id")) != "mosshell":
			continue
		var entry := {
			"node": node,
			"name": str(instance.get("display_name")),
			"level": int(instance.get("level")),
			"radius": float(node.call("body_radius")) if node.has_method("body_radius") else -1.0,
			"pos": (node as Node3D).global_position,
		}
		if entry["name"].begins_with("Elder"):
			elders.append(entry)
		else:
			ordinary.append(entry)

	print("elder mosshells: %d   ordinary mosshells: %d" % [elders.size(), ordinary.size()])
	for e: Dictionary in elders:
		print("  ELDER    %-18s level=%-3d body_radius=%.3f at (%.0f, %.0f)" % [
			e["name"], e["level"], e["radius"], e["pos"].x, e["pos"].z])
	for e: Dictionary in ordinary:
		print("  ordinary %-18s level=%-3d body_radius=%.3f at (%.0f, %.0f)" % [
			e["name"], e["level"], e["radius"], e["pos"].x, e["pos"].z])
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
