extends SceneTree

## F07#0: production-camera frames of the Observatory latch stair, closed and
## open. Needs a display:
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tests/probe_cloudreach_latch_capture.gd -- --out=<dir>

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const LATCH := "side_observatory_latch_complete"
const FLAGS: Array[String] = ["cloudreach_chapter_started", "fly_traversal_unlocked", "sky_shrine_reached",
	"cloudreach_upper_route_unlocked", "cloudreach_act_ii_complete", "storm_anchor_upper_west_disabled",
	"storm_anchor_upper_east_disabled", "cloudreach_upper_anchors_disabled", "side_observatory_latch_sighted"]
## [label, trainer position, point the camera faces, latch thrown]
const SHOTS := [
	["fork_looking_up_closed", Vector3(-176.0, 900.0, 4712.0), Vector3(-520.0, 1080.0, 5300.0), false],
	["top_at_latch_closed", Vector3(-512.0, 1080.0, 5306.0), Vector3(-180.0, 900.0, 4720.0), false],
	["top_at_latch_open", Vector3(-512.0, 1080.0, 5306.0), Vector3(-180.0, 900.0, 4720.0), true],
	["on_stair_descending", Vector3(-400.0, 1017.0, 5095.0), Vector3(-180.0, 900.0, 4720.0), true],
	["fork_looking_up_open", Vector3(-176.0, 900.0, 4712.0), Vector3(-520.0, 1080.0, 5300.0), true],
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://latch_capture"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	for flag: String in FLAGS:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(30, PROGRESSION.config())
		game.party.add(member)
	game.set("current_realm", "cloudreach")
	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 60:
		await process_frame
	var player: CharacterBody3D = world.get_node("Player")
	var rig: Node = world.get_node("CameraRig")
	var shots: Array = []
	for shot: Array in SHOTS:
		if bool(shot[3]) and not game.progression.has(LATCH):
			game.progression.set_flag(LATCH)
			for _frame in 10:
				await process_frame
		var at: Vector3 = shot[1]
		var ground := float(world.call("ground_height_near", at))
		player.global_position = Vector3(at.x, (ground if is_finite(ground) else at.y) + 0.2, at.z)
		player.velocity = Vector3.ZERO
		var face: Vector3 = shot[2]
		var yaw := atan2(-(face.x - at.x), -(face.z - at.z))
		player.rotation.y = yaw
		if rig.has_method("snap_behind"):
			rig.call("snap_behind")
		elif "yaw" in rig:
			rig.set("yaw", yaw)
		for _frame in 90:
			await process_frame
		await RenderingServer.frame_post_draw
		var path := out.path_join("%s.png" % str(shot[0]))
		root.get_texture().get_image().save_png(path)
		shots.append({"label": shot[0], "player": str(player.global_position), "ground": ground, "file": path})
	print("LATCH CAPTURE " + JSON.stringify(shots))
	quit(0)
