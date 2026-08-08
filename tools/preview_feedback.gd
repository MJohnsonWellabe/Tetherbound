extends SceneTree

## Photograph the feedback layer: tool HUD line, context prompt, harvest
## counter pop, prop shake/sink/pop, the toast queue coalescing, and the
## level-up flourish.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/preview_feedback.gd
##
## This is the acceptance for the whole layer, and `tests/test_toasts.gd` is
## not: the queue can be provably correct while the toasts draw on top of the
## minimap, the counter pop lands behind the tree, or the context line renders
## as raw bbcode. You have to look at it.
##
## RENDERED, NEVER `--headless`: the prop beats write MultiMesh instance
## transforms, and under the dummy renderer those writes are discarded and the
## whole FX path refuses to start (see `harvestable._fx_start`). A headless run
## of this file would photograph the one configuration the guard exists to
## keep silent.

const HARVEST := preload("res://scripts/world/harvestable.gd")
const TOOLS := preload("res://scripts/items/tools.gd")
const INVENTORY := preload("res://scripts/items/inventory.gd")
const HUD_SCENE := preload("res://scenes/ui/playground_hud.tscn")
const OUT := "res://shots/_feedback_%s.png"

## The trainer stands 1.6m short of this tree, which is exactly where
## `tools.aim_point()` lands a swing (half the 3.2m reach).
const TREE_AT := Vector3(4.0, 0.0, 0.0)
const PLAYER_AT := Vector3(2.4, 0.0, 0.0)


## A trainer that carries something: the duck-typed half of `tools._bag()`.
class Trainer extends CharacterBody3D:
	var bag: RefCounted = null

	func inventory() -> RefCounted:
		return bag


var _hud: CanvasLayer = null
var _toasts: Control = null
var _kit: Node = null
var _world_index: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	_light(world)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	ground.mesh = plane
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color(0.42, 0.48, 0.29)
	ground.material_override = grass
	world.add_child(ground)

	# A scatter the harvest index can read: batch nodes named the way
	# `vegetation.gd` names them, drawn with stand-in cones and tufts.
	var scatter := Node3D.new()
	scatter.name = "Vegetation"
	world.add_child(scatter)
	_tree_batch(scatter, "CommonTree_1_0_0", [
		TREE_AT, Vector3(6.5, 0.0, -3.0), Vector3(2.0, 0.0, -5.0),
	])
	_bush_batch(scatter, "Bush_Common_Flowers_0_0", [
		Vector3(-2.5, 0.0, 1.0), Vector3(-4.0, 0.0, -1.5),
	])

	var index: Node3D = HARVEST.new()
	index.name = "Harvestable"
	world.add_child(index)
	index.call("bind", scatter)
	_world_index = index
	print("indexed %d props (transforms readable: %s)" % [
		int(index.call("count")), str(index.call("transforms_readable"))
	])

	# The trainer: the real 1.8m capsule, with an axe in the bag.
	var player := Trainer.new()
	player.name = "Player"
	player.bag = INVENTORY.new()
	player.bag.call("add", "axe", 1)
	world.add_child(player)
	player.global_position = PLAYER_AT
	player.look_at(Vector3(TREE_AT.x, 0.0, TREE_AT.z), Vector3.UP)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	body.mesh = capsule
	body.position = Vector3(0.0, 0.9, 0.0)
	var coat := StandardMaterial3D.new()
	coat.albedo_color = Color(0.35, 0.42, 0.55)
	body.material_override = coat
	player.add_child(body)

	_kit = TOOLS.new()
	_kit.name = "Tools"
	world.add_child(_kit)
	_kit.call("bind", player, index)

	_hud = HUD_SCENE.instantiate()
	world.add_child(_hud)
	_hud.call("bind_feedback", _kit)
	_toasts = _hud.get_node("Root/Toasts")
	# The M1 tuning readout would fill the left half of every frame with
	# "waiting for player"; these frames are about the feedback layer.
	(_hud.get_node("Root/Readout") as Label).visible = false

	var camera := Camera3D.new()
	camera.fov = 55.0
	world.add_child(camera)
	camera.make_current()
	camera.global_position = PLAYER_AT + Vector3(-1.2, 2.4, 4.6)
	camera.look_at(TREE_AT + Vector3(0.0, 1.2, 0.0), Vector3.UP)

	for i in 40:
		await physics_frame

	# 1. The tool line, with the right tool in hand: "Axe  [RB] Cycle tool" and
	#    "Tree — [A] Gather".
	_kit.call("equip", "axe")
	await _settle(40)
	await _shoot("1_tool_equipped")

	# 2. Bare hands at the same tree: "needs an Axe" with the cycle hint,
	#    because the axe IS in the bag.
	_kit.call("equip", "")
	await _settle(40)
	await _shoot("2_tool_needed")

	# 3. One swing: prop pulse, "+3 Wood" counter pop, arc, "+3 Wood" toast.
	_kit.call("equip", "axe")
	await _settle(10)
	var swung: Dictionary = _kit.call("swing")
	print("swing 1: %s" % str(swung))
	await _settle(8)
	await _shoot("3_harvest_pop")

	# 4. Three more swings: the tree is spent and SINKS; the pickup toast has
	#    coalesced into one "+12 Wood".
	for i in 3:
		_kit.call("swing")
		await _settle(6)
	await _settle(10)
	await _shoot("4_depletion_and_coalesced")

	# 5. The stack: pickups still coalescing, an XP award, the autosave tick —
	#    three toasts, capped, none covering the world.
	_toasts.call("xp", "Bramblit", 44)
	_toasts.call("saved", "autosave")
	await _settle(8)
	await _shoot("5_toast_stack")

	# 6. The level-up flourish, photographed at its overshoot.
	#
	# MAX_VISIBLE is 3 (toasts.gd) and all three slots are already taken by the
	# stack shot above, so this QUEUES rather than showing — the same "queue,
	# don't stack" rule the stack shot is demonstrating. It surfaces once the
	# shortest-lived active toast (Saved, 2.0s) expires and frees a slot; the
	# overshoot bounce is the first 0.4s of ITS OWN time on screen, not of the
	# call that queued it, so the wait has to clear the queue before it can
	# start, and the shot has to land inside that narrow window once it does.
	_toasts.call("level_up", "Bramblit", 5)
	await _settle(126)
	await _shoot("6_levelup_flourish")

	# 7. Regrow: seven minutes pass in one call, the tree pops back in.
	_world_index.call("tick", 500.0)
	await _settle(9)
	await _shoot("7_regrow_pop")

	print("the capsule is 1.80m; toasts sit below the minimap's corner.")
	quit(0)


func _settle(frames: int) -> void:
	for i in frames:
		await physics_frame


func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if shot != null:
		shot.save_png(OUT % name)
		print("wrote %s" % (OUT % name))


func _tree_batch(scatter: Node3D, name: String, at: Array) -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 1.1
	cone.height = 3.2
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.22, 0.42, 0.20)
	cone.material = leaf
	_batch(scatter, name, cone, at, Vector3(0.0, 1.6, 0.0))


func _bush_batch(scatter: Node3D, name: String, at: Array) -> void:
	var tuft := SphereMesh.new()
	tuft.radius = 0.55
	tuft.height = 0.9
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.30, 0.48, 0.22)
	tuft.material = leaf
	_batch(scatter, name, tuft, at, Vector3(0.0, 0.4, 0.0))


func _batch(scatter: Node3D, name: String, mesh: Mesh, at: Array, lift: Vector3) -> void:
	var node := MultiMeshInstance3D.new()
	node.name = name
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = at.size()
	for i in at.size():
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, (at[i] as Vector3) + lift))
	node.multimesh = multi
	scatter.add_child(node)


func _light(world: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.68, 0.84)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.72, 0.76, 0.82)
	e.ambient_light_energy = 1.1
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-44.0), deg_to_rad(-38.0), 0.0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	world.add_child(sun)
