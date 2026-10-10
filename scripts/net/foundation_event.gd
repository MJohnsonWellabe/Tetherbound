extends RefCounted

## Ordered host obligations use the existing reward_deliveries world carrier.
## This codec grants nothing; only the authenticated production writer appends.
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const FIELDS := ["version", "kind", "delivery_id", "world_id", "world_namespace", "session_id", "source_id", "duties", "status"]

static func make(world: RefCounted, epoch: String, source: String, duties: Array) -> Dictionary:
	var row := {"version": 1, "kind": "foundation_event", "world_id": world.world_id,
		"world_namespace": world.reward_delivery_namespace, "session_id": epoch, "source_id": source,
		"duties": duties.duplicate(true), "status": "retained"}
	row.delivery_id = identity(row)
	return row if valid(row, world.reward_delivery_namespace, world.world_id) else {}

static func identity(row: Dictionary) -> String:
	return "foundation_event:" + JSON.stringify([row.get("world_namespace"), row.get("session_id"), row.get("source_id")]).sha256_text()

static func valid(raw: Variant, namespace_id: String, world_id: String) -> bool:
	if not raw is Dictionary or raw.size() != FIELDS.size(): return false
	for key: String in FIELDS:
		if not raw.has(key): return false
	if raw.version != 1 or raw.kind != "foundation_event" or raw.status != "retained" \
		or raw.world_namespace != namespace_id or raw.world_id != world_id or raw.delivery_id != identity(raw) \
		or not ESSENCE._opaque_id(raw.session_id) or not ESSENCE._opaque_id(raw.source_id) \
		or not raw.duties is Array or raw.duties.is_empty(): return false
	for duty: Variant in raw.duties:
		if not duty is Dictionary or duty.size() != 4 or not duty.get("character_id") is String or duty.character_id.is_empty() \
			or duty.get("action") not in ["research_event", "master_win", "boss_relic", "rematch_win", "bounty_event", "capture_offer", "combat_mastery", "combat_round_reward", "wild_defeat_share"] \
			or not duty.get("intent") is Dictionary or not duty.get("context") is Dictionary: return false
		if not _duty_valid(duty, raw): return false
	return true

static func _strings(raw: Variant, allow_empty: bool = false) -> bool:
	if not raw is Array or (not allow_empty and raw.is_empty()): return false
	var seen := {}
	for value: Variant in raw:
		if not ESSENCE._opaque_id(value) or seen.has(value): return false
		seen[value] = true
	return true

static func _duty_valid(duty: Dictionary, row: Dictionary) -> bool:
	var context: Dictionary = duty.context
	var intent: Dictionary = duty.intent
	if not ESSENCE._opaque_id(duty.character_id) or not ESSENCE._opaque_id(context.get("source_key")): return false
	if duty.action == "combat_round_reward":
		return context.get("world_namespace") == row.world_namespace and context.get("session_id") == row.session_id \
			and row.source_id == context.source_key \
			and preload("res://scripts/net/combat_round_reward.gd").source_valid(intent, context, duty.character_id)
	if duty.action == "wild_defeat_share":
		# One retained guest share of one host wild victory (F27).
		return context.get("world_namespace") == row.world_namespace and context.get("session_id") == row.session_id \
			and context.get("validated_host_outcome") == "win" and intent.get("kind") == "wild_defeat" \
			and intent.get("world_namespace") == row.world_namespace and ESSENCE._opaque_id(intent.get("event_id")) \
			and row.source_id == "wild_xp:" + str(intent.event_id) and context.source_key == row.source_id \
			and ESSENCE._equivalent(context.get("defeat_event"), intent) \
			and context.get("settled_vitals") is Array and not context.settled_vitals.is_empty() and context.settled_vitals.size() <= 5 \
			and _strings(context.get("participants")) and context.participants.size() <= 4 and context.participants.has(duty.character_id)
	if duty.action in ["research_event", "rematch_win", "bounty_event", "combat_mastery"]:
		if context.get("world_namespace") != row.world_namespace or context.get("session_id") != row.session_id: return false
	if duty.action != "master_win":
		if not _strings(context.get("participants")) or context.participants.size() > 4 or not context.participants.has(duty.character_id): return false
	if duty.action in ["research_event", "bounty_event"]:
		if not intent.is_empty() or context.get("event_confirmed") != true or not ESSENCE._opaque_id(context.get("event_id")): return false
	if duty.action == "research_event":
		if not ESSENCE._opaque_id(context.get("species_id")) or context.get("kind") not in ["sight", "cast", "catch", "defeat"] \
			or not str(context.source_key).begins_with("encounter:"): return false
		if row.source_id != context.event_id and row.source_id != "defeat:" + str(context.event_id): return false
		if context.kind == "cast" and not ESSENCE._opaque_id(context.get("move_id")): return false
		if context.kind == "catch" and (context.get("wild") != true or not context.get("night") is bool): return false
		if context.kind == "defeat" and context.get("opponent_defeated") != true: return false
	elif duty.action == "combat_mastery":
		if intent.size() != 2 or not ESSENCE._opaque_id(intent.get("action_id")) \
			or not ESSENCE._component(intent.get("creature_uid")) or context.get("event_confirmed") != true \
			or context.get("source_key") != "combat_mastery:" + str(intent.action_id) \
			or not context.get("outcome") is Dictionary \
			or not context.get("binding") is Dictionary or context.binding.get("character_id") != duty.character_id \
			or context.binding.get("creature_uid") != intent.creature_uid \
			or not ESSENCE._integer(context.binding.get("deployment_generation"), 1, 2147483647) \
			or not ESSENCE._opaque_id(context.get("encounter_id")): return false
		var event: Dictionary = context.outcome
		if context.has("parent_action_id") or context.has("tag_part"):
			var parent := tag_mastery_parent(context, intent, duty.character_id)
			if parent.is_empty() or row.source_id != "mastery:" + parent or row.duties.size() > 2: return false
			var parts := {}
			var creatures := {}
			for sibling: Variant in row.duties:
				if not sibling is Dictionary or sibling.get("action") != "combat_mastery" \
					or sibling.get("character_id") != duty.character_id \
					or not sibling.get("context") is Dictionary or not sibling.get("intent") is Dictionary: return false
				var other: Dictionary = sibling.context
				if tag_mastery_parent(other, sibling.intent, duty.character_id) != parent \
					or other.get("encounter_id") != context.encounter_id \
					or other.get("outcome", {}).get("target_uid") != event.get("target_uid") \
					or parts.has(other.tag_part) or creatures.has(sibling.intent.creature_uid): return false
				parts[other.tag_part] = true
				creatures[sibling.intent.creature_uid] = true
		elif row.source_id != "mastery:" + str(intent.action_id): return false
		if event.get("action_id") != intent.action_id or event.get("attacker_uid") != intent.creature_uid \
			or not ESSENCE._component(event.get("move_id")): return false
		if event.size() != 6 \
			or not ESSENCE._opaque_id(event.get("target_uid")) or event.target_uid == event.attacker_uid \
			or not _positive_number(event.get("target_hp_before")) or not _positive_number(event.get("applied_damage")) \
			or float(event.applied_damage) > float(event.target_hp_before): return false
	elif duty.action == "capture_offer":
		if not intent.is_empty() or load("res://scripts/net/foundation_capture_rules.gd").call("offer_valid", context) != true \
			or row.source_id != context.source_key or context.world_namespace != row.world_namespace or context.session_id != row.session_id: return false
	elif duty.action == "bounty_event":
		if context.source_key != "halda_bounty_event" or context.get("kind") not in ["catch_trait", "defeat_alpha", "rematch"] \
			or context.event_id != row.source_id \
			or not preload("res://scripts/data/biome_order.gd").ids(false).has(context.get("biome")) \
			or not _strings(context.get("issued_instances")) or not _strings(context.get("traits"), true): return false
		for instance: String in context.issued_instances:
			if instance.length() != 64 or not instance.is_valid_hex_number(false): return false
		for trait_row: String in context.traits:
			if not preload("res://scripts/creatures/traits.gd").config().get("traits", {}).has(trait_row): return false
	elif duty.action == "master_win":
		if intent.size() != 3 or not ESSENCE._opaque_id(intent.get("master_id")) or not ESSENCE._opaque_id(intent.get("creature_uid")) \
			or not ESSENCE._opaque_id(intent.get("encounter_id")) or context.get("master_id") != intent.master_id \
			or context.get("creature_uid") != intent.creature_uid or context.get("encounter_id") != intent.encounter_id \
			or context.get("validated_host_outcome") != "win" or context.get("participant_count") != 1 \
			or context.source_key != "master_encounter:" + str(intent.encounter_id) \
			or (context.has("settled_vitals") and (not context.settled_vitals is Array or context.settled_vitals.is_empty() \
				or context.settled_vitals.size() > 5)): return false
	elif duty.action == "boss_relic":
		if intent.size() != 3 or not ESSENCE._opaque_id(intent.get("trainer_id")) or not ESSENCE._opaque_id(intent.get("encounter_id")) \
			or context.get("encounter_id") != intent.encounter_id or context.get("validated_host_outcome") != "win" \
			or context.source_key != "boss:" + str(intent.trainer_id): return false
		# WorldState preflights these rows while loading. Loading the authored
		# reward router lazily avoids its NPC/Session/WorldLedger preload cycle.
		var rewards: Script = load("res://scripts/net/encounter_rewards.gd")
		if rewards == null: return false
		var handoff: Dictionary = rewards.call("chapter_hand_off", intent.trainer_id, str(context.get("realm", "")))
		if handoff.is_empty() or handoff.relic_biome != intent.get("biome"): return false
	elif duty.action == "rematch_win":
		if intent.size() != 3 or not ESSENCE._opaque_id(intent.get("trainer_id")) or not ESSENCE._opaque_id(intent.get("encounter_id")) \
			or intent.get("tier") not in ["r1", "endgame"] or context.get("trainer_id") != intent.trainer_id \
			or context.get("tier") != intent.tier or context.get("encounter_id") != intent.encounter_id \
			or context.get("validated_host_outcome") != "win" or context.source_key != "rematch:" + str(intent.trainer_id) \
			or not ESSENCE._integer(context.get("world_seconds"), 0, 9007199254740991) \
			or not _strings(context.get("world_flags"), true) or not _strings(context.get("personal_flags"), true): return false
		var profile := preload("res://scripts/repeatables/rematch_rules.gd").profile(intent.trainer_id)
		if profile.is_empty(): return false
		if profile.kind == "master" and (context.participants.size() != 1 or context.get("single_creature_duel") != true or not ESSENCE._opaque_id(context.get("creature_uid"))): return false
	return true


## One command journal may retain two distinct creature-owned quick receipts.
## This validates their existing child identity; it grants no use or damage.
static func tag_mastery_parent(context: Dictionary, intent: Dictionary, character: String) -> String:
	if not ESSENCE._opaque_id(context.get("parent_action_id")) \
		or context.get("tag_part") not in ["outgoing", "incoming"] \
		or not context.get("binding") is Dictionary or not context.get("outcome") is Dictionary \
		or context.outcome.has("effect_receipt") or context.binding.get("character_id") != character \
		or context.binding.get("creature_uid") != intent.get("creature_uid") \
		or not ESSENCE._component(intent.get("creature_uid")) \
		or not ESSENCE._integer(context.binding.get("deployment_generation"), 1, 2147483647): return ""
	var parent: String = context.parent_action_id
	var fields := parent.rsplit(":", true, 2)
	if fields.size() != 3 or fields[0] != "command:%s:%s" % [context.get("encounter_id", ""), character] \
		or not fields[1].is_valid_int() or not fields[2].is_valid_int() \
		or not ESSENCE._integer(int(fields[1]), 1, 2147483647) \
		or not ESSENCE._integer(int(fields[2]), 1, 2147483647) \
		or str(int(fields[1])) != fields[1] or str(int(fields[2])) != fields[2]: return ""
	var generation := int(fields[1]) + (1 if context.tag_part == "incoming" else 0)
	if context.binding.deployment_generation != generation \
		or intent.get("action_id") != JSON.stringify([parent, context.tag_part, intent.creature_uid, generation]).sha256_text(): return ""
	return parent

## Additive event shape on the existing retained mastery carrier. These are
## effective host status receipts, with no fabricated hostile damage fields.
static func _positive_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) > 0.0

## An empty `world_id` means the caller does not know it (a character
## snapshot carries world identity in the split envelope, not in its payload),
## exactly as actor_vitals_delivery.world_errors treats it: every other field is
## still checked and the row must name a world, but not a particular one.
static func errors(rows: Dictionary, namespace_id: String, world_id: String) -> Array[String]:
	var result: Array[String] = []
	for key: Variant in rows:
		var row: Variant = rows[key]
		if str(key).begins_with("foundation_event:") or (row is Dictionary and row.get("kind") == "foundation_event"):
			var expected := world_id
			if expected.is_empty() and row is Dictionary and row.get("world_id") is String:
				expected = row.world_id
			if expected.is_empty() or not valid(row, namespace_id, expected) or row.delivery_id != key:
				result.append("Invalid retained Foundation event")
	return result
