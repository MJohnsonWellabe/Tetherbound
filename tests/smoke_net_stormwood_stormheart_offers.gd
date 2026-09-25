extends "res://tests/helpers/net_harness.gd"

# peers: 2 -- WIP, deliberately not matched by CI discovery (see below)

## WORK IN PROGRESS, parked on coordinator order until the X05 two-peer proof
## command lands. It does not pass yet and is held out of the CI `peers: 2`
## shard on purpose (the header above does not match its exact-line regex).
##
## Last run (scenario mixed, TB_SH_STOP=1): both processes boot, host and join,
## the staged Dynamo frees the Stormheart, both characters are recorded as
## participants, and the host's own offer, Yes and personal receipt pass. The
## guest's offer is refused "Stand beside the freed Stormheart" because the
## host's `remote_trainer` proxy for the guest stays at its Stormwood arrival
## (-300, 32.3, 180) while the guest stands at the core (-100, 262, 5482):
## with BOTH peers inside Stormwood the host never received the guest's moved
## `net_position` (the guest's own view also lists no remote trainers). The
## harness `teleport`-style move is the suspect as much as replication; not
## diagnosed further. Disconnect needs a >30 s ENet timeout before rejoin.
##
## ACCEPTANCE §6.1 F11-B/F11-C and card S3: live two-peer Stormheart offers,
## disconnect/reload, no duplicate grants, and the persisted Long Storm
## aftermath, Spark shrine and once-opened Waterward gate.
##
##   TB_SH_SCENARIO=mixed|reverse|both godot --headless --path . \
##       --script tests/smoke_net_stormwood_stormheart_offers.gd
##
## Two real Godot processes over ENet (the shared `net_harness.gd` coordinator;
## each peer is `tools/net/peer_runner.gd` extended by
## `tests/helpers/stormheart_peer_runner.gd`, each with its own user://).
##
## STARTING STATE (staged, disclosed): each peer's party is granted by the
## harness (`party_grant`), the Stormwood key/gate and the Act I/II, Kestrel and
## core-reached world flags are committed through the host ledger, and both
## peers enter Stormwood through `Game.enter_realm`. The Dynamo is staged at its
## fourth conduit: both peers are admitted as captain-fight fighters through
## the Dynamo's own `_add_participant()` and its own `_complete_marrow()` then
## commits Marrow through the real chapter event. The Marrow fight and the
## Break are NOT played here. From that point everything is production code:
## the ending's participant record and release, each peer's own offer
## Interactable, the host's claim and its world save, the real DialoguePanel
## Yes/No, the real Team tab release ceremony at five, Session drop/rejoin with
## the character file, the Waterward view, the RealmGate, the Meadows Spark
## socket, the title screen's Load of the autosave slot and the crossing into
## Tidewake.
##
## Scenario (the per-character answers; each character answers once per world):
##   mixed   host (2 creatures, space) Yes; guest (five, capacity) No
##   reverse host (five) No;            guest (five) Yes -> releases belt row 0
##   both    host (five) Yes -> releases belt row 4; guest (2, space) Yes
## The guest always answers after a process-kill disconnect while its offer is
## open, then a relaunch and rejoin.

const RUNNER := "res://tests/helpers/stormheart_peer_runner.gd"
const ENDING := preload("res://scripts/world/stormwood_ending.gd")
const MEADOWS := "meadows"
const STORMWOOD := "stormwood"
const REALM_STEP_BUDGET := 10000
const STAGED_WORLD_FLAGS := ["realm_key_stormwood", "realm_gate_stormwood_unlocked",
	"stormwood:act_i_complete", "stormwood:act_ii_complete", "stormwood:all_rods_disabled",
	"stormwood:ember_bivouac_reached", "stormwood:kestrel_defeated", "stormwood:core_reached"]
const SPACE_PARTY := ["bramblebun", "mudsnout"]
const FULL_PARTY := ["bramblebun", "mudsnout", "sparkit", "terrapup", "ripplet"]
const AFTERMATH_FLAGS := ["stormwood:marrow_defeated", "stormwood:legendary_freed",
	"stormwood:legendary_offer_made", "stormwood:long_storm_ended", "realm_heart_stormwood_earned",
	"stormwood:waterward_revealed", "waterward_route_revealed", "stormwood:chapter_complete",
	"realm_gate_water_unlocked"]

var _scenario := "mixed"
var _plan := {}
var _results: Array = []
var _host_id := ""
var _guest_id := ""
var _guest_peer := 0
var _host_port := 0
var _stage := "setup"
var _live_before_reload := {}
## The whole two-session proof (two Stormwood boots, a relaunch, a full restart
## and a Tidewake crossing) is far longer than the harness's default 300 s
## step phase; this smoke's own wall bound replaces it.
const PROOF_WALL_S := 3600.0


func _initialize() -> void:
	_run()


func _run() -> void:
	heartbeat_silence_tolerance_s = 120.0
	_scenario = OS.get_environment("TB_SH_SCENARIO")
	if _scenario.is_empty():
		_scenario = "mixed"
	_plan = {
		"mixed": {"host_party": SPACE_PARTY, "host_accept": true, "host_release": -1,
			"guest_party": FULL_PARTY, "guest_accept": false, "guest_release": -1},
		"reverse": {"host_party": FULL_PARTY, "host_accept": false, "host_release": -1,
			"guest_party": FULL_PARTY, "guest_accept": true, "guest_release": 0},
		"both": {"host_party": FULL_PARTY, "host_accept": true, "host_release": 4,
			"guest_party": SPACE_PARTY, "guest_accept": true, "guest_release": -1},
	}.get(_scenario, {})
	if _plan.is_empty():
		check(false, "unknown TB_SH_SCENARIO '%s'" % _scenario)
		quit(await finish())
		return
	print("STORMHEART OFFERS scenario=%s plan=%s" % [_scenario, JSON.stringify(_plan)])
	if not await launch(2, "world"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + PROOF_WALL_S * 1000.0
	if not await _session_one():
		_summary()
		quit(await finish())
		return
	await _session_two()
	_summary()
	quit(await finish())


# --- session one: live offers, disconnect, duplicates, late joiner ----------

func _session_one() -> bool:
	for peer in 2:
		for species: String in (_plan.host_party if peer == 0 else _plan.guest_party):
			if not await _need(peer, "party_grant", {"species": species, "level": 40}):
				return false
	var host_saved := await step(0, "save_character_here")
	var guest_saved := await step(1, "save_character_here")
	_host_id = str((host_saved.get("data", {}) as Dictionary).get("character_id", ""))
	_guest_id = str((guest_saved.get("data", {}) as Dictionary).get("character_id", ""))
	if _host_id.is_empty() or _guest_id.is_empty() or _host_id == _guest_id:
		check(false, "setup: two distinct stable character ids (%s / %s)" % [_host_id, _guest_id])
		return false
	var hello: Dictionary = (_peers[0] as Dictionary).get("hello", {})
	_host_port = int(hello.get("enet_port", 0))
	if not await _need(0, "host", {"port": _host_port}):
		return false
	if not await _join_guest(_guest_id):
		return false
	for flag: String in STAGED_WORLD_FLAGS:
		if not await _need(0, "story_flag", {"flag": flag, "scope": "world"}):
			return false
	for peer in 2:
		for flag: String in STAGED_WORLD_FLAGS:
			if not await _need(peer, "wait_flag", {"flag": flag}):
				return false
	for peer in 2:
		if not await _need(peer, "enter_realm", {"realm": STORMWOOD}, REALM_STEP_BUDGET):
			return false
	if not await _await_ending(0) or not await _await_ending(1):
		return false
	var staged := await step(0, "sh_stage_dynamo", {"peers": [1, _guest_peer]})
	print("STAGE dynamo: ", staged.get("detail", ""))
	if str(staged.get("verdict", "")) != "PASS":
		check(false, "setup: the staged fourth conduit freed the Stormheart (%s)" % str(staged.get("detail", "")))
		return false
	for peer in 2:
		await _need(peer, "wait_flag", {"flag": ENDING.FREED_FLAG})
		await _need(peer, "sh_drain", {"conversation": "stormwood_stormheart_release"})
		await _need(peer, "sh_go", {"target": "StormheartOffer", "within": ENDING.OFFER_RADIUS_M})
	await step(0, "wait", {"frames": 60})
	var host := await _state(0)
	print("ACTORS host view: ", host.get("actor_offer_distance", {}), " remotes ", host.get("remote_trainers", []))
	print("ACTORS guest view: ", (await _state(1)).get("position", []), " remotes ", (await _state(1)).get("remote_trainers", []))
	var guest := await _state(1)

	# 1. Both participated and each receives their own offer.
	var participants: Array = host.get("participants", [])
	_a("1a", participants.has(_host_id) and participants.has(_guest_id) and participants.size() == 2,
		"host recorded exactly both stable characters as fight participants %s" % str(participants))
	_a("1b", (host.stormheart_uids as Array).is_empty() and (guest.stormheart_uids as Array).is_empty(),
		"neither party holds a Stormheart before answering")
	var host_offer := await step(0, "sh_offer")
	var guest_offer := await step(1, "sh_offer")
	host = await _state(0)
	guest = await _state(1)
	var claims: Dictionary = host.get("claims", {})
	var host_claim := str((claims.get(_host_id, {}) as Dictionary).get("uid", ""))
	var guest_claim := str((claims.get(_guest_id, {}) as Dictionary).get("uid", ""))
	_a("1c", str(host_offer.get("verdict", "")) == "PASS" and str(guest_offer.get("verdict", "")) == "PASS",
		"each peer's own offer Interactable opened its Stormheart offer dialogue (%s | %s)"
			% [str(host_offer.get("detail", "")), str(guest_offer.get("detail", ""))])
	_a("1d", claims.size() == 2 and not host_claim.is_empty() and not guest_claim.is_empty()
		and host_claim != guest_claim,
		"the host reserved one distinct claim per character %s" % JSON.stringify(claims))
	_a("1e", (host.offer_uids as Array).has(host_claim) and not (host.offer_uids as Array).has(guest_claim)
		and (guest.offer_uids as Array).has(guest_claim) and not (guest.offer_uids as Array).has(host_claim),
		"each peer received only its own claim (host %s, guest %s)" % [str(host.offer_uids), str(guest.offer_uids)])

	if OS.get_environment("TB_SH_STOP") == "1":
		return false
	# 2. The host answers now; the guest's answer comes after its disconnect.
	await _need(0, "sh_reset_offer_counters")
	var host_party_before: Array = _uids(host)
	var answered := await step(0, "sh_answer", {"accept": _plan.host_accept})
	print("HOST answer: ", answered.get("detail", ""))
	var ceremony := {}
	if bool(_plan.host_accept) and int(_plan.host_release) >= 0:
		ceremony = await step(0, "sh_ceremony", {"release": int(_plan.host_release)})
		print("HOST ceremony: ", ceremony.get("detail", ""))
	await step(0, "wait", {"frames": 60})
	host = await _state(0)
	_check_answer("2a", "host", host, _host_id, host_claim, bool(_plan.host_accept),
		int(_plan.host_release), host_party_before)

	# 3. Guest disconnect while its offer is open (process killed), relaunch,
	# rejoin from its character file; the same claim is owed exactly once.
	guest = await _state(1)
	_a("3a", bool(guest.panel_open) and str(guest.panel_conversation) == ENDING.OFFER_CONVERSATION
		and str(guest.local_claim) == guest_claim and (guest.answers as Array).is_empty(),
		"the guest's offer is open and unanswered when its process is killed")
	var guest_party_before: Array = _uids(guest)
	await _kill_peer(1)
	await _need(0, "expect_peers", {"count": 1}, 3600)
	host = await _state(0)
	var guest_row: Dictionary = (host.claims as Dictionary).get(_guest_id, {})
	_a("3b", str(guest_row.get("uid", "")) == guest_claim and not bool(guest_row.get("settled", true)),
		"while the guest is gone the host still holds its one unsettled claim %s" % JSON.stringify(guest_row))
	if not await _relaunch([1], {1: "world"}):
		return false
	if not await _join_guest(_guest_id):
		return false
	if not await _guest_into_stormwood():
		return false
	var reopened := await _await_panel(1)
	guest = await _state(1)
	host = await _state(0)
	_a("3c", reopened and str(guest.local_claim) == guest_claim
		and (guest.offer_uids as Array).size() >= 1 and _all_equal(guest.offer_uids, guest_claim),
		"after rejoin the host re-sent the same claim %s and the guest's offer reopened (uids %s)"
			% [guest_claim, str(guest.offer_uids)])
	_a("3d", (host.claims as Dictionary).size() == 2
		and str(((host.claims as Dictionary).get(_guest_id, {}) as Dictionary).get("uid", "")) == guest_claim,
		"the rejoin created no second claim (claims %s)" % JSON.stringify(host.claims))
	_a("3e", _uids(guest) == guest_party_before and int(guest.party_size) == (_plan.guest_party as Array).size(),
		"the relaunched guest restored its own party from disk (%d members)" % int(guest.party_size))
	await _need(1, "sh_go", {"target": "StormheartOffer", "within": ENDING.OFFER_RADIUS_M})
	await _need(1, "sh_reset_offer_counters")
	var guest_answer := await step(1, "sh_answer", {"accept": _plan.guest_accept})
	print("GUEST answer: ", guest_answer.get("detail", ""))
	if bool(_plan.guest_accept) and int(_plan.guest_release) >= 0:
		var guest_ceremony := await step(1, "sh_ceremony", {"release": int(_plan.guest_release)})
		print("GUEST ceremony: ", guest_ceremony.get("detail", ""))
	await step(1, "wait", {"frames": 90})
	guest = await _state(1)
	host = await _state(0)
	_check_answer("3f", "guest", guest, _guest_id, guest_claim, bool(_plan.guest_accept),
		int(_plan.guest_release), guest_party_before)
	_check_host_record("2b", host, _host_id, bool(_plan.host_accept))
	_check_host_record("3g", host, _guest_id, bool(_plan.guest_accept))
	_a("2c", _answer_bound(host, host_claim, bool(_plan.host_accept)) and _answer_bound(guest, guest_claim, bool(_plan.guest_accept))
		and not (host.answers as Array).any(func(a: String) -> bool: return a.contains(guest_claim))
		and not (guest.answers as Array).any(func(a: String) -> bool: return a.contains(host_claim)),
		"each answer is bound to that character's own claim (host %s, guest %s)" % [str(host.answers), str(guest.answers)])
	var snapshot_live := _snapshot(host, guest)

	# 4. No duplicate grants: double submit, host re-activation, replay after a
	# reconnect, and a late non-participant.
	var dup := await step(1, "sh_intent", {"intent": {"kind": "ending_settled", "kept": true}, "times": 2})
	await step(1, "sh_intent", {"intent": {"kind": "ending_claim", "already_accepted": false}, "times": 2})
	await step(0, "sh_intent", {"intent": {"kind": "ending_settled", "kept": not bool(_plan.host_accept)}, "times": 2})
	var host_again := await step(0, "sh_offer", {"expect_offer": false})
	host = await _state(0)
	guest = await _state(1)
	_a("4a", _snapshot(host, guest) == snapshot_live,
		"double ending_settled/ending_claim from both peers changed no claim, answer, flag or party")
	_a("4b", str(host_again.get("verdict", "")) == "PASS",
		"the host re-activating its answered offer is refused: %s" % str(host_again.get("detail", "")))
	await _need(1, "drop_link", {"settle_frames": 60})
	await _need(0, "expect_peers", {"count": 1}, 3600)
	await step(1, "leave", {"reason": "link_died"})
	await _need(1, "sh_reset_offer_counters")
	if not await _join_guest(_guest_id) or not await _guest_into_stormwood():
		return false
	await _need(1, "sh_go", {"target": "StormheartOffer", "within": ENDING.OFFER_RADIUS_M})
	await step(1, "wait", {"frames": 240})
	await step(1, "sh_intent", {"intent": {"kind": "ending_claim", "already_accepted": false}, "times": 2})
	await step(1, "sh_intent", {"intent": {"kind": "ending_settled", "kept": not bool(_plan.guest_accept)}, "times": 2})
	host = await _state(0)
	guest = await _state(1)
	_a("4c", int((guest.events as Dictionary).get("ending_offer", 0)) == 0 and not bool(guest.panel_open),
		"after a reconnect the settled guest is sent no offer (events %s)" % JSON.stringify(guest.events))
	_a("4d", _snapshot(host, guest) == snapshot_live,
		"replayed claim/settle after the reconnect granted nothing twice and changed no answer")
	# Late non-participant: the same process joins as a character who never fought.
	await _need(1, "drop_link", {"settle_frames": 60})
	await _need(0, "expect_peers", {"count": 1}, 3600)
	await step(1, "leave", {"reason": "link_died"})
	await _need(1, "wipe_character")
	var late_id := "character-f11-late-nonparticipant"
	await _need(1, "sh_reset_offer_counters")
	if not await _join_guest(late_id) or not await _guest_into_stormwood():
		return false
	await _need(1, "sh_go", {"target": "StormheartOffer", "within": ENDING.OFFER_RADIUS_M})
	var late_offer := await step(1, "sh_offer", {"expect_offer": false})
	await step(1, "wait", {"frames": 120})
	host = await _state(0)
	var late := await _state(1)
	_a("4e", str(late_offer.get("verdict", "")) == "PASS" and not (host.claims as Dictionary).has(late_id)
		and (late.stormheart_uids as Array).is_empty() and int((late.events as Dictionary).get("ending_offer", 0)) == 0
		and not (host.resolutions as Array).any(func(f: String) -> bool: return f.ends_with(late_id)),
		"a late non-participant is refused and receives nothing: %s" % str(late_offer.get("detail", "")))
	await _need(1, "drop_link", {"settle_frames": 60})
	await _need(0, "expect_peers", {"count": 1}, 3600)
	await step(1, "leave", {"reason": "link_died"})
	await _need(1, "wipe_character")
	if not await _join_guest(_guest_id) or not await _guest_into_stormwood():
		return false

	# F11-C before the save: the Waterward view, the gate opened once by the
	# guest (a remote unlock intent), and the Spark set into its Meadows socket.
	await _need(1, "sh_go", {"target": "WaterwardView", "within": ENDING.VIEW_RADIUS_M})
	var view := await step(1, "sh_prompt", {"target": "WaterwardView", "settle": 180})
	print("VIEW: ", view.get("detail", ""))
	for peer in 2:
		await _need(peer, "wait_flag", {"flag": "stormwood:waterward_revealed"})
	await _need(1, "sh_go", {"target": "WaterwardRealmGate", "offset": [0.0, 0.0, -2.0], "within": 6.0})
	var unlock := await step(1, "sh_prompt", {"target": "WaterwardRealmGate", "settle": 180})
	print("GATE unlock: ", unlock.get("detail", ""))
	for peer in 2:
		await _need(peer, "wait_flag", {"flag": "realm_gate_water_unlocked"})
	guest = await _state(1)
	_a("5a", str(guest.realm) == STORMWOOD and bool((guest.world_flags as Dictionary).get("realm_gate_water_unlocked", false))
		and not bool((guest.world_flags as Dictionary).get("realm_key_water", true)),
		"the guest's first gate use opened the Waterward gate once and consumed the Water key without travelling")
	if not await _need(1, "enter_realm", {"realm": MEADOWS}, REALM_STEP_BUDGET):
		return false
	var placed := await step(1, "sh_shrine")
	print("SHRINE: ", placed.get("detail", ""))
	for peer in 2:
		await _need(peer, "wait_flag", {"flag": "realm_heart_stormwood_placed"})

	# 5. Save to disk, then quit both processes.
	await _need(1, "save_character_here")
	await _need(0, "save_character_here")
	host = await _state(0)
	guest = await _state(1)
	_stage = "before-reload"
	_live_before_reload = {"host": host, "guest": guest}
	return true


# --- session two: both processes restarted, world loaded from disk ----------

func _session_two() -> void:
	var before_host: Dictionary = _live_before_reload.get("host", {})
	var before_guest: Dictionary = _live_before_reload.get("guest", {})
	await _stop_all()
	if not await _relaunch([0, 1], {0: "title", 1: "world"}):
		return
	var loaded := await step(0, "sh_production_load", {"port": _host_port})
	print("RELOAD host: ", loaded.get("detail", ""))
	_a("5b", str(loaded.get("verdict", "")) == "PASS",
		"the restarted host loaded the autosave from disk through the title screen: %s" % str(loaded.get("detail", "")))
	if str(loaded.get("verdict", "")) != "PASS":
		return
	await _need(0, "sh_reset_offer_counters")
	if not await _join_guest(_guest_id):
		return
	await step(1, "wait", {"frames": 240})
	await step(0, "wait", {"frames": 120})
	var host := await _state(0)
	var guest := await _state(1)
	_a("5c", str(host.realm) == STORMWOOD and str(host.world_id) == str(before_host.world_id)
		and str(host.character_id) == _host_id and str(guest.character_id) == _guest_id,
		"after restart the host is back in its Stormwood world %s and both stable characters return"
			% str(host.world_id))
	_a("5d", _uids(host) == _uids(before_host) and _uids(guest) == _uids(before_guest)
		and host.answers == before_host.answers and guest.answers == before_guest.answers
		and host.stormheart_uids == before_host.stormheart_uids and guest.stormheart_uids == before_guest.stormheart_uids,
		"each character's answer and legendary are unchanged after reload (host %s / guest %s)"
			% [str(host.stormheart_uids), str(guest.stormheart_uids)])
	_a("5e", JSON.stringify(host.claims) == JSON.stringify(before_host.claims)
		and host.resolutions == before_host.resolutions,
		"the host's saved claims and per-character world receipts are unchanged %s" % JSON.stringify(host.claims))
	_a("5f", int((host.events as Dictionary).get("ending_offer", 0)) == 0
		and int((guest.events as Dictionary).get("ending_offer", 0)) == 0
		and not bool(host.panel_open) and not bool(host.offer_prompt_enabled),
		"no re-offer after reload (host events %s, guest events %s)" % [JSON.stringify(host.events), JSON.stringify(guest.events)])
	var host_flags := _pick(host.world_flags as Dictionary)
	var guest_flags := _pick(guest.world_flags as Dictionary)
	_a("5g", host_flags == guest_flags and host_flags.values().all(func(v: bool) -> bool: return v)
		and not bool((host.world_flags as Dictionary).get("realm_key_water", true))
		and host.resolutions == guest.resolutions,
		"aftermath, Spark and once-opened gate facts are identical and set on both peers %s" % JSON.stringify(host_flags))
	_a("5h", bool(host.spark_earned) and bool(host.spark_placed) and bool(guest.spark_earned) and bool(guest.spark_placed)
		and str(guest.spark_shrine_state) in ["placed_inactive", "active"],
		"the Spark is earned and set in its Meadows socket on both peers (guest shrine '%s')" % str(guest.spark_shrine_state))
	_a("5i", not bool(host.cage_visible) and bool(host.waterward_sea_visible) and str(host.water_gate_state) == "unlocked",
		"the reloaded Stormwood shows the aftermath: containment gone, Waterward sea shown, gate state '%s'"
			% str(host.water_gate_state))
	await _need(0, "sh_go", {"target": "WaterwardRealmGate", "offset": [0.0, 0.0, -2.0], "within": 6.0})
	var crossed := await step(0, "sh_prompt", {"target": "WaterwardRealmGate", "settle": 7200, "until_realm": "water"}, 9000)
	print("GATE cross: ", crossed.get("detail", ""))
	host = await _state(0)
	_a("5j", str(host.realm) == "water" and str((crossed.get("data", {}) as Dictionary).get("scene", "")) != "Stormwood",
		"after reload a peer walks through the open Waterward gate into Tidewake: %s" % str(crossed.get("detail", "")))
	_a("5k", int(host.max_party_seen) <= 5 and int(guest.max_party_seen) <= 5,
		"no process ever held a sixth creature after reload")


# --- helpers ----------------------------------------------------------------

func _check_answer(id: String, who: String, state: Dictionary, character: String, claim: String,
		accept: bool, release: int, party_before: Array) -> void:
	var uids := _uids(state)
	var hearts: Array = state.get("stormheart_uids", [])
	var planned := party_before.size()
	if accept:
		var room := planned < 5
		var expected_size := planned + 1 if room else 5
		var kept_old: Array = party_before.duplicate()
		if not room:
			kept_old.remove_at(release)
		var others := uids.filter(func(u: String) -> bool: return u != claim)
		_a(id, hearts == [claim] and uids.size() == expected_size and others == kept_old
			and int(state.max_party_seen) <= 5 and (state.pending_catch as Dictionary).is_empty(),
			"%s Yes %s: the Stormheart %s joined; party %d -> %d%s; max seen %d"
				% [who, "with space" if room else "at five", claim, planned, uids.size(),
					"" if room else ", released only belt row %d" % release, int(state.max_party_seen)])
	else:
		_a(id, hearts.is_empty() and uids == party_before and (state.pending_catch as Dictionary).is_empty(),
			"%s No: no Stormheart, party unchanged at %d, no ceremony" % [who, uids.size()])
	_a(id + "+", _answer_bound(state, claim, accept) and bool(state.receipt_flag)
		and bool(state.accepted_flag) == accept and str(state.character_id) == character,
		"%s receipt bound to character %s: %s" % [who, character, str(state.answers)])


func _check_host_record(id: String, host: Dictionary, character: String, accept: bool) -> void:
	var row: Dictionary = (host.claims as Dictionary).get(character, {})
	var wanted := ENDING.resolution_flag(accept, character)
	var other := ENDING.resolution_flag(not accept, character)
	_a(id, bool(row.get("settled", false)) and bool(row.get("kept", not accept)) == accept
		and (host.resolutions as Array).has(wanted) and not (host.resolutions as Array).has(other),
		"host settled %s once as %s (%s)" % [character, "accepted" if accept else "refused", JSON.stringify(row)])


func _answer_bound(state: Dictionary, claim: String, accept: bool) -> bool:
	return state.answers == [ENDING.answer_flag(claim, accept)]


func _snapshot(host: Dictionary, guest: Dictionary) -> String:
	return JSON.stringify([host.claims, host.resolutions, host.answers, _uids(host), guest.answers, _uids(guest),
		_pick(host.world_flags as Dictionary)])


func _pick(flags: Dictionary) -> Dictionary:
	var out := {}
	for flag: String in AFTERMATH_FLAGS:
		out[flag] = bool(flags.get(flag, false))
	return out


func _uids(state: Dictionary) -> Array:
	var out: Array = []
	for row: Dictionary in state.get("party", []):
		out.append(str(row.get("uid", "")))
	return out


func _all_equal(values: Array, wanted: String) -> bool:
	for value: Variant in values:
		if str(value) != wanted:
			return false
	return true


func _a(id: String, condition: bool, message: String) -> void:
	_results.append({"id": id, "pass": condition, "message": message})
	check(condition, "[%s] %s" % [id, message])


func _summary() -> void:
	var passed := _results.filter(func(r: Dictionary) -> bool: return bool(r.pass)).size()
	print("STORMHEART OFFERS SUMMARY scenario=%s: %d/%d numbered assertions passed, %d harness failures"
		% [_scenario, passed, _results.size(), failures.size() - (_results.size() - passed)])


func _need(peer: int, action: String, args: Dictionary = {}, budget: int = -1) -> bool:
	var result := await step(peer, action, args, budget)
	var ok := str(result.get("verdict", "")) == "PASS"
	if not ok:
		check(false, "setup: peer %d %s: %s" % [peer, action, str(result.get("detail", ""))])
	return ok


func _state(peer: int) -> Dictionary:
	var value: Variant = await probe(peer, "sh_state")
	var out := {"claims": {}, "resolutions": [], "answers": [], "party": [], "party_size": 0,
		"stormheart_uids": [], "offer_uids": [], "events": {}, "world_flags": {}, "participants": [],
		"pending_catch": {}, "max_party_seen": 0}
	if value is Dictionary:
		out.merge(value as Dictionary, true)
	else:
		print("coordinator: peer %d sh_state probe returned nothing" % peer)
	return out


func _await_ending(peer: int) -> bool:
	for _i in 120:
		var state := await _state(peer)
		if state.has("local_claim"):
			return true
		await step(peer, "wait", {"frames": 30})
	check(false, "setup: peer %d never mounted the Stormwood ending" % peer)
	return false


func _await_panel(peer: int) -> bool:
	for _i in 60:
		var state := await _state(peer)
		if bool(state.get("panel_open", false)) and str(state.get("panel_conversation", "")) == ENDING.OFFER_CONVERSATION:
			return true
		await step(peer, "wait", {"frames": 30})
	return false


func _join_guest(character_id: String) -> bool:
	var joined := await step(1, "join", {"host": "127.0.0.1", "port": _host_port, "budget_frames": 6000,
		"character": {"character_id": character_id, "display_name": "Guest"}}, 6500)
	if str(joined.get("verdict", "")) != "PASS":
		check(false, "setup: guest join as %s: %s" % [character_id, str(joined.get("detail", ""))])
		return false
	for peer in 2:
		if not await _need(peer, "expect_peers", {"count": 2}, 1200):
			return false
	var session: Variant = await probe(1, "session")
	_guest_peer = int((session as Dictionary).get("peer_id", 0)) if session is Dictionary else 0
	return _guest_peer > 1


## A relaunched or rejoined guest whose saved realm is Stormwood stands its
## Stormwood scene through the ordinary router.
func _guest_into_stormwood() -> bool:
	var realm: Variant = await probe(1, "realm")
	if realm is Dictionary and str((realm as Dictionary).get("scene", "")) == "Stormwood":
		return await _await_ending(1)
	print("GUEST realm before Stormwood entry: ", realm)
	if not await _need(1, "enter_realm", {"realm": STORMWOOD}, REALM_STEP_BUDGET):
		return false
	return await _await_ending(1)


func _kill_peer(i: int) -> void:
	var p: Dictionary = _peers[i]
	p["quit_sent"] = true
	var pid := int(p.get("pid", -1))
	if pid > 0 and OS.is_process_running(pid):
		OS.execute("kill", ["-9", str(pid)])
	for _i in 600:
		await process_frame
		if not OS.is_process_running(pid):
			break
	p["exited"] = true
	print("coordinator: killed peer %d (pid %d) to disconnect it" % [i, pid])


func _stop_all() -> void:
	for p: Dictionary in _peers:
		if not bool(p.get("exited", false)):
			p["quit_sent"] = true
			_send_to(p, {"type": "quit", "code": 0})
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		_pump_once()
		if _peers.all(func(p: Dictionary) -> bool: return bool(p.get("exited", false))):
			break
	for p: Dictionary in _peers:
		var pid := int(p.get("pid", -1))
		if pid > 0 and OS.is_process_running(pid):
			OS.execute("kill", ["-9", str(pid)])
		p["exited"] = true
	print("coordinator: both peers quit (graceful=%s)" % str(Time.get_ticks_msec() < deadline))


## Start fresh processes for `indices` on the same user-data homes, ENet ports
## and (appended) logs, then wait for their hello.
func _relaunch(indices: Array, scenes: Dictionary) -> bool:
	var controls := CONTROL_PORTS.reserve(indices.size(), 0)
	if not bool(controls.ok):
		check(false, "setup: could not reserve relaunch control ports")
		return false
	var enet_base := enet_port_for(0)
	for n in indices.size():
		var i := int(indices[n])
		var old: Dictionary = _peers[i]
		var server: TCPServer = controls.servers[n]
		_control_servers.append(server)
		var role := "host" if i == 0 else "client"
		var pid := _spawn_peer(i, role, int(controls.ports[n]), enet_base + i, str(scenes.get(i, "world")),
			str(old.home), str(old.log_path), [])
		print("coordinator: relaunched peer %d (%s) pid=%d scene=%s" % [i, role, pid, str(scenes.get(i, "world"))])
		_peers[i] = {
			"index": i, "role": role, "server": server, "sock": null, "rx_buf": "",
			"pid": pid, "home": old.home, "log_path": old.log_path, "control_port": int(controls.ports[n]),
			"hashes": [], "hello": null, "exited": false, "unexpected_exit": false,
			"quit_sent": false, "last_heartbeat_t": 0.0, "last_heartbeat": null,
			"heartbeat_deferred_until_s": 0.0, "last_verdict": null, "last_value": null,
		}
	var deadline := Time.get_ticks_msec() + DEFAULT_HELLO_BUDGET_S * 1000.0
	while Time.get_ticks_msec() < deadline:
		await process_frame
		_pump_once()
		if indices.all(func(i: int) -> bool: return (_peers[i] as Dictionary).get("hello") != null):
			_step_phase_deadline_ms = Time.get_ticks_msec() + PROOF_WALL_S * 1000.0
			return true
	check(false, "setup: relaunched peers %s never said hello" % str(indices))
	return false


## The shared launcher, pointed at the Stormheart runner. Logs append so a
## relaunched process keeps its earlier output for the SCRIPT ERROR grep.
func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", RUNNER, "--",
		"--role=%s" % role, "--peer=%d" % i,
		"--control-port=%d" % control_port, "--enet-port=%d" % enet_port,
		"--scene=%s" % scene, "TB_NET_RUN_ID=%s" % _run_id]
	for extra in extra_args:
		args.append(str(extra))
	OS.set_environment("XDG_DATA_HOME", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", "0")
	var parts: Array[String] = [_shq(OS.get_executable_path())]
	for a in args:
		parts.append(_shq(str(a)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >>%s 2>&1" % [" ".join(parts), _shq(log_path)]])
