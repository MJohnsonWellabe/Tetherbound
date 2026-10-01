extends Node3D
## Cloudreach-only, source-backed architectural lamps. No collision/state changes.
const CONFIG := "res://data/config/cloudreach_landmark_lighting.json"
const LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
var _lamps: Array[Dictionary] = []
var _clock: Node
var _spec: Dictionary
var _last_weight := -1.0
var _signals: Array[Dictionary] = []

func build(world: Node3D) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_spec = JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) as Dictionary
	_clock = world.get_tree().get_first_node_in_group("day_cycle")
	for site: Dictionary in _spec.get("sites", []):
		var target := world.get_node_or_null(NodePath("Landmarks/" + str(site.id))) as Node3D
		if target == null:
			push_error("Missing architectural lamp landmark: " + str(site.id))
			continue
		if site.has("signal"):
			_configure_signal(target, site.signal)
		var base_y := 0.0
		if site.has("frame_base_node"):
			var support := target.get_node(NodePath(str(site.frame_base_node)))
			base_y = float(support.call("frame_base_y")) - target.global_position.y
		var reused: Array[Node] = []
		if site.has("reuse_lights"):
			reused = target.find_children(str(site.reuse_lights), "OmniLight3D", true, false)
			if reused.size() != (site.fixtures as Array).size():
				push_error("Architectural lamp replacement count mismatch: " + str(site.id))
				continue
		for fixture: Dictionary in site.fixtures:
			var lamp := Node3D.new()
			lamp.name = "ArchitecturalLantern"
			target.add_child(lamp)
			var at: Array = fixture.at
			lamp.position = Vector3(float(at[0]), float(at[1]) + base_y, float(at[2]))
			lamp.rotation.y = deg_to_rad(float(fixture.get("yaw", 0.0)))
			var model := LANTERN.instantiate() as Node3D
			var bounds: AABB = BOUNDS.measure(model)
			var height := float(fixture.get("height_m", site.get("height_m", 1.8)))
			var scale_factor := height / maxf(bounds.size.y, 0.01)
			model.scale = Vector3.ONE * scale_factor
			model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_factor
			lamp.add_child(model)
			var colour := Color(str(site.get("colour", "#ffc17d")))
			var glow := StandardMaterial3D.new()
			glow.albedo_color = colour
			glow.emission_enabled = true
			glow.emission = colour
			var core := MeshInstance3D.new()
			core.name = "FlameCore"
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = height * 0.065
			cylinder.bottom_radius = height * 0.065
			cylinder.height = height * 0.2
			core.mesh = cylinder
			core.material_override = glow
			core.position = Vector3(0, height * 0.27, height * 0.2)
			lamp.add_child(core)
			var light: OmniLight3D
			if not reused.is_empty():
				light = reused.pop_back() as OmniLight3D
				light.reparent(lamp, false)
			else:
				light = OmniLight3D.new()
				lamp.add_child(light)
			light.name = "ArchitecturalLight"
			light.position = core.position + Vector3.BACK * float(site.get("light_offset_m", 0.4))
			light.light_color = colour
			light.omni_range = float(fixture.get("range_m", site.range_m))
			light.omni_attenuation = float(site.get("attenuation", 1.0))
			light.shadow_enabled = false
			_lamps.append({"light":light,"material":glow,"energy":float(fixture.get("energy", site.energy))})
	_process(0.0)

func _configure_signal(target: Node3D, spec: Dictionary) -> void:
	var signal_node := target.get_node(NodePath(str(spec.node))) as Node3D
	var light := target.get_node(NodePath(str(spec.light))) as OmniLight3D
	# Only this landmark's instantiated flame geometry changes. The carried torch
	# scene, particle material and all shared mesh/material resources stay intact.
	for entry: Array in [["FlameOuter", "outer_scale"], ["FlameCore", "core_scale"]]:
		var flame := signal_node.get_node(NodePath(entry[0])) as MeshInstance3D
		var quad := flame.mesh.duplicate() as QuadMesh
		quad.size *= float(spec[entry[1]])
		flame.mesh = quad
		var material := flame.material_override.duplicate() as StandardMaterial3D
		material.billboard_keep_scale = true
		flame.material_override = material
	light.global_position = signal_node.to_global(signal_node.call("flame_local_position"))
	_signals.append({"light":light,"day_energy":light.light_energy,"day_range":light.omni_range,
		"night_energy":float(spec.energy),"night_range":float(spec.range_m)})

func _process(_delta: float) -> void:
	if not is_instance_valid(_clock): return
	var hour := float(_clock.call("hour"))
	var weight := night_weight(hour, _spec)
	if is_equal_approx(weight, _last_weight): return
	_last_weight = weight
	for lamp: Dictionary in _lamps:
		(lamp.light as OmniLight3D).light_energy = float(lamp.energy) * weight
		(lamp.material as StandardMaterial3D).emission_energy_multiplier = 2.0 * weight
	for signal_spec: Dictionary in _signals:
		var light := signal_spec.light as OmniLight3D
		light.light_energy = lerpf(float(signal_spec.day_energy), float(signal_spec.night_energy), weight)
		light.omni_range = lerpf(float(signal_spec.day_range), float(signal_spec.night_range), weight)

static func night_weight(hour: float, spec: Dictionary) -> float:
	var dawn: Array = spec.get("dawn_hours", [5.0, 7.0])
	var dusk: Array = spec.get("dusk_hours", [17.0, 19.0])
	return 1.0 - smoothstep(float(dawn[0]), float(dawn[1]), hour) + smoothstep(float(dusk[0]), float(dusk[1]), hour)
