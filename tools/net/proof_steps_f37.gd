extends RefCounted

## Explicit F37 fixture/control adapter. It earns no feast or chapter progress.
static func step(runner: SceneTree, action: String, args: Dictionary) -> Dictionary:
	var game := runner.root.get_node("Game")
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
		game.local.save_data()
		game.local.redesign_character.creatures[creature.uid].breakthroughs = [10,20,30] if args.get("breakthrough",false) else [10,20]
		game.local.redesign_character.creatures[creature.uid].cap_level = 40 if args.get("breakthrough",false) else 30
		return {"verdict":"PASS","detail":"SETUP owned L30 Ripplet and explicit breakthrough fixture before admission","data":{"uid":creature.uid}}
	if action == "f37_mount":
		if not director.summon_active_creature(): return {"verdict":"FAIL","detail":"summon refused"}
		for frame in 30: await runner.physics_frame
		var player: Node3D = world.local_rig()
		player.global_position = director.ally_body().global_position + Vector3(2,0,0)
		for frame in 2: await runner.physics_frame
		riding.interaction_activate()
		for frame in 120:
			await runner.physics_frame
			if riding.is_mounted(): return {"verdict":"PASS","detail":"ordinary mount prompt authorized"}
		return {"verdict":"FAIL","detail":"host did not authorize mount"}
	if action == "f37_deep_fixture":
		if not riding.is_mounted(): return {"verdict":"FAIL","detail":"not mounted"}
		riding.mount_body().global_position = Vector3(-215,-0.7,166)
		riding.mount_body().velocity = Vector3.ZERO
		for frame in 30: await runner.physics_frame
		return {"verdict":"PASS","detail":"SETUP deep pose near optional cache"}
	if action == "f37_jump":
		Input.action_press("jump")
		await runner.physics_frame
		Input.action_release("jump")
		for frame in 45: await runner.physics_frame
		return {"verdict":"PASS","detail":"ordinary Jump tap"}
	if action == "f37_status":
		var player: Node = world.local_rig()
		var instance: RefCounted = director.ally_instance()
		return {"verdict":"PASS","data":{"mounted":riding.is_mounted(),"diving":riding.diving,
			"dive_remaining_s":riding.dive_remaining_s,"swim_mode":player.swim_controller.snapshot().mode,
			"uid":str(instance.uid) if instance != null else "", "stamina_fraction":float(instance.swim_stamina_fraction) if instance != null else -1.0,
			"saddle_count":game.inventory.count("swim_saddle"),"stone":game.local.flags.has("water_swim_stone_earned")}}
	return {"verdict":"ERROR","detail":"unknown F37 action"}
