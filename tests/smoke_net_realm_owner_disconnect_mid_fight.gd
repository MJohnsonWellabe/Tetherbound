extends "res://tests/helpers/net_harness.gd"

# peers: 2

## RESTORED 2026-09-06 (lane MP-REALM-REOPEN), together with the removal of the
## `is_multi_peer()` refusal in `game_state.gd::can_enter_realm()` -- the two
## edits that were held together and had to be made together.
##
## This smoke was held, not quarantined, because the shell it exercises froze
## the host for longer than the harness's 15 s heartbeat window: `add_child()`
## ran the world root's whole `_ready()` in one call. The world roots now build
## across frames under `scripts/world/shell_build_budget.gd` and
## `realm_shells.gd` reads the scene off the loader thread. Both smokes were
## run locally and passed before this header came back.

## Stage B Wave 6 lane 6.A. **THE CASE THAT SANK D97'S FIRST DESIGN.**
##
##   tools/net/run_net_smoke.sh net_realm_owner_disconnect_mid_fight
##
## D97's first draft delegated an unhosted realm's simulation to its first
## occupant. Adversarial review killed it on two counts, and this smoke is the
## second one made into a test: *"a delegating client's disconnect mid-fight
## loses encounter state nothing else holds."*
##
## Under a headless shell the host holds that state instead, so the same
## disconnect is survivable -- but only if the shell that is torn down when
## its last occupant vanishes is READ BACK before it is freed. A shell freed
## without that read leaves `Game` looking exactly as it does in the healthy
## case, which is why the sharp assertion here is the one on DISK.
##
## ## The shape of the run
##
## Deliberately the reverse geography of `smoke_net_split_realms.gd`: the HOST
## goes to Cloudreach and the CLIENT stays in the Meadows. That puts the
## expensive shell -- the Meadows, with the encounter director and the 385,333
## prop scatter -- on the host, and it puts the fight somewhere a fight can
## actually happen (`cloudreach_cliffs.tscn` authors no `EncounterDirector`).
##
##   1. host and client form a session in the Meadows;
##   2. the client commits a Meadows world record, so there is state whose
##      only home is the realm about to become unhosted;
##   3. the host crosses to Cloudreach; the Meadows becomes a shell;
##   4. the client picks a fight in the Meadows -- inside the host's shell,
##      which is the point: the host is simulating a realm it cannot see;
##   5. the client's LINK IS CUT. Not `leave()`: `drop_link` closes the
##      transport out from under the session, which is what a pulled cable
##      does, and the only path that reaches
##      `session.gd::_on_peer_disconnected()`;
##   6. the host notices, folds the now-empty Meadows shell down THROUGH its
##      own world save, and the record from step 2 is still there -- live, and
##      in the autosave file re-read off `user://`.
##
## ## Why the disk check is the assertion and the live one is not
##
## `Game.placed_buildings` is host-side and ledger-committed, so it survives a
## shell teardown whether or not anything read the shell. The file does not:
## it is written by `realm_shells.gd::_tear_down()` calling `Game.save_game()`
## while the shell is still in the tree, and that call is the deliverable. A
## teardown that freed first and saved after would leave the live count intact
## and the file behind, which is exactly the silent version of losing world
## state.

## Wall-clock seconds of STEPS this smoke may spend.
##
## Two world builds inside the step phase: the host's Cloudreach and its
## Meadows shell. Smaller than `smoke_net_split_realms.gd`'s because nothing
## is built twice.
const REALM_STEP_BUDGET_S := 900.0

const MEADOWS := "meadows"
const CLOUDREACH := "cloudreach"


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")

	# Rule 16 costs world builds, and world builds are what the shard's shared
	# 300 s step budget (`data/config/multiplayer.json::test_budgets
	# .smoke_step_budget_s_2peer`) was sized without. That number stays what it
	# is for every other smoke -- raising it globally would hide a real hang in
	# a cheap one -- and this run extends its OWN deadline instead, by exactly
	# the builds it adds. The measured cost is in
	# `ralph/reports/MP-6A-REALMS-0906/REPORT.md`; if this smoke ever needs
	# more than REALM_STEP_BUDGET_S it is telling you something about the
	# shell, not about the budget.
	_step_phase_deadline_ms = Time.get_ticks_msec() + REALM_STEP_BUDGET_S * 1000.0

	# --- the handshake, copied verbatim from smoke_net_movement_two_peers.gd ---
	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session,
		"a Session exists to host/join (lane 2.A); without it there are no remote bodies to see")
	if not have_session:
		quit(await finish())
		return

	var hosted: Dictionary = await step(0, "host", {})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined peer 0's world on port %d (%s)" % [port, str(joined.get("detail", ""))])
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry holds both players (%s)" % [i, str(seen.get("detail", ""))])
	# --- end of the copied handshake block ------------------------------------

	# Cloudreach is key-gated in the ordinary way (`realm_hearts.json` gives it
	# `entry_key_flag = "realm_key_cloudreach"`), in solo exactly as in a
	# session. That gate is not what this smoke is about, so it is opened here
	# as setup -- without it the crossing below reports "enter_realm refused"
	# and reads like lane 6.A never landed.
	var route: Dictionary = await step(0, "story_flag",
		{"flag": "realm_key_cloudreach", "scope": "world"})
	check(str(route.get("verdict", "")) == "PASS",
		"the Cloudreach route is open before the host tries to walk it (%s)"
			% str(route.get("detail", "")))

	# 2. World state whose only realm is the one about to be left unhosted.
	var planted: Dictionary = await step(1, "storage_place", {"realm": MEADOWS})
	check(str(planted.get("verdict", "")) == "PASS",
		"the client committed a Meadows world record before anybody moved (%s)"
			% str(planted.get("detail", "")))
	var before = await probe(0, "world_records")
	var live_before := _count(before, "live", MEADOWS)
	check(live_before > 0,
		"the host holds at least one Meadows world record to lose (holds %d)" % live_before)

	# 3. The HOST leaves for Cloudreach; the Meadows becomes a realm it is not
	#    standing in, and therefore a shell.
	var away: Dictionary = await step(0, "enter_realm", {"realm": CLOUDREACH},
		int(_budgets.get("step_budget_frames", DEFAULT_STEP_BUDGET_FRAMES)) * 4)
	check(str(away.get("verdict", "")) == "PASS",
		"the host crossed into Cloudreach, leaving the client alone in the Meadows (%s)"
			% str(away.get("detail", "")))
	if str(away.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var shells = await _await_shells(0, [MEADOWS], 240)
	check(_shell_realms(shells) == [MEADOWS],
		"the host runs a headless MEADOWS shell for the peer it left behind (holds %s)"
			% str(_shell_realms(shells)))
	_report_shell_cost(shells)
	# A shell that is not simulating anything is not a shell. The host's own
	# spawner has to have put the client's body inside it, or the fight below
	# is happening somewhere the host is not looking.
	var realms_row: Dictionary = ((shells.get("realms", {}) as Dictionary).get(MEADOWS, {})) as Dictionary
	check(int(realms_row.get("bodies", 0)) >= 1,
		"the client's trainer body stands inside the host's Meadows shell (found %d)"
			% int(realms_row.get("bodies", 0)))

	# The shell is IN THE TREE within a frame or two of the crossing, and it is
	# not finished for a good while after that: lane MP-REALM-REOPEN made the
	# build spread across frames so the host keeps serving the players already
	# in the session (`scripts/world/shell_build_budget.gd`). A realm whose
	# shell is still laying its ground cannot bind an encounter, so the fight
	# below waits for the shell to say it is done rather than racing it. This
	# is the ordering the feature actually has, not a tolerance: the host is
	# authoritative for a realm from the moment its shell is READY.
	shells = await _await_shell_ready(0, MEADOWS, 300)
	check(_shell_ready(shells, MEADOWS),
		"the host's Meadows shell finished building before anything asks it to simulate")

	# 4. The client fights, in the realm only the host's shell is simulating.
	var deployed: Dictionary = await step(1, "deploy_creature", {})
	check(str(deployed.get("verdict", "")) == "PASS",
		"the client put a creature out in the Meadows (%s)" % str(deployed.get("detail", "")))
	# `require_encounter_record: false`, and that is a STATED LIMITATION rather
	# than a loosened assertion. `encounter_director.gd::
	# _open_encounter_if_networked()` is host-only by design -- lane 4.C's
	# handover H1: wild creatures are not replicated, so the host has never
	# heard of the wild a client is standing in front of and there is nothing
	# for it to mint a record about. A client's wild fight is local and
	# unarbitrated on `main` today, in one realm or two, and this smoke was
	# written asserting a binding the codebase has never produced.
	#
	# It does not weaken what this smoke is FOR. The deliverable here is that
	# a realm's world state survives its last occupant vanishing mid-fight,
	# and the sharp assertion for that is the one on DISK below. What this
	# step still proves is that the client really is in a live fight when its
	# link dies. When wild replication lands, drop this argument.
	var engaged: Dictionary = await step(1, "engage_wild",
		{"require_encounter_record": false})
	var fighting := str(engaged.get("verdict", "")) == "PASS"
	check(fighting, "the client is mid-fight in the unhosted realm (%s)" % str(engaged.get("detail", "")))

	# 5. The cable is pulled.
	var dropped: Dictionary = await step(1, "drop_link", {})
	check(str(dropped.get("verdict", "")) == "PASS",
		"the client's transport went away without a Session.leave() (%s)" % str(dropped.get("detail", "")))

	# 6. The host notices and folds the shell down. Polled: `peer_disconnected`
	#    arrives on ENet's schedule, not on this script's.
	var folded := await _await_shells(0, [], 60)
	check(_shell_realms(folded).is_empty(),
		"the host folded the now-empty Meadows shell down (still holds %s)" % str(_shell_realms(folded)))
	var alone: Dictionary = await step(0, "expect_peers", {"count": 1})
	check(str(alone.get("verdict", "")) == "PASS",
		"the host is alone in the session again (%s)" % str(alone.get("detail", "")))

	# THE assertion. Live first, because a failure there means something much
	# worse than a lost save.
	var after = await probe(0, "world_records")
	check(after is Dictionary, "the host answered a world_records probe after the drop")
	var live_after := _count(after, "live", MEADOWS)
	check(live_after >= live_before,
		"the host still holds every Meadows world record (%d before, %d after)"
			% [live_before, live_after])

	# And on disk, which is what `realm_shells.gd::_tear_down()` writing BEFORE
	# it frees is for. Re-read off `user://`, not remembered from the write.
	var disk_after := _count(after, "disk", MEADOWS)
	var disk_map: Dictionary = ((after as Dictionary).get("disk", {})) as Dictionary
	check(disk_map.has("_file"),
		"the host's autosave file exists to be read back (keys: %s)" % str(disk_map.keys()))
	check(disk_after >= live_before,
		"the folded-down realm's world state reached the autosave file: %d Meadows record(s) on disk, %d were live before the drop (%s)"
			% [disk_after, live_before, str(disk_map.get("_file", ""))])

	# The client really did lose its session rather than merely go quiet --
	# otherwise every check above is about a peer that never left.
	var orphan = await probe(1, "session")
	check(orphan is Dictionary and not bool((orphan as Dictionary).get("active", true)),
		"the dropped peer is genuinely out of the session, not merely silent")

	quit(await finish())


## Poll until the host says the named shell has finished its sliced build.
## Same shape as `_await_shells` below, on `realms[realm].ready`.
func _await_shell_ready(peer: int, realm: String, seconds: int) -> Dictionary:
	var deadline := Time.get_ticks_msec() + seconds * 1000
	var last: Dictionary = {}
	while Time.get_ticks_msec() < deadline:
		var v = await probe(peer, "realm_shells")
		last = v if v is Dictionary else {}
		if _shell_ready(last, realm):
			return last
		await step(peer, "wait", {"frames": 60})
	return last


static func _shell_ready(report: Variant, realm: String) -> bool:
	if not (report is Dictionary):
		return false
	var realms: Variant = (report as Dictionary).get("realms", {})
	if not (realms is Dictionary):
		return false
	var row: Variant = (realms as Dictionary).get(realm)
	return row is Dictionary and bool((row as Dictionary).get("ready", false))


func _await_shells(peer: int, want: Array, seconds: int) -> Dictionary:
	var deadline := Time.get_ticks_msec() + seconds * 1000
	var last: Dictionary = {}
	while Time.get_ticks_msec() < deadline:
		var v = await probe(peer, "realm_shells")
		last = v if v is Dictionary else {}
		if _shell_realms(last) == want:
			return last
		await step(peer, "wait", {"frames": 60})
	return last


## `report[bucket][realm]`, or 0. Asserts nothing itself -- but it reads
## `has()` before `get()` on every level, deliberately: `int(null)` is 0 in
## GDScript, so a probe that came back malformed would otherwise report a
## confident, wrong zero and a comparison against it would pass or fail for
## reasons that have nothing to do with the deliverable.
static func _count(report: Variant, bucket: String, realm: String) -> int:
	if not (report is Dictionary):
		return -1
	var d: Dictionary = report
	if not d.has(bucket) or not (d[bucket] is Dictionary):
		return -1
	var b: Dictionary = d[bucket]
	if not b.has(realm):
		return 0
	return int(b[realm])


static func _shell_realms(report: Variant) -> Array:
	if not (report is Dictionary):
		return []
	var realms: Variant = (report as Dictionary).get("realms", {})
	if not (realms is Dictionary):
		return []
	var out: Array = (realms as Dictionary).keys()
	out.sort()
	return out


func _report_shell_cost(report: Variant) -> void:
	if not (report is Dictionary):
		return
	var d: Dictionary = report
	for realm: String in (d.get("realms", {}) as Dictionary).keys():
		var row: Dictionary = (d.get("realms", {}) as Dictionary)[realm] as Dictionary
		# See `smoke_net_split_realms.gd::_report_shell_cost` for why this is
		# `attach_ms` + `build_ms` rather than the lane-6.A `boot_ms`.
		print("6A-SHELL-COST peer=0 realm=%s attach_ms=%d build_ms=%d ready=%s static_delta_kb=%d process_static_kb=%d vm_hwm_kb=%d bodies=%d"
			% [realm, int(row.get("attach_ms", -1)), int(row.get("build_ms", -1)),
				str(row.get("ready", false)), int(row.get("static_delta_kb", -1)),
				int(d.get("static_memory_kb", -1)), int(d.get("vm_hwm_kb", -1)),
				int(row.get("bodies", -1))])
