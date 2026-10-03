extends RefCounted

## One host-held admitted-character record for keys and the combat roster.
## Explicit portable fields only; no packet may replace an admitted baseline.
## Session guards host calls and transport identity; the portable owner alone
## persists its character. World receipts remain the durable portal ledger.
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const REDESIGN := preload("res://scripts/data/redesign_state.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const PORTAL := preload("res://scripts/net/portal_escrow_validation.gd")
const REWARD := preload("res://scripts/net/reward_delivery.gd")
const EQUIPMENT := preload("res://scripts/player/player_equipment.gd")
const BIOMES := preload("res://scripts/data/biome_order.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const FIELDS := ["character_id", "party", "redesign_character", "inventory", "portal_escrow", "vitals_escrow", "equipment", "realm_hearts"]
var _training_stages: Dictionary = {}
var _training_pending: Dictionary = {}
var _records: Dictionary = {}
var _world_instance := ""
var _portal_stages: Dictionary = {}
var _portal_stage_sequence := 0
var _loadout_pending: Dictionary = {}
var _vitals_pending: Dictionary = {}
var _vitals_seen: Dictionary = {}
var _vitals_stages: Dictionary = {}
var _vitals_stage_sequence := 0
var _groom_preparations: Dictionary = {}
var _research_preparations: Dictionary = {}


func bind_world(world_instance: String) -> bool:
	if world_instance.is_empty():
		return false
	if world_instance != _world_instance:
		if not _research_preparations.is_empty() or not _groom_preparations.is_empty() or not _training_stages.is_empty() or not _training_pending.is_empty() or not _portal_stages.is_empty() or not _loadout_pending.is_empty() or not _vitals_pending.is_empty():
			return false
		_records.clear()
		_portal_stages.clear()
		_vitals_seen.clear()
		_world_instance = world_instance
	return true


const RECORD_RULES := preload("res://scripts/net/character_record_rules.gd")

static func portable_projection(personal: Dictionary) -> Dictionary:
	return RECORD_RULES.portable_projection(personal)


static func empty_equipment() -> Dictionary:
	return RECORD_RULES.empty_equipment()


static func equipment_errors(raw: Variant) -> Array[String]:
	return RECORD_RULES.equipment_errors(raw)


static func heart_selection_errors(raw: Variant) -> Array[String]:
	return RECORD_RULES.heart_selection_errors(raw)


static func errors(raw: Variant, expected_character: String) -> Array[String]:
	return RECORD_RULES.errors(raw, expected_character)


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
	_replace_record(character_id, 0, raw.duplicate(true))
	_records[character_id].state["vitals_escrow"] = raw.get("vitals_escrow", {}).duplicate(true)
	return {"ok": true, "already_seeded": false, "revision": 0, "state": state(character_id)}


func _replace_record(character: String, next_revision: int, next_state: Dictionary) -> void:
	var carried: bool = _records.get(character, {}).has("personal_flags")
	var flags := personal_flags(character)
	var discovered: Variant = _records.get(character, {}).get("discovered_landmarks")
	_records[character] = {"revision": next_revision, "state": next_state}
	if carried: _records[character].personal_flags = flags
	if discovered is Dictionary: _records[character].discovered_landmarks = discovered.duplicate(true)

## Admission-only companion on the SAME record. A rejoin never refreshes it.
## Session validates every ID against the authored realm map catalogue first.
func seed_discovered_landmarks(character: String, discoveries: Dictionary) -> bool:
	if not _records.has(character): return false
	if _records[character].has("discovered_landmarks"): return true
	_records[character].discovered_landmarks = discoveries.duplicate(true)
	return true

func discovered_landmarks(character: String) -> Dictionary:
	return _records.get(character, {}).get("discovered_landmarks", {}).duplicate(true)

## A preparation is a transient CAS reservation, not an award or receipt.
func reserve_groom_preparation(character: String, prepared: Dictionary) -> bool:
	if _groom_preparations.has(character):
		return equivalent(_groom_preparations[character], prepared)
	if _portal_mutation_pending(character) or _training_locked(character) or _portal_stages.has(character) \
		or _loadout_pending.has(character) or _vitals_pending.has(character) or _vitals_stages.has(character) \
		or revision(character) != prepared.get("revision", -1) or not equivalent(state(character), prepared.get("before")) \
		or not preload("res://scripts/net/groom_passive_sync.gd").valid(prepared): return false
	_groom_preparations[character] = prepared.duplicate(true)
	return true

func cancel_groom_preparation(character: String, hash: String) -> bool:
	if _groom_preparations.get(character, {}).get("hash") != hash: return false
	_groom_preparations.erase(character)
	return true

## Called only after the authenticated owner's BOOL-save acknowledgement.
## The candidate was derived/reserved by this host; packets carry only its hash.
func commit_groom_preparation(character: String, prepared: Dictionary) -> bool:
	if not equivalent(_groom_preparations.get(character), prepared): return false
	if revision(character) == int(prepared.revision) + 1 and equivalent(state(character), prepared.after):
		_groom_preparations.erase(character)
		return true # Same-original retry after the world writer failed.
	if revision(character) != prepared.revision or not equivalent(state(character), prepared.before): return false
	_replace_record(character, int(prepared.revision) + 1, prepared.after.duplicate(true))
	for realm: String in prepared.discoveries:
		var ids: Array = _records[character].discovered_landmarks.get(realm, [])
		for id: String in prepared.discoveries[realm]:
			if not ids.has(id): ids.append(id)
		_records[character].discovered_landmarks[realm] = ids
	_groom_preparations.erase(character)
	return true

func retain_groom_preparation(character: String, prepared: Dictionary) -> bool:
	if revision(character) != int(prepared.revision) + 1 or not equivalent(state(character), prepared.after) \
		or _training_locked(character): return false
	_groom_preparations[character] = prepared.duplicate(true)
	return true

## Research preparations reserve the same admitted record, but bind an actual
## retained event instead of a Groom station/action. They grant no reward.
func reserve_research_preparation(character: String, prepared: Dictionary, retained: Dictionary) -> bool:
	if not _research_preparation_valid(character, prepared, retained): return false
	return _reserve_research_preparation_checked(character, prepared, retained)

## Cursor is the host service's locally validated contiguous input replay,
## never a value read from a peer packet. The common reservation keeps every
## existing transaction exclusion and original/retry guard in one place.
func reserve_owner_passive_checkpoint(character: String, prepared: Dictionary, retained: Dictionary, cursor: Dictionary) -> bool:
	var codec := preload("res://scripts/net/owner_passive_preparation.gd")
	var valid_cursor: bool = codec.valid_action_host(prepared, cursor) if prepared.get("kind") == codec.ACTION_KIND else codec.valid_host(prepared, retained, cursor)
	if not _records.has(character) or prepared.get("character_id") != character \
		or prepared.get("world_namespace") != _world_instance \
		or not valid_cursor or (prepared.get("kind") == codec.ACTION_KIND and not retained.is_empty()): return false
	for realm: String in discovered_landmarks(character):
		for id: String in discovered_landmarks(character)[realm]:
			if not prepared.discoveries.get(realm, []).has(id): return false
	if not _reserve_research_preparation_checked(character, prepared, retained): return false
	_research_preparations[character].owner_cursor = cursor.duplicate(true)
	return true

func commit_owner_passive_checkpoint(character: String, token_hash: String) -> bool:
	var original := _owner_passive_original(character, token_hash)
	return not original.is_empty() and commit_research_preparation(character, original.prepared, original.retained)

func retain_owner_passive_checkpoint(character: String, token_hash: String) -> bool:
	var original := _owner_passive_original(character, token_hash)
	return not original.is_empty() and retain_research_preparation(character, original.prepared, original.retained)

func cancel_owner_passive_checkpoint(character: String, token_hash: String) -> bool:
	return not _owner_passive_original(character, token_hash).is_empty() and cancel_research_preparation(character, token_hash)

func _owner_passive_original(character: String, token_hash: String) -> Dictionary:
	var original: Dictionary = _research_preparations.get(character, {})
	if original.get("prepared", {}).get("kind") not in ["owner_passive_preparation", "owner_action_passive_preparation"] \
		or original.prepared.get("hash") != token_hash: return {}
	return original

func _reserve_research_preparation_checked(character: String, prepared: Dictionary, retained: Dictionary) -> bool:
	if _research_preparations.has(character):
		var original: Dictionary = _research_preparations[character]
		return not original.committed and not _research_other_transaction(character) \
			and not _training_stages.has(character) and not _training_pending.has(character) and not _groom_preparations.has(character) \
			and equivalent(original.prepared, prepared) \
			and equivalent(original.retained, retained) and _research_reserved_state_matches(character, prepared)
	if _research_other_transaction(character) or _training_locked(character) \
		or revision(character) != prepared.revision or not _research_state_equivalent(prepared, state(character), prepared.before): return false
	_research_preparations[character] = {"prepared": prepared.duplicate(true),
		"retained": retained.duplicate(true), "committed": false, "applied": false}
	return true

## Caller must authenticate the actual owner's successful BOOL-save ACK.
## This private host API accepts no save-success boolean from a packet.
## Commit and the real research stage MUST be synchronous, without an await,
## signal publication, or another writer between them. On failed world write,
## retain the SAME original; on success cancel its transient reservation.
func commit_research_preparation(character: String, prepared: Dictionary, retained: Dictionary) -> bool:
	if not _research_original_matches(character, prepared, retained) or _research_other_transaction(character) \
		or _training_stages.has(character) or _training_pending.has(character) or _groom_preparations.has(character): return false
	var original: Dictionary = _research_preparations[character]
	if original.committed:
		return revision(character) == _research_applied_revision(prepared) and _research_state_equivalent(prepared, state(character), prepared.after)
	if not _research_reserved_state_matches(character, prepared): return false
	if not original.applied:
		var discovered := discovered_landmarks(character)
		for realm: String in prepared.discoveries:
			if not discovered.has(realm): discovered[realm] = []
			for id: String in prepared.discoveries[realm]:
				if not discovered[realm].has(id): discovered[realm].append(id)
		if not preload("res://scripts/net/groom_passive_sync.gd").discovery_shape(discovered): return false
		_replace_record(character, _research_applied_revision(prepared), prepared.after.duplicate(true))
		_records[character].discovered_landmarks = discovered
		original.applied = true
	original.committed = true
	return true

func retain_research_preparation(character: String, prepared: Dictionary, retained: Dictionary) -> bool:
	if not _research_original_matches(character, prepared, retained) or _research_other_transaction(character) \
		or _training_stages.has(character) or _training_pending.has(character) or _groom_preparations.has(character) \
		or _research_preparations[character].applied != true \
		or revision(character) != _research_applied_revision(prepared) or not _research_state_equivalent(prepared, state(character), prepared.after): return false
	# Exact retained retry is idempotent; an unreserved candidate cannot create it.
	_research_preparations[character].committed = false
	return true

func cancel_research_preparation(character: String, hash: String) -> bool:
	if _research_preparations.get(character, {}).get("prepared", {}).get("hash") != hash: return false
	_research_preparations.erase(character)
	return true # An already BOOL-saved/committed baseline is never rolled back.

func _research_preparation_valid(character: String, prepared: Dictionary, retained: Dictionary) -> bool:
	if not _records.has(character) or prepared.get("character_id") != character \
		or prepared.get("world_namespace") != _world_instance: return false
	if prepared.get("kind") in ["owner_passive_preparation", "owner_action_passive_preparation"]:
		# Only the explicit host cursor reservation can introduce this variant.
		var cursor: Dictionary = _research_preparations.get(character, {}).get("owner_cursor", {})
		if prepared.get("kind") == "owner_action_passive_preparation":
			return retained.is_empty() and preload("res://scripts/net/owner_passive_preparation.gd").valid_action_host(prepared, cursor)
		return preload("res://scripts/net/owner_passive_preparation.gd").valid_host(prepared, retained, cursor)
	return preload("res://scripts/net/research_passive_preparation.gd").valid(prepared, retained)

func _research_original_matches(character: String, prepared: Dictionary, retained: Dictionary) -> bool:
	var original: Dictionary = _research_preparations.get(character, {})
	return not original.is_empty() and _research_preparation_valid(character, prepared, retained) \
		and equivalent(original.prepared, prepared) and equivalent(original.retained, retained)

func _research_reserved_state_matches(character: String, prepared: Dictionary) -> bool:
	if _research_preparations.get(character, {}).get("applied") == true:
		return revision(character) == _research_applied_revision(prepared) and _research_state_equivalent(prepared, state(character), prepared.after)
	return revision(character) == prepared.revision and _research_state_equivalent(prepared, state(character), prepared.before)

func _research_applied_revision(prepared: Dictionary) -> int:
	# Request checkpoints preserve the original quoted action revision. The
	# synchronous real transaction advances it once; exact full-record CAS and
	# the shared reservation prevent another baseline or writer using this slot.
	return int(prepared.revision) if prepared.get("kind") == "owner_action_passive_preparation" else int(prepared.revision) + 1

func _research_state_equivalent(prepared: Dictionary, left: Dictionary, right: Dictionary) -> bool:
	if prepared.get("kind") in ["owner_passive_preparation", "owner_action_passive_preparation"]:
		return preload("res://scripts/net/owner_passive_preparation.gd").exact(left, right)
	return equivalent(left, right)

func _research_other_transaction(character: String) -> bool:
	return _portal_mutation_pending(character) or _portal_stages.has(character) \
		or _loadout_pending.has(character) or _vitals_pending.has(character) or _vitals_stages.has(character)

func _research_reserved(character: String) -> bool:
	return _research_preparations.has(character) and _research_preparations[character].committed != true

func state(character_id: String) -> Dictionary:
	return _records[character_id].state.duplicate(true) if _records.has(character_id) else {}

## Admission-time portable flags, held on the existing character registry row.
## Subsequent updates come only from host-authored personal ledger flag ops.
func seed_personal_flags(character: String, raw: Variant) -> bool:
	if not _records.has(character) or not personal_flags_valid(raw): return false
	if _records[character].has("personal_flags"): return true
	_records[character].personal_flags = {}
	for flag: String in raw.flags: _records[character].personal_flags[flag] = true
	return true

static func personal_flags_valid(raw: Variant) -> bool:
	if not raw is Dictionary or raw.size() != 1 or not raw.get("flags") is Array: return false
	var seen := {}
	for flag: Variant in raw.flags:
		if not flag is String or flag.is_empty() or seen.has(flag) or preload("res://autoload/progression_state.gd").scope_of(flag) != "player": return false
		seen[flag] = true
	return true

func personal_flags(character: String) -> Dictionary:
	return _records.get(character, {}).get("personal_flags", {}).duplicate(true)

func record_personal_flag(character: String, flag: String, value: bool) -> void:
	if not _records.has(character) or preload("res://autoload/progression_state.gd").scope_of(flag) != "player": return
	if not _records[character].has("personal_flags"): _records[character].personal_flags = {}
	if value: _records[character].personal_flags[flag] = true
	else: _records[character].personal_flags.erase(flag)


## Actual combat consumers use this detached view of the SAME admitted row.
## RealmHeartState currently activates from merged world flags; those cannot
## prove this traveler's personal relic hang. Keep the portable legacy choice
## and typed hung array in state(), but expose no power until a protected
## personal grant/hang producer exists. Empty selection yields baseline 1.0.
## No per-request stats, cloned ownership registry or inferred receipt here.
func actor_stat_state(character_id: String) -> Dictionary:
	var personal := state(character_id)
	if personal.is_empty():
		return {}
	personal.realm_hearts = {"active_id": ""}
	personal.redesign_character.relics_hung = []
	return personal


func revision(character_id: String) -> int:
	return int(_records[character_id].revision) if _records.has(character_id) else -1


## Session alone projects the actual local host PlayerState here. Remote
## packets never reach this arm: their baseline is retained by admission. This
## tracks host-earned party/gifts without taking a client's proposed refresh.
func refresh_host_local(raw: Dictionary, character_id: String) -> Dictionary:
	if _portal_mutation_pending(character_id): return {"ok": true, "revision": revision(character_id), "state": state(character_id), "pending_transaction": true}
	if _training_locked(character_id) or _portal_stages.has(character_id) or _loadout_pending.has(character_id) or _vitals_pending.has(character_id):
		return {"ok": true, "revision": revision(character_id), "state": state(character_id), "pending_transaction": true}
	var seeded := seed_admitted_character(raw, character_id)
	if not bool(seeded.get("ok", false)) or not bool(seeded.get("already_seeded", false)):
		return seeded
	var current := state(character_id)
	var candidate := raw.duplicate(true)
	candidate["vitals_escrow"] = raw.get("vitals_escrow", {}).duplicate(true)
	# Gear/selection are captured once at actual admission. This local save
	# projection is not an equip CAS and cannot refresh a command profile on a
	# later hit. Future host-authorized gear changes need their typed doorway.
	candidate["equipment"] = current.equipment.duplicate(true)
	candidate["realm_hearts"] = current.realm_hearts.duplicate(true)
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
	_replace_record(character_id, revision(character_id) + 1, candidate)
	return {"ok": true, "revision": revision(character_id), "state": state(character_id)}


## Only accepted host HP-contact code supplies the staged maps. There is no
## RPC or arbitrary snapshot replacement arm for a client's proposed rank.
func commit_creature_mastery(character_id: String, uid: String, expected_revision: int,
		expected_uses: Dictionary, expected_receipts: Dictionary, next_uses: Dictionary,
		next_receipts: Dictionary) -> Dictionary:
	if _portal_mutation_pending(character_id): return {"ok": false, "code": "portal_owner_save_pending", "revision": revision(character_id)}
	if _training_locked(character_id) or _portal_stages.has(character_id) or _loadout_pending.has(character_id) or _vitals_stages.has(character_id):
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
	_replace_record(character_id, expected_revision + 1, candidate)
	return {"ok": true, "revision": expected_revision + 1, "state": state(character_id)}


## The registered live station caller stages only the three editable slots.
## An accepted edit remains locked until the portable owner has atomically
## saved this exact revision. Disconnect/rejoin returns the retained pending
## edit; a later packet cannot replace or undo that accepted host baseline.
func commit_creature_loadout(character_id: String, uid: String, expected_revision: int,
		expected_loadout_revision: int, expected_last_edit: Dictionary, next_loadout: Dictionary,
		next_loadout_revision: int, next_edit_receipt: Dictionary) -> Dictionary:
	if _portal_mutation_pending(character_id): return {"ok": false, "code": "portal_owner_save_pending", "revision": revision(character_id)}
	if _training_locked(character_id) or _portal_stages.has(character_id) or _vitals_stages.has(character_id):
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
	_replace_record(character_id, expected_revision + 1, candidate)
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
	if _portal_mutation_pending(character_id): return {"ok": false, "code": "portal_owner_save_pending"}
	if _training_locked(character_id) or _portal_stages.has(character_id) or _loadout_pending.has(character_id) or _vitals_stages.has(character_id):
		return {"ok": false, "code": "transaction_busy"}
	var candidate := state(character_id)
	if candidate.is_empty() or not PORTAL.KEYS.has(biome) \
			or receipt != PORTAL.receipt(biome, character_id, _world_instance):
		return {"ok": false, "code": "not_admitted"}
	var personal: Dictionary = candidate.redesign_character
	if personal.transaction_receipts.has(receipt):
		return {"ok": true, "duplicate": true, "revision": revision(character_id)}
	if biome == "biome5" and character_fifth_stirred(character_id):
		return {"ok": false, "code": "already_stirred"}
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
	if slot < 0:
		return {"ok": false, "code": "key_delivery_pending"}
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
		"token": token, "revision": revision(character_id), "key_slot": slot}


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
		if owned.redesign_character.transaction_receipts.has(PORTAL.receipt(biome, character_id, _world_instance)):
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
	_replace_record(character_id, revision(character_id) + 1, candidate.duplicate(true))
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


## Internal host settlement only. A later accepted absolute value supersedes
## owner-save pending data without freezing combat. This is retained memory,
## not a durable handoff until the existing world journal saves successfully.
func commit_creature_vitals(character_id: String, uid: String, expected_revision: int,
		expected_hp: float, expected_fainted: bool, next_hp: float, next_fainted: bool,
		receipt: Dictionary) -> Dictionary:
	if _portal_mutation_pending(character_id): return {"ok": false, "code": "portal_owner_save_pending", "revision": revision(character_id)}
	if _training_locked(character_id) or _portal_stages.has(character_id) or _vitals_stages.has(character_id):
		return {"ok": false, "code": "transaction_busy"}
	if not valid_vitals_receipt(receipt, uid):
		return {"ok": false, "code": "invalid_vitals_receipt"}
	var key: String = receipt.receipt_id
	var old: Variant = _vitals_seen.get(character_id, {}).get(key)
	if old is Dictionary:
		if not equivalent(old.receipt, receipt) or not equivalent(old.hp, next_hp) or old.fainted != next_fainted:
			return {"ok": false, "code": "receipt_conflict"}
		return {"ok": true, "duplicate": true, "revision": revision(character_id),
			"state": state(character_id), "pending_owner_save": true, "durable": bool(old.get("durable", false)),
			"accepted": old.duplicate(true)}
	var config: Variant = preload("res://scripts/data/redesign_data.gd").json("res://data/config/character_authority.json")
	var limit: Variant = config.get("vitals_receipts_per_character_limit") if config is Dictionary else null
	if not (limit is int or limit is float) or not is_finite(float(limit)) or float(limit) < 1.0 \
			or float(limit) != floor(float(limit)) or float(limit) > 1000000.0 \
			or _vitals_seen.get(character_id, {}).size() >= int(limit):
		return {"ok": false, "code": "vitals_history_capacity", "revision": revision(character_id)}
	if expected_revision < 0 or revision(character_id) != expected_revision:
		return {"ok": false, "code": "stale_revision", "revision": revision(character_id)}
	var candidate := state(character_id)
	var owned: Dictionary = {}
	for row: Dictionary in candidate.party:
		if row.uid == uid:
			owned = row
			break
	if owned.is_empty() or not equivalent(owned.get("hp"), expected_hp) or owned.get("fainted") != expected_fainted:
		return {"ok": false, "code": "stale_vitals"}
	var maximum: Variant = owned.get("max_hp")
	if not (maximum is int or maximum is float) or not is_finite(float(maximum)) or float(maximum) <= 0.0 \
			or not is_finite(expected_hp) or not is_finite(next_hp) or next_hp < 0.0 or next_hp > float(maximum) \
			or next_fainted != (next_hp == 0.0) or (expected_fainted and not next_fainted):
		return {"ok": false, "code": "invalid_vitals"}
	# The caller supplies only HP/faint. No maximum/party/move/inventory import.
	owned.hp = next_hp
	owned.fainted = next_fainted
	var failures := errors(candidate, character_id)
	if not failures.is_empty():
		return {"ok": false, "code": "invalid_character", "errors": failures}
	_replace_record(character_id, expected_revision + 1, candidate)
	if not _vitals_pending.has(character_id):
		_vitals_pending[character_id] = {}
	if not _vitals_seen.has(character_id):
		_vitals_seen[character_id] = {}
	var accepted := {"uid": uid, "hp": next_hp, "fainted": next_fainted,
		"max_hp": maximum, "receipt": receipt.duplicate(true), "character_revision": expected_revision + 1,
		"expected_hp": expected_hp, "expected_fainted": expected_fainted, "durable": false}
	_vitals_pending[character_id][uid] = accepted
	_vitals_seen[character_id][key] = accepted.duplicate(true)
	return {"ok": true, "duplicate": false, "revision": expected_revision + 1,
		"state": state(character_id), "pending_owner_save": true, "durable": false,
		"accepted": accepted.duplicate(true)}


## Freeze only a synchronous world-save transaction. This private token is
## never accepted from a network packet. The old record, latest owner pending
## settlement and replay history all roll back together on world-write failure.
func stage_creature_vitals(character_id: String, uid: String, expected_revision: int,
		expected_hp: float, expected_fainted: bool, next_hp: float, next_fainted: bool,
		receipt: Dictionary) -> Dictionary:
	if _vitals_stages.has(character_id):
		return {"ok": false, "code": "transaction_busy"}
	var before := {"record": _records.get(character_id, {}).duplicate(true),
		"pending": _vitals_pending.get(character_id, {}).duplicate(true),
		"seen": _vitals_seen.get(character_id, {}).duplicate(true)}
	var result := commit_creature_vitals(character_id, uid, expected_revision,
		expected_hp, expected_fainted, next_hp, next_fainted, receipt)
	if not bool(result.get("ok", false)) or bool(result.get("duplicate", false)):
		return result
	_vitals_stage_sequence += 1
	result["token"] = _vitals_stage_sequence
	result["character_id"] = character_id
	_vitals_stages[character_id] = {"token": result.token, "before": before,
		"uid": uid, "receipt_id": str(receipt.receipt_id), "revision": result.revision}
	return result


func finish_creature_vitals(stage: Dictionary, world_saved: bool) -> bool:
	var character := str(stage.get("character_id", ""))
	var frozen: Variant = _vitals_stages.get(character)
	if not frozen is Dictionary or stage.get("token") != frozen.token \
			or revision(character) != int(frozen.revision):
		return false
	if not world_saved:
		_records[character] = frozen.before.record.duplicate(true)
		if frozen.before.pending.is_empty():
			_vitals_pending.erase(character)
		else:
			_vitals_pending[character] = frozen.before.pending.duplicate(true)
		if frozen.before.seen.is_empty():
			_vitals_seen.erase(character)
		else:
			_vitals_seen[character] = frozen.before.seen.duplicate(true)
	else:
		_vitals_seen[character][frozen.receipt_id].durable = true
		_vitals_pending[character][frozen.uid].durable = true
	_vitals_stages.erase(character)
	return true


## The private stage token selects the frozen result. Never trust a caller's
## mutable accepted dictionary when constructing the durable world journal.
func staged_creature_vitals(stage: Dictionary) -> Dictionary:
	var character := str(stage.get("character_id", ""))
	var frozen: Variant = _vitals_stages.get(character)
	if not frozen is Dictionary or stage.get("token") != frozen.token \
			or revision(character) != int(frozen.revision):
		return {}
	return _vitals_pending.get(character, {}).get(frozen.uid, {}).duplicate(true)


static func valid_vitals_receipt(receipt: Dictionary, uid: String) -> bool:
	var keys := ["receipt_id", "encounter_id", "creature_uid", "body_generation", "vitals_revision"]
	if receipt.size() != keys.size():
		return false
	for key: String in keys:
		if not receipt.has(key):
			return false
	for key: String in ["receipt_id", "encounter_id", "creature_uid"]:
		if not receipt[key] is String or receipt[key].is_empty() or receipt[key].length() > 160:
			return false
	for key: String in ["body_generation", "vitals_revision"]:
		var value: Variant = receipt[key]
		if not (value is int or value is float) or not is_finite(float(value)) \
				or float(value) < 1.0 or float(value) != floor(float(value)) or float(value) > 2147483647.0:
			return false
	return receipt.creature_uid == uid


func pending_creature_vitals(character_id: String) -> Dictionary:
	return _vitals_pending.get(character_id, {}).duplicate(true)


## Reconstruct only this world's discriminated pending absolute values before
## admitting a character to act. An accepted historical row supplies a revision
## high-water only: it cannot overwrite newer portability from another world.
func recover_durable_vitals(character_id: String, deliveries: Dictionary) -> Dictionary:
	var candidate := state(character_id)
	if candidate.is_empty() or _portal_stages.has(character_id) or _vitals_stages.has(character_id):
		return {"ok": false, "code": "authority_not_ready"}
	var actor := preload("res://scripts/net/actor_vitals_delivery.gd")
	var high_water := revision(character_id)
	var pending: Dictionary = _vitals_pending.get(character_id, {}).duplicate(true)
	var seen: Dictionary = _vitals_seen.get(character_id, {}).duplicate(true)
	for raw: Variant in deliveries.values():
		if not raw is Dictionary or raw.get("kind") != "actor_vitals" \
				or raw.get("character_id") != character_id:
			continue
		if not actor.valid(raw, character_id, _world_instance) or raw.status == "settled":
			return {"ok": false, "code": "malformed_durable_vitals"}
		high_water = maxi(high_water, int(raw.character_revision))
		if raw.status == "accepted":
			continue
		var owned: Dictionary = {}
		for row: Dictionary in candidate.party:
			if row.uid == raw.creature_uid:
				owned = row
				break
		if owned.is_empty() or not actor.personal_baseline_matches(owned, raw,
			candidate.get("vitals_escrow", {}).get(raw.delivery_id)):
			return {"ok": false, "code": "unsettled_vitals_conflict"}
		owned.hp = float(raw.hp)
		owned.fainted = bool(raw.fainted)
		var accepted := {"uid": str(raw.creature_uid), "hp": raw.hp, "fainted": raw.fainted,
			"max_hp": raw.max_hp, "receipt": raw.receipt.duplicate(true),
			"character_revision": raw.character_revision, "expected_hp": raw.expected_hp,
			"expected_fainted": raw.expected_fainted, "durable": true}
		pending[raw.creature_uid] = accepted
		seen[raw.receipt.receipt_id] = accepted.duplicate(true)
	var config: Variant = preload("res://scripts/data/redesign_data.gd").json("res://data/config/character_authority.json")
	var limit: Variant = config.get("vitals_receipts_per_character_limit") if config is Dictionary else null
	if not (limit is int or limit is float) or not is_finite(float(limit)) \
			or float(limit) != floor(float(limit)) or float(limit) < 1.0 \
			or float(limit) > 1000000.0 or seen.size() > int(limit):
		return {"ok": false, "code": "vitals_history_capacity"}
	var failures := errors(candidate, character_id)
	if not failures.is_empty():
		return {"ok": false, "code": "invalid_character", "errors": failures}
	if _research_reserved(character_id) and (high_water != revision(character_id) \
		or not equivalent(candidate, state(character_id)) or not pending.is_empty()):
		return {"ok": false, "code": "transaction_busy"}
	_replace_record(character_id, high_water, candidate)
	if not pending.is_empty():
		_vitals_pending[character_id] = pending
	if not seen.is_empty():
		_vitals_seen[character_id] = seen
	return {"ok": true, "revision": high_water, "state": state(character_id),
		"pending_owner_save": not pending.is_empty()}


## Owner save ACK releases only the exact newest absolute settlement. The
## retained baseline and replay history survive ACK and disconnect/rejoin.
func acknowledge_creature_vitals(character_id: String, uid: String,
		character_revision: int, receipt: Dictionary) -> bool:
	var pending: Variant = _vitals_pending.get(character_id, {}).get(uid)
	if not pending is Dictionary or int(pending.character_revision) != character_revision \
			or not equivalent(pending.receipt, receipt):
		return false
	_vitals_pending[character_id].erase(uid)
	if _vitals_pending[character_id].is_empty():
		_vitals_pending.erase(character_id)
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


## Only the same admitted full record is staged. Proposed before/state are
## internal frozen outputs, recomputed here rather than packet baselines.
func _training_locked(character: String) -> bool:
	return _training_stages.has(character) or _training_pending.has(character) or _groom_preparations.has(character) or _research_reserved(character)


func stage_creature_training(character: String, action: String, action_id: String,
		expected_revision: int, intent: Dictionary, before: Dictionary,
		next: Dictionary, receipt: String) -> Dictionary:
	if _portal_mutation_pending(character): return {"ok": false, "code": "portal_owner_save_pending"}
	if not action in ["altar_spend", "wild_defeat"] or not _records.has(character) or _training_locked(character) \
			or _portal_stages.has(character) or _loadout_pending.has(character) \
			or _vitals_pending.has(character) or _vitals_stages.has(character):
		return {"ok": false, "code": "transaction_busy"}
	if expected_revision < 0 or expected_revision >= 2147483647 or revision(character) != expected_revision \
			or intent.get("spend_id" if action == "altar_spend" else "event_id") != action_id or not equivalent(before, state(character)):
		return {"ok": false, "code": "stale_revision"}
	var actual: Dictionary = ESSENCE.stage_core_spend(state(character), character, expected_revision, intent,
		ESSENCE.config(), PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror) if action == "altar_spend" else ESSENCE.stage_core_defeat(state(character), character, intent, expected_revision,
		ESSENCE.config(), PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	if actual.get("ok") != true or actual.get("duplicate") == true \
			or actual.get("receipt") != receipt or not equivalent(actual.get("state"), next) \
			or not errors(next, character).is_empty():
		return {"ok": false, "code": "training_proposal_conflict"}
	var token := Crypto.new().generate_random_bytes(16).hex_encode()
	var accepted := {"ok": true, "token": token, "character_id": character,
		"action": action, "action_id": action_id, "intent": intent.duplicate(true),
		"before": before.duplicate(true), "state": next.duplicate(true), "receipt": receipt,
		"character_revision": expected_revision + 1}
	_training_stages[character] = {"token": token, "record": _records[character].duplicate(true),
		"accepted": accepted.duplicate(true)}
	# Hidden promotion: no yield/signal/publication before prepared world save.
	_replace_record(character, expected_revision + 1, next.duplicate(true))
	return accepted


func staged_creature_training(stage: Dictionary) -> Dictionary:
	var saved: Dictionary = _training_stages.get(str(stage.get("character_id", "")), {})
	return saved.accepted.duplicate(true) if not saved.is_empty() and saved.token == stage.get("token") else {}


func finish_creature_training(stage: Dictionary, world_saved: bool) -> bool:
	var character := str(stage.get("character_id", ""))
	var saved: Dictionary = _training_stages.get(character, {})
	if saved.is_empty() or saved.token != stage.get("token"):
		return false
	if not world_saved:
		_records[character] = saved.record.duplicate(true)
	else:
		_training_pending[character] = saved.accepted.duplicate(true)
	_training_stages.erase(character)
	return true


func acknowledge_creature_training(character: String, row: Dictionary) -> bool:
	if row.get("status") != "accepted" or row.get("character_id") != character \
			or not preload("res://autoload/world_state.gd").training_row_valid(row, _world_instance):
		return false
	var pending: Dictionary = _training_pending.get(character, {})
	if pending.is_empty():
		return _records.has(character) and state(character).redesign_character.transaction_receipts.has(row.receipt)
	if pending.receipt != row.receipt or pending.character_revision != row.character_revision \
			or revision(character) != int(row.character_revision) \
			or not equivalent(RECORD_RULES.training_projection(state(character), row, ESSENCE.training_projection), row.after):
		return false
	_training_pending.erase(character)
	return true


## Host restart recovers one typed decision from the existing world document.
## Portable before/after must match exactly; never trust a packet balance.
func recover_durable_training(character: String, deliveries: Dictionary) -> Dictionary:
	if not _records.has(character): return {"ok": false, "code": "not_admitted"}
	var row: Dictionary = preload("res://autoload/world_state.gd").training_owner_row(deliveries, _world_instance, "", character)
	if row.is_empty():
		for raw: Variant in deliveries.values():
			if raw is Dictionary and raw.get("character_id") == character and raw.get("kind") in ["creature_training", "altar_building"]: return {"ok": false, "code": "invalid_training_journal"}
		return {"ok": true}
	if not preload("res://autoload/world_state.gd").training_row_valid(row, _world_instance) \
			or row.character_id != character:
		return {"ok": false, "code": "invalid_training_journal"}
	var current := state(character)
	if row.status == "accepted":
		# Old accepted history must never replace a later earned portable state.
		if not current.redesign_character.transaction_receipts.has(row.receipt):
			return {"ok": false, "code": "accepted_training_marker_missing"}
		if _research_reserved(character) and int(row.character_revision) > revision(character):
			return {"ok": false, "code": "transaction_busy"}
		_records[character].revision = maxi(revision(character), int(row.character_revision))
		return {"ok": true}
	if _portal_stages.has(character) or _loadout_pending.has(character) or _vitals_pending.has(character) \
			or _vitals_stages.has(character) or _training_stages.has(character) or _research_reserved(character):
		return {"ok": false, "code": "transaction_busy"}
	var projected := RECORD_RULES.training_projection(current, row, ESSENCE.training_projection)
	if not equivalent(projected, row.before) and not equivalent(projected, row.after):
		return {"ok": false, "code": "unsettled_training_conflict"}
	# The validated journal owns exactly its canonical projection: v1 Altar
	# building/training has three fields; v2/v3 training has all eight admitted
	# fields. Preserve unrelated v1 gear/escrows, and recover every v2/v3 field.
	for field: String in projected:
		var value: Variant = row.after[field]
		current[field] = value.duplicate(true) if value is Dictionary or value is Array else value
	if not errors(current, character).is_empty(): return {"ok": false, "code": "invalid_training_candidate"}
	_replace_record(character, int(row.character_revision), current)
	_training_pending[character] = {"receipt": row.receipt, "character_revision": row.character_revision}
	return {"ok": true, "pending": true}


func creature_training_is_pending(character: String) -> bool:
	return _training_locked(character)


func creature_training_pending_matches(character: String, row: Dictionary) -> bool:
	var pending: Dictionary = _training_pending.get(character, {})
	return not pending.is_empty() and pending.get("receipt") == row.get("receipt") \
		and pending.get("character_revision") == row.get("character_revision") \
		and revision(character) == int(row.get("character_revision", -1)) \
		and equivalent(RECORD_RULES.training_projection(state(character), row, ESSENCE.training_projection), row.get("after"))


## The same private stage/pending fence as Altar training. No separate
## inventory ledger; full admitted state remains the only mutable baseline.
## Serves version-1 Altar and version-2 F31 Homestead records alike.
func stage_altar_building(character: String, proposal: Dictionary) -> Dictionary:
	if _portal_mutation_pending(character): return {"ok": false, "code": "portal_owner_save_pending"}
	if not _records.has(character) or _training_locked(character) \
		or _portal_stages.has(character) or _loadout_pending.has(character) \
		or _vitals_pending.has(character) or _vitals_stages.has(character):
		return {"ok": false, "code": "transaction_busy"}
	if proposal.get("ok") != true or proposal.get("character_id") != character \
		or proposal.get("character_revision") != revision(character) + 1 \
		or not equivalent(proposal.get("before"), state(character)): return {"ok": false, "code": "stale_revision"}
	var actual := preload("res://autoload/world_state.gd").building_transition(state(character),
		character, revision(character), proposal.action, proposal.action_id, proposal.record, _world_instance)
	if actual.is_empty() or not equivalent(actual, proposal) or not errors(actual.state, character).is_empty():
		return {"ok": false, "code": "invalid_building_candidate"}
	var token := Crypto.new().generate_random_bytes(16).hex_encode()
	actual.token = token
	_training_stages[character] = {"token": token, "record": _records[character].duplicate(true), "accepted": actual.duplicate(true)}
	_replace_record(character, actual.character_revision, actual.state.duplicate(true))
	return actual


func character_fifth_stirred(character_id: String) -> bool:
	var personal := state(character_id)
	if personal.is_empty(): return false
	for raw: Variant in personal.portal_escrow.values():
		if PORTAL.valid_row(raw, character_id) and raw.biome == "biome5" and raw.status == "settled": return true
	return false


## Reconstruct the hidden debit from the already saved world journal before
## an admitted rejoin can use another key. Never accept a client replacement.
func recover_durable_portals(character_id: String, deliveries: Dictionary) -> Dictionary:
	const DELIVERY = preload("res://scripts/net/portal_delivery.gd")
	var current := state(character_id)
	if current.is_empty(): return {"ok": false, "code": "not_admitted"}
	var candidate := current.duplicate(true)
	for raw: Variant in deliveries.values():
		if not raw is Dictionary or raw.get("kind") != DELIVERY.KIND or raw.get("character_id") != character_id: continue
		if not DELIVERY.valid(raw, character_id, _world_instance) or raw.status not in ["pending", "accepted"]:
			return {"ok": false, "code": "invalid_portal_journal"}
		if candidate.redesign_character.transaction_receipts.has(raw.receipt): continue
		if _portal_stages.has(character_id) or _training_stages.has(character_id) or _training_pending.has(character_id) or _loadout_pending.has(character_id) or _vitals_pending.has(character_id) or _research_reserved(character_id): return {"ok": false, "code": "transaction_busy"}
		var slot := -1
		for index: int in candidate.inventory.size():
			var stack: Variant = candidate.inventory[index]
			if stack is Dictionary and stack.id == raw.item:
				if slot >= 0 or stack.n != 1: return {"ok": false, "code": "invalid_owned_key"}
				slot = index
		if slot >= 0: candidate.inventory[slot] = null
		candidate.redesign_character.transaction_receipts.append(raw.receipt)
		if raw.biome != "biome5" and not candidate.redesign_character.portal_unlocks.has(raw.biome):
			candidate.redesign_character.portal_unlocks.append(raw.biome)
	if not errors(candidate, character_id).is_empty(): return {"ok": false, "code": "invalid_portal_recovery"}
	if not equivalent(current, candidate): _replace_record(character_id, revision(character_id) + 1, candidate)
	return {"ok": true, "revision": revision(character_id)}


var _portal_pending_reader: Callable

func bind_portal_pending_reader(reader: Callable) -> void:
	_portal_pending_reader = reader

func _portal_mutation_pending(character_id: String) -> bool:
	return _portal_pending_reader.is_valid() and _portal_pending_reader.call(character_id) == true


const CHARACTER_ACTIONS := preload("res://scripts/net/character_action_rules.gd")

## Host-internal synchronous stage. Session derives context from the actual
## registered source; no network packet contains a source context/candidate.
## Existing _training_stages/_training_pending and _records remain the only
## transaction and admitted-character stores. The prepared writer must finish
## this stage immediately with its real bool world-save result before yielding.
func stage_character_action(character: String, expected_revision: int,
		action: String, original_intent: Dictionary, host_context: Dictionary) -> Dictionary:
	if _portal_mutation_pending(character) or not _records.has(character) or _training_locked(character) \
			or _portal_stages.has(character) or _loadout_pending.has(character) \
			or _vitals_pending.has(character) or _vitals_stages.has(character):
		return {"ok": false, "code": "transaction_busy", "durable": false}
	if expected_revision < 0 or expected_revision >= 2147483647 or revision(character) != expected_revision:
		return {"ok": false, "code": "stale_revision", "revision": revision(character), "durable": false}
	var action_rules: Script = preload("res://scripts/net/foundation_actions.gd") if action in preload("res://scripts/net/foundation_actions.gd").ACTIONS else CHARACTER_ACTIONS
	var proposal: Dictionary = action_rules.stage(state(character), expected_revision, action,
		original_intent, host_context, errors)
	if proposal.get("ok") != true: return proposal.duplicate(true)
	# A callback is re-staged inside the actual canonical registry. It cannot
	# be substituted by an owner-proposed inventory, cost, cap, seed or party.
	var token := Crypto.new().generate_random_bytes(16).hex_encode()
	var accepted: Dictionary = proposal.duplicate(true)
	accepted.token = token
	accepted.action_id = proposal.receipt.sha256_text()
	accepted.character_revision = expected_revision + 1
	_training_stages[character] = {"token": token, "record": _records[character].duplicate(true),
		"accepted": accepted.duplicate(true)}
	# Hidden promotion: the existing finish_creature_training rolls back all
	# canonical state on failed world save, or retains the original owner
	# pending action until exact bool-owner-save/ACK and second world save.
	_replace_record(character, expected_revision + 1, accepted.state.duplicate(true))
	return accepted
