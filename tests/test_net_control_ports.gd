extends "res://tests/test_case.gd"

const PORTS := preload("res://tests/helpers/net_control_ports.gd")


func test_os_ports_are_distinct_live_reservations_until_release() -> void:
	var first := PORTS.reserve(4)
	var second := PORTS.reserve(4)
	assert_true(first.ok)
	assert_true(second.ok)
	var seen: Dictionary = {}
	for allocation: Dictionary in [first, second]:
		for index in allocation.ports.size():
			var port := int(allocation.ports[index])
			assert_true(port > 0 and port <= 65535)
			assert_false(seen.has(port), "concurrent harness reservations never share a port")
			seen[port] = true
			assert_true(allocation.servers[index].is_listening())
			assert_eq(allocation.servers[index].get_local_port(), port)
	PORTS.release(first.servers)
	PORTS.release(second.servers)
	for server: TCPServer in first.servers + second.servers:
		assert_false(server.is_listening(), "teardown releases every reservation")


func test_occupied_exact_override_fails_without_fallback() -> void:
	var held := PORTS.reserve(1)
	assert_true(held.ok)
	var occupied := int(held.ports[0])
	# The old guessed-base mechanism would hit this same occupied-port error;
	# an explicit override must continue exposing it rather than silently retry.
	# One port keeps this an occupancy check even if listen(0) chose 65535.
	var refused := PORTS.reserve(1, occupied)
	assert_false(refused.ok)
	assert_true(str(refused.reason).contains("port %d for peer 0" % occupied))
	assert_true(refused.servers.is_empty())
	assert_true(refused.ports.is_empty())
	assert_true(held.servers[0].is_listening())
	PORTS.release(held.servers)


func test_assigned_listener_accepts_real_control_connection() -> void:
	var held := PORTS.reserve(1)
	assert_true(held.ok)
	var client := StreamPeerTCP.new()
	assert_eq(client.connect_to_host("127.0.0.1", int(held.ports[0])), OK)
	var server: TCPServer = held.servers[0]
	for frame in 120:
		client.poll()
		if server.is_connection_available():
			break
		await (Engine.get_main_loop() as SceneTree).process_frame
	assert_true(server.is_connection_available(), "child can reach the port passed in argv")
	var accepted := server.take_connection()
	assert_true(accepted != null)
	if accepted != null:
		accepted.disconnect_from_host()
	client.disconnect_from_host()
	PORTS.release(held.servers)
