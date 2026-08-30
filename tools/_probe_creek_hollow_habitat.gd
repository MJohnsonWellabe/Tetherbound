extends SceneTree

## CREATURE-PRESENTATION / §15+§7. Every habitat-tagged spawn cluster in Creek
## Hollow (data/config/bands/band1_lower_meadows/spawns.json orders 6-8 and
## 1018-1045), each shot from a plausible approach angle at standing eye
## height, so the claim in that file's own `_comment_creek_hollow` -- "the
## existing pond, mill, footbridge, ranger station, reed arcs, grove scatter
## and west-bank hollow provide the water edge, open bank, rocky/mill
## shoulder, grove and overhang equivalents" -- can be judged against a real
## render instead of taken on file comments alone.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_probe_creek_hollow_habitat.gd
##
## Same pinning discipline as _probe_creature_habitat.gd: time forced to day
## and world_look's processing switched off before any shot is taken.
##
## FIRST VERSION of this probe hand-picked one eye offset per cluster from the
## spawn radius alone, with no idea what stands on that exact patch of ground.
## Three of seven landed the eye inside a rock, flush against a wall, or
## pressed into a tree trunk -- Creek Hollow's whole point is dense rock/tree
## dressing, so a blind offset has good odds of landing on top of the dressing
## itself. This version casts a ray from every candidate eye position toward
## the cluster centre first and keeps the candidate with the clearest line of
## sight, the same way a player's own camera collision would push the lens
## back off a wall rather than clip through it.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/creature_presentation/habitat"
const SETTLE_FRAMES := 30
const PER_SHOT_SETTLE := 12
const EYE_HEIGHT := 1.7
const CLEAR_ENOUGH := 6.0
## data/config/terrain_playground.json::water.level. A candidate whose eye
## would sit below this is a submerged camera, not a shoreline vantage -- and
## an underwater sightline reports huge "clearance" for free (nothing solid
## is in the way), which made the vantage-finder prefer a submerged view over
## every real shore approach on the first attempt.
const WATER_LEVEL := -17.0

## [habitat tag, look-at centre, cluster radius from spawns.json]. The three
## water centres were moved 0829 (T1-CREATURE §15, spawns.json's own
## _comment_depth_0829) off the lakebed and into water shallow enough for the
## creature to actually clear the surface -- kept in sync with that file
## rather than the original OW5D offsets.
const CLUSTERS := [
	["creek_edge", Vector2(-378.0296, 528.0823), 14.0],
	["rock_overhang", Vector2(-371.2711, 562.9456), 10.0],
	["water_edge", Vector2(-356.1437, 516.158), 14.0],
	["open_basin", Vector2(-432.2, 485.5), 14.2],
	["rocky_shoulder", Vector2(-345.0, 595.0), 15.6],
	["grove", Vector2(-383.7, 597.0), 17.0],
	["far_water_edge", Vector2(-420.0, 610.0), 17.6],
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
	# T1-GROUND-3. This tool's own frames are the ones JUDGE-3 section 0 used to
	# establish that the harness produces grass-free evidence -- "bushes, reeds,
	# flower clumps and fern cards on a splat, and no blades". The cause was the
	# line above having no counterpart for the grass field: Terrain3D got told
	# about this camera and the field did not, so its ring stayed parked on the
	# gameplay camera and this tool photographed ground it was not dressing.
	# `grass_field.gd::_follow_camera` now redirects the ring to whichever camera
	# is rendering, which fixes this tool and the other 122 like it. The
	# CAPTURE_CHECK below is what makes a future regression of the same shape
	# loud instead of silent; it sits at the SHUTTER rather than here, because
	# the redirect happens in the field's own `_process` and a check run in the
	# same frame as `make_current()` fires before the world has had a tick to
	# settle -- which is a false alarm on exactly the frame the fix is working.

	var wanted: Array = OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for cluster: Array in CLUSTERS:
		var tag: String = cluster[0]
		if not wanted.is_empty() and not wanted.has(tag):
			continue
		var centre: Vector2 = cluster[1]
		var radius: float = cluster[2]
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
		# Last thing before the shutter, once the world is posed and settled:
		# refuse to write a frame that is missing a whole rendering system.
		# See tools/capture_check.gd and JUDGE-3 section 0 -- this tool's own
		# earlier frames are the evidence that motivated it.
		CAPTURE_CHECK.require(self, camera)
		var image := root.get_texture().get_image()
		if image != null:
			image.save_png("%s/creekhollow-%s.png" % [OUT, tag])
			print("wrote %s/creekhollow-%s.png" % [OUT, tag])
	quit(0)


## Tries a ring of bearings at a few standoff distances outside the cluster's
## own radius, and returns the [eye, look_at, clearance] whose sightline to
## the centre travels furthest before hitting anything solid -- i.e. the
## candidate least likely to be a wall, rock or trunk in the player's face.
## Stops early once a candidate clears CLEAR_ENOUGH metres, since that is
## already an open, readable approach and trying harder only spends render
## time for no judgement difference.
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
			if eye.y < WATER_LEVEL + 0.3:
				continue
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
