extends SceneTree

## GF-B-001. Proves that a change to `water.gd::_bake_height_texture` produced
## the same 512x512 texture, byte for byte.
##
##   godot --headless --path . --script tools/_probe_water_bake_identity.gd
##
## The bake is the shader's only source of depth. Every visible property of
## both bodies of water -- where the surface fades out, where the foam band
## sits, how quickly shallow reads into deep -- is decoded from it, so an
## optimisation of the bake is allowed to be faster and is not allowed to be
## different. `tools/_probe_heightfield_cost.gd` checksums `height_at` for the
## same reason; this covers the other half, the part that turns those heights
## into pixels.
##
## The reference implementation below is the ORIGINAL loop, kept here rather
## than in `water.gd`: one `Image.set_pixel` per texel with a fresh `Color`.
## Holding it in the probe is the point -- the thing being checked has to be
## the code that shipped, not a paraphrase of the code that is being tested.

const WATER := preload("res://scripts/world/water.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SIZE := 512


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	field.call("height_at", 0.0, 0.0)

	var water: Node = WATER.new()
	water.set("_field", field)

	var failures := 0
	for name: String in _regions():
		var rect: Rect2 = _regions()[name]
		# The same window `_build_material` derives: the region's own range,
		# widened a metre each way.
		var low := INF
		var high := -INF
		for z in range(int(rect.position.y), int(rect.end.y) + 1, 4):
			for x in range(int(rect.position.x), int(rect.end.x) + 1, 4):
				var h := float(field.call("height_at", float(x), float(z)))
				low = minf(low, h)
				high = maxf(high, h)
		low -= 1.0
		high += 1.0

		var shipped: ImageTexture = water.call("_bake_height_texture", rect, low, high)
		var reference := _reference_bake(field, rect, low, high)
		var a := shipped.get_image().get_data()
		var b := reference.get_data()
		print("\n=== %s ===" % name)
		print("window %.3f .. %.3f m over %d bytes" % [low, high, b.size()])
		if a.size() != b.size():
			print("   FAIL: %d bytes against the reference's %d" % [a.size(), b.size()])
			failures += 1
			continue
		var differing := 0
		for i in a.size():
			if a[i] != b[i]:
				differing += 1
		if differing == 0:
			print("   IDENTICAL: %d of %d bytes differ" % [differing, b.size()])
		else:
			print("   FAIL: %d of %d bytes differ" % [differing, b.size()])
			failures += 1

	water.free()
	print("\n%s" % ("all regions identical" if failures == 0 else "%d region(s) DIFFER" % failures))
	quit(1 if failures > 0 else 0)


## The original bake, verbatim: `Image.create_empty` plus one `set_pixel` per
## texel. FORMAT_RF holds a 32-bit float and `Color`'s components are 32-bit
## floats, so both routes round the same double the same way -- which is the
## claim this probe exists to check rather than assert.
func _reference_bake(field: RefCounted, region: Rect2, height_min: float, height_max: float) -> Image:
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RF)
	var span := maxf(height_max - height_min, 0.001)
	for py in SIZE:
		var wz := region.position.y + (float(py) + 0.5) / SIZE * region.size.y
		for px in SIZE:
			var wx := region.position.x + (float(px) + 0.5) / SIZE * region.size.x
			var h := float(field.call("height_at", wx, wz))
			image.set_pixel(px, py, Color(clampf((h - height_min) / span, 0.0, 1.0), 0.0, 0.0))
	return image


## A small rect and a wide, extremely anisotropic one -- the real river rect is
## 2,091 x 186.5 m, so a bake that only ever sees square regions is not the
## bake this game runs.
func _regions() -> Dictionary:
	return {
		"square region": Rect2(-491.0, 449.0, 192.0, 192.0),
		"river-shaped region": Rect2(-1047.0, 4057.0, 2091.0, 186.5),
	}
