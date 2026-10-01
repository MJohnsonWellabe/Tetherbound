extends RefCounted

## Runtime installer for the same saved per-character training carrier.
## It changes preserved live UID instances; it never loads/rebuilds a party.
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
	var plan := _live_plan(roster.members, current, row)
	if plan.get("ok") != true: return plan
	if session.call("_retain_owner_training_retry", player, world, row) != true \
		or session.call("_begin_owner_training_install", player, world, row) != true: return _deny("owner_install_refused")
	if proposal.get("duplicate") != true:
		# Exact release runs before other mutations, so its bound container guard
		# checks the actual whole pre-decision owner and original live instance.
		if plan.release_index >= 0 and party.call("remove_at", plan.release_index) != plan.release_instance:
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
		if not ESSENCE._equivalent(current.equipment, row.after.equipment):
			player.get("equipment").call("load_data", row.after.equipment)
	var installed: Dictionary = player.call("save_data")
	if not ESSENCE._equivalent(RECORD.portable_projection(installed), row.after):
		return _rollback(game, player, world, session, row, snapshot, roster, plan, "owner_action_install_conflict") if proposal.get("duplicate") != true else _end_refused(session, "owner_action_install_conflict")
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


static func _live_plan(members: Array, current: Dictionary, row: Dictionary) -> Dictionary:
	if members.size() != current.party.size(): return _deny("owner_party_changed")
	var changes: Array[Dictionary] = []
	var projections: Array[Dictionary] = []
	var release_index := -1
	var release_instance: RefCounted
	var next_index := 0
	for index: int in members.size():
		var instance: Variant = members[index]
		var prior: Dictionary = current.party[index]
		if not instance is RefCounted or instance.get("uid") != prior.uid: return _deny("owner_party_changed")
		if row.action == "trait_release" and prior.uid == row.intent.creature_uid and not _has_uid(row.after.party, prior.uid):
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
	if next_index != row.after.party.size(): return _deny("owner_roster_import_refused")
	if row.action == "trait_release" and not ESSENCE._equivalent(current, row.after) \
		and (release_index < 0 or members.size() <= 1 or row.after.party.size() != members.size() - 1): return _deny("owner_release_changed")
	return {"ok": true, "changes": changes, "traits": projections, "release_index": release_index, "release_instance": release_instance}


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
	if not ESSENCE._equivalent(snapshot.equipment, row.after.equipment):
		player.get("equipment").call("load_data", snapshot.equipment)
	if plan.release_index >= 0 and party_restore(player, roster) != true: return _end_refused(session, "owner_roster_rollback_failed")
	var restored := ESSENCE._equivalent(RECORD.portable_projection(player.call("save_data")), row.before)
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
