extends RefCounted

## P2-037 visual-only shell finish. Reference: Stormheart stronghold boards A/B.
## The opening can only widen and the inner wall can only retreat into wood.
## No collision, deck, actor, progression, camera or world edits live here.
const EXPOSED_SHADER := preload("res://scripts/world/stormheart_split_wood.gdshader")
const WOOD_ATLAS := "res://assets/buildings/quaternius_medieval/T_WoodTrim_BaseColor.png"
const BANDS := 50
const PANELS := 64
const LIP_PANELS := 6


static func exposed_material(settings: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = EXPOSED_SHADER
	material.set_shader_parameter("wood_atlas", load(WOOD_ATLAS))
	material.set_shader_parameter("wood_tint", Color(str(settings.get("exposed_wood_tint", "#a8997b"))))
	return material


static func _surface() -> Dictionary:
	return {"vertices": PackedVector3Array(), "normals": PackedVector3Array(), "uvs": PackedVector2Array()}


static func build_surfaces(tree: Node3D, side: int, repeat_m: float, settings: Dictionary) -> Dictionary:
	var wall := _surface()
	var lips := _surface()
	var start := -PI * 0.5 + 0.27 if side == 0 else PI * 0.5 + 0.14
	var end := PI * 0.5 - 0.14 if side == 0 else PI * 1.5 - 0.27
	for band in BANDS:
		var low := float(band) * 5.0
		var high := float(band + 1) * 5.0
		for panel in PANELS:
			var a := lerpf(start, end, float(panel) / PANELS)
			var b := lerpf(start, end, float(panel + 1) / PANELS)
			for inner in [false, true]:
				var corners: Array[Vector2] = [Vector2(a, low), Vector2(b, low), Vector2(b, high), Vector2(a, high)]
				var order := [0, 2, 1, 0, 3, 2] if inner else [0, 1, 2, 0, 2, 3]
				for index: int in order:
					var c := corners[index]
					var at := wall_point(tree, c.x, c.y, inner, start, end, side, settings)
					var across := wall_point(tree, c.x + 0.001, c.y, inner, start, end, side, settings) - wall_point(tree, c.x - 0.001, c.y, inner, start, end, side, settings)
					var up := wall_point(tree, c.x, c.y + 0.02, inner, start, end, side, settings) - wall_point(tree, c.x, c.y - 0.02, inner, start, end, side, settings)
					var normal := up.cross(across).normalized()
					wall.vertices.append(at)
					wall.normals.append(-normal if inner else normal)
					wall.uvs.append(grain_uv(c.x, c.y, repeat_m, settings))
		for edge in 2:
			for panel in LIP_PANELS:
				var u := float(panel) / LIP_PANELS
				var v := float(panel + 1) / LIP_PANELS
				var a := lip_point(tree, u, low, edge, start, end, side, settings)
				var b := lip_point(tree, v, low, edge, start, end, side, settings)
				var c := lip_point(tree, v, high, edge, start, end, side, settings)
				var d := lip_point(tree, u, high, edge, start, end, side, settings)
				# Metres across the actual exposed thickness, not atan2 UVs which
				# collapse to one value on a radial cap and stretch bark down it.
				var angle := start if edge == 0 else end
				var width_low := wall_point(tree, angle, low, false, start, end, side, settings).distance_to(wall_point(tree, angle, low, true, start, end, side, settings))
				var width_high := wall_point(tree, angle, high, false, start, end, side, settings).distance_to(wall_point(tree, angle, high, true, start, end, side, settings))
				var repeat := maxf(0.5, float(settings.get("exposed_wood_repeat_m", 7.0)))
				var uv: Array[Vector2] = [Vector2(u * width_low, low), Vector2(v * width_low, low), Vector2(v * width_high, high), Vector2(u * width_high, high)]
				var points: Array[Vector3] = [a, b, c, d]
				var order := [0, 2, 1, 0, 3, 2] if edge == 1 else [0, 1, 2, 0, 2, 3]
				for triangle in 2:
					var i := triangle * 3
					var normal := (points[order[i + 2]] - points[order[i]]).cross(points[order[i + 1]] - points[order[i]]).normalized()
					for corner in 3:
						var index: int = order[i + corner]
						lips.vertices.append(points[index])
						lips.normals.append(normal)
						lips.uvs.append(uv[index] / repeat)
	return {"wall": wall, "lips": lips}


static func wall_point(tree: Node3D, angle: float, height: float, inner: bool,
		start: float, end: float, side: int, settings: Dictionary) -> Vector3:
	var blend := maxf(0.01, deg_to_rad(float(settings.get("lip_blend_degrees", 12.0))))
	var recess := clampf(deg_to_rad(float(settings.get("lip_recess_degrees", 2.4))), 0.0, blend * 0.4)
	var irregular := 0.5 + 0.3 * sin(height * 0.073 + side * 1.7) + 0.2 * sin(height * 0.191 + side * 2.3)
	# Positive at the start and negative at the end remove bark from the
	# existing opening edge. Neither lip grows into the entrance/ascent.
	var shift := recess * irregular * ((1.0 - smoothstep(0.0, blend, angle - start)) - (1.0 - smoothstep(0.0, blend, end - angle)))
	var mapped := angle + shift
	var point: Vector3 = tree.call("_ancient_trunk_point", mapped, height, inner)
	if inner:
		var relief := clampf(float(settings.get("inner_relief_m", 0.85)), 0.0, 1.0)
		var lobes := 0.5 + 0.3 * sin(mapped * 9.0 + height * 0.045) + 0.2 * sin(mapped * 17.0 - height * 0.083)
		# Fade before the existing upper taper. The protected inner46m
		# radius is unchanged or enlarged; physical surfaces are untouched.
		point += Vector3(cos(mapped), 0.0, sin(mapped)) * relief * lobes * (1.0 - smoothstep(170.0, 185.0, height))
	return point


static func grain_uv(angle: float, height: float, repeat_m: float, settings: Dictionary) -> Vector2:
	var wavelength := maxf(8.0, float(settings.get("grain_wander_height_m", 18.0)))
	var wander := clampf(float(settings.get("grain_wander_tiles", 0.38)), 0.0, 0.5)
	var u := angle * 58.0 / repeat_m
	var v := height / repeat_m
	# Smooth, shared mapping bends/breaks the long repeated groove columns.
	# SurfaceTool derives tangents from these actual UVs for the normal map.
	u += wander * (sin(height / wavelength + angle * 3.0) + 0.35 * sin(height / (wavelength * 0.37) - angle * 5.0))
	v += 0.12 * sin(angle * 7.0 + height / (wavelength * 1.6))
	return Vector2(u, v)


static func lip_point(tree: Node3D, u: float, height: float, edge: int,
		start: float, end: float, side: int, settings: Dictionary) -> Vector3:
	var angle := start if edge == 0 else end
	var outer := wall_point(tree, angle, height, false, start, end, side, settings)
	var inner := wall_point(tree, angle, height, true, start, end, side, settings)
	var at := outer.lerp(inner, u)
	# Endpoint-zero corrugation stays in the bark side of the original lip;
	# both cap boundaries meet the same wall vertices without a floating skin.
	var depth := clampf(float(settings.get("fracture_depth_m", 0.65)), 0.0, 1.0)
	var split := sin(PI * u) * depth * (0.55 + 0.25 * sin(u * 21.0 + height * 0.17) + 0.2 * sin(u * 37.0 - height * 0.09))
	var into_wood := Vector3(-sin(angle), 0.0, cos(angle)) * (1.0 if edge == 0 else -1.0)
	return at + into_wood * split
