extends SceneTree

## TREE-SILHOUETTE-0903. Checks ground height/slope at every new or moved
## anchor centre this pass adds, headless arithmetic on the analytic
## heightfield only (no render). Run before trusting a coordinate.
##
##   godot --headless --path . --script tools/_probe_tree_silhouette_0903.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const POINTS := {
	"gate east flank (20,50)": Vector2(20.0, 50.0),
	"gate west flank NEW (-4,58)": Vector2(-4.0, 58.0),
	"mound foot copse (60.5,-133.7)": Vector2(60.5, -133.7),
	"frame trunk (-58,199)": Vector2(-58.0, 199.0),
	"knoll crown (42,128)": Vector2(42.0, 128.0),
	"crest hero (-224,336)": Vector2(-224.0, 336.0),
	"crest pair (-232,330)": Vector2(-232.0, 330.0),
	"comp4 near-tree pin (-243,338)": Vector2(-243.0, 338.0),
	"first-bend a (-95,292)": Vector2(-95.0, 292.0),
	"first-bend b (-136,289)": Vector2(-136.0, 289.0),
	"far-side grove (-420,560)": Vector2(-420.0, 560.0),
	"far-side grove deadfall (-432,548)": Vector2(-432.0, 548.0),
	"shore clearing centre (-397,586)": Vector2(-397.0, 586.0),
	"fisher camp (-395.5,583.5)": Vector2(-395.5, 583.5),
	"mill (-383.5,517)": Vector2(-383.5, 517.0),
	"long field grove 1 (-120,650)": Vector2(-120.0, 650.0),
	"long field grove 2 (5,1235)": Vector2(5.0, 1235.0),
	"far-rim treeline (15,1385)": Vector2(15.0, 1385.0),
	"far-rim deadfall (30,1378)": Vector2(30.0, 1378.0),
	"bridge rim eye (11,1266)": Vector2(11.0, 1266.0),
}


func _init() -> void:
	var f: RefCounted = HEIGHTFIELD.new()
	print("water level %.2f" % float(f.water_level()))
	print("%-32s %8s %8s %7s %7s" % ["point", "x", "z", "h", "slope"])
	for label: String in POINTS.keys():
		var p: Vector2 = POINTS[label]
		var h: float = f.height_at(p.x, p.y)
		var hx: float = f.height_at(p.x + 1.0, p.y)
		var hz: float = f.height_at(p.x, p.y + 1.0)
		var dx := hx - h
		var dz := hz - h
		var slope := rad_to_deg(atan2(sqrt(dx * dx + dz * dz), 1.0))
		print("%-32s %8.1f %8.1f %7.2f %7.2f" % [label, p.x, p.y, h, slope])
	quit(0)
