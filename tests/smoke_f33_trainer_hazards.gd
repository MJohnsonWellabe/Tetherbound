extends SceneTree

## F33#3: trainer gear mitigates the trainer's actual hazards, proven on the
## PRODUCTION callers in the real Meadows world (Game, Player, pond Water):
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
	for label: String in ["off", "bare", "dressed"]:
		_set_hazards(label != "off")
		_wear(equipment, "stormglass" if label != "bare" else "")
		vitals.set("active_buffs", [] as Array[Dictionary])
		dynamo.call("_apply_local_hazard", {"static_seconds": 8.0, "damage": 0.0})
		var buffs: Array = vitals.get("active_buffs")
		durations[label] = float(buffs[0].remaining_s) if not buffs.is_empty() else -1.0
	_check(is_equal_approx(float(durations.off), 8.0) and is_equal_approx(float(durations.bare), 8.0), "bare / off: 8 s of Dynamo static")
	_check(float(durations.dressed) > 0.0 and float(durations.dressed) < 8.0,
		"Stormglass shortens Dynamo static (%.2f s)" % durations.dressed)
	dynamo.queue_free()

	print("F33 TRAINER HAZARDS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
