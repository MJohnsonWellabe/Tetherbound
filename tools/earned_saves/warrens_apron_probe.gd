extends SceneTree

## Read-only Warrens approach probe (CARD:M2 blocker, 13 Oct): prints the live
## entrance/mouth markers, the raised floor, the product ramp run, and along
## the mouth axis from the entrance outward the heightfield height and the top
## physics surface, so the staging pose can be put on the walkable apron.
## No save, no gameplay, nothing written.
##   godot --headless --path . --script tools/earned_saves/warrens_apron_probe.gd
const SCENE := "res://scenes/world/meadows_playground.tscn"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null("Game")
	if game != null:
		game.call("reset_for_new_game")
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	var warrens: Node3D
	for _i in 3600:
		await physics_frame
		warrens = world.get_node_or_null("BurrowWarrens") as Node3D
		if warrens != null and bool(warrens.get("_arena_definition_ready")):
			break
	if warrens == null:
		print("WARRENS PROBE no BurrowWarrens")
		quit(1)
		return
	for _i in 60:
		await physics_frame
	var entrance: Vector3 = warrens.call("marker", "entrance")
	var mouth: Vector3 = warrens.call("marker", "mouth")
	var run := float(warrens.call("_apron_run_m"))
	print("WARRENS PROBE origin=%s yaw=%.1f floor_y=%.2f ramp_run=%.2f outer_z=%.2f entrance=%s mouth=%s" % [
		warrens.global_position, rad_to_deg(warrens.global_rotation.y), float(warrens.get("_floor_y")), run,
		float(warrens.call("_mouth_outer_z")), entrance, mouth])
	var forward := mouth - entrance
	forward.y = 0.0
	forward = forward.normalized()
	var side := Vector3(forward.z, 0.0, -forward.x)
	var space := world.get_world_3d().direct_space_state
	var player := world.get_node_or_null("Player") as CollisionObject3D
	var exclude: Array[RID] = []
	if player != null:
		exclude.append(player.get_rid())
	for i in 29:
		var back := float(i)
		var line := "WARRENS PROBE back=%4.1f" % back
		for lateral: float in [-3.0, 0.0, 3.0]:
			var at := entrance - forward * back + side * lateral
			var h := float(world.call("ground_height_at", at.x, at.z))
			var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, h + 30.0, at.z), Vector3(at.x, h - 30.0, at.z))
			query.exclude = exclude
			var hit := space.intersect_ray(query)
			var top := (hit.position as Vector3).y if not hit.is_empty() else NAN
			var what := str((hit.collider as Node).name) if not hit.is_empty() and hit.collider is Node else "-"
			line += "  [lat %+.0f (%.1f,%.1f) h=%.2f top=%.2f %s]" % [lateral, at.x, at.z, h, top, what]
		print(line)
	quit(0)
