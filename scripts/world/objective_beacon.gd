extends Node3D

## OWNER-0912-WAYFINDING — the one world-space answer to "where next?"
##
## The HUD and quest log already choose a single objective from the production
## flag store. `quest_log.gd::tracked_beacon()` gives that SAME row a concrete
## destination; this node renders it as a tall cyan squad-ping beam and mirrors
## it into MapState's existing `objective` dynamic marker. There is no second
## objective state here and no completion logic. A flag revision moves the
## existing marker and this presentation together.
##
## The beam is mounted only in the real Meadows world, never in simulation
## shells. It has no collider, light or particle emitter: it cannot block the
## route, alter lighting, or spend the GPU on thousands of particles. Three
## tiny unshaded meshes and one Label3D remain visible at road distance.

const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const CONFIG_PATH := "res://data/config/objective_beacon.json"

var _log: RefCounted = null
var _config: Dictionary = {}
var _visual: Node3D = null
var _beam: MeshInstance3D = null
var _ring: MeshInstance3D = null
var _core: MeshInstance3D = null
var _label: Label3D = null
var _beam_material: StandardMaterial3D = null
var _ring_material: StandardMaterial3D = null
var _core_material: StandardMaterial3D = null
var _colour := Color("63e8ff")
var _last_progression_revision := -2
var _active_id := ""
var _elapsed := 0.0


func _ready() -> void:
	_log = QUEST_LOG.new()
	_config = _load_config()
	_colour = Color.from_string(str(_config.get("colour", "#63E8FF")), Color("63e8ff"))
	_build_visual()
	refresh_now()


func _exit_tree() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game != null:
		var map_state: Variant = game.get("map")
		if map_state != null:
			map_state.call("remove_dynamic_marker", "objective")


func _process(delta: float) -> void:
	_elapsed += delta
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		_set_active(false)
		return
	var progression: RefCounted = game.get("progression")
	if progression == null:
		_set_active(false)
		return
	var revision := int(progression.get("revision"))
	if revision != _last_progression_revision:
		refresh_now()
	_animate_ping()


## Public so a focused smoke can force the same update production uses without
## waiting for its polling frame.
func refresh_now() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null or str(game.get("current_realm")) != "meadows":
		_clear_target(game)
		return
	var progression: RefCounted = game.get("progression")
	if progression == null:
		_clear_target(game)
		return
	_last_progression_revision = int(progression.get("revision"))
	_log.call("set_realm", "meadows")
	var target: Dictionary = _log.call("tracked_beacon", progression)
	if target.is_empty():
		_clear_target(game)
		return
	var at: Vector2 = target.get("position", Vector2.ZERO)
	var world_at := world_position(at, _ground_height(at))
	global_position = world_at
	_active_id = str(target.get("id", ""))
	var display_name := str(target.get("display_name", "Next objective"))
	_label.text = "NEXT  •  %s" % display_name
	_set_active(true)
	var map_state: Variant = game.get("map")
	if map_state != null:
		map_state.call("add_dynamic_marker", "objective", "objective", world_at, display_name)


static func world_position(at: Vector2, ground_y: float) -> Vector3:
	return Vector3(at.x, ground_y + 0.08, at.y)


func active_objective_id() -> String:
	return _active_id


func _clear_target(game: Node) -> void:
	_active_id = ""
	_set_active(false)
	if game == null:
		return
	var map_state: Variant = game.get("map")
	if map_state != null:
		map_state.call("remove_dynamic_marker", "objective")


func _set_active(active: bool) -> void:
	if _visual != null:
		_visual.visible = active


func _ground_height(at: Vector2) -> float:
	var source: Node = get_parent()
	while source != null:
		if source.has_method("ground_height_at"):
			var height := float(source.call("ground_height_at", at.x, at.y))
			if not is_nan(height):
				return height
		source = source.get_parent()
	return 0.0


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_warning("objective beacon config missing; using safe defaults")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("objective beacon config is invalid; using safe defaults")
		return {}
	return parsed as Dictionary


func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "PingVisual"
	add_child(_visual)

	var visible_range := float(_config.get("visible_range_m", 3200.0))
	var beam_height := float(_config.get("beam_height_m", 92.0))
	var beam_radius := float(_config.get("beam_radius_m", 0.72))
	_beam_material = _material(float(_config.get("beam_opacity", 0.19)))
	var beam_mesh := CylinderMesh.new()
	beam_mesh.height = beam_height
	beam_mesh.top_radius = beam_radius * 0.55
	beam_mesh.bottom_radius = beam_radius
	beam_mesh.radial_segments = 12
	_beam = _mesh("SkyBeam", beam_mesh, _beam_material, visible_range)
	_beam.position.y = beam_height * 0.5

	var ring_radius := float(_config.get("ground_ring_radius_m", 3.4))
	var ring_width := float(_config.get("ground_ring_width_m", 0.24))
	_ring_material = _material(float(_config.get("ground_ring_opacity", 0.78)))
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = maxf(0.05, ring_radius - ring_width)
	ring_mesh.outer_radius = ring_radius
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 8
	_ring = _mesh("GroundPing", ring_mesh, _ring_material, visible_range)
	_ring.position.y = 0.12

	var core_radius := float(_config.get("core_radius_m", 0.48))
	_core_material = _material(0.96)
	var core_mesh := SphereMesh.new()
	core_mesh.radius = core_radius
	core_mesh.height = core_radius * 2.0
	core_mesh.radial_segments = 4
	core_mesh.rings = 2
	_core = _mesh("PingCore", core_mesh, _core_material, visible_range)
	_core.position.y = float(_config.get("core_height_m", 2.9))
	_core.rotation.y = PI * 0.25

	_label = Label3D.new()
	_label.name = "DestinationLabel"
	_label.position.y = float(_config.get("label_height_m", 4.25))
	_label.font_size = int(_config.get("label_font_size", 30))
	_label.modulate = Color(0.92, 0.99, 1.0, 1.0)
	_label.outline_modulate = Color(0.01, 0.04, 0.06, 0.94)
	_label.outline_size = 8
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.visibility_range_end = minf(visible_range, 240.0)
	_visual.add_child(_label)
	_visual.visible = false


func _mesh(node_name: String, mesh: Mesh, material: Material, visible_range: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visibility_range_end = visible_range
	_visual.add_child(instance)
	return instance


func _material(opacity: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(_colour.r, _colour.g, _colour.b, opacity)
	material.emission_enabled = true
	material.emission = _colour
	material.emission_energy_multiplier = 1.35
	return material


func _animate_ping() -> void:
	if _visual == null or not _visual.visible:
		return
	var hz := float(_config.get("pulse_hz", 0.72))
	var amount := float(_config.get("pulse_amount", 0.22))
	var pulse := 0.5 + 0.5 * sin(_elapsed * TAU * hz)
	var beam_opacity := float(_config.get("beam_opacity", 0.19))
	var ring_opacity := float(_config.get("ground_ring_opacity", 0.78))
	_beam_material.albedo_color.a = beam_opacity * lerpf(1.0 - amount, 1.0 + amount, pulse)
	_ring_material.albedo_color.a = ring_opacity * lerpf(0.72, 1.0, pulse)
	_ring.scale = Vector3.ONE * lerpf(0.96, 1.04, pulse)
	_ring.rotation.y += get_process_delta_time() * 0.34
	_core.position.y = float(_config.get("core_height_m", 2.9)) + sin(_elapsed * TAU * hz) * 0.18
	_core.rotation.y += get_process_delta_time() * 0.8
