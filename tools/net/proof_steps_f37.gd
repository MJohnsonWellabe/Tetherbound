extends RefCounted
const INPUT := preload("res://tools/net/proof_steps.gd")
const SUNKEN := preload("res://scripts/world/ripplet_sunken_rules.gd")
const CLAIM := preload("res://scripts/world/ledger_claim.gd")

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
			return {"verdict":"FAIL","detail":"actual sunken prompt never won Interact"}
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
