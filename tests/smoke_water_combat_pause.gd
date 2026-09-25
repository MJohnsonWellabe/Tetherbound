extends SceneTree

## ACCEPTANCE F12 "combat pause" witness in the production Water scene.
##
## Real: the Water scene, its EncounterDirector/CombatManager/CombatHUD, the
## authored surface wild pair `road_visibility_tidal_cradle_to_salt_crown_
## sheltered_04` spawned by the production site loop, swimming by stick input,
## the Engage press (`interact` through the InteractionArbiter), the mid-fight
## switch press (`party_cycle` read by CombatHUD) and quick attacks
## (`combat_quick`), and the swim state's own pause/resume.
##
## Fixtures (disclosed): every mandatory dock unlock flag is set so the closed
## gate tide race does not ring the salt_crown rest shoal; a two-member Water
## party at level 50; the trainer starts on the authored rest_03 safe landing;
## once the switch is proven the enemy's hp is capped at ENEMY_HP_CEILING (the
## `enemy_hp_ceiling` allowance peer_runner/smoke_net_shared_boss use) so the
## fight finishes inside budget; the second fight starts from an exhaustion
## fixture (stamina 0) to measure drowning damage across a pause.
##
## Not claimed: an aggressive interception. Every Water wild site spawns with
## `aggressive: false` (water_encounter_director.site_spawn_plans), so the only
## production way into a wild fight while swimming is the player's Engage.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SITE_ID := "road_visibility_tidal_cradle_to_salt_crown_sheltered_04"
const ANCHOR_ID := "tidal_cradle_to_salt_crown_rest_03"
const PARTY := ["water_mosshell", "water_riverdrake"]
const ENEMY_HP_CEILING := 12.0
const HUMAN := 1
const PAUSED := 3
const MEASURE_FRAMES := 120
## Horizontal drift allowed between the settled pause and the fight end.
const PAUSED_DRIFT_LIMIT_M := 0.1
## Resumed drain/drowning must be within this fraction of the configured rate.
const RATE_TOLERANCE := 0.1

var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var swimming: Node
var director: Node
var manager: Node
var game: Node
var vitals: RefCounted
var checks := 0
var finished := false
var notes: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(300.0).timeout.connect(func() -> void:
		if not finished:
			_fail("300 second watchdog expired"))
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://smoke_water_combat_pause_fixture")
	game.current_realm = "water"
	var world_config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	for dock: Dictionary in world_config.docks:
		if not str(dock.get("unlock_flag", "")).is_empty():
			game.world.flags.set_flag(str(dock.unlock_flag))
	for id: String in PARTY:
		var creature: RefCounted = SPECIES.spawn(id)
		if not _expect(creature != null, "party fixture species " + id):
			return
		creature.set_level(50, PROGRESSION.config())
		if not _expect(game.local.party.add(creature), "party fixture add " + id):
			return
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 900:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not _expect(bool(world.call("shell_build_complete")), "Water shell built"):
		return
	player = world.get_node("Player")
	camera = world.get_node("CameraRig")
	swimming = player.get("swim_controller")
	director = world.get_node("EncounterDirector")
	manager = world.get_node("CombatManager")
	vitals = player.get("vitals")
	var anchor := _anchor(world.get("config"), ANCHOR_ID)
	if not _expect(anchor.is_finite(), "rest_03 safe anchor authored"):
		return
	anchor.y = float(world.call("ground_height_at", anchor.x, anchor.z)) + 0.15
	# The only trainer position write: the authored dry rest-shoal landing.
	player.global_position = anchor
	player.velocity = Vector3.ZERO
	await _frames(45)
	if not _expect(player.is_on_floor() and not swimming.is_swimming() and swimming.state.has_safe_landing,
		"rest_03 landing settled dry and earned recovery"):
		return
	var landing: Vector3 = swimming.state.safe_landing
	await director.summon_active_creature()
	await _frames(20)
	if not _expect(director.ally_body() != null, "production summon deployed party member 0"):
		return
	var pair: Array = await _site_members()
	if not _expect(pair.size() == 2, "production spawned the authored surface pair (%d)" % pair.size()):
		return
	_note("site=%s species=%s,%s levels=%d,%d" % [SITE_ID, pair[0].instance.species_id, pair[1].instance.species_id,
		pair[0].instance.level, pair[1].instance.level])

	# ---- fight 1: stamina drain pause + mid-fight switch --------------------
	var entered := await _swim_until_offered(pair[0], "fight 1")
	if not entered:
		return
	if not await _engage(pair[0], "fight 1"):
		return
	var pause := await _measure_pause("fight 1")
	if pause.is_empty():
		return
	var before_switch: RefCounted = manager.active_creature()
	await _tap(&"party_cycle")
	var after_switch: RefCounted = manager.active_creature()
	if not _expect(manager.is_fighting() and after_switch != before_switch
		and str(after_switch.species_id) == PARTY[1] and str(director.ally_body().get("species_id")) == PARTY[1],
		"party_cycle switched %s -> %s mid-fight" % [before_switch.species_id, after_switch.species_id]):
		return
	if not _expect(int(swimming.state.mode) == PAUSED and is_equal_approx(float(vitals.stamina), float(pause.stamina))
		and is_equal_approx(float(vitals.health), float(pause.health)), "switch left swim pause and resources frozen"):
		return
	_note("fight 1 switch %s->%s" % [before_switch.species_id, after_switch.species_id])
	if not await _finish_fight("fight 1"):
		return
	if not await _measure_resume(pause, false, "fight 1"):
		return

	# ---- fight 2: drowning damage pause ------------------------------------
	var second: Node3D = pair[1]
	if not _expect(is_instance_valid(second) and bool(second.call("is_alive")), "second surface wild still live"):
		return
	if not await _swim_until_offered(second, "fight 2"):
		return
	vitals.stamina = 0.0 # exhaustion fixture
	var drown_start: float = vitals.health
	await _frames(30)
	var drown_loss := drown_start - float(vitals.health)
	if not _expect(drown_loss > 1.0 and bool(swimming.state.drowning), "exhaustion drowns before engage: lost %.3f HP in 30 frames" % drown_loss):
		return
	_note("fight 2 pre-engage drowning: %.3f HP lost in 30 frames" % drown_loss)
	if not await _engage(second, "fight 2"):
		return
	var drowning_pause := await _measure_pause("fight 2")
	if drowning_pause.is_empty():
		return
	if not await _finish_fight("fight 2"):
		return
	if not await _measure_resume(drowning_pause, true, "fight 2"):
		return

	if not _expect(swimming.state.has_safe_landing and swimming.state.safe_landing.is_equal_approx(landing),
		"safe landing unchanged by both fights: %s vs %s" % [swimming.state.safe_landing, landing]):
		return
	_stick(0, 0)
	finished = true
	for line in notes:
		print("  ", line)
	print("WATER COMBAT PAUSE OK checks=%d" % checks)
	quit(0)


## Real stick input toward the live wild; measures stamina drain en route and
## stops once the director offers this wild through the arbiter.
func _swim_until_offered(wild: Node3D, label: String) -> bool:
	var start_stamina := -1.0
	var swim_frames := 0
	var arbiter: Node = world.get_node("InteractionArbiter")
	for frame in 2400:
		var offset := wild.global_position - player.global_position
		offset.y = 0.0
		if swimming.is_swimming():
			if start_stamina < 0.0:
				start_stamina = vitals.stamina
			swim_frames += 1
		if swimming.is_swimming() and swim_frames > 90 and director._engageable() == wild \
				and arbiter.winning_provider() == director:
			_stick(0, 0)
			await _frames(2)
			var spent := start_stamina - float(vitals.stamina)
			_note("%s swim: %d frames swimming, stamina %.3f -> %.3f (spent %.3f), mode=%d" % [
				label, swim_frames, start_stamina, vitals.stamina, spent, swimming.state.mode])
			return _expect(int(swimming.state.mode) == HUMAN and spent > 0.5, "%s real swim spent stamina (%.3f)" % [label, spent])
		var direction := offset.normalized() if offset.length() > 2.0 else Vector3.ZERO
		var local: Vector3 = camera.planar_basis().inverse() * direction
		_stick(local.x, local.z)
		await physics_frame
	_stick(0, 0)
	return _fail("%s never reached an Engage offer: player=%s wild=%s swimming=%s" % [
		label, player.global_position, wild.global_position, swimming.is_swimming()])


func _engage(wild: Node3D, label: String) -> bool:
	await _tap(&"interact")
	for frame in 60:
		if manager.is_fighting():
			break
		await physics_frame
	return _expect(manager.is_fighting() and manager.enemy_body() == wild, "%s interact press engaged the surface wild" % label)


## Resources frozen while the fight runs, measured over MEASURE_FRAMES.
func _measure_pause(label: String) -> Dictionary:
	await _frames(3)
	var at := {"stamina": float(vitals.stamina), "health": float(vitals.health),
		"position": player.global_position, "frame": Engine.get_physics_frames()}
	if not _expect(int(swimming.state.mode) == PAUSED and not bool(swimming.state.drowning),
		"%s swim state COMBAT_PAUSED (mode=%d)" % [label, swimming.state.mode]):
		return {}
	var modes := {}
	for frame in MEASURE_FRAMES:
		await physics_frame
		modes[int(swimming.state.mode)] = true
	var ok := modes.keys() == [PAUSED] and float(vitals.stamina) == float(at.stamina) and float(vitals.health) == float(at.health)
	_note("%s pause: %d frames, modes=%s stamina %.3f->%.3f health %.3f->%.3f" % [label, MEASURE_FRAMES,
		modes.keys(), at.stamina, vitals.stamina, at.health, vitals.health])
	if not _expect(ok and manager.is_fighting(), "%s stamina and health frozen through the fight" % label):
		return {}
	return at


func _finish_fight(label: String) -> bool:
	var foe_at_start: Node3D = manager.enemy_body()
	var tick := 0
	var frames := 0
	var min_mode_ok := true
	while manager.is_fighting() and frames < 3600:
		var enemy: RefCounted = manager.enemy()
		if enemy != null and float(enemy.hp) > ENEMY_HP_CEILING:
			enemy.hp = ENEMY_HP_CEILING # disclosed hp ceiling fixture
		var foe: Node3D = manager.enemy_body()
		var ally: Node3D = director.ally_body()
		if is_instance_valid(foe) and is_instance_valid(ally):
			var offset := foe.global_position - ally.global_position
			offset.y = 0.0
			if offset.length() > manager.combat_move_reach("quick") * 0.8:
				var local: Vector3 = camera.planar_basis().inverse() * offset.normalized()
				_stick(local.x, local.z)
			else:
				_stick(0, 0)
		if tick % 20 == 0:
			Input.action_press("combat_quick")
		elif tick % 20 == 2:
			Input.action_release("combat_quick")
		if int(swimming.state.mode) != PAUSED:
			min_mode_ok = false
		tick += 1
		frames += 1
		await physics_frame
	Input.action_release("combat_quick")
	_stick(0, 0)
	if not _expect(not manager.is_fighting(), "%s finished inside budget (%d frames)" % [label, frames]):
		return false
	if not _expect(is_instance_valid(foe_at_start) and not bool(foe_at_start.call("is_alive")),
		"%s ended by the wild fainting (a victory), not a flee or loss" % label):
		return false
	_note("%s fight ended after %d frames by the wild fainting; paused throughout=%s" % [label, frames, min_mode_ok])
	return _expect(min_mode_ok, "%s swim state stayed COMBAT_PAUSED for the whole fight" % label)


## After the fight: HUMAN at the surface, no teleport, and the resource that
## was paused resumes from its paused value.
func _measure_resume(pause: Dictionary, drowning: bool, label: String) -> bool:
	var fight_end: Vector3 = player.global_position
	await _frames(2)
	var resume_stamina: float = vitals.stamina
	var resume_health: float = vitals.health
	var jump := player.global_position.distance_to(fight_end)
	var surface_target: float = swimming.state.surface_y - 0.7
	if not _expect(int(swimming.state.mode) == HUMAN, "%s resumed HUMAN (mode=%d)" % [label, swimming.state.mode]):
		return false
	var paused_drift := Vector2(fight_end.x - pause.position.x, fight_end.z - pause.position.z).length()
	if not _expect(jump < 0.5 and paused_drift < PAUSED_DRIFT_LIMIT_M, "%s no teleport: resume step %.3f m, drift during fight %.3f m" % [label, jump, paused_drift]):
		return false
	if not _expect(absf(player.global_position.y - surface_target) < 0.3, "%s swimmer at the surface y=%.3f target=%.3f" % [label, player.global_position.y, surface_target]):
		return false
	if not _expect(absf(resume_stamina - float(pause.stamina)) < 0.2 and absf(resume_health - float(pause.health)) < 0.2,
		"%s resumed from paused values (stamina %.3f vs %.3f, health %.3f vs %.3f)" % [label, resume_stamina, pause.stamina, resume_health, pause.health]):
		return false
	await _frames(MEASURE_FRAMES)
	var stamina_delta := resume_stamina - float(vitals.stamina)
	var health_delta := resume_health - float(vitals.health)
	_note("%s resume over %d frames: stamina -%.3f health -%.3f drowning=%s y=%.3f step=%.3f" % [label, MEASURE_FRAMES,
		stamina_delta, health_delta, swimming.state.drowning, player.global_position.y, jump])
	# The resumed rate must match the configured human rate, not merely be nonzero.
	var seconds := float(MEASURE_FRAMES) / float(Engine.physics_ticks_per_second)
	if drowning:
		var expected_hp := float(_human_config().drowning_damage_per_s) * seconds
		return _expect(bool(swimming.state.drowning) and absf(health_delta - expected_hp) <= expected_hp * RATE_TOLERANCE
			and is_zero_approx(float(vitals.stamina)),
			"%s drowning damage resumed at the configured rate (%.3f HP in %.1f s, expected %.3f)" % [label, health_delta, seconds, expected_hp])
	var expected_stamina := float(_human_config().stamina_drain_per_s) * seconds
	return _expect(absf(stamina_delta - expected_stamina) <= expected_stamina * RATE_TOLERANCE and is_zero_approx(health_delta)
		and not bool(swimming.state.drowning),
		"%s stamina drain resumed at the configured rate (%.3f in %.1f s, expected %.3f)" % [label, stamina_delta, seconds, expected_stamina])


func _human_config() -> Dictionary:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
	return config.human


func _site_members() -> Array:
	var result: Array = []
	for _frame in 120:
		result = director._site_members.get(SITE_ID, [])
		if result.size() == 2:
			break
		await physics_frame
	return result


func _anchor(config: Dictionary, id: String) -> Vector3:
	for anchor: Dictionary in config.get("anchors", []):
		if str(anchor.get("id", "")) == id:
			var raw: Array = anchor.safe_position
			return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.INF


func _stick(x: float, y: float) -> void:
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)


func _tap(action: StringName) -> void:
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
	Input.parse_input_event(up)
	await process_frame
	await _frames(8)


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _note(line: String) -> void:
	notes.append(line)


func _expect(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		_fail(label)
	return ok


func _fail(message: String) -> bool:
	if finished:
		return false
	finished = true
	for line in notes:
		print("  ", line)
	push_error("WATER COMBAT PAUSE FAILED: " + message)
	print("WATER COMBAT PAUSE FAILED: " + message)
	quit(1)
	return false
