extends SceneTree

## Minimal live single-host fixture for Stormwood arch runtime. It deliberately
## does not model two peers, forest presentation, or the full chapter. It does
## mount the production runtime, Session, ledger, inventory, real Area3D, real
## CharacterBody3D player, and InteractionArbiter.
const ARCH_RUNTIME := preload("res://scripts/world/stormwood_arch_runtime.gd")
const INTERACTION_ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const BUILD_PLACER := preload("res://scripts/build/build_placer.gd")

var _failures: Array[String] = []
var _arrivals: Array[Dictionary] = []


class FixtureWorld extends Node3D:
	var simulation_only := false

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0

	func ground_height_near(_at: Vector3) -> float:
		return 0.0


class LightningStub extends Node3D:
	var player: CharacterBody3D

	func _actors() -> Dictionary:
		return {1: player}


class CombatStub extends Node:
	var fighting := false

	func is_fighting() -> bool:
		return fighting


class CameraStub extends Node:
	func planar_basis() -> Basis:
		return Basis.IDENTITY


class DirectorStub extends Node3D:
	var _encounter_host: RefCounted = null
	var _ally_body: Node3D = null


class ChapterStub extends Node:
	var events: Array[String] = []

	func emit_event(event: String) -> void:
		events.append(event)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	_expect(game != null, "Game autoload is available")
	if game == null:
		_finish()
		return
	game.call("reset_for_new_game")
	game.set("current_realm", "stormwood")
	var session := game.get_node_or_null(^"Session")
	_expect(session != null and session.is_host(), "offline Session supplies the production host path")
	if session == null:
		_finish()
		return
	session.stormwood_arch_arrival.connect(func(event: Dictionary) -> void: _arrivals.append(event.duplicate(true)))

	var world := FixtureWorld.new()
	world.name = "StormwoodArchSmokeWorld"
	root.add_child(world)
	var player := _player()
	world.add_child(player)
	var camera := CameraStub.new()
	camera.name = "PlayerCamera"
	world.add_child(camera)
	var ally := CharacterBody3D.new()
	ally.name = "ActiveCompanion"
	world.add_child(ally)
	ally.global_position = Vector3(8, 0, 8)
	var lightning := LightningStub.new()
	lightning.name = "StormwoodLightning"
	lightning.player = player
	world.add_child(lightning)
	var combat := CombatStub.new()
	combat.name = "CombatManager"
	world.add_child(combat)
	var director := DirectorStub.new()
	director.name = "EncounterDirector"
	director._ally_body = ally
	world.add_child(director)
	var chapter := ChapterStub.new()
	chapter.name = "StormwoodChapter"
	world.add_child(chapter)
	var arbiter := INTERACTION_ARBITER.new()
	arbiter.name = "InteractionArbiter"
	arbiter.player_path = NodePath("../Player")
	world.add_child(arbiter)
	var runtime := ARCH_RUNTIME.new()
	runtime.name = "StormwoodArchRuntime"
	world.add_child(runtime)
	runtime.mount(world)
	var placer := BUILD_PLACER.new()
	placer.name = "BuildPlacer"
	placer.player_path = NodePath("../Player")
	placer.camera_rig_path = NodePath("../PlayerCamera")
	world.add_child(placer)
	await process_frame
	await physics_frame

	var arches: Dictionary = runtime.get("_arches")
	var ashfoot: Node3D = (arches["a_ashfoot"] as Dictionary).node
	var pools: Node3D = (arches["a_pools"] as Dictionary).node
	_expect(arches.has("a_ashfoot") and arches.has("a_pools"), "production runtime mounts linked A endpoints")
	_expect(int(game.inventory.count("stormglass")) == 0, "fixture begins with no Stormglass key material")
	player.global_position = ashfoot.global_position
	var dark: Dictionary = runtime.travel_for_peer(session.local_peer_id(), "a_ashfoot")
	_expect(not bool(dark.get("ok", false)), "dark unlinked A endpoint cannot travel")
	_expect(_arrivals.is_empty(), "dark direct validation creates no arrival transport")

	game.inventory.add("stormglass", 6)
	var ash_prompt := (arches["a_ashfoot"] as Dictionary).prompt as Node3D
	var pools_prompt := (arches["a_pools"] as Dictionary).prompt as Node3D
	player.global_position = ash_prompt.global_position + Vector3(0, 0, -1.0)
	arbiter.call("_recompute")
	_expect(bool(arbiter.call("activate")), "InteractionArbiter selects the nearby unlit relight prompt")
	await process_frame
	await process_frame
	_expect(game.progression.has("stormwood:arch:a_ashfoot:lit"), "arbiter activation reaches production relight ledger claim")
	_expect(int(game.inventory.count("stormglass")) == 3, "first relight atomically costs three Stormglass")
	player.global_position = ash_prompt.global_position + Vector3(0, 0, -1.0)
	arbiter.call("_recompute")
	_expect(not bool(arbiter.call("activate")), "lit relight prompt is disabled after its first winning claim")
	await process_frame
	_expect(int(game.inventory.count("stormglass")) == 3, "already-lit endpoint cannot charge a second time")
	await _activate_at(arbiter, player, pools_prompt)
	await process_frame
	_expect(game.progression.has("stormwood:arch:a_pools:lit"), "second A endpoint records its own winning node flag")
	_expect(int(game.inventory.count("stormglass")) == 0, "each A endpoint costs exactly three Stormglass")

	# This is ordinary Area3D body entry, which calls Session's host dispatcher.
	player.global_position = ashfoot.global_position + Vector3(0, 0, 4)
	await physics_frame
	player.global_position = ashfoot.global_position
	await physics_frame
	await physics_frame
	print("ARCH PASSAGE linked=%s overlaps=%s" % [str((arches["a_ashfoot"] as Dictionary).get("spec")), str(((ashfoot.get_node("Passage") as Area3D).get_overlapping_bodies()))])
	await process_frame
	_expect(not _arrivals.is_empty() and bool(_arrivals.back().get("ok", false)), "walking into linked A passage emits a host-approved arrival")
	var expected := pools.to_global(Vector3(0, 0, 3.5))
	expected.y = 0.6
	_expect(player.global_position.distance_to(expected) < 0.05, "arrival places player at linked twin footing")
	_expect(ally.global_position.distance_to(player.global_position + Vector3(2, 0, 0)) < 0.05, "active companion moves alongside arriving player")
	_expect(chapter.events.has("arch:pair_a_travel"), "A arrival reaches the production chapter event seam")

	runtime.set("_arrival_until", {})
	combat.fighting = true
	player.global_position = ashfoot.global_position
	var before_combat := player.global_position
	session.request_stormwood_arch_travel("a_ashfoot")
	await process_frame
	_expect(not _arrivals.is_empty() and not bool(_arrivals.back().get("ok", false)), "Session host rejects arch travel during local combat")
	_expect(player.global_position.distance_to(before_combat) < 0.01, "combat refusal leaves player at source")
	combat.fighting = false

	# The recipe unlock is a prerequisite only; the proof below is two real
	# BuildPlacer presses, with the exact inventory that the host rechecks.
	game.progression.set_flag("stormwood:arch_recipe_known")
	game.inventory.add("stormglass_crown", 6)
	game.inventory.add("stormglass", 18)
	game.inventory.add("thunderwood_frame", 6)
	game.inventory.add("conductor_vine", 12)
	var crown_before := _materials(game, ["stormglass_crown", "thunderwood_frame", "conductor_vine"])
	var crown_uid := await _place_arch(game, placer, player, Vector3(-160, 0, 2750))
	_expect(not crown_uid.is_empty(), "BuildPlacer plants the Still Grove Crown twin through the host ledger")
	_expect(_materials(game, ["stormglass_crown", "thunderwood_frame", "conductor_vine"]) ==
		{"stormglass_crown": crown_before["stormglass_crown"] - 6,
		"thunderwood_frame": crown_before["thunderwood_frame"] - 2,
		"conductor_vine": crown_before["conductor_vine"] - 4},
		"Still Grove spends six Crown-grade Stormglass and its exact frame/vine recipe")
	var ordinary_before := _materials(game, ["stormglass", "thunderwood_frame", "conductor_vine"])
	var ordinary_uid := await _place_arch(game, placer, player, Vector3(-630, 0, 800))
	_expect(not ordinary_uid.is_empty(), "an ordinary player arch follows the same production BuildPlacer path")
	_expect(_materials(game, ["stormglass", "thunderwood_frame", "conductor_vine"]) ==
		{"stormglass": ordinary_before["stormglass"] - 6,
		"thunderwood_frame": ordinary_before["thunderwood_frame"] - 2,
		"conductor_vine": ordinary_before["conductor_vine"] - 4},
		"ordinary footing spends the normal Stormglass recipe, never Crown grade")
	await process_frame
	await physics_frame
	_expect(arches.has(crown_uid), "world-revision reconciliation mounts a production Area3D for the built Crown twin")
	var crown: Node3D = (arches["e_crown"] as Dictionary).node
	if arches.has(crown_uid):
		var crown_twin: Node3D = (arches[crown_uid] as Dictionary).node
		runtime.set("_arrival_until", {})
		await _walk_into_passage(player, crown_twin)
		_expect(not _arrivals.is_empty() and bool(_arrivals.back().get("ok", false)) and
			str(_arrivals.back().get("target", "")) == "e_crown",
			"built Still Grove passage reaches Crown through Area3D and Session")
		_expect(chapter.events.has("arch:crown_arrived"), "Crown arrival reaches the production chapter seam")
		runtime.set("_arrival_until", {})
		await _walk_into_passage(player, crown)
		_expect(not _arrivals.is_empty() and bool(_arrivals.back().get("ok", false)) and
			str(_arrivals.back().get("target", "")) == crown_uid,
			"Crown passage returns through Session to its constructed Still Grove twin")

		var crown_piece := _placed_arch_at(Vector3(-160, 0, 2750))
		_expect(crown_piece != null and placer.dismantle_piece(game, crown_piece),
			"BuildPlacer dismantles the constructed Crown twin through its normal ledger path")
		await process_frame
		await physics_frame
		runtime.set("_arrival_until", {})
		player.global_position = crown.global_position
		session.request_stormwood_arch_travel("e_crown")
		await process_frame
		_expect(not _arrivals.is_empty() and not bool(_arrivals.back().get("ok", false)),
			"dismantling the constructed twin makes Crown travel refuse through Session")

	# A separate ordinary pair leaves a real target for the clearance query.
	var pair_a_uid := ordinary_uid
	var pair_b_uid := await _place_arch(game, placer, player, Vector3(-1050, 0, 1750))
	await process_frame
	await physics_frame
	_expect(not pair_b_uid.is_empty() and arches.has(pair_a_uid) and arches.has(pair_b_uid),
		"two constructed ordinary arches mount their production passages")
	if arches.has(pair_a_uid) and arches.has(pair_b_uid):
		var pair_a: Node3D = (arches[pair_a_uid] as Dictionary).node
		var pair_b: Node3D = (arches[pair_b_uid] as Dictionary).node
		var blocker := _destination_blocker(pair_b)
		world.add_child(blocker)
		await physics_frame
		runtime.set("_arrival_until", {})
		player.global_position = pair_a.global_position
		session.request_stormwood_arch_travel(pair_a_uid)
		await process_frame
		_expect(not _arrivals.is_empty() and not bool(_arrivals.back().get("ok", false)) and
			player.global_position.distance_to(pair_a.global_position) < 0.01,
			"the destination capsule blocks constructed-pair travel without moving the player")
	world.queue_free()
	await process_frame
	_finish()


func _player() -> CharacterBody3D:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.collision_layer = 1
	player.collision_mask = 1
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)
	return player


func _activate_at(arbiter: Node, player: CharacterBody3D, prompt: Node3D) -> void:
	player.global_position = prompt.global_position + Vector3(0, 0, -1.0)
	await process_frame
	arbiter.call("_recompute")
	_expect(bool(arbiter.call("activate")), "InteractionArbiter selects the nearby relight prompt")


func _materials(game: Node, ids: Array[String]) -> Dictionary:
	var result := {}
	for id: String in ids:
		result[id] = int(game.inventory.count(id))
	return result


func _place_arch(game: Node, placer: Node, player: CharacterBody3D, at: Vector3) -> String:
	# CameraStub faces -Z, so three metres south puts the live ghost precisely
	# on the requested footing. The action is a real BuildPlacer frame, not a
	# ledger call staged by the smoke.
	player.global_position = at + Vector3(0, 0, 3)
	game.pending_build = "stormglass_arch"
	await physics_frame
	await physics_frame
	if not bool(placer.get("_ghost_ok")):
		return ""
	var before := (game.placed_buildings as Array).size()
	Input.action_press("build_place")
	await physics_frame
	Input.action_release("build_place")
	await process_frame
	if (game.placed_buildings as Array).size() != before + 1:
		return ""
	return str((game.placed_buildings as Array).back().get("uid", ""))


func _walk_into_passage(player: CharacterBody3D, arch: Node3D) -> void:
	player.global_position = arch.global_position + Vector3(0, 0, 4)
	await physics_frame
	player.global_position = arch.global_position
	await physics_frame
	await physics_frame
	await process_frame


func _placed_arch_at(at: Vector3) -> Node3D:
	for node: Node in get_nodes_in_group("placed_building"):
		if str(node.get_meta("building_id", "")) == "stormglass_arch" and \
				(node as Node3D).global_position.distance_to(at) < 0.1:
			return node as Node3D
	return null


func _destination_blocker(target: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "ArchDestinationBlocker"
	body.collision_layer = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 2.0, 1.0)
	collision.shape = shape
	collision.position = target.to_global(Vector3(0, 0.9, 3.5))
	body.add_child(collision)
	return body


func _expect(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)


func _finish() -> void:
	for failure: String in _failures:
		push_error("STORMWOOD ARCHES: " + failure)
	print("STORMWOOD ARCHES: %s" % ("PASS" if _failures.is_empty() else "FAIL"))
	quit(0 if _failures.is_empty() else 1)
