extends SceneTree

## Continuous late Tidewake traversal diagnostic.  Its one explicit seam
## fixture is synthetic: a healthy level-60 owned Aquaryn plus the resolved
## Alpha, Swim Stone, Iona recipe and saddle facts begin at Tidal Cradle's
## departure.  The established production smoke instead defeats Aquaryn with
## a level-49 Mosshell; this diagnostic must not be cited as acceptance of that
## ordinary branch.  Once the
## mount leaves that shore this script never teleports an actor, sets a story
## flag, adds materials, or repairs health/stamina.  Travel uses the authored
## route polylines and the same physical movement path as a player; every later
## flag must come from its production prompt or combat result.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CATALOG := preload("res://scripts/creatures/water_species_catalog.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

const START_ANCHOR := "tidal_cradle_to_salt_crown_departure"
const LATE_ROUTES := [
	"tidal_cradle_to_salt_crown_sheltered",
	"salt_crown_to_sluice_isle_sheltered",
	"sluice_isle_to_veilfall_sheltered",
]
const WATCHDOG_MS := 15 * 60 * 1000

var game: Node
var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var director: Node
var manager: Node
var riding: Node
var navigator: RefCounted
var checks := 0
var failures: Array[String] = []
var finished := false
var started_ms := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	_watchdog.call_deferred()
	await process_frame
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = "water-continuous-late"
	game.world.world_id = "water-continuous-late-world"
	game.save_system = SAVE.new("user://water_continuous_late_%d/" % Time.get_ticks_usec())
	var merged: Dictionary = CATALOG.merge_catalogue(SPECIES.table())
	if not _check(bool(merged.ok), "Water species catalogue accepts the late-route fixture"):
		_finish()
		return
	SPECIES.table().merge(merged.catalogue, true)

	# Synthetic diagnostic setup, and the only direct progression setup in this
	# witness. No value below is repaired after `DEPARTED` is printed.
	game.world.flags.set_flag("water_aquaryn_resolved")
	game.local.flags.set_flag("water_swim_stone_earned")
	game.local.flags.set_flag("water_swim_saddle_recipe_learned")
	game.inventory.add("swim_saddle", 1)
	var aquaryn: RefCounted = SPECIES.spawn("water_aquaryn")
	aquaryn.set_level(60, PROGRESSION.config())
	if not _check(game.local.party.add(aquaryn), "Synthetic level-60 Aquaryn diagnostic fixture is disclosed before departure"):
		_finish()
		return

	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 90000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not _check(world.shell_build_complete(), "Production Tidewake world finishes building"):
		_finish()
		return
	player = world.local_rig()
	camera = world.local_camera_rig()
	director = world.get_node("EncounterDirector")
	manager = world.get_node("CombatManager")
	riding = world.get_node("RidingController")
	navigator = NAVIGATOR.new(self, player, camera, _send_stick)

	# Initial pose belongs to the declared seam, before continuous evidence.
	player.global_position = _anchor(START_ANCHOR)
	player.velocity = Vector3.ZERO
	await _frames(12)
	if not _check(await director.summon_active_creature(), "Production summon deploys the surviving Aquaryn at Tidal Cradle"):
		_finish()
		return
	await _frames(24)
	if not _check(riding.mount(), "Synthetic Swim Stone/saddle fixture permits production mounting of Aquaryn"):
		_finish()
		return
	await _frames(8)
	_checkpoint("DEPARTED Tidal Cradle; fixture writes are now forbidden")

	if not await _cross_route(LATE_ROUTES[0]):
		_finish()
		return
	_checkpoint("LANDED Salt Crown on the same mount and stamina")
	if not await _dismount_on_land("Salt Crown"):
		_finish()
		return
	if not await _walk_land_route("salt_crown_exploration_spine"):
		_finish()
		return
	if not await _activate_dock_action("salt_crown_chart", "water_dock_salt_crown_landing_charted"):
		_finish()
		return
	_checkpoint("CHARTED Salt Crown onward crossing through its production prompt")
	if not await _mount_existing("Salt Crown departure"):
		_finish()
		return
	if not await _cross_route(LATE_ROUTES[1]):
		_finish()
		return
	_checkpoint("LANDED Sluice Isle on the same unrepaired mount")
	if not await _dismount_on_land("Sluice Isle"):
		_finish()
		return

	# Follow the authored island spine toward Bex instead of taking a straight
	# analytic chord through Sluice Isle's pump terrain.
	# Bex guards the western control directly off the arrival leg. Continue to
	# Twin Pumps only after his result permits that control to be disabled.
	var sluice_path := _land_route("sluice_isle_exploration_spine")
	for index in range(1, 2):
		var point: Vector3 = sluice_path[index]
		if not await _walk_to(point, "Sluice approach waypoint %d" % index):
			_finish()
			return
		_checkpoint("Sluice approach waypoint %d player=%s target=%s" % [
			index, str(player.global_position), str(point)])
	if not await _defeat_trainer("water_trainer_bex", "defeated_water_trainer_bex"):
		_finish()
		return
	if not await _activate_dock_action("sluice_west_control", "water_sluice_west_disabled"):
		_finish()
		return
	_checkpoint("BEX defeated and western control disabled")
	if not await _recover_at_camp("water_camp_sluice_isle"):
		_finish()
		return
	_checkpoint("Aquaryn recovered through the authored Sluice creature bed and overnight rest")
	for index in range(2, 4):
		var point: Vector3 = sluice_path[index]
		if not await _walk_to(point, "Sluice ascent waypoint %d" % index):
			_finish()
			return
		_checkpoint("Sluice ascent waypoint %d player=%s target=%s" % [
			index, str(player.global_position), str(point)])

	# Calder guards the east control near waypoint 5. Reach him on the same
	# graded departure leg rather than cutting back through the central crown.
	for index in range(4, 6):
		var point: Vector3 = sluice_path[index]
		if not await _walk_to(point, "Sluice departure waypoint %d" % index):
			_finish()
			return
		_checkpoint("Sluice departure waypoint %d player=%s target=%s" % [
			index, str(player.global_position), str(point)])
	if not await _defeat_trainer("water_trainer_calder", "defeated_water_trainer_calder"):
		_finish()
		return
	if not await _activate_dock_action("sluice_east_control", "water_sluice_east_disabled"):
		_finish()
		return
	if not await _wait_flag("water_dock_sluice_isle_both_controls_disabled", 240):
		_fail("Both physical Sluice controls did not publish their combined completion")
		_finish()
		return
	if not _check(not world.get_node("WaterDocks").get("_barriers").has(
			"water_dock_sluice_isle_both_controls_disabled"),
			"Combined Sluice completion removes the final crossing barrier"):
		_finish()
		return
	_checkpoint("CALDER defeated; both controls and final barrier are open")

	if not await _mount_existing("Sluice Isle departure"):
		_finish()
		return
	if not await _cross_route(LATE_ROUTES[2]):
		_finish()
		return
	_checkpoint("LANDED Veilfall after the longest authored crossing")
	if not await _dismount_on_land("Veilfall"):
		_finish()
		return

	# The complete authored exploration spine is the graded exterior hike. Venn
	# is fought where production placed him before the path returns to the falls.
	var veilfall_path := _land_route("veilfall_exploration_spine")
	for index in range(1, veilfall_path.size() - 1):
		if not await _walk_to(veilfall_path[index], "Veilfall exterior waypoint %d" % index):
			_finish()
			return
	if not await _defeat_trainer("water_trainer_venn", "defeated_water_trainer_venn"):
		_finish()
		return
	if not await _walk_to(veilfall_path[-1], "waterfall entrance"):
		_finish()
		return
	_checkpoint("OFFICER VENN defeated after the physical Veilfall hike")

	var cave: Node3D = world.get_node("WaterVeilfall")
	if not await _activate_prompt(cave.get("_entry_prompt"), "Veilfall waterfall entrance"):
		_finish()
		return
	await _frames(12)
	if not _check(cave.contains_interior(player.global_position), "Waterfall entrance transfers the same player into Veilfall"):
		_finish()
		return
	var controls: Dictionary = cave.get("_controls")
	if not await _walk_to(cave.interior.position + Vector3(-5, 0, 18.9), "intake pump") \
			or not await _activate_prompt(controls.intake_pump, "Veilfall intake pump") \
			or not await _wait_flag("water_veilfall_intake_stopped", 180):
		_fail("Physical Veilfall intake sequence did not complete")
		_finish()
		return
	if not await _walk_to(cave.interior.position + Vector3(0, 0, 34), "opened intake grille") \
			or not await _walk_to(cave.interior.position + Vector3(9, 0, 45.9), "return sluice") \
			or not await _activate_prompt(controls.sluice_wheel, "Veilfall return sluice") \
			or not await _wait_flag("water_veilfall_return_opened", 180):
		_fail("Physical Veilfall return-sluice sequence did not complete")
		_finish()
		return
	for local_point: Vector3 in [Vector3(0, 0, 56), Vector3(0, 0, 70), Vector3(0, 0, 87)]:
		if not await _walk_to(cave.interior.position + local_point, "Veilfall interior waypoint"):
			_finish()
			return
	_checkpoint("Veilfall intake and return sluices opened through physical controls")

	if not await _defeat_trainer("water_trainer_nerissa", "water_captain_nerissa_defeated"):
		_finish()
		return
	if not await _activate_prompt(controls.guardian_tether, "Abyssal Guardian tether") \
			or not await _wait_flag("water_guardian_freed", 240):
		_fail("Nerissa victory did not permit the physical Guardian release")
		_finish()
		return
	_checkpoint("CAPTAIN NERISSA defeated and Guardian tether released")

	if not await _activate_prompt(cave.get("_guardian_prompt"), "freed Abyssal Guardian"):
		_finish()
		return
	if not await _wait_flag("water_currents_restored", 600):
		_fail("Guardian settlement did not publish water_currents_restored")
		_finish()
		return
	_check(game.world.flags.has("water_guardian_settled"), "Guardian settlement is durable before currents restore")
	_check(game.local.party.members().any(func(member: RefCounted) -> bool:
		return str(member.species_id) == "water_abyssal_guardian"),
		"Guardian enters the available ordinary party holder")
	_checkpoint("WATER CURRENTS RESTORED through one continuous late chapter")
	_finish()


func _cross_route(id: String) -> bool:
	if not riding.is_mounted():
		return _fail("Route %s began without the established swim mount" % id)
	var route := _route(id)
	if route.is_empty():
		return _fail("Authored water route is missing: " + id)
	for raw: Array in route.polyline:
		var point := _v(raw)
		var distance: float = riding.mount_body().global_position.distance_to(point)
		if not await _move_mount_to(point, maxi(900, int(distance * 45.0)), 2.5):
			return false
	var arrival := _anchor(str(route.to_anchor))
	return await _move_mount_to(arrival, 1600, 1.8)


func _move_mount_to(target: Vector3, budget: int, tolerance: float) -> bool:
	for frame in budget:
		if not riding.is_mounted() or not is_instance_valid(riding.mount_body()):
			_stop_stick()
			return _fail("Mount was lost at %s while travelling toward %s" % [
				str(riding.mount_body().global_position if is_instance_valid(riding.mount_body()) else Vector3.INF),
				str(target)])
		var body: Node3D = riding.mount_body()
		var offset := target - body.global_position
		offset.y = 0
		if offset.length() <= tolerance:
			_stop_stick()
			await _frames(6)
			return true
		var local: Vector3 = camera.planar_basis().inverse() * offset.normalized()
		_send_stick(local.x, local.z)
		await physics_frame
	_stop_stick()
	return _fail("Mounted route timed out %.1fm from %s (stamina=%.3f hp=%.1f)" % [
		riding.mount_body().global_position.distance_to(target), str(target),
		float(director.ally_instance().swim_stamina_fraction), float(director.ally_instance().hp)])


func _dismount_on_land(label: String) -> bool:
	if not _check(riding.is_mounted(), label + " landing retains its mount"):
		return false
	if not _check(world.water_depth_at(riding.mount_body().global_position) < 1.2,
			label + " route reaches authored shallow land"):
		return false
	if not _check(riding.dismount(), label + " production dismount succeeds"):
		return false
	await _frames(12)
	return _check(player.is_on_floor(), label + " dismount leaves the player grounded")


func _mount_existing(label: String) -> bool:
	if director.ally_body() == null:
		if not await director.summon_active_creature():
			return _fail(label + ": surviving active creature could not be summoned")
	await _frames(20)
	var body: Node3D = director.ally_body()
	if body == null or not is_instance_valid(body):
		return _fail(label + ": active creature has no mountable production body")
	_checkpoint(label + " pre-approach mount predicates: " + _mount_predicates(body))
	# A battle can leave the creature several metres from the trainer. Mounting
	# is a proximity interaction, so physically approach the surviving follower
	# and require its real Ride offer instead of calling mount from wherever the
	# preceding control happened to leave the player.
	var radius := float(body.body_radius()) if body.has_method("body_radius") else 0.0
	if not await _walk_to(body.global_position, label + " mount approach", radius + 2.5):
		return false
	var offer: Dictionary = riding.interaction_offer(player.global_position)
	_checkpoint(label + " reached follower; mount predicates: " + _mount_predicates(body))
	if offer.is_empty() or not bool(offer.get("actionable", true)):
		return _fail("%s: production Ride offer refused (%s offer=%s)" % [
			label, _mount_predicates(body), str(offer)])
	riding.interaction_activate()
	await _frames(6)
	if not riding.is_mounted():
		return _fail(label + ": actionable production Ride offer did not mount the surviving creature")
	await _frames(6)
	return true


func _mount_predicates(body: Node3D) -> String:
	var arbiter: Node = riding.get("_arbiter") as Node
	var mountable: Node3D = riding.call("_mountable_body") as Node3D
	var species_id := str(body.get("species_id"))
	var instance: RefCounted = director.ally_instance()
	return "player=%s body=%s visible=%s rideable_body=%s fainted=%s allowed=%s arbiter_enabled=%s surface_distance=%.2f centre_distance=%.2f has_tack=%s saddle=%d swim_flag=%s fight=%s trainer=%s input_owner=%s" % [
		str(player.global_position), str(body.global_position), str(body.visible),
		str(mountable == body), str(bool(instance.fainted)) if instance != null else "missing",
		str(bool(riding.call("_riding_allowed"))),
		str(bool(arbiter.call("enabled"))) if arbiter != null else "missing",
		mount_surface_distance_for_diagnostic(riding, player.global_position, body),
		player.global_position.distance_to(body.global_position),
		str(bool(riding.call("_has_tack", species_id))), game.inventory.count("swim_saddle"),
		str(game.local.flags.has("water_swim_stone_earned")), str(manager.is_fighting()),
		str(director.trainer_battle_active()),
		str(INPUT_OWNER.current(self).get_path()) if INPUT_OWNER.current(self) != null else "none"]


static func mount_surface_distance_for_diagnostic(
		riding_node: Node, from: Vector3, body: Node3D) -> float:
	return float(riding_node.call("_mount_surface_distance", from, body))


func _walk_land_route(id: String) -> bool:
	var points := _land_route(id)
	if points.is_empty():
		return _fail("Authored land route is missing: " + id)
	for point: Vector3 in points.slice(1):
		if not await _walk_to(point, id):
			return false
	return true


func _walk_to(point: Vector3, label: String, tolerance: float = 1.3) -> bool:
	var horizontal := Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(point.x, point.z))
	var budget := maxi(1200, int(horizontal * 65.0))
	var arrived: bool = await navigator.walk_to(point, budget, tolerance)
	_stop_stick()
	if not arrived:
		return _fail("Walking failed for %s: %.1fm remain, player=%s target=%s resets=%d locomotion=%s input_owner=%s colliders=%s" % [
			label, player.global_position.distance_to(point), str(player.global_position), str(point),
			int(navigator.confined_resets()), str(navigator.can_walk()),
			str(INPUT_OWNER.current(self).get_path()) if INPUT_OWNER.current(self) != null else "none",
			_collision_context(player.global_position, point)])
	await _frames(4)
	return true


func _collision_context(at: Vector3, target: Vector3) -> String:
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = 4.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]
	var found: Array[String] = []
	for sample: Dictionary in [{"label": "player", "at": at}, {"label": "target", "at": target}]:
		query.transform = Transform3D(Basis.IDENTITY, sample.at)
		for hit: Dictionary in space.intersect_shape(query, 24):
			var collider: Object = hit.get("collider")
			if collider == null:
				continue
			var path := str((collider as Node).get_path()) if collider is Node else str(collider)
			found.append("%s:%s" % [str(sample.label), path])
	return str(found)


func _defeat_trainer(id: String, flag: String) -> bool:
	if not director.trainer_nodes.has(id):
		return _fail("Production trainer is absent: " + id)
	var prompt: Node3D = director.trainer_prompts.get(id)
	if not await _activate_prompt(prompt, id + " challenge"):
		return false
	await _drain_dialogue()
	var deadline := Time.get_ticks_msec() + 15000
	while not director.trainer_battle_active() and Time.get_ticks_msec() < deadline:
		await physics_frame
	if not director.trainer_battle_active():
		return _fail(id + " challenge never entered production combat")
	var opponents: Dictionary = {}
	deadline = Time.get_ticks_msec() + 180000
	var tick := 0
	while director.trainer_battle_active() and Time.get_ticks_msec() < deadline:
		var enemy: Node3D = manager.enemy_body()
		var ally: Node3D = director.ally_body()
		if is_instance_valid(enemy) and is_instance_valid(ally) and manager.is_fighting():
			opponents[enemy.get_instance_id()] = str(enemy.instance.species_id)
			ally.face_towards(enemy.global_position)
			var offset := enemy.global_position - ally.global_position
			offset.y = 0
			_stop_combat_input()
			if offset.length() > manager.combat_move_reach("quick") * 0.8:
				var local: Vector3 = camera.planar_basis().inverse() * offset.normalized()
				_send_stick(local.x, local.z)
			if tick % 20 == 0:
				Input.action_press("combat_quick")
			elif tick % 20 == 2:
				Input.action_release("combat_quick")
		else:
			_stop_combat_input()
		tick += 1
		await physics_frame
	_stop_combat_input()
	if director.trainer_battle_active():
		return _fail("%s combat exceeded 180 seconds after %d opponents" % [id, opponents.size()])
	await _drain_dialogue()
	if not await _wait_flag(flag, 180):
		var ally: RefCounted = director.ally_instance()
		return _fail("%s ended without %s (opponents=%s ally_hp=%.1f/%.1f fainted=%s blocker=%s)" % [
			id, flag, str(opponents.values()), float(ally.hp) if ally != null else -1.0,
			float(ally.max_hp) if ally != null else -1.0,
			str(bool(ally.fainted)) if ally != null else "missing", str(director.usable_ally_blocker())])
	_checkpoint("defeated %s opponents=%d" % [id, opponents.size()])
	return true


func _recover_at_camp(id: String) -> bool:
	var service: Node = world.get_node_or_null("WaterCamps")
	var rest: Node3D = service.camps.get(id) if service != null else null
	var bed: Node3D = service.get_node_or_null(id + "_creature_bed") if service != null else null
	var bed_prompt: Node3D = bed.get_node_or_null("Interactable") if bed != null else null
	var rest_prompt: Node3D = rest.get_node_or_null("Interactable") if rest != null else null
	if rest == null or bed == null or bed_prompt == null or rest_prompt == null:
		return _fail("Authored recovery services are missing at " + id)
	var member: RefCounted = game.local.party.at(0)
	if director.ally_body() != null:
		await _tap("creature_recall")
		await _frames(12)
	if director.ally_body() != null:
		return _fail(id + " recovery could not recall the active creature")
	if not await _activate_prompt(bed_prompt, id + " creature bed"):
		return false
	var panel: Node = INPUT_OWNER.current(self)
	var focus := root.get_viewport().gui_get_focus_owner() as Button
	if not _check(panel != null and panel.has_method("is_open") and bool(panel.is_open()),
			"Sluice creature-bed interaction opens its production panel"):
		return false
	if not _check(focus != null and not focus.disabled,
			"Creature-bed panel gives controller focus to an enabled party row"):
		return false
	await _tap("ui_accept")
	await _frames(8)
	if not _check(bool(member.resting) and int(member.rest_bed_index) == int(bed.build_index()),
			"Controller input assigns Aquaryn to the authored Sluice creature bed"):
		return false
	await _tap("menu_cancel")
	await _frames(8)
	var day_before: int = game.day
	if not await _activate_prompt(rest_prompt, id + " overnight rest"):
		return false
	var deadline := Time.get_ticks_msec() + 15000
	while game.day == day_before and Time.get_ticks_msec() < deadline:
		await physics_frame
	if not _check(game.day == day_before + 1, "Ordinary Sluice camp input advances one night"):
		return false
	if not _check(not bool(member.fainted) and float(member.hp) >= float(member.max_hp) - 0.01,
			"Physically bedded Aquaryn recovers overnight without an HP injection"):
		return false
	await _tap("creature_recall")
	await _frames(24)
	return _check(director.ally_body() != null, "Controller input redeploys the recovered Aquaryn")


func _activate_dock_action(id: String, flag: String) -> bool:
	var equipment := world.get_node("WaterDocks").get_node_or_null(id) as Node3D
	if equipment == null:
		return _fail("Production dock equipment is absent: " + id)
	var prompt: Node3D
	for child: Node in equipment.get_children():
		if child.has_method("interaction_offer"):
			prompt = child
			break
	if prompt == null or not await _activate_prompt(prompt, id):
		return false
	if not await _wait_flag(flag, 180):
		return _fail("Dock action %s did not publish %s" % [id, flag])
	return true


func _activate_prompt(prompt: Node3D, label: String) -> bool:
	if prompt == null or not is_instance_valid(prompt):
		return _fail(label + " has no production prompt")
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var at := prompt.global_position + Vector3(cos(angle), 0, sin(angle)) * 2.5
		var floor: float = world.ground_height_at(at.x, at.z)
		if is_finite(floor):
			at.y = floor + 0.1
		if not await _walk_to(at, label + " approach", 1.0):
			return false
		if not prompt.interaction_offer(player.global_position).is_empty():
			prompt.interaction_activate()
			await _frames(5)
			return true
	return _fail("%s never offered interaction from a physically reached stance" % label)


func _drain_dialogue() -> void:
	var dialogue: Node = world.get_node("DialoguePanel")
	for step in 80:
		if not dialogue.is_open():
			return
		dialogue.advance()
		await _frames(2)


func _wait_flag(id: String, maximum_frames: int) -> bool:
	for frame in maximum_frames:
		if game.world.flags.has(id):
			return true
		await physics_frame
	return game.world.flags.has(id)


func _route(id: String) -> Dictionary:
	for route: Dictionary in world.config.water_routes:
		if str(route.id) == id:
			return route
	return {}


func _land_route(id: String) -> Array[Vector3]:
	for route: Dictionary in world.config.land_routes:
		if str(route.id) == id:
			var result: Array[Vector3] = []
			for raw: Array in route.polyline:
				result.append(_v(raw))
			return result
	return []


func _anchor(id: String) -> Vector3:
	for row: Dictionary in world.config.anchors:
		if str(row.id) == id:
			var point := _v(row.safe_position)
			point.y = world.ground_height_at(point.x, point.z) + 0.15
			return point
	return Vector3.INF


func _v(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _send_stick(x: float, y: float) -> void:
	_send_axis(JOY_AXIS_LEFT_X, x)
	_send_axis(JOY_AXIS_LEFT_Y, y)


func _send_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


func _stop_stick() -> void:
	_send_stick(0.0, 0.0)


func _stop_combat_input() -> void:
	_stop_stick()
	Input.action_release("combat_quick")


func _tap(action: StringName) -> void:
	# GUI controls consume parsed action events; changing the Input singleton's
	# polled state alone drives combat but does not press a focused Button.
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	down.strength = 1.0
	Input.parse_input_event(down)
	await process_frame
	await _frames(4)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	up.strength = 0.0
	Input.parse_input_event(up)
	await process_frame
	await _frames(8)


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame


func _check(ok: bool, label: String) -> bool:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok:
		failures.append(label)
	return ok


func _fail(message: String) -> bool:
	_check(false, message)
	return false


func _checkpoint(label: String) -> void:
	print("WATER CONTINUOUS +%.1fs — %s" % [
		(Time.get_ticks_msec() - started_ms) / 1000.0, label])


func _watchdog() -> void:
	while not finished and Time.get_ticks_msec() - started_ms < WATCHDOG_MS:
		await create_timer(1.0).timeout
	if not finished:
		_fail("15 minute continuous Tidewake watchdog expired")
		_finish()


func _finish() -> void:
	if finished:
		return
	finished = true
	_stop_combat_input()
	print("WATER CONTINUOUS LATE: %d checks, %d failures" % [checks, failures.size()])
	if not failures.is_empty():
		print("WATER CONTINUOUS FAILURES: ", failures)
	quit(0 if failures.is_empty() else 1)
