extends "res://tests/test_case.gd"

## Source contract for the final Meadows acceptance batch. This does not claim
## visual acceptance; it prevents stale directories, incomplete manifests, or
## a staged/fake riding pose from being mistaken for production evidence.

const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const LEGACY_FOCUSED := [
	"res://tools/capture_grandpas_village_identity.gd",
	"res://tools/capture_burrow_warrens_visual_identity.gd",
	"res://tools/capture_stonewater_reach_identity.gd",
	"res://tools/capture_tether_relay_identity.gd",
	"res://tools/capture_ironwood_grove_identity.gd",
]


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func test_shared_output_contract_requires_a_new_named_report_round() -> void:
	assert_eq(FRESH_OUTPUT.requested(["--output=res://ralph/reports/MEADOWS-0912/final-village-01"]),
		"res://ralph/reports/MEADOWS-0912/final-village-01")
	assert_eq(FRESH_OUTPUT.requested([]), "")
	assert_true(FRESH_OUTPUT.valid("res://ralph/reports/MEADOWS-0912/final-village-01"))
	for invalid: String in ["", "res://", "res://shots", "user://reports/final",
			"res://ralph/reports/final", "res://ralph/reports/../final", "res:\\reports\\final"]:
		assert_false(FRESH_OUTPUT.valid(invalid), "unsafe or ambiguous capture output passed: %s" % invalid)


func test_every_focused_location_harness_fails_closed_and_accounts_for_its_plan() -> void:
	for path: String in LEGACY_FOCUSED:
		var source := _source(path)
		for required: String in ["FRESH_OUTPUT.create_fresh", "DisplayServer.get_name() == \"headless\"",
				'"output_directory"', '"expected_frame_count"', '"captured_frame_count"',
				'"planned_frames"', '"complete"', '"failures"', "quit(0 if complete else 1)"]:
			assert_true(source.contains(required), "%s omits %s" % [path, required])
		assert_false(source.contains("DEFAULT_OUT_DIR"), "%s can still silently reuse an old round" % path)


func test_village_and_location_plans_cover_the_0912_judgment_angles() -> void:
	var village := _source("res://tools/capture_grandpas_village_identity.gd")
	for required: String in ["06-south-street-from-trail-gate", "07-south-street-from-well",
			"05-mira-trade-crest", 'for time_name: String in ["day", "night"]']:
		assert_true(village.contains(required), "village plan omits %s" % required)
	var warrens := _source("res://tools/capture_burrow_warrens_visual_identity.gd")
	for required: String in ["01-arrival-day", "01-arrival-night", "02-threshold-day",
			"02-threshold-night", "03-den-arrival-day"]:
		assert_true(warrens.contains(required), "Warrens plan omits %s" % required)
	var stonewater := _source("res://tools/capture_stonewater_reach_identity.gd")
	for required: String in ["01-haulage-wreck-day", "02-road-arrival-day", "05-spring-arrival-day",
			"07-overlook-water-night", "08-springhead-night"]:
		assert_true(stonewater.contains(required), "Stonewater plan omits %s" % required)
	var relay := _source("res://tools/capture_tether_relay_identity.gd")
	assert_true(relay.contains("01-relay-approach") and relay.contains("03-relay-apparatus")
		and relay.contains('for time_name: String in ["day", "night"]'))
	var ironwood := _source("res://tools/capture_ironwood_grove_identity.gd")
	assert_true(ironwood.contains("01-long-road-world-tree-day")
		and ironwood.contains("01-long-road-world-tree-night")
		and ironwood.contains("04-ironwood-workyard-day")
		and ironwood.contains("04-ironwood-workyard-night"))


func test_riding_plan_uses_the_real_mount_path_and_paired_fit_views() -> void:
	var source := _source("res://tools/_capture_riding.gd")
	for required: String in ["EncounterDirector", "RidingController.mount()", 'riding.call("mount")',
			'riding.call("is_mounted")', 'riding.call("mount_body")', "RideSaddle",
			"01-unsaddled-three-quarter-day", "01-unsaddled-three-quarter-night",
			"02-mounted-three-quarter-day", "02-mounted-three-quarter-night",
			"03-mounted-side-day", "03-mounted-side-night", '"expected_frame_count": PLANNED.size()',
			'"production_riding_mounted"', '"saddle_visual_present"']:
		assert_true(source.contains(required), "riding receipt omits %s" % required)
	for forbidden: String in ["reparent(player", "player.reparent", "set_rider_pose", "DEFAULT_OUT_DIR"]:
		assert_false(source.contains(forbidden), "riding receipt stages forbidden pose/output seam: %s" % forbidden)


func test_existing_combined_and_bramblebun_tools_keep_their_production_contracts() -> void:
	var combined := _source("res://tools/capture_meadows_0912_wayfinding_and_pulls.gd")
	assert_true(combined.contains("DirAccess.dir_exists_absolute")
		and combined.contains('const TIMES: Array[String] = ["day", "night"]')
		and combined.contains('"expected_frame_count": VIEWS.size() * TIMES.size()')
		and combined.contains("production_scene"))
	var bramblebun := _source("res://tools/capture_bramblebun_low_light_floor.gd")
	assert_true(bramblebun.contains('requires a unique --output=res://... directory')
		and bramblebun.contains('"day", "golden", "night"')
		and bramblebun.contains("EncounterDirector")
		and bramblebun.contains("production Camera3D"))
