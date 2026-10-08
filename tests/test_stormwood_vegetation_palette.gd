extends "res://tests/test_case.gd"

const VEGETATION := preload("res://scripts/world/vegetation.gd")
const CONFIG_PATH := "res://data/config/stormwood_vegetation.json"


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
	# Preserve the explicit OFF control even on a flag-on candidate cut.
	vegetation._stormwood_leaf_profile_cache = {}
	var layer: Dictionary = cfg.layers.storm_bush
	var leaves := _material_after_policy(str(layer.models[0]), "Leaves_TwistedTree",
			layer, vegetation)
	assert_true(leaves != null, "Bush leaf material is outside the palette policy")
	assert_true(leaves.albedo_color.is_equal_approx(Color("#78906f")))
	assert_eq(leaves.albedo_texture.resource_path,
			"res://assets/environment/stylized_nature/derived/Leaves_NormalTree_C_desat55.png")
	# Exercise the same realm-local hook on the installed material/UV sheet.
	# No replacement atlas or recolored fixture can stand in for its alpha.
	vegetation._stormwood_leaf_profile_cache = null
	var actual_profile: Dictionary = vegetation._stormwood_leaf_profile()
	var finish: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_ground_finish.json"))
	assert_eq(bool(actual_profile.get("enabled", false)), bool(finish.get("leaf_original_alpha", {}).get("enabled", false)),
			"the own leaf flag is independent of the failed cover flag")
	# Keep all positive alpha/mip assertions when the shipping leaf flag is OFF.
	vegetation._stormwood_leaf_profile_cache = actual_profile if not actual_profile.is_empty() else {"enabled":true,"tint":"#8eaa91","brightness":1.35,"contrast":0.9}
	leaves = _material_after_policy(str(layer.models[0]),"Leaves_TwistedTree",layer,vegetation)
	assert_true(leaves.albedo_color.is_equal_approx(Color("#8eaa91")))
	var original: Image = (load("res://assets/environment/stylized_nature/Leaves_TwistedTree_C.png") as Texture2D).get_image()
	var changed: Image = leaves.albedo_texture.get_image()
	if original.is_compressed():
		assert_eq(original.decompress(),OK)
	if changed.is_compressed():
		assert_eq(changed.decompress(),OK)
	original.convert(Image.FORMAT_RGBA8)
	changed.convert(Image.FORMAT_RGBA8)
	assert_eq(changed.get_size(),original.get_size(),"same installed UV sheet dimensions")
	var before := original.get_data()
	var after := changed.get_data()
	var original_alpha := PackedByteArray()
	var changed_alpha := PackedByteArray()
	var coloured_pixels := 0
	var non_neutral_pixels := 0
	for index in range(0,original.get_width()*original.get_height()*4,4):
		original_alpha.append(before[index+3])
		changed_alpha.append(after[index+3])
		if after[index+3]>128:
			if absi(int(after[index])-int(after[index+1]))>1 or absi(int(after[index])-int(after[index+2]))>1:
				non_neutral_pixels += 1
			coloured_pixels += 1
	assert_eq(changed_alpha,original_alpha,"EVERY base-level alpha byte stays registered to original UVs")
	assert_true(coloured_pixels>0)
	assert_eq(non_neutral_pixels,0,"opaque installed RGB is neutralized before green tint")
	assert_true(changed.has_mipmaps())
	vegetation._realm_bake_name = "playground"
	var unchanged := _material_after_policy(str(layer.models[0]),"Leaves_TwistedTree",layer,vegetation)
	assert_eq(unchanged.albedo_texture.resource_path,"res://assets/environment/stylized_nature/derived/Leaves_NormalTree_C_desat55.png",
		"enabled Stormwood overlay cannot leak into another realm")
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
