extends RefCounted

## Host commit helper only. UI/VFX/number/audio events never call this.
## Character-scope uses and bounded durable event identities travel with the
## same creature UID. An imported snapshot never awards additional uses.
const CONFIG_PATH := "res://data/config/move_mastery.json"
const MOVES := preload("res://scripts/creatures/move_db.gd")
const MAX_KNOWN_MOVES := 256
const MAX_TRACKED_USES := 300
static var _loaded := false
static var _config: Dictionary = {}
static var _host_epoch: String = ""
static var _host_sequence: int = 0
static var _registered_moves: Dictionary = {}

class OwnedRecord extends RefCounted:
	var uid: String = ""
	var known_moves: Array[String] = []
	var move_mastery_uses: Dictionary = {}
	var move_mastery_receipts: Dictionary = {}

## An already validated admitted row, detached from the authority registry.
## This avoids rebuilding a species/stat instance to stage two mastery maps.
static func owned_record(row: Dictionary) -> RefCounted:
	var record := OwnedRecord.new()
	record.uid = str(row.get("uid", ""))
	for id: String in row.get("known_moves", []): record.known_moves.append(id)
	record.move_mastery_uses = (row.get("move_mastery_uses", {}) as Dictionary).duplicate(true)
	record.move_mastery_receipts = (row.get("move_mastery_receipts", {}) as Dictionary).duplicate(true)
	return record

## Import a host-authorized update without awarding a use locally. Caller
## authenticates the authority RPC and matches a live owned creature UID.
## Older reliable messages and rejoin snapshots cannot regress earned history.
static func stage_authority_update(creature: RefCounted, uses: Dictionary, receipts: Dictionary) -> Dictionary:
	if creature == null: return {"ok": false}
	var known: Array = creature.get("known_moves")
	if not valid_document(known, uses, receipts, known): return {"ok": false}
	var previous_uses: Dictionary = creature.get("move_mastery_uses")
	var previous_receipts: Dictionary = creature.get("move_mastery_receipts")
	for move: String in previous_uses:
		if int(uses.get(move, 0)) < int(previous_uses[move]): return {"ok": false}
		var before: Array = previous_receipts.get(move, [])
		var after: Array = receipts.get(move, [])
		if after.size() < before.size(): return {"ok": false}
		for index: int in before.size():
			if after[index] != before[index]: return {"ok": false}
	return {"ok": true, "uses": uses.duplicate(true), "receipts": receipts.duplicate(true)}

## Mint on the authority once per accepted action and freeze in its pending
## transaction. Encounter/body counters alone repeat after process restart;
## the fresh cryptographic process epoch prevents collisions with portable
## receipts retained from a previous world or host. Never accept a peer epoch.
static func new_action_identity(accepted_action_id: String) -> String:
	if accepted_action_id.is_empty() or accepted_action_id.length()>120: return ""
	if _host_epoch.is_empty(): _host_epoch = Crypto.new().generate_random_bytes(16).hex_encode()
	_host_sequence += 1
	# Separate allocation sequence also covers a recreated encounter/manager
	# reusing its presentation counter during the same process lifetime.
	return "%s:%d:%s" % [_host_epoch,_host_sequence,accepted_action_id.sha256_text().left(24)]

static func config() -> Dictionary:
	if not _loaded:
		_loaded = true
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if valid_config(raw): _config = raw
	return _config

static func valid_config(raw: Variant) -> bool:
	if not raw is Dictionary: return false
	var thresholds: Variant = raw.get("rank_thresholds")
	if not thresholds is Array or thresholds.size() != 5: return false
	var previous := -1
	for value: Variant in thresholds:
		if not _whole_nonnegative(value) or int(value) <= previous: return false
		previous = int(value)
	if int(thresholds[0]) != 0: return false
	if int(thresholds[4])>MAX_TRACKED_USES: return false
	var increment: Variant = raw.get("damage_per_rank")
	if not (increment is int or increment is float) or not is_finite(float(increment)) or float(increment) < 0.0: return false
	var cap: Variant = raw.get("max_known_moves")
	return _whole_nonnegative(cap) and int(cap) > 0 and int(cap) <= MAX_KNOWN_MOVES

static func _whole_nonnegative(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0.0 and floor(float(value)) == float(value)

static func rank_from_uses(uses: int) -> int:
	if config().is_empty(): return 1
	var thresholds: Array = config().rank_thresholds
	var rank := 1
	for index: int in mini(thresholds.size(),5):
		if uses >= int(thresholds[index]): rank = index+1
	return clampi(rank,1,5)

static func power_multiplier(rank: int) -> float:
	if config().is_empty(): return 1.0
	return 1.0 + float(clampi(rank,1,5)-1)*float(config().damage_per_rank)

static func rank_for(creature: RefCounted, move_id: String) -> int:
	if creature == null: return 1
	var uses: Dictionary = creature.get("move_mastery_uses")
	return rank_from_uses(int(uses.get(move_id,0)))

## Freeze once in the actual accepted host action, before any credit. Actor
## identity comes from the existing live deployment record, never an RPC card.
## Pending actions retain this value across IO retries and body replacement.
static func freeze_action(creature: RefCounted, slot: String, actor: Dictionary,
		completed_tiers: Array, moves: RefCounted) -> Dictionary:
	if creature == null or moves == null or not ["quick", "charged", "utility", "ultimate"].has(slot):
		return {"ok": false, "code": "invalid_slot"}
	var uid := str(creature.get("uid"))
	if str(actor.get("creature_uid", "")) != uid or str(actor.get("character_id", "")).is_empty() \
			or str(actor.get("encounter_id", "")).is_empty() or not _whole_nonnegative(actor.get("generation")) \
			or int(actor.generation) < 1 or not _whole_nonnegative(actor.get("action")) or int(actor.action) < 1:
		return {"ok": false, "code": "stale_actor"}
	var move_id := str(creature.get("move_" + slot))
	var known: Array = creature.get("known_moves")
	if not known.has(move_id) or not moves.has(move_id) or str(moves.slot(move_id)) != slot:
		return {"ok": false, "code": "unknown_or_wrong_slot"}
	var row: Dictionary = moves.move(move_id).duplicate(true)
	var rank := rank_for(creature, move_id)
	var unique_tiers := {}
	for tier: Variant in completed_tiers:
		if not _whole_nonnegative(tier) or int(tier) < 1 or int(tier) > 5 or unique_tiers.has(int(tier)):
			return {"ok": false, "code": "invalid_breakthroughs"}
		unique_tiers[int(tier)] = true
	var growth := 1.0
	if slot == "ultimate":
		var signature: Dictionary = row.get("ultimate", {})
		growth += float(signature.get("growth_per_breakthrough", 0.0)) * unique_tiers.size()
	row["mastery_rank"] = rank
	row["effect_tier"] = rank
	row["power_multiplier"] = power_multiplier(rank) * growth
	row["slot"] = slot
	row["move_id"] = move_id
	row["action_id"] = new_action_identity("%s:%s:%d:%d" % [actor.encounter_id, uid, int(actor.generation), int(actor.action)])
	row["actor_binding"] = actor.duplicate(true)
	row["breakthrough_count"] = unique_tiers.size()
	row["vfx"] = effect_tier(row.get("vfx", {}), rank, unique_tiers.size() if slot == "ultimate" else 0)
	return {"ok": true, "move": row}

## Tier changes object count/size and impact only. Geometry/timing/cost stays
## frozen and unchanged, so a higher rank never falsifies an opponent's tell.
static func effect_tier(base: Dictionary, rank: int, breakthroughs: int = 0) -> Dictionary:
	var result := base.duplicate(true)
	var step := clampi(rank, 1, 5) - 1
	var tier := clampi(breakthroughs, 0, 5)
	result["effect_tier"] = step + 1
	result["breakthrough_tier"] = tier
	result["count"] = maxi(1, int(base.get("count", 1))) + step + tier
	result["size"] = float(base.get("size", 1.0)) * power_multiplier(step + 1) * (1.0 + float(config().get("damage_per_rank", 0.0)) * tier)
	result["impact_scale"] = float(base.get("impact_scale", 1.0)) * power_multiplier(step + 1)
	return result

## Stage into the SAME existing live actor row as HP/action/Wind. No new meter
## registry or portable ledger: meter is encounter-scoped, keyed by creature UID.
## Caller verifies frozen binding against current generation before committing.
static func stage_meter_landed(actor: Dictionary, frozen: Dictionary, actual_debit: float,
		meter_config: Dictionary) -> Dictionary:
	var binding: Variant = frozen.get("actor_binding")
	if not binding is Dictionary or not is_finite(actual_debit) or actual_debit <= 0.0:
		return {"ok": false, "code": "not_landed"}
	for key: String in ["character_id", "creature_uid", "encounter_id", "generation"]:
		if actor.get(key) != binding.get(key): return {"ok": false, "code": "stale_actor"}
	var action := int(binding.get("action", -1))
	if action < 1 or action <= int(actor.get("last_meter_action", 0)):
		return {"ok": false, "code": "replayed_action"}
	var maximum: Variant = meter_config.get("max")
	var gains: Variant = meter_config.get("landed_gain")
	if not _whole_nonnegative(maximum) or int(maximum) < 1 or not gains is Dictionary:
		return {"ok": false, "code": "invalid_meter_config"}
	var slot := str(frozen.get("slot", ""))
	if not ["quick", "charged", "utility", "ultimate"].has(slot): return {"ok": false, "code": "invalid_slot"}
	var gain: Variant = gains.get(slot, 0)
	if not _whole_nonnegative(gain) or (slot == "ultimate" and int(gain) != 0):
		return {"ok": false, "code": "invalid_meter_config"}
	var before: Variant = actor.get("ultimate_meter", 0.0)
	if not (before is int or before is float) or not is_finite(float(before)) \
			or float(before) < 0.0 or float(before) > float(maximum): return {"ok": false, "code": "invalid_meter"}
	var next := actor.duplicate(true)
	next["ultimate_meter"] = minf(float(maximum), float(before) + float(gain))
	next["last_meter_action"] = action
	return {"ok": true, "actor": next}

## The firing CAS consumes full meter inside the accepted action transaction.
## A refusal or IO rollback leaves the exact old row available for retry.
static func stage_ultimate_spend(actor: Dictionary, frozen: Dictionary, meter_config: Dictionary) -> Dictionary:
	var binding: Variant = frozen.get("actor_binding")
	if not binding is Dictionary or str(frozen.get("slot", "")) != "ultimate": return {"ok": false, "code": "invalid_slot"}
	for key: String in ["character_id", "creature_uid", "encounter_id", "generation"]:
		if actor.get(key) != binding.get(key): return {"ok": false, "code": "stale_actor"}
	var maximum: Variant = meter_config.get("max")
	if not _whole_nonnegative(maximum) or int(maximum) < 1: return {"ok": false, "code": "invalid_meter_config"}
	if not ["idle", "recovery"].has(str(actor.get("state", ""))): return {"ok": false, "code": "committed"}
	var action := int(binding.get("action", -1))
	if action < 1 or action <= int(actor.get("last_ultimate_action", 0)): return {"ok": false, "code": "replayed_action"}
	var meter: Variant = actor.get("ultimate_meter")
	if not (meter is int or meter is float) or not is_finite(float(meter)) or float(meter) != float(maximum):
		return {"ok": false, "code": "ultimate_not_full"}
	var next := actor.duplicate(true)
	next["ultimate_meter"] = 0.0
	next["last_ultimate_action"] = action
	return {"ok": true, "actor": next}

## Call inside the existing host HP transaction after commit, from the actual
## manager/director Node. Incoming network requests cannot supply this authority.
## The caller MUST revalidate current live attacker+target UID/generation and
## supply actual clamped HP debit inside that host commit; this helper does not
## authenticate facts merely because a local dictionary contains them.
## host_event is constructed there using pre-debit live HP and accepted damage,
## never copied from a peer impact or presentation callback.
static func credit_landed_use(authority: Node, creature: RefCounted, host_event: Dictionary) -> bool:
	if config().is_empty() or authority == null or not authority.is_inside_tree() or creature == null: return false
	if not authority.get_multiplayer().is_server(): return false
	var staged := stage_landed_use(creature, host_event)
	if not bool(staged.get("ok", false)): return false
	creature.set("move_mastery_uses", staged.uses)
	creature.set("move_mastery_receipts", staged.receipts)
	return true

## Pure staging for the same host transaction. It cannot prove hit authority:
## only credit_landed_use publishes, after the owning Node validates live facts.
static func stage_landed_use(creature: RefCounted, host_event: Dictionary) -> Dictionary:
	if creature == null or config().is_empty(): return {"ok":false,"reason":"unavailable"}
	var event_id := str(host_event.get("action_id",""))
	var move_id := str(host_event.get("move_id",""))
	if event_id.is_empty() or event_id.length()>160 or move_id.is_empty(): return {"ok":false,"reason":"invalid_or_replayed_hit"}
	if str(host_event.get("attacker_uid","")) != str(creature.get("uid")): return {"ok":false,"reason":"invalid_or_replayed_hit"}
	if str(host_event.get("target_uid","")) == "" or str(host_event.target_uid) == str(creature.get("uid")): return {"ok":false,"reason":"invalid_or_replayed_hit"}
	var raw_hp: Variant = host_event.get("target_hp_before",0.0)
	var raw_damage: Variant = host_event.get("applied_damage",0.0)
	if not (raw_hp is int or raw_hp is float) or not (raw_damage is int or raw_damage is float): return {"ok":false,"reason":"invalid_or_replayed_hit"}
	var hp_before := float(raw_hp)
	var applied := float(raw_damage)
	if not is_finite(hp_before) or not is_finite(applied) or hp_before <= 0.0 or applied <= 0.0 or applied > hp_before: return {"ok":false,"reason":"invalid_or_replayed_hit"}
	if bool(host_event.get("snapshot_replay",false)): return {"ok":false,"reason":"invalid_or_replayed_hit"}
	return _stage_use(creature, move_id, event_id)

## Non-damaging utilities earn mastery only from a committed, effective host
## utility receipt. Full-health heal, immune root, miss and snapshot award none.
## This is private transaction planning: receiving this dictionary is not proof
## of authority. The actual existing host HP/effect writer constructs it itself.
static func stage_accepted_effect(creature: RefCounted, receipt: Dictionary) -> Dictionary:
	if creature == null or config().is_empty(): return {"ok": false, "reason": "unavailable"}
	var move_id := str(receipt.get("move_id", ""))
	var event_id := str(receipt.get("action_id", ""))
	if event_id.is_empty() or event_id.length() > 160 \
			or receipt.get("source_uid") != creature.get("uid") \
			or bool(receipt.get("snapshot_replay", false)):
		return {"ok": false, "reason": "invalid_effect"}
	var registry := MOVES.load_default()
	if not registry.has(move_id) or registry.slot(move_id) != "utility":
		return {"ok": false, "reason": "invalid_effect"}
	var kind := str(receipt.get("kind", ""))
	if kind == "heal":
		var before: Variant = receipt.get("hp_before")
		var after: Variant = receipt.get("hp_after")
		if not (before is int or before is float) or not (after is int or after is float) \
				or not is_finite(float(before)) or not is_finite(float(after)) \
				or float(before) <= 0.0 or float(after) <= float(before):
			return {"ok": false, "reason": "no_effect"}
	elif not ["root", "slow_field", "movement_buff", "trap", "next_hit_buff", "damage_taken_debuff"].has(kind):
		return {"ok": false, "reason": "no_effect"}
	if str(registry.move(move_id).get("utility", {}).get("kind", "")) != kind:
		return {"ok": false, "reason": "wrong_effect"}
	return _stage_use(creature, move_id, event_id)

static func _stage_use(creature: RefCounted, move_id: String, event_id: String) -> Dictionary:
	var known: Array = creature.get("known_moves")
	if not known.has(move_id): return {"ok":false,"reason":"invalid_or_replayed_hit"}
	var uses: Dictionary = creature.get("move_mastery_uses")
	var histories: Dictionary = creature.get("move_mastery_receipts")
	if not valid_document(known, uses, histories, known): return {"ok": false, "reason": "invalid_mastery_state"}
	var seen: Array = histories.get(move_id,[])
	if seen.has(event_id): return {"ok":false,"reason":"invalid_or_replayed_hit"}
	var thresholds: Array = config().rank_thresholds
	var maximum := int(thresholds[4])
	var raw_uses: Variant = uses.get(move_id,0)
	if not _whole_nonnegative(raw_uses): return {"ok":false,"reason":"invalid_mastery_state"}
	var old_uses := int(raw_uses)
	if seen.size() != old_uses: return {"ok":false,"reason":"invalid_mastery_state"}
	if old_uses >= maximum or seen.size() >= maximum: return {"ok":false,"reason":"saturated"}
	# Stage all replacements before publishing the complete character mutation.
	var next_uses := uses.duplicate(true)
	var next_history := histories.duplicate(true)
	var next_seen := seen.duplicate()
	next_seen.append(event_id)
	next_uses[move_id] = old_uses+1
	next_history[move_id] = next_seen
	return {"ok":true,"uses":next_uses,"receipts":next_history}

## Durable import validation, not a use event. Failure refuses the whole incoming
## mastery document; it never partially restores one move then resets another.
## allowed_moves comes from the host's species/level/breakthrough learnset and
## compatible primary-type TM records, not the incoming portable document.
static func valid_document(known: Variant, uses: Variant, histories: Variant, allowed_moves: Array) -> bool:
	if config().is_empty() or not known is Array or not uses is Dictionary or not histories is Dictionary: return false
	var thresholds: Array = config().rank_thresholds
	var maximum := int(thresholds[4])
	# Cache plain ids rather than a script-backed RefCounted. A static owned
	# resource can keep its script/dependency graph alive during engine exit.
	if _registered_moves.is_empty():
		var registry := MOVES.load_default()
		for id: String in registry.move_ids(): _registered_moves[id] = true
	if known.size() > int(config().get("max_known_moves",128)) or uses.size() > known.size() or histories.size() > known.size(): return false
	var unique: Dictionary = {}
	for raw: Variant in known:
		if not raw is String or str(raw).is_empty() or unique.has(raw): return false
		if not _registered_moves.has(raw) or not allowed_moves.has(raw): return false
		unique[raw] = true
	for move: Variant in uses:
		if not unique.has(move): return false
		var value: Variant = uses[move]
		if not _whole_nonnegative(value): return false
		if int(value) < 0 or int(value) > maximum: return false
	for move: Variant in histories:
		if not unique.has(move) or not histories[move] is Array: return false
		var rows: Array = histories[move]
		if rows.size() > maximum or rows.size() != int(uses.get(move,0)): return false
		var seen: Dictionary = {}
		for event: Variant in rows:
			if not event is String or str(event).is_empty() or str(event).length()>160 or seen.has(event): return false
			seen[event] = true
	for move: Variant in uses:
		if int(uses[move]) > 0 and not histories.has(move): return false
	return true
