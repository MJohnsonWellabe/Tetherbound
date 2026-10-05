extends SceneTree

## F33#3: trainer gear eases swim drowning and the water current, proven on
## the PRODUCTION caller (swim_controller.physics_step, driven by the real
## Player in the real Water world): the trainer floats in the First Shore ->
## Reedhaven direct current with no input, bare and then wearing the full
## Tidesteel travel set, and with hazard mitigation OFF (no change). The push
## is read from the Player's own velocity; drowning from real vitals health
## over the same frames at zero stamina.
## Disclosed fixtures: the swimmer is placed at the current's centreline; zero
## stamina is the exhaustion fixture; gear is equipped straight onto the
## trainer; the hazard flag is switched by the equipment's own config cache.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const EQUIP := preload("res://scripts/player/player_equipment.gd")
const PIECES := {"helmet": "travel_hood", "upper_body": "travel_coat", "lower_body": "travel_trousers", "boots": "travel_boots"}
const IN_CURRENT := Vector3(0.0, 0.0, 220.0)

var failures := 0
var checks := 0
var world: Node3D
var player: CharacterBody3D


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
			equipment.call("equip", "%s_%s" % [tier, PIECES[slot]])


## Float at the current with no input; returns [mean push along the flow, health lost].
func _float(swimming: Node, frames: int) -> Array:
	var sea: float = world.field.water_level()
	player.global_position = Vector3(IN_CURRENT.x, sea, IN_CURRENT.z)
	player.velocity = Vector3.ZERO
	for _frame in 20:
		await physics_frame
	var vitals: RefCounted = player.get("vitals")
	vitals.set("stamina", 0.0)
	var health_before := float(vitals.get("health"))
	var push := 0.0
	for _frame in frames:
		player.global_position = Vector3(IN_CURRENT.x, player.global_position.y, IN_CURRENT.z)
		await physics_frame
		push += -player.velocity.z
	return [push / float(frames), health_before - float(vitals.get("health")), swimming.is_swimming()]


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://smoke_f33_swim_hazards_fixture")
	game.current_realm = "water"
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 600:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	_check(bool(world.call("shell_build_complete")), "real Water world built")
	player = world.get_node("Player")
	var swimming: Node = player.get("swim_controller")
	var equipment: RefCounted = game.get("player_equipment")
	var flow: Vector3 = world.call("current_at", Vector3(IN_CURRENT.x, world.field.water_level(), IN_CURRENT.z))
	_check(flow.length() > 0.1, "the First Shore direct current pushes here (%.3f m/s)" % flow.length())
	var runs := {}
	for label: String in ["off", "bare", "dressed"]:
		_set_hazards(label != "off")
		_wear(equipment, "tidesteel" if label != "bare" else "")
		var vitals: RefCounted = player.get("vitals")
		vitals.set("health", float(vitals.get("max_health")))
		runs[label] = await _float(swimming, 60)
		print("%s: push %.4f m/s, drowning %.3f hp, swimming=%s" % [label, runs[label][0], runs[label][1], str(runs[label][2])])
	_check(bool(runs.bare[2]) and bool(runs.dressed[2]), "the trainer is swimming through the production physics_step")
	var reduction_current := float(equipment.call("hazard_reduction", "currents"))
	var reduction_drowning := float(equipment.call("hazard_reduction", "drowning"))
	_check(absf(float(runs.off[0]) - float(runs.bare[0])) < 0.02 and absf(float(runs.off[1]) - float(runs.bare[1])) < 0.05,
		"hazards off: worn gear changes neither push nor drowning")
	_check(float(runs.bare[0]) > 0.1 and float(runs.dressed[0]) < float(runs.bare[0]),
		"Tidesteel eases the current push (%.3f < %.3f m/s)" % [runs.dressed[0], runs.bare[0]])
	_check(absf(float(runs.dressed[0]) - float(runs.bare[0]) * (1.0 - reduction_current)) < 0.03,
		"by its authored current reduction (%.0f%%)" % (reduction_current * 100.0))
	_check(float(runs.bare[1]) > 0.0 and float(runs.dressed[1]) < float(runs.bare[1]),
		"Tidesteel eases swim drowning (%.2f < %.2f hp)" % [runs.dressed[1], runs.bare[1]])
	_check(absf(float(runs.dressed[1]) - float(runs.bare[1]) * (1.0 - reduction_drowning)) < 0.1,
		"by its authored drowning reduction (%.0f%%)" % (reduction_drowning * 100.0))
	print("F33 SWIM HAZARDS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
