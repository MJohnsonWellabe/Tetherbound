extends "res://tests/test_case.gd"

const ORDER := preload("res://scripts/data/biome_order.gd")
const HEARTS := preload("res://autoload/realm_heart_state.gd")
const SHRINE := preload("res://scripts/world/realm_heart_shrine.gd")


func test_relic_slots_place_tidewake_before_cloudreach_and_stormwood() -> void:
	# Exercise the production placement loop, rather than only restating config.
	# Off-tree construction avoids rendering; the actual child order/positions
	# remain observable and the fixture owns every node it creates.
	var shrine := SHRINE.new()
	shrine.heart_id = "meadows"
	shrine._build_relic_slots()
	assert_eq(shrine.get_child_count(), 3)
	var expected_ids := ["water", "cloudreach", "stormwood"]
	var expected_positions := [Vector3(-3, 0, 0), Vector3(3, 0, 0), Vector3(0, 0, -3)]
	for i: int in mini(3, shrine.get_child_count()):
		var slot := shrine.get_child(i) as Node3D
		assert_eq(str(slot.get("heart_id")), expected_ids[i], "actual shrine socket order")
		assert_eq(slot.position, expected_positions[i], "actual socket position for " + expected_ids[i])
	shrine.free()


func test_realm_heart_order_ignores_authored_dictionary_insertion_order() -> void:
	var state := HEARTS.new()
	assert_eq(state.ordered_realm_ids(), ["meadows", "water", "cloudreach", "stormwood"])
	assert_eq(ORDER.ordered_runtime_ids(["stormwood", "water", "meadows", "cloudreach"]),
		["meadows", "water", "cloudreach", "stormwood"])
	assert_eq(ORDER.ordered_runtime_ids(["cloudreach", "meadows"]), ["meadows", "cloudreach"])


func test_gameplay_has_no_literal_old_chapter_order_array() -> void:
	# Gameplay dictionaries may define names in any insertion order. Ordered
	# arrays must not preserve the retired chapter sequence. This complements
	# the live shrine consumer regression above; it scans shipping code only.
	var old_order := RegEx.new()
	assert_eq(old_order.compile("\\[\\s*[\"']meadows[\"']\\s*,\\s*[\"']cloudreach[\"']\\s*,\\s*[\"']stormwood[\"']\\s*,\\s*[\"'](?:water|tidewake)[\"']\\s*\\]"), OK)
	var files: Array[String] = []
	_collect_scripts("res://autoload", files)
	_collect_scripts("res://scripts", files)
	assert_true(files.size() > 100, "the scan must inspect the production script tree")
	for path: String in files:
		var source := FileAccess.get_file_as_string(path)
		var code_lines: PackedStringArray = []
		for line: String in source.split("\n"):
			code_lines.append(line.split("#", true, 1)[0])
		assert_true(old_order.search("\n".join(code_lines)) == null,
			"retired gameplay chapter array in " + path)


func _collect_scripts(path: String, out: Array[String]) -> void:
	var directory := DirAccess.open(path)
	assert_true(directory != null, "gameplay directory is readable: " + path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if directory.current_is_dir():
			if not entry.begins_with("."):
				_collect_scripts(path.path_join(entry), out)
		elif entry.ends_with(".gd"):
			out.append(path.path_join(entry))
		entry = directory.get_next()
	directory.list_dir_end()
