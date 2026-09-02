extends SceneTree

## OWNER-0902-REST-VISIBILITY, half 1. Owner playtest finding 15, verbatim:
## "Creatures never get out of bed / never appear rested."
##
## `OWNER-0902-DAYNIGHT-REGRESSION` cleared the day/night clock and traced the
## symptom to the build-placement path instead. `OWNER-0902-TENT-CAMPFIRE-
## PLACEMENT` and `OWNER-0902-CAMP-SPLIT` then landed real fixes to that path
## -- but nobody has since run an actual rest cycle start to finish. The
## closest existing coverage, `tools/_probe_camp_split.gd`, places all four
## camp pieces and proves the bedroll's OWN rest heals the trainer and
## advances the day; it never assigns a creature to the creature_bed at all,
## so the exact symptom the owner reported (a creature that goes INTO a bed)
## was never actually exercised. This probe closes that gap: it drives the
## whole loop through the real production path in a live Meadows world --
## real catalogue+placer piece placement, the real Interactable prompts, the
## real rest panel, the real bedroll sleep sequence -- and checks the
## creature on the other end is not just healed but genuinely reads as
## "Rested" the same way `tab_creatures.gd`'s own team-menu row would show
## it (`creature_condition.gd::label()`, the exact function that screen
## calls).
##
##   godot --headless --path . --script tools/gate_f/probe_rest_cycle_e2e.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 200
const CREATURE_CONDITION := preload("res://scripts/creatures/creature_condition.gd")

var _failures: Array[String] = []
var _world: Node
var _game: Node
var _player: CharacterBody3D
var _placer: Node


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL: %s" % message)


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_placer = get_first_node_in_group("build_placer")
	if _game == null or _player == null or _placer == null:
		_fail("Meadows did not stand up Game, Player, and BuildPlacer")
		_report()
		return

	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")

	_game.set("free_build", false)
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "wood", 30)
	inventory.call("add", "stone", 30)
	inventory.call("add", "fiber", 30)

	await _teleport_to(Vector3(90.0, 0.0, 90.0))

	var creature_bed := await _place("creature_bed", Vector3(90.0, 0.0, 90.0))
	var bedroll := await _place("bedroll", Vector3(94.0, 0.0, 90.0))
	if creature_bed == null or bedroll == null:
		_report()
		return
	print("creature_bed and bedroll both placed independently through the real menu+placer")

	# A fresh Meadows boot has no starter chosen yet -- seed one the same way
	# every other Gate F probe that needs a live creature does
	# (`probe_revive_menu_flow.gd`, `probe_mira_intro_grant.gd`): through the
	# real `Game.make_creature()`/`Party.add()` path, not a hand-built instance.
	var party: RefCounted = _game.get("party")
	var creature: RefCounted = party.call("at", 0)
	if creature == null:
		creature = _game.call("make_creature", "terrapup")
		if creature == null or not bool(party.call("add", creature)):
			_fail("could not seed a starter creature into the party")
			_report()
			return
		print("seeded a terrapup into party slot 0")

	# The worst version of the owner's own complaint: a fainted creature going
	# into a bed. If a fainted creature can neither be assigned nor woken
	# rested, "never gets out of bed" reproduces at its harshest.
	creature.set("hp", 0.0)
	creature.set("fainted", true)
	creature.set("rested", false)
	print("creature before rest: %s fainted=%s hp=%s/%s"
		% [str(creature.call("label")), str(creature.get("fainted")),
			str(creature.get("hp")), str(creature.get("max_hp"))])

	# --- walk to the creature_bed and interact, the real production path ---
	await _teleport_to(creature_bed.global_position + Vector3(0.0, 0.0, 1.0))
	var bed_prompt := creature_bed.get_node_or_null(^"Interactable")
	if bed_prompt == null:
		_fail("placed creature_bed has no Interactable prompt")
		_report()
		return
	bed_prompt.emit_signal("activated")
	for i in 10:
		await physics_frame

	var panel := _find_by_script(root, "creature_bed_panel.gd")
	if panel == null:
		_fail("creature_bed's Interactable prompt did not open creature_bed_panel.gd")
	elif not bool(panel.call("is_open")):
		_fail("creature_bed_panel.gd opened but is_open() is false")
	else:
		print("creature_bed's Rest prompt opened the real rest panel")

	# Mirrors pressing the panel's own row button (`creature_bed_panel.gd::
	# _on_rest_row`), which does nothing but call this on the bed.
	var assigned: bool = creature_bed.call("assign_creature", 0)
	print("assign_creature(0) returned: %s" % str(assigned))
	if not assigned:
		_fail("assign_creature(0) refused -- a player pressing this row would see nothing happen")
	if not bool(creature.get("resting")):
		_fail("creature is not marked resting after assign_creature(0)")
	if panel != null:
		panel.call("close")

	# --- walk to the bedroll and sleep, the real production path ---
	await _teleport_to(bedroll.global_position + Vector3(0.0, 0.0, 1.0))
	var bed_prompt2 := bedroll.get_node_or_null(^"Interactable")
	if bed_prompt2 == null:
		_fail("placed bedroll has no Interactable prompt")
		_report()
		return
	var day_before := int(_game.get("day"))
	bed_prompt2.emit_signal("activated")
	# player_bed.gd's own fade: FADE_SECONDS (1.2) half-out, a 0.4s hold where
	# `_pass_the_night()` actually runs, then half-in. Waited generously past
	# that real wall-clock sequence rather than guessing the exact frame.
	var waited := 0.0
	while waited < 3.0:
		await process_frame
		waited += 1.0 / 60.0

	if int(_game.get("day")) != day_before + 1:
		_fail("sleeping at the bedroll did not advance the day (%d -> %d)" % [day_before, int(_game.get("day"))])

	print("")
	print("creature after rest: %s fainted=%s resting=%s rested=%s hp=%s/%s rest_bed_index=%s"
		% [str(creature.call("label")), str(creature.get("fainted")), str(creature.get("resting")),
			str(creature.get("rested")), str(creature.get("hp")), str(creature.get("max_hp")),
			str(creature.get("rest_bed_index"))])

	if bool(creature.get("resting")):
		_fail("creature is still marked resting after a completed night's sleep -- this is the bed it never gets out of")
	if int(creature.get("rest_bed_index")) != -1:
		_fail("creature's rest_bed_index was not cleared after waking (%s)" % str(creature.get("rest_bed_index")))
	if bool(creature.get("fainted")):
		_fail("creature is still fainted after a completed bed rest")
	if not bool(creature.get("rested")):
		_fail("creature's rested flag is false after a completed bed rest -- it never appears rested")
	if float(creature.get("hp")) < float(creature.get("max_hp")):
		_fail("creature woke without full HP (%s / %s)" % [str(creature.get("hp")), str(creature.get("max_hp"))])
	if not bool(creature_bed.call("is_occupied")) == true:
		pass  # bed correctly vacated; is_occupied() should now be false, checked below
	if bool(creature_bed.call("is_occupied")):
		_fail("creature_bed still reports occupied after the creature woke")

	# The actual player-visible proof: the exact string tab_creatures.gd's own
	# team-menu row would show for this creature right now.
	var cfg := CREATURE_CONDITION.config()
	var displayed := CREATURE_CONDITION.label(creature, cfg)
	print("tab_creatures.gd condition line would read: \"%s\"" % displayed)
	if not displayed.begins_with("Rested"):
		_fail("the real team-menu condition line does not read \"Rested...\" after a completed rest (got \"%s\")" % displayed)

	_report()


func _place(id: String, at: Vector3) -> Node3D:
	await _teleport_to(at)
	_game.set("pending_build", id)
	for i in 20:
		await physics_frame
	if not bool(_placer.get("_ghost_ok")):
		_fail("'%s' ghost is red at %s (reason: %s)" % [id, at, str(_placer.get("_ghost_reason"))])
		return null
	var before: Array[Node] = get_nodes_in_group("placed_building")
	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 15:
		await physics_frame
	_game.set("pending_build", "")
	for i in 5:
		await physics_frame
	for node: Node in get_nodes_in_group("placed_building"):
		if before.has(node):
			continue
		if str(node.get_meta("building_id", "")) == id:
			print("placed '%s' through the real catalogue+placer" % id)
			return node as Node3D
	_fail("arming and pressing build_place for '%s' planted nothing" % id)
	return null


func _teleport_to(at: Vector3) -> void:
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else 0.0
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 12:
		await physics_frame


func _find_by_script(node: Node, suffix: String) -> Node:
	var script: Script = node.get_script()
	if script != null and str(script.resource_path).ends_with(suffix):
		return node
	for child in node.get_children():
		var found := _find_by_script(child, suffix)
		if found != null:
			return found
	return null


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("REST CYCLE E2E PROBE: PASS -- a real creature_bed assignment followed by a "
			+ "real bedroll sleep, through the actual production interaction path, produces "
			+ "a creature that is out of bed, fully healed, un-fainted, and reads \"Rested\" "
			+ "on the real team-menu condition line.")
		quit(0)
		return
	print("REST CYCLE E2E PROBE: FAIL (%d)" % _failures.size())
	for failure in _failures:
		print("  - %s" % failure)
	quit(1)
