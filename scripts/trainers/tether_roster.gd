extends RefCounted

## Put the Meadows legendary into the species table.
##
## THIS FILE IS A SEAM AND SHOULD BE DELETED. Read the header of
## `data/trainers/species_addendum.json` first; the short version is that
## `data/pals/species.json` belonged to another agent for the whole of M13/M14,
## and the legendary cannot be a made-up object that only the Warden knows
## about — it joins the party, it is written to the save, and
## `pal_instance.from_record()` rebuilds a saved pal by asking
## `pal_species.spawn()` for its id. A species that is not in the table would
## produce a legendary that joins, saves, and is silently gone on the next load.
##
## So the addendum's entries are merged into the live table. Three rules make
## that safe enough to ship:
##
##   1. IT NEVER OVERWRITES. An id that `species.json` already defines is left
##      exactly as `species.json` defines it, and this says so. The day the
##      legendary is moved into that file properly, this becomes a no-op rather
##      than a fight between two definitions.
##   2. IT IS IDEMPOTENT. Called from two places on purpose (see below) and safe
##      to call from a third.
##   3. IT RUNS BEFORE ANY SAVE IS RESTORED. `encounter_director._ready()` calls
##      it SYNCHRONOUSLY, and `save_director` — which is the scene's first child
##      — waits a process frame before restoring. So the table is complete
##      before a record is ever looked up. That ordering is asserted by
##      tests/test_trainer_battle.gd rather than trusted.
##
## Merging into `pal_species.table()` works because that function returns the
## cached Dictionary itself. That is a real dependency on another file's
## internals and it is why this is one small file with a loud name rather than
## three lines hidden in a Node.

const SPECIES := preload("res://scripts/pals/pal_species.gd")
const ADDENDUM_PATH := "res://data/trainers/species_addendum.json"

static var _registered: bool = false


## Merge the addendum. Returns the ids it actually added.
static func register() -> PackedStringArray:
	var added := PackedStringArray()
	if _registered:
		return added

	var file := FileAccess.open(ADDENDUM_PATH, FileAccess.READ)
	if file == null:
		push_error("no species addendum at %s; the legendary will not exist" % ADDENDUM_PATH)
		return added
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("%s did not parse as a JSON object" % ADDENDUM_PATH)
		return added

	# Asked for BEFORE anything is written, so the table is loaded from
	# species.json first and this is genuinely an addendum rather than a race.
	var table: Dictionary = SPECIES.table()
	if table.is_empty():
		push_error("the species table is empty; refusing to register the legendary into nothing")
		return added

	var entries: Dictionary = (parsed as Dictionary).get("species", {})
	for id: String in entries.keys():
		if id.begins_with("_"):
			continue
		if table.has(id):
			# The good ending: somebody moved it into species.json. Say so, so the
			# next person knows this file is now deletable.
			print("[tether] species.json already defines '%s'; the addendum is redundant and this file can go" % id)
			continue
		table[id] = entries[id]
		added.append(id)

	_registered = true
	if added.size() > 0:
		print("[tether] registered %d species not in species.json: %s" % [
			added.size(), ", ".join(added)
		])
	return added


static func is_registered() -> bool:
	return _registered


## For tests that want to prove the merge from a clean state.
static func forget() -> void:
	_registered = false
