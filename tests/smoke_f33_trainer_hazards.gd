extends SceneTree

## F33#3: trainer gear mitigates the trainer's actual hazards, proven on the
## PRODUCTION callers in the real Meadows world (Game, Player, pond Water):
## - falls: the real Player falls 8 m onto existing world collision; its public
##   landed signal and actual health loss compare bare and full Skyglass gear;
## - cold heights: player_controller._cold_regen_scale (the scale it passes to
##   vitals.tick) inside gear.json's authored Cloudreach cold zone, then the
##   real vitals.tick regen with it;
## - drowning: the pond's water.gd _apply_hazard_damage;
## - storm static: stormwood_dynamo._apply_local_hazard (outside a fight, so
##   only the trainer's static applies).
## Each is measured bare, then wearing the matching full travel set, and with
## hazard mitigation OFF (gear must change nothing then). Swim drowning and the
## water current run in smoke_f33_swim_hazards.gd (the Water world).
## Disclosed fixtures: realm/position set on the player for the cold zone;
## gear equipped straight onto the trainer; the hazard flag is switched by the
## equipment's own config cache, as gear.json would switch it.
## The fall setup raises the grounded body once with zero velocity; gravity,
## collision and landing damage then run normally, within 120 physics frames.
## Fall's OFF control uses runtime_enabled, retaining legacy item defense;
## hazards_enabled gates the later cold/pond/static consumers, not legacy falls.
const SCENE := "res://scenes/world/meadows_playground.tscn"
const EQUIP := preload("res://scripts/player/player_equipment.gd")
const DYNAMO := preload("res://scripts/world/stormwood_dynamo.gd")
const PIECES := {"helmet": "travel_hood", "upper_body": "travel_coat", "lower_body": "travel_trousers", "boots": "travel_boots"}

var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS: " if ok else "FAIL: ") + what)


func _set_hazards(live: bool) -> void:
	var cfg: Dictionary = EQUIP._gear_config().duplicate(true)
	cfg.feature_flags.hazards_enabled = live
	EQUIP._gear_rules = cfg


func _wear(equipment: RefCounted, tier: String) -> void:
	for slot: String in PIECES:
		equipment.call("unequip", slot)
		if not tier.is_empty():
			var result: Dictionary = equipment.call("equip", "%s_%s" % [tier, PIECES[slot]])
			if result.get("ok") == false: print("equip refused: %s" % str(result))


func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 120:
		await physics_frame
	var player := world.get_node("Player") as CharacterBody3D
	var equipment: RefCounted = game.get("player_equipment")
	var local: RefCounted = game.get("local")
	var vitals: RefCounted = player.get("vitals")
	_check(equipment != null and vitals != null, "real Game equipment and Player vitals")

	# --- Physical fall ------------------------------------------------------
	var gear_cache_before := EQUIP._gear_rules.duplicate(true)
	var fall_gear_config := EQUIP._gear_config().duplicate(true)
	var worn_before: Dictionary = equipment.call("save_data")
	var health_before_falls := float(vitals.get("health"))
	# The arrival stand can be underneath a roof. Select existing open terrain
	# by actual collision rays across the capsule footprint, never by adding a
	# test floor or accepting a shortened impact on a nearby building.
	var arrival_position := player.global_position
	var open_ground := Vector3(INF, INF, INF)
	for offset: Vector3 in [Vector3(16, 0, 0), Vector3(-16, 0, 0), Vector3(0, 0, 16), Vector3(0, 0, -16),
			Vector3(32, 0, 0), Vector3(-32, 0, 0), Vector3(0, 0, 32), Vector3(0, 0, -32)]:
		var candidate := arrival_position + offset
		candidate.y = float(world.call("ground_height_at", candidate.x, candidate.z))
		if not is_finite(candidate.y): continue
		var clear := true
		for footprint: Vector3 in [Vector3.ZERO, Vector3(0.5, 0, 0), Vector3(-0.5, 0, 0), Vector3(0, 0, 0.5), Vector3(0, 0, -0.5)]:
			var ray := PhysicsRayQueryParameters3D.create(candidate + footprint + Vector3.UP * 10.0,
				candidate + footprint - Vector3.UP * 0.5, player.collision_mask, [player.get_rid()])
			var hit := player.get_world_3d().direct_space_state.intersect_ray(ray)
			if hit.is_empty() or absf((hit.position as Vector3).y - candidate.y) > 0.15 \
				or (hit.normal as Vector3).y < 0.98:
				clear = false
				break
		if clear:
			open_ground = candidate
			break
	_check(is_finite(open_ground.y), "existing terrain has a clear 8 m drop across the capsule footprint")
	if not is_finite(open_ground.y):
		quit(1)
		return
	player.global_position = open_ground + Vector3.UP * 0.15
	player.velocity = Vector3.ZERO
	for _frame in 120: await physics_frame
	var landing_origin := player.global_position
	print("F33 fall surface: arrival=%s terrain=%s grounded=%s" % [arrival_position, open_ground, landing_origin])
	_check(player.is_on_floor(), "fall starts from the actual grounded Player")
	var movement: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/movement.json"))
	# Same height and zero initial velocity: contact quantization may differ
	# by one fixed gravity step, so compare within that step plus 0.05 m/s.
	var impact_tolerance := float(movement.jump.gravity) * float(movement.jump.fall_gravity_multiplier) \
		/ float(Engine.physics_ticks_per_second) + 0.05
	var landed_samples: Array[Dictionary] = []
	var observe_landing := func(speed: float, damage: float) -> void:
		landed_samples.append({"speed": speed, "damage": damage, "position": player.global_position})
	player.connect("landed", observe_landing)
	var falls := {}
	for label: String in ["bare", "dressed", "off"]:
		var fall_config := fall_gear_config.duplicate(true)
		fall_config.feature_flags.runtime_enabled = label != "off"
		EQUIP._gear_rules = fall_config
		_wear(equipment, "" if label == "bare" else "skyglass")
		equipment.call("unequip", "backpack")
		var authored_defense := 0.0
		for slot: String in EQUIP.SLOTS:
			var item: Dictionary = game.get("items").call("definition", equipment.call("equipped_in", slot))
			authored_defense += float(item.get("defense", 0.0) if label == "off" \
				else item.get("fall_damage_reduction", item.get("defense", 0.0)))
		var defense_cap: float = EQUIP.MAX_TOTAL_DEFENSE if label == "off" \
			else minf(EQUIP.MAX_TOTAL_DEFENSE, float(fall_config.mitigation_cap))
		authored_defense = clampf(authored_defense, 0.0, defense_cap)
		_check(is_equal_approx(float(equipment.call("total_defense")), authored_defense),
			"%s: real worn fall defense matches authored fields (%.3f)" % [label, authored_defense])
		landed_samples.clear()
		vitals.set("health", float(vitals.get("max_health")))
		player.global_position = landing_origin + Vector3.UP * 8.0
		player.velocity = Vector3.ZERO
		var saw_airborne := false
		for _frame in 120:
			await physics_frame
			if not player.is_on_floor(): saw_airborne = true
			if not landed_samples.is_empty(): break
		_check(saw_airborne and player.is_on_floor() and landed_samples.size() == 1,
			"%s: ordinary gravity and collision produced one landing within 120 frames" % label)
		if landed_samples.size() != 1: continue
		var landed: Dictionary = landed_samples[0]
		var loss := float(vitals.get("max_health")) - float(vitals.get("health"))
		var unprotected := float(vitals.call("fall_damage_for", float(landed.speed)))
		falls[label] = {"speed": landed.speed, "loss": loss, "base": unprotected, "defense": authored_defense}
		_check((landed.position as Vector3).distance_to(landing_origin) < 0.1,
			"%s: the body landed back on the same real world surface (%s -> %s)" % [label, landing_origin, landed.position])
		_check(unprotected > 0.0 and loss > 0.0 and float(vitals.get("health")) > 0.0,
			"%s: a damaging nonlethal physical fall (%.3f m/s, %.3f HP)" % [label, landed.speed, loss])
		_check(absf(loss - float(landed.damage)) < 0.01 \
			and absf(loss - unprotected * (1.0 - authored_defense)) < 0.01,
			"%s: actual HP loss and landed damage apply the authored fall reduction" % label)
	player.disconnect("landed", observe_landing)
	if falls.size() == 3:
		_check(absf(float(falls.dressed.speed) - float(falls.bare.speed)) <= impact_tolerance \
			and absf(float(falls.off.speed) - float(falls.bare.speed)) <= impact_tolerance,
			"same 8 m fall impacts agree within one gravity step (%.3f m/s)" % impact_tolerance)
		_check(float(falls.dressed.defense) > float(falls.bare.defense) \
			and float(falls.dressed.loss) < float(falls.bare.loss), "Skyglass reduces the actual landing's health loss")
		_check(float(falls.off.defense) < float(falls.dressed.defense) \
			and float(falls.off.loss) > float(falls.dressed.loss), "runtime OFF retains only authored legacy defense")
	EQUIP._gear_rules = gear_cache_before
	equipment.call("load_data", worn_before)
	vitals.set("health", health_before_falls)

	# --- Cold heights -------------------------------------------------------
	var zone: Dictionary = (EQUIP._gear_config().get("cold_zones", []) as Array)[0]
	var inside := Vector3((float(zone.min[0]) + float(zone.max[0])) * 0.5, (float(zone.min[1]) + float(zone.max[1])) * 0.5,
		(float(zone.min[2]) + float(zone.max[2])) * 0.5)
	var realm_before: String = str(local.get("realm"))
	local.set("realm", str(zone.realm_id))
	player.set_physics_process(false)
	player.global_position = inside
	_set_hazards(false)
	_wear(equipment, "skyglass")
	_check(is_equal_approx(float(player.call("_cold_regen_scale")), 1.0), "hazards off: no cold penalty at all")
	_set_hazards(true)
	_wear(equipment, "")
	var bare := float(player.call("_cold_regen_scale"))
	_wear(equipment, "skyglass")
	var dressed := float(player.call("_cold_regen_scale"))
	_check(is_equal_approx(bare, 1.0 - float(zone.stamina_regen_penalty)), "in the cold zone bare regen is slowed (%.3f)" % bare)
	_check(dressed > bare and dressed < 1.0, "Skyglass cold gear eases it (%.3f > %.3f)" % [dressed, bare])
	var regen := {}
	for label: String in ["bare", "dressed"]:
		_wear(equipment, "" if label == "bare" else "skyglass")
		vitals.set("stamina", 0.0)
		vitals.set("_regen_cooldown", 0.0)
		vitals.call("tick", 1.0, false, 1.0, float(player.call("_cold_regen_scale")))
		regen[label] = float(vitals.get("stamina"))
	_check(float(regen.dressed) > float(regen.bare) and float(regen.bare) > 0.0,
		"the real vitals.tick regenerates more with cold gear (%.2f vs %.2f), never drains" % [regen.dressed, regen.bare])
	# Review finding 3: the same comparison through the player's own physics
	# frames, so the controller's call into vitals.tick is what is measured.
	var physics_regen := {}
	player.set_physics_process(true)
	for label: String in ["bare", "dressed"]:
		_wear(equipment, "" if label == "bare" else "skyglass")
		vitals.set("stamina", 0.0)
		vitals.set("_regen_cooldown", 0.0)
		for _frame in 30:
			player.global_position = inside
			player.velocity = Vector3.ZERO
			await physics_frame
		physics_regen[label] = float(vitals.get("stamina"))
	player.set_physics_process(false)
	_check(float(physics_regen.dressed) > float(physics_regen.bare) * 1.15 and float(physics_regen.bare) > 0.0,
		"the controller's own frames regenerate more with cold gear (%.2f vs %.2f)" % [physics_regen.dressed, physics_regen.bare])
	player.global_position = inside + Vector3(5000, 0, 0)
	_check(is_equal_approx(float(player.call("_cold_regen_scale")), 1.0), "outside the zone there is no penalty")
	local.set("realm", realm_before)

	# --- Pond drowning ------------------------------------------------------
	var water := world.get_node_or_null("Water")
	_check(water != null, "the real pond Water node")
	if water != null:
		var losses := {}
		for label: String in ["off", "bare", "dressed"]:
			_set_hazards(label != "off")
			_wear(equipment, "tidesteel" if label != "bare" else "")
			vitals.set("health", float(vitals.get("max_health")))
			water.call("_apply_hazard_damage", player, 10.0)
			losses[label] = float(vitals.get("max_health")) - float(vitals.get("health"))
		_check(is_equal_approx(float(losses.off), 10.0), "hazards off: gear changes no drowning damage")
		_check(is_equal_approx(float(losses.bare), 10.0), "bare: full pond drowning damage")
		var expected := 10.0 * (1.0 - float(equipment.call("hazard_reduction", "drowning")))
		_check(float(losses.dressed) < 10.0 and is_equal_approx(float(losses.dressed), expected),
			"Tidesteel eases pond drowning (%.2f)" % losses.dressed)

	# --- Stormwood Dynamo static -------------------------------------------
	var dynamo: Node3D = DYNAMO.new()
	dynamo.set("world", world)
	world.add_child(dynamo)
	var durations := {}
	for label: String in ["off", "bare", "partial", "dressed"]:
		_set_hazards(label != "off")
		_wear(equipment, "stormglass" if label != "bare" else "")
		if label == "partial":
			equipment.call("unequip", "helmet")
			equipment.call("unequip", "boots")
		vitals.set("active_buffs", [] as Array[Dictionary])
		dynamo.call("_apply_local_hazard", {"static_seconds": 8.0, "damage": 0.0})
		var buffs: Array = vitals.get("active_buffs")
		durations[label] = float(buffs[0].remaining_s) if not buffs.is_empty() else -1.0
	_check(is_equal_approx(float(durations.off), 8.0) and is_equal_approx(float(durations.bare), 8.0), "bare / off: 8 s of Dynamo static")
	_check(float(durations.partial) > 0.0 and float(durations.partial) < 8.0,
		"two Stormglass pieces shorten Dynamo static (%.2f s)" % durations.partial)
	_check(float(durations.dressed) < 0.0, "a full insulated set is immune, as to ordinary lightning")
	dynamo.queue_free()

	print("F33 TRAINER HAZARDS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
