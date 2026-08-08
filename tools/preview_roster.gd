extends SceneTree

## Contact sheet for CANDIDATE creature art, before any of it is wired into
## `species.json`.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/preview_roster.gd -- <mode>
##
## modes:  roster   every candidate creature, native scale, 1.8m bar each
##         cohesion creatures + Styloo characters + Quaternius environment,
##                  one frame, one light — the two-art-styles test from MA-04
##
## Why this is not `tools/preview_creatures.gd`: that one renders whatever is
## already in `species.json` through `pal.tscn`, which fits every model to a
## collider height and therefore DESTROYS the one measurement a sourcing pass
## needs — what size the pack is actually authored at. This loads the raw
## imported scenes instead and touches no game data.
##
## Every model is left playing its idle clip for a beat before the shot, because
## the bind pose of a skinned animal is not a pose anybody will ever see, and
## judging a silhouette on it is judging the wrong thing.

const TRAINER := 1.80
const SHOTS := "res://shots/"

const CREATURES := [
	# Farm Animal Pack's Pig and Sheep were candidates and were fetched, measured
	# and dropped: they ship only Idle and Jump. See docs/ASSET_LEDGER.md.
	["res://assets/pals/quaternius/Wolf.gltf", "Idle"],
	["res://assets/pals/quaternius/ShibaInu.gltf", "Idle"],
	["res://assets/pals/quaternius/Husky.gltf", "Idle"],
	["res://assets/pals/quaternius/Fox.gltf", "Idle"],
	["res://assets/pals/quaternius/Deer.gltf", "Idle"],
	["res://assets/pals/quaternius/Stag.gltf", "Idle"],
	["res://assets/pals/quaternius/Horse.gltf", "Idle"],
	["res://assets/pals/quaternius/Horse_White.gltf", "Idle"],
	["res://assets/pals/quaternius/Donkey.gltf", "Idle"],
	["res://assets/pals/quaternius/Alpaca.gltf", "Idle"],
	["res://assets/pals/quaternius/Bull.gltf", "Idle"],
	["res://assets/pals/quaternius/Cow.gltf", "Idle"],
	["res://assets/pals/quaternius/Frog.fbx", "FrogArmature|Frog_Idle"],
	["res://assets/pals/quaternius/Rat.fbx", "RatArmature|Rat_Idle"],
]

## The whole Quaternius animal family — glTF and FBX alike — is authored at
## roughly 3x life size (a wolf stands 2.58m). One correction, applied here so
## the sheet shows what the game would show rather than what the pack ships.
## Tunable: this is the number `base_scale` would carry if the pack is adopted.
const PACK_SCALE := 0.32

const CHARACTERS := [
	"res://assets/characters/knight.glb",
	"res://assets/characters/mage.glb",
	"res://assets/characters/dwarf.glb",
]

const SCENERY := [
	"res://assets/environment/stylized_nature/CommonTree_1.gltf",
	"res://assets/environment/stylized_nature/Bush_Common.gltf",
	"res://assets/environment/stylized_nature/Rock_Medium_1.gltf",
]


func _init() -> void:
	var mode := "roster"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]
	_run(mode)


func _run(mode: String) -> void:
	var world := Node3D.new()
	root.add_child(world)
	_light(world)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.34, 0.36, 0.30)
	floor_mesh.material_override = mat
	world.add_child(floor_mesh)

	var camera := Camera3D.new()
	camera.fov = 40.0
	camera.far = 900.0
	world.add_child(camera)
	camera.make_current()

	if mode == "cohesion":
		var placed: Array = _lay_cohesion(world)
		camera.look_at_from_position(Vector3(0.1, 1.7, 8.2), Vector3(0.1, 0.95, 0.0), Vector3.UP)
		await _settle()
		_measure(placed)
		_shot("cohesion")
		quit(0)
		return

	# One tile per creature, each framed on the SAME 2.2m-tall window, so the
	# sheet's cells are directly comparable and a 0.46m rat is visibly a quarter
	# of the 1.8m bar rather than four pixels in a group shot. The composite is
	# assembled by tools/compose_roster.py.
	var tiles := "res://shots/_roster_tiles/"
	DirAccess.make_dir_recursive_absolute(tiles)
	var jobs: Array = CREATURES.duplicate()
	jobs.append([CHARACTERS[0], ""])
	jobs.append([CHARACTERS[1], ""])
	jobs.append([CHARACTERS[2], ""])
	for job: Array in jobs:
		var node := _spawn(world, job[0], job[1], Vector3.ZERO)
		if node == null:
			continue
		_ruler(world, Vector3(-1.15, 0.0, 0.0))
		camera.look_at_from_position(
			Vector3(0.55, 1.15, 4.35), Vector3(0.0, 0.88, 0.0), Vector3.UP)
		await _settle()
		var name := String(job[0]).get_file().get_basename()
		print("  %-14s %5.2f m   %.2fx trainer" % [
			name, _posed_height(node), _posed_height(node) / TRAINER])
		_shot_to("%s%s.png" % [tiles, name])
		for child in world.get_children():
			if child == node or (child is MeshInstance3D and child.mesh is BoxMesh):
				child.queue_free()
		await process_frame
	print("\nwrote tiles to %s" % tiles)
	quit(0)


func _settle() -> void:
	for i in 90:
		await physics_frame
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw


func _measure(placed: Array) -> void:
	print("\nmeasured under Idle, trainer = %.2fm" % TRAINER)
	for entry: Array in placed:
		var node: Node3D = entry[0]
		var h := _posed_height(node)
		print("  %-16s %5.2f m   %.2fx trainer" % [entry[1], h, h / TRAINER])


func _shot(mode: String) -> void:
	_shot_to("%s_%s.png" % [SHOTS, mode])


func _shot_to(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image == null:
		printerr("no image for %s" % path)
		return
	image.save_png(path)


func _lay_roster(world: Node3D) -> Array:
	var placed: Array = []
	var per_row := 6
	var pitch := 3.0
	var i := 0
	for entry: Array in CREATURES:
		var col := i % per_row
		var row := i / per_row
		var pos := Vector3(
			(col - (per_row - 1) * 0.5) * pitch,
			0.0,
			-float(row) * pitch * 1.6
		)
		var node := _spawn(world, entry[0], entry[1], pos)
		if node != null:
			_ruler(world, pos + Vector3(-1.35, 0.0, 0.0))
			placed.append([node, String(entry[0]).get_file().get_basename()])
		i += 1
	# The trainer stands in the same rank so the cast can be compared to its
	# own ruler rather than to an abstract bar.
	var knight := _spawn(world, CHARACTERS[0], "", Vector3(
		0.0, 0.0, pitch * 1.6))
	if knight != null:
		placed.append([knight, "knight (trainer)"])
	return placed


func _lay_cohesion(world: Node3D) -> Array:
	var placed: Array = []
	var spots := [
		[CHARACTERS[0], "", Vector3(-3.1, 0.0, 0.0), "knight (trainer)"],
		[CHARACTERS[1], "", Vector3(-1.9, 0.0, 0.4), "mage (Warden?)"],
		[CHARACTERS[2], "", Vector3(-0.7, 0.0, 0.0), "dwarf"],
		["res://assets/pals/quaternius/Wolf.gltf", "Idle", Vector3(0.6, 0.0, 0.3), "Wolf"],
		["res://assets/pals/quaternius/Deer.gltf", "Idle", Vector3(1.9, 0.0, 0.0), "Deer"],
		["res://assets/pals/quaternius/Fox.gltf", "Idle", Vector3(3.0, 0.0, 0.5), "Fox"],
	]
	for s: Array in spots:
		var node := _spawn(world, s[0], s[1], s[2])
		if node != null:
			placed.append([node, s[3]])
	var x := -5.2
	for path: String in SCENERY:
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			continue
		var node: Node3D = packed.instantiate()
		world.add_child(node)
		node.position = Vector3(x, 0.0, -4.5)
		x += 4.4
	_ruler(world, Vector3(-4.1, 0.0, 0.0))
	return placed


func _spawn(world: Node3D, path: String, clip: String, pos: Vector3) -> Node3D:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		printerr("could not load %s" % path)
		return null
	var node: Node3D = packed.instantiate()
	world.add_child(node)
	node.position = pos
	if path.begins_with("res://assets/pals/"):
		node.scale = Vector3.ONE * PACK_SCALE
	if clip != "":
		var players: Array[AnimationPlayer] = []
		_collect_players(node, players)
		for player in players:
			if player.has_animation(clip):
				player.play(clip)
			else:
				printerr("%s has no clip %s" % [path.get_file(), clip])
	return node


func _ruler(world: Node3D, pos: Vector3) -> void:
	var ruler := MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.12, TRAINER, 0.12)
	ruler.mesh = bar
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.92, 0.90, 0.86)
	grey.emission_enabled = true
	grey.emission = Color(0.30, 0.29, 0.27)
	ruler.material_override = grey
	world.add_child(ruler)
	ruler.position = pos + Vector3(0.0, TRAINER * 0.5, 0.0)


func _light(world: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.18, 0.20)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.70, 0.74, 0.80)
	e.ambient_light_energy = 1.1
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(-38.0), 0.0)
	key.light_energy = 1.5
	world.add_child(key)


## Height of the posed skeleton, which is the number a scale check wants.
##
## `Mesh.get_aabb()` on a skinned mesh returns a box padded to cover every pose
## in every clip: it reported the 1.4m alpaca as 5.40m tall, which is its
## rear-up attack, not its height. Bone positions under the idle clip are the
## honest measurement.
func _posed_height(node: Node3D) -> float:
	var skeletons: Array[Skeleton3D] = []
	_collect_skeletons(node, skeletons)
	var top := -INF
	var bottom := INF
	for skeleton in skeletons:
		for bone in skeleton.get_bone_count():
			var p: Vector3 = (skeleton.global_transform * skeleton.get_bone_global_pose(bone)).origin
			top = maxf(top, p.y)
			bottom = minf(bottom, p.y)
	if top == -INF:
		return 0.0
	# `skeleton.global_transform` already carries the pack-scale applied to the
	# spawned node, so do NOT multiply by it again here.
	return top - bottom


func _collect_skeletons(node: Node, into: Array[Skeleton3D]) -> void:
	if node is Skeleton3D:
		into.append(node as Skeleton3D)
	for child in node.get_children():
		_collect_skeletons(child, into)


func _collect_players(node: Node, into: Array[AnimationPlayer]) -> void:
	if node is AnimationPlayer:
		into.append(node as AnimationPlayer)
	for child in node.get_children():
		_collect_players(child, into)
