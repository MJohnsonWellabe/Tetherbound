extends "res://tests/test_case.gd"

## The planner must never promise a different result than BuildPlacer's live
## ghost. These are deliberately pure: the shared evaluator receives the same
## raw aim, records, affordability gate, and ground sampler that the public
## node wrapper supplies at runtime.

const BUILD_PLACER := preload("res://scripts/build/build_placer.gd")
const SOURCE_PATH := "res://scripts/build/build_placer.gd"


class FakeGame extends Node:
	var placed_buildings: Array = []
	var affordable := true

	func can_afford(_id: String) -> bool:
		return affordable


func _flat_ground(_at: Vector3) -> float:
	return 0.0


func _evaluate(game: Node, id: String, records: Array = []) -> Dictionary:
	return BUILD_PLACER.evaluate_placement(game, id, Vector3.ZERO, records,
		Callable(self, "_flat_ground"))


func test_public_preview_and_live_ghost_share_one_legality_core() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH)
	assert_true(source.contains("var preview := preview_placement(game, armed, raw_spot)"),
		"the live ghost must consume the public preview result")
	assert_true(source.contains("return evaluate_placement(game, armed, raw_spot, buildings"),
		"the public wrapper must delegate to the shared legality core")


func test_preview_agrees_with_live_for_a_legal_floor() -> void:
	var game := FakeGame.new()
	var preview := _evaluate(game, "floor")
	assert_true(bool(preview.get("ok", false)))
	assert_false(bool(preview.get("structural", false)), "a free grid floor is legal but has no structural snap")
	assert_eq(str(preview.get("reason", "")), "")


func test_preview_agrees_with_live_for_an_occupied_structural_anchor() -> void:
	var game := FakeGame.new()
	var floor_record := {"id": "floor", "position": [0.0, 0.0, 1.0]}
	# Ask the placer where it WOULD stand a wall against this floor's edge,
	# then stand one exactly there and prove it refuses a second. Unlike
	# same-id floor aim, this structural candidate deliberately does not use
	# the ordinary grid's neighbour-push fallback before occupancy is checked.
	#
	# The anchor is derived rather than written as a literal because a literal
	# is what made this check stale: BUILD-KIT-3 recentred the wall on its own
	# off-centre material instead of its glTF origin, moving every floor-edge
	# anchor by 0.11m, and the hard-coded fixture then named a cell the placer
	# no longer produces. `occupied()` is a 0.02m same-anchor test, so the
	# check silently stopped reaching the occupancy branch it exists for and
	# reported a legal placement instead. Derived, it cannot go stale again.
	var first := _evaluate(game, "wall", [floor_record])
	assert_true(bool(first.get("ok", false)),
		"the first wall against a bare floor edge must be legal")
	var anchor: Vector3 = first.get("position", Vector3.INF)
	assert_true(anchor.is_finite(), "the structural snap resolved no position at all")

	var preview := _evaluate(game, "wall", [
		floor_record,
		{"id": "wall", "position": [anchor.x, anchor.y, anchor.z]},
	])
	assert_false(bool(preview.get("ok", false)))
	assert_eq(str(preview.get("reason", "")), "Something is already here")


func test_preview_preserves_live_floor_neighbour_push_before_occupancy() -> void:
	var game := FakeGame.new()
	var preview := _evaluate(game, "floor", [{"id": "floor", "position": [0.0, 0.0, 0.0]}])
	assert_true(bool(preview.get("ok", false)))
	var resolved: Vector3 = preview.get("position", Vector3.INF)
	assert_true(resolved.distance_to(Vector3.ZERO) > 0.01,
		"same-id floor aim must retain the live grid resolver's legal neighbour push")


func test_preview_reports_an_unsupported_roof_exactly_as_live_grid_fallback() -> void:
	var game := FakeGame.new()
	var preview := _evaluate(game, "roof")
	assert_true(bool(preview.get("ok", false)), "the existing live placer permits its ordinary grid fallback")
	assert_false(bool(preview.get("structural", false)),
		"preflight must reject this for a planned roof even though live free placement stays legal")


func test_preview_agrees_with_live_for_an_unaffordable_piece() -> void:
	var game := FakeGame.new()
	game.affordable = false
	var preview := _evaluate(game, "floor")
	assert_false(bool(preview.get("ok", false)))
	assert_eq(str(preview.get("reason", "")), "Can't afford this — check the build menu for what's short")
