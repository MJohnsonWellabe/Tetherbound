extends SceneTree

## OWNER-0901-CREATURE-GRASS-VISIBILITY-V2, round 2. The practice-pen stand
## `_probe_grass_separation.gd` uses (36,-50) turns out to sit in shade (grass
## L≈72-77 there, measured off real renders) -- the owner's complaint is about
## the SUNLIT meadow, where grass reads much brighter (L≈130-165, measured off
## `grass_density_ladder/A-75k-creature.png`, the one sunlit frame this branch
## had rendered, taken for an unrelated reason). `field_degreen`/
## `field_emission` were tuned entirely against the shaded site and read as
## barely-separated to invisible in real sunlight (measured ratio ~0.92-0.98,
## i.e. the creature is AS DARK OR DARKER than the grass around it).
##
## This probe stands at the same `band1_open` site (0,700) the density ladder
## and `perf_render_stats.gd` use -- confirmed sunlit -- and sweeps
## `field_emission`/`field_degreen` there directly, at several nearby offsets
## in one boot so a bush-overlap spot can be found without paying for a new
## world stand-up per candidate.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_grass_sunlit.gd -- --species=bramblebun

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://ralph/reports/hud-catch/grass_sunlit"
const SETTLE_FRAMES := 240
const POSE_FRAMES := 30
const SITE_X := 0.0
const SITE_Z := 700.0
const EYE_HEIGHT := 1.78
const RANGE := 6.5

var SPECIES_ID := "bramblebun"
var _world: Node = null
var _camera: Camera3D = null
var _body: Node3D = null
var _written: Array[String] = []


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

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	var species := load("res://scripts/creatures/creature_species.gd")
	var table: Dictionary = species.call("placeholder", SPECIES_ID)
	var original_emission: float = float(table.get("field_emission", 0.0))
	var original_degreen: float = float(table.get("field_degreen", 0.0))

	# Several offsets around the sunlit stand, looking for one where real
	# cover-tier/scatter growth actually overlaps the creature -- the
	# coordinator's own worst-case example. Each entry: (dx, dz) from
	# (SITE_X, SITE_Z), camera stands RANGE back on -x.
	var offsets := [
		Vector2(0.0, 0.0),
		Vector2(8.0, 4.0),
		Vector2(-6.0, 10.0),
		Vector2(14.0, -8.0),
		Vector2(-10.0, -6.0),
	]
	var oi := 0
	for off: Vector2 in offsets:
		oi += 1
		var centre := Vector3(SITE_X + off.x, 0.0, SITE_Z + off.y)
		centre.y = _ground(centre)
		var stand := centre - Vector3(RANGE, 0.0, 0.0)
		stand.y = _ground(stand)
		_camera = Camera3D.new()
		_world.add_child(_camera)
		_camera.global_position = stand + Vector3(0.0, EYE_HEIGHT, 0.0)
		_camera.look_at(centre + Vector3(0.0, 0.45, 0.0), Vector3.UP)
		_camera.fov = 52.0
		_camera.make_current()

		table["field_emission"] = original_emission
		table["field_degreen"] = original_degreen
		if _body != null and is_instance_valid(_body):
			_body.queue_free()
			await process_frame
		_body = _spawn(centre)
		for i in POSE_FRAMES:
			await physics_frame
		_save("site%d-shipped" % oi)
		_camera.queue_free()
		await process_frame

	# Sweep on the FIRST (centre) site, which the frames above already show.
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

	var sweep := [
		{"tag": "e0.0-g0.0", "emission": 0.0, "degreen": 0.0},
		{"tag": "e0.9-g0.75", "emission": 0.9, "degreen": 0.75},
		{"tag": "e1.4-g0.75", "emission": 1.4, "degreen": 0.75},
		{"tag": "e1.8-g0.75", "emission": 1.8, "degreen": 0.75},
		{"tag": "e2.2-g0.9", "emission": 2.2, "degreen": 0.9},
		{"tag": "e2.6-g1.0", "emission": 2.6, "degreen": 1.0},
	]
	for variant: Dictionary in sweep:
		table["field_emission"] = float(variant["emission"])
		table["field_degreen"] = float(variant["degreen"])
		if _body != null and is_instance_valid(_body):
			_body.queue_free()
			await process_frame
		_body = _spawn(centre)
		for i in POSE_FRAMES:
			await physics_frame
		_save("sweep-%s" % variant["tag"])

	table["field_emission"] = original_emission
	table["field_degreen"] = original_degreen

	print("")
	for line: String in _written:
		print("  %s" % line)
	quit(0)


func _save(tag: String) -> void:
	var path := "%s/%s-%s.png" % [OUT, SPECIES_ID, tag]
	var image := get_root().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(path))
	_written.append(path)
	print("wrote %s" % path)


func _spawn(at: Vector3) -> Node3D:
	var scene: PackedScene = load("res://scenes/creatures/creature.tscn")
	if scene == null:
		return null
	var body: Node3D = scene.instantiate()
	body.set_script(load("res://scripts/creatures/wild_creature.gd"))
	body.name = "SunlitProbe_%s" % SPECIES_ID
	_world.add_child(body)
	body.global_position = at
	body.call("populate", SPECIES_ID, null)
	body.global_position = at
	return body


func _ground(at: Vector3) -> float:
	if _world != null and _world.has_method("ground_height_at"):
		return float(_world.call("ground_height_at", at.x, at.z))
	return 0.0
