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
const STONE_SHADER_PATH := "res://shaders/stone_field.gdshader"
const COVER_SHADER_PATH := "res://shaders/cover_tier.gdshader"

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
## The stone tier rides as a CHILD of this node, so the camera-follow in
## `_process` moves both rings with one transform write and the two can never
## disagree about where the field is centred.
var _stones: MultiMeshInstance3D = null
var _stone_material: ShaderMaterial = null
## Every generic cover tier's material -- bushes, flowers, litter. They all
## run `shaders/cover_tier.gdshader` and differ only by mesh and config, so
## binding, centring and winding them is one loop rather than one branch per
## tier.
var _cover_materials: Array[ShaderMaterial] = []
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

	# AFTER `custom_aabb` is set, not before: the stone ring copies it, and
	# built first it copied the default zero AABB instead.
	_build_stones(cfg, radius)
	_build_cover_tiers(cfg, radius)
	_apply_clearing(cfg)


## The generic cover tiers, from `cover_tiers` in the config: small bushes,
## flower drifts, forest litter. Each is one more MultiMesh child on the same
## ring, running `shaders/cover_tier.gdshader`, differing only by mesh and
## numbers -- see that shader's header for the rule about what may and may not
## be generated this way, and why harvestable bushes are not on the list.
func _build_cover_tiers(cfg: Dictionary, radius: float) -> void:
	var names := _terrain_texture_names()
	for entry: Variant in cfg.get("cover_tiers", []):
		var tier: Dictionary = entry
		if not bool(tier.get("enabled", true)):
			continue
		var count := int(tier.get("count", 0))
		if count <= 0:
			continue

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _cover_mesh(str(tier.get("mesh", "bush")))
		mm.instance_count = count
		# Its own RNG stream, seeded from its own name, so adding or removing a
		# tier cannot reshuffle where any other tier's items land.
		var rng := RandomNumberGenerator.new()
		rng.seed = int(tier.get("seed", hash(str(tier.get("name", "tier")))))
		var bias := float(tier.get("centre_bias", 0.6))
		for i in count:
			var angle := rng.randf_range(0.0, TAU)
			var r := radius * pow(rng.randf(), bias)
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)),
					Vector3(sin(angle) * r, 0.0, cos(angle) * r)))

		var node := MultiMeshInstance3D.new()
		node.name = "Cover_" + str(tier.get("name", "tier"))
		node.multimesh = mm
		var mat := ShaderMaterial.new()
		mat.shader = load(COVER_SHADER_PATH)
		node.material_override = mat
		# Same reasoning as the grass and stone tiers: thousands of small
		# shadows overlap into a black carpet rather than reading as shade, and
		# the shader darkens each item at its own contact instead.
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.custom_aabb = custom_aabb
		add_child(node)

		for key: String in [
			"item_size", "size_jitter", "sink", "slope_lie", "density_gain",
			"drift_scale", "drift_contrast", "tint_jitter", "ground_blend",
			"contact_darken", "sway", "wind_scale", "gust", "gust_speed",
			"gust_length", "field_radius", "fade_start",
		]:
			if tier.has(key):
				mat.set_shader_parameter(key, float(tier[key]))
			elif cfg.has(key):
				mat.set_shader_parameter(key, float(cfg[key]))
		for key2: String in ["tint_base", "tint_tip"]:
			if tier.has(key2):
				mat.set_shader_parameter(key2, Color(str(tier[key2])))
		if tier.has("wind_dir"):
			var d: Array = tier["wind_dir"]
			mat.set_shader_parameter("wind_dir", Vector2(float(d[0]), float(d[1])).normalized())
		elif cfg.has("wind_dir"):
			var d2: Array = cfg["wind_dir"]
			mat.set_shader_parameter("wind_dir", Vector2(float(d2[0]), float(d2[1])).normalized())
		# Where it grows, by terrain texture NAME. Same list the grass tier
		# builds its forbidden mask from, so a lane that reorders
		# terrain_playground.json's textures cannot silently move a tier onto
		# the wrong surface.
		var allowed: Array = tier.get("ground", ["grass", "soil"])
		var mask := 0
		for i in names.size():
			if str(names[i]) in allowed:
				mask |= 1 << i
		mat.set_shader_parameter("allowed_base_mask", mask)
		_cover_materials.append(mat)
	if not _cover_materials.is_empty():
		print("[grass_field] %d cover tier(s) up" % _cover_materials.size())


## The meshes the cover tiers use, generated rather than imported so no asset
## enters the repository -- `CLAUDE.md`'s no-new-assets rule for the Meadows is
## untouched by any of this. UV.y runs 0 at the base to 1 at the top in every
## one of them, because that is the channel the shader's tint gradient and its
## contact darken both read.
func _cover_mesh(kind: String) -> ArrayMesh:
	match kind:
		"flower":
			return _flower_mesh()
		"litter":
			return _litter_mesh()
		_:
			return _bush_mesh()


## A small bush: crossed leaf panels on a short stem, domed so the silhouette is
## round rather than a card. DECORATIVE ONLY -- the harvestable bushes stay
## scattered, because harvesting needs an identity that survives and a generated
## thing has none.
func _bush_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	# A DOME OF MANY SMALL LEAVES, and the "many" is the whole point. Two earlier
	# versions failed the same way at different scales: five big crossed panels
	# read as a folded green box, and twenty quads at a third of the bush's own
	# size read as a handful of chunky slabs stuck in the grass. A leaf that is
	# an appreciable fraction of the silhouette IS the silhouette, and a flat
	# one then reads as flat however it is lit. Forty-four leaves at an eighth
	# of the bush size each are individually too small to read as polygons, so
	# what the eye gets is the mass they make.
	var rings := [
		{"count": 12, "y": 0.10, "r": 0.30, "tilt": 0.80, "size": 0.17},
		{"count": 11, "y": 0.28, "r": 0.29, "tilt": 0.66, "size": 0.16},
		{"count": 9, "y": 0.46, "r": 0.24, "tilt": 0.50, "size": 0.15},
		{"count": 7, "y": 0.63, "r": 0.17, "tilt": 0.34, "size": 0.14},
		{"count": 5, "y": 0.78, "r": 0.10, "tilt": 0.18, "size": 0.13},
	]
	for ring_index in rings.size():
		var ring: Dictionary = rings[ring_index]
		var count := int(ring["count"])
		for i in count:
			# Offset each ring so leaves interleave rather than stacking.
			var yaw := TAU * (float(i) + 0.37 * float(ring_index)) / float(count)
			var out := Vector3(sin(yaw), 0.0, cos(yaw))
			var side := Vector3(out.z, 0.0, -out.x)
			# The leaf leans outward and up: `tilt` 1 is flat, 0 is vertical.
			var up_axis := (Vector3.UP * (1.0 - float(ring["tilt"])) + out * float(ring["tilt"])).normalized()
			var at := out * float(ring["r"]) + Vector3.UP * float(ring["y"])
			var half := float(ring["size"]) * 0.5
			var first := verts.size()
			for corner in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
				# Taper the far edge so a leaf is a blade, not a rectangle.
				var w := half * (0.30 if corner.y > 0.5 else 0.62)
				verts.append(at + side * corner.x * w + up_axis * corner.y * float(ring["size"]))
				# Weighted toward the leaf's OWN axis rather than toward world up.
				# An even split put the inner rings' normals nearly straight up, so
				# every one of them took full sun at once and the bush read as a
				# handful of bright flat flakes sitting in the grass.
				normals.append((up_axis * 0.85 + Vector3.UP * 0.25).normalized())
				# UV.y across the whole bush height, not the leaf's own, so the
				# shader's base-to-tip gradient runs up the BUSH.
				# Typed, not inferred: `corner` comes from an untyped Array literal so
				# `corner.y` is a Variant and `:=` cannot infer a type from it.
				var t: float = (float(ring["y"]) + corner.y * float(ring["size"])) / 0.95
				uvs.append(Vector2(corner.x * 0.5 + 0.5, clamp(t, 0.0, 1.0)))
			indices.append_array([first, first + 1, first + 2, first + 1, first + 3, first + 2])
	return _mesh_from(verts, normals, uvs, indices)


## A flower: a thin stem with a small flat head. The head is what carries the
## colour, so the shader's tint_tip is the bloom and tint_base the stalk.
func _flower_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	# Stem.
	var first := verts.size()
	for corner in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
		verts.append(Vector3(corner.x * 0.016, corner.y * 0.80, 0.0))
		normals.append(Vector3(0.0, 0.5, 1.0).normalized())
		uvs.append(Vector2(corner.x * 0.5 + 0.5, corner.y * 0.74))
	indices.append_array([first, first + 1, first + 2, first + 1, first + 3, first + 2])
	# Head: three VERTICAL crossed petals. The first version used horizontal
	# quads facing up, and at this size a flat upward-facing quad is not a
	# bloom, it is a white paper square lying in the grass -- which is exactly
	# how the field rendered. Vertical petals catch the light on an edge and
	# read as a flower head from any angle the player can stand at.
	for i in 3:
		var yaw := PI * float(i) / 3.0
		var side := Vector3(sin(yaw), 0.0, cos(yaw))
		var start_i := verts.size()
		for corner in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
			# Narrow at the base, wider at the top: a bloom, not a card.
			var w := 0.090 * (1.0 if corner.y > 0.5 else 0.40)
			verts.append(side * corner.x * w + Vector3.UP * (0.70 + corner.y * 0.25))
			normals.append((side * 0.3 + Vector3.UP * 0.9).normalized())
			uvs.append(Vector2(corner.x * 0.5 + 0.5, 0.82 + corner.y * 0.18))
		indices.append_array([start_i, start_i + 1, start_i + 2, start_i + 1, start_i + 3, start_i + 2])
	return _mesh_from(verts, normals, uvs, indices)


## Forest litter: flat irregular scraps lying on the ground. Near-zero height,
## so `slope_lie` puts them ON the terrain rather than standing them up on it.
func _litter_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in 4:
		var yaw := TAU * float(i) / 4.0 + 0.4 * float(i)
		var dir := Vector3(sin(yaw), 0.0, cos(yaw))
		var side := Vector3(dir.z, 0.0, -dir.x)
		var at := dir * (0.18 + 0.22 * float(i % 2))
		var w := 0.16 + 0.08 * float(i % 3)
		var first := verts.size()
		for corner in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
			verts.append(at + side * corner.x * w + dir * corner.y * w
					+ Vector3.UP * (0.012 + 0.01 * float(i % 2)))
			normals.append(Vector3.UP)
			# UV.y near 1 everywhere: litter has no base-to-tip gradient, it is
			# all "tip", so the shader's contact darken does not black it out.
			uvs.append(Vector2(corner.x * 0.5 + 0.5, 0.85))
		indices.append_array([first, first + 1, first + 2, first + 1, first + 3, first + 2])
	return _mesh_from(verts, normals, uvs, indices)


func _mesh_from(verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## The stone tier: loose grit, gravel and field stone, on the same ring.
##
## Built as a child rather than a second top-level node so it inherits the
## camera follow for free. It is a separate MultiMesh because it is a different
## mesh, a different mask and a different shader -- stone lies on the ground
## where grass refuses to grow, and the two read the SAME control map with the
## mask inverted, so they tile the ground between them without either being told
## where the other is.
##
## The defect it exists for, from a blind pass asked the question directly:
## stones, path edges and tree bases "sit on top" of the ground rather than
## bedding into it, and the path "shares one texture with the meadow, so the
## boundary is a density edge rather than a material edge, and it looks cut".
func _build_stones(cfg: Dictionary, radius: float) -> void:
	var stone_cfg: Dictionary = cfg.get("stones", {})
	if not bool(stone_cfg.get("enabled", true)):
		return
	var count := int(stone_cfg.get("count", 26000))
	if count <= 0:
		return

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _stone_mesh(int(stone_cfg.get("sides", 7)))
	mm.instance_count = count

	# Same disc law as the tufts, drawn from its own stream so adding or
	# removing stones cannot reshuffle where the grass lands.
	var bias := float(stone_cfg.get("centre_bias", 0.58))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(stone_cfg.get("seed", 771131))
	for i in count:
		var angle := rng.randf_range(0.0, TAU)
		var r := radius * pow(rng.randf(), bias)
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)),
				Vector3(sin(angle) * r, 0.0, cos(angle) * r)))

	_stones = MultiMeshInstance3D.new()
	_stones.name = "StoneField"
	_stones.multimesh = mm
	_stone_material = ShaderMaterial.new()
	_stone_material.shader = load(STONE_SHADER_PATH)
	_stones.material_override = _stone_material
	# A pebble's shadow is not information at this size, and thousands of them
	# would be the same black carpet `vegetation.json`'s grass layer turned its
	# own shadows off for. The shader darkens each stone at its own contact
	# instead, which is the read that was actually missing.
	_stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stones.custom_aabb = custom_aabb
	add_child(_stones)

	for key: String in [
		"stone_size", "size_jitter", "sink", "density_gain", "clump_scale",
		"clump_contrast", "tint_jitter", "ground_blend", "contact_darken", "slope_lie",
		"stray_chance", "verge_gain", "field_radius", "fade_start",
	]:
		if stone_cfg.has(key):
			_stone_material.set_shader_parameter(key, float(stone_cfg[key]))
		elif cfg.has(key):
			_stone_material.set_shader_parameter(key, float(cfg[key]))
	if stone_cfg.has("tint_stone"):
		_stone_material.set_shader_parameter("tint_stone", Color(str(stone_cfg["tint_stone"])))
	# Where stone is ALLOWED is built from the same named texture list the grass
	# field builds its forbidden mask from, so the two are inverses by
	# construction rather than by two lists somebody has to keep in step.
	var names := _terrain_texture_names()
	var allowed: Array = stone_cfg.get("ground", ["rock", "path"])
	var mask := 0
	for i in names.size():
		if str(names[i]) in allowed:
			mask |= 1 << i
	_stone_material.set_shader_parameter("allowed_base_mask", mask)


## One stone: a squat faceted dome, generated rather than imported so no asset
## enters the repository. Flat-bottomed on purpose -- the shader buries the
## bottom, and a sphere would show its underside on a slope.
func _stone_mesh(sides: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	# Two rings and a crown: enough to read as a rounded stone at the size these
	# are drawn, and 3 * sides triangles rather than a sphere's dozens.
	var rings := [
		{"y": 0.0, "r": 0.5},
		{"y": 0.22, "r": 0.44},
		{"y": 0.38, "r": 0.26},
	]
	for ring_index in rings.size():
		var ring: Dictionary = rings[ring_index]
		for i in sides:
			var a := TAU * float(i) / float(sides)
			# A little per-vertex wobble so the silhouette is not a polygon.
			var wobble := 1.0 + 0.16 * sin(float(i) * 2.7 + float(ring_index) * 1.9)
			verts.append(Vector3(sin(a), 0.0, cos(a)) * float(ring["r"]) * wobble
					+ Vector3.UP * float(ring["y"]))
			normals.append(Vector3(sin(a) * 0.7, 0.6, cos(a) * 0.7).normalized())
	var crown := verts.size()
	verts.append(Vector3.UP * 0.44)
	normals.append(Vector3.UP)
	for ring_index in rings.size() - 1:
		for i in sides:
			var a0 := ring_index * sides + i
			var a1 := ring_index * sides + (i + 1) % sides
			var b0 := a0 + sides
			var b1 := a1 + sides
			indices.append_array([a0, b0, a1, a1, b0, b1])
	var top := (rings.size() - 1) * sides
	for i in sides:
		indices.append_array([top + i, crown, top + (i + 1) % sides])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


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

	# Metres, baked. An earlier version carried the mesh in [-0.5, 0.5] and let
	# the shader's `blade_width` scale x -- which also scaled the OFFSET below,
	# so the four blades of a tuft collapsed to two centimetres apart and every
	# tuft rendered as one wide leaf. Real dimensions here, and `blade_width`
	# is a multiplier around 1.0.
	# 16mm half-width and a tip that keeps 40% of it. An earlier version tapered
	# to 15% of an 11mm blade, which is a 1.6mm tip -- sub-pixel at any distance
	# past a couple of metres, and it aliased into white speckle across the whole
	# field rather than reading as grass.
	# 11mm blades, and the number has now been wrong in both directions. At 19mm
	# a blind critic measured them against the 1.80m trainer and called them
	# 4-6cm where real meadow grass at this height is 3-6mm -- "a field of
	# leeks". At a literal 6mm they are correct and read WORSE: a 6mm blade is
	# under a pixel wide beyond a few metres on a 1280-wide frame, so the field
	# dissolves into wisp and the software rasteriser has no coverage AA to
	# recover it. 11mm is the compromise the render resolution actually
	# supports, not the botanically right answer. Revisit if the game ever
	# renders at a resolution where a thinner blade survives minification.
	var half_width := 0.0055
	var spread := 0.075
	for b in blades:
		var yaw := TAU * float(b) / float(blades) + 0.37 * float(b)
		var dir := Vector3(sin(yaw), 0.0, cos(yaw))
		var side := Vector3(dir.z, 0.0, -dir.x)
		var normal := dir
		# Blades of one tuft start at slightly different points so the tuft has
		# a footprint rather than a single stem.
		var offset := (dir * 0.6 + side * (float(b) - float(blades - 1) * 0.5)) * spread
		var first := verts.size()
		for s in segments + 1:
			var t := float(s) / float(segments)
			# Taper: full width at the base, a point at the tip.
			var half := half_width * (1.0 - t * t * 0.55)
			verts.append(offset + side * -half + Vector3.UP * t)
			verts.append(offset + side * half + Vector3.UP * t)
			normals.append(normal)
			normals.append(normal)
			uvs.append(Vector2(0.0, t))
			uvs.append(Vector2(1.0, t))
			var blade_id := float(b) / float(blades)
			uv2s.append(Vector2(blade_id, 0.0))
			uv2s.append(Vector2(blade_id, 0.0))
		for s in segments:
			var a := first + s * 2
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
		"gust", "gust_speed", "gust_length",
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


## Tell the grass where the bushes gather, so it gives way to them.
##
## The grass and the cover tiers are separate MultiMeshes that know nothing
## about each other, so without this they simply occupy the same ground: blades
## stand through leaves and the near field reads as two systems drawn over each
## other rather than as one meadow. A bush shades out what grows beneath it, and
## this is that, done the only way two independent procedural fields can agree
## on anything -- by evaluating the SAME function.
##
## So the numbers are read off the claiming tier's own config entry rather than
## written twice. A tier claims clearings with `clears_grass`, and the shader's
## `clearing_*` uniforms are its `drift_scale` and `drift_contrast` verbatim; if
## the bushes move, the thinning moves with them. With no tier claiming,
## `clearing_strength` stays 0 and the grass shader skips the work entirely.
func _apply_clearing(cfg: Dictionary) -> void:
	if _material == null:
		return
	for entry: Variant in cfg.get("cover_tiers", []):
		var tier: Dictionary = entry
		if not (bool(tier.get("enabled", true)) and bool(tier.get("clears_grass", false))):
			continue
		_material.set_shader_parameter("clearing_scale", float(tier.get("drift_scale", 0.05)))
		_material.set_shader_parameter("clearing_contrast", float(tier.get("drift_contrast", 0.88)))
		_material.set_shader_parameter("clearing_strength",
				float(cfg.get("clearing_strength", 0.85)))
		_material.set_shader_parameter("clearing_floor", float(cfg.get("clearing_floor", 0.78)))
		_material.set_shader_parameter("clearing_shorten", float(cfg.get("clearing_shorten", 0.45)))
		return


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

	var rids: Array[RID] = [_material.get_rid()]
	if _stone_material != null:
		rids.append(_stone_material.get_rid())
	for cover: ShaderMaterial in _cover_materials:
		rids.append(cover.get_rid())
	for rid: RID in rids:
		_bind_maps(rid, data)
	_bind_region_uniforms(data)

	# Say out loud whether the stone tier actually got the terrain, because the
	# failure mode when it does not is silent and spectacular: an unbound
	# `sampler2DArray` still texelFetches, at a layer index this shader takes up
	# to the region count, and the undefined result goes straight into a vertex
	# Y offset. The stones then render kilometres up as a dome of white shards.
	# It cost two render cycles of guessing before this line existed.
	if _stone_material != null:
		var stone_rid: RID = _stone_material.get_rid()
		print("[grass_field] stone tier: rid_valid=%s height_map=%s region_map=%d entries" % [
			str(stone_rid.is_valid()),
			str(RenderingServer.material_get_param(stone_rid, "_height_maps")),
			(RenderingServer.material_get_param(stone_rid, "_region_map") as Array).size()
				if RenderingServer.material_get_param(stone_rid, "_region_map") != null else -1])


## The three map textures, onto one material. Bound through the RenderingServer
## rather than `set_shader_parameter` because `Terrain3DData` hands them out as
## RIDs and there is no Texture2DArray object to pass.
func _bind_maps(rid: RID, data: Object) -> void:
	for pair: Array in [
		["_height_maps", "get_height_maps_rid"],
		["_control_maps", "get_control_maps_rid"],
		["_color_maps", "get_color_maps_rid"],
	]:
		if data.has_method(str(pair[1])):
			RenderingServer.material_set_param(rid, str(pair[0]), data.call(str(pair[1])))


## The region arithmetic, onto both materials. Read off the LIVE terrain: the
## shaders reproduce Terrain3D's own lookup and a region size or vertex spacing
## that disagreed by one would put the whole field on the wrong ground.
func _bind_region_uniforms(data: Object) -> void:
	var region_size := float(_terrain.get("region_size"))
	var vertex_spacing := float(_terrain.get("vertex_spacing"))
	var region_map: Array = data.call("get_region_map") if data.has_method("get_region_map") else []
	var map := PackedInt32Array()
	map.resize(region_map.size())
	for i in region_map.size():
		map[i] = int(region_map[i])

	var all: Array[ShaderMaterial] = [_material, _stone_material]
	all.append_array(_cover_materials)
	for mat: ShaderMaterial in all:
		if mat == null:
			continue
		mat.set_shader_parameter("_region_size", region_size)
		mat.set_shader_parameter("_region_texel_size", 1.0 / region_size)
		mat.set_shader_parameter("_region_map_size", int(sqrt(float(region_map.size()))))
		mat.set_shader_parameter("_vertex_density", 1.0 / vertex_spacing)
		mat.set_shader_parameter("_region_map", map)
	_bound = true
	print("[grass_field] bound: %d tufts, radius %.0fm, region_size %.0f, vertex_spacing %.1f, %d region slots" % [
		multimesh.instance_count if multimesh != null else 0,
		float(config().get("field_radius", 48.0)), region_size, vertex_spacing, map.size()])


func _process(delta: float) -> void:
	if _material == null:
		return
	_wind += delta
	_material.set_shader_parameter("wind_time", _wind)
	for cover: ShaderMaterial in _cover_materials:
		cover.set_shader_parameter("wind_time", _wind)
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
	if _stone_material != null:
		_stone_material.set_shader_parameter("field_centre", centre)
	for cover: ShaderMaterial in _cover_materials:
		cover.set_shader_parameter("field_centre", centre)
