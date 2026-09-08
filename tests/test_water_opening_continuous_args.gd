extends "res://tests/test_case.gd"

const OPENING := preload("res://tests/smoke_water_opening_continuous.gd")
const STORMWOOD := preload("res://tests/smoke_stormwood_continuous.gd")


func test_optional_segment_arguments_preserve_shorter_modes() -> void:
	var base: Dictionary = OPENING.requested_segments(PackedStringArray())
	assert_false(base.through_reedhaven)
	assert_false(base.through_brine)
	assert_false(base.through_shellwatch)
	assert_false(base.through_tidal_recipe)
	var reedhaven: Dictionary = OPENING.requested_segments(
		PackedStringArray(["--through-reedhaven"]))
	assert_true(reedhaven.through_reedhaven)
	assert_false(reedhaven.through_brine)
	assert_false(reedhaven.through_shellwatch)
	assert_false(reedhaven.through_tidal_recipe)
	var brine: Dictionary = OPENING.requested_segments(PackedStringArray(["--through-brine"]))
	assert_true(brine.through_reedhaven)
	assert_true(brine.through_brine)
	assert_false(brine.through_shellwatch)
	assert_false(brine.through_tidal_recipe)
	var shellwatch: Dictionary = OPENING.requested_segments(
		PackedStringArray(["--through-shellwatch"]))
	assert_true(shellwatch.through_reedhaven)
	assert_true(shellwatch.through_brine)
	assert_true(shellwatch.through_shellwatch)
	assert_false(shellwatch.through_tidal_recipe)
	var tidal: Dictionary = OPENING.requested_segments(PackedStringArray(["--through-tidal-recipe"]))
	assert_true(tidal.through_reedhaven)
	assert_true(tidal.through_brine)
	assert_true(tidal.through_shellwatch)
	assert_true(tidal.through_tidal_recipe)
	assert_eq(OPENING.BRINE_PARTY, STORMWOOD.ENTRY_PARTY)
	assert_eq(OPENING.BRINE_PARTY_LEVEL, 44)
