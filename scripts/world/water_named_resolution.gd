extends RefCounted
## Co-op carrier for Tidewake named-encounter completion flags.
##
## The shared encounter director records a named catch/defeat through
## `_mark_once_cleared()`, which (outside `warrens_cleared`) writes straight to
## this peer's merged progression. On a CLIENT that lands only in its local
## mirror of the world store and never reaches the host; on the HOST in a
## multi-peer session it lands in host truth but no ledger delta tells clients.
## Water gates (the Deep Watch Candy III cache, the chart control, Orsen's lead)
## read these world flags, so this relay forwards each local 0->1 transition
## once: a client submits the already-permitted `set_world_flag` intent, and the
## host publishes the flag op to peers. Flags present at baseline (save/snapshot)
## or already carried by a world delta are never re-sent.
const ENCOUNTERS := "res://data/config/water_encounters.json"
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

var flags: Array[String] = []
var _known: Dictionary = {}


func _init() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENCOUNTERS))
	if not data is Dictionary:
		return
	for named: Variant in (data as Dictionary).get("named_encounters", []):
		if named is Dictionary:
			var flag := str((named as Dictionary).get("completion_flag", ""))
			# Only a declared WORLD fact may be forwarded as one. On main the
			# other four named completion flags have no declared scope yet.
			if not flag.is_empty() and not flags.has(flag) \
					and PROGRESSION_STATE.scope_of(flag) == PROGRESSION_STATE.SCOPE_WORLD:
				flags.append(flag)


## Everything already true when the scene starts or a snapshot/load lands is
## host knowledge, not a new local resolution.
func baseline(world_flags: Variant) -> void:
	_known.clear()
	if world_flags == null:
		return
	for flag: String in flags:
		if world_flags.has(flag):
			_known[flag] = true


## A committed world delta (host commit, host publish or client receipt) already
## carries the fact to every peer.
func note_delta(delta: Dictionary) -> void:
	for op: Variant in delta.get("ops", []):
		if op is Dictionary and str(op.get("op", "")) == "flag" and str(op.get("scope", "")) == "world" \
				and bool(op.get("value", false)) and flags.has(str(op.get("id", ""))):
			_known[str(op.id)] = true


## Named flags set locally since baseline that no delta has carried. Each is
## returned once; the caller forwards it.
func pending(world_flags: Variant) -> Array[String]:
	var out: Array[String] = []
	if world_flags == null:
		return out
	for flag: String in flags:
		if not _known.has(flag) and world_flags.has(flag):
			_known[flag] = true
			out.append(flag)
	return out


static func flag_op(flag: String) -> Dictionary:
	return {"op": "flag", "scope": "world", "realm": "water", "id": flag, "value": true}
