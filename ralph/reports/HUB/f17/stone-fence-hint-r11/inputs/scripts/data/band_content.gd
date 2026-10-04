extends RefCounted

## BAND-SPLIT. One merge for every content config that is cut per corridor band.
##
## Why this exists. Every piece of Meadows content used to live in one
## top-level array in one file: `spawns.json`'s `spawns`, `props.json`'s
## `clusters`, `harvest.json`'s `nodes`, `trainers.json`'s `trainers`. The unit
## of work on this project is a BAND -- one agent authoring Band 3 -- and the
## unit of ownership was a FILE, so every band's author had to edit every file
## and collide with every other band's author on all four, continuously. This
## makes the two units the same: a band owns `data/config/bands/<band>/`, whole,
## and nothing else touches it.
##
## What stays in the head file is what is not positional: `spawns.json`'s
## `respawn_seconds` and `roles`, `trainers.json`'s `flow` and `prompts`, every
## `_comment`. Those are global. Sharding them into five copies would give five
## agents five things to drift apart, which is the opposite of the point.
##
## The merged array must be IDENTICAL to the pre-split file -- same entries,
## same order, same values -- because array position is identity here (see
## `order` below). `tests/test_band_content.gd` pins that against the
## pre-split originals in `tests/fixtures/band_split_baseline/`.

## The corridor's bands, in trail order, matching `terrain_playground.json`'s
## `trail.bands[]` ids. `tests/test_band_content.gd` asserts they still match,
## because a band added to the trail and not added here would load as an empty
## world region with no error anywhere.
##
## Deliberately a literal and not a `DirAccess` listing of `bands/`. A directory
## scan reads as more flexible and is worse in both directions: it silently
## picks up a stray or half-finished directory as if it were canon, and it
## silently loads nothing if `res://` listing behaves differently in an export
## than it does in the editor. Five ids in a const cannot do either.
const BANDS: Array[String] = [
	"band1_lower_meadows",
	"band2_stone_and_root",
	"band3_the_river_lock",
	"band4_upper_meadows_ironwood",
	"band5_stronghold_approach",
]

const BANDS_DIR := "res://data/config/bands"

## Where an entry with no `order` is put: after everything numbered, in a
## defined place rather than at a random one. Loud (it push_error()s) but not
## fatal, and above any plausible authored order.
const UNORDERED_BASE := 1000000


## Load a head config and merge its band files back into one array.
##
## `head_path` is the original file (`res://data/config/spawns.json`), which now
## carries only the non-positional keys. `array_key` is the array that was cut
## out (`"spawns"`). Returns the head dictionary with `array_key` filled in.
##
## A band with no file, or a band file with an empty array, is not an error:
## most configs are genuinely empty in most bands right now (there are no props
## at all above Band 2), and requiring five files per config would mean five
## empty files per config for no reason.
static func load_config(head_path: String, array_key: String) -> Dictionary:
	var head := _parse(head_path)
	if head.is_empty():
		return {}
	if head.has(array_key):
		# The head file is supposed to have been emptied of its positional
		# array. If one comes back it is either a bad merge or somebody
		# re-adding content to the file the split exists to stop them editing;
		# either way it would be silently concatenated with the band files and
		# shift every `order` after it.
		push_error("%s still carries a top-level '%s'; band content belongs under %s/<band>/" % [
			head_path, array_key, BANDS_DIR])

	# The file name is the same in every band directory: spawns.json's bands are
	# bands/<band>/spawns.json.
	var file_name := head_path.get_file()
	var collected: Array = []
	for band_index in BANDS.size():
		var band_path := "%s/%s/%s" % [BANDS_DIR, BANDS[band_index], file_name]
		if not FileAccess.file_exists(band_path):
			continue
		var band_doc := _parse(band_path)
		if band_doc.is_empty():
			continue
		var entries: Array = band_doc.get(array_key, []) as Array
		for file_index in entries.size():
			var entry: Variant = entries[file_index]
			if not entry is Dictionary:
				push_error("%s has a non-dictionary entry in '%s'" % [band_path, array_key])
				continue
			var spec: Dictionary = entry
			var order := UNORDERED_BASE + band_index * 10000 + file_index
			if spec.has("order"):
				order = int(spec["order"])
			else:
				push_error("%s: a '%s' entry has no `order`; it was appended at the end" % [
					band_path, array_key])
			collected.append({"order": order, "band": band_index, "file": file_index, "entry": spec})

	# Sort by `order` alone. Band order and file order are only tie-breakers, so
	# that a duplicated `order` still produces the same array on every boot
	# instead of an engine-dependent one -- a world that differs between two
	# runs of the same build is the failure this whole file is guarding.
	collected.sort_custom(_before)

	var merged: Array = []
	var seen_order := {}
	for row: Dictionary in collected:
		var order := int(row["order"])
		if seen_order.has(order):
			# Not fatal -- the sort above already made it deterministic -- but
			# for `spawns.json` two entries sharing an `order` share a seed,
			# which means two clusters scattering identically, and that is
			# invisible until somebody notices two species standing in the same
			# ring.
			push_error("%s: `order` %d is used twice (bands '%s' and '%s')" % [
				file_name, order, BANDS[int(seen_order[order])], BANDS[int(row["band"])]])
		seen_order[order] = row["band"]
		merged.append(row["entry"])

	head[array_key] = merged
	return head


static func _before(a: Dictionary, b: Dictionary) -> bool:
	if int(a["order"]) != int(b["order"]):
		return int(a["order"]) < int(b["order"])
	if int(a["band"]) != int(b["band"]):
		return int(a["band"]) < int(b["band"])
	return int(a["file"]) < int(b["file"])


static func _parse(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("band content missing at %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("%s is not a JSON object" % path)
		return {}
	return parsed
