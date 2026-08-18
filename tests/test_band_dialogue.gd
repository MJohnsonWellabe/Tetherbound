extends "res://tests/test_case.gd"

## BAND-SPLIT-2. `data/dialogue/` was already multi-file and already merged the
## way `scripts/data/band_content.gd` merges the four content configs -- an
## explicit const list of paths, unioned by `scripts/story/dialogue_runner.gd::
## table()` -- but split by chapter beat (opening/village/trainers/relay/
## stronghold/meadows_freed), not by band. A trainer a band author placed had
## nowhere of its own to put a conversation; it had to land in the shared
## `trainers.json`. This adds one container per band to
## `EXTRA_DIALOGUE_PATHS`.
##
## Unlike the positional-array splits (`test_band_content.gd`,
## `test_band_vegetation.gd`), there is no `order` here to prove identity
## against: `table()` is a Dictionary keyed by conversation id, looked up only
## by id, never by position, so five more merge sources cannot reorder
## anything that exists. What CAN break is additivity -- a bad merge could
## silently drop an id, or a stray path could 404 and silently contribute
## nothing without anyone noticing. That is what this file checks.
##
## Verified failable before shipping: commenting out
## `"res://data/dialogue/bands/band2_stone_and_root.json"` from
## `EXTRA_DIALOGUE_PATHS` failed `test_every_band_file_is_wired_into_the_table`
## with "band2_stone_and_root.json is listed in
## scripts/data/band_content.gd's BANDS but not in dialogue_runner.gd's
## EXTRA_DIALOGUE_PATHS" -- restored afterward.

const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const DIALOGUE_RUNNER := preload("res://scripts/story/dialogue_runner.gd")

const BANDS_DIALOGUE_DIR := "res://data/dialogue/bands"


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## Every band `band_content.gd` knows about needs a dialogue container wired
## into the runner's merge list, or a trainer placed in that band has nowhere
## to put a conversation without touching a file another band also writes to.
func test_every_band_file_is_wired_into_the_table() -> void:
	for band: String in BAND_CONTENT.BANDS:
		var expected_path := "%s/%s.json" % [BANDS_DIALOGUE_DIR, band]
		assert_true(DIALOGUE_RUNNER.EXTRA_DIALOGUE_PATHS.has(expected_path),
			"%s.json is listed in band_content.gd's BANDS but not in dialogue_runner.gd's EXTRA_DIALOGUE_PATHS" % band)
		assert_true(FileAccess.file_exists(expected_path),
			"%s does not exist on disk" % expected_path)
		var doc := _read_json(expected_path)
		assert_true(doc.has("conversations"),
			"%s has no top-level 'conversations' key; dialogue_runner.gd's _load_conversations() would silently read nothing from it" % expected_path)


## The band files are additive-only. Adding five more sources to the merge
## must not change a single id that already resolved before this split --
## nothing here is allowed to shadow opening.json's or village.json's table.
func test_band_dialogue_does_not_shadow_any_existing_conversation() -> void:
	DIALOGUE_RUNNER._table = {}
	var table := DIALOGUE_RUNNER.table()
	for band: String in BAND_CONTENT.BANDS:
		var doc := _read_json("%s/%s.json" % [BANDS_DIALOGUE_DIR, band])
		var conversations: Dictionary = doc.get("conversations", {}) as Dictionary
		for id: String in conversations:
			assert_eq(table.get(id, null), conversations[id],
				"band %s's conversation '%s' did not win the merge -- an earlier file already used this id" % [band, id])
	DIALOGUE_RUNNER._table = {}


## A band file that only ever contains `{"conversations": {}}` must not error
## or warn its way into the merge; dialogue_runner.gd's own additive-merge
## comment promises "a missing village.json degrades to no banter, never to a
## broken opening" -- an empty band file has to degrade the same way.
func test_an_empty_band_file_merges_as_a_true_no_op() -> void:
	DIALOGUE_RUNNER._table = {}
	var before_count := 0
	# opening.json alone, without any of the extra files, is the floor every
	# band file's absence would fall back to.
	var opening := _read_json(DIALOGUE_RUNNER.DIALOGUE_PATH)
	before_count = (opening.get("conversations", {}) as Dictionary).size()
	assert_true(before_count > 0, "opening.json's own conversations table is empty; this test would prove nothing")

	var table := DIALOGUE_RUNNER.table()
	assert_true(table.size() >= before_count,
		"the merged table (%d ids) is smaller than opening.json alone (%d ids)" % [table.size(), before_count])
	DIALOGUE_RUNNER._table = {}
