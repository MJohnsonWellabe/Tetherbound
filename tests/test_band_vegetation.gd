extends "res://tests/test_case.gd"

## BAND-SPLIT-2. `vegetation.json`'s `clearings` and `footprints` are cut per
## corridor band under `data/config/bands/<band>/vegetation.json`, the same
## treatment `BAND-SPLIT` gave `spawns`/`clusters`/`nodes`/`trainers` -- see
## `tests/test_band_content.gd` for the pattern this copies and D54 for the
## reasoning. Unlike those four, both split arrays live in the SAME per-band
## file (there is one `vegetation.json` per band, holding whichever of
## `clearings`/`footprints` that band authored), so `scripts/world/
## scatter_rules.gd::config()` calls `band_content.gd.load_config()` twice
## against the same head path -- once per array key -- and this test proves
## that produces the same merged result the four-file pattern does.
##
## The load-bearing claim is identity, not tidiness: the merged config must
## match the pre-split file entry for entry, index for index, value for
## value, because `order` is what a future author reserves a range against
## (Band N -> N000-N999) and a merge that reorders would silently shuffle
## which clearing keeps trees off which building.
##
## Verified failable before shipping, twice:
##
##   * Deleting `footprints[6]` (the inn) from
##     `bands/band1_lower_meadows/vegetation.json` fails with "footprints
##     merged to 6 entries but 7 were authored before the split; the band
##     files have lost 1".
##   * Swapping the `order` of `clearings` 5 and 6 (the mill clearing and the
##     ranger station clearing, both radius-different so the swap is
##     detectable) fails with "clearings[5].radius is 10.0, expected 15.0".

const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const SCATTER_RULES := preload("res://scripts/world/scatter_rules.gd")

const BASELINE_PATH := "res://tests/fixtures/band_split_baseline/vegetation.json"
const HEAD_PATH := "res://data/config/vegetation.json"

## file's top-level array key -> nothing else needed; both keys share one file.
const SPLIT_KEYS := ["clearings", "footprints"]


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## --- the load-bearing check ---------------------------------------------------


func test_merged_arrays_are_identical_to_the_pre_split_file() -> void:
	var baseline := _read_json(BASELINE_PATH)
	assert_false(baseline.is_empty(),
		"the vegetation.json baseline fixture is missing or empty; this test would prove nothing")

	for array_key: String in SPLIT_KEYS:
		var want_array: Array = baseline.get(array_key, []) as Array
		assert_false(want_array.is_empty(),
			"the baseline's '%s' is empty; this test would prove nothing" % array_key)

		var merged: Array = BAND_CONTENT.load_config(HEAD_PATH, array_key).get(array_key, []) as Array
		assert_true(merged.size() >= want_array.size(),
			"%s merged to %d entries but %d were authored before the split; the band files have lost %d" % [
				array_key, merged.size(), want_array.size(), want_array.size() - merged.size()])
		if merged.size() < want_array.size():
			continue

		for index in want_array.size():
			var want: Dictionary = want_array[index]
			var got: Dictionary = merged[index]
			assert_eq(int(got.get("order", -1)), index,
				"%s entry %d carries order %s; before the split it was at index %d" % [
					array_key, index, str(got.get("order", "<missing>")), index])
			var stripped := got.duplicate(true)
			stripped.erase("order")
			var difference := _first_difference(stripped, want, "%s[%d]" % [array_key, index])
			assert_eq(difference, "",
				"%s: the merged entry does not match the pre-split file — %s" % [array_key, difference])


func test_scatter_rules_config_carries_both_split_arrays() -> void:
	# The real caller merges via config(), not load_config() directly -- this
	# proves the two-call merge in scatter_rules.gd actually wires both arrays
	# into one dictionary rather than the second call clobbering the first.
	#
	# GATE-D4/prompt 65: was `assert_eq` against the pre-split baseline count,
	# which only ever held while every band file matched the original
	# unsplit file exactly -- true by construction until a lane actually used
	# the mechanism GATE_D_LANE_CONTRACT.md section 4 invites ("add your
	# clearings normally"). Band 4's new watchtower-spur and field-camp
	# clearings (data/config/bands/band4_upper_meadows_ironwood/vegetation.json)
	# are genuinely NEW entries past the baseline, exactly like the sibling
	# `test_merged_arrays_are_identical_to_the_pre_split_file` above already
	# expects (`merged.size() >= want_array.size()`) -- this test used a
	# stricter, uncoordinated check on the same data and broke on the first
	# real content addition rather than on drift. Loosened to match its own
	# sibling's contract: at least the baseline, never fewer.
	SCATTER_RULES._config = {}
	var config := SCATTER_RULES.config()
	var baseline := _read_json(BASELINE_PATH)
	for array_key: String in SPLIT_KEYS:
		var want: Array = baseline.get(array_key, []) as Array
		var got: Array = config.get(array_key, []) as Array
		assert_true(got.size() >= want.size(),
			"scatter_rules.config()'s '%s' has %d entries, expected at least %d" % [array_key, got.size(), want.size()])
	SCATTER_RULES._config = {}


## --- the machinery, checked so a future content pass cannot break it quietly ---


func test_the_head_file_no_longer_carries_the_positional_arrays() -> void:
	var head := _read_json(HEAD_PATH)
	assert_false(head.is_empty(), "vegetation.json is missing or is not a JSON object")
	for array_key: String in SPLIT_KEYS:
		assert_false(head.has(array_key),
			"vegetation.json has a top-level '%s' again; band content belongs under data/config/bands/<band>/" % array_key)


func test_no_band_file_entry_is_dropped_by_the_merge() -> void:
	for array_key: String in SPLIT_KEYS:
		var authored := 0
		for band: String in BAND_CONTENT.BANDS:
			var path := "res://data/config/bands/%s/vegetation.json" % band
			if not FileAccess.file_exists(path):
				continue
			authored += (_read_json(path).get(array_key, []) as Array).size()
		var merged: Array = BAND_CONTENT.load_config(HEAD_PATH, array_key).get(array_key, []) as Array
		assert_eq(merged.size(), authored,
			"vegetation.json's '%s': the band files hold %d entries but the merge produced %d" % [
				array_key, authored, merged.size()])


func test_order_is_unique_across_every_band_and_key() -> void:
	# clearings and footprints share the reserved-range convention independently
	# -- a clearing and a footprint may legally share a number, since they merge
	# into different arrays, so uniqueness is checked per key, not across both.
	for array_key: String in SPLIT_KEYS:
		var owner_of := {}
		for band: String in BAND_CONTENT.BANDS:
			var path := "res://data/config/bands/%s/vegetation.json" % band
			if not FileAccess.file_exists(path):
				continue
			for entry: Variant in (_read_json(path).get(array_key, []) as Array):
				assert_true((entry as Dictionary).has("order"),
					"%s/vegetation.json's '%s' has an entry with no `order`; its merge position is undefined" % [
						band, array_key])
				var order := int((entry as Dictionary).get("order", -1))
				assert_false(owner_of.has(order),
					"vegetation.json's '%s': order %d is used by both '%s' and '%s'" % [
						array_key, order, str(owner_of.get(order, "")), band])
				owner_of[order] = band


## --- a value-by-value compare that says WHERE it differs ----------------------
## Copied verbatim from tests/test_band_content.gd — see that file for why it
## is not a bare `==`.
func _first_difference(got: Variant, want: Variant, path: String) -> String:
	if typeof(got) != typeof(want):
		return "%s: type %s, expected %s (%s vs %s)" % [
			path, type_string(typeof(got)), type_string(typeof(want)), str(got), str(want)]
	if got is Dictionary:
		var got_dict: Dictionary = got
		var want_dict: Dictionary = want
		for key: Variant in want_dict:
			if not got_dict.has(key):
				return "%s.%s is missing" % [path, str(key)]
			var nested := _first_difference(got_dict[key], want_dict[key], "%s.%s" % [path, str(key)])
			if nested != "":
				return nested
		for key: Variant in got_dict:
			if not want_dict.has(key):
				return "%s.%s was added" % [path, str(key)]
		return ""
	if got is Array:
		var got_array: Array = got
		var want_array: Array = want
		if got_array.size() != want_array.size():
			return "%s has %d items, expected %d" % [path, got_array.size(), want_array.size()]
		for index in want_array.size():
			var nested := _first_difference(got_array[index], want_array[index], "%s[%d]" % [path, index])
			if nested != "":
				return nested
		return ""
	if got is float or got is int:
		if not is_equal_approx(float(got), float(want)):
			return "%s is %s, expected %s" % [path, str(got), str(want)]
		return ""
	if got != want:
		return "%s is %s, expected %s" % [path, str(got), str(want)]
	return ""
