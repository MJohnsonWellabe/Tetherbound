extends RefCounted

## Coordinator ruling: high-frequency kinds in a character's shared
## transaction_receipts stay bounded, so a long clear never reaches the 4096
## cap (after which every foundation action refuses receipt_budget).
##
## Each kind keeps only its newest N receipts (data/config/receipt_windows.json);
## care keeps only the current host day. Receipts are appended in order, so the
## front is the oldest. Why an evicted receipt cannot pay twice:
## - essence_spend, station_craft: a client request; character authority stages
##   only at the current character revision with `before` equal to the live
##   record, so a resend of an old request is refused stale.
## - care: keyed by host day; only today's receipts can match a new request.
## - groom: keyed by creature and day through F27's care receipt; an old day's
##   groom cannot be re-staged today.
## - bounty_decision: rotations are guarded by the board's anchor day, claims by
##   the permanent bounty_receipts list and the current board.
## - wild_defeat, trainer_round, shed_win: host-presented combat outcomes, offered
##   only while their duty is unsettled (retries within the same fight's
##   settlement). A window of 1024 newer outcomes of the same kind is a recency
##   margin far beyond any retry, not a construction-level proof.
## Once-ever kinds are never touched.

const DATA := preload("res://scripts/data/redesign_data.gd")
const CONFIG := "res://data/config/receipt_windows.json"


static func window(kind: String) -> int:
	var raw: Variant = DATA.json(CONFIG)
	return int((raw as Dictionary).get(kind, 0)) if raw is Dictionary else 0


## Whether `receipt` belongs to `kind` for this character.
static func is_kind(receipt: String, kind: String, character_id: String) -> bool:
	match kind:
		"essence_spend": return receipt.begins_with("essence_spend:%s:" % character_id)
		"wild_defeat": return receipt.begins_with("defeat:%s:" % character_id)
		"trainer_round": return receipt.begins_with("defeat:trainer_round_") and receipt.ends_with(":" + character_id)
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


## `receipts` without this character's care receipts from host days before
## `host_day` (the daily cap reads only today's).
static func compact_care(receipts: Array, character_id: String, host_day: int) -> Array:
	var prefix := "care:%s:" % character_id
	var out: Array = []
	for raw: Variant in receipts:
		var text := str(raw)
		if text.begins_with(prefix):
			var day := text.substr(prefix.length()).get_slice(":", 0)
			if day.is_valid_int() and int(day) < host_day: continue
		out.append(raw)
	return out
