extends RefCounted

## F24 pure support-command staging, not an RPC receiver or live meter owner.
## The future transport reconstructs host_context from the ONE admitted
## character/encounter record. Never pass a client's claimed context here.
## The state belongs to that participant; new encounters begin at zero.
## This module deliberately has NO contact-to-meter registration API. Fill
## must be part of EncounterHost's canonical accepted hostile HP transaction.
## No gameplay caller exists yet. The future host transaction must atomically
## accept item consumption or scheduled creature strikes together with this
## meter proposal, before publishing. A failure discards the entire proposal.

const CONFIG_PATH := "res://data/config/tether_commands.json"
const CHECK := preload("res://scripts/combat/utility_effects.gd")
static var _config_cache: Dictionary = {}


static func config() -> Dictionary:
	if not _config_cache.is_empty(): return _config_cache
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null: return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary: _config_cache = parsed
	return _config_cache


static func valid_config(cfg: Dictionary) -> bool:
	if not cfg.get("meter") is Dictionary or not cfg.meter.get("gain") is Dictionary \
		or not cfg.get("gear_tiers") is Dictionary: return false
	if not CHECK._number(cfg.meter.get("max"), 1.0, 1000000.0) \
		or not _whole(cfg.get("receipt_limit_per_player"), 1, 65536): return false
	for slot: String in ["quick", "charged", "utility"]:
		if not CHECK._number(cfg.meter.gain.get(slot), 0.0, float(cfg.meter.max)): return false
	for slot: String in ["ultimate", "tag_switch", "damage_taken"]:
		if not CHECK._number(cfg.meter.gain.get(slot), 0.0, 0.0): return false
	for tier: int in range(1, 5):
		var row: Variant = cfg.gear_tiers.get(str(tier))
		if not row is Dictionary or not CHECK._number(row.get("meter_rate"), 0.001, 10.0) \
			or not _whole(row.get("pouch_size"), 1, 3) \
			or not CHECK._number(row.get("snare_movement_multiplier"), 0.0, 1.0) \
			or not CHECK._number(row.get("snare_catch_bonus"), 0.0, 1.0): return false
	for command: String in ["rally", "item_throw", "tag_switch", "snare"]:
		var row: Variant = cfg.get(command)
		if not row is Dictionary or not CHECK._number(row.get("cost"), 0.001, float(cfg.meter.max)): return false
	for command: String in ["rally", "snare"]:
		if not CHECK._number(cfg[command].get("duration_s"), 0.001, 60.0): return false
	for key: String in ["damage_multiplier", "wind_regen_multiplier"]:
		if not CHECK._number(cfg.rally.get(key), 1.0, 4.0): return false
	for key: String in ["combo_window_s", "switch_lock_s"]:
		if not CHECK._number(cfg.tag_switch.get(key), 0.001, 60.0): return false
	for key: String in ["incoming_power_multiplier", "outgoing_power_multiplier"]:
		if not CHECK._number(cfg.tag_switch.get(key), 0.001, 4.0): return false
	if not cfg.item_throw.get("allowed_kinds") is Array or cfg.item_throw.allowed_kinds.is_empty() \
		or not cfg.item_throw.get("forbidden_kinds") is Array: return false
	for kind: Variant in cfg.item_throw.allowed_kinds:
		if not kind is String or kind not in ["consumable", "food"]: return false
	for kind: String in ["orb", "key", "weapon"]:
		if not cfg.item_throw.forbidden_kinds.has(kind): return false
	return typeof(cfg.snare.get("wild_only")) == TYPE_BOOL and cfg.snare.wild_only


static func gear_profile(tier: int) -> Dictionary:
	var cfg := config()
	if not valid_config(cfg) or tier < 1 or tier > 4: return {}
	var profile: Dictionary = cfg.gear_tiers[str(tier)].duplicate(true)
	profile["tier"] = tier
	return profile


## Arithmetic only; this never mutates/grants a meter. Actual entitlement is
## checked by the host hostile-debit transaction, not a slot label supplied
## by a client or a presentation callback.
static func landed_gain(slot: String, admitted_tier: int) -> float:
	var profile := gear_profile(admitted_tier)
	if profile.is_empty() or slot not in ["quick", "charged", "utility"]: return 0.0
	return float(config().meter.gain[slot]) * float(profile.meter_rate)


static func empty_state(encounter_id: String, character_id: String, admitted_tier: int) -> Dictionary:
	var gear := gear_profile(admitted_tier)
	if not CHECK._identity(encounter_id) or not CHECK._identity(character_id) or gear.is_empty(): return {}
	return {"encounter_id": encounter_id, "character_id": character_id, "gear": gear,
		"revision": 0, "meter": 0.0, "last_sequence": 0, "receipts": {}, "rally_until_ms": 0,
		"snare": {}, "last_landed_ms": -1, "last_landed_uid": ""}


## Exact client request shape from COMBAT10.3. The host supplies active UID,
## generation, admitted owned UIDs and real legal-action/item/target readers.
## This is a detached proposal only: no bag debit, HP, pose, scene, callback,
## save or live meter write occurs. External transaction failure discards it.
static func stage(state: Dictionary, intent: Dictionary, host: Dictionary,
		authority: RefCounted = null) -> Dictionary:
	var cfg := config()
	if not valid_config(cfg) or state.is_empty(): return _refuse("invalid_config")
	if intent.size() != 4 or not intent.get("encounter_id") is String \
		or typeof(intent.get("generation")) != TYPE_INT or not _whole(intent.generation, 1, 2147483647) \
		or typeof(intent.get("sequence")) != TYPE_INT or not _whole(intent.sequence, 1, 2147483647) \
		or not intent.get("command_id") is String: return _refuse("malformed")
	if not CHECK._identity(state.get("encounter_id")) or not CHECK._identity(state.get("character_id")) \
		or not state.get("receipts") is Dictionary or not state.get("snare") is Dictionary \
		or not _whole(state.get("rally_until_ms"), 0, 9007199254740991): return _refuse("invalid_state")
	if intent.encounter_id != state.get("encounter_id") or host.get("encounter_id") != intent.encounter_id \
		or host.get("character_id") != state.get("character_id") \
		or typeof(host.get("generation")) != TYPE_INT or host.generation != intent.generation or host.get("phase") != "active" \
		or host.get("participant") != true: return _refuse("wrong_scope")
	var uid: Variant = host.get("active_uid")
	var owned: Variant = host.get("owned_uids")
	if not CHECK._identity(uid) or not _valid_owned(owned) \
		or not owned.has(uid) or host.get("active_alive") != true \
		or not _whole(host.get("now_ms"), 0, 9007199254740991): return _refuse("invalid_actor")
	var command := str(intent.command_id)
	if command not in ["rally", "item_throw", "tag_switch", "snare"]: return _refuse("unknown_command")
	# Resolve the existing canonical actor/participant anchor, not a claimed
	# tier in state/context. No Script instance can arrive through an RPC.
	if authority == null or authority.get_script() == null \
		or authority.get_script().resource_path != "res://scripts/net/encounter_host.gd" \
		or typeof(host.get("peer_id")) != TYPE_INT or int(host.peer_id) <= 0:
		return _refuse("admission_not_ready")
	var anchor: Dictionary = authority.call("command_gear_anchor", str(intent.encounter_id),
		int(host.peer_id), str(state.character_id), str(uid), int(intent.generation))
	if anchor.is_empty(): return _refuse("admission_not_ready")
	if not CHECK._number(state.get("meter"), 0.0, float(cfg.meter.max)) \
		or not _whole(state.get("revision"), 0, 2147483646) \
		or not state.get("gear") is Dictionary: return _refuse("invalid_state")
	var gear: Dictionary = state.gear
	if not _whole(anchor.get("tier"), 1, 4) or anchor != gear_profile(int(anchor.tier)) \
		or gear != anchor: return _refuse("invalid_gear")
	var receipts: Dictionary = state.get("receipts", {})
	var key := "%d:%d" % [int(intent.generation), int(intent.sequence)]
	var raw_prior: Variant = receipts.get(key, {})
	if not raw_prior is Dictionary: return _refuse("invalid_state")
	var prior: Dictionary = raw_prior
	if not prior.is_empty():
		if not prior.get("intent") is Dictionary or not prior.get("effect") is Dictionary \
			or not CHECK._identity(prior.get("source_uid")): return _refuse("invalid_state")
		if prior.intent != intent or prior.source_uid != uid: return _refuse("receipt_conflict")
		return {"ok": true, "duplicate": true, "receipt": prior.duplicate(true)}
	if not _whole(state.get("last_sequence"), 0, 2147483647) \
		or int(intent.sequence) <= int(state.last_sequence): return _refuse("replayed_sequence")
	if receipts.size() >= int(cfg.receipt_limit_per_player): return _refuse("receipt_budget")
	if host.get("command_allowed") != true: return _refuse("illegal_state")
	var cost := float(cfg[command].cost)
	if float(state.meter) < cost: return _refuse("insufficient_meter")
	var now := int(host.now_ms)
	var effect := {"command_id": command, "owner_character_id": str(state.character_id),
		"source_uid": str(uid), "hp_damage": 0.0, "poise_damage": 0.0}
	if command == "rally":
		effect.merge({"target_uid": str(uid), "duration_s": float(cfg.rally.duration_s),
			"damage_multiplier": float(cfg.rally.damage_multiplier), "wind_regen_multiplier": float(cfg.rally.wind_regen_multiplier)})
	elif command == "item_throw":
		# Item identity/type/count are read through the existing host inventory
		# consumption preflight. No orb, key, bomb or damaging consumable door.
		if host.get("item_use_ready") != true or not CHECK._identity(host.get("pouch_item_id")) \
			or not _whole(host.get("pouch_item_index"), 0, int(gear.pouch_size) - 1) \
			or host.get("earlier_pouch_slots_empty") != true \
			or not cfg.item_throw.allowed_kinds.has(host.get("pouch_item_kind")) \
			or cfg.item_throw.forbidden_kinds.has(host.get("pouch_item_kind")) \
			or host.get("item_deals_damage") != false: return _refuse("pouch_empty_or_invalid")
		effect.merge({"target_uid": str(uid), "item_id": str(host.pouch_item_id), "requires_item_commit": true})
	elif command == "tag_switch":
		var incoming: Variant = host.get("next_uid")
		if not CHECK._identity(incoming) or incoming == uid or not owned.has(incoming) \
			or host.get("next_alive") != true or host.get("switch_allowed") != true \
			or not _whole(host.get("switch_ready_ms"), 0, 9007199254740991) \
			or int(host.switch_ready_ms) > now or not _whole(state.get("last_landed_ms"), 0, now) \
			or state.get("last_landed_uid") != uid \
			or now - int(state.last_landed_ms) > ceili(float(cfg.tag_switch.combo_window_s) * 1000.0): return _refuse("no_combo_window")
		effect.merge({"incoming_uid": incoming, "switch_lock_s": float(cfg.tag_switch.switch_lock_s),
			"creature_strikes": [{"source_uid": str(uid), "source_kind": "creature", "power_multiplier": float(cfg.tag_switch.outgoing_power_multiplier)},
				{"source_uid": incoming, "source_kind": "creature", "power_multiplier": float(cfg.tag_switch.incoming_power_multiplier)}]})
	else:
		var record: Dictionary = authority.call("record", str(intent.encounter_id))
		var opponent: Variant = record.get("opponent")
		if record.get("kind") != "wild" or not opponent is Dictionary \
			or opponent.get("owner_npc") != "" or not CHECK._number(opponent.get("hp"), 0.001, 1000000000.0) \
			or not opponent.get("card") is Dictionary \
			or opponent.card.get("uid") != host.get("opponent_uid"): return _refuse("not_snareable")
		if host.get("opponent_kind") != "wild" or host.get("opponent_owned") != false \
			or host.get("snare_immune") != false or host.get("opponent_alive") != true \
			or not CHECK._identity(host.get("opponent_uid")) or host.opponent_uid == uid: return _refuse("not_snareable")
		effect.merge({"target_uid": str(host.opponent_uid), "duration_s": float(cfg.snare.duration_s),
			"movement_multiplier": float(gear.snare_movement_multiplier), "catch_bonus": float(gear.snare_catch_bonus)})
	var next := state.duplicate(true)
	next.meter = float(state.meter) - cost
	next.last_sequence = int(intent.sequence)
	next.revision = int(state.revision) + 1
	if command == "rally": next.rally_until_ms = maxi(int(state.get("rally_until_ms", 0)), now + ceili(float(cfg.rally.duration_s) * 1000.0))
	if command == "snare":
		var previous: Dictionary = state.get("snare", {})
		var expiry := now + ceili(float(cfg.snare.duration_s) * 1000.0)
		if previous.get("target_uid") == effect.target_uid: expiry = maxi(expiry, int(previous.get("expires_at_ms", 0)))
		next.snare = {"target_uid": effect.target_uid, "owner_character_id": state.character_id,
			"expires_at_ms": expiry, "catch_bonus": effect.catch_bonus, "movement_multiplier": effect.movement_multiplier}
	var receipt := {"intent": intent.duplicate(true), "source_uid": str(uid), "effect": effect.duplicate(true)}
	next.receipts[key] = receipt
	return {"ok": true, "duplicate": false, "expected_revision": int(state.revision),
		"cost": cost, "effect": effect, "receipt": receipt, "state": next}


## Catch-only presentation/arithmetic reader for the same owner's snare.
## Shared target movement is applied by the host status transaction, not
## accumulated once per player's state. This getter neither consumes nor
## grants an Orb and never authorizes capture of an ineligible creature.
static func snare_catch_bonus(state: Dictionary, character_id: String,
		target_uid: String, now_ms: int) -> float:
	if not CHECK._identity(character_id) or not CHECK._identity(target_uid) or now_ms < 0 \
		or state.get("character_id") != character_id or not state.get("snare") is Dictionary: return 0.0
	var snare: Dictionary = state.snare
	if snare.get("owner_character_id") != character_id or snare.get("target_uid") != target_uid \
		or not _whole(snare.get("expires_at_ms"), 0, 9007199254740991) \
		or int(snare.expires_at_ms) <= now_ms or not CHECK._number(snare.get("catch_bonus"), 0.0, 1.0): return 0.0
	return float(snare.catch_bonus)


static func _whole(value: Variant, low: int, high: int) -> bool:
	return CHECK._number(value, float(low), float(high)) and float(value) == floorf(float(value))


static func _valid_owned(raw: Variant) -> bool:
	if not raw is Array or raw.is_empty() or raw.size() > 5: return false
	var seen := {}
	for uid: Variant in raw:
		if not CHECK._identity(uid) or seen.has(uid): return false
		seen[uid] = true
	return true


static func _refuse(code: String) -> Dictionary:
	return {"ok": false, "code": code}
