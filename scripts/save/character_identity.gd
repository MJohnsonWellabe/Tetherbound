extends RefCounted

## Stable portable identity is independent of a save slot, process id, world,
## or transport peer. Sixteen random bytes keep independently-created
## characters distinct while remaining safe as a save-directory name.

const PREFIX := "character-"
const RANDOM_BYTES := 16
const MAX_LENGTH := 128


static func mint() -> String:
	var random := Crypto.new().generate_random_bytes(RANDOM_BYTES)
	if random.size() != RANDOM_BYTES:
		return ""
	return PREFIX + random.hex_encode()


## Existing slot-based and explicitly-authored ids remain valid. This slice
## changes creation, not legacy ownership or journal identities.
static func is_valid(id: String) -> bool:
	if id.is_empty() or id.length() > MAX_LENGTH:
		return false
	for code: int in id.to_utf8_buffer():
		var valid := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) \
			or (code >= 97 and code <= 122) or code == 45 or code == 95
		if not valid:
			return false
	return true
