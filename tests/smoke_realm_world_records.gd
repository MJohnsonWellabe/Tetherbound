extends SceneTree

const PLACER := preload("res://scripts/build/build_placer.gd")
const DEATH := preload("res://scripts/world/player_death.gd")
const PLAYER := preload("res://scenes/player/player.tscn")
const CAMERA := preload("res://scripts/player/camera_rig.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var failed := false
var checks := 0

class LayeredWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 1000.0
	func ground_height_near(at: Vector3) -> float:
		return at.y


func _init() -> void:
	call_deferred("_run")


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error(message)


func owned_nodes(world: Node, group: String) -> Array:
	return get_nodes_in_group(group).filter(func(node: Node) -> bool: return world.is_ancestor_of(node))


func same_payload(a: Variant, b: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(a)) == JSON.parse_string(JSON.stringify(b))


func _run() -> void:
	var game := root.get_node("Game")
	game.reset_for_new_game()
	var world := LayeredWorld.new()
	world.name = "RealmRecordsFixture"
	root.add_child(world)
	current_scene = world
	var camera := SpringArm3D.new()
	camera.name = "CameraRig"
	camera.set_script(CAMERA)
	world.add_child(camera)
	var camera_eye := Camera3D.new()
	camera_eye.name = "Camera3D"
	camera.add_child(camera_eye)
	var player: CharacterBody3D = PLAYER.instantiate()
	player.name = "Player"
	world.add_child(player)
	player.set_physics_process(false)
	var placer := PLACER.new()
	placer.name = "BuildPlacer"
	placer.player_path = NodePath("../Player")
	placer.camera_rig_path = NodePath("../CameraRig")
	world.add_child(placer)
	placer.set_physics_process(false)
	check(placer._ground_height(Vector3(7,700,9)) == 700.0, "building ground query retains intended stacked elevation")
	var death := DEATH.new()
	world.add_child(death)
	death.configure_recovery([{"id": "safe", "position": [30,700,40], "requires_flag": ""}],
		func(at: Vector3) -> float: return at.y)
	death.build(world, player, Vector3(30,700,40))
	for realm: String in ["meadows", "cloudreach"]:
		game.current_realm = realm
		game.bind_realm_map()
		game.register_building("tent", Vector3(10, 700 if realm == "cloudreach" else 0, 20))
		for i in 2:
			game.inventory.add("wood", i + 3)
			death._drop_satchel(game.inventory.drain(), Vector3(i * 3, 700 if realm == "cloudreach" else 0, 20), game)
	var saves := SAVE.new("user://smoke_realm_world_records/")
	check(saves.save(game, 0), "write isolated real save")
	var original_satchels: Array = game.death_satchels.duplicate(true)
	for realm: String in ["cloudreach", "meadows", "cloudreach"]:
		game.current_realm = realm
		game.bind_realm_map()
		placer.restore_from_game(game)
		death.restore_from_game(game)
		await process_frame
		var buildings := owned_nodes(world, PLACER.PLACED_GROUP)
		var satchels := owned_nodes(world, "death_satchel")
		check(buildings.size() == 1, realm + " renders one owned building only")
		check(satchels.size() == 2, realm + " renders both owned satchels only")
		for node: Node in buildings + satchels:
			check(node.get_meta("realm") == realm, "live interaction body ownership matches realm")
		death.sync_state_to_game(game)
		check(same_payload(game.death_satchels, original_satchels), "there/back sync preserves all four inventories")
		check(saves.save(game, 0) and saves.load_slot(game, 0), "live per-realm save/load")
		placer.restore_from_game(game)
		death.restore_from_game(game)
		await process_frame
		check(owned_nodes(world, "death_satchel").size() == 2, "reload has no duplicate bags")
	# Reject a stale foreign-building target even when a caller holds its node.
	var target: Node3D = owned_nodes(world, PLACER.PLACED_GROUP)[0]
	game.current_realm = "meadows"
	check(not placer.dismantle_piece(game, target), "foreign-realm dismantle refused")
	game.current_realm = "cloudreach"
	game.bind_realm_map()
	# Real production Player died signal drives drain, fresh bag and timed respawn.
	game.register_building("bedroll", Vector3(-100,0,-100))
	game.placed_buildings.back()["realm"] = "meadows"
	player.global_position = Vector3(100,720,100)
	game.inventory.add("wood", 7)
	player.emit_signal("died")
	await create_timer(2.0).timeout
	check(player.global_position.is_equal_approx(Vector3(32,701,42)), "Cloudreach death returns to authored local camp, never Meadows bed")
	check(game.inventory.count("wood") == 0, "carried inventory drained on death")
	check(game.death_satchels.size() == 5, "new death preserves all previous satchels")
	check(game.death_satchels.back().realm == "cloudreach", "new bag tagged to death realm")
	check(owned_nodes(world, "death_satchel").size() == 3, "all three Cloudreach bags available")
	death.sync_state_to_game(game)
	check(saves.save(game, 0) and saves.load_slot(game, 0), "post-death save reload")
	death.restore_from_game(game)
	await process_frame
	check(owned_nodes(world, "death_satchel").size() == 3, "three Cloudreach satchels survive reload")
	check(same_payload(game.death_satchels[0], original_satchels[0]), "Meadows bag unchanged after Cloudreach death")
	world.queue_free()
	await process_frame
	DirAccess.remove_absolute(saves.slot_path(0))
	print("REALM WORLD RECORDS SMOKE: %s (%d checks)" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)
