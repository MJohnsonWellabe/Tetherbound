extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F33 Harness maximum HP (coordinator ruling 2026-10-05) across two real
## processes: host-authoritative, fight-scoped, never saved raised.
##
##   tools/net/run_net_smoke.sh harness_max_hp
##
## The guest wears a Tidesteel Harness +1 before joining, so the record the
## host admits carries it. Both peers deploy, the host engages a wild, the
## guest joins the fight. The host's live opponent strikes the guest's creature
## through the production host strike (host pick -> admitted geared card ->
## host_deliver_enemy_hit -> RPC -> guest apply_host_enemy_hit). Asserted:
##   * the host's s (from the admitted record) is the Harness's authored s;
##   * the guest's bar shows max x the HOST's s, at the stored HP fraction,
##     after the guest dropped the Harness from its own record (so only the
##     host's s can explain it);
##   * the guest's stored HP fell by the rolled hit (its own hit_landed) / s;
##   * the guest's saved party row holds the base maximum, mid-fight and after.
## DISCLOSED FIXTURES (peer side: tests/helpers/harness_hp_net_peer.gd): gear
## written into the guest's own record before join; the host's swing placed
## 1.5 m from the guest's creature with a narrow cone so it picks the guest;
## and, from just before the guest joins until the scripted hit has been read,
## the host does not route its live wild's own swings (harness_hold_opponent),
## so the scripted strike is the only hit the guest takes in that window.

const PEER_SCRIPT := "res://tests/helpers/harness_hp_net_peer.gd"
const ITEM := "tidesteel_harness_plus_1"
const ANNOUNCE_POLLS := 16
const GEAR := preload("res://scripts/creatures/creature_gear.gd")


func _initialize() -> void:
	_run()


func _run() -> void:
	var expected_s := float(GEAR.modifiers({"harness": ITEM, "charm": ""}, GEAR.config()).max_hp)
	check(expected_s > 1.0, "%s raises maximum HP (authored s %.3f)" % [ITEM, expected_s])
	if not await launch(2, "world"):
		quit(await finish())
		return
	for i in 2:
		var granted: Dictionary = await step(i, "party_grant", {"species": "terrapup"})
		check(granted.get("verdict") == "PASS", "peer %d owns a creature (%s)" % [i, str(granted.get("detail", ""))])
	var worn: Dictionary = await _hstep(1, "harness_wear", {"item": ITEM})
	check(worn.get("verdict") == "PASS", "the guest wears the Harness before joining (%s)" % str(worn.get("detail", "")))
	var hosted: Dictionary = await step(0, "host", {})
	check(hosted.get("verdict") == "PASS", "peer 0 hosts (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(joined.get("verdict") == "PASS", "peer 1 joins (%s)" % str(joined.get("detail", "")))
	# The guest drops its own Harness now, before any fight: the host admitted
	# it at join, so only the host's s can raise the guest's bar from here on.
	var unworn: Dictionary = await _hstep(1, "harness_unwear")
	check(unworn.get("verdict") == "PASS", "the guest's local record no longer carries the Harness")
	var guest_session: Variant = await probe(1, "session")
	var guest_peer := int((guest_session as Dictionary).get("peer_id", 0)) if guest_session is Dictionary else 0
	check(guest_peer > 1, "the guest has a real peer id (%d)" % guest_peer)
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(seen.get("verdict") == "PASS", "peer %d sees both players" % i)
		var deployed: Dictionary = await step(i, "deploy_creature", {})
		check(deployed.get("verdict") == "PASS", "peer %d deployed its creature (%s)" % [i, str(deployed.get("detail", ""))])
	var resting: Dictionary = await _hstep(1, "harness_read")
	check(is_equal_approx(float(resting.get("shown_max", 0.0)), float(resting.get("max_hp", -1.0))),
		"out of a fight the guest's bar is the stored maximum (%s)" % str(resting.get("detail", "")))

	var engaged: Dictionary = await step(0, "engage_wild", {})
	check(engaged.get("verdict") == "PASS", "the host engages a wild (%s)" % str(engaged.get("detail", "")))
	if engaged.get("verdict") != "PASS":
		quit(await finish())
		return
	var host_view: Dictionary = await _encounter(0)
	var encounter_id := str(host_view.get("id", ""))
	var guest_view: Dictionary = await _encounter(1)
	for _wait in ANNOUNCE_POLLS:
		if (guest_view.get("joinable", []) as Array).has(encounter_id): break
		await step(1, "wait", {"frames": 15})
		guest_view = await _encounter(1)
	var here := _vec(host_view.get("opponent_pos", []))
	check(here != Vector3.INF, "the fight's position is announced")
	if here == Vector3.INF:
		quit(await finish())
		return
	var held: Dictionary = await _hstep(0, "harness_hold_opponent")
	check(held.get("verdict") == "PASS", "the host holds its wild's own swings for the measured window (%s)" % str(held.get("detail", "")))
	await step(1, "teleport", {"at": [here.x - 2.5, here.y + 1.0, here.z]})
	var joined_fight: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id})
	check(joined_fight.get("verdict") == "PASS", "the guest joins the fight (%s)" % str(joined_fight.get("detail", "")))
	# Keep the host's own creature well clear of the narrow swing at the guest.
	await step(0, "place_creature", {"at": [here.x + 12.0, here.y, here.z + 12.0]})

	var before: Dictionary = await _hstep(1, "harness_read")
	check(bool(before.get("fighting", false)), "the guest is in the fight")
	check(float(before.get("last_incoming", -1.0)) < 0.0,
		"no unscripted hit landed on the guest before the host's hit (%s)" % str(before.get("detail", "")))
	check(absf(float(before.get("shown_max", 0.0)) - float(before.get("max_hp", -1.0))) < 0.01,
		"before the host's hit the guest's own (bare) record shows no raise")
	var hit: Dictionary = await _hstep(0, "harness_host_hit", {"peer_id": guest_peer})
	check(hit.get("verdict") == "PASS", "the host's opponent strikes the guest's creature (%s)" % str(hit.get("detail", "")))
	var host_s := float(hit.get("host_s", 0.0))
	check(absf(host_s - expected_s) < 0.0001, "the host's s comes from the admitted record (%.4f vs authored %.4f)" % [host_s, expected_s])
	var after: Dictionary = {}
	for _poll in 20:
		await step(1, "wait", {"frames": 6})
		after = await _hstep(1, "harness_read")
		if float(after.get("hp", 0.0)) < float(before.get("hp", 0.0)) - 0.001: break
	var stored_loss := float(before.get("hp", 0.0)) - float(after.get("hp", 0.0))
	var rolled := float(after.get("last_incoming", -1.0))
	print("harness hit: before %s | after %s" % [str(before.get("detail", "")), str(after.get("detail", ""))])
	check(stored_loss > 0.0, "the hit reached the guest's creature (stored -%.2f)" % stored_loss)
	check(absf(float(after.get("shown_max", 0.0)) - float(after.get("max_hp", 0.0)) * host_s) < 0.01,
		"the guest's bar shows max x the host's s (%.2f = %.2f x %.4f)" % [float(after.get("shown_max", 0.0)), float(after.get("max_hp", 0.0)), host_s])
	check(absf(float(after.get("shown_hp", 0.0)) / maxf(0.001, float(after.get("shown_max", 1.0)))
		- float(after.get("hp", 0.0)) / maxf(0.001, float(after.get("max_hp", 1.0)))) < 0.0001,
		"the bar shows the stored HP fraction")
	check(rolled > 0.0 and absf(stored_loss - rolled / host_s) < 0.01,
		"stored HP fell by the rolled hit / the host's s (%.2f = %.2f / %.4f)" % [stored_loss, rolled, host_s])
	check(absf(float(after.get("saved_max", 0.0)) - float(after.get("max_hp", -1.0))) < 0.0001
		and float(after.get("saved_max", 0.0)) < float(after.get("shown_max", 0.0)),
		"mid-fight the guest's saved party row holds the base maximum (%.2f)" % float(after.get("saved_max", 0.0)))
	var released: Dictionary = await _hstep(0, "harness_release_opponent")
	check(released.get("verdict") == "PASS", "the host routes its wild's swings again (%s)" % str(released.get("detail", "")))
	var left: Dictionary = await _hstep(1, "harness_flee")
	var out: Dictionary = {}
	for _poll in 40:
		await step(1, "wait", {"frames": 15})
		out = await _hstep(1, "harness_read")
		if not bool(out.get("fighting", true)): break
	print("after leaving: %s (leave %s)" % [str(out.get("detail", "")), str(left.get("detail", ""))])
	check(not bool(out.get("fighting", true)), "the guest left the fight (%s)" % str(left.get("detail", "")))
	if not bool(out.get("fighting", true)):
		check(is_equal_approx(float(out.get("shown_max", 0.0)), float(out.get("max_hp", -1.0))),
			"after the fight the guest's bar is the stored maximum again")
		check(absf(float(out.get("saved_max", 0.0)) - float(out.get("max_hp", -1.0))) < 0.0001, "and the saved row holds it")
	quit(await finish())


func _hstep(peer: int, action: String, args := {}) -> Dictionary:
	var result: Dictionary = await step(peer, action, args)
	var flat := result.duplicate(true)
	if result.get("data") is Dictionary:
		flat.merge(result.data, true)
	return flat


func _encounter(peer: int) -> Dictionary:
	var value = await probe(peer, "encounter")
	return value if value is Dictionary else {}


static func _vec(value: Variant) -> Vector3:
	if not (value is Array) or (value as Array).size() != 3:
		return Vector3.INF
	var a: Array = value
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://")]
	if _is_windows():
		args.append_array(["--log-file", log_path])
	args.append_array(["--script", PEER_SCRIPT, "--", "--role=" + role, "--peer=%d" % i,
		"--control-port=%d" % control_port, "--enet-port=%d" % enet_port, "--scene=" + scene,
		"TB_NET_RUN_ID=" + _run_id])
	for extra: Variant in extra_args:
		args.append(str(extra))
	OS.set_environment("XDG_DATA_HOME", home)
	if _is_windows():
		OS.set_environment("APPDATA", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", OS.get_environment("TB_NET_WORLD_SEED") if not OS.get_environment("TB_NET_WORLD_SEED").is_empty() else "0")
	if _is_windows():
		return OS.create_process(OS.get_executable_path(), args)
	var parts: Array[String] = [_shq(OS.get_executable_path())]
	for arg: Variant in args:
		parts.append(_shq(str(arg)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" % [" ".join(parts), _shq(log_path)]])
