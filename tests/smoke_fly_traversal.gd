extends SceneTree

## Bounded physics/input fixture, not evidence for the full Cloudreach route.
## Production Player/CameraRig/Trainer + real static collisions and Game save.
const PLAYER := preload("res://scenes/player/player.tscn")
const CAMERA := preload("res://scripts/player/camera_rig.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var world: Node3D
var player: CharacterBody3D
var fly: Node
var game: Node
var failures: Array[String] = []
var assertions := 0
var _saved_system: RefCounted


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	game = root.get_node("Game")
	game.current_realm = "cloudreach"
	game.pending_realm_entry = ""
	game.saved_player_pose = {}
	game.party = PARTY.new()
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail", "sparkit"]:
		game.party.add(SPECIES.spawn(species))
	game.party.set_active(4)
	_saved_system = game.save_system
	game.save_system = SAVE.new("user://test_cloudreach_fly_smoke/")
	_build_world()
	await _frames(60)
	_check(player.is_on_floor(), "fixture starts on actual floor")
	await _deploy()
	_check(not fly.is_flying(), "no launch before authorization")
	await _frames(70)
	game.progression.set_flag("fly_traversal_unlocked")
	player.vitals.rest()
	_action("jump", true)
	await _frames(3)
	_action("jump", false)
	await _frames(7)
	player.set_locomotion_enabled(false)
	_action("jump", true)
	await _frames(3)
	_action("jump", false)
	_check(not fly.is_flying(), "dialogue/combat input lock prevents airborne confirmation from launching")
	player.set_locomotion_enabled(true)
	await _frames(70)
	player.vitals.rest()
	await _deploy()
	_check(fly.is_flying(), "second airborne Jump deploys Fly")
	_check(player.rider_visible() and player.collision_layer != 0 and player.collision_mask != 0, "flight retains visible trainer and live collision")
	_check(game.party.size() == 5 and game.party.active_index() == 4, "full non-Fly party uses Maela's carrier without a sixth slot")
	_check(fly.last_flight_used_mentor_loaner(), "flight records the non-owned mentor carrier")
	_check(player.get_node_or_null("FlyCompanionPresentation") != null, "installed creature art is visible overhead")
	var trainer: Skeleton3D = player.get_node("Model").skeleton()
	var left_hand: Vector3 = trainer.to_global(trainer.get_bone_global_pose(trainer.find_bone("LeftHand")).origin)
	var right_hand: Vector3 = trainer.to_global(trainer.get_bone_global_pose(trainer.find_bone("RightHand")).origin)
	var head: Vector3 = trainer.to_global(trainer.get_bone_global_pose(trainer.find_bone("Head")).origin)
	_check(left_hand.y > head.y + 0.15 and right_hand.y > head.y + 0.15, "both installed trainer wrists are raised above the head joint")
	_action("jump", true)
	var highest := player.position.y
	for i in 240:
		await physics_frame
		highest = maxf(highest, player.position.y)
	_action("jump", false)
	_check(highest > 5.0 and highest < 12.5, "ceiling collision stops the upward glide: %.2f m" % highest)
	# Remove the real ceiling and test the separate bounded-current ceiling.
	world.get_node("Ceiling").queue_free()
	_action("jump", true)
	await _frames(160)
	_check(player.position.y <= 18.2, "authored updraft ceiling prevents infinite ascent")
	_action("jump", false)
	await _capture_if_requested()
	# Save at height through real Game.save_game; preserve stamina and active slot.
	var before_save: float = player.vitals.stamina_fraction()
	var anchor: Vector3 = fly.safe_anchor
	_check(game.save_game(1), "airborne save written")
	player.vitals.rest()
	_check(game.load_game(1), "same-scene airborne load")
	await _frames(4)
	_check(not fly.is_flying() and player.position.distance_to(anchor) < 1.0, "same-scene load returns to safe floor")
	_check(absf(player.vitals.stamina_fraction() - before_save) < 0.03, "same-scene load preserves stamina")
	# A fresh Player must receive the pending traversal state too.
	world.free()
	_check(game.load_game(1), "load before replacement scene exists")
	_build_world()
	await _frames(8)
	_check(not fly.is_flying() and player.position.distance_to(anchor) < 1.0, "fresh scene load returns to safe floor")
	_check(absf(player.vitals.stamina_fraction() - before_save) < 0.05, "fresh scene load preserves stamina")
	_check(game.party.active_index() == 4, "fresh scene preserves active party member")
	game.saved_player_pose = {}
	player.vitals.rest()
	await _frames(20)
	await _deploy()
	_action("jump", true)
	await _frames(55)
	_action("jump", false)
	fly.register_restriction("test_upper", AABB(Vector3(7, -10, -50), Vector3(2, 100, 100)), "fly_test_route_open")
	_action("move_right", true)
	await _frames(75)
	_check(player.position.x < 6.6, "locked 3D restriction stops a real input flight")
	game.progression.set_flag("fly_test_route_open")
	_action("jump", true)
	await _frames(100)
	_check(player.position.x > 10.0 and player.position.x < 17.7, "unlocked route passes; real side wall still collides")
	_action("move_right", false)
	_action("jump", false)
	player.vitals.stamina = 0.0
	await _frames(4)
	_check(fly.state == "exhausted", "empty stamina enters controlled exhausted descent")
	for i in 300:
		await physics_frame
		if player.is_on_floor() and not fly.is_flying():
			break
	_check(not fly.is_flying() and player.is_on_floor(), "exhausted descent lands on actual floor")
	_check(player.vitals.health > 0.0, "controlled exhausted landing survives")
	player.vitals.rest()
	await _deploy()
	_action("jump", true)
	await _frames(40)
	_action("jump", false)
	_action("fly_descend", true)
	for i in 300:
		await physics_frame
		if player.is_on_floor() and not fly.is_flying():
			break
	_action("fly_descend", false)
	_check(not fly.is_flying() and player.is_on_floor(), "controller descent ends on floor contact (state=%s y=%.2f vy=%.2f)" % [fly.state, player.position.y, player.velocity.y])
	# A fall below the level must use verified ground, never a highest-XZ snap.
	player.vitals.rest()
	await _deploy()
	var recovery_anchor: Vector3 = fly.safe_anchor
	player.position.y = recovery_anchor.y - 110.0
	await _frames(3)
	_check(not fly.is_flying() and player.position.distance_to(recovery_anchor) < 1.0, "void recovery returns to the physically verified landing")
	_check(player.rider_visible() and not player.is_carried(), "landing preserves ordinary riding/visibility state")
	await _frames(4)
	_check(player.get_node("Model").animation_player().is_playing(), "ordinary trainer animation resumes after flight")
	_check(is_equal_approx(player.get_node("Collision").shape.height, 1.8), "landing restores exact ground collider")
	for action: String in ["jump", "move_right", "fly_descend"]:
		_action(action, false)
	game.save_system = _saved_system
	world.free()
	for failure: String in failures:
		printerr("FAIL: " + failure)
	print("FLY CORE: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _build_world() -> void:
	world = Node3D.new()
	world.name = "FlyPhysicsFixture"
	root.add_child(world)
	_box("Floor", Vector3(0, -1, 0), Vector3(100, 2, 100))
	_box("Wall", Vector3(18, 20, 0), Vector3(1, 40, 80))
	_box("Ceiling", Vector3(0, 14, 0), Vector3(10, 1, 10))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	world.add_child(light)
	var rig := SpringArm3D.new()
	rig.name = "CameraRig"
	rig.set_script(CAMERA)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	world.add_child(rig)
	player = PLAYER.instantiate()
	player.position = Vector3(0, 0.1, 0)
	world.add_child(player)
	fly = player.fly_controller
	fly.register_updraft("fixture", AABB(Vector3(-30, 0, -30), Vector3(60, 20, 60)), 12.0, 20.0)


func _box(id: String, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = id
	body.position = at
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	body.add_child(visual)
	world.add_child(body)


func _deploy() -> void:
	_action("jump", true)
	await _frames(3)
	_action("jump", false)
	await _frames(7)
	_action("jump", true)
	await _frames(3)
	_action("jump", false)
	await _frames(3)


func _action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)
	print("%s %s" % ["OK" if ok else "FAIL", message])


func _capture_if_requested() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(argument.trim_prefix("--capture="))
			print("FLY PERF draws=%d frame_ms=%.2f" % [Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
