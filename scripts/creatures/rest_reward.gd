extends RefCounted

## Personal rest eligibility lives in the existing transaction receipt carrier.
## Only canonical completed-encounter/discovery producers call earn(). Neither
## a calendar change nor an ordinary checkpoint creates eligibility.
const E := preload("res://scripts/creatures/essence.gd")
const P := preload("res://scripts/creatures/progression.gd")
const WINDOWS := preload("res://scripts/creatures/receipt_windows.gd")
const CLOCK := "rest_activity"
const PAID := "rest_award"
const COMPLETE := "rest_complete"
const DISCOVERY := "rest_discovery"
const MAX_GENERATION := 2147483646


static func generation(personal: Dictionary, character: String, kind: String) -> int:
	var result := 0
	for raw: Variant in personal.get("transaction_receipts", []):
		var receipt := str(raw)
		if not receipt.begins_with(kind + ":" + character + ":"): continue
		if not WINDOWS.rest_marker_valid(receipt): return -1
		result = maxi(result, WINDOWS.rest_decimal(receipt.split(":")[2]))
	return result


static func _replace(personal: Dictionary, character: String, kind: String, marker: String) -> void:
	var kept: Array = []
	for raw: Variant in personal.transaction_receipts:
		var prior := str(raw)
		# Paid anchors are per calendar; never discard another world on a visit.
		if not prior.begins_with(kind + ":" + character + ":") or (kind == PAID and prior.split(":")[3] != marker.split(":")[3]): kept.append(raw)
	kept.append(marker)
	personal.transaction_receipts = kept


## Mutates only the caller's detached canonical candidate, before its original
## schema validation and BOOL save. A retry starts from the same frozen before.
static func earn(candidate: Dictionary, source_receipt: String, source_kind: String) -> bool:
	if source_kind not in ["wild_encounter_win", "trainer_encounter_win", "landmark_discovery"] \
		or source_receipt.is_empty() or not candidate.get("redesign_character") is Dictionary \
		or not E._component(candidate.get("character_id")): return false
	var character: String = candidate.character_id
	var personal: Dictionary = candidate.redesign_character
	var previous := generation(personal, character, CLOCK)
	var consumed := generation(personal, character, PAID)
	if previous < 0 or consumed < 0 or consumed > previous or previous >= MAX_GENERATION: return false
	_replace(personal, character, CLOCK, "%s:%s:%d:%s" % [CLOCK, character, previous + 1,
		JSON.stringify([source_kind, source_receipt]).sha256_text()])
	return true


## Frozen retained night/discovery duty. The actual Session producer owns this
## authorization; a player cannot submit these actions through Foundation RPC.
static func source_valid(action: String, intent: Dictionary, context: Dictionary, character: String) -> bool:
	if not E._integer(context.get("rest_source_version"), 1, 1) or context.get("character_id", character) != character \
		or not E._opaque_id(context.get("world_id")) or not E._opaque_id(context.get("world_namespace")) \
		or not E._opaque_id(context.get("session_id")) or not context.get("participants") is Array \
		or not context.participants.has(character) or context.participants.size() > 4 \
		or intent.size() != 1 or not intent.get("action_id") is String or intent.action_id.length() != 32 \
		or not intent.action_id.is_valid_hex_number(false) or intent.action_id.to_lower() != intent.action_id: return false
	var participants := {}
	for participant: Variant in context.participants:
		if not E._component(participant) or participants.has(participant): return false
		participants[participant] = true
	if action == "rest_discovery":
		if context.get("actual_replayed_discovery") != true or not context.get("sources") is Array \
			or context.sources.is_empty() or context.sources.size() > 1024: return false
		var discovery_seen := {}
		for source: Variant in context.sources:
			if not source is String or source.length() != 64 or not source.is_valid_hex_number(false) or source.to_lower() != source or discovery_seen.has(source): return false
			discovery_seen[source] = true
		return context.get("source_key") == "rest_discovery:" + intent.action_id
	if action != "rest_complete" or context.get("actual_completed_night") != true \
		or not E._integer(context.get("night_day"), 1, MAX_GENERATION) \
		or not E._integer(context.get("eligible_generation"), 0, MAX_GENERATION) \
		or not context.get("party_uids") is Array or context.party_uids.is_empty() or context.party_uids.size() > 5 \
		or not context.get("bed_roster") is Dictionary: return false
	var seen := {}
	for uid: Variant in context.party_uids:
		if not E._component(uid) or seen.has(uid): return false
		seen[uid] = true
	for uid: Variant in context.bed_roster:
		var bed: Variant = context.bed_roster[uid]
		if not seen.has(uid) or not bed is Dictionary or bed.size() != 2 \
			or not E._integer(bed.get("bed_index"), -1, 2147483646) \
			or not (bed.get("comfort_bonus") is float or bed.get("comfort_bonus") is int) \
			or not is_finite(float(bed.comfort_bonus)) or float(bed.comfort_bonus) < 0.0: return false
	return context.get("source_key") == "rest_night:" + str(context.world_id) + ":" + str(context.night_day)

static func receipt(action: String, character: String, intent: Dictionary) -> String:
	return "%s:%s:%s" % [action, character, str(intent.get("action_id", "")).sha256_text()]

static func stage_discovery(current: Dictionary, intent: Dictionary, context: Dictionary) -> Dictionary:
	if not source_valid(DISCOVERY, intent, context, str(current.get("character_id", ""))):
		return {"ok": false, "code": "authenticated_discovery_required"}
	var decision := receipt(DISCOVERY, current.character_id, intent)
	if current.redesign_character.transaction_receipts.has(decision): return {"ok": false, "code": "reconcile_original_decision"}
	var next := current.duplicate(true)
	for source: String in context.sources:
		if not earn(next, source, "landmark_discovery"): return {"ok": false, "code": "invalid_discovery_qualification"}
	next.redesign_character.transaction_receipts.append(decision)
	return {"ok": true, "state": next, "receipt": decision}

## Healing finishes only the night's authentic occupied beds. XP is a separate
## all-owned cohort, including fainted members. Both changes precede the v3 save.
static func stage(current: Dictionary, intent: Dictionary, context: Dictionary) -> Dictionary:
	if not source_valid(COMPLETE, intent, context, str(current.get("character_id", ""))):
		return {"ok": false, "code": "actual_prepared_night_required"}
	var character: String = current.character_id
	var decision := receipt(COMPLETE, character, intent)
	if current.redesign_character.transaction_receipts.has(decision): return {"ok": false, "code": "reconcile_original_decision"}
	var uids: Array = []
	for card: Dictionary in current.party: uids.append(card.uid)
	if not E._equivalent(uids, context.party_uids): return {"ok": false, "code": "night_roster_changed"}
	var latest_activity := generation(current.redesign_character, character, CLOCK)
	var eligible := int(context.eligible_generation)
	var consumed := generation(current.redesign_character, character, PAID)
	if latest_activity < 0 or consumed < 0 or consumed > latest_activity or eligible > latest_activity:
		return {"ok": false, "code": "invalid_rest_eligibility"}
	var calendar := str(context.world_namespace).sha256_text()
	var paid_day := 0
	for raw: Variant in current.redesign_character.transaction_receipts:
		var marker := str(raw)
		if marker.begins_with(PAID + ":" + character + ":") and marker.split(":")[3] == calendar:
			paid_day = maxi(paid_day, WINDOWS.rest_decimal(marker.split(":")[4]))
	var qualified := eligible > consumed and int(context.night_day) > paid_day
	var amount := P.rest_xp(P.config()) if qualified else 0
	if amount != 0 and amount != 5: return {"ok": false, "code": "invalid_authored_rest_XP"}
	var next := current.duplicate(true)
	var codec: RefCounted = load("res://scripts/save/save_game.gd").new()
	var party := preload("res://autoload/party.gd").new()
	codec.call("_array_to_party", current.party, party, current.redesign_character)
	if party.call("size") != current.party.size(): return {"ok": false, "code": "night_roster_decode_failed"}
	var decoded_uids: Array = []
	for member: RefCounted in party.call("members"): decoded_uids.append(member.get("uid"))
	if not E._equivalent(decoded_uids, context.party_uids): return {"ok": false, "code": "night_roster_decode_failed"}
	var completed := {}
	for member: RefCounted in party.call("members"):
		var uid := str(member.get("uid"))
		if not context.bed_roster.has(uid):
			if member.get("resting") == true: return {"ok": false, "code": "night_bed_roster_changed"}
			continue
		var bed: Dictionary = context.bed_roster[uid]
		if member.get("resting") != true or member.get("rest_bed_index") != bed.bed_index:
			return {"ok": false, "code": "night_bed_assignment_changed"}
		preload("res://scripts/creatures/home_recovery.gd").rest(member, P.config(), current.redesign_character)
		member.set("rested", true); member.set("resting", false); member.set("rest_bed_index", -1)
		preload("res://scripts/creatures/bond_milestones.gd").credit_rest_night(member)
		var condition := preload("res://scripts/creatures/creature_condition.gd").config()
		preload("res://scripts/creatures/creature_condition.gd").note_rest_completed(member, condition)
		var bonus := float(bed.comfort_bonus)
		member.set("rested_seconds_left", float(member.get("rested_seconds_left")) * (1.0 + bonus))
		member.set("happiness", clampf(float(member.get("happiness")) + float(condition.happiness.on_rest_completed) * bonus, 0.0, float(condition.happiness.max)))
		completed[uid] = true
	if completed.size() != context.bed_roster.size(): return {"ok": false, "code": "night_bed_roster_changed"}
	next.party = codec.call("_party_to_array", party)
	var awards := {}
	for index: int in next.party.size():
		var card: Dictionary = next.party[index]
		if amount > 0:
			var cap := E.creature_cap(current.redesign_character, str(card.uid))
			var changed := P.staged_xp(card, cap, amount, P.config(), E._canonical_trait_maximum.bind(current.redesign_character.creatures))
			if changed.is_empty(): return {"ok": false, "code": "invalid_rest_XP_or_cap"}
			changed = P.staged_training_condition(changed, int(changed.level) - int(card.level), false)
			if changed.is_empty(): return {"ok": false, "code": "invalid_rest_condition"}
			next.party[index] = changed
		awards[card.uid] = amount
	if qualified:
		_replace(next.redesign_character, character, PAID, "%s:%s:%d:%s:%d" % [PAID, character, eligible, calendar, int(context.night_day)])
	next.redesign_character.transaction_receipts.append(decision)
	var teaching := preload("res://scripts/creatures/teaching.gd")
	next = E.refresh_training_moves(next, teaching.available_moves, teaching.character_loadout_mirror)
	if next.is_empty(): return {"ok": false, "code": "canonical_power_refresh_unavailable"}
	return {"ok": true, "state": next, "receipt": decision, "qualified": qualified, "awards": awards}
