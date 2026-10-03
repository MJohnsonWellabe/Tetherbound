extends RefCounted

## Strict discriminator within the existing durable reward delivery carrier.
## Only an internal retained host actor supplies the absolute values. This
## record contains no inventory, moves or replacement portable party.
const VERSION := 1
const KIND := "actor_vitals"
const KEYS := ["version", "kind", "delivery_id", "world_id", "world_namespace", "session_id",
	"character_id", "creature_uid", "max_hp", "expected_hp", "expected_fainted", "hp", "fainted", "character_revision",
	"journal_revision", "receipt", "status"]
const RECEIPT_KEYS := ["receipt_id", "encounter_id", "creature_uid", "body_generation", "vitals_revision"]

## Exact host HP transition, including the existing faint condition effect.
## Original alive/fainted state owns once-only application; a live-after
## failed-write retry never spends mood/rest for the same faint a second time.
static func settled_card(current: Dictionary, hp: float, fainted: bool) -> Dictionary:
	if not current.get("fainted") is bool or not (current.get("max_hp") is int or current.get("max_hp") is float) \
		or not is_finite(float(current.max_hp)) or float(current.max_hp) <= 0.0 \
		or not is_finite(hp) or hp < 0.0 or hp > float(current.max_hp) or fainted != (hp == 0.0) \
		or (current.fainted and not fainted): return {}
	var next := current.duplicate(true)
	next.hp = hp
	next.fainted = fainted
	if not current.fainted and fainted:
		var snapshot := preload("res://scripts/creatures/progression.gd").TrainingConditionSnapshot.new()
		snapshot.values = next
		var condition: Script = preload("res://scripts/creatures/creature_condition.gd")
		condition.call("note_faint", snapshot, condition.call("config"))
		next = snapshot.values
	return next


static func delivery_id(world_namespace: String, character_id: String, uid: String) -> String:
	if world_namespace.is_empty() or character_id.is_empty() or uid.is_empty():
		return ""
	return KIND + ":" + ("%s\n%s\n%s" % [world_namespace, character_id, uid]).sha256_text()


static func valid(raw: Variant, owner: String = "", world_namespace: String = "") -> bool:
	if not raw is Dictionary or raw.size() != KEYS.size():
		return false
	for key: String in KEYS:
		if not raw.has(key):
			return false
	for key: String in ["delivery_id", "world_id", "world_namespace", "session_id", "character_id", "creature_uid"]:
		if not raw[key] is String or raw[key].is_empty() or raw[key].length() > 160:
			return false
	if raw.kind != KIND or not _integer(raw.version, VERSION, VERSION) \
			or not raw.status in ["pending", "accepted", "settled"] \
			or raw.delivery_id != delivery_id(raw.world_namespace, raw.character_id, raw.creature_uid) \
			or (not owner.is_empty() and raw.character_id != owner) \
			or (not world_namespace.is_empty() and raw.world_namespace != world_namespace):
		return false
	if not _integer(raw.character_revision, 1, 2147483647) or not _integer(raw.journal_revision, 1, 2147483647):
		return false
	for key: String in ["hp", "expected_hp", "max_hp"]:
		if not (raw[key] is int or raw[key] is float) or not is_finite(float(raw[key])):
			return false
	if float(raw.max_hp) <= 0.0 or float(raw.hp) < 0.0 or float(raw.hp) > float(raw.max_hp) \
			or float(raw.expected_hp) < 0.0 or float(raw.expected_hp) > float(raw.max_hp) \
			or not raw.expected_fainted is bool or raw.expected_fainted != (float(raw.expected_hp) == 0.0) \
			or (raw.expected_fainted and not raw.fainted) \
			or not raw.fainted is bool or raw.fainted != (float(raw.hp) == 0.0):
		return false
	var receipt: Variant = raw.receipt
	if not receipt is Dictionary or receipt.size() != RECEIPT_KEYS.size():
		return false
	for key: String in RECEIPT_KEYS:
		if not receipt.has(key):
			return false
	for key: String in ["receipt_id", "encounter_id", "creature_uid"]:
		if not receipt[key] is String or receipt[key].is_empty() or receipt[key].length() > 160:
			return false
	return receipt.creature_uid == raw.creature_uid \
		and _integer(receipt.body_generation, 1, 2147483647) \
		and _integer(receipt.vitals_revision, 1, 2147483647)


static func next_record(world_id: String, world_namespace: String, session_id: String,
		character: String, uid: String, maximum: float, expected_hp: float, expected_fainted: bool,
		hp: float, fainted: bool,
		character_revision: int, receipt: Dictionary, previous: Variant) -> Dictionary:
	if not receipt_valid(receipt, uid):
		return {} # Validate finite whole numbers before any int normalization.
	var journal_revision := 1
	if previous != null:
		if not valid(previous, character, world_namespace) or previous.creature_uid != uid:
			return {}
		if int(previous.character_revision) >= character_revision \
				or (previous.receipt.encounter_id == receipt.get("encounter_id") \
					and int(previous.receipt.body_generation) == int(receipt.get("body_generation", -1)) \
					and int(previous.receipt.vitals_revision) >= int(receipt.get("vitals_revision", -1))):
			return {}
		journal_revision = int(previous.journal_revision) + 1
		# The owner may have missed every intermediate accepted hit. Preserve
		# the oldest unsettled personal CAS baseline while superseding absolute
		# HP, rather than requiring an owner to replay missing delta packets.
		if previous.status != "accepted":
			expected_hp = float(previous.expected_hp)
			expected_fainted = bool(previous.expected_fainted)
	var row := {"version": VERSION, "kind": KIND, "delivery_id": delivery_id(world_namespace, character, uid),
		"world_id": world_id, "world_namespace": world_namespace, "session_id": session_id,
		"character_id": character, "creature_uid": uid, "max_hp": maximum, "hp": hp, "fainted": fainted,
		"expected_hp": expected_hp, "expected_fainted": expected_fainted,
		"character_revision": character_revision, "journal_revision": journal_revision,
		"receipt": receipt.duplicate(true), "status": "pending"}
	return row if valid(row, character, world_namespace) else {}


static func receipt_valid(raw: Variant, uid: String) -> bool:
	if not raw is Dictionary or raw.size() != RECEIPT_KEYS.size():
		return false
	for key: String in RECEIPT_KEYS:
		if not raw.has(key):
			return false
	for key: String in ["receipt_id", "encounter_id", "creature_uid"]:
		if not raw[key] is String or raw[key].is_empty() or raw[key].length() > 160:
			return false
	return raw.creature_uid == uid and _integer(raw.body_generation, 1, 2147483647) \
		and _integer(raw.vitals_revision, 1, 2147483647)


## Save boundaries validate all matching discriminator/prefix records. A
## historical settled marker may refer to a released creature or an earlier
## level's maximum; it proves a receipt only, never current ownership.
static func escrow_errors(raw: Variant, owner: String) -> Array[String]:
	var errors: Array[String] = []
	if not raw is Dictionary:
		return ["personal escrow must be an object"]
	for key: Variant in raw:
		var row: Variant = raw[key]
		if str(key).begins_with(KIND + ":") or (row is Dictionary and row.get("kind") == KIND):
			if not valid(row, owner) or row.status != "settled" or key != row.delivery_id:
				errors.append("malformed actor vitals escrow " + str(key))
	return errors


static func world_errors(raw: Variant, world_namespace: String, world_id: String = "") -> Array[String]:
	var errors: Array[String] = []
	if not raw is Dictionary:
		return ["world deliveries must be an object"]
	for key: Variant in raw:
		var row: Variant = raw[key]
		if str(key).begins_with(KIND + ":") or (row is Dictionary and row.get("kind") == KIND):
			if world_namespace.is_empty() or not valid(row, "", world_namespace) \
					or (not world_id.is_empty() and row.world_id != world_id) \
					or row.status == "settled" or key != row.delivery_id:
				errors.append("malformed world actor vitals delivery " + str(key))
	return errors


static func has_pending_owner(records: Dictionary, character: String) -> bool:
	for raw: Variant in records.values():
		if raw is Dictionary and raw.get("kind") == KIND \
				and raw.get("character_id") == character and raw.get("status") == "pending":
			return true
	return false


## Generic historical reward ops cannot inject or ACK these records. The new
## discriminated arms retain exact latest revision/receipt binding.
static func valid_world_op(op: Dictionary, records: Dictionary, world_namespace: String) -> bool:
	if world_namespace.is_empty() or op.get("scope") != "world" or not op.get("delivery_id") is String:
		return false
	var previous: Variant = records.get(op.delivery_id)
	match op.get("op"):
		"actor_vitals_journal":
			if op.size() != 4 or not op.has("delivery") or not valid(op.delivery, "", world_namespace) \
					or op.delivery.delivery_id != op.delivery_id or op.delivery.status != "pending":
				return false
			if previous == null:
				return int(op.delivery.journal_revision) == 1
			if not valid(previous, op.delivery.character_id, world_namespace) \
					or previous.creature_uid != op.delivery.creature_uid \
					or int(op.delivery.journal_revision) != int(previous.journal_revision) + 1 \
					or int(op.delivery.character_revision) <= int(previous.character_revision):
				return false
			return previous.status == "accepted" or (
				equivalent(op.delivery.expected_hp, previous.expected_hp) \
				and op.delivery.expected_fainted == previous.expected_fainted)
		"actor_vitals_accept":
			var keys := ["op", "scope", "delivery_id", "character_id", "journal_revision", "receipt"]
			if op.size() != keys.size():
				return false
			for key: String in keys:
				if not op.has(key):
					return false
			return op.character_id is String and not op.character_id.is_empty() \
				and previous is Dictionary and previous.get("character_id") == op.character_id \
				and valid(previous, op.character_id, world_namespace) and previous.status == "pending" \
				and equivalent(previous.journal_revision, op.journal_revision) and equivalent(previous.receipt, op.receipt)
	return false


## Both bootstrap and the owner receiver use the same per-UID proof. A saved
## intermediate settled marker is valid after its ACK was lost and subsequent
## accepted damage superseded the journal. Foreign/stale markers never grant HP.
static func personal_baseline_matches(owned: Dictionary, incoming: Dictionary, previous: Variant) -> bool:
	if not valid(incoming) or owned.get("uid") != incoming.creature_uid \
			or not equivalent(owned.get("max_hp"), incoming.max_hp):
		return false
	var matches_after: bool = equivalent(owned.get("hp"), incoming.hp) and owned.get("fainted") == incoming.fainted
	if previous != null:
		if not valid(previous, incoming.character_id, incoming.world_namespace) \
				or previous.status != "settled" or previous.creature_uid != incoming.creature_uid \
				or int(previous.journal_revision) > int(incoming.journal_revision):
			return false
		if int(previous.journal_revision) == int(incoming.journal_revision):
			var expected: Dictionary = incoming.duplicate(true)
			expected.status = "settled"
			return equivalent(previous, expected) and matches_after
		if equivalent(previous.max_hp, incoming.max_hp) \
				and equivalent(owned.get("hp"), previous.hp) and owned.get("fainted") == previous.fainted:
			return true
	return matches_after or (equivalent(owned.get("hp"), incoming.expected_hp) \
		and owned.get("fainted") == incoming.expected_fainted)


## The host transport caller supplies the current world identities; payload
## world names cannot authenticate themselves. Only this owned UID's HP and
## faint state change. Save failure retains accepted live HP and restores only
## the unsaved marker. The durable world row remains pending for the retry.
static func apply_owner(game: Node, incoming: Variant) -> Dictionary:
	var saver: Variant = game.get("save_system")
	if not saver is Object or not saver.has_method("finish_fallback") \
			or not saver.has_method("save_character_prepared") or not saver.has_method("fallback_busy"):
		return {"ok": false, "code": "prepared_owner_writer_missing"}
	# Its completion listeners may change the latest journal or start another
	# fallback. Finish BEFORE taking any owner/receipt/HP/marker references.
	saver.call("finish_fallback")
	if bool(saver.call("fallback_busy")):
		return {"ok": false, "code": "fallback_busy"}
	var player: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	if player == null or world == null:
		return {"ok": false, "code": "not_ready"}
	var character := str(player.get("character_id"))
	var world_namespace := str(world.get("reward_delivery_namespace"))
	if character.is_empty() or world_namespace.is_empty() \
			or not valid(incoming, character, world_namespace) or incoming.world_id != str(world.get("world_id")):
		return {"ok": false, "code": "foreign_vitals"}
	if not equivalent(world.get("reward_deliveries").get(incoming.delivery_id), incoming):
		return {"ok": false, "code": "superseded_world_vitals"}
	var session: Variant = game.get("session")
	if not session is Node or not session.has_method("_owner_vitals_retry_receipt") \
			or not session.has_method("_retain_owner_vitals_retry"):
		return {"ok": false, "code": "owner_retry_context_missing"}
	var escrow: Dictionary = player.get("satchel_escrow")
	var previous: Variant = escrow.get(incoming.delivery_id)
	var exact_retry := false
	if previous != null:
		if not valid(previous, character, world_namespace) or previous.status != "settled":
			return {"ok": false, "code": "malformed_vitals_marker"}
		if int(previous.journal_revision) > int(incoming.journal_revision):
			return {"ok": false, "code": "stale_vitals"}
		if int(previous.journal_revision) == int(incoming.journal_revision):
			var expected: Dictionary = incoming.duplicate(true)
			expected.status = "settled"
			if not equivalent(previous, expected):
				return {"ok": false, "code": "conflicting_vitals"}
			# Exact retries still perform a real portable bool write. An in-memory
			# marker is never evidence that a previous disk write succeeded.
			exact_retry = true
	var owned: RefCounted = null
	var live_party: Variant = player.get("party")
	if not live_party is Object or not live_party.has_method("members"):
		return {"ok": false, "code": "missing_live_party"}
	var members: Variant = live_party.call("members")
	if not members is Array:
		return {"ok": false, "code": "invalid_live_party"}
	for creature: Variant in members:
		if not creature is RefCounted or not creature.get("uid") is String:
			return {"ok": false, "code": "invalid_live_party"}
		if str(creature.get("uid")) == incoming.creature_uid:
			owned = creature
	if owned == null or float(owned.get("max_hp")) != float(incoming.max_hp):
		return {"ok": false, "code": "unowned_or_changed_maximum"}
	var current_hp := float(owned.get("hp"))
	var current_fainted := bool(owned.get("fainted"))
	if current_fainted and not bool(incoming.fainted):
		return {"ok": false, "code": "revival_requires_distinct_authority"}
	var matches_before: bool = current_hp == float(incoming.expected_hp) \
		and current_fainted == bool(incoming.expected_fainted)
	var matches_after: bool = current_hp == float(incoming.hp) and current_fainted == bool(incoming.fainted)
	var matches_intermediate := previous is Dictionary \
		and int(previous.journal_revision) < int(incoming.journal_revision) \
		and float(previous.max_hp) == float(incoming.max_hp) \
		and current_hp == float(previous.hp) and current_fainted == bool(previous.fainted)
	var retry: Dictionary = session.call("_owner_vitals_retry_receipt", player, world, incoming.creature_uid)
	var matches_unsaved: bool = valid(retry, character, world_namespace) \
		and retry.world_id == incoming.world_id and retry.delivery_id == incoming.delivery_id \
		and equivalent(retry.max_hp, incoming.max_hp) \
		and equivalent(retry.expected_hp, incoming.expected_hp) and retry.expected_fainted == incoming.expected_fainted \
		and int(retry.journal_revision) < int(incoming.journal_revision) \
		and int(retry.character_revision) < int(incoming.character_revision) \
		and equivalent(current_hp, retry.hp) and current_fainted == retry.fainted
	if not matches_before and not matches_after and not matches_intermediate and not matches_unsaved:
		return {"ok": false, "code": "stale_personal_vitals"}
	if exact_retry and not matches_after:
		return {"ok": false, "code": "newer_live_vitals"}
	if not bool(session.call("_retain_owner_vitals_retry", player, world, incoming)):
		return {"ok": false, "code": "owner_retry_limit"}
	if exact_retry:
		# An older marker must not ACK over a later live accepted hit. Matching
		# retries still perform a real bool write; equality is not durability.
		return _save_owner(game, character, incoming, true)
	var before_escrow: Dictionary = escrow.duplicate(true)
	if session.has_method("_owner_passive_actor_vitals_record") \
		and session.call("_owner_passive_actor_vitals_record", incoming, false) != true:
		return {"ok": false, "code": "owner_passive_vitals_input_pending", "pending": true}
	if not current_fainted and incoming.fainted:
		var condition: Script = preload("res://scripts/creatures/creature_condition.gd")
		condition.call("note_faint", owned, condition.call("config"))
	owned.set("hp", float(incoming.hp))
	owned.set("fainted", bool(incoming.fainted))
	var marker: Dictionary = incoming.duplicate(true)
	marker.status = "settled"
	escrow[incoming.delivery_id] = marker
	var saved := _save_owner(game, character, incoming, false)
	if not bool(saved.get("ok", false)):
		player.set("satchel_escrow", before_escrow)
		# Never resurrect accepted battle HP from the old portable snapshot.
		# Matching next attempt still writes the real marker/document to disk.
		saved["pending"] = true
		saved["delivery_id"] = incoming.delivery_id
		saved["journal_revision"] = incoming.journal_revision
	return saved


static func _save_owner(game: Node, character: String, row: Dictionary, duplicate: bool) -> Dictionary:
	var saver: RefCounted = game.get("save_system")
	if saver == null or not bool(saver.call("save_character_prepared", game, character)):
		return {"ok": false, "code": "owner_save_failed"}
	var session: Node = game.get("session")
	if session.has_method("_owner_passive_actor_vitals_record") \
		and session.call("_owner_passive_actor_vitals_record", row, true) != true:
		return {"ok": false, "code": "owner_passive_vitals_saved_input_pending", "saved": true, "pending": true}
	game.get("session").call("_clear_owner_vitals_retry", game.get("local"), game.get("world"), row)
	return {"ok": true, "duplicate": duplicate, "creature_uid": row.creature_uid,
		"character_revision": row.character_revision, "journal_revision": row.journal_revision,
		"receipt": row.receipt.duplicate(true)}


static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum


## JSON numbers preserve mathematical identity across int/float decoding.
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
