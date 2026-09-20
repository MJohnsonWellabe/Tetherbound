extends "res://tests/test_case.gd"

const SESSION := preload("res://scripts/net/session.gd")
const SNAPSHOT_TRANSFER := preload("res://scripts/net/snapshot_transfer.gd")
const PEER_REGISTRY := preload("res://scripts/net/peer_registry.gd")


class GameStub extends Node:
	var events: Array = []
	var applied_snapshot: Dictionary = {}

	func apply_world_snapshot(snapshot: Dictionary) -> void:
		applied_snapshot = snapshot.duplicate(true)
		events.append("snapshot")


class LedgerRpcStub extends Node:
	var events: Array
	var applied: Array[Dictionary] = []

	func _init(shared_events: Array) -> void:
		events = shared_events
		name = "LedgerRpc"

	func apply_remote_delta(delta: Dictionary) -> void:
		applied.append(delta.duplicate(true))
		events.append("delta")


func test_begin_is_boundary_and_early_chunk_finalizes_snapshot_then_delta() -> void:
	var game := GameStub.new()
	var session := SESSION.new()
	var ledger := LedgerRpcStub.new(game.events)
	game.add_child(session)
	session.add_child(ledger)
	session.set("_mode", "client")
	var box: Dictionary = session.get("_box")
	box["snapshot"] = false

	var expected := {"day": 7, "payload": "world".repeat(50_000)}
	var encoded: Dictionary = SNAPSHOT_TRANSFER.new().encode_snapshot(expected, 44)
	var chunks: Array = encoded.chunks
	assert_true(chunks.size() > 1)
	assert_false(session.queue_bootstrap_delta({"seq": 1}),
		"ledger traffic before BEGIN keeps its ordinary application path")
	assert_true(session.call("_receive_snapshot_chunk", 44, 0, chunks[0], false),
		"chunk zero may cross its independent channel before BEGIN")
	assert_true(session.call("_receive_snapshot_begin", encoded.descriptor, false))

	var queued := {"seq": 2, "ops": [{"kind": "flag", "value": "original"}]}
	assert_true(session.queue_bootstrap_delta(queued))
	var queued_ops: Array = queued.get("ops", [])
	(queued_ops[0] as Dictionary)["value"] = "mutated-after-queue"
	var registry_a := PEER_REGISTRY.new()
	registry_a.add(1, "host", "Host")
	session.call("_rpc_registry", registry_a.save_data())
	var registry_b := PEER_REGISTRY.new()
	registry_b.add(1, "host", "Host")
	registry_b.add(21, "guest", "Latest Guest")
	session.call("_rpc_registry", registry_b.save_data())
	assert_eq(int(session.registry().call("size")), 0,
		"post-BEGIN registry is held until the baseline applies")

	for index in range(1, chunks.size()):
		assert_true(session.call("_receive_snapshot_chunk", 44, index, chunks[index], false))
	assert_true(session.snapshot_ready())
	assert_true(session.handshake_snapshot_applied())
	assert_eq(game.applied_snapshot, expected)
	assert_eq(game.events, ["snapshot", "delta"],
		"queued deltas replay only after the immutable baseline")
	var applied_ops: Array = ledger.applied[0].get("ops", [])
	assert_eq(str((applied_ops[0] as Dictionary).get("value", "")), "original",
		"the queue owns an immutable delta copy")
	assert_eq(int(session.registry().call("size")), 2,
		"only the latest post-BEGIN registry is installed")
	game.free()


func test_bootstrap_delta_overflow_fails_without_applying_entries() -> void:
	var game := GameStub.new()
	var session := SESSION.new()
	var ledger := LedgerRpcStub.new(game.events)
	game.add_child(session)
	session.add_child(ledger)
	session.set("_mode", "client")
	session.set("_config", {
		"snapshot_delta_queue_max_entries": 1,
		"snapshot_delta_queue_max_bytes": 1024,
	})
	var box: Dictionary = session.get("_box")
	box["snapshot"] = false
	session.set("_bootstrap_boundary", true)
	assert_true(session.queue_bootstrap_delta({"seq": 1}))
	assert_true(session.queue_bootstrap_delta({"seq": 2}),
		"overflowed delta remains consumed rather than falling through to apply")
	assert_true(session.handshake_failed())
	assert_false(session.handshake_snapshot_applied())
	assert_true(ledger.applied.is_empty())
	assert_true(game.applied_snapshot.is_empty())
	assert_false(session.handshake_failure_reason().is_empty())
	game.free()


func test_conflicting_early_chunk_fails_and_never_opens_readiness() -> void:
	var session := SESSION.new()
	session.set("_mode", "client")
	var box: Dictionary = session.get("_box")
	box["snapshot"] = false
	var first := PackedByteArray([1, 2, 3])
	assert_true(session.call("_receive_snapshot_chunk", 8, 0, first, false))
	assert_true(session.call("_receive_snapshot_chunk", 8, 0, first, false),
		"identical early duplicate is idempotent")
	assert_false(session.call("_receive_snapshot_chunk", 8, 0,
		PackedByteArray([1, 2, 4]), false))
	assert_true(session.handshake_failed())
	assert_false(session.handshake_snapshot_applied())
	session.free()


func test_unacknowledged_host_transfer_expires_and_runs_peer_cleanup_once() -> void:
	var session := SESSION.new()
	session.set("_mode", "host")
	var registry: RefCounted = session.registry()
	registry.call("add", 1, "host", "Host")
	registry.call("add", 22, "guest", "Guest")
	var sends: Dictionary = session.get("_snapshot_sends")
	sends[22] = {
		"transfer_id": 5,
		"chunks": [PackedByteArray([1])],
		"next_index": 0,
		"awaiting_index": 0,
		"deadline_ms": -1,
	}
	var left: Array[int] = []
	session.peer_left.connect(func(peer_id: int) -> void: left.append(peer_id))
	session.call("_expire_snapshot_sends")
	assert_false(sends.has(22))
	assert_false(bool(registry.call("has", 22)))
	assert_eq(left, [22], "timeout uses the admitted-peer cleanup edge")
	session.call("_on_peer_disconnected", 22)
	assert_eq(left, [22], "physical close cannot emit peer-left twice")
	session.free()
