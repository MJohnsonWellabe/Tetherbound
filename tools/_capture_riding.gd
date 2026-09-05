extends SceneTree

## OP-0904-3 / CL-O3's evidence: two frames of the same animal, one before the
## saddle is built and one with the trainer sitting on it.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_riding.gd
##
## NEVER with `--headless` and a real rendering driver (it hangs forever).
##
## The two frames answer the two halves of the owner's report separately, so a
## blind judge can be asked about each without being told which is which:
##
##   `riding_before_saddle.png`  the mount standing in the field, unsaddled and
##                               unridden — nothing on its back at all
##   `riding_mounted.png`        the same animal with the saddle fitted and the
##                               trainer seated on it
##   `riding_mounted_side.png`   the same moment from the side, which is the
##                               only angle that shows whether the legs hang
##                               where a rider's legs hang or clip through
##
## Framing is fixed relative to the MOUNT rather than to a world coordinate:
## the thing under judgement is a creature and a rider at each other's scale,
## and the 1.80 m trainer is the ruler CLAUDE.md's own scale rule is written
## in. `--species=` overrides the animal; the default is whatever the data
## says is rideable and needs a saddle.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")

const SETTLE_FRAMES := 300
const POSE_FRAMES := 6
const FOV := 48.0
## Where the camera stands, in metres, in the mount's own frame: back, up and
## to one side. Close enough that a 2 m animal and a 1.8 m rider fill the frame
## and a judge can see a knee.
const EYE_BEHIND := 4.6
const EYE_UP := 2.1
const EYE_SIDE := 3.2
const SIDE_EYE_BEHIND := 0.4
const SIDE_EYE_SIDE := 5.4

var _species := ""
var _out_dir := "res://shots_riding"
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _parse_args() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--species="):
			_species = a.substr("--species=".length())
		elif a.begins_with("--out="):
			_out_dir = a.substr("--out=".length())
			if not _out_dir.begins_with("res://"):
				_out_dir = "res://" + _out_dir
			_out_dir = _out_dir.trim_suffix("/")


func _run() -> void:
	_parse_args()
	if _species == "":
		_species = _default_species()
	if _species == "":
		print("no rideable species that wants a saddle; nothing to capture")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	var packed: PackedScene = load(SCENE) as PackedScene
	if packed == null:
		print("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)

	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var rig: Node = world.get_node_or_null(^"CameraRig")
	var director: Node = world.get_node_or_null(^"EncounterDirector")
	var riding: Node = world.get_node_or_null(^"RidingController")
	var game := root.get_node_or_null(^"/root/Game")
	if player == null or director == null or riding == null or game == null:
		print("the playground is missing the player, director, riding controller or Game")
		quit(1)
		return
	var party: RefCounted = game.get("party")
	var bag: RefCounted = game.get("inventory")
	var progression: RefCounted = game.get("progression")

	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null and look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	if look != null and look.has_method("apply_time"):
		look.call("apply_time", "day")

	# Nothing built, nothing fitted: the state a player is in before the
	# tournament pays out the pattern.
	var saddles := int(bag.call("count", "saddle"))
	if saddles > 0:
		bag.call("remove", "saddle", saddles)
	progression.call("set_flag", RIDING.saddle_fitted_flag(_species), false)

	if not await _bring_out_the_mount(director, party):
		quit(1)
		return
	var mount: Node3D = director.call("ally_body")

	# Open, flat ground: the point of the frame is the animal and the rider, and
	# a mount standing in a hedge is a frame about the hedge.
	mount.call("place_on_ground", Vector3(0.0, 0.0, 0.0))
	player.global_position = mount.global_position + mount.global_basis.x * 1.4
	for i in 60:
		await physics_frame

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	for i in 60:
		await physics_frame

	await _shoot(camera, mount, "riding_before_saddle", EYE_BEHIND, EYE_UP, EYE_SIDE)

	# Build it, put it on, get on.
	bag.call("add", "saddle", 1)
	for i in 10:
		await physics_frame
	if not bool(riding.call("mount")):
		_failures.append("could not mount the %s for the second frame" % _species)
	for i in 60:
		await physics_frame
	await _shoot(camera, mount, "riding_mounted", EYE_BEHIND, EYE_UP, EYE_SIDE)
	await _shoot(camera, mount, "riding_mounted_side", SIDE_EYE_BEHIND, EYE_UP, SIDE_EYE_SIDE)

	print("")
	if _failures.is_empty():
		print("riding capture: OK -> %s" % _out_dir)
		quit(0)
		return
	for line in _failures:
		print("riding capture FAIL: %s" % line)
	quit(1)


func _default_species() -> String:
	var file := FileAccess.open("res://data/creatures/species.json", FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ""
	var table: Variant = (parsed as Dictionary).get("species", {})
	if not table is Dictionary:
		return ""
	var ids: Array = []
	for id: String in (table as Dictionary):
		if not id.begins_with("_") and RIDING.saddle_belongs_on(id):
			ids.append(id)
	ids.sort()
	return str(ids[0]) if not ids.is_empty() else ""


func _bring_out_the_mount(director: Node, party: RefCounted) -> bool:
	if director.call("ally_body") != null:
		director.call("dismiss_active_creature")
		for i in 20:
			await physics_frame
	var instance: RefCounted = SPECIES.spawn(_species)
	if instance == null or not bool(party.call("add", instance)):
		print("could not put a %s in the party" % _species)
		return false
	for i in int(party.call("size")):
		if party.call("at", i) == instance:
			party.call("set_active", i)
			break
	await director.call("summon_active_creature")
	for i in 120:
		await physics_frame
		var body: Node3D = director.call("ally_body")
		if body != null and is_instance_valid(body) and body.visible:
			return true
	print("the %s never stood up in the world" % _species)
	return false


## Frame the mount from `behind`/`up`/`side` metres in its own basis, looking at
## its middle, and write the PNG.
func _shoot(camera: Camera3D, mount: Node3D, name: String,
		behind: float, up: float, side: float) -> void:
	var height := float(mount.call("body_height")) if mount.has_method("body_height") else 2.0
	var centre := mount.global_position + Vector3(0.0, height * 0.62, 0.0)
	var eye := mount.global_position \
		- mount.global_basis.z * behind \
		+ mount.global_basis.x * side \
		+ Vector3(0.0, up, 0.0)
	camera.global_position = eye
	camera.look_at(centre, Vector3.UP)
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: the viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [_out_dir, name]
	var err := image.save_png(path)
	if err != OK:
		_failures.append("%s: save_png failed (%d)" % [name, err])
		return
	print("  %s -> %s" % [name, path])
