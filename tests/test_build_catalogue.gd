extends "res://tests/test_case.gd"

## The build menu's catalogue, data/items/buildables.json.
##
## Failure modes here are silent the same way test_spawns_data.gd's are: a
## cost referencing a resource id that got renamed, a mesh path typo'd once
## and never caught until a player arms the piece and sees nothing placed, a
## duplicate id where the second entry silently shadows the first everywhere
## `ItemDB.buildable()` is called.

const BUILDABLES_PATH := "res://data/items/buildables.json"
const ITEMS_PATH := "res://data/items/items.json"


func _buildables_config() -> Dictionary:
	var file := FileAccess.open(BUILDABLES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _buildables() -> Array:
	return _buildables_config().get("buildables", []) as Array


func _item_ids() -> Array[String]:
	var file := FileAccess.open(ITEMS_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var items: Dictionary = (parsed as Dictionary).get("items", {}) as Dictionary
	var out: Array[String] = []
	for id: String in items.keys():
		out.append(id)
	return out


# --- the table is well-formed ------------------------------------------------

func test_the_table_exists_and_is_not_empty() -> void:
	assert_false(_buildables().is_empty(),
		"buildables.json has no catalogue; the build tab would be empty")


func test_every_entry_has_the_required_fields() -> void:
	for entry: Variant in _buildables():
		var piece: Dictionary = entry
		var id := str(piece.get("id", ""))
		for field in ["id", "name", "category", "blurb", "cost"]:
			assert_true(piece.has(field),
				"'%s' is missing its '%s' field" % [id, field])


func test_every_id_is_unique() -> void:
	var seen: Array[String] = []
	for entry: Variant in _buildables():
		var id := str((entry as Dictionary).get("id", ""))
		assert_false(seen.has(id), "'%s' appears more than once in buildables.json" % id)
		seen.append(id)


# --- costs resolve to real items ---------------------------------------------

func test_every_cost_references_a_real_item() -> void:
	var known := _item_ids()
	for entry: Variant in _buildables():
		var piece: Dictionary = entry
		var id := str(piece.get("id", ""))
		for requirement: Variant in (piece.get("cost", []) as Array):
			var need: Dictionary = requirement
			var need_id := str(need.get("id", ""))
			assert_true(known.has(need_id),
				"'%s' costs '%s', which is not in items.json" % [id, need_id])


func test_every_cost_amount_is_positive() -> void:
	for entry: Variant in _buildables():
		var piece: Dictionary = entry
		var id := str(piece.get("id", ""))
		for requirement: Variant in (piece.get("cost", []) as Array):
			var need: Dictionary = requirement
			assert_true(int(need.get("n", 0)) > 0,
				"'%s' has a cost entry with a non-positive amount" % id)


# --- geometry resolves --------------------------------------------------------

func test_every_non_camp_entry_has_a_mesh_that_exists() -> void:
	# R2.6/R2.7. `camp` and `storage` place through their own hand-authored
	# scripts (camp.gd, storage_container.gd) and carry no `mesh` field of
	# their own; every other entry is generic geometry placed by
	# build_piece.gd from this path, so a missing one is a piece that arms in
	# the menu and puts nothing in the world when placed.
	for entry: Variant in _buildables():
		var piece: Dictionary = entry
		var id := str(piece.get("id", ""))
		if id == "camp" or id == "storage":
			continue
		var mesh_path := str(piece.get("mesh", ""))
		assert_ne(mesh_path, "", "'%s' has no 'mesh' field" % id)
		if mesh_path != "":
			assert_true(ResourceLoader.exists(mesh_path),
				"'%s' names mesh '%s', which does not exist" % [id, mesh_path])
