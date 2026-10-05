extends RefCounted

## One original host catch offer, promoted through the existing full character
## transaction. The offer is never an owned sixth or a reserve party.
static func codec() -> Script:
	return load("res://scripts/save/water_capture_codec.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")

static func receipt(offer: String, character: String) -> String:
	return "craft:wild_capture_%s:%s" % [offer.sha256_text(), character]

static func offer_valid(context: Dictionary) -> bool:
	if context.size() != 8 or not ESSENCE._opaque_id(context.get("offer_id")) \
		or context.get("source_key") != "capture:" + str(context.offer_id) \
		or not ESSENCE._opaque_id(context.get("world_namespace")) or not ESSENCE._opaque_id(context.get("session_id")) \
		or not context.get("participants") is Array or context.participants.size() != 1 \
		or not ESSENCE._opaque_id(context.participants[0]) \
		or not preload("res://scripts/data/biome_order.gd").runtime_ids(false).has(context.get("realm")) \
		or not codec().call("valid_capture_traits", context.get("capture_traits")): return false
	var card: RefCounted = codec().call("decode", context.get("creature"), context.capture_traits)
	return card != null and context.capture_traits.captured_from.world_namespace == context.world_namespace

static func stage(current: Dictionary, intent: Dictionary, context: Dictionary) -> Dictionary:
	if intent.size() != 3 or not intent.get("offer_id") is String or not intent.get("keep") is bool \
		or not intent.get("released_uid") is String: return ESSENCE._refuse("invalid_capture_choice")
	var offer := context.duplicate(true)
	for field: String in ["character_id", "expected_revision", "in_range", "in_combat", "foundation_runtime_authorized", "retained_event"]: offer.erase(field)
	if not offer_valid(offer) or intent.offer_id != offer.offer_id or current.character_id != offer.participants[0]: return ESSENCE._refuse("original_capture_required")
	var token := receipt(intent.offer_id, current.character_id)
	if current.redesign_character.transaction_receipts.has(token): return ESSENCE._refuse("reconcile_original_capture")
	var uid: String = offer.creature.uid
	for owned: Dictionary in current.party:
		if owned.uid == uid: return ESSENCE._refuse("capture_already_owned")
	var next := current.duplicate(true)
	var payout: Array = []
	if not intent.keep:
		if not intent.released_uid.is_empty(): return ESSENCE._refuse("decline_cannot_release_owned")
	else:
		if current.party.size() == 5:
			var released := ESSENCE.stage_release(current, current.character_id, intent.released_uid, int(context.expected_revision), ESSENCE.config())
			if released.get("ok") != true or released.get("duplicate") == true: return ESSENCE._refuse("capture_release_refused")
			next = released.state.duplicate(true)
			payout = released.payout.duplicate(true)
		elif not intent.released_uid.is_empty(): return ESSENCE._refuse("capture_has_free_slot")
		if next.party.size() >= 5: return ESSENCE._refuse("five_owned_slots")
		# Owner authority projections carry no in-fight energy meter
		# (character_record_rules.portable_projection, ESSENCE.training_projection),
		# so the staged roster card leaves it out like every other owned card.
		var newcomer: Dictionary = offer.creature.duplicate(true)
		newcomer.erase("energy")
		next.party.append(newcomer)
		next.redesign_character = TEACHING.character_loadout_mirror(next.party, next.redesign_character)
		if not next.redesign_character.creatures.has(uid): return ESSENCE._refuse("capture_loadout_missing")
		next.redesign_character = preload("res://scripts/creatures/breakthrough.gd").initialize_caught(next.redesign_character, offer.creature)
		if next.redesign_character.is_empty(): return ESSENCE._refuse("capture_tiers_invalid")
		for field: String in offer.capture_traits: next.redesign_character.creatures[uid][field] = offer.capture_traits[field]
		var card: Dictionary = next.party.back()
		if not TRAITS._refresh_max_hp(card, next.redesign_character.creatures[uid], TRAITS.config()): return ESSENCE._refuse("capture_stats_invalid")
		next.redesign_character = preload("res://scripts/creatures/breakthrough.gd").refresh_feast_moves(next.party, next.redesign_character)
	if next.redesign_character.transaction_receipts.size() >= int(ESSENCE.config().maximum_transaction_receipts): return ESSENCE._refuse("receipt_budget")
	next.redesign_character.transaction_receipts.append(token)
	return {"ok": true, "state": next, "receipt": token, "payout": payout}
