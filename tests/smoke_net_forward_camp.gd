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
## Optional --heal-pulse reuses the grant seam for a guest L15 Meadowhart,
## enables candidate saved vitals in memory before boot, and AFTER all original
## assertions proves legal camp equip -> actual wild damage -> B Heal -> saved
## receipt/Manager feedback. No HP, AI, RNG or mastery fixture is introduced.

const PEER_SCRIPT := "res://tests/helpers/forward_camp_net_peer.gd"
const STEP_BUDGET := 3000


func _init_budgets() -> void:
	super._init_budgets()
	_budgets["smoke_step_budget_s_2peer"] = 900.0


func _initialize() -> void:
	_run()


func _run() -> void:
	var heal_mode: bool = OS.get_cmdline_user_args().has("--heal-pulse")
	if not await launch(2, "world", ["--heal-pulse"] if heal_mode else []):
		quit(await finish())
		return
	for i in 2:
		var grant := {"species": "terrapup"}
		if i == 1: grant["level"] = 15
		var granted: Dictionary = await step(i, "party_grant", grant)
		check(granted.get("verdict") == "PASS", "peer %d owns a creature" % i)
		if heal_mode and i == 1:
			# Same disclosed pre-admission grant seam; L15 naturally learns Heal.
			var healer: Dictionary = await step(i, "party_grant", {"species":"meadowhart", "level":15})
			check(healer.get("verdict") == "PASS", "Heal setup: guest owns a legally eligible L15 Meadowhart")
		# The guest brings two: one for its camp, one to place a second (the
		# pack-up offer applies when a kit is in hand to place).
		var kit: Dictionary = await _cstep(i, "camp_grant_kit", {"n": 1 + i})
		check(int(kit.get("kits", 0)) == 1 + i, "peer %d holds %d forward-camp kit(s)" % [i, 1 + i])
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
	check(int(guest_held.get("kits", -1)) == 2, "after joining the guest still holds its kits (%d)" % int(guest_held.get("kits", -1)))

	# --- the guest places -----------------------------------------------------
	await step(1, "teleport", {"at": _offset(host_place.get("spot", []), 30.0)})
	var guest_place: Dictionary = await _cstep(1, "camp_place", {"away": 20.0}, STEP_BUDGET)
	check(guest_place.get("verdict") == "PASS", "the guest places its own camp (%s)" % str(guest_place.get("detail", "")))
	var host_view := await _await_records(0, 2)
	check(_owners(host_view).has(guest_id) and int(host_view.get("nodes", 0)) == 2,
		"the host holds the guest's camp with the guest's character id (%s)" % str(host_view.get("detail", "")))
	guest_view = await _await_records(1, 2)
	check(_owners(guest_view).has(guest_id) and _owners(guest_view).has(host_id), "the guest holds both camps")
	var guest_kits := await _await_kits(1, 1)
	check(guest_kits == 1, "the host debited one of the guest's own kits (%d left)" % guest_kits)
	var settled := {}
	for _poll in 20:
		settled = await _cstep(1, "camp_records")
		if settled.get("pending") == false: break
		await step(1, "wait", {"frames": 30})
	check(settled.get("pending") == false, "the guest's camp request settles (no pending original left)")

	# --- the guest moves its camp (HOMESTEAD §8 pack-up offer) ------------------
	var old_guest_uid := ""
	for row: Dictionary in guest_view.get("records", []):
		if row.character_id == guest_id: old_guest_uid = str(row.uid)
	# Searched from beside the old camp (terrain collision streams around the
	# player); 12 m clears the old camp's footprint, which still stands while
	# the new ghost is validated.
	var moved: Dictionary = await _cstep(1, "camp_place", {"away": 12.0, "presses": 2}, STEP_BUDGET)
	check(moved.get("verdict") == "PASS" and str((moved.get("messages", [""]) as Array)[0]).contains("Press Place again to pack it up"),
		"the guest is offered a pack-up and, pressing again, pitches a new camp (%s)" % str(moved.get("detail", "")).left(160))
	host_view = await _await_records(0, 2)
	var guest_uids := (host_view.get("records", []) as Array).filter(func(r: Dictionary) -> bool: return r.character_id == guest_id)
	check(guest_uids.size() == 1 and str(guest_uids[0].uid) != old_guest_uid,
		"the host holds exactly one guest camp, the new one (%s)" % str(host_view.get("detail", "")))
	check(await _await_kits(1, 1) == 1, "the old camp's kit was refunded and one spent on the new camp (one left)")

	# F23: existing party_grant's level parameter unlocks the authored L15
	# utility; same guest/camp, production panel equip -> journal -> owner ACK.
	var edit := await _cstep(1, "camp_loadout_edit", {}, STEP_BUDGET)
	check(edit.get("verdict") == "PASS", "guest equips Quake Ring at its camp (%s)" % str(edit.get("detail", "")))
	var expected: Dictionary = edit.get("card", {})
	check(expected.get("move_utility") == "quake_ring" and int(expected.get("loadout_revision", 0)) == 1 and not expected.get("loadout_last_edit", {}).is_empty(),
		"camp equip changes the guest utility and saves its original revision")
	var view_args := {"character_id": guest_id, "uid": str(expected.get("uid", ""))}
	check(await _await_loadout(0, view_args, expected), "host admits the guest's saved loadout before reload")

	# --- host save and reload -------------------------------------------------
	var reload: Dictionary = await step(0, "save_reload_here", {}, STEP_BUDGET)
	check(reload.get("verdict") == "PASS", "the host saves and reloads its world (%s)" % str(reload.get("detail", "")))
	host_view = await _await_records(0, 2)
	check(_owners(host_view).has(host_id) and _owners(host_view).has(guest_id),
		"after the host reload both camps are in the world (%s)" % str(host_view.get("detail", "")))
	var guest_reload: Dictionary = await step(1, "save_reload_here", {}, STEP_BUDGET)
	check(guest_reload.get("verdict") == "PASS", "guest saves and reloads its character (%s)" % str(guest_reload.get("detail", "")))
	check(await _await_loadout(1, view_args, expected), "guest character reload preserves every loadout field and original receipt")

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
	check(await _await_loadout(0, view_args, expected), "host re-admits the guest's persisted loadout")
	check(await _await_loadout(1, view_args, expected), "guest rejoin preserves the saved loadout and receipt")
	if heal_mode: await _prove_heal(guest_id)
	quit(await finish())


func _prove_heal(character: String) -> void:
	var edit := await _cstep(1, "camp_loadout_edit", {"species":"meadowhart", "move_id":"heal_pulse"}, STEP_BUDGET)
	check(edit.get("verdict") == "PASS", "Heal: actual camp panel saves the legal owned utility (%s)" % str(edit.get("detail", "")))
	var expected: Dictionary = edit.get("card", {})
	var uid: String = str(expected.get("uid", ""))
	var args := {"character_id":character, "uid":uid}
	check(not uid.is_empty() and expected.get("move_utility") == "heal_pulse" and not expected.get("loadout_last_edit", {}).is_empty(),
		"Heal: equipped utility has its exact saved loadout receipt")
	if uid.is_empty() or edit.get("verdict") != "PASS": return
	check(await _await_loadout(0, args, expected), "Heal: host admits the actual equipped owner loadout")
	var deployed := await _cstep(1, "camp_heal_deploy")
	check(deployed.get("verdict") == "PASS", "Heal: normal LB selects and deploys the owned healer")
	if deployed.get("verdict") != "PASS": return
	var host_deployed: Dictionary = await step(0, "deploy_creature")
	check(host_deployed.get("verdict") == "PASS", "Heal: host deploys its actual owned creature")
	var target := await _cstep(0, "camp_heal_target")
	check(target.get("verdict") == "PASS" and not str(target.get("encounter_id", "")).is_empty(), "Heal: normal interact opens an actual canonical wild")
	if target.get("verdict") != "PASS" or str(target.get("encounter_id", "")).is_empty(): return
	await step(1, "teleport", {"at":target.get("position", [])})
	var joined: Dictionary = await step(1, "join_encounter", {"encounter_id":str(target.encounter_id)})
	check(joined.get("verdict") == "PASS", "Heal: guest joins the host's exact wild record")
	if joined.get("verdict") != "PASS": return
	var left: Dictionary = await step(0, "press", {"action":"combat_run"})
	check(left.get("verdict") == "PASS", "Heal: host normally disengages while the guest remains")
	var wounded := await _cstep(1, "camp_heal_wounded", args, STEP_BUDGET)
	var before: Dictionary = wounded.get("observation", {})
	print("HEAL actual wounded observation: ", JSON.stringify(before))
	check(wounded.get("verdict") == "PASS" and before.get("active_uid") == uid and before.get("saved_bool_seen") == true,
		"Heal: real enemy damage reaches the current owned body and the actual owner save BOOL")
	if wounded.get("verdict") != "PASS": return
	var pressed: Dictionary = await step(1, "press", {"action":"combat_utility"})
	check(pressed.get("verdict") == "PASS", "Heal: physical B utility tap reaches the mounted combat input")
	var after := {}
	var host := {}
	var completed := false
	var heal_action := ""
	for heal_poll: int in 40:
		after = (await _cstep(1, "camp_heal_view", args)).get("observation", {})
		host = (await _cstep(0, "camp_heal_view", args)).get("observation", {})
		var row: Dictionary = after.get("row", {})
		var originals: Array = host.get("originals", [])
		for original: Dictionary in originals:
			if original.get("proposal", {}).get("settlement_receipt") == row.get("receipt") \
				and original.get("heal_bundle", {}).get("move_id") == "heal_pulse" \
				and original.get("proposal", {}).get("hp_before") == before.get("hp") \
				and original.get("proposal", {}).get("hp_after", 0.0) > original.get("proposal", {}).get("hp_before", 0.0) \
				and original.get("committed") == true and original.get("presented") == true \
				and row.get("creature_uid") == uid and row.get("receipt") != before.get("row", {}).get("receipt") \
				and row.get("receipt", {}).get("encounter_id") == str(target.encounter_id) \
				and after.get("disk", {}).get("hp") == row.get("hp") and after.get("hp") == row.get("hp") \
				and after.get("disk_marker", {}).get("receipt") == row.get("receipt") and after.get("disk_marker", {}).get("hp") == row.get("hp") \
				and after.get("marker", {}).get("receipt") == row.get("receipt") and after.get("marker", {}).get("status") == "settled" \
				and after.get("saved_bool_seen") == true and after.get("feedback_seen") == true and after.get("awaiting") == false:
				completed = true
				heal_action = str(original.get("heal_bundle", {}).get("effect", {}).get("receipt", {}).get("action_id", ""))
		if completed: break
		await step(1, "wait", {"frames":15})
	print("HEAL actual completion observation: ", JSON.stringify({"owner":after, "host":host}))
	check(completed, "Heal: one canonical positive heal saves its exact owner receipt before Manager completion")
	var exit: Dictionary = await step(1, "press", {"action":"combat_run"})
	check(exit.get("verdict") == "PASS", "Heal: normal guest disengage settles its earned mastery")
	var earned := false
	for mastery_poll: int in 40:
		var final: Dictionary = (await _cstep(1, "camp_heal_view", args)).get("observation", {})
		var old_uses: int = int(before.get("uses", {}).get("heal_pulse", 0))
		var old_receipts: Array = before.get("receipts", {}).get("heal_pulse", [])
		var new_receipts: Array = final.get("disk", {}).get("move_mastery_receipts", {}).get("heal_pulse", [])
		if int(final.get("disk", {}).get("move_mastery_uses", {}).get("heal_pulse", -1)) == old_uses + 1 \
			and new_receipts.size() == old_receipts.size() + 1 and not heal_action.is_empty() \
			and not old_receipts.has(heal_action) and new_receipts.has(heal_action):
			earned = true
			break
		await step(1, "wait", {"frames":15})
	check(earned, "Heal: actual owner disk credits exactly one new equipped Heal use after exit")


func _await_loadout(peer: int, args: Dictionary, expected: Dictionary) -> bool:
	if expected.is_empty(): return false
	for _poll: int in 40:
		var view := await _cstep(peer, "camp_loadout_view", args)
		if view.get("verdict") == "PASS" and view.get("card") == expected: return true
		await step(peer, "wait", {"frames": 15})
	return false


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
