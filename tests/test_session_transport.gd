extends "res://tests/test_case.gd"

const SESSION := preload("res://scripts/net/session.gd")


class SaveSystemSpy extends RefCounted:
	var save_character_calls := 0

	func save_character(_game: Object, _character_id: String) -> bool:
		save_character_calls += 1
		return true


class PlayerStub extends RefCounted:
	var character_id := "selected-character"


class GameStub extends Node:
	var save_system := SaveSystemSpy.new()
	var local := PlayerStub.new()


func test_disconnected_or_wrong_role_peers_are_refused_before_install() -> void:
	assert_false(SESSION.transport_peer_valid(null, true))
	assert_false(SESSION.transport_peer_valid(null, false))

	var unopened_enet := ENetMultiplayerPeer.new()
	assert_false(SESSION.transport_peer_valid(unopened_enet, true),
		"an unopened ENet peer is not a listen server")
	assert_false(SESSION.transport_peer_valid(unopened_enet, false),
		"an unopened ENet peer is not a connecting client")

	var offline := OfflineMultiplayerPeer.new()
	assert_true(SESSION.transport_peer_valid(offline, true),
		"a connected server-shaped MultiplayerPeer is accepted by the generic seam")
	assert_false(SESSION.transport_peer_valid(offline, false),
		"a server-shaped peer cannot be installed as a client")

	var session := SESSION.new()
	assert_false(session.call("host_with_peer", offline, 5, "test"),
		"the generic seam cannot expand the configured four-player session")
	assert_eq(session.get("_peer"), null,
		"invalid capacity is rejected before the peer is installed")
	session.free()


func test_enet_physical_timeout_routing_remains_transport_specific() -> void:
	assert_true(SESSION.transport_uses_enet_timeouts(ENetMultiplayerPeer.new()))
	assert_false(SESSION.transport_uses_enet_timeouts(OfflineMultiplayerPeer.new()),
		"an injected non-ENet peer never reaches ENet get_peer/set_timeout APIs")
	assert_true(SESSION.timeout_peer_is_physical(false, 1),
		"an ENet client configures only its physical server connection")
	assert_false(SESSION.timeout_peer_is_physical(false, 42),
		"an ENet client skips logical fellow-client ids")
	assert_true(SESSION.timeout_peer_is_physical(true, 42),
		"an ENet host configures each physical client")
	assert_false(SESSION.timeout_peer_is_physical(true, 1),
		"an ENet host never asks for itself as a physical peer")


func test_transport_closed_fires_after_peer_and_kind_are_cleared() -> void:
	var session := SESSION.new()
	var observed := {"count": 0, "peer": null, "kind": "not-called"}
	session.transport_closed.connect(func() -> void:
		observed["count"] = int(observed["count"]) + 1
		observed["peer"] = session.get("_peer")
		observed["kind"] = session.call("transport_kind")
	)
	session.set("_peer", OfflineMultiplayerPeer.new())
	session.set("_mode", "host")
	session.set("_transport_kind", "test")

	session.call("_teardown")

	assert_eq(int(observed["count"]), 1)
	assert_eq(observed["peer"], null,
		"the callback observes the peer after close and release")
	assert_eq(str(observed["kind"]), "",
		"the callback observes transport state after teardown")
	session.call("_teardown")
	assert_eq(int(observed["count"]), 1,
		"tearing down an already-closed session does not emit a false second edge")
	session.free()


func test_client_character_is_not_saveable_until_snapshot_admission() -> void:
	var session := SESSION.new()
	session.set("_mode", "client")
	var box: Dictionary = session.get("_box")
	box["handshake_snapshot_applied"] = false
	assert_false(session.call("client_character_save_ready"),
		"a refusal or disconnect before snapshot cannot overwrite the selected character")

	box["handshake_snapshot_applied"] = true
	assert_true(session.call("client_character_save_ready"),
		"an admitted client keeps the established save-on-leave behavior")

	session.set("_mode", "host")
	assert_false(session.call("client_character_save_ready"),
		"the predicate is specifically the client portable-save gate")
	session.free()


func test_failed_client_leave_does_not_call_the_character_store() -> void:
	var game := GameStub.new()
	var session := SESSION.new()
	game.add_child(session)
	session.set("_peer", OfflineMultiplayerPeer.new())
	session.set("_mode", "client")
	var box: Dictionary = session.get("_box")
	box["handshake_snapshot_applied"] = false

	session.call("leave", "refused")

	assert_eq(game.save_system.save_character_calls, 0,
		"a selected portable character remains untouched when admission never completed")
	game.free()


func test_world_first_preparation_closes_authority_snapshot_and_save_gates() -> void:
	var session := SESSION.new()
	assert_true(session.call("is_host"))
	assert_true(session.call("snapshot_ready"))
	assert_false(session.call("is_active"))

	assert_true(session.call("prepare_client_join"))
	assert_false(session.call("is_host"),
		"the locally loaded destination is never authoritative while waiting to dial")
	assert_false(session.call("snapshot_ready"),
		"gameplay remains behind the host snapshot gate")
	assert_false(session.call("is_active"),
		"preparation does not pretend a MultiplayerPeer exists or allow RPCs")
	assert_false(session.call("client_character_save_ready"))

	session.call("cancel_client_join_preparation")
	assert_true(session.call("is_host"))
	assert_true(session.call("snapshot_ready"))
	session.free()
