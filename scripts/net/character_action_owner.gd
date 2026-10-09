extends RefCounted

## Runtime installer for the same saved per-character training carrier.
## It changes preserved live UID instances; it never loads/rebuilds a party.
const STARTER_FLAG := "opening:starter_granted"
const DELIVERY := preload("res://scripts/net/character_action_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")


static func apply_owner(game: Node, row: Dictionary) -> Dictionary:
	if game == null: return _deny("owner_game_unavailable")
	var saver: Variant = game.get("save_system")
	if not saver is RefCounted or not saver.has_method("finish_fallback") or not saver.has_method("save_character_prepared"):
		return _deny("prepared_owner_writer_missing")
	saver.call("finish_fallback") # Flush BEFORE freezing current owner/epoch.
	if saver.call("fallback_busy") == true: return _deny("fallback_busy")
	var player: Variant = game.get("local")
	var world: Variant = game.get("world")
	var session: Variant = game.get("session")
	if not player is RefCounted or not world is RefCounted or not session is Node: return _deny("owner_context_missing")
	var epoch := str(session.call("_altar_current_epoch"))
	if epoch.is_empty() or not DELIVERY.valid(row, RECORD.errors, str(player.character_id), str(world.reward_delivery_namespace), str(world.world_id)) \
		or not ESSENCE._equivalent(world.reward_deliveries.get(row.delivery_id), row): return _deny("foreign_or_superseded_action")
	var snapshot: Dictionary = player.call("save_data")
	var current := RECORD.portable_projection(snapshot)
	var proposal := DELIVERY.owner_plan(current, row, RECORD.errors)
	if proposal.get("ok") != true: return proposal
	var party: Variant = player.get("party")
	var inventory: Variant = player.get("inventory")
	if not party is RefCounted or not inventory is RefCounted or not party.has_method("members") \
		or not party.has_method("owner_training_release_snapshot") or not party.has_method("restore_owner_training_release") \
		or not inventory.has_method("set_slot"): return _deny("owner_containers_unavailable")
	var roster: Dictionary = party.call("owner_training_release_snapshot")
	# The decided row plus the passive care accrued since its stage: owner
	# walking/nourishment between stage and apply is never rolled back.
	var target := ESSENCE.merge_owner_passive(row.after, row.after if proposal.get("duplicate") == true else row.before, current)
	var applied := row.duplicate(true)
	applied.after = target
	# F01#6a: an original starter is the guest's own live instance -- the one its
	# follower body already pilots -- never a second decoded copy.
	var starter_live: RefCounted = null
	if row.action == "starter_choice" and proposal.get("duplicate") != true:
		starter_live = game.call("pending_original_starter_instance") if game.has_method("pending_original_starter_instance") else null
		if starter_live == null: return _deny("owner_starter_instance_missing")
	var plan := _live_plan(roster.members, current, applied, starter_live)
	if plan.get("ok") != true: return plan
	if row.action == "rest_complete" and proposal.get("duplicate") != true:
		# These existing save metadata/vitals are outside portable authority.
		# Keep them in this same owner install/BOOL-save, not an after-ACK write.
		var vitals: RefCounted = game.call("player_vitals") if game.has_method("player_vitals") else null
		if vitals != null and vitals.has_method("rest"):
			plan["rest_trainer_before"] = {"body": weakref(vitals), "values": {"health": vitals.get("health"),
				"stamina": vitals.get("stamina"), "satiety": vitals.get("satiety"),
				"_exhausted": vitals.get("_exhausted"), "damage_revision": vitals.get("damage_revision")}}
	if session.call("_retain_owner_training_retry", player, world, row) != true \
		or session.call("_begin_owner_training_install", player, world, row) != true: return _deny("owner_install_refused")
	if proposal.get("duplicate") != true:
		# Exact release runs before other mutations, so its bound container guard
		# checks the actual whole pre-decision owner and original live instance.
		if row.action != "wild_capture" and plan.release_index >= 0 and party.call("remove_at", plan.release_index) != plan.release_instance:
			session.call("_end_owner_training_install")
			return _deny("owner_release_refused")
		for change: Dictionary in plan.changes: change.instance.set(change.field, change.after)
		for projection: Dictionary in plan.traits:
			if TRAITS.project_instance(projection.instance, projection.record) != true:
				return _rollback(game, player, world, session, row, snapshot, roster, plan, "owner_trait_projection_failed")
		for slot: int in row.after.inventory.size():
			var stack: Variant = row.after.inventory[slot]
			if not ESSENCE._equivalent(snapshot.inventory[slot], stack):
				inventory.call("set_slot", slot, stack.duplicate(true) if stack is Dictionary else null)
		player.set("redesign_character", row.after.redesign_character.duplicate(true))
		if row.action in ["wild_capture", "starter_choice"] and party.call("install_owner_capture_roster", plan.capture_members) != true:
			return _rollback(game, player, world, session, row, snapshot, roster, plan, "owner_capture_roster_refused")
		if row.action == "starter_choice":
			player.flags.call("set_flag", STARTER_FLAG, true)
		if row.action == "rest_complete":
			player.flags.call("set_flag", "player_slept_at_home", true)
			player.set("satiety", preload("res://scripts/save/save_game.gd").new().call("_default_satiety"))
			var vitals: RefCounted = game.call("player_vitals") if game.has_method("player_vitals") else null
			if vitals != null and vitals.has_method("rest"): vitals.call("rest")
		if not ESSENCE._equivalent(current.equipment, row.after.equipment):
			player.get("equipment").call("load_data", row.after.equipment)
		# F31#2: a relic power choice changes only the active heart.
		if not ESSENCE._equivalent(current.realm_hearts, row.after.realm_hearts) and player.get("hearts") != null:
			player.get("hearts").call("load_data", row.after.realm_hearts)
	if not preload("res://scripts/net/home_key_action.gd").install_owner(player, row):
		return _rollback(game, player, world, session, row, snapshot, roster, plan, "owner_home_key_install_refused")
	var installed: Dictionary = player.call("save_data")
	if not ESSENCE._equivalent(RECORD.portable_projection(installed), target):
		return _rollback(game, player, world, session, row, snapshot, roster, plan, "owner_action_install_conflict") if proposal.get("duplicate") != true else _end_refused(session, "owner_action_install_conflict")
	if row.action == "wild_capture" and row.intent.keep and proposal.get("duplicate") != true:
		# The same owner BOOL write includes the ordinary owned-catch skill XP.
		# A failed write retains this installed state; duplicate retries never
		# award again, and the saved capture receipt prevents a rejoin replay.
		var skills: RefCounted = player.get("skills")
		if skills != null: preload("res://scripts/player/skills_activity.gd").new(skills).record_catch(row.intent.offer_id, true, true)
	session.call("_end_owner_training_install")
	if saver.call("save_character_prepared", game, str(player.character_id)) != true:
		# Saved world entitlement cannot be refunded. Retain this exact installed
		# owner state under its existing retry fence for another real bool write.
		return {"ok": false, "saved": false, "pending": true, "durable": true, "code": "owner_action_save_failed"}
	if game.get("local") != player or game.get("world") != world or str(session.call("_altar_current_epoch")) != epoch \
		or not ESSENCE._equivalent(world.reward_deliveries.get(row.delivery_id), row) \
		or session.call("_mark_owner_training_saved", player, world, row) != true:
		return {"ok": false, "saved": true, "pending": true, "durable": true, "code": "owner_action_context_changed"}
	return {"ok": true, "saved": true, "duplicate": proposal.get("duplicate") == true,
		"receipt": row.receipt, "delivery_id": row.delivery_id, "journal_revision": row.journal_revision,
		"character_revision": row.character_revision, "action": row.action, "action_id": row.action_id}


static func _live_plan(members: Array, current: Dictionary, row: Dictionary, starter_live: RefCounted = null) -> Dictionary:
	if members.size() != current.party.size(): return _deny("owner_party_changed")
	if row.action in ["wild_capture", "starter_choice"] and ESSENCE._equivalent(current, row.after):
		return {"ok": true, "changes": [], "traits": [], "release_index": -1, "release_instance": null, "capture_members": members}
	if row.action == "starter_choice":
		return _starter_plan(members, row, starter_live)
	var changes: Array[Dictionary] = []
	var projections: Array[Dictionary] = []
	var release_index := -1
	var release_instance: RefCounted
	var next_index := 0
	for index: int in members.size():
		var instance: Variant = members[index]
		var prior: Dictionary = current.party[index]
		if not instance is RefCounted or instance.get("uid") != prior.uid: return _deny("owner_party_changed")
		if ((row.action in ["trait_release", "essence_release"] and prior.uid == row.intent.creature_uid) or (row.action == "wild_capture" and prior.uid == row.intent.released_uid)) and not _has_uid(row.after.party, prior.uid):
			if release_index >= 0: return _deny("ambiguous_release")
			release_index = index
			release_instance = instance
			continue
		if next_index >= row.after.party.size() or row.after.party[next_index].uid != prior.uid: return _deny("owner_roster_import_refused")
		var next: Dictionary = row.after.party[next_index]
		next_index += 1
		var properties: Dictionary = {}
		for property: Dictionary in instance.get_property_list(): properties[property.name] = true
		for field: String in next:
			if field == "uid" or ESSENCE._equivalent(prior.get(field), next[field]): continue
			if not properties.has(field): return _deny("owner_codec_field_unavailable")
			var old: Variant = instance.get(field)
			var value: Variant = _typed_value(old, next[field])
			if value == null and next[field] != null: return _deny("owner_codec_type_unavailable")
			changes.append({"instance": instance, "field": field, "before": _copy(old), "after": value})
		var mirror: Variant = row.after.redesign_character.creatures.get(prior.uid)
		if mirror is Dictionary and mirror.has("traits_initialized"):
			if not TRAITS.trait_state_errors(mirror).is_empty(): return _deny("owner_trait_state_invalid")
			var previous: Dictionary = {}
			for field: String in ["traits_initialized", "rolled_traits", "taught_traits"]:
				if not properties.has(field): return _deny("owner_trait_projection_unavailable")
				previous[field] = _copy(instance.get(field))
			projections.append({"instance": instance, "record": mirror, "before": previous})
	var capture_members: Array = []
	if row.action == "wild_capture":
		for member: RefCounted in members:
			if member != release_instance: capture_members.append(member)
		if row.intent.keep:
			if next_index + 1 != row.after.party.size(): return _deny("owner_capture_shape_changed")
			var card: Dictionary = row.after.party[next_index]
			if card.uid != row.host_context.creature.uid: return _deny("owner_capture_uid_changed")
			var newcomer := preload("res://scripts/save/water_capture_codec.gd").decode_owned(card, row.after.redesign_character)
			if newcomer == null: return _deny("owner_capture_decode_failed")
			capture_members.append(newcomer)
			next_index += 1
	if next_index != row.after.party.size(): return _deny("owner_roster_import_refused")
	if row.action in ["trait_release", "essence_release"] and not ESSENCE._equivalent(current, row.after) \
		and (release_index < 0 or members.size() <= 1 or row.after.party.size() != members.size() - 1): return _deny("owner_release_changed")
	return {"ok": true, "changes": changes, "traits": projections, "release_index": release_index, "release_instance": release_instance, "capture_members": capture_members}


## F01#6a. The staged starter joins an EMPTY roster, and the only newcomer is
## the guest's own pending live instance, proved equal to the staged card in the
## same energy-free portable form the host staged it from.
static func _starter_plan(members: Array, row: Dictionary, starter_live: RefCounted) -> Dictionary:
	if not members.is_empty() or (row.after.party as Array).size() != 1: return _deny("owner_starter_shape_changed")
	var card: Dictionary = row.after.party[0]
	if starter_live == null or str(starter_live.get("uid")) != str(card.get("uid")) \
		or str(card.get("uid")) != str(row.get("intent", {}).get("creature", {}).get("uid", "")):
		return _deny("owner_starter_uid_changed")
	var live_card: Variant = RECORD.portable_card(preload("res://scripts/save/water_capture_codec.gd").encode(starter_live, row.after.redesign_character))
	if not live_card is Dictionary or not ESSENCE.owner_matches_after({"party": [live_card]}, {"party": [card]}):
		return _deny("owner_starter_card_changed")
	return {"ok": true, "changes": [], "traits": [], "release_index": -1, "release_instance": null,
		"capture_members": [starter_live]}


static func _rollback(game: Node, player: RefCounted, world: RefCounted, session: Node,
		row: Dictionary, snapshot: Dictionary, roster: Dictionary, plan: Dictionary, code: String) -> Dictionary:
	if game.get("local") != player or game.get("world") != world \
		or session.call("_begin_owner_training_rollback", player, world, row) != true: return _end_refused(session, "owner_rollback_context_changed")
	for change: Dictionary in plan.changes: change.instance.set(change.field, change.before)
	for projection: Dictionary in plan.traits:
		for field: String in projection.before: projection.instance.set(field, projection.before[field])
	var inventory: RefCounted = player.get("inventory")
	for slot: int in snapshot.inventory.size():
		var stack: Variant = snapshot.inventory[slot]
		inventory.call("set_slot", slot, stack.duplicate(true) if stack is Dictionary else null)
	player.set("redesign_character", snapshot.redesign_character.duplicate(true))
	if row.action in preload("res://scripts/net/home_key_action.gd").ACTIONS:
		player.set("satchel_escrow", snapshot.satchel_escrow.duplicate(true))
		player.flags.call("load_data", snapshot.flags)
	if row.action == "starter_choice":
		player.flags.call("load_data", snapshot.flags)
		# Back to the empty roster through the guarded install (rollback=true);
		# the live instance stays the follower's, owned by the pending adoption.
		if player.get("party").call("install_owner_capture_roster", [], true) != true:
			return _end_refused(session, "owner_roster_rollback_failed")
	if row.action == "rest_complete":
		player.flags.call("load_data", snapshot.flags)
		player.set("satiety", snapshot.satiety)
		var recovery: Dictionary = plan.get("rest_trainer_before", {})
		var vitals: RefCounted = recovery.body.get_ref() if recovery.get("body") is WeakRef else null
		if vitals != null:
			for field: String in ["health", "stamina", "satiety", "_exhausted", "damage_revision"]:
				vitals.set(field, recovery.values[field])
	if not ESSENCE._equivalent(snapshot.equipment, row.after.equipment):
		player.get("equipment").call("load_data", snapshot.equipment)
	if not ESSENCE._equivalent(snapshot.realm_hearts, row.after.realm_hearts) and player.get("hearts") != null:
		player.get("hearts").call("load_data", snapshot.realm_hearts)
	if (plan.release_index >= 0 or row.action == "wild_capture") and party_restore(player, roster) != true: return _end_refused(session, "owner_roster_rollback_failed")
	var expected: Dictionary = row.before
	if row.action == "combat_round_reward":
		expected = preload("res://scripts/net/combat_round_reward.gd").settled_before(row.before, row.intent, row.host_context)
	var restored := ESSENCE.owner_matches_after(RECORD.portable_projection(player.call("save_data")), expected)
	session.call("_end_owner_training_install")
	return {"ok": false, "saved": false, "pending": true, "durable": true, "code": code if restored else "owner_rollback_conflict"}


static func party_restore(player: RefCounted, roster: Dictionary) -> bool:
	return player.get("party").call("restore_owner_training_release", roster) == true


static func _typed_value(old: Variant, value: Variant) -> Variant:
	match typeof(old):
		TYPE_INT: return int(value) if ESSENCE._integer(value, -2147483648, 2147483647) else null
		TYPE_FLOAT: return float(value) if (value is int or value is float) and is_finite(float(value)) else null
		TYPE_STRING: return value if value is String else null
		TYPE_BOOL: return value if value is bool else null
		TYPE_DICTIONARY: return value.duplicate(true) if value is Dictionary else null
		TYPE_ARRAY:
			if not value is Array: return null
			if old.is_typed() and old.get_typed_builtin() == TYPE_STRING:
				var strings: Array[String] = []
				for entry: Variant in value:
					if not entry is String: return null
					strings.append(entry)
				return strings
			return value.duplicate(true) if not old.is_typed() else null
	return null


static func _has_uid(rows: Array, uid: String) -> bool:
	for card: Dictionary in rows:
		if card.uid == uid: return true
	return false


static func _copy(value: Variant) -> Variant:
	return value.duplicate(true) if value is Array or value is Dictionary else value


static func _end_refused(session: Node, code: String) -> Dictionary:
	session.call("_end_owner_training_install")
	return {"ok": false, "saved": false, "pending": true, "durable": true, "code": code}


static func _deny(code: String) -> Dictionary:
	return {"ok": false, "saved": false, "code": code}
