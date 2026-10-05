extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F34#4: forward-camp placement is host-authoritative and persists through
## reload and rejoin, across two real processes.
##
##   tools/net/run_net_smoke.sh forward_camp
##
## Both peers hold a kit (the guest's before joining, so the host admits it).
## The host places a camp; the guest sees the record and the planted camp.
## The guest places its own camp (20 m clear) through its production placer;
## the host validates it against the guest's admitted inventory and body,
## debits the guest's kit and plants one record carrying the GUEST's character
## id, which both peers then hold. The host saves and reloads its world: both
## camps survive. The guest leaves and rejoins: it receives both camps again.
## DISCLOSED FIXTURES (tests/helpers/forward_camp_net_peer.gd): kits added
## straight to the satchel; ground found by the placer's own preview; Player
## stood 3 m from the spot and the ghost aimed at it before the Place press.

const PEER_SCRIPT := "res://tests/helpers/forward_camp_net_peer.gd"
const STEP_BUDGET := 3000


func _init_budgets() -> void:
	super._init_budgets()
	_budgets["smoke_step_budget_s_2peer"] = 900.0


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return
	for i in 2:
		var granted: Dictionary = await step(i, "party_grant", {"species": "terrapup"})
		check(granted.get("verdict") == "PASS", "peer %d owns a creature" % i)
		var kit: Dictionary = await _cstep(i, "camp_grant_kit", {"n": 1})
		check(int(kit.get("kits", 0)) == 1, "peer %d holds one forward-camp kit" % i)
	var hosted: Dictionary = await step(0, "host", {})
	check(hosted.get("verdict") == "PASS", "peer 0 hosts (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(joined.get("verdict") == "PASS", "peer 1 joins (%s)" % str(joined.get("detail", "")))
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(seen.get("verdict") == "PASS", "peer %d sees both players" % i)

	var host_id := str((await _cstep(0, "camp_records")).get("character_id", ""))
	var guest_id := str((await _cstep(1, "camp_records")).get("character_id", ""))
	check(not host_id.is_empty() and not guest_id.is_empty() and host_id != guest_id, "two distinct characters")

	# --- the host places ------------------------------------------------------
	var host_place: Dictionary = await _cstep(0, "camp_place", {}, STEP_BUDGET)
	check(host_place.get("verdict") == "PASS", "the host places its camp (%s)" % str(host_place.get("detail", "")))
	check(int(host_place.get("kits", -1)) == 0, "the host's kit is spent")
	var guest_view := await _await_records(1, 1)
	check(_owners(guest_view).has(host_id) and int(guest_view.get("nodes", 0)) == 1,
		"the guest receives the host's camp record and planted camp (%s)" % str(guest_view.get("detail", "")))

	var guest_held := await _cstep(1, "camp_records")
	check(int(guest_held.get("kits", -1)) == 1, "after joining the guest still holds its kit (%d)" % int(guest_held.get("kits", -1)))

	# --- the guest places -----------------------------------------------------
	await step(1, "teleport", {"at": _offset(host_place.get("spot", []), 30.0)})
	var guest_place: Dictionary = await _cstep(1, "camp_place", {"away": 20.0}, STEP_BUDGET)
	check(guest_place.get("verdict") == "PASS", "the guest places its own camp (%s)" % str(guest_place.get("detail", "")))
	var host_view := await _await_records(0, 2)
	check(_owners(host_view).has(guest_id) and int(host_view.get("nodes", 0)) == 2,
		"the host holds the guest's camp with the guest's character id (%s)" % str(host_view.get("detail", "")))
	guest_view = await _await_records(1, 2)
	check(_owners(guest_view).has(guest_id) and _owners(guest_view).has(host_id), "the guest holds both camps")
	var guest_kits := await _await_kits(1, 0)
	check(guest_kits == 0, "the host debited the guest's own kit (%d left)" % guest_kits)
	var settled := {}
	for _poll in 20:
		settled = await _cstep(1, "camp_records")
		if settled.get("pending") == false: break
		await step(1, "wait", {"frames": 30})
	check(settled.get("pending") == false, "the guest's camp request settles (no pending original left)")

	# --- host save and reload -------------------------------------------------
	var reload: Dictionary = await step(0, "save_reload_here", {}, STEP_BUDGET)
	check(reload.get("verdict") == "PASS", "the host saves and reloads its world (%s)" % str(reload.get("detail", "")))
	host_view = await _await_records(0, 2)
	check(_owners(host_view).has(host_id) and _owners(host_view).has(guest_id),
		"after the host reload both camps are in the world (%s)" % str(host_view.get("detail", "")))

	# --- guest leave and rejoin -----------------------------------------------
	var left: Dictionary = await step(1, "leave", {})
	check(left.get("verdict") == "PASS", "the guest leaves (%s)" % str(left.get("detail", "")))
	host_session = await probe(0, "session")
	port = int((host_session as Dictionary).get("enet_port", port)) if host_session is Dictionary else port
	var rejoined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(rejoined.get("verdict") == "PASS", "the guest rejoins (%s)" % str(rejoined.get("detail", "")))
	guest_view = await _await_records(1, 2)
	check(_owners(guest_view).has(host_id) and _owners(guest_view).has(guest_id) and int(guest_view.get("nodes", 0)) == 2,
		"after rejoining the guest receives both camps (%s)" % str(guest_view.get("detail", "")))
	quit(await finish())


func _owners(view: Dictionary) -> Array:
	return (view.get("records", []) as Array).map(func(r: Dictionary) -> String: return str(r.get("character_id", "")))


func _await_records(peer: int, count: int) -> Dictionary:
	var view: Dictionary = {}
	for _poll in 40:
		view = await _cstep(peer, "camp_records")
		if (view.get("records", []) as Array).size() >= count: break
		await step(peer, "wait", {"frames": 15})
	return view


func _await_kits(peer: int, expected: int) -> int:
	var kits := -1
	for _poll in 40:
		kits = int((await _cstep(peer, "camp_records")).get("kits", -1))
		if kits == expected: break
		await step(peer, "wait", {"frames": 15})
	return kits


static func _offset(at: Variant, metres: float) -> Array:
	if not at is Array or (at as Array).size() != 3: return [0.0, 2.0, 0.0]
	return [float(at[0]) + metres, float(at[1]) + 2.0, float(at[2])]


## A camp_* step's values arrive under data; flatten them for the checks.
func _cstep(peer: int, action: String, args := {}, budget: int = -1) -> Dictionary:
	var result: Dictionary = await step(peer, action, args, budget)
	var flat := result.duplicate(true)
	if result.get("data") is Dictionary:
		flat.merge(result.data, true)
	return flat


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
