extends RefCounted

## Host commit helper only. UI/VFX/number/audio events never call this.
## Character-scope uses and bounded durable event identities travel with the
## same creature UID. An imported snapshot never awards additional uses.
const CONFIG_PATH := "res://data/config/move_mastery.json"
const MOVES := preload("res://scripts/creatures/move_db.gd")
const MAX_KNOWN_MOVES := 256
static var _loaded := false
static var _config: Dictionary = {}
static var _host_epoch: String = ""

## Mint on the authority once per accepted action and freeze in its pending
## transaction. Encounter/body counters alone repeat after process restart;
## the fresh cryptographic process epoch prevents collisions with portable
## receipts retained from a previous world or host. Never accept a peer epoch.
static func new_action_identity(accepted_action_id: String) -> String:
	if accepted_action_id.is_empty() or accepted_action_id.length()>120: return ""
	if _host_epoch.is_empty(): _host_epoch = Crypto.new().generate_random_bytes(16).hex_encode()
	return _host_epoch+":"+accepted_action_id

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
	var known: Array = creature.get("known_moves")
	if not known.has(move_id): return {"ok":false,"reason":"invalid_or_replayed_hit"}
	var uses: Dictionary = creature.get("move_mastery_uses")
	var histories: Dictionary = creature.get("move_mastery_receipts")
	var seen: Array = histories.get(move_id,[])
	if seen.has(event_id): return {"ok":false,"reason":"invalid_or_replayed_hit"}
	var thresholds: Array = config().rank_thresholds
	var maximum := int(thresholds[4])
	var raw_uses: Variant = uses.get(move_id,0)
	if not _whole_nonnegative(raw_uses): return {"ok":false,"reason":"invalid_mastery_state"}
	var old_uses := int(raw_uses)
	if seen.size() != old_uses: return {"ok":false,"reason":"invalid_mastery_state"}
	if old_uses >= maximum or seen.size() >= maximum: return {"ok":false,"reason":"invalid_or_replayed_hit"}
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
	var moves := MOVES.load_default()
	if known.size() > int(config().get("max_known_moves",128)) or uses.size() > known.size() or histories.size() > known.size(): return false
	var unique: Dictionary = {}
	for raw: Variant in known:
		if not raw is String or str(raw).is_empty() or unique.has(raw): return false
		if not moves.has(raw) or not allowed_moves.has(raw): return false
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
