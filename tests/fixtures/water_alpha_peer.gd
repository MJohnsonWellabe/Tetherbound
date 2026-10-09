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
		"water_alpha_attune_world_fixture":
			if not game.is_host():
				return {"verdict": "FAIL", "detail": "Only the host may name the test world"}
			game.world.world_id = "net-water-swim-stone-late-join"
			return {"verdict": "PASS", "detail": "Explicit isolated named-world fixture installed"}
		"water_alpha_attune_request":
			alpha.last_verdict = {}
			alpha.request_attunement()
			for frame in 240:
				await physics_frame
				if str(alpha.last_verdict.get("kind", "")) == "attune":
					return {"verdict": "PASS", "detail": "Attunement request reached host authority",
						"data": {"host_verdict": alpha.last_verdict.duplicate(true)}}
			return {"verdict": "FAIL", "detail": "No host attunement verdict arrived",
				"data": {"simulation_only": alpha.world.simulation_only,
					"pending": alpha.get("_attune_pending"), "last_verdict": alpha.last_verdict.duplicate(true)}}
		"water_alpha_attune_prepare":
			var chapter: Node = alpha.world.get_node_or_null("WaterChapter")
			var bodies: Dictionary = chapter.get("npc_bodies") if chapter != null else {}
			var iona := bodies.get("water_iona") as Node3D
			if iona == null:
				return {"verdict": "FAIL", "detail": "Production Iona body unavailable"}
			alpha.world.local_rig().global_position = iona.global_position + Vector3(1, 0, 0)
			for frame in 240:
				await physics_frame
			return {"verdict": "PASS", "detail": "Trainer stands beside production Iona"}
		"water_alpha_attune_talk":
			var talk_service: Node = alpha.world.get_node_or_null("WaterNPCs")
			var talk_panel: Node = alpha.world.get_node_or_null("DialoguePanel")
			if talk_service == null or talk_panel == null or not bool(talk_service.call("start_conversation", "water_iona")):
				return {"verdict": "FAIL", "detail": "Normal Iona interaction did not start"}
			var conversation_id := str(talk_panel.call("runner").call("conversation_id"))
			if conversation_id != "water_iona_attunement":
				return {"verdict": "FAIL", "detail": "Iona selected " + conversation_id}
			for line in 8:
				talk_panel.call("advance")
				await physics_frame
				if not bool(talk_panel.call("is_open")):
					break
			for frame in 300:
				await physics_frame
				if game.local.flags.has("water_swim_stone_earned"):
					return {"verdict": "PASS", "detail": "Iona dialogue earned the host-issued personal Stone"}
			return {"verdict": "FAIL", "detail": "Completed Iona attunement did not deliver the Stone",
				"data": {"host_verdict": alpha.last_verdict.duplicate(true)}}
		"water_alpha_attune_repeat":
			var repeat_service: Node = alpha.world.get_node_or_null("WaterNPCs")
			var refused_repeat := repeat_service == null or not bool(repeat_service.call("start_conversation", "water_iona", "water_iona_attunement"))
			return {"verdict": "PASS" if refused_repeat else "FAIL",
				"detail": "Already rewarded character cannot replay attunement" if refused_repeat else "Attunement replay opened"}
		"water_alpha_resolved_engage":
			alpha.request_engage()
			for frame in 240:
				await physics_frame
				if str(alpha.last_verdict.get("kind", "")) == "engage":
					var refused_engage := not bool(alpha.last_verdict.get("ok", false))
					return {"verdict": "PASS" if refused_engage else "FAIL",
						"detail": "Resolved shared encounter remains non-repeatable",
						"host_verdict": alpha.last_verdict.duplicate(true)}
			return {"verdict": "FAIL", "detail": "No resolved-engage verdict arrived"}
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
		# A host folds its simulation shell as soon as the last Water peer
		# leaves. No Alpha node is the strongest possible cleanup result; report
		# its observable semantics explicitly instead of letting probe defaults
		# misdescribe an absent service as a live target and locked claim.
		return {"ready": false, "service_absent": alpha == null,
			"current_realm": game.current_realm, "record": {},
			"has_target": false, "catch_owner": 0}
	var rec: Dictionary = alpha.authority.record() if game.is_host() else alpha.encounter_record()
	var at: Vector3 = alpha.body.global_position
	var player_at: Vector3 = alpha.world.local_rig().global_position
	var character_id := str(game.local.character_id)
	var probe_args: Dictionary = msg.get("args", {}) as Dictionary
	var entitlement_character := str(probe_args.get("character_id", character_id))
	var entitlement_id: String = preload("res://scripts/world/water_alpha_rewards.gd").entitlement(entitlement_character)
	var saved_flags: Array = game.world.flags.save_data().get("flags", [])
	return {"ready": true, "path": str(alpha.get_path()), "shell": bool(alpha.world.simulation_only),
		"has_target": alpha.target_body() != null if game.is_host() else false,
		"catch_owner": alpha.get("_catch_arbiter").owner_of(alpha.authority.encounter_id, Time.get_ticks_msec()) if game.is_host() else 0,
		"player_position": [player_at.x, player_at.y, player_at.z],
		"current_realm": game.current_realm, "authority": alpha.is_alpha_authority(),
		"record": rec, "position": [at.x, at.y, at.z], "hp": alpha.body.instance.hp,
		"local_fight": alpha.get("_local_fight"), "stone": game.local.flags.has("water_swim_stone_earned"),
		"resolved": game.world.flags.has("water_aquaryn_resolved"), "character_id": character_id,
		"entitled": preload("res://scripts/world/water_alpha_rewards.gd").entitled(game.world, entitlement_character),
		"entitlement_count": saved_flags.count(entitlement_id),
		"last_verdict": alpha.last_verdict.duplicate(true),
		"capture_claims": game.world.water_capture_claims.size()}
