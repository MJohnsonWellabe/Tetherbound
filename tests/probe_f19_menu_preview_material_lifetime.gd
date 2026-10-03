extends SceneTree

## Game owns the pause menu outside the disposable world scene. Its real
## creature viewport was therefore outside earlier world material censuses.
## Direct preview selection is a disclosed component fixture, not an offer,
## paid action, visual judgment or earned-campaign witness.
const PREVIEW := preload("res://scripts/ui/creature_viewport.gd")
var _held: Array[Resource] = []
var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for treatment: String in ["baseline", "retain-preview-materials"]:
		print("F19 MENU PREVIEW BEGIN " + treatment)
		var preview := PREVIEW.new()
		root.add_child(preview)
		for species: String in ["veridian", "solmane", ""]:
			if treatment == "retain-preview-materials": _observe(preview)
			print("F19 MENU PREVIEW SELECT " + JSON.stringify({"treatment": treatment, "species": species}))
			preview.set_species(species)
			if not species.is_empty():
				var body: Node3D = preview.get("_body")
				if not is_instance_valid(body) or not is_instance_valid(body.get("_model")):
					_failures.append("Actual imported preview model unavailable: " + species)
			for frame in 3: await process_frame
		if treatment == "retain-preview-materials": _observe(preview)
		print("F19 MENU PREVIEW DELETE " + treatment)
		preview.queue_free()
		for frame in 4: await process_frame
		_held.clear()
		for frame in 3: await process_frame
		print("F19 MENU PREVIEW END " + treatment)
	print("F19 MENU PREVIEW DIAGNOSTIC ONLY " + JSON.stringify({"failures": _failures,
		"actual_models": ["veridian", "solmane"], "acceptance": false}))
	quit(0 if _failures.is_empty() else 1)

func _observe(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		for material: Material in [mesh_node.material_override, mesh_node.material_overlay]:
			if material != null: _held.append(material)
		if mesh_node.mesh != null:
			for surface in mesh_node.mesh.get_surface_count():
				for material: Material in [mesh_node.get_active_material(surface),
						mesh_node.get_surface_override_material(surface),
						mesh_node.mesh.surface_get_material(surface)]:
					if material != null: _held.append(material)
	for child: Node in node.get_children(): _observe(child)
