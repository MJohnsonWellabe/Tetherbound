extends "res://tests/smoke_cloudreach_continuous.gd"

## Capture the shipped captain challenge through real interaction and the
## installed live-input pilot. This is an evidence fixture, not progression
## proof: summit flags and a legal five-creature party are seeded in memory.

const FIGHT_ID := "captain_veyra_storm_anchor"
const MANIFEST_WRITER := preload("res://tools/capture_manifest_writer.gd")
## Same native world-build bound as capture_cloudreach_frame_matrix.gd.
const BOOT_MAX_SECONDS := 600.0
var _phase2_output := "res://ralph/reports/VISUAL/phase2/cloudreach/fight_live_main"
var _phase2_seed := 2042
var _phase2_frames: Array[Dictionary] = []
var _phase2_last_sample := -999999
var _phase2_shot_pending := false


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_phase2_output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="):
			_phase2_seed = int(arg.trim_prefix("--seed="))
	if not _phase2_output.begins_with("res://ralph/reports/VISUAL/phase2/cloudreach/"):
		push_error("Cloudreach fight output must stay under Phase 2 evidence")
		quit(1)
		return
	seed(_phase2_seed)
	start_usec = Time.get_ticks_usec()
	output_dir = _phase2_output
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		failed = true
		push_error("Cloudreach fight output directory cannot be created")
		quit(1)
		return
	root.size = Vector2i(1920, 1080)
	live_combat = true
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "cloudreach"
	for flag: String in ["realm_key_cloudreach", "cloudreach_upper_route_unlocked", "cloudreach_act_ii_complete", "cloudreach_upper_anchors_disabled"]:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(_fixture_level(), PROGRESSION.config())
		game.party.add(member)
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	# Production _ready yields during its build before mounting chapter/combat.
	# Reuse the realm-entry completion seam, not a fixed settling frame count.
	var boot_started := Time.get_ticks_msec()
	while is_instance_valid(world) and current_scene == world \
			and Time.get_ticks_msec() - boot_started < int(BOOT_MAX_SECONDS * 1000.0) \
			and not bool(game.call("_realm_scene_ready", world, "cloudreach")):
		await process_frame
	if not _require(is_instance_valid(world) and current_scene == world \
			and bool(game.call("_realm_scene_ready", world, "cloudreach")), "Production Cloudreach world finished mounting"):
		_write_manifest()
		quit(1)
		return
	player = world.get_node_or_null("Player") as CharacterBody3D
	runtime = world.get_node_or_null("CloudreachRuntime")
	chapter = world.get_node_or_null("CloudreachChapter")
	if not _require(player != null and runtime != null and chapter != null \
			and runtime.get("_mounted") == true and runtime.get("world") == world \
			and runtime.get("chapter") == chapter and chapter.has_method("physical_runtime"), "Production Cloudreach runtime/chapter bindings"):
		_write_manifest()
		quit(1)
		return
	physical = chapter.call("physical_runtime") as Node
	director = runtime.get("director") as Node
	manager = runtime.get("manager") as Node
	fly = player.get("fly_controller") as Node
	var rig := world.get_node_or_null("CameraRig") as Node3D
	var arbiter := world.get_node_or_null("InteractionArbiter")
	if not _require(physical != null and physical.get_parent() == chapter \
			and director != null and director == world.get_node_or_null("EncounterDirector") \
			and manager != null and manager == world.get_node_or_null("CombatManager") \
			and fly != null and rig != null and arbiter != null and arbiter.has_signal("activated"), "Production Cloudreach fight/input bindings"):
		_write_manifest()
		quit(1)
		return
	combat_pilot = BALANCE.InputPilot.new(self, manager, director, rig)
	combat_pilot.pilot = PILOT.Pilot.SPACER
	combat_pilot.switch_input = true
	combat_pilot.use_switching = false
	combat_pilot.listen()
	arbiter.activated.connect(func(provider: Object) -> void:
		interaction_activations += 1
		last_activated_path = str(provider.get_path()))
	director.trainer_started.connect(func(id: String) -> void: battle_starts.append(id))
	director.trainer_victory.connect(func(id: String) -> void: battle_wins.append(id))
	director.trainer_lost.connect(func(id: String) -> void: battle_losses.append(id))
	await _frames(20)
	var start := Vector3(100.0, 1160.06, 5350.0)
	player.global_position = start
	player.velocity = Vector3.ZERO
	last_position = start
	physics_frame.connect(_record_frame)
	physics_frame.connect(_sample_fight)
	stage = "captain_phase2_approach"
	await _frames(30)
	if not _require(_has("summit_extraction_engine_reached"), "Summit event relocated captain"):
		_write_manifest()
		quit(1)
		return
	var won := await _battle(FIGHT_ID)
	await _frames(30)
	await _shot("aftermath")
	_write_manifest()
	print("PHASE2 CLOUDREACH FIGHT won=%s captures=%d" % [str(won), _phase2_frames.size()])
	quit(0 if won and not failed and not _phase2_frames.is_empty() else 1)


func _sample_fight() -> void:
	if not is_instance_valid(director) or not director.trainer_battle_active():
		return
	var now := Engine.get_physics_frames()
	if _phase2_shot_pending or now - _phase2_last_sample < 180:
		return
	_phase2_last_sample = now
	_phase2_shot_pending = true
	_shot.call_deferred("live-%04d" % now)


func _fixture_level() -> int:
	return 25


func _capture(label: String) -> void:
	await _shot(label)


func _shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		failed = true
		_phase2_shot_pending = false
		return
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [output_dir, label]
	var captured := root.get_texture().get_image()
	var result := captured.save_png(path)
	var persisted := Image.new()
	if result == OK:
		result = persisted.load(path)
	if result == OK and persisted.get_size() == root.size:
		_phase2_frames.append({"id": label, "file": path, "stage": stage,
			"simulated_seconds": simulated_seconds, "fighting": manager.is_fighting(),
			"trainer_battle_active": director.trainer_battle_active()})
	else:
		failed = true
		push_error("Cloudreach fight PNG persistence/raster failed: " + path)
	_phase2_shot_pending = false


func _write_manifest() -> void:
	if _phase2_frames.is_empty():
		failed = true
	var manifest := {"biome": "cloudreach", "category": "systems", "system": "fight",
		"fight_id": FIGHT_ID,
		"seed": _phase2_seed, "scene": "res://scenes/world/cloudreach_cliffs.tscn",
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"resolution": [root.size.x, root.size.y],
		"fixture": "In-memory summit progression flags and five level-25 creatures; production captain challenge and live controller-input combat pilot",
		"frames": _phase2_frames, "victory": FIGHT_ID in battle_wins,
		"failure": failed, "complete": FIGHT_ID in battle_wins and not failed and not _phase2_frames.is_empty()}
	var path := output_dir.path_join("manifest.json")
	if MANIFEST_WRITER.write_json(path, manifest) != OK \
			or FileAccess.get_file_as_string(path) != JSON.stringify(manifest, "\t") + "\n":
		failed = true
		push_error("Cloudreach fight manifest persistence/readback failed")
