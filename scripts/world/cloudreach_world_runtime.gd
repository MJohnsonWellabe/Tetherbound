extends Node

signal finale_presentation_mode_changed(mode: String)

## Production-scene composition only. Canonical gameplay services retain their
## flags, inventories, battle resolution and save ownership.
const COMBAT := preload("res://scripts/combat/cloudreach_combat_manager.gd")
const ENCOUNTERS := preload("res://scripts/world/cloudreach_scene_encounters.gd")
const FINALE := preload("res://scripts/world/cloudreach_finale_controller.gd")
const ATMOSPHERE := preload("res://scripts/world/cloudreach_scene_atmosphere.gd")
const ARENA := preload("res://scripts/world/cloudreach_summit_presentation.gd")
const PLACER := preload("res://scripts/build/build_placer.gd")
const DEATH := preload("res://scripts/world/player_death.gd")
const COMBAT_HUD := preload("res://scenes/combat/combat_hud.tscn")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
var world: Node3D
var player: CharacterBody3D
var chapter: Node
var manager: Node
var director: Node
var finale: Node3D
var atmosphere: Node
var death: Node3D
var presentation: Node3D
var navigation: RefCounted
var battle_yards: Node3D
var payoffs: Node3D
var _registered: Array[CharacterBody3D] = []
var _field_body: CharacterBody3D
var _mounted := false
var _recovering := false
var _traveler_revision := -1


func build_environment(owner_world: Node3D) -> void:
	world = owner_world
	presentation = ARENA.new()
	presentation.name = "SummitArenaPresentation"
	world.add_child(presentation)
	presentation.call("build", world)
	battle_yards=preload("res://scripts/world/cloudreach_battle_yards.gd").new()
	battle_yards.name="CloudreachBattleYards"
	world.add_child(battle_yards)
	battle_yards.call("build",world)


func mount(owner_world: Node3D, chapter_node: Node, realm_map: RefCounted) -> void:
	if _mounted:
		return
	_mounted = true
	world = owner_world
	chapter = chapter_node
	navigation = realm_map
	player = world.get_node("Player")
	var game := get_node("/root/Game")
	var placer := PLACER.new()
	placer.name = "BuildPlacer"
	placer.player_path = NodePath("../Player")
	placer.camera_rig_path = NodePath("../CameraRig")
	world.add_child(placer)
	death = DEATH.new()
	death.name = "PlayerDeath"
	world.add_child(death)
	var data: Dictionary = chapter.get("_chapter")
	death.call("configure_recovery", data.get("camping_contract", {}).get("camps", []), Callable(world, "ground_height_near"))
	death.call("build", world, player, player.global_position)
	death.call("restore_from_game", game)
	manager = COMBAT.new()
	manager.name = "CombatManager"
	manager.set("ground_world", world)
	world.add_child(manager)
	finale = FINALE.new()
	finale.name = "CloudreachFinaleController"
	finale.call("setup", game.get("progression"), Callable(chapter.call("events_adapter"), "emit_event"),
		Callable(self, "controlled_body"), Callable(self, "creature_piloted"), Callable(self, "recover_to_bivouac"))
	world.add_child(finale)
	_install_creature_relay_prompts()
	presentation.call("bind_finale", finale)
	director = ENCOUNTERS.new()
	director.name = "EncounterDirector"
	director.set("chapter_source", chapter)
	director.set("authored_yard_positions",battle_yards.get("trainer_positions"))
	director.set("player_path", NodePath("../Player"))
	director.set("manager_path", NodePath("../CombatManager"))
	director.set("camera_rig_path", NodePath("../CameraRig"))
	var bodies: Dictionary = chapter.call("npc_bodies")
	director.call("setup", world, bodies, resolved_encounter_data(bodies))
	world.add_child(director)
	director.call("set_arbiter", world.get_node("InteractionArbiter"))
	director.connect("trainer_started", _trainer_started)
	director.connect("trainer_opposition_changed", Callable(finale, "opposition_remaining"))
	director.connect("trainer_victory", _trainer_won)
	director.connect("trainer_lost", _trainer_lost)
	var combat_hud := COMBAT_HUD.instantiate()
	combat_hud.name = "CombatHUD"
	combat_hud.set("manager_path", NodePath("../CombatManager"))
	combat_hud.set("director_path", NodePath("../EncounterDirector"))
	world.add_child(combat_hud)
	atmosphere = ATMOSPHERE.new()
	atmosphere.name = "CloudreachAtmosphere"
	atmosphere.call("configure", game.get("progression"), navigation, player, presentation.call("atmosphere_bindings"))
	world.add_child(atmosphere)
	payoffs = preload("res://scripts/world/cloudreach_world_payoffs.gd").new()
	payoffs.name = "CloudreachWorldPayoffs"
	world.add_child(payoffs)
	payoffs.call("configure", world, chapter, presentation)
	finale.connect("phase_changed", _phase_changed)
	_register_actor(player)
	# PlaygroundHUD already mounts the progression-feed presenter and build-menu
	# input entry point. Reuse them; a duplicate presenter would drain the queue.
	var hud := world.get_node("PlaygroundHUD")
	var minimap: Control = hud.get("_minimap")
	if minimap != null:
		minimap.call("configure", navigation, world.call("map_terrain_texture"), 90.0)
		hud.set("_minimap_baked", true)
	add_to_group("progression_restore")
	_publish_finale_presentation_mode()


func _install_creature_relay_prompts() -> void:
	var prompts: Dictionary = finale.get("_prompts")
	for id: String in prompts.keys():
		var previous: Node3D = prompts[id]
		var prompt := preload("res://scripts/world/cloudreach_relay_interactable.gd").new()
		prompt.name = previous.name
		prompt.position = previous.position
		prompt.configure(str(previous.get("label")),float(previous.get("radius")),false)
		prompt.controlled_body = Callable(self,"controlled_body")
		finale.remove_child(previous)
		previous.queue_free()
		finale.add_child(prompt)
		prompt.activated.connect(Callable(finale,"_activate_relay").bind(id))
		prompts[id]=prompt


func resolved_encounter_data(bodies: Dictionary) -> Dictionary:
	var data: Dictionary = ENCOUNTERS.read_json(ENCOUNTERS.CONFIG_PATH)
	var physical: Dictionary = ENCOUNTERS.read_json("res://data/config/cloudreach_physical_runtime.json")
	if str(get_node("/root/Game").get("current_realm")) != "cloudreach":
		data["trainers"] = []
		data["wild_sites"] = []
		return data
	for spec: Dictionary in data.trainers:
		if str(spec.id)=="officer_voss_summit_approach":
			spec["reuse_npc_id"]="officer_voss"
		if str(spec.get("reuse_npc_id", "")) == "orrin":
			spec["reuse_npc_id"] = "bridgekeeper_orrin"
		var requirements: Array = physical.get("encounter_requirements", {}).get(str(spec.id), spec.get("requires_flags", []))
		spec["requires_flags"] = requirements.duplicate()
		var body: Node3D = bodies.get(str(spec.get("reuse_npc_id", "")))
		var at := body.global_position if body != null else world.call("_resource_position", FINALE.vec(spec.position)) as Vector3
		var yards: Dictionary=battle_yards.get("trainer_positions")
		if yards.has(str(spec.id)):
			at=yards[str(spec.id)]
		spec["position"] = [at.x, at.y, at.z]
	for site: Dictionary in data.wild_sites:
		var at: Vector3 = world.call("_resource_position", FINALE.vec(site.position))
		site["position"] = [at.x, at.y, at.z]
	return data


func controlled_body() -> CharacterBody3D:
	if is_instance_valid(_field_body):
		return _field_body
	if manager != null and bool(manager.call("is_fighting")):
		return manager.get("_ally_body") as CharacterBody3D
	return player


func creature_piloted() -> bool:
	var body := controlled_body()
	return is_instance_valid(body) and body != player


func _register_actor(actor: CharacterBody3D) -> void:
	if not is_instance_valid(actor):
		return
	var registry: RefCounted = actor.get("_environment_velocity")
	if registry != null and (registry.get("_entries") as Dictionary).has(&"cloudreach_summit"):
		return
	actor.call("register_environment_velocity_modifier", &"cloudreach_summit", finale, Callable(finale, "apply_hazards"), 100)
	if actor not in _registered:
		_registered.append(actor)


func _process(_delta: float) -> void:
	if not _mounted:
		return
	_sync_returning_travelers()
	var ally: CharacterBody3D = director.call("ally_body")
	_register_actor(ally)
	_register_actor(controlled_body())
	var should_pilot := str(finale.get("phase")) == "break_the_eye" \
		and not bool(manager.call("is_fighting")) and not bool(director.call("trainer_battle_active")) \
		and is_instance_valid(ally) and ally.visible \
		and ally.global_position.distance_to(finale.global_position) < 65.0
	if should_pilot and ally != _field_body:
		_release_field_control()
		_field_body = ally
		_field_body.call("set_following", false)
		player.call("set_locomotion_enabled", false)
		world.get_node("CameraRig").call("set_target", ally, {"distance": 5.8, "height": 1.4})
		world.get_node("InteractionArbiter").call("set_player", ally)
	elif not should_pilot and is_instance_valid(_field_body):
		_release_field_control()
	if finale != null:
		finale.call("witness_restoration", controlled_body())


func _sync_returning_travelers() -> void:
	var flags: RefCounted = get_node("/root/Game").get("progression")
	var revision := int(flags.get("revision"))
	if revision == _traveler_revision:
		var previous: Array = (atmosphere.get("bindings") as Dictionary).get("returning_travelers",[])
		if previous.all(func(body: Variant) -> bool: return is_instance_valid(body)) and (not previous.is_empty() or not bool(flags.call("has","cloudreach_winds_restored"))):
			return
	_traveler_revision = revision
	var returning: Array = []
	if bool(flags.call("has","cloudreach_winds_restored")):
		var bodies: Dictionary = chapter.call("npc_bodies")
		for id in ["warden_aila","courier_neri","bridgekeeper_orrin"]:
			if is_instance_valid(bodies.get(id)):
				returning.append(bodies[id])
	# PhysicalRuntime owns relocation; atmosphere only binds those same people,
	# never a second cast and never hides their pre-restoration incarnations.
	(atmosphere.get("bindings") as Dictionary)["returning_travelers"] = returning


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_field_body) or INPUT_OWNER.current(get_tree()) != null:
		return
	if not bool(world.get_node("InteractionArbiter").call("enabled")):
		return
	var axis := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var basis: Basis = world.get_node("CameraRig").call("planar_basis")
	_field_body.call("request_move", basis * Vector3(axis.x, 0, axis.y))


func _release_field_control() -> void:
	if is_instance_valid(_field_body):
		_field_body.call("set_following", true)
	_field_body = null
	if is_instance_valid(world) and is_instance_valid(player):
		world.get_node("InteractionArbiter").call("set_player", player)
		world.get_node("CameraRig").call("set_target", player, {})
		player.call("set_locomotion_enabled", true)


func _trainer_started(id: String) -> void:
	finale.call("encounter_started", id)
	if id == "captain_veyra_storm_anchor":
		atmosphere.call("set_finale_active", true)


func _trainer_won(id: String) -> void:
	if id == "captain_veyra_storm_anchor":
		finale.call("encounter_won", id)
	else:
		chapter.call("physical_runtime").call("encounter_won", id)


func _trainer_lost(id: String) -> void:
	finale.call("encounter_lost", id, controlled_body())


func _phase_changed(phase: String) -> void:
	if atmosphere != null:
		atmosphere.call("set_finale_active", phase in ["crosswind_command", "anchor_overload"])
	_publish_finale_presentation_mode()


func finale_presentation_mode() -> String:
	var phase := str(finale.get("phase")) if finale != null else "dormant"
	if phase in ["crosswind_command","anchor_overload"]:
		return "combat"
	return "relays" if phase=="break_the_eye" else "exploration"


func _publish_finale_presentation_mode() -> void:
	var mode:=finale_presentation_mode()
	finale_presentation_mode_changed.emit(mode)
	for name in ["PlaygroundHUD","CombatHUD"]:
		var hud:=world.get_node_or_null(NodePath(name))
		if hud!=null and hud.has_method("set_world_presentation_mode"):
			hud.call("set_world_presentation_mode",mode)


func recover_to_bivouac(_body: CharacterBody3D, _camp: String, _safe: Vector3) -> void:
	# Deferred: the director finishes its existing loss callback before recovery.
	if _recovering:
		return
	_recovering = true
	_recover.call_deferred()


func _recover() -> void:
	_release_field_control()
	# A deep fall can arrive during a live round, not only after defeat. Let the
	# real manager/director unwind that round as a retreat before moving bodies.
	if bool(manager.call("is_fighting")):
		manager.call("_begin_resolve", "fled")
		await manager.exited
	elif bool(director.call("trainer_battle_active")):
		director.call("_finish_trainer_battle", false)
	var game := get_node("/root/Game")
	var at: Vector3 = death.call("recovery_position", game, finale.global_position)
	death.call("_respawn", at)
	var ally: Node3D = director.call("ally_body")
	if is_instance_valid(ally):
		ally.global_position = at + Vector3(2, 0, 0)
		ally.set("velocity", Vector3.ZERO)
	world.get_node("CameraRig").call("set_target", player, {})
	world.get_node("CameraRig").global_position = at+Vector3.UP*1.75
	game.call("save_game", game.call("autosave_slot"))
	_recovering = false


func restore_progression_from_game(_game: Node) -> void:
	_release_field_control()
	_traveler_revision = -1


func _exit_tree() -> void:
	for actor in _registered:
		if is_instance_valid(actor):
			actor.call("clear_environment_velocity_modifier", &"cloudreach_summit")
	_registered.clear()
