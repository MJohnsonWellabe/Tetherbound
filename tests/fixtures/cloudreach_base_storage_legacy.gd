extends "res://scripts/world/cloudreach_ground_cover.gd"

## Frozen pre-storage placement/upload oracle from20062f725. Only the emitter
## name and the test-only recording line differ. No packed-buffer helper used.
var recorded: Array[Transform3D] = []

# Frozen functions from 20062f725d7e36ba3e896b0ed72a5c1216bae9d2; source-checked before native review.
func _build_patch_tier(parent: Node3D, label: String, patch: Dictionary, mesh: ArrayMesh,
		material: ShaderMaterial, requested: int, scale_min: float, scale_max: float,
		config: Dictionary, seed_value: int, tier: int,
		build_budget: RefCounted = null) -> int:
	if requested <= 0 or mesh == null:
		return 0
	var origin := parent.position
	var transforms: Array[Transform3D] = []
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
	while transforms.size() + unsupported < requested and attempts < max_attempts:
		attempts += 1
		if attempts % 2048 == 0:
			_profile_progress("sample", parent.name, label, attempts, transforms.size(), requested)
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
		transforms.append(Transform3D(basis, at - origin))
	if transforms.is_empty():
		return 0
	return await _legacy_emit_patch_tier(parent, label, mesh, material, transforms, config,
		build_budget)


func _legacy_emit_patch_tier(parent: Node3D, label: String, mesh: ArrayMesh,
		material: ShaderMaterial, transforms: Array[Transform3D], config: Dictionary,
		build_budget: RefCounted = null) -> int:
	recorded = transforms.duplicate()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		if i > 0 and i % 2048 == 0:
			_profile_progress("upload", parent.name, label, i + 1, transforms.size(), transforms.size())
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
	return transforms.size()
