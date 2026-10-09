extends RefCounted

## Coordinator ruling: high-frequency kinds in a character's shared
## transaction_receipts stay bounded, so a long clear never reaches the 4096
## cap (after which every foundation action refuses receipt_budget).
##
## Each kind keeps only its newest N receipts (data/config/receipt_windows.json).
## Receipts are appended in order, so the front is the oldest. Combat mastery
## and trainer rounds are retained world duties: they are windowed only because
## an accepted duty is now settled durably in the world (retained_settlement.gd,
## ruling R2), so the retry loop never re-stages one whose receipt was evicted
## (review R1). NOT windowed: care retains its paying calendar anchor. Legacy
## five-field receipts also remain exact (review R4).
## Why an evicted receipt cannot pay twice:
## - essence_spend, station_craft: a client request; character authority stages
##   only at the current character revision with `before` equal to the live
##   record, so a resend of an old request is refused stale.
## - groom: keyed by creature and day through F27's care receipt; an old day's
##   groom cannot be re-staged today.
## - bounty_decision: rotations are guarded by the board's anchor day, claims by
##   the permanent bounty_receipts list and the current board.
## - wild_defeat, shed_win: host-presented wild outcomes, retried only within
##   the live in-memory encounter (no retained world duty); a window of 1024
##   newer outcomes is a recency margin far beyond any retry.
## - station_craft also matches feast cooks (same craft:<c>:<32 hex> shape),
##   which share the same stale-revision guard.
## Once-ever kinds are never touched.

const DATA := preload("res://scripts/data/redesign_data.gd")
const CONFIG := "res://data/config/receipt_windows.json"


static var _config_cache: Dictionary = {}


## Rest anchors are not recency windows: the generation survives every other
## kind's compaction. Absent anchors are the legacy state (generation zero).
static func rest_decimal(raw: String) -> int:
	if raw.is_empty() or raw.length() > 10 or not raw.is_valid_int(): return -1
	var value := raw.to_int()
	return value if value >= 0 and value <= 2147483646 and str(value) == raw else -1


static func rest_marker_valid(raw: String) -> bool:
	var fields := raw.split(":")
	if fields.size() == 3 and fields[0] in ["rest_complete", "rest_discovery"]:
		return not fields[1].is_empty() and fields[2].length() == 64 and fields[2].to_lower() == fields[2] and fields[2].is_valid_hex_number(false)
	if fields.size() < 4 or fields[1].is_empty() or fields[1].length() > 128 \
		or fields[1] != fields[1].strip_edges() or fields[1].contains("\n") or fields[1].contains("\r") \
		or rest_decimal(fields[2]) < 0 or fields[3].length() != 64: return false
	for letter: String in fields[3]:
		if not "0123456789abcdef".contains(letter): return false
	if fields[0] == "rest_activity": return fields.size() == 4 and rest_decimal(fields[2]) > 0
	if fields[0] == "rest_award": return fields.size() == 5 and rest_decimal(fields[4]) > 0
	return false


static func window(kind: String) -> int:
	if _config_cache.is_empty():
		var raw: Variant = DATA.json(CONFIG)
		_config_cache = raw if raw is Dictionary else {"_unavailable": true}
	return int(_config_cache.get(kind, 0))


## Whether `receipt` belongs to `kind` for this character.
static func is_kind(receipt: String, kind: String, character_id: String) -> bool:
	match kind:
		"essence_spend": return receipt.begins_with("essence_spend:%s:" % character_id)
		"wild_defeat": return receipt.begins_with("defeat:%s:" % character_id)
		"shed_win": return receipt.begins_with("craft:%s:shed_win:" % character_id)
		"combat_mastery": return receipt.begins_with("craft:combat_mastery_") and receipt.ends_with(":" + character_id)
		"trainer_round": return receipt.begins_with("defeat:trainer_round_") and receipt.ends_with(":" + character_id)
		"groom": return receipt.begins_with("groom:")
		"bounty_decision": return (receipt.begins_with("bounty:clock_") or receipt.begins_with("bounty:event_")) and receipt.ends_with(":" + character_id)
		"station_craft":
			var prefix := "craft:%s:" % character_id
			if not receipt.begins_with(prefix): return false
			var tail := receipt.substr(prefix.length())
			if tail.length() != 32: return false
			for c: String in tail:
				if not "0123456789abcdef".contains(c): return false
			return true
	return false


## `receipts` with the oldest of this kind dropped so at most `window - 1`
## remain (room for the receipt about to be appended). An unset window (< 2)
## leaves them untouched.
static func compact(receipts: Array, kind: String, character_id: String) -> Array:
	var size := window(kind)
	if size < 2: return receipts
	var drop := -(size - 1)
	for raw: Variant in receipts:
		if is_kind(str(raw), kind, character_id): drop += 1
	if drop <= 0: return receipts
	var out: Array = []
	for raw: Variant in receipts:
		if drop > 0 and is_kind(str(raw), kind, character_id):
			drop -= 1
			continue
		out.append(raw)
	return out
