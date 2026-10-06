extends RefCounted

## Detached staging over the EXISTING EncounterHost participant, action receipt
## and target status row. This is not an authority registry or a journal.
## Only the host's accepted-action producer calls it, using retained canonical
## actor/geometry/ownership values. RPC packets contain ONLY intent().
## Commit this plan inside the existing action transaction, after durable item
## debit + exact owner ACK for item throw. Never award from HUD/VFX hit events.
const CONFIG_PATH := "res://data/config/tether_commands.json"
const COMMAND_IDS := ["item_throw", "rally", "tag_combo", "snare"]
const EFFECTS := preload("res://scripts/combat/utility_effects.gd")
static var _config: Dictionary = {}
static var _loaded := false

static func config() -> Dictionary:
	if not _loaded:
		_loaded = true
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if valid_config(raw): _config = raw
	return _config

static func valid_config(raw: Variant) -> bool:
	if not raw is Dictionary or raw.get("version") != 1 \
		or raw.get("scope") != "encounter_participant": return false
	if not raw.get("feature_flags") is Dictionary: return false
	for flag: String in ["runtime_enabled", "network_enabled", "ui_enabled"]:
		if not raw.feature_flags.get(flag) is bool: return false
	if not raw.get("meter") is Dictionary or not raw.meter.get("gain") is Dictionary \
		or not _number(raw.meter.get("maximum"), 1, 10000): return false
	for slot: String in ["quick", "charged", "utility", "ultimate", "tag_combo"]:
		if not _number(raw.meter.gain.get(slot), 0, float(raw.meter.maximum)): return false
	if raw.meter.gain.ultimate != 0 or raw.meter.gain.tag_combo != 0: return false
	if not _number(raw.get("combo_window_s"), 0.01, 5) \
		or not _number(raw.get("switch_lockout_s"), 0.01, 10): return false
	if not raw.get("commands") is Dictionary or raw.commands.size() != COMMAND_IDS.size(): return false
	for id: String in COMMAND_IDS:
		var row: Variant = raw.commands.get(id)
		if not row is Dictionary or not _number(row.get("cost"), 1, float(raw.meter.maximum)) \
			or not EFFECTS._identity(row.get("label")) or not EFFECTS._identity(row.get("action")): return false
	if not _number(raw.commands.rally.get("duration_s"), 0.01, 30) \
		or not _number(raw.commands.rally.get("damage_multiplier"), 1, 1.6) \
		or not _number(raw.commands.rally.get("wind_regen_multiplier"), 1, 2) \
		or not _number(raw.commands.snare.get("duration_s"), 0.01, 10) \
		or not _number(raw.commands.tag_combo.get("incoming_quick_multiplier"), 0.01, 2) \
		or not _number(raw.commands.tag_combo.get("outgoing_quick_multiplier"), 0.01, 1): return false
	if not raw.get("snare_bounds") is Dictionary \
		or not _number(raw.snare_bounds.get("minimum_movement_multiplier"), 0.01, 1) \
		or not _number(raw.snare_bounds.get("maximum_catch_bonus"), 0, 0.25): return false
	if not raw.get("tiers") is Dictionary or raw.tiers.size() != 5: return false
	var previous := {"meter_rate": 0.0, "pouch_size": 0, "catch_bonus": 0.0, "movement_multiplier": 1.0}
	for tier: int in 5:
		var row: Variant = raw.tiers.get(str(tier))
		if not row is Dictionary or not _number(row.get("meter_rate"), 1, 2) \
			or not _integer(row.get("pouch_size"), 1, 3) \
			or not _number(row.get("movement_multiplier"), float(raw.snare_bounds.minimum_movement_multiplier), 1) \
			or not _number(row.get("catch_bonus"), 0, float(raw.snare_bounds.maximum_catch_bonus)): return false
		if row.meter_rate < previous.meter_rate or row.pouch_size < previous.pouch_size \
			or row.catch_bonus < previous.catch_bonus or row.movement_multiplier > previous.movement_multiplier: return false
		previous = row
	if not raw.get("item_bounds") is Dictionary: return false
	var item: Dictionary = raw.item_bounds
	for key: String in ["maximum_heal", "maximum_nourishment", "maximum_happiness", "maximum_buff_seconds"]:
		if not _number(item.get(key), 0.001, 1000000): return false
	if not _number(item.get("minimum_buff_scale"), 0.001, 1) \
		or not _number(item.get("maximum_buff_scale"), 1, 2) \
		or not item.get("buff_stats") is Array: return false
	for stat: Variant in item.buff_stats:
		if stat not in ["attack", "defence", "speed", "wind_regen"]: return false
	return raw.get("refusals") is Dictionary and raw.get("ui") is Dictionary

static func enabled(flag: String = "runtime_enabled") -> bool:
	return bool(config().get("feature_flags", {}).get(flag, false))

## These authored slot bindings remain the single rebindable input source.
## Exploration uses items; enabled combat assigns the same directions here.
static func input_action(command_id: String) -> String:
	return str({"item_throw": "hotbar_2", "rally": "hotbar_3", "tag_combo": "hotbar_4", "snare": "hotbar_5"}.get(command_id, ""))

static func tier_profile(tier: int) -> Dictionary:
	return (config().get("tiers", {}).get(str(tier), {}) as Dictionary).duplicate(true)

## Kept on the existing participant; meter survives own switches but lapses at
## encounter exit. The owning host reads equipped backpack and lessons ONCE at
## admission. No client tier, inventory, unlock, HP or UID is accepted here.
static func admission(character_id: String, encounter_id: String, tier: int) -> Dictionary:
	if not EFFECTS._identity(character_id) or not EFFECTS._identity(encounter_id) \
		or tier_profile(tier).is_empty(): return {}
	return {"character_id": character_id, "encounter_id": encounter_id,
		"tier": tier, "meter": 0.0, "revision": 0, "last_sequence": 0,
		"combo": {}, "rally_until_ms": 0, "switch_until_ms": 0}

static func intent(encounter_id: String, generation: int, sequence: int, command_id: String) -> Dictionary:
	return {"encounter_id": encounter_id, "generation": generation,
		"sequence": sequence, "command_id": command_id}

static func valid_intent(raw: Variant) -> bool:
	return raw is Dictionary and raw.size() == 4 and EFFECTS._identity(raw.get("encounter_id")) \
		and _integer(raw.get("generation"), 1, 2147483647) \
		and _integer(raw.get("sequence"), 1, 2147483647) and COMMAND_IDS.has(raw.get("command_id"))

static func _valid_state(state: Dictionary, actor: Dictionary) -> bool:
	return not config().is_empty() and state.get("character_id") == actor.get("character_id") \
		and state.get("encounter_id") == actor.get("encounter_id") \
		and EFFECTS._identity(state.get("character_id")) and EFFECTS._identity(state.get("encounter_id")) \
		and EFFECTS._identity(actor.get("creature_uid")) and _integer(actor.get("generation"), 1, 2147483647) \
		and _number(actor.get("hp"), 0.001, INF) and _number(state.get("meter"), 0, float(config().get("meter", {}).get("maximum", 0))) \
		and _integer(state.get("revision"), 0, 2147483646) and _integer(state.get("last_sequence"), 0, 2147483647) \
		and _integer(state.get("rally_until_ms"), 0, 9223372036854775807) \
		and _integer(state.get("switch_until_ms"), 0, 9223372036854775807) \
		and state.get("combo") is Dictionary and _integer(state.get("tier"), 0, 4)

## Called in the SAME accepted hostile HP-debit transaction as F23 mastery.
## Marker is placed on the same retained hit receipt, not a sequence watermark:
## projectiles may arrive out of order. Original frozen actor binding required.
static func stage_landed(state: Dictionary, actor: Dictionary, frozen: Dictionary,
		receipt: Dictionary, actual_debit: float, target_uid: String, target_generation: int, now_ms: int) -> Dictionary:
	if not enabled(): return refuse("disabled")
	if not _valid_state(state, actor) or now_ms < 0 or not frozen.get("actor_binding") is Dictionary:
		return refuse("stale_actor")
	for key: String in ["character_id", "creature_uid", "encounter_id", "generation"]:
		if frozen.actor_binding.get(key) != actor.get(key): return refuse("stale_actor")
	if not EFFECTS._identity(frozen.get("action_id")) or receipt.get("action_id") != frozen.action_id \
		or receipt.get("attacker_uid") != actor.creature_uid or receipt.get("generation") != actor.generation \
		or receipt.get("landed") != true or receipt.get("command_meter_credited", false) != false \
		or not is_finite(actual_debit) or actual_debit <= 0 or not EFFECTS._identity(target_uid) \
		or target_generation < 1 or target_generation > 2147483647 \
		or target_uid == actor.creature_uid: return refuse("replayed")
	var slot := str(frozen.get("slot", ""))
	if not config().meter.gain.has(slot) or bool(frozen.get("tag_combo", false)): return refuse("invalid_request")
	var next := state.duplicate(true)
	var stamped := receipt.duplicate(true)
	stamped["command_meter_credited"] = true
	next.meter = minf(float(config().meter.maximum), float(state.meter) \
		+ float(config().meter.gain[slot]) * float(tier_profile(int(state.tier)).meter_rate))
	if slot != "ultimate":
		next.combo = {"source_uid": actor.creature_uid, "source_generation": actor.generation,
			"target_uid": target_uid, "target_generation": target_generation, "action_id": frozen.action_id,
			"until_ms": now_ms + int(float(config().combo_window_s) * 1000)}
	next.revision = int(state.revision) + 1
	return {"ok": true, "state": next, "receipt": stamped}

## host is a detached trusted view from the same live canonical participant.
## command receipt/action_id is allocated by the EXISTING accepted action path.
## No callbacks, side effects or mutations happen during staging.
static func stage_command(state: Dictionary, request: Dictionary, host: Dictionary,
		now_ms: int) -> Dictionary:
	if not enabled(): return refuse("disabled")
	if not valid_intent(request) or now_ms < 0 or not host.get("actor") is Dictionary: return refuse("invalid_request")
	var actor: Dictionary = host.actor
	if not _valid_state(state, actor) or request.encounter_id != state.encounter_id \
		or int(request.generation) != int(actor.generation) or host.get("owner_admitted") != true \
		or host.get("encounter_active") != true or not _integer(host.get("peer_id"), 1, 2147483647): return refuse("stale_actor")
	if int(request.sequence) <= int(state.last_sequence): return refuse("replayed")
	var accepted: Variant = host.get("accepted_receipt")
	if not accepted is Dictionary or not EFFECTS._identity(accepted.get("action_id")) \
		or accepted.get("character_id") != state.character_id or accepted.get("encounter_id") != state.encounter_id \
		or accepted.get("attacker_uid") != actor.creature_uid or accepted.get("generation") != actor.generation \
		or accepted.get("sequence") != request.sequence or accepted.get("command_id") != request.command_id \
		or accepted.get("command_committed") != false: return refuse("replayed")
	var id: String = request.command_id
	if not host.get("unlocked_commands") is Array or not host.unlocked_commands.has(id): return refuse("locked")
	var row: Dictionary = config().commands[id]
	if float(state.meter) < float(row.cost): return refuse("meter")
	var next := state.duplicate(true)
	var effect: Dictionary = {}
	match id:
		"rally":
			next.rally_until_ms = now_ms + int(float(row.duration_s) * 1000)
			effect = {"kind": "rally", "character_id": state.character_id,
				"until_ms": next.rally_until_ms, "damage_multiplier": row.damage_multiplier,
				"wind_regen_multiplier": row.wind_regen_multiplier}
		"item_throw":
			if not host.get("pouch") is Array or not host.get("items") is Dictionary \
				or not host.get("inventory_counts") is Dictionary: return refuse("pouch_invalid")
			var item := first_pouch_item(host.pouch, host.items, host.inventory_counts, int(state.tier))
			if item.is_empty(): return refuse("pouch_empty")
			# The durable transaction adapter preflights actual target resources and
			# freezes this SAME action identity; dispatch never calls local hotbar.
			if host.get("item_transaction_ready") != true or host.get("item_can_apply") != true:
				return refuse("transaction_unavailable")
			effect = {"kind": "item_throw", "character_id": state.character_id,
				"creature_uid": actor.creature_uid, "generation": actor.generation,
				"item_id": item, "count": 1, "action_id": accepted.action_id}
		"tag_combo":
			var combo: Dictionary = state.combo
			if combo.get("source_uid") != actor.creature_uid or combo.get("source_generation") != actor.generation \
				or not _integer(combo.get("until_ms"), 0, 9223372036854775807) \
				or now_ms >= int(combo.until_ms): return refuse("combo_window")
			if now_ms < int(state.switch_until_ms) or host.get("switch_allowed") != true: return refuse("switch_locked")
			var incoming: Variant = host.get("incoming")
			if not incoming is Dictionary or incoming.get("character_id") != state.character_id \
				or not EFFECTS._identity(incoming.get("creature_uid")) or incoming.creature_uid == actor.creature_uid \
				or not _number(incoming.get("hp"), 0.001, INF) \
				or not _integer(incoming.get("generation"), 1, 2147483647) \
				or host.get("incoming_is_next_owned") != true: return refuse("no_partner")
			var target: Variant = host.get("target")
			if not _valid_target(target) or target.uid != combo.get("target_uid") \
				or target.generation != combo.get("target_generation") \
				or host.get("combo_geometry_connected") != true: return refuse("invalid_target")
			effect = {"kind": "tag_combo", "character_id": state.character_id, "encounter_id": state.encounter_id,
				"target_uid": target.uid, "target_generation": target.generation,
				"strikes": [joint_strike(actor, target, accepted.action_id, "outgoing", float(row.outgoing_quick_multiplier)),
					joint_strike(incoming, target, accepted.action_id, "incoming", float(row.incoming_quick_multiplier))]}
			next.combo = {}
			next.switch_until_ms = now_ms + int(float(config().switch_lockout_s) * 1000)
		"snare":
			var target: Variant = host.get("target")
			if not _valid_target(target) or host.get("snare_geometry_connected") != true: return refuse("invalid_target")
			if target.get("ownership_kind") != "wild" or target.get("trainer_owned") != false: return refuse("trainer_target")
			if target.get("snare_immune") != false: return refuse("snare_immune")
			var tier := tier_profile(int(state.tier))
			effect = {"kind": "snare", "target_uid": target.uid, "target_generation": target.generation,
				"character_id": state.character_id, "until_ms": now_ms + int(float(row.duration_s) * 1000),
				"movement_multiplier": tier.movement_multiplier, "catch_bonus": tier.catch_bonus}
			if not host.get("target_snare") is Dictionary or not host.get("admitted_character_ids") is Array:
				return refuse("stale_actor")
			var status := snare_status(effect, host.target_snare, now_ms, host.admitted_character_ids)
			if status.is_empty(): return refuse("stale_actor")
			effect["status"] = status
	next.meter = float(state.meter) - float(row.cost)
	next.last_sequence = int(request.sequence)
	next.revision = int(state.revision) + 1
	var stamped: Dictionary = accepted.duplicate(true)
	stamped["command_committed"] = true
	return {"ok": true, "state": next, "effect": effect, "receipt": stamped,
		"expected_revision": state.revision, "requires_owner_debit_ack": id == "item_throw"}

## Both strikes enter the ordinary creature quick-move resolver, preserving
## the original+incoming UID, generation, mastery/type and immutable parent ID.
## Neither this module nor a trainer gesture directly subtracts HP or poise.
static func joint_strike(actor: Dictionary, target: Dictionary, action_id: String,
		part: String, multiplier: float) -> Dictionary:
	return {"source_kind": "creature", "attacker_uid": actor.creature_uid,
		"character_id": actor.character_id, "generation": actor.generation,
		"target_uid": target.uid, "target_generation": target.generation,
		"parent_action_id": action_id, "part": part, "slot": "quick",
		"power_multiplier": multiplier, "tag_combo": true, "meter_gain": 0.0}

## The owning action transaction stages BOTH strikes before switching bodies.
## It retains the outgoing actor until commit; querying only the new active
## creature would misattribute the parting strike. Actual damage is computed
## by the ordinary move cone/type/rolled-damage functions, then clamped in
## strike order against the same hostile HP. Caller commits HP, switch and the
## returned subreceipts together on the existing parent command receipt.
static func stage_joint_attack(effect: Dictionary, frozen_moves: Array,
		host: Dictionary, combat_config: Dictionary) -> Dictionary:
	var math := preload("res://scripts/combat/combat_math.gd")
	var chart := preload("res://scripts/combat/type_chart.gd")
	var moves := preload("res://scripts/creatures/move_db.gd").load_default()
	if effect.get("kind") != "tag_combo" or not effect.get("strikes") is Array \
		or effect.strikes.size() != 2 or frozen_moves.size() != 2 \
		or not host.get("actors") is Array or host.actors.size() != 2 \
		or not host.get("rolls") is Array or host.rolls.size() != 2 \
		or not host.get("target") is Dictionary: return refuse("invalid_request")
	var target: Dictionary = host.target
	if not _valid_target(target) or target.uid != effect.get("target_uid") \
		or target.generation != effect.get("target_generation") \
		or not EFFECTS._point(target.get("position")) \
		or not _number(target.get("defence"), 1, INF): return refuse("invalid_target")
	var bonus_cap: Variant = combat_config.get("damage", {}).get("max_bonus_product")
	if not _number(bonus_cap, 1, 2): return refuse("invalid_request")
	var hp := float(target.hp)
	var strikes: Array = []
	for index: int in 2:
		var strike: Variant = effect.strikes[index]
		var actor: Variant = host.actors[index]
		var move: Variant = frozen_moves[index]
		if not strike is Dictionary or not actor is Dictionary or not move is Dictionary \
			or not move.get("actor_binding") is Dictionary: return refuse("stale_actor")
		var part := "outgoing" if index == 0 else "incoming"
		var power := float(config().commands.tag_combo[part + "_quick_multiplier"])
		if strike.get("part") != part or strike.get("source_kind") != "creature" \
			or strike.get("parent_action_id") != effect.strikes[0].get("parent_action_id") \
			or not EFFECTS._identity(strike.get("parent_action_id")) \
			or strike.get("attacker_uid") != actor.get("creature_uid") \
			or strike.get("generation") != actor.get("generation") \
			or strike.get("character_id") != effect.get("character_id") \
			or actor.get("character_id") != effect.get("character_id") \
			or actor.get("encounter_id") != effect.get("encounter_id") \
			or not EFFECTS._identity(actor.get("creature_uid")) \
			or not _integer(actor.get("generation"), 1, 2147483647) \
			or strike.get("target_uid") != target.uid or strike.get("target_generation") != target.generation \
			or strike.get("power_multiplier") != power or strike.get("tag_combo") != true \
			or move.get("slot") != "quick" or not _number(actor.get("hp"), 0.001, INF) \
			or not _number(actor.get("attack"), 1, INF) or not _number(host.rolls[index], 0, 1) \
			or not EFFECTS._point(actor.get("position")) or not EFFECTS._point(actor.get("facing")) \
			or not _number(actor.get("bonus_product"), 1, float(bonus_cap)) \
			or not _number(move.get("power_multiplier"), 1, INF) \
			or not _number(move.get("power"), 0.001, INF) \
			or not _number(move.get("range"), 0.001, 100) \
			or not _number(move.get("cone_degrees"), 0.001, 360) \
			or not EFFECTS._identity(move.get("move_id")): return refuse("stale_actor")
		for key: String in ["character_id", "creature_uid", "encounter_id", "generation"]:
			if actor.get(key) != move.actor_binding.get(key): return refuse("stale_actor")
		if index == 1 and actor.creature_uid == host.actors[0].creature_uid: return refuse("no_partner")
		var connected := math.move_connects(move, actor.position, actor.facing, target.position)
		if moves.move(str(move.move_id)).get("slot") != "quick": return refuse("stale_actor")
		var type_scale := chart.multiplier_dual(moves.type_of(str(move.move_id)),
			str(target.get("type", "")), str(target.get("secondary_type", "")))
		# Host profiles already include mastery, breakthroughs and gear in power.
		# Match host_roll_damage's authored named multiplier and type lookup; the
		# Tag fraction scales the resulting ordinary quick hit exactly once.
		var damage := math.rolled_damage(float(move.power),
			float(actor.attack), float(target.defence), float(host.rolls[index]),
			moves.power(str(move.move_id)), type_scale) * power * float(actor.bonus_product) if connected else 0.0
		damage = clampf(damage, 0.0, hp)
		var receipt: Dictionary = strike.duplicate(true)
		receipt["action_id"] = JSON.stringify([strike.parent_action_id, part, actor.creature_uid, actor.generation]).sha256_text()
		receipt["move_id"] = move.move_id
		receipt["landed"] = damage > 0.0
		receipt["actual_hp_debit"] = damage
		receipt["target_hp_before"] = hp
		hp -= damage
		receipt["target_hp_after"] = hp
		strikes.append(receipt)
	return {"ok": true, "strikes": strikes, "hp_before": target.hp, "hp_after": hp,
		"switched_to_uid": host.actors[1].creature_uid}

static func _valid_target(target: Variant) -> bool:
	return target is Dictionary and EFFECTS._identity(target.get("uid")) \
		and _integer(target.get("generation"), 1, 2147483647) \
		and _number(target.get("hp"), 0.001, INF) and target.get("hostile") == true

## Pouch is an ordered assignment, never an inventory copy or a supply.
static func valid_pouch(raw: Variant, items: Dictionary, tier: int) -> bool:
	if not raw is Array or tier_profile(tier).is_empty() or raw.size() > 3: return false
	for item: Variant in raw:
		if not item is String or (not item.is_empty() and not support_item(items.get(item))): return false
	return true

static func support_item(row: Variant) -> bool:
	if not row is Dictionary or row.get("kind") not in ["food", "consumable"]: return false
	if config().is_empty(): return false
	var bounds: Dictionary = config().item_bounds
	# Refuse revival, damage, catch or arbitrary effects; existing items use
	# heal, satiety, creature_buff. The transaction applies exactly these fields.
	for key: String in ["damage", "base_power", "poise_damage", "revive_fraction", "revive", "orb", "catch_bonus"]:
		if row.has(key): return false
	if row.has("heal") and _number(row.heal, 0.001, float(bounds.maximum_heal)): return true
	var food: Variant = row.get("creature_food")
	if food is Dictionary and _number(food.get("nourishment"), 0.001, float(bounds.maximum_nourishment)) \
		and _number(food.get("happiness", 0), 0, float(bounds.maximum_happiness)): return true
	var buff: Variant = row.get("creature_buff")
	return buff is Dictionary and EFFECTS._identity(buff.get("id")) \
		and bounds.buff_stats.has(buff.get("stat")) \
		and _number(buff.get("scale"), float(bounds.minimum_buff_scale), float(bounds.maximum_buff_scale)) \
		and _number(buff.get("duration_s"), 0.001, float(bounds.maximum_buff_seconds))

static func first_pouch_item(pouch: Array, items: Dictionary, counts: Dictionary, tier: int) -> String:
	if not valid_pouch(pouch, items, tier): return ""
	for index: int in mini(pouch.size(), int(tier_profile(tier).pouch_size)):
		var item: String = pouch[index]
		if not item.is_empty() and _integer(counts.get(item), 1, 2147483647): return item
	return ""

## Prepare the owned inventory + creature candidate for the existing saved
## character transaction. The adapter must first settle its canonical live
## baseline and retain this exact original until owner ACK; this helper never
## replaces a live actor, spends meter, publishes a buff or writes a file.
static func stage_item_use(current: Dictionary, effect: Dictionary, host: Dictionary,
		frozen_runtime_authorized: bool = false) -> Dictionary:
	# A validated immutable saved row must remain replayable with gameplay OFF.
	# Live callers still use the default and cannot start a disabled command.
	if not enabled() and not frozen_runtime_authorized: return refuse("disabled")
	if not host.get("actor") is Dictionary: return refuse("stale_actor")
	var record: GDScript = load("res://scripts/net/character_record_rules.gd")
	var actor: Dictionary = host.get("actor", {})
	if not record.errors(current, str(current.get("character_id", ""))).is_empty() \
		or effect.size() != 7 or effect.get("kind") != "item_throw" or effect.get("count") != 1 \
		or effect.get("character_id") != current.get("character_id") \
		or not EFFECTS._identity(effect.get("action_id")) or not EFFECTS._identity(effect.get("item_id")) \
		or host.get("owner_admitted") != true or host.get("encounter_active") != true \
		or not _integer(actor.get("generation"), 1, 2147483647): return refuse("stale_actor")
	for key: String in ["character_id", "creature_uid", "generation"]:
		if effect.get(key) != actor.get(key): return refuse("stale_actor")
	var selected := -1
	for index: int in current.party.size():
		if current.party[index].uid == effect.creature_uid:
			if selected != -1: return refuse("stale_actor")
			selected = index
	if selected == -1: return refuse("stale_actor")
	var owned: Dictionary = current.party[selected]
	if owned.fainted or float(owned.hp) <= 0.0 or actor.get("hp") != owned.hp \
		or actor.get("max_hp") != owned.max_hp: return refuse("transaction_unavailable")
	var rules := preload("res://scripts/world/death_satchel_rules.gd")
	var items: RefCounted = rules.db()
	var equipment := preload("res://scripts/player/player_equipment.gd").new()
	equipment.configure(items)
	equipment.load_data(current.equipment)
	var inventory: RefCounted = rules.inventory_from(current.inventory)
	var counts := {}
	for stack: Variant in current.inventory:
		if stack is Dictionary: counts[stack.id] = inventory.call("count", str(stack.id))
	var pouch: Array = current.redesign_character.get("tether_pouch", [])
	if first_pouch_item(pouch, items.get("_items"), counts, equipment.command_pouch_tier()) != effect.item_id:
		return refuse("pouch_empty")
	var codec: GDScript = load("res://scripts/save/water_capture_codec.gd")
	var creature: RefCounted = codec.decode_owned(owned, current.redesign_character)
	if creature == null: return refuse("stale_actor")
	var definition: Dictionary = items.call("definition", str(effect.item_id))
	var buff := {}
	if definition.has("creature_food"):
		var condition := preload("res://scripts/creatures/creature_condition.gd")
		if condition.feed(creature, condition.config(), definition.creature_food).get("accepted") != true:
			return refuse("transaction_unavailable")
	elif definition.has("creature_buff"):
		buff = definition.creature_buff.duplicate(true)
		if creature.call("apply_buff", str(buff.id), str(buff.stat), float(buff.scale), float(buff.duration_s)) != true:
			return refuse("transaction_unavailable")
	elif float(creature.call("heal", float(definition.get("heal", 0.0)))) <= 0.0:
		return refuse("transaction_unavailable")
	if inventory.call("remove", str(effect.item_id), 1) != true: return refuse("pouch_empty")
	var next := current.duplicate(true)
	next.inventory = rules.slots(inventory)
	for key: String in ["hp", "nourishment", "happiness"]:
		next.party[selected][key] = creature.get(key)
	if not record.errors(next, str(current.character_id)).is_empty(): return refuse("transaction_unavailable")
	return {"ok": true, "before": current.duplicate(true), "state": next,
		"effect": effect.duplicate(true), "buff": buff, "requires_owner_debit_ack": true}

static func stage_pouch_assignment(current: Array, index: int, item_id: String,
		tier: int, items: Dictionary, outside_combat: bool) -> Dictionary:
	if not outside_combat or not valid_pouch(current, items, tier) \
		or index < 0 or index >= int(tier_profile(tier).get("pouch_size", 0)) \
		or (not item_id.is_empty() and not support_item(items.get(item_id))): return refuse("pouch_invalid")
	var next := current.duplicate()
	while next.size() <= index: next.append("")
	next[index] = item_id
	return {"ok": true, "expected": current.duplicate(), "pouch": next}

static func rally_modifiers(state: Dictionary, character_id: String, now_ms: int) -> Dictionary:
	if state.get("character_id") != character_id or now_ms < 0 \
		or now_ms >= int(state.get("rally_until_ms", 0)): return {"damage": 1.0, "wind_regen": 1.0}
	var row: Dictionary = config().commands.rally
	return {"damage": row.damage_multiplier, "wind_regen": row.wind_regen_multiplier}

## Refresh one shared target slow. Preserve each commander's unstacked catch
## benefit until its own expiry. Stage this before spending command meter.
static func snare_status(effect: Dictionary, previous: Dictionary, now_ms: int,
		admitted_characters: Array) -> Dictionary:
	if effect.get("kind") != "snare" or now_ms < 0 or admitted_characters.size() > 4 \
		or not admitted_characters.has(effect.get("character_id")): return {}
	for character: Variant in admitted_characters:
		if not EFFECTS._identity(character): return {}
	var next := effect.duplicate(true)
	var grants: Dictionary = {}
	if previous.get("target_uid") == effect.get("target_uid") \
		and previous.get("target_generation") == effect.get("target_generation"):
		for character: String in previous.get("catch_grants", {}):
			var grant: Variant = previous.catch_grants[character]
			if admitted_characters.has(character) and grant is Dictionary \
				and _integer(grant.get("until_ms"), now_ms + 1, 9223372036854775807):
				grants[character] = grant.duplicate(true)
	# Existing encounter admits at most four stable characters. Each gets only
	# their own unstacked bonus; a refresh does not extend somebody else's bonus.
	# Status lifetime bounds history; the encounter roster may replace a peer.
	# Do not equate four concurrent participants with four historical owners.
	grants[effect.character_id] = {"until_ms": effect.until_ms, "bonus": effect.catch_bonus}
	next["catch_grants"] = grants
	return next

## Only the host translates its status clock for the existing record carrier.
## Guests render remaining time; they never compare a foreign host timestamp
## with their own process clock or import catch grants into presentation.
static func snare_presentation(status: Dictionary, target_uid: String, target_generation: int,
		now_ms: int) -> Dictionary:
	if not EFFECTS._identity(target_uid) or target_generation < 1 \
		or status.get("kind") != "snare" or status.get("target_uid") != target_uid \
		or status.get("target_generation") != target_generation or now_ms < 0 \
		or not EFFECTS._identity(status.get("character_id")) \
		or not _integer(status.get("until_ms"), now_ms + 1, 9223372036854775807): return {}
	return {"target_uid": target_uid, "target_generation": target_generation,
		"character_id": status.character_id, "remaining_s": minf(float(config().commands.snare.duration_s),
			float(int(status.until_ms) - now_ms) / 1000.0)}

static func snare_modifiers(status: Dictionary, target_uid: String, target_generation: int,
		character_id: String, now_ms: int) -> Dictionary:
	var neutral := {"movement": 1.0, "catch_bonus": 0.0}
	if status.get("kind") != "snare" or status.get("target_uid") != target_uid \
		or status.get("target_generation") != target_generation or now_ms < 0 \
		or now_ms >= int(status.get("until_ms", 0)): return neutral
	var bounds: Dictionary = config().snare_bounds
	var grant: Dictionary = (status.get("catch_grants", {}) as Dictionary).get(character_id, {})
	var bonus := float(grant.get("bonus", 0)) if now_ms < int(grant.get("until_ms", 0)) else 0.0
	return {"movement": clampf(float(status.get("movement_multiplier", 1)), float(bounds.minimum_movement_multiplier), 1),
		"catch_bonus": clampf(bonus, 0, float(bounds.maximum_catch_bonus))}

static func refuse(code: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": str(config().get("refusals", {}).get(code, "Command unavailable."))}

static func _number(value: Variant, minimum: float, maximum: float) -> bool:
	return EFFECTS._number(value, minimum, maximum)

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return _number(value, float(minimum), float(maximum)) and float(value) == floorf(float(value))
