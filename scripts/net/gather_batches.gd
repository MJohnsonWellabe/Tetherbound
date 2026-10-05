extends RefCounted

## Coordinator ruling (b): a guest's frequent gathers pay into the host's
## character authority through one journaled reward delivery per BATCH.
##
## Durable world carrier: redesign_world.gather_batches[character_id] =
##   {next_seq, acked, replayed, hits, open: {item: n}}
## (optional schema key; a v28 world without it is an empty map).
## - gather_accrue adds one gather to the open batch.
## - gather_flush journals the open batch as reward delivery
##   "gather_batch:<seq>" and opens the next sequence.
## - gather_mark advances `acked` (the guest saved and ACKed the delivery) or
##   `replayed` (the host's owner-passive replay credited it to the character
##   authority). A row is pruned only at or below BOTH marks: the ACK closes
##   redelivery, and the replay still looks the row up by id until it has run.
## Exactly-once: each seq is one delivery id; the guest's escrow refuses a
## second application of the same id, and pruned seqs are below the marks.

const DATA := preload("res://scripts/data/redesign_data.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")
const CONFIG := "res://data/config/gather_batching.json"
const SOURCE_PREFIX := "gather_batch:"
const FIELD := "gather_batches"


static func config() -> Dictionary:
	var raw: Variant = DATA.json(CONFIG)
	return raw if raw is Dictionary else {}


static func enabled() -> bool:
	return config().get("enabled") == true


static func max_hits() -> int:
	return maxi(1, int(config().get("max_hits", 8)))


static func flush_seconds() -> float:
	return maxf(0.1, float(config().get("flush_seconds", 1.5)))


static func source(seq: int) -> String:
	return SOURCE_PREFIX + str(seq)


## The batch seq a delivery source names, or -1.
static func seq_of(delivery_source: String) -> int:
	if not delivery_source.begins_with(SOURCE_PREFIX): return -1
	var tail := delivery_source.substr(SOURCE_PREFIX.length())
	return int(tail) if tail.is_valid_int() and int(tail) >= 1 else -1


static func empty_batch() -> Dictionary:
	return {"next_seq": 1, "acked": 0, "replayed": 0, "hits": 0, "open": {}}


## The character's batch with integral counts (a JSON reload reads numbers
## back as floats), or an empty batch.
static func batch(redesign_world: Dictionary, character_id: String) -> Dictionary:
	var all: Variant = redesign_world.get(FIELD, {})
	var row: Variant = all.get(character_id) if all is Dictionary else null
	if not row is Dictionary or not batch_valid(row): return empty_batch()
	var out := {"next_seq": int(row.next_seq), "acked": int(row.acked), "replayed": int(row.replayed),
		"hits": int(row.hits), "open": {}}
	for item: String in row.open: out.open[item] = int(row.open[item])
	return out


static func batch_valid(row: Variant) -> bool:
	if not row is Dictionary or row.size() != 5: return false
	for key: String in ["next_seq", "acked", "replayed", "hits"]:
		if not _int(row.get(key)): return false
	if int(row.next_seq) < 1 or int(row.acked) < 0 or int(row.replayed) < 0 or int(row.hits) < 0 \
		or int(row.acked) >= int(row.next_seq) or int(row.replayed) >= int(row.next_seq): return false
	if not row.get("open") is Dictionary: return false
	for item: Variant in row.open:
		if not item is String or (item as String).is_empty() or not _int(row.open[item]) or int(row.open[item]) < 1: return false
	return (row.open as Dictionary).is_empty() == (int(row.hits) == 0)


## The open batch after one more gather, or {} when it cannot accept it.
static func accrued(row: Dictionary, item: String, count: int) -> Dictionary:
	if not batch_valid(row) or item.is_empty() or count < 1: return {}
	var next := row.duplicate(true)
	if not next.open.has(item) and next.open.size() >= int(config().get("max_open_items", 24)): return {}
	next.open[item] = int(next.open.get(item, 0)) + count
	next.hits = int(next.hits) + 1
	return next


## The reward delivery that flushes this open batch, or {} when it is empty.
static func flush_delivery(row: Dictionary, world_id: String, world_namespace: String, character_id: String) -> Dictionary:
	if not batch_valid(row) or (row.open as Dictionary).is_empty() or world_id.is_empty() or world_namespace.is_empty(): return {}
	var items: Array = (row.open as Dictionary).keys()
	items.sort()
	var stacks: Array = []
	for item: String in items:
		var part := REWARD_DELIVERY.make_record(world_id, world_namespace, "probe", character_id, item, int(row.open[item]))
		if part.is_empty(): return {}
		stacks.append_array(part.stacks)
	var delivery := REWARD_DELIVERY.make_record(world_id, world_namespace, source(int(row.next_seq)), character_id, "", 0)
	if delivery.is_empty() or stacks.size() > 24: return {}
	delivery.stacks = stacks
	return delivery


static func flushed(row: Dictionary) -> Dictionary:
	var next := row.duplicate(true)
	next.next_seq = int(row.next_seq) + 1
	next.hits = 0
	next.open = {}
	return next


## The batch with `mark` ("acked" or "replayed") advanced to `seq`; marks never
## regress and never pass a seq that was not flushed yet.
static func marked(row: Dictionary, mark: String, seq: int) -> Dictionary:
	if not batch_valid(row) or not mark in ["acked", "replayed"] or seq < 1 or seq >= int(row.next_seq): return {}
	var next := row.duplicate(true)
	next[mark] = maxi(int(row[mark]), seq)
	return next


## Delivery ids of this character's settled batches at or below both marks.
static func prunable(reward_deliveries: Dictionary, character_id: String, row: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var floor_seq := mini(int(row.get("acked", 0)), int(row.get("replayed", 0)))
	for id: Variant in reward_deliveries:
		var delivery: Variant = reward_deliveries[id]
		if not delivery is Dictionary or str(delivery.get("character_id", "")) != character_id: continue
		var seq := seq_of(str(delivery.get("source", "")))
		if seq >= 1 and seq <= floor_seq and str(delivery.get("status", "")) == "accepted":
			out.append(str(id))
	return out


static func _int(value: Variant) -> bool:
	return (value is int) or (value is float and is_finite(value) and float(value) == floor(float(value)))
