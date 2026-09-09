extends SceneTree

## Initialized, non-rendering preflight for the creature mipmap experiment.
## It builds ordinary production CreatureBody instances and reports the active
## material/texture state. A null Image is reported as unavailable, never as zero.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const IDS: Array[String] = [
	"pebbik", "skyrill", "voltarach", "torrentoad", "water_cragclaw",
	"sparkit", "galecrest", "water_mosshell",
]

var _failures: Array[String] = []
var _records: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var holder := Node3D.new()
	holder.name = "CreatureMipmapPreflight"
	root.add_child(holder)

	for id: String in IDS:
		var body := CREATURE_SCENE.instantiate() as CharacterBody3D
		if body == null:
			_failures.append("%s: creature scene did not instantiate as CharacterBody3D" % id)
			continue
		body.set_script(BODY)
		holder.add_child(body)
		body.set_physics_process(false)
		body.call("setup", id, false)
		var before := _records.size()
		_collect_materials(body, id, body)
		if _records.size() == before:
			_failures.append("%s: production body exposed no active BaseMaterial3D" % id)

	var available_images := 0
	for record: Dictionary in _records:
		if bool(record.get("image_available", false)):
			available_images += 1
	print("CREATURE_MIPMAP_PREFLIGHT=%s" % JSON.stringify({
		"ids": IDS,
		"records": _records,
		"active_images_available": available_images,
		"failures": _failures,
	}))
	holder.queue_free()
	await process_frame
	await process_frame
	quit(0 if _failures.is_empty() else 1)


func _collect_materials(node: Node, id: String, body: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh := instance.mesh
		for surface: int in (mesh.get_surface_count() if mesh != null else 0):
			var material := instance.get_active_material(surface) as BaseMaterial3D
			if material == null:
				continue
			var albedo := material.albedo_texture
			var image: Image = albedo.get_image() if albedo != null else null
			_records.append({
				"id": id,
				"node": str(body.get_path_to(instance)),
				"surface": surface,
				"material_name": material.resource_name,
				"material_path": material.resource_path,
				"texture_filter": int(material.texture_filter),
				"albedo_class": albedo.get_class() if albedo != null else "",
				"albedo_path": albedo.resource_path if albedo != null else "",
				"texture_size": [albedo.get_width(), albedo.get_height()] if albedo != null else [],
				"image_available": image != null and not image.is_empty(),
				"image_mipmap_count": image.get_mipmap_count() if image != null and not image.is_empty() else null,
				"normal_path": material.normal_texture.resource_path if material.normal_texture != null else "",
				"emission_enabled": material.emission_enabled,
				"emission_energy": material.emission_energy_multiplier,
				"roughness": material.roughness,
				"metallic": material.metallic,
			})
	for child: Node in node.get_children():
		_collect_materials(child, id, body)
