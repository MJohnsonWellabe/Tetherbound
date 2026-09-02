extends SceneTree

## Follow-up to _probe_wood_node_gap.gd: is the (40.5,-28) wood node's low Y
## (-3.62, vs ~0-1 for its neighbours) real terrain, or a placement bug?
## Reads the analytic terrain height at both failing coordinates directly,
## no world stand-up needed.
##
##   godot --headless --path . --script tools/_probe_wood_node_gap2.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const POINTS := {
	"S03-79 (40.5,-28) node_y=-3.62": Vector2(40.5, -28.0),
	"S03-91 (6,-34) node_y=0.98": Vector2(6.0, -34.0),
	"S03-65 (16,-28) node_y=0.89 [control, PASS via re-added equip]": Vector2(16.0, -28.0),
}


func _init() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	if config.is_empty():
		push_error("no terrain config")
		quit(1)
		return
	var field: RefCounted = HEIGHTFIELD.new(config)
	for label: String in POINTS.keys():
		var p: Vector2 = POINTS[label]
		var h: float = field.call("height_at", p.x, p.y)
		var slope: float = field.call("slope_degrees_at", p.x, p.y, 1.0)
		print("%s -- terrain height=%.2f slope=%.1fdeg" % [label, h, slope])
	quit(0)
