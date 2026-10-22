extends "res://tests/test_case.gd"

## F38 P2-033 / P2-034 (22 Oct): Meadows pickups and harvest rewards show their
## own Meshy model. Each configured model must load and fit its declared size;
## any other realm keeps the generic visual.

const VISUALS := preload("res://scripts/world/meshy_item_visuals.gd")


func _visual_height(wrapper: Node3D) -> float:
	var box := AABB()
	var first := true
	for raw: Node in wrapper.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw as MeshInstance3D
		if mesh.name == "ContactShadow":
			continue
		var t := Transform3D()
		var walk: Node = mesh
		while walk != null and walk != wrapper:
			t = (walk as Node3D).transform * t
			walk = walk.get_parent()
		var b := t * mesh.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box.size.y


func test_every_configured_item_loads_and_fits_in_meadows() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VISUALS.CONFIG))
	var items: Dictionary = cfg.get("items", {})
	assert_true(items.size() > 0, "items are configured")
	for item_id: String in items:
		var spec: Dictionary = items[item_id]
		var wrapper := VISUALS.visual_for(item_id, "meadows")
		assert_true(wrapper != null, "%s builds a Meshy visual in Meadows" % item_id)
		if wrapper == null:
			continue
		if spec.has("height_m") and not spec.has("length_m"):
			assert_true(absf(_visual_height(wrapper) - float(spec.height_m)) < 0.02,
				"%s is fitted to its declared height" % item_id)
		wrapper.free()


func test_other_realms_and_unlisted_items_keep_the_generic_visual() -> void:
	assert_true(VISUALS.visual_for("rare_candy", "tidewake") == null, "another realm is unchanged")
	assert_true(VISUALS.visual_for("not_an_item", "meadows") == null, "an unlisted item is unchanged")
