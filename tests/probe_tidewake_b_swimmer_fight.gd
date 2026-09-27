extends SceneTree

## DRY RUN probe (does not count): reproduces the DRY RUN 7 swimmer catch-fight
## stall without replaying the campaign. Declared fixtures: world/personal flags,
## a spawned five-member party matching the DRY RUN 7 belt, and a POSED trainer
## start on the beach below the Tidal Cradle mosshell ledge. From there the
## production path is used unchanged: controller-deployed ally, the swimmer
## preparation's planned approach, the exact-wild Engage, and the replacement
## segment's own _fight_until_catchable, with a per-60-frame monitor and a
## first-floor-loss report (the ally pinned at the arena wall on the cliff).
## --survey lists resident wild bodies with 8 m ground relief; --ground compares
## sampled ground with ray hits under the ledge. Observation only.
##   godot --headless --path . --script tests/probe_tidewake_b_swimmer_fight.gd [-- --survey|--ground]
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const HARVEST := preload("res://tests/helpers/water_reedhaven_segment.gd")
const PREP := preload("res://tests/helpers/water_earned_swimmer_preparation_segment.gd")
const SWIMMER := preload("res://tests/helpers/water_earned_swimmer_segment.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TARGET := "water_tidal_cradle_wild_009_0"
const WANT_SPECIES := "water_mosshell"
## Beside the Tidal camp bed, where DRY RUN 7's recovery left the trainer.
const START := Vector3(556.1, 0.0, 1362.0)
const ACTIVE_SLOT := 3
const BELT := [["terrapup", 56], ["bramblebun", 55], ["mudsnout", 55], ["sparkit", 55], ["sparkit", 55]]
var _hits := 0
var _misses := 0
var _taken := 0
var _monitoring := true
var _frames_fought := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	print("DRY RUN probe - does not count: declared flags, fixture belt, posed trainer start")
	var game: Node = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	for flag: String in ["water_swim_lesson_complete", "water_dock_reedhaven_repaired",
			"water_dock_brine_steps_trial_won", "water_aquaryn_resolved",
			"water_dock_salt_crown_landing_charted",
			"water_dock_shellwatch_residents_freed_and_pump_disabled",
			"water_dock_sluice_isle_both_controls_disabled"]:
		game.world.flags.set_flag(flag)
	for flag: String in ["water_swim_lesson_briefed", "water_swim_stone_earned", "water_swim_saddle_recipe_learned"]:
		game.local.flags.set_flag(flag)
	while game.party.size() > 0:
		game.party.remove_at(0)
	for row: Array in BELT:
		var creature: RefCounted = SPECIES.spawn(str(row[0]))
		creature.set_level(int(row[1]), PROGRESSION.config())
		creature.hp = creature.max_hp
		game.party.add(creature)
	# DRY RUN 7's fighter: Irva's sparkit matchup lead (slot 3) stayed active.
	game.party.set_active(ACTIVE_SLOT)
	var world: Node3D = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	var player: CharacterBody3D = world.get_node("Player")
	var camera: Node3D = world.get_node("CameraRig")
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	# Declared fixture seed: the first world seed whose production roll makes
	# this site the DRY RUN 7 water_mosshell (the campaign seed is not logged).
	var site: Dictionary = {}
	for row: Dictionary in director.encounter_config.get("wild_sites", []):
		if str(row.id) + "_0" == TARGET:
			site = row
	var table: Dictionary = director.find_id(director.chapter.get("encounter_tables", []), str(site.table_id))
	for seed_value in range(1, 5000):
		var rolled: Dictionary = director.roll_wild(table, seed_value, hash(str(site.id)))
		if str(rolled.get("species", "")) == WANT_SPECIES:
			game.world_seed = seed_value
			print("FIXTURE world_seed=%d rolls %s level %s" % [seed_value, rolled.species, rolled.level])
			break
	var start := START
	start.y = float(world.call("ground_height_at", start.x, start.z)) + 0.3
	player.global_position = start
	player.velocity = Vector3.ZERO
	print("POSE probe start -> %s" % start)
	if OS.get_cmdline_user_args().has("--survey"):
		for _frame in 240:
			await physics_frame
		for body: Node3D in director.wild_creatures():
			if not is_instance_valid(body) or not body.has_meta("water_site_id"):
				continue
			var at := body.global_position
			var worst := 0.0
			for i in 16:
				for r: float in [2.0, 4.0, 6.0, 8.0]:
					var p: Vector3 = at + Vector3(cos(i * TAU / 16.0), 0.0, sin(i * TAU / 16.0)) * r
					worst = maxf(worst, absf(float(world.call("ground_height_at", p.x, p.z)) - at.y))
			print("SURVEY %s %s compatible=%s mode=%s depth=%.2f at=%s relief8m=%.1f" % [body.name, body.species_id,
				SWIMMER.compatible_swimmer(str(body.species_id)), str(body.get_meta("water_placement_mode", "")),
				float(world.water_depth_at(at)), at, worst])
		quit(0)
		return
	if OS.get_cmdline_user_args().has("--ground"):
		await _ground_survey(world, player)
		return
	var target: Node3D
	for _frame in 600:
		await physics_frame
		for body: Node3D in director.wild_creatures():
			if is_instance_valid(body) and body.name == TARGET:
				target = body
		if target != null:
			break
	if target == null:
		print("PROBE RESULT FAIL: resident %s not spawned" % TARGET)
		quit(1)
		return
	var harvest: RefCounted = HARVEST.new()
	harvest.setup(self, world, player, camera)
	var care: RefCounted = SWIMMER.WATER_WALK.new()
	care.setup(self, world, player, camera)
	if not await care._ensure_ally_deployed("probe"):
		print("PROBE RESULT FAIL: ally deploy %s" % str(care.failures))
		quit(1)
		return
	var capture: RefCounted = CountingSwimmer.new()
	capture._tree = self
	capture._world = world
	capture._game = game
	capture._player = player
	capture._rig = camera
	capture._encounter = director
	capture._combat = manager
	capture._arbiter = world.get_node("InteractionArbiter")
	print("TARGET %s species=%s level=%d at %s" % [target.name, target.species_id,
		target.get("instance").level, target.global_position])
	if not await PREP.planned_approach(harvest, world, player, target.global_position, "probe swimmer"):
		print("PROBE RESULT FAIL: planned approach %s" % str(harvest.failures))
		quit(1)
		return
	harvest._stop_stick()
	if not await capture._walk_to_and_engage_wild(target, 2600):
		print("PROBE RESULT FAIL: engage %s" % str(capture._failures))
		quit(1)
		return
	capture._wild = target
	manager.hit_landed.connect(func(on_enemy: bool, _amount: float) -> void:
		if on_enemy:
			_hits += 1
		else:
			_taken += 1)
	manager.attack_missed.connect(func(by_player: bool) -> void:
		if by_player:
			_misses += 1)
	print("FIGHTER %s quick=%s type=%s" % [manager.active_creature().species_id,
		manager.active_creature().move_quick, manager.active_creature().creature_type])
	manager.hit_effectiveness.connect(func(on_enemy: bool, effectiveness: int) -> void:
		if on_enemy and _hits < 3:
			print("EFFECTIVENESS on_enemy=%s %d" % [on_enemy, effectiveness]))
	_monitor(manager, director, player, target)
	_watch_floor(manager, director, current_scene)
	var started := Time.get_ticks_msec()
	capture.counting_steps = true
	var ok: bool = await capture._fight_until_catchable()
	_monitoring = false
	print("PROBE fight weakened=%s frames=%d steps=%d zero_frame_steps=%d taps=%d charged_taps=%d refused_not_ready=%d exhausted_quick=%d hits=%d misses=%d taken=%d ms=%d failures=%s" % [ok, _frames_fought, capture.steps, capture.zero_frame_steps,
		capture.taps, capture.charged_taps, capture.not_ready, capture.no_wind, _hits, _misses, _taken, Time.get_ticks_msec() - started, str(capture._failures)])
	print("PROBE RESULT %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


## --ground: compare the sampled ground height with the physics floor a ray
## actually hits across the beach under the mosshell ledge (fall site ~563,1309).
func _ground_survey(world: Node3D, player: Node3D) -> void:
	player.global_position = Vector3(572.0, float(world.call("ground_height_at", 572.0, 1315.0)) + 0.3, 1315.0)
	for _frame in 120:
		await physics_frame
	var space := world.get_world_3d().direct_space_state
	for z in range(1304, 1316, 1):
		var row := "Z %d:" % z
		for x in range(558, 570, 1):
			var ground := float(world.call("ground_height_at", float(x), float(z)))
			var ray := PhysicsRayQueryParameters3D.create(Vector3(x, 40, z), Vector3(x, -60, z))
			ray.exclude = [player.get_rid()]
			var hit := space.intersect_ray(ray)
			var hy: float = hit.position.y if not hit.is_empty() else NAN
			var who: String = str(hit.collider.name) if not hit.is_empty() else "-"
			row += " %d:g%.1f/h%.1f(%s)" % [x, ground, hy, who.left(6)]
		print(row)
	quit(0)


## First frame the ally is below its sampled ground: print that frame and the
## one before, with the arena circle, to locate how it left the terrain.
func _watch_floor(manager: Node, director: Node, world: Node) -> void:
	var previous := ""
	while _monitoring:
		await physics_frame
		var ally: Node3D = director.ally_body()
		if ally == null:
			continue
		var at := ally.global_position
		var ground := float(world.call("ground_height_at", at.x, at.z))
		var arena: Node3D = manager.get("_arena")
		var centre: Vector3 = arena.global_position if arena != null else Vector3.INF
		var line := "ally=%s vel=%s ground=%.2f on_floor=%s arena_centre=%s radius=%s from_centre=%.2f" % [at,
			(ally as CharacterBody3D).velocity, ground, (ally as CharacterBody3D).is_on_floor(), centre,
			str(arena.get("radius")) if arena != null else "-",
			Vector2(at.x - centre.x, at.z - centre.z).length()]
		if at.y < ground - 0.75:
			print("FLOOR LOST f=%d before: %s" % [_frames_fought, previous])
			print("FLOOR LOST f=%d now:    %s" % [_frames_fought, line])
			return
		previous = line


func _monitor(manager: Node, director: Node, player: Node3D, target: Node3D) -> void:
	var frame := 0
	while _monitoring:
		await physics_frame
		frame += 1
		_frames_fought = frame
		if frame % 60 != 0 or not is_instance_valid(target):
			continue
		var ally: Node3D = director.ally_body()
		var foe: RefCounted = manager.enemy()
		var own: RefCounted = manager.active_creature()
		if ally == null or foe == null or own == null:
			print("MON f=%d missing ally/foe" % frame)
			continue
		var d := ally.global_position - target.global_position
		print("MON f=%d ally=%s wild=%s d3=%.2f dxz=%.2f dy=%.2f reach=%.2f foe=%.0f/%.0f own=%.0f/%.0f action=%s wind=%.1f/%.1f quick_ready=%s hits=%d misses=%d taken=%d player=%s" % [
			frame, ally.global_position, target.global_position, d.length(),
			Vector2(d.x, d.z).length(), d.y, float(manager.combat_move_reach("quick")),
			foe.hp, foe.max_hp, own.hp, own.max_hp, str(manager.get("_action")),
			float(manager.wind_value()), float(manager.wind_cost("quick")), manager.quick_ready(),
			_hits, _misses, _taken, player.global_position])


## Observation only: counts each quick press and whether production would
## accept it at that instant, then sends the helper's own physical tap.
class CountingSwimmer extends "res://tests/helpers/water_earned_swimmer_segment.gd":
	var taps := 0
	var charged_taps := 0
	var steps := 0
	var zero_frame_steps := 0
	var counting_steps := false

	func _drive_body_toward(body: Node3D, point: Vector3, frames: int) -> void:
		var before := Engine.get_physics_frames()
		await super(body, point, frames)
		if counting_steps and body != _player:
			steps += 1
			if Engine.get_physics_frames() == before:
				zero_frame_steps += 1
	var not_ready := 0
	var no_wind := 0

	func _tap_action(action: StringName) -> void:
		if action == &"combat_charged":
			charged_taps += 1
		if action == &"combat_quick":
			taps += 1
			if not bool(_combat.call("quick_ready")):
				not_ready += 1
			elif float(_combat.call("wind_value")) < float(_combat.call("wind_cost", "quick")):
				no_wind += 1
		await super(action)
