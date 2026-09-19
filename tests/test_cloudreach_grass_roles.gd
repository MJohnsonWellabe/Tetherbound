extends "res://tests/test_case.gd"

const COVER := preload("res://scripts/world/cloudreach_ground_cover.gd")
const ROLES := preload("res://scripts/world/cloudreach_grass_roles.gd")
const CATALOGUE_PATH := "res://data/config/debug_teleport_spots.json"


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
		assert_true(scales.x / scales.y >= 2.5 and scales.x / scales.y <= 2.9,
			"width remains proportional to selected height")
	var tall_at: Vector3 = probes[ROLES.SPARSE_TALL]
	var demoted: Vector3 = ROLES.scales(tall_at, 0.5, 0.5, 1.0, cfg, false)
	assert_true(demoted.y >= 0.65 and demoted.y <= 0.85,
		"ineligible tall grass demotes to medium without removing the tuft")
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
			assert_true(width / height >= 2.5 and width / height <= 2.9,
				"generated grass width follows its chosen role height")
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
