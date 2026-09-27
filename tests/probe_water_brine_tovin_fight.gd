extends SceneTree

## DRY RUN probe (does not count): repeats the Brine Steps Tovin trainer
## battle without replaying the campaign. Declared fixtures: the paid
## Reedhaven repair flag, the tidewake_b_water_arrival_dry_fixture belt
## (terrapup/bramblebun/mudsnout/sparkit/sparkit L55, terrapup active), a
## declared world_seed and a POSED player start on the Brine Steps spine.
## From there the production segment path is unchanged: spine walk to p5,
## controller recall, the Tovin prompt and the segment's own _fight_tovin
## (water_combat_pilot drive per physics frame). A monitor logs every 60
## frames: ally/enemy pos, dxz, dy, hp, manager action, enemy intent, arena,
## plus per-frame buckets of what the fight waited on and every hit amount.
## Finding: no deadlock. The terrapup lead's ground moves land 0.8x on
## Tovin's two water creatures (~6/quick, ~28/charged vs 955 HP), so paid
## play needs ~160-183 s; the segment's sparkit matchup lead needs ~80 s.
## --no-lead skips the segment's matchup-lead selection (the old path).
##   godot --headless --path . --script tests/probe_water_brine_tovin_fight.gd -- --seed=N [--start=K] [--no-lead]
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SEGMENT := preload("res://tests/helpers/water_brine_segment.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const BELT: Array[String] = ["terrapup", "bramblebun", "mudsnout", "sparkit", "sparkit"]
var _monitoring := true
var _hits := 0
var _misses := 0
var _taken := 0
var _amounts: Array = []
var _buckets := {}
var _profiles := {}


func _init() -> void:
	_run.call_deferred()


func _arg(name: String, fallback: int) -> int:
	for raw: String in OS.get_cmdline_user_args():
		if raw.begins_with("--%s=" % name):
			return int(raw.split("=")[1])
	return fallback


func _run() -> void:
	var seed_value := _arg("seed", 1)
	var start_index := _arg("start", 4)
	print("DRY RUN probe - does not count: declared repair flag, fixture belt, seed=%d, posed start spine[%d]" % [
		seed_value, start_index])
	seed(seed_value)
	var game: Node = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.world_seed = seed_value
	game.world.flags.set_flag("water_dock_reedhaven_repaired")
	for species_id: String in BELT:
		var creature: RefCounted = SPECIES.spawn(species_id)
		creature.set_level(55, PROGRESSION.config())
		creature.hp = creature.max_hp
		game.party.add(creature)
	var world: Node3D = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 2400:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	var player: CharacterBody3D = world.get_node("Player")
	var camera: Node3D = world.get_node("CameraRig")
	var segment: RefCounted = SEGMENT.new()
	segment.setup(self, world, player, camera)
	var spine: Array[Vector3] = segment._land_route(SEGMENT.SPINE_ID)
	var start := spine[start_index]
	start.y = float(world.call("ground_height_at", start.x, start.z)) + 0.3
	player.global_position = start
	player.velocity = Vector3.ZERO
	for _frame in 120:
		await physics_frame
	for index in range(start_index + 1, 6):
		if not await segment._walk_to(spine[index], "spine %d" % index):
			print("PROBE RESULT FAIL: %s" % str(segment.failures))
			quit(1)
			return
	if not await segment._ensure_ally_deployed():
		print("PROBE RESULT FAIL: %s" % str(segment.failures))
		quit(1)
		return
	var mgr: Node = world.get_node("CombatManager")
	mgr.hit_landed.connect(func(on_enemy: bool, _amount: float) -> void:
		if on_enemy:
			_hits += 1
			_amounts.append(snappedf(_amount, 0.1))
		else:
			_taken += 1)
	mgr.attack_missed.connect(func(by_player: bool) -> void:
		if by_player:
			_misses += 1)
	if not OS.get_cmdline_user_args().has("--no-lead") \
			and not await segment._select_matchup_lead("water", "before Tovin"):
		print("PROBE RESULT FAIL: %s" % str(segment.failures))
		quit(1)
		return
	print("PROBE fighter=%s" % str(game.party.active().species_id))
	_monitor(world)
	var started := Time.get_ticks_msec()
	var frames_before := Engine.get_physics_frames()
	var ok: bool = await segment._fight_tovin()
	_monitoring = false
	var ally: RefCounted = world.get_node("EncounterDirector").ally_instance()
	print("PROBE buckets(frames) %s" % str(_buckets))
	print("PROBE fight hits=%d misses=%d taken=%d amounts=%s" % [_hits, _misses, _taken, str(_amounts)])
	print("PROBE fight ok=%s ms=%d frames=%d ally_hp=%s failures=%s" % [ok, Time.get_ticks_msec() - started,
		Engine.get_physics_frames() - frames_before, str(ally.hp) if ally != null else "?", str(segment.failures)])
	print("PROBE RESULT %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _monitor(world: Node) -> void:
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	var frame := 0
	while _monitoring:
		await physics_frame
		frame += 1
		var ally: Node3D = director.ally_body()
		var enemy: Node3D = manager.enemy_body()
		if not is_instance_valid(ally) or not is_instance_valid(enemy) or not manager.is_fighting():
			continue
		_bucket(manager, ally, enemy)
		if frame % 60 != 0:
			continue
		var d := enemy.global_position - ally.global_position
		var arena: Node3D = manager.arena()
		var centre: Vector3 = arena.global_position if arena != null else Vector3.INF
		var own: RefCounted = manager.active_creature()
		print("MON f=%d %s ally=%s enemy=%s dxz=%.2f dy=%.2f reach=%.2f/%.2f own=%.0f/%.0f foe=%.0f/%.0f action=%s intent=%s wind=%.0f arena=%s r=%s ally_from_c=%.2f enemy_from_c=%.2f ally_floor=%s vel=%s hits=%d misses=%d taken=%d" % [
			frame, enemy.instance.species_id, ally.global_position, enemy.global_position,
			Vector2(d.x, d.z).length(), d.y, float(manager.combat_move_reach("quick")),
			float(manager.combat_move_reach("charged")), own.hp, own.max_hp,
			enemy.instance.hp, enemy.instance.max_hp, str(manager.get("_action")),
			str(enemy.call("intent")) if enemy.has_method("intent") else "-",
			float(manager.wind_value()), centre, str(arena.get("radius")) if arena != null else "-",
			Vector2(ally.global_position.x - centre.x, ally.global_position.z - centre.z).length(),
			Vector2(enemy.global_position.x - centre.x, enemy.global_position.z - centre.z).length(),
			(ally as CharacterBody3D).is_on_floor(), (ally as CharacterBody3D).velocity, _hits, _misses, _taken])


## Per-frame classification of what the fight is waiting on (observation only).
func _bucket(manager: Node, ally: Node3D, enemy: Node3D) -> void:
	var d := enemy.global_position - ally.global_position
	d.y = 0.0
	var key := "other"
	if manager.player_is_committed():
		key = "committed_" + str(manager.get("_action"))
	elif manager.enemy_is_winding_up():
		var cfg: Dictionary = enemy.combat_config()
		key = "enemy_tell_%s" % ("inside" if d.length() < float(cfg.get("range", 2.6)) + 0.35 else "outside")
		if not _profiles.has(str(enemy.instance.species_id)):
			_profiles[str(enemy.instance.species_id)] = true
			print("PROFILE %s range=%s cone=%s lunge=%s windup=%s power=%s" % [enemy.instance.species_id,
				cfg.get("range"), cfg.get("cone_degrees"), cfg.get("lunge"), cfg.get("windup"), cfg.get("power")])
	elif d.length() > float(manager.combat_move_reach("quick")) - 0.25:
		key = "out_of_reach"
	elif not manager.quick_ready():
		key = "quick_cooldown"
	elif float(manager.wind_value()) < float(manager.wind_cost("quick")):
		key = "wind_starved"
	else:
		key = "in_reach_ready_w%d" % (int(manager.wind_value()) / 20 * 20)
	_buckets[key] = int(_buckets.get(key, 0)) + 1
