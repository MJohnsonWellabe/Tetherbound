extends SceneTree
## Production mounted traversal with explicit inventory/unlock/party fixtures.
## Does not claim Alpha victory, crafting, transport, or visual acceptance.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const IDS := ["water_aquaryn", "water_mosshell", "water_sirenseal", "water_riverdrake", "water_cannonback"]
var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var riding: Node
var director: Node
var game: Node
var checks := 0
var finished := false
var measured_distance := 0.0
var movement_samples: Array = []
func _init() -> void:
	call_deferred("run")
func run() -> void:
	create_timer(240.0).timeout.connect(func() -> void:
		if not finished:
			fail("240 second watchdog"))
	await process_frame
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://smoke_water_mounted_fixture")
	game.current_realm = "water"
	game.local.flags.set_flag("water_swim_stone_earned")
	game.local.flags.set_flag("water_swim_saddle_recipe_taught")
	game.local.inventory.add("swim_saddle", 1)
	for id: String in IDS:
		if not check(game.local.party.add(SPECIES.spawn(id)), "Five-owned-mount fixture add " + id):
			return
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	while not world.call("shell_build_complete"):
		await process_frame
	player = world.get_node("Player")
	camera = world.get_node("CameraRig")
	director = world.get_node("EncounterDirector")
	riding = world.get_node_or_null("RidingController")
	if not check(riding != null, "Water production RidingController mounted"):
		return
	var lesson: Dictionary = world.config.swim_lesson
	var start := anchor(str(lesson.start_anchor))
	var finish := anchor(str(lesson.end_anchor))
	var entry := vec(lesson.surface_polyline[0])
	var midpoint := entry.lerp(vec(lesson.surface_polyline[-1]), 0.5)
	midpoint += Vector3(midpoint.x,0,midpoint.z).normalized()*15.0
	var mount_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_mounts.json")).mounts
	for index in IDS.size():
		var id: String = IDS[index]
		print("WATER MOUNTED start ",id)
		director.dismiss_active_creature()
		game.local.party.set_active(index)
		player.global_position = start + Vector3.UP * 0.2
		player.velocity = Vector3.ZERO
		player.vitals.stamina = player.vitals.max_stamina
		player.vitals.health = player.vitals.max_health
		await frames(30)
		if not check(director.summon_active_creature(), id + " production summon"):
			return
		await frames(30)
		if not check(riding.mount(), id + " production mount from dry shore"):
			return
		var body: Node3D = riding.mount_body()
		var creature: RefCounted = director.ally_instance()
		var energy_before: float = creature.energy
		var human_before: float = player.vitals.stamina
		if not await move_mount_to(entry, 0.9, 1000):
			return
		var stamina_before := stamina(creature)
		measured_distance = 0.0
		if not await move_mount_to(midpoint, 1.0, 1000):
			return
		if not check(measured_distance >= 27.0, id + " actual mounted swimming distance"):
			return
		if not check(stamina(creature) < stamina_before, id + " spends creature swim stamina"):
			return
		if not check(is_equal_approx(creature.energy, energy_before), id + " swimming does not spend combat energy"):
			return
		if not check(float(player.vitals.stamina) >= human_before-0.01, id + " mounted swimming does not spend human stamina"):
			return
		await frames(60)
		var offset := vec(mount_data[id].mount_offset)
		if not check(player.global_position.distance_to(body.to_global(offset)) < 0.15, id + " rider tracks measured seat anchor player=%s seat=%s offset=%s velocity=%s" % [player.global_position,body.to_global(offset),player.carry_offset(),body.velocity]):
			return
		if not check(body.global_position.y + offset.y - 0.92 > 0.05, id + " rider art origin remains above sea"):
			return
		# Explicit exhausted-resource fixture proves gradual damage and no refill
		# from the real dismount/remount path, not a complete crossing budget.
		if not check(world.water_depth_at(body.global_position) > 3.0, id + " deep-water exhaustion fixture"): 
			return
		creature.swim_stamina_fraction = 0.0
		var hp_before: float = creature.hp
		await frames(45)
		if not check(creature.hp < hp_before and creature.hp > 0.0, id + " exhausted mount takes gradual HP loss"):
			return
		if not check(bool(world.get_node("MountedSwimming").state.drowning), id + " mounted drowning state is exposed"):
			return
		movement_samples.append(motion_sample(body, midpoint, Vector3.ZERO))
		if not check(riding.dismount(), id + " deep water dismount"):
			return
		for handoff_frame in 4:
			await physics_frame
			movement_samples.append(motion_sample(body, midpoint, Vector3.ZERO))
		if not check(int(player.swim_controller.state.mode) == 1, id + " dismounted rider enters human swimming state=%s depth=%s pos=%s" % [player.swim_controller.snapshot(),world.water_depth_at(player.global_position),player.global_position]):
			return
		if not check(riding.mount(), id + " real remount while exhausted"):
			return
		for handoff_frame in 4:
			await physics_frame
			movement_samples.append(motion_sample(body, midpoint, Vector3.ZERO))
		if not check(is_zero_approx(stamina(creature)), id + " remount does not refill creature swim stamina"):
			return
		# Restore only this explicit fixture resource so dry-exit evidence can
		# continue independently of whether the exhausted mount would faint.
		creature.swim_stamina_fraction = 1.0
		# Physical safe landing completes this mount's input-driven evidence leg.
		if not await move_mount_to(vec(lesson.surface_polyline[-1]), 1.0, 1000):
			return
		if not await move_mount_to(finish, 1.0, 1800):
			return
		if not check(riding.dismount(), id + " dismount after shore crossing"):
			return
		await frames(30)
		if not check(player.is_on_floor(), id + " safe land exit restores grounded player"):
			return
	finished = true
	action(false)
	print("WATER MOUNTED SWIMMING OK checks=%d mounts=%d" % [checks, IDS.size()])
	quit(0)
func stamina(creature: RefCounted) -> float:
	return float(creature.get("swim_stamina_fraction"))
func move_mount_to(target: Vector3, tolerance: float, limit: int) -> bool:
	var body: Node3D = riding.mount_body()
	var previous := body.global_position
	for _frame in limit:
		var delta := target - body.global_position
		delta.y = 0
		if delta.length() <= tolerance:
			action(false)
			await frames(2)
			return true
		camera.set("yaw", atan2(-delta.x, -delta.z))
		action(true)
		if _frame % 120 == 0:
			movement_samples.append(motion_sample(body, target, delta.normalized()))
		await physics_frame
		var moved := body.global_position - previous
		moved.y = 0
		measured_distance += moved.length()
		previous = body.global_position
		if not riding.is_mounted():
			return fail("unexpected dismount while approaching %s" % target)
	print("WATER MOUNTED MOTION ",JSON.stringify(movement_samples))
	return fail("mounted movement timed out target=%s actual=%s latest=%s" % [target,body.global_position,motion_sample(body,target,Vector3.ZERO)])
func anchor(id: String) -> Vector3:
	for row: Dictionary in world.config.anchors:
		if str(row.id) == id:
			var at := vec(row.safe_position)
			at.y = world.ground_height_at(at.x, at.z)
			return at
	return Vector3.INF
func vec(raw: Array) -> Vector3:
	return Vector3(float(raw[0]),float(raw[1]),float(raw[2]))
func frames(count: int) -> void:
	for _frame in count:
		await physics_frame
func action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)
func check(ok: bool, label: String) -> bool:
	checks += 1
	return true if ok else fail(label)
func fail(label: String) -> bool:
	finished = true
	action(false)
	push_error("WATER MOUNTED: " + label)
	quit(1)
	return false






func motion_sample(body: CharacterBody3D, target: Vector3, expected: Vector3) -> Dictionary:
	var actual_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var basis_value: Basis = camera.planar_basis()
	var request := basis_value * Vector3(actual_input.x,0,actual_input.y)
	var contacts: Array = []
	for index in body.get_slide_collision_count():
		var hit := body.get_slide_collision(index)
		var collider := hit.get_collider()
		contacts.append({"collider":str(collider.get_path()) if collider is Node else str(collider), "normal":hit.get_normal(),"velocity":hit.get_collider_velocity()})
	var input_owner: Node = preload("res://scripts/ui/input_owner.gd").current(self)
	return {"contacts":contacts,"tick":Time.get_ticks_msec(),"position":body.global_position,"target":target,
		"expected_direction":expected,"input":actual_input,"camera_yaw":camera.yaw,
		"camera_basis":basis_value,"derived_request":request,"requested":body.get("_requested"),
		"requested_speed":body.get("_requested_speed"),"velocity":body.velocity,
		"impulse":body.get("_impulse"),"platform_velocity":body.get_platform_velocity(),
		"environment_added":body.get("_environment_velocity").get("_added"),
		"environment_surviving":body.get("_environment_velocity").get("_surviving"),
		"physics_enabled":body.is_physics_processing(),"layer":body.collision_layer,"mask":body.collision_mask,
		"following":body.is_following(),"on_floor":body.is_on_floor(),"floor_normal":body.get_floor_normal(),
		"depth":world.water_depth_at(body.global_position),"ground":world.ground_height_at(body.global_position.x,body.global_position.z),
		"current":world.current_at(body.global_position),"riding":riding.is_mounted(),
		"riding_allowed":riding._riding_allowed(),"riding_speed":riding.ride_speed_now(),
		"input_owner":str(input_owner.get_path()) if input_owner != null else "",
		"mounted_state":world.get_node("MountedSwimming").state.snapshot(),
		"player_carried":player.is_carried(),"player_position":player.global_position}


