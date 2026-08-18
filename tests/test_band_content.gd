extends "res://tests/test_case.gd"

## BAND-SPLIT. The four content configs are cut per corridor band; this file is
## the proof that cutting them changed nothing.
##
## Why it exists in this shape. The split is a pure data-layout change, so the
## only way it can be wrong is by being *almost* right: one entry dropped, one
## entry duplicated, or -- the one that would actually hurt -- entries merged
## back in a different order. Order is identity for `spawns.json`:
## `encounter_director.gd` seeds each cluster's scatter, level roll, IVs, traits
## and shiny draw from the entry's `order`, so a reordered merge moves creatures
## and rerolls them. None of that raises an error, none of it fails a smoke
## test, and all of it would be found weeks later as "the meadow feels
## different" with nothing in any diff to point at.
##
## So this does not read the split's diff or check that it looks reasonable. It
## loads the pre-split originals out of `tests/fixtures/band_split_baseline/`
## and asserts the merge reproduces them entry for entry, index for index,
## value for value.
##
## The fixtures are deliberately frozen copies and NOT a golden file to be
## regenerated. Every assertion below is scoped to the first `baseline.size()`
## entries, so content authored after the split appends past them and this stays
## green -- while the entries that existed at the split, and the indices they
## occupy, are pinned forever. That is exactly the property five agents
## authoring five bands need: nobody else's new content can move yours.
##
## Verified failable before shipping, twice, because "it passes" proves nothing:
##
##   * Deleting one node from `bands/band2_stone_and_root/harvest.json` fails
##     with "harvest.json merged to 21 entries but 22 were authored before the
##     split; the band files have lost 1".
##   * Swapping the `order` of `spawns` 4 and 5 — the adversarial case, since
##     both are `meadowhart` and the counts are unchanged, so nothing about the
##     table's shape moves — fails with "spawns[4].centre[0] is 40.0, expected
##     60.0". That is the failure that matters: those two entries carry
##     different seeds, so a swap moves both clusters and rerolls every creature
##     in them.

const BAND_CONTENT := preload("res://scripts/data/band_content.gd")

const BASELINE_DIR := "res://tests/fixtures/band_split_baseline"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"

## config file name -> the positional array that was cut out of it.
const SPLIT_CONFIGS := {
	"spawns.json": "spawns",
	"props.json": "clusters",
	"harvest.json": "nodes",
	"trainers.json": "trainers",
}


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## --- the load-bearing check ---------------------------------------------------


func test_merged_arrays_are_identical_to_the_pre_split_files() -> void:
	for file_name: String in SPLIT_CONFIGS:
		var array_key := str(SPLIT_CONFIGS[file_name])
		var baseline: Array = _read_json("%s/%s" % [BASELINE_DIR, file_name]).get(array_key, []) as Array
		assert_false(baseline.is_empty(),
			"the %s baseline fixture is missing or empty; this test would prove nothing" % file_name)

		var merged: Array = BAND_CONTENT.load_config(
			"res://data/config/%s" % file_name, array_key).get(array_key, []) as Array
		assert_true(merged.size() >= baseline.size(),
			"%s merged to %d entries but %d were authored before the split; the band files have lost %d" % [
				file_name, merged.size(), baseline.size(), baseline.size() - merged.size()])
		if merged.size() < baseline.size():
			continue

		for index in baseline.size():
			var want: Dictionary = baseline[index]
			var got: Dictionary = merged[index]
			# `order` is the one key the split adds. It has to equal the index
			# it replaced, or the seeds derived from it are different numbers.
			assert_eq(int(got.get("order", -1)), index,
				"%s entry %d carries order %s; before the split it was at index %d and the seed is derived from that" % [
					file_name, index, str(got.get("order", "<missing>")), index])
			var stripped := got.duplicate(true)
			stripped.erase("order")
			var difference := _first_difference(stripped, want, "%s[%d]" % [array_key, index])
			assert_eq(difference, "",
				"%s: the merged entry does not match the pre-split file — %s" % [file_name, difference])


func test_the_head_files_keep_every_global_they_had() -> void:
	for file_name: String in SPLIT_CONFIGS:
		var array_key := str(SPLIT_CONFIGS[file_name])
		var baseline: Dictionary = _read_json("%s/%s" % [BASELINE_DIR, file_name])
		assert_false(baseline.is_empty(), "the %s baseline fixture is missing" % file_name)
		var merged: Dictionary = BAND_CONTENT.load_config(
			"res://data/config/%s" % file_name, array_key)

		for key: String in baseline:
			if key == array_key:
				continue
			# `respawn_seconds`, `roles`, `flow`, `prompts` and every `_comment`
			# are global. The split must not have taken any of them with it, and
			# must not have sharded them into five copies that can drift.
			var difference := _first_difference(merged.get(key, null), baseline[key], key)
			assert_eq(difference, "",
				"%s lost or changed the global '%s' — %s" % [file_name, key, difference])


## --- the machinery, checked so a future content pass cannot break it quietly ---


func test_the_head_files_no_longer_carry_the_positional_array() -> void:
	# If an author re-adds entries to the head file they would be invisible to
	# the merge (which fills the key outright) rather than merged, so the world
	# would silently ignore them. `band_content.gd` push_error()s on this; the
	# check is here so it fails a test run and not just a log nobody reads.
	for file_name: String in SPLIT_CONFIGS:
		var head: Dictionary = _read_json("res://data/config/%s" % file_name)
		assert_false(head.is_empty(), "%s is missing or is not a JSON object" % file_name)
		assert_false(head.has(str(SPLIT_CONFIGS[file_name])),
			"%s has a top-level '%s' again; band content belongs under data/config/bands/<band>/" % [
				file_name, str(SPLIT_CONFIGS[file_name])])


func test_no_band_file_entry_is_dropped_by_the_merge() -> void:
	# Counted from the band files directly rather than from the merge, so this
	# fails if the merge ever skips a band, a file or an entry — the failure the
	# `order` sort is most likely to introduce.
	for file_name: String in SPLIT_CONFIGS:
		var array_key := str(SPLIT_CONFIGS[file_name])
		var authored := 0
		for band: String in BAND_CONTENT.BANDS:
			var path := "res://data/config/bands/%s/%s" % [band, file_name]
			if not FileAccess.file_exists(path):
				continue
			authored += (_read_json(path).get(array_key, []) as Array).size()
		var merged: Array = BAND_CONTENT.load_config(
			"res://data/config/%s" % file_name, array_key).get(array_key, []) as Array
		assert_eq(merged.size(), authored,
			"%s: the band files hold %d entries but the merge produced %d" % [
				file_name, authored, merged.size()])


func test_order_is_unique_across_every_band() -> void:
	# Two entries sharing an `order` is the collision the reserved per-band
	# ranges exist to prevent, and for spawns it means two clusters scattering
	# off one seed — invisible until somebody notices two species standing in
	# the same ring.
	for file_name: String in SPLIT_CONFIGS:
		var array_key := str(SPLIT_CONFIGS[file_name])
		var owner_of := {}
		for band: String in BAND_CONTENT.BANDS:
			var path := "res://data/config/bands/%s/%s" % [band, file_name]
			if not FileAccess.file_exists(path):
				continue
			for entry: Variant in (_read_json(path).get(array_key, []) as Array):
				assert_true((entry as Dictionary).has("order"),
					"%s/%s has an entry with no `order`; its merge position is undefined" % [band, file_name])
				var order := int((entry as Dictionary).get("order", -1))
				assert_false(owner_of.has(order),
					"%s: order %d is used by both '%s' and '%s'" % [
						file_name, order, str(owner_of.get(order, "")), band])
				owner_of[order] = band


func test_the_loader_knows_exactly_the_bands_the_trail_has() -> void:
	# A band added to the trail and not added here loads as a region with no
	# content and no error anywhere — the world just quietly has nothing in it
	# past a certain z.
	var trail: Dictionary = _read_json(TERRAIN_PATH).get("trail", {}) as Dictionary
	var authored: Array[String] = []
	for band: Variant in (trail.get("bands", []) as Array):
		authored.append(str((band as Dictionary).get("id", "")))
	assert_false(authored.is_empty(), "terrain_playground.json declares no trail bands")
	assert_eq(BAND_CONTENT.BANDS, authored,
		"band_content.gd's band list %s does not match the trail's %s" % [
			str(BAND_CONTENT.BANDS), str(authored)])


## --- a value-by-value compare that says WHERE it differs ----------------------
##
## Not `==`. Two reasons: Godot's `==` on nested containers is easy to be wrong
## about, and a bare true/false here would report "spawns.json does not match"
## for a 13-entry table of 6-key dictionaries and leave the reader to find it.
## Returns "" for equal, or a human-readable path to the first difference.
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
			if want_dict.has(key):
				continue
			# A NEW `_comment*` key is documentation, not data, and must not fail
			# this test. The point of the identity check is that SPLITTING the
			# configs changed no gameplay value -- not that the split files are
			# frozen against every later edit. `OW6` annotated four existing
			# `trainers` entries with `_comment_ow6` explaining why each captain
			# sits where it does, which is exactly the kind of `_why` this repo
			# asks authors to write, and it turned the whole bundle red.
			#
			# A new key that is NOT a comment still fails, because that would be
			# real data appearing from nowhere. Missing keys and changed values
			# fail either way, comment or not -- the loop above sees those, and
			# it is the one that catches a split dropping something.
			if str(key).begins_with("_comment"):
				continue
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
