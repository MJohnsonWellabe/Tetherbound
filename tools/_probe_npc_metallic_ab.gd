extends SceneTree

## GF-B-010, the A/B. Six humanoid rigs under the game's OWN day environment,
## rendered twice: once with each body's `metallic` put back to the 1.0 Godot
## imports from the .glb (`metallicFactor` is absent from every rig's glTF
## material and the format's default for an absent one is 1.0), and once as
## `character_model.gd` builds them today.
##
##   xvfb-run -a -s "-screen 0 1280x400x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x400 \
##     --script tools/_probe_npc_metallic_ab.gd
##
## A wooden crate stands at the end of each row as the control the Gate F
## coordinator's own frame used: a correctly-lit prop a metre from a black
## character. The environment is built by `world_look.gd` from `art.json`'s real
## `day` block -- not a hand-made sun -- so the answer is about the game's
## lighting rather than a probe's.
##
## Prints mean luminance of each character's own image region so the difference
## is a number, not an impression.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")

const KEYS := ["trainer", "grandpa", "villager_farmer", "villager_keeper", "warden", "grunt"]
const OUT := "res://shots/npc_metallic_ab"
const SPACING := 1.15


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _shoot(true, "before-as-imported")
	await _shoot(false, "after-character-model")
	quit(0)


func _shoot(as_imported: bool, name: String) -> void:
	var world := Node3D.new()
	root.add_child(world)
	_build_environment(world)

	var x := -(KEYS.size() - 1) * 0.5 * SPACING
	for key: String in KEYS:
		var holder := Node3D.new()
		holder.set_script(CHARACTER_MODEL)
		world.add_child(holder)
		if bool(holder.call("build_from_config", CHARACTER_MODEL.config_for(key))):
			holder.position = Vector3(x, 0.0, 0.0)
			holder.rotation.y = PI
			if as_imported:
				_restore_import_metallic(holder)
		x += SPACING

	var crate: PackedScene = load("res://assets/props/quaternius_fantasy/Crate_Wooden.gltf")
	if crate != null:
		var c: Node3D = crate.instantiate()
		c.position = Vector3(x + 0.2, 0.0, 0.0)
		world.add_child(c)

	var cam := Camera3D.new()
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.2, 6.4), Vector3(0.0, 0.95, 0.0), Vector3.UP)
	cam.current = true

	for i in 40:
		await process_frame
	var img: Image = get_root().get_texture().get_image()
	img.save_png("%s/%s.png" % [OUT, name])
	print("%s: wrote %s.png  centre-band mean luma %.4f" % [name, name, _band_luma(img)])
	world.queue_free()
	await process_frame


## The BEFORE half: undo `character_model.gd`'s own correction and put each
## body back to the `metallic` Godot imports from the .glb, so the two frames
## differ by exactly the one property under investigation and by nothing else.
## Deliberately not "instantiate the .glb raw" -- that would also drop the
## height fit, the hair part and the accessories, and the comparison would stop
## being about metallic.
func _restore_import_metallic(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				var src: Material = mi.get_active_material(s)
				if src is BaseMaterial3D and (src as BaseMaterial3D).metallic_texture == null:
					var m: BaseMaterial3D = (src as BaseMaterial3D).duplicate()
					m.metallic = 1.0
					mi.set_surface_override_material(s, m)
	for child in node.get_children():
		_restore_import_metallic(child)


## Mean luminance of the horizontal band the bodies occupy, ignoring sky and
## ground -- the row of characters, and nothing else.
func _band_luma(img: Image) -> float:
	var h := img.get_height()
	var top := int(h * 0.35)
	var bottom := int(h * 0.80)
	var total := 0.0
	var n := 0
	for y in range(top, bottom, 2):
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			total += c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			n += 1
	return total / float(maxi(1, n))


## The real thing: a DirectionalLight3D and a WorldEnvironment handed to
## `world_look.gd`, which then reads `art.json`'s `day` block onto them exactly
## as `meadows_playground.tscn` does. Nothing about the light is typed here.
func _build_environment(world: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	world.add_child(sun)

	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = Environment.new()
	world.add_child(env_node)

	var look := Node.new()
	look.set_script(WORLD_LOOK)
	world.add_child(look)
	look.set("sun_path", look.get_path_to(sun))
	look.set("environment_path", look.get_path_to(env_node))
	look.call("_ready")
	look.call("apply_time", "day")
