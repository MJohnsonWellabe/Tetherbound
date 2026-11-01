extends Node3D

## Dense decorative ground layers for Cloudreach's stacked cliff surfaces.
##
## Meadows can keep a camera-relative field because Terrain3D provides one
## height per XZ. Cloudreach deliberately stacks surfaces at the same XZ, so it
## uses deterministic per-plate MultiMeshes instead. The meshes themselves are
## the Meadows GrassField's production tuft, flower and bush meshes; only the
## placement source changes. Every patch has its own visibility range so the
## whole 6.5 km chapter is never submitted at once.

const GRASS_FIELD_SCRIPT := preload("res://scripts/world/grass_field.gd")
const COVER_SHADER := preload("res://shaders/cloudreach_ground_cover.gdshader")
const GRASS_ROLES := preload("res://scripts/world/cloudreach_grass_roles.gd")
const EXCLUSION_INDEX := preload("res://scripts/world/cloudreach_cover_exclusion_index.gd")
const COVER_BUFFER := preload("res://scripts/world/cloudreach_cover_buffer.gd")

var _grass_instances := 0
var _flower_instances := 0
var _bush_instances := 0
var _exclusions: Array[Dictionary] = []
## Index overflow exclusions unpacked once per patch for the placement loop (the same
## arithmetic as _excluded, without per-root Dictionary/String lookups).
var _fast_seg_a := PackedVector3Array()
var _fast_seg_b := PackedVector3Array()
var _fast_seg_half := PackedFloat64Array()
var _fast_box_centre := PackedVector3Array()
var _fast_box_rotation := PackedFloat64Array()
var _fast_box_half := PackedVector2Array()
var _fast_box_ellipse: Array[bool] = []

var _active_index := EXCLUSION_INDEX.new()
var _active_exclusions: Array[Dictionary] = []:
	set(value):
		_active_exclusions = value
		_active_index.build(value)
		_prepare_fast_exclusions()
var _profile_enabled := false
var _profile_started_ms := 0
var _profile_last_ms := 0
var _profile_lines := 0
var _profile_queries := 0
var _profile_candidates := 0
var _profile_linear_candidates := 0
## Optional instance cache (capture-speed lane, 1 Nov 2026). See `cache_key()`.
const CACHE_FORMAT := 1
const CACHE_ARG := "--ground-cover-cache"
const CACHE_DEFAULT_DIR := "user://ground_cover_cache"
## Scripts whose code decides the generated transforms. Their source text is
## part of the cache key, so editing any of them is a cache miss.
const CACHE_CODE_PATHS: Array[String] = [
	"res://scripts/world/cloudreach_ground_cover.gd",
	"res://scripts/world/cloudreach_grass_roles.gd",
	"res://scripts/world/cloudreach_cover_exclusion_index.gd",
	"res://scripts/world/cloudreach_cover_buffer.gd",
	"res://scripts/world/cloudreach_crown_surface.gd",
]
var _cache_hit: Dictionary = {}
var _cache_record: Dictionary = {}
var _cache_state := "off"
static var _cache_unkeyable := false


func build(patches: Array[Dictionary], config: Dictionary, exclusions: Array[Dictionary] = [],
		build_budget: RefCounted = null) -> void:
	_exclusions = exclusions
	_profile_enabled = OS.get_cmdline_user_args().has("--profile-realm-load")
	_profile_started_ms = Time.get_ticks_msec()
	_profile_last_ms = _profile_started_ms
	_profile_lines = 0
	_profile_queries = 0
	_profile_candidates = 0
	_profile_linear_candidates = 0
	var factory := GRASS_FIELD_SCRIPT.new()
	# Seven-blade groups read as tufted ground cover at gameplay distance. The
	# former four-blade/high-density combination resolved into uniform vertical
	# noise even though its instance count was high.
	var grass_mesh := factory.call("surface_tuft_mesh", 7, 2) as ArrayMesh
	var flower_mesh := factory.call("surface_cover_mesh", "flower") as ArrayMesh
	var bush_mesh := factory.call("surface_cover_mesh", "bush") as ArrayMesh
	factory.free()

	var grass_material := _cover_material(
		Color(str(config.get("grass_base", "#334512"))),
		Color(str(config.get("grass_tip", "#84933a"))), 0.11, 0.50, false)
	var dry_grass_material := _cover_material(
		Color(str(config.get("dry_grass_base", "#4b4919"))),
		Color(str(config.get("dry_grass_tip", "#a89b42"))), 0.14, 0.50, false)
	var surface_family := preload("res://scripts/world/cloudreach_environment_materials.gd")
	surface_family.ground_cover_parameters(grass_material, false, config)
	surface_family.ground_cover_parameters(dry_grass_material, true, config)
	grass_material.set_shader_parameter("grass_curve", 0.30)
	dry_grass_material.set_shader_parameter("grass_curve", 0.30)
	grass_material.set_shader_parameter("camera_clearance", true)
	dry_grass_material.set_shader_parameter("camera_clearance", true)
	var flower_material := _cover_material(
		Color(str(config.get("flower_base", "#335119"))),
		Color(str(config.get("flower_tip", "#d49ac6"))), 0.075, 0.62, false)
	var bush_material := _cover_material(
		Color(str(config.get("bush_base", "#243b16"))),
		Color(str(config.get("bush_tip", "#647a31"))), 0.055, 0.72, true)

	var cache_path := _cache_path(patches, config, exclusions)
	_cache_hit = {}
	_cache_record = {}
	_cache_state = "off"
	if not cache_path.is_empty():
		_cache_hit = load_cache(cache_path)
		_cache_state = "hit" if not _cache_hit.is_empty() else "miss"
		print("[cloudreach_cover] instance cache %s %s" % [_cache_state, cache_path])
	for patch_index in patches.size():
		await _breathe(build_budget)
		var patch := patches[patch_index]
		if _cache_state != "hit":
			_active_exclusions = _nearby_exclusions(patch)
		var patch_root := Node3D.new()
		patch_root.name = "CoverPatch%03d" % patch_index
		patch_root.position = _patch_origin(patch)
		add_child(patch_root)
		var area := _patch_area(patch)
		var is_route := str(patch.get("kind", "ellipse")) == "segment"
		var grass_count := mini(int(area * float(config.get("grass_density_per_m2", 0.24))),
			int(config.get("route_grass_patch_cap", 12000) if is_route
				else config.get("region_grass_patch_cap", 50000)))
		if is_route:
			grass_count=int(grass_count*0.64)
		var flower_count := mini(int(area * float(config.get("flower_density_per_m2", 0.010))),
			int(config.get("route_flower_patch_cap", 360) if is_route
				else config.get("region_flower_patch_cap", 900)))
		var bush_count := mini(int(area * float(config.get("bush_density_per_m2", 0.0025))),
			int(config.get("route_bush_patch_cap", 52) if is_route
				else config.get("region_bush_patch_cap", 130)))
		if _cache_state == "hit":
			_grass_instances += await _emit_cached(patch_root, "Grass", patch_index, 0, grass_mesh,
				dry_grass_material if bool(patch.get("dry", false)) else grass_material, config,
				build_budget)
			_flower_instances += await _emit_cached(patch_root, "Flowers", patch_index, 1,
				flower_mesh, flower_material, config, build_budget)
			_bush_instances += await _emit_cached(patch_root, "Understorey", patch_index, 2,
				bush_mesh, bush_material, config, build_budget)
			continue
		_grass_instances += await _build_patch_tier(patch_root, "Grass", patch, grass_mesh,
			dry_grass_material if bool(patch.get("dry", false)) else grass_material,
			grass_count, float(config.get("grass_scale_min", 0.52)),
			float(config.get("grass_scale_max", 0.88)), config, patch_index * 31 + 7, 0,
			build_budget)
		_flower_instances += await _build_patch_tier(patch_root, "Flowers", patch, flower_mesh,
			flower_material, flower_count, float(config.get("flower_scale_min", 0.62)),
			float(config.get("flower_scale_max", 1.05)), config, patch_index * 31 + 13, 1,
			build_budget)
		_bush_instances += await _build_patch_tier(patch_root, "Understorey", patch, bush_mesh,
			bush_material, bush_count, float(config.get("bush_scale_min", 0.72)),
			float(config.get("bush_scale_max", 1.18)), config, patch_index * 31 + 19, 2,
			build_budget)
	if _cache_state == "miss":
		var error := save_cache(cache_path, _cache_record)
		print("[cloudreach_cover] instance cache write %s %s" % [error_string(error), cache_path])
	_cache_record = {}
	_cache_hit = {}


## "off", "hit" (transforms read from the cache) or "miss" (generated and written).
func cache_state() -> String:
	return _cache_state


func grass_instance_count() -> int:
	return _grass_instances


func flower_instance_count() -> int:
	return _flower_instances


func bush_instance_count() -> int:
	return _bush_instances


func _build_patch_tier(parent: Node3D, label: String, patch: Dictionary, mesh: ArrayMesh,
		material: ShaderMaterial, requested: int, scale_min: float, scale_max: float,
		config: Dictionary, seed_value: int, tier: int,
		build_budget: RefCounted = null) -> int:
	if requested <= 0 or mesh == null:
		return 0
	var origin := parent.position
	var transforms := PackedFloat32Array()
	var accepted := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + int(patch.get("seed", 0)) * 1009
	var attempts := 0
	var unsupported := 0
	var max_attempts := maxi(requested * 7, 32)
	var path_clearance := float(config.get("path_clearance_m", 1.8))
	# One continuous asymmetric planting field across adjacent geometry chunks.
	# Per-patch phase previously made visible parallel planting bands.
	var frequency := float(config.get("cluster_frequency", 0.16))
	var threshold := float(config.get("cluster_threshold", -0.18)) + float(tier) * 0.34
	var sampler := _prepare_sampler(patch, path_clearance)
	while accepted + unsupported < requested and attempts < max_attempts:
		attempts += 1
		if attempts % 2048 == 0:
			_profile_progress("sample", parent.name, label, attempts, accepted, requested)
			await _breathe(build_budget)
		# The planting field is tested inside the sampler, on XZ, before the
		# surface height and exclusion lookups (it draws no random numbers, so
		# the accepted set and every RNG draw are unchanged). About three of
		# four attempts fail it; the height/exclusion work on them was most of
		# Cloudreach's load time (host_first_realm, 13 Oct).
		var at := _sample_prepared(sampler, rng, frequency, threshold)
		if is_nan(at.y):
			continue
		if _excluded(at, true):
			continue
		var legacy_scale: float = rng.randf_range(scale_min, scale_max)
		var scale_value: float = legacy_scale * float(patch.get("height_scale", 1.0))
		var legacy_width: float = rng.randf_range(0.82, 1.16)
		var width_scale: float = scale_value * legacy_width
		if tier == 0:
			# Preserve both historical width draws. Only the second draw affected
			# grass, but consuming the first keeps later grass positions and yaws
			# bit-stable within this tier's RNG stream.
			var grass_width_draw: float = rng.randf_range(1.6, 2.3)
			var height_jitter: float = GRASS_ROLES.unit_jitter(legacy_scale, scale_min, scale_max)
			var width_jitter: float = GRASS_ROLES.unit_jitter(grass_width_draw, 1.6, 2.3)
			var role: int = GRASS_ROLES.role_at(at, config)
			var tall_eligible := true
			if str(patch.get("kind", "")) == "segment" \
					and role == GRASS_ROLES.SPARSE_TALL:
				var axis: Vector3 = (patch["b"] as Vector3) - (patch["a"] as Vector3)
				axis.y = 0.0
				var lateral: float = absf(Vector3.UP.cross(axis.normalized()).dot(
					at - (patch["a"] as Vector3)))
				var tall_clear: float = float(patch.get("path_half_width", 4.0)) \
					+ float(config.get("path_clearance_m", 1.8)) \
					+ float(config.get("grass_role_tall_route_clearance_m", 2.5))
				tall_eligible = lateral >= tall_clear
			var role_scales: Vector3 = GRASS_ROLES.scales_for_role(role, height_jitter,
				width_jitter, float(patch.get("height_scale", 1.0)), config, tall_eligible)
			role_scales *= GRASS_ROLES.local_scale(at, config)
			scale_value = role_scales.y
			width_scale = role_scales.x
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
			Vector3(width_scale, scale_value, width_scale))
		# Discard unsupported roots only after consuming the same placement and
		# appearance draws. Count them toward the requested total: retrying them
		# would pack extra grass against the terrace edge and move valid tufts.
		if patch.has("clip_rect") and not (patch["clip_rect"] as Rect2).has_point(Vector2(at.x, at.z)):
			unsupported += 1
			continue
		COVER_BUFFER.append(transforms, Transform3D(basis, at - origin))
		accepted += 1
	if _cache_state == "miss":
		_cache_record[_cache_slot(parent, tier)] = transforms.duplicate()
	if transforms.is_empty():
		return 0
	return await _emit_patch_tier(parent, label, mesh, material, transforms, config,
		build_budget)


func _cache_slot(parent: Node, tier: int) -> String:
	return "%s:%d" % [str(parent.name), tier]


## A cache hit uploads the exact float32 transforms a miss generated for this
## patch and tier, through the same upload path, so the MultiMesh buffers,
## counts, node names and order are identical.
func _emit_cached(parent: Node3D, label: String, patch_index: int, tier: int, mesh: ArrayMesh,
		material: ShaderMaterial, config: Dictionary, build_budget: RefCounted) -> int:
	if mesh == null:
		return 0
	var cached: Variant = _cache_hit.get(_cache_slot(parent, tier), PackedFloat32Array())
	var transforms: PackedFloat32Array = (cached as PackedFloat32Array).duplicate() \
		if cached is PackedFloat32Array else PackedFloat32Array()
	if transforms.is_empty():
		return 0
	return await _emit_patch_tier(parent, label, mesh, material, transforms, config,
		build_budget)


## The cache file for these exact inputs, or "" when the cache is off. On only
## with `--ground-cover-cache` (or `--ground-cover-cache=<dir>`) on the
## command line; capture tools pass it, ordinary play never does.
func _cache_path(patches: Array[Dictionary], config: Dictionary,
		exclusions: Array[Dictionary]) -> String:
	var directory := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg == CACHE_ARG:
			directory = CACHE_DEFAULT_DIR
		elif arg.begins_with(CACHE_ARG + "="):
			directory = arg.trim_prefix(CACHE_ARG + "=").strip_edges()
	if directory.is_empty():
		return ""
	var key := cache_key(patches, config, exclusions)
	if key.is_empty():
		push_warning("[cloudreach_cover] instance cache off: an input object has no fingerprint")
		return ""
	return "%s/cloudreach_cover_%s.bin" % [directory, key]


## sha256 over everything that decides the generated transforms: the cache
## format, engine version (FastNoiseLite, RNG), the generator scripts' source,
## the ground-cover config, every patch (a crown-surface sampler by its exact
## triangle bytes) and every exclusion, all as exact binary `var_to_bytes`.
## Any change to any input is a different file; nothing is ever invalidated
## in place.
static func cache_key(patches: Array[Dictionary], config: Dictionary,
		exclusions: Array[Dictionary]) -> String:
	_cache_unkeyable = false
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(("format=%d engine=%s" % [CACHE_FORMAT, Engine.get_version_info().get("hash", "")]).to_utf8_buffer())
	for path: String in CACHE_CODE_PATHS:
		hashing.update(FileAccess.get_file_as_string(path).to_utf8_buffer())
	hashing.update(var_to_bytes(_cache_plain(config)))
	hashing.update(var_to_bytes(_cache_plain(patches)))
	hashing.update(var_to_bytes(_cache_plain(exclusions)))
	var digest := hashing.finish().hex_encode()
	# An input object whose data cannot be fingerprinted makes the inputs
	# unkeyable: never risk a stale hit, generate instead.
	return "" if _cache_unkeyable else digest


## Replace objects (crown-surface samplers) with a fingerprint of their data
## so `var_to_bytes` never encodes an instance id.
static func _cache_plain(value: Variant) -> Variant:
	if value is Dictionary:
		var out := {}
		for key: Variant in (value as Dictionary):
			out[key] = _cache_plain((value as Dictionary)[key])
		return out
	if value is Array:
		var out := []
		for item: Variant in (value as Array):
			out.append(_cache_plain(item))
		return out
	if value is Object:
		var object := value as Object
		var triangles: Variant = object.get("_triangles") if is_instance_valid(object) else null
		if triangles is PackedVector3Array:
			return "sampler:" + (triangles as PackedVector3Array).to_byte_array().hex_encode().sha256_text()
		_cache_unkeyable = true
		return "object:" + (object.get_class() if is_instance_valid(object) else "freed")
	return value


static func load_cache(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var stored: Variant = file.get_var()
	file.close()
	if not stored is Dictionary or int((stored as Dictionary).get("format", -1)) != CACHE_FORMAT:
		return {}
	var tiers: Variant = (stored as Dictionary).get("tiers", {})
	return tiers as Dictionary if tiers is Dictionary else {}


## Written to a temporary name and renamed, so a killed boot never leaves a
## truncated file under the final key.
static func save_cache(path: String, tiers: Dictionary) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var temporary := path + ".partial"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_var({"format": CACHE_FORMAT, "tiers": tiers})
	file.close()
	return DirAccess.rename_absolute(temporary, path)


## Upload one unchanged patch/tier batch. Drop the caller's temporary packed
## storage before yielding; MultiMesh owns the submitted data from here.
func _emit_patch_tier(parent: Node3D, label: String, mesh: ArrayMesh,
		material: ShaderMaterial, transforms: PackedFloat32Array, config: Dictionary,
		build_budget: RefCounted = null) -> int:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	var count := int(transforms.size() / 12.0)
	mm.instance_count = count
	mm.buffer = transforms
	transforms.clear()
	if count > 2048:
		_profile_progress("upload", parent.name, label, count, count, count)
		await _breathe(build_budget)
	var instances := MultiMeshInstance3D.new()
	instances.name = label
	instances.multimesh = mm
	instances.material_override = material
	instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instances.visibility_range_end = float(config.get("visibility_range_m", 360.0))
	instances.visibility_range_end_margin = 42.0
	instances.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(instances)
	return count


func _profile_progress(phase: String, patch: StringName, tier: String,
		progress: int, accepted: int, requested: int) -> void:
	if not _profile_enabled or _profile_lines >= 64:
		return
	var now := Time.get_ticks_msec()
	if now - _profile_last_ms < 10000:
		return
	_profile_last_ms = now
	_profile_lines += 1
	print("[cloudreach_cover] phase=%s patch=%s tier=%s progress=%d accepted=%d requested=%d elapsed_ms=%d local_exclusions=%d unbounded_exclusions=%d queries=%d candidates=%d linear_candidates=%d" % [
		phase, patch, tier, progress, accepted, requested, now - _profile_started_ms,
		_active_exclusions.size(), _active_index.unbounded.size(),
		_profile_queries, _profile_candidates, _profile_linear_candidates])


func _breathe(build_budget: RefCounted) -> void:
	if build_budget != null and build_budget.has_method("breathe"):
		await build_budget.call("breathe")


func _nearby_exclusions(patch: Dictionary) -> Array[Dictionary]:
	var centre := _patch_origin(patch)
	var follows_surface := patch.has("surface_rows") or patch.has("crown_surface")
	var radius := 0.0
	if str(patch.get("kind", "")) == "segment":
		radius = (patch["a"] as Vector3).distance_to(patch["b"]) * 0.5 + float(patch["half_width"])
	else:
		var half: Vector2 = patch["half"]
		radius = maxf(half.x, half.y)
	var nearby: Array[Dictionary] = []
	for exclusion: Dictionary in _exclusions:
		var at: Vector3
		var extra := 10.0
		if str(exclusion.get("kind", "")) == "segment":
			var a: Vector3 = exclusion["a"]
			var b: Vector3 = exclusion["b"]
			var ab := b - a
			var t := clampf((centre - a).dot(ab) / maxf(ab.length_squared(), 0.01), 0, 1)
			if follows_surface:
				var flat := Vector2(ab.x, ab.z)
				t = clampf(Vector2(centre.x - a.x, centre.z - a.z).dot(flat)
					/ maxf(flat.length_squared(), 0.01), 0, 1)
			at = a.lerp(b, t)
		else:
			at = exclusion["centre"]
			extra = (exclusion["half"] as Vector2).length()
		# Surface clamps can move roots vertically away from the source line.
		# Cull in XZ, then let _excluded test the corrected root's actual height.
		var distance := Vector2(at.x - centre.x, at.z - centre.z).length() \
			if follows_surface else at.distance_to(centre)
		if distance < radius + extra + 4.0:
			nearby.append(exclusion)
	return nearby


func _prepare_fast_exclusions() -> void:
	_fast_seg_a.clear(); _fast_seg_b.clear(); _fast_seg_half.clear()
	_fast_box_centre.clear(); _fast_box_rotation.clear(); _fast_box_half.clear(); _fast_box_ellipse.clear()
	for exclusion: Dictionary in _active_index.unbounded:
		if str(exclusion.get("kind", "")) == "segment":
			_fast_seg_a.append(exclusion["a"])
			_fast_seg_b.append(exclusion["b"])
			_fast_seg_half.append(float(exclusion["half_width"]))
		else:
			_fast_box_centre.append(exclusion["centre"])
			_fast_box_rotation.append(float(exclusion["rotation"]))
			_fast_box_half.append(exclusion["half"])
			_fast_box_ellipse.append(str(exclusion.get("kind", "")) == "ellipse")


## The original narrow phase over overflow arrays: the same tests, so the same
## answer for every root (segments and boxes are independent ORs).
func _excluded_fast(at: Vector3) -> bool:
	for i in _fast_seg_a.size():
		var a: Vector3 = _fast_seg_a[i]
		var b: Vector3 = _fast_seg_b[i]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t := clampf(Vector2(at.x - a.x, at.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.01), 0, 1)
		var nearest := a.lerp(b, t)
		if absf(nearest.y - at.y) < 3.0 and Vector2(at.x - nearest.x, at.z - nearest.z).length() < float(_fast_seg_half[i]):
			return true
	for i in _fast_box_centre.size():
		var centre: Vector3 = _fast_box_centre[i]
		if absf(at.y - centre.y) > 3.0:
			continue
		var local := Vector2(at.x - centre.x, at.z - centre.z).rotated(-float(_fast_box_rotation[i]))
		var half: Vector2 = _fast_box_half[i]
		if _fast_box_ellipse[i]:
			if (local/half).length_squared()<=1.0:
				return true
			continue
		if absf(local.x) <= half.x and absf(local.y) <= half.y:
			return true
	return false


## _sample_patch's per-patch constants, read once per tier instead of once
## per attempt. _sample_prepared draws the same random numbers in the same
## order and evaluates the same expressions, so every root is unchanged.
func _prepare_sampler(patch: Dictionary, path_clearance: float) -> Dictionary:
	var prepared := {"patch": patch, "segment": str(patch.get("kind", "ellipse")) == "segment"}
	if prepared.segment:
		var a: Vector3 = patch.get("a", Vector3.ZERO)
		var b: Vector3 = patch.get("b", Vector3.ZERO)
		var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
		var half_width := float(patch.get("half_width", 20.0))
		var clear := float(patch.get("path_half_width", 4.0)) + path_clearance
		prepared.valid = flat.length_squared() >= 0.01 and half_width > clear
		prepared.a = a
		prepared.b = b
		prepared.right = Vector3.UP.cross(flat.normalized()).normalized() if prepared.valid else Vector3.ZERO
		prepared.half_width = half_width
		prepared.clear = clear
		prepared.rows = patch.get("surface_rows") if patch.has("surface_rows") else null
		prepared.offset = Vector3.UP * float(patch.get("surface_offset_y", -0.64))
	else:
		prepared.centre = patch.get("centre", Vector3.ZERO)
		prepared.half = patch.get("half", Vector2(20.0, 20.0))
		prepared.inner = float(patch.get("inner_clear_fraction", 0.0))
		prepared.crown = patch.get("crown_surface") if patch.has("crown_surface") else null
	return prepared


func _sample_prepared(p: Dictionary, rng: RandomNumberGenerator, frequency: float,
		threshold: float) -> Vector3:
	if p.segment:
		if not p.valid:
			return Vector3(NAN, NAN, NAN)
		var half_width: float = p.half_width
		var clear: float = p.clear
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var lateral := rng.randf_range(clear, half_width * 0.92) * side
		var t := rng.randf_range(0.02, 0.98)
		var at: Vector3 = (p.a as Vector3).lerp(p.b, t) + (p.right as Vector3) * lateral
		var edge_mass:=sin(at.x*0.49+side*1.7)*cos(at.z*0.43-side*0.7)
		edge_mass+=0.35*sin(at.x*0.91+at.z*0.77)
		var worn_width:=clear+minf(2.0,half_width-clear)*(0.5+0.5*sin(at.x*0.27+at.z*0.31))
		if edge_mass < 0.05 or absf(lateral)<worn_width:
			return Vector3(NAN,NAN,NAN)
		if _cluster_value(at.x, at.z, frequency) < threshold:
			return Vector3(NAN, NAN, NAN)
		if p.rows != null:
			at.y = _ridge_surface_height(p.rows, at)
		return at + (p.offset as Vector3)
	var half: Vector2 = p.half
	var angle := rng.randf_range(0.0, TAU)
	var radius := sqrt(rng.randf()) * 0.88
	if radius < float(p.inner):
		return Vector3(NAN, NAN, NAN)
	var at: Vector3 = (p.centre as Vector3) + Vector3(cos(angle) * half.x * radius, 0.08,
		sin(angle) * half.y * radius)
	if _cluster_value(at.x, at.z, frequency) < threshold:
		return Vector3(NAN, NAN, NAN)
	if p.crown != null:
		var sample: Vector2 = p.crown.sample(at.x, at.z)
		if not is_finite(sample.x) or sample.y < 0.64:
			return Vector3(NAN, NAN, NAN)
		at.y = sample.x + 0.04
	return at


func _excluded(at: Vector3, local_only: bool = false) -> bool:
	if local_only:
		var candidates := _active_index.candidates(at)
		if _profile_enabled:
			_profile_queries += 1
			_profile_candidates += candidates.size() + _active_index.unbounded.size()
			_profile_linear_candidates += _active_exclusions.size()
		return _excluded_from(at, candidates) \
			or _excluded_fast(at)
	return _excluded_from(at, _exclusions)


func _excluded_from(at: Vector3, exclusions: Array[Dictionary]) -> bool:
	# Keep the exact old narrow phase: same vertical gates, projection,
	# rotation, strict/inclusive boundaries, and no additional RNG draws.
	for exclusion: Dictionary in exclusions:
		if str(exclusion.get("kind", "")) == "segment":
			var a: Vector3 = exclusion["a"]
			var b: Vector3 = exclusion["b"]
			var ab := Vector2(b.x - a.x, b.z - a.z)
			var t := clampf(Vector2(at.x - a.x, at.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.01), 0, 1)
			var nearest := a.lerp(b, t)
			if absf(nearest.y - at.y) < 3.0 and Vector2(at.x - nearest.x, at.z - nearest.z).length() < float(exclusion["half_width"]):
				return true
			continue
		var centre: Vector3 = exclusion["centre"]
		if absf(at.y - centre.y) > 3.0:
			continue
		var local := Vector2(at.x - centre.x, at.z - centre.z).rotated(-float(exclusion["rotation"]))
		var half: Vector2 = exclusion["half"]
		if str(exclusion.get("kind",""))=="ellipse":
			if (local/half).length_squared()<=1.0:
				return true
			continue
		if absf(local.x) <= half.x and absf(local.y) <= half.y:
			return true
	return false


## The planting field's value at an XZ point (see _build_patch_tier).
static func _cluster_value(x: float, z: float, frequency: float) -> float:
	var cluster := sin(x * frequency * 0.61 + sin(z * frequency * 0.39))
	cluster += sin(z * frequency * 0.47 - x * frequency * 0.23) * 0.8
	cluster += sin(x * frequency * 1.9 + z * frequency * 1.2) * 0.22
	return cluster


func _sample_patch(patch: Dictionary, rng: RandomNumberGenerator, path_clearance: float,
		frequency: float = 0.0, threshold: float = -INF) -> Vector3:
	var kind := str(patch.get("kind", "ellipse"))
	if kind == "segment":
		var a: Vector3 = patch.get("a", Vector3.ZERO)
		var b: Vector3 = patch.get("b", Vector3.ZERO)
		var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
		if flat.length_squared() < 0.01:
			return Vector3(NAN, NAN, NAN)
		var right := Vector3.UP.cross(flat.normalized()).normalized()
		var half_width := float(patch.get("half_width", 20.0))
		var clear := float(patch.get("path_half_width", 4.0)) + path_clearance
		if half_width <= clear:
			return Vector3(NAN, NAN, NAN)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var lateral := rng.randf_range(clear, half_width * 0.92) * side
		var t := rng.randf_range(0.02, 0.98)
		var at:=a.lerp(b,t)+right*lateral
		# Two-dimensional lobes avoid a route aligned with a phase gradient
		# turning a low-frequency field into one uninterrupted bright rail.
		var edge_mass:=sin(at.x*0.49+side*1.7)*cos(at.z*0.43-side*0.7)
		edge_mass+=0.35*sin(at.x*0.91+at.z*0.77)
		var worn_width:=clear+minf(2.0,half_width-clear)*(0.5+0.5*sin(at.x*0.27+at.z*0.31))
		if edge_mass < 0.05 or absf(lateral)<worn_width:
			return Vector3(NAN,NAN,NAN)
		if threshold > -INF and _cluster_value(at.x, at.z, frequency) < threshold:
			return Vector3(NAN, NAN, NAN)
		if patch.has("surface_rows"):
			at.y = _ridge_surface_height(patch["surface_rows"], at)
		return at + Vector3.UP * float(patch.get("surface_offset_y", -0.64))
	var centre: Vector3 = patch.get("centre", Vector3.ZERO)
	var half: Vector2 = patch.get("half", Vector2(20.0, 20.0))
	var angle := rng.randf_range(0.0, TAU)
	var radius := sqrt(rng.randf()) * 0.88
	if radius < float(patch.get("inner_clear_fraction", 0.0)):
		return Vector3(NAN, NAN, NAN)
	var at := centre + Vector3(cos(angle) * half.x * radius, 0.08,
		sin(angle) * half.y * radius)
	if threshold > -INF and _cluster_value(at.x, at.z, frequency) < threshold:
		return Vector3(NAN, NAN, NAN)
	if patch.has("crown_surface"):
		var sample: Vector2 = patch["crown_surface"].sample(at.x, at.z)
		if not is_finite(sample.x) or sample.y < 0.64:
			return Vector3(NAN, NAN, NAN)
		at.y = sample.x + 0.04
	return at


## Sample the same triangle split that builds the visible/collidable shoulder.
## Its rows are ordered along one straight XZ axis, so only one interval needs
## testing even where a settlement clamp adds hundreds of cross-sections.
static func _ridge_surface_height(rows: Array, at: Vector3) -> float:
	if rows.size() < 2:
		return NAN
	var start: Vector3 = rows[0][3]
	var end: Vector3 = rows[rows.size() - 1][3]
	var axis := Vector2(end.x - start.x, end.z - start.z).normalized()
	var along := Vector2(at.x - start.x, at.z - start.z).dot(axis)
	var low := 0
	var high := rows.size() - 1
	while high - low > 1:
		var middle := (low + high) / 2
		var point: Vector3 = rows[middle][3]
		if Vector2(point.x - start.x, point.z - start.z).dot(axis) <= along:
			low = middle
		else:
			high = middle
	var row_a: Array = rows[low]
	var row_b: Array = rows[high]
	for column in row_a.size() - 1:
		var height := _triangle_height(at, row_a[column], row_b[column], row_a[column + 1])
		if is_finite(height):
			return height
		height = _triangle_height(at, row_a[column + 1], row_b[column], row_b[column + 1])
		if is_finite(height):
			return height
	return NAN


static func _triangle_height(at: Vector3, a: Vector3, b: Vector3, c: Vector3) -> float:
	var det := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
	if absf(det) < 0.000001:
		return NAN
	var u := ((b.z - c.z) * (at.x - c.x) + (c.x - b.x) * (at.z - c.z)) / det
	var v := ((c.z - a.z) * (at.x - c.x) + (a.x - c.x) * (at.z - c.z)) / det
	var w := 1.0 - u - v
	if minf(u, minf(v, w)) < -0.00001:
		return NAN
	return u * a.y + v * b.y + w * c.y


func _patch_origin(patch: Dictionary) -> Vector3:
	if str(patch.get("kind", "ellipse")) == "segment":
		var a: Vector3 = patch.get("a", Vector3.ZERO)
		var b: Vector3 = patch.get("b", Vector3.ZERO)
		return a.lerp(b, 0.5)
	return patch.get("centre", Vector3.ZERO)


func _patch_area(patch: Dictionary) -> float:
	if str(patch.get("kind", "ellipse")) == "segment":
		var a: Vector3 = patch.get("a", Vector3.ZERO)
		var b: Vector3 = patch.get("b", Vector3.ZERO)
		return a.distance_to(b) * float(patch.get("half_width", 20.0)) * 1.45
	var half: Vector2 = patch.get("half", Vector2(20.0, 20.0))
	return PI * half.x * half.y * 0.76


func _cover_material(base: Color, tip: Color, wind: float, soften: float,
		cut_leaves: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = COVER_SHADER
	material.set_shader_parameter("tint_base", base)
	material.set_shader_parameter("tint_tip", tip)
	material.set_shader_parameter("wind_strength", wind)
	material.set_shader_parameter("normal_soften", soften)
	material.set_shader_parameter("leaf_cut", 1.0 if cut_leaves else 0.0)
	return material
