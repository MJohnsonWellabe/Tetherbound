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
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

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

	var field: RefCounted = HEIGHTFIELD.new()
	for entry: Variant in cfg.get("streams", []):
		_build_stream(entry, shader, field)

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


## Running water, laid down the bed the terrain already cut for it.
##
## The milestone spec asks for a stream, and the honest objection to answering
## that with the pond code is exactly right: a stream is a route with a
## direction, not a flat disc, and a long thin pond is a long thin pond. What
## makes this one a stream is upstream of here — `playground_heightfield.gd`
## cuts a channel along an authored route and FORCES its bed to fall, `min_fall`
## metres per metre travelled, so the bed is descending by construction. This
## reads that bed back and lays a surface on it, so the water surface descends
## with it. Every quad of it is at a different height, and it is running downhill
## from a source at the foot of the stronghold bluff into the valley pond.
##
## The ribbon also NARROWS and WIDENS along its length, which is the other thing
## a still frame can use to say which way water is going.
##
## WHAT IS HONESTLY MISSING: there is no flow ANIMATION. The surface does not
## scroll. `shaders/water.gdshader` computes its ripples from two standing wave
## sets in world space with no directional term, and adding one means adding a
## uniform to a shader this milestone does not own. So the direction is carried
## by the geometry — the fall, the taper, the banks — and not by the material.
## That is a real gap and it is the first thing to fix when the shader is next
## opened.
func _build_stream(entry: Variant, shader: Shader, field: RefCounted) -> void:
	var stream: Dictionary = entry
	var index := int(stream.get("channel", 0))
	var spine: Array = field.call("channel_centreline", index, float(stream.get("sample", 2.0)))
	if spine.size() < 2:
		push_warning("water stream '%s' names channel %d, which the terrain has no bed for" % [
			stream.get("name", "?"), index
		])
		return

	var fill := float(stream.get("fill", 0.5))
	var start_width := float(stream.get("width_start", 1.6))
	var end_width := float(stream.get("width_end", 3.4))

	var mesh := MeshInstance3D.new()
	mesh.name = str(stream.get("name", "Stream"))
	mesh.mesh = _ribbon(spine, fill, start_width, end_width)
	mesh.material_override = _material(shader, stream, maxf(start_width, end_width))
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

	# Recorded as a chain of small discs rather than as one body, so everything
	# that already knows how to ask "is there water at this point" — the scatter's
	# drowning pass, `level_at` — keeps working unchanged. A stream is a pond
	# that is a hundred and fifty metres long and two metres wide.
	for i in spine.size():
		var at: Vector3 = spine[i]
		var t := float(i) / float(maxi(1, spine.size() - 1))
		_bodies.append({
			"name": "%s_%d" % [mesh.name, i],
			"centre": Vector2(at.x, at.z),
			"radius": lerpf(start_width, end_width, t) + 0.4,
			"level": at.y + fill,
		})


## A quad strip following the spine, with the vertex RED channel carrying
## distance ACROSS the water rather than distance from a centre.
##
## That is the only change the shader needs to work on a stream instead of a
## disc: it reads `COLOR.r` as "how close is this fragment to the edge", uses it
## to blend shallow to deep and to lay the foam line. On a disc that is radius;
## on a ribbon it is how far off the centreline you are. So a brook gets foam
## along BOTH banks, which is where a brook's foam is.
func _ribbon(spine: Array, fill: float, start_width: float, end_width: float) -> ArrayMesh:
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var colours := PackedColorArray()
	var indices := PackedInt32Array()

	var count := spine.size()
	for i in count:
		var at: Vector3 = spine[i]
		var t := float(i) / float(maxi(1, count - 1))
		var ahead: Vector3 = spine[mini(i + 1, count - 1)]
		var behind: Vector3 = spine[maxi(i - 1, 0)]
		var along := Vector2(ahead.x - behind.x, ahead.z - behind.z)
		if along == Vector2.ZERO:
			along = Vector2(0.0, 1.0)
		var across := along.orthogonal().normalized() * lerpf(start_width, end_width, t)
		# The surface is FLAT across the channel and falls along it — which is
		# what water does, and is only possible because the bed underneath was
		# cut to a monotonically falling profile.
		var level := at.y + fill
		for side in [-1.0, 1.0]:
			points.append(Vector3(at.x + across.x * side, level, at.z + across.y * side))
			normals.append(Vector3.UP)
			# Tangent along +X, matching the disc, so the shader's ripple
			# derivatives land on the world axes it expects.
			tangents.append_array([1.0, 0.0, 0.0, 1.0])
			colours.append(Color(1.0, 0.0, 0.0, 1.0))
		# A third vertex down the middle, so the deep colour has somewhere to be.
		# Two-vertex-wide strips are all shore and all foam.
		points.append(Vector3(at.x, level, at.z))
		normals.append(Vector3.UP)
		tangents.append_array([1.0, 0.0, 0.0, 1.0])
		colours.append(Color(0.0, 0.0, 0.0, 1.0))

	for i in count - 1:
		var a := i * 3
		var b := (i + 1) * 3
		# left bank -> middle
		indices.append_array([a, b, a + 2, a + 2, b, b + 2])
		# middle -> right bank
		indices.append_array([a + 2, b + 2, a + 1, a + 1, b + 2, b + 1])

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
		if key.begins_with("_") or key in [
			"centre", "radius", "fill", "name",
			"channel", "sample", "width_start", "width_end",
		]:
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
