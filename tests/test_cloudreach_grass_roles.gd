extends "res://tests/test_case.gd"

const COVER := preload("res://scripts/world/cloudreach_ground_cover.gd")
const ROLES := preload("res://scripts/world/cloudreach_grass_roles.gd")


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


func test_world_field_has_low_led_hierarchy_and_coherent_clumps() -> void:
	var cfg: Dictionary = _config()
	var counts: Array[int] = [0, 0, 0]
	var same_neighbors: int = 0
	var neighbor_pairs: int = 0
	for x in range(-500, 501, 10):
		for z in range(-500, 501, 10):
			var role: int = ROLES.role_at(Vector3(float(x), 0.0, float(z)), cfg)
			counts[role] += 1
			if x < 500:
				neighbor_pairs += 1
				if role == ROLES.role_at(Vector3(float(x + 10), 0.0, float(z)), cfg):
					same_neighbors += 1
	var total: int = counts[0] + counts[1] + counts[2]
	assert_true(counts[ROLES.LOW] > counts[ROLES.MEDIUM], "low grass is the majority role")
	assert_true(counts[ROLES.MEDIUM] > counts[ROLES.SPARSE_TALL],
		"medium grass is more common than sparse tall grass")
	assert_true(float(counts[ROLES.SPARSE_TALL]) / float(total) <= 0.08,
		"tall grass stays at or below eight percent on a broad fixed grid")
	var observed_agreement: float = float(same_neighbors) / float(neighbor_pairs)
	var shuffled_agreement: float = 0.0
	for count: int in counts:
		var share: float = float(count) / float(total)
		shuffled_agreement += share * share
	assert_true(observed_agreement > shuffled_agreement + 0.12,
		"neighbor agreement is materially stronger than shuffled role choice")


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
