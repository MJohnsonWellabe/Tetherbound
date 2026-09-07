extends SceneTree
## C1 diagnosis: at a stand the owner/judge calls a mown lawn, WHICH predicate
## refuses the grass? The fill and the ellipse pass agree about what counts as
## turf, so a bare plane is one of five answers and this says which.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")

var _stands := {
	"05-upper-cloudreach-cliffhold": Vector2(-400.0, 3890.0),
	"01-arrival-first-reveal": Vector2(0.0, -260.0),
}


func _initialize() -> void:
	var world: Node3D = SCENE.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var runtime := world.get_node_or_null("CloudreachWorld")
	var built: Node = runtime if runtime != null else world
	var look: Node = _find(built, "CloudreachLook")
	if look == null:
		print("no look node; children: ", built.get_children())
		quit(1)
		return
	for name: String in _stands.keys():
		var stand: Vector2 = _stands[name]
		print("\n=== %s at %s ===" % [name, str(stand)])
		var tally := {"no_hit": 0, "not_turf": 0, "excluded": 0, "settlement": 0,
			"route": 0, "plantable": 0}
		var tops := {}
		for ring in 10:
			var radius := 2.0 + float(ring) * 2.0
			for step in 16:
				var a := float(step) * TAU / 16.0
				var at := stand + Vector2(cos(a), sin(a)) * radius
				var hit: Dictionary = look.call("probe_turf_at", at)
				var verdict := str(hit.get("verdict", "no_hit"))
				tally[verdict] = int(tally.get(verdict, 0)) + 1
				var collider := str(hit.get("collider", ""))
				if collider != "":
					tops[collider] = int(tops.get(collider, 0)) + 1
		print("  r=2..20 m  ", tally)
		print("  colliders hit: ", tops)
	quit(0)


func _find(node: Node, needle: String) -> Node:
	if node.name.contains(needle):
		return node
	for child in node.get_children():
		var found := _find(child, needle)
		if found != null:
			return found
	return null
