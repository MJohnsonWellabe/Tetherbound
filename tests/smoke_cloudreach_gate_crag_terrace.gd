extends "res://tests/smoke_cloudreach_continuous.gd"

## F40#1 `gate_crag_terrace_1113`: real-input walk from the Realm Gate Crag
## crown's north lawn up the terrace's five lips to its top. Skips (exit 0)
## while the flag is off, because the terrace is not built then.


func _run() -> void:
	var visual: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var cfg: Dictionary = (visual.get("landmass", {}) as Dictionary).get("gate_crag_terrace_1113", {})
	if not bool(cfg.get("enabled", false)):
		print("CLOUDREACH GATE CRAG TERRACE SKIP (flag off)")
		quit(0)
		return
	Engine.time_scale=8.0
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	output_dir="user://gate-crag-terrace-smoke"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game=root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm="cloudreach"
	game.progression.set_flag("realm_key_cloudreach")
	for species: String in ["sparkit","mudsnout","bramblebun","terrapup","brooktail"]:
		game.party.add(SPECIES.spawn(species))
	world=SCENE.instantiate()
	root.add_child(world)
	current_scene=world
	player=world.get_node("Player")
	runtime=world.get_node("CloudreachRuntime")
	chapter=world.get_node("CloudreachChapter")
	physical=chapter.get_node("PhysicalRuntime")
	director=runtime.director
	manager=runtime.manager
	await _frames(20)
	var start:=Vector3(0.0,150.3,-112.0)
	player.global_position=start
	player.velocity=Vector3.ZERO
	last_position=start
	physics_frame.connect(_record_frame)
	stage="gate_crag_lawn_to_terrace_top"
	await _frames(20)
	var tiers := int(cfg.get("tiers", 3))
	var centre: Array = cfg.get("centre_xz", [0.0, 0.0])
	var shift: Array = cfg.get("tier_shift_xz", [0.0, 0.0])
	var top_y := 150.0 + 0.10 + float(cfg.get("lip_m", 0.32)) * float(tiers)
	var target:=Vector3(float(centre[0]) + float(shift[0]) * float(tiers), top_y,
		-130.0 + float(centre[1]) + float(shift[1]) * float(tiers))
	var arrived:=await _walk(target)
	_require(arrived,"Real stick walked from the lawn to the terrace top")
	_require(player.is_on_floor(),"Player is grounded on the terrace")
	_require(player.global_position.y > top_y - 0.2,
		"Player stands on the top tier (y %.2f, top %.2f)" % [player.global_position.y, top_y])
	var ground := float(world.call("ground_height_at", target.x, target.z)) \
		if world.has_method("ground_height_at") else NAN
	print("terrace ground_height_at top = %s (top %.2f)" % [ground, top_y])
	_release()
	print("CLOUDREACH GATE CRAG TERRACE %s from=%s to=%s distance_m=%.1f"%[
		"FAIL" if failed else "PASS",start,player.global_position,distance_m])
	quit(1 if failed else 0)
