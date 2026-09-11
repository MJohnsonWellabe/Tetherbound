extends SceneTree

## Read-only committed-bake audit for the real Ironwood Grove arrival frame.
## This never loads the production world, regenerates scatter, or writes output.
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const STAND := Vector2(-321.0, 5025.0)
const TARGET := Vector2(-344.0, 5075.0)
const CAMERA_BACK_M := 5.2


func _init() -> void:
	var by_layer := BAKE.load_all("playground")
	var forward := (TARGET - STAND).normalized()
	var camera := STAND - forward * CAMERA_BACK_M
	for layer_name: String in ["trees", "grove", "saplings"]:
		for raw: Variant in by_layer.get(layer_name, []):
			var placement := raw as Dictionary
			var at3 := placement.get("position", Vector3.ZERO) as Vector3
			var at := Vector2(at3.x, at3.z)
			var delta := at - camera
			var depth := delta.dot(forward)
			var lateral := absf(delta.cross(forward))
			if depth < 0.0 or depth > 42.0 or lateral > 13.0:
				continue
			print("%s at=(%.2f, %.2f) depth=%.2f lateral=%.2f scale=%.2f model=%s" % [
				layer_name, at.x, at.y, depth, lateral,
				float(placement.get("scale", 0.0)), str(placement.get("model", ""))])
	quit(0)
