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
##    the host"), leaves, and rejoins. It holds every payout this world
##    recorded, so its record is adopted (owner ruling 2026-10-05, "guest wins
##    unless behind"); the host's record has the find, absorbed once.
## 4. Offline change (F18 render 37365638014): the guest leaves, its creature
##    gains a level offline (fixture), and it rejoins. Not behind: the host
##    adopts the guest's record (its levels), no refusal, and a later find pays
##    on both sides.
## 4b. Behind (a restored backup): the guest leaves and forgets that later
##    find (fixture `op_rollback`), and rejoins. Its record lacks a payout this
##    world absorbed, so the held record wins and the guest adopts it: the find
##    is back, its payout row settled, not paid again.
## 5. NEGATIVE CONTROL: an invalid portable record (fixture: hp above max) is
##    refused at the rejoin hello with a reason, never adopted.

const PEER_SCRIPT := "res://tests/smoke_net_owner_passive_rejoin_peer.gd"
const BUILD_BUDGET := 20000
const ADMIT_FRAMES := 600

var _port := 0
var _guest_character := ""
var _tonic_uid := ""
var _tonic_receipt := ""
var _tonic_remaining := 0.0
var _earned_mastery: Dictionary = {}
var _mastery_uid := ""


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
		_ok(await step(i, "op_tonic_candidate"), "tonic: process-local candidate gates before world boot")
		if not _ok(await step(i, "boot", {"scene": "world"}, BUILD_BUDGET), "SETUP: peer %d boots its own Meadows world" % i):
			quit(await finish())
			return
		await step(i, "dismiss_dialogue", {})
		_ok(await step(i, "party_grant", {"species": "terrapup", "level": 8}), "SETUP: peer %d owns a terrapup" % i)
	_ok(await step(1, "op_tonic_supply"), "tonic: guest saves its initial two-item stock before admission")
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
	if not await _tonic_item_original():
		quit(await finish())
		return
	# Mastery settles after a normal wild exit, before testing plain rejoin.
	# The actual Item remains timed; neither exit fabricates a win or reward.
	for i in [1, 0]:
		if not _ok(await step(i, "press", {"action":"combat_run"}), "mastery: normal disengage input exits peer %d's wild fight" % i):
			quit(await finish())
			return
	var mastery_settled := false
	for poll in 30:
		var owner: Dictionary = (await _state(1)).get("mastery", {})
		var held: Dictionary = (await _state(0)).get("mastery", {}).get("held", {}).get(_guest_character, {}).get(_mastery_uid, {})
		if owner.get("disk", {}).get(_mastery_uid, {}) == _earned_mastery and held == _earned_mastery:
			mastery_settled = true
			break
		await step(0, "wait", {"frames":30})
	check(mastery_settled, "mastery: normal exit settles exactly the actual earned uses on owner disk and host")

	# 2. Plain leave + rejoin.
	if not await _rejoin("rejoin"):
		quit(await finish())
		return
	var after := await _await_admitted("after-rejoin")
	var rejoined_id := str(((after.guest as Dictionary).get("local", {}) as Dictionary).get("id", ""))
	check(rejoined_id != first_id and not rejoined_id.is_empty(), "rejoin: the guest armed a new stream")
	check(_admitted(after), "rejoin: the host admitted the rejoined guest's NEW stream (not pending, same id)")
	var rejoin_tonic: Dictionary = (await _state(1)).get("tonic", {})
	var rejoin_remaining := _tonic_seconds(rejoin_tonic)
	check(rejoin_remaining > 0.0 and rejoin_remaining <= _tonic_remaining,
		"tonic: new admitted stream reconciles remaining duration without refreshing the saved Item")
	check(int(rejoin_tonic.get("stock", -1)) == 1, "tonic: rejoin never debits the Item a second time")
	check((rejoin_tonic.get("disk_receipts", []) as Array).has(_tonic_receipt), "tonic: owner disk retains the exact saved Item receipt")
	var rejoin_mastery := {}
	var held_mastery := {}
	for poll in 30:
		rejoin_mastery = (await _state(1)).get("mastery", {})
		held_mastery = (await _state(0)).get("mastery", {}).get("held", {}).get(_guest_character, {}).get(_mastery_uid, {})
		if rejoin_mastery.get("disk", {}).get(_mastery_uid, {}) == _earned_mastery and held_mastery == _earned_mastery: break
		await step(0, "wait", {"frames":30})
	check(rejoin_mastery.get("live", {}).get(_mastery_uid, {}).get("uses") == _earned_mastery.get("uses") \
		and rejoin_mastery.get("live", {}).get(_mastery_uid, {}).get("receipts") == _earned_mastery.get("receipts"),
		"mastery: plain rejoin preserves actual landed uses and never credits an admission replay")
	check(rejoin_mastery.get("disk", {}).get(_mastery_uid, {}) == _earned_mastery and held_mastery == _earned_mastery,
		"mastery: real owner disk and rejoined host hold exactly the earned per-UID mastery")

	# 3. Passive inputs after the rejoin are acknowledged under the new id.
	# Saved mastery legitimately rebases the owner stream. Sample its current
	# admitted identity after settlement before testing additional inputs.
	var walking_stream := await _await_admitted("before-walk")
	check(_admitted(walking_stream), "rejoin: the current post-settlement walking stream is admitted")
	rejoined_id = str(walking_stream.guest.get("local", {}).get("id", ""))
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
	# Natural authored ninety-second timer, not a forged prefix or accelerated clock.
	var expired := false
	for poll in 110:
		await step(1, "wait", {"frames":60})
		var owner_tonic: Dictionary = (await _state(1)).get("tonic", {})
		var host_tonic: Dictionary = (await _state(0)).get("tonic", {})
		var effects: Array = host_tonic.get("projected", {}).get(_guest_character, {}).get(_tonic_uid, {}).get("effects", [])
		if _tonic_seconds(owner_tonic) == 0.0 and effects.is_empty():
			expired = true
			break
	check(expired, "tonic: actual owner passive ticks expire the same effect on guest and host")
	check(_tonic_seconds((await _state(0)).get("tonic", {})) == 0.0, "tonic: the guest command never buffs the other player's creature")
	if not await _rejoin("expired-tonic"):
		quit(await finish())
		return
	check(_admitted(await _await_admitted("expired-tonic")), "tonic: expired receipt rejoins normally")
	check(_tonic_seconds((await _state(1)).get("tonic", {})) == 0.0,
		"tonic: accepting the saved receipt after expiry cannot resurrect its old duration")

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
	var code := str(((await _state(0)).get("rejoin_codes", {}) as Dictionary).get(_guest_character, ""))
	check(code == "readmitted_portable", "deliver-then-leave: holding every payout, the guest's record is adopted (%s)" % code)
	var held: Dictionary = (((await _state(0)).get("authority", {}) as Dictionary).get(_guest_character, {}) as Dictionary)
	check(int((held.get("items", {}) as Dictionary).get("berries", 0)) == int(((await _state(1)).get("items", {}) as Dictionary).get("berries", -1)),
		"deliver-then-leave: the host's held record has the find, from its own row (%s)" % JSON.stringify(held))

	# 4. Offline change.
	if not _ok(await step(1, "leave"), "offline change: guest leaves"):
		quit(await finish())
		return
	_ok(await step(0, "expect_peers", {"count": 1}), "offline change: host sees the guest gone")
	var held_levels: Array = (await _state(1)).get("levels", [])
	_ok(await step(1, "op_diverge"), "offline change: FIXTURE the guest's creature gains a level offline")
	var levels: Array = (await _state(1)).get("levels", [])
	check(levels != held_levels, "offline change: the guest's file now differs (levels %s -> %s)" % [str(held_levels), str(levels)])
	_ok(await step(1, "join", {"host": "127.0.0.1", "port": _port}), "offline change: guest rejoins")
	for i in 2: _ok(await step(i, "expect_peers", {"count": 2}), "offline change: peer %d sees both" % i)
	var changed := await _await_admitted("offline-change")
	check(_admitted(changed), "offline change: the rejoined stream is admitted")
	var changed_code := str(((await _state(0)).get("rejoin_codes", {}) as Dictionary).get(_guest_character, ""))
	check(changed_code == "readmitted_portable", "offline change: not behind, the guest's record is adopted (%s)" % changed_code)
	held = (((await _state(0)).get("authority", {}) as Dictionary).get(_guest_character, {}) as Dictionary)
	check(held.get("levels") == levels, "offline change: the host's record now has the guest's levels (guest %s, host %s)" % [str(levels), JSON.stringify(held)])
	var kept: Dictionary = await _state(1)
	check(kept.get("levels") == levels and str((kept.get("local", {}) as Dictionary).get("admission_refused", "")).is_empty(),
		"offline change: the guest keeps its levels, not refused (guest levels %s, refused '%s')" % [
		str(kept.get("levels")), str((kept.get("local", {}) as Dictionary).get("admission_refused", ""))])
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

	# 4b. Behind: a restored backup made before that find.
	var full: Dictionary = (await _state(1)).get("items", {})
	if not _ok(await step(1, "leave"), "behind: guest leaves"):
		quit(await finish())
		return
	_ok(await step(0, "expect_peers", {"count": 1}), "behind: host sees the guest gone")
	_ok(await step(1, "op_rollback", {"find": "op_rejoin_find_b", "item": "berries", "count": 2}),
		"behind: FIXTURE the guest's file forgets the later find (a backup)")
	_ok(await step(1, "join", {"host": "127.0.0.1", "port": _port}), "behind: guest rejoins")
	for i in 2: _ok(await step(i, "expect_peers", {"count": 2}), "behind: peer %d sees both" % i)
	var behind_code := str(((await _state(0)).get("rejoin_codes", {}) as Dictionary).get(_guest_character, ""))
	check(behind_code == "held_wins", "behind: the host's held record wins (%s)" % behind_code)
	var restored: Dictionary = {}
	for _i in 30:
		restored = await _state(1)
		if int((restored.get("items", {}) as Dictionary).get("berries", 0)) == int(full.get("berries", -1)): break
		await step(0, "wait", {"frames": 30})
	check(int((restored.get("items", {}) as Dictionary).get("berries", 0)) == int(full.get("berries", -1))
		and str((restored.get("local", {}) as Dictionary).get("admission_refused", "")).is_empty(),
		"behind: the guest adopted the held record, the find is back once (%s vs %s)" % [JSON.stringify(restored.get("items", {})), JSON.stringify(full)])
	var behind_admitted := await _await_admitted("behind")
	check(_admitted(behind_admitted), "behind: the stream is admitted after the adoption")
	for _i in 10: await step(0, "wait", {"frames": 30})
	check(int(((await _state(1)).get("items", {}) as Dictionary).get("berries", 0)) == int(full.get("berries", -1)), "behind: the find is never paid a second time")

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


func _tonic_seconds(state: Dictionary) -> float:
	for owned: Dictionary in state.get("owned", {}).values():
		for buff: Dictionary in owned.get("buffs", []):
			if buff.get("id") == "attack_tonic": return float(buff.get("remaining_s", 0.0))
	return 0.0


func _tonic_item_original() -> bool:
	if not _ok(await step(1, "op_tonic_pouch"), "tonic: production personal pouch assignment saves"): return false
	_ok(await step(0, "deploy_creature"), "tonic: host deploys its actual owned creature")
	if not _ok(await step(0, "op_tonic_target"), "tonic: normal interact opens a real canonical wild fight"): return false
	var encounter: Dictionary = await probe(0, "encounter")
	var id := str(encounter.get("id", ""))
	if id.is_empty():
		check(false, "tonic: actual host encounter identity is required")
		return false
	_ok(await step(1, "teleport", {"at":encounter.get("opponent_pos", [])}), "tonic: existing proximity fixture reaches the shared fight")
	_ok(await step(1, "deploy_creature"), "tonic: guest deploys its same admitted owned creature")
	if not _ok(await step(1, "join_encounter", {"encounter_id":id}), "tonic: guest joins the host's exact record"): return false
	var before_mastery: Dictionary = (await _state(1)).get("mastery", {}).get("live", {})
	if not _ok(await step(1, "op_tonic_hits"), "tonic: normal accepted quick hits earn Item meter"): return false
	var retained: Array = (await _state(0)).get("mastery", {}).get("retained", {}).get(_guest_character, [])
	var seen := {}
	for event: Dictionary in retained:
		var uid := str(event.get("attacker_uid", ""))
		var move := str(event.get("move_id", ""))
		var action := str(event.get("action_id", ""))
		if not before_mastery.has(uid) or seen.has(action) or float(event.get("applied_damage", 0.0)) <= 0.0: continue
		if _mastery_uid.is_empty():
			_mastery_uid = uid
			_earned_mastery = {"uses":before_mastery[uid].uses.duplicate(true), "receipts":before_mastery[uid].receipts.duplicate(true)}
		if uid != _mastery_uid: continue
		seen[action] = true
		if not _earned_mastery.receipts.has(move): _earned_mastery.receipts[move] = []
		if not _earned_mastery.receipts[move].has(action):
			_earned_mastery.receipts[move].append(action)
			_earned_mastery.uses[move] = int(_earned_mastery.uses.get(move, 0)) + 1
	check(not seen.is_empty(), "mastery: actual landed quick hits retain unique creature-owned mastery obligations")
	print("MASTERY actual earned expectation: ", JSON.stringify({"uid":_mastery_uid, "before":before_mastery, "retained":retained, "earned":_earned_mastery}))
	_ok(await step(1, "op_tonic_clear"), "tonic: existing proximity fixture clears reach while previous actual HP writes settle")
	var ready := false
	for poll in 20:
		var current: Dictionary = (await _state(0)).get("tonic", {}).get("readiness", {}).get(_guest_character, {})
		if current.get("admission") == true and current.get("vitals_pending") == false:
			ready = true
			break
		await step(0, "wait", {"frames":30})
	check(ready, "tonic: host confirms the actual previous owner HP saves are settled before writer refusal")
	if not ready: return false
	var pending: Dictionary = await step(1, "op_tonic_item")
	if not _ok(pending, "tonic: production Item request preserves its original while owner save refuses"): return false
	var guest: Dictionary = (await _state(1)).get("tonic", {})
	var host: Dictionary = (await _state(0)).get("tonic", {})
	var original: Dictionary = host.get("rows", {}).get(_guest_character, {})
	print("TONIC original actual owner/host: ", JSON.stringify({"owner":guest, "host":host}))
	check(original.get("status") == "pending" and not str(original.get("receipt", "")).is_empty(),
		"tonic: host journal retains the precise original awaiting owner TRUE BOOL")
	check(_tonic_seconds(guest) == 0.0 and host.get("projected", {}).get(_guest_character, {}).is_empty(),
		"tonic: owner save refusal installs no owner or authoritative effect")
	check(int(guest.get("stock", -1)) == 1 and int(guest.get("disk_stock", -1)) == 2 \
		and guest.get("fenced") == true and not (guest.get("disk_receipts", []) as Array).has(str(original.get("receipt", ""))) \
		and guest.get("saved_result", {}).get("saved") != true,
		"tonic: failed owner save fences the pending debit, keeps disk unchanged and produces no saved result")
	_tonic_receipt = str(original.get("receipt", ""))
	_tonic_uid = str(original.get("uid", ""))
	_ok(await step(1, "op_tonic_writer", {"block":false}), "tonic: original actual owner writer is restored")
	if not _ok(await step(1, "op_tonic_retry"), "tonic: retry sends the same original request"): return false
	for poll in 30:
		guest = (await _state(1)).get("tonic", {})
		host = (await _state(0)).get("tonic", {})
		if guest.get("saved_result", {}).get("saved") == true and host.get("rows", {}).get(_guest_character, {}).get("status") == "accepted": break
		await step(0, "wait", {"frames":30})
	check(guest.get("saved_result", {}).get("saved") == true \
		and guest.get("saved_result", {}).get("receipt") == _tonic_receipt,
		"tonic: actual TRUE owner-write BOOL precedes the exact saved result")
	check(int(guest.get("stock", -1)) == 1 and int(guest.get("disk_stock", -1)) == 1 \
		and (guest.get("disk_receipts", []) as Array).has(_tonic_receipt),
		"tonic: real owner disk holds one debit and the original receipt")
	check(host.get("rows", {}).get(_guest_character, {}).get("receipt") == _tonic_receipt \
		and host.get("rows", {}).get(_guest_character, {}).get("request") == original.get("request"),
		"tonic: retry neither substitutes nor duplicates the accepted original")
	_tonic_remaining = _tonic_seconds(guest)
	check(_tonic_remaining > 0.0 and _tonic_remaining <= 90.0, "tonic: actual saved effect starts its authored timer")
	return _tonic_remaining > 0.0
