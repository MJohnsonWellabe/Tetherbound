extends SceneTree

## GATE-D. Renders the `bushes` layer's seven models side by side so the "these
## read tropical against a temperate meadow" claim from a blind critique of one
## camp frame can be checked against the MESHES. The layer is shared
## corridor-wide, so if the claim holds it is not a camp defect, it is every
## band's ground cover, and it belongs to whoever owns vegetation.json.
##
## READ THIS BEFORE JUDGING COLOUR FROM THIS FRAME. It loads each .gltf raw and
## does NOT run the scatter pipeline, so the layer's own `retexture` map is not
## applied. Bush_Common and Bush_Common_Flowers therefore render CRIMSON here.
## That is the pack's autumn twisted-oak leaf texture, it is a known thing the
## config already fixes (`retexture` points `Leaves_TwistedTree` at
## `Leaves_NormalTree_C.png`, with its own comment explaining that no colour
## multiply turns red into green), and it is NOT what the game shows. This
## frame is evidence about SHAPE and SCALE, which no retexture changes.
##
## Measured heights, which is the part worth keeping:
##   Bush_Common 1.58m   Bush_Common_Flowers 1.58m   Fern_1 0.84m
##   Plant_1 1.01m       Plant_1_Big 2.35m
##   Plant_7 0.25m       Plant_7_Big 0.25m

const MODELS := [
	"Bush_Common", "Bush_Common_Flowers", "Fern_1",
	"Plant_1", "Plant_1_Big", "Plant_7", "Plant_7_Big",
]
const DIR := "res://assets/environment/stylized_nature/%s.gltf"


func _init() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.47, 0.38)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.78, 0.72)
	e.ambient_light_energy = 0.9
	env.environment = e
	world.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	sun.light_energy = 1.2
	world.add_child(sun)

	var x := 0.0
	for name: String in MODELS:
		var packed: PackedScene = load(DIR % name)
		if packed == null:
			print("MISSING ", name)
			continue
		var inst: Node3D = packed.instantiate()
		inst.position = Vector3(x, 0.0, 0.0)
		world.add_child(inst)
		var aabb := _aabb_of(inst)
		print("%-20s height=%.2fm  width=%.2fm" % [name, aabb.size.y, aabb.size.x])
		x += 1.6

	var cam := Camera3D.new()
	world.add_child(cam)
	# add_child BEFORE look_at: Node3D.look_at() requires the node to be inside
	# the tree and errors out otherwise, leaving the camera at its default
	# orientation and the frame pointing at nothing.
	# look_at_from_position, not position-then-look_at: inside SceneTree._init()
	# nothing added this frame is "inside the tree" yet, and Node3D.look_at()
	# hard-requires that -- it errors and leaves the camera at its default
	# orientation, which renders a frame of nothing that still saves fine.
	cam.look_at_from_position(
		Vector3((x - 1.6) * 0.5, 1.15, 5.2),
		Vector3((x - 1.6) * 0.5, 0.6, 0.0), Vector3.UP)
	cam.current = true

	for i in 8:
		await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png("res://shots/bushes/bushes_layer.png")
	print("wrote shots/bushes/bushes_layer.png")
	quit(0)


func _aabb_of(node: Node) -> AABB:
	var out := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		var box := mi.get_aabb()
		if first:
			out = box
			first = false
		else:
			out = out.merge(box)
	return out
