extends RefCounted

## Read only the real admitted stream. No admission, replay, save or ACK work.
const SYNC := preload("res://scripts/net/owner_passive_sync.gd")
const HASH := preload("res://scripts/net/research_passive_preparation.gd")

static func mounted(service: RefCounted, session: Node, game: Node) -> bool:
	return service != null and session != null and game != null and service.get_script() == SYNC \
		and game.get("session") == session and session.get("_owner_passive") == service \
		and service.call("owner") == session and service.call("_game") == game

static func integral(value: Variant) -> bool:
	if value is int: return value >= 0
	return value is float and is_finite(value) and value >= 0.0 \
		and value <= 9007199254740991.0 and floor(value) == value

static func live_host_scope(stream: Dictionary, world: RefCounted, epoch: Variant) -> bool:
	return world != null and stream.get("world_id") == world.get("world_id") \
		and stream.get("world_namespace") == world.get("reward_delivery_namespace") \
		and stream.get("epoch") == epoch and stream.get("departed", false) is bool \
		and stream.get("departed", false) == false and not stream.has("readmit")

static func observe(tree: SceneTree, character: String = "") -> Dictionary:
	var game: Node = tree.root.get_node_or_null(^"Game") if tree != null else null
	var session: Node = game.get("session") if game != null else null
	if session == null or session.call("is_active") != true: return {}
	var world: RefCounted = game.get("world")
	if world == null: return {}
	var service: RefCounted = session.get("_owner_passive")
	if not mounted(service, session, game): return {}
	if character.is_empty():
		if session.call("is_host") == true: return {}
		var local: Dictionary = service.get("local")
		var player: RefCounted = game.get("local")
		if player == null or local.get("character") != player.get("character_id"): return {}
		return {"character": local.get("character"), "id": local.get("id"), "base_hash": local.get("base_hash"),
			"peer": session.call("local_peer_id"), "epoch": session.call("_altar_current_epoch"),
			"world_id": world.get("world_id"), "world_namespace": world.get("reward_delivery_namespace"), "realm": game.get("current_realm"),
			"sequence": local.get("sequence", 0), "acked": local.get("acked", -1), "error": local.get("error", "missing"),
			"admission_pending": local.get("admission_pending", true), "hello_pending": local.get("hello_pending", true),
			"save_pending": not (service.get("pending") as Dictionary).is_empty(),
			"rebase_pending": not (local.get("rebase", {}) as Dictionary).is_empty(),
			"readmit_pending": not (service.get("held_readmit") as Dictionary).is_empty()}
	if session.call("is_host") != true: return {}
	var stream: Dictionary = (service.get("hosts") as Dictionary).get(character, {})
	var cursor: Dictionary = stream.get("cursor", {})
	if stream.get("character") != character or cursor.is_empty() \
		or not live_host_scope(stream, world, session.call("_altar_current_epoch")) \
		or not integral(stream.get("peer")) or stream.get("peer", 0) <= 0 \
		or session.call("_authority_character", int(stream.get("peer", 0))) != character: return {}
	return {"character": stream.character, "id": stream.get("id"), "base_hash": HASH.fingerprint(cursor.get("base", {})),
		"peer": stream.get("peer"), "epoch": stream.get("epoch"), "world_id": stream.get("world_id"), "world_namespace": stream.get("world_namespace"),
		"realm": cursor.get("realm"), "sequence": cursor.get("sequence", 0), "travel_valid": cursor.get("travel_valid", false),
		"error": stream.get("error", "missing"), "checkpoint_pending": not (stream.get("checkpoint", {}) as Dictionary).is_empty()}

static func binding(snapshot: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for field: String in ["character", "id", "base_hash", "peer", "epoch", "world_id", "world_namespace", "realm", "sequence"]:
		if not snapshot.has(field): return {}
		out[field] = snapshot[field]
	for field: String in ["peer", "sequence"]:
		if not integral(out[field]) or out[field] <= 0: return {}
	for field: String in ["character", "id", "base_hash", "epoch", "world_id", "world_namespace", "realm"]:
		if not out[field] is String or str(out[field]).is_empty(): return {}
	return out

static func ready(local: Dictionary, host: Dictionary, original: Dictionary) -> bool:
	if binding(original).is_empty() or binding(local).is_empty() or binding(host).is_empty() \
		or not integral(local.get("acked")): return false
	for field: String in ["character", "id", "base_hash", "peer", "epoch", "world_id", "world_namespace", "realm"]:
		if local.get(field) != original.get(field) or host.get(field) != original.get(field): return false
	for field: String in ["admission_pending", "hello_pending", "save_pending", "rebase_pending", "readmit_pending"]:
		if not local.get(field) is bool or local[field] != false: return false
	return local.get("error") == "" and host.get("error") == "" \
		and host.get("travel_valid") is bool and host.travel_valid == true \
		and host.get("checkpoint_pending") is bool and host.checkpoint_pending == false \
		and local.acked >= original.sequence and local.acked <= local.sequence \
		and host.sequence >= original.sequence

static func await_before_placement(harness: Object, guest: int = 1) -> bool:
	# At most 600 requested wait frames plus probe time, before the harness jumps
	# beyond the real host's initial-pose observation ring. Freeze once only.
	var original: Dictionary = {}
	for _poll in 40:
		var local: Variant = await harness.call("probe", guest, "owner_pose_prefix")
		if local is Dictionary:
			if original.is_empty(): original = binding(local)
			if not original.is_empty():
				var host: Variant = await harness.call("probe", 0, "owner_pose_prefix", {"character": original.character})
				if host is Dictionary and ready(local, host, original):
					harness.call("check", true, "guest original owner prefix ACK and actual host first-discovery pose confirmed before fixture travel")
					return true
		var waited: Dictionary = await harness.call("step", guest, "wait", {"frames": 15})
		if waited.get("verdict") != "PASS": break
	harness.call("check", false, "guest original owner prefix/host first-discovery pose not confirmed after 40 polls of 15 requested wait frames; fixture did not move it")
	return false
