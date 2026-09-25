extends SceneTree

## Production interaction fixture for `stormwood_glass_for_bryn`. The real
## chain node, interaction arbiter, chapter-events writer, Game ledger, save
## system, RestPoint and creature bed run; a fixture panel stands in for the
## dialogue UI and completes a conversation on request, and a flat fixture
## world stands in for the terrain. Meeting Bryn is staged and disclosed here
## (the earned route to Rodline Post is `smoke_stormwood_glass_for_bryn_earned`).
const GLASS := preload("res://scripts/world/stormwood_glass_for_bryn.gd")
const EVENTS := preload("res://scripts/world/realm_chapter_events.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

var failures: Array[String] = []
var assertions := 0


class FixtureWorld extends Node3D:
	var simulation_only := false

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


class FixturePanel extends Node:
	signal completed(conversation_id: String)
	var started: Array[String] = []

	func is_open() -> bool:
		return false

	func complete(conversation_id: String) -> void:
		started.append(conversation_id)
		completed.emit(conversation_id)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	_check(game != null, "Game autoload is available")
	if game == null:
		_finish()
		return
	game.set("save_system", SAVE_GAME.new("user://smoke_glass_for_bryn_%d" % Time.get_ticks_usec()))
	game.reset_for_new_game()
	game.current_realm = "stormwood"
	game.world.world_id = "smoke-glass-for-bryn"
	game.local.character_id = "smoke-glass-for-bryn-courier"
	var world := _mount_world(game, "GlassForBrynFixture")
	var glass: Node3D = world.get_node("GlassForBryn")
	var panel: Node = world.get_node("DialoguePanel")
	var player: Node3D = world.get_node("Player")
	var arbiter: Node = world.get_node("InteractionArbiter")
	await process_frame
	await physics_frame

	var prompt: Node3D = glass.get("inspect_prompt")
	var supplies: Node3D = glass.get("supplies")
	_check(glass.get("shelter") != null and prompt != null and supplies != null,
		"the rod shelter, its supplies and its inspect prompt are standing")
	_check(not supplies.visible and not bool(prompt.get("enabled")),
		"before the chain the shelter offers no supplies and no inspection")
	_check(glass.get("care_point") == null and _bed(glass) == null,
		"before the chain the shelter is not a care point and has no creature bed")

	# STAGED: Bryn's own story account (earned in the witness run).
	for flag: String in ["stormwood:chapter_started", "stormwood:rodline_linked", GLASS.REVEALED]:
		game.ledger.submit({"kind": "set_world_flag", "realm": "stormwood", "id": flag, "value": true})
	_check(game.progression.has(GLASS.REVEALED), "fixture met Bryn")

	panel.complete(GLASS.REQUEST)
	await process_frame
	_check(not game.progression.has(GLASS.STEP_2), "a request before Bryn's brief does nothing")
	panel.complete(GLASS.OFFER)
	await process_frame
	_check(game.progression.has(GLASS.STEP_1), "Bryn's brief records step 1 through chapter events")

	game.inventory.add("stormglass", 2)
	game.inventory.add("conductor_vine", 2)
	game.take_pending_world_message()
	panel.complete(GLASS.REQUEST)
	await process_frame
	_check(not game.progression.has(GLASS.STEP_2), "two Stormglass cannot repair the shelter")
	_check(_counts(game) == [2, 2], "a lacking delivery takes nothing (%s)" % str(_counts(game)))
	var told := str(game.take_pending_world_message())
	_check(told.contains("3 Stormglass") and told.contains("carry 2 Stormglass"),
		"the player is told what Bryn needs and what they carry: %s" % told)
	_check(not bool(glass.call("delivering")), "a refused request leaves nothing in flight")

	game.inventory.add("stormglass", 2)
	var sequence := int(game.ledger.ledger.seq)
	panel.complete(GLASS.REQUEST)
	await process_frame
	_check(game.progression.has(GLASS.STEP_2), "the full delivery records step 2")
	_check(_counts(game) == [1, 0], "exactly 3 Stormglass and 2 Conductor Vine were taken (%s)" % str(_counts(game)))
	_check(int(game.ledger.ledger.seq) == sequence + 1, "flag and takes arrived as one delta")
	var journal: Variant = game.save_system.call("worlds").call("read", "smoke-glass-for-bryn")
	_check(journal is Dictionary and _journal_has(journal, GLASS.STEP_2),
		"the host journal holds the delivery")

	game.inventory.add("stormglass", 3)
	game.inventory.add("conductor_vine", 2)
	var before := _counts(game)
	_check(not bool(glass.call("request_delivery")), "a second press asks nothing")
	panel.complete(GLASS.REQUEST)
	glass.call("dispatch", 1, {"kind": GLASS.DELIVERY_KIND, "stormglass": 9, "conductor_vine": 9})
	await process_frame
	_check(_counts(game) == before, "a repeated or retried delivery takes nothing (%s)" % str(_counts(game)))
	_check(int(game.ledger.ledger.seq) == sequence + 1, "no second delta was committed")

	await process_frame
	_check(supplies.visible, "the repaired supplies are visible at the shelter")
	_check(bool(prompt.get("enabled")), "the supplies can be inspected")
	player.global_position = prompt.global_position + Vector3(0, -0.6, 1.2)
	await physics_frame
	arbiter.call("_recompute")
	_check(str((arbiter.get("_winner") as Dictionary).get("label", "")) == "Inspect the repaired supplies",
		"the arbiter offers the inspection at the shelter")
	_check(arbiter.activate(), "the production prompt inspects the supplies")
	await process_frame
	_check(game.progression.has(GLASS.COMPLETE), "inspection completes the chain")
	_check(not bool(prompt.get("enabled")), "the inspection is not offered again")

	var care: Node3D = glass.get("care_point")
	var bed := _bed(glass)
	_check(care != null and care.get_node_or_null(^"Interactable") != null,
		"the shelter now offers the shared rest")
	_check(bed != null and int(bed.call("build_index")) == GLASS.bed_index(),
		"one creature bed stands at its reserved index")
	var shelter_xz := GLASS.shelter_at()
	var bed_xz := shelter_xz + GLASS._offset(GLASS.config().shelter.creature_bed.offset)
	_check(bed != null and Vector2(bed.global_position.x, bed.global_position.z).distance_to(bed_xz) < 0.05,
		"the bed stands where authored, not doubled by its parent offset")
	_check(care != null and Vector2(care.global_position.x, care.global_position.z).distance_to(shelter_xz) < 0.05,
		"the care point stands at the shelter")
	var creature: RefCounted = SPECIES.spawn("sparkit")
	_check(creature != null and bool(game.party.add(creature)), "fixture party has a companion")
	if bed != null:
		# Stand on the bed's far side from the rest prompt, as a player would.
		var away := Vector2(bed.global_position.x, bed.global_position.z) - shelter_xz
		away = away.normalized() * 1.1
		player.global_position = bed.global_position + Vector3(away.x, 0, away.y)
		await physics_frame
		arbiter.call("_recompute")
		_check(str((arbiter.get("_winner") as Dictionary).get("label", "")) == "Rest a Creature",
			"the arbiter offers the new bed: %s" % str(arbiter.get("_winner")))
		_check(bool(bed.call("assign_creature", 0)), "a companion can be bedded down")
		_check(bool(creature.get("resting")) and int(creature.get("rest_bed_index")) == GLASS.bed_index(),
			"the companion rests in this shelter's bed")
		_check(int(bed.call("occupant_index")) == 0, "the bed reports its occupant")
		_check(not bool(bed.call("assign_creature", 0)), "one bed holds one companion")
	var rest_prompt := care.get_node_or_null(^"Interactable") as Node3D if care != null else null
	if rest_prompt != null:
		player.global_position = rest_prompt.global_position + Vector3(0, -0.6, 1.0)
		await physics_frame
		arbiter.call("_recompute")
		_check(str((arbiter.get("_winner") as Dictionary).get("label", "")) == "Rest at the rod crews' shelter",
			"the arbiter offers rest at the shelter")

	panel.complete(GLASS.THANKS)
	await process_frame
	_check(game.progression.has(GLASS.THANKED), "Bryn's acknowledgement is recorded once heard")

	# Save/load and a later arrival: a fresh process view mounts from the world.
	var saved: Dictionary = game.world.save_data()
	game.world.load_data({})
	_check(not game.progression.has(GLASS.COMPLETE), "fresh world data clears the chain")
	game.world.load_data(saved)
	world.queue_free()
	await process_frame
	await process_frame
	var reloaded := _mount_world(game, "GlassForBrynReloaded")
	await process_frame
	var again: Node3D = reloaded.get_node("GlassForBryn")
	for flag: String in [GLASS.STEP_1, GLASS.STEP_2, GLASS.COMPLETE, GLASS.THANKED]:
		_check(game.progression.has(flag), "%s survives world save/load" % flag)
	_check(again.get("care_point") != null and _bed(again) != null,
		"a remounted shelter is a care point with its bed at once")
	_check(not bool((again.get("inspect_prompt") as Node3D).get("enabled")),
		"a remounted shelter does not ask for inspection again")
	_check(int(_bed(again).call("occupant_index")) == 0 if _bed(again) != null else false,
		"the companion is still resting in the reloaded bed")
	for flag: String in ["stormwood:rod_verge_disabled", "stormwood:rod_hollows_disabled",
			"stormwood:rod_deepwood_disabled", "stormwood:rod_dynamo_disabled",
			"stormwood:lower_rods_disabled", "stormwood:all_rods_disabled"]:
		_check(not game.progression.has(flag), "the chain did not write %s" % flag)
	reloaded.queue_free()
	await process_frame
	await process_frame
	_finish()


func _mount_world(game: Node, world_name: String) -> Node3D:
	var world := FixtureWorld.new()
	world.name = world_name
	root.add_child(world)
	var player := _player()
	world.add_child(player)
	player.global_position = Vector3(-700.0, 0.0, 2301.5)
	var arbiter := ARBITER.new()
	arbiter.name = "InteractionArbiter"
	arbiter.player_path = NodePath("../Player")
	world.add_child(arbiter)
	var panel := FixturePanel.new()
	panel.name = "DialoguePanel"
	world.add_child(panel)
	var chapter := EVENTS.new()
	chapter.name = "StormwoodChapter"
	chapter.realm_id = "stormwood"
	chapter.chapter = _chapter_data()
	world.add_child(chapter)
	var glass := GLASS.new()
	glass.name = "GlassForBryn"
	world.add_child(glass)
	glass.mount(world)
	return world


func _bed(glass: Node) -> Node3D:
	var care: Node = glass.get("care_point")
	return care.get_node_or_null(^"CampCreatureBed") as Node3D if care != null else null


func _counts(game: Node) -> Array:
	return [int(game.inventory.count("stormglass")), int(game.inventory.count("conductor_vine"))]


func _journal_has(journal: Dictionary, flag: String) -> bool:
	return JSON.stringify(journal).contains(flag)


func _chapter_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_chapter.json"))
	return parsed if parsed is Dictionary else {}


func _player() -> CharacterBody3D:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.collision_layer = 1
	player.collision_mask = 1
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)
	return player


func _check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _finish() -> void:
	for failure: String in failures:
		push_error("FAIL: " + failure)
	print("STORMWOOD GLASS FOR BRYN %s: %d assertions, %d failures" % [
		"OK" if failures.is_empty() else "FAILED", assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
