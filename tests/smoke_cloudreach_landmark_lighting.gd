extends SceneTree
## Real-tree presentation smoke; no world/progression fixture or renderer needed.
const LIGHTING := preload("res://scripts/world/cloudreach_landmark_lighting.gd")
var _failures := 0
var _checks := 0

class Clock extends Node:
	var current_hour := 10.0
	func hour() -> float: return current_hour

class BeaconSupport extends Node3D:
	func frame_base_y() -> float: return 503.5

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error(message)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var clock := Clock.new()
	world.add_child(clock)
	clock.add_to_group("day_cycle")
	var landmarks := Node3D.new()
	landmarks.name = "Landmarks"
	world.add_child(landmarks)
	for label in ["SummitEyrieStronghold", "CliffholdSettlement", "WindscarBeacon"]:
		var site := Node3D.new()
		site.name = label
		site.position.y = 500.0
		landmarks.add_child(site)
		if label == "SummitEyrieStronghold":
			for i in 4:
				var old_mount := Node3D.new()
				site.add_child(old_mount)
				var old_light := OmniLight3D.new()
				old_light.name = "AviaryEntryLanternLight"
				old_mount.add_child(old_light)
		if label == "WindscarBeacon":
			var support := BeaconSupport.new()
			support.name = "OpenWindscarBeacon"
			site.add_child(support)
			var signal_node := load("res://assets/props/built/torch_prop.tscn").instantiate() as Node3D
			signal_node.name = "WindscarSignalFlame"
			signal_node.scale = Vector3.ONE * 2.0
			support.add_child(signal_node)
			var signal_light := OmniLight3D.new()
			signal_light.name = "WindscarSignalLight"
			signal_light.light_energy = 1.45
			signal_light.omni_range = 10.0
			support.add_child(signal_light)
	var controller := LIGHTING.new()
	world.add_child(controller)
	controller.build(world)
	var lights := world.find_children("ArchitecturalLight", "OmniLight3D", true, false)
	_check(lights.size() == 10, "all configured physical lamps must build")
	_check(world.find_children("*", "OmniLight3D", true, false).size() == 11, "aviary accents and beacon signal must reuse existing lights")
	var signal_light := landmarks.get_node("WindscarBeacon/OpenWindscarBeacon/WindscarSignalLight") as OmniLight3D
	var signal_node := landmarks.get_node("WindscarBeacon/OpenWindscarBeacon/WindscarSignalFlame") as Node3D
	_check(signal_light.global_position.is_equal_approx(signal_node.to_global(signal_node.call("flame_local_position"))), "signal light must coincide with its visible flame")
	var control_torch := load("res://assets/props/built/torch_prop.tscn").instantiate() as Node3D
	var control_flame := control_torch.get_node("FlameOuter") as MeshInstance3D
	var beacon_flame := signal_node.get_node("FlameOuter") as MeshInstance3D
	_check((control_flame.mesh as QuadMesh).size.is_equal_approx(Vector2.ONE * 0.22), "other torch geometry must retain handheld size")
	_check((beacon_flame.mesh as QuadMesh).size.is_equal_approx(Vector2.ONE * 0.88), "beacon halo mesh must be enlarged locally")
	_check(not (control_flame.material_override as StandardMaterial3D).billboard_keep_scale, "other torch materials must remain unchanged")
	_check((beacon_flame.material_override as StandardMaterial3D).billboard_keep_scale, "beacon billboard must retain parent scale")
	control_torch.free()
	_check(world.find_children("*", "CollisionObject3D", true, false).is_empty(), "presentation must not add collision")
	for light: OmniLight3D in lights:
		_check(is_zero_approx(light.light_energy), "daylight must switch extra light energy off")
		_check(not light.shadow_enabled, "no added shadow lights")
		_check(light.get_parent().get_node_or_null("FlameCore") != null, "light must have visible source")
	clock.current_hour = 23.0
	paused = true
	await process_frame
	await process_frame
	for light: OmniLight3D in lights:
		_check(light.light_energy >= 3.0, "night lighting must follow clock even while paused")
	_check(is_equal_approx(signal_light.light_energy, 5.0), "signal night energy must follow paused clock")
	clock.current_hour = 10.0
	await process_frame
	await process_frame
	for light: OmniLight3D in lights:
		_check(is_zero_approx(light.light_energy), "return to day must clear night light")
	paused = false
	_check(is_equal_approx(signal_light.light_energy, 1.45) and is_equal_approx(signal_light.omni_range, 10.0), "signal daylight energy/range must be restored")
	for lamp: Node3D in landmarks.get_node("WindscarBeacon").get_children():
		if str(lamp.name).begins_with("ArchitecturalLantern"):
			_check(is_equal_approx(lamp.position.y, 9.0), "beacon mounts must follow terrain-fit base plus height")
	world.queue_free()
	await process_frame
	print("LANDMARK LIGHTING: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
