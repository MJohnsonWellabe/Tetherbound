extends SceneTree

## Isolated allocation diagnosis. No world scene, save, terrain or render.
const BAKER = preload("res://scripts/world/map_baker.gd")
const EXTENT = preload("res://scripts/world/world_extent.gd")

class FlatWorld extends RefCounted:
	func ground_height_at(_x: float, _z: float) -> float:
		return -100.0

func _initialize() -> void:
	call_deferred("_probe")

func _receipt(stage: String) -> void:
	print("ALLOC_PROBE ", JSON.stringify({"stage": stage, "pid": OS.get_process_id(), "static_bytes": OS.get_static_memory_usage(), "peak_static_bytes": OS.get_static_memory_peak_usage(), "system": OS.get_memory_info()}))

func _probe() -> void:
	_receipt("start")
	var bounds: Dictionary = EXTENT.bounds()
	var width: int = maxi(1, int(ceil((bounds.max_x - bounds.min_x) / BAKER.DEFAULT_METRES_PER_PIXEL)))
	var height: int = maxi(1, int(ceil((bounds.max_z - bounds.min_z) / BAKER.DEFAULT_METRES_PER_PIXEL)))
	print("ALLOC_DIMENSIONS ", JSON.stringify({"bounds": bounds, "source": [width, height], "output": [width * BAKER.PRODUCTION_OUTPUT_SCALE, height * BAKER.PRODUCTION_OUTPUT_SCALE], "source_rgb_bytes": width * height * 3, "output_rgb_bytes": width * height * 12}))
	var direct := Image.create(width, height, false, Image.FORMAT_RGB8)
	_receipt("before_direct_resize")
	direct.resize(width * BAKER.PRODUCTION_OUTPUT_SCALE, height * BAKER.PRODUCTION_OUTPUT_SCALE, Image.INTERPOLATE_BILINEAR)
	_receipt("after_direct_resize")
	assert(direct.get_size() == Vector2i(width * 2, height * 2))
	direct = null
	var texture: ImageTexture = BAKER.bake(FlatWorld.new())
	_receipt("after_production_bake")
	assert(texture.get_size() == Vector2(width * 2, height * 2))
	print("ALLOC_PROBE PASS")
	quit(0)
