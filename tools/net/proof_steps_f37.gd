extends RefCounted
const INPUT := preload("res://tools/net/proof_steps.gd")
const SUNKEN := preload("res://scripts/world/ripplet_sunken_rules.gd")
const CLAIM := preload("res://scripts/world/ledger_claim.gd")
const RIPPLET := preload("res://scripts/player/ripplet_traversal.gd")

## Explicit F37 fixture/control adapter. It earns no feast or chapter progress.
static func step(runner: SceneTree, action: String, args: Dictionary) -> Dictionary:
	var game := runner.root.get_node("Game")
	if action == "f37_record_disconnect":
		var earlier: Dictionary = runner.get_meta("f37_saved_dive", {})
		if earlier.is_empty() or game.session.is_active():
			return {"verdict":"FAIL","detail":"disconnect save observation requires the retained prior save and inactive session"}
		var saved: Dictionary = game.save_system.characters().read(str(earlier.character_id))
		var mount: Dictionary = saved.get("player_pose", {}).get("aquatic", {}).get("mount", {})
		var debt: float = float(mount.get("dive", {}).get("remaining_s", -1.0))
		if saved.get("character_id") != earlier.character_id or mount.get("creature_uid") != earlier.uid \
			or debt <= 0.0 or debt > float(earlier.remaining_s):
			return {"verdict":"FAIL","detail":"final production disconnect save lost the owned mount or refreshed its spent allowance",
				"data":{"earlier":earlier,"mount":mount}}
		runner.set_meta("f37_saved_dive", {"uid":earlier.uid,"remaining_s":debt,"character_id":earlier.character_id})
		return {"verdict":"PASS","detail":"final disconnect-written character file supplies the exact returning debt",
			"data":{"saved_dive_recorded":true,"uid":earlier.uid,"remaining_s":debt,"prior_remaining_s":earlier.remaining_s}}
	var world := runner.current_scene
	if world == null or not world.has_method("world_realm") or world.world_realm() != "water": return {"verdict":"ERROR","detail":"F37 requires Water"}
	var director := world.get_node("EncounterDirector")
	var riding := world.get_node("RidingController")
	if action == "f37_fixture":
		director.dismiss_active_creature()
		game.party.clear()
		var creature := preload("res://scripts/creatures/creature_species.gd").spawn("ripplet")
		creature.level = 30
		creature.recompute_stats_from_base(preload("res://scripts/creatures/progression.gd").config())
		game.party.add(creature)
		game.local.redesign_character = game.local.save_data().redesign_character
		game.local.redesign_character.creatures[creature.uid].breakthroughs = [1,2,3] if args.get("breakthrough",false) else [1,2]
		game.local.redesign_character.creatures[creature.uid].cap_level = 40 if args.get("breakthrough",false) else 30
		return {"verdict":"PASS","detail":"SETUP owned L30 Ripplet and explicit breakthrough fixture before admission","data":{"uid":creature.uid}}
	if action == "f37_mount":
		if not director.summon_active_creature(): return {"verdict":"FAIL","detail":"summon refused"}
		for frame in 30: await runner.physics_frame
		var player: Node3D = world.local_rig()
		player.global_position = director.ally_body().global_position + Vector3(2,0,0)
		for frame in 2: await runner.physics_frame
		if not await INPUT._tap(runner, "interact"):
			return {"verdict":"FAIL","detail":"physical mount input edge failed"}
		for frame in 120:
			await runner.physics_frame
			if riding.is_mounted(): return {"verdict":"PASS","detail":"ordinary mount prompt authorized"}
		return {"verdict":"FAIL","detail":"host did not authorize mount"}
	if action == "f37_deep_fixture":
		if not riding.is_mounted(): return {"verdict":"FAIL","detail":"not mounted"}
		var started := Engine.get_physics_frames()
		if args.get("continue_after_crossing", false):
			if not runner.has_meta("f37_current_started"):
				return {"verdict":"FAIL","detail":"deep continuation requires its actual preceding current crossing"}
			started = int(runner.get_meta("f37_current_started"))
		var crossing := {}
		if args.get("current_crossing", false):
			var before: Vector3 = riding.mount_body().global_position
			var flow: Vector3 = world.current_at(before)
			if Vector2(before.x + 161.911, before.z - 78.643).length() > 1.2 or flow.length() <= 0.0:
				return {"verdict":"FAIL","detail":"current crossing requires its actual authored start and nonzero flow"}
			var crossed: Dictionary = await runner.call("_step_move_to", {"x":-251.054,"z":121.941,"close_enough":1.0,"budget_frames":2400})
			if crossed.get("verdict") != "PASS" or not riding.is_mounted(): return {"verdict":"FAIL","detail":"ordinary mounted current crossing failed","data":crossed}
			var after: Vector3 = riding.mount_body().global_position
			var seconds := float(Engine.get_physics_frames() - started) / float(Engine.physics_ticks_per_second)
			var speed := Vector2(after.x - before.x, after.z - before.z).length() / maxf(seconds, 0.001)
			var human: float = world.local_rig().swim_controller.get("_config").human.speed_m_s
			crossing = {"from":before,"to":after,"current_before":flow,"current_after":world.current_at(after),
				"physics_seconds":seconds,"measured_m_s":speed,"human_reference_m_s":human}
			if speed <= human: return {"verdict":"FAIL","detail":"actual mounted crossing did not exceed configured human speed","data":crossing}
			if args.get("stop_after_crossing", false):
				runner.set_meta("f37_current_started", started)
				return {"verdict":"PASS","detail":"ordinary actual current crossing; deep continuation shares the same original movement allowance","data":crossing}
		var remaining := 2400 - (Engine.get_physics_frames() - started)
		if remaining <= 0: return {"verdict":"FAIL","detail":"ordinary deep approach exhausted its existing movement budget"}
		var moved: Dictionary = await runner.call("_step_move_to", {"x":-215.0,"z":166.0,"close_enough":0.8,"budget_frames":remaining})
		if moved.get("verdict") != "PASS": return moved
		for frame in 30: await runner.physics_frame
		var depth: float = world.water_depth_at(riding.mount_body().global_position) if riding.is_mounted() else 0.0
		return {"verdict":"PASS" if riding.is_mounted() and depth >= 8.0 else "FAIL",
			"detail":"ordinary mapped movement to the optional cache; actual deep-water clearance",
			"data":{"mounted":riding.is_mounted(),"depth_m":depth,"crossing":crossing}}
	if action == "f37_sunken_claim":
		var id := str(args.get("site_id", ""))
		var row := SUNKEN.site(id)
		if id not in ["lantern_arch_cache", "lantern_pearl_bed"] or row.is_empty() or not riding.is_mounted() or not riding.diving:
			return {"verdict":"FAIL","detail":"claim requires the authored Lantern find and an actual mounted dive"}
		var deadline := Engine.get_physics_frames() + 600
		var moved: Dictionary = await runner.call("_step_move_to", {"x":float(row.position[0]),"z":float(row.position[2]),"close_enough":0.8,"budget_frames":300})
		if moved.get("verdict") != "PASS": return moved
		var prompt: Node = world.get_node("RippletSunkenContent").get_node_or_null(NodePath(id))
		var arbiter := runner.get_first_node_in_group("interaction_arbiter")
		while Engine.get_physics_frames() < deadline and (arbiter == null or arbiter.winning_provider() != prompt):
			await runner.physics_frame
		if prompt == null or arbiter == null or arbiter.winning_provider() != prompt or not riding.is_mounted() or not riding.diving:
			var player: CharacterBody3D = world.local_rig()
			var carrier: Node3D = player.carrier()
			var winner: Node = arbiter.winning_provider() if arbiter != null else null
			var data := {"site_id":id, "prompt_exists":prompt != null, "mounted":riding.is_mounted(),
				"diving":riding.diving, "dive_remaining_s":riding.dive_remaining_s, "player_position":player.global_position,
				"carrier":carrier.get_path() if is_instance_valid(carrier) else "none",
				"winner":winner.get_path() if winner != null else "none",
				"input_owner":str(preload("res://scripts/ui/input_owner.gd").current(runner))}
			if prompt != null:
				data.merge({"enabled":prompt.enabled, "radius_m":prompt.radius, "prompt_position":prompt.global_position,
					"distance_m":player.global_position.distance_to(prompt.global_position),
					"offer":prompt.interaction_offer(player.global_position),
					"sight_clear":prompt.call("_has_line_of_sight", player.global_position)})
				var interaction := preload("res://scripts/world/interactable.gd")
				var sight: Vector3 = player.global_position + Vector3.UP * interaction.SIGHT_EYE_HEIGHT - prompt.global_position
				if sight.length() > interaction.SIGHT_SELF_CLEARANCE + interaction.SIGHT_TRAINER_CLEARANCE:
					var query := PhysicsRayQueryParameters3D.create(prompt.global_position + sight.normalized() * interaction.SIGHT_SELF_CLEARANCE,
						prompt.global_position + sight.normalized() * (sight.length() - interaction.SIGHT_TRAINER_CLEARANCE))
					query.collide_with_areas = false
					query.collision_mask = 0x7FFFFFFF
					var viewer: CollisionObject3D = arbiter.viewer() if arbiter != null else null
					if viewer != null and viewer.global_position.is_equal_approx(player.global_position): query.exclude = [viewer.get_rid()]
					var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
					var collider: Node = hit.get("collider")
					data["first_sight_hit"] = collider.get_path() if collider != null else "none"
					data["first_sight_hit_is_carrier"] = collider != null and collider == carrier
					data["first_sight_rid"] = str(hit.get("rid", RID()))
					data["first_sight_position"] = hit.get("position", Vector3.INF)
			return {"verdict":"FAIL","detail":"actual sunken prompt never won Interact", "data":data}
		var offer: Dictionary = prompt.call("interaction_offer", world.local_rig().global_position)
		if not offer.get("actionable", false): return {"verdict":"FAIL","detail":"winning sunken prompt is not currently actionable"}
		var key := SUNKEN.claim_key(row, game.world.flags, game.world.day)
		if key.is_empty() or game.world.flags.has(key): return {"verdict":"FAIL","detail":"sunken find was already spent before input"}
		var uid := str(director.ally_instance().uid)
		var item := str(row.item)
		var before: int = game.inventory.count(item)
		var transport := CLAIM.transport(world)
		if transport == null: return {"verdict":"FAIL","detail":"sunken claim has no actual ledger transport"}
		var heard := {"flag_commits":0,"code":"","reason":""}
		var on_delta := func(delta: Dictionary) -> void:
			if CLAIM.sets_world_flag(delta, key): heard.flag_commits += 1
		var on_refused := func(kind: String, code: String, reason: String, _detail: Dictionary) -> void:
			if kind == "ripplet_sunken_claim":
				heard.code = code
				heard.reason = reason
		transport.connect("delta_applied", on_delta)
		transport.connect("intent_refused", on_refused)
		var pressed: bool = await INPUT._tap(runner, "interact")
		while Engine.get_physics_frames() < deadline and heard.code == "" \
			and (not game.world.flags.has(key) or game.inventory.count(item) != before + int(row.count)):
			await runner.physics_frame
		var gained: int = game.inventory.count(item) - before
		var claimed: bool = pressed and game.world.flags.has(key) and gained == int(row.count) and heard.flag_commits == 1
		if claimed:
			heard.code = ""
			heard.reason = ""
			var repeat: Dictionary = CLAIM.submit(world, {"kind":"ripplet_sunken_claim","realm":"water","site_id":id,"creature_uid":uid,"claim_key":key})
			if not repeat.get("pending", false):
				heard.code = repeat.get("code", "")
				heard.reason = repeat.get("reason", "")
			while Engine.get_physics_frames() < deadline and heard.code == "": await runner.physics_frame
		transport.disconnect("delta_applied", on_delta)
		transport.disconnect("intent_refused", on_refused)
		var duplicate_refused: bool = claimed and heard.code == "refused" and str(heard.reason).contains("spent") \
			and heard.flag_commits == 1 and game.world.flags.has(key) and game.inventory.count(item) == before + int(row.count)
		return {"verdict":"PASS" if duplicate_refused else "FAIL","detail":"physical sunken claim and ordinary ledger duplicate refusal",
			"data":{"site_id":id,"item":item,"gained":gained,"flag":key,"flag_commits":heard.flag_commits,"duplicate_refused":duplicate_refused,"reason":heard.reason}}
	if action == "f37_hidden_route":
		var route := {}
		for candidate: Dictionary in RIPPLET.config().routes:
			if candidate.id == "lantern_arch_cut": route = candidate
		if route.is_empty() or not route.get("optional", false) or not riding.is_mounted() or not riding.diving:
			return {"verdict":"FAIL","detail":"optional authored route requires a live owned Ripplet dive"}
		var uid := str(director.ally_instance().uid)
		var approach: Dictionary = await runner.call("_step_move_to", {"x":float(route.from[0]),"z":float(route.from[2]),"close_enough":0.8,"budget_frames":300})
		if approach.get("verdict") != "PASS" or not riding.is_mounted() or not riding.diving:
			return {"verdict":"FAIL","detail":"ordinary submerged route approach failed","data":approach}
		var from: Vector3 = riding.mount_body().global_position
		var speed_before: float = riding.ride_speed_now()
		var started := Engine.get_physics_frames()
		var crossed: Dictionary = await runner.call("_step_move_to", {"x":float(route.to[0]),"z":float(route.to[2]),"close_enough":0.8,"budget_frames":400})
		var still_owned: bool = riding.is_mounted() and riding.diving and str(director.ally_instance().uid) == uid
		var after: Vector3 = riding.mount_body().global_position if riding.is_mounted() else Vector3.INF
		var seconds := float(Engine.get_physics_frames() - started) / float(Engine.physics_ticks_per_second)
		var passed: bool = crossed.get("verdict") == "PASS" and still_owned and speed_before > float(RIPPLET.config().surface_speed_m_s) \
			and Vector2(after.x - from.x, after.z - from.z).length() >= 30.0 and seconds > 0.0
		return {"verdict":"PASS" if passed else "FAIL","detail":"ordinary mapped submerged traversal of the authored optional Lantern arch cut",
			"data":{"route_id":route.id,"optional":route.optional,"uid":uid,"from":from,"to":after,"physics_seconds":seconds,
				"actual_route_speed_m_s":speed_before,"owned_dive_retained":still_owned,"crossing":crossed}}
	if action == "f37_jump":
		if not await INPUT._tap(runner, "jump"):
			return {"verdict":"FAIL","detail":"physical Dive input edge failed"}
		for frame in 45: await runner.physics_frame
		return {"verdict":"PASS","detail":"ordinary Jump tap"}
	if action == "f37_status":
		var player: Node = world.local_rig()
		var instance: RefCounted = director.ally_instance()
		var data := {"mounted":riding.is_mounted(),"diving":riding.diving,
			"dive_remaining_s":riding.dive_remaining_s,"swim_mode":player.swim_controller.snapshot().mode,
			"uid":str(instance.uid) if instance != null else "", "stamina_fraction":float(instance.swim_stamina_fraction) if instance != null else -1.0,
			"saddle_count":game.inventory.count("swim_saddle"),"stone":game.local.flags.has("water_swim_stone_earned")}
		if args.get("observe_restore", false):
			# Read existing restoration/authority results only. Never request a
			# mount, retry restoration, clear pending state or advance a frame.
			var saved: Dictionary = game.save_system.characters().read(str(game.local.character_id))
			var mount: Dictionary = saved.get("player_pose", {}).get("aquatic", {}).get("mount", {})
			var body: Node3D = director.ally_body()
			var service: Node = world.get_node("RippletWaterService")
			var peer := int(args.get("restore_peer", game.session.local_peer_id()))
			var answers: Dictionary = {}
			for token: String in service.get("_answered"):
				if token.begins_with(str(peer) + ":"):
					answers[token] = service.get("_answered")[token].duplicate(true)
			data.restore_observation = {"observed_peer":peer, "character_id":str(game.local.character_id),
				"saved_mount":mount, "pending_mount":player.swim_controller.get("_pending_mount").duplicate(true),
				"saved_uid_index":preload("res://scripts/save/water_traversal_save.gd").mount_index(mount, game.party.members()),
				"active_index":game.party.active_index(), "party_mutation_blocked":game.party._owner_mutation_blocked(),
				"ally_body":str(body.get_path()) if is_instance_valid(body) else "none",
				"ally_visible":is_instance_valid(body) and body.is_visible_in_tree(),
				"riding_allowed":riding._riding_allowed(), "tack":riding._has_tack("ripplet"),
				"ripplet_requesting":riding.get("_ripplet_requesting"), "actual_authority_answers":answers}
			print("F37 RESTORE OBSERVATION " + JSON.stringify(data.restore_observation))
		if args.get("remember_saved_dive", false):
			var saved: Dictionary = game.save_system.characters().read(str(game.local.character_id))
			var mount: Dictionary = saved.get("player_pose", {}).get("aquatic", {}).get("mount", {})
			var debt: float = float(mount.get("dive", {}).get("remaining_s", -1.0))
			if not riding.is_mounted() or not riding.diving or mount.get("creature_uid") != data.uid or debt <= 0.0 or debt >= 20.0:
				return {"verdict":"FAIL","detail":"actual saved character has no spent dive allowance for this owned mount","data":data}
			runner.set_meta("f37_saved_dive", {"uid":data.uid,"remaining_s":debt,"character_id":saved.character_id})
			data.saved_dive_remaining_s = debt
			data.saved_dive_recorded = true
		if args.has("require_saved_dive"):
			var saved: Dictionary = runner.get_meta("f37_saved_dive", {})
			if saved.is_empty() or saved.uid != data.uid or saved.character_id != str(game.local.character_id):
				return {"verdict":"FAIL","detail":"returning ride lost the actual saved character or creature identity","data":data}
			data.saved_dive_remaining_s = saved.remaining_s
			data.restored_dive_budget = riding.get_meta("restored_dive_budget", -1.0)
			data.saved_dive_matches = riding.is_mounted() and not riding.diving \
				and riding.get_meta("restored_dive_uid", "") == saved.uid and data.restored_dive_budget == saved.remaining_s
			data.resumed_dive_within_saved = riding.is_mounted() and riding.diving \
				and riding.dive_remaining_s > 0.0 and riding.dive_remaining_s <= float(saved.remaining_s)
			if (args.require_saved_dive == "surface" and not data.saved_dive_matches) \
				or (args.require_saved_dive == "resumed" and not data.resumed_dive_within_saved):
				return {"verdict":"FAIL","detail":"returning dive allowance changed or refreshed","data":data}
		return {"verdict":"PASS","data":data}
	return {"verdict":"ERROR","detail":"unknown F37 action"}
