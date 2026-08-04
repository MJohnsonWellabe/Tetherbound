extends Node3D

## Standing water, placed on the terrain the world already has.
##
## The critic's third-ranked gap was "there is nothing to look at" — it measured
## `02-valley-floor` at **0.7% desaturated pixels** and observed that the art
## board lists Streams & Ponds as one of five pillars while the build has none.
## The terrain already carries one broad basin. This puts water in it.
##
## The whole thing is one horizontal disc with a shader on it, and the trick
## that makes that enough is the oldest one there is: **the terrain occludes
## it**. The disc is drawn wider than the water actually reaches, and wherever
## the ground rises above the water level the ground is simply in front. So the
## shoreline is the real contour of the basin, irregular and free, rather than a
## circle somebody had to author.
##
## No collision, and no swimming. The player wades: the terrain's own collision
## is still under them, so they walk the bed. That is why the fill below is
## ankle-to-knee deep and not a lake — adding a swim state is a new traversal
## mechanic, which CLAUDE.md says to flag rather than invent.

const CONFIG_PATH := "res://data/config/water.json"
const SHADER_PATH := "res://shaders/water.gdshader"

## Rings and radial segments of each disc. Enough that the vertex swell has
## somewhere to happen and the shore gradient interpolates smoothly; a disc of
## two triangles would get neither.
const RINGS := 28
const SEGMENTS := 72

var _bodies: Array = []


## `ground_height_at` is passed in rather than looked up, so this node never
## needs to know what kind of terrain it is standing on — and so it can be
## built in a test against a plain heightfield.
##
## It is a CALLABLE and never a raycast. D09: rays hit props, miss on the frame
## the terrain has not streamed in, and return a different answer depending on
## the physics tick. The heightfield is the ground's own definition of itself.
func build(ground_height: Callable) -> void:
	for child in get_children():
		child.queue_free()
	_bodies = []

	var cfg := _load()
	var shader: Shader = load(SHADER_PATH) as Shader
	if shader == null:
		push_error("water shader missing: %s" % SHADER_PATH)
		return

	for entry: Variant in cfg.get("bodies", []):
		var body: Dictionary = entry
		var centre := Vector2(
			float((body.get("centre", [0.0, 0.0]) as Array)[0]),
			float((body.get("centre", [0.0, 0.0]) as Array)[1])
		)
		var radius := float(body.get("radius", 60.0))
		if radius <= 0.0:
			continue

		# The surface height is DERIVED, not authored. The basin floor is a
		# consequence of the terrain recipe, and a hand-written level would drift
		# the first time anyone retunes the valley's depth — leaving either a
		# puddle in a crater or a disc hanging in the air above it.
		var floor_height: float = ground_height.call(centre.x, centre.y)
		if is_nan(floor_height):
			push_warning("water body '%s' sits off the terrain; skipped" % body.get("name", "?"))
			continue
		var level: float = floor_height + float(body.get("fill", 1.2))

		var mesh := MeshInstance3D.new()
		mesh.name = str(body.get("name", "Water"))
		mesh.mesh = _disc(radius)
		mesh.material_override = _material(shader, body, radius)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
		mesh.position = Vector3(centre.x, level, centre.y)

		_bodies.append({"name": mesh.name, "centre": centre, "radius": radius, "level": level})


## What got built, for tests and for the export check. A pond that failed to
## place should be visible as a number rather than as an absence.
func stats() -> Dictionary:
	return {"bodies": _bodies.size(), "placed": _bodies.duplicate(true)}


## Height of the water at a point, or NAN if no body covers it. The AI and the
## scatter both need to know where the pond is — nothing should grow in it.
func level_at(x: float, z: float) -> float:
	for body: Dictionary in _bodies:
		var centre: Vector2 = body["centre"]
		if Vector2(x, z).distance_to(centre) <= float(body["radius"]):
			return float(body["level"])
	return NAN


## A flat fan disc whose vertex RED channel is normalised distance from the
## centre.
##
## That channel is the only thing the shader knows about the pond's shape. It
## cannot be computed in the fragment stage — a fragment has no idea where the
## mesh it belongs to is centred — and reconstructing it from world position
## would hard-code the pond's centre into the material.
func _disc(radius: float) -> ArrayMesh:
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var colours := PackedColorArray()
	var indices := PackedInt32Array()

	for ring in RINGS + 1:
		var r: float = radius * float(ring) / float(RINGS)
		var shore: float = float(ring) / float(RINGS)
		for segment in SEGMENTS + 1:
			var angle: float = TAU * float(segment) / float(SEGMENTS)
			points.append(Vector3(cos(angle) * r, 0.0, sin(angle) * r))
			normals.append(Vector3.UP)
			# A tangent along +X, so the shader's TANGENT/BINORMAL are the world
			# X and Z axes and its ripple derivatives land on the right ones.
			tangents.append_array([1.0, 0.0, 0.0, 1.0])
			colours.append(Color(shore, 0.0, 0.0, 1.0))

	var stride := SEGMENTS + 1
	for ring in RINGS:
		for segment in SEGMENTS:
			var a: int = ring * stride + segment
			var b: int = a + 1
			var c: int = a + stride
			var d: int = c + 1
			indices.append_array([a, c, b, b, c, d])

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = indices

	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


func _material(shader: Shader, body: Dictionary, radius: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("depth_radius", radius)
	# Every remaining uniform is optional and per-body, so a second pond can be
	# a different colour without a second shader.
	for key: String in body.keys():
		if key.begins_with("_") or key in ["centre", "radius", "fill", "name"]:
			continue
		var value: Variant = body[key]
		if value is String and (value as String).begins_with("#"):
			material.set_shader_parameter(key, Color(value as String))
		else:
			material.set_shader_parameter(key, value)
	return material


func _load() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("water config missing: %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
