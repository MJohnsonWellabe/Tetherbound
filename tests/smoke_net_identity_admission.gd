extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Focused real-RPC admission proof. The second process first claims the host's
## live portable character id, then joins legally with its own id. The refusal
## must arrive as a readable reason before the disconnect; the rejected socket
## must never mutate the registry, receive a world snapshot, or alter host world
## state. This uses the existing ENet/process harness and shipping Session RPCs.


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	var hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	var port := int(hello.get("enet_port", 0))
	check(port > 0, "host reported an ENet port (%d)" % port)
	if port <= 0:
		quit(await finish())
		return

	# First use a one-peer admitted cap. ENet still keeps one unadmitted
	# handshake seat, so the client receives `session_full` instead of a generic
	# transport refusal; registry/world/snapshot invariants are the same as the
	# identity-conflict case below.
	var hosted: Dictionary = await step(0, "host", {"port": port, "max_peers": 1})
	check(str(hosted.get("verdict", "")) == "PASS", "host opened the session (%s)"
		% str(hosted.get("detail", "")))
	var before_session: Dictionary = await probe(0, "session") as Dictionary
	var before_rows: Array = before_session.get("rows", []) as Array
	check(before_rows.size() == 1, "host registry starts with one real row (%s)" % str(before_rows))
	if before_rows.size() != 1:
		quit(await finish())
		return
	var host_character := str((before_rows[0] as Dictionary).get("character_id", ""))
	check(not host_character.is_empty(), "host has a stable nonempty character id")
	var before_world: Variant = await probe(0, "state_hash")
	var full: Dictionary = await step(1, "join", {
		"host": "127.0.0.1",
		"port": port,
		"character": {"character_id": "full-smoke-guest", "display_name": "Full Guest"},
		"budget_frames": 600,
	}, 1200)
	check(str(full.get("verdict", "")) == "FAIL",
		"full admitted session refused the overflow handshake (%s)" % str(full.get("detail", "")))
	check(str(full.get("detail", "")).contains("This session is full (1/1)."),
		"overflow client received the readable full-session reason (%s)" % str(full))
	var full_client: Dictionary = await probe(1, "session") as Dictionary
	check(bool(full_client.get("handshake_rejected_by_host", false)),
		"full-session refusal arrived as a host admission verdict")
	check(not bool(full_client.get("handshake_snapshot_applied", true)),
		"full-session client never applied a host snapshot")
	var after_full_session: Dictionary = await probe(0, "session") as Dictionary
	check(after_full_session.get("rows", []) == before_rows,
		"full-session refusal left the complete registry at one host")
	check((await probe(0, "state_hash")) == before_world,
		"full-session refusal left the host world state unchanged")

	var closed: Dictionary = await step(0, "leave", {"reason": "resize_admission_smoke"})
	check(str(closed.get("verdict", "")) == "PASS", "one-peer host closed cleanly before rehost")
	hosted = await step(0, "host", {"port": port, "max_peers": 4})
	check(str(hosted.get("verdict", "")) == "PASS", "host reopened at the production four-peer cap")
	before_session = await probe(0, "session") as Dictionary
	before_rows = before_session.get("rows", []) as Array
	host_character = str((before_rows[0] as Dictionary).get("character_id", ""))
	before_world = await probe(0, "state_hash")

	var rejected: Dictionary = await step(1, "join", {
		"host": "127.0.0.1",
		"port": port,
		"character": {"character_id": host_character, "display_name": "Impostor"},
		"budget_frames": 600,
	}, 1200)
	check(str(rejected.get("verdict", "")) == "FAIL",
		"live host identity was refused (%s)" % str(rejected.get("detail", "")))
	check(str(rejected.get("detail", "")).contains(
		"That character is already connected to this world."),
		"client received the readable identity-conflict reason (%s)" % str(rejected))
	var rejected_client: Dictionary = await probe(1, "session") as Dictionary
	check(bool(rejected_client.get("handshake_failed", false)),
		"client recorded a terminal handshake failure")
	check(bool(rejected_client.get("handshake_rejected_by_host", false)),
		"client distinguishes host refusal from a retryable transport failure")
	check(not bool(rejected_client.get("handshake_snapshot_applied", true)),
		"rejected client never applied a host snapshot")
	check(not bool(rejected_client.get("active", true)),
		"rejected transport was closed after the reason arrived")

	var after_reject_session: Dictionary = await probe(0, "session") as Dictionary
	check(after_reject_session.get("rows", []) == before_rows,
		"identity refusal left the complete host registry unchanged")
	check((await probe(0, "state_hash")) == before_world,
		"identity refusal left the host world state unchanged")

	var legal: Dictionary = await step(1, "join", {
		"host": "127.0.0.1",
		"port": port,
		"character": {"character_id": "identity-smoke-guest", "display_name": "Guest"},
	})
	check(str(legal.get("verdict", "")) == "PASS",
		"same transport process can join with a free stable identity (%s)"
			% str(legal.get("detail", "")))
	var admitted: Dictionary = await probe(0, "session") as Dictionary
	check(int(admitted.get("peer_count", 0)) == 2,
		"host registry has exactly host plus admitted guest")
	check(_character_ids(admitted.get("rows", []) as Array).has("identity-smoke-guest"),
		"legal guest identity is registered")

	quit(await finish())


func _character_ids(rows: Array) -> Array:
	var out: Array = []
	for raw: Variant in rows:
		if raw is Dictionary:
			out.append(str((raw as Dictionary).get("character_id", "")))
	return out
