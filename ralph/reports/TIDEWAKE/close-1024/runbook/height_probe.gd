extends SceneTree
## Analytic Tidewake heights and trail clearance at given points (headless, no
## scene). Edit POINTS, then:
##   godot --headless --path . --script ralph/reports/TIDEWAKE/close-1024/runbook/height_probe.gd
## Note: summit cap/terraces apply only when their candidate is ON, so this
## reports the shipping (uncapped) field.
const POINTS := [Vector2(990.1, 2717.4), Vector2(233.2, 958.0)]


func _init() -> void:
	var hf: RefCounted = load("res://scripts/world/water_heightfield.gd").shared()
	print("sea ", hf.call("water_level"))
	for p: Vector2 in POINTS:
		print(p, " h=", snapped(float(hf.call("height_at", p.x, p.y)), 0.01),
			" trail=", snapped(float(hf.call("_nearest_trail_distance", p.x, p.y)), 0.1))
	quit()
