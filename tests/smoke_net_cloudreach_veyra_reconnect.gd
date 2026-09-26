extends "res://tests/smoke_net_proof_two_peer.gd"

# peers: 2 -- MANUAL (about 20 min; the fix is covered by tests/test_cloudreach_director_client_veyra.gd in CI; run by hand: tools/net/run_net_smoke.sh cloudreach_veyra_reconnect)

## F08 #2 reconnect witness: a GUEST's Veyra win is journaled once in the HOST
## world, never written into the guest's own stores, and survives the guest
## dropping and rejoining -- with no double grant.
##
##   tools/net/run_net_smoke.sh cloudreach_veyra_reconnect
##
## The two-peer proof runner (`tests/smoke_net_proof_two_peer.gd`, whose step
## table and report this reuses) with three lane-local differences:
##   * the scenario is below, not a JSON file (TB_PROOF_SCENARIO is not needed);
##   * each peer runs `tests/smoke_net_cloudreach_veyra_peer.gd` (the proof peer
##     runner plus one fixture action and one probe -- see its header);
##   * a longer heartbeat-silence tolerance, for the reason
##     `tests/smoke_cloudreach_rejoin_closed_gate_proof.gd` gives: building
##     Cloudreach blocks a peer's heartbeat for minutes on the 4-core container.
##
## Setup stand-ins (disclosed): world flags through the ledger (`story_flag`)
## stand in for playing to Cloudreach and to Veyra's arena (her three
## `requires_flags`, seeded on the HOST world only). The fight itself is a
## fixture: the guest's production director runs its final-round victory hook
## (`_record_trainer_defeat`) for Veyra's authored spec. Route, wire, host
## journal, delta, save, drop and rejoin are the game's own code. Loopback ENet:
## local evidence, not internet/Steam acceptance.
##
## NEGATIVE CONTROLS: (1) before the win both peers read Veyra unbeaten; (2) the
## same same-frame probe, run on main's unfixed client route for another trainer
## (Ila), DOES see a local world-flag write -- so "no local write" for Veyra is a
## check that can fail; (3) the host's saved world DOES name the flag, so the
## guest character file's "does not name it" can fail.

const VEYRA := "captain_veyra_storm_anchor"
const VEYRA_FLAG := "captain_veyra_defeated"
const CONTROL_TRAINER := "trainer_ila_lower_ring"
const VEYRA_PREREQUISITES := ["cloudreach_act_ii_complete", "cloudreach_upper_anchors_disabled",
	"summit_extraction_engine_reached"]
const VEYRA_COINS := 150
const VEYRA_CANDY := 1
const SILENCE_TOLERANCE_S := 420.0
const PEER_SCRIPT := "res://tests/smoke_net_cloudreach_veyra_peer.gd"

var _before: Dictionary = {}
var _after_win: Dictionary = {}
var _guest_character := ""


func _initialize() -> void:
	heartbeat_silence_tolerance_s = SILENCE_TOLERANCE_S
	super._initialize()


func _scenario() -> Dictionary:
	var steps: Array = [
		{"peer": "all", "action": "boot", "args": {"scene": "world"}, "budget_frames": 20000,
			"label": "each peer boots its own fresh Meadows world"},
		{"peer": "all", "action": "story_flag", "args": {"flag": "realm_key_cloudreach", "scope": "world"},
			"label": "setup: both worlds hold the Cloudreach key"},
		{"peer": 0, "action": "enter_realm", "args": {"realm": "cloudreach"}, "budget_frames": 20000,
			"label": "host enters Cloudreach"},
		{"peer": 1, "action": "enter_realm", "args": {"realm": "cloudreach"}, "budget_frames": 20000,
			"label": "guest enters Cloudreach in its own world"},
		{"peer": 1, "action": "save_character_here", "label": "guest saves its portable character in Cloudreach"},
		{"peer": 0, "action": "host"},
		{"peer": 1, "action": "production_join", "args": {"returning_route": false, "budget_frames": 20000},
			"budget_frames": 20000, "label": "guest continues its own save into the host's world"},
		{"peer": "all", "action": "expect_peers", "args": {"count": 2}},
		{"peer": 1, "probe": "player_identity", "expect_data": {"realm": "cloudreach"},
			"label": "guest stands in Cloudreach"},
	]
	for flag: String in VEYRA_PREREQUISITES:
		steps.append({"peer": 0, "action": "story_flag", "args": {"flag": flag, "scope": "world"},
			"label": "setup (host world): Veyra prerequisite %s" % flag})
	steps.append_array([
		{"peer": 1, "action": "wait_flag", "args": {"flag": VEYRA_PREREQUISITES[-1], "scope": "world"},
			"label": "the guest reads the host's prerequisites"},
		{"peer": 0, "action": "assert", "args": {"check": "flag_set", "flag": VEYRA_FLAG}, "expect": "FAIL",
			"label": "CONTROL: host world has Veyra unbeaten before the win"},
		{"peer": 1, "action": "assert", "args": {"check": "flag_set", "flag": VEYRA_FLAG}, "expect": "FAIL",
			"label": "CONTROL: guest reads Veyra unbeaten before the win"},
		{"custom": "before"},
		{"peer": 1, "action": "veyra_client_win", "args": {"trainer": CONTROL_TRAINER, "mode": "base"},
			"expect_data": {"local_flag_same_frame": true, "had_flag": false},
			"label": "NEGATIVE CONTROL: main's unfixed client route (Ila) writes the world flag locally in the same frame"},
		{"peer": 1, "action": "veyra_client_win", "args": {"trainer": VEYRA},
			"expect_data": {"had_flag": false, "local_flag_same_frame": false, "world_store_writes_same_frame": 0,
				"sent_to_host": true, "victory_emits": 1},
			"label": "guest wins Veyra: one trainer_victory in flight, nothing written locally"},
		{"peer": 1, "action": "wait_flag", "args": {"flag": VEYRA_FLAG, "scope": "world", "budget_frames": 1800},
			"label": "Veyra's flag reaches the guest with the host's delta"},
		{"peer": 0, "action": "assert", "args": {"check": "flag_set", "flag": VEYRA_FLAG},
			"label": "host world holds Veyra's defeat"},
		{"custom": "after_win"},
		{"peer": 1, "action": "save_character_here", "label": "guest saves its portable character"},
		{"custom": "character_file"},
		{"peer": 1, "action": "drop_link", "label": "guest's link drops"},
		{"peer": 0, "action": "expect_peers", "args": {"count": 1}, "budget_frames": 1800},
		{"peer": 1, "action": "join", "args": {}, "label": "guest rejoins (reclaims its held seat)"},
		{"peer": "all", "action": "expect_peers", "args": {"count": 2}},
		{"peer": 1, "action": "wait_flag", "args": {"flag": VEYRA_FLAG, "scope": "world", "budget_frames": 1800},
			"label": "REJOIN: the guest reads Veyra's defeat from the host's world"},
		{"peer": 1, "probe": "player_identity", "expect_data": {"realm": "cloudreach"},
			"label": "REJOIN: guest's session still names realm cloudreach (title-level reseat; the Cloudreach scene is NOT rebuilt, so this is not a walk back into the realm)", "continue_on_fail": true},
		# (No repeat-win step here: the stock `join` step reseats the dropped
		# guest from the TITLE without rebuilding its realm scene, so no
		# Cloudreach director exists to drive -- run 2026-09-26T053151Z. The
		# no-double-grant proof is the host journal and the guest satchel below.)
		{"peer": 1, "action": "wait", "args": {"frames": 240}},
		{"custom": "after_rejoin"},
		{"peer": 1, "action": "save_character_here", "label": "guest saves again after the rejoin"},
		{"custom": "character_file"},
		{"peer": 0, "action": "save_world", "args": {}, "label": "host saves its world"},
		{"peer": "all", "action": "capture_saves", "args": {"label": "final"}},
		{"peer": 0, "action": "check_saved", "args": {"label": "final", "dir": "worlds", "contains": [VEYRA_FLAG]},
			"label": "CONTROL: the host's saved world names Veyra's defeat"},
		{"peer": 1, "action": "check_saved", "args": {"label": "final", "dir": "characters", "lacks": [VEYRA_FLAG]},
			"label": "the guest's saved character holds no copy of the world flag"},
	])
	return {"name": "F08 #2: guest Veyra win journaled once in the host world, through drop and rejoin",
		"claim": "ACCEPTANCE F08: Veyra's win persists through two-peer reconnect without double grants; a client-run trainer win goes through the host-journaled trainer_victory route and never a local world-flag write.",
		"peers": 2, "scene": "title", "budget_s": 3600, "steps": steps}


func _run() -> void:
	_proof_out = OS.get_environment("TB_PROOF_OUT")
	if _proof_out.is_empty():
		_proof_out = OS.get_environment("TB_NET_OUT_DIR")
	var s := _scenario()
	var peers := int(s["peers"])
	_host_peer = 0
	if not await launch(peers, str(s["scene"])):
		await _end(s, "tests/smoke_net_cloudreach_veyra_reconnect.gd")
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + float(s["budget_s"]) * 1000.0
	var index := 0
	for entry: Dictionary in (s["steps"] as Array):
		index += 1
		if entry.has("custom"):
			if not await _custom(str(entry["custom"])):
				break
			continue
		var stop := false
		for peer: int in _targets(entry.get("peer", 0), peers):
			if not await _run_entry(index, peer, entry) and not bool(entry.get("continue_on_fail", false)):
				stop = true
				break
		if stop:
			break
	await _end(s, "tests/smoke_net_cloudreach_veyra_reconnect.gd")


func _state(peer: int) -> Dictionary:
	var value: Variant = await probe(peer, "veyra_state", {})
	return value if value is Dictionary else {}


func _count(rows: Variant, character: String) -> int:
	var n := 0
	for raw: Variant in (rows as Array):
		if raw is Dictionary and str((raw as Dictionary).get("character_id", "")) == character:
			n += 1
	return n


func _item(state: Dictionary, id: String) -> int:
	return int((state.get("items", {}) as Dictionary).get(id, 0))


func _custom(name: String) -> bool:
	match name:
		"before":
			_before = await _state(1)
			_guest_character = str(_before.get("character_id", ""))
			var host := await _state(0)
			check(not _guest_character.is_empty(), "the guest has a stable character id (%s)" % _guest_character)
			check(int(host.get("journal_count", -1)) == 0 and int(_before.get("journal_count", -1)) == 0,
				"CONTROL: no Veyra journal rows anywhere before the win (host %s, guest %s)"
					% [str(host.get("journal_count")), str(_before.get("journal_count"))])
			return not _guest_character.is_empty()
		"after_win":
			var host := await _state(0)
			for _i in 600:
				if _count(host.get("journal_rows", []), _guest_character) >= 2:
					break
				await physics_frame
				if _i % 60 == 59:
					host = await _state(0)
			_after_win = await _state(1)
			check(bool(host.get("world_flag", false)), "host: Veyra's defeat is a WORLD flag in the host world")
			check(not bool(host.get("player_flag", true)), "host: not a player flag")
			check(_count(host.get("journal_rows", []), _guest_character) == 2,
				"host journal: exactly 2 Veyra rows (coins, rare candy) for the guest's character (%s)"
					% JSON.stringify(host.get("journal_rows", [])))
			check(int(host.get("journal_count", -1)) == 2,
				"host journal: no Veyra row for anybody else (%d rows)" % int(host.get("journal_count", -1)))
			check(bool(_after_win.get("world_flag", false)) and not bool(_after_win.get("player_flag", true)),
				"guest: the flag sits in its mirror of the host world, not in its player store")
			var coins := _item(_after_win, "coin") - _item(_before, "coin")
			var candy := _item(_after_win, "rare_candy") - _item(_before, "rare_candy")
			# The Ila control's own payout lands in coin too; count candy for
			# Veyra alone (Ila pays no rare candy) and bound coin from below.
			check(candy == VEYRA_CANDY, "guest satchel: Veyra's %d rare candy landed exactly once (got %d)"
				% [VEYRA_CANDY, candy])
			check(coins >= VEYRA_COINS, "guest satchel: Veyra's %d coin landed (got +%d incl. the Ila control)"
				% [VEYRA_COINS, coins])
			return true
		"character_file":
			var guest := await _state(1)
			check(bool(guest.get("character_file_exists", false)),
				"the guest's character file exists (%s)" % str(guest.get("character_file", "")))
			check(not bool(guest.get("character_file_mentions_flag", true)),
				"the guest's own character file holds no copy of %s" % VEYRA_FLAG)
			return true
		"after_rejoin":
			var host := await _state(0)
			var guest := await _state(1)
			check(str(guest.get("character_id", "")) == _guest_character, "the same character rejoined")
			check(bool(guest.get("world_flag", false)), "REJOIN: the guest still reads Veyra beaten from the host")
			check(_count(host.get("journal_rows", []), _guest_character) == 2 and int(host.get("journal_count", -1)) == 2,
				"REJOIN: still exactly 2 Veyra journal rows in the host world (%s)"
					% JSON.stringify(host.get("journal_rows", [])))
			check(_item(guest, "coin") == _item(_after_win, "coin") and _item(guest, "rare_candy") == _item(_after_win, "rare_candy"),
				"REJOIN: no double grant (coin %d->%d, rare candy %d->%d)" % [_item(_after_win, "coin"),
					_item(guest, "coin"), _item(_after_win, "rare_candy"), _item(guest, "rare_candy")])
			return true
	check(false, "unknown custom step %s" % name)
	return false


func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var exe := OS.get_executable_path()
	var project_path := ProjectSettings.globalize_path("res://")
	var args: Array = ["--headless", "--path", project_path]
	if _is_windows():
		args.append_array(["--log-file", log_path])
	args.append_array([
		"--script", PEER_SCRIPT, "--",
		"--role=%s" % role, "--peer=%d" % i,
		"--control-port=%d" % control_port, "--enet-port=%d" % enet_port,
		"--scene=%s" % scene,
		"TB_NET_RUN_ID=%s" % _run_id,
	])
	for extra in extra_args:
		args.append(str(extra))
	OS.set_environment("XDG_DATA_HOME", home)
	if _is_windows():
		OS.set_environment("APPDATA", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", OS.get_environment("TB_NET_WORLD_SEED") \
		if not OS.get_environment("TB_NET_WORLD_SEED").is_empty() else "0")
	if _is_windows():
		return OS.create_process(exe, args)
	var parts: Array[String] = [_shq(exe)]
	for a in args:
		parts.append(_shq(str(a)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" % [" ".join(parts), _shq(log_path)]])
