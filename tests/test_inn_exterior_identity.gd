extends "res://tests/test_case.gd"

const IDENTITY := preload("res://scripts/world/inn_exterior_identity.gd")
const VILLAGE := preload("res://scripts/world/village.gd")
const PREFABS_PATH := "res://data/config/building_prefabs.json"


func _built() -> Node3D:
	var identity: Node3D = IDENTITY.new()
	identity.call("build")
	return identity


func test_inn_has_a_public_silhouette_and_two_readable_faces() -> void:
	var identity := _built()
	var stats: Dictionary = identity.call("stats")
	assert_true(float(stats.porch_width_m) >= 5.0,
		"the inn porch is too narrow to change the farmhouse silhouette")
	assert_eq(int(stats.sign_count), 2,
		"square and twins viewpoints each need a readable inn sign")
	var front := identity.get_node_or_null(^"InnSigns/FrontInnSign/Label") as Label3D
	var side := identity.get_node_or_null(^"InnSigns/SideInnSign/Label") as Label3D
	assert_true(front != null and front.text.contains("INN"), "frontage does not name the inn")
	assert_true(side != null and side.text.contains("ROOMS"), "side elevation does not advertise lodging")
	identity.free()


func test_hospitality_dressing_keeps_the_door_lane_open() -> void:
	var identity := _built()
	var stats: Dictionary = identity.call("stats")
	assert_eq(int(stats.lantern_count), 2, "the public threshold needs paired night lights")
	assert_true(int(stats.guest_prop_count) >= 4, "the inn yard does not read occupied")
	for child: Node in identity.get_node(^"GuestYard").get_children():
		if not child is Node3D:
			continue
		var at := (child as Node3D).position
		assert_true(absf(at.x) > float(stats.door_half_width_m),
			"%s blocks the authored 1.6m doorway lane" % child.name)
	identity.free()


func test_inn_material_masses_differ_from_the_private_farmhouse() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PREFABS_PATH))
	assert_true(parsed is Dictionary, "building prefab config parses")
	var prefabs := (parsed as Dictionary).get("prefabs", {}) as Dictionary
	var inn_retint := (prefabs.get("inn", {}) as Dictionary).get("retint", {}) as Dictionary
	var home_retint := (prefabs.get("farmhouse_shell", {}) as Dictionary).get("retint", {}) as Dictionary
	assert_ne(str((inn_retint.get("MI_WoodTrim", {}) as Dictionary).get("color", "")),
		str((home_retint.get("MI_WoodTrim", {}) as Dictionary).get("color", "")),
		"inn timber still matches Grandpa's House")
	assert_ne(str((inn_retint.get("MI_Plaster", {}) as Dictionary).get("color", "")),
		str((home_retint.get("MI_Plaster", {}) as Dictionary).get("color", "")),
		"inn plaster still matches Grandpa's House")


func test_production_village_attaches_identity_only_to_the_inn() -> void:
	var village: Node3D = VILLAGE.new()
	assert_true(village != null, "production village script no longer instantiates")
	village.free()
	var source := FileAccess.get_file_as_string("res://scripts/world/village.gd")
	assert_true(source.contains('if prefab_name != "inn"'),
		"inn identity is no longer scoped to the inn prefab")
	assert_true(source.contains('identity.call("build")'),
		"production village no longer builds the inn frontage")
