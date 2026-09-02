extends SceneTree

## Ad hoc, throwaway: dump every surface's albedo_color and mean texture colour
## for bramblebun_redesign's shipped mesh, to check whether its green
## thorn/leaf surfaces are a SEPARATE material from its tan/cream body (so a
## per-surface tint could target only the green ones) or one shared textured
## material (so any tint applies uniformly to both).
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --script tools/_dump_bramblebun_materials.gd

const MODEL := "res://assets/creatures/tetherbound/bramblebun_redesign/models/creature_bramblebun_redesign_lod0.glb"


func _init() -> void:
	var scene: PackedScene = load(MODEL)
	if scene == null:
		print("FAIL: could not load %s" % MODEL)
		quit(1)
		return
	var node := scene.instantiate()
	_walk(node, 0)
	quit(0)


func _walk(node: Node, depth: int) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		print("%sMeshInstance3D %s: %d surfaces" % ["  ".repeat(depth), node.name, mesh.get_surface_count() if mesh else 0])
		for i in (mesh.get_surface_count() if mesh else 0):
			var mat: Material = mi.get_active_material(i)
			if mat is BaseMaterial3D:
				var bm := mat as BaseMaterial3D
				var tex := bm.albedo_texture
				print("%s  surface %d: name=%s albedo_color=%s emission_enabled=%s tex=%s" % [
					"  ".repeat(depth), i, mat.resource_name, bm.albedo_color, bm.emission_enabled,
					(tex.resource_path if tex else "none")])
				if tex is Texture2D:
					_mean_colour(tex as Texture2D)
			else:
				print("%s  surface %d: non-BaseMaterial3D (%s)" % ["  ".repeat(depth), i, mat])
	for child in node.get_children():
		_walk(child, depth + 1)


func _mean_colour(tex: Texture2D) -> void:
	var img := tex.get_image()
	if img == null:
		print("    (no image data)")
		return
	img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var step := maxi(1, w / 64)
	var sr := 0.0
	var sg := 0.0
	var sb := 0.0
	var n := 0
	var y := 0
	while y < h:
		var x := 0
		while x < w:
			var c := img.get_pixel(x, y)
			sr += c.r
			sg += c.g
			sb += c.b
			n += 1
			x += step
		y += step
	if n == 0:
		return
	var mean := Color(sr / n, sg / n, sb / n)
	print("    mean colour over %dx%d (sampled %d): %s  hue=%.1f  value=%.3f" % [
		w, h, n, mean, mean.h * 360.0, mean.v])
