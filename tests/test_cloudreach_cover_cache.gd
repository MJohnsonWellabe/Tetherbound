extends "res://tests/test_case.gd"

## Capture-speed lane: the optional Cloudreach ground-cover instance cache
## (`--ground-cover-cache`) is content-addressed and stores exact float32
## transforms. A hit must only ever come from identical inputs.

const COVER := preload("res://scripts/world/cloudreach_ground_cover.gd")
const SAMPLER := preload("res://scripts/world/cloudreach_crown_surface.gd")


func _sampler(height: float) -> RefCounted:
	var sampler := SAMPLER.new()
	sampler.build(PackedVector3Array([Vector3(0, height, 0), Vector3(10, height, 0), Vector3(0, height, 10)]),
		Transform3D.IDENTITY)
	return sampler


func _inputs(height: float = 1.0) -> Array:
	var patches: Array[Dictionary] = [
		{"kind": "ellipse", "centre": Vector3(1, 2, 3), "half": Vector2(20, 12), "seed": 4,
			"crown_surface": _sampler(height)},
		{"kind": "segment", "a": Vector3.ZERO, "b": Vector3(40, 0, 0), "half_width": 9.0}]
	var exclusions: Array[Dictionary] = [{"centre": Vector3(5, 0, 5), "half": Vector2.ONE, "rotation": 0.0}]
	return [patches, {"grass_density_per_m2": 4.8, "cluster_threshold": -0.22}, exclusions]


func _key(inputs: Array) -> String:
	return COVER.cache_key(inputs[0], inputs[1], inputs[2])


func test_key_is_stable_for_identical_inputs() -> void:
	var first := _key(_inputs())
	assert_eq(first.length(), 64, "sha256 hex key")
	assert_eq(_key(_inputs()), first, "fresh but identical inputs (new sampler objects) share the key")


func test_any_input_change_changes_the_key() -> void:
	var base := _key(_inputs())
	var changed := _inputs()
	(changed[1] as Dictionary)["grass_density_per_m2"] = 4.81
	assert_ne(_key(changed), base, "config value")
	changed = _inputs()
	((changed[0] as Array)[1] as Dictionary)["half_width"] = 9.0001
	assert_ne(_key(changed), base, "patch geometry")
	changed = _inputs()
	(changed[2] as Array).append({"centre": Vector3.ZERO, "half": Vector2.ONE, "rotation": 0.0})
	assert_ne(_key(changed), base, "exclusions")
	assert_ne(_key(_inputs(1.5)), base, "crown-surface triangles")


func test_unfingerprinted_object_disables_the_cache() -> void:
	var inputs := _inputs()
	((inputs[0] as Array)[0] as Dictionary)["node"] = Node.new()
	assert_eq(_key(inputs), "", "an object without triangle data never keys a cache")
	(((inputs[0] as Array)[0] as Dictionary)["node"] as Node).free()


func test_round_trip_is_bit_exact() -> void:
	var path := "user://cover-cache-test-%s/cover.bin" % Crypto.new().generate_random_bytes(8).hex_encode()
	var transforms := PackedFloat32Array([0.1, 1.0 / 3.0, -2.5e-7, 123456.789, NAN, 0.0, -0.0, 1e30])
	var tiers := {"CoverPatch000:0": transforms, "CoverPatch001:2": PackedFloat32Array()}
	assert_eq(COVER.save_cache(path, tiers), OK, "cache writes")
	assert_false(FileAccess.file_exists(path + ".partial"), "temporary file renamed")
	var loaded := COVER.load_cache(path)
	assert_eq(loaded.keys(), tiers.keys(), "every slot returns")
	assert_eq((loaded["CoverPatch000:0"] as PackedFloat32Array).to_byte_array(), transforms.to_byte_array(),
		"transforms are byte-identical")
	assert_eq(COVER.load_cache(path + ".missing"), {}, "absent cache is a miss")
