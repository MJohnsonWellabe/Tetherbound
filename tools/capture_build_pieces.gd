extends SceneTree

## Capture R2.6's five build pieces for the required blind-judge visual pass.
## Standalone-stage pattern (`capture_village_npcs.gd`) -- no
## `meadows_playground.tscn` dependency, so this doesn't touch the
## render-perf wall `RENDER-PERF-DIAG` diagnosed on the full scene.
##
## Two shots: a side-by-side catalogue lineup (floor shot near-top-down so
## its pattern actually reads, per round 1's blind critique), and a small
## assembled corner (two floor tiles, a back wall, a side wall, a door
## filling the rest of the back run, a roof spanning both walls, a fence
## standing apart) -- positions below use each piece's own measured AABB
## (`tools/_diag_piece_sizes.gd`, round 2, not committed) so edges actually
## meet rather than the round-1 guessed offsets that floated and gapped.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_build_pieces.gd

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 20

const MESHES := {
	"floor": "res://assets/buildings/quaternius_medieval/Floor_UnevenBrick.gltf",
	"wall": "res://assets/buildings/quaternius_medieval/Wall_Plaster_Straight.gltf",
	"door": "res://assets/buildings/quaternius_medieval/Door_1_Flat.gltf",
	"roof": "res://assets/buildings/quaternius_medieval/Roof_RoundTile_2x1.gltf",
	"fence": "res://assets/buildings/quaternius_medieval/Prop_WoodenFence_Single.gltf",
}
const ORDER := ["floor", "wall", "door", "roof", "fence"]

## Round-1 critique named flat, shadowless lighting as the reason the plaster
## wall read as a texture-less white slab. A single strong key with real
## shadows (an outdoor sun angle, not the soft character-portrait rig
## `capture_village_npcs.gd` uses) is the fix that stays in-scene.
func _stage() -> Node3D:
	var world := Node3D.new()
	root.add_child(world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.11, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.65)
	env.ambient_light_energy = 0.9
	env_node.environment = env
	world.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-48.0), deg_to_rad(-35.0), 0.0)
	sun.light_energy = 2.4
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	world.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-15.0), deg_to_rad(150.0), 0.0)
	fill.light_energy = 0.5
	fill.light_color = Color(0.75, 0.82, 0.95)
	world.add_child(fill)
	return world


func _shoot(path: String, camera: Camera3D) -> void:
	camera.make_current()
	for i in SETTLE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		push_error("viewport returned no image")
		return
	var error := image.save_png(path)
	if error != OK:
		push_error("save_png failed (%d)" % error)
		return
	print("  %s -> %s" % [path.get_file(), path])


func _piece(mesh_path: String, at: Vector3, yaw_deg: float, parent: Node3D) -> void:
	var p := BUILD_PIECE.new()
	parent.add_child(p)
	p.call("build_real", mesh_path)
	p.position = at
	p.rotation.y = deg_to_rad(yaw_deg)


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await _lineup()
	await _corner()
	quit(0)


func _lineup() -> void:
	var world := _stage()
	for i in ORDER.size():
		var id: String = ORDER[i]
		_piece(MESHES[id], Vector3((i - (ORDER.size() - 1) / 2.0) * 2.6, 0.0, 0.0), 0.0, world)

	var camera := Camera3D.new()
	camera.fov = 45.0
	world.add_child(camera)
	# Higher and steeper than round 1's near-eye-level shot, so the floor
	# tile's own pattern is actually legible instead of foreshortened to a
	# sliver -- the rest of the lineup still reads fine from this angle.
	camera.look_at_from_position(Vector3(0.0, 4.4, 7.6), Vector3(0.0, 0.6, 0.0), Vector3.UP)
	await _shoot("%s/build_pieces_lineup.png" % OUT_DIR, camera)
	world.queue_free()


## A wall-and-doorway frontage sized from each piece's real AABB (floor
## 2x2m; wall 2.0m wide / 3.12m tall, origin at its base; door 1.12m wide /
## 2.1m tall, origin at its LEFT edge, not its centre; roof 3.3m wide,
## origin at the ridge with the eave hanging 0.34m below it) so the wall's
## right edge (x=0.5) and the door's left edge (also x=0.5, given the
## door's own origin convention) actually meet, and the roof centres over
## the combined run rather than round 1's guessed offsets that floated and
## gapped. One wall, not two — round 1's second wall added a corner seam
## this capture couldn't align cleanly with the tools at hand; a single
## wall-plus-doorway frontage is the arrangement this kit can show
## correctly without a real snapping system, which is `EV6`'s job, not
## this item's.
func _corner() -> void:
	var world := _stage()

	_piece(MESHES["floor"], Vector3(0.0, 0.0, 0.0), 0.0, world)
	_piece(MESHES["wall"], Vector3(-0.5, 0.0, -1.0), 0.0, world)
	_piece(MESHES["door"], Vector3(0.5, -0.04, -1.0), 0.0, world)
	_piece(MESHES["roof"], Vector3(0.0, 3.12, -1.0), 0.0, world)
	_piece(MESHES["fence"], Vector3(2.2, 0.0, 1.2), 20.0, world)

	var camera := Camera3D.new()
	camera.fov = 48.0
	world.add_child(camera)
	camera.look_at_from_position(Vector3(4.0, 2.4, 4.6), Vector3(0.0, 1.3, -0.6), Vector3.UP)
	await _shoot("%s/build_pieces_corner.png" % OUT_DIR, camera)
	world.queue_free()
