extends SceneTree

## Focused regression for the Bramblebun redesign's UV/albedo ownership.
## The expected texture is read from the installed redesign GLB, not pinned as
## a duplicate test literal. Ordinary, alpha and shiny all instantiate the
## actual CreatureBody dressing path.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const REDESIGN_SCENE := preload("res://assets/creatures/tetherbound/bramblebun_redesign/models/creature_bramblebun_redesign_lod0.glb")
const LEGACY_FRAGMENT := "/bramblebun/models/bramblebun_extracted_"

var _assertions := 0
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	var source_art := REDESIGN_SCENE.instantiate() as Node3D
	root.add_child(source_art)
	var source_textures := _active_albedo_textures(source_art)
	_check(source_textures.size() == 1, "redesign source exposes exactly one textured surface")
	var expected: Texture2D = source_textures[0] if source_textures.size() == 1 else null
	_check(expected != null, "redesign source has a base-colour texture")
	var look: Dictionary = SPECIES.placeholder("bramblebun")
	_check(BODY.colourway_source_species("bramblebun", look) == "bramblebun_redesign",
		"resolver owns Bramblebun colourways with redesign source")

	for variant: String in ["ordinary", "alpha", "shiny"]:
		var body := CREATURE_SCENE.instantiate() as Node3D
		body.name = "Binding_%s" % variant
		body.set_script(BODY)
		root.add_child(body)
		body.call("setup", "bramblebun", variant == "shiny")
		if variant == "alpha":
			body.call("set_alpha", true)
		body.set_physics_process(false)
		var textures := _active_albedo_textures(body.call("model_pivot") as Node3D)
		_check(textures.size() == 1, "%s exposes exactly one textured surface" % variant)
		if textures.size() == 1 and expected != null:
			var actual: Texture2D = textures[0]
			_check(actual == expected, "%s retains exact redesign texture resource identity" % variant)
			_check(not actual.resource_path.contains(LEGACY_FRAGMENT),
				"%s never binds the legacy UV atlas" % variant)
			print("BRAMBLEBUN_BINDING variant=%s texture_id=%d path=%s expected_id=%d" % [
				variant, actual.get_instance_id(), actual.resource_path, expected.get_instance_id()])
		body.queue_free()
		await process_frame

	source_art.queue_free()
	print("BRAMBLEBUN_BINDING_RESULT assertions=%d failures=%s" % [
		_assertions, JSON.stringify(_failures)])
	quit(0 if _failures.is_empty() else 1)


func _active_albedo_textures(node: Node) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		for child: Node in current.get_children():
			pending.append(child)
		if not current is MeshInstance3D:
			continue
		var instance := current as MeshInstance3D
		if instance.mesh == null or not instance.visible:
			continue
		for surface in instance.mesh.get_surface_count():
			var material := instance.get_active_material(surface) as BaseMaterial3D
			if material != null and material.albedo_texture != null:
				textures.append(material.albedo_texture)
	return textures


func _check(condition: bool, label: String) -> void:
	_assertions += 1
	if not condition:
		_failures.append(label)
		push_error("BRAMBLEBUN_BINDING failed: %s" % label)
