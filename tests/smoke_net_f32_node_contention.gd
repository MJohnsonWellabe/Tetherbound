extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F32#5 (contention half): two real ENet peers press the SAME F32 renewable
## node at one shared wall-clock instant. MULTIPLAYER §10 "Attuned and essence
## nodes": world depletion on the host clock, personal grant, first valid claim
## wins, host world save.
##
##   GODOT_BIN=/usr/local/bin/godot tools/net/run_net_smoke.sh f32_node_contention
##
## Production path under test: `foundation_resources.gd` mounts the canonical
## `renewable_site_catalog.gd` site through `f32_world_mount.gd` on BOTH peers;
## each press is the node's own `Interactable.activated` signal, so the request
## travels harvest_node -> F32 SourceService -> Resources.submit ->
## Session._foundation_send -> host `host_context` -> world ledger stock CAS ->
## owner save/ACK. Nothing in that chain is stubbed.
##
## Disclosed fixtures (setup, not the feature): both trainers are teleported
## beside the site instead of walking, and the mount retry timer is cleared so
## the node mounts at once rather than within its 10 s retry window. The two
## peers stand on opposite sides of the node, both inside its 2.6 m host range.
##
## Peer-specific steps/probes live in a scoped runner that extends the shared
## `tools/net/peer_runner.gd` without editing it. Its source is the constant
## below, written into this run's own directory at launch (the same pattern as
## `smoke_net_f20_ending.gd`'s scoped runner, kept in one file).
##
## Four characters: MULTIPLAYER §9 makes two-peer runs the PR evidence and
## three/four-peer runs owner-kit/nightly (`# peers: 4` stays out of PR CI on
## memory grounds, see `smoke_net_four_peer_session.gd`). This file proves the
## two-character race only; it does not claim the four-character run.

const SITE := "essence_meadows_ground_01"
const SITE_GUEST_FIRST := "essence_meadows_psychic_01"
const REALM := "meadows"
const PRESS_LEAD_MS := 2500.0
const SETTLE_POLLS := 40
const POLL_FRAMES := 30

const RUNNER_SOURCE := """extends "res://tools/net/peer_runner.gd"

const F32_SITES := preload("res://scripts/world/renewable_site_catalog.gd")
var _f32_node: Node3D
var _f32_site := ""
var _f32_realm := ""
var _f32_press := ""
var _f32_settled: Array = []
var _f32_connected := false

func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	var args: Dictionary = (msg.get("args", {}) as Dictionary)
	if action == "f32_stand":
		return await _f32_stand(args)
	if action == "f32_diag_portal_flag":
		# DIAGNOSTIC FIXTURE ONLY (TB_F32_DIAG_PORTAL_FLAG=1): flips the host's
		# in-memory session config so `_rpc_travel_lifecycle` stops dropping
		# guest samples. Never acceptance evidence; the shipped flag is false.
		var session: Node = root.get_node(^"Game").get("session")
		(session.get("_config") as Dictionary)["redesign_portal_runtime_enabled"] = true
		return {"verdict": "PASS", "detail": "DIAGNOSTIC: host in-memory redesign_portal_runtime_enabled=true (portal_runtime_ready=%s)" % str(session.call("portal_runtime_ready"))}
	if action == "f32_press":
		var at := float(args.get("at_unix_ms", 0.0))
		if at > 0.0:
			_f32_press_at.call_deferred(at)
			return {"verdict": "PASS", "detail": "armed press for %.0f" % at}
		return _f32_press_now()
	return await super._execute_step(msg)

func _execute_probe(msg: Dictionary) -> Variant:
	if str(msg.get("what", "")) == "f32_node":
		return _f32_probe((msg.get("args", {}) as Dictionary))
	if str(msg.get("what", "")) == "f32_diag":
		return _f32_diag()
	return await super._execute_probe(msg)

func _f32_resources() -> Node:
	var game := root.get_node_or_null(^"Game")
	if game == null or game.get("session") == null: return null
	return (game.get("session") as Node).get_node_or_null(^"FoundationComposition/Resources")

func _f32_stand(args: Dictionary) -> Dictionary:
	_f32_site = str(args.get("site", ""))
	_f32_node = null
	_f32_press = ""
	_f32_settled = []
	_f32_realm = str(args.get("realm", "meadows"))
	var spec := F32_SITES.by_id(_f32_realm, _f32_site)
	var player := _probe.call("player") as CharacterBody3D
	var world := current_scene
	var resources := _f32_resources()
	if spec.is_empty() or player == null or world == null or resources == null or not world.has_method("ground_height_at"):
		return {"verdict": "ERROR", "detail": "site/player/world/Resources missing (spec %s)" % str(not spec.is_empty())}
	if not _f32_connected:
		resources.get_node(^"SourceService").connect("settled", func(op: String, id: String, action_id: String, verdict: Dictionary) -> void:
			if op == "node" and id == _f32_site:
				_f32_settled.append({"action_id": action_id, "verdict": verdict.duplicate(true), "unix_ms": Time.get_unix_time_from_system() * 1000.0}))
		_f32_connected = true
	var at := Vector2(float(spec.at[0]), float(spec.at[1]))
	var offset: Array = args.get("offset", [0.0, 6.0]) as Array
	var approach: Array = args.get("approach", [1.3, 0.0]) as Array
	# Mount from the disclosed 6 m start, like the native material smoke.
	for target: Vector2 in [at + Vector2(float(offset[0]), float(offset[1])), at + Vector2(float(approach[0]), float(approach[1]))]:
		var ground := float(world.call("ground_height_at", target.x, target.y))
		REMOTE_CREATURE_TP.teleport_body(player as PhysicsBody3D, Vector3(target.x, ground + 0.3, target.y))
		player.velocity = Vector3.ZERO
		for i in 45: await physics_frame
		if _f32_node == null:
			(resources.get("_mount_retry") as Dictionary).erase(_f32_realm)
			resources.call("_mount_realm", _f32_realm, player)
			_f32_node = resources.call("_source", _f32_realm, _f32_site)
	if _f32_node == null:
		var mount: Node = null
		for child: Node in world.find_children("RenewableResources", "", true, false): mount = child
		var why: Variant = mount.call("census").get("refusals", {}).get(_f32_site, "no mount") if mount != null else "no RenewableResources mount"
		return {"verdict": "FAIL", "detail": "site %s not mounted: %s" % [_f32_site, str(why)]}
	for i in 60: await physics_frame
	var d := player.global_position.distance_to(_f32_node.global_position)
	return {"verdict": "PASS" if d <= 2.4 else "FAIL",
		"detail": "mounted %s; trainer %.2f m from node at %s" % [_f32_site, d, str(_f32_node.global_position)]}

## Host-side admission inputs for every remote peer, and this peer's own
## registry view. Read-only: `host_context` stages nothing.
func _f32_diag() -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	var resources := _f32_resources()
	if game == null or resources == null: return {}
	var session: Node = game.get("session")
	var view: Dictionary = session.call("homestead_personal_view")
	var out := {"local_peer": int(session.call("local_peer_id")), "view_registry_revision": view.get("registry_revision"),
		"view_character": view.get("character_id"), "peers": []}
	var lifecycle0: Node = resources.get_parent().get_node(^"TravelLifecycle")
	out.local_sample_empty = (lifecycle0.call("local_sample") as Dictionary).is_empty()
	out.portal_runtime_ready = session.call("portal_runtime_ready")
	if not bool(session.call("is_host")):
		var sample: Dictionary = lifecycle0.call("local_sample")
		sample.sequence = 1
		out.sample_valid = preload("res://scripts/net/foundation_travel_lifecycle.gd").valid_sample(sample)
		var types := {}
		for field: Variant in sample: types[str(field)] = type_string(typeof(sample[field]))
		out.sample_types = types
		out.snapshot_ready = session.call("snapshot_ready")
		out.is_active = session.call("is_active")
		return out
	var key := "resource:%s:%s" % [_f32_realm, _f32_site]
	var intent := {"operation": "node", "request": {"site_id": _f32_site, "expected_stock_revision": 0, "action_id": "0123456789abcdef0123456789abcdef"}}
	var lifecycle: Node = resources.get_parent().get_node(^"TravelLifecycle")
	var registry: RefCounted = session.get("_registry")
	for row: Dictionary in registry.call("rows"):
		var peer := int(row.get("peer_id", 0))
		var actor: CharacterBody3D = resources.call("_body", peer)
		var source: Node3D = resources.call("_source", _f32_realm, _f32_site)
		var character := str(session.call("_authority_character", peer))
		var authority: RefCounted = session.get("_character_authority")
		var safety: Dictionary = lifecycle.call("local_sample") if peer == int(session.call("local_peer_id")) else lifecycle.call("host_context", peer)
		var context: Dictionary = resources.call("host_context", peer, key, intent)
		out.peers.append({"peer": peer, "character": character, "authority_revision": int(authority.call("revision", character)) if authority != null else -1,
			"actor": actor != null, "actor_pos": str(actor.global_position) if actor != null else "",
			"distance": actor.global_position.distance_to(source.global_position) if actor != null and source != null else -1.0,
			"safety": safety, "in_combat": session.call("_altar_peer_in_combat", peer),
			"admitted": not (session.call("admitted_character_state", peer) as Dictionary).is_empty(),
			"context_empty": context.is_empty(), "context_expected_revision": context.get("expected_revision"),
			"lifecycle": _f32_lifecycle_diag(lifecycle, session, game, peer)})
	return out

func _f32_lifecycle_diag(lifecycle: Node, session: Node, game: Node, peer: int) -> Dictionary:
	if peer == int(session.call("local_peer_id")): return {}
	var observation: Dictionary = (lifecycle.get("_observations") as Dictionary).get(peer, {})
	var out := {"observation": not observation.is_empty()}
	if observation.is_empty(): return out
	var sample: Dictionary = observation.sample
	out.age_ms = Time.get_ticks_msec() - int(observation.seen_at)
	out.character_ok = sample.character_id == session.call("_authority_character", peer)
	out.epoch_ok = sample.session_epoch == session.call("_altar_current_epoch")
	out.world_ok = sample.world_instance_id == game.get("world").reward_delivery_namespace
	var actor: Node = lifecycle.call("remote_body", peer)
	out.actor = actor != null
	if actor != null:
		out.net_realm = str(actor.get("net_realm"))
		out.sample_realm = str(sample.realm)
		out.physics = actor.is_physics_processing()
		out.aquatic = actor.get("aquatic") != null
	out.personal = not (session.get("_character_authority").call("state", sample.character_id) as Dictionary).is_empty()
	var halls := 0
	for hall: Node in get_nodes_in_group("crossing_halls"): halls += 1
	out.crossing_halls = halls
	return out

func _f32_press_at(at_unix_ms: float) -> void:
	while Time.get_unix_time_from_system() * 1000.0 < at_unix_ms:
		await physics_frame
	_f32_press_now()

func _f32_press_now() -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null or _f32_node == null or not is_instance_valid(_f32_node):
		_f32_press = "no_node"
		return {"verdict": "ERROR", "detail": "no mounted node"}
	if not bool(_f32_node.call("_renewable_ready", game)):
		# The node's own gate refuses a depleted source before any request.
		_f32_press = "not_ready"
	else:
		_f32_press = "submitted"
	var prompt := _f32_node.get_node_or_null(^"Interactable")
	if prompt == null:
		return {"verdict": "ERROR", "detail": "node has no Interactable"}
	prompt.emit_signal("activated")
	return {"verdict": "PASS", "detail": "pressed (%s)" % _f32_press}

func _f32_counts(slots: Variant, items: Array) -> Dictionary:
	var out := {}
	for item: Variant in items: out[str(item)] = 0
	if slots is Array:
		for slot: Variant in slots:
			if slot is Dictionary and out.has(str(slot.get("id", ""))):
				out[str(slot.id)] += int(slot.get("n", 0))
	return out

func _f32_probe(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	if game == null: return {}
	var items: Array = args.get("items", []) as Array
	var session: Node = game.get("session")
	var world: RefCounted = game.get("world")
	var local: RefCounted = game.get("local")
	var character := str(local.get("character_id"))
	var inv: RefCounted = game.get("inventory")
	var counts := {}
	for item: Variant in items: counts[str(item)] = int(inv.call("count", str(item)))
	var receipts: Array = []
	for r: Variant in (local.get("redesign_character") as Dictionary).get("transaction_receipts", []):
		if str(r).contains(":f32:"): receipts.append(str(r))
	var rows: Array = []
	for value: Variant in (world.get("reward_deliveries") as Dictionary).values():
		if value is Dictionary and value.get("action") == "resource" \\
			and (value.get("intent", {}) as Dictionary).get("request", {}).get("site_id") == _f32_site:
			rows.append({"status": value.get("status"), "character_id": value.get("character_id"),
				"receipt": value.get("receipt"), "action_id": value.intent.request.get("action_id")})
	var saver: RefCounted = game.get("save_system")
	var disk_character: Dictionary = {}
	var disk_world_stock: Variant = null
	var disk_world_rows := 0
	if saver != null:
		saver.call("finish_fallback")
		var saved: Dictionary = (saver.call("characters") as RefCounted).call("read", character)
		var disk_receipts: Array = []
		for r: Variant in (saved.get("redesign_character", {}) as Dictionary).get("transaction_receipts", []):
			if str(r).contains(":f32:"): disk_receipts.append(str(r))
		disk_character = {"present": not saved.is_empty(), "counts": _f32_counts(saved.get("inventory", []), items), "receipts": disk_receipts}
		if bool(session.call("is_host")):
			var wsaved: Dictionary = (saver.call("worlds") as RefCounted).call("read", str(world.get("world_id")))
			disk_world_stock = (wsaved.get("redesign_world", {}) as Dictionary).get("node_cycles", {}).get("sites", {}).get(_f32_realm + ":" + _f32_site, null)
			for value: Variant in (wsaved.get("reward_deliveries", {}) as Dictionary).values():
				if value is Dictionary and value.get("action") == "resource" \\
					and (value.get("intent", {}) as Dictionary).get("request", {}).get("site_id") == _f32_site: disk_world_rows += 1
	var resources := _f32_resources()
	return {"character_id": character, "is_host": bool(session.call("is_host")), "day": int(game.get("day")),
		"stock": resources.call("stock", _f32_realm, _f32_site) if resources != null else {},
		"node": _f32_node != null and is_instance_valid(_f32_node),
		"ready": bool(_f32_node.call("_renewable_ready", game)) if _f32_node != null and is_instance_valid(_f32_node) else null,
		"claiming": bool(_f32_node.get("_claiming")) if _f32_node != null and is_instance_valid(_f32_node) else null,
		"pending": (resources.get("_pending") as Dictionary).size() if resources != null else -1,
		"press": _f32_press, "settled": _f32_settled.duplicate(true), "counts": counts, "receipts": receipts,
		"rows": rows, "disk_character": disk_character, "disk_world_stock": disk_world_stock, "disk_world_rows": disk_world_rows}
"""

var _runner_path := ""
var _outputs: Dictionary = {}


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	if not await launch(2, "world"):
		quit(await finish())
		return
	if not await _pass(0, "host", {}):
		quit(await finish())
		return
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	if not await _pass(1, "join", {"host": "127.0.0.1", "port": port}):
		quit(await finish())
		return
	for i in 2:
		if not await _pass(i, "expect_peers", {"count": 2}):
			quit(await finish())
			return

	if OS.get_environment("TB_F32_DIAG_PORTAL_FLAG") == "1":
		print("F32 CONTENTION DIAGNOSTIC MODE: host portal flag forced on in memory; this run is NOT acceptance evidence")
		if not await _pass(0, "f32_diag_portal_flag", {}):
			quit(await finish())
			return
	for i in 2:
		if not await _pass(i, "save_character_here", {}):
			quit(await finish())
			return
	# Race 1: one shared instant. Race 2: the guest presses first (host 400 ms
	# later) so the guest-owner save/ACK winner path is exercised too.
	if not await _race(SITE, 0.0, "simultaneous", -1):
		quit(await finish())
		return
	if not await _race(SITE_GUEST_FIRST, 400.0, "guest-first", 1):
		quit(await finish())
		return
	print("F32 CONTENTION verdict: two-character node races, one commit each (four-character run is owner-kit/nightly scope, not this smoke)")
	quit(await finish())


func _race(site: String, lead_ms: float, label: String, expected_winner: int) -> bool:
	_outputs = preload("res://scripts/world/renewable_site_catalog.gd").by_id(REALM, site).get("outputs", {})
	check(not _outputs.is_empty(), "SETUP [%s]: canonical F32 site %s:%s exists with outputs %s" % [label, REALM, site, str(_outputs)])
	# Opposite sides of the same node, both inside the host's 2.6 m range.
	if not await _pass(0, "f32_stand", {"site": site, "realm": REALM, "offset": [6.0, 0.0], "approach": [1.3, 0.0]}, 4000 ): return false
	if not await _pass(1, "f32_stand", {"site": site, "realm": REALM, "offset": [-6.0, 0.0], "approach": [-1.3, 0.0]}, 4000 ): return false
	for i in 2: await step(i, "wait", {"frames": 120})

	var items: Array = _outputs.keys()
	var start := [await probe(0, "f32_node", {"items": items}), await probe(1, "f32_node", {"items": items})]
	print("F32 CONTENTION [" + label + "] start host: %s" % JSON.stringify(start[0]))
	print("F32 CONTENTION [" + label + "] start guest: %s" % JSON.stringify(start[1]))
	for i in 2:
		check(start[i] is Dictionary and bool(start[i].get("node", false)) and start[i].get("ready") == true,
			"SETUP: peer %d mounted the production node and reads it ready" % i)
	if not (start[0] is Dictionary and start[1] is Dictionary):
		return false
	check(start[0].character_id != start[1].character_id, "SETUP: two distinct characters")
	for i in 2:
		check(bool(start[i].disk_character.get("present", false)),
			"SETUP [%s]: peer %d's own character file exists before the race" % [label, i])
	check(_eq(start[0].stock, start[1].stock) and int(start[0].stock.get("revision", -1)) == 0,
		"SETUP: both peers read the same ready stock revision 0 (%s / %s)" % [str(start[0].stock), str(start[1].stock)])

	print("F32 CONTENTION [" + label + "] diag host: %s" % JSON.stringify(await probe(0, "f32_diag")))
	print("F32 CONTENTION [" + label + "] diag guest: %s" % JSON.stringify(await probe(1, "f32_diag")))
	# --- the race: one shared instant, two real presses ----------------------
	var press_at := Time.get_unix_time_from_system() * 1000.0 + PRESS_LEAD_MS
	for i in 2:
		if not await _pass(i, "f32_press", {"at_unix_ms": press_at + (lead_ms if i == 0 else 0.0)} ): return false
	var after := []
	for poll in SETTLE_POLLS:
		for i in 2: await step(i, "wait", {"frames": POLL_FRAMES})
		after = [await probe(0, "f32_node", {"items": items}), await probe(1, "f32_node", {"items": items})]
		if after[0] is Dictionary and after[1] is Dictionary and _quiet(after[0]) and _quiet(after[1]) \
			and int(after[0].stock.get("revision", 0)) >= 1 and int(after[1].stock.get("revision", 0)) >= 1: break
	print("F32 CONTENTION [" + label + "] after host: %s" % JSON.stringify(after[0]))
	print("F32 CONTENTION [" + label + "] after guest: %s" % JSON.stringify(after[1]))
	if not (after[0] is Dictionary and after[1] is Dictionary):
		check(false, "both peers still answer the probe after the race")
		return false

	# World stock: exactly one revision consumed, identical on both screens.
	for i in 2:
		check(int(after[i].stock.get("revision", -1)) == 1 and int(after[i].stock.get("generation", -1)) == 2,
			"peer %d reads exactly one stock revision consumed (%s)" % [i, str(after[i].stock)])
		check(after[i].ready == false, "peer %d sees the node depleted (next ready day %s, day %d)"
			% [i, str(after[i].stock.get("next_ready_day")), int(after[i].day)])
	check(_eq(after[0].stock, after[1].stock), "host and guest stock records are identical")

	# One grant, to one character, nothing duplicated.
	var winner := -1
	var loser := -1
	for i in 2:
		var gained := _gain(start[i], after[i])
		if _eq(gained, _expected()): winner = i
		elif _eq(gained, _zero()): loser = i
	check(winner >= 0 and loser >= 0 and winner != loser,
		"exactly one peer received the outputs (host gain %s, guest gain %s, expected %s)"
			% [str(_gain(start[0], after[0])), str(_gain(start[1], after[1])), str(_expected())])
	if winner < 0 or loser < 0 or winner == loser:
		return false
	if expected_winner >= 0:
		# First valid claim wins (MULTIPLAYER §10). The guest pressed 400 ms
		# before the host, with the node ready and nobody else in flight.
		check(winner == expected_winner, "[%s] the first valid claim (peer %d) is the one that won (winner peer %d; loser settled %s)"
			% [label, expected_winner, winner, str(after[loser].settled)])
	print("F32 CONTENTION [" + label + "] winner peer %d (%s), loser peer %d (%s)" % [winner, ("host" if winner == 0 else "guest"), loser, ("host" if loser == 0 else "guest")])

	# Winner: saved decision, receipt in memory and on its own disk.
	var won: Array = after[winner].settled
	check(won.size() == 1 and _saved(won[0].verdict),
		"winner's one press settled as an owner-saved, acknowledged decision (%s)" % str(won))
	var new_receipts := (after[winner].receipts as Array).filter(func(r: Variant) -> bool: return not (start[winner].receipts as Array).has(r))
	check(new_receipts.size() == 1 and new_receipts[0] == str(won[0].verdict.get("receipt", "")) if won.size() == 1 else false,
		"winner gained exactly one F32 receipt this race, the settled one (%s)" % str(new_receipts))
	var wdisk: Dictionary = after[winner].disk_character
	check(bool(wdisk.get("present", false)) and _eq(_diff(start[winner].disk_character.get("counts", {}), wdisk.get("counts", {})), _expected())
		and (wdisk.get("receipts", []) as Array).has(new_receipts[0] if new_receipts.size() == 1 else "-"),
		"winner's character file carries the exact gain and the same receipt (%s)" % str(wdisk))

	# Loser: clean refusal, no item, no receipt.
	var lost: Array = after[loser].settled
	if after[loser].press == "submitted":
		check(lost.size() == 1 and lost[0].verdict.get("ok") != true and lost[0].verdict.get("terminal_refusal") == true
			and not str(lost[0].verdict.get("reason", "")).is_empty(),
			"loser's in-flight press was refused terminally with a reason (%s)" % str(lost))
		# harvest_node.gd shows `verdict.reason` on the HUD verbatim, so the
		# reason must be a player sentence, not the machine code.
		var told := str(lost[0].verdict.get("reason", "")) if lost.size() > 0 else ""
		check(not told.is_empty() and told != str(lost[0].verdict.get("code", "")) and told.contains(" "),
			"loser's on-screen refusal is a player sentence, not the raw code (shown: '%s')" % told)
		print("F32 CONTENTION [" + label + "] loser shape A: refused '%s' (%s)" % [str(lost[0].verdict.get("code", "")) if lost.size() > 0 else "", str(lost[0].verdict.get("reason", "")) if lost.size() > 0 else ""])
	else:
		check(after[loser].press == "not_ready" and lost.is_empty(),
			"loser's press found the node already depleted and sent nothing (press '%s', settled %s)" % [after[loser].press, str(lost)])
		print("F32 CONTENTION [" + label + "] loser shape B: winner's delta depleted the node before the press")
	check(after[loser].receipts == start[loser].receipts, "loser gained no receipt (%s -> %s)" % [str(start[loser].receipts), str(after[loser].receipts)])
	check(_eq(_diff(start[loser].disk_character.get("counts", {}), after[loser].disk_character.get("counts", {})), _zero()),
		"loser's character file gained nothing (%s)" % str(after[loser].disk_character))

	# Host journal and host world save: one accepted row for the winner.
	var host: Dictionary = after[0]
	check(host.rows.size() == 1 and host.rows[0].status == "accepted" and host.rows[0].character_id == after[winner].character_id
		and after[winner].receipts.has(str(host.rows[0].receipt)),
		"host world journal holds exactly one accepted resource row, owned by the winner (%s)" % str(host.rows))
	check(host.disk_world_stock is Dictionary and _eq(host.disk_world_stock, host.stock) and int(host.disk_world_rows) == 1,
		"host world save on disk holds the consumed stock and one journal row (disk %s, rows %d)" % [str(host.disk_world_stock), int(host.disk_world_rows)])

	# Depleted for both: the loser presses again and is refused before any send.
	if not await _pass(loser, "f32_press", {} ): return false
	for i in 2: await step(i, "wait", {"frames": 90})
	var again: Variant = await probe(loser, "f32_node", {"items": items})
	var host_again: Variant = await probe(0, "f32_node", {"items": items})
	check(again is Dictionary and again.press == "not_ready" and _eq(again.counts, after[loser].counts)
		and again.settled.size() == after[loser].settled.size(),
		"loser's re-press on the depleted node is refused locally with no item (%s)" % (JSON.stringify(again) if again is Dictionary else "null"))
	check(host_again is Dictionary and host_again.rows.size() == 1 and _eq(host_again.stock, host.stock),
		"host stock and journal unchanged by the re-press")
	return true


func _pass(peer: int, action: String, args: Dictionary, frames: int = 3000) -> bool:
	var out: Dictionary = await step(peer, action, args, frames)
	var ok := str(out.get("verdict", "")) == "PASS"
	check(ok, "peer %d %s: %s" % [peer, action, str(out.get("detail", ""))])
	return ok


func _quiet(row: Dictionary) -> bool:
	return row.get("claiming") == false and int(row.get("pending", 1)) == 0


func _saved(verdict: Dictionary) -> bool:
	return verdict.get("ok") == true and verdict.get("resolved") == true \
		and verdict.get("owner_saved") == true and verdict.get("owner_acknowledged") == true


func _expected() -> Dictionary:
	var out := {}
	for id: Variant in _outputs: out[str(id)] = int(_outputs[id])
	return out


func _zero() -> Dictionary:
	var out := {}
	for id: Variant in _outputs: out[str(id)] = 0
	return out


func _gain(before: Dictionary, after_row: Dictionary) -> Dictionary:
	return _diff(before.get("counts", {}), after_row.get("counts", {}))


func _diff(before: Dictionary, after_counts: Dictionary) -> Dictionary:
	var out := {}
	for id: Variant in _outputs:
		out[str(id)] = int(after_counts.get(str(id), 0)) - int(before.get(str(id), 0))
	return out


func _eq(a: Variant, b: Variant) -> bool:
	return JSON.stringify(a, "", true) == JSON.stringify(b, "", true)


## Scoped runner, written into this run's directory (never into the project).
func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	if _runner_path.is_empty():
		_runner_path = _run_dir.path_join("f32_contention_peer.gd")
		var file := FileAccess.open(_runner_path, FileAccess.WRITE)
		if file == null: return -1
		file.store_string(RUNNER_SOURCE)
		file.close()
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://")]
	if _is_windows(): args.append_array(["--log-file", log_path])
	args.append_array(["--script", _runner_path, "--",
		"--role=%s" % role, "--peer=%d" % i, "--control-port=%d" % control_port,
		"--enet-port=%d" % enet_port, "--scene=%s" % scene, "TB_NET_RUN_ID=%s" % _run_id])
	for extra: Variant in extra_args: args.append(str(extra))
	OS.set_environment("XDG_DATA_HOME", home)
	if _is_windows(): OS.set_environment("APPDATA", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", "0")
	if _is_windows(): return OS.create_process(OS.get_executable_path(), args)
	var quoted: Array[String] = [_shq(OS.get_executable_path())]
	for arg: Variant in args: quoted.append(_shq(str(arg)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" % [" ".join(quoted), _shq(log_path)]])
