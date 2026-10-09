extends "res://tests/test_case.gd"

## Oxblood/red is reserved for Team Tether (hard rule). The frame-matrix blind
## verdict (WO-M M2, frame 24) found crimson shrubs beside the friendly Old
## Wind Observatory: its edge TwistedTrees kept the installed crimson
## `Leaves_TwistedTree_C` sheet because they bypassed the region's foliage
## palette. These tests hold the palette at the three places it can leak.

const OBSERVATORY := preload("res://scripts/world/cloudreach_old_wind_observatory_presentation.gd")
const WORLD := preload("res://scripts/world/cloudreach_world.gd")
const CRIMSON_LEAF_SHEET := "Leaves_TwistedTree_C.png"
## Installed models whose shipped leaf material is the crimson sheet.
const CRIMSON_LEAF_MODELS := ["TwistedTree_", "Bush_Common"]
## Presentation config keys allowed to carry a red: Team Tether's own dressing.
const TETHER_KEY_MARKERS := ["tether", "oxblood", "enemy", "hostile", "drone", "relay"]


func test_observatory_edge_trees_wear_the_green_region_leaf() -> void:
	var world := WORLD.new()
	var visual := OBSERVATORY.new() as Node3D
	visual.build(_materials(), false, world)
	var trees := visual.find_children("ObservatoryWindTree*", "Node3D", true, false)
	assert_eq(trees.size(), 4)
	var leaf_surfaces := 0
	for tree: Node in trees:
		for node: Node in tree.find_children("*", "MeshInstance3D", true, false):
			var instance := node as MeshInstance3D
			if instance.mesh == null:
				continue
			for surface in instance.mesh.get_surface_count():
				var source := instance.mesh.surface_get_material(surface)
				if source == null or not source.resource_name.to_lower().contains("leaves"):
					continue
				leaf_surfaces += 1
				var active := instance.get_active_material(surface) as StandardMaterial3D
				assert_true(active != null, "%s leaf surface has no material" % tree.name)
				if active == null:
					continue
				var texture_path := active.albedo_texture.resource_path \
					if active.albedo_texture != null else ""
				assert_false(texture_path.ends_with(CRIMSON_LEAF_SHEET),
					"%s still wears the crimson TwistedTree leaf sheet" % tree.name)
				assert_false(_is_red(active.albedo_color),
					"%s leaf tint %s is red" % [tree.name, active.albedo_color.to_html(false)])
	assert_true(leaf_surfaces > 0, "observatory edge trees expose leaf surfaces to check")
	visual.free()
	world.free()


func test_cloudreach_scripts_placing_crimson_leaf_models_route_them_through_the_palette() -> void:
	var dir := DirAccess.open("res://scripts/world")
	assert_true(dir != null)
	if dir == null:
		return
	var checked := 0
	for file_name: String in dir.get_files():
		if not file_name.begins_with("cloudreach_") or not file_name.ends_with(".gd"):
			continue
		var source := FileAccess.get_file_as_string("res://scripts/world/" + file_name)
		var places_crimson := false
		for marker: String in CRIMSON_LEAF_MODELS:
			if source.contains(marker):
				places_crimson = true
		if not places_crimson:
			continue
		checked += 1
		assert_true(source.contains("_apply_tree_palette"),
			"%s places a crimson-leaf model without the Cloudreach tree palette" % file_name)
	assert_true(checked >= 3, "the scan found the Cloudreach scripts that place trees/bushes")


func test_friendly_cloudreach_presentation_configs_carry_no_red() -> void:
	var dir := DirAccess.open("res://data/config")
	assert_true(dir != null)
	if dir == null:
		return
	var scanned := 0
	for file_name: String in dir.get_files():
		if not file_name.begins_with("cloudreach_") or not file_name.ends_with(".json"):
			continue
		var parsed: Variant = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/" + file_name))
		assert_true(parsed != null, "%s parses" % file_name)
		scanned += 1
		_scan_for_red(parsed, file_name)
	assert_true(scanned >= 10, "the scan found the Cloudreach presentation configs")


func _scan_for_red(value: Variant, path: String) -> void:
	if value is Dictionary:
		for key: Variant in (value as Dictionary).keys():
			var child_path := "%s.%s" % [path, str(key)]
			if _is_tether_path(child_path):
				continue
			_scan_for_red((value as Dictionary)[key], child_path)
	elif value is Array:
		for index in (value as Array).size():
			_scan_for_red((value as Array)[index], "%s[%d]" % [path, index])
	elif value is String:
		var text := value as String
		if text.length() in [7, 9] and text.begins_with("#") and Color.html_is_valid(text):
			assert_false(_is_red(Color(text)),
				"%s = %s is a red outside Team Tether's dressing" % [path, text])


func _is_tether_path(path: String) -> bool:
	var lower := path.to_lower()
	for marker: String in TETHER_KEY_MARKERS:
		if lower.contains(marker):
			return true
	return false


## Red/oxblood family: hue within 18 degrees of pure red, clearly saturated and
## not near-black. Terracotta and warm timber (hue >= 20 deg) stay allowed.
static func _is_red(colour: Color) -> bool:
	var hue_deg := colour.h * 360.0
	var red_hue := hue_deg <= 18.0 or hue_deg >= 340.0
	return red_hue and colour.s >= 0.45 and colour.v >= 0.18


func _materials() -> Dictionary:
	var result := {}
	for key: String in ["masonry", "masonry_trim", "weathered_timber"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#817661")
		result[key] = material
	return result
