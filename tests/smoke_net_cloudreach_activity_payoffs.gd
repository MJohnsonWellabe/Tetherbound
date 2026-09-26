extends "res://tests/helpers/net_harness.gd"

# peers: 2 -- by hand, not in the CI net shard (two ~220 s Cloudreach builds)

## F07 #1: a second-character / peer witness for the Cloudreach activity
## payoffs (WORLD §11), two real ENet peers with distinct characters, both in
## the production Cloudreach scene.
##
##   GODOT_BIN=... tools/net/run_net_smoke.sh cloudreach_activity_payoffs
##
## Peers run `tests/smoke_net_cloudreach_activity_payoffs_peer.gd` (the proof
## peer runner plus read-only lane probes and the disclosed fixtures below).
##
## ## Activities and their declared payoff scope
##
## * `packs_on_the_wrong_side` -- chain completion `side_stranded_couriers_complete`
##   is WORLD (flag_scopes.json); the couriers' thanks (potion_small x2 plus the
##   player-scoped receipt `cloudreach_payout:couriers_thanks`) is PER
##   CHARACTER through the ledger's `reward_grant` (cloudreach_personal_reward.gd).
##   Rule asserted: the claimant gets its own, persisted in ITS character file;
##   the other character gets nothing from that claim, keeps its own offer and
##   gets its own when it claims; no second payment on repeat, forged resubmit,
##   reconnect or character reload; the world fact and the two delivery journal
##   rows are in the host world file only.
## * `aeries_of_cloudreach` -- the survey `side_aerie_high_perches_surveyed` is
##   WORLD; the payoff (a safe landing restores traversal stamina) is applied to
##   the LANDING trainer only and is never saved (cloudreach_world_payoffs.gd).
##   Rule asserted: both peers see the surveyed landing; each trainer's landing
##   rests that trainer only; an unsurveyed aerie rests nobody; no character
##   file gains any aerie state; the survey is saved in the host world only.
##
## ## Disclosed fixtures (SETUP, not earned-route proof)
##
## * Both peers boot their own Meadows world from the title (serially), take
##   `realm_key_cloudreach` in their OWN world through the ledger and cross into
##   Cloudreach through the production `Game.enter_realm` (serially), THEN host
##   and join: a peer blocked ~220 s in a Cloudreach build would drop an ENet
##   link (the F06 proof's order). Each peer gets one terrapup (`party_grant`).
## * World flags seeded on the host through the ledger (`story_flag`, world):
##   cloudreach_chapter_started, cloudreach_crisis_learned,
##   causeway_survivors_reconnected, side_courier_pack_recovered,
##   side_courier_medicine_delivered (couriers chain steps 1-2), and
##   side_aerie_high_perches_surveyed (stands in for the Fly-landing survey).
## * Step 3 (report to Neri) is the chapter's real dialogue-effect guard called
##   by the GUEST (`cr_report_to_neri`), as the solo smoke does.
## * Each claimant is teleported beside the thanks (`cr_stand_at_reward`); the
##   claim itself is the ordinary `interact` press.
## * Aerie landings: `cr_aerie_land` teleports the trainer onto the aerie floor,
##   sets its stamina to 10 and emits its own FlyController `landed` signal, as
##   the solo world-payoffs smoke does.
## * `cr_forge_claim` is an adversary: the same reward_grant intent, submitted
##   again with the offer's own gate bypassed.
## * Reconnect is `leave` + plain `join`; reload is `save_reload_here` (the
##   client re-applies its character FILE through the production character save).

const LOCAL_TOLERANCE_S := 420.0
const PEER_SCRIPT := "res://tests/smoke_net_cloudreach_activity_payoffs_peer.gd"
const BUILD_BUDGET := 20000
const CLAIMED := "cloudreach_payout:couriers_thanks"
const COMPLETE := "side_stranded_couriers_complete"
const SURVEY := "side_aerie_high_perches_surveyed"
const SETUP_WORLD_FLAGS := ["cloudreach_chapter_started", "cloudreach_crisis_learned",
	"causeway_survivors_reconnected", "side_courier_pack_recovered", "side_courier_medicine_delivered"]

var _character := ["", ""]
var _base_potions := [0, 0]
var _port := 0


func _initialize() -> void:
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
	var r := await step(peer, "cr_state")
	return r.get("data", {}) as Dictionary


func _disk(peer: int) -> Dictionary:
	var r := await step(peer, "cr_disk")
	return r.get("data", {}) as Dictionary


func _run() -> void:
	heartbeat_silence_tolerance_s = LOCAL_TOLERANCE_S
	if not await launch(2, "title"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 3600.0 * 1000.0

	# --- SETUP: two independent characters reach Cloudreach, then join ------
	for i in 2:
		if not _ok(await step(i, "boot", {"scene": "world"}, BUILD_BUDGET), "SETUP: peer %d boots its own Meadows world" % i):
			quit(await finish())
			return
	for i in 2:
		_ok(await step(i, "dismiss_dialogue", {}), "SETUP: peer %d holds the world" % i)
		_ok(await step(i, "story_flag", {"flag": "realm_key_cloudreach", "scope": "world"}), "SETUP: peer %d's own world holds the Cloudreach key" % i)
		_ok(await step(i, "party_grant", {"species": "terrapup", "level": 20}), "SETUP: peer %d owns a terrapup" % i)
	for i in 2:
		if not _ok(await step(i, "enter_realm", {"realm": "cloudreach"}, BUILD_BUDGET), "SETUP: peer %d crosses into Cloudreach" % i):
			quit(await finish())
			return
	if not _ok(await step(0, "host"), "peer 0 hosts from Cloudreach"):
		quit(await finish())
		return
	var session: Variant = await probe(0, "session")
	_port = int((session as Dictionary).get("enet_port", 0)) if session is Dictionary else 0
	if not _ok(await step(1, "join", {"host": "127.0.0.1", "port": _port}), "peer 1 joins the host"):
		quit(await finish())
		return
	for i in 2:
		_ok(await step(i, "expect_peers", {"count": 2}), "peer %d's registry holds both players" % i)
		await step(i, "dismiss_dialogue", {"settle": 10})
	var s0 := await _state(0)
	var s1 := await _state(1)
	_character = [str(s0.get("character_id", "")), str(s1.get("character_id", ""))]
	check(str(s0.get("scene", "")) == "CloudreachCliffs" and str(s1.get("scene", "")) == "CloudreachCliffs",
		"both peers stand in the production Cloudreach scene (%s / %s)" % [s0.get("scene"), s1.get("scene")])
	check(not _character[0].is_empty() and not _character[1].is_empty() and _character[0] != _character[1],
		"host and guest are distinct characters (%s / %s)" % [_character[0], _character[1]])

	for flag: String in SETUP_WORLD_FLAGS:
		_ok(await step(0, "story_flag", {"flag": flag, "scope": "world"}), "SETUP: host commits world fact %s" % flag)
	for i in 2:
		_ok(await step(i, "wait_flag", {"flag": SETUP_WORLD_FLAGS[-1], "scope": "world", "budget_frames": 600}),
			"SETUP: peer %d received the seeded chain steps" % i)
	await step(0, "wait", {"frames": 30})
	for i in 2:
		var st := await _state(i)
		_base_potions[i] = int(st.get("potions", 0))
		check(not bool(st.get("offered", true)) and not bool(st.get("claimed", true)),
			"peer %d: the thanks is not offered before Neri hears the report (%s)" % [i, JSON.stringify(st)])

	await _couriers()
	await _aeries()
	await _persistence()
	quit(await finish())


# === packs_on_the_wrong_side: world completion, per-character thanks ===========

func _couriers() -> void:
	_ok(await step(1, "cr_report_to_neri"), "the GUEST reports to Neri through the dialogue guard")
	for i in 2:
		_ok(await step(i, "wait_flag", {"flag": COMPLETE, "scope": "world", "budget_frames": 900}),
			"peer %d sees the WORLD chain completion committed once by the host" % i)
	await step(0, "wait", {"frames": 30})
	for i in 2:
		var st := await _state(i)
		check(bool(st.get("offered", false)) and not bool(st.get("claimed", true)),
			"peer %d: its own couriers' thanks is offered after the shared completion" % i)
		check(bool((st.get("people_returned", {}) as Dictionary).get("shelter_courier", false)),
			"peer %d: the shared world consequence shows (stranded pair returned to Galefoot)" % i)

	# The guest claims first.
	var stood := await step(1, "cr_stand_at_reward")
	_ok(stood, "guest stands beside the thanks")
	check(str((stood.get("data", {}) as Dictionary).get("prompt", "")).contains("couriers"),
		"guest's live prompt is the couriers' thanks ('%s')" % str((stood.get("data", {}) as Dictionary).get("prompt", "")))
	_ok(await step(1, "press", {"action": "interact"}), "guest presses interact at the thanks")
	_ok(await step(1, "wait_flag", {"flag": CLAIMED, "scope": "player", "budget_frames": 900}),
		"guest's OWN player-scoped receipt arrives")
	await step(1, "wait", {"frames": 30})
	var g := await _state(1)
	check(int(g.get("potions", -1)) == _base_potions[1] + 2,
		"guest received exactly two small potions (%d -> %d)" % [_base_potions[1], int(g.get("potions", -1))])
	check(not bool(g.get("offered", true)), "the thanks is no longer offered to the guest")
	var gd := await _disk(1)
	var gfile: Dictionary = (gd.get("characters", {}) as Dictionary).get(_character[1], {}) as Dictionary
	check(bool((gfile.get("flags", {}) as Dictionary).get(CLAIMED, false)) and int(gfile.get("potions", -1)) == _base_potions[1] + 2,
		"the guest's OWN character file holds its receipt and +2 potions, written by the production delivery (no explicit save): %s" % JSON.stringify(gfile))

	# NEGATIVE CONTROL: the host got nothing from the guest's claim.
	await step(0, "wait", {"frames": 60})
	var h := await _state(0)
	check(not bool(h.get("claimed", true)), "NEGATIVE CONTROL: the host holds NO receipt from the guest's claim")
	check(int(h.get("potions", -1)) == _base_potions[0], "NEGATIVE CONTROL: the host's potions are unchanged (%d -> %d)" % [_base_potions[0], int(h.get("potions", -1))])
	check(bool(h.get("offered", false)), "the host's own thanks is still offered (independent)")
	var control := await step(0, "assert", {"check": "flag_set", "flag": CLAIMED})
	check(str(control.get("verdict", "")) == "FAIL",
		"NEGATIVE CONTROL: 'host holds the claimed flag' is asserted and must FAIL (%s)" % str(control.get("detail", "")))

	# Repeat press and a forged resubmit pay the guest nothing more.
	await step(1, "press", {"action": "interact"})
	await step(1, "wait", {"frames": 90})
	check(int((await _state(1)).get("potions", -1)) == _base_potions[1] + 2, "a repeat interact press pays the guest nothing more")
	var forged := await step(1, "cr_forge_claim")
	var fd: Dictionary = forged.get("data", {}) as Dictionary
	check(str(fd.get("code", "")) == "already_taken" and int(fd.get("potions_after", -1)) == _base_potions[1] + 2,
		"NEGATIVE CONTROL: a forged second reward_grant from the guest is refused 'already_taken' and pays nothing (%s)" % str(forged.get("detail", "")))

	# The host claims its own.
	stood = await step(0, "cr_stand_at_reward")
	_ok(stood, "host stands beside the thanks")
	_ok(await step(0, "press", {"action": "interact"}), "host presses interact at the thanks")
	_ok(await step(0, "wait_flag", {"flag": CLAIMED, "scope": "player", "budget_frames": 900}),
		"host's OWN player-scoped receipt arrives")
	await step(0, "wait", {"frames": 30})
	h = await _state(0)
	check(int(h.get("potions", -1)) == _base_potions[0] + 2,
		"host received its own two small potions (%d -> %d)" % [_base_potions[0], int(h.get("potions", -1))])
	check(not bool(h.get("offered", true)), "the thanks is no longer offered to the host")
	await step(1, "wait", {"frames": 60})
	g = await _state(1)
	check(int(g.get("potions", -1)) == _base_potions[1] + 2,
		"NEGATIVE CONTROL: the host's claim did not pay the guest again (%d)" % int(g.get("potions", -1)))
	forged = await step(0, "cr_forge_claim")
	fd = forged.get("data", {}) as Dictionary
	check(str(fd.get("code", "")) == "already_taken" and int(fd.get("potions_after", -1)) == _base_potions[0] + 2,
		"NEGATIVE CONTROL: a forged second reward_grant from the host is refused and pays nothing (%s)" % str(forged.get("detail", "")))


# === aeries_of_cloudreach: world survey, per-trainer transient rest ===========

func _aeries() -> void:
	_ok(await step(0, "story_flag", {"flag": SURVEY, "scope": "world"}), "SETUP: host commits the High Perches survey (world)")
	for i in 2:
		_ok(await step(i, "wait_flag", {"flag": SURVEY, "scope": "world", "budget_frames": 600}), "peer %d received the survey" % i)
	await step(0, "wait", {"frames": 30})
	var rests := [0, 0]
	for i in 2:
		var st := await _state(i)
		var markers: Dictionary = st.get("markers", {}) as Dictionary
		check(bool(markers.get("high_perches", false)) and not bool(markers.get("observatory", true)),
			"peer %d draws the surveyed High Perches landing and not the unsurveyed Observatory (%s)" % [i, JSON.stringify(markers)])
		rests[i] = int(st.get("aerie_rests", -1))

	# CONTROL first, while the guest's safe anchor is still the low arrival
	# road: on the first run the guest had already stood on the 1020 m High
	# Perches, so Cloudreach's grounded-fall recovery (>100 m below the safe
	# anchor) carried it back there from the 920 m Observatory before the
	# landing fired. `at_marker` now proves where the landing happened.
	var unsurveyed := await step(1, "cr_aerie_land", {"id": "observatory"})
	var ud: Dictionary = unsurveyed.get("data", {}) as Dictionary
	check(bool(ud.get("at_marker", false)) and not bool(ud.get("marker_visible", true))
			and int(ud.get("rests_after", -1)) == int(ud.get("rests_before", -2)) and float(ud.get("stamina_after", 99.0)) < 11.0,
		"CONTROL: a landing ON the UNSURVEYED Observatory aerie rests nobody (%s)" % str(unsurveyed.get("detail", "")))
	var land := await step(1, "cr_aerie_land", {"id": "high_perches"})
	var ld: Dictionary = land.get("data", {}) as Dictionary
	check(bool(ld.get("on_floor", false)) and bool(ld.get("at_marker", false)) and int(ld.get("rests_after", -1)) == int(ld.get("rests_before", -2)) + 1
			and float(ld.get("stamina_after", 0.0)) >= float(ld.get("max_stamina", 1.0)) - 0.01,
		"the GUEST's landing on the surveyed aerie restores the guest's stamina (%s)" % str(land.get("detail", "")))
	var h := await _state(0)
	check(int(h.get("aerie_rests", -1)) == rests[0],
		"NEGATIVE CONTROL: the guest's landing gave the HOST no rest (host rests %d -> %d)" % [rests[0], int(h.get("aerie_rests", -1))])
	var guest_rests := int((await _state(1)).get("aerie_rests", -1))
	land = await step(0, "cr_aerie_land", {"id": "high_perches"})
	ld = land.get("data", {}) as Dictionary
	check(int(ld.get("rests_after", -1)) == int(ld.get("rests_before", -2)) + 1
			and float(ld.get("stamina_after", 0.0)) >= float(ld.get("max_stamina", 1.0)) - 0.01,
		"the HOST's own landing on the same aerie rests the host (%s)" % str(land.get("detail", "")))
	check(int((await _state(1)).get("aerie_rests", -1)) == guest_rests,
		"NEGATIVE CONTROL: the host's landing gave the guest no rest")


# === saved state, reconnect and reload ======================================

func _persistence() -> void:
	# Explicit save of each side's own data (host: autosave = world + host
	# character; client: character only, which is the production rule).
	_ok(await step(0, "save_character_here"), "host saves (world + its character)")
	_ok(await step(1, "save_character_here"), "guest saves its own character")
	var hd := await _disk(0)
	var gd := await _disk(1)
	print("HOST DISK: " + JSON.stringify(hd))
	print("GUEST DISK: " + JSON.stringify(gd))
	var host_worlds: Dictionary = hd.get("worlds", {}) as Dictionary
	var holding := 0
	var recipients: Array = []
	for id: String in host_worlds:
		var w: Dictionary = host_worlds[id]
		if bool((w.get("flags", {}) as Dictionary).get(COMPLETE, false)):
			holding += 1
			check(bool((w.get("flags", {}) as Dictionary).get(SURVEY, false)), "host world '%s' saved the aerie survey" % id)
			check(not bool((w.get("flags", {}) as Dictionary).get(CLAIMED, true)), "host world '%s' holds no personal receipt flag" % id)
			for row: Variant in (w.get("couriers_deliveries", []) as Array):
				recipients.append(str((row as Dictionary).get("character_id", "")))
	check(holding == 1, "exactly one host world file holds the chain completion (%d)" % holding)
	recipients.sort()
	var want := _character.duplicate()
	want.sort()
	check(recipients == want,
		"the host world journals exactly one couriers' delivery per character, host and guest (%s)" % str(recipients))
	var guest_world_facts := 0
	for id: String in (gd.get("worlds", {}) as Dictionary):
		var w: Dictionary = (gd.get("worlds", {}) as Dictionary)[id]
		if bool((w.get("flags", {}) as Dictionary).get(COMPLETE, false)) or bool((w.get("flags", {}) as Dictionary).get(SURVEY, false)):
			guest_world_facts += 1
	check(guest_world_facts == 0, "no GUEST-side world file holds the shared activity state (the host saves the world once)")
	for pair: Array in [[hd, 0], [gd, 1]]:
		var disk: Dictionary = pair[0]
		var i: int = pair[1]
		var file: Dictionary = (disk.get("characters", {}) as Dictionary).get(_character[i], {}) as Dictionary
		var flags: Dictionary = file.get("flags", {}) as Dictionary
		check(bool(flags.get(CLAIMED, false)) and int(file.get("potions", -1)) == _base_potions[i] + 2,
			"peer %d's OWN character file: its receipt and exactly +2 potions (%s)" % [i, JSON.stringify(file)])
		check(not bool(flags.get(COMPLETE, true)) and not bool(flags.get(SURVEY, true)),
			"peer %d's character file carries no world activity state" % i)
		check(not (disk.get("characters", {}) as Dictionary).has(_character[1 - i]),
			"peer %d holds no file for the other character" % i)

	# Reconnect: the guest leaves and rejoins with the same character.
	_ok(await step(1, "leave", {"reason": "f07_reconnect"}), "guest leaves")
	_ok(await step(0, "expect_peers", {"count": 1}, 900), "host sees the guest gone")
	_ok(await step(1, "join", {"host": "127.0.0.1", "port": _port}), "guest rejoins")
	for i in 2:
		_ok(await step(i, "expect_peers", {"count": 2}), "peer %d sees both after the rejoin" % i)
	await step(1, "wait", {"frames": 180})
	var g := await _state(1)
	check(str(g.get("character_id", "")) == _character[1], "the guest rejoined as the same character")
	check(bool(g.get("claimed", false)) and int(g.get("potions", -1)) == _base_potions[1] + 2 and not bool(g.get("offered", true)),
		"after reconnect: guest keeps its receipt, exactly +2 potions, no new offer (%s)" % JSON.stringify(g))
	check(bool((g.get("world", {}) as Dictionary).get(COMPLETE, false)) and bool((g.get("markers", {}) as Dictionary).get("high_perches", false)),
		"after reconnect: the rejoined guest still sees the shared world state")

	# Reload from disk.
	_ok(await step(1, "save_reload_here"), "guest re-applies its character FILE")
	await step(1, "wait", {"frames": 60})
	g = await _state(1)
	check(bool(g.get("claimed", false)) and int(g.get("potions", -1)) == _base_potions[1] + 2 and not bool(g.get("offered", true)),
		"after character reload: guest keeps exactly one payment and no offer (%s)" % JSON.stringify(g))
	_ok(await step(0, "save_reload_here", {}, BUILD_BUDGET), "host reloads its autosave (world + character)")
	await step(0, "wait", {"frames": 60})
	var h := await _state(0)
	check(bool(h.get("claimed", false)) and int(h.get("potions", -1)) == _base_potions[0] + 2 and not bool(h.get("offered", true)),
		"after host reload: host keeps exactly one payment and no offer (%s)" % JSON.stringify(h))
	check(bool((h.get("world", {}) as Dictionary).get(COMPLETE, false)) and bool((h.get("world", {}) as Dictionary).get(SURVEY, false)),
		"after host reload: the world still holds the chain completion and the survey")
	await step(1, "wait", {"frames": 60})
	check(int((await _state(1)).get("potions", -1)) == _base_potions[1] + 2, "the host's reload re-delivered nothing to the guest")
