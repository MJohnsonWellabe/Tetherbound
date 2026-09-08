extends SceneTree

## Synthetic low-RAM admission diagnostic, NOT campaign evidence. No world,
## Terrain3D, saved party, progression or save service is loaded or mutated.
## Only startup/population is replaced; admission and manager.begin are real.
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const BODY := preload("res://scenes/creatures/creature.tscn")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const CROWN := preload("res://tests/helpers/stormwood_crown_build_segment.gd")

class LocalDirector extends "res://scripts/combat/stormwood_encounter_director.gd":
	func _ready() -> void:
		pass
	func _process(_delta: float) -> void:
		pass
	func _physics_process(_delta: float) -> void:
		pass
	func _party() -> RefCounted:
		return null

class Ground extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	for resting in [true, false]:
		await _case(resting)
	print("SYNTHETIC ALPHA ADMISSION: 2 cases, failures=", failures)
	quit(0 if failures.is_empty() else 1)

func _case(resting: bool) -> void:
	var world := Ground.new()
	world.name = "SyntheticAdmission"
	root.add_child(world)
	var player := CharacterBody3D.new()
	player.name = "Player"
	world.add_child(player)
	var manager := MANAGER.new()
	manager.name = "CombatManager"
	world.add_child(manager)
	manager.set_physics_process(false)
	manager.set_process(false)
	var ally := BODY.instantiate() as Node3D
	ally.set_script(WILD)
	world.add_child(ally)
	ally.call("populate", "terrapup", player)
	ally.set_physics_process(false)
	var creature := ally.get("instance") as RefCounted
	creature.set("resting", resting)
	var alpha := BODY.instantiate() as Node3D
	alpha.set_script(WILD)
	alpha.name = "Named_capacitor_alpha"
	world.add_child(alpha)
	alpha.call("populate", "voltarach", player)
	alpha.position = Vector3(0, 0, -3)
	alpha.set_physics_process(false)
	var director := LocalDirector.new()
	director.name = "EncounterDirector"
	world.add_child(director)
	director._player = player
	director._manager = manager
	director._ally = creature
	director._ally_body = ally
	director._wild_creatures.append(alpha)
	var arbiter := ARBITER.new()
	world.add_child(arbiter)
	arbiter.set_player(player)
	arbiter.register(director)
	var observed := {"activated": 0, "entered": 0}
	arbiter.activated.connect(func(provider: Object) -> void:
		if provider == director:
			observed.activated += 1)
	manager.entered.connect(func() -> void: observed.entered += 1)
	for _frame in 4:
		await process_frame
	var offer: Dictionary = arbiter.winner()
	var exact: bool = director._engageable() == alpha
	var helper := CROWN.new()
	helper._tree = self
	helper._director = director
	helper._arbiter = arbiter
	var pressed: bool = await helper._tap_named_engage(alpha)
	var fighting := manager.is_fighting()
	print("SYNTHETIC ADMISSION ", {"resting": resting, "offer": offer,
		"exact": exact, "no_usable_ally": director.no_usable_ally(),
		"observed": observed, "fighting": fighting, "pressed": pressed,
		"restored_scale": Engine.time_scale, "restored_hz": Engine.physics_ticks_per_second})
	if not exact or not bool(offer.get("actionable", false)) \
			or observed.activated != 1 or observed.entered != (0 if resting else 1) \
			or fighting == resting or not pressed \
			or Engine.time_scale != 8.0 or Engine.physics_ticks_per_second != 480:
		failures.append("unexpected physical admission result, resting=" + str(resting))
	world.queue_free()
	await process_frame
	await process_frame
