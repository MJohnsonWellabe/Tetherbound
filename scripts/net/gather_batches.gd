extends RefCounted

## Coordinator ruling (b): a guest's frequent gathers pay into the host's
## character authority through one journaled reward delivery per BATCH.
##
## Durable world carrier: redesign_world.gather_batches[character_id] =
##   {next_seq, hits, open: {item: n}, replayed: [seq]}
## (optional schema key; a v28 world without it is an empty map).
## - gather_accrue adds one gather to the open batch.
## - gather_flush journals the open batch as reward delivery
##   "gather_batch:<seq>" and opens the next sequence.
## - A row is pruned only when THAT row is both accepted (the guest saved and
##   ACKed it) and listed in `replayed` (the host's owner-passive replay
##   credited it to the character authority, which happens only once the guest
##   actually settled it into its satchel). Per-row, so an unsettled earlier
##   batch (a full bag) is never swept by a later one (review B1).
## Exactly-once: each seq is one delivery id; the guest's escrow refuses a
## second application of the same id, and the guest prunes an escrow row only
## when the host's row for it is gone in the same world (review B2).

const DATA := preload("res://scripts/data/redesign_data.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")
const CONFIG := "res://data/config/gather_batching.json"
const SOURCE_PREFIX := "gather_batch:"
const FIELD := "gather_batches"
const MAX_REPLAYED := 64
const MAX_STACKS := 24

static var _config_cache: Dictionary = {}


static func config() -> Dictionary:
	if _config_cache.is_empty():
		var raw: Variant = DATA.json(CONFIG)
		_config_cache = raw if raw is Dictionary else {"enabled": false}
	return _config_cache


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
	return {"next_seq": 1, "hits": 0, "open": {}, "replayed": []}


## The character's batch with integral counts (a JSON reload reads numbers back
## as floats); an empty batch when there is none; {} when the stored row is
## corrupt (never silently reset, which would reuse delivery ids).
static func batch(redesign_world: Dictionary, character_id: String) -> Dictionary:
	var all: Variant = redesign_world.get(FIELD, {})
	if not all is Dictionary or not (all as Dictionary).has(character_id): return empty_batch()
	var row: Variant = all[character_id]
	if not batch_valid(row): return {}
	var out := {"next_seq": int(row.next_seq), "hits": int(row.hits), "open": {}, "replayed": []}
	for item: String in row.open: out.open[item] = int(row.open[item])
	for seq: Variant in row.replayed: out.replayed.append(int(seq))
	return out


static func batch_valid(row: Variant) -> bool:
	if not row is Dictionary or row.size() != 4: return false
	if not _int(row.get("next_seq")) or not _int(row.get("hits")) or int(row.next_seq) < 1 or int(row.hits) < 0: return false
	if not row.get("open") is Dictionary or not row.get("replayed") is Array: return false
	for item: Variant in row.open:
		if not item is String or (item as String).is_empty() or not _int(row.open[item]) or int(row.open[item]) < 1: return false
	if (row.replayed as Array).size() > MAX_REPLAYED: return false
	for seq: Variant in row.replayed:
		if not _int(seq) or int(seq) < 1 or int(seq) >= int(row.next_seq): return false
	return (row.open as Dictionary).is_empty() == (int(row.hits) == 0)


## How many satchel stacks this open map flushes as, or -1 when invalid.
static func stack_count(open: Dictionary) -> int:
	var n := 0
	for item: String in open:
		var part := REWARD_DELIVERY.make_record("w", "n", "probe", "c", item, int(open[item]))
		if part.is_empty(): return -1
		n += (part.stacks as Array).size()
	return n


## The open batch after one more gather, or {} when it cannot accept it: the
## flush would exceed one delivery's stacks, or the batch is far past its
## flush size (repeated failed saves); the gather is then refused, never taken
## and left unpaid (review S4).
static func accrued(row: Dictionary, item: String, count: int) -> Dictionary:
	if not batch_valid(row) or item.is_empty() or count < 1: return {}
	if int(row.hits) >= max_hits() * 4: return {}
	var next := row.duplicate(true)
	next.open[item] = int(next.open.get(item, 0)) + count
	var stacks := stack_count(next.open)
	if stacks < 0 or stacks > MAX_STACKS: return {}
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
	if delivery.is_empty() or stacks.size() > MAX_STACKS: return {}
	delivery.stacks = stacks
	return delivery


static func flushed(row: Dictionary) -> Dictionary:
	var next := row.duplicate(true)
	next.next_seq = int(row.next_seq) + 1
	next.hits = 0
	next.open = {}
	return next


## The batch with `seq` recorded as credited by the host's replay, or {} when
## the seq was never flushed or the list is full.
static func replayed_marked(row: Dictionary, seq: int) -> Dictionary:
	if not batch_valid(row) or seq < 1 or seq >= int(row.next_seq): return {}
	var next := row.duplicate(true)
	if not next.replayed.has(seq):
		if next.replayed.size() >= MAX_REPLAYED: return {}
		next.replayed.append(seq)
	return next


## The id of this character's batch row `seq`, or "" when it is not journaled.
static func row_id(reward_deliveries: Dictionary, character_id: String, seq: int) -> String:
	for id: Variant in reward_deliveries:
		var delivery: Variant = reward_deliveries[id]
		if delivery is Dictionary and str(delivery.get("character_id", "")) == character_id \
				and seq_of(str(delivery.get("source", ""))) == seq:
			return str(id)
	return ""


## Prune every row that is both accepted and replayed; returns
## [next batch, ids to erase].
static func pruned(reward_deliveries: Dictionary, character_id: String, row: Dictionary) -> Array:
	var next := row.duplicate(true)
	var erase: Array[String] = []
	for seq: int in row.replayed:
		var id := row_id(reward_deliveries, character_id, seq)
		if id.is_empty():
			next.replayed.erase(seq) # Already gone; nothing left to wait for.
		elif str(reward_deliveries[id].get("status", "")) == "accepted":
			erase.append(id)
			next.replayed.erase(seq)
	return [next, erase]


## Guest: escrow ids of this character's settled batch rows from THIS world
## (namespace) whose host row is already gone (review B2).
static func guest_prunable(escrow: Dictionary, reward_deliveries: Dictionary, world_namespace: String, character_id: String) -> Array[String]:
	var out: Array[String] = []
	if world_namespace.is_empty(): return out
	for id: Variant in escrow:
		var entry: Variant = escrow[id]
		if entry is Dictionary and str(entry.get("status", "")) == "settled" \
				and str(entry.get("character_id", "")) == character_id \
				and seq_of(str(entry.get("source", ""))) >= 1 \
				and str(entry.get("world_namespace", "")) == world_namespace \
				and not reward_deliveries.has(id):
			out.append(str(id))
	return out


static func _int(value: Variant) -> bool:
	return (value is int) or (value is float and is_finite(value) and float(value) == floor(float(value)))
