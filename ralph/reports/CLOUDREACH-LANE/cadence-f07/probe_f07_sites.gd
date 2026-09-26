extends SceneTree

## Scratch probe: admit named Cloudreach wild sites in the production scene and
## report real-floor support for every body. Fixture relocation only.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var fails := 0


func _init() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func _run() -> void:
	var ids: Array = []
	var prefix := "road_visibility_upper_plateau_circuit_"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="): prefix = arg.substr(9)
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	game.set("save_system", SAVE.new("user://cloudreach_site_probe_%d" % OS.get_process_id()))
	game.set("current_realm", "cloudreach")
	var member: RefCounted = SPECIES.spawn("sparkit")
	member.call("set_level", 25, PROGRESSION.config())
	game.get("party").call("add", member)
	for flag in ["fly_traversal_unlocked", "cloudreach_upper_route_unlocked", "cloudreach_act_ii_complete"]:
		game.progression.set_flag(flag)
	var world: Node3D = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	var player: CharacterBody3D = world.get_node("Player")
	player.collision_layer = 0
	var director: Node = world.get_node("EncounterDirector")
	await frames(12)
	for site: Dictionary in director.get("encounter_config").wild_sites:
		var id := str(site.id)
		if not id.begins_with(prefix): continue
		var raw: Array = site.position
		var centre := Vector3(raw[0], raw[1], raw[2])
		player.global_position = centre + Vector3(0, 0.3, 0)
		player.velocity = Vector3.ZERO
		await frames(30)
		var members: Array = director.get("_site_members").get(id, [])
		var ok: bool = director.get("_site_spawned").has(id) and not director.get("_site_failures").has(id) and members.size() == int(site.count)
		var ground := float(world.call("ground_height_near", centre))
		var bodies: Array = []
		for wild: Node3D in members:
			var support: Vector3 = director.call("_wild_support", wild.global_position, float(wild.call("body_radius")), wild)
			var sup_ok := support.is_finite() and absf(support.y - wild.global_position.y) < 0.8
			ok = ok and sup_ok
			bodies.append({"name": str(wild.name), "species": wild.get("species_id"), "at": str(wild.global_position), "supported": sup_ok, "radius": wild.call("body_radius")})
		if not ok: fails += 1
		print("SITE PROBE " + JSON.stringify({"id": id, "ok": ok, "centre": str(centre), "ground_height_near": ground, "bodies": bodies}))
	print("SITE PROBE DONE failures=%d" % fails)
	quit(0 if fails == 0 else 1)
