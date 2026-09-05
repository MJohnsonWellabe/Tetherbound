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
	var source := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
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
	var source := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
	assert_true(source.contains("before_wood - 39"), "2x2 house must spend its exact 39 wood")
	assert_true(source.contains("before_stone - 34"), "2x2 house must spend its exact 34 stone")
	assert_true(source.contains("built_records != 12"), "four floors + door + three walls + four roofs")
	assert_true(source.contains("wood_before + 6"), "dismantled wall must refund all six wood")
	assert_true(source.contains("stone_before + 2"), "dismantled wall must refund both stone")


func test_reusable_segment_enters_and_preflights_the_documented_patch_before_spending() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
	assert_true(source.contains("BUILD_PATCH_XZ := Vector2(30.0, -40.0)"),
		"the authored Practice Meadow clearing must be the documented patch")
	assert_true(source.contains("Vector2(10.0, -13.0), # Village Square"),
		"the reusable route must begin at the real-exploration Village Square entry")
	assert_true(source.contains("Vector2(18.0, -24.0), # Practice Meadow road bend"),
		"the route must follow the authored road bend instead of a settlement diagonal")
	assert_true(source.contains("all twelve planned anchors were green/reachable before spending"),
		"canonical evidence must walk to the patch rather than arrive by fixture warp")
	assert_true(source.contains("Practice Meadow road waypoint %d"),
		"the player must approach the patch through named parsed-controller waypoints")
	assert_false(source.contains("_walk_to(Vector3(BUILD_PATCH_XZ.x"),
		"the old direct diagonal to the patch must not return")
	assert_true(source.contains("build segment must begin at the Village Square route entry through ordinary exploration"),
		"canonical evidence must enter from real exploration, never a helper-side warp")
	assert_true(source.contains("the documented patch has no legal first Floor ghost"),
		"a live green Floor ghost must prove clearance before paid placement")
	assert_true(source.contains("_preflight_all_planned_anchors"),
		"all planned anchors must be checked before the first paid Floor")
	assert_true(source.contains("preview_placement"),
		"future structural anchors must use BuildPlacer's public no-spend query")
	assert_true(source.contains("planned: Array[Dictionary]"),
		"planned support records must remain test-local")


func test_mechanical_fixture_is_not_misrepresented_as_canonical_evidence() -> void:
	var wrapper := FileAccess.get_file_as_string(MECHANICAL_WRAPPER_PATH)
	assert_true(wrapper.contains("explicitly a fixture, not Gate A's canonical continuous session"),
		"the injected mechanical wrapper must stay honestly labelled")
	assert_true(wrapper.contains("Wrapper-only fixture placement"),
		"fixture positioning must remain visibly scoped outside the reusable controller segment")
	assert_true(wrapper.contains("ROUTE_ENTRY_XZ := Vector2(10.0, -13.0)"),
		"the mechanical wrapper must stage only at the named route entry")
	assert_true(wrapper.contains("This is not canonical positioning"),
		"the wrapper must disclose that its route-entry staging is noncanonical")


func test_roof_stances_use_the_preflighted_open_exterior_ring() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
	assert_true(source.contains("_place_roof_from_exterior"),
		"each roof must be placed from an explicitly staged exterior stance")
	assert_true(source.contains("var door_target := floor_a + Vector3(0, 0, -1)"),
		"the doorway must remain on the front edge")
	assert_true(source.contains("floor_a + Vector3(2, 0, -1)"),
		"the front-right roof must have a front wall support")
	assert_true(source.contains("floor_a + Vector3(0, 0, 3)"),
		"the rear-left roof must have a rear wall support")
	assert_true(source.contains("floor_a + Vector3(2, 0, 3)"),
		"the rear-right roof must have a rear wall support")
	assert_true(source.contains("_assert_live_roof_ghost"),
		"each exterior stance must prove its live Roof ghost before spending")
	assert_true(source.contains("green live ghost"),
		"a red or absent Roof ghost must fail before placement")
	assert_true(source.contains("Roof ghost resolved to"),
		"the live ghost must resolve to the exact supported anchor")
	assert_true(source.contains("HOUSE_AIM_DIRECTION, \"rear-exterior\""),
		"rear roofs must use the preflighted exterior ring")
	# The front pair faces the OTHER way, and that is the fix rather than a
	# drift from it. GATEB-COORD drove this segment to a finished house for the
	# first time and found that `HOUSE_AIM_DIRECTION` puts the front stance
	# three metres the wrong way -- on top of the floor the completed shell
	# encloses, which the preflight cannot detect because it runs before
	# anything is built. The trainer circled the finished house for three full
	# attempts trying to reach a spot inside it. The front row's exterior IS
	# the south side, so the segment stands there and faces back; the roof
	# ANCHOR is unchanged, because
	# `build_snap_contract.gd::_add_supported_roofs()` corrects by the
	# SUPPORT's yaw rather than the player's.
	assert_true(source.contains("-HOUSE_AIM_DIRECTION,\n\t\t\t\t\"front-exterior\"")
			or source.contains("-HOUSE_AIM_DIRECTION, \"front-exterior\""),
		"front roofs must be aimed from their own exterior, facing back at the house")
	assert_true(source.contains("look_right"),
		"the exterior roof orientation must be supplied through the right stick")
	assert_false(source.contains("_move_round_open_right_side"),
		"the known transfer blocker must not return")
	assert_true(source.contains("all twelve planned anchors"),
		"no paid roof route may begin without all-anchor preflight")


func test_structural_travel_is_stowed_then_rearmed_through_the_catalogue() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
	assert_true(source.contains("_stow_piece_for_travel"),
		"roof and dismantle travel must use the public Cancel path")
	assert_true(source.contains("await _tap_action(&\"build_cancel\")"),
		"stowing must be a parsed visible control, not direct pending_build mutation")
	assert_true(source.contains("await _walk_to(wanted_player, \"aimed dismantle stance\")"),
		"the player must reach each exterior stance while placement is stowed")
	assert_true(source.contains("await _select_piece(\"roof\")"),
		"Roof must be rearmed through the controller catalogue at the destination")
	assert_true(source.contains("await _select_piece(\"wall\")"),
		"the placer must be rearmed publicly at the dismantle stance")


func test_preflight_errors_do_not_claim_a_dismantle_attempt() -> void:
	var source := FileAccess.get_file_as_string(SOURCE_PATH).replace("\r\n", "\n")
	var preflight := source.substr(source.find("func _preflight()"), source.find("func _preflight_all_planned_anchors"))
	assert_false(preflight.contains("aimed dismantle stance"),
		"a pre-spend route failure must not be reported as dismantle movement")
	# Matched as a PREFIX. GATEB-COORD gave `_walk_to` a third parameter (the
	# arrival tolerance, so a walk that only needs to BE somewhere does not
	# fail asking for 16cm), and what this assertion is for is unchanged: every
	# caller still has to name its own purpose, because that is what turns a
	# walk failure into a sentence that says which walk failed.
	assert_true(source.contains("func _walk_to(target: Vector3, purpose: String"),
		"shared controller walking must name each caller's actual purpose")
