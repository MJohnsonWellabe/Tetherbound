extends "res://tests/test_case.gd"

## F36#52 Mirejaw (GPU High G-below6-hits, 12 Nov 2026: 5.72 -> 6.32, 3/3).
## creature_clip_flags.json below6_mirejaw_hit scales the hit clip so the jaw
## and tail stay in a readable flinch; it ships ON and cites that verdict. The
## Abyssal flinch judged alongside it lost and is not declared.

const CLIP_PATH := "res://data/config/creature_clip_flags.json"


func _flags() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CLIP_PATH))
	assert_true(parsed is Dictionary, "creature_clip_flags.json parses")
	return (parsed as Dictionary).get("flags", {}) if parsed is Dictionary else {}


func test_mirejaw_grounded_hit_ships_on() -> void:
	var entry: Dictionary = _flags().get("below6_mirejaw_hit", {})
	assert_true(bool(entry.get("enabled", false)), "below6_mirejaw_hit ships ON (judged gain)")
	assert_true(str(entry.get("_why_on", "")).contains("G-below6-hits.md"), "it cites its GPU verdict")
	assert_true(str(entry.get("_why_on", "")).contains("5.72 -> 6.32"), "and its judged score")
	var hit: Dictionary = (((entry.get("species", {}) as Dictionary).get("mirejaw", {}) as Dictionary).get("hit", {}) as Dictionary)
	assert_eq(float(hit.get("rotation", 1.0)), 0.45)
	assert_eq(float(hit.get("position", 1.0)), 0.5)


func test_abyssal_flinch_is_not_shipped() -> void:
	assert_false(_flags().has("below6_flinch_abyssal"), "the Abyssal flinch lost on the GPU and is not declared")
