extends "res://tools/catalogue_survey.gd"

## F26#0 supplement, not a visual/full-biome acceptance oracle. Reuses the
## production catalogue driver, its staged travel/time and original captures.
## Example (ROOT must grant the single engine token and pin the actual SHA):
## --rendering-method forward_plus --resolution 1920x1080 --script
## tools/capture_renderer_material_census.gd -- --biome=water --preset=Medium
## --source-commit=<40-char SHA> --times=day --subset="Twin Pumps"
## --subset="Veilfall Cascade" --output=<fresh directory>
## Native stdout/stderr must be retained by the caller beside this JSON.

const BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")
var _graphics_capture: Dictionary = {}
var _census: Array[Dictionary] = []
var _resources: Dictionary = {}
var _resource_ids: Dictionary = {}


func _run() -> void:
	_graphics_capture = BOOTSTRAP.prepare(self)
	if _graphics_capture.is_empty():
		quit(1)
		return
	# Unlike the full Stormwood visual matrix, this is a binding inspection at
	# named catalogue locations. It makes no Surge/aftermath mood claim.
	await super._run()


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["graphics_capture"] = _graphics_capture
	_manifest["material_census_scope"] = "Read-only inspection of mounted bindings after each production catalogue capture. Travel and clock are staged by the inherited driver; no material, geometry, collider or renderer defaults are repaired. Captured views and native logs still require independent review. Unmounted sites, culled/streamed families not mounted here, intentional defaults and earlier silent loader substitutions remain unproved."


func _capture_row(row: Dictionary) -> void:
	var count_before := _records.size()
	await super._capture_row(row)
	if _records.size() == count_before:
		return
	_resources = {}
	_resource_ids = {}
	var bindings: Array[Dictionary] = []
	_walk_bindings(_world, bindings)
	_census.append({"frame_id": row.frame_id, "bindings": bindings,
		"resources": _resources, "binding_count": bindings.size(),
		"world_scene": SCENES[_biome_id]})
	_write_manifest()


func _walk_bindings(node: Node, bindings: Array[Dictionary]) -> void:
	var path := str(_world.get_path_to(node))
	var script := node.get_script() as Script
	var owner_script := script.resource_path if script != null else ""
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			for surface in instance.mesh.get_surface_count():
				_add_surface(bindings, instance, path, owner_script, instance.mesh,
					surface, instance.get_active_material(surface), "mesh_instance")
	elif node is MultiMeshInstance3D:
		var instance := node as MultiMeshInstance3D
		if instance.multimesh != null and instance.multimesh.mesh != null:
			var mesh := instance.multimesh.mesh
			for surface in mesh.get_surface_count():
				var active := instance.material_override
				if active == null:
					active = mesh.surface_get_material(surface)
				_add_surface(bindings, instance, path, owner_script, mesh, surface,
					active, "multimesh", {"instances": instance.multimesh.instance_count,
					"visible_instance_count": instance.multimesh.visible_instance_count})
	elif node is GPUParticles3D:
		var particles := node as GPUParticles3D
		for pass_index in particles.draw_passes:
			var mesh := particles.get_draw_pass_mesh(pass_index)
			if mesh == null:
				continue
			for surface in mesh.get_surface_count():
				var active := particles.material_override
				if active == null:
					active = mesh.surface_get_material(surface)
				_add_surface(bindings, particles, path, owner_script, mesh, surface,
					active, "gpu_particle_draw_pass", {"draw_pass": pass_index,
					"emitting": particles.emitting})
		bindings.append({"node": path, "kind": "particle_process",
			"material": _resource_ref(particles.process_material)})
	elif node is CPUParticles3D:
		var particles := node as CPUParticles3D
		if particles.mesh != null:
			for surface in particles.mesh.get_surface_count():
				var active := particles.material_override
				if active == null:
					active = particles.mesh.surface_get_material(surface)
				_add_surface(bindings, particles, path, owner_script, particles.mesh,
					surface, active, "cpu_particle", {"emitting": particles.emitting})
	elif node is Sprite3D:
		bindings.append({"node": path, "kind": "sprite",
			"texture": _resource_ref((node as Sprite3D).texture),
			"material_override": _resource_ref((node as Sprite3D).material_override)})
	elif node is WorldEnvironment:
		bindings.append({"node": path, "kind": "environment",
			"resource": _resource_ref((node as WorldEnvironment).environment)})
	# Terrain3D draws through its own extension rather than MeshInstance3D.
	# Inspect actual material/assets resources; do not load substitute assets.
	if node.is_class("Terrain3D"):
		for property: Dictionary in node.get_property_list():
			var property_name := str(property.name)
			if property_name in ["material", "assets"]:
				var value: Variant = node.get(property_name)
				bindings.append({"node": path, "kind": "terrain_" + property_name,
					"resource": _resource_ref(value as Resource)})
	for child in node.get_children():
		_walk_bindings(child, bindings)


func _add_surface(bindings: Array[Dictionary], node: GeometryInstance3D,
		path: String, owner_script: String, mesh: Mesh, surface: int,
		active: Material, kind: String, extra: Dictionary = {}) -> void:
	var source := mesh.surface_get_material(surface)
	var classification := "bound_material_requires_visual_review"
	if active == null:
		classification = "unbound_primitive_default_requires_source_review" if mesh is PrimitiveMesh \
			else "unbound_surface_requires_source_review"
	elif active is BaseMaterial3D and (active as BaseMaterial3D).albedo_texture == null:
		classification = "untextured_material_may_be_authored_requires_source_review"
	bindings.append({"node": path, "owner_script": owner_script, "kind": kind,
		"visible_in_tree": node.is_visible_in_tree(), "surface": surface,
		"mesh_class": mesh.get_class(), "mesh_path": mesh.resource_path,
		"mesh_source_material": _resource_ref(source),
		"active_material": _resource_ref(active),
		"material_override": _resource_ref(node.material_override),
		"material_overlay": _resource_ref(node.material_overlay),
		"classification": classification, "extra": extra})


func _resource_ref(resource: Resource) -> String:
	if resource == null:
		return ""
	var instance_id := resource.get_instance_id()
	if _resource_ids.has(instance_id):
		return str(_resource_ids[instance_id])
	var key := "resource_%06d" % (_resource_ids.size() + 1)
	_resource_ids[instance_id] = key
	var path := resource.resource_path
	var row := {"class": resource.get_class(), "path": path,
		"resource_name": resource.resource_name, "children": {}, "null_object_properties": []}
	_resources[key] = row # Register before recursion; material graphs can share/cycle.
	if not path.is_empty() and path.begins_with("res://"):
		var source_path := path.split("::")[0]
		row["source_path"] = source_path
		row["source_exists"] = FileAccess.file_exists(source_path) or ResourceLoader.exists(source_path)
	if resource is Texture or resource is Image:
		return key # Inspect bindings, never duplicate pixel/terrain arrays in JSON.
	if resource is Shader:
		row["code_sha256"] = (resource as Shader).code.sha256_text()
		row["code_empty"] = (resource as Shader).code.is_empty()
		return key
	if resource.is_class("Terrain3DMaterial") and resource.has_method("get_shader_rid"):
		var shader_rid: RID = resource.call("get_shader_rid")
		row["builtin_shader_rid_valid"] = shader_rid.is_valid()
		row["builtin_shader_uniform_names"] = []
		if shader_rid.is_valid():
			for parameter: Dictionary in RenderingServer.get_shader_parameter_list(shader_rid):
				row.builtin_shader_uniform_names.append(str(parameter.name))
		# This extension's get_shader_param readback is explicitly unreliable in
		# playground_world.gd. Absence in that getter is not a missing texture.
		row["terrain_limit"] = "Stored assets/override graph and builtin shader uniform names only. get_shader_rid is the builtin shader, distinct from an override; these names alone do not certify the active override or private generated terrain texture arrays."
	if resource is BaseMaterial3D:
		var material := resource as BaseMaterial3D
		row["albedo_rgba"] = [material.albedo_color.r, material.albedo_color.g,
			material.albedo_color.b, material.albedo_color.a]
		row["roughness"] = material.roughness
		row["metallic"] = material.metallic
		row["emission_enabled"] = material.emission_enabled
	if resource is ShaderMaterial:
		var material := resource as ShaderMaterial
		if material.shader != null:
			for uniform: Dictionary in material.shader.get_shader_uniform_list():
				var name := str(uniform.name)
				var value: Variant = material.get_shader_parameter(name)
				if value is Resource:
					row.children["shader_parameter/" + name] = _resource_ref(value)
				elif int(uniform.type) == TYPE_OBJECT:
					row.null_object_properties.append("shader_parameter/" + name)
	# Stored object properties include BaseMaterial textures, Terrain3D assets,
	# terrain shader overrides and Environment.sky/Sky.sky_material.
	for property: Dictionary in resource.get_property_list():
		var name := str(property.name)
		if name == "script" or not (int(property.usage) & PROPERTY_USAGE_STORAGE):
			continue
		if int(property.type) not in [TYPE_OBJECT, TYPE_ARRAY]:
			continue
		var value: Variant = resource.get(name)
		if value is Resource:
			row.children[name] = _resource_ref(value)
		elif value is Array:
			for index in value.size():
				if value[index] is Resource:
					row.children["%s/%d" % [name, index]] = _resource_ref(value[index])
		elif int(property.type) == TYPE_OBJECT:
			row.null_object_properties.append(name)
	return key


func _write_manifest() -> void:
	_manifest["material_census"] = _census
	_manifest["native_error_evidence"] = "Caller must retain actual process stdout/stderr and exit receipt. This inspector cannot infer shader compilation success or prior silent fallback from bound-resource presence."
	_manifest["frames"] = _records
	_manifest["failures"] = _failures
	var file := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	if file == null:
		push_error("Material census receipt could not be opened")
		quit(1)
		return
	file.store_string(JSON.stringify(_manifest, "\t") + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		push_error("Material census receipt flush failed")
		quit(1)
