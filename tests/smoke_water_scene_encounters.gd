extends SceneTree
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
		check(director.summon_active_creature(), "Production summon deploys owned ally")
		director._process(0.0)
		director._challenge(id)
		check(director.trainer_battle_id() == id, "Production trainer challenge starts battle")
		check(director._trainer_body != null and director._trainer_body.trainer_owned, "Actual trainer-owned opponent spawned")
	print("Water encounter smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)



