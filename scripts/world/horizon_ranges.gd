extends Node3D

## MEADOWS-VISUAL-PASS round 5. The key-art board puts blue ranges and a
## snow-capped peak behind every Meadows panel; three blind rounds found "no
## landmarks, mountains or water in any frame" and "a hard green line against
## the sky". The playable corridor ends at +-1024m, and the gameplay camera's
## far plane is 2000m on an 8km-long map, so fixed geometry cannot stay on the
## horizon from everywhere.
##
## This builds two rings of real, lit mountain geometry -- a far snowy range
## and nearer forested foothills -- and keeps them centred on the camera in XZ,
## the way a sky is. They are shaded by the sun and hazed by the scene's own
## fog, so they change with the time of day. A version painted into the sky
## shader was tried first and a blind judge read it as "a vertical-striped
## cardboard backdrop": a per-bearing shade has no form. Never walked into,
## never collided with, casts no shadow. Two draw calls.
##
## Config: data/config/meadows_horizon.json. Presentation only, local to each
## peer.

const CONFIG_PATH := "res://data/config/meadows_horizon.json"

var _config: Dictionary = {}
var _base_y := 0.0


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_warning("meadows_horizon.json missing or invalid; no horizon ranges")
		return
	_config = parsed
	_base_y = float(_config.get("base_y", -40.0))
	for layer_variant: Variant in _config.get("layers", []):
		var layer: Dictionary = layer_variant
		var instance := MeshInstance3D.new()
		instance.name = str(layer.get("name", "Range"))
		instance.mesh = build_ring(layer, int(_config.get("seed", 1)))
		instance.material_override = _material()
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		add_child(instance)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		global_position = Vector3(camera.global_position.x, _base_y, camera.global_position.z)


func _material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


## One ring of mountains as an ArrayMesh, in local space around the origin.
## `layer`: radius (inner edge), depth (how far back the ridge sits), height
## (tallest crest), base (floor fraction of height), frequency (crests), the
## hero peak, snow line and colours. Deterministic from `seed`.
static func build_ring(layer: Dictionary, seed: int) -> ArrayMesh:
	var segments := int(layer.get("segments", 360))
	var rows := int(layer.get("rows", 14))
	var radius := float(layer.get("radius", 1800.0))
	var depth := float(layer.get("depth", 500.0))
	var height := float(layer.get("height", 260.0))
	var floor_fraction := float(layer.get("base", 0.2))
	var skirt := float(layer.get("skirt", 160.0))
	var noise := FastNoiseLite.new()
	noise.seed = seed + int(layer.get("seed_offset", 0))
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED if bool(layer.get("ridged", true)) else FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = int(layer.get("octaves", 5))
	noise.frequency = float(layer.get("frequency", 0.9))
	var massif := FastNoiseLite.new()
	massif.seed = seed + 991 + int(layer.get("seed_offset", 0))
	massif.frequency = float(layer.get("massif_frequency", 0.35))
	var hero_bearing := deg_to_rad(float(layer.get("hero_bearing_deg", 0.0)))
	var hero_width := deg_to_rad(float(layer.get("hero_width_deg", 8.0)))
	var hero_lift := float(layer.get("hero_lift", 0.0))

	var positions := PackedVector3Array()
	positions.resize((segments + 1) * (rows + 1))
	for i in segments + 1:
		var bearing := TAU * float(i % segments) / float(segments)
		var ring := Vector2(cos(bearing), sin(bearing))
		var off := absf(wrapf(bearing - hero_bearing, -PI, PI))
		var hero := hero_lift * exp(-pow(off / maxf(hero_width, 0.001), 2.0))
		for j in rows + 1:
			var t := float(j) / float(rows)
			var along := ring * (2.0 + t * 0.6)
			var ridge := pow(clampf((noise.get_noise_2d(along.x, along.y) + 1.0) * 0.5, 0.0, 1.0),
				float(layer.get("sharpness", 1.0)))
			var mass := clampf((massif.get_noise_2d(ring.x * 3.0, ring.y * 3.0) + 1.0) * 0.5, 0.0, 1.0)
			# Height rises from the front edge to the crest near the back, then
			# falls away behind it, so every crest has a lit and a shaded side.
			var profile := sin(clampf(t * 1.15, 0.0, 1.0) * PI * 0.5) * (1.0 - smoothstep(0.85, 1.0, t) * 0.6)
			var h := height * (floor_fraction + (1.0 - floor_fraction) * ridge * (0.45 + 0.55 * mass)) * profile
			# The hero carries the ridge's own breakup, so it reads as the
			# tallest peak of the range rather than a smooth cone set on it.
			h += hero * height * profile * (0.55 + 0.45 * ridge)
			if j == 0:
				h = -skirt
			var r := radius + depth * t
			positions[i * (rows + 1) + j] = Vector3(ring.x * r, h, ring.y * r)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var colours := _colours(layer, positions, segments, rows, height)
	for i in segments:
		for j in rows:
			var a := i * (rows + 1) + j
			var b := (i + 1) * (rows + 1) + j
			for index: int in [a, b, a + 1, b, b + 1, a + 1]:
				st.set_color(colours[index])
				st.add_vertex(positions[index])
	st.generate_normals()
	return st.commit()


## Forest low down, rock above, snow on the crests of a tall range.
static func _colours(layer: Dictionary, positions: PackedVector3Array, segments: int, rows: int,
		height: float) -> PackedColorArray:
	var forest := Color(str(layer.get("forest", "#3f5a3a")))
	var rock := Color(str(layer.get("rock", "#6f7784")))
	var snow := Color(str(layer.get("snow", "#e8eef4")))
	var snow_line := float(layer.get("snow_line", 2.0)) * height
	var tree_line := float(layer.get("tree_line", 0.35)) * height
	var out := PackedColorArray()
	out.resize(positions.size())
	for index in positions.size():
		var y := positions[index].y
		var c := forest.lerp(rock, smoothstep(tree_line * 0.7, tree_line * 1.3, y))
		c = c.lerp(snow, smoothstep(snow_line * 0.96, snow_line * 1.04, y))
		# A little variation so a slope is not one flat swatch.
		var jitter := (sin(float(index) * 12.9898) * 43758.5453)
		jitter = (jitter - floorf(jitter)) * 0.08 - 0.04
		out[index] = Color(clampf(c.r + jitter, 0.0, 1.0), clampf(c.g + jitter, 0.0, 1.0), clampf(c.b + jitter, 0.0, 1.0))
	return out
