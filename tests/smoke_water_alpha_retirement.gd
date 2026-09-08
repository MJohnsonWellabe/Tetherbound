extends SceneTree

## Small native lifecycle fixture, NOT a campaign win. Actual Aquaryn packed
## body, Alpha process/exit callback, manager signal, ledger and scratch save.
const ALPHA := preload("res://scripts/combat/water_alpha.gd")
const BODY := preload("res://scripts/creatures/water_alpha_body.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CATALOG := preload("res://scripts/creatures/water_species_catalog.gd")
const REWARD := preload("res://scripts/world/water_alpha_rewards.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
var checks := 0
var failures: Array[String] = []

class GeometryWorld extends Node3D:
	var simulation_only := false
	func ground_height_at(_x: float, _z: float) -> float: return 0.0

func _initialize() -> void:
	_run.call_deferred()

func _check(passed: bool, label: String) -> void:
	checks += 1
	if not passed:
		failures.append(label)
	print("PASS: " if passed else "FAIL: ", label)

func _hits(body: CharacterBody3D) -> bool:
	var center: Vector3 = body.centre()
	var ray := PhysicsRayQueryParameters3D.create(center + Vector3(-20, 0, 0), center + Vector3(20, 0, 0))
	return body.get_world_3d().direct_space_state.intersect_ray(ray).get("collider") == body

func _run() -> void:
	var game := root.get_node("Game")
	game.current_realm = "water"
	game.local.character_id = "native-alpha-retirement"
	game.world.world_id = "native-alpha-retirement"
	game.save_system = SAVE.new("user://alpha_retirement_%d/" % Time.get_ticks_usec())
	var catalog: Dictionary = CATALOG.merge_catalogue(SPECIES.table())
	SPECIES.table().merge(catalog.catalogue, true)
	var world := GeometryWorld.new()
	root.add_child(world)
	var alpha := ALPHA.new()
	alpha.world = world
	alpha.rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_alpha.json"))
	world.add_child(alpha)
	alpha.set_physics_process(false) # No encounter transport/world simulation in this fixture.
	var body: CharacterBody3D = ALPHA.CREATURE_SCENE.instantiate()
	body.set_script(BODY)
	alpha.add_child(body)
	alpha.body = body
	body.populate("water_aquaryn", null)
	var manager := MANAGER.new()
	world.add_child(manager)
	manager.set_process(false)
	manager.set_physics_process(false)
	manager.exited.connect(alpha._on_alpha_exit)
	for frame in 3:
		await physics_frame
	_check(body.visible and body.collision_layer != 0 and _hits(body), "Unresolved actual Aquaryn obstructs the native collision ray")
	# An unjournaled result/exit must not retire the live encounter.
	alpha._local_fight = true
	manager.exited.emit("fled")
	await process_frame
	await physics_frame
	_check(body.visible and _hits(body), "Unresolved exit preserves actual body and collision")
	var observer := ALPHA.new()
	observer.world = world
	observer.rules = alpha.rules
	world.add_child(observer)
	observer.set_physics_process(false)
	var observer_body: CharacterBody3D = ALPHA.CREATURE_SCENE.instantiate()
	observer_body.set_script(BODY)
	observer.add_child(observer_body)
	observer.body = observer_body
	observer_body.populate("water_aquaryn", null)
	observer_body.position = Vector3(50, 0, 0)
	await physics_frame
	_check(observer_body.visible and _hits(observer_body), "Unresolved nonparticipant body also collides")
	alpha._local_fight = true
	var ledger := LEDGER.new(game.world)
	var reward: Dictionary = REWARD.resolve(game, ledger, "won", [game.local.character_id])
	_check(reward.get("ok", false) and game.world.flags.has(REWARD.RESOLVED), "Actual reward ledger journals explicit diagnostic defeat")
	for frame in 3:
		await physics_frame
	_check(body.visible and _hits(body), "Durable outcome preserves body until local result beat exits")
	_check(not observer_body.visible and observer_body.collision_layer == 0 and not _hits(observer_body),
		"Nonparticipant observes durable completion without needing a local fight exit")
	manager.exited.emit("won")
	for frame in 3:
		await physics_frame
	_check(not body.visible and body.collision_layer == 0, "Actual post-result Alpha process retires same-live body")
	_check(not _hits(body), "Retired Alpha no longer obstructs native physics ray")
	_check(not body.is_physics_processing(), "Retired Alpha no longer integrates creature physics")
	print("alpha retirement checks=", checks, " failures=", failures)
	world.free()
	quit(0 if failures.is_empty() else 1)
