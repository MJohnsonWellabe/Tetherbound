extends SceneTree

## Does the shared pickup highlight read as THE ITEM GLOWING, at the distances
## that matter, without covering the item up?
##
##   xvfb-run -a -s "-screen 0 960x540x24" \
##     godot --path . --rendering-driver opengl3 --resolution 960x540 \
##       --script tools/_probe_pickup_glow_isolated.gd
##
## The full-world capture takes many minutes and answers three questions at once
## -- is the glow drawing, is the pickup in frame, does it read against grass --
## which is the wrong shape for tuning any of them. This answers the first and
## the third in about a minute.
##
## ## What it puts in frame, and why each part is deliberate
##
## * **A real prop at every stand, not a bare marker.** The owner's directive is
##   that the glow must not take over the item's geometry or design, and a frame
##   containing nothing but glows is incapable of showing whether it does. An
##   earlier version of this probe registered empty `Node3D`s and was therefore
##   useless for the exact question it was being used to answer.
## * **One prop per frame, dead centre.** The first version put three stands in
##   one frame at different lateral offsets, and reading which glow belonged to
##   which prop turned into guesswork. Three frames, each unambiguous.
## * **Meadow green under a full sun.** An additive glow tuned against a dark
##   studio floor is guaranteed to look strong and guaranteed to disappear in
##   the game: the ground OP-0830-3 is about is a bright daylit field.

const GLOW := preload("res://scripts/world/pickup_glow.gd")
const OUT_DIR := "res://ralph/reports/T5-FEEL/shots"

## Distance, the prop's real-world size at that stand, and its item colour.
## Sizes are the actual objects: a TM orb is 20cm, a fiber clump is knee high,
## a rock deposit is knee-to-thigh.
const STANDS := [
	{"name": "near", "distance": 3.0, "size": 0.20, "colour": "#c9a227"},
	{"name": "mid", "distance": 11.0, "size": 0.45, "colour": "#9aa64a"},
	{"name": "far", "distance": 24.0, "size": 0.70, "colour": "#8e8d86"},
]

var _world: Node3D = null
var _camera: Camera3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = Node3D.new()
	_world.name = "IsolatedWorld"
	root.add_child(_world)
	# A node added to `root` from a SceneTree script's `_init` has not ENTERED
	# the tree until the tree next processes, so `get_tree()` on its children is
	# null until then -- and `pickup_glow.gd::attach()` needs the tree to find
	# the field. Not a game path (every real pickup registers from `_ready()` or
	# later, by which point the tree is up); purely this harness's own ordering.
	await process_frame

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120.0, 120.0)
	ground.mesh = plane
	var dirt := StandardMaterial3D.new()
	dirt.albedo_color = Color("#7c8737")
	ground.material_override = dirt
	_world.add_child(ground)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	light.light_energy = 1.1
	_world.add_child(light)

	_camera = Camera3D.new()
	_camera.current = true
	_world.add_child(_camera)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for stand: Dictionary in STANDS:
		await _shoot(stand)
	quit(0)


func _shoot(stand: Dictionary) -> void:
	var size := float(stand["size"])
	var distance := float(stand["distance"])

	var marker := Node3D.new()
	marker.position = Vector3.ZERO
	_world.add_child(marker)

	var prop := MeshInstance3D.new()
	var body := BoxMesh.new()
	body.size = Vector3(size, size, size)
	prop.mesh = body
	prop.position = Vector3.UP * (size * 0.5)
	var skin := StandardMaterial3D.new()
	# A plain mid tone on purpose: if this prop's faces and edges are still
	# distinguishable beside the glow, a real textured prop certainly will be.
	skin.albedo_color = Color(0.42, 0.34, 0.26)
	skin.metallic = 0.0
	skin.roughness = 0.85
	prop.material_override = skin
	marker.add_child(prop)

	GLOW.attach(marker, Color(str(stand["colour"])))

	# Eye height and a slight look-down, like the game's own third-person rig.
	_camera.position = Vector3(0.0, 1.7, distance)
	_camera.look_at(Vector3(0.0, size * 0.5, 0.0))

	for i in 6:
		await process_frame
	var image := root.get_texture().get_image()
	var path := "%s/_isolated-glow-%s.png" % [OUT_DIR, stand["name"]]
	image.save_png(path)

	# Brightest pixel, so "is anything glowing at all" is a number rather than
	# someone squinting at a PNG.
	var brightest := 0.0
	for y in image.get_height():
		for x in image.get_width():
			brightest = maxf(brightest, image.get_pixel(x, y).get_luminance())
	# The halo's actual world height, printed beside the prop's own crown. The
	# pair is the whole "on the item, not floating above it" claim, and reading
	# it off a render is guesswork -- a first pass at this spent a round arguing
	# with a 30-pixel gap in a PNG that a printed number settles.
	var placed := Vector3.ZERO
	var field := _world.get_node_or_null(^"PickupGlowField")
	if field != null:
		var motes := field.get_node_or_null(^"Motes") as MultiMeshInstance3D
		if motes != null and motes.multimesh.instance_count > 0:
			placed = motes.multimesh.get_instance_transform(0).origin
	print("[isolated] %-5s %4.1fm prop %.2fm crown %.2fm halo y=%.2f -> %s (brightest %.3f)" % [
		stand["name"], distance, size, size, placed.y, path, brightest])

	GLOW.detach(marker)
	marker.queue_free()
	await process_frame
