extends "res://tests/helpers/net_harness.gd"

# peers: 2

## X05 / MULTIPLAYER §1.1 step 5 and ACCEPTANCE §7 "version mismatch". Two real
## processes and the shipping Session RPCs. Peer 1 claims different game
## content through the debug-only `--net-content-fingerprint=` override in
## `scripts/net/build_fingerprint.gd`, so it looks like a friend on another
## build. The host must refuse it before the registry, realm preparation or
## snapshot, with a reason that names the content difference. The refusal must
## arrive well inside the generic handshake timeout, and the host's registry
## and world must be unchanged.

const MISMATCHED_CONTENT := "0000000000000000000000000000000000000000000000000000000000000bad"
## The join step's own frame budget is the generic timeout it would otherwise
## sit out. A specific refusal must come back far sooner.
const REFUSAL_WALL_MS := 15_000


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world", [],
			{1: ["--net-content-fingerprint=%s" % MISMATCHED_CONTENT]}):
		quit(await finish())
		return

	var hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	var port := int(hello.get("enet_port", 0))
	check(port > 0, "host reported an ENet port (%d)" % port)
	if port <= 0:
		quit(await finish())
		return

	var hosted: Dictionary = await step(0, "host", {"port": port, "max_peers": 4})
	check(str(hosted.get("verdict", "")) == "PASS", "host opened a four-peer session (%s)"
		% str(hosted.get("detail", "")))
	var before_session := _as_dict(await probe(0, "session"))
	var before_rows: Array = before_session.get("rows", []) as Array
	check(before_rows.size() == 1, "host registry starts with one real row (%s)" % str(before_rows))
	var before_world: Variant = await probe(0, "state_hash")

	var started_ms := Time.get_ticks_msec()
	var refused: Dictionary = await step(1, "join", {
		"host": "127.0.0.1",
		"port": port,
		"character": {"character_id": "mismatch-smoke-guest", "display_name": "Other Build"},
		"budget_frames": 1800,
	}, 2400)
	var elapsed_ms := Time.get_ticks_msec() - started_ms
	var detail := str(refused.get("detail", ""))
	check(str(refused.get("verdict", "")) == "FAIL",
		"mismatched content was refused (%s)" % detail)
	check(detail.contains("You and the host have different game content"),
		"client received the readable content-mismatch reason (%s)" % detail)
	check(detail.contains("yours 00000000"),
		"the reason names the joiner's own content hash prefix (%s)" % detail)
	check(elapsed_ms < REFUSAL_WALL_MS,
		"refusal arrived in %d ms, not after the generic timeout" % elapsed_ms)

	var client := _as_dict(await probe(1, "session"))
	check(bool(client.get("handshake_rejected_by_host", false)),
		"mismatch arrived as a host admission verdict, not a transport failure")
	check(not bool(client.get("handshake_snapshot_applied", true)),
		"mismatched client never applied a host snapshot")
	check(not bool(client.get("active", true)),
		"mismatched client's transport closed after the reason arrived")

	var after_session := _as_dict(await probe(0, "session"))
	check(after_session.get("rows", []) == before_rows,
		"mismatch refusal left the host registry unchanged")
	check((await probe(0, "state_hash")) == before_world,
		"mismatch refusal left the host world state unchanged")

	quit(await finish())


## A probe that failed returns its error text, not a Dictionary. Treat that as
## an empty answer so the checks fail and the run finishes, instead of a cast
## error stranding the coroutine until the runner's timeout.
func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}
