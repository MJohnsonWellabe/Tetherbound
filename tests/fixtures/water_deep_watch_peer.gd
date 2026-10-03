extends "res://tools/net/peer_runner.gd"

## Test-side orchestration for smoke_net_water_deep_watch_chart. Poses are
## teleport fixtures, including owned actor placement/aim during the fight.
## Pre-session level49 Mosshells are disclosed input fixtures, not earned teams.
## The host opens the real retained Tidecoil; the resolver uses real quick input
## and host damage/terminal authority. No HP, outcome, flag or guest Alpha copy
## is fabricated. Claims use the production pickup and LedgerRPC transport.
const GATED := "water:deep_watch:pickup:002"
const RESOLVED := "water_named_deep_watch_tidecoil_resolved"
const TIDECOIL_ID := "water_deep_watch_tidecoil"
const TIDECOIL_SITE := Vector3(1262.0, -0.43, 3377.0)
const ISLAND_CENTRE := Vector3(1350.0, 0.0, 3500.0)

var _refusals: Array = []
var _named_encounter_id := ""
var _named_victory_source: Dictionary = {}


func _world() -> Node3D:
	return root.get_node_or_null("WaterArchipelago") as Node3D


func _pose(at: Vector3) -> void:
	var world := _world()
	var player := world.local_rig() as CharacterBody3D
	player.global_position = Vector3(at.x, float(world.ground_height_at(at.x, at.z)) + 0.1, at.z)
	player.velocity = Vector3.ZERO


func _cache_position() -> Vector3:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	for row: Dictionary in data.pickups:
		if str(row.id) == GATED:
			return Vector3(float(row.position[0]), 0.0, float(row.position[2]))
	return Vector3.INF


func _on_refused(kind: String, code: String, reason: String, _detail: Dictionary) -> void:
	_refusals.append({"kind": kind, "code": code, "reason": reason})


func _named_bodies(director: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for wild: Variant in director.get("_wild_creatures"):
		if is_instance_valid(wild) and str((wild as Node).get_meta("water_named_encounter", "")) == TIDECOIL_ID:
			out.append(wild as Node3D)
	return out


func _retain_named_victory(intent: Dictionary, _peer: int, verdict: Dictionary) -> void:
	if str(intent.get("encounter_id", "")) != _named_encounter_id \
		or verdict.get("ok") != true or verdict.get("delta", {}).get("killed") != true:
		return
	# Observe the immutable source already captured by the actual host, before
	# the normal terminal/streaming lifecycle can retire the runtime. No writes
	# to the encounter, creature, journal or world flags occur in this observer.
	_named_victory_source = _encounter_director().call("host_wild_victory_source", _named_encounter_id)
	_named_victory_source = _named_victory_source.duplicate(true)


func _execute_step(msg: Dictionary) -> Dictionary:
	var name := str(msg.get("action", ""))
	if not name.begins_with("deep_watch_"):
		return await super._execute_step(msg)
	var world := _world()
	if world == null or not bool(world.call("shell_build_complete")):
		return {"verdict": "FAIL", "detail": "Production Water world unavailable"}
	var game := root.get_node("Game")
	var pickups: Node = world.get_node("WaterPickups")
	var args: Dictionary = msg.get("args", {})
	match name:
		"deep_watch_claim_locked":
			_pose(_cache_position() + Vector3(1.0, 0.0, 0.0))
			for frame in 400:
				await physics_frame
			pickups.call("refresh")
			var spawned: bool = pickups.call("node_for", GATED) != null
			var ledger: Node = game.get("ledger")
			if not ledger.intent_refused.is_connected(_on_refused):
				ledger.intent_refused.connect(_on_refused)
			_refusals.clear()
			var verdict: Dictionary = ledger.call("submit", {"kind": "water_personal_pickup", "realm": "water",
				"pickup_id": GATED, "personal_claimed": false})
			var refusal: Dictionary = {}
			if not bool(verdict.get("pending", false)):
				refusal = {"kind": "water_personal_pickup", "code": str(verdict.get("code", "")), "reason": str(verdict.get("reason", ""))}
			for frame in 900:
				if not refusal.is_empty():
					break
				for entry: Dictionary in _refusals:
					if str(entry.kind) == "water_personal_pickup":
						refusal = entry
				await physics_frame
			var ok := not spawned and str(refusal.get("code", "")) == "locked"
			return {"verdict": "PASS" if ok else "FAIL",
				"detail": "Locked cache withheld and host refused: %s" % str(refusal),
				"data": {"spawned": spawned, "refusal": refusal, "submit": verdict, "all_refusals": _refusals.duplicate(true),
					"message": str(game.get("_pending_world_message")), "candy": int(game.inventory.count("skill_candy_iii"))}}
		"deep_watch_stage":
			var stand := Vector3.INF
			for distance: float in [30.0, 40.0, 50.0, 60.0, 70.0, 80.0]:
				var candidate := TIDECOIL_SITE + (ISLAND_CENTRE - TIDECOIL_SITE).normalized() * distance
				if float(world.ground_height_at(candidate.x, candidate.z)) >= 0.8:
					stand = candidate
					break
			if not stand.is_finite():
				return {"verdict": "FAIL", "detail": "No dry stand within Tidecoil's activation reach"}
			_pose(stand)
			var director: Node = world.get_node("EncounterDirector")
			for frame in mini(300, int(msg.get("budget_frames", 1200))):
				await physics_frame
				var bodies := _named_bodies(director)
				if not game.is_host():
					if not bodies.is_empty():
						return {"verdict": "FAIL", "detail": "Guest has an independent named Tidecoil body"}
					continue
				if bodies.size() != 1:
					continue
				var body := bodies[0]
				var cycle: Dictionary = director.call("foundation_alpha_cycle", TIDECOIL_ID)
				var packet: Dictionary = body.get_meta("foundation_alpha_packet", {})
				if cycle.get("status") != "active" or packet.is_empty() or packet != cycle.get("spawn_traits", {}) \
					or body.get_meta("foundation_alpha_site", "") != TIDECOIL_ID \
					or int(body.get_meta("foundation_alpha_generation", 0)) != int(cycle.get("generation", -1)):
					continue
				if not director.is_connected("host_strike_finished", _retain_named_victory):
					director.connect("host_strike_finished", _retain_named_victory)
				return {"verdict": "PASS", "detail": "Exactly one original host retained Tidecoil is resident",
					"data": {"body_id": body.get_instance_id(), "card": WATER_CAPTURE_CODEC.encode(body.get("instance")),
						"alpha_generation": int(cycle.generation), "packet": packet.duplicate(true)}}
			return {"verdict": "PASS" if not game.is_host() else "FAIL",
				"detail": "Guest staged without an Alpha copy" if not game.is_host() else "Original retained host Tidecoil never became resident"}
		"deep_watch_open":
			if not game.is_host():
				return {"verdict": "FAIL", "detail": "Only the host opens the retained named encounter"}
			var opened: Dictionary = await _step_engage_wild({"foundation_alpha_site": TIDECOIL_ID})
			if opened.get("verdict") != "PASS": return opened
			var director := _encounter_director()
			var rec: Dictionary = director.call("encounter_record")
			_named_encounter_id = str(rec.get("encounter_id", ""))
			return {"verdict": "PASS" if not _named_encounter_id.is_empty() else "FAIL",
				"detail": "Host opened the original retained Tidecoil through production interaction",
				"data": {"encounter_id": _named_encounter_id, "opponent": rec.get("opponent", {})}}
		"deep_watch_wait_resolver":
			if not game.is_host(): return {"verdict": "FAIL", "detail": "Host runtime observation required"}
			var director := _encounter_director()
			var id := str(args.get("encounter_id", ""))
			var resolver := int(args.get("resolver_peer", 0))
			for frame in mini(1200, int(msg.get("budget_frames", 1200))):
				await physics_frame
				var rec: Dictionary = director.get("_encounter_host").call("record", id)
				var participants: Dictionary = rec.get("participants", {})
				var runtime: Node = director.call("_shared_host_fight", id) as Node
				var manager := _combat_manager()
				var local_present := manager != null and bool(manager.call("is_fighting"))
				if rec.get("phase") == "active" and participants.size() == 1 and participants.has(resolver) \
					and is_instance_valid(runtime) and local_present == (resolver == int(director.call("_local_peer_id"))):
					return {"verdict": "PASS", "detail": "Canonical host runtime remains active for the sole resolver",
						"data": {"record": rec.duplicate(true), "body_generation": int(runtime.get("body_generation")),
							"body_id": runtime.call("body").get_instance_id()}}
			return {"verdict": "FAIL", "detail": "Actual withdrawal did not leave the resolver in the canonical host runtime"}
		"deep_watch_resolve":
			var director := _encounter_director()
			var manager := _combat_manager()
			var id := str(args.get("encounter_id", ""))
			if id.is_empty() or manager == null or str(manager.call("encounter_id")) != id:
				return {"verdict": "FAIL", "detail": "Resolver is not admitted to the actual named encounter"}
			var began := _physics_count
			var budget := mini(1200, int(msg.get("budget_frames", 1200)))
			var presses := 0
			var defeated := false
			while _physics_count - began < budget:
				await physics_frame
				if _physics_count - began > budget: break
				if game.world.flags.has(RESOLVED):
					return {"verdict": "PASS", "detail": "Real resolver inputs completed host-authoritative Tidecoil",
						"data": {"encounter_id": id, "quick_presses": presses, "frames": _physics_count - began}}
				var rec: Dictionary = director.call("encounter_record")
				if rec.get("encounter_id") == id and rec.get("phase") == "done" \
					and float(rec.get("opponent", {}).get("hp", -1.0)) == 0.0:
					defeated = true
				if defeated:
					continue # Preserve the observed real defeat while its flag relay settles.
				if rec.get("encounter_id") != id or rec.get("opponent", {}).get("species_id") != "tidecoil":
					return {"verdict": "FAIL", "detail": "Resolver lost the original Tidecoil record"}
				if not bool(manager.call("is_fighting")):
					return {"verdict": "FAIL", "detail": "Resolver left the named fight before a real defeat"}
				if not bool(manager.call("quick_ready")) or budget - (_physics_count - began) < 30:
					continue
				var enemy: Node3D = manager.call("enemy_body") as Node3D
				if not is_instance_valid(enemy):
					return {"verdict": "FAIL", "detail": "Actual named opponent presentation is unavailable"}
				# Disclosed fixture placement/aim; production owns cooldown, move
				# commitment, wind-up, damage, durable resolution and flag relay.
				var reach := float(manager.call("combat_move_reach", "quick"))
				if not is_finite(reach) or reach <= 0.0:
					return {"verdict": "FAIL", "detail": "Actual resolver quick move has no valid reach"}
				# Use the production size-aware reach; a fixed short offset can
				# overlap the real large bodies and be displaced before the tap.
				var at := enemy.global_position + Vector3(maxf(0.5, reach - 0.25), 0.0, 0.0)
				var target: Vector3 = enemy.call("centre")
				var placed: Dictionary = await _step_place_creature({"at": [at.x, at.y, at.z],
					"face": [target.x, target.y, target.z], "settle": 20})
				if placed.get("verdict") != "PASS": return placed
				if not bool(manager.call("quick_ready")) or budget - (_physics_count - began) < 30: continue
				var pressed: Dictionary = await _step_press({"action": "combat_quick"})
				if pressed.get("verdict") != "PASS": return pressed
				presses += 1
			return {"verdict": "FAIL", "detail": "Actual Tidecoil defeat/resolution did not finish within the original frame budget",
				"data": {"encounter_id": id, "quick_presses": presses,
					"record": director.call("encounter_record"), "refusal": manager.get("last_encounter_refusal")}}
		"deep_watch_claim":
			_pose(_cache_position() + Vector3(1.0, 0.0, 0.0))
			var before := int(game.inventory.count("skill_candy_iii"))
			var cache: Node = null
			for frame in 240:
				await physics_frame
				cache = pickups.call("node_for", GATED)
				if cache != null:
					break
			if cache == null:
				return {"verdict": "FAIL", "detail": "Resolved cache never streamed in on this peer"}
			for frame in 60:
				await physics_frame
			_refusals.clear()
			cache.call("_on_picked_up")
			for frame in 900:
				await physics_frame
				if game.local.flags.has("water_candy:" + GATED) and int(game.inventory.count("skill_candy_iii")) == before + 1:
					return {"verdict": "PASS", "detail": "Production claim paid one Candy III through the host"}
			return {"verdict": "FAIL", "detail": "Claim did not complete", "data": {"refusals": _refusals.duplicate(true),
				"candy": int(game.inventory.count("skill_candy_iii"))}}
	return {"verdict": "ERROR", "detail": "Unknown Deep Watch action"}


func _execute_probe(msg: Dictionary) -> Variant:
	if str(msg.get("what", "")) != "deep_watch":
		return super._execute_probe(msg)
	var game := root.get_node("Game")
	var receipts := 0
	for flag: Variant in game.world.flags.all_set():
		if str(flag).begins_with("water_claim:") and str(flag).ends_with(":" + GATED):
			receipts += 1
	var director := _encounter_director()
	var owned: Array = []
	for creature: RefCounted in game.local.party.members():
		owned.append({"uid": str(creature.get("uid")), "species": str(creature.get("species_id")), "level": int(creature.get("level"))})
	return {"resolved": game.world.flags.has(RESOLVED), "receipts": receipts,
		"character_id": str(game.local.character_id), "host": bool(game.is_host()), "owned": owned,
		"named_bodies": _named_bodies(director).size() if director != null else -1,
		"victory_source": _named_victory_source.duplicate(true),
		"alpha_cycle": game.world.redesign_world.get("alpha_cycles", {}).get("sites", {}).get(TIDECOIL_ID, {}).duplicate(true)}
