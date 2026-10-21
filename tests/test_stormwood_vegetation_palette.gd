extends "res://tests/test_case.gd"

const VEGETATION := preload("res://scripts/world/vegetation.gd")
const CONFIG_PATH := "res://data/config/stormwood_vegetation.json"
const HARVESTS := preload("res://scripts/world/stormwood_harvest_runtime.gd")


func _mesh_in(node: Node) -> Mesh:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return (node as MeshInstance3D).mesh
	for child: Node in node.get_children():
		var found := _mesh_in(child)
		if found != null:
			return found
	return null


func _material_after_policy(model_path: String, material_name: String,
		layer: Dictionary, vegetation: Node) -> StandardMaterial3D:
	var root := (load(model_path) as PackedScene).instantiate()
	var source_mesh := _mesh_in(root)
	assert_true(source_mesh != null, "%s has no production mesh" % model_path)
	var tinted: Mesh = vegetation._retint(source_mesh, layer.get("retint", {}),
			layer.get("retexture", {}))
	for surface in source_mesh.get_surface_count():
		var source := source_mesh.surface_get_material(surface)
		if source != null and source.resource_name == material_name:
			var result := tinted.surface_get_material(surface) as StandardMaterial3D
			root.free()
			return result
	root.free()
	return null


func test_canopy_policy_retints_bark_without_replacing_its_texture() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var vegetation := VEGETATION.new()
	vegetation.configure_realm_scatter(cfg, null, "stormwood", -1)
	var layer: Dictionary = cfg.layers.storm_canopy
	var bark := _material_after_policy(str(layer.models[0]), "Bark_TwistedTree",
			layer, vegetation)
	assert_true(bark != null, "TwistedTree bark material is outside the palette policy")
	assert_true(bark.albedo_color.is_equal_approx(Color("#8f9580")))
	assert_true(bark.albedo_texture != null,
			"Bark retint must preserve the installed bark texture")
	vegetation.free()


func test_bush_policy_replaces_crimson_sheet_with_existing_green_family() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var vegetation := VEGETATION.new()
	vegetation.configure_realm_scatter(cfg, null, "stormwood", -1)
	var layer: Dictionary = cfg.layers.storm_bush
	var leaves := _material_after_policy(str(layer.models[0]), "Leaves_TwistedTree",
			layer, vegetation)
	assert_true(leaves != null, "Bush leaf material is outside the palette policy")
	assert_true(leaves.albedo_color.is_equal_approx(Color("#78906f")))
	assert_eq(leaves.albedo_texture.resource_path,
			"res://assets/environment/stylized_nature/derived/Leaves_NormalTree_C_desat55.png")
	vegetation.free()


func test_fern_joins_understory_palette_while_mushroom_remains_an_accent() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var vegetation := VEGETATION.new()
	vegetation.configure_realm_scatter(cfg, null, "stormwood", -1)
	var fern: Dictionary = cfg.layers.storm_fern
	var leaves := _material_after_policy(str(fern.models[0]), "Leaves", fern, vegetation)
	assert_true(leaves != null)
	assert_true(leaves.albedo_color.is_equal_approx(Color("#6f865f")))
	assert_false((cfg.layers.storm_mushroom as Dictionary).has("retint"),
			"Mushrooms remain the limited warm colour accent")
	vegetation.free()


func test_harvest_bush_node_wears_the_scatter_bush_policy_not_its_crimson_sheet() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var layer: Dictionary = cfg.layers.storm_bush
	var model := str(layer.models[0])
	var root := (load(model) as PackedScene).instantiate() as Node3D
	var changed := int(HARVESTS.apply_scatter_leaf_policy(root, model))
	assert_true(changed > 0, "harvest bush visual received no leaf policy")
	var found := false
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		for surface in instance.mesh.get_surface_count():
			var source := instance.mesh.surface_get_material(surface)
			if source == null or source.resource_name != "Leaves_TwistedTree":
				continue
			var worn := instance.get_surface_override_material(surface) as StandardMaterial3D
			assert_true(worn != null)
			assert_true(worn.albedo_color.is_equal_approx(Color(str(layer.retint.Leaves_TwistedTree))))
			assert_eq(worn.albedo_texture.resource_path, str(layer.retexture.Leaves_TwistedTree))
			found = true
	assert_true(found, "Bush_Common has no leaf surface")
	root.free()
