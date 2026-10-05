extends RefCounted

## Coordinator ruling: high-frequency kinds in a character's shared
## transaction_receipts stay bounded, so a long clear never reaches the 4096
## cap (after which every foundation action refuses receipt_budget).
##
## Each kind keeps only its newest N receipts (data/config/receipt_windows.json).
## Receipts are appended in order, so the front is the oldest. NOT windowed:
## trainer rounds and combat mastery (their retained world duties count as
## settled only while the receipt exists, so evicting one re-stages the duty;
## review R1/R2) and care (its receipt carries no world namespace; review R4).
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
