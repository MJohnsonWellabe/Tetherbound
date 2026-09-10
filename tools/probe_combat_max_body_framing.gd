extends SceneTree

## Measurement-only native probe for the production combat camera's largest
## installed creature bodies. It uses the real world, CameraRig, Camera3D,
## CombatManager framing functions and CreatureBody meshes. No debug boxes and
## no acceptance constants: the first run records projected bounds so a later
## correction can be derived from actual overflow.
##
## godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##   --script tools/probe_combat_max_body_framing.gd

const WORLD := preload("res://scenes/world/meadows_playground.tscn")
const CREATURE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const GAPS: Array[float] = [5.0, 11.0]
const OUT := "res://.artifacts/creature-pipeline-0910/max-body-framing"
const VIEWPORT_SIZE := Vector2i(1280, 720)


func _init() -> void:
	_run()


func _run() -> void:
	root.size = VIEWPORT_SIZE
	if root.size != VIEWPORT_SIZE:
		push_error("max-body framing probe could not set %s viewport; got %s" % [VIEWPORT_SIZE, root.size])
		quit(1)
		return
	var output := OUT
	var argv := OS.get_cmdline_user_args()
	if argv.size() >= 2 and argv[0] == "--out":
		output = str(argv[1])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var world := WORLD.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	var ready := false
	for i in 1200:
		if _world_ready(world):
			ready = true
			break
		await physics_frame
	if not ready:
		push_error("max-body framing probe timed out waiting for production world nodes and finite ground")
		quit(1)
		return
	var player := world.get_node(^"Player") as Node3D
	var rig := world.get_node(^"CameraRig") as SpringArm3D
	var camera := rig.get_node(^"Camera3D") as Camera3D
	var manager := world.get_node(^"CombatManager")
	if player == null or rig == null or camera == null or manager == null:
		push_error("max-body framing probe could not resolve production nodes")
		quit(1)
		return

	var ally := CREATURE.instantiate() as Node3D
	var enemy := CREATURE.instantiate() as Node3D
	ally.set_script(CREATURE_BODY)
	enemy.set_script(CREATURE_BODY)
	world.add_child(ally)
	world.add_child(enemy)
	await process_frame
	ally.call("setup", "abyssal_guardian", false)
	enemy.call("setup", "solmane", false)
	_freeze_body(ally)
	_freeze_body(enemy)
	# Measured open road in Band 2, far from the village houses, Warrens and
	# Stronghold room claims. The first retained run used player+8 at the village
	# spawn and the spring arm collapsed to 2.1m against nearby construction.
	var player_at := Vector3(20.0, 0.0, 2120.0)
	player_at.y = float(world.call("ground_height_at", player_at.x, player_at.z)) + 1.0
	player.global_position = player_at
	var origin := Vector3(20.0, 0.0, 2125.0)
	origin.y = float(world.call("ground_height_at", origin.x, origin.z))
	ally.global_position = origin
	enemy.global_position = origin + Vector3(GAPS[0], 0.0, 0.0)

	manager.set("_player", player)
	manager.set("_ally_body", ally)
	manager.set("_wild", enemy)
	manager.set("_camera_rig", rig)
	manager.set("_camera_framing_extra", 0.0)
	manager.call("_open_arena")
	if manager.get("_arena") == null or not is_instance_valid(manager.get("_arena")):
		push_error("max-body framing probe could not create the production arena")
		quit(1)
		return
	rig.call("set_target", ally, manager.call("_combat_camera_profile"))

	for gap in GAPS:
		enemy.global_position = origin + Vector3(gap, 0.0, 0.0)
		for i in 240:
			manager.call("_update_combat_camera_framing", 1.0 / 60.0)
			await physics_frame
		var ally_rect := _projected_rect(ally, camera)
		var enemy_rect := _projected_rect(enemy, camera)
		var union := ally_rect.merge(enemy_rect)
		var viewport_size := camera.get_viewport().get_visible_rect().size
		var hud_rects := _visible_hud_rects(world, viewport_size)
		print("MAX BODY FRAMING gap=%.1f desired=%.3f spring=%.3f clearance=%.3f fov=%.1f viewport=%s ally=%s enemy=%s union=%s normalized=%s behind=%d" % [
			gap, float(rig.get("_distance")), rig.spring_length,
			float(manager.call("_room_clearance")), camera.fov, viewport_size,
			ally_rect, enemy_rect, union,
			Rect2(union.position / viewport_size, union.size / viewport_size),
			_count_behind(ally, camera) + _count_behind(enemy, camera)])
		print("MAX BODY HUD gap=%.1f occupied=%s" % [gap, hud_rects])
		await RenderingServer.frame_post_draw
		var shot := camera.get_viewport().get_texture().get_image()
		var shot_path := "%s/gap-%02d.png" % [output, int(gap)]
		var save_error := shot.save_png(ProjectSettings.globalize_path(shot_path))
		if save_error != OK:
			push_error("could not save %s: %s" % [shot_path, error_string(save_error)])
			quit(1)
			return

	ally.queue_free()
	enemy.queue_free()
	quit(0)


func _projected_rect(body: Node3D, camera: Camera3D) -> Rect2:
	var rect := Rect2()
	var first := true
	for child in body.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null or not mesh_instance.is_visible_in_tree():
			continue
		var bounds := mesh_instance.mesh.get_aabb()
		for corner in _corners(bounds):
			var point := camera.unproject_position(mesh_instance.global_transform * corner)
			if first:
				rect = Rect2(point, Vector2.ZERO)
				first = false
			else:
				rect = rect.expand(point)
	return rect


func _count_behind(body: Node3D, camera: Camera3D) -> int:
	var count := 0
	for child in body.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null or not mesh_instance.is_visible_in_tree():
			continue
		for corner in _corners(mesh_instance.mesh.get_aabb()):
			if camera.is_position_behind(mesh_instance.global_transform * corner):
				count += 1
	return count


func _corners(bounds: AABB) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for x in [0.0, 1.0]:
		for y in [0.0, 1.0]:
			for z in [0.0, 1.0]:
				out.append(bounds.position + bounds.size * Vector3(x, y, z))
	return out


func _visible_hud_rects(world: Node, viewport_size: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var paths := [
		^"PlaygroundHUD/Root/BottomDock", ^"PlaygroundHUD/Root/PartyStrip",
		^"PlaygroundHUD/Root/VitalsCluster", ^"PlaygroundHUD/Root/PlayerHealthBar",
		^"PlaygroundHUD/Root/Minimap", ^"PlaygroundHUD/Root/ObjectiveBlock",
		^"PlaygroundHUD/Root/DaytimeReadout", ^"CombatHUD/Root/AllyPlate",
		^"CombatHUD/Root/EnemyPlate", ^"CombatHUD/Root/Prompt"]
	for path in paths:
		var control := world.get_node_or_null(path) as Control
		if control == null or not control.is_visible_in_tree() \
				or control.size.x <= 1.0 or control.size.y <= 1.0:
			continue
		var rect := control.get_global_rect()
		if rect.intersects(Rect2(Vector2.ZERO, viewport_size)):
			out.append({"path": str(control.get_path()), "rect": rect})
	return out


func _freeze_body(body: Node3D) -> void:
	body.set_process(false)
	body.set_physics_process(false)
	body.set_process_input(false)
	body.set_process_unhandled_input(false)
	for child in body.find_children("*", "AnimationPlayer", true, false):
		(child as AnimationPlayer).stop()


func _world_ready(world: Node) -> bool:
	if not is_instance_valid(world) or not world.is_node_ready():
		return false
	# Same production-completion seam used by the representative Meadows HUD
	# capture: these nodes are built after terrain/scatter, and a finite ground
	# query rejects the earlier UI-only frame.
	for path in [^"Village", ^"Props", ^"BuildPlacer"]:
		if world.get_node_or_null(path) == null:
			return false
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if player == null or hud == null or not hud.is_node_ready() or not hud.visible:
		return false
	var height := float(world.call("ground_height_at", -15.0, -1.0))
	return is_finite(height)
