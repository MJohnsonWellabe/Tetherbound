extends SceneTree
const SAVE := preload("res://scripts/save/save_game.gd")
const BUILD := preload("res://scripts/world/water_scene_encounters.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CATALOG := preload("res://scripts/creatures/water_species_catalog.gd")
class PeerFixture:
	extends Node3D
	var net_realm := "water"
var checks := 0
var failures := 0
func _init() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)
func run() -> void:
	await process_frame
	var game: Node = root.get_node("Game")
	game.set("save_system", SAVE.new("user://water_scene_encounters_%d" % OS.get_process_id()))
	game.current_realm = "water"
	var translated := CATALOG.merge_catalogue(SPECIES.table())
	check(bool(translated.ok), "Water catalogue fixture validates")
	SPECIES.table().merge(translated.catalogue, true)
	game.local.party.add(SPECIES.spawn("water_mosshell"))
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	while not world.call("shell_build_complete"):
		await process_frame
	var player: Node3D = world.get_node("Player")
	player.set_physics_process(false)
	var chapter: Node = world.get_node("WaterChapter")
	var director: Node = BUILD.build(world, chapter.npc_bodies)
	var manager: Node = world.get_node("CombatManager")
	var arbiter: Node = world.get_node("InteractionArbiter")
	var hud: Node = world.get_node_or_null("CombatHUD")
	check(hud != null, "Actual Water scene supplies the shipped CombatHUD")
	if hud == null:
		quit(1)
		return
	check(hud.get("_manager") == manager and hud.get("_director") == director, "CombatHUD binds the actual Water manager and director")
	check(director.get("_arbiter") == arbiter and arbiter.get("_provider_set").has(director), "Water director registers with the shared interaction arbiter")
	check(BUILD.build(world, chapter.npc_bodies) == director and world.get_node("CombatHUD") == hud, "Repeated build retains the director and HUD identities")
	var hud_count := 0
	for child in world.get_children():
		if child.get_script() == hud.get_script():
			hud_count += 1
	check(hud_count == 1, "Repeated build creates no duplicate combat canvas")
	for _frame in 30:
		await process_frame
	check(director.trainer_nodes.size() == 24, "All 24 physical trainers")
	var reused := 0
	for id: String in director.trainer_specs:
		var spec: Dictionary = director.trainer_specs[id]
		if not str(spec.reuse_npc_id).is_empty():
			reused += 1
			check(director.trainer_nodes[id] == chapter.npc_bodies[spec.reuse_npc_id], "Reused trainer keeps greeting body")
			check(director.trainer_prompts[id] != director.trainer_nodes[id].call("prompt_node"), "Challenge is distinct from greeting")
	check(reused == 3, "Three shared trainer NPCs")
	# Teleport fixture to a real dry authored encounter, then production spawn.
	var site: Dictionary = director.encounter_config.wild_sites[0]
	player.global_position = Vector3(float(site.position[0]), float(site.position[1]), float(site.position[2]))
	for _frame in 30:
		await process_frame
	check(not director._wild_creatures.is_empty(), "Actual production wild bodies spawn")
	for wild: Node3D in director._wild_creatures:
		check(wild.instance != null and str(wild.instance.species_id).begins_with("water_"), "Wild body carries Water instance")
	# Remote proxy fixture exercises the live director's same cross-island input.
	var remote := PeerFixture.new()
	world.add_child(remote)
	remote.add_to_group("remote_trainer")
	var remote_site: Dictionary = {}
	for candidate: Dictionary in director.encounter_config.wild_sites:
		if str(candidate.id).begins_with("water_salt_crown_"):
			remote_site = candidate
			break
	check(not remote_site.is_empty(), "Distant island encounter fixture exists")
	if not remote_site.is_empty():
		for flag: String in remote_site.get("requires_flags", []):
			game.world.flags.set_flag(flag)
		var table: Dictionary = director.find_id(director.chapter.encounter_tables, str(remote_site.table_id))
		var unlock := str(table.get("requires_unlock", ""))
		if not unlock.is_empty():
			game.world.flags.set_flag(unlock)
		remote.global_position = Vector3(float(remote_site.position[0]), float(remote_site.position[1]), float(remote_site.position[2]))
		for _frame in 10:
			await process_frame
		check(director.occupied_positions().size() == 2, "Both distant Water neighborhoods included")
		var distant_count := 0
		for wild: Node3D in director._wild_creatures:
			if wild.global_position.distance_to(remote.global_position) < 100:
				distant_count += 1
		check(distant_count > 0, "Actual wild bodies populate remote island while local stays on First Shore")
		remote.net_realm = "stormwood"
		check(director.occupied_positions().size() == 1, "Other realm proxy excluded")
	remote.queue_free()
	var id := "water_trainer_lysa"
	if not director.trainer_nodes.has(id):
		check(false, "Lysa trainer fixture exists")
	else:
		var spec: Dictionary = director.trainer_specs[id]
		for flag: String in spec.get("requires_flags", []):
			game.world.flags.set_flag(flag)
		player.global_position = director.trainer_nodes[id].global_position + Vector3(1.5, 0, 0)
		check(await director.summon_active_creature(), "Production summon deploys owned ally")
		# Diagnostic pose only: inspect the actual wild offer through the shared
		# arbiter before starting the existing authored trainer fixture.
		var trainer_pose := player.global_position
		var nearby: Node3D = director._wild_creatures[0] if not director._wild_creatures.is_empty() else null
		check(nearby != null, "An actual wild body is available for the Engage display check")
		if nearby != null:
			player.global_position = nearby.global_position + Vector3(0.8, 0, 0)
			arbiter._recompute()
			hud._process(0.0)
			check(arbiter.winning_provider() == director and "Engage " in str(arbiter.prompt()), "Actual wild Engage offer wins the Water arbiter")
			check(hud.get("_prompt").is_visible_in_tree() and "Engage " in str(hud.get("_prompt").text), "CombatHUD visibly presents the actual Engage prompt")
			player.global_position = trainer_pose
		director._process(0.0)
		director._challenge(id)
		check(director.trainer_battle_id() == id, "Production trainer challenge starts battle")
		check(director._trainer_body != null and director._trainer_body.trainer_owned, "Actual trainer-owned opponent spawned")
		for frame in 3:
			await process_frame
		check(manager.is_fighting() and hud.get("_enemy_panel").is_visible_in_tree() and hud.get("_ally_panel").is_visible_in_tree(), "Actual Water fight shows both combatant panels")
		check(not str(hud.get("_enemy_name").text).is_empty() and not str(hud.get("_ally_name").text).is_empty(), "Combat panels display actual creature names")
		check(float(hud.get("_enemy_health").value) > 0 and float(hud.get("_ally_health").value) > 0, "Combat panels display living creature health")
		check(hud.get("_grid_panel").is_visible_in_tree() and not str(hud.get("_cell_quick_content").text).is_empty(), "Actual Water fight displays its move controls")
	await capture_if_requested(world)
	print("Water encounter smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)





# Optional rendered evidence of this same explicitly synthetic scene fixture.
func capture_if_requested(world: Node3D) -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			await RenderingServer.frame_post_draw
			var path := argument.trim_prefix("--capture=")
			check(world.get_viewport().get_texture().get_image().save_png(path) == OK, "Rendered actual Water fight HUD saved")
