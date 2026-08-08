extends SceneTree

## Look at riding. M12.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/preview_riding.gd
##
## A mount point that is 30cm inside a creature's back, a rider facing the wrong
## way, or a camera buried in an animal's hindquarters are all invisible to every
## assertion in `tests/test_mount.gd` and obvious in one frame. So this stands the
## trainer beside each rideable creature and then on it, from the side and the
## front, standing and at a gallop, and writes the frames out to be looked at.
##
## It drives the REAL path — `Input.action_press`, `mount.mount()`, the actual
## `pal_body` and the actual spring arm — rather than posing the models by hand.
## A preview that arranges what it wants to see cannot report that mounting does
## not work.
##
## The world here is a flat plane with a `ground_height_at` of zero, which is
## exactly what D09 says to ask: the terrain answers for its own height, and the
## test terrain's answer is nought.

const PLAYER := preload("res://scenes/player/player.tscn")
const MOUNT := preload("res://scripts/pals/mount.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const PARTY_MANAGER := preload("res://scripts/pals/party_manager.gd")
const BAG := preload("res://scripts/player/trainer_inventory.gd")

const OUT_DIR := "res://shots/riding"
const TRAINER_HEIGHT := 1.80


## A floor that can answer for its own height, which is all `mount.gd` and
## `pal_body.place_on_ground` ask of a world.
class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var world := FlatWorld.new()
	world.name = "World"
	root.add_child(world)
	_light(world)
	_ground(world)

	# The scene shape `mount.gd` discovers by duck typing: a bag on the trainer,
	# and a party beside him holding what he would deploy.
	var rig := _camera_rig(world)
	var bag := BAG.new()
	bag.name = "TrainerInventory"
	world.add_child(bag)
	var party := PARTY_MANAGER.new()
	party.name = "Party"
	world.add_child(party)

	var player: CharacterBody3D = PLAYER.instantiate()
	player.name = "Player"
	world.add_child(player)
	player.global_position = Vector3.ZERO

	# A camera of our own for the fixed shots, made current per frame; the rig
	# above is what the last shot uses, so the gameplay framing is also seen.
	var camera := Camera3D.new()
	camera.fov = 45.0
	world.add_child(camera)

	for i in 30:
		await physics_frame

	bag.call("inventory").call("add", MOUNT.SADDLE_ITEM, 1)

	var rideable: Array[String] = []
	for id in SPECIES.ids():
		if MOUNT.is_rideable(id):
			rideable.append(id)
	print("rideable: %s" % ", ".join(rideable))

	for id in rideable:
		await _shoot(world, player, party, camera, rig, id)

	print("wrote frames to %s" % OUT_DIR)
	quit(0)


func _shoot(
	world: Node3D, player: CharacterBody3D, party: Node, camera: Camera3D, rig: Node3D, id: String
) -> void:
	# One pal in the party at a time, so `active()` is unambiguous.
	party.call("clear")
	party.call("add", SPECIES.spawn(id, 0.5))

	player.global_position = Vector3.ZERO
	for i in 20:
		await physics_frame

	var mount: Node = player.call("mount")
	camera.make_current()
	await _frame(camera, Vector3(4.6, 1.6, 0.0), Vector3(0.0, 1.0, 0.0),
		"%s/%s-0-dismounted-side.png" % [OUT_DIR, id])

	if not bool(mount.call("mount")):
		print("  %-14s COULD NOT MOUNT: %s" % [id, mount.call("last_refusal")])
		return

	var creature: Node3D = mount.call("body")
	for i in 10:
		await physics_frame

	var seat: Vector3 = MOUNT.seat_offset(id)
	print("  %-14s back %.2fm  seat %.2fm  rider head %.2fm  base %.1f m/s  gallop %.1f m/s" % [
		id,
		float(MOUNT.ride_data(id).get("back_height", 0.0)),
		seat.y,
		player.global_position.y + TRAINER_HEIGHT,
		MOUNT.ride_speed(id, false),
		MOUNT.ride_speed(id, true),
	])

	var at := creature.global_position
	await _frame(camera, at + Vector3(5.0, 1.9, 0.0), at + Vector3(0.0, 1.2, 0.0),
		"%s/%s-1-mounted-side.png" % [OUT_DIR, id])
	await _frame(camera, at + Vector3(0.0, 1.9, 4.6), at + Vector3(0.0, 1.2, 0.0),
		"%s/%s-2-mounted-front.png" % [OUT_DIR, id])

	# Moving, at a gallop, through the game's own camera. This is the frame that
	# would show a spring arm collapsed inside the animal's rump.
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for i in 90:
		await physics_frame
	var moved := creature.global_position.distance_to(at)
	print("      galloped %.1fm in 1.5s (%.1f m/s), mount stamina %.0f%%" % [
		moved, moved / 1.5, mount.call("stamina_fraction") * 100.0])
	# The moving side shot is aimed on the LAST frame before the shutter. This
	# tool's physics and render cadences are not the game's, so a camera placed
	# four frames early photographs empty grass where the mount used to be.
	camera.make_current()
	await _track(camera, creature, Vector3(6.0, 2.2, 0.0),
		"%s/%s-4-galloping-side.png" % [OUT_DIR, id])

	# THE GAME'S OWN CAMERA, on a mount that has just pulled up. Riding stops the
	# input, not the shot: what this frame is for is the spring arm, which
	# collapses on the first thing it touches and — with the trainer sitting ON an
	# animal — would otherwise spend the whole ride inside its hindquarters.
	Input.action_release("move_forward")
	Input.action_release("sprint")
	for i in 40:
		await physics_frame
	var lens: Camera3D = rig.get_node("Camera3D") as Camera3D
	lens.make_current()
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	print("      spring arm %.1fm from the rider (profile asks for %.1f)" % [
		lens.global_position.distance_to(player.global_position),
		float(MOUNT.config().get("camera", {}).get("distance", 0.0))])
	_save("%s/%s-3-camera-behind.png" % [OUT_DIR, id])
	camera.make_current()

	mount.call("dismount")
	for i in 20:
		await physics_frame


func _frame(camera: Camera3D, at: Vector3, looking_at: Vector3, path: String) -> void:
	camera.global_position = at
	camera.look_at(looking_at, Vector3.UP)
	await _settle()
	_save(path)


## Aim at something that is moving, on the frame the shutter opens.
func _track(camera: Camera3D, subject: Node3D, offset: Vector3, path: String) -> void:
	for i in 4:
		camera.global_position = subject.global_position + offset
		camera.look_at(subject.global_position + Vector3(0.0, 1.2, 0.0), Vector3.UP)
		await process_frame
	camera.global_position = subject.global_position + offset
	camera.look_at(subject.global_position + Vector3(0.0, 1.2, 0.0), Vector3.UP)
	await RenderingServer.frame_post_draw
	_save(path)


func _settle() -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw


func _save(path: String) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		print("  no image for %s" % path)
		return
	image.save_png(path)


func _camera_rig(world: Node3D) -> Node3D:
	var rig := SpringArm3D.new()
	rig.name = "CameraRig"
	rig.spring_length = 5.2
	rig.margin = 0.3
	rig.set_script(load("res://scripts/player/camera_rig.gd"))
	world.add_child(rig)
	var lens := Camera3D.new()
	lens.name = "Camera3D"
	lens.fov = 70.0
	rig.add_child(lens)
	return rig


func _light(world: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.55, 0.66)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.70, 0.75, 0.82)
	e.ambient_light_energy = 1.1
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(-40.0), 0.0)
	key.light_energy = 1.5
	key.shadow_enabled = true
	world.add_child(key)


## A plane to stand on, with a static body under it so the trainer's own
## `move_and_slide` has something to land on when he gets off.
func _ground(world: Node3D) -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.34, 0.40, 0.30)
	mesh.material_override = mat
	world.add_child(mesh)

	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	floor_body.add_child(shape)
	world.add_child(floor_body)
