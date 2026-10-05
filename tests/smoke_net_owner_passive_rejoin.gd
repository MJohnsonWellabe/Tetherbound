extends "res://tests/helpers/net_harness.gd"

# peers: 2 -- by hand (two Meadows builds), tools/net/run_net_smoke.sh owner_passive_rejoin

## Owner-passive admission survives a guest rejoin (MULTIPLAYER: co-op after
## any reconnect). Two real ENet peers in the production Meadows scene.
##
## The owner-passive stream carries a guest's care/travel inputs to the host
## and is what every passive-gated guest action (`owner_passive_sync.gd`
## `action_gate`/`gate`/`capture_gate`, e.g. an Altar spend) checkpoints
## against: the host must hold the guest's CURRENT stream and acknowledge it.
##
## 1. Join: the guest's stream is admitted (admission_pending false) and the
##    host holds exactly that stream id for the guest's character.
## 2. Leave + rejoin (plain `leave` then `join`): the guest arms a new stream;
##    the host must drop the departed one and admit the new one, acking it.
## 3. The rejoined guest walks: its recorded inputs are acknowledged by the
##    host under the new stream id (the passive path the gates rely on).
## 3b. Deliver-then-leave (coordinator 2026-10-05, F01 op10/op11): the guest
##    takes a world find (a host-journaled payout it applies and saves) while
##    its owner-passive send is held (fixture: "left before its inputs reached
##    the host"), leaves, and rejoins. The host rebuilds the payout from its own
##    accepted row and admits the stream; its held record has the find.
## 4. Offline change (coordinator 2026-10-05, F18 render 37365638014): the
##    guest leaves, its creature gains a level offline (fixture), and it
##    rejoins. The host re-admits its current portable record (first-join
##    rules, nothing owed), and a later find still pays on both sides.
## 5. NEGATIVE CONTROL: an invalid portable record (fixture: hp above max) is
##    refused at the rejoin hello with a reason, never adopted.

const PEER_SCRIPT := "res://tests/smoke_net_owner_passive_rejoin_peer.gd"
const BUILD_BUDGET := 20000
const ADMIT_FRAMES := 600

var _port := 0
var _guest_character := ""


func _initialize() -> void:
	# Building the Meadows world blocks a peer's heartbeat for minutes on the
	# 4-core container (smoke_net_cloudreach_veyra_reconnect.gd's reason).
	heartbeat_silence_tolerance_s = 420.0
	_run()


func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var exe := OS.get_executable_path()
	var args: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", PEER_SCRIPT, "--",
		"--role=%s" % role, "--peer=%d" % i,
		"--control-port=%d" % control_port, "--enet-port=%d" % enet_port,
		"--scene=%s" % scene, "TB_NET_RUN_ID=%s" % _run_id]
	for extra in extra_args:
		args.append(str(extra))
	OS.set_environment("XDG_DATA_HOME", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", "0")
	var parts: Array[String] = [_shq(exe)]
	for a in args:
		parts.append(_shq(str(a)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" % [" ".join(parts), _shq(log_path)]])


func _ok(result: Dictionary, label: String) -> bool:
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "%s -- %s" % [label, str(result.get("detail", ""))])
	return passed


func _state(peer: int) -> Dictionary:
	var value: Variant = await probe(peer, "op_state")
	return value if value is Dictionary else {}


## Wait until the guest's own stream is admitted and the host holds that same
## id for the guest's character, or the budget runs out. Returns the last pair.
func _await_admitted(label: String) -> Dictionary:
	var guest := {}
	var host := {}
	var waited := 0
	while waited <= ADMIT_FRAMES:
		guest = await _state(1)
		host = await _state(0)
		var mine: Dictionary = guest.get("local", {})
		var held: Dictionary = (host.get("hosts", {}) as Dictionary).get(_guest_character, {})
		if not bool(mine.get("admission_pending", true)) and str(held.get("id", "")) == str(mine.get("id", "x")):
			break
		await step(0, "wait", {"frames": 30})
		waited += 30
	print("OP %s guest=%s host_stream=%s" % [label, JSON.stringify(guest.get("local", {})),
		JSON.stringify((host.get("hosts", {}) as Dictionary).get(_guest_character, {}))])
	return {"guest": guest, "host": host}


func _admitted(pair: Dictionary) -> bool:
	var mine: Dictionary = (pair.guest as Dictionary).get("local", {})
	var held: Dictionary = ((pair.host as Dictionary).get("hosts", {}) as Dictionary).get(_guest_character, {})
	return bool(mine.get("armed", false)) and not bool(mine.get("admission_pending", true)) \
		and str(mine.get("error", "")).is_empty() and str(held.get("id", "")) == str(mine.get("id", "")) \
		and not bool(held.get("departed", false))


func _rejoin(label: String) -> bool:
	if not _ok(await step(1, "leave"), "%s: guest leaves" % label):
		return false
	_ok(await step(0, "expect_peers", {"count": 1}), "%s: host sees the guest gone" % label)
	if not _ok(await step(1, "join", {"host": "127.0.0.1", "port": _port}), "%s: guest rejoins" % label):
		return false
	for i in 2:
		_ok(await step(i, "expect_peers", {"count": 2}), "%s: peer %d sees both" % [label, i])
	return true


func _run() -> void:
	if not await launch(2, "title"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 3600.0 * 1000.0
	for i in 2:
		if not _ok(await step(i, "boot", {"scene": "world"}, BUILD_BUDGET), "SETUP: peer %d boots its own Meadows world" % i):
			quit(await finish())
			return
		await step(i, "dismiss_dialogue", {})
		_ok(await step(i, "party_grant", {"species": "terrapup", "level": 8}), "SETUP: peer %d owns a terrapup" % i)
	if not _ok(await step(0, "host"), "peer 0 hosts"):
		quit(await finish())
		return
	var session: Variant = await probe(0, "session")
	_port = int((session as Dictionary).get("enet_port", 0)) if session is Dictionary else 0
	if not _ok(await step(1, "join", {"host": "127.0.0.1", "port": _port}), "peer 1 joins"):
		quit(await finish())
		return
	for i in 2:
		_ok(await step(i, "expect_peers", {"count": 2}), "peer %d sees both" % i)
		await step(i, "dismiss_dialogue", {"settle": 10})
	_guest_character = str((await _state(1)).get("character_id", ""))
	check(not _guest_character.is_empty(), "the guest has a character id")

	# 1. First join.
	var first := await _await_admitted("first-join")
	check(_admitted(first), "first join: the guest's owner-passive stream is admitted by the host")
	var first_id := str(((first.guest as Dictionary).get("local", {}) as Dictionary).get("id", ""))

	# 2. Plain leave + rejoin.
	if not await _rejoin("rejoin"):
		quit(await finish())
		return
	var after := await _await_admitted("after-rejoin")
	var rejoined_id := str(((after.guest as Dictionary).get("local", {}) as Dictionary).get("id", ""))
	check(rejoined_id != first_id and not rejoined_id.is_empty(), "rejoin: the guest armed a new stream")
	check(_admitted(after), "rejoin: the host admitted the rejoined guest's NEW stream (not pending, same id)")

	# 3. Passive inputs after the rejoin are acknowledged under the new id.
	var before_walk: Dictionary = ((await _state(1)).get("local", {}) as Dictionary)
	await step(1, "stick", {"x": 0.0, "y": -1.0, "frames": 180})
	await step(1, "stick", {"x": 1.0, "y": 0.0, "frames": 120})
	var acked_ok := false
	var walked: Dictionary = {}
	for _i in 20:
		await step(0, "wait", {"frames": 30})
		walked = ((await _state(1)).get("local", {}) as Dictionary)
		# The walking owner records inputs continuously, so the newest few
		# are always in flight: the proof is that the host acknowledges
		# inputs recorded AFTER the rejoin under the new stream id.
		if int(walked.get("acked", 0)) > int(before_walk.get("sequence", 0)) \
				and str(walked.get("id", "")) == rejoined_id and str(walked.get("error", "")).is_empty():
			acked_ok = true
			break
	check(acked_ok, "rejoin: the walking guest's passive inputs are acknowledged by the host (%s -> %s)"
		% [JSON.stringify(before_walk), JSON.stringify(walked)])

	# 3b. Deliver-then-leave.
	var base_items: Dictionary = (await _state(1)).get("items", {})
	_ok(await step(1, "op_hold", {"hold": true}), "deliver-then-leave: FIXTURE the guest's owner-passive send is held")
	# Both peers stand the find, as both run the same world scene: the host's
	# own world says what it holds, so the guest's claim is a journaled payout.
	for i in 2:
		_ok(await step(i, "pickup_stand", {"id": "op_rejoin_find_a", "item": "berries", "realm": "meadows", "count": 3}),
			"deliver-then-leave: peer %d stands the find" % i)
	_ok(await step(1, "pickup_take"), "deliver-then-leave: the guest takes it")
	var paid := false
	for _i in 30:
		await step(0, "wait", {"frames": 30})
		if int(((await _state(1)).get("items", {}) as Dictionary).get("berries", 0)) >= int(base_items.get("berries", 0)) + 3:
			paid = true
			break
	check(paid, "deliver-then-leave: the guest's satchel holds the find (host-journaled payout applied and saved)")
	for _i in 10: await step(0, "wait", {"frames": 30}) # The host accepts the guest's ACK.
	if not await _rejoin("deliver-then-leave"):
		quit(await finish())
		return
	_ok(await step(1, "op_hold", {"hold": false}), "deliver-then-leave: the new stream sends normally")
	var delivered := await _await_admitted("deliver-then-leave")
	check(_admitted(delivered), "deliver-then-leave: the rejoined stream is admitted, not refused")
	var held: Dictionary = (((await _state(0)).get("authority", {}) as Dictionary).get(_guest_character, {}) as Dictionary)
	check(int((held.get("items", {}) as Dictionary).get("berries", 0)) == int(((await _state(1)).get("items", {}) as Dictionary).get("berries", -1)),
		"deliver-then-leave: the host's held record has the find, from its own row (%s)" % JSON.stringify(held))

	# 4. Offline change.
	if not _ok(await step(1, "leave"), "offline change: guest leaves"):
		quit(await finish())
		return
	_ok(await step(0, "expect_peers", {"count": 1}), "offline change: host sees the guest gone")
	_ok(await step(1, "op_diverge"), "offline change: FIXTURE the guest's creature gains a level offline")
	var levels: Array = (await _state(1)).get("levels", [])
	_ok(await step(1, "join", {"host": "127.0.0.1", "port": _port}), "offline change: guest rejoins")
	for i in 2: _ok(await step(i, "expect_peers", {"count": 2}), "offline change: peer %d sees both" % i)
	var changed := await _await_admitted("offline-change")
	check(_admitted(changed), "offline change: the rejoined stream is admitted")
	held = (((await _state(0)).get("authority", {}) as Dictionary).get(_guest_character, {}) as Dictionary)
	check(held.get("levels") == levels, "offline change: the host re-admitted the current record (levels %s, host %s)" % [str(levels), JSON.stringify(held)])
	var before_find: Dictionary = (await _state(1)).get("items", {})
	for i in 2:
		_ok(await step(i, "pickup_stand", {"id": "op_rejoin_find_b", "item": "berries", "realm": "meadows", "count": 2}),
			"offline change: peer %d stands another find" % i)
	_ok(await step(1, "pickup_take"), "offline change: the guest takes it")
	var pays := false
	for _i in 30:
		await step(0, "wait", {"frames": 30})
		var mine_now: Dictionary = (await _state(1)).get("items", {})
		var host_now: Dictionary = ((((await _state(0)).get("authority", {}) as Dictionary).get(_guest_character, {}) as Dictionary).get("items", {}))
		if int(mine_now.get("berries", 0)) == int(before_find.get("berries", 0)) + 2 and int(host_now.get("berries", 0)) == int(mine_now.get("berries", 0)):
			pays = true
			break
	check(pays, "offline change: a later find pays the guest and reaches the host's record (satchel not blocked): guest %s host %s" % [
		JSON.stringify((await _state(1)).get("items", {})),
		JSON.stringify((((await _state(0)).get("authority", {}) as Dictionary).get(_guest_character, {}) as Dictionary))])

	# 5. Negative control: an invalid record is refused, never adopted.
	if not _ok(await step(1, "leave"), "invalid: guest leaves"):
		quit(await finish())
		return
	_ok(await step(0, "expect_peers", {"count": 1}), "invalid: host sees the guest gone")
	_ok(await step(1, "op_corrupt"), "invalid: FIXTURE the guest's record is invalid (hp above max)")
	var refused: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": _port})
	check(str(refused.get("verdict", "")) != "PASS" and str(refused.get("detail", "")).contains("could not be admitted"),
		"invalid: the rejoin is refused with a reason (%s)" % str(refused.get("detail", "")))
	quit(await finish())
