extends SceneTree

## T5-CAMPS: the same ground, by day and after dark.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_night_ecology.gd
##
## The claim this has to settle is not "a config value changed". It is that a
## player standing in band 1's oak grove ring sees something after dark that is
## not there by day. So every site below is shot TWICE from an identical camera
## -- same eye, same target, same fov -- with nothing changed between the two
## frames but the world clock. A pair that looks the same is a failed fix, and
## the pair is the evidence rather than either frame alone.
##
## `CAPTURE_CHECK.require()` runs before every shutter. `tools/capture_check.gd`
## exists because a share of this repo's prior visual evidence was rendered with
## the grass field parked on a camera nobody was looking through, and lanes then
## reasoned about ground palette and emptiness from frames that were missing the
## largest thing in the real view. A night shot is the worst possible place to
## repeat that: "dark and bare" is exactly what a silently-degraded frame looks
## like, and nothing in the image would say so.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
## Under `ralph/reports/`, not `shots/`: `.gitignore` line 45 ignores `/shots/`
## at the repo root, and its own comment records that the pattern was narrowed
## to the root precisely so per-report evidence directories stay tracked. Frames
## that back a claim in a handover have to be committed with it.
const OUT := "res://ralph/reports/t5-camps-night-ecology"

const SETTLE_FRAMES := 90
const PER_SHOT_SETTLE := 14
## The gates are re-read in encounter_director.gd::_process, so the clock change
## needs frames to actually reach the creatures' visibility.
const GATE_FRAMES := 12
const EYE_HEIGHT := 1.7
const CLEAR_ENOUGH := 6.0

## Cluster centres authored in band1_lower_meadows/spawns.json. The radius is
## the cluster's own scatter radius, so the vantage search stands off the whole
## group rather than off its centre point.
const SITES := [
	["band0-home-hook", Vector2(60.0, 46.0), 12.0],
	["band1-grove-interior", Vector2(265.0, 897.0), 14.0],
	["band1-camp-grove", Vector2(337.0, 965.0), 14.0],
]


var _t0: int = 0


func _elapsed() -> String:
	return "%6.1fs" % ((Time.get_ticks_msec() - _t0) / 1000.0)


func _init() -> void:
	_t0 = Time.get_ticks_msec()
	_run()


func _run() -> void:
	print("[%s] instantiating world" % _elapsed())
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	print("[%s] world added; settling %d frames" % [_elapsed(), SETTLE_FRAMES])
	for _i in SETTLE_FRAMES:
		await process_frame
	print("[%s] settled" % _elapsed())

	# The HUD is not the subject and it covers the ground the subject stands on.
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	var director: Node = world.get_node_or_null(^"EncounterDirector")
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

	for site: Array in SITES:
		var tag := str(site[0])
		var centre: Vector2 = site[1]
		var radius: float = site[2]
		var placement := _find_clear_vantage(space, field, centre, radius)
		var eye: Vector3 = placement[0]
		var look_at: Vector3 = placement[1]
		camera.global_position = eye
		camera.look_at(look_at, Vector3.UP)
		print("")
		print("[%s] %s: vantage clearance %.1fm" % [_elapsed(), tag, float(placement[2])])
		for preset: String in ["day", "night"]:
			await _shoot(world, look, director, camera, tag, preset, centre, radius)
	quit(0)


func _shoot(world: Node, look: Node, director: Node, camera: Camera3D,
		tag: String, preset: String, centre: Vector2, radius: float) -> void:
	if look != null:
		look.call("apply_time", preset)
		look.set_process(false)
	for _i in GATE_FRAMES:
		await process_frame

	# Say, in the log beside the frame, how many gated bodies are actually
	# showing in this shot. A reader should not have to count owls in a dark
	# PNG to know whether the pair proves anything.
	var showing := _visible_night_bodies_near(director, centre, radius)
	var dark := look != null and bool(look.call("is_dark"))
	print("  [%s] %-6s is_dark=%-5s night bodies visible near site: %d" % [
		_elapsed(), preset, str(dark), showing])

	for _i in PER_SHOT_SETTLE:
		await process_frame
	CAPTURE_CHECK.require(self, camera)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image != null:
		var path := "%s/%s-%s.png" % [OUT, tag, preset]
		image.save_png(path)
		print("  [%s] wrote %s" % [_elapsed(), path])


## Night-gated bodies standing within the frame's subject area and currently
## visible. Read off the live nodes, not off the config.
func _visible_night_bodies_near(director: Node, centre: Vector2, radius: float) -> int:
	if director == null:
		return -1
	var n := 0
	for wild: Variant in director.call("wild_creatures"):
		if not (wild is Node3D):
			continue
		var body: Node3D = wild
		if not str(body.name).begins_with("Wild_duskhush_"):
			continue
		var here := Vector2(body.global_position.x, body.global_position.z)
		if here.distance_to(centre) <= radius + 10.0 and body.visible:
			n += 1
	return n


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
