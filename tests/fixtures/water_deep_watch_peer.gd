extends "res://tools/net/peer_runner.gd"

## Test-side orchestration for smoke_net_water_deep_watch_chart. Poses are
## teleport fixtures. The accepted_alpha_cycle argument drives a genuinely
## admitted fight with ordinary creature inputs; the legacy terminal-handler
## fixture remains available to callers omitting that argument. The claim uses
## the production pickup body and LedgerRPC transport, never a direct host rule.
const GATED := "water:deep_watch:pickup:002"
const RESOLVED := "water_named_deep_watch_tidecoil_resolved"
const TIDECOIL_ID := "water_deep_watch_tidecoil"
const TIDECOIL_SITE := Vector3(1262.0, -0.43, 3377.0)
const ISLAND_CENTRE := Vector3(1350.0, 0.0, 3500.0)

var _refusals: Array = []


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


func _execute_step(msg: Dictionary) -> Dictionary:
	var name := str(msg.get("action", ""))
	if not name.begins_with("deep_watch_"):
		return await super._execute_step(msg)
	var world := _world()
	if world == null or not bool(world.call("shell_build_complete")):
		return {"verdict": "FAIL", "detail": "Production Water world unavailable"}
	var game := root.get_node("Game")
	var pickups: Node = world.get_node("WaterPickups")
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
		"deep_watch_resolve":
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
			var body: Node3D = null
			for frame in 300:
				await physics_frame
				for wild: Variant in director.get("_wild_creatures"):
					if is_instance_valid(wild) and str((wild as Node).get_meta("water_named_encounter", "")) == TIDECOIL_ID:
						body = wild as Node3D
				if body != null:
					break
			if body == null:
				return {"verdict": "FAIL", "detail": "Named Tidecoil body never became resident"}
			if msg.get("args", {}).get("accepted_alpha_cycle") == true:
				var deployed := await _step_deploy_creature({})
				if deployed.get("verdict") != "PASS": return deployed
				var engaged := await _step_engage_wild({"foundation_alpha_site": TIDECOIL_ID})
				if engaged.get("verdict") != "PASS": return engaged
				var manager := _combat_manager()
				var encounter_id := str(manager.call("encounter_id"))
				var owner = game.local
				var host_world = game.world
				var session = game.session
				var epoch := str(session.call("_altar_current_epoch"))
				for frame in 600:
					if game.local != owner or game.world != host_world or game.session != session \
							or not is_instance_valid(manager) or not is_instance_valid(session) \
							or str(session.call("_altar_current_epoch")) != epoch:
						return {"verdict": "FAIL", "detail": "Alpha fight owner/world/session/epoch changed"}
					if game.world.flags.has(RESOLVED):
						return {"verdict": "PASS", "detail": "Genuine Alpha fight resolved through ordinary creature inputs",
							"data": {"encounter_id": encounter_id}}
					var current_encounter := str(manager.call("encounter_id"))
					if not current_encounter.is_empty() and current_encounter != encounter_id:
						return {"verdict": "FAIL", "detail": "Alpha fight changed before original resolution"}
					if current_encounter == encounter_id and bool(manager.call("quick_ready")) and manager.get("_move_awaiting_host") != true:
						var ally: Node3D = manager.get("_ally_body")
						var enemy: Node3D = manager.get("_wild")
						if is_instance_valid(ally) and is_instance_valid(enemy):
							var target: Vector3 = enemy.call("centre")
							ally.call("place_on_ground", target + Vector3(1.1, 0, 0))
							ally.call("face_towards", target)
							var pressed := await _inject("combat_quick", 1)
							if pressed.get("verdict") != "PASS": return pressed
					await physics_frame
				return {"verdict": "FAIL", "detail": "No genuine Alpha resolution within original bounded fight input",
					"data": {"encounter_id": encounter_id}}
			director.set("_engaged_with", body)
			director.call("_on_combat_exited", "won")
			for frame in 10:
				await physics_frame
			var local: bool = game.world.flags.has(RESOLVED)
			return {"verdict": "PASS" if local else "FAIL",
				"detail": "Director terminal handler recorded Tidecoil on this peer: %s (host=%s)" % [local, game.is_host()]}
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
		"deep_watch_depart_alpha":
			var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
			var at: Array = cfg.entry_anchors.from_stormwood.position
			_pose(Vector3(float(at[0]), float(at[1]), float(at[2])))
			for frame in 120: await physics_frame
			return {"verdict": "PASS", "detail": "Disclosed pose at authored First Shore arrival; production census must confirm departure"}
		"deep_watch_visit_alpha":
			_pose(TIDECOIL_SITE + (ISLAND_CENTRE - TIDECOIL_SITE).normalized() * 60.0)
			for frame in 120: await physics_frame
			return {"verdict": "PASS", "detail": "Disclosed pose within original Tidecoil residency radius"}
	return {"verdict": "ERROR", "detail": "Unknown Deep Watch action"}


func _execute_probe(msg: Dictionary) -> Variant:
	if str(msg.get("what", "")) != "deep_watch":
		return super._execute_probe(msg)
	var game := root.get_node("Game")
	var receipts := 0
	for flag: Variant in game.world.flags.all_set():
		if str(flag).begins_with("water_claim:") and str(flag).ends_with(":" + GATED):
			receipts += 1
	var rules := preload("res://scripts/repeatables/alpha_respawns.gd")
	var cycle: Dictionary = game.world.redesign_world.get("alpha_cycles", {}).get("sites", {}).get(TIDECOIL_ID, {}).duplicate(true)
	var bodies: Array = []
	var world := _world()
	if world != null:
		for wild: Node3D in world.get_node("EncounterDirector").get("_wild_creatures"):
			if not is_instance_valid(wild) or wild.is_queued_for_deletion() or not wild.visible \
					or not bool(wild.call("is_alive")) or wild.get_meta("foundation_alpha_site", "") != TIDECOIL_ID: continue
			var instance: RefCounted = wild.get("instance")
			bodies.append({"uid": str(instance.get("uid")), "generation": wild.get_meta("foundation_alpha_generation", 0),
				"packet": wild.get_meta("foundation_alpha_packet", {}).duplicate(true),
				"rolled_traits": instance.get("rolled_traits").duplicate(), "initialized": instance.get("traits_initialized")})
	# Read the already-cached store and physical document. No worlds() getter,
	# autosave or fallback completion can manufacture this observation.
	var disk: Dictionary = {}
	var store: RefCounted = game.save_system.get("_worlds")
	if store != null:
		var path := str(store.call("path_for", str(game.world.world_id)))
		var readable := preload("res://scripts/save/atomic_save_file.gd").readable_path(path)
		if FileAccess.file_exists(readable):
			var parsed: Variant = preload("res://scripts/save/save_document.gd").parse(FileAccess.get_file_as_string(readable))
			if parsed is Dictionary: disk = parsed
	var source: Dictionary = world.get_node("EncounterDirector").call("host_wild_victory_source",
		str(msg.get("args", {}).get("encounter_id", ""))) if world != null and game.is_host() else {}
	return {"resolved": game.world.flags.has(RESOLVED), "receipts": receipts,
		"character_id": str(game.local.character_id), "host": bool(game.is_host()), "day": int(game.world.day),
		"world_namespace": str(game.world.reward_delivery_namespace), "cycle": cycle, "bodies": bodies,
		"retained": rules.retained_spawn(game.world.redesign_world, TIDECOIL_ID),
		"saved_cycle": disk.get("redesign_world", {}).get("alpha_cycles", {}).get("sites", {}).get(TIDECOIL_ID, {}),
		"saved_retained": rules.retained_spawn(disk.get("redesign_world", {}), TIDECOIL_ID),
		"victory_source": source.duplicate(true),
		"accepted_kill": source.get("accepted", {}).get("delta", {}).get("killed") == true,
		"enemy_fainted": source.get("enemy_record", {}).get("fainted") == true}
