extends "res://tests/smoke_cloudreach_continuous.gd"

## Shrine-dais corner trap (#340, Cloudreach-B). A 2.2 m BOX collider on the
## west SkyPillar held a trainer standing on the dais at (1099.003, 1051.301,
## 2941.399) forever: every move with an x component was swept into the dais
## top beside the box's corner (never a wall, so no step-up or unwedge fired),
## and the same pillar filled the Fly companion's launch room there.
##
## On the production scene with the real controller:
##   1. both SkyPillars collide as cylinders;
##   2. the Fly launch-room query (`fly_controller.gd::launch_blockers`'
##      own shape) at the reported pose hits no SkyPillar;
##   3. from the reported pose the harness's ordinary `_walk` reaches the
##      reported target (1121.0, 1050.0, 2938.5), the dais route onward.
##
##   godot --headless --path . --script tests/smoke_cloudreach_shrine_dais.gd
##
## Prints `CLOUDREACH SHRINE DAIS {...}`; exit 0 on pass.

const POSE := Vector3(1099.003, 1051.301, 2941.399)
const TARGET := Vector3(1121.0, 1050.0, 2938.5)
const FLAGS: Array[String] = ["cloudreach_chapter_started", "fly_traversal_unlocked", "sky_shrine_reached"]


func _run() -> void:
	start_usec = Time.get_ticks_usec()
	output_dir = "user://cloudreach_shrine_dais"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = root.get_node("Game")
	game.reset_for_new_game()
	for flag: String in FLAGS:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(25, PROGRESSION.config())
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
	await _frames(20)
	var failures: Array[String] = []
	var shrine := world.find_child("SkyShrineHeartstone", true, false)
	var shapes: Array[String] = []
	if shrine == null:
		failures.append("SkyShrineHeartstone missing")
	else:
		# The second pillar's node name is auto-uniqued, so identify the
		# pillars by their 20 m collider: two cylinders, and no 2.2 m box left.
		for body: Node in shrine.find_children("Collision", "StaticBody3D", true, false):
			if body.get_child_count() == 0 or not body.get_child(0) is CollisionShape3D:
				continue
			var shape := (body.get_child(0) as CollisionShape3D).shape
			if shape is CylinderShape3D and absf((shape as CylinderShape3D).height - 20.0) < 0.01:
				shapes.append("CylinderShape3D r=%.2f" % (shape as CylinderShape3D).radius)
			elif shape is BoxShape3D and (shape as BoxShape3D).size.is_equal_approx(Vector3(2.2, 20.0, 2.2)):
				shapes.append("BoxShape3D")
				failures.append("a SkyPillar still collides as a 2.2 m box: " + str(body.get_path()))
	if shapes.size() != 2:
		failures.append("expected 2 SkyPillar colliders, found %s" % str(shapes))
	stage = "shrine_dais"
	player.global_position = POSE
	player.velocity = Vector3.ZERO
	await _frames(10)
	# The launch-room query exactly as `launch_blockers()` builds it.
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = fly.call("_flight_shape")
	query.transform = Transform3D(Basis.IDENTITY, POSE).translated(
		Vector3.UP * float(fly.get("config").get("collision_height_m", 4.5)) * 0.5)
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	var launch_hits: Array[String] = []
	for hit: Dictionary in player.get_world_3d().direct_space_state.intersect_shape(query, 8):
		var path := str((hit.collider as Node).get_path())
		launch_hits.append(path)
		if path.contains("SkyPillar"):
			failures.append("Fly launch room at the dais pose hits " + path)
	var walked := await _walk(TARGET)
	_release()
	if not walked or failed:
		failures.append("walking from the trapped pose did not reach " + str(TARGET))
	var result := {"verdict": "PASS" if failures.is_empty() else "FAIL", "pillar_shapes": shapes,
		"launch_room_hits": launch_hits, "walked_to_target": walked, "end": str(player.global_position),
		"failures": failures}
	print("CLOUDREACH SHRINE DAIS " + JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
