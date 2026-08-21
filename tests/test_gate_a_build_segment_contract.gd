extends "res://tests/test_case.gd"

## Static guard for the reusable Gate A controller segment. The real Meadows
## wrapper is a smoke test; this keeps future convenience edits from quietly
## turning the reusable segment back into a direct-state fixture.

const SEGMENT := preload("res://tests/helpers/gate_a_build_segment.gd")
const SOURCE_PATH := "res://tests/helpers/gate_a_build_segment.gd"
const MECHANICAL_WRAPPER_PATH := "res://tests/smoke_gate_a_build_segment_meadows.gd"


func test_reusable_segment_parses() -> void:
	var segment: RefCounted = SEGMENT.new()
	assert_true(segment != null, "the continuous-evidence helper must remain loadable")


func test_reusable_segment_mutates_play_only_through_parsed_controller_events() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH)
	for banned in [
		"set(\"pending_build\"",
		"_spawn_building",
		"register_building",
		"dismantle_piece",
		"global_position =",
		"inventory.call(\"add\"",
		"inventory.call(\"remove\"",
	]:
		assert_false(source.contains(banned), "reusable segment must not use bypass '%s'" % banned)
	assert_true(source.contains("Input.parse_input_event"), "controller events must cross the live InputMap")
	for action in ["build_open", "ui_accept", "build_place", "build_dismantle", "build_cancel", "move_right", "move_back"]:
		assert_true(source.contains(action), "controller sequence must include %s" % action)


func test_reusable_segment_names_the_canonical_paid_house_contract() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH)
	assert_true(source.contains("before_wood - 39"), "2x2 house must spend its exact 39 wood")
	assert_true(source.contains("before_stone - 34"), "2x2 house must spend its exact 34 stone")
	assert_true(source.contains("built_records != 12"), "four floors + door + three walls + four roofs")
	assert_true(source.contains("wood_before + 6"), "dismantled wall must refund all six wood")
	assert_true(source.contains("stone_before + 2"), "dismantled wall must refund both stone")


func test_reusable_segment_enters_and_checks_the_documented_patch_before_spending() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH)
	assert_true(source.contains("BUILD_PATCH_XZ := Vector2(14.0, 20.0)"),
		"the southeast opening-meadow patch must stay documented in source")
	assert_true(source.contains("walked by controller to the documented off-trail patch"),
		"canonical evidence must walk to the patch rather than arrive by fixture warp")
	assert_true(source.contains("await _walk_to(Vector3(BUILD_PATCH_XZ.x"),
		"the player must approach the patch with parsed controller movement")
	assert_true(source.contains("the documented patch has no legal first Floor ghost"),
		"a live green Floor ghost must prove clearance before paid placement")
	assert_true(source.contains("get_first_node_in_group(&\"build_placer\")"),
		"clearance may read only the live placer state, never a test-side placement")


func test_mechanical_fixture_is_not_misrepresented_as_canonical_evidence() -> void:
	var wrapper := FileAccess.get_file_as_string(MECHANICAL_WRAPPER_PATH)
	assert_true(wrapper.contains("explicitly a fixture, not Gate A's canonical continuous session"),
		"the injected mechanical wrapper must stay honestly labelled")
	assert_true(wrapper.contains("Wrapper-only fixture placement"),
		"fixture positioning must remain visibly scoped outside the reusable controller segment")


func test_roof_stances_route_around_the_completed_lower_shell() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH)
	assert_true(source.contains("_move_to_roof_stance"),
		"roof placement must use the outside staging route")
	assert_true(source.contains("_lower_shell_bounds"),
		"the exterior route must derive its footprint from the pieces this segment placed")
	assert_true(source.contains("position.x - BUILD_SNAP.HALF"),
		"lower-shell bounds must use the authoritative module contract")
	assert_true(source.contains("crossing_z = _player.global_position.z"),
		"an already-safe exterior stance must remain the crossing lane instead of moving toward a guessed axis")
	assert_true(source.contains("geometry-derived roof crossing lane"),
		"each roof approach must cross outside the measured house")
	assert_true(source.contains("geometry-derived roof approach lane"),
		"each roof approach must close on its stance from the target's outside side")
	assert_true(source.contains("await _turn_camera_toward(-outward)"),
		"each roof must be aimed inward from an exterior controller stance")
	assert_true(source.contains("look_right"),
		"the exterior roof orientation must be supplied through the right stick")
	assert_true(source.contains("remaining * direction <= 0.0"),
		"clearance legs must accept crossing a coordinate instead of oscillating around a precision waypoint")


func test_structural_travel_is_stowed_then_rearmed_through_the_catalogue() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH)
	assert_true(source.contains("_stow_piece_for_travel"),
		"roof and dismantle travel must use the public Cancel path")
	assert_true(source.contains("await _tap_action(&\"build_cancel\")"),
		"stowing must be a parsed visible control, not direct pending_build mutation")
	assert_true(source.contains("await _move_to_roof_stance"),
		"the player must reach the exterior stance while placement is stowed")
	assert_true(source.contains("await _select_piece(\"roof\")"),
		"Roof must be rearmed through the controller catalogue at the destination")
	assert_true(source.contains("await _select_piece(\"wall\")"),
		"the placer must be rearmed publicly at the dismantle stance")
