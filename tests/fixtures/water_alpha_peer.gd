extends "res://tools/net/peer_runner.gd"

## Only test-side orchestration. All combat packets use the production Alpha
## transport; this helper never calls host_commit or mutates enemy HP/outcome.
func _execute_step(msg: Dictionary) -> Dictionary:
	var name := str(msg.get("action", ""))
	if not name.begins_with("water_alpha_"):
		return await super._execute_step(msg)
	var alpha := root.get_node_or_null("WaterArchipelago/WaterAlpha")
	if alpha == null or not alpha.ready_for_intents:
		return {"verdict": "FAIL", "detail": "Production Alpha service unavailable"}
	var game := root.get_node("Game")
	match name:
		"water_alpha_prepare":
			var world := alpha.get_parent()
			var player: Node3D = world.get_node("Player")
			var director: Node = world.get_node("EncounterDirector")
			if director.ally_body() != null:
				director.dismiss_active_creature()
			game.local.party.clear()
			var creature: RefCounted = SPECIES_DATA.spawn("water_mosshell")
			creature.set_level(49, NET_PROGRESSION.config())
			game.local.party.add(creature)
			player.global_position = alpha.body.global_position + Vector3(7, 0, 0)
			player.global_position.y = world.ground_height_at(player.position.x, player.position.z)
			# The fixture crosses islands in one step. Let the production owner
			# pose/landing acknowledgement settle before host-owned deployment.
			for frame in 240:
				await physics_frame
			var summoned: bool = await director.summon_active_creature()
			for frame in 90:
				await physics_frame
			return {"verdict": "PASS" if summoned else "FAIL", "detail": "Explicit level49 Mosshell/position fixture, production summon"}
		"water_alpha_engage":
			alpha.request_engage()
			for frame in 180:
				await physics_frame
				if alpha.get("_local_fight"):
					return {"verdict": "PASS", "detail": "Production request reached host and client manager entered"}
			return {"verdict": "FAIL", "detail": "No host-authorized local fight", "host_verdict": alpha.last_verdict,
				"deployed_position": str(alpha.primary.ally_body().global_position) if alpha.primary.ally_body() != null else "missing"}
		"water_alpha_forge":
			alpha.submit_encounter_intent({"kind": "catch_finished", "encounter_id": str(alpha.encounter_record().get("encounter_id", "")),
				"caught": true, "species_id": "water_aquaryn", "outcome": "caught", "eligible_character_ids": [game.local.character_id]})
			for frame in 30:
				await physics_frame
			return {"verdict": "PASS", "detail": "Forged catch result sent over real client transport without a host claim"}
		"water_alpha_wait_hit":
			if not alpha.get("_local_fight") or alpha.encounter_record().is_empty():
				return {"verdict": "FAIL", "detail": "No Alpha fight: unrelated wild damage cannot count"}
			var creature: RefCounted = alpha.primary.ally_instance()
			var before: float = creature.hp
			for frame in 540:
				await physics_frame
				if creature.hp < before:
					return {"verdict": "PASS", "detail": "Real host enemy strike reduced owned creature HP", "before": before, "after": creature.hp}
			return {"verdict": "FAIL", "detail": "No real host enemy strike reached client"}
	return {"verdict": "ERROR", "detail": "Unknown Alpha test action"}

func _execute_probe(msg: Dictionary) -> Variant:
	if str(msg.get("what", "")) != "water_alpha":
		return super._execute_probe(msg)
	var game := root.get_node("Game")
	var alpha := root.get_node_or_null("WaterArchipelago/WaterAlpha")
	if alpha == null or not alpha.ready_for_intents:
		return {"ready": false, "current_realm": game.current_realm}
	var rec: Dictionary = alpha.authority.record() if game.is_host() else alpha.encounter_record()
	var at: Vector3 = alpha.body.global_position
	var player_at: Vector3 = alpha.world.local_rig().global_position
	return {"ready": true, "path": str(alpha.get_path()), "shell": bool(alpha.world.simulation_only),
		"has_target": alpha.target_body() != null if game.is_host() else false,
		"catch_owner": alpha.get("_catch_arbiter").owner_of(alpha.authority.encounter_id, Time.get_ticks_msec()) if game.is_host() else 0,
		"player_position": [player_at.x, player_at.y, player_at.z],
		"current_realm": game.current_realm, "authority": alpha.is_alpha_authority(),
		"record": rec, "position": [at.x, at.y, at.z], "hp": alpha.body.instance.hp,
		"local_fight": alpha.get("_local_fight"), "stone": game.local.flags.has("water_swim_stone_earned"),
		"resolved": game.world.flags.has("water_aquaryn_resolved"), "character_id": game.local.character_id}
