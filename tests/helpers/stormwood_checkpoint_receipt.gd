extends RefCounted

## Read-back of the copied checkpoint's authoritative split character. This
## is file persistence evidence, not an in-world reload or a new save writer.
const OWNER_FIELDS := ["character_id", "party", "inventory", "redesign_character",
	"flags", "realm", "pending_realm_entry", "realm_hearts"]

static func saved_owner_error(pair: Dictionary, expected: Dictionary) -> String:
	if pair.get("state") != "split" or not pair.get("character") is Dictionary:
		return "Copied checkpoint has no readable authoritative split character"
	var saved: Dictionary = pair.character
	if str(expected.get("character_id", "")).is_empty() \
			or pair.get("character_id") != expected.get("character_id"):
		return "Copied checkpoint selects a different character"
	for field: String in OWNER_FIELDS:
		if not expected.has(field) or not saved.has(field):
			return "Copied checkpoint lacks owner field " + field
		# Disk JSON integral numbers are floats; normalize both sides exactly as
		# the chapter handoff comparison does before comparing complete fields.
		if JSON.stringify(JSON.parse_string(JSON.stringify(saved[field]))) \
				!= JSON.stringify(JSON.parse_string(JSON.stringify(expected[field]))):
			return "Copied checkpoint changed owner field " + field
	return ""
