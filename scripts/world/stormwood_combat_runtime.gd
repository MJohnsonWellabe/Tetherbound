extends Node

const DIRECTOR := preload("res://scripts/combat/stormwood_encounter_director.gd")
const MANAGER := preload("res://scripts/combat/cloudreach_combat_manager.gd")
const TRAINER_CAST := preload("res://scripts/world/stormwood_trainers.gd")
const HUD := preload("res://scenes/combat/combat_hud.tscn")
const DEATH := preload("res://scripts/world/player_death.gd")

func mount(world: Node3D) -> void:
	var manager := MANAGER.new()
	manager.name = "CombatManager"
	manager.ground_world = world
	world.add_child(manager)
	var director := DIRECTOR.new()
	director.name = "EncounterDirector"
	director.player_path = NodePath("../Player")
	director.manager_path = NodePath("../CombatManager")
	director.camera_rig_path = NodePath("../CameraRig")
	world.add_child(director)
	director.set_arbiter(world.get_node("InteractionArbiter"))
	var trainers := TRAINER_CAST.new()
	trainers.name = "StormwoodTrainers"
	world.add_child(trainers)
	trainers.build_authored(world.get_node("Player"))
	if not bool(world.get("simulation_only")):
		var hud := HUD.instantiate()
		hud.name = "CombatHUD"
		hud.set("manager_path", NodePath("../CombatManager"))
		hud.set("director_path", NodePath("../EncounterDirector"))
		world.add_child(hud)
		# Bind the established downed/revive/satchel path to this realm's rig.
		# A lethal fall or storm must never leave a zero-health player walking.
		var player := world.get_node("Player") as CharacterBody3D
		var death := DEATH.new()
		death.name = "PlayerDeath"
		world.add_child(death)
		var entry := Vector3(-350, world.ground_height_at(-350, 450), 450)
		death.configure_recovery([{"id": "ashfoot", "position": [entry.x, entry.y, entry.z], "requires_flag": ""}], Callable(world, "ground_height_near"))
		death.build(world, player, entry + Vector3.UP)
		death.restore_from_game(world.get_node("/root/Game"))
