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


# --- CAMP-SHELTER-0903: a bedroll needs a tent ------------------------------

func test_bedroll_inside_a_placed_tent_is_accepted() -> void:
	var game := FakeGame.new()
	# `_flat_ground` always answers 0.0 and `Vector3.ZERO`'s own snap lands
	# the bedroll ghost's raw aim exactly at the origin -- the same spot a
	# tent placed at the origin (yaw 0) sits at, so this is the ordinary
	# "aim at the tent you already pitched" placement, not a contrived one.
	var preview := _evaluate(game, "bedroll", [{"id": "tent", "position": [0.0, 0.0, 0.0], "yaw_deg": 0.0}])
	assert_true(bool(preview.get("ok", false)), "a bedroll dead centre in a placed tent must be legal")
	assert_eq(str(preview.get("reason", "")), "")


func test_bedroll_outside_every_tent_is_refused_with_a_clear_reason() -> void:
	var game := FakeGame.new()
	# The tent sits 20m away -- nowhere near this bedroll's own aim (the
	# origin) once `_bedroll_has_tent` rotates the aim into the tent's own
	# local frame and checks it against `camp_tent.gd::INTERIOR_HALF_X`/`_Z`.
	var preview := _evaluate(game, "bedroll", [{"id": "tent", "position": [20.0, 0.0, 20.0], "yaw_deg": 0.0}])
	assert_false(bool(preview.get("ok", false)), "a bedroll with no tent over it must be refused")
	assert_eq(str(preview.get("reason", "")), "A bedroll needs to be inside a tent")


func test_bedroll_with_no_tent_placed_at_all_is_refused() -> void:
	var game := FakeGame.new()
	var preview := _evaluate(game, "bedroll")
	assert_false(bool(preview.get("ok", false)))
	assert_eq(str(preview.get("reason", "")), "A bedroll needs to be inside a tent")


func test_a_removed_tent_no_longer_shelters_a_bedroll() -> void:
	# `occupied()`/`_bedroll_has_tent` both skip `removed` entries -- a
	# dismantled tent must stop covering a bedroll the same live way a real
	# dismantle does (`build_placer.gd::dismantle_piece` marks a record
	# removed rather than deleting it outright is out of scope here; what
	# matters is this planner-facing check honours the same flag).
	var game := FakeGame.new()
	var preview := _evaluate(game, "bedroll",
		[{"id": "tent", "position": [0.0, 0.0, 0.0], "yaw_deg": 0.0, "removed": true}])
	assert_false(bool(preview.get("ok", false)))
	assert_eq(str(preview.get("reason", "")), "A bedroll needs to be inside a tent")


func test_other_ids_are_unaffected_by_the_tent_requirement() -> void:
	# The constraint is bedroll-specific -- a floor (or any other buildable)
	# with no tent anywhere nearby must place exactly as it always has.
	var game := FakeGame.new()
	var preview := _evaluate(game, "floor")
	assert_true(bool(preview.get("ok", false)))
	assert_eq(str(preview.get("reason", "")), "")


func test_loading_a_save_never_re_checks_bedroll_placement_legality() -> void:
	# A save written before this rule existed (or one where the tent over a
	# bedroll was later dismantled) must still load -- `restore_from_game`
	# reads `id`/`position`/`yaw_deg` straight off each record and spawns it
	# unconditionally, the same way it already tolerated an overlapping or
	# off-terrain legacy placement. A regression that routed a load through
	# `evaluate_placement` (or the new `_bedroll_has_tent` check specifically)
	# would start silently dropping exactly those legacy bedrolls, so this
	# guards the shape of the function rather than only today's numbers.
	var source := FileAccess.get_file_as_string(SOURCE_PATH)
	var start := source.find("func restore_from_game(")
	var next_func := source.find("\nfunc ", start + 1)
	var body := source.substr(start, next_func - start)
	assert_false(body.contains("evaluate_placement"),
		"restore_from_game must not re-run placement legality on a loaded save")
	assert_false(body.contains("_bedroll_has_tent"),
		"restore_from_game must not re-run the tent-containment check on a loaded save")
