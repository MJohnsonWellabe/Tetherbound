extends SceneTree

## OWNER-0901-CREATURE-GRASS-VISIBILITY-V2, final verification. Renders the
## exact sunlit spot `_probe_grass_sunlit.gd` found landing a creature inside
## a real, statically-baked bush (band1_open, (0,700)) -- BEFORE (the old,
## un-sited spot, exactly reproducing `grass_bush_clear/bramblebun-without-clear.png`)
## and AFTER (the same candidate draw run through
## `encounter_director.gd::_pick_clear_spot()`'s own algorithm, calling the
## real, shipped `vegetation.gd::has_solid_scatter_near()` this branch just
## added -- not a re-implementation, the actual method).
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_spawn_siting.gd -- --species=bramblebun

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://ralph/reports/hud-catch/grass_spawn_siting"
const SETTLE_FRAMES := 240
const POSE_FRAMES := 40
const SITE_X := 0.0
const SITE_Z := 700.0
const EYE_HEIGHT := 1.78
const RANGE := 6.5
## Matches the cluster radius that actually put a creature in this exact
## bush -- large enough that the un-sited draw reliably lands on it (this IS
## where it landed with distance 0 in the earlier probe), small enough that
## the whole disc is in frame.
const CLUSTER_RADIUS := 2.0
const CLEAR_ATTEMPTS := 6
const CLEAR_MARGIN := 0.8

var SPECIES_ID := "bramblebun"
var _world: Node = null
var _camera: Camera3D = null
var _vegetation: Node = null
var _body: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--species="):
			SPECIES_ID = arg.substr(10)

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_vegetation = _world.get_node_or_null(^"Vegetation")
	if _vegetation == null:
		print("FAIL: no Vegetation node -- has_solid_scatter_near cannot be tested")
		quit(1)
		return
	if not _vegetation.has_method("has_solid_scatter_near"):
		print("FAIL: vegetation.gd has no has_solid_scatter_near -- did the branch land?")
		quit(1)
		return

	var centre := Vector3(SITE_X, 0.0, SITE_Z)
	centre.y = _ground(centre)
	var stand := centre - Vector3(RANGE, 0.0, 0.0)
	stand.y = _ground(stand)

	_camera = Camera3D.new()
	_world.add_child(_camera)
	_camera.global_position = stand + Vector3(0.0, EYE_HEIGHT, 0.0)
	_camera.look_at(centre + Vector3(0.0, 0.45, 0.0), Vector3.UP)
	_camera.fov = 52.0
	_camera.make_current()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	# BEFORE: the un-sited draw (distance 0, the exact spot known to land
	# inside the bush -- matches grass_bush_clear/bramblebun-without-clear.png).
	_body = _spawn(centre)
	for i in POSE_FRAMES:
		await physics_frame
	_save("before-unsited")

	# AFTER: the real _pick_clear_spot() algorithm, same rng-driven draw
	# shape, at the SAME cluster centre/radius, calling the shipped
	# has_solid_scatter_near() -- not a re-implementation. Attempt 1 is
	# forced to the exact known-bad point (distance 0, the BEFORE spot)
	# rather than a fresh random draw, so this actually exercises the retry
	# path instead of just getting lucky on a first random guess -- every
	# attempt after the first is the ordinary randomised draw.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("spawn_siting_probe")
	var spot := centre
	var attempts_used := 0
	for attempt in CLEAR_ATTEMPTS:
		attempts_used = attempt + 1
		if attempt == 0:
			spot = centre
		else:
			var angle := rng.randf_range(0.0, TAU)
			var distance := CLUSTER_RADIUS * sqrt(rng.randf())
			spot = centre + Vector3(sin(angle), 0.0, cos(angle)) * distance
		spot.y = _ground(spot)
		if not bool(_vegetation.call("has_solid_scatter_near", spot, CLEAR_MARGIN)):
			break
	print("picked spot after %d attempt(s): %s (clear=%s)" % [
		attempts_used, spot,
		not bool(_vegetation.call("has_solid_scatter_near", spot, CLEAR_MARGIN))])

	if _body != null and is_instance_valid(_body):
		_body.queue_free()
		await process_frame
	_body = _spawn(spot)
	for i in POSE_FRAMES:
		await physics_frame
	_save("after-sited")

	print("done")
	quit(0)


func _save(tag: String) -> void:
	var path := "%s/%s-%s.png" % [OUT, SPECIES_ID, tag]
	var image := get_root().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(path))
	print("wrote %s" % path)


func _spawn(at: Vector3) -> Node3D:
	var scene: PackedScene = load("res://scenes/creatures/creature.tscn")
	if scene == null:
		return null
	var body: Node3D = scene.instantiate()
	body.set_script(load("res://scripts/creatures/wild_creature.gd"))
	body.name = "SpawnSitingProbe_%s" % SPECIES_ID
	_world.add_child(body)
	body.global_position = at
	body.call("populate", SPECIES_ID, null)
	body.global_position = at
	return body


func _ground(at: Vector3) -> float:
	if _world != null and _world.has_method("ground_height_at"):
		return float(_world.call("ground_height_at", at.x, at.z))
	return 0.0
