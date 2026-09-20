extends "res://tests/test_case.gd"

const SNAPSHOT_TRANSFER := preload("res://scripts/net/snapshot_transfer.gd")


func test_snapshot_larger_than_steam_packet_limit_round_trips_out_of_order() -> void:
	var snapshot := {
		"realm": "meadows",
		"world_revision": 417,
		"large_state": "tetherbound".repeat(60_000),
		"nested": {"placed": [1, 2, 3], "flags": {"gate": true}},
	}
	var sender := SNAPSHOT_TRANSFER.new()
	var encoded: Dictionary = sender.encode_snapshot(snapshot, 73)
	assert_true(bool(encoded.get("ok")))
	assert_true(int(encoded.descriptor.total_bytes) > 512 * 1024)
	assert_true(int(encoded.descriptor.chunk_count) > 1)

	var receiver := SNAPSHOT_TRANSFER.new()
	assert_true(receiver.begin(encoded.descriptor))
	var chunks: Array = encoded.chunks
	for index in range(chunks.size() - 1, -1, -1):
		assert_true(receiver.accept_chunk(73, index, chunks[index]))
	assert_true(receiver.is_ready())
	assert_eq(receiver.snapshot(), snapshot)


func test_missing_chunk_and_identical_duplicate_never_complete_early() -> void:
	var transfer := SNAPSHOT_TRANSFER.new(64, 4096)
	var encoded: Dictionary = transfer.encode_snapshot({"payload": "x".repeat(300)}, 4)
	assert_true(bool(encoded.ok))
	assert_true(transfer.begin(encoded.descriptor))
	var chunks: Array = encoded.chunks
	assert_true(transfer.accept_chunk(4, 0, chunks[0]))
	assert_true(transfer.accept_chunk(4, 0, chunks[0]), "identical duplicate is idempotent")
	for index in range(2, chunks.size()):
		assert_true(transfer.accept_chunk(4, index, chunks[index]))
	assert_false(transfer.is_ready(), "missing chunk must not expose a snapshot")
	assert_eq(transfer.snapshot(), {})
	assert_true(transfer.accept_chunk(4, 1, chunks[1]))
	assert_true(transfer.is_ready())


func test_invalid_chunks_are_rejected_without_replacing_accepted_data() -> void:
	var transfer := SNAPSHOT_TRANSFER.new(64, 4096)
	var encoded: Dictionary = transfer.encode_snapshot({"payload": "y".repeat(180)}, 9)
	assert_true(transfer.begin(encoded.descriptor))
	var chunks: Array = encoded.chunks
	assert_false(transfer.accept_chunk(10, 0, chunks[0]), "wrong transfer id")
	assert_false(transfer.accept_chunk(9, chunks.size(), chunks[0]), "invalid index")
	assert_false(transfer.accept_chunk(9, 0, chunks[0].slice(0, chunks[0].size() - 1)),
		"invalid size")
	assert_true(transfer.accept_chunk(9, 0, chunks[0]))
	var conflicting: PackedByteArray = chunks[0].duplicate()
	conflicting[0] = conflicting[0] ^ 0xff
	assert_false(transfer.accept_chunk(9, 0, conflicting), "differing duplicate")
	for index in range(1, chunks.size()):
		assert_true(transfer.accept_chunk(9, index, chunks[index]))
	assert_true(transfer.is_ready(), "only the originally accepted valid bytes are assembled")
	assert_eq(transfer.snapshot(), {"payload": "y".repeat(180)})


func test_corrupt_complete_payload_never_becomes_ready() -> void:
	var transfer := SNAPSHOT_TRANSFER.new(64, 4096)
	var encoded: Dictionary = transfer.encode_snapshot({"payload": "z".repeat(180)}, 12)
	assert_true(transfer.begin(encoded.descriptor))
	var chunks: Array = encoded.chunks
	var corrupt: PackedByteArray = chunks[0].duplicate()
	corrupt[0] = corrupt[0] ^ 0xff
	assert_true(transfer.accept_chunk(12, 0, corrupt))
	for index in range(1, chunks.size()):
		var accepted := transfer.accept_chunk(12, index, chunks[index])
		if index < chunks.size() - 1:
			assert_true(accepted)
	assert_false(transfer.is_ready())
	assert_eq(transfer.snapshot(), {})
	assert_false(transfer.last_error().is_empty(), "hash failure must be explicit")


func test_valid_variant_bytes_that_are_not_a_dictionary_are_rejected() -> void:
	var transfer := SNAPSHOT_TRANSFER.new(64, 4096)
	var bytes := var_to_bytes(["not", "a", "world", "snapshot"])
	var descriptor := {
		"version": SNAPSHOT_TRANSFER.VERSION,
		"transfer_id": 18,
		"total_bytes": bytes.size(),
		"chunk_count": ceili(float(bytes.size()) / 64.0),
		"sha256": transfer._sha256(bytes),
	}
	assert_true(transfer.begin(descriptor))
	for index in int(descriptor.chunk_count):
		var start := index * 64
		transfer.accept_chunk(18, index, bytes.slice(start, mini(start + 64, bytes.size())))
	assert_false(transfer.is_ready())
	assert_eq(transfer.snapshot(), {})
	assert_false(transfer.last_error().is_empty())


func test_descriptor_limits_and_reset_release_partial_state() -> void:
	var transfer := SNAPSHOT_TRANSFER.new(64, 256)
	var too_large: Dictionary = transfer.encode_snapshot({"payload": "q".repeat(1024)}, 1)
	assert_false(bool(too_large.ok), "oversized snapshots fail instead of truncating")
	assert_false(str(too_large.error).is_empty())

	var encoded: Dictionary = transfer.encode_snapshot({"payload": "ok".repeat(40)}, 2)
	assert_true(bool(encoded.ok))
	var malformed: Dictionary = encoded.descriptor.duplicate(true)
	malformed["chunk_count"] = int(malformed["chunk_count"]) + 1
	assert_false(transfer.begin(malformed))
	assert_false(transfer.is_ready())
	assert_true(transfer.begin(encoded.descriptor))
	assert_true(transfer.accept_chunk(2, 0, encoded.chunks[0]))
	assert_true(transfer.received_bytes() > 0)
	transfer.reset()
	assert_eq(transfer.received_bytes(), 0)
	assert_false(transfer.is_ready())
	assert_eq(transfer.snapshot(), {})
	assert_false(transfer.accept_chunk(2, 1, encoded.chunks[1]),
		"reset transfer cannot accept an old chunk")
