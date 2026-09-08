extends RefCounted
const DIRECTOR := preload("res://scripts/combat/water_encounter_director.gd")
const HUD := preload("res://scenes/combat/combat_hud.tscn")
const MANAGER := preload("res://scripts/combat/cloudreach_combat_manager.gd")
static func build(world: Node3D, bodies: Dictionary) -> Node:
	if world.has_node("EncounterDirector"):
		return world.get_node("EncounterDirector")
	var manager := MANAGER.new()
	manager.name = "CombatManager"
	manager.ground_world = world
	world.add_child(manager)
	var director := DIRECTOR.new()
	director.name = "EncounterDirector"
	director.player_path = ^"../Player"
	director.manager_path = ^"../CombatManager"
	director.camera_rig_path = ^"../CameraRig"
	director.setup(world, bodies)
	world.add_child(director)
	director.set_arbiter(world.get_node("InteractionArbiter"))
	if not bool(world.get("simulation_only")):
		var hud := HUD.instantiate()
		hud.name = "CombatHUD"
		hud.set("manager_path", NodePath("../CombatManager"))
		hud.set("director_path", NodePath("../EncounterDirector"))
		world.add_child(hud)
	return director
