extends Node3D

## F17 presentation owns no progression writes. Host WorldState is the sole
## shared display source; F18/F31 interactions validate and transact separately.
const ORDER := preload("res://scripts/data/biome_order.gd")
const CONFIG_PATH := "res://data/config/crossing_hall.json"
const ARCH_MODEL := "res://assets/buildings/quaternius_medieval/Wall_Arch.gltf"
const STAND_MODEL := "res://assets/props/quaternius_fantasy/BookStand.gltf"
const LANTERN_MODEL := "res://assets/props/quaternius_fantasy/Lantern_Wall.gltf"

var _config: Dictionary = {}
var _arches: Dictionary = {}
var _pedestals: Dictionary = {}
var _elapsed := 0.0
var _last_display: Dictionary = {}


func build(config: Dictionary) -> bool:
	if not validate_layout(config):
		push_error("Crossing Hall needs one home arch, seven signed arches and eight ordered pedestals")
		return false
	_config = config.duplicate(true)
	add_to_group("crossing_halls")
	for entry: Dictionary in _config.arches:
		_build_arch(entry)
	for entry: Dictionary in _config.pedestals:
		_build_pedestal(entry)
	_add_light(Vector3(0, 5.8, 5))
	_add_light(Vector3(12, 4.8, 0))
	refresh_from_game()
	set_process(true)
	return true


static func validate_layout(config: Dictionary) -> bool:
	var arches: Variant = config.get("arches")
	var pedestals: Variant = config.get("pedestals")
	if not arches is Array or not pedestals is Array or arches.size() != 8 or pedestals.size() != 8:
		return false
	var order := ORDER.ids(true)
	if order.size() != 8:
		return false
	var arch_ids: Array[String] = []
	for index: int in arches.size():
		var row: Variant = arches[index]
		if not row is Dictionary or not _position_valid(row.get("at")):
			return false
		var id := str(row.get("id", ""))
		if arch_ids.has(id) or str(row.get("biome", "")) != order[index]:
			return false
		if index == 0 and (id != "home" or row.get("kind") != "home"):
			return false
		if index > 0 and (id != order[index] or row.get("kind") != ("live" if index < 4 else "sealed")):
			return false
		arch_ids.append(id)
	for index: int in pedestals.size():
		var row: Variant = pedestals[index]
		if not row is Dictionary or row.get("biome") != order[index] or not _position_valid(row.get("at")):
			return false
	return _position_valid(config.get("home_arrival")) and _position_valid(config.get("shrine_entry"))


static func _position_valid(raw: Variant) -> bool:
	if not raw is Array or raw.size() != 3:
		return false
	for component: Variant in raw:
		if not (component is int or component is float) or not is_finite(float(component)):
			return false
	return true


func _build_arch(entry: Dictionary) -> void:
	var slot := Node3D.new()
	slot.name = "Arch_" + str(entry.id)
	slot.position = _position(entry.at)
	slot.rotation.y = deg_to_rad(float(entry.get("yaw_deg", 0)))
	slot.set_meta("biome", str(entry.biome))
	slot.add_to_group("crossing_hall_arches")
	add_child(slot)
	_add_model(slot, ARCH_MODEL)
	var board := _label(slot, ORDER.display_name(str(entry.biome)), Vector3(0, 3.55, 0))
	board.name = "BiomeSign"
	var state := _label(slot, "Home arch" if entry.kind == "home" else "Sealed" if entry.kind == "sealed" else "Locked", Vector3(0, 2.95, .12))
	state.name = "StateSign"
	var arrival := Marker3D.new()
	arrival.name = "Approach"
	arrival.position = Vector3(0, .05, 2.8)
	slot.add_child(arrival)
	var membrane := MeshInstance3D.new()
	membrane.name = "PortalSurface"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.45, 2.4)
	membrane.mesh = mesh
	membrane.position = Vector3(0, 1.28, -.08)
	var material := StandardMaterial3D.new()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = .75
	membrane.material_override = material
	slot.add_child(membrane)
	_arches[str(entry.id)] = slot


func _build_pedestal(entry: Dictionary) -> void:
	var slot := Node3D.new()
	slot.name = "Pedestal_" + str(entry.biome)
	slot.position = _position(entry.at)
	slot.rotation.y = deg_to_rad(float(entry.get("yaw_deg", 0)))
	slot.set_meta("biome", str(entry.biome))
	slot.add_to_group("crossing_hall_pedestals")
	add_child(slot)
	_add_model(slot, STAND_MODEL)
	# Measured installed BookStand bounds, authored in config so physics and
	# presentation share one native-scale footprint rather than a solid room.
	var collider: Dictionary = _config.get("pedestal_collider", {})
	var body := StaticBody3D.new()
	body.name = "PedestalBody"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = _position(collider.get("size", [.51, 1.44, .51]))
	shape.shape = box
	shape.position = _position(collider.get("at", [0, .72, 0]))
	body.add_child(shape)
	slot.add_child(body)
	_label(slot, ORDER.display_name(str(entry.biome)), Vector3(0, 1.35, .15))
	var arrival := Marker3D.new()
	arrival.name = "Approach"
	arrival.position = Vector3(0, .05, 1.8)
	slot.add_child(arrival)
	_pedestals[str(entry.biome)] = slot


func _add_model(parent: Node3D, path: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Crossing Hall installed model missing: " + path)
		return
	parent.add_child(packed.instantiate())


func _label(parent: Node3D, text: String, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 32
	label.pixel_size = .006
	label.modulate = Color("f2e6cb")
	label.outline_modulate = Color("332c27")
	label.no_depth_test = false
	parent.add_child(label)
	return label


func _add_light(at: Vector3) -> void:
	var lantern := Node3D.new()
	lantern.position = at
	add_child(lantern)
	_add_model(lantern, LANTERN_MODEL)
	var light := OmniLight3D.new()
	light.position = at
	var settings: Dictionary = _config.get("light", {})
	light.light_color = Color(str(settings.get("colour", "#ffd7a4")))
	light.light_energy = float(settings.get("energy", 1.15))
	light.omni_range = float(settings.get("range_m", 8.5))
	light.shadow_enabled = false
	add_child(light)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < float(_config.get("refresh_seconds", .2)):
		return
	_elapsed = 0
	refresh_from_game()


func refresh_from_game() -> void:
	var game := get_node_or_null("/root/Game")
	var world: RefCounted = game.get("world") if game != null else null
	var display: Dictionary = world.get("redesign_world") if world != null else {}
	if display == _last_display:
		return
	_last_display = display.duplicate(true)
	apply_display(display)


func apply_display(display: Dictionary) -> void:
	var unlocked: Array = display.get("portal_unlocks", [])
	var shrine: Dictionary = display.get("shrine_display", {})
	var colors: Dictionary = _config.get("arch_materials", {})
	for id: String in _arches:
		var arch: Node3D = _arches[id]
		var state := "open" if id == "home" or unlocked.has(id) else "locked"
		if ORDER.ids(false).find(id) < 0 and id != "home":
			state = "stirred" if id == "biome5" and bool(display.get("fifth_arch_stirred", false)) else "sealed"
		arch.set_meta("arch_state", state)
		var material := (arch.get_node("PortalSurface") as MeshInstance3D).material_override as StandardMaterial3D
		material.albedo_color = Color(str(colors.get(state, "#303947")))
		material.emission_enabled = state == "open" or state == "stirred"
		material.emission = material.albedo_color
		material.emission_energy_multiplier = .25 if state == "open" else .1
		(arch.get_node("StateSign") as Label3D).text = "Home arch" if id == "home" else state.capitalize()
	for id: String in _pedestals:
		var pedestal: Node3D = _pedestals[id]
		pedestal.set_meta("relic_displayed", bool(shrine.get(id, false)))


func home_arrival() -> Vector3:
	return to_global(_position(_config.home_arrival))


func arch(id: String) -> Node3D:
	return _arches.get(id) as Node3D


func shrine_entry() -> Vector3:
	return to_global(_position(_config.shrine_entry))


func layout_signature() -> String:
	return JSON.stringify(_config).sha256_text()


func display_snapshot() -> Dictionary:
	return _last_display.duplicate(true)


static func _position(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
