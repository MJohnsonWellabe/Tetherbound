extends SceneTree

## T1-CREATURE §15 continuation, coordinator's "then": Band 2 (Stone & Root /
## Old Quarry) is the most rock-heavy band outside Creek Hollow, so it is
## where a creature's silhouette is most likely to disappear into a rock
## background the same way Creek Hollow's water creatures disappeared into
## the pond. Same clear-vantage instrument as
## tools/_probe_creek_hollow_habitat.gd, pointed at the two band2 spawns
## nearest the Old Quarry's worked rock face (map_landmarks.json centre
## ~[400,1800]): order 2029 (burrowback, 438,1825) and order 2027
## (burrowback, 280,1660, the next-nearest).
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_band2_rock_silhouette.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/band2_rock_silhouette"
const SETTLE_FRAMES := 30
const PER_SHOT_SETTLE := 12
const EYE_HEIGHT := 1.7
const CLEAR_ENOUGH := 6.0

## [tag, spawn centre, cluster radius]
const POINTS := [
	["quarry-near-2029", Vector2(438.0, 1825.0), 6.0],
	["quarry-near-2027", Vector2(280.0, 1660.0), 6.0],
]


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for _i in SETTLE_FRAMES:
		await process_frame

	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
		look.set_process(false)
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)

	var field := HEIGHTFIELD.new(HEIGHTFIELD.load_config())
	var space: PhysicsDirectSpaceState3D = (world as Node3D).get_world_3d().direct_space_state

	var camera := Camera3D.new()
	camera.fov = 62.0
	camera.far = 2000.0
	root.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for point: Array in POINTS:
		var tag: String = point[0]
		var centre: Vector2 = point[1]
		var radius: float = point[2]
		var placement := _find_clear_vantage(space, field, centre, radius)
		var eye: Vector3 = placement[0]
		var look_at: Vector3 = placement[1]
		var clearance: float = placement[2]
		print("%s: clearance %.1fm" % [tag, clearance])
		camera.global_position = eye
		camera.look_at(look_at, Vector3.UP)
		if look != null:
			look.call("apply_time", "day")
		for _i in PER_SHOT_SETTLE:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image != null:
			image.save_png("%s/%s.png" % [OUT, tag])
			print("wrote %s/%s.png" % [OUT, tag])
	quit(0)


func _find_clear_vantage(space: PhysicsDirectSpaceState3D, field: RefCounted, centre: Vector2, radius: float) -> Array:
	var look_at := Vector3(centre.x, field.height_at(centre.x, centre.y) + 0.5, centre.y)
	var best_eye := Vector3.ZERO
	var best_clearance := -1.0
	var standoffs: Array[float] = [radius + 4.0, radius + 8.0, radius + 12.0]
	for standoff: float in standoffs:
		for bearing_deg in range(0, 360, 45):
			var bearing := deg_to_rad(float(bearing_deg))
			var offset: Vector2 = Vector2(cos(bearing), sin(bearing)) * standoff
			var pos: Vector2 = centre + offset
			var eye := Vector3(pos.x, field.height_at(pos.x, pos.y) + EYE_HEIGHT, pos.y)
			var to_target: Vector3 = look_at - eye
			var distance := to_target.length()
			if distance < 1.0:
				continue
			var query := PhysicsRayQueryParameters3D.create(eye, look_at)
			var hit := space.intersect_ray(query)
			var clearance: float = distance
			if not hit.is_empty():
				clearance = eye.distance_to(hit.position as Vector3)
			if clearance > best_clearance:
				best_clearance = clearance
				best_eye = eye
			if clearance >= CLEAR_ENOUGH:
				return [best_eye, look_at, best_clearance]
	return [best_eye, look_at, best_clearance]
