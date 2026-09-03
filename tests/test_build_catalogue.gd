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

# --- D34 menu categories -----------------------------------------------------

## build_menu.gd (D34/spec 12.2) only knows how to draw these four tabs, in
## this order -- an entry with any other value is invisible to the menu, the
## same silent-drop failure mode `test_the_table_exists_and_is_not_empty`
## already guards the whole catalogue against.
const MENU_CATEGORIES := ["survival", "crafting", "structures", "furniture"]

func test_every_category_is_a_menu_tab() -> void:
	for entry: Variant in _buildables():
		var piece: Dictionary = entry
		var id := str(piece.get("id", ""))
		var category := str(piece.get("category", ""))
		assert_true(MENU_CATEGORIES.has(category),
			"'%s' has category '%s', which build_menu.gd draws no tab for" % [id, category])


func test_every_entry_has_a_thumbnail() -> void:
	# build_menu.gd's grid cells show ONLY the thumbnail, no text (spec 12.3) --
	# an entry with no thumbnail (or one pointing nowhere) is a broken texture
	# in the middle of the grid rather than a missing label a player could at
	# least read past.
	for entry: Variant in _buildables():
		var piece: Dictionary = entry
		var id := str(piece.get("id", ""))
		var thumbnail := str(piece.get("thumbnail", ""))
		assert_ne(thumbnail, "", "'%s' has no 'thumbnail' field" % id)
		if thumbnail != "":
			assert_true(ResourceLoader.exists(thumbnail),
				"'%s' names thumbnail '%s', which does not exist" % [id, thumbnail])


const HAND_AUTHORED_IDS := ["tent", "campfire", "bedroll", "storage"]

func test_every_non_camp_entry_has_a_mesh_that_exists() -> void:
	# R2.6/R2.7. `tent`/`campfire`/`bedroll` (OWNER-0902-CAMP-SPLIT) and
	# `storage` place through their own hand-authored scripts
	# (camp_tent.gd/campfire.gd/player_bed.gd, storage_container.gd) and
	# carry no `mesh` field of their own; every other entry is generic
	# geometry placed by build_piece.gd from this path, so a missing one is a
	# piece that arms in the menu and puts nothing in the world when placed.
	for entry: Variant in _buildables():
		var piece: Dictionary = entry
		var id := str(piece.get("id", ""))
		if HAND_AUTHORED_IDS.has(id):
			continue
		var mesh_path := str(piece.get("mesh", ""))
		assert_ne(mesh_path, "", "'%s' has no 'mesh' field" % id)
		if mesh_path != "":
			assert_true(ResourceLoader.exists(mesh_path),
				"'%s' names mesh '%s', which does not exist" % [id, mesh_path])


# --- CAMP-SHELTER-0903: the tent is actually bigger than the trainer --------

const CAMP_TENT := preload("res://scripts/build/camp_tent.gd")

## data/config/art.json's trainer `height` entry -- read as a literal rather
## than parsed here since this test only needs the one number and camp_tent.gd
## itself does the same (its own header comment cites 1.80m directly).
const TRAINER_HEIGHT := 1.8
## Owner playtest 2026-09-03 item 7 asked for room to duck under the roof AND
## stand, not just clear the trainer's own height by a hair -- half a metre is
## enough to read as headroom rather than as a rounding margin.
const MIN_HEADROOM := 0.5

func test_tent_peak_clears_the_trainer_with_real_headroom() -> void:
	assert_true(CAMP_TENT.PEAK_HEIGHT > TRAINER_HEIGHT + MIN_HEADROOM,
		"tent peak %.3fm leaves less than %.1fm over the %.2fm trainer"
			% [CAMP_TENT.PEAK_HEIGHT, MIN_HEADROOM, TRAINER_HEIGHT])


func test_tent_floor_fits_the_bedroll_with_the_trainer_still_inside() -> void:
	# INTERIOR_HALF_X/_Z already have the bedroll's own footprint subtracted
	# (camp_tent.gd's own comment on them) -- a positive margin here is a
	# bedroll placed dead centre still keeping BOTH its own edges and a
	# 0.4m-radius trainer capsule under the roof, not just barely fitting the
	# bedroll alone.
	var trainer_radius := 0.4
	assert_true(CAMP_TENT.INTERIOR_HALF_X > trainer_radius,
		"tent interior X margin %.3fm does not clear a standing trainer beside the bedroll"
			% CAMP_TENT.INTERIOR_HALF_X)
	assert_true(CAMP_TENT.INTERIOR_HALF_Z > 0.0,
		"tent interior Z margin %.3fm leaves the bedroll's own ends outside the roof"
			% CAMP_TENT.INTERIOR_HALF_Z)


func test_tent_does_not_swallow_a_campfire_one_grid_cell_away() -> void:
	# Free-placed pieces of different ids never block each other
	# (`build_snap_contract.gd::occupied` only checks same-id overlap), so the
	# ordinary way a player ends up with a tent beside a campfire is one
	# `build_grid.gd::GRID_SIZE` (2m) grid cell apart. campfire.gd's own scaled
	# stone-ring footprint (measured raw 2.0w x 1.99907d, `STONE_RING_SCALE`
	# 0.8 -> 1.6w x 1.599d) gives it a 0.8m half-extent on both axes.
	const CAMPFIRE_HALF := 0.8
	const GRID_SIZE := 2.0
	assert_true(CAMP_TENT.HALF_X + CAMPFIRE_HALF <= GRID_SIZE,
		"tent X half-extent %.3fm + campfire half %.3fm clips at one grid cell (%.1fm) apart"
			% [CAMP_TENT.HALF_X, CAMPFIRE_HALF, GRID_SIZE])
	assert_true(CAMP_TENT.HALF_Z + CAMPFIRE_HALF <= GRID_SIZE,
		"tent Z half-extent %.3fm + campfire half %.3fm clips at one grid cell (%.1fm) apart"
			% [CAMP_TENT.HALF_Z, CAMPFIRE_HALF, GRID_SIZE])
