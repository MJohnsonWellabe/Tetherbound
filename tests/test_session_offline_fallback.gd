extends "res://tests/test_case.gd"

## Systems bar 1 (STATE known bug): offline-solo boss rewards when every port
## is taken. Host-authored durable rewards need an active session, so with the
## default port and the whole fallback span taken Session.host() opens a
## session of one on Godot's OfflineMultiplayerPeer: active host, no socket,
## nobody can join. An asked-for port keeps the old non-fatal refusal.

const RUNS_IN_INITIALIZED_TREE := true
const SESSION := preload("res://scripts/net/session.gd")
const BEACON := preload("res://scripts/mp/lan_beacon.gd")


func _occupy_span(session: Node) -> Array:
	var held: Array = []
	var first := int(session.call("default_port"))
	var beacon := int(BEACON.beacon_port_for(first))
	for port in range(first, first + int(session.call("_cfg", "port_fallback_span", 0)) + 1):
		if port == beacon: continue
		var blocker := ENetMultiplayerPeer.new()
		if blocker.create_server(port, 1) == OK: held.append(blocker)
	return held


func test_every_port_taken_hosts_an_offline_session_of_one() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var game := Node.new() # A plain parent: a second Game autoload would boot a world.
	game.name = "OfflineFallbackHost"
	var session := SESSION.new()
	game.add_child(session)
	tree.root.add_child(game)
	var held := _occupy_span(session)
	assert_false(held.is_empty(), "the test could take the span's ports")
	assert_false(bool(session.call("host", -1)), "no port was bound")
	assert_true(bool(session.call("is_active")), "solo still runs inside an active session")
	assert_true(bool(session.call("is_host")))
	assert_eq(str(session.call("transport_kind")), "offline")
	assert_eq(int(session.call("bound_port")), 0, "nothing to advertise or invite to")
	assert_eq(int(session.call("max_peers")) >= 1, true)
	session.call("_teardown") # The production leave would also save a world this fixture has no Game for.
	assert_false(bool(session.call("is_active")))
	var asked := SESSION.new()
	game.add_child(asked)
	assert_false(bool(asked.call("host", int(session.call("default_port")))), "an asked-for taken port still refuses")
	assert_false(bool(asked.call("is_active")), "and stays offline-solo, as before")
	for blocker: ENetMultiplayerPeer in held: blocker.close()
	game.get_parent().remove_child(game)
	game.free()
