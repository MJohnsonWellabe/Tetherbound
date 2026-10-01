extends RefCounted

## Detached F44 candidates. Foundation alone admits the host context and uses
## its existing character_training prepared world-save / owner-save / ACK.
const DATA := preload("res://scripts/data/redesign_data.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const PATH := "res://data/config/rematches.json"

static func config() -> Dictionary:
	var raw: Variant = DATA.json(PATH)
	return raw if raw is Dictionary else {}

static func profile(id: String) -> Dictionary:
	return config().get("profiles", {}).get(id, {}).duplicate(true)

static func master_spec(id: String) -> Dictionary:
	var row := BREAKTHROUGH.master(id)
	if row.is_empty(): return {}
	return {"id": row.id, "name": row.name, "participants": 1, "no_switch": true, "no_flee": true,
		"team": [{"species": row.species_id, "level": int(row.cap_level), "combat": row.combat.duplicate(true)}]}

static func available(id: String, tier: String, world_flags: Array, personal_flags: Array) -> bool:
	var row := profile(id)
	if row.is_empty(): return false
	if tier == "endgame": return personal_flags.has(str(config().get("credits_flag", "")))
	if tier != "r1" or row.biome == "stormwood" or row.kind == "boss": return false
	var gate: String = config().biomes[row.biome].climax_flag
	return world_flags.has(gate) or personal_flags.has(gate)

## Canonical spec from the live director, never an RPC roster. Preserve identity,
## team/send-out order and pattern. Story rewards and original defeat flags are
## deliberately excluded from the combat-only copy; its outcome goes to F44.
static func encounter_spec(original: Dictionary, tier: String) -> Dictionary:
	var row := profile(str(original.get("id", "")))
	if row.is_empty() or tier not in ["r1", "endgame"]: return {}
	if tier == "r1" and (row.biome == "stormwood" or row.kind == "boss"): return {}
	var team: Variant = original.get("team")
	if not team is Array or team.is_empty() or (row.kind == "master" and team.size() != 1): return {}
	var level: int = int(config().endgame_levels[row.kind]) if tier == "endgame" else int(config().biomes[row.biome].r1_levels[row.kind])
	var result := original.duplicate(true)
	result.reward = {"coins": 0, "items": [], "flags": [], "xp_bonus": 0}
	result.defeat_flag = ""
	result.requires_flags = []
	result.rechallenge = true
	result.rematch = {"original_id": row.id, "tier": tier, "original_defeat_flag": row.defeat_flag,
		"arena": "halda_lawn" if row.kind == "boss" else "original_site"}
	for member: Variant in result.team:
		if not member is Dictionary or not member.get("species") is String: return {}
		member.level = level
		member.trainer_owned = true
		var learnset: Dictionary = TEACHING.learnsets().get(member.species, {})
		if learnset.is_empty(): return {}
		if not member.get("moves", {}) is Dictionary: return {}
		member.moves = member.get("moves", {}).duplicate(true)
		member.moves.utility = str(learnset.get("first_utility", ""))
		member.moves.ultimate = str(learnset.get("ultimate", ""))
		if member.moves.utility.is_empty() or member.moves.ultimate.is_empty(): return {}
	# No world-event/dialogue consumers should see a synthetic story victory.
	for key: String in ["win_event", "victory_event", "win_conversation", "victory_conversation", "defeated", "reward_flags", "chapter_hand_off"]:
		result.erase(key)
	return result

## Intent has only encounter identity. All eligibility, roster, clock and
## participant evidence comes from the bound host producer and is re-staged
## inside Foundation. No saved balance or client victory statement is trusted.
static func stage(current: Dictionary, revision: int, intent: Dictionary, context: Dictionary) -> Dictionary:
	if intent.size() != 3: return deny("invalid_rematch_intent")
	for field: String in ["trainer_id", "tier"]:
		if not TRAITS.component(intent.get(field)): return deny("invalid_rematch_identity")
	# EncounterHost's actual IDs are '<peer>:<minted>', and its sequence restarts
	# in a new session. Preserve that ID in the immutable intent, hash it only
	# for the receipt component, and bind the receipt to Foundation's epoch.
	if not intent.get("encounter_id") is String or intent.encounter_id.is_empty() \
		or intent.encounter_id.length() > 256 or intent.encounter_id.contains("\n") \
		or not TRAITS.component(context.get("session_id")): return deny("invalid_host_encounter_epoch")
	var row := profile(intent.trainer_id)
	if row.is_empty() or context.get("character_id") != current.get("character_id") \
		or context.get("expected_revision") != revision or context.get("validated_host_outcome") != "win" \
		or context.get("encounter_id") != intent.encounter_id or context.get("trainer_id") != intent.trainer_id \
		or context.get("tier") != intent.tier or context.get("source_key") != "rematch:" + intent.trainer_id \
		or context.get("in_range") != true: return deny("canonical_rematch_win_required")
	var participants: Variant = context.get("participants")
	if not participants is Array or participants.is_empty() or participants.size() > 4 \
		or not participants.has(current.character_id): return deny("not_rematch_participant")
	var distinct: Dictionary = {}
	for character: Variant in participants:
		if not TRAITS.component(character) or distinct.has(character): return deny("invalid_participant_snapshot")
		distinct[character] = true
	if row.kind == "master":
		if participants.size() != 1 or context.get("single_creature_duel") != true: return deny("master_rematches_are_one_on_one")
		var uid: Variant = context.get("creature_uid")
		if not TRAITS.component(uid): return deny("admitted_duel_creature_required")
		var owned := false
		for card: Dictionary in current.get("party", []):
			if card.get("uid") == uid: owned = true
		if not owned: return deny("admitted_duel_creature_required")
	if not context.get("world_flags") is Array or not context.get("personal_flags") is Array \
		or not available(intent.trainer_id, intent.tier, context.world_flags, context.personal_flags): return deny("tier_locked")
	if not TRAITS.component(context.get("world_namespace")) \
		or not TRAITS.integer(context.get("world_seconds"), 0, 9007199254740991): return deny("host_clock_required")
	var personal: Variant = current.get("redesign_character")
	if not personal is Dictionary or not personal.get("transaction_receipts") is Array: return deny("invalid_character")
	var base := "rematch:%s:%s:%s" % [intent.trainer_id, intent.tier, current.character_id]
	# Completed outcomes pay at most once, including a no-payout cooldown win.
	var win_receipt: String = base + ":win:" + context.world_namespace + ":" + context.session_id + ":" + intent.encounter_id.sha256_text()
	if personal.transaction_receipts.has(win_receipt): return deny("reconcile_original_delivery")
	if personal.transaction_receipts.size() + 2 > int(config().maximum_transaction_receipts): return deny("receipt_budget_exhausted")
	var first: bool = not personal.transaction_receipts.has(base)
	var cooldowns: Variant = personal.get("rematch_cooldowns", {})
	if not cooldowns is Dictionary: return deny("invalid_rematch_cooldowns")
	var key: String = context.world_namespace + ":" + intent.trainer_id + ":" + intent.tier
	var last: Variant = cooldowns.get(key, {})
	if not last is Dictionary: return deny("invalid_rematch_cooldown")
	# Cooldowns use the host-world namespace, as the declared cycle carrier
	# does. Never compare clocks across worlds; F47 owns cross-world daily caps.
	if not last.is_empty() and last.get("world_namespace") != context.world_namespace: return deny("foreign_rematch_cooldown")
	if not last.is_empty() and int(context.world_seconds) < int(last.get("paid_at_seconds", 0)): return deny("host_clock_regressed")
	var foreign_paid_clock := false
	for saved_key: String in cooldowns:
		if not saved_key.ends_with(":" + intent.trainer_id + ":" + intent.tier): continue
		var saved: Variant = cooldowns[saved_key]
		if not saved is Dictionary: return deny("invalid_rematch_cooldown")
		if saved.get("world_namespace") != context.world_namespace: foreign_paid_clock = true
	# A different host has no authority to advance the original world's clock.
	# Retain the win without a repeat payout until that owning clock can prove
	# its deadline. World hopping cannot mint a new cooldown or compare clocks.
	var paid: bool = first or (not foreign_paid_clock and int(context.world_seconds) >= int(last.get("next_eligible_seconds", 0)))
	var next := current.duplicate(true)
	if paid:
		var payout: Dictionary = config().biomes[row.biome].unique_materials.duplicate(true) if first else config().biomes[row.biome].repeat_materials.duplicate(true)
		if first and row.kind in ["master", "boss"]: payout = {"tether_candy": int(config().unique_candy)}
		if not first:
			var essence_types: Array = row.essence_types
			for type_id: String in essence_types:
				payout["essence_" + type_id] = int(config().repeat_essence_per_type)
		if not BAG.valid_slots(next.get("inventory")): return deny("invalid_inventory")
		var bag := BAG.inventory_from(next.inventory)
		for item: String in payout:
			if not BAG.db().has(item) or not BAG.give_stack(bag, {"id": item, "n": int(payout[item])}):
				return deny("rematch_reward_pending_make_satchel_room")
		next.inventory = BAG.slots(bag)
		if first: next.redesign_character.transaction_receipts.append(base)
		if not next.redesign_character.has("rematch_cooldowns"): next.redesign_character.rematch_cooldowns = {}
		next.redesign_character.rematch_cooldowns[key] = {"world_namespace": context.world_namespace,
			"paid_at_seconds": int(context.world_seconds), "next_eligible_seconds": int(context.world_seconds) + int(config().repeat_days) * int(config().day_seconds)}
	next.redesign_character.transaction_receipts.append(win_receipt)
	return {"ok": true, "duplicate": false, "state": next, "receipt": win_receipt,
		"original_intent": intent.duplicate(true), "original_revision": revision,
		"reward_paid": paid, "unique_reward": first and paid}

static func deny(code: String) -> Dictionary:
	return {"ok": false, "code": code, "durable": false}
