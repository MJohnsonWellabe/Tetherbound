extends Node

## Station-scoped transaction door. The only remote character authority is
## Session's admitted registry; this service retains no party or entitlement.
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
const STATION_GROUP := &"move_loadout_station"
const STATION_META := &"move_loadout_station"
signal completed(edit_id: String, result: Dictionary)

class LoadoutRecord extends RefCounted:
	var uid: String = ""
	var known_moves: Array[String] = []
	var move_quick: String = ""
	var move_charged: String = ""
	var move_utility: String = ""
	var move_ultimate: String = ""
	var loadout_revision: int = 0
	var loadout_last_edit: Dictionary = {}

static func ensure(tree: SceneTree) -> Node:
	var existing := tree.root.get_node_or_null(^"LoadoutService")
	if existing != null: return existing
	var service: Node = (load("res://scripts/creatures/loadout_service.gd") as GDScript).new()
	service.name = "LoadoutService"
	tree.root.add_child(service)
	return service

## Called by an authored/registered station builder, never an RPC. Unknown
## shells refuse registration rather than inheriting the host's local realm.
static func register_station(station: Node3D, kind: String, radius: float) -> String:
	if station == null or not station.is_inside_tree() or not ["altar", "forward_camp"].has(kind) \
			or not is_finite(radius) or radius <= 0.0: return ""
	var realm := _realm_of_station(station)
	if realm.is_empty() or not station.global_position.is_finite(): return ""
	var at := station.global_position
	# Authored XZ identity remains stable when the actual bench's grounded Y
	# is reconciled after construction; reach still uses its live full pose.
	var key := "%s:%s:%s" % [realm, kind, ("%.3f:%.3f" % [at.x, at.z]).sha256_text().left(24)]
	for other: Node in station.get_tree().get_nodes_in_group(STATION_GROUP):
		if other != station and str((other.get_meta(STATION_META, {}) as Dictionary).get("key", "")) == key: return ""
	station.set_meta(STATION_META, {"key": key, "kind": kind, "realm": realm, "radius": radius})
	station.add_to_group(STATION_GROUP)
	ensure(station.get_tree())
	return key

static func _realm_of_station(station: Node) -> String:
	var node := station
	while node != null:
		for property: Dictionary in node.get_property_list():
			if str(property.name) == "shell_realm":
				var shell := str(node.get("shell_realm"))
				if not shell.is_empty(): return shell
		var script := node.get_script() as GDScript
		if script != null:
			var constants := script.get_script_constant_map()
			if constants.has("REALM_ID"): return str(constants.REALM_ID)
		if node == station.get_tree().current_scene:
			var game := station.get_node_or_null(^"/root/Game")
			return str(game.get("current_realm")) if game != null else ""
		node = node.get_parent()
	return ""

func station_available(key: String) -> bool:
	var station := _station(key)
	# A local display hint only. The host independently repeats the live
	# geometry/participation checks when committing the request.
	return station != null and bool(_checked_context(station, _local_context(station)).get("ok", false))

func submit(station_key: String, request: Dictionary) -> void:
	var session := _session()
	if session != null and bool(session.call("is_active")) and not bool(session.call("is_host")):
		rpc_id(1, "_rpc_edit", station_key, request)
		return
	completed.emit(str(request.get("edit_id", "")), _commit(_local_peer(), station_key, request))

@rpc("any_peer", "call_remote", "reliable")
func _rpc_edit(station_key: String, request: Dictionary) -> void:
	if not multiplayer.is_server(): return
	var peer := multiplayer.get_remote_sender_id()
	if peer <= 0: return
	var result := _commit(peer, station_key, request)
	rpc_id(peer, "_rpc_result", str(request.get("edit_id", "")), result)

@rpc("authority", "call_remote", "reliable")
func _rpc_result(edit_id: String, result: Dictionary) -> void:
	# Result application is a separate validated owner-save transaction. The
	# pending UI must not optimistically equip a remote host refusal.
	if bool(result.get("ok", false)) and not _apply_owner_result(result):
		result = {"ok": false, "reason": "owner_save_failed", "host_committed": true}
	completed.emit(edit_id, result)

func _station(key: String) -> Node3D:
	if key.is_empty() or key.length() > 96: return null
	for candidate: Node in get_tree().get_nodes_in_group(STATION_GROUP):
		if candidate is Node3D and not candidate.is_queued_for_deletion() \
				and str((candidate.get_meta(STATION_META, {}) as Dictionary).get("key", "")) == key:
			return candidate as Node3D
	return null

func _context(peer: int, station: Node3D) -> Dictionary:
	var spec: Dictionary = station.get_meta(STATION_META, {})
	var session := _session()
	var state: Dictionary = {}
	if session != null and bool(session.call("is_active")):
		# The admission owner supplies actual host-held trainer position and
		# EncounterHost participation. Absence is an explicit fail-closed seam.
		if not session.has_method("host_station_context"): return {"ok": false}
		state = session.call("host_station_context", peer, str(spec.get("realm", "")))
	else:
		state = _local_context(station)
	return _checked_context(station, state)

func _local_context(station: Node3D) -> Dictionary:
	var game := get_node_or_null(^"/root/Game")
	var world := get_tree().current_scene
	var spec: Dictionary = station.get_meta(STATION_META, {})
	if game == null or world == null or str(game.get("current_realm")) != str(spec.get("realm", "")): return {"ok": false}
	var player := world.get_node_or_null(^"Player") as Node3D
	var fight := world.get_node_or_null(^"CombatManager")
	if player == null or fight == null or not fight.has_method("is_fighting"): return {"ok": false}
	return {"ok": true, "position": player.global_position, "in_combat": bool(fight.call("is_fighting"))}

func _checked_context(station: Node3D, state: Dictionary) -> Dictionary:
	var spec: Dictionary = station.get_meta(STATION_META, {})
	var at: Variant = state.get("position")
	if not bool(state.get("ok", false)) or not at is Vector3 or not (at as Vector3).is_finite() \
			or bool(state.get("in_combat", true)): return {"ok": false}
	var radius := float(spec.get("radius", 0.0))
	if radius <= 0.0 or not is_finite(radius) or station.global_position.distance_to(at) > radius: return {"ok": false}
	return {"ok": true, "station_kind": str(spec.get("kind", "")), "within_reach": true, "in_combat": false}

func _commit(peer: int, key: String, request: Dictionary) -> Dictionary:
	var station := _station(key)
	if station == null: return {"ok": false, "reason": "station_missing"}
	var context := _context(peer, station)
	if not bool(context.get("ok", false)): return {"ok": false, "reason": "station_unavailable"}
	var session := _session()
	if session != null and bool(session.call("is_active")):
		return _commit_admitted(session, peer, context, request)
	var game := get_node_or_null(^"/root/Game")
	if game == null or not bool(game.call("is_host")): return {"ok": false, "reason": "not_authority"}
	var party: RefCounted = game.get("party")
	if party == null or int(party.call("size")) > 5: return {"ok": false, "reason": "invalid_party"}
	var player: RefCounted = game.get("local")
	if player == null: return {"ok": false, "reason": "missing_character"}
	var personal: Dictionary = player.call("save_data")
	if not TEACHING.admitted_party_errors(personal.get("party"), personal.get("redesign_character", {})).is_empty():
		return {"ok": false, "reason": "invalid_party"}
	var creature: RefCounted = null
	var owned: Array[String] = []
	for member: RefCounted in party.call("members"):
		owned.append(str(member.get("uid")))
		if str(member.get("uid")) == str(request.get("creature_uid", "")): creature = member
	context["owned_creature_uids"] = owned
	var staged := TEACHING.stage_loadout_edit(creature, request, context, MOVES.load_default())
	if not bool(staged.get("ok", false)) or bool(staged.get("replayed", false)): return staged
	var previous := _loadout_state(creature)
	_apply_loadout(creature, staged.loadout, int(staged.revision), staged.receipt)
	if not bool(game.call("autosave_here")):
		_apply_loadout(creature, previous.loadout, int(previous.revision), previous.receipt)
		return {"ok": false, "reason": "save_failed"}
	return {"ok": true, "creature_uid": str(creature.get("uid")), "loadout": staged.loadout,
		"revision": staged.revision, "receipt": staged.receipt}

func _commit_admitted(session: Node, peer: int, context: Dictionary, request: Dictionary) -> Dictionary:
	for method: String in ["admitted_character_state", "admitted_character_revision", "host_commit_creature_loadout"]:
		if not session.has_method(method): return {"ok": false, "reason": "admission_unavailable"}
	var personal: Dictionary = session.call("admitted_character_state", peer)
	if not TEACHING.admitted_party_errors(personal.get("party"), personal.get("redesign_character", {})).is_empty():
		return {"ok": false, "reason": "invalid_admission"}
	var owned: Array[String] = []
	var selected: Dictionary = {}
	for row: Dictionary in personal.party:
		owned.append(str(row.get("uid", "")))
		if str(row.get("uid", "")) == str(request.get("creature_uid", "")): selected = row
	if selected.is_empty() or not selected.has("known_moves"): return {"ok": false, "reason": "canonical_loadout_unavailable"}
	var record := LoadoutRecord.new()
	record.uid = str(selected.uid)
	for move: String in selected.known_moves: record.known_moves.append(move)
	for slot: String in ["quick", "charged", "utility", "ultimate"]: record.set("move_" + slot, selected["move_" + slot])
	record.loadout_revision = int(selected.loadout_revision)
	record.loadout_last_edit = selected.loadout_last_edit.duplicate(true)
	context["owned_creature_uids"] = owned
	var staged := TEACHING.stage_loadout_edit(record, request, context, MOVES.load_default())
	if not bool(staged.get("ok", false)): return staged
	# The precise registry CAS call is connected only after its single owner
	# pins persistence/rollback semantics. Never substitute a local registry.
	return {"ok": false, "reason": "station_cas_not_connected"}

## Detached import from the authority-only result RPC. This grants no known
## moves, mastery or signature change and cannot skip a loadout revision.
static func stage_owner_loadout(creature: RefCounted, result: Dictionary) -> Dictionary:
	if creature == null or not result.get("creature_uid") is String \
			or str(result.creature_uid) != str(creature.get("uid")): return {"ok": false}
	var revision: Variant = result.get("revision")
	if not (revision is int or revision is float) or not is_finite(float(revision)) \
			or float(revision) < 1.0 or floor(float(revision)) != float(revision): return {"ok": false}
	var slots: Variant = result.get("loadout")
	var receipt: Variant = result.get("receipt")
	if not slots is Dictionary or slots.size() != 4 or not receipt is Dictionary or receipt.size() != 6: return {"ok": false}
	for slot: String in ["quick", "charged", "utility", "ultimate"]:
		if not slots.get(slot) is String: return {"ok": false}
	if str(slots.ultimate) != str(creature.get("move_ultimate")): return {"ok": false}
	for field: String in ["edit_id", "creature_uid", "quick", "charged", "utility"]:
		if not receipt.get(field) is String: return {"ok": false}
	if str(receipt.edit_id).is_empty() or str(receipt.edit_id).length() > 64 \
			or str(receipt.creature_uid) != str(creature.get("uid")): return {"ok": false}
	var expected: Variant = receipt.get("expected_revision")
	if not (expected is int or expected is float) or not is_finite(float(expected)) \
			or floor(float(expected)) != float(expected) or int(expected) != int(revision) - 1: return {"ok": false}
	var current := _loadout_state(creature)
	for slot: String in ["quick", "charged", "utility"]:
		if receipt[slot] != slots[slot]: return {"ok": false}
	if int(revision) == int(current.revision):
		return {"ok": slots == current.loadout and TEACHING._same_edit_receipt(receipt, current.receipt), "replayed": true}
	if int(revision) != int(current.revision) + 1: return {"ok": false}
	var known: Array = creature.get("known_moves")
	var moves := MOVES.load_default()
	for slot: String in ["quick", "charged", "utility"]:
		var move := str(slots[slot])
		if slot == "utility" and move.is_empty(): continue
		if not known.has(move) or not bool(moves.call("has", move)) or str(moves.call("slot", move)) != slot: return {"ok": false}
	return {"ok": true, "replayed": false, "loadout": slots.duplicate(true),
		"revision": int(revision), "receipt": receipt.duplicate(true)}

func _apply_owner_result(result: Dictionary) -> bool:
	var game := get_node_or_null(^"/root/Game")
	var session := _session()
	if game == null or session == null or not session.has_method("client_character_save_ready") \
			or not bool(session.call("client_character_save_ready")): return false
	var player: RefCounted = game.get("local")
	var saver: RefCounted = game.get("save_system")
	if player == null or saver == null: return false
	var personal: Dictionary = player.call("save_data")
	if not TEACHING.admitted_party_errors(personal.get("party"), personal.get("redesign_character", {})).is_empty(): return false
	var creature: RefCounted = null
	var party: RefCounted = game.get("party")
	for owned: RefCounted in party.call("members"):
		if str(owned.get("uid")) == str(result.get("creature_uid", "")): creature = owned
	var staged := stage_owner_loadout(creature, result)
	if not bool(staged.get("ok", false)): return false
	if bool(staged.get("replayed", false)): return true
	var previous := _loadout_state(creature)
	_apply_loadout(creature, staged.loadout, int(staged.revision), staged.receipt)
	# The public production portable writer returns its atomic write outcome;
	# Game.autosave_here has a void guest route and cannot prove this commit.
	var character_id := str(player.get("character_id"))
	if character_id.is_empty() or not bool(saver.call("save_character", game, character_id)):
		_apply_loadout(creature, previous.loadout, int(previous.revision), previous.receipt)
		return false
	return true

static func _loadout_state(creature: RefCounted) -> Dictionary:
	var slots := {}
	for slot: String in ["quick", "charged", "utility", "ultimate"]: slots[slot] = str(creature.get("move_" + slot))
	return {"loadout": slots, "revision": int(creature.get("loadout_revision")),
		"receipt": (creature.get("loadout_last_edit") as Dictionary).duplicate(true)}

static func _apply_loadout(creature: RefCounted, slots: Dictionary, revision: int, receipt: Dictionary) -> void:
	for slot: String in ["quick", "charged", "utility", "ultimate"]: creature.set("move_" + slot, str(slots[slot]))
	creature.set("loadout_revision", revision)
	creature.set("loadout_last_edit", receipt.duplicate(true))

func _session() -> Node:
	var game := get_node_or_null(^"/root/Game")
	return game.get("session") as Node if game != null else null

func _local_peer() -> int:
	var session := _session()
	return int(session.call("local_peer_id")) if session != null else 1
