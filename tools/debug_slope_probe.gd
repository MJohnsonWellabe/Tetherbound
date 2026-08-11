extends SceneTree

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var centre := Vector2(140.0, -90.0)
	var bearing := Vector2(1.0, 0.0)
	for d in [0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0, 55.0, 58.0, 60.0, 65.0, 70.0]:
		var p: Vector2 = centre + bearing * d
		var h: float = field.height_at(p.x, p.y)
		var s1: float = field.slope_degrees_at(p.x, p.y, 1.0)
		var s6: float = field.slope_degrees_at(p.x, p.y, 6.0)
		print("d=%5.1f  xz=(%7.2f,%7.2f)  h=%6.2f  slope(1m)=%6.2f  slope(6m)=%6.2f" % [d, p.x, p.y, h, s1, s6])
	quit(0)
