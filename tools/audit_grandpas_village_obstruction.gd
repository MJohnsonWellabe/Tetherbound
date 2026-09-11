extends SceneTree

## Read-only inventory of committed scatter crossing the R1 square-arrival
## composition. It does not load the world, regenerate scatter, or write data.

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const STAND := Vector2(6.0, -22.0)
const TARGET := Vector2(8.0, -5.0)
const CAMERA_BACK_M := 4.6


func _init() -> void:
	var by_layer := BAKE.load_all("playground")
	var forward := (TARGET - STAND).normalized()
	var camera := STAND - forward * CAMERA_BACK_M
	for layer_name: String in by_layer.keys():
		for raw: Variant in by_layer.get(layer_name, []):
			var placement := raw as Dictionary
			var at3 := placement.get("position", Vector3.ZERO) as Vector3
			var at := Vector2(at3.x, at3.z)
			var delta := at - camera
			var depth := delta.dot(forward)
			var lateral := delta.cross(forward)
			if depth < 0.0 or depth > 32.0 or absf(lateral) > 8.0:
				continue
			if layer_name == "deadfall" or str(placement.get("model", "")).contains("DeadTree"):
				print("%s at=(%.3f, %.3f) depth=%.2f lateral=%.2f scale=%.2f model=%s" % [
					layer_name, at.x, at.y, depth, lateral,
					float(placement.get("scale", 0.0)), str(placement.get("model", ""))])
	quit(0)
