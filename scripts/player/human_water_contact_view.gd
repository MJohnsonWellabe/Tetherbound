extends Node3D

## P2-072: local presentation only. Never writes aquatic state, body/art
## transforms, velocity, resources, network fields, camera or shadow settings.
const CONFIG := "res://data/config/human_water_contact_visual.json"
const SWIM := preload("res://scripts/player/swim_state.gd")
const FOAM := preload("res://shaders/human_water_contact.gdshader")

var settings: Dictionary = {}
var _body: CharacterBody3D
var _contact: MeshInstance3D
var _trail: Array[Dictionary] = []
var _phase := 0.0
var _fade := 0.0
var _last_position := Vector3.INF
var _last_emission := Vector3.INF
var _emission_clock := 0.0


static func load_settings() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return raw if raw is Dictionary else {}


static func attach(model: Node3D, body: CharacterBody3D) -> Node3D:
	var config := load_settings()
	# Gate-off creates no node, geometry, material, particles or processing.
	if not bool(config.get("enabled", false)) or body == null:
		return null
	var view := new()
	view.name = "HumanWaterContact"
	view.settings = config
	view._body = body
	model.add_child(view)
	return view


static func snapshot(body: Node) -> Dictionary:
	if not is_instance_valid(body):
		return {}
	var local := body.get_node_or_null("SwimController")
	if local != null and local.has_method("snapshot"):
		return local.call("snapshot")
	if body.has_method("animation_state"):
		var aquatic: Variant = body.get("aquatic")
		if aquatic is Object and aquatic.has_method("snapshot"):
			return aquatic.call("snapshot")
	return {}


func _ready() -> void:
	# World-space surface planes must not inherit trainer art tilt or seat drop.
	top_level = true
	transform = Transform3D.IDENTITY


func _process(delta: float) -> void:
	if not is_instance_valid(_body):
		_clear()
		queue_free()
		return
	step_visual(delta, snapshot(_body), _body.global_position)


func step_visual(delta: float, packet: Dictionary, body_position: Vector3) -> void:
	var mode := int(packet.get("mode", SWIM.Mode.LAND))
	var human := mode == SWIM.Mode.HUMAN
	var paused := mode == SWIM.Mode.COMBAT_PAUSED and int(packet.get(
		"resume_mode", SWIM.Mode.LAND)) == SWIM.Mode.HUMAN
	var sea := float(packet.get("surface_y", NAN))
	if not bool(settings.get("enabled", false)) or not (human or paused) \
			or not is_finite(sea) or not body_position.is_finite():
		_clear()
		return
	delta = maxf(0.0, delta)
	# Paused entry cannot generate effects, including on a late remote spawn.
	if paused and _contact == null:
		return
	var at := Vector3(body_position.x, sea + float(settings.get("surface_lift_m", 0.045)), body_position.z)
	if _contact == null:
		_contact = _ring()
		_last_position = at
		_last_emission = at
	if human:
		_phase += delta * 2.0
		_fade = minf(1.0, _fade + delta * 5.0)
		_contact.position = at
		_emission_clock += delta
		var moved := at.distance_to(_last_position)
		# A teleport/reconnect discontinuity must not paint a trail across land.
		if moved > 3.0:
			_clear_trail()
			_last_emission = at
		elif moved > 0.001 and at.distance_to(_last_emission) >= float(settings.get("trail_spacing_m", 0.4)) \
				and _emission_clock >= float(settings.get("trail_interval_s", 0.16)):
			var ring := _ring()
			ring.position = at
			_trail.append({"node": ring, "age": 0.0, "phase": _phase})
			_last_emission = at
			_emission_clock = 0.0
			while _trail.size() > clampi(int(settings.get("max_trail_rings", 6)), 0, 12):
				(_trail.pop_front()["node"] as MeshInstance3D).free()
	else:
		_fade = maxf(0.0, _fade - delta / maxf(0.01, float(settings.get("pause_fade_s", 0.35))))
	_last_position = at
	_set_ring(_contact, _phase, _fade)
	var lifetime := maxf(0.01, float(settings.get("trail_lifetime_s", 1.15)))
	for index in range(_trail.size() - 1, -1, -1):
		var entry := _trail[index]
		entry.age = float(entry.age) + delta
		var ring := entry.node as MeshInstance3D
		if float(entry.age) >= lifetime:
			ring.free()
			_trail.remove_at(index)
			continue
		var remaining := 1.0 - float(entry.age) / lifetime
		_set_ring(ring, float(entry.phase), remaining * _fade * 0.6)


func _ring() -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * clampf(float(settings.get("ring_diameter_m", 1.35)), 0.1, 3.0)
	ring.mesh = plane
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = FOAM
	material.render_priority = 2
	ring.material_override = material
	add_child(ring)
	return ring


func _set_ring(ring: MeshInstance3D, phase: float, opacity: float) -> void:
	var material := ring.material_override as ShaderMaterial
	material.set_shader_parameter("phase", phase)
	material.set_shader_parameter("opacity", opacity * clampf(float(settings.get("opacity", 0.26)), 0.0, 0.5))


func _clear_trail() -> void:
	for entry in _trail:
		(entry.node as MeshInstance3D).free()
	_trail.clear()


func _clear() -> void:
	_clear_trail()
	if is_instance_valid(_contact):
		_contact.free()
	_contact = null
	_phase = 0.0
	_fade = 0.0
	_last_position = Vector3.INF
	_last_emission = Vector3.INF
	_emission_clock = 0.0
