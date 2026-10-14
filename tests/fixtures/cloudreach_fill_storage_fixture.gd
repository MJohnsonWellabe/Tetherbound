extends "res://scripts/world/cloudreach_look.gd"

## The frozen fd2 fill loop below is the placement oracle. Synthetic triangles
## cover wet/dry, near/far, steep/tiny rejection, fractional counts and RNG
## consumption on rejected tufts without loading a world or doing raycasts.
var recorded: Dictionary = {}

func _collect_turf_triangles() -> Array:
	_cover_fill_surfaces = 4
	_cover_fill_area = 500.0
	var result: Array = []
	for i in 8:
		var base := Vector3(i * 20, i * 3, -i * 13)
		result.append({"a": base, "b": base + Vector3(12, 1, 0),
			"c": base + Vector3(0, 2, 15), "area": 0.005 if i == 6 else 90.0,
			"normal_y": 0.1 if i == 7 else 0.9, "dry": i % 2 == 1})
	return result

func _fill_tuft_at(point: Vector3, _extra_clear: float, rng: RandomNumberGenerator,
		_scale_min: float, _scale_max: float, _buried_tolerance: float = 0.25) -> Variant:
	if int(absf(point.x * 3.0)) % 5 == 0:
		return null
	var width := rng.randf_range(0.7, 1.9)
	var height := rng.randf_range(0.3, 1.2)
	return Transform3D(Basis(Vector3.UP, rng.randf_range(-PI, PI)).scaled(
		Vector3(width, height, width * 0.8)), point + Vector3.UP * 0.02)

func _commit_tufts(_parent: Node3D, label: String, buffer: PackedFloat32Array,
		_mesh: ArrayMesh, material: Material, visibility_range: float) -> int:
	var transforms: Array[Transform3D] = []
	for offset in range(0, buffer.size(), 12):
		transforms.append(Transform3D(Basis(
			Vector3(buffer[offset], buffer[offset + 4], buffer[offset + 8]),
			Vector3(buffer[offset + 1], buffer[offset + 5], buffer[offset + 9]),
			Vector3(buffer[offset + 2], buffer[offset + 6], buffer[offset + 10])),
			Vector3(buffer[offset + 3], buffer[offset + 7], buffer[offset + 11])))
	return _record_legacy(_parent, label, transforms, _mesh, material, visibility_range)

func _record_legacy(_parent: Node3D, label: String, transforms: Array[Transform3D],
		_mesh: ArrayMesh, material: Material, visibility_range: float) -> int:
	recorded[label] = {"transforms": transforms.duplicate(), "material": material,
		"visibility": visibility_range}
	return transforms.size()

# Frozen fd2 function; only function and commit-seam names differ.
func legacy_fill(root: Node3D, ellipse_patches: Array, cfg: Dictionary, budget: int,
		tuft_mesh: ArrayMesh, main_material: Material, main_material_dry: Material,
		far_material: Material, far_material_dry: Material, extra_clear: float) -> void:
	var fill: Dictionary = cfg.get("turf_fill", {})
	if not bool(fill.get("enabled", true)) or ellipse_patches.is_empty() or tuft_mesh == null:
		return
	var spacing := maxf(1.0, float(fill.get("grid_spacing_m", 6.0)))
	var reach := maxf(spacing, float(fill.get("reach_m", 130.0)))
	var density := maxf(0.0, float(fill.get("density_per_m2", float(cfg.get("main_density_per_m2", 0.35)))))
	var far_density := maxf(0.0, float(fill.get("far_density_per_m2", 0.06)))
	var fade_start := maxf(0.0, float(fill.get("fade_start_m", 25.0)))
	var fade_span := maxf(1.0, float(fill.get("fade_span_m", 95.0)))
	var distant_factor := clampf(float(fill.get("distant_density_factor", 0.3)), 0.0, 1.0)
	var share := clampf(float(fill.get("budget_share", 0.55)), 0.0, 4.0)
	var near_visibility := float(fill.get("visibility_range_m", 360.0))
	var far_visibility := float(fill.get("far_visibility_range_m", float(cfg.get("far_visibility_range_m", 900.0))))
	var scale_min := float(fill.get("scale_min", 0.52))
	var scale_max := float(fill.get("scale_max", 0.95))
	# An absolute cap wins over the share when it is set: the fill covers every
	# turf surface in the realm now, not a skirt around each patch, so its size
	# is set by how much turf there IS and not by a fraction of the ellipse
	# pass's budget.
	var cap := maxi(0, int(float(budget) * share))
	if fill.has("instance_cap"):
		cap = maxi(0, int(fill["instance_cap"]))
	if cap <= 0:
		return

	var started_usec := Time.get_ticks_usec()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(fill.get("seed", 90607))
	var cell_area := spacing * spacing
	var probe_casts := 0
	# Cells are keyed on a global lattice so two patches whose skirts overlap
	# plant a cell once between them rather than twice.
	var seen: Dictionary = {}
	var cells: Array = []
	var desired := 0.0

	# PASS 1 -- read the turf off the GEOMETRY, not off a guessed grid.
	#
	# OWNER 2026-09-06: "there should be nowhere you can stand that doesn't
	# have grass or isn't a bare dirt patch or mud pit or something else. it
	# cannot just be plain green painted on a parking lot."
	#
	# That is an invariant, and a grid cannot hold it. Two grid shapes were
	# tried and both failed for the same underlying reason -- a downward
	# raycast needs a height to start from, the only hint available is the
	# nearest authored patch, and across a realm with ~1000 m of vertical range
	# that hint is wrong often enough that the ray misses the ground entirely.
	# A skirt around each patch left everything beyond its reach bare (33,527
	# turf cells); one grid over the union box found LESS turf, not more
	# (7,548), because the shared hint was wrong more often.
	#
	# So this walks the world's own turf SURFACES and scatters over their
	# triangles. A triangle is ground that exists, at a height that is known,
	# with an area that is exactly computable -- no hint, no miss, and coverage
	# proportional to area by construction. A surface counts as turf when its
	# material IS one of the world's turf materials (object identity against
	# `_materials`, not a name match), and a triangle is skipped only when it
	# is too steep to stand on.
	var surfaces := _collect_turf_triangles()
	_cover_fill_cells = surfaces.size()
	var min_normal_y := clampf(float(fill.get("min_normal_y", 0.55)), -1.0, 1.0)
	var buried_tolerance := maxf(0.02, float(fill.get("buried_tolerance_m", 0.25)))
	for raw: Variant in surfaces:
		var tri: Dictionary = raw
		var normal_y := float(tri["normal_y"])
		if normal_y < min_normal_y:
			continue
		var area := float(tri["area"])
		if area <= 0.01:
			continue
		cells.append(tri)
		desired += (density + far_density) * area
	probe_casts = cells.size()

	# PASS 2 -- plant. The budget is scaled ONCE across every triangle found
	# rather than spent first-come-first-served: stopping at a cap mid-sweep
	# would leave whatever surfaces came later with no grass at all, which is
	# the very thing this pass exists to make impossible.
	var scale_factor := 1.0 if desired <= 0.0 else minf(1.0, float(cap) / desired)
	var near_transforms: Array[Transform3D] = []
	var dry_transforms: Array[Transform3D] = []
	var far_transforms: Array[Transform3D] = []
	var far_dry_transforms: Array[Transform3D] = []
	for raw: Variant in cells:
		var tri: Dictionary = raw
		var a: Vector3 = tri["a"]
		var b: Vector3 = tri["b"]
		var c: Vector3 = tri["c"]
		var area := float(tri["area"])
		var dry_tri := bool(tri["dry"])
		var wanted := density * area * scale_factor
		var wanted_far := far_density * area * scale_factor
		var target := int(wanted) + (1 if rng.randf() < fmod(wanted, 1.0) else 0)
		var target_far := int(wanted_far) + (1 if rng.randf() < fmod(wanted_far, 1.0) else 0)
		for i in target + target_far:
			# Uniform over the triangle: the sqrt keeps the sample from
			# bunching at vertex `a`, which a plain (u, v) pair does.
			var u := rng.randf()
			var v := rng.randf()
			var su := sqrt(u)
			var point := a + (b - a) * (1.0 - su) + (c - a) * (v * su)
			var placed: Variant = _fill_tuft_at(point, extra_clear, rng, scale_min, scale_max,
				buried_tolerance)
			if placed == null:
				continue
			var xform: Transform3D = placed
			if i < target:
				if dry_tri:
					dry_transforms.append(xform)
				else:
					near_transforms.append(xform)
			else:
				if dry_tri:
					far_dry_transforms.append(xform)
				else:
					far_transforms.append(xform)

	_cover_fill_grid = {"turf_triangles": cells.size(), "surfaces": _cover_fill_surfaces,
		"turf_area_m2": int(_cover_fill_area), "density_scale": scale_factor}
	_cover_fill_count += _record_legacy(root, "CoverFillMain", near_transforms, tuft_mesh,
		main_material, near_visibility)
	_cover_fill_count += _record_legacy(root, "CoverFillDry", dry_transforms, tuft_mesh,
		main_material_dry, near_visibility)
	_cover_fill_count += _record_legacy(root, "CoverFillFar", far_transforms, tuft_mesh,
		far_material, far_visibility)
	_cover_fill_count += _record_legacy(root, "CoverFillFarDry", far_dry_transforms, tuft_mesh,
		far_material_dry, far_visibility)
	_cover_fill_msec = int((Time.get_ticks_usec() - started_usec) / 1000)
	_cover_fill_probes = probe_casts
