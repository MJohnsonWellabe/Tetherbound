extends "res://tests/test_case.gd"

## GATEB-FLAGS (68-CHAPTER/17-RG18). Pure-logic coverage for
## scripts/build/home_progress.gd -- the "what counts as a home" rule the
## Gate B objective lane explicitly left for whoever owns building.
##
## Uses a small fixed `cfg` throughout rather than the shipped
## data/config/progression.json, the same seam progression.gd's own tests
## use -- these prove the ARITHMETIC, not today's tuned piece counts.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const HOME_PROGRESS := preload("res://scripts/build/home_progress.gd")

const CFG := {
	"home": {
		"required_pieces": {"camp": 1, "floor": 1, "wall": 2},
	},
}

var db: RefCounted = null
var bag: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	bag = INVENTORY.new(db)


func test_required_pieces_reads_the_given_config() -> void:
	assert_eq(HOME_PROGRESS.required_pieces(CFG), {"camp": 1, "floor": 1, "wall": 2})


func test_pieces_built_counts_by_id_ignoring_position() -> void:
	var placed := [
		{"id": "camp", "position": [0, 0, 0]},
		{"id": "wall", "position": [1, 0, 0]},
		{"id": "wall", "position": [2, 0, 0]},
		{"id": "fence", "position": [3, 0, 0]},
	]
	var counts := HOME_PROGRESS.pieces_built(placed)
	assert_eq(int(counts.get("camp", 0)), 1)
	assert_eq(int(counts.get("wall", 0)), 2)
	assert_eq(int(counts.get("fence", 0)), 1)


func test_home_built_is_false_short_of_any_single_requirement() -> void:
	var placed := [
		{"id": "camp", "position": [0, 0, 0]},
		{"id": "floor", "position": [1, 0, 0]},
		{"id": "wall", "position": [2, 0, 0]},
	]
	assert_false(HOME_PROGRESS.home_built(placed, CFG),
		"one wall short of the required two must not read as a finished home")


func test_home_built_is_true_once_every_requirement_is_met() -> void:
	var placed := [
		{"id": "camp", "position": [0, 0, 0]},
		{"id": "floor", "position": [1, 0, 0]},
		{"id": "wall", "position": [2, 0, 0]},
		{"id": "wall", "position": [3, 0, 0]},
	]
	assert_true(HOME_PROGRESS.home_built(placed, CFG))


func test_home_built_is_true_with_extra_pieces_beyond_the_minimum() -> void:
	var placed := [
		{"id": "camp", "position": [0, 0, 0]},
		{"id": "floor", "position": [1, 0, 0]},
		{"id": "floor", "position": [1, 0, 1]},
		{"id": "wall", "position": [2, 0, 0]},
		{"id": "wall", "position": [3, 0, 0]},
		{"id": "wall", "position": [4, 0, 0]},
	]
	assert_true(HOME_PROGRESS.home_built(placed, CFG))


func test_home_built_fails_closed_on_empty_config() -> void:
	assert_false(HOME_PROGRESS.home_built([{"id": "camp", "position": [0, 0, 0]}], {"home": {}}),
		"an empty/missing required_pieces config must never read as an instant home")


func test_materials_threshold_sums_real_buildable_costs() -> void:
	var camp_cost: Dictionary = db.buildable("camp")
	var floor_cost: Dictionary = db.buildable("floor")
	var wall_cost: Dictionary = db.buildable("wall")
	var expected := {}
	for requirement in camp_cost.get("cost", []):
		expected[str(requirement["id"])] = int(expected.get(str(requirement["id"]), 0)) + int(requirement["n"])
	for requirement in floor_cost.get("cost", []):
		expected[str(requirement["id"])] = int(expected.get(str(requirement["id"]), 0)) + int(requirement["n"])
	for requirement in wall_cost.get("cost", []):
		expected[str(requirement["id"])] = int(expected.get(str(requirement["id"]), 0)) + int(requirement["n"]) * 2

	var threshold := HOME_PROGRESS.materials_threshold(db, CFG)
	for item_id: String in expected.keys():
		assert_eq(int(threshold.get(item_id, -1)), int(expected[item_id]),
			"threshold for '%s' must equal the buildable costs summed, not a hand-typed number" % item_id)


func test_materials_gathered_is_false_until_every_required_item_is_held() -> void:
	var threshold := HOME_PROGRESS.materials_threshold(db, CFG)
	for item_id: String in threshold.keys():
		bag.add(item_id, int(threshold[item_id]) - 1)
	assert_false(HOME_PROGRESS.materials_gathered(bag, db, CFG),
		"one short on any single required item must not read as gathered")


func test_materials_gathered_is_true_once_the_threshold_is_met() -> void:
	var threshold := HOME_PROGRESS.materials_threshold(db, CFG)
	for item_id: String in threshold.keys():
		bag.add(item_id, int(threshold[item_id]))
	assert_true(HOME_PROGRESS.materials_gathered(bag, db, CFG))


func test_materials_gathered_ignores_free_build_and_still_requires_real_holdings() -> void:
	# home_progress.gd never reads GameState.free_build at all -- this test
	# exists so a future change that threads it through (making the
	## threshold collapse to zero under Free Build) gets caught immediately:
	# gathering must behave the same whether or not placing is free.
	var threshold := HOME_PROGRESS.materials_threshold(db, CFG)
	assert_false(threshold.is_empty(), "a real cost must still exist regardless of free_build")
	assert_false(HOME_PROGRESS.materials_gathered(bag, db, CFG),
		"an empty satchel must never read as gathered, free build or not")
