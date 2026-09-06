extends "res://tests/helpers/net_harness.gd"

## HELD, 2026-09-06, and NOT quarantined -- the distinction matters.
##
## This smoke is not failing while the feature it covers still ships. The
## feature was WITHDRAWN: `game_state.gd::can_enter_realm()` re-instates D97's
## multi-peer refusal, because this smoke measured the host freezing for longer
## than the harness's 15 s heartbeat window at
## `realm_shells.gd`'s synchronous `add_child` -- the whole world build, inside
## one frame, on the machine everybody else depends on. A test for a door that
## is deliberately shut cannot pass, so its `# peers: 2` header is removed and
## CI stops discovering it.
##
## Restoring it is two edits and they belong together: delete the
## `is_multi_peer()` lines in `can_enter_realm()`, and put the header back.
## Do not do either alone.

#  peers-held: HELD, header removed on purpose; see the note below

## Stage B Wave 6 lane 6.A. THE player-visible outcome of the lane, and of
## directive rule 16: **two people in different biomes at the same time.**
##
##   tools/net/run_net_smoke.sh net_split_realms
##
## Until this lane `Game.enter_realm()` REFUSED outright in a multi-peer
## session -- D97's interim rule, which the decision itself scoped to
## development. This smoke is what lifting it has to survive.
##
## ## The shape of the run
##
## Both peers boot the Meadows and form a session, exactly as
## `smoke_net_movement_two_peers.gd` does (its handshake block is copied
## verbatim below, per the lane brief). Then:
##
##   1. the CLIENT walks through into Cloudreach while the host stays in the
##      Meadows. It does NOT leave the session -- the assertion after the
##      crossing is that both peers still report two peers and an active
##      session, because "swaps its own world scene without leaving" is half
##      the deliverable and a client that quietly dropped would satisfy every
##      other check here;
##   2. the HOST stands a headless Cloudreach shell up, because somebody is in
##      a realm it is not in. `realm_shells` reports it, on the host and only
##      on the host;
##   3. the registry knows where each of them is, and the two answers differ.
##      Read off `Session.realm_of()`, never off `Game.current_realm`, which
##      D97 makes true of the local player alone;
##   4. **nobody draws a trainer who is not there.** Each peer sees exactly
##      one trainer body -- its own invisible outbound proxy -- and none it
##      does not own. This is the check that fails if the despawn-before-swap
##      ordering in `game_state.gd::enter_realm()` is lost;
##   5. both GATHER, at the same time, in different realms: two ledger intents
##      carrying two different explicit realms, both committed by the one host;
##   6. the host FIGHTS in the Meadows while the client is in Cloudreach --
##      the host simulating one realm in the foreground while it holds another
##      as a shell;
##   7. they SWAP. The client comes back to the Meadows and the host goes to
##      Cloudreach, and the shell swaps with them: the host now holds a
##      MEADOWS shell, the expensive one, and the client's own Cloudreach
##      scene is gone.
##
## ## What it costs, and why the budget is what it is
##
## Five world builds in one run (two Meadows boots, the client's Cloudreach,
## the host's Cloudreach shell, then the host's Meadows shell and the client's
## second Meadows). Spike S2 measured a cold Meadows boot at 84 s. The
## measured cost of this run is recorded in
## `ralph/reports/MP-6A-REALMS-0906/REPORT.md`; it is the most expensive net
## smoke in the shard by a wide margin and that is inherent to what rule 16
## asks for, not slack in the script.

## Which realm each peer starts in and ends in. Named rather than repeated so
## the swap at the end reads as a swap.
## Wall-clock seconds of STEPS this smoke may spend.
##
## Three world builds inside the step phase: the client's Cloudreach, the
## host's Cloudreach shell, then the host's real Cloudreach and its Meadows
## shell alongside the client's second Meadows. At S2's ~85 s per cold Meadows
## that is the dominant term and 1,200 s carries it with margin.
const REALM_STEP_BUDGET_S := 1200.0

const MEADOWS := "meadows"
const CLOUDREACH := "cloudreach"
## The story flag `realm_hearts.json` requires before Cloudreach will open.
const CLOUDREACH_KEY_FLAG := "realm_key_cloudreach"


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

	# Everybody starts in the same realm, and the host holds no shell for a
	# realm it is standing in. Asserted BEFORE the crossing so a later "the
	# host has a Cloudreach shell" cannot pass on a shell that was always
	# there.
	for i in 2:
		var start = await probe(i, "realm")
		check(start is Dictionary and str((start as Dictionary).get("current", "")) == MEADOWS,
			"peer %d starts in the Meadows (got '%s')"
				% [i, str((start as Dictionary).get("current", "")) if start is Dictionary else "<none>"])
	var shells_before = await probe(0, "realm_shells")
	check(shells_before is Dictionary and (_shell_realms(shells_before)).is_empty(),
		"the host holds no realm shell while everybody is in one realm (holds %s)"
			% str(_shell_realms(shells_before)))

	# Cloudreach is key-gated in the ordinary way: `realm_hearts.json` gives it
	# `entry_key_flag = "realm_key_cloudreach"`, and `can_enter_realm()` refuses
	# without it in SOLO exactly as in a session. That gate is not what this
	# smoke is about -- it is about whether a multi-peer session still refuses a
	# crossing the player has otherwise earned -- so the key is granted here as
	# setup. Without it the smoke reports "enter_realm refused" and reads like
	# lane 6.A's work never landed, which is what it did on its first local run.
	#
	# Granted as an ordinary world flag through the ledger, on the host, so both
	# peers hold it: the gate is a world fact about the route being open, not a
	# personal one.
	var keyed: Dictionary = await step(0, "story_flag",
		{"flag": CLOUDREACH_KEY_FLAG, "scope": "world"})
	check(str(keyed.get("verdict", "")) == "PASS",
		"the Cloudreach route is open before anyone tries to walk it (%s)"
			% str(keyed.get("detail", "")))
	for i in 2:
		var seen: Dictionary = await step(i, "wait_flag", {"flag": CLOUDREACH_KEY_FLAG})
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d sees the Cloudreach route open (%s)" % [i, str(seen.get("detail", ""))])

	# 1. The client crosses. `enter_realm` is the game's own door; the step
	#    fails loudly if it is still refused.
	var crossed: Dictionary = await step(1, "enter_realm", {"realm": CLOUDREACH},
		int(_budgets.get("step_budget_frames", DEFAULT_STEP_BUDGET_FRAMES)) * 4)
	check(str(crossed.get("verdict", "")) == "PASS",
		"peer 1 crossed into Cloudreach without leaving the session (%s)" % str(crossed.get("detail", "")))
	if str(crossed.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	# The other half of "without leaving the session". A client that dropped
	# its peer on the way through would satisfy every realm check below.
	for i in 2:
		var still = await probe(i, "session")
		var d: Dictionary = still if still is Dictionary else {}
		check(bool(d.get("active", false)),
			"peer %d's session is still active after the crossing" % i)
		check(int(d.get("peer_count", 0)) == 2,
			"peer %d still counts 2 peers after the crossing (got %d)" % [i, int(d.get("peer_count", 0))])

	# 3. The registry, which is the only thing entitled to answer "where is
	#    that other player" -- checked on BOTH peers, because the client's copy
	#    is replicated and a host-only assertion would not notice it going
	#    stale.
	for i in 2:
		var view = await probe(i, "realm")
		var d: Dictionary = view if view is Dictionary else {}
		var by_peer: Dictionary = d.get("peers", {}) as Dictionary
		check(by_peer.size() == 2, "peer %d's registry carries a realm for both players" % i)
		var realms: Array = by_peer.values()
		realms.sort()
		check(realms == [CLOUDREACH, MEADOWS],
			"peer %d sees one player in each realm (got %s)" % [i, str(realms)])
	var host_realm = await probe(0, "realm")
	check(str((host_realm as Dictionary).get("current", "")) == MEADOWS,
		"the host is still standing in the Meadows")
	var guest_realm = await probe(1, "realm")
	check(str((guest_realm as Dictionary).get("current", "")) == CLOUDREACH,
		"the client is standing in Cloudreach")
	check(str((guest_realm as Dictionary).get("scene", "")) == "CloudreachCliffs",
		"the client's CURRENT SCENE is Cloudreach, not merely its realm id (got '%s')"
			% str((guest_realm as Dictionary).get("scene", "")))

	# 2. The shell. On the host, and only on the host.
	var shells = await probe(0, "realm_shells")
	check(shells is Dictionary and _shell_realms(shells) == [CLOUDREACH],
		"the host stands a headless Cloudreach shell up for the peer who went there (holds %s)"
			% str(_shell_realms(shells)))
	_report_shell_cost(0, shells)
	var guest_shells = await probe(1, "realm_shells")
	check(guest_shells is Dictionary and (_shell_realms(guest_shells)).is_empty(),
		"the client hosts nothing: shells are the HOST's, not every peer's (holds %s)"
			% str(_shell_realms(guest_shells)))

	# 4. Nobody is drawing a trainer who is not there. One body each -- its own
	#    outbound proxy, which `remote_trainer.gd` keeps invisible -- and none
	#    it does not own.
	for i in 2:
		var bodies = await probe(i, "remote_trainers")
		var d: Dictionary = bodies if bodies is Dictionary else {}
		check(_not_mine(d).is_empty(),
			"peer %d draws no trainer body for a player in another realm (drew %d)"
				% [i, _not_mine(d).size()])

	# 5. Both gather, at once, in two realms. Two intents, two explicit realms,
	#    one host deciding both.
	var host_gathered: Dictionary = await step(0, "storage_place", {"realm": MEADOWS})
	check(str(host_gathered.get("verdict", "")) == "PASS",
		"the host committed a Meadows world record while the client was elsewhere (%s)"
			% str(host_gathered.get("detail", "")))
	var guest_gathered: Dictionary = await step(1, "storage_place", {"realm": CLOUDREACH})
	check(str(guest_gathered.get("verdict", "")) == "PASS",
		"the client committed a CLOUDREACH world record from Cloudreach (%s)"
			% str(guest_gathered.get("detail", "")))

	# 6. The host fights in its own realm while it holds another as a shell.
	var deployed: Dictionary = await step(0, "deploy_creature", {})
	check(str(deployed.get("verdict", "")) == "PASS",
		"the host put a creature out in the Meadows (%s)" % str(deployed.get("detail", "")))
	var engaged: Dictionary = await step(0, "engage_wild", {})
	check(str(engaged.get("verdict", "")) == "PASS",
		"the host fought a wild in the Meadows while a Cloudreach shell was standing (%s)"
			% str(engaged.get("detail", "")))
	var shells_mid = await probe(0, "realm_shells")
	check(_shell_realms(shells_mid) == [CLOUDREACH],
		"the Cloudreach shell survived the host's own fight (holds %s)" % str(_shell_realms(shells_mid)))

	# 7. The swap. Client home first, so the host is never the only occupant of
	#    a realm it is about to leave.
	var home: Dictionary = await step(1, "enter_realm", {"realm": MEADOWS},
		int(_budgets.get("step_budget_frames", DEFAULT_STEP_BUDGET_FRAMES)) * 4)
	check(str(home.get("verdict", "")) == "PASS",
		"peer 1 crossed back into the Meadows (%s)" % str(home.get("detail", "")))
	var away: Dictionary = await step(0, "enter_realm", {"realm": CLOUDREACH},
		int(_budgets.get("step_budget_frames", DEFAULT_STEP_BUDGET_FRAMES)) * 4)
	check(str(away.get("verdict", "")) == "PASS",
		"the HOST crossed into Cloudreach, the other way round (%s)" % str(away.get("detail", "")))

	var swapped = await probe(0, "realm")
	check(str((swapped as Dictionary).get("current", "")) == CLOUDREACH,
		"the host is now in Cloudreach")
	var guest_home = await probe(1, "realm")
	check(str((guest_home as Dictionary).get("current", "")) == MEADOWS,
		"the client is now back in the Meadows")
	check(str((guest_home as Dictionary).get("scene", "")) == "MeadowsPlayground",
		"the client's current scene really is the Meadows again (got '%s')"
			% str((guest_home as Dictionary).get("scene", "")))

	# The shell swapped with them, which is the whole reconcile in one line:
	# Cloudreach is no longer a realm the host is absent from, and the Meadows
	# now is. This is also the run's only MEADOWS shell -- the expensive one.
	var shells_after = await _await_shells(0, [MEADOWS], 60)
	check(_shell_realms(shells_after) == [MEADOWS],
		"the host now holds a Meadows shell and no Cloudreach one (holds %s)"
			% str(_shell_realms(shells_after)))
	_report_shell_cost(0, shells_after)

	quit(await finish())


## Poll the host's shell report until it says what is expected, or the budget
## runs out. A stand-up is not instantaneous -- `realm_shells.gd` reconciles on
## its own tick so a crossing and a scene swap cannot race -- and a shell that
## takes a Meadows boot to appear is the measurement, not a failure.
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


static func _shell_realms(report: Variant) -> Array:
	if not (report is Dictionary):
		return []
	var realms: Variant = (report as Dictionary).get("realms", {})
	if not (realms is Dictionary):
		return []
	var out: Array = (realms as Dictionary).keys()
	out.sort()
	return out


## The bodies a process is drawing that it does not own -- i.e. other people.
## Same helper, same reasoning as `smoke_net_movement_two_peers.gd::_others()`.
static func _not_mine(bodies: Dictionary) -> Array:
	var out: Array = []
	for key in bodies.keys():
		var row: Variant = bodies[key]
		if row is Dictionary and not bool((row as Dictionary).get("mine", false)):
			out.append(row)
	return out


## The lane's own measurement, printed into the run log rather than asserted:
## a boot cost and a memory figure are evidence for
## `ralph/reports/MP-6A-REALMS-0906/REPORT.md`, and a smoke that turned them
## into a bar would be asserting this box's wall clock.
func _report_shell_cost(peer: int, report: Variant) -> void:
	if not (report is Dictionary):
		return
	var d: Dictionary = report
	var realms: Dictionary = d.get("realms", {}) as Dictionary
	for realm: String in realms.keys():
		var row: Dictionary = realms[realm] as Dictionary
		print("6A-SHELL-COST peer=%d realm=%s boot_ms=%d static_delta_kb=%d process_static_kb=%d vm_hwm_kb=%d bodies=%d"
			% [peer, realm, int(row.get("boot_ms", -1)), int(row.get("static_delta_kb", -1)),
				int(d.get("static_memory_kb", -1)), int(d.get("vm_hwm_kb", -1)),
				int(row.get("bodies", -1))])
