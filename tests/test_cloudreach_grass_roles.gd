extends "res://tests/test_case.gd"

const COVER := preload("res://scripts/world/cloudreach_ground_cover.gd")
const ROLES := preload("res://scripts/world/cloudreach_grass_roles.gd")
const CATALOGUE_PATH := "res://data/config/debug_teleport_spots.json"
const ROLE_WIDTH_RATIOS: Array[Vector2] = [Vector2(2.5, 2.9), Vector2(1.9, 2.3),
	Vector2(1.5, 1.9)]


class RecordingCover extends COVER:
	var recorded: Dictionary = {}

	func _emit_patch_tier(parent: Node3D, label: String, mesh: ArrayMesh,
			material: ShaderMaterial, transforms: Array[Transform3D], config: Dictionary,
			build_budget: RefCounted = null) -> int:
		var key: String = "%s/%s" % [parent.name, label]
		recorded[key] = transforms.duplicate()
		return await super._emit_patch_tier(parent, label, mesh, material, transforms, config,
			build_budget)


func _config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/cloudreach_visual.json"))
	assert_true(parsed is Dictionary, "Cloudreach visual config parses")
	return (parsed as Dictionary).get("ground_cover", {}) if parsed is Dictionary else {}


func test_settlement_yard_discards_roots_beyond_its_supporting_floor() -> void:
	var floor_centre := Vector3(-340, 830, 3970)
	var floor_bounds := Rect2(Vector2(-364, 3946), Vector2(48, 48))
	var clip := floor_bounds.grow(-0.2)
	var cfg := _config()
	var removed := 0
	var retained := 0
	# Exercise the real MultiMesh upload with both partially/fully unsupported
	# ellipses and a wholly supported patch. Compare complete transforms, not
	# just the new sampler's boundary predicate.
	for offset: Vector3 in [Vector3(20, 0.14, 4), Vector3(25, 0.14, 10),
			Vector3(30, 0.14, 16), Vector3(-9, 0.14, -26), Vector3(8, 0.14, 8)]:
		var patch := {"kind":"ellipse", "centre":floor_centre + offset,
			"half":Vector2(6.8, 9.0) if offset.z == -26 else Vector2(4.5, 5.0),
			"seed":842, "height_scale":0.68}
		var bounded := patch.duplicate()
		bounded["clip_rect"] = clip
		var original := RecordingCover.new()
		var candidate := RecordingCover.new()
		await original.build([patch], cfg, [])
		await candidate.build([bounded], cfg, [])
		for key: String in original.recorded:
			var expected: Array = []
			for transform: Transform3D in original.recorded[key]:
				var world_at: Vector3 = transform.origin + (patch.centre as Vector3)
				if clip.has_point(Vector2(world_at.x, world_at.z)):
					expected.append(transform)
					retained += 1
				else:
					removed += 1
			assert_eq(candidate.recorded.get(key, []), expected,
				"all supported transforms retained exactly; no replacement plants at the boundary")
		original.free()
		candidate.free()
	assert_true(removed > 0, "legacy placement reproduces unsupported roots")
	assert_true(retained > 0, "supported vegetation remains")


func test_ridge_height_follows_triangles_across_irregular_rotated_rows() -> void:
	# Uneven station spacing and saddle-shaped cells distinguish the actual
	# triangle split from centreline, bilinear and evenly-spaced-row guesses.
	for variant: int in 3:
		var rows := _ridge_test_rows(variant)
		for row_index: int in rows.size() - 1:
			for column: int in 6:
				var a: Vector3 = rows[row_index][column]
				var b: Vector3 = rows[row_index + 1][column]
				var c: Vector3 = rows[row_index][column + 1]
				var d: Vector3 = rows[row_index + 1][column + 1]
				# Construct points from known barycentric weights. Their expected
				# Y comes from construction, independently of the height solver.
				for expected: Vector3 in [a * 0.2 + b * 0.3 + c * 0.5,
						c * 0.2 + b * 0.3 + d * 0.5, b.lerp(c, 0.5), a]:
					var query := Vector3(expected.x, -500.0, expected.z)
					var actual: float = COVER._ridge_surface_height(rows, query)
					assert_true(is_finite(actual) and absf(actual - expected.y) < 0.002,
						"exact triangle height at interior, diagonal and row/column boundaries")
		var last_corner: Vector3 = rows[rows.size() - 1][6]
		assert_true(absf(COVER._ridge_surface_height(rows, last_corner) - last_corner.y) < 0.002,
			"last row and outside column boundary remain supported")
		for outside: Vector3 in [Vector3(-19, 0, 12), Vector3(19, 0, 12),
				Vector3(0, 0, -1), Vector3(0, 0, 54)]:
			assert_true(is_nan(COVER._ridge_surface_height(rows, _ridge_test_point(outside, variant))),
				"outside the generated footprint returns no support")
	assert_true(is_nan(COVER._ridge_surface_height([], Vector3.ZERO)), "empty surface has no support")
	assert_true(is_nan(COVER._ridge_surface_height([_ridge_test_rows(0)[0]], Vector3.ZERO)),
		"one cross-section has no surface area")


func test_route_cover_preserves_distribution_and_roots_every_tier_on_drawn_triangles() -> void:
	var cfg := _config()
	cfg["grass_density_per_m2"] = 1.0
	cfg["route_grass_patch_cap"] = 90
	cfg["flower_density_per_m2"] = 1.0
	cfg["route_flower_patch_cap"] = 20
	cfg["bush_density_per_m2"] = 1.0
	cfg["route_bush_patch_cap"] = 8
	cfg["cluster_threshold"] = -3.0
	var adjusted := 0
	for variant: int in 3:
		var rows := _ridge_test_rows(variant)
		var a: Vector3 = rows[0][3]
		var b: Vector3 = rows[rows.size() - 1][3]
		# Deliberately incorrect source centreline, reproducing the old source
		# of floating roots while keeping the same patch bounds and RNG stream.
		a.y = 175.0
		b.y = 190.0
		var patch := {"kind":"segment", "a":a, "b":b, "half_width":16.0,
			"path_half_width":2.0, "seed":193, "surface_offset_y":0.025}
		var grounded := patch.duplicate()
		grounded["surface_rows"] = rows
		var original := RecordingCover.new()
		var candidate := RecordingCover.new()
		await original.build([patch], cfg, [])
		await candidate.build([grounded], cfg, [])
		assert_eq(candidate.recorded.size(), 3, "grounded build uploads grass, flowers and bushes")
		var origin := a.lerp(b, 0.5)
		for key: String in original.recorded:
			var before: Array = original.recorded[key]
			var after: Array = candidate.recorded.get(key, [])
			assert_true(not before.is_empty(), "fixture creates each visible tier")
			assert_eq(after.size(), before.size(), "grounding preserves tier count without exclusions")
			for index: int in mini(before.size(), after.size()):
				var old_transform: Transform3D = before[index]
				var new_transform: Transform3D = after[index]
				assert_eq(Vector2(new_transform.origin.x, new_transform.origin.z),
					Vector2(old_transform.origin.x, old_transform.origin.z),
					"same random stream preserves every root XZ")
				assert_eq(new_transform.basis, old_transform.basis,
					"grounding preserves every tuft yaw, width and height")
				var world_at := new_transform.origin + origin
				# Independent engine ray/triangle intersection, not a second call
				# to the production sampler under test or its barycentric helper.
				var expected := _ridge_test_triangle_ray(rows, world_at)
				assert_true(is_finite(expected) and absf(world_at.y - expected - 0.025) < 0.002,
					"uploaded root rests on the exact drawn triangle plus its offset")
				if absf(new_transform.origin.y - old_transform.origin.y) > 1.0:
					adjusted += 1
		original.free()
		candidate.free()
	assert_true(adjusted > 0, "fixture catches the old floating-centreline placement")


func test_grounded_route_exclusions_use_corrected_height_without_crossing_strata() -> void:
	var rows := _ridge_test_rows(0)
	var a: Vector3 = rows[0][3]
	var b: Vector3 = rows[rows.size() - 1][3]
	# The source line is deliberately far above the drawn surface. A broad
	# phase using that stale height loses exclusions on the actual surface.
	a.y = 500.0
	b.y = 500.0
	var patch := {"kind":"segment", "a":a, "b":b, "half_width":16.0,
		"surface_rows":rows}
	var root_at: Vector3 = (rows[1][1] as Vector3) * 0.2 \
		+ (rows[2][1] as Vector3) * 0.3 + (rows[1][2] as Vector3) * 0.5
	root_at.y += 0.025
	var rectangle := {"kind":"rect", "centre":root_at,
		"half":Vector2(1.0, 1.0), "rotation":0.0}
	# This segment slopes sharply in Y. A 3D closest-point projection from
	# the stale source line also moves far away in X, so this exercises the
	# segment projection fix separately from the final distance metric.
	var segment := {"kind":"segment", "a":root_at - Vector3(100, 100, 0),
		"b":root_at + Vector3(100, 100, 0), "half_width":1.0}
	var cover := COVER.new()
	for exclusion: Dictionary in [rectangle, segment]:
		cover._exclusions = [exclusion]
		cover._active_exclusions = cover._nearby_exclusions(patch)
		assert_eq(cover._active_exclusions.size(), 1,
			"broad phase retains actual-surface exclusion despite stale source height")
		assert_true(cover._excluded(root_at, true),
			"correctly grounded root obeys rectangle and sloping-segment exclusions")
		assert_false(cover._excluded(root_at + Vector3.UP * 40.0, true),
			"another stratum sharing XZ is not excluded")
	var stacked := rectangle.duplicate()
	stacked["centre"] = root_at + Vector3.UP * 40.0
	cover._exclusions = [stacked]
	cover._active_exclusions = cover._nearby_exclusions(patch)
	assert_eq(cover._active_exclusions.size(), 1,
		"conservative XZ broad phase may retain an exclusion on another stratum")
	assert_false(cover._excluded(root_at, true),
		"narrow phase rejects the other-stratum exclusion at the grounded root")
	cover.free()


func _ridge_test_rows(variant: int) -> Array:
	var rows: Array = []
	var stations: Array[float] = [0.0, 5.0, 21.0, 53.0]
	for row_index: int in stations.size():
		var row: Array[Vector3] = []
		for column: int in 7:
			var height := 100.0 + row_index * 3.0 + column * 0.7
			height += 7.0 if (row_index + column) % 2 == 0 else -4.0
			row.append(_ridge_test_point(Vector3(-18.0 + column * 6.0, height,
				stations[row_index]), variant))
		rows.append(row)
	return rows


func _ridge_test_point(point: Vector3, variant: int) -> Vector3:
	if variant == 1:
		point = Vector3(point.z, point.y, point.x)
	elif variant == 2:
		point = Basis(Vector3.UP, 0.63) * point
	return point + Vector3(-310.0, 0.0, 3990.0)


func _ridge_test_triangle_ray(rows: Array, at: Vector3) -> float:
	for row_index: int in rows.size() - 1:
		for column: int in 6:
			var a: Vector3 = rows[row_index][column]
			var b: Vector3 = rows[row_index + 1][column]
			var c: Vector3 = rows[row_index][column + 1]
			var d: Vector3 = rows[row_index + 1][column + 1]
			for triangle: Array in [[a, b, c], [c, b, d]]:
				var hit: Variant = Geometry3D.ray_intersects_triangle(
					Vector3(at.x, 1000.0, at.z), Vector3.DOWN,
					triangle[0], triangle[1], triangle[2])
				if hit is Vector3:
					return (hit as Vector3).y
	return NAN


func test_world_field_has_low_led_hierarchy_and_one_metre_coherent_clumps() -> void:
	var cfg: Dictionary = _config()
	var counts: Array[int] = [0, 0, 0]
	var same_neighbors: int = 0
	var neighbor_pairs: int = 0
	for x: int in range(-600, 601, 5):
		for z: int in range(-600, 601, 5):
			var at: Vector3 = Vector3(float(x), 0.0, float(z))
			var role: int = ROLES.role_at(at, cfg)
			counts[role] += 1
			neighbor_pairs += 1
			if role == ROLES.role_at(at + Vector3.RIGHT, cfg):
				same_neighbors += 1
	var total: int = counts[0] + counts[1] + counts[2]
	assert_true(counts[ROLES.LOW] > counts[ROLES.MEDIUM], "low grass is the majority role")
	assert_true(counts[ROLES.MEDIUM] > counts[ROLES.SPARSE_TALL],
		"medium grass is more common than sparse tall grass")
	assert_true(counts[ROLES.SPARSE_TALL] > 0, "broad fixed grid contains sparse-tall grass")
	assert_true(float(counts[ROLES.SPARSE_TALL]) / float(total) <= 0.08,
		"tall grass stays at or below eight percent on a broad fixed grid")
	var observed_agreement: float = float(same_neighbors) / float(neighbor_pairs)
	var shuffled_agreement: float = 0.0
	for count: int in counts:
		var share: float = float(count) / float(total)
		shuffled_agreement += share * share
	assert_true(observed_agreement > shuffled_agreement + 0.12,
		"one-metre neighbor agreement is materially stronger than shuffled role choice")


func test_live_catalogue_neighborhoods_are_low_led_with_accents() -> void:
	var cfg: Dictionary = _config()
	var stands: Array[Vector2] = _cloudreach_catalogue_positions()
	assert_eq(stands.size(), 12, "test derives every live Cloudreach catalogue stand")
	var aggregate: Array[int] = [0, 0, 0]
	for centre: Vector2 in stands:
		var counts: Array[int] = [0, 0, 0]
		for dx: int in range(-15, 16):
			for dz: int in range(-15, 16):
				if dx * dx + dz * dz > 225:
					continue
				var role: int = ROLES.role_at(
					Vector3(centre.x + float(dx), 0.0, centre.y + float(dz)), cfg)
				counts[role] += 1
		for role: int in 3:
			aggregate[role] += counts[role]
		var total: int = counts[0] + counts[1] + counts[2]
		assert_true(float(counts[ROLES.LOW]) / float(total) > 0.50,
			"each live 15m neighborhood has a low-grass majority")
		assert_true(counts[ROLES.MEDIUM] > 0,
			"each live 15m neighborhood contains medium accents")
		assert_true(float(counts[ROLES.SPARSE_TALL]) / float(total) <= 0.10,
			"each live 15m neighborhood keeps sparse-tall at or below ten percent")
	assert_true(aggregate[ROLES.SPARSE_TALL] > 0,
		"the combined live catalogue neighborhoods contain sparse-tall accents")


func test_role_field_config_switches_and_switches_back_deterministically() -> void:
	var original: Dictionary = _config()
	var alternate: Dictionary = original.duplicate()
	alternate["grass_role_seed"] = int(original["grass_role_seed"]) + 17
	# R1 reads field scale; the staged R2 helper reads cellular frequency.
	# Setting both keeps this production test meaningful before and after promotion.
	alternate["grass_role_field_scale"] = 1.37
	alternate["grass_role_cell_frequency"] = 0.137
	var first: Array[int] = _role_fingerprint(original)
	var changed: Array[int] = _role_fingerprint(alternate)
	var restored: Array[int] = _role_fingerprint(original)
	assert_ne(changed, first, "seed/frequency switch changes the deterministic role field")
	assert_eq(restored, first, "switching config back reproduces the original role field")


func test_role_ranges_widths_and_tall_demotion() -> void:
	var cfg: Dictionary = _config()
	var probes: Dictionary = {}
	for x in range(-400, 401, 4):
		for z in range(-400, 401, 4):
			var at: Vector3 = Vector3(float(x), 0.0, float(z))
			var role: int = ROLES.role_at(at, cfg)
			if not probes.has(role):
				probes[role] = at
	assert_eq(probes.size(), 3, "fixed grid contains every grass role")
	var expected_ranges: Array[Vector2] = [Vector2(0.40, 0.60), Vector2(0.65, 0.85),
		Vector2(0.90, 1.10)]
	for role: int in 3:
		var scales: Vector3 = ROLES.scales(probes[role], 0.5, 0.5, 1.0, cfg)
		assert_true(scales.y >= expected_ranges[role].x and scales.y <= expected_ranges[role].y,
			"role height remains in its authored metre range")
		assert_true(scales.x / scales.y >= ROLE_WIDTH_RATIOS[role].x \
				and scales.x / scales.y <= ROLE_WIDTH_RATIOS[role].y,
			"each role uses its bounded proportional width range")
	var tall_at: Vector3 = probes[ROLES.SPARSE_TALL]
	var demoted: Vector3 = ROLES.scales(tall_at, 0.5, 0.5, 1.0, cfg, false)
	var direct_medium: Vector3 = ROLES.scales_for_role(ROLES.MEDIUM, 0.5, 0.5, 1.0, cfg)
	assert_true(demoted.y >= 0.65 and demoted.y <= 0.85,
		"ineligible tall grass demotes to medium without removing the tuft")
	assert_eq(demoted, direct_medium,
		"tall demotion is identical to medium in both height and width")
	var widest_tall: Vector3 = ROLES.scales_for_role(ROLES.SPARSE_TALL, 1.0, 1.0, 1.0, cfg)
	assert_true(widest_tall.x * 0.532 <= 1.12,
		"tall tuft authored span stays at or below 1.12m at nominal height multiplier")
	assert_eq(ROLES.unit_jitter(0.5, 0.5, 0.5), 0.5,
		"fixed legacy scale ranges produce finite centered jitter")


func test_real_ellipse_and_segment_keep_caps_and_emit_role_scaled_tufts() -> void:
	var cfg: Dictionary = _config()
	cfg["grass_density_per_m2"] = 1.0
	cfg["region_grass_patch_cap"] = 180
	cfg["route_grass_patch_cap"] = 120
	cfg["flower_density_per_m2"] = 0.0
	cfg["bush_density_per_m2"] = 0.0
	cfg["cluster_threshold"] = -1.0
	var patches: Array[Dictionary] = [
		{"kind": "ellipse", "centre": Vector3(-90.0, 0.0, 35.0),
			"half": Vector2(24.0, 18.0), "seed": 71, "height_scale": 1.0},
		{"kind": "segment", "a": Vector3(20.0, 0.0, -25.0),
			"b": Vector3(105.0, 0.0, 20.0), "half_width": 15.0,
			"path_half_width": 4.0, "seed": 93, "height_scale": 1.0}
	]
	var cover := RecordingCover.new()
	await cover.build(patches, cfg, [])
	assert_eq(cover.grass_instance_count(), 180 + int(120.0 * 0.64),
		"real ellipse and segment generation retain their existing capped counts")
	var roles_seen: Dictionary = {}
	for patch_index: int in patches.size():
		var key: String = "CoverPatch%03d/Grass" % patch_index
		var transforms: Array = cover.recorded.get(key, [])
		if transforms.is_empty():
			continue
		var patch: Dictionary = patches[patch_index]
		var origin: Vector3 = (patch["a"] as Vector3).lerp((patch["b"] as Vector3), 0.5) \
			if str(patch.get("kind", "ellipse")) == "segment" else patch["centre"]
		for raw_xform: Variant in transforms:
			var xform: Transform3D = raw_xform
			var world_at: Vector3 = origin + xform.origin
			var role: int = ROLES.role_at(world_at, cfg)
			var height: float = xform.basis.y.length()
			if role == ROLES.SPARSE_TALL and height < 0.90:
				role = ROLES.MEDIUM
			roles_seen[role] = true
			assert_true(height >= 0.40 and height <= 1.10,
				"generated grass uses visible hierarchy height ranges")
			var width: float = xform.basis.x.length()
			var expected_ratio: Vector2 = ROLE_WIDTH_RATIOS[role]
			assert_true(width / height >= expected_ratio.x and width / height <= expected_ratio.y,
				"generated grass width follows its chosen role bounds")
	assert_true(roles_seen.has(ROLES.LOW) and roles_seen.has(ROLES.MEDIUM),
		"real fixtures contain low and medium hierarchy roles")
	cover.free()


func _cloudreach_catalogue_positions() -> Array[Vector2]:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE_PATH))
	assert_true(parsed is Dictionary, "debug teleport catalogue parses")
	var positions: Array[Vector2] = []
	if not parsed is Dictionary:
		return positions
	for raw_biome: Variant in (parsed as Dictionary).get("biomes", []):
		if not raw_biome is Dictionary \
				or str((raw_biome as Dictionary).get("id", "")) != "cloudreach":
			continue
		for raw_band: Variant in (raw_biome as Dictionary).get("bands", []):
			if not raw_band is Dictionary:
				continue
			for raw_spot: Variant in (raw_band as Dictionary).get("spots", []):
				if not raw_spot is Dictionary:
					continue
				var value: Variant = (raw_spot as Dictionary).get("position", [])
				if value is Array and (value as Array).size() == 2:
					positions.append(Vector2(float(value[0]), float(value[1])))
	return positions


func _role_fingerprint(cfg: Dictionary) -> Array[int]:
	var result: Array[int] = []
	for x: int in range(-250, 251, 25):
		for z: int in range(-250, 251, 25):
			result.append(ROLES.role_at(Vector3(float(x), 0.0, float(z)), cfg))
	return result
