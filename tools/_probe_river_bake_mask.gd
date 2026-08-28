extends SceneTree

## GF-B-001. Proves the river's masked height bake is identical to a full one
## everywhere the river's surface can read it.
##
##   godot --headless --path . --script tools/_probe_river_bake_mask.gd
##
## `water.gd::_river_surface_mask` skips baking texels the river's surface does
## not lie over, on the argument that a fragment shader only runs on fragments
## of its own mesh. That argument is worth exactly nothing unsupported, because
## a mask that is a few texels too small produces a band of wrong depth along
## one bank, and no headless smoke test would see it: the geometry counts do
## not change, and neither does anything else a test currently asserts.
##
## So this does not check the mask against the reasoning that produced it. It
## stands the real composer up, takes the RiverSurface mesh that was ACTUALLY
## built, rasterises its triangles into texel space, dilates by one texel for
## bilinear filtering, and compares the shipped texture against a full unmasked
## bake over every texel in that set. The mask code has no say in which texels
## get checked.
##
## Triangles are rasterised as their bounding boxes -- a superset of the true
## coverage, which makes the test STRICTER than the mesh, not looser.

const WATER := preload("res://scripts/world/water.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SIZE := 512


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var water: Node = WATER.new()
	root.add_child(water)
	water.build()

	var surface: MeshInstance3D = water.get_node_or_null(^"RiverSurface") as MeshInstance3D
	if surface == null:
		print("FAIL: the composer built no RiverSurface")
		quit(1)
		return
	var material := surface.material_override as ShaderMaterial
	if material == null:
		print("FAIL: RiverSurface carries no ShaderMaterial")
		quit(1)
		return

	var packed: Vector4 = material.get_shader_parameter("region")
	var region := Rect2(packed.x, packed.y, packed.z, packed.w)
	var height_min := float(material.get_shader_parameter("height_min"))
	var height_max := float(material.get_shader_parameter("height_max"))
	var shipped: Image = (material.get_shader_parameter("terrain_height") as ImageTexture).get_image()

	print("river region  %.1f,%.1f  %.1f x %.1f m  (%.3f x %.3f m/texel)" % [
		region.position.x, region.position.y, region.size.x, region.size.y,
		region.size.x / SIZE, region.size.y / SIZE])
	print("depth window  %.3f .. %.3f m" % [height_min, height_max])

	var reachable := _texels_the_surface_covers(surface, region)
	var covered := 0
	for flag: int in reachable:
		covered += flag
	print("the built mesh, dilated by one texel, covers %d of %d texels (%.1f%%)" % [
		covered, reachable.size(), 100.0 * float(covered) / float(reachable.size())])

	# The reference: a full bake over the same rect and the same window, with
	# no mask anywhere near it.
	var field: RefCounted = HEIGHTFIELD.new()
	field.call("height_at", 0.0, 0.0)
	var span := maxf(height_max - height_min, 0.001)
	# The texture holds 32-bit floats. `clampf` returns a 64-bit one, and the
	# two are almost never bit-equal, so the reference has to be rounded the
	# same way the bake's own `Color` component rounds it before any comparison
	# means anything. A one-element PackedFloat32Array is that rounding.
	var narrow := PackedFloat32Array()
	narrow.resize(1)
	var differing := 0
	var worst := 0.0
	var sampled_outside := 0
	for py in SIZE:
		var wz := region.position.y + (float(py) + 0.5) / SIZE * region.size.y
		for px in SIZE:
			var index := py * SIZE + px
			var have := shipped.get_pixel(px, py).r
			if reachable[index] == 0:
				if have < 1.0:
					sampled_outside += 1
				continue
			var wx := region.position.x + (float(px) + 0.5) / SIZE * region.size.x
			narrow[0] = clampf(
				(float(field.call("height_at", wx, wz)) - height_min) / span, 0.0, 1.0)
			var want: float = narrow[0]
			if have != want:
				differing += 1
				worst = maxf(worst, absf(have - want))

	print("\n=== every texel the surface can read ===")
	if differing == 0:
		print("   IDENTICAL: 0 of %d differ from a full unmasked bake" % covered)
	else:
		print("   FAIL: %d of %d differ, worst by %.6f of the window (%.4f m)" % [
			differing, covered, worst, worst * span])
	print("\n=== texels the surface cannot read ===")
	print("   %d of %d were baked anyway (mask slack; harmless, just not saved)" % [
		sampled_outside, reachable.size() - covered])
	print("   %d were filled with the ceiling and never sampled -- %.1f%% of the bake saved" % [
		reachable.size() - covered - sampled_outside,
		100.0 * float(reachable.size() - covered - sampled_outside) / float(reachable.size())])

	quit(1 if differing > 0 else 0)


## Texel coverage of the mesh as it was actually built, from its own vertex
## array, dilated by one texel on every side.
##
## Bounding box per triangle rather than a scanline fill: it marks strictly
## more texels than the triangle covers, so anything this test passes is safe
## for the real coverage too. The dilation is what bilinear filtering needs --
## a fragment at the very edge of the mesh samples the four texels around its
## position, and up to three of those lie outside the footprint.
func _texels_the_surface_covers(surface: MeshInstance3D, region: Rect2) -> PackedByteArray:
	var hit := PackedByteArray()
	hit.resize(SIZE * SIZE)
	var arrays: Array = surface.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	# `SurfaceTool.commit()` without `index()` produces a non-indexed surface,
	# and Godot hands back a Nil in that slot rather than an empty array. The
	# river's ribbon is one of those, so this cannot be typed straight through.
	var index_data: Variant = arrays[Mesh.ARRAY_INDEX]
	var indices := PackedInt32Array() if index_data == null else index_data as PackedInt32Array
	var count := indices.size() if indices.size() > 0 else vertices.size()
	print("mesh: %d vertices, %d indices, %d triangles" % [
		vertices.size(), indices.size(), count / 3])

	var raw := PackedByteArray()
	raw.resize(SIZE * SIZE)
	var i := 0
	while i + 2 < count:
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for k in 3:
			var v: Vector3 = vertices[indices[i + k]] if indices.size() > 0 else vertices[i + k]
			lo = Vector2(minf(lo.x, v.x), minf(lo.y, v.z))
			hi = Vector2(maxf(hi.x, v.x), maxf(hi.y, v.z))
		var px0 := clampi(int(floor((lo.x - region.position.x) / region.size.x * SIZE)), 0, SIZE - 1)
		var px1 := clampi(int(ceil((hi.x - region.position.x) / region.size.x * SIZE)), 0, SIZE - 1)
		var py0 := clampi(int(floor((lo.y - region.position.y) / region.size.y * SIZE)), 0, SIZE - 1)
		var py1 := clampi(int(ceil((hi.y - region.position.y) / region.size.y * SIZE)), 0, SIZE - 1)
		for py in range(py0, py1 + 1):
			for px in range(px0, px1 + 1):
				raw[py * SIZE + px] = 1
		i += 3

	for py in SIZE:
		for px in SIZE:
			if raw[py * SIZE + px] == 0:
				continue
			for dy in [-1, 0, 1]:
				var ny: int = py + dy
				if ny < 0 or ny >= SIZE:
					continue
				for dx in [-1, 0, 1]:
					var nx: int = px + dx
					if nx < 0 or nx >= SIZE:
						continue
					hit[ny * SIZE + nx] = 1
	return hit
