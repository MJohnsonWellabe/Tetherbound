extends SceneTree

## Does a real `Game.load_game()` end a live Veyra battle? The finale keeps its
## encounter across a load only while the director still runs the battle
## (`cloudreach_finale_controller.gd::_encounter_survives`); this asks the real
## production scene -- the real CloudreachRuntime, EncounterDirector,
## CombatManager and finale -- rather than a stub.
##
## Isolated save directory; the saved-state preconditions are set directly and
## only battle damage/resolution is accelerated, as
## `smoke_cloudreach_production_integration.gd` does. Two windows: a load in the
## beat between Veyra's creatures (the game menu can open there) and a load
## during a live round (the menu refuses `is_fighting()`; asked anyway).
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const VEYRA := "captain_veyra_storm_anchor"

var failures: Array[String] = []
var game: Node
var save_dir := ""


func _init() -> void:
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	print("MIDBATTLE LOAD %s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures.append(label)


func frames(count: int) -> void:
	for i in count:
		await physics_frame


## Resolve the live round as a win, as the production integration smoke does.
func _win_round(manager: Node) -> void:
	var enemy: RefCounted = manager.get("_enemy")
	enemy.call("take_damage", float(enemy.get("hp")) + 1.0)
	manager.call("_award_victory")
	manager.call("_begin_resolve", "won")


func _state(director: Node, manager: Node, finale: Node) -> String:
	return "battle=%s fighting=%s phase=%s in_encounter=%s" % [
		director.call("trainer_battle_active"), manager.call("is_fighting"),
		finale.get("phase"), finale.get("_in_encounter")]


func _run() -> void:
	game = root.get_node("Game")
	game.call("reset_for_new_game")
	save_dir = "user://test_cloudreach_midbattle_load_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	var original_saver: RefCounted = game.get("save_system")
	game.set("save_system", SAVE.new(save_dir))
	game.set("current_realm", "cloudreach")
	var member: RefCounted = SPECIES.spawn("galecrest")
	member.call("set_level", 40, preload("res://scripts/creatures/progression.gd").config())
	game.get("party").call("add", member)
	var world: Node3D = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	await frames(12)
	var runtime: Node = world.get_node("CloudreachRuntime")
	var player: CharacterBody3D = world.get_node("Player")
	var director: Node = runtime.get("director")
	var manager: Node = runtime.get("manager")
	var finale: Node3D = runtime.get("finale")
	check(finale.get("fight_director") == director, "the runtime hands the finale its director")
	var flags: RefCounted = game.get("progression")
	for flag in ["realm_key_cloudreach", "cloudreach_chapter_started", "cloudreach_crisis_learned",
			"cloudreach_lower_anchors_investigated", "causeway_survivors_reconnected",
			"windscar_aerie_prepared", "cloudreach_act_i_complete", "fly_traversal_unlocked",
			"sky_shrine_reached", "storm_anchor_engine_truth_learned", "cloudreach_upper_route_unlocked",
			"cloudreach_act_ii_complete", "cloudreach_upper_anchors_disabled",
			"summit_extraction_engine_reached"]:
		flags.call("set_flag", flag)
	await frames(8)
	var origin: Vector3 = finale.global_position
	player.global_position = origin + Vector3(0, 0.2, -10)
	player.velocity = Vector3.ZERO
	world.get_node("CameraRig").global_position = player.global_position + Vector3.UP * 1.75
	await frames(6)
	check(await director.call("summon_active_creature"), "real party deployment at summit")
	await frames(5)
	check(game.call("save_game", 0), "pre-battle checkpoint saved")
	var captain: Node3D = director.get("trainer_nodes").get(VEYRA)
	check(director.call("begin_trainer_battle", director.get("trainer_specs")[VEYRA], captain),
		"real captain challenge starts")
	await frames(5)
	check(finale.get("phase") == "crosswind_command", "trainer start reaches the finale")

	# Window 1: the beat between Veyra's first and second creature.
	var resolved := false
	for frame in 900:
		if int(manager.get("state")) == 1 and not resolved:
			_win_round(manager)
			resolved = true
		if resolved and not bool(manager.call("is_fighting")) and bool(director.call("trainer_battle_active")):
			break
		await physics_frame
	var beat := resolved and not bool(manager.call("is_fighting")) and bool(director.call("trainer_battle_active"))
	check(beat, "reached the beat between creatures (%s)" % _state(director, manager, finale))
	var before := _state(director, manager, finale)
	check(game.call("load_game", 0), "real load in the beat")
	var right_after := _state(director, manager, finale)
	await frames(8)
	var settled := _state(director, manager, finale)
	print("MIDBATTLE LOAD OBSERVED beat: before [%s] right-after [%s] +8 frames [%s]" % [before, right_after, settled])
	check(bool(director.call("trainer_battle_active")) == bool(finale.get("_in_encounter")),
		"after a beat load the finale mirrors the director (%s)" % settled)
	# Does the battle carry on? Let the director send the next creature.
	var next_round := false
	for frame in 600:
		if int(manager.get("state")) == 1:
			next_round = true
			break
		if not bool(director.call("trainer_battle_active")):
			break
		await physics_frame
	print("MIDBATTLE LOAD OBSERVED beat: next creature sent after the load = %s [%s]" % [
		next_round, _state(director, manager, finale)])
	check(bool(director.call("trainer_battle_active")) == bool(finale.get("_in_encounter")),
		"while the battle goes on the finale still mirrors it (%s)" % _state(director, manager, finale))

	# Window 2: a load during a live round.
	if next_round:
		before = _state(director, manager, finale)
		check(game.call("load_game", 0), "real load during a live round")
		right_after = _state(director, manager, finale)
		await frames(8)
		settled = _state(director, manager, finale)
		print("MIDBATTLE LOAD OBSERVED round: before [%s] right-after [%s] +8 frames [%s]" % [before, right_after, settled])
		check(bool(director.call("trainer_battle_active")) == bool(finale.get("_in_encounter")),
			"after a mid-round load the finale mirrors the director (%s)" % settled)

	game.set("save_system", original_saver)
	world.queue_free()
	await process_frame
	await process_frame
	_remove_tree(ProjectSettings.globalize_path(save_dir))
	print("CLOUDREACH MIDBATTLE LOAD %s failures=%d" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	quit(0 if failures.is_empty() else 1)


func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for child in dir.get_directories():
		_remove_tree(path.path_join(child))
	for file in dir.get_files():
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)
