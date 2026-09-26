extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F06: Cloudreach GROUND RIDING, two real peers, both standing in Cloudreach.
##
##   tools/net/run_net_smoke.sh cloudreach_riding
##
## The Meadows two-peer ride (`smoke_net_riding.gd`) never entered Cloudreach,
## and Cloudreach now builds its own riding controller
## (`scripts/world/cloudreach_riding_controller.gd`, stood up by
## `cloudreach_world_runtime.gd::_mount_ground_riding()`), which also feeds
## Fly's safe anchor from the mount's floor contact
## (`fly_controller.gd::observe_carried_ground`). On a CLIENT that anchor is a
## proposal the host must grant (`_anchor_is_the_hosts_to_give`,
## `_propose_anchor`). This smoke is the integrator review's request: the
## guest (peer 1) rides in Cloudreach while the host (peer 0) keeps playing.
##
## ## Disclosed fixtures (SETUP, not earned-route proof)
##
## * Both peers boot the Meadows (`launch(2, "world")`), host/join over the
##   harness's loopback ENet, and press the opening dialogue away.
## * `realm_key_cloudreach` is granted as a WORLD flag through the ledger on
##   the host (the `smoke_net_split_realms.gd` fixture), so the crossing is
##   not refused for a key this smoke is not about.
## * Each peer's party is seeded with `party_grant` in the solo Cloudreach
##   saddle smoke's order: meadowhart, bramblebun, mudsnout, terrapup,
##   brooktail. Index 0 (the Meadowhart) is active. One `saddle` is put in each
##   satchel with `storage_grant`. The `saddle_fitted_meadowhart` flag is NOT
##   seeded: `mount()` fits the saddle itself on the first ride, so the
##   saddle a remote peer sees is the one the mount fitted.
## * The guest crosses into Cloudreach first, then the host, both through the
##   production `Game.enter_realm("cloudreach")`. Nobody is placed in
##   Cloudreach: both stand where the realm's own arrival puts them.
## * The companion is called out with the ordinary `creature_recall` binding,
##   as the solo smoke does on arrival.
## * The guest walks to its own mount with the harness's stick navigator
##   (`move_to`, real move axes). Mount, dismount and remount are the real
##   `interact` press. Riding is the real left stick: the long ride is the
##   same `move_to` navigator steering the mount up the arrival road through
##   four disclosed waypoints (`ROAD_WAYPOINTS`, on the road's own centreline:
##   a live crossing stands only the 7 m collision ribbon there, not the solo
##   build's shoulders); the remount ride is a raw `stick` push.
## * Before each walk to its mount the guest waits (bounded) until its
##   companion stands at the trainer's level (`_companion_settled`): after a
##   dismount on the ribbon the follower can step off the edge on its way to
##   its station and be recovered by the realm's companion-fall rule.
## * The host's concurrent play is its own stick, plus a ledger drop and pickup
##   of wood it was granted (`storage_grant`), as in `smoke_net_riding.gd`.
## * Arrival order: the guest crosses first, then the host. The opposite order
##   (the host already in Cloudreach when the guest arrives) is the re-entry
##   leg near the end: the guest crosses back to the Meadows and returns
##   through the same production door, and the same tracking and riding
##   checks are asserted there.
## * Forced dismount: the host starts a wild fight with `engage_wild` (which
##   stands the host beside the nearest Cloudreach wild, the harness's
##   documented placement), and the mounted guest joins that host-owned
##   encounter with `join_encounter`. The HOST's admission is what starts the
##   guest's fight, and the fight is what must end the ride.
##
## ## What is not observed directly, and what stands in for it
##
## * Where the rider is set down is judged against the mount's position two
##   frames after the dismount press, not two seconds later: once off, the
##   mount is a follower again and walks away to its station.
## * "Collision restored" after a dismount is observed as `on_floor` (a
##   `CharacterBody3D` with a zero mask is never on a floor) plus a y that
##   holds still for a second. `player_controller.set_carrier(null)` restores
##   layer and mask on the same two lines, so the mask is the witness.
## * The pending window of an anchor proposal is a network round trip on
##   loopback, too short to sample reliably from the coordinator. The anchor
##   claim is therefore proved from both ends instead: the guest's counters and
##   `host_validated`, the host's own log of each claim and verdict, and the
##   final anchor's height being the HOST's ground plus the arbiter's epsilon
##   rather than the guest's claimed height (a carried claim is the rider's
##   clear spot, lifted `SETTLE_LIFT_M` off the floor).
## * Wall-clock only: the hello window is 360 s (`_init_budgets`), because two
##   cold Meadows boots side by side outlast the shared 180 s.

const MOUNT_SPECIES := "meadowhart"
const TEAM := ["meadowhart", "bramblebun", "mudsnout", "terrapup", "brooktail"]
const CLOUDREACH := "cloudreach"
const CLOUDREACH_KEY_FLAG := "realm_key_cloudreach"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const ANCHOR_ARBITER := preload("res://scripts/net/fly_anchor_arbiter.gd")
const RIDING := preload("res://scripts/world/cloudreach_riding_controller.gd")
## Two realm crossings plus the Meadows boots; `smoke_net_split_realms.gd`
## extends its own deadline for the same cost.
const REALM_STEP_BUDGET_S := 1500.0
const SETTLE_FRAMES := 90
const SEAT_TOLERANCE_M := 0.35
## Host-side "B moved" threshold during the stick rounds.
const RIDE_MOVED_M := 4.0
const NO_ARBITER := "<no arbiter readable>"
## The guest's long ride: the arrival road north from the spawn, one waypoint
## per concurrent round. Steered with the harness's `move_to` stick navigator
## (real move axes, camera-relative), because a fixed stick direction depends
## on where the guest's camera happened to face.
## Every point lies ON the road's own centreline, `cloudreach_world.json`
## `arrival_gate_road` from (0, 105, -260) toward (-80, 130, 40), because a
## LIVE crossing does not build the solo geological shoulders
## (`cloudreach_world.gd`: `routes:*:geological_shoulders:deferred` while the
## shell build is slicing) and stands only the 7 m collision ribbon
## (`path_collision_width_m`) along that line. The draft's points were measured
## by a SOLO ride on the shoulders, 7-8 m east of the line: in the two-peer run
## the mount rode off the ribbon at (1.3, -236) and dropped into the
## mounted-fall recovery (reproduced solo with the shoulders removed; the same
## ride along these points stayed on floor every frame).
## The first point is the line where it leaves the arrival landing, so the ride
## joins the ribbon at the landing's own ramp (`_landing_join`) rather than
## climbing the ribbon's side from the mesa crown west of it.
const ROAD_WAYPOINTS: Array[Vector3] = [
	Vector3(-1.6, 0.0, -254.0), Vector3(-5.33, 0.0, -240.0),
	Vector3(-10.67, 0.0, -220.0), Vector3(-16.0, 0.0, -200.0),
]
const RIDE_MIN_M := 30.0
## `fly_traversal.json` landing_anchor: resubmit_m 8 + max_drift_m 6. An anchor
## further than this from where the ride ended was not re-proposed.
const ANCHOR_FOLLOW_M := 14.0

var _asserted := 0
var _ids: Array[int] = []
var _party_baseline: Array = [[], []]


## Wall-clock only, as `smoke_net_veridian_choices.gd` and
## `smoke_net_shared_boss.gd` do: two cold Meadows boots side by side on one
## runner outlast the shared 180 s hello window (the first 2026-09-26 run died
## there with both peers still building the world, neither exited). No gameplay
## bound -- frame budget, reach, tolerance -- moves with it.
func _init_budgets() -> void:
	super._init_budgets()
	_budgets["hello_budget_s"] = maxf(float(_budgets.get("hello_budget_s", DEFAULT_HELLO_BUDGET_S)), 360.0)


func _initialize() -> void:
	_run()


func _run() -> void:
	heartbeat_silence_tolerance_s = 60.0
	if not await launch(2, "world"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + REALM_STEP_BUDGET_S * 1000.0
	var crossing_budget := int(_budgets.get("step_budget_frames", DEFAULT_STEP_BUDGET_FRAMES)) * 4

	# --- handshake (smoke_net_riding.gd) --------------------------------------
	if not _ok(await step(0, "host", {}), "peer 0 hosted a world"):
		quit(await finish())
		return
	var host_session: Variant = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	if not _ok(await step(1, "join", {"host": "127.0.0.1", "port": port}), "peer 1 joined on port %d" % port):
		quit(await finish())
		return
	for i in 2:
		_ok(await step(i, "expect_peers", {"count": 2}), "peer %d's registry holds both players" % i)
	for i in 2:
		var row: Variant = await probe(i, "session")
		_ids.append(int((row as Dictionary).get("peer_id", 0)) if row is Dictionary else 0)
	_check(_ids[0] == 1 and _ids[1] != 0 and _ids[1] != 1,
		"peer 0 is the listen server and peer 1 has its own id (%s)" % str(_ids))
	for i in 2:
		_ok(await step(i, "dismiss_dialogue", {}), "SETUP: peer %d holds the world, not a dialogue box" % i)

	# --- SETUP: key, party, saddle ---------------------------------------------
	_ok(await step(0, "story_flag", {"flag": CLOUDREACH_KEY_FLAG, "scope": "world"}),
		"SETUP: the Cloudreach route is open")
	for i in 2:
		_ok(await step(i, "wait_flag", {"flag": CLOUDREACH_KEY_FLAG}), "SETUP: peer %d sees the key" % i)
	for i in 2:
		var party_before: Variant = await probe(i, "party")
		var before_size := (party_before as Array).size() if party_before is Array else -1
		_check(before_size == 0, "SETUP: peer %d starts with an empty party, so the seeded five are the whole party (had %d)" % [i, before_size])
		for species: String in TEAM:
			_ok(await step(i, "party_grant", {"species": species}), "SETUP: peer %d party_grant %s" % [i, species])
		_ok(await step(i, "storage_grant", {"item": "saddle", "n": 1}), "SETUP: peer %d has a saddle in the satchel" % i)
		_party_baseline[i] = await _party_ids(i)
		var party_now: Variant = await probe(i, "party")
		var species_now: Array = []
		for member: Variant in (party_now as Array if party_now is Array else []):
			species_now.append(str((member as Dictionary).get("species", "")))
		_check((_party_baseline[i] as Array).size() == 5 and species_now == TEAM,
			"SETUP: peer %d owns exactly five, meadowhart first (%s)" % [i, str(species_now)])
	await _step_party("after the fixture")

	# --- both peers cross into Cloudreach -------------------------------------
	# GUEST FIRST, then the host. The other order (host first) is exercised by
	# the re-entry leg at the end of this file, where it is asserted on rather
	# than routed around: see `_guest_rejoins_the_hosts_realm()`.
	for i: int in [1, 0]:
		var crossed: Dictionary = await step(i, "enter_realm", {"realm": CLOUDREACH}, crossing_budget)
		if not _ok(crossed, "peer %d crossed into Cloudreach" % i):
			quit(await finish())
			return
	for i in 2:
		var where: Variant = await probe(i, "realm")
		var d: Dictionary = where if where is Dictionary else {}
		_check(str(d.get("current", "")) == CLOUDREACH and str(d.get("scene", "")) == "CloudreachCliffs",
			"peer %d stands in the production Cloudreach scene (%s / %s)" % [i, str(d.get("current", "")), str(d.get("scene", ""))])
		var peers: Dictionary = d.get("peers", {}) as Dictionary
		_check(peers.size() == 2 and peers.values().all(func(r: Variant) -> bool: return str(r) == CLOUDREACH),
			"peer %d's registry has both players in Cloudreach (%s)" % [i, str(peers)])
	for i in 2:
		await step(i, "dismiss_dialogue", {"settle": 10})
	await _step_party("after the crossing")

	# --- companions out by the recall binding ---------------------------------
	for i in 2:
		var out := await _recall_until_out(i)
		_check(out != Vector3.INF, "peer %d called its Meadowhart out in Cloudreach with creature_recall" % i)
	var guest_mount := await _own_mount(1)
	_check(str(guest_mount.get("species", "")) == MOUNT_SPECIES,
		"the guest's companion is its Meadowhart (%s)" % str(guest_mount.get("species", "")))
	if guest_mount.is_empty():
		print("smoke_net_cloudreach_riding: aborting -- the guest has no companion out")
		quit(await finish())
		return

	# The host's copy of the guest's trainer has to track the guest at all
	# before any claim about how it is drawn riding can mean anything.
	await _check_host_tracks_guest("on foot in Cloudreach, before any ride")

	# === 1. the guest mounts by interact; the host sees it riding and seated ===
	var anchor_pre: Dictionary = await _anchor(1)
	print("ANCHOR before mount: %s" % JSON.stringify(anchor_pre))
	await _mount_by_interact("first mount")
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})
	var drawn := await _drawn_ride(0, _ids[1])
	_check(not drawn.is_empty(), "the host holds a trainer body for the guest")
	_check(bool(drawn.get("riding", false)) and bool(drawn.get("visible", false)),
		"the host draws the guest as RIDING and visible (%s)" % JSON.stringify(drawn))
	_check(str(drawn.get("mount_species", "")) == MOUNT_SPECIES,
		"the host knows the guest is on a %s (got '%s')" % [MOUNT_SPECIES, str(drawn.get("mount_species", ""))])
	_check(bool(drawn.get("seated", false)), "the seated pose reached the guest's skeleton on the host")
	_check(bool(drawn.get("saddled", false)) and bool(drawn.get("mount_saddle_worn", false)),
		"the saddle the guest's mount fitted is worn on the host's copy (published %s, worn %s)"
			% [str(drawn.get("saddled", false)), str(drawn.get("mount_saddle_worn", false))])
	_check(_seat_error(drawn) <= SEAT_TOLERANCE_M,
		"the host draws the guest IN the saddle: %.2f m off the seat (tolerance %.2f)" % [_seat_error(drawn), SEAT_TOLERANCE_M])
	await _step_party("mounted")

	# === 2 + 3. the guest rides by stick; the host keeps playing; the anchor ===
	var host_log_offset := _peer_log_size(0)
	var anchor_mounted: Dictionary = await _anchor(1)
	print("ANCHOR at mount: %s" % JSON.stringify(anchor_mounted))
	var host_view_start := _pos(drawn.get("pos", []))
	var host_before: Array = await probe(0, "position")
	await step(0, "storage_grant", {"item": "wood", "n": 8})
	var samples: Array = []
	var rounds: Array = [
		{"peer": 0, "action": "stick", "args": {"stick": "left", "x": 1.0, "y": 0.0, "frames": 120}},
		{"peer": 0, "action": "item_drop", "args": {"item": "wood", "n": 2}},
		{"peer": 0, "action": "item_pickup", "args": {}},
		{"peer": 0, "action": "stick", "args": {"stick": "left", "x": -1.0, "y": -1.0, "frames": 120}},
	]
	var guest_ride_start := _pos(await probe(1, "position"))
	var max_host_seen_moved := 0.0
	for r in rounds.size():
		var waypoint: Vector3 = ROAD_WAYPOINTS[r]
		var result: Array = await race([
			{"peer": 1, "action": "move_to", "args": {"x": waypoint.x, "z": waypoint.z, "close_enough": 3.0, "budget_frames": 900},
				"budget_frames": 4000},
			rounds[r],
		])
		var mount_now := await _own_mount(1)
		print("ride round %d: guest mount at %s" % [r + 1, str(mount_now.get("pos", []))])
		_check(_all_passed(result), "round %d: the guest rode by stick along the arrival road WHILE the host played: %s" % [r + 1, _verdicts(result)])
		var sample: Dictionary = await _anchor(1)
		var ride: Dictionary = await _local_ride(1)
		sample["mounted"] = bool(ride.get("mounted", false))
		samples.append(sample)
		var seen := await _drawn_ride(0, _ids[1])
		max_host_seen_moved = maxf(max_host_seen_moved, _flat(host_view_start, _pos(seen.get("pos", []))))
	for i in 2:
		await step(i, "wait", {"frames": 60})
	var drawn_after := await _drawn_ride(0, _ids[1])
	_check(max_host_seen_moved >= RIDE_MOVED_M,
		"the host SAW the guest ride: its copy of the guest moved %.2f m (wanted >= %.1f)" % [max_host_seen_moved, RIDE_MOVED_M])
	_check(bool(drawn_after.get("riding", false)) and _seat_error(drawn_after) <= SEAT_TOLERANCE_M,
		"the guest is still drawn riding and seated on the host after the ride (%.2f m off the seat)" % _seat_error(drawn_after))
	var host_after: Array = await probe(0, "position")
	_check(_flat(_pos(host_before), _pos(host_after)) > 1.0,
		"the host's own trainer moved during the ride: %.2f m" % _flat(_pos(host_before), _pos(host_after)))
	_check(str(await probe(0, "input_context")) == "world", "the host is still playing its own game (world context)")
	_check(samples.all(func(s: Variant) -> bool: return bool((s as Dictionary).get("mounted", false))),
		"the guest stayed mounted through every round")

	# --- 3. the anchor, from both ends ----------------------------------------
	var anchor_end: Dictionary = await _anchor(1)
	var host_log := _peer_log_suffix(0, host_log_offset)
	var claims := _claims(host_log, _ids[1])
	print("ANCHOR after ride: %s" % JSON.stringify(anchor_end))
	print("HOST CLAIMS during ride: %s" % str(claims))
	var proposals := int(anchor_end.get("proposals", 0)) - int(anchor_mounted.get("proposals", 0))
	var accepts := int(anchor_end.get("accepts", 0)) - int(anchor_mounted.get("accepts", 0))
	var granted: Array = claims.filter(func(c: Dictionary) -> bool: return bool(c.granted))
	_check(bool(anchor_mounted.get("host_validated", false)) and samples.all(func(s: Variant) -> bool: return bool((s as Dictionary).get("host_validated", false))),
		"the guest's fly controller treats its anchor as the host's to give throughout the ride")
	_check(proposals >= 1,
		"riding over new ground PROPOSED the anchor to the host (%d proposals while carried; observe_ground refuses while carried, so these are observe_carried_ground's)" % proposals)
	_check(claims.size() >= proposals and proposals >= 1,
		"the host received each proposal (%d claims logged by the host for peer %d, %d proposals sent)" % [claims.size(), _ids[1], proposals])
	_check(granted.size() >= 1 and accepts == granted.size(),
		"the host GRANTED them and the guest counted exactly those grants (%d granted on the host, %d accepts on the guest)" % [granted.size(), accepts])
	_check(bool(anchor_end.get("host_granted", false)) and not bool(anchor_end.get("pending", true)),
		"the guest's current anchor is a host grant, not a local write (host_granted %s, pending %s)"
			% [str(anchor_end.get("host_granted", false)), str(anchor_end.get("pending", true))])
	var final_anchor := _pos(anchor_end.get("anchor", []))
	var last_grant: Vector3 = granted[granted.size() - 1].at if not granted.is_empty() else Vector3.INF
	_check(final_anchor != Vector3.INF and last_grant != Vector3.INF
			and Vector2(final_anchor.x - last_grant.x, final_anchor.z - last_grant.z).length() < 0.05,
		"the guest's anchor is the LAST claim the host granted (anchor %s, last grant %s)" % [str(final_anchor), str(last_grant)])
	# A CARRIED claim is not the guest's floor: `observe_carried_ground` is fed
	# the rider's clear spot, which `cloudreach_riding_controller.gd` lifts
	# SETTLE_LIFT_M (0.05) off its ray hit. The floor under the claim is
	# therefore claim.y - SETTLE_LIFT_M, and the arbiter's answer is the HOST's
	# ray to that same static floor plus GROUND_EPSILON_M (0.08): 0.03 m above
	# the claim, never the claim itself. The draft compared against claim.y as
	# if it were floor (a walking claim), which no carried claim can meet.
	var claim_floor_y := last_grant.y - RIDING.SETTLE_LIFT_M if last_grant != Vector3.INF else INF
	_check(final_anchor != Vector3.INF and last_grant != Vector3.INF
			and absf(final_anchor.y - claim_floor_y - ANCHOR_ARBITER.GROUND_EPSILON_M) < 0.02
			and absf(final_anchor.y - last_grant.y) > 0.01,
		"its height is the HOST's ground plus the arbiter's %.2f m, not the guest's claimed height (anchor y %.3f, claim y %.3f, floor under the claim %.3f)"
			% [ANCHOR_ARBITER.GROUND_EPSILON_M, final_anchor.y, last_grant.y, claim_floor_y])
	_check(final_anchor != Vector3.INF and _flat(_pos(anchor_mounted.get("anchor", [])), final_anchor) > 1.0,
		"the anchor followed the ride (moved %.2f m from where it was at mount)" % _flat(_pos(anchor_mounted.get("anchor", [])), final_anchor))
	# The long-ride freeze: one proposal left unanswered while carried must not
	# stop every later one. After a ride of RIDE_MIN_M or more, the committed
	# anchor has to be near where the ride ENDED -- within the resubmit
	# distance plus the arbiter's drift allowance -- not somewhere along it.
	var guest_ride_end := _pos(await probe(1, "position"))
	var ridden := _flat(guest_ride_start, guest_ride_end)
	var anchor_lag := _flat(final_anchor, guest_ride_end)
	_check(ridden >= RIDE_MIN_M,
		"the guest's ride was a long one: %.1f m by stick (wanted >= %.0f)" % [ridden, RIDE_MIN_M])
	_check(final_anchor != Vector3.INF and anchor_lag >= 0.0 and anchor_lag <= ANCHOR_FOLLOW_M,
		"after a %.1f m ride the guest's safe anchor is %.1f m from where the ride ended (wanted <= %.0f): the anchor kept following, no proposal froze it"
			% [ridden, anchor_lag, ANCHOR_FOLLOW_M])
	await _step_party("after the ride")

	# === 4. dismount by interact onto ground; the host sees the guest stand ===
	await _dismount_by_interact("first dismount")
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})
	var standing := await _drawn_ride(0, _ids[1])
	_check(not standing.is_empty() and not bool(standing.get("riding", true)) and not bool(standing.get("carried", true)),
		"the host stops drawing the guest as riding or carried (%s)" % JSON.stringify(standing))
	_check(not standing.is_empty() and not bool(standing.get("seated", true)) and bool(standing.get("visible", false)),
		"the host draws the guest STANDING: not seated, visible")
	_check(bool(standing.get("mount_saddle_worn", false)), "the saddle stays on the guest's mount on the host's screen")
	var guest_now: Array = await probe(1, "position")
	_check(_pos(standing.get("pos", [])).distance_to(_pos(guest_now)) < 1.5,
		"the host draws the guest where the guest stands (%.2f m apart)" % _pos(standing.get("pos", [])).distance_to(_pos(guest_now)))
	await _step_party("after the dismount")

	# === 5. remount after dismounting ========================================
	await _mount_by_interact("remount")
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})
	var again := await _drawn_ride(0, _ids[1])
	_check(bool(again.get("riding", false)) and bool(again.get("seated", false)) and _seat_error(again) <= SEAT_TOLERANCE_M,
		"the host draws the guest riding and seated again after the remount (%s)" % JSON.stringify(again))
	var remount_ride: Array = await race([
		{"peer": 1, "action": "stick", "args": {"stick": "left", "x": 0.0, "y": 1.0, "frames": 90}},
		{"peer": 0, "action": "stick", "args": {"stick": "left", "x": 1.0, "y": 0.0, "frames": 90}},
	])
	_check(_all_passed(remount_ride), "the remounted guest rides again while the host moves: %s" % _verdicts(remount_ride))
	var remounted_local := await _local_ride(1)
	_check(bool(remounted_local.get("mounted", false)), "the guest is still on the mount after riding the remount")
	await _step_party("after the remount")

	await _dismount_by_interact("dismount after the remount")

	# === the other arrival order: host already in Cloudreach ================
	await _guest_rejoins_the_hosts_realm(crossing_budget)
	await _step_party("after the re-entry")

	# === 6. a forced dismount from the host's fight ==========================
	await _mount_by_interact("mount before the host's fight")
	await _forced_dismount_by_host_fight()
	await _step_party("end of run")

	print("smoke_net_cloudreach_riding: %d assertions, %d failures" % [_asserted, failures.size()])
	quit(await finish())


# --- the legs -----------------------------------------------------------------

func _mount_by_interact(context: String) -> void:
	# Walk to the companion with the stick until the game offers the ride, as
	# the solo smoke's `_walk_to_mount()` does: the follower re-stations as the
	# trainer approaches, so one walk to where it WAS can end out of reach.
	# The prompt is read off the interaction arbiter through the harness's
	# `downed` probe; it is a diagnostic, never a substitute for the press.
	var prompt := ""
	for attempt in 4:
		await _companion_settled(1, context)
		var mount := await _own_mount(1)
		var at := _pos(mount.get("pos", []))
		if at == Vector3.INF:
			_check(false, "%s: the guest has a companion to walk to" % context)
			return
		var walked: Dictionary = await step(1, "move_to", {"x": at.x, "z": at.z, "close_enough": 2.2, "budget_frames": 900})
		await step(1, "wait", {"frames": 10})
		prompt = await _prompt(1)
		var standing_at := _pos(mount.get("pos", []))
		print("%s: walk %d to mount at %s -> %s; prompt '%s'" % [context, attempt + 1, str(standing_at), str(walked.get("detail", "")), prompt])
		if prompt.contains("Ride ") or prompt == NO_ARBITER:
			break
	var pressed: Dictionary = await step(1, "press", {"action": "interact"})
	_ok(pressed, "%s: the guest pressed interact" % context)
	await step(1, "wait", {"frames": 30})
	var ride := await _local_ride(1)
	_check(bool(ride.get("mounted", false)) and str(ride.get("species", "")) == MOUNT_SPECIES,
		"%s: the interact press put the guest on its own %s (%s)" % [context, MOUNT_SPECIES, JSON.stringify(ride)])
	_check(bool(ride.get("saddle_worn", false)) and bool(ride.get("seated", false)),
		"%s: the guest's own mount wears the saddle and the guest is seated" % context)
	var fly: Dictionary = await _fly_local(1)
	_check(bool(fly.get("carried", false)), "%s: the guest's trainer is carried by the mount" % context)


func _dismount_by_interact(context: String) -> void:
	var before := await _local_ride(1)
	print("%s: before the press the guest's mount is at %s; prompt '%s'"
		% [context, str((await _own_mount(1)).get("pos", [])), await _prompt(1)])
	var pressed: Dictionary = await step(1, "press", {"action": "interact"})
	_ok(pressed, "%s: the guest pressed interact" % context)
	# Where the rider was set down is judged against where the mount stood AT
	# the dismount. Once off, the mount is an ordinary follower again and walks
	# to its station beside the trainer; on a live crossing's 7 m road ribbon
	# that station can be open air, and the realm's companion-fall rule
	# (`cloudreach_companion_fall.gd`) recovers it seconds later. The draft read
	# the mount two seconds after the press and measured that walk (mount y
	# 27-66 m while the trainer stood at 105-106), not the dismount spot.
	await step(1, "wait", {"frames": 2})
	var mount_at_dismount := _pos((await _own_mount(1)).get("pos", []))
	var trainer_at_dismount := _pos(await probe(1, "position"))
	await step(1, "wait", {"frames": 60})
	var ride := await _local_ride(1)
	_check(bool(before.get("mounted", false)) and not bool(ride.get("mounted", true)),
		"%s: the interact press dismounted the guest" % context)
	await _check_standing_clear(context, mount_at_dismount, trainer_at_dismount)


## Choreography, not an assertion: a player waits for their companion to be
## standing before walking over to ride it. After a dismount on a live
## crossing's road ribbon the follower can step off the edge on its way to its
## station (a shared `follower_creature.gd` behaviour, recovered by this
## realm's `cloudreach_companion_fall.gd`), and walking the trainer after a
## falling body leads it to the same edge. Standing = within 1.5 m of the
## trainer's height and still at that height a quarter-second later. Bounded;
## whatever state the companion is in afterwards, the Ride checks that follow
## decide.
func _companion_settled(peer: int, context: String) -> void:
	for poll in 40:
		var a := _pos((await _own_mount(peer)).get("pos", []))
		var me := _pos(await probe(peer, "position"))
		await step(peer, "wait", {"frames": 15})
		var b := _pos((await _own_mount(peer)).get("pos", []))
		if a != Vector3.INF and b != Vector3.INF and me != Vector3.INF \
				and absf(b.y - me.y) < 1.5 and absf(b.y - a.y) < 0.2:
			if poll > 0:
				print("%s: companion standing again after %d poll(s) at %s" % [context, poll, str(b)])
			return
	print("%s: companion still not standing beside the trainer after the wait" % context)


## On ground, solid, beside the mount rather than inside it.
func _check_standing_clear(context: String, m: Vector3, set_down: Vector3) -> void:
	var fly: Dictionary = await _fly_local(1)
	var p0 := _pos(await probe(1, "position"))
	await step(1, "wait", {"frames": 60})
	var fly_later: Dictionary = await _fly_local(1)
	var p1 := _pos(await probe(1, "position"))
	_check(not bool(fly.get("carried", true)) and bool(fly.get("on_floor", false)) and bool(fly_later.get("on_floor", false)),
		"%s: the guest stands on a floor, no longer carried -- collision mask restored (carried %s, on_floor %s/%s)"
			% [context, str(fly.get("carried", "?")), str(fly.get("on_floor", "?")), str(fly_later.get("on_floor", "?"))])
	_check(p0 != Vector3.INF and absf(p1.y - p0.y) < 0.3 and _flat(p0, p1) < 0.5,
		"%s: the guest stays put on that ground for a second (moved %.2f m, dy %.2f)" % [context, _flat(p0, p1), p1.y - p0.y])
	var radius := _mount_radius()
	_check(m != Vector3.INF and set_down != Vector3.INF and _flat(set_down, m) >= radius * 0.9,
		"%s: the guest is set down BESIDE the mount, not inside it (%.2f m from its centre at the dismount, body radius %.2f)" % [context, _flat(set_down, m), radius])
	_check(m != Vector3.INF and set_down != Vector3.INF and absf(set_down.y - m.y) < 1.5,
		"%s: on the mount's ground level, not on its back or under it (trainer y %.2f, mount y %.2f at the dismount)" % [context, set_down.y, m.y])
	_check(set_down != Vector3.INF and p0 != Vector3.INF and _flat(set_down, p0) < 0.5 and absf(set_down.y - p0.y) < 0.3,
		"%s: the spot the guest was set down on is the spot it then stands on (%.2f m, dy %.2f)" % [context, _flat(set_down, p0), p0.y - set_down.y])


## The host starts a wild fight in Cloudreach; the MOUNTED guest joins that
## host-owned encounter. The host's admission starts the guest's fight, and
## `riding_controller._riding_allowed()` must end the ride for it.
func _forced_dismount_by_host_fight() -> void:
	var before := await _local_ride(1)
	_check(bool(before.get("mounted", false)), "forced leg: the guest is mounted before the host's fight")
	var engaged: Dictionary = await step(0, "engage_wild", {"settle": 60}, 4000)
	if str(engaged.get("verdict", "")) != "PASS":
		_check(false, "forced leg NOT COVERED: the host could not start a Cloudreach wild fight (%s)" % str(engaged.get("detail", "")))
		return
	var host_fight: Variant = await probe(0, "encounter")
	var encounter_id := str((host_fight as Dictionary).get("id", "")) if host_fight is Dictionary else ""
	_check(not encounter_id.is_empty(), "forced leg: the host minted an encounter record (%s)" % encounter_id)
	var guest_view: Variant = await probe(1, "encounter")
	var joinable: Array = (guest_view as Dictionary).get("joinable", []) if guest_view is Dictionary else []
	_check(joinable.has(encounter_id), "forced leg: the mounted guest was told the host's fight exists (%s)" % str(joinable))
	var joined: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id, "settle": 300}, 3000)
	_ok(joined, "forced leg: the host admitted the mounted guest into its fight")
	await step(1, "wait", {"frames": 30})
	var after := await _local_ride(1)
	_check(not bool(after.get("mounted", true)), "forced leg: the host's fight ended the guest's ride")
	var context := str(await probe(1, "input_context"))
	_check(context == "combat" or context == "combat_aim", "forced leg: the guest is in the fight (context '%s')" % context)
	var fly: Dictionary = await _fly_local(1)
	_check(not bool(fly.get("carried", true)), "forced leg: the guest is not carried after the forced dismount")
	var p := _pos(await probe(1, "position"))
	var mount := await _own_mount(1)
	var m := _pos(mount.get("pos", []))
	_check(m != Vector3.INF and _flat(p, m) >= _mount_radius() * 0.9 and absf(p.y - m.y) < 1.5,
		"forced leg: the guest is set down beside the mount, not inside it (%.2f m, dy %.2f)" % [_flat(p, m), p.y - m.y])
	await step(0, "wait", {"frames": SETTLE_FRAMES})
	var seen := await _drawn_ride(0, _ids[1])
	_check(not seen.is_empty() and not bool(seen.get("riding", true)) and not bool(seen.get("seated", true)),
		"forced leg: the host stops drawing the guest as a rider (%s)" % JSON.stringify(seen))


## The host's copy of the guest's trainer stands where the guest stands.
func _check_host_tracks_guest(context: String) -> void:
	await step(1, "stick", {"stick": "left", "x": 0.0, "y": -1.0, "frames": 45})
	await step(0, "wait", {"frames": SETTLE_FRAMES})
	var seen := await _drawn_ride(0, _ids[1])
	var guest_at := _pos(await probe(1, "position"))
	var gap := _pos(seen.get("pos", [])).distance_to(guest_at) if not seen.is_empty() else INF
	_check(not seen.is_empty() and gap < 1.5,
		"%s: the host draws the guest's trainer where the guest stands (%.2f m apart; host copy %s, guest %s)"
			% [context, gap, str(seen.get("pos", [])), str(guest_at)])
	var anchor := await _anchor(1)
	_check(int(anchor.get("proposals", 0)) >= 1 and int(anchor.get("accepts", 0)) >= 1,
		"%s: the guest's walking anchor has reached the host and been granted (%s)" % [context, JSON.stringify(anchor)])


## Host already standing in Cloudreach; the guest leaves for the Meadows and
## walks back in. This is the arrival order a real friend joining a host
## mid-chapter has. Asserted, not routed around: the host's copy of the
## guest must land on the guest when the guest arrives second.
func _guest_rejoins_the_hosts_realm(crossing_budget: int) -> void:
	if not _ok(await step(1, "enter_realm", {"realm": "meadows"}, crossing_budget), "re-entry: the guest crossed back to the Meadows"):
		return
	if not _ok(await step(1, "enter_realm", {"realm": CLOUDREACH}, crossing_budget), "re-entry: the guest walked back into the host's Cloudreach"):
		return
	await step(1, "dismiss_dialogue", {"settle": 10})
	_check(await _recall_until_out(1) != Vector3.INF, "re-entry: the guest called its Meadowhart out again")
	await _check_host_tracks_guest("re-entry, host arrived first")
	await _mount_by_interact("re-entry mount")
	await step(0, "wait", {"frames": SETTLE_FRAMES})
	var drawn := await _drawn_ride(0, _ids[1])
	_check(bool(drawn.get("riding", false)) and bool(drawn.get("seated", false)) and _seat_error(drawn) <= SEAT_TOLERANCE_M,
		"re-entry: the host draws the guest riding and seated (%s)" % JSON.stringify(drawn))
	await _dismount_by_interact("re-entry dismount")


# --- helpers ------------------------------------------------------------------

## The winning interaction prompt on `peer`, from the `downed` probe's
## arbiter block ("" when that probe has no arbiter to read).
func _prompt(peer: int) -> String:
	var row: Variant = await probe(peer, "downed")
	var arbiter: Variant = (row as Dictionary).get("interaction_arbiter", null) if row is Dictionary else null
	return str((arbiter as Dictionary).get("prompt", "")) if arbiter is Dictionary else NO_ARBITER


func _check(condition: bool, message: String) -> void:
	_asserted += 1
	check(condition, message)


func _ok(result: Dictionary, message: String) -> bool:
	var passed := str(result.get("verdict", "")) == "PASS"
	_check(passed, "%s (%s)" % [message, str(result.get("detail", ""))])
	return passed


## Item 7, on BOTH peers every time: the same five UIDs in the same order.
func _step_party(context: String) -> void:
	for i in 2:
		var now := await _party_ids(i)
		_check(now.size() == 5 and now == _party_baseline[i],
			"%s: peer %d has the same five companions, same order, no sixth (%d)" % [context, i, now.size()])


func _party_ids(peer: int) -> Array:
	var row: Variant = await probe(peer, "tournament")
	if not (row is Dictionary):
		return []
	return ((row as Dictionary).get("party_ids", []) as Array).duplicate()


func _recall_until_out(peer: int) -> Vector3:
	for attempt in 6:
		var mine := await _own_mount(peer)
		if not mine.is_empty() and bool(mine.get("visible", false)):
			return _pos(mine.get("pos", []))
		await step(peer, "press", {"action": "creature_recall"})
		await step(peer, "wait", {"frames": 90})
	return Vector3.INF


## This peer's OWN piloted companion, from the `deployed_creatures` probe.
func _own_mount(peer: int) -> Dictionary:
	var rows: Variant = await probe(peer, "deployed_creatures")
	if not (rows is Dictionary):
		return {}
	for key: Variant in (rows as Dictionary).keys():
		var row: Dictionary = (rows as Dictionary)[key]
		if bool(row.get("local", false)):
			return row
	return {}


func _local_ride(peer: int) -> Dictionary:
	var raw: Variant = await probe(peer, "riding")
	return (raw as Dictionary).get("local", {}) as Dictionary if raw is Dictionary else {}


func _fly_local(peer: int) -> Dictionary:
	var raw: Variant = await probe(peer, "flying")
	return (raw as Dictionary).get("local", {}) as Dictionary if raw is Dictionary else {}


func _anchor(peer: int) -> Dictionary:
	var fly := await _fly_local(peer)
	var report: Variant = fly.get("anchor", {})
	return (report as Dictionary).duplicate() if report is Dictionary else {}


func _drawn_ride(viewer: int, owner: int) -> Dictionary:
	var raw: Variant = await probe(viewer, "riding")
	if not (raw is Dictionary):
		return {}
	var remote: Variant = (raw as Dictionary).get("remote", {})
	if not (remote is Dictionary) or not (remote as Dictionary).has(str(owner)):
		return {}
	var row: Variant = (remote as Dictionary)[str(owner)]
	return row if row is Dictionary else {}


func _seat_error(row: Dictionary) -> float:
	if not row.has("gap") or float(row["gap"]) < 0.0:
		return INF
	var offset: Vector3 = SPECIES.rideable(MOUNT_SPECIES).get("mount_offset", Vector3.UP)
	return absf(float(row["gap"]) - offset.length())


## The Meadowhart's collision radius is not on the wire; its dismount distance
## is authored in species.json, and a spot inside the body is closer than half
## of it by construction. Half the authored distance is the conservative floor.
func _mount_radius() -> float:
	return float(SPECIES.rideable(MOUNT_SPECIES).get("dismount_distance", 1.6)) * 0.5


## `[fly] peer <id> claimed a landing at (x, y, z) -- granted (ok)`, from
## `remote_trainer.gd::_rpc_request_landing_anchor` on the host.
func _claims(text: String, peer_id: int) -> Array:
	var out: Array = []
	var pattern := RegEx.new()
	pattern.compile("\\[fly\\] peer (\\d+) claimed a landing at \\(([-0-9.e]+), ([-0-9.e]+), ([-0-9.e]+)\\) -- (granted|refused) \\(([^)]*)\\)")
	for m: RegExMatch in pattern.search_all(text):
		if int(m.get_string(1)) != peer_id:
			continue
		out.append({"at": Vector3(float(m.get_string(2)), float(m.get_string(3)), float(m.get_string(4))),
			"granted": m.get_string(5) == "granted", "code": m.get_string(6)})
	return out


func _peer_log_size(peer: int) -> int:
	var file := FileAccess.open(str((_peers[peer] as Dictionary).get("log_path", "")), FileAccess.READ)
	if file == null:
		return 0
	var size := file.get_length()
	file.close()
	return size


func _peer_log_suffix(peer: int, offset: int) -> String:
	var file := FileAccess.open(str((_peers[peer] as Dictionary).get("log_path", "")), FileAccess.READ)
	if file == null:
		return ""
	var length := file.get_length()
	file.seek(clampi(offset, 0, length))
	var suffix := file.get_buffer(length - file.get_position()).get_string_from_utf8()
	file.close()
	return suffix


static func _pos(raw: Variant) -> Vector3:
	if not (raw is Array) or (raw as Array).size() != 3:
		return Vector3.INF
	var a: Array = raw
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


static func _flat(a: Vector3, b: Vector3) -> float:
	if a == Vector3.INF or b == Vector3.INF:
		return -1.0
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _all_passed(results: Array) -> bool:
	if results.is_empty():
		return false
	for entry: Variant in results:
		var verdict: Variant = (entry as Dictionary).get("verdict", {}) if entry is Dictionary else null
		if not (verdict is Dictionary) or str((verdict as Dictionary).get("verdict", "")) != "PASS":
			return false
	return true


static func _verdicts(results: Array) -> String:
	var parts := PackedStringArray()
	for entry: Variant in results:
		if not (entry is Dictionary):
			continue
		var d: Dictionary = (entry as Dictionary).get("verdict", {}) as Dictionary
		parts.append("peer %d %s (%s)" % [int((entry as Dictionary).get("peer", -1)),
			str(d.get("verdict", "?")), str(d.get("detail", ""))])
	return "; ".join(parts)
