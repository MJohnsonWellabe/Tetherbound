extends "res://tests/test_case.gd"

const PREFIX := preload("res://tests/helpers/net_owner_pose_prefix.gd")
const SYNC := preload("res://scripts/net/owner_passive_sync.gd")

class MountedGame extends Node:
	var session: Node

class MountedSession extends Node:
	var game: Node
	var _owner_passive: RefCounted
	func _game() -> Node: return game

class World extends RefCounted:
	var world_id := "world-id"
	var reward_delivery_namespace := "world"

func _local() -> Dictionary:
	return {"character":"owner", "id":"stream", "base_hash":"base", "peer":2,
		"epoch":"epoch", "world_id":"world-id", "world_namespace":"world", "realm":"meadows", "sequence":5, "acked":5,
		"error":"", "admission_pending":false, "hello_pending":false, "save_pending":false, "rebase_pending":false, "readmit_pending":false}

func _host(local: Dictionary) -> Dictionary:
	var out: Dictionary = PREFIX.binding(local)
	out.merge({"travel_valid":true, "checkpoint_pending":false, "error":""})
	return out

func test_ack_alone_never_proves_the_original_initial_discovery_pose() -> void:
	var local := _local()
	var original: Dictionary = PREFIX.binding(local)
	var host := _host(local)
	assert_true(PREFIX.ready(local, host, original))
	host.travel_valid = false
	assert_false(PREFIX.ready(local, host, original))
	host.travel_valid = true
	host.sequence = 4
	assert_false(PREFIX.ready(local, host, original))
	host.sequence = 5
	local.acked = 4
	assert_false(PREFIX.ready(local, host, original))

func test_no_foreign_cursor_owner_world_epoch_or_rebase_can_acknowledge_the_frozen_prefix() -> void:
	var local := _local()
	var original: Dictionary = PREFIX.binding(local)
	for field: String in ["character", "id", "base_hash", "peer", "epoch", "world_id", "world_namespace", "realm"]:
		var host := _host(local)
		host[field] = 3 if field == "peer" else "foreign"
		assert_false(PREFIX.ready(local, host, original))
	for field: String in ["admission_pending", "hello_pending", "save_pending", "rebase_pending", "readmit_pending"]:
		var changed := local.duplicate(true)
		changed[field] = true
		assert_false(PREFIX.ready(changed, _host(local), original))
	var host := _host(local)
	host.error = "owner_passive_initial_pose_unconfirmed"
	assert_false(PREFIX.ready(local, host, original))
	host.error = ""
	host.checkpoint_pending = true
	assert_false(PREFIX.ready(local, host, original))

func test_later_live_care_inputs_do_not_require_a_permanently_empty_queue_or_reset_the_boundary() -> void:
	var local := _local()
	var original: Dictionary = PREFIX.binding(local)
	local.sequence = 8
	var host := _host(local)
	assert_true(PREFIX.ready(local, host, original))
	assert_eq(original.sequence, 5)
	assert_true(PREFIX.binding({}).is_empty())
	local.sequence = 0
	assert_true(PREFIX.binding(local).is_empty())
	for invalid: Variant in [true, "5", 5.5, -1]:
		local.sequence = invalid
		assert_true(PREFIX.binding(local).is_empty())

func test_malformed_counters_regressed_sequence_and_ack_beyond_local_are_refused() -> void:
	var original: Dictionary = PREFIX.binding(_local())
	for invalid: Variant in [true, "5", 5.5, -1, NAN, INF, 9007199254740992.0, null]:
		for field: String in ["acked", "sequence"]:
			var local := _local()
			local[field] = invalid
			assert_false(PREFIX.ready(local, _host(_local()), original))
		var host := _host(_local())
		host.sequence = invalid
		assert_false(PREFIX.ready(_local(), host, original))
		var changed := original.duplicate(true)
		changed.sequence = invalid
		assert_false(PREFIX.ready(_local(), _host(_local()), changed))
	var local := _local()
	local.sequence = 4
	assert_false(PREFIX.ready(local, _host(_local()), original))
	local.sequence = 5
	local.acked = 6
	assert_false(PREFIX.ready(local, _host(_local()), original))
	local.sequence = 8.0
	local.acked = 6.0
	assert_true(PREFIX.ready(local, _host(local), original))

func test_only_current_mounted_service_and_live_full_world_scope_are_observed() -> void:
	var game := MountedGame.new()
	var session := MountedSession.new()
	var foreign := MountedSession.new()
	session.game = game
	game.session = session
	var service: RefCounted = SYNC.new(session)
	session._owner_passive = service
	assert_true(PREFIX.mounted(service, session, game))
	session._owner_passive = SYNC.new(foreign)
	assert_false(PREFIX.mounted(session._owner_passive, session, game))
	session._owner_passive = service
	game.session = foreign
	assert_false(PREFIX.mounted(service, session, game))
	game.session = session
	session.game = foreign
	assert_false(PREFIX.mounted(service, session, game))
	var world := World.new()
	var stream := {"world_id":"world-id", "world_namespace":"world", "epoch":"epoch"}
	assert_true(PREFIX.live_host_scope(stream, world, "epoch"))
	for field: String in ["world_id", "world_namespace", "epoch"]:
		var changed := stream.duplicate(true)
		changed[field] = "foreign"
		assert_false(PREFIX.live_host_scope(changed, world, "epoch"))
	stream.departed = true
	assert_false(PREFIX.live_host_scope(stream, world, "epoch"))
	stream.departed = false
	stream.readmit = {}
	assert_false(PREFIX.live_host_scope(stream, world, "epoch"))
	game.free()
	session.free()
	foreign.free()
