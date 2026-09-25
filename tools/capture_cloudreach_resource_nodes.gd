extends SceneTree

## Evidence frames for the F07 resource-node move: each moved gatherable as the
## trainer sees it from the walking route, through the production camera.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_cloudreach_resource_nodes.gd -- --tag=after
##
## Run it once on main (`--tag=before`) and once on the branch (`--tag=after`).
## The frames stand the trainer wherever the RUNTIME put the node (the scene's
## own node, not the authored data), so main's frames show where main actually
## snapped each node and the branch's show where it is now.
##
## Disclosed fixture: the upper-route unlock flag is seeded so the gated
## regions' nodes are in the world; the trainer is stood at a probed spot on a
## ring around the node (standable floor, clear capsule, line of sight from the
## camera's height) and the rig is aimed a little off-axis so the trainer does
## not hide the node.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const LANE := preload("res://tools/capture_cloudreach_lane_common.gd")
const OUT := "res://ralph/reports/CLOUDREACH-LANE/captures/resource_nodes"
const NODES := [
	"cr_node_cliffglass_ravine",
	"cr_node_cloudberry_cliffhold",
	"cr_node_cliffglass_observatory",
	"cr_node_cliffglass_summit",
]

var _world: Node3D
var _player: CharacterBody3D
var _rig: Node
var _frames: Array = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var tag := "after"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			tag = arg.trim_prefix("--tag=")
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	for species: String in ["galecrest", "bramblebun", "mudsnout", "terrapup", "brooktail"]:
		(game.get("party") as RefCounted).call("add", SPECIES.spawn(species))
	var flags: RefCounted = game.get("progression")
	for flag: String in ["realm_key_cloudreach", "cloudreach_chapter_started", "cloudreach_crisis_learned",
			"fly_traversal_unlocked", "cloudreach_upper_route_unlocked"]:
		flags.call("set_flag", flag)
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig")
	for i in 600:
		await process_frame
		if _world.get_node_or_null(^"EncounterDirector") != null and i > 20:
			break
	await _frames_wait(20)
	for id: String in NODES:
		var node := _find_node(id)
		if node == null:
			push_error("capture: no scene node for %s" % id)
			continue
		var at := node.global_position
		var stand := _probe_stand(at)
		print("NODE %s %s at=%s stand=%s" % [tag, id, at, stand])
		if stand == Vector3.INF:
			push_error("capture: no clear stand near %s" % id)
			continue
		await _stand_and_look(stand, at)
		LANE.save_frame(self, "%s/%s" % [OUT, tag], "%s_%s" % [tag, id], _frames)
	LANE.contact_sheet(_frames, "%s/_sheet_resource_nodes_%s.png" % [OUT, tag], 2)
	quit(0)


## The runtime's gatherable for `id`: the interactable the trainer can press,
## wherever the world placed it.
func _find_node(id: String) -> Node3D:
	var found := _world.find_child(id, true, false)
	return found as Node3D


func _probe_stand(at: Vector3) -> Vector3:
	var space := _world.get_world_3d().direct_space_state
	for radius: float in [5.0, 7.0, 4.0, 9.0]:
		for step in 16:
			var angle := TAU * float(step) / 16.0
			var probe := at + Vector3(cos(angle), 0.0, sin(angle)) * radius
			var down := PhysicsRayQueryParameters3D.create(probe + Vector3.UP * 4.0, probe + Vector3.DOWN * 6.0)
			down.collision_mask = 1
			var hit := space.intersect_ray(down)
			if hit.is_empty() or (hit.normal as Vector3).y < cos(deg_to_rad(40.0)):
				continue
			var feet: Vector3 = hit.position
			var eye := feet + Vector3.UP * 1.6
			var look := PhysicsRayQueryParameters3D.create(eye, at + Vector3.UP * 0.6)
			look.collision_mask = 1
			if not space.intersect_ray(look).is_empty():
				continue
			return feet
	return Vector3.INF


func _stand_and_look(at: Vector3, target: Vector3, off_axis_deg: float = 16.0) -> void:
	_player.global_position = at + Vector3.UP * 0.3
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", LANE.yaw_towards(_player.global_position, target) + deg_to_rad(off_axis_deg))
	_rig.set("pitch", deg_to_rad(-14.0))
	await _frames_wait(30)


func _frames_wait(count: int) -> void:
	for i in count:
		await process_frame
