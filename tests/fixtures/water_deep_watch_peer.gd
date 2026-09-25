extends "res://tools/net/peer_runner.gd"

## Test-side orchestration for smoke_net_water_deep_watch_chart. Poses are
## teleport fixtures. Tidecoil resolution invokes the production Water director's
## won-fight terminal handler on the real named body (no fight is played); the
## claim uses the production pickup body and LedgerRPC transport; the host rule
## is never called directly.
const GATED := "water:deep_watch:pickup:002"
const RESOLVED := "water_named_deep_watch_tidecoil_resolved"
const TIDECOIL_ID := "water_deep_watch_tidecoil"
const TIDECOIL_SITE := Vector3(1483.196, -0.5075, 3427.917)
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
	return {"verdict": "ERROR", "detail": "Unknown Deep Watch action"}


func _execute_probe(msg: Dictionary) -> Variant:
	if str(msg.get("what", "")) != "deep_watch":
		return super._execute_probe(msg)
	var game := root.get_node("Game")
	var receipts := 0
	for flag: Variant in game.world.flags.all_set():
		if str(flag).begins_with("water_claim:") and str(flag).ends_with(":" + GATED):
			receipts += 1
	return {"resolved": game.world.flags.has(RESOLVED), "receipts": receipts,
		"character_id": str(game.local.character_id), "host": bool(game.is_host())}
