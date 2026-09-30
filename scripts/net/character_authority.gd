extends RefCounted

## One host-held admitted-character record for keys and the combat roster.
## Explicit portable fields only; no packet may replace an admitted baseline.
## Session guards host calls and transport identity; the portable owner alone
## persists its character. World receipts remain the durable portal ledger.
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const REDESIGN := preload("res://scripts/data/redesign_state.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const PORTAL := preload("res://scripts/world/portal_arch.gd")
const REWARD := preload("res://scripts/net/reward_delivery.gd")
const FIELDS := ["character_id", "party", "redesign_character", "inventory", "portal_escrow"]
var _records: Dictionary = {}
var _world_instance := ""
var _portal_stages: Dictionary = {}
var _portal_stage_sequence := 0
var _loadout_pending: Dictionary = {}


func bind_world(world_instance: String) -> bool:
	if world_instance.is_empty():
		return false
	if world_instance != _world_instance:
		if not _portal_stages.is_empty() or not _loadout_pending.is_empty():
			return false
		_records.clear()
		_portal_stages.clear()
		_world_instance = world_instance
	return true


static func portable_projection(personal: Dictionary) -> Dictionary:
	var rows: Dictionary = {}
	var escrow: Variant = personal.get("satchel_escrow", {})
	if escrow is Dictionary:
		for key: Variant in escrow:
			var row: Variant = escrow[key]
			if str(key).begins_with(PORTAL.KIND + ":") or (row is Dictionary and row.get("kind") == PORTAL.KIND):
				rows[key] = row.duplicate(true) if row is Dictionary else row
	return {"character_id": personal.get("character_id"), "party": personal.get("party"),
		"redesign_character": personal.get("redesign_character"), "inventory": personal.get("inventory"),
		"portal_escrow": rows}


static func errors(raw: Variant, expected_character: String) -> Array[String]:
	if not raw is Dictionary or raw.size() != FIELDS.size():
		return ["admission requires the exact portable authority fields"]
	for key: String in FIELDS:
		if not raw.has(key):
			return ["missing portable authority field " + key]
	if expected_character.is_empty() or raw.character_id != expected_character:
		return ["portable authority belongs to another character"]
	var failures := TEACHING.admitted_party_errors(raw.party, raw.redesign_character)
	failures.append_array(REDESIGN.validate("character", raw.redesign_character, REDESIGN.uids(raw.party)))
	if not RULES.valid_slots(raw.inventory):
		failures.append("invalid admitted inventory")
	elif raw.inventory.size() != preload("res://autoload/inventory.gd").SLOT_COUNT:
		failures.append("admitted inventory must retain every slot")
	else:
		for stack: Variant in raw.inventory:
			if stack != null and not bool(RULES.db().call("has", str(stack.id))):
				failures.append("unknown admitted item " + str(stack.id))
	if not raw.portal_escrow is Dictionary:
		failures.append("portal escrow must be a typed object")
	else:
		for key: Variant in raw.portal_escrow:
			var row: Variant = raw.portal_escrow[key]
			if not PORTAL.valid_row(row, expected_character) or str(key) != str(row.get("receipt", "")):
				failures.append("invalid admitted portal journal")
	return failures


func seed_admitted_character(raw: Dictionary, character_id: String) -> Dictionary:
	if _world_instance.is_empty():
		return {"ok": false, "code": "world_not_bound"}
	var failures := errors(raw, character_id)
	if not failures.is_empty():
		return {"ok": false, "code": "invalid_character", "errors": failures}
	if _records.has(character_id):
		# Rejoin cannot overwrite newer earned authority. The caller receives the
		# existing record for subsequent roster/debit admission and reconciliation.
		return {"ok": true, "already_seeded": true, "revision": revision(character_id), "state": state(character_id)}
	_records[character_id] = {"revision": 0, "state": raw.duplicate(true)}
	return {"ok": true, "already_seeded": false, "revision": 0, "state": state(character_id)}


func state(character_id: String) -> Dictionary:
	return _records[character_id].state.duplicate(true) if _records.has(character_id) else {}


func revision(character_id: String) -> int:
	return int(_records[character_id].revision) if _records.has(character_id) else -1


## Session alone projects the actual local host PlayerState here. Remote
## packets never reach this arm: their baseline is retained by admission. This
## tracks host-earned party/gifts without taking a client's proposed refresh.
func refresh_host_local(raw: Dictionary, character_id: String) -> Dictionary:
	if _portal_stages.has(character_id) or _loadout_pending.has(character_id):
		return {"ok": true, "revision": revision(character_id), "state": state(character_id), "pending_transaction": true}
	var seeded := seed_admitted_character(raw, character_id)
	if not bool(seeded.get("ok", false)) or not bool(seeded.get("already_seeded", false)):
		return seeded
	var current := state(character_id)
	var candidate := raw.duplicate(true)
	# A failed owner settlement still leaves the durable world debit committed.
	# Preserve its host entitlement while the actual local key remains pending
	# for atomic personal retry, rather than minting a second host-owned key.
	for receipt: String in current.redesign_character.transaction_receipts:
		if receipt.begins_with(PORTAL.KIND + ":") and not candidate.redesign_character.transaction_receipts.has(receipt):
			candidate.redesign_character.transaction_receipts.append(receipt)
	for biome: String in current.redesign_character.portal_unlocks:
		if not candidate.redesign_character.portal_unlocks.has(biome):
			candidate.redesign_character.portal_unlocks.append(biome)
	if equivalent(current, candidate):
		return {"ok": true, "revision": revision(character_id), "state": current}
	var failures := errors(candidate, character_id)
	if not failures.is_empty():
		return {"ok": false, "code": "invalid_local_character", "errors": failures}
	_records[character_id] = {"revision": revision(character_id) + 1, "state": candidate}
	return {"ok": true, "revision": revision(character_id), "state": state(character_id)}


## Only accepted host HP-contact code supplies the staged maps. There is no
## RPC or arbitrary snapshot replacement arm for a client's proposed rank.
func commit_creature_mastery(character_id: String, uid: String, expected_revision: int,
		expected_uses: Dictionary, expected_receipts: Dictionary, next_uses: Dictionary,
		next_receipts: Dictionary) -> Dictionary:
	if _portal_stages.has(character_id) or _loadout_pending.has(character_id):
		return {"ok": false, "code": "transaction_busy", "revision": revision(character_id)}
	if expected_revision < 0 or revision(character_id) != expected_revision:
		return {"ok": false, "code": "stale_revision", "revision": revision(character_id)}
	var candidate := state(character_id)
	var owned: Dictionary = {}
	for row: Dictionary in candidate.party:
		if str(row.uid) == uid:
			owned = row
			break
	if owned.is_empty() or not equivalent(owned.get("move_mastery_uses", {}), expected_uses) \
			or not equivalent(owned.get("move_mastery_receipts", {}), expected_receipts):
		return {"ok": false, "code": "stale_creature", "revision": expected_revision}
	owned.move_mastery_uses = next_uses.duplicate(true)
	owned.move_mastery_receipts = next_receipts.duplicate(true)
	candidate.redesign_character = TEACHING.character_loadout_mirror(candidate.party, candidate.redesign_character)
	var failures := errors(candidate, character_id)
	if not failures.is_empty():
		return {"ok": false, "code": "invalid_mastery", "errors": failures, "revision": expected_revision}
	# Existing credits are immutable. A host contact allocation adds exactly one
	# unique receipt/use; its frozen rank is read before reaching this method.
	var added := 0
	for move: Variant in expected_uses:
		if not next_uses.has(move) or float(next_uses[move]) < float(expected_uses[move]):
			return {"ok": false, "code": "mastery_regression", "revision": expected_revision}
	for move: Variant in expected_receipts:
		if not next_receipts.get(move) is Array:
			return {"ok": false, "code": "mastery_regression", "revision": expected_revision}
		var old_history: Array = expected_receipts[move]
		var next_history: Array = next_receipts[move]
		if next_history.size() < old_history.size():
			return {"ok": false, "code": "mastery_regression", "revision": expected_revision}
		for index: int in old_history.size():
			if next_history[index] != old_history[index]:
				return {"ok": false, "code": "mastery_regression", "revision": expected_revision}
	for move: Variant in next_uses:
		var difference := float(next_uses[move]) - float(expected_uses.get(move, 0))
		if not is_finite(difference) or difference < 0 or difference != floor(difference):
			return {"ok": false, "code": "invalid_mastery", "revision": expected_revision}
		added += int(difference)
	if added != 1:
		return {"ok": false, "code": "one_contact_required", "revision": expected_revision}
	_records[character_id] = {"revision": expected_revision + 1, "state": candidate}
	return {"ok": true, "revision": expected_revision + 1, "state": state(character_id)}


## The registered live station caller stages only the three editable slots.
## An accepted edit remains locked until the portable owner has atomically
## saved this exact revision. Disconnect/rejoin returns the retained pending
## edit; a later packet cannot replace or undo that accepted host baseline.
func commit_creature_loadout(character_id: String, uid: String, expected_revision: int,
		expected_loadout_revision: int, expected_last_edit: Dictionary, next_loadout: Dictionary,
		next_loadout_revision: int, next_edit_receipt: Dictionary) -> Dictionary:
	if _portal_stages.has(character_id):
		return {"ok": false, "code": "transaction_busy", "revision": revision(character_id)}
	if _loadout_pending.has(character_id):
		var pending: Dictionary = _loadout_pending[character_id]
		if pending.uid == uid and equivalent(pending.receipt, next_edit_receipt):
			return {"ok": true, "duplicate": true, "revision": revision(character_id),
				"state": state(character_id), "pending_owner_save": true}
		return {"ok": false, "code": "owner_save_pending", "revision": revision(character_id)}
	if expected_revision < 0 or revision(character_id) != expected_revision:
		return {"ok": false, "code": "stale_revision", "revision": revision(character_id)}
	if next_loadout.size() != 3 or next_loadout_revision != expected_loadout_revision + 1:
		return {"ok": false, "code": "invalid_loadout", "revision": expected_revision}
	var candidate := state(character_id)
	var owned: Dictionary = {}
	for row: Dictionary in candidate.party:
		if str(row.uid) == uid:
			owned = row
			break
	if owned.is_empty() or int(owned.get("loadout_revision", 0)) != expected_loadout_revision \
			or not equivalent(owned.get("loadout_last_edit", {}), expected_last_edit):
		return {"ok": false, "code": "stale_creature", "revision": expected_revision}
	var receipt_keys := ["edit_id", "expected_revision", "creature_uid", "quick", "charged", "utility"]
	if next_edit_receipt.size() != receipt_keys.size():
		return {"ok": false, "code": "invalid_edit_receipt", "revision": expected_revision}
	for key: String in receipt_keys:
		if not next_edit_receipt.has(key):
			return {"ok": false, "code": "invalid_edit_receipt", "revision": expected_revision}
	if next_edit_receipt.get("creature_uid") != uid \
			or not equivalent(next_edit_receipt.get("expected_revision"), expected_loadout_revision):
		return {"ok": false, "code": "invalid_edit_receipt", "revision": expected_revision}
	for slot: String in ["quick", "charged", "utility"]:
		if not next_loadout.get(slot) is String or next_edit_receipt.get(slot) != next_loadout[slot]:
			return {"ok": false, "code": "invalid_loadout", "revision": expected_revision}
		owned["move_" + slot] = next_loadout[slot]
	owned.loadout_revision = next_loadout_revision
	owned.loadout_last_edit = next_edit_receipt.duplicate(true)
	# The whole-document preflight checks known moves, exact slot roles and the
	# canonical mirror. No ultimate/known/mastery/relic/inventory fields changed.
	candidate.redesign_character = TEACHING.character_loadout_mirror(candidate.party, candidate.redesign_character)
	var failures := errors(candidate, character_id)
	if not failures.is_empty():
		return {"ok": false, "code": "invalid_loadout", "errors": failures, "revision": expected_revision}
	_records[character_id] = {"revision": expected_revision + 1, "state": candidate}
	_loadout_pending[character_id] = {"uid": uid, "receipt": next_edit_receipt.duplicate(true),
		"loadout_revision": next_loadout_revision, "character_revision": expected_revision + 1}
	return {"ok": true, "duplicate": false, "revision": expected_revision + 1,
		"state": state(character_id), "pending_owner_save": true}


## Transport rebinds character identity. This only releases an action lock,
## never imports owner data or spends/refunds anything. Replayed old ACKs
## cannot acknowledge a newer edit. The owner sends it only after SaveCharacter.
func acknowledge_creature_loadout(character_id: String, uid: String,
		loadout_revision: int, edit_receipt: Dictionary) -> bool:
	var pending: Variant = _loadout_pending.get(character_id)
	if not pending is Dictionary or pending.uid != uid \
			or int(pending.loadout_revision) != loadout_revision \
			or not equivalent(pending.receipt, edit_receipt):
		return false
	_loadout_pending.erase(character_id)
	return true


func pending_creature_loadout(character_id: String) -> Dictionary:
	return _loadout_pending[character_id].duplicate(true) if _loadout_pending.has(character_id) else {}


## Prepare an explicit owned-key debit without changing the admitted record.
## The existing synchronous transaction promotes it invisibly before SaveWorld,
## rolls it back if that save fails, and publishes/settles the owner only after
## success. A pending stage excludes other writers until its explicit finish.
func stage_portal_debit(character_id: String, biome: String, receipt: String,
		accepted_deliveries: Array = []) -> Dictionary:
	if _portal_stages.has(character_id) or _loadout_pending.has(character_id):
		return {"ok": false, "code": "transaction_busy"}
	var candidate := state(character_id)
	if candidate.is_empty() or not PORTAL.KEYS.has(biome) \
			or receipt != PORTAL.receipt(biome, character_id):
		return {"ok": false, "code": "not_admitted"}
	var personal: Dictionary = candidate.redesign_character
	if personal.transaction_receipts.has(receipt):
		return {"ok": true, "duplicate": true, "revision": revision(character_id)}
	var slot := -1
	for index: int in candidate.inventory.size():
		var stack: Variant = candidate.inventory[index]
		if stack is Dictionary and stack.id == PORTAL.KEYS[biome]:
			if slot >= 0 or int(stack.n) != 1:
				return {"ok": false, "code": "invalid_owned_key"}
			slot = index
	var keys := protected_keys(character_id, accepted_deliveries)
	if int(keys.get(PORTAL.KEYS[biome], 0)) != 1:
		return {"ok": false, "code": "missing_owned_key"}
	if slot >= 0:
		candidate.inventory[slot] = null
	if biome != "biome5" and not personal.portal_unlocks.has(biome):
		personal.portal_unlocks.append(biome)
	personal.transaction_receipts.append(receipt)
	var failures := errors(candidate, character_id)
	if not failures.is_empty():
		return {"ok": false, "code": "invalid_debit", "errors": failures}
	_portal_stage_sequence += 1
	var token := "%s:%d" % [_world_instance, _portal_stage_sequence]
	_portal_stages[character_id] = {"token": token, "world_instance": _world_instance,
		"revision": revision(character_id), "state": candidate, "before": _records[character_id].duplicate(true), "committed": false}
	# The caller can carry only the frozen stage identity, not a replacement
	# inventory/party payload to the promotion seam.
	return {"ok": true, "duplicate": false, "character_id": character_id,
		"token": token, "revision": revision(character_id)}


## Protected keys cannot leave via drops, death, sale or trade. Later grants
## come only from the existing host world journal after its acceptance save;
## no client acknowledgement packet supplies an item/quantity/source baseline.
## This is a detached view of this same admitted record and world receipts,
## not a second mutable inventory ledger.
func protected_keys(character_id: String, accepted_deliveries: Array = []) -> Dictionary:
	var owned := state(character_id)
	var result: Dictionary = {}
	if owned.is_empty():
		return result
	for biome: String in PORTAL.KEYS:
		var item: String = PORTAL.KEYS[biome]
		if owned.redesign_character.transaction_receipts.has(PORTAL.receipt(biome, character_id)):
			result[item] = 0
			continue
		var count := 0
		for stack: Variant in owned.inventory:
			if stack is Dictionary and stack.id == item:
				count += int(stack.n)
		# An admitted baseline can already contain this same accepted gift. Its
		# world proof adds entitlement only when that baseline lacks the key.
		if count == 0:
			var seen: Dictionary = {}
			for raw: Variant in accepted_deliveries:
				if not raw is Dictionary or raw.get("status") != "accepted" \
						or raw.get("character_id") != character_id \
						or raw.get("world_namespace") != _world_instance:
					continue
				var id: String = REWARD.delivery_id(_world_instance, str(raw.get("source", "")), character_id)
				if id.is_empty() or raw.get("delivery_id") != id or seen.has(id) \
						or not RULES.valid_slots(raw.get("stacks")):
					continue
				seen[id] = true
				for stack: Variant in raw.stacks:
					if stack is Dictionary and stack.id == item:
						count += int(stack.n)
		result[item] = count
	return result


func commit_portal_debit(stage: Dictionary) -> bool:
	if not bool(stage.get("ok", false)):
		return false
	if bool(stage.get("duplicate", false)):
		return false # No promotion is needed for an already committed receipt.
	var character_id := str(stage.get("character_id", ""))
	var frozen: Variant = _portal_stages.get(character_id)
	if not frozen is Dictionary or stage.get("token") != frozen.token \
			or frozen.world_instance != _world_instance \
			or int(frozen.revision) != revision(character_id):
		return false
	var candidate: Variant = frozen.state
	if not errors(candidate, character_id).is_empty():
		return false
	_records[character_id] = {"revision": revision(character_id) + 1, "state": candidate.duplicate(true)}
	frozen.committed = true
	return true


## Synchronous world-save failure rolls back the hidden admitted debit too.
## The frozen token cannot restore another transaction or a later revision.
func finish_portal_debit(stage: Dictionary, world_saved: bool) -> bool:
	var character_id := str(stage.get("character_id", ""))
	var frozen: Variant = _portal_stages.get(character_id)
	if not frozen is Dictionary or stage.get("token") != frozen.token:
		return false
	if bool(frozen.committed) and not world_saved:
		if revision(character_id) != int(frozen.revision) + 1:
			return false
		_records[character_id] = frozen.before.duplicate(true)
	_portal_stages.erase(character_id)
	return true


static func equivalent(left: Variant, right: Variant) -> bool:
	if (left is int or left is float) and (right is int or right is float):
		return is_finite(float(left)) and is_finite(float(right)) and float(left) == float(right)
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key: Variant in left:
			if not right.has(key) or not equivalent(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for index: int in left.size():
			if not equivalent(left[index], right[index]):
				return false
		return true
	return typeof(left) == typeof(right) and left == right
