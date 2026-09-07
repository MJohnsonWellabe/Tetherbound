extends RefCounted

## Repairs the Cloudreach finale's pre-Stormwood entitlement names without
## making a save-format version carry gameplay history.  The marker is a world
## flag, so it travels through both the flat v22 payload and world.json's
## `flags: {"flags": Array[String]}` shape.

const LEGACY_KEY := "realm_key_water"
const LEGACY_REVEAL := "waterward_route_revealed"
const STORMWOOD_KEY := "realm_key_stormwood"
const STORMWOOD_REVEAL := "stormward_route_revealed"
const MARKER := "cloudreach_reward_retargeted_stormwood"
const CLOUDREACH_COMPLETE := "cloudreach_chapter_complete"

## A later Stormwood finale may legitimately award Water access.  These flags
## are provenance, not aliases: leave its Water entitlement intact.
const LATER_WATER_SOURCES: Array[String] = [
	"stormwood:chapter_complete",
	"stormwood:waterward_revealed",
]


## Return a copy of a legacy flat save payload with only its earned Cloudreach
## finale aliases retargeted.  Invalid/missing flag stores remain untouched.
static func repair_flat_payload(payload: Dictionary) -> Dictionary:
	var out := payload.duplicate(true)
	var progression: Variant = out.get("progression")
	if not (progression is Dictionary):
		return out
	var repaired := repair_flag_store(progression as Dictionary)
	if repaired != progression:
		out["progression"] = repaired
	return out


## Same repair for the state returned by WorldSave.state(), where world flags
## already live under `flags` rather than flat `progression`.
static func repair_world_state_payload(payload: Dictionary) -> Dictionary:
	var out := payload.duplicate(true)
	var flags: Variant = out.get("flags")
	if not (flags is Dictionary):
		return out
	var repaired := repair_flag_store(flags as Dictionary)
	if repaired != flags:
		out["flags"] = repaired
	return out


## Pure and idempotent.  Completion is the evidence that these were earned;
## neither a partial Cloudreach run nor a later Water reward is rewritten.
static func repair_flag_store(store: Dictionary) -> Dictionary:
	var raw: Variant = store.get("flags")
	if not (raw is Array):
		return store
	var ids: Array = raw as Array
	if not ids.has(CLOUDREACH_COMPLETE):
		return store
	if ids.has(MARKER) or _has_later_water_source(ids):
		return store
	if not ids.has(LEGACY_KEY) and not ids.has(LEGACY_REVEAL):
		return store

	var repaired: Array = []
	for id: Variant in ids:
		if id == LEGACY_KEY or id == LEGACY_REVEAL:
			continue
		repaired.append(id)
	_add_once(repaired, STORMWOOD_KEY)
	_add_once(repaired, STORMWOOD_REVEAL)
	_add_once(repaired, MARKER)
	var out := store.duplicate(true)
	out["flags"] = repaired
	return out


static func _has_later_water_source(ids: Array) -> bool:
	for id: String in LATER_WATER_SOURCES:
		if ids.has(id):
			return true
	return false


static func _add_once(ids: Array, id: String) -> void:
	if not ids.has(id):
		ids.append(id)
