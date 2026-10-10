extends RefCounted

## F44#2 peer steps for tests/smoke_net_f44_alpha_respawn.gd. They read the
## host's retained alpha cycle and each peer's live alpha bodies, stand a
## trainer on the ground, and run the host's real morning (Game.advance_day).
## Nothing here resolves, departs, spawns or rolls an alpha: those come only
## from FoundationAlphas / AlphaRespawnService on the host.
const RULES := preload("res://scripts/repeatables/alpha_respawns.gd")


static func run(runner: SceneTree, action: String, args: Dictionary) -> Dictionary:
	match action:
		"f44_alpha_view": return _view(runner, str(args.get("site_id", "")), str(args.get("encounter_id", "")))
		"f44_stand": return await _stand(runner, args)
		"f44_advance_days": return await _advance_days(runner, int(args.get("days", 1)))
	return {"verdict": "ERROR", "detail": "unknown F44 action '%s'" % action}


static func _ok(detail: String, data: Dictionary = {}) -> Dictionary:
	return {"verdict": "PASS", "detail": detail, "data": data}


static func _fail(detail: String, data: Dictionary = {}) -> Dictionary:
	return {"verdict": "FAIL", "detail": detail, "data": data}


## The retained cycle record (host truth, mirrored on a client through the
## world snapshot) and every live body this peer's director tags for the site.
static func _view(runner: SceneTree, site_id: String, encounter_id: String = "") -> Dictionary:
	var game := runner.root.get_node_or_null(^"Game")
	if game == null or RULES.site(site_id).is_empty(): return _fail("needs Game and a configured alpha site")
	var record: Dictionary = game.world.redesign_world.get("alpha_cycles", {}).get("sites", {}).get(site_id, {})
	var bodies: Array = []
	for director: Node in runner.root.find_children("*", "Node", true, false):
		if not director.has_method("foundation_register_alpha"): continue
		for wild: Variant in director.get("_wild_creatures"):
			if not is_instance_valid(wild) or str((wild as Node).get_meta("foundation_alpha_site", "")) != site_id: continue
			var body := wild as Node3D
			var instance: Variant = body.get("instance")
			bodies.append({"generation": int(body.get_meta("foundation_alpha_generation", 0)),
				"alive": bool(body.call("is_alive")), "visible": body.visible,
				"traits": (instance.get("rolled_traits") as Array).duplicate() if instance != null and instance.get("rolled_traits") is Array else [],
				"position": [body.global_position.x, body.global_position.y, body.global_position.z]})
	# Diagnostics only: the host producer's retained resolutions, and the
	# fight's victory capture (or its recorded refusal).
	var diagnostics := {}
	var alphas: Node = runner.root.get_node_or_null(^"Game/Session/FoundationComposition/Alphas")
	if alphas != null:
		var pending: Array = []
		for frozen: Dictionary in (alphas.get("_pending") as Dictionary).values():
			pending.append({"site_id": frozen.site_id, "generation": frozen.generation, "seconds": frozen.seconds, "characters": frozen.characters})
		diagnostics.pending = pending
		diagnostics.settled = (alphas.get("_settled") as Dictionary).size()
	if not encounter_id.is_empty():
		for director: Node in runner.root.find_children("*", "Node", true, false):
			if not director.has_method("host_wild_victory_source"): continue
			var runtime: Variant = director.call("_shared_host_fight", encounter_id)
			if runtime == null: continue
			diagnostics.victory_source = not (director.call("host_wild_victory_source", encounter_id) as Dictionary).is_empty()
			diagnostics.capture_refusal = str(runtime.get_meta(&"wild_victory_capture_refusal", ""))
			diagnostics.canonical = runtime.has_meta(&"canonical_wild_context")
	var near: Array = []
	for director: Node in runner.root.find_children("*", "Node", true, false):
		if not director.has_method("foundation_register_alpha"): continue
		for wild: Variant in director.get("_wild_creatures"):
			if is_instance_valid(wild) and (wild as Node3D).global_position.distance_to(Vector3(-318, (wild as Node3D).global_position.y, 505)) < 25.0:
				near.append({"name": str((wild as Node).name), "display": str((wild as Node).get("display_name")), "metas": (wild as Node).get_meta_list()})
	diagnostics.near_site = near
	var guards: Array = []
	for director: Node in runner.root.find_children("*", "Node", true, false):
		if director.has_method("foundation_register_alpha"):
			guards.append({"director": str(director.get_path()), "metas": director.get_meta_list(), "realm": str(director.call("_encounter_realm"))})
	diagnostics.directors = guards
	var live := bodies.filter(func(b: Dictionary) -> bool: return b.alive and b.visible)
	return _ok("cycle %s, %d live body(ies)" % [str(record.get("status", "none")), live.size()],
		{"cycle": record.duplicate(true), "bodies": bodies, "live": live, "day": int(game.get("day")), "diagnostics": diagnostics,
			"is_host": game.call("is_host") == true})


## Stand the trainer on the ground at [x, z] (a disclosed fixture position).
static func _stand(runner: SceneTree, args: Dictionary) -> Dictionary:
	var at: Array = args.get("at", [])
	var scene := runner.current_scene
	if at.size() != 2 or scene == null or not scene.has_method("ground_height_at"): return _fail("f44_stand needs args.at = [x, z] in a world")
	var y := float(scene.call("ground_height_at", float(at[0]), float(at[1])))
	if not is_finite(y): return _fail("no ground at %s" % str(at))
	return await runner.call("_step_teleport", {"at": [float(at[0]), y + 1.0, float(at[1])], "settle": int(args.get("settle", 60))})


## Host only: N real mornings, one frame apart.
static func _advance_days(runner: SceneTree, days: int) -> Dictionary:
	var game := runner.root.get_node_or_null(^"Game")
	if game == null or game.call("is_host") != true: return _fail("mornings are host truth")
	for i in days:
		game.call("advance_day")
		await runner.physics_frame
	return _ok("advanced %d day(s) to day %d" % [days, int(game.get("day"))], {"day": int(game.get("day"))})
