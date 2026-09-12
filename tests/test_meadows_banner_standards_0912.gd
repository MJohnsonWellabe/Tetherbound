extends "res://tests/test_case.gd"

## OWNER-0912 red-flag regression coverage. Meadows faction sites use the
## installed vertical standard accepted at Hallward, never the flat castle
## cloth cutout that read as a paper arrow in production captures.

const PROP_PATHS := [
	"res://data/config/bands/band1_lower_meadows/props.json",
	"res://data/config/bands/band3_the_river_lock/props.json",
	"res://data/config/bands/band4_upper_meadows_ironwood/props.json",
	"res://data/config/bands/band5_stronghold_approach/props.json",
]
const STANDARD_MODEL := "Banner_1"
const STANDARD_DIR := "res://assets/props/quaternius_fantasy"
const STANDARD_SCALE := 1.55
const STANDARD_SINK := -2.4
const STANDARD_MATERIAL := "MI_Banner"
const OXBLOOD := "#7a2430"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s parses as a JSON object" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _all_props(path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_cluster: Variant in (_json(path).get("clusters", []) as Array):
		if not raw_cluster is Dictionary:
			continue
		for raw_prop: Variant in ((raw_cluster as Dictionary).get("props", []) as Array):
			if raw_prop is Dictionary:
				result.append(raw_prop as Dictionary)
	return result


func test_meadows_has_no_flat_castle_banner_props() -> void:
	for path: String in PROP_PATHS:
		for prop: Dictionary in _all_props(path):
			assert_false(str(prop.get("model", "")) == "Banner",
				"%s must not restore the flat castle Banner prop" % path)


func test_every_meadows_banner_uses_the_accepted_vertical_treatment() -> void:
	var standard_count := 0
	for path: String in PROP_PATHS:
		for prop: Dictionary in _all_props(path):
			if str(prop.get("model", "")) != STANDARD_MODEL:
				continue
			standard_count += 1
			assert_eq(str(prop.get("dir", "")), STANDARD_DIR,
				"vertical standards resolve through the installed fantasy-prop family")
			assert_almost_eq(float(prop.get("scale", 0.0)), STANDARD_SCALE, 0.001,
				"vertical standards keep the accepted readable scale")
			assert_almost_eq(float(prop.get("sink_m", 0.0)), STANDARD_SINK, 0.001,
				"vertical standards seat their measured below-origin extent")
			assert_false(prop.has("pitch_deg"),
				"full standards stand vertically instead of faking a cloth-stake lean")
			var retint := prop.get("retint", {}) as Dictionary
			var cloth := retint.get(STANDARD_MATERIAL, {}) as Dictionary
			assert_true(str(cloth.get("color", "")) in [OXBLOOD, "#d86870"],
				"vertical standards retain an authored readable Tether-red cloth colour")
			assert_eq(str(cloth.get("profile", "")), "dimensional_cloth",
				"vertical standards use the non-planar luminance-remapped cloth profile")
	assert_eq(standard_count, 12,
		"all twelve installed roadside standards are covered by this regression")
