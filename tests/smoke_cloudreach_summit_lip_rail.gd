extends "res://tests/smoke_cloudreach_continuous.gd"

## Summit bivouac lip rail (#356 11:20). Fixture start (disclosed): summit
## flags, a level-30 retained five, the trainer placed at the camp. Ordinary
## stick input then (1) walks straight at the south lip and must stay on the
## terrace, and (2) leaves the camp through the exit band to the arena
## threshold with the continuous harness's own `_leave_summit_bivouac`.
##
##   godot --headless --path . --script tests/smoke_cloudreach_summit_lip_rail.gd

const CAMP := Vector3(132.0, 1160.0, 5342.0)
const FLAGS: Array[String] = ["realm_key_cloudreach", "fly_traversal_unlocked", "cloudreach_upper_route_unlocked",
	"cloudreach_act_ii_complete", "storm_anchor_upper_west_disabled", "storm_anchor_upper_east_disabled",
	"cloudreach_upper_anchors_disabled", "storm_anchor_summit_feed_disabled"]
## Straight lines from the camp over the lip, down the ~8 m bank to the road.
const OVER_THE_LIP: Array[Vector3] = [Vector3(133.0, 1152.0, 5322.0), Vector3(138.0, 1152.0, 5318.0), Vector3(143.0, 1150.0, 5314.0)]


func _run() -> void:
	start_usec = Time.get_ticks_usec()
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	accelerated = true
	output_dir = "user://summit_lip_rail"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = root.get_node("Game")
	game.reset_for_new_game()
	for flag: String in FLAGS:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(30, PROGRESSION.config())
		game.party.add(member)
	game.current_realm = "cloudreach"
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.physical_runtime()
	runtime = world.get_node("CloudreachRuntime")
	director = runtime.director
	manager = runtime.manager
	fly = player.fly_controller
	physics_frame.connect(_record_frame)
	await _frames(30)
	var report := {}
	var rail := physical.get_node_or_null(^"summit_bivouac/CampLipRail")
	report["rail_built"] = rail != null
	report["rail_panels"] = 0 if rail == null else rail.find_children("RailPanel*", "", false, false).size()
	var lowest := INF
	for target: Vector3 in OVER_THE_LIP:
		_stand(CAMP + Vector3(0.0, 0.0, -8.0))
		await _frames(20)
		failed = false
		await _walk(target, 0.75)
		_release()
		await _frames(20)
		lowest = minf(lowest, player.global_position.y)
	report["lowest_after_lip_walks"] = snappedf(lowest, 0.01)
	report["stayed_on_terrace"] = lowest > 1158.0
	_stand(CAMP)
	await _frames(20)
	failed = false
	report["left_through_band"] = await _leave_summit_bivouac()
	report["end"] = str(player.global_position)
	var ok: bool = bool(report.rail_built) and int(report.rail_panels) >= 4 and bool(report.stayed_on_terrace) \
		and bool(report.left_through_band)
	print("SUMMIT LIP RAIL " + JSON.stringify(report))
	print("SUMMIT LIP RAIL %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _stand(at: Vector3) -> void:
	var ground := float(world.call("ground_height_near", at))
	player.global_position = Vector3(at.x, (ground if is_finite(ground) else at.y) + 1.2, at.z)
	player.velocity = Vector3.ZERO
