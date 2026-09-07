extends SceneTree

## One real Water scene, normal party deployment and Alpha combat entry.
## Teleport/level fixtures are explicit; this does not prove the island journey.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CATALOG := preload("res://scripts/creatures/water_species_catalog.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var checks := 0
var failures := 0

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
	print("PASS: " if ok else "FAIL: ", label)
	return ok

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.current_realm = "water"
	game.local.character_id = "alpha-runtime-smoke"
	game.world.world_id = "alpha-runtime-world"
	game.save_system = SAVE.new("user://water_alpha_runtime_%d/" % Time.get_ticks_usec())
	var catalog: Dictionary = CATALOG.merge_catalogue(SPECIES.table())
	SPECIES.table().merge(catalog.catalogue, true)
	var ally: RefCounted = SPECIES.spawn("water_mosshell")
	ally.set_level(49, preload("res://scripts/creatures/progression.gd").config())
	game.local.party.add(ally)
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 90000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not check(world.shell_build_complete(), "Actual Water scene finishes building with Alpha service"):
		_finish()
		return
	var alpha: Node = world.get_node("WaterAlpha")
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	var player: Node3D = world.get_node("Player")
	check(alpha.ready_for_intents and alpha.body.instance.species_id == "water_aquaryn", "Live Aquaryn uses Water species and authority")
	check(alpha.body.instance.level == 49, "Authored Alpha level")
	check(not game.local.flags.has("water_swim_stone_earned"), "No fixture grants Stone")
	player.global_position = alpha.body.global_position + Vector3(7, 0, 0)
	player.global_position.y = world.ground_height_at(player.position.x, player.position.z)
	for frame in 12:
		await physics_frame
	if not check(director.summon_active_creature(), "Normal summon deploys owned Mosshell"):
		_finish()
		return
	var before: Vector3 = alpha.body.global_position
	alpha.request_engage()
	check(manager.is_fighting() and manager.encounter_id() == alpha.authority.encounter_id, "Normal local combat binds to host Alpha encounter")
	check(alpha.body.global_position.distance_to(before) < 0.01, "Combat entry preserves shared enemy position")
	check(alpha.body.arena == null, "Shared Alpha is not confined to a local arena")
	check(alpha.authority.record().get("participants", {}).size() == 1, "Host records actual participant")
	var hp_before: float = ally.hp
	for frame in 360:
		await physics_frame
	check(alpha.body.global_position.distance_to(before) > 0.1, "Real Alpha AI moves toward deployed opponent")
	check(ally.hp < hp_before, "Host enemy strike reaches actual participant through transport")
	check(not game.local.flags.has("water_swim_stone_earned"), "An unfinished fight never grants Stone")
	# Drive normal quick-attack input and face the live target. No damage/HP
	# injection: the manager windup, host geometry and damage roll must execute.
	var deadline_fight := Time.get_ticks_msec() + 90000
	var tick := 0
	while manager.is_fighting() and Time.get_ticks_msec() < deadline_fight:
		var deployed: Node3D = director.get("_ally_body")
		if deployed != null:
			deployed.face_towards(alpha.body.global_position)
		if tick % 24 == 0:
			Input.action_press("combat_quick")
		elif tick % 24 == 2:
			Input.action_release("combat_quick")
		tick += 1
		await physics_frame
	Input.action_release("combat_quick")
	check(not manager.is_fighting(), "Real fight reaches an exit within bounded time")
	check(str(alpha.authority.resolution.get("outcome", "")) == "defeated", "Normal attack input defeats actual Alpha")
	check(game.world.flags.has("water_aquaryn_resolved"), "Defeat is journaled as world progression")
	check(game.local.flags.has("water_swim_stone_earned"), "Eligible character receives Swim Stone unlock")
	print("Alpha runtime evidence: phase=", alpha.authority.phase().id, " ally_hp=", ally.hp, " enemy_hp=", alpha.body.instance.hp)
	if game.local.flags.has("water_swim_stone_earned"):
		await _complete_saddle_chain(game, world, director, player, ally)
	_finish()

func _complete_saddle_chain(game: Node, world: Node3D, director: Node, player: Node3D, ally: RefCounted) -> void:
	# Explicit proximity and crafting-material fixtures. The Stone was earned
	# above through actual combat; no recipe flag or saddle item is injected.
	check(not game.local.flags.has("water_swim_saddle_recipe_learned"), "Victory alone does not teach the recipe")
	check(game.inventory.count("swim_saddle") == 0, "No fixture supplies a Swim Saddle")
	var chapter: Node = world.get_node("WaterChapter")
	var iona: Node3D = chapter.npc_bodies.get("water_iona")
	if not check(iona != null, "Iona's production NPC exists after victory"):
		return
	player.set_physics_process(false)
	var prompt: Node3D = iona.prompt_node()
	if not check(await _find_offer(world, player, prompt), "Nearby Iona offers actual conversation"):
		return
	prompt.interaction_activate()
	await _frames(3)
	var dialogue: Node = world.get_node("DialoguePanel")
	if not check(dialogue.is_open() and str(dialogue.runner().conversation_id()) == "water_iona_recipe", "Earned Stone selects Iona's guarded recipe conversation"):
		return
	check(not game.local.flags.has("water_swim_saddle_recipe_learned"), "Opening conversation does not grant the recipe early")
	for step in 12:
		if not dialogue.is_open(): break
		dialogue.advance()
		await _frames(3)
	if not check(not dialogue.is_open() and game.local.flags.has("water_swim_saddle_recipe_learned"), "Completing Iona's actual dialogue teaches the personal recipe"):
		return
	var camp: Node3D = world.get_node("WaterCamps").camps.get("water_camp_tidal_cradle")
	if not check(camp != null, "Tidal Cradle has its actual preparation camp"):
		return
	var craft: Node3D = camp.get_node("CraftInteractable")
	if not check(await _find_offer(world, player, craft), "Nearby camp workbench offers actual crafting"):
		return
	for resource: String in ["reed_fiber", "driftwood", "reef_stone"]:
		game.inventory.add(resource, {"reed_fiber":8, "driftwood":6, "reef_stone":4}[resource])
	var before := {"reed_fiber":game.inventory.count("reed_fiber"), "driftwood":game.inventory.count("driftwood"), "reef_stone":game.inventory.count("reef_stone")}
	craft.interaction_activate()
	await _frames(3)
	var panel: Node = camp.get("_craft_panel")
	if not check(panel != null and panel.is_open(), "Camp interaction opens production CraftPanel"):
		return
	var ids: Array = panel.get("_recipe_ids")
	var index := ids.find("water_swim_saddle")
	if not check(index >= 0, "Earned Stone and completed Iona lesson expose the real saddle row"):
		return
	var rows: Array = panel.get("_rows")
	rows[index].pressed.emit()
	await _frames(3)
	check(game.inventory.count("reed_fiber") == int(before.reed_fiber)-8 and game.inventory.count("driftwood") == int(before.driftwood)-6 and game.inventory.count("reef_stone") == int(before.reef_stone)-4, "Real saddle craft consumes exactly eight reed, six driftwood and four reefstone")
	if not check(game.inventory.count("swim_saddle") == 1, "Real craft produces one Swim Saddle"):
		return
	panel.close()
	await _frames(3)
	player.set_physics_process(true)
	# Re-summon the same surviving owned companion beside the preparation camp
	# after the explicit proximity jump. No new creature or healing fixture.
	director.dismiss_active_creature()
	await _frames(3)
	if not check(director.summon_active_creature(), "Normal summon returns the surviving owned Mosshell after preparation"):
		return
	await _frames(30)
	var riding: Node = world.get_node("RidingController")
	if not check(riding.mount(), "Production RidingController mounts Mosshell using the crafted saddle and earned Stone"):
		return
	await _frames(5)
	check(riding.is_mounted() and riding.mount_body() == director.ally_body() and director.ally_instance() == ally, "Mounted body remains the same owned companion from the Alpha fight")
	check(game.local.party.members().size() == 1, "The reward chain never adds a hidden creature slot")
	print("Alpha-to-saddle evidence: dialogue=water_iona_recipe camp=tidal_cradle materials=8reed/6drift/4reef mount=", riding.mount_body().species_id)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _find_offer(world: Node3D, player: Node3D, prompt: Node3D) -> bool:
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var at := prompt.global_position + Vector3(cos(angle), 0, sin(angle)) * 2.0
		at.y = world.ground_height_at(at.x, at.z) + 0.1
		player.global_position = at
		player.velocity = Vector3.ZERO
		await _frames(1)
		if not prompt.interaction_offer(at).is_empty():
			return true
	return false

func _finish() -> void:
	print("Water Alpha runtime smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
