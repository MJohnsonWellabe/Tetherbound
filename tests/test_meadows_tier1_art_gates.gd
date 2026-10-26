extends "res://tests/test_case.gd"

## F38 tier-1 new art (close-1024): the Hall arch facades ship ON (GPU +0.79
## Medium, +1.11 High); the stronghold hero gatehouse and the Meadows hero
## pieces stay OFF until a GPU pass judges them, and build nothing while off;
## on, a facade is fitted inside its arch slot.

const ARCH_FACADES := preload("res://scripts/world/crossing_hall_arch_facades.gd")
const GATEHOUSE := preload("res://scripts/world/stronghold_hero_gatehouse.gd")
const HERO_PIECES := preload("res://scripts/world/meadows_hero_pieces.gd")


func _block(path: String, key: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (parsed as Dictionary).get(key, {}) if parsed is Dictionary else {}


func test_shipping_configs_gate_the_new_art() -> void:
	assert_true(bool(_block("res://data/config/crossing_hall.json", "arch_facades").get("enabled", false)), "facades ON after the GPU pass")
	assert_false(bool(_block("res://data/config/stronghold.json", "hero_gatehouse").get("enabled", true)))
	assert_false(bool(_block("res://data/config/stronghold.json", "courtyard_daylight_candidate").get("enabled", true)), "courtyard daylight OFF until judged")
	var pieces := HERO_PIECES.settings()
	var clearings: Dictionary = pieces.get("clearings", {})
	assert_true(bool(clearings.get("enabled", false)), "clearings ON after GPU MH7")
	assert_true(str(clearings.get("_why_on", "")).contains("GPU MH7"), "ON carries its GPU verdict")
	for group: String in pieces.keys():
		if pieces[group] is Dictionary and (pieces[group] as Dictionary).has("pieces"):
			assert_false(bool((pieces[group] as Dictionary).get("enabled", true)), group + " stays OFF")


func test_off_builders_add_nothing() -> void:
	var root := Node3D.new()
	var arch := Node3D.new()
	root.add_child(arch)
	var cfg := _block("res://data/config/crossing_hall.json", "arch_facades").duplicate(true)
	cfg["enabled"] = false
	assert_eq(ARCH_FACADES.build(root, cfg, {"tidewake": arch}), 0)
	assert_eq(arch.get_child_count(), 0)
	assert_eq(GATEHOUSE.build(root, _block("res://data/config/stronghold.json", "hero_gatehouse"), 0.0, 0.0), null)
	assert_eq(HERO_PIECES.build(root), 0)
	assert_eq(HERO_PIECES.clear(root), 0, "no Vegetation node: clearings cut nothing")
	assert_eq(root.get_child_count(), 1)
	root.free()


func test_enabled_facade_fits_its_arch() -> void:
	var root := Node3D.new()
	var arch := Node3D.new()
	root.add_child(arch)
	var cfg := _block("res://data/config/crossing_hall.json", "arch_facades").duplicate(true)
	cfg["enabled"] = true
	assert_eq(ARCH_FACADES.build(root, cfg, {"tidewake": arch}), 1)
	var holder := arch.get_node_or_null(^"ArchFacade_tidewake") as Node3D
	assert_true(holder != null, "facade holder parented to its arch slot")
	var model := holder.get_child(0) as Node3D
	var size: Array = (cfg["pieces"]["tidewake"] as Dictionary)["size_m"]
	var fresh := (load(str(cfg["pieces"]["tidewake"]["path"])) as PackedScene).instantiate() as Node3D
	var bounds := preload("res://scripts/characters/render_bounds.gd").measure(fresh)
	assert_almost_eq(bounds.size.y * model.scale.y, float(size[1]), 0.05, "fitted to the configured height")
	fresh.free()
	root.free()
