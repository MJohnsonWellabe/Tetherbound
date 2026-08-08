extends SceneTree

## Look at the companion. Wave 1 of the visual pass, and the one that matters
## most: a creature-collector where the creature is a row in a menu is not the
## genre it claims to be, and that is exactly the kind of thing invisible to
## every assertion in `tests/test_companion.gd` and obvious in one frame.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/preview_companion.gd
##
## Drives the REAL path: the real `pal_body`, the real `party_manager`, and
## `companion.gd`'s own `_physics_process` — nothing here poses a model by hand.
## A flat world with `ground_height_at() == 0.0`, the same fixture
## `preview_riding.gd` uses, because all D09 asks of a world is that it answer.

const PLAYER := preload("res://scenes/player/player.tscn")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const PARTY_MANAGER := preload("res://scripts/pals/party_manager.gd")
const MOUNT := preload("res://scripts/pals/mount.gd")
const BAG := preload("res://scripts/player/trainer_inventory.gd")

const OUT_DIR := "res://shots/companion"


class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


var _world: Node3D = null
var _player: CharacterBody3D = null
var _party: Node = null
var _camera: Camera3D = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_world = FlatWorld.new()
	_world.name = "World"
	root.add_child(_world)
	_light()
	_ground()

	_party = PARTY_MANAGER.new()
	_party.name = "Party"
	_world.add_child(_party)

	# `mount.gd`'s saddle check reads `_player.call("inventory")`, which resolves
	# `../TrainerInventory` off the player — the same sibling shape
	# `preview_riding.gd` stands up. Without it shot 7 (mounting) does not just
	# skip; it null-calls, throws mid-coroutine, and the script never reaches its
	# own `quit(0)` — the SceneTree spins forever rendering nothing new.
	var bag := BAG.new()
	bag.name = "TrainerInventory"
	_world.add_child(bag)

	_player = PLAYER.instantiate()
	_player.name = "Player"
	_world.add_child(_player)
	_player.global_position = Vector3.ZERO

	_camera = Camera3D.new()
	_camera.fov = 55.0
	_world.add_child(_camera)
	_camera.make_current()

	for i in 30:
		await physics_frame

	_party.call("add", SPECIES.spawn("wild_grazer", 0.5))
	var companion: Node = _player.call("companion")
	print("companion node: %s" % companion)

	# 1 — appears beside the trainer, unprompted, the moment there is a party.
	for i in 40:
		await physics_frame
	print("out after spawn: %s  species: %s" % [companion.call("is_out"), companion.call("species_id")])
	await _frame(Vector3(0.0, 2.4, 6.0), Vector3(0.0, 1.0, 0.0), "01-appears-beside-you.png")

	# 2 — walks away; the companion should be following by the time it settles.
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for i in 240:
		await physics_frame
	Input.action_release("move_forward")
	Input.action_release("sprint")
	for i in 20:
		await physics_frame
	var body: Node3D = companion.call("body")
	var dist := (_player.global_position - body.global_position).length() if body != null else -1.0
	print("distance after a sprint away: %.1fm" % dist)
	await _frame(
		_player.global_position + Vector3(2.0, 2.4, 8.0), _player.global_position, "02-catching-up.png"
	)

	# 3 — stop, and let it settle and graze. Held long enough to cross into a
	# graze or idle-variant beat on the config's own numbers.
	for i in 420:
		await physics_frame
	dist = (_player.global_position - companion.call("body").global_position).length()
	print("distance once settled: %.1fm" % dist)
	await _frame(
		_player.global_position + Vector3(3.0, 2.0, 3.0), _player.global_position, "03-settled-grazing.png"
	)

	# 4 — a fight opens (locomotion suspended). The companion has to vanish, not
	# stand there while a separate ally body fights in front of it.
	_player.call("set_locomotion_enabled", false)
	for i in 20:
		await physics_frame
	print("out during a suppressed world: %s" % companion.call("is_out"))
	await _frame(_player.global_position + Vector3(0.0, 2.4, 6.0), _player.global_position, "04-hidden-in-combat.png")

	# 5 — the fight ends. It has to come back without the player doing anything.
	_player.call("set_locomotion_enabled", true)
	for i in 60:
		await physics_frame
	print("out after the world returns: %s" % companion.call("is_out"))
	await _frame(_player.global_position + Vector3(0.0, 2.4, 6.0), _player.global_position, "05-returns-after-combat.png")

	# 6 — swap the active pal. The companion has to become the NEW one, not keep
	# showing the old species.
	_party.call("add", SPECIES.spawn("wild_stalker", 0.5))
	_party.call("set_active", 1)
	for i in 60:
		await physics_frame
	print("species after switching the active pal: %s" % companion.call("species_id"))
	await _frame(_player.global_position + Vector3(0.0, 2.4, 6.0), _player.global_position, "06-swaps-on-active-change.png")

	# 7 — mount the (now active) Fox... no, mount needs a rideable species and a
	# saddle. Switch back to the Stag and mount it: the companion and the mount
	# ARE the same creature, so it must vanish as a follower the instant it
	# becomes a ride.
	_party.call("set_active", 0)
	bag.call("inventory").call("add", MOUNT.SADDLE_ITEM, 1)
	for i in 40:
		await physics_frame
	var mount: Node = _player.call("mount")
	var mounted := bool(mount.call("mount"))
	for i in 20:
		await physics_frame
	# Checked after a physics frame has actually run: companion.gd only despawns
	# in _physics_process, so reading is_out() in the same call as mount() would
	# race and print stale state even though the frame below is correct.
	print("mounted: %s  companion out while mounted: %s" % [mounted, companion.call("is_out")])
	await _frame(_player.global_position + Vector3(0.0, 2.6, 6.0), _player.global_position, "07-hidden-while-mounted.png")
	mount.call("dismount")
	for i in 40:
		await physics_frame
	print("companion out after dismounting: %s" % companion.call("is_out"))
	await _frame(_player.global_position + Vector3(0.0, 2.4, 6.0), _player.global_position, "08-returns-after-dismount.png")

	print("wrote frames to %s" % OUT_DIR)
	quit(0)


func _frame(at: Vector3, looking_at: Vector3, name: String) -> void:
	_camera.make_current()
	_camera.global_position = at
	_camera.look_at(looking_at + Vector3(0.0, 1.0, 0.0), Vector3.UP)
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("  no image for %s" % name)
		return
	image.save_png("%s/%s" % [OUT_DIR, name])
	print("frame -> %s/%s" % [OUT_DIR, name])


func _light() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.55, 0.66)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.70, 0.75, 0.82)
	e.ambient_light_energy = 1.1
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	_world.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(-40.0), 0.0)
	key.light_energy = 1.5
	key.shadow_enabled = true
	_world.add_child(key)


func _ground() -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.34, 0.40, 0.30)
	mesh.material_override = mat
	_world.add_child(mesh)

	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	floor_body.add_child(shape)
	_world.add_child(floor_body)
