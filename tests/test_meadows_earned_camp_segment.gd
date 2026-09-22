extends "res://tests/test_case.gd"

const CAMP := preload("res://tests/helpers/meadows_earned_camp_segment.gd")
const BUILDABLES_PATH := "res://data/items/buildables.json"


class CatalogueGame extends Node:
	var by_id := {}

	func _init() -> void:
		var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BUILDABLES_PATH))
		for raw: Variant in parsed.get("buildables", []):
			if raw is Dictionary:
				by_id[str((raw as Dictionary).get("id", ""))] = raw

	func build_cost_for(id: String) -> Array:
		return ((by_id.get(id, {}) as Dictionary).get("cost", []) as Array).duplicate(true)


func test_full_camp_plan_reads_three_beds_from_the_live_catalogue() -> void:
	assert_eq(CAMP.piece_plan(false),
		["tent", "campfire", "bedroll", "creature_bed", "creature_bed", "creature_bed"])
	var game := CatalogueGame.new()
	assert_eq(CAMP.required_stock(game, false), {"wood": 30, "fiber": 34, "stone": 8})
	game.free()


func test_one_bed_lesson_remains_a_primitive_without_claiming_three_bed_readiness() -> void:
	assert_eq(CAMP.piece_plan(true), ["tent", "campfire", "bedroll", "creature_bed"])
	var game := CatalogueGame.new()
	assert_eq(CAMP.required_stock(game, true), {"wood": 18, "fiber": 18, "stone": 8})
	game.free()
