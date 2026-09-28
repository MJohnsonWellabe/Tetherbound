extends "res://tests/smoke_cloudreach_continuous.gd"

## Capture the shipped captain challenge through real interaction and the
## installed live-input pilot. This is an evidence fixture, not progression
## proof: summit flags and a legal five-creature party are seeded in memory.

const FIGHT_ID := "captain_veyra_storm_anchor"
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
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1920, 1080)
	live_combat = true
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "cloudreach"
	for flag: String in ["realm_key_cloudreach", "cloudreach_upper_route_unlocked", "cloudreach_act_ii_complete", "cloudreach_upper_anchors_disabled"]:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(25, PROGRESSION.config())
		game.party.add(member)
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	runtime = world.get_node("CloudreachRuntime")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.get_node("PhysicalRuntime")
	director = runtime.director
	manager = runtime.manager
	fly = player.fly_controller
	combat_pilot = BALANCE.InputPilot.new(self, manager, director, world.get_node("CameraRig"))
	combat_pilot.pilot = PILOT.Pilot.SPACER
	combat_pilot.switch_input = true
	combat_pilot.use_switching = false
	combat_pilot.listen()
	world.get_node("InteractionArbiter").activated.connect(func(provider: Object) -> void:
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
	quit(0 if won else 1)


func _sample_fight() -> void:
	if not is_instance_valid(director) or not director.trainer_battle_active():
		return
	var now := Engine.get_physics_frames()
	if _phase2_shot_pending or now - _phase2_last_sample < 180:
		return
	_phase2_last_sample = now
	_phase2_shot_pending = true
	_shot.call_deferred("live-%04d" % now)


func _capture(label: String) -> void:
	await _shot(label)


func _shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [output_dir, label]
	var result := root.get_texture().get_image().save_png(path)
	if result == OK:
		_phase2_frames.append({"id": label, "file": path, "stage": stage,
			"simulated_seconds": simulated_seconds, "fighting": manager.is_fighting(),
			"trainer_battle_active": director.trainer_battle_active()})
	_phase2_shot_pending = false


func _write_manifest() -> void:
	var manifest := {"biome": "cloudreach", "category": "systems", "system": "fight",
		"seed": _phase2_seed, "scene": "res://scenes/world/cloudreach_cliffs.tscn",
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"resolution": [root.size.x, root.size.y],
		"fixture": "In-memory summit progression flags and five level-25 creatures; production captain challenge and live controller-input combat pilot",
		"frames": _phase2_frames, "victory": FIGHT_ID in battle_wins,
		"failure": failed, "complete": FIGHT_ID in battle_wins and not _phase2_frames.is_empty()}
	var stream := FileAccess.open(output_dir + "/manifest.json", FileAccess.WRITE)
	if stream != null:
		stream.store_string(JSON.stringify(manifest, "\t") + "\n")
		stream.close()
