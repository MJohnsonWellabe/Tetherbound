extends "res://tests/smoke_f19_veridian_functional.gd"

## Diagnostic only: original choice/save/reload, with actual whole-world
## teardown. Earlier retention sampled world/choice readiness, before the
## choice could create or replace resources. Resample all exposed geometry
## Material references immediately before each actual world deletion, including
## hidden surface overrides missed by get_active_material. Do not retain native
## Mesh/MultiMesh resources: that prior counterfactual amplified errors.
const LABEL_DELETE_PROBE := preload("res://tests/helpers/f19_label_base_teardown_probe.gd")
const SPRITE_DELETE_PROBE := preload("res://tests/helpers/f19_sprite_base_teardown_probe.gd")
var _treatment := "baseline"
var _held: Array[Resource] = []
var _held_ids: Dictionary = {}
var _new_material_count := 0
var _new_material_owners: Array[String] = []
var _hold_owner := ""
var _retained_total := 0

func _run() -> void:
	_run_diagnostic.call_deferred()

func _run_diagnostic() -> void:
	if not preload("res://tests/helpers/f19_functional_offload.gd").configure("veridian_material_diagnostic"):
		quit(2)
		return
	await _boot_world()
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		quit(2)
		return
	for treatment: String in ["baseline", "retain-late-cpu-materials"]:
		_treatment = treatment
		print("F19 WORLD MATERIAL BEGIN " + JSON.stringify({
			"treatment": treatment, "acceptance": false,
			"scope": "Original space-accept with actual save/reload; original gameplay fixtures retained"}))
		await _scenario(treatment, 4, "accept", "")
		for frame in 3: await process_frame
		if treatment == "retain-late-cpu-materials" and _retained_total == 0:
			_fail("Late CPU particle counterfactual observed no retained actual Materials")
		print("F19 WORLD MATERIAL END " + JSON.stringify({"treatment": treatment, "failures": _failures}))
	# Keep the final world's actual resources alive through its destruction.
	_observe_world("pre-world-delete")
	for child: Node in root.get_children():
		if child.name != "Game": child.queue_free()
	for frame in 4: await process_frame
	_held.clear()
	_held_ids.clear()
	for frame in 3: await process_frame
	print("F19 WORLD MATERIAL DIAGNOSTIC ONLY; counterfactual cannot count as clean acceptance")
	quit(0 if _failures.is_empty() and _max_party_seen <= 5 else 1)

func _boot_world() -> void:
	# Preserve every retained reference until the old world's queued native
	# destruction and the inherited fresh world's ordinary settle complete.
	if is_instance_valid(_world): _observe_world("pre-world-delete")
	var old_resources: Array[Resource] = _held.duplicate()
	await super._boot_world()
	_held.clear()
	_held_ids.clear()
	_observe_world("world-ready")
	old_resources.clear()

func _drive_to_choice(climax: Node, label: String) -> bool:
	var reached: bool = await super._drive_to_choice(climax, label)
	if reached: _observe_world("choice-ready")
	return reached

func _read_the_choice(climax: Node, label: String) -> bool:
	_prompt_state("before-reading", climax, label)
	var read: bool = await super._read_the_choice(climax, label)
	_prompt_state("after-reading", climax, label)
	return read

func _prompt_state(phase: String, climax: Node, label: String) -> void:
	var player := _world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null: return
	var prompts: Array = []
	for key: String in ["_accept_prompt", "_refuse_prompt"]:
		var prompt: Node3D = climax.get(key)
		if is_instance_valid(prompt):
			prompts.append({"key": key, "position": str(prompt.global_position),
				"distance": player.global_position.distance_to(prompt.global_position),
				"live": not (prompt.call("interaction_offer", player.global_position) as Dictionary).is_empty()})
	print("F19 PROMPT OBSERVED " + JSON.stringify({"phase": phase, "label": label,
		"player_position": str(player.global_position), "velocity": str(player.velocity),
		"on_floor": player.is_on_floor(), "prompts": prompts}))

func _observe_world(phase: String) -> void:
	var previous_held := _held.size()
	_new_material_count = 0
	_new_material_owners.clear()
	var state := {"labels": [], "existing_script_labels": [], "geometry_count": 0,
		"geometry_classes": {}, "particles": [], "sprites": []}
	_observe(_world, state)
	if phase == "choice-ready" and _treatment == "retain-final-world-materials" and _held.is_empty():
		_fail("Final-resource counterfactual retained no actual geometry resources")
	if phase == "choice-ready" and _treatment == "detach-world-sprites" and (state["sprites"] as Array).is_empty():
		_fail("Sprite counterfactual observed no actual world Sprite3D")
	print("F19 WORLD MATERIAL OBSERVED " + JSON.stringify({
		"phase": phase, "treatment": _treatment, "held_resources": _held.size(),
		"new_resource_count": _held.size() - previous_held,
		"new_material_count": _new_material_count,
		"new_material_owner_samples": _new_material_owners,
		"new_material_owner_sample_limit": 64,
		"geometry_count": state["geometry_count"], "labels": state["labels"],
		"existing_script_labels": state["existing_script_labels"],
		"geometry_classes": state["geometry_classes"], "particles": state["particles"],
		"sprites": state["sprites"]}))

func _observe(node: Node, state: Dictionary) -> void:
	_hold_owner = str(node.get_path())
	if node is GeometryInstance3D:
		state["geometry_count"] = int(state["geometry_count"]) + 1
		var classes: Dictionary = state["geometry_classes"]
		classes[node.get_class()] = int(classes.get(node.get_class(), 0)) + 1
		if _treatment == "retain-final-world-materials":
			var geometry := node as GeometryInstance3D
			_hold(geometry.material_override)
			_hold(geometry.material_overlay)
			if node is MeshInstance3D:
				var instance := node as MeshInstance3D
				if instance.mesh != null:
					for surface in instance.mesh.get_surface_count():
						_hold(instance.get_active_material(surface))
						_hold(instance.get_surface_override_material(surface))
						_hold(instance.mesh.surface_get_material(surface))
			elif node is MultiMeshInstance3D:
				var instance := node as MultiMeshInstance3D
				if instance.multimesh != null and instance.multimesh.mesh != null:
					for surface in instance.multimesh.mesh.get_surface_count():
						_hold(instance.multimesh.mesh.surface_get_material(surface))
	if node.get_class() == "Terrain3D" and _treatment == "retain-final-world-materials":
		# Raw native RID teardown may ignore Resource references; disclose that
		# limitation rather than silently assuming Terrain3DMaterial retention.
		_hold(node.get("material") as Resource)
	if node is GPUParticles3D or node is CPUParticles3D:
		var retain_particle := _treatment == "retain-final-world-materials" \
			or (_treatment == "retain-late-cpu-materials" and node is CPUParticles3D)
		var meshes: Array[Mesh] = []
		if node is CPUParticles3D:
			var mesh := (node as CPUParticles3D).mesh
			if mesh != null: meshes.append(mesh)
		else:
			var particles := node as GPUParticles3D
			for pass_index in particles.draw_passes:
				var mesh: Mesh = particles.get("draw_pass_%d" % (pass_index + 1)) as Mesh
				if mesh != null: meshes.append(mesh)
			if _treatment == "retain-final-world-materials": _hold(particles.process_material)
		var materials := 0
		for mesh: Mesh in meshes:
			for surface in mesh.get_surface_count():
				var material := mesh.surface_get_material(surface)
				if material != null:
					materials += 1
					if retain_particle: _hold(material)
		if retain_particle:
			_hold((node as GeometryInstance3D).material_override)
			_hold((node as GeometryInstance3D).material_overlay)
		(state["particles"] as Array).append({"path": str(node.get_path()), "class": node.get_class(),
			"draw_meshes": meshes.size(), "draw_materials": materials})
	if node is Sprite3D:
		var sprite := node as Sprite3D
		(state["sprites"] as Array).append({"path": str(sprite.get_path()),
			"script_present": sprite.get_script() != null,
			"observer_installed": sprite.get_script() == SPRITE_DELETE_PROBE})
		if _treatment == "detach-world-sprites":
			if sprite.get_script() == SPRITE_DELETE_PROBE:
				pass # Already observed; do not replace or reinitialize.
			elif sprite.get_script() != null:
				_fail("Sprite deletion observer refused existing product script: " + str(sprite.get_path()))
			else:
				var before := _sprite_live_state(sprite)
				sprite.set_meta("f19_diagnostic_original_path", str(sprite.get_path()))
				sprite.set_script(SPRITE_DELETE_PROBE)
				if _sprite_live_state(sprite) != before:
					_fail("Sprite deletion observer changed live properties: " + str(sprite.get_path()))
	if node is Label3D:
		var label := node as Label3D
		(state["labels"] as Array).append(str(label.get_path()))
		if _treatment == "detach-world-labels":
			if label.get_script() == LABEL_DELETE_PROBE:
				pass # Already observed at world-ready; do not replace/reinitialize.
			elif label.get_script() != null:
				(state["existing_script_labels"] as Array).append(str(label.get_path()))
			else:
				var before := _label_live_state(label)
				label.set_meta("f19_diagnostic_original_path", str(label.get_path()))
				label.set_script(LABEL_DELETE_PROBE)
				if _label_live_state(label) != before:
					_fail("World label deletion observer changed live properties: " + str(label.get_path()))
	for child: Node in node.get_children(true):
		_observe(child, state)

func _hold(resource: Resource) -> void:
	if resource != null and not _held_ids.has(resource.get_instance_id()):
		_held_ids[resource.get_instance_id()] = true
		_held.append(resource)
		_retained_total += 1
		if resource is Material:
			_new_material_count += 1
			if _new_material_owners.size() < 64:
				_new_material_owners.append(_hold_owner + ":" + str(resource.get_instance_id()))

func _label_live_state(label: Label3D) -> Dictionary:
	var state := {"base": label.get_base()}
	for property: String in ["text", "font", "font_size", "pixel_size", "outline_size",
			"fixed_size", "billboard", "modulate", "outline_modulate", "no_depth_test",
			"shaded", "visible", "cast_shadow", "transform", "material_override", "material_overlay"]:
		state[property] = label.get(property)
	return state

func _sprite_live_state(sprite: Sprite3D) -> Dictionary:
	var state := {"base": sprite.get_base()}
	for property: String in ["texture", "pixel_size", "centered", "offset", "flip_h", "flip_v",
			"billboard", "modulate", "alpha_cut", "alpha_scissor_threshold", "shaded",
			"transparent", "double_sided", "no_depth_test", "fixed_size", "visible",
			"cast_shadow", "transform", "material_override", "material_overlay"]:
		state[property] = sprite.get(property)
	return state
