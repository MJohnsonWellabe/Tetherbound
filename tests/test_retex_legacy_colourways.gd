extends "res://tests/test_case.gd"

## Close-1020: an installed retexture changes a species' ordinary look only.
## Its shiny, alpha and aspect-variant repaints were painted on the earlier
## texture set and must still resolve, with that set's normal and
## metal/roughness maps, instead of silently rendering as the plain retex.

const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const MODELS := "res://assets/creatures/tetherbound/burrowback/models/"
const RETEX := MODELS + "creature_burrowback_installed_retex_v2_lod0.glb"
const RIPPLET_MODELS := "res://assets/creatures/tetherbound/ripplet/models/"
const RIPPLET_RETEX := "res://assets/creatures/tetherbound/ripplet/candidate_installed_retex/models/creature_ripplet_installed_retex_r6_lod0.glb"
const TUSKROOT_RETEX := "res://assets/creatures/tetherbound/tuskroot/candidate/models/creature_tuskroot_native_retex.glb"


func _material(path: String) -> BaseMaterial3D:
	var root: Node = (load(path) as PackedScene).instantiate()
	var found: BaseMaterial3D = null
	var stack: Array[Node] = [root]
	while not stack.is_empty() and found == null:
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			found = (node as MeshInstance3D).mesh.surface_get_material(0) as BaseMaterial3D
		stack.append_array(node.get_children())
	root.free()
	return found


func test_burrowback_retex_keeps_its_variant_repaints() -> void:
	var source := _material(RETEX)
	assert_true(source != null, "retex material")
	assert_true(CREATURE_BODY._swapped_material(source, "burrowback", "vivid") == null,
		"the retex is the ordinary look; the old vivid repaint must not cover it")
	for suffix: String in ["shiny", "alpha", "nightburrow"]:
		var copy := CREATURE_BODY._swapped_material(source, "burrowback", suffix)
		assert_true(copy != null, "%s lost its repaint on the retex" % suffix)
		if copy == null:
			continue
		assert_eq(copy.albedo_texture.resource_path,
			MODELS + "creature_burrowback_lod0_base_color_%s.png" % suffix, suffix)
		assert_eq(copy.normal_texture.resource_path, MODELS + "creature_burrowback_lod0_normal.jpg", suffix)
		assert_eq(copy.roughness_texture.resource_path,
			MODELS + "creature_burrowback_lod0_metallic_roughness.png", suffix)
		assert_eq(copy.emission_texture.resource_path,
			MODELS + "creature_burrowback_lod0_emissive_%s.png" % suffix, suffix)


func test_ripplet_retex_keeps_its_shiny_repaint() -> void:
	var source := _material(RIPPLET_RETEX)
	assert_true(CREATURE_BODY._swapped_material(source, "ripplet", "vivid") == null,
		"the retex is the ordinary look; the old vivid repaint must not cover it")
	var copy := CREATURE_BODY._swapped_material(source, "ripplet", "shiny")
	assert_true(copy != null, "shiny lost its repaint on the retex")
	if copy == null:
		return
	assert_eq(copy.albedo_texture.resource_path, RIPPLET_MODELS + "creature_ripplet_lod0_base_color_shiny.png")
	assert_eq(copy.normal_texture.resource_path, RIPPLET_MODELS + "creature_ripplet_lod0_normal.jpg")
	assert_eq(copy.emission_texture.resource_path, RIPPLET_MODELS + "creature_ripplet_lod0_emissive_shiny.png")


func test_ashtusk_keeps_native_maps_on_the_tuskroot_retex() -> void:
	var copy := CREATURE_BODY._swapped_material(_material(TUSKROOT_RETEX), "ashtusk_native", "ashtusk")
	assert_true(copy != null, "ashtusk lost its colourway on the retex mesh")
	if copy == null:
		return
	assert_eq(copy.albedo_texture.resource_path, CREATURE_BODY.ASHTUSK_NATIVE_MAPS.albedo)
	assert_eq(copy.normal_texture.resource_path, CREATURE_BODY.ASHTUSK_NATIVE_MAPS.normal)
	assert_eq(copy.metallic, 0.0)
