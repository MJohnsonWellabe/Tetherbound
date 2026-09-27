extends "res://tests/test_case.gd"

const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const MATERIALS := preload("res://scripts/world/imported_materials.gd")
const IDS := ["elixir_might", "elixir_guard", "elixir_vigour", "swift_tonic", "attack_tonic", "stoneguard_brew"]

func test_drinks_import_upright_at_ground_with_materials_kept_by_both_loaders() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/items.json"))
	var items: Dictionary = data.get("items", data)
	for id: String in IDS:
		var spec: Dictionary = items[id]
		var scene := load(str(spec.get("world_model", ""))) as PackedScene
		assert_true(scene != null, id + " needs an imported scene, not a fallback")
		if scene == null:
			continue
		var model := scene.instantiate() as Node3D
		var box := BOUNDS.measure(model)
		assert_true(absf(box.position.y) < 0.005, id + " must stand on the authored ground")
		assert_true(absf(box.size.y - 0.8) < 0.005, id + " must preserve authored bottle height")
		assert_true(box.size.x > 0.3 and box.size.z > 0.2, id + " must be volumetric")
		assert_true(box.size.y * float(spec.world_model_scale) < 0.75, id + " ordinary pickup stays below trainer waist")
		assert_eq(MATERIALS.make_dielectric(model), 0, id + " must retain its materials in both cache and harvest loaders")
		var triangles := 0
		for node: Node in model.find_children("*", "MeshInstance3D", true, false):
			var mesh := (node as MeshInstance3D).mesh
			if mesh != null:
				triangles += mesh.get_faces().size() / 3
		assert_true(triangles > 100 and triangles < 12000, id + " stays a bounded pickup mesh, got " + str(triangles))
		model.free()

func test_authored_meadows_tonic_overrides_use_the_same_world_model() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/items.json"))
	var items: Dictionary = data.get("items", data)
	var found := 0
	for band: String in ["band2_stone_and_root", "band3_the_river_lock", "band4_upper_meadows_ironwood"]:
		var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/bands/%s/harvest.json" % band))
		for spec: Dictionary in cfg.nodes:
			var id := str(spec.get("item", ""))
			if not IDS.has(id):
				continue
			found += 1
			assert_eq(str(spec.model), str(items[id].world_model), "explicit crate override must not hide the new bottle")
			assert_eq(float(spec.model_scale), float(items[id].world_model_scale), "same bottle size in both loaders")
	assert_eq(found, 3, "all three existing Meadows tonic finds are covered")
