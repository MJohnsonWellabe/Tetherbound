extends SceneTree

## Look at the roster THE GAME ACTUALLY HAS, through the code the game uses.
##
##   xvfb-run -a -s "-screen 0 1400x900x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --resolution 1400x900 \
##     --script tools/preview_roster_ingame.gd -- <mode>
##
## modes:
##   probe   headless. Per raw model: material names and colours, the three
##           different AABBs Godot will hand you, and the clip list. This is the
##           sheet a species entry is written FROM.
##   sheet   one tile per species in data/pals/species.json, each framed on the
##           same window with the 1.80m trainer beside it, composited into
##           `shots/_roster_ingame.png` with the measured height printed on it.
##   line    the whole cast in one rank, at scale, with the trainer standing in
##           it — the shot that answers "does the size spread say anything".
##   field   the whole cast standing on the REAL meadow under the real sun. The
##           readability question is about THIS ground, and only three species
##           ever spawn in the playground, so nothing else can show the other
##           five against it.
##
## Not `tools/preview_roster.gd`: that one loads RAW candidate models at a guessed
## pack scale and is for choosing a pack. This one goes through `pal.tscn` and
## `pal_body.gd`, so what it shows is what a fight shows — fitted to the species'
## gameplay height, retinted by `art.json`, posed on its declared idle clip.

const SPECIES := preload("res://scripts/pals/pal_species.gd")
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
const BODY := preload("res://scripts/pals/pal_body.gd")

const TRAINER_MODEL := "res://assets/characters/knight.glb"
const TRAINER_HEIGHT := 1.80
const SHOTS := "res://shots/"

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
## Terrain3D builds its collision over many frames; a creature grounded before
## then falls through the world. `tests/smoke_art.gd` uses 300 for the same
## reason.
const WORLD_SETTLE := 300

## Long enough that a skinned model is standing in its idle rather than in the
## bind pose. A bind pose is not a silhouette anybody will ever see, and every
## measurement taken on one has been wrong (`docs/reviews/MA-04`).
const SETTLE_PHYSICS := 90

## Wide enough that the LONGEST creature fits beside the trainer at a shared
## camera window. A 3.4m Thornback in a tile 2m across is a Thornback that
## overflows its own cell, and a sheet where every creature fills its tile is a
## sheet that cannot be used to judge scale — which is the thing it exists for.
const TILE := Vector2i(400, 360)
const COLS := 4


func _init() -> void:
	var mode := "probe"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]
	match mode:
		"probe":
			_probe()
		"sheet":
			_sheet()
		"line":
			_line()
		"field":
			_field()
		_:
			printerr("unknown mode '%s'" % mode)
			quit(1)


## --- probe ------------------------------------------------------------------

func _probe() -> void:
	var dir := DirAccess.open("res://assets/pals/quaternius")
	var names: Array[String] = []
	for file in dir.get_files():
		if file.get_extension().to_lower() in ["gltf", "glb", "fbx"]:
			names.append(file)
	names.sort()
	for file in names:
		await _probe_one("res://assets/pals/quaternius/%s" % file)
	quit(0)


func _probe_one(path: String) -> void:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		print("%-14s FAILED TO LOAD" % path.get_file())
		return
	var scene: Node3D = packed.instantiate()
	root.add_child(scene)
	# Global transforms are meaningless until the node is in the tree AND the
	# tree has stepped; without this every box below is measured against an
	# identity transform and the numbers are silently local.
	await process_frame

	var meshes: Array[MeshInstance3D] = []
	_collect(scene, meshes)

	var rest := AABB()
	var instance_box := AABB()
	var resource_box := AABB()
	var started := false
	var materials: Array[String] = []
	for mesh in meshes:
		var r: AABB = mesh.global_transform * _rest_aabb(mesh.mesh)
		var i: AABB = mesh.global_transform * mesh.get_aabb()
		var m: AABB = mesh.global_transform * mesh.mesh.get_aabb()
		if started:
			rest = rest.merge(r)
			instance_box = instance_box.merge(i)
			resource_box = resource_box.merge(m)
		else:
			rest = r
			instance_box = i
			resource_box = m
			started = true
		for surface in mesh.mesh.get_surface_count():
			var mat: Material = mesh.mesh.surface_get_material(surface)
			var label := "(null)"
			if mat != null:
				var std := mat as StandardMaterial3D
				var c: Color = Color.WHITE if std == null else std.albedo_color
				var textured: bool = std != null and std.albedo_texture != null
				label = "%s %s%s" % [
					mat.resource_name, c.to_html(false), "  TEX" if textured else ""]
			if not materials.has(label):
				materials.append(label)

	var clips: PackedStringArray = []
	var players: Array[AnimationPlayer] = []
	_collect_players(scene, players)
	for player in players:
		for a in player.get_animation_list():
			clips.append(String(a))

	print("\n%s" % path.get_file())
	print("  rest      %5.2f x %5.2f x %5.2f   long/tall %.2f  wide/tall %.2f" % [
		rest.size.x, rest.size.y, rest.size.z,
		maxf(rest.size.x, rest.size.z) / maxf(rest.size.y, 0.001),
		minf(rest.size.x, rest.size.z) / maxf(rest.size.y, 0.001)])
	print("  instance  %5.2f x %5.2f x %5.2f  (MeshInstance3D.get_aabb)" % [
		instance_box.size.x, instance_box.size.y, instance_box.size.z])
	print("  resource  %5.2f x %5.2f x %5.2f  (mesh.mesh.get_aabb)" % [
		resource_box.size.x, resource_box.size.y, resource_box.size.z])
	print("  materials: %s" % ", ".join(materials))
	print("  clips(%d): %s" % [clips.size(), ", ".join(clips)])

	root.remove_child(scene)
	scene.queue_free()


func _rest_aabb(mesh: Mesh) -> AABB:
	var box := AABB()
	var started := false
	if mesh == null:
		return box
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for v in verts:
			if not started:
				box = AABB(v, Vector3.ZERO)
				started = true
			else:
				box = box.expand(v)
	return box


## --- rendered sheets ---------------------------------------------------------

func _order() -> Array[String]:
	var ids: Array[String] = []
	for id: String in SPECIES.table().keys():
		ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		return float(SPECIES.placeholder(a).get("height", 1.0)) \
			< float(SPECIES.placeholder(b).get("height", 1.0)))
	return ids


func _sheet() -> void:
	var ids := _order()
	var tiles: Array[Image] = []
	DirAccess.make_dir_recursive_absolute(SHOTS)

	var caption := _caption()

	# ONE camera window for every tile, sized on the tallest creature in the
	# roster. Framing each tile on its own subject makes every creature the same
	# size on the sheet, which is the one thing a scale review must not do.
	var tallest := TRAINER_HEIGHT
	for id in ids:
		tallest = maxf(tallest, SPECIES.body_height(id))
	# Sized on the horizontal need, not the vertical one: the tallest creature
	# is 2.10m and the longest is 3.4m, and the wide one is what overflows.
	var window: float = maxf(tallest * 1.30, 5.0 * float(TILE.y) / float(TILE.x))

	for id in ids:
		var world := _stage()
		var camera: Camera3D = world.get_node(^"Cam")
		var pal: Node3D = await _pal(world, id, Vector3(0.35, 0.0, 0.0))
		await _trainer(world, Vector3(-1.35, 0.0, 0.0))
		var declared: float = SPECIES.body_height(id)
		camera.look_at_from_position(
			Vector3(0.3, window * 0.44, window * 1.32),
			Vector3(0.3, window * 0.36, 0.0), Vector3.UP)
		caption.text = "%s   %.2fm   %s\n%s" % [
			SPECIES.display_name(id), declared, SPECIES.type_of(id).to_upper(), id]
		await _settle()
		tiles.append(_tile())
		print("  %-16s %-14s %.2fm declared   bone span %.2fm   %s" % [
			id, SPECIES.display_name(id), declared, _rendered_height(pal),
			SPECIES.type_of(id)])
		world.queue_free()
		await process_frame

	var rows := int(ceil(float(tiles.size()) / float(COLS)))
	var sheet := Image.create(COLS * TILE.x, rows * TILE.y, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.08, 0.09, 0.10))
	for i in tiles.size():
		var x := (i % COLS) * TILE.x
		var y := (i / COLS) * TILE.y
		sheet.blit_rect(tiles[i], Rect2i(Vector2i.ZERO, TILE), Vector2i(x, y))
	sheet.save_png("%s_roster_ingame.png" % SHOTS)
	print("\nwrote %s_roster_ingame.png  (%d species, %dx%d)" % [
		SHOTS, tiles.size(), sheet.get_width(), sheet.get_height()])
	quit(0)


func _line() -> void:
	var ids := _order()
	var world := _stage()
	var camera: Camera3D = world.get_node(^"Cam")

	# Spaced by MEASURED length, not by collider radius. A radius says how wide a
	# creature is and every quadruped here is two to three times longer than
	# that, so radius-spacing put the Gloamfang inside the Thornback.
	const GAP := 0.55
	var cursor := GAP
	for id in ids:
		var pal: Node3D = await _pal(world, id, Vector3(cursor, 0.0, 0.0))
		var length: float = _model_bounds(pal.get_node(^"Model") as Node3D).size.z
		pal.position.x = cursor + length * 0.5
		cursor += length + GAP
		print("  %-16s %-14s %.2fm tall, %.2fm long" % [
			id, SPECIES.display_name(id), SPECIES.body_height(id), length])
	var trainer: Node3D = await _trainer(world, Vector3(cursor + 0.6, 0.0, 0.0))
	if trainer != null:
		trainer.rotation.y = deg_to_rad(180.0)
	var span: float = cursor + 1.8

	var centre := span * 0.5
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	# KEEP_WIDTH, because `size` is the VERTICAL extent by default and a rank
	# 17m wide framed to 17m tall renders a row of ants.
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = span
	camera.look_at_from_position(
		Vector3(centre, 1.1, span * 0.9), Vector3(centre, 1.1, 0.0), Vector3.UP)
	await _settle()
	var image := root.get_texture().get_image()
	image.save_png("%s_roster_line.png" % SHOTS)
	print("\nwrote %s_roster_line.png  (%d species + trainer, %.1fm of rank)" % [
		SHOTS, ids.size(), span])
	quit(0)


## The whole roster standing on the REAL meadow, under the real sky and the real
## sun, on the real grass.
##
## The stage the other two modes use paints its floor the meadow's measured
## olive, which is a good proxy and is not the thing. The two defects M11 exists
## to fix — a wolf at the ground's own value and a frog at the ground's own hue —
## are claims about THIS ground, and only five of the eight species ever appear
## in the playground (the encounter director spawns three), so nothing else in
## the project can put the other five in front of the meadow.
func _field() -> void:
	var scene: Node = (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	# The terrain's collision is built over several frames and a creature placed
	# before then falls through the world.
	for i in WORLD_SETTLE:
		await physics_frame

	var player: Node3D = scene.get_node_or_null(^"Player") as Node3D
	var origin: Vector3 = Vector3.ZERO if player == null else player.global_position

	var ids := _order()
	var placed: Array[Node3D] = []
	var cursor := 0.0
	for id in ids:
		var body: Node3D = PAL_SCENE.instantiate()
		body.set_script(BODY)
		scene.add_child(body)
		await process_frame
		body.call("setup", id)
		# Strung out along one axis in front of where the player stands, spaced
		# by measured length so a 3.4m Thornback does not stand inside the
		# Gloamfang.
		var length: float = _model_bounds(body.get_node(^"Model") as Node3D).size.z
		cursor += length * 0.5 + 0.8
		body.call("place_on_ground", origin + Vector3(cursor, 0.0, -14.0))
		cursor += length * 0.5
		body.rotation.y = deg_to_rad(90.0)
		placed.append(body)

	var camera := Camera3D.new()
	camera.fov = 46.0
	camera.far = 900.0
	scene.add_child(camera)
	camera.make_current()
	var middle: Vector3 = origin + Vector3(cursor * 0.5, 0.0, -14.0)
	camera.look_at_from_position(
		middle + Vector3(0.0, 3.4, 15.5), middle + Vector3(0.0, 1.0, 0.0), Vector3.UP)

	await _settle()
	# Claimed again after settling: the playground owns a camera rig that takes
	# `current` back whenever the player moves, and a shot from the player's
	# third-person camera is not the shot this mode is for.
	camera.make_current()
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("%s_roster_field.png" % SHOTS)
	print("wrote %s_roster_field.png  (%d species on the real meadow)" % [SHOTS, placed.size()])
	quit(0)


## One label over the 3D, so the sheet is evidence rather than a picture: a tile
## nobody can name is a tile nobody can act on.
func _caption() -> Label:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var label := Label.new()
	# Centred across the whole frame rather than pinned to its left edge.
	# `_tile()` keeps only the centre columns, and the first version of this put
	# the caption in the part that gets cropped away — a sheet whose labels read
	# "dow Hopper".
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.offset_top = 14.0
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 8)
	layer.add_child(label)
	return label


## Crop the frame to the tile's aspect before resizing.
##
## Resizing a 1400x900 frame straight into a 280x400 cell squashes every
## creature horizontally by 2.2x, which would make a judgement about silhouette
## a judgement about the tool.
func _crop_width() -> int:
	return int(DisplayServer.window_get_size().y * float(TILE.x) / float(TILE.y))


func _tile() -> Image:
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	var width: int = mini(_crop_width(), image.get_width())
	var crop := image.get_region(Rect2i(
		(image.get_width() - width) / 2, 0, width, image.get_height()))
	crop.resize(TILE.x, TILE.y, Image.INTERPOLATE_LANCZOS)
	return crop


func _stage() -> Node3D:
	var world := Node3D.new()
	root.add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	# The ground's own value, near enough. A creature that vanishes against this
	# would vanish in the meadow — which is the whole point of the exercise.
	e.background_color = Color(0.30, 0.33, 0.24)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.70, 0.74, 0.80)
	e.ambient_light_energy = 1.0
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-44.0), deg_to_rad(-36.0), 0.0)
	key.light_energy = 1.5
	world.add_child(key)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	# Measured off the meadow's grass, not invented: the readability question is
	# "does this creature separate from THAT".
	mat.albedo_color = Color(0.33, 0.36, 0.21)
	mat.roughness = 0.95
	ground.material_override = mat
	world.add_child(ground)

	# A COLLIDER under the plane, not just a mesh.
	#
	# `pal_body` is a CharacterBody3D and runs gravity the moment it is visible.
	# Without a floor to land on, every creature fell 29 metres during the 90
	# settle frames and the sheet rendered as the trainer standing alone in an
	# empty field — which is exactly the artefact MA-04 got and reported as
	# "_creatures.png contains no creatures".
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	floor_shape.shape = box
	floor_shape.position = Vector3(0.0, -0.5, 0.0)
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)

	var camera := Camera3D.new()
	camera.name = "Cam"
	camera.fov = 42.0
	camera.far = 900.0
	world.add_child(camera)
	camera.make_current()
	return world


## A real creature: `pal.tscn` with `pal_body.gd`, set up from the species table.
## Everything the game does to a model — fit, retint, yaw, idle clip — happens
## here and nowhere in this file.
func _pal(world: Node3D, id: String, pos: Vector3) -> Node3D:
	var body: Node3D = PAL_SCENE.instantiate()
	body.set_script(BODY)
	world.add_child(body)
	await process_frame
	body.call("setup", id)
	body.position = pos
	# Side-on. A quadruped seen head-on is a face and two legs; the silhouette
	# that has to read at combat distance is the profile.
	body.rotation.y = deg_to_rad(90.0)
	return body


func _trainer(world: Node3D, pos: Vector3) -> Node3D:
	var packed: PackedScene = load(TRAINER_MODEL) as PackedScene
	if packed == null:
		return null
	var node: Node3D = packed.instantiate()
	world.add_child(node)
	await process_frame
	node.position = pos
	# The knight ships un-scaled; fit it to the project's 1.80m ruler the same
	# way the player scene does.
	# The sword and shield are modelled into the trainer's skinned mesh and the
	# game collapses their bones (`scripts/player/trainer_model.gd`, art.json's
	# `hide_bones`) — the trainer cannot fight. The ruler in this sheet has to be
	# the trainer the game shows, not an armed one.
	var skeletons: Array[Skeleton3D] = []
	_collect_skeletons(node, skeletons)
	for skeleton in skeletons:
		for name: String in ["DEF-shield", "DEF-bone.01"]:
			var index := skeleton.find_bone(name)
			if index >= 0:
				skeleton.set_bone_pose_position(index, Vector3.ZERO)
				skeleton.set_bone_pose_scale(index, Vector3.ONE * 0.0001)

	var box := _model_bounds(node)
	if box.size.y > 0.001:
		node.scale = Vector3.ONE * (TRAINER_HEIGHT / box.size.y)
	return node


func _settle() -> void:
	for i in SETTLE_PHYSICS:
		await physics_frame
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw


## What the creature RENDERS as, posed. Bone positions, not a mesh AABB: on a
## skinned mesh Godot's AABB is padded to cover every pose in every clip and
## reported a 1.4m alpaca as 5.40m — its rear-up attack.
func _rendered_height(node: Node3D) -> float:
	var skeletons: Array[Skeleton3D] = []
	_collect_skeletons(node, skeletons)
	var top := -INF
	var bottom := INF
	for skeleton in skeletons:
		for bone in skeleton.get_bone_count():
			var p: Vector3 = (skeleton.global_transform * skeleton.get_bone_global_pose(bone)).origin
			top = maxf(top, p.y)
			bottom = minf(bottom, p.y)
	return 0.0 if top == -INF else top - bottom


func _model_bounds(node: Node3D) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect(node, meshes)
	var box := AABB()
	var started := false
	var to_local := node.global_transform.affine_inverse()
	for mesh in meshes:
		var local: AABB = (to_local * mesh.global_transform) * mesh.get_aabb()
		box = local if not started else box.merge(local)
		started = true
	return box


func _collect(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect(child, into)


func _collect_players(node: Node, into: Array[AnimationPlayer]) -> void:
	if node is AnimationPlayer:
		into.append(node as AnimationPlayer)
	for child in node.get_children():
		_collect_players(child, into)


func _collect_skeletons(node: Node, into: Array[Skeleton3D]) -> void:
	if node is Skeleton3D:
		into.append(node as Skeleton3D)
	for child in node.get_children():
		_collect_skeletons(child, into)
