extends Node

## The one thing in the game that writes a save file.
##
## `structures.gd` got there first and owned `user://structures.json` outright:
## its own path, its own version constant, its own parse and its own refusal
## logic. That shape works exactly once. The second system needing persistence
## copies it, and then a player's world is several files that can silently
## disagree about which build wrote them — a party from this build sitting
## beside structures from the last one, with nothing in either file able to
## notice. `TECHNICAL_START.md` §Save Requirements lists fourteen things to
## persist; fourteen files with fourteen version numbers is not a save system.
##
## So: ONE envelope per slot, ONE version number, and systems REGISTER into it.
## Adding persistence to a new system is a `register()` call and two methods on
## the system itself, never a new file and never a new version number.
##
## A contributor is any object with:
##   `save_data() -> Dictionary`   what to write under its domain key
##   `load_data(Dictionary) -> void`   put it back
##
## Deliberately not `Resource`/`ResourceSaver`: the save has to survive a script
## being renamed or a class disappearing, and a binary resource that names its
## own script cannot. JSON is greppable, diffable, and hand-editable while the
## slice is being tuned, which matters more right now than a few kilobytes.

## Bumped when ANY domain changes its record shape, so an old file is refused
## whole rather than half-read. One number for the whole envelope is the point:
## per-domain versions would let a file be partly current, which is the exact
## state nobody can reason about.
const SAVE_VERSION := 1

const SLOT_PATH := "user://save_%d.json"

## The envelope's own key. A domain may not be called this, or it would
## overwrite the version and the file would then read as version 0 forever.
const VERSION_KEY := "version"

signal saved(slot: int)
signal loaded(slot: int)

## `domain name -> contributor`.
var _contributors: Dictionary = {}


## Take part in every future save. Idempotent: registering the same domain
## again just repoints it, so a caller may re-register defensively without
## having to remember whether it already did.
##
## Callers DO re-register defensively. Under `--script` (which is how every
## test and smoke runs) autoloads are attached to the tree only after the
## script's `_init()` returns, so a smoke that instantiates its world inside
## `_init()` reaches `_ready()` on its nodes before this singleton exists. A
## contributor that registered only in `_ready()` would be quietly absent from
## its own save file. Cheaper to allow a second call than to order the boot.
func register(domain: String, contributor: Object) -> void:
	if domain.is_empty() or domain == VERSION_KEY:
		push_error("'%s' is not a usable save domain name" % domain)
		return
	if contributor == null:
		push_error("save domain '%s' was registered with nothing" % domain)
		return
	if not contributor.has_method("save_data") or not contributor.has_method("load_data"):
		push_error("save domain '%s' needs save_data() and load_data()" % domain)
		return
	_contributors[domain] = contributor


func unregister(domain: String) -> void:
	_contributors.erase(domain)


func is_registered(domain: String) -> bool:
	return _contributors.has(domain)


## Registered domain names, in registration order.
func domains() -> Array[String]:
	var out: Array[String] = []
	out.assign(_contributors.keys())
	return out


func slot_path(slot: int) -> String:
	return SLOT_PATH % slot


func has_slot(slot: int = 0) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func delete_slot(slot: int = 0) -> bool:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	# Globalised, because `DirAccess.remove_absolute` wants a real filesystem
	# path and will not resolve `user://` for you.
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK


## Write every registered domain into one file. Returns false if it did not land
## on disk, so a caller can tell the player rather than assume.
##
## Only registered domains are written. A domain that used to be in the file and
## is no longer registered is DROPPED, and warned about rather than carried
## forward invisibly: silently preserving data for a system that no longer
## exists is how a save file accumulates ghosts nobody can account for.
func save(slot: int = 0) -> bool:
	var envelope: Dictionary = {VERSION_KEY: SAVE_VERSION}
	for domain: String in _contributors:
		var contributor: Object = _contributors[domain]
		if not is_instance_valid(contributor):
			push_warning("save domain '%s' has gone away; skipping it" % domain)
			continue
		var data: Variant = contributor.call("save_data")
		if not data is Dictionary:
			push_warning("save domain '%s' did not return a Dictionary; skipping it" % domain)
			continue
		envelope[domain] = data

	_warn_about_dropped_domains(slot, envelope)

	var path := slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("could not write save to %s" % path)
		return false
	# Indented and key-sorted: a save whose byte order depends on which system
	# happened to register first cannot be diffed between two runs, and diffing
	# two runs is how a persistence bug gets found.
	file.store_string(JSON.stringify(envelope, "  ", true))
	file.close()
	saved.emit(slot)
	return true


## Put a slot back into the registered domains. Returns true only if something
## was actually applied.
##
## Nothing is handed to any contributor until the whole file has parsed and its
## version has been accepted, so a bad file leaves the running game exactly as
## it was. `structures.gd.load_saved()` established that discipline and the
## reason is the same: a half-applied load is worse than no load, because it
## looks like a working game with one system's state from another era.
func load_slot(slot: int = 0) -> bool:
	var path := slot_path(slot)
	# An absent slot is not an error. "New game" and "slot 3 is empty" both come
	# through here, and neither is worth a red line in the console.
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("save %s exists but could not be opened; loading nothing" % path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("save %s is not readable; loading nothing" % path)
		return false

	var envelope: Dictionary = parsed
	var version := int(envelope.get(VERSION_KEY, 0))
	if version != SAVE_VERSION:
		push_warning("save %s is version %d, this build writes %d; ignoring it" % [
			path, version, SAVE_VERSION
		])
		return false

	for domain: String in _contributors:
		# A domain missing from the file is left alone rather than handed an
		# empty dictionary. The version gate above already guarantees the file
		# is this build's shape, so an absent key means that system genuinely
		# had nothing to say — not that it should be wiped.
		if not envelope.has(domain):
			continue
		var contributor: Object = _contributors[domain]
		if not is_instance_valid(contributor):
			push_warning("save domain '%s' has gone away; skipping it" % domain)
			continue
		var data: Variant = envelope[domain]
		if not data is Dictionary:
			push_warning("save domain '%s' in %s is not a Dictionary; skipping it" % [domain, path])
			continue
		contributor.call("load_data", data as Dictionary)

	loaded.emit(slot)
	return true


func _warn_about_dropped_domains(slot: int, envelope: Dictionary) -> void:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	for domain: String in (parsed as Dictionary).keys():
		if domain != VERSION_KEY and not envelope.has(domain):
			push_warning("save domain '%s' was in %s and is not registered now; it will be lost" % [
				domain, path
			])
