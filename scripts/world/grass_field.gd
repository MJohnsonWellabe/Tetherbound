extends MultiMeshInstance3D

## GRASS-FIELD. The camera-relative ground cover that replaces stored grass
## placements.
##
## `shaders/grass_field.gdshader` carries the argument for why this exists; the
## short version is that `ralph/reports/WORLD_GRASS_2026-08-25.md` measured a
## continuous carpet at ~40x outside the chapter's placement ceiling however it
## is spent, so a system that stores a transform per tuft cannot reach it. This
## stores nothing: a fixed ring of tufts follows the camera and the vertex
## shader puts each one on the terrain surface by sampling Terrain3D's own
## height data.
##
## Cost is a function of the RING, not of the world. The same number of tufts
## renders standing in the village and eight kilometres down the corridor, and
## nothing about it grows when the corridor does.
##
## OFF BY DEFAULT, AND THAT IS THE POINT. `data/config/grass_field.json`'s
## `enabled` decides, the scatter path is left completely intact behind it, and
## `suppress_scatter_layers` names the layers `vegetation.gd` skips when this is
## on. The one thing this container cannot measure is the only hardware that
## matters (`PERF-ROG-GPU`: Compatibility counts MultiMesh batches, not
## instances, and this box rasterises in software), so the owner has to be able
## to A/B it on the Ally and a bad result has to be one flag away from gone.
##
## Everything here is vertex maths, one texelFetch and an alpha scissor. No
## compute shader, no RenderingDevice, no subsurface scattering -- Godot lists
## all three as unsupported on the GL Compatibility renderer that `D01` locks
## this project to.

const CONFIG_PATH := "res://data/config/grass_field.json"
const SHADER_PATH := "res://shaders/grass_field.gdshader"

## Read once and cached, the same way `scatter_rules.gd::config()` does it, so a
## test can ask what the config says without standing a world up.
static var _config: Dictionary = {}

## Test seam. `data/config/grass_field.json`'s `enabled` is the production
## switch and defaults to off; a probe or a smoke test that wants the field
## standing without editing the shipped config sets this before adding the node
## to the tree. Deliberately NOT a way to turn it on in the game -- nothing in
## `scripts/` sets it.
@export var force_enabled := false

var _camera: Camera3D = null
var _terrain: Node = null
var _material: ShaderMaterial = null
var _bound := false
var _wind := 0.0
## The last snapped centre. The ring only rebuilds its uniform when this moves,
## which is most frames a no-op.
var _centre := Vector3(INF, INF, INF)


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_config = parsed
	return _config


## Whether the field is on. Read by `vegetation.gd` as well as by this node, so
## the two cannot disagree about which system owns the ground.
static func is_enabled() -> bool:
	return bool(config().get("enabled", false))


## Layer names `vegetation.gd` skips while the field is on. Returned as a
## Dictionary-as-set so the caller's inner loop is a hash lookup, not a scan.
static func suppressed_layers() -> Dictionary:
	var out: Dictionary = {}
	if not is_enabled():
		return out
	for name: Variant in config().get("suppress_scatter_layers", []):
		out[str(name)] = true
	return out


func _ready() -> void:
	if not (is_enabled() or force_enabled):
		# Nothing built, nothing bound, no per-frame work. A disabled field is
		# not a cheap field, it is an absent one.
		set_process(false)
		visible = false
		return
	_build()
	set_process(true)


## Build the tuft mesh and the ring. Both are built once and never rebuilt: the
## ring moves by moving this node, not by rewriting instance transforms, which
## is what keeps the per-frame cost at "one uniform write".
func _build() -> void:
	var cfg := config()
	var count := int(cfg.get("tuft_count", 42000))
	var radius := float(cfg.get("field_radius", 48.0))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _tuft_mesh(int(cfg.get("blades_per_tuft", 4)),
			int(cfg.get("blade_segments", 4)))
	mm.instance_count = count

	# Distribution. `r = radius * u^centre_bias` with a bias below 0.5 crowds
	# the middle, which is where the camera is and where a bare patch is most
	# visible; a uniform disc (bias 0.5) spends most of its tufts in the outer
	# ring where they are sub-pixel anyway.
	var bias := float(cfg.get("centre_bias", 0.62))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cfg.get("seed", 20260825))
	for i in count:
		var angle := rng.randf_range(0.0, TAU)
		var r := radius * pow(rng.randf(), bias)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		mm.set_instance_transform(i, Transform3D(basis,
				Vector3(sin(angle) * r, 0.0, cos(angle) * r)))
	multimesh = mm

	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_PATH)
	material_override = _material
	_apply_config(cfg)

	# The field is ground cover: it must not push the camera around, must not
	# receive a harvest prompt, and must not cast the black carpet a thousand
	# overlapping blade shadows would make (`vegetation.json`'s grass layer
	# turned its own shadows off for exactly that measured reason).
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The ring is authored around the origin and moved; without this Godot culls
	# it against an AABB that does not follow.
	custom_aabb = AABB(Vector3(-radius, -400.0, -radius),
			Vector3(radius * 2.0, 800.0, radius * 2.0))


## One tuft: a handful of tapered blades at different yaws, sharing one mesh.
##
## Generated rather than imported, and that is deliberate on two counts. It adds
## no asset to the repository, so `CLAUDE.md`'s no-new-assets rule for the
## Meadows is untouched. And it is what lets the blade carry `UV.y` as "height
## along the blade", which is the channel the base-to-tip gradient and the
## ground blend both read -- the two things a blind critic named as missing from
## the scattered tufts ("flat two-tone polygon... no base-to-tip gradient, no
## translucency, no ground blend").
func _tuft_mesh(blades: int, segments: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	# UV2.x carries WHICH BLADE of the tuft this vertex belongs to. Without it
	# every blade in a tuft hashes on the same instance origin and therefore
	# gets the same height, the same lean and the same lean direction -- five
	# parallel strips, which a blind critic read exactly as "a comb, or a field
	# of leeks, not a meadow".
	var uv2s := PackedVector2Array()
	var indices := PackedInt32Array()

	# Metres, baked, and the per-blade VARIATION is baked here too rather than
	# computed in the shader. That is a deliberate move after a blind critic
	# measured this field and reported "zero height variance -- the field has a
	# mown ceiling... every blade a straight vertical constant-width rectangle",
	# despite the shader carrying both a height jitter and a per-blade bend. Two
	# reasons to bake it instead of arguing with that:
	#
	#   1. It cannot silently fail. The shader path depended on UV2 reaching the
	#      vertex stage to tell one blade of a tuft from another; geometry that
	#      is already different needs nothing delivered.
	#   2. The critic's own prescription is a geometry one, not a parameter one:
	#      "a moong-01 or palworld-03 grass card carries five to eight tapered,
	#      curving blades of differing length, so one quad reads as a tuft and
	#      the field reads as turf" -- and, on scaling the existing quad, "a 25:1
	#      rectangle stays a reed at any size".
	#
	# So each blade in the tuft gets its own length, its own outward splay and
	# its own forward curve, from a deterministic hash of its index. The shader
	# then scales the whole thing by one height, and the differences survive.
	var half_width := 0.0055
	var spread := 0.075
	for b in blades:
		# Deterministic per-blade variation. `fract(sin(i) * k)` rather than an
		# RNG so the mesh is identical on every run and every machine -- this
		# geometry is shared by every tuft in the world, so a mesh that varied
		# per boot would be a different world per boot.
		var r1 := fmod(abs(sin(float(b) * 12.9898) * 43758.5453), 1.0)
		var r2 := fmod(abs(sin(float(b) * 78.233) * 24634.6345), 1.0)
		var r3 := fmod(abs(sin(float(b) * 39.425) * 15731.7431), 1.0)
		# Length: 0.55 to 1.0 of the tuft's height. The short ones are what stop
		# the field having a flat top, and they are the majority on purpose --
		# meadow is mostly base turf with a few stems standing above it.
		var length := 0.55 + 0.45 * r1
		# Splay: each blade leans out from the tuft centre, further the taller
		# it is, so a tuft opens like a fan instead of standing as a bundle.
		var splay := (0.10 + 0.22 * r2) * length
		# Curve: the tip falls away from vertical. A blade of grass is an arc;
		# a straight one reads as a reed however wide it is.
		var curve := (0.25 + 0.55 * r3) * length
		var yaw := TAU * (float(b) + 0.37 * r2) / float(blades)
		var dir := Vector3(sin(yaw), 0.0, cos(yaw))
		var side := Vector3(dir.z, 0.0, -dir.x)
		var offset := dir * spread * (0.35 + 0.65 * r2)
		var first := verts.size()
		for s2 in segments + 1:
			var t := float(s2) / float(segments)
			# Taper to a point rather than to a flat top. The critic measured
			# "constant width top to bottom, squared-off top" and that squared
			# tip is most of why a blade reads as a plank.
			var half := half_width * (1.0 - t) * (1.0 - t * 0.35) + half_width * 0.06
			# The arc: lean grows with t^1.7, so the base stays planted and the
			# top half does the bending.
			var lean := dir * (splay * t + curve * pow(t, 1.7))
			var up := Vector3.UP * (t * length)
			verts.append(offset + lean + side * -half + up)
			verts.append(offset + lean + side * half + up)
			# Normal tilted toward the blade's own face, so a fan of blades
			# catches the light at a spread of angles instead of one.
			normals.append((dir * 0.55 + Vector3.UP * 0.8).normalized())
			normals.append((dir * 0.55 + Vector3.UP * 0.8).normalized())
			uvs.append(Vector2(0.0, t))
			uvs.append(Vector2(1.0, t))
			var blade_id := float(b) / float(blades)
			uv2s.append(Vector2(blade_id, 0.0))
			uv2s.append(Vector2(blade_id, 0.0))
		for s2 in segments:
			var a := first + s2 * 2
			indices.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _apply_config(cfg: Dictionary) -> void:
	for key: String in [
		"field_radius", "fade_start", "blade_width", "height_near", "height_far",
		"height_jitter", "bend", "shade_jitter", "density_gain", "clump_scale", "clump_contrast",
		"ground_blend", "translucency", "wind_strength", "wind_scale",
	]:
		if cfg.has(key):
			_material.set_shader_parameter(key, float(cfg[key]))
	for key: String in ["tint_base", "tint_tip"]:
		if cfg.has(key):
			_material.set_shader_parameter(key, Color(str(cfg[key])))
	if cfg.has("wind_dir"):
		var d: Array = cfg["wind_dir"]
		_material.set_shader_parameter("wind_dir",
				Vector2(float(d[0]), float(d[1])).normalized())
	# Which terrain textures grass refuses. Named rather than numbered in the
	# config, because `terrain_playground.json`'s texture ORDER is what decides
	# the ids and a lane that reorders it must not silently move the mask.
	var names: Array = []
	var terrain_cfg := _terrain_texture_names()
	for entry: Variant in cfg.get("forbidden_ground", ["rock", "path"]):
		names.append(str(entry))
	var mask := 0
	for i in terrain_cfg.size():
		if str(terrain_cfg[i]) in names:
			mask |= 1 << i
	_material.set_shader_parameter("forbidden_base_mask", mask)


func _terrain_texture_names() -> Array:
	var file := FileAccess.open("res://data/config/terrain_playground.json", FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	var out: Array = []
	if parsed is Dictionary:
		for entry: Variant in (parsed as Dictionary).get("textures", []):
			out.append(str((entry as Dictionary).get("name", "")))
	return out


## Point the field at the terrain whose height data it should sample, and at the
## camera it should follow. Called by `playground_world.gd` once both exist;
## kept explicit rather than searched for, so a scene that has no terrain gets a
## clear "not bound" rather than a field lying flat at y=0.
func bind(terrain: Node, camera: Camera3D) -> void:
	_terrain = terrain
	_camera = camera
	_bind_terrain()


## Mirror Terrain3D's own map textures and region lookup onto this material.
##
## Read off the LIVE terrain rather than configured here, because the two must
## agree exactly: the shader reproduces Terrain3D's region arithmetic, and a
## region size or vertex spacing that disagreed by one would put the whole field
## on the wrong ground without erroring.
##
## The three map textures are bound through `RenderingServer.material_set_param`
## rather than `set_shader_parameter` because `Terrain3DData` hands them out as
## RIDs (`get_height_maps_rid()` and friends) and there is no Texture2DArray
## object to pass.
func _bind_terrain() -> void:
	if _terrain == null or _material == null:
		return
	var data: Object = _terrain.get("data")
	if data == null:
		push_warning("[grass_field] terrain has no data; the field cannot find the ground")
		return

	var rid: RID = _material.get_rid()
	for pair: Array in [
		["_height_maps", "get_height_maps_rid"],
		["_control_maps", "get_control_maps_rid"],
		["_color_maps", "get_color_maps_rid"],
	]:
		if data.has_method(str(pair[1])):
			RenderingServer.material_set_param(rid, str(pair[0]), data.call(str(pair[1])))

	var region_size := float(_terrain.get("region_size"))
	var vertex_spacing := float(_terrain.get("vertex_spacing"))
	var region_map: Array = data.call("get_region_map") if data.has_method("get_region_map") else []
	var map := PackedInt32Array()
	map.resize(region_map.size())
	for i in region_map.size():
		map[i] = int(region_map[i])

	_material.set_shader_parameter("_region_size", region_size)
	_material.set_shader_parameter("_region_texel_size", 1.0 / region_size)
	_material.set_shader_parameter("_region_map_size", int(sqrt(float(region_map.size()))))
	_material.set_shader_parameter("_vertex_density", 1.0 / vertex_spacing)
	_material.set_shader_parameter("_region_map", map)
	_bound = true
	print("[grass_field] bound: %d tufts, radius %.0fm, region_size %.0f, vertex_spacing %.1f, %d region slots" % [
		multimesh.instance_count if multimesh != null else 0,
		float(config().get("field_radius", 48.0)), region_size, vertex_spacing, map.size()])


func _process(delta: float) -> void:
	if _material == null:
		return
	_wind += delta
	_material.set_shader_parameter("wind_time", _wind)
	if _camera == null or not is_instance_valid(_camera):
		return

	# Snap to a grid. Following the camera continuously makes every blade swim
	# against the ground it is supposed to be growing out of, because the ring's
	# own noise lookup is in WORLD space while the instances are in LOCAL space
	# -- a sub-metre move re-rolls which tufts survive. Snapping means the set
	# only changes when the ring has moved a whole cell.
	var snap := float(config().get("snap", 2.0))
	var at := _camera.global_position
	var centre := Vector3(snappedf(at.x, snap), 0.0, snappedf(at.z, snap))
	if centre.is_equal_approx(_centre):
		return
	_centre = centre
	global_position = centre
	_material.set_shader_parameter("field_centre", centre)
