extends "res://tests/test_case.gd"

## THINGS-TELLDUST (13 Nov 2026): the wind-up dust ships as one soft low band
## (LANE-SCOUT G-things-telldust.md: 3/3 prefer on every set, no loss).
const TELL_STYLE := preload("res://scripts/combat/tell_style.gd")


func _soft() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json"))
	assert_true(parsed is Dictionary)
	return ((parsed as Dictionary).get("telegraph", {}) as Dictionary).get("soft_style", {})


func test_the_shipped_dust_is_the_judged_band() -> void:
	var soft := _soft()
	# Round 2 (THINGS-TELLDUST3, G-things-telldust3-grunt-medium.md) lowered and
	# tightened the round-1 band: 0.8 / 0.3 / 0.06 -> 0.5 / 0.2 / 0.04.
	assert_eq(float(soft.get("dust_size_m", 0.0)), 0.5)
	assert_eq(float(soft.get("dust_spacing_m", 0.0)), 0.2)
	assert_eq(float(soft.get("dust_alpha", 0.0)), 0.32)
	assert_eq(float(soft.get("dust_rise_m", 0.0)), 0.04)
	assert_eq(str(soft.get("dust_colour", "")), "#8a7654")
	assert_true(str(soft.get("_why_dust_band_1113", "")).contains("G-things-telldust.md"))


func test_the_puffs_overlap_so_they_cannot_read_as_beads() -> void:
	var soft := _soft()
	assert_true(float(soft.get("dust_size_m", 0.0)) > float(soft.get("dust_spacing_m", 1.0)) * 2.0,
		"each puff is more than twice as wide as the gap to the next")


func test_the_dust_is_still_on_and_the_outlines_still_off() -> void:
	var soft := _soft()
	assert_true(TELL_STYLE.dust_enabled(soft), "the wind-up still kicks up dust")
	assert_true(soft.get("outline_off") == true, "painted attack outlines stay off (owner, 24 Oct)")
