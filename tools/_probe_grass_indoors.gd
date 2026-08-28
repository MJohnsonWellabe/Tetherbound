extends SceneTree

## GRASS-INDOORS. Does the ground cover grow through things that are standing
## on the ground?
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_grass_indoors.gd -- --out=shots/indoors
##
## NEVER with `--headless` and a real rendering driver: that combination hangs
## forever with no error (ralph/conventions.md, "Art pipeline traps").
##
## THE REPORT THIS ANSWERS is the owner's, 2026-08-28: "grass grows through
## indoor buildings now". `ralph/OWNER_PLAYTEST_2026-08-28.md` §7. The word
## that dates it is NOW -- the field was switched on the day before.
##
## THREE EXPOSURES PER SITE, FROM ONE BOOT, which is the whole design of this
## tool. A before/after across two runs would compare two different worlds; the
## exclusion is a shader uniform, so all three states can be photographed from
## one seat with nothing else changing:
##
##   `-before`  `built_count` forced to 0 -- the field exactly as the owner
##              played it, with no idea that anything is standing on the ground.
##   `-after`   the list the field actually computes. The fix.
##   `-nofield` every one of the field's MultiMeshes hidden. This is the
##              ATTRIBUTION frame and it is why the sheet can be trusted: any
##              ground cover still standing in it belongs to the baked scatter,
##              not to the field, and is a different defect with a different
##              owner. Taken at the reported site only -- the others do not
##              need it once the mechanism is established.
##
## THE SITES are chosen to answer the general case as well as the reported one,
## because the defect is not "Grandpa's house" but "the field does not know
## about placed geometry":
##
##   grandpa-house   the reported site, and one vegetation.json already
##                   footprints ("grass was standing on the floor and the rug").
##   inn             the other authored interior, footprinted the same way.
##   workshop        a village structure with NO footprint entry. If the field
##                   is clean here it is because of something else, and that is
##                   worth knowing.
##   warrens-mouth   the Burrow Warrens' surface entrance.
##   relay-station   Team Tether's relay, band 3.
##   stronghold      the outer works, band 5.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"

const BOOT_FRAMES := 90
const ARRIVE_FRAMES := 25
const SETTLE_FRAMES := 45
const POSE_FRAMES := 4
const FOV := 70.0

## Eye height above the ground the terrain reports, and how far in front of the
## camera the framed floor is. 1.5m is a standing eye; 3.5m of offset puts the
## floor under the camera's own feet in the lower third and the far wall above
## it, which is the framing that answers "is there grass on this floor".
const EYE_UP := 1.5
const EYE_BACK := 3.5

## name, world XZ, and which way the camera faces (it stands `EYE_BACK` back
## along this and looks down the length of it). `nofield` marks the site that
## also gets the attribution exposure.
const SITES := [
	["grandpa-house", Vector2(-22.0, -16.0), Vector2(1.0, 0.0), true],
	["inn", Vector2(-1.5, -9.0), Vector2(1.0, 0.0), false],
	["workshop", Vector2(2.0, 2.0), Vector2(1.0, 0.0), false],
	["warrens-mouth", Vector2(-357.0, 2610.0), Vector2(0.0, 1.0), false],
	["relay-station", Vector2(350.0, 3760.0), Vector2(0.0, 1.0), false],
	["stronghold", Vector2(0.0, 7560.0), Vector2(1.0, 0.0), false],
]

var _field: RefCounted = null
var _world: Node = null
var _player: Node3D = null
var _camera: Camera3D = null
var _grass: Node3D = null
var _look: Node = null
var _weather: Node = null
var _out_dir := "res://shots/indoors"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return
	var only := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = "res://" + arg.substr(6).trim_prefix("res://")
		elif arg.begins_with("--only="):
			only = arg.substr(7)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	print("[indoors] writing to %s" % _out_dir)

	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame
	print("[indoors] world up")

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	_player = _world.get_node_or_null(^"Player") as Node3D
	if _player == null:
		print("no Player node")
		quit(1)
		return
	# The trainer stands where the camera is looking and would be most of the
	# frame. Hidden rather than moved: the encounter director and the terrain
	# both stream around the player's POSITION, so it has to stay at the site.
	_player.visible = false

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)

	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	await _pin("day")

	_grass = _world.get_node_or_null(^"GrassField") as Node3D
	if _grass == null:
		print("FAIL no GrassField node -- grass_field.json's `enabled` is off, and")
		print("     there is nothing for this tool to photograph.")
		quit(1)
		return

	for entry: Variant in SITES:
		var site: Array = entry
		if only != "" and not (only in str(site[0])):
			continue
		await _shoot(site)

	print("")
	print("indoors pass written to %s" % _out_dir)
	quit(0)


func _shoot(site: Array) -> void:
	var name: String = str(site[0])
	var at: Vector2 = site[1]
	var facing: Vector2 = (site[2] as Vector2).normalized()
	var attribute: bool = bool(site[3])

	# Two seatings, the way every probe in this repo does it: the analytic
	# height first so Terrain3D has somewhere to stream to, then the surface
	# that actually arrived.
	_place(at, _field.height_at(at.x, at.y))
	_frame(at, facing)
	for i in ARRIVE_FRAMES:
		await physics_frame
	_place(at, _field.height_at(at.x, at.y))
	_frame(at, facing)
	for i in SETTLE_FRAMES:
		await physics_frame

	_set_built(false)
	await _expose("%s-before" % name)
	_set_built(true)
	await _expose("%s-after" % name)
	if attribute:
		_show_field(false)
		for i in 8:
			await physics_frame
		await _expose("%s-nofield" % name)
		_show_field(true)
	print("  %-16s at (%.0f, %.0f), ground %.2f, %d footprint(s) in reach" % [
		name, at.x, at.y, _field.height_at(at.x, at.y), _built_count()])


## Force the exclusion off (the build the owner played) or back to whatever the
## field itself computes. Only `built_count` is touched: the list, the bounds
## and every other uniform stay exactly as they are, so the two exposures
## differ by this one thing.
func _set_built(on: bool) -> void:
	var live := _built_count()
	for material: ShaderMaterial in _grass.call("_field_materials"):
		material.set_shader_parameter("built_count", live if on else 0)


func _built_count() -> int:
	var built: PackedVector3Array = _grass.call("_visible_footprints", _grass.global_position)
	return built.size()


func _show_field(on: bool) -> void:
	_grass.visible = on
	for child in _grass.get_children():
		if child is GeometryInstance3D:
			(child as GeometryInstance3D).visible = on


func _pin(time: String) -> void:
	if _weather != null:
		_weather.set_process(true)
		_weather.set_physics_process(true)
		_weather.call("set_weather", "clear")
	if _look != null:
		_look.set_process(true)
		_look.set_physics_process(true)
		_look.call("apply_time", time)
	for i in 30:
		await physics_frame
	if _weather != null:
		_weather.set_process(false)
		_weather.set_physics_process(false)
	if _look != null:
		_look.set_process(false)
		_look.set_physics_process(false)


func _expose(name: String) -> void:
	for node in _world.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
	for node in root.get_children():
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % name)
		return
	if image.save_png("%s/%s.png" % [_out_dir, name]) != OK:
		print("FAIL %s: save_png" % name)


func _place(at: Vector2, ground: float) -> void:
	_player.global_position = Vector3(at.x, ground + 0.4, at.y)
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO


## The camera stands back along `facing` and looks down its length at the floor.
## Height comes from the ANALYTIC heightfield, not from a downward raycast: a
## ray cast from above lands on the roof of the building this tool exists to
## look inside.
func _frame(at: Vector2, facing: Vector2) -> void:
	var ground: float = _field.height_at(at.x, at.y)
	var eye := at - facing * EYE_BACK
	_camera.global_position = Vector3(eye.x, ground + EYE_UP, eye.y)
	_camera.look_at(Vector3(at.x, ground + 0.15, at.y), Vector3.UP)
