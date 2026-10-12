extends "res://tools/earned_saves/earned_chain_runner.gd"

## RD-12 regression (coordinator 2026-10-12): in SOLO play an ordinary trainer
## duel fills the Tether Command meter and the Ultimate from landed creature
## hits, exactly as a wild fight does. Real world from a disclosed generated
## boundary profile; the production send-out, encounter open and host strike
## paths run unchanged. Disclosed shortcuts: the player is placed beside the
## trainer and the duel starts through director.begin_trainer_battle(), the
## call the trainer's own challenge dialogue makes, instead of walking and
## talking. Combat input is the route pilot's ordinary controller presses.
##
##   godot --headless --path . --script tests/smoke_solo_duel_meter.gd -- --profile=relay [--trainer=<id>]

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const PILOT := preload("res://tests/helpers/water_combat_pilot.gd")
const FIGHT_SIM_S := 40.0
const VICTORY_SIM_S := 900.0

var _trainer_id := ""
var _to_victory := false


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	segment = "relay"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="): segment = arg.trim_prefix("--profile=")
		elif arg.begins_with("--trainer="): _trainer_id = arg.trim_prefix("--trainer=")
		elif arg == "--to-victory": _to_victory = true
	game = root.get_node("Game")
	var scratch := OS.get_user_data_dir().path_join("solo_duel_meter_%d_%d" % [OS.get_process_id(), Time.get_ticks_msec()])
	save_dir = scratch.path_join(segment + "/save")
	receipt_path = scratch.path_join(segment + "/receipt.json")
	generated_fixture = true
	game.set("save_system", SAVE.new(scratch + "_working"))
	if not await _generate_boundary_fixture():
		failures.append("generated boundary profile required: " + segment)
		_finish()
		return
	for frame in 120: await process_frame
	var world := current_scene as Node3D
	var director: Node = world.find_child("EncounterDirector", true, false)
	var player := world.get_node_or_null("Player") as Node3D
	if director == null or player == null:
		failures.append("world has no EncounterDirector or Player")
		_finish()
		return
	# Deploy the lead by its ordinary controller action, as the route helpers do.
	for attempt in 3:
		if director.call("ally_body") != null: break
		Input.action_press(&"creature_recall")
		for frame in 3: await physics_frame
		Input.action_release(&"creature_recall")
		for frame in 120: await physics_frame
	var picked := _pick_trainer(world, director)
	if picked.is_empty():
		failures.append("no challengeable ordinary trainers.json trainer in this world")
		_finish()
		return
	var body: Node3D = picked.body
	disclosures.append("Player placed beside %s; duel started via begin_trainer_battle (the dialogue's own call)." % picked.id)
	player.global_position = body.global_position + (player.global_position - body.global_position).normalized() * 3.0
	for frame in 10: await physics_frame
	var session: Node = game.get("session")
	# Solo is a one-peer hosted session: the title screen hosts on Start/Load
	# (title_screen.gd); the generated-fixture loader does not, so host here.
	if session != null and session.call("is_active") != true:
		session.call("host", 27015)
		disclosures.append("Hosted the one-peer solo session as the title screen does on Load.")
	var solo: bool = session == null or session.call("is_multi_peer") != true
	print("SOLO_DUEL trainer=%s solo=%s session_host=%s" % [picked.id, solo,
		session != null and session.call("is_host") == true])
	if not bool(director.call("begin_trainer_battle", picked.spec, body)):
		failures.append("begin_trainer_battle refused " + str(picked.id))
		_finish()
		return
	var manager: Node = director.get("_manager")
	print("SOLO_DUEL diag solo_record=%s is_host=%s multi=%s commands=%s vitals=%s" % [director.get("_solo_duel_record"),
		director.call("_is_host"), director.call("_is_multi_peer"),
		preload("res://scripts/combat/tether_commands.gd").enabled(),
		preload("res://scripts/combat/combat_math.gd").config().get("actor_vitals", {}).get("runtime_enabled")])
	var deadline := Time.get_ticks_msec() + 20000
	while not bool(manager.call("is_fighting")) and Time.get_ticks_msec() < deadline:
		await physics_frame
	if not bool(manager.call("is_fighting")):
		failures.append("the duel never reached a live fight")
		_finish()
		return
	var encounter := str(manager.call("encounter_id"))
	print("SOLO_DUEL diag after_open solo_record=%s" % director.get("_solo_duel_record"))
	print("SOLO_DUEL bound_encounter=%s" % encounter)
	var pilot: RefCounted = PILOT.new()
	var hit_count: Array[int] = [0] # lambdas capture locals by value
	manager.hit_landed.connect(func(on_enemy: bool, _amount: float) -> void: if on_enemy: hit_count[0] += 1)
	var xp_before := _party_xp()
	var coins_before := int(game.local.inventory.count("coin"))
	var command_input: Node = null
	for child: Node in manager.get_children():
		if child.has_method("request") and str(child.get_script().resource_path).ends_with("tether_command_input.gd"): command_input = child
	var spent := {"tried": false, "before": 0.0, "after": -1.0}
	var sim := 0.0
	var meter := 0.0
	var ultimate := 0.0
	var limit := VICTORY_SIM_S if _to_victory else FIGHT_SIM_S
	while sim < limit and bool(director.call("trainer_battle_active")):
		var enemy: Node3D = manager.call("enemy_body")
		var ally: Node3D = director.call("ally_body")
		if is_instance_valid(enemy) and is_instance_valid(ally):
			pilot.call("drive", manager, ally, enemy)
		await physics_frame
		sim += 1.0 / float(Engine.physics_ticks_per_second)
		var snapshot: Dictionary = manager.call("tether_command_snapshot")
		meter = maxf(meter, float(snapshot.get("meter", 0.0)))
		ultimate = maxf(ultimate, float(manager.call("ultimate_fraction")))
		# A command is spendable: Rally through the same request path the
		# controller binding uses, once the meter holds a full tier.
		if not spent.tried and command_input != null and float(snapshot.get("meter", 0.0)) >= 50.0 \
				and snapshot.get("active") == true:
			spent.tried = true
			spent.before = float(snapshot.get("meter", 0.0))
			spent["requested"] = bool(command_input.call("request", "rally"))
			for frame in 30: await physics_frame
			sim += 30.0 / float(Engine.physics_ticks_per_second)
			spent.after = float((manager.call("tether_command_snapshot") as Dictionary).get("meter", 0.0))
	pilot.call("release")
	var hits := hit_count[0]
	for frame in 240: await physics_frame
	print("SOLO_DUEL_METER " + JSON.stringify({"trainer": picked.id, "encounter": encounter, "hits": hits,
		"command_meter_max": meter, "ultimate_fraction_max": ultimate, "sim_s": snappedf(sim, 0.1),
		"command_spend": spent, "battle_active": bool(director.call("trainer_battle_active")),
		"xp_gained": _party_xp() - xp_before, "coins_gained": int(game.local.inventory.count("coin")) - coins_before,
		"defeated_flag": game.world.flags.has("defeated_" + str(picked.id)) or game.local.flags.has("defeated_" + str(picked.id))}))
	if spent.tried and float(spent.after) >= float(spent.before): failures.append("Rally did not spend the command meter")
	if not spent.tried: failures.append("the meter never offered a spendable command")
	if encounter.is_empty(): failures.append("solo ordinary duel bound no host encounter record")
	if hits < 3: failures.append("fewer than 3 landed creature hits (%d)" % hits)
	if meter <= 0.0: failures.append("landed hits did not fill the Tether Command meter")
	if ultimate <= 0.0: failures.append("landed hits did not fill the Ultimate meter")
	_finish()


func _pick_trainer(world: Node, director: Node) -> Dictionary:
	var found: Dictionary = {}
	var seen: Array[String] = []
	for node: Node in world.get_tree().get_nodes_in_group(&"foundation_trainer_specs"):
		var id := str(node.get_meta("trainer_id", ""))
		var spec: Dictionary = TRAINERS.trainer(id)
		var ok := not spec.is_empty() and not spec.has("master") and not spec.has("rematch") \
			and bool(director.call("can_challenge", spec))
		seen.append("%s:%s" % [id, ok])
		if not _trainer_id.is_empty() and id != _trainer_id: continue
		if ok and found.is_empty(): found = {"id": id, "spec": spec, "body": node}
	print("SOLO_DUEL candidates " + ", ".join(seen))
	return found


func _party_xp() -> int:
	var total := 0
	for creature: RefCounted in game.local.party.members():
		total += int(creature.level) * 1000000 + int(creature.xp)
	return total

