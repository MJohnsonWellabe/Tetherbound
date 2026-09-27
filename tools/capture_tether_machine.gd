extends "res://tools/capture_visual_audit.gd"
## DRY RUN — does not count. Installed hero mesh and production Hall camera.

func _run() -> void:
	await process_frame
	root.size = Vector2i(1920,1080)
	await process_frame
	if root.size != Vector2i(1920,1080):
		quit(1)
		return
	await super._run()

func _run_roster() -> void:
	await _build_stage()
	var spec: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stronghold.json")) as Dictionary).machine
	var model := (load(str(spec.model)) as PackedScene).instantiate() as Node3D
	var bounds := RENDER_BOUNDS.measure(model)
	var factor := float(spec.height) / bounds.size.y
	model.scale = Vector3.ONE * factor
	model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	var machine := Node3D.new()
	_stage.add_child(machine)
	model.name = "Model"
	machine.add_child(model)
	preload("res://scripts/world/tether_machine_finish.gd").apply(machine, spec)
	var width := bounds.size.x * factor
	_trainer.position = Vector3(-width * 0.5 - 2.0,0,0)
	for angle: float in [0.0,90.0,180.0,270.0]:
		_frame(-width * 0.5 - 3.0,width * 0.5,float(spec.height),angle,bounds.size.z * factor)
		await _shoot("machine_" + str(int(angle)), {"azimuth":angle,"height":spec.height,"proof":"DRY RUN — does not count"})
	machine.queue_free()

func _build_rows(_spec: Dictionary) -> Array:
	var hold := _world.get_node("Stronghold") as Node3D
	var chamber: Vector3 = hold.call("marker", "legendary_chamber")
	var reveal: Vector3 = hold.call("marker", "reveal_stand")
	var machine := hold.call("machine") as Node3D
	var east := hold.global_basis.x.normalized()
	var south := hold.global_basis.z.normalized()
	return [
		{"id":"machine_entrance","stands":[chamber+east*12.5],"target":machine.global_position+Vector3.UP*8,"pitch_deg":12.0,"times":["day","night"]},
		{"id":"machine_reveal","stands":[reveal],"target":machine.global_position+Vector3.UP*8,"pitch_deg":12.0,"times":["day","night"]},
		{"id":"machine_side","stands":[chamber+east*10+south*9],"target":machine.global_position+Vector3.UP*8,"pitch_deg":12.0,"times":["day","night"]}
	]

func _run_region() -> bool:
	if not await super._run_region():
		return false
	var hold := _world.get_node("Stronghold")
	var machine := hold.call("machine") as Node3D
	var climax := _world.get_node("StrongholdClimax")
	var light := machine.get_node("CoreLight") as Light3D
	var hardware := machine.get_node_or_null("Hardware") as Node3D
	_check(hardware != null and hardware.get_parent() == machine, "hardware sits outside measured Model")
	_check(light.visible and light.light_energy > 0.0, "bound core light active")
	_check(_emissive_surfaces(machine) > 0, "bound rune surfaces active")
	var stage: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stronghold_climax.json")) as Dictionary).legendary.stage
	var cage: Dictionary = climax.call("_measure_cage", stage)
	_check(absf(float(cage.dais_top) - 4.063849) < .01, "unchanged measured dais")
	_check(absf(float(cage.crown_under) - 11.732381) < .01, "unchanged measured crown")
	var shape := machine.get_node("MachineBody").get_child(0) as CollisionShape3D
	_check(shape.shape is CylinderShape3D and is_equal_approx((shape.shape as CylinderShape3D).radius,5.6) and is_equal_approx((shape.shape as CylinderShape3D).height,2.7), "unchanged base collision")
	# Real release presentation path, with fixture progression. Not earned play.
	climax.call("_free_the_legendary")
	for i in 480:
		await physics_frame
		_clear_interruptions()
	_check(not light.visible, "released core light disabled")
	_check(_emissive_surfaces(machine) == 0, "released rune emission disabled")
	_check(hardware != null and hardware.visible, "released physical fittings remain")
	_check(climax.call("_measure_cage", stage) == cage, "release preserves measured cage geometry")
	for row: Dictionary in _build_rows({}):
		if row.id != "machine_entrance":
			continue
		row.id = "machine_entrance_freed"
		for time: String in ["day", "night"]:
			await _capture_region_row(_region_spec(_region), row, time)
	return _skips.is_empty()

func _emissive_surfaces(node: Node) -> int:
	var count := 0
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var mat := mesh.get_active_material(surface) as BaseMaterial3D
			if mat != null and mat.emission_enabled and mat.emission_energy_multiplier > 0:
				count += 1
	return count

func _check(ok: bool, label: String) -> void:
	_log_line({"kind":"check", "ok":ok, "label":label})
	if not ok:
		_skip("machine_contract",label)

func _finish(ok: bool) -> void:
	super._finish(ok and _skips.is_empty())
