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
const FALL_RECOVERY := preload("res://scripts/world/fall_recovery.gd")
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
var fall_recovery: Node3D
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
	_mount_fall_recovery()


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
	_recover.call_deferred(Vector3.INF)


## OP-0905-22 fall failsafe entry point (see `_mount_fall_recovery`/`_on_world_fall`
## below). Shares `_recover` with the finale hazard current's own recovery
## (`recover_to_bivouac`, wired in `mount()`), and the same `_recovering` guard,
## so a hazard-current recovery already in flight can never be doubled by a
## kill-plane one landing in the same frame -- whichever fires first wins and
## the other is a no-op.
func recover_from_world_fall(body: CharacterBody3D) -> void:
	if _recovering:
		return
	_recovering = true
	_recover.call_deferred(body.global_position)


## `from` is the point `player_death.gd::recovery_position` measures "nearest
## unlocked camp" against. The finale hazard current always resolves that
## against its own arena (`finale.global_position`) -- the current only ever
## runs near there, so that reads as "nearest camp to here" in practice. A
## kill-plane fall can happen anywhere in the realm, so `recover_from_world_fall`
## passes the body's own (pre-recovery) position instead; `Vector3.INF` keeps
## the original arena-relative behaviour for the hazard-current caller.
func _recover(from: Vector3 = Vector3.INF) -> void:
	_release_field_control()
	# A deep fall can arrive during a live round, not only after defeat. Let the
	# real manager/director unwind that round as a retreat before moving bodies.
	if bool(manager.call("is_fighting")):
		manager.call("_begin_resolve", "fled")
		await manager.exited
	elif bool(director.call("trainer_battle_active")):
		director.call("_finish_trainer_battle", false)
	var game := get_node("/root/Game")
	var origin := from if from.is_finite() else finale.global_position
	var at: Vector3 = death.call("recovery_position", game, origin)
	death.call("_respawn", at)
	var ally: Node3D = director.call("ally_body")
	if is_instance_valid(ally):
		ally.global_position = at + Vector3(2, 0, 0)
		ally.set("velocity", Vector3.ZERO)
	world.get_node("CameraRig").call("set_target", player, {})
	world.get_node("CameraRig").global_position = at+Vector3.UP*1.75
	game.call("save_game", game.call("autosave_slot"))
	_recovering = false


## OP-0905-22: a below-the-cloud-sea kill plane covering the whole realm, not
## just the finale arena -- `cloudreach_finale_controller.gd::_apply_recovery_current`
## only ever acts within `config.recovery.current_radius_m` of the arena while a
## finale phase is live, so a fall anywhere else (or before the finale engages
## at all) had nothing catching it. Kill-plane Y and XZ bounds live in
## `data/config/cloudreach_world.json::realm.fall_recovery` per CLAUDE.md
## ("tunables in data/config").
##
## The kill plane is measured off the CloudSea mesh's own built Y rather than
## re-deriving `world_bounds.min_y + 18.0` a second time (`cloudreach_world.gd
## ::_build_cloud_sea`) -- one authored offset, read once, so the two can never
## quietly drift apart if that formula ever changes.
func _mount_fall_recovery() -> void:
	var config: Dictionary = world.call("config_data")
	var realm: Dictionary = config.get("realm", {})
	var bounds: Dictionary = realm.get("world_bounds", {})
	var tunables: Dictionary = realm.get("fall_recovery", {})
	var cloud_sea := world.get_node_or_null(^"CloudSea") as Node3D
	var cloud_sea_y: float = cloud_sea.global_position.y if cloud_sea != null \
		else float(bounds.get("min_y", -200.0)) + 18.0
	var kill_plane_y: float = cloud_sea_y - float(tunables.get("below_cloud_sea_m", 50.0))
	fall_recovery = FALL_RECOVERY.new()
	fall_recovery.name = "FallRecovery"
	world.add_child(fall_recovery)
	fall_recovery.call("setup", Callable(self, "_recovery_target"), kill_plane_y, bounds,
		Callable(self, "_on_world_fall"), player.global_position,
		float(tunables.get("bounds_margin_m", 400.0)))


## Always the human trainer body, never whichever body `controlled_body()`
## returns -- the piloted-ally case only exists briefly, close to the finale
## arena, exactly where `_apply_recovery_current`'s own current already
## watches for a fall. This is the map-wide backstop underneath that, not a
## replacement for it.
func _recovery_target() -> CharacterBody3D:
	return player


## `last_safe` is finite only when the trainer was genuinely, recently
## standing on solid ground moments before the fall (`fall_recovery.gd`) --
## that case is corrected LOCALLY, a few metres, the same way
## `world_perimeter.gd` recovers a Meadows physics glitch rather than sending
## a long walk all the way home. Anything else -- a real plunge off the
## world, or a reading too old to trust -- goes through the exact
## nearest-camp/realm-entry ladder a real death already uses, by way of
## `recover_from_world_fall` above, rather than duplicating that ladder here.
func _on_world_fall(body: CharacterBody3D, last_safe: Vector3) -> void:
	if not is_instance_valid(body):
		return
	var riding := world.get_node_or_null(^"RidingController")
	if riding != null and bool(riding.call("is_mounted")) and riding.call("mount_body") == body:
		riding.call("dismount")
	if last_safe.is_finite():
		print("[cloudreach_fall_recovery] %s fell below the cloud sea -- returning to last safe ground" % body.name)
		body.global_position = last_safe
		body.velocity = Vector3.ZERO
		_settle_companion_beside(body)
	else:
		print("[cloudreach_fall_recovery] %s fell below the cloud sea with no fresh safe ground -- recovering to camp/realm entry" % body.name)
		recover_from_world_fall(body)


## The follower re-leashes on its own once it is more than `LEASH` metres
## away in XZ (`follower_creature.gd::_tick_follow`) -- but that check ignores
## Y entirely, so a companion left standing on a ledge directly above a
## trainer who just fell straight down reads as "close enough" and never
## moves. Only reachable from the local-recovery branch above: the ladder
## branch's own `_recover()` already repositions the ally beside wherever it
## respawns the trainer.
func _settle_companion_beside(body: CharacterBody3D) -> void:
	var companion: Node3D = director.call("ally_body") if director != null else null
	if is_instance_valid(companion) and companion != body:
		companion.global_position = body.global_position + Vector3(1.5, 0.0, 1.5)
		if companion is CharacterBody3D:
			companion.velocity = Vector3.ZERO


func restore_progression_from_game(_game: Node) -> void:
	_release_field_control()
	_traveler_revision = -1


func _exit_tree() -> void:
	for actor in _registered:
		if is_instance_valid(actor):
			actor.call("clear_environment_velocity_modifier", &"cloudreach_summit")
	_registered.clear()
