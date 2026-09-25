extends "res://tests/helpers/net_harness.gd"

# peers: 3

## X05 / MULTIPLAYER §1.1 and §5: the 120 s reconnect reservation, on three
## real processes and the shipping Session RPCs. The host opens two seats.
## Guest A joins and its link drops (`drop_link`, a raw transport close, so no
## goodbye). Guest B is then refused with the held-seat reason. A rejoins
## with the same character under a new transport peer and takes its seat. A
## then leaves deliberately, which frees the seat at once, and B gets in.
## The lapse of the window at 120 s is covered by
## tests/test_session_reconnect_reservation.gd with an explicit clock.

const A_CHAR := "reservation-smoke-a"
const B_CHAR := "reservation-smoke-b"


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(3, "world"):
		quit(await finish())
		return
	var hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	var port := int(hello.get("enet_port", 0))
	check(port > 0, "host reported an ENet port (%d)" % port)
	if port <= 0:
		quit(await finish())
		return

	var hosted: Dictionary = await step(0, "host", {"port": port, "max_peers": 2})
	check(str(hosted.get("verdict", "")) == "PASS", "host opened two seats (%s)"
		% str(hosted.get("detail", "")))
	var a_in: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port,
		"character": {"character_id": A_CHAR, "display_name": "Guest A"}})
	check(str(a_in.get("verdict", "")) == "PASS", "guest A joined (%s)" % str(a_in.get("detail", "")))
	var a_peer_before := int(((await probe(1, "session")) as Dictionary).get("peer_id", 0))

	var dropped: Dictionary = await step(1, "drop_link", {"settle_frames": 60})
	check(str(dropped.get("verdict", "")) == "PASS", "guest A's link dropped (%s)"
		% str(dropped.get("detail", "")))
	var back_to_one: Dictionary = await step(0, "expect_peers", {"count": 1}, 900)
	check(str(back_to_one.get("verdict", "")) == "PASS", "host noticed the drop (%s)"
		% str(back_to_one.get("detail", "")))
	var before_world: Variant = await probe(0, "state_hash")

	var started_ms := Time.get_ticks_msec()
	var b_refused: Dictionary = await step(2, "join", {"host": "127.0.0.1", "port": port,
		"character": {"character_id": B_CHAR, "display_name": "Guest B"}, "budget_frames": 900}, 1500)
	var refused_ms := Time.get_ticks_msec() - started_ms
	var b_detail := str(b_refused.get("detail", ""))
	check(str(b_refused.get("verdict", "")) == "FAIL", "guest B was refused while A's seat is held (%s)" % b_detail)
	check(b_detail.contains("A seat is being held for a player who is reconnecting"),
		"guest B heard the held-seat reason (%s)" % b_detail)
	check(refused_ms < 15_000, "the held-seat refusal arrived in %d ms" % refused_ms)
	var b_client: Dictionary = await probe(2, "session") as Dictionary
	check(bool(b_client.get("handshake_rejected_by_host", false)) \
			and not bool(b_client.get("handshake_snapshot_applied", true)),
		"guest B got a host verdict and no snapshot")
	var host_rows: Array = ((await probe(0, "session")) as Dictionary).get("rows", []) as Array
	check(host_rows.size() == 1, "the refusal left the host registry at one row (%s)" % str(host_rows))
	check((await probe(0, "state_hash")) == before_world, "the refusal left the host world unchanged")

	var a_back: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port,
		"character": {"character_id": A_CHAR, "display_name": "Guest A"}})
	check(str(a_back.get("verdict", "")) == "PASS", "guest A reclaimed its held seat (%s)"
		% str(a_back.get("detail", "")))
	var a_session: Dictionary = await probe(1, "session") as Dictionary
	check(int(a_session.get("peer_id", 0)) != a_peer_before,
		"the returning character arrived on a new transport peer")
	var both: Dictionary = await step(0, "expect_peers", {"count": 2}, 900)
	check(str(both.get("verdict", "")) == "PASS", "host counts host plus A again")

	var a_left: Dictionary = await step(1, "leave", {"reason": "done_for_now"})
	check(str(a_left.get("verdict", "")) == "PASS", "guest A left deliberately")
	var one_again: Dictionary = await step(0, "expect_peers", {"count": 1}, 900)
	check(str(one_again.get("verdict", "")) == "PASS", "host noticed A leave")
	var b_in: Dictionary = await step(2, "join", {"host": "127.0.0.1", "port": port,
		"character": {"character_id": B_CHAR, "display_name": "Guest B"}})
	check(str(b_in.get("verdict", "")) == "PASS",
		"a deliberate leave holds no seat, so guest B joined at once (%s)" % str(b_in.get("detail", "")))
	var rows: Array = ((await probe(0, "session")) as Dictionary).get("rows", []) as Array
	var ids: Array = []
	for r: Variant in rows:
		ids.append(str((r as Dictionary).get("character_id", "")))
	check(ids.has(B_CHAR) and not ids.has(A_CHAR) and ids.size() == 2,
		"host registry is host plus B (%s)" % str(ids))

	quit(await finish())
