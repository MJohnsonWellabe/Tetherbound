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
## The beam is mounted only in real player-facing realm worlds, never in
## simulation shells. It has no collider, light or particle emitter: it cannot
## block the route, alter lighting, or spend the GPU on thousands of particles.
## Four tiny unshaded meshes and one Label3D remain visible at road distance.

const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const CONFIG_PATH := "res://data/config/objective_beacon.json"
const MAP_OWNER_META := &"regional_objective_beacon_owner"
const PRESENTATION_HOLD := preload("res://scripts/ui/presentation_hold.gd")

var _log: RefCounted = null
var _config: Dictionary = {}
var _visual: Node3D = null
var _beam: MeshInstance3D = null
var _distance_beam: MeshInstance3D = null
var _ring: MeshInstance3D = null
var _core: MeshInstance3D = null
var _label: Label3D = null
var _beam_material: StandardMaterial3D = null
var _distance_beam_material: StandardMaterial3D = null
var _ring_material: StandardMaterial3D = null
var _core_material: StandardMaterial3D = null
var _colour := Color("63e8ff")
var _last_progression_revision := -2
var _active_id := ""
var _elapsed := 0.0
var realm_id := "meadows"
var _claimed_map: RefCounted = null
var _marker_owner: RefCounted = RefCounted.new()
var _last_realm := ""
## Whether a target is resolved; the beam draws only when this is true and no
## story payoff holds the screen (`presentation_hold.gd`).
var _has_target := false


func _ready() -> void:
	_log = QUEST_LOG.new()
	_config = _load_config()
	_colour = Color.from_string(str(_config.get("colour", "#63E8FF")), Color("63e8ff"))
	_build_visual()
	refresh_now()


func _exit_tree() -> void:
	_remove_owned_marker()
	_claimed_map = null


func _process(delta: float) -> void:
	_elapsed += delta
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		_clear_target(null)
		_claim_map(null)
		_last_realm = ""
		_set_active(false)
		return
	var progression: RefCounted = game.get("progression")
	if progression == null:
		_claim_map(_map_for_game(game))
		_clear_target(game)
		return
	var revision := int(progression.get("revision"))
	var current_realm := str(game.get("current_realm"))
	var current_map := _map_for_game(game)
	if revision != _last_progression_revision or current_realm != _last_realm \
			or current_map != _claimed_map:
		refresh_now()
	_apply_visibility()
	_animate_ping()
	_update_distance_beam()


## Public so a focused smoke can force the same update production uses without
## waiting for its polling frame.
func refresh_now() -> void:
	var game := get_node_or_null(^"/root/Game")
	_last_realm = str(game.get("current_realm")) if game != null else ""
	_claim_map(_map_for_game(game))
	if game == null or str(game.get("current_realm")) != realm_id:
		_clear_target(game)
		return
	var progression: RefCounted = game.get("progression")
	if progression == null:
		_clear_target(game)
		return
	_last_progression_revision = int(progression.get("revision"))
	_log.call("set_realm", realm_id)
	var target: Dictionary = _log.call("tracked_beacon", progression)
	if target.is_empty():
		_clear_target(game)
		return
	var at: Vector2 = target.get("position", Vector2.ZERO)
	var ground_y := _ground_height(at)
	if not is_finite(ground_y):
		_clear_target(game)
		return
	var world_at := world_position(at, ground_y)
	global_position = world_at
	_active_id = str(target.get("id", ""))
	var display_name := str(target.get("display_name", "Next objective"))
	_label.text = "NEXT  •  %s" % display_name
	_set_active(true)
	if _claimed_map != null:
		_claimed_map.call("add_dynamic_marker", "objective", "objective", world_at, display_name)
		_mark_owned()


static func world_position(at: Vector2, ground_y: float) -> Vector3:
	return Vector3(at.x, ground_y + 0.08, at.y)


static func distance_segment_opacity(distance_m: float, start_m: float,
		full_m: float, max_opacity: float) -> float:
	if distance_m <= start_m:
		return 0.0
	var span := maxf(0.001, full_m - start_m)
	var weight := clampf((distance_m - start_m) / span, 0.0, 1.0)
	weight = weight * weight * (3.0 - 2.0 * weight)
	return weight * max_opacity


func active_objective_id() -> String:
	return _active_id


func _clear_target(game: Node) -> void:
	_active_id = ""
	_set_active(false)
	_remove_owned_marker()


func _map_for_game(game: Node) -> RefCounted:
	if game == null or str(game.get("current_realm")) != realm_id:
		return null
	var candidate: Variant = game.get("map") if game != null else null
	return candidate as RefCounted if candidate is RefCounted else null


## Dynamic maps belong to portable characters and are separate per realm. The
## owner token lives in MapState metadata, never in its serialized marker
## dictionary. It prevents a deferred old-realm exit from clearing a newer
## beacon's marker, while claiming an existing marker lets this live instance
## remove stale saved presentation when no objective is active.
func _claim_map(map_state: RefCounted) -> void:
	if _claimed_map == map_state:
		return
	_remove_owned_marker()
	_claimed_map = map_state
	_mark_owned()


func _mark_owned() -> void:
	if _claimed_map == null:
		return
	_claimed_map.set_meta(MAP_OWNER_META, _marker_owner)


func _remove_owned_marker() -> void:
	if _claimed_map == null:
		return
	if _claimed_map.has_meta(MAP_OWNER_META) \
			and _claimed_map.get_meta(MAP_OWNER_META) == _marker_owner:
		_claimed_map.call("remove_dynamic_marker", "objective")
		_claimed_map.remove_meta(MAP_OWNER_META)


func _set_active(active: bool) -> void:
	_has_target = active
	_apply_visibility()


## The beam stands down while a story payoff plays (F05 heal: it read as a
## stray cyan column over the land healing). The target and map marker are
## untouched; the beam returns the frame the hold ends.
func _apply_visibility() -> void:
	if _visual != null:
		_visual.visible = _has_target and not (is_inside_tree() and PRESENTATION_HOLD.active(get_tree()))


func beam_visible() -> bool:
	return _visual != null and _visual.visible


func _ground_height(at: Vector2) -> float:
	var source: Node = get_parent()
	while source != null:
		if source.has_method("ground_height_at"):
			var height := float(source.call("ground_height_at", at.x, at.y))
			if not is_nan(height):
				return height
		source = source.get_parent()
	return NAN


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
	var beam_radius := float(_config.get("beam_radius_m", 0.9))
	# The destination beam is the one part of the marker that must survive a
	# forested route. The ground ring/core still depth-test so the marker stays
	# seated in the world; only this narrow, translucent vertical is allowed to
	# show through intervening canopy. Otherwise an ordinary tree directly on
	# the camera-to-objective bearing erases the entire wayfinding answer.
	_beam_material = _material(float(_config.get("beam_opacity", 0.26)), true)
	var beam_mesh := CylinderMesh.new()
	beam_mesh.height = beam_height
	beam_mesh.top_radius = beam_radius * 0.55
	beam_mesh.bottom_radius = beam_radius
	beam_mesh.radial_segments = 12
	_beam = _mesh("SkyBeam", beam_mesh, _beam_material, visible_range)
	_beam.position.y = beam_height * 0.5

	# A second, distance-only section reinforces the upper half of the same beam.
	# Its wider world footprint is needed for a few stable pixels at 500 m, while
	# the fade keeps the accepted nearby treatment exactly on the original beam.
	# Maximum render priority makes the depth-independent section survive ordinary
	# opaque trunks instead of being lost to transparent-pass ordering.
	var distance_base := float(_config.get("distance_segment_base_m", 42.0))
	var distance_height := minf(
		float(_config.get("distance_segment_height_m", 50.0)),
		maxf(1.0, beam_height - distance_base))
	var distance_radius := float(_config.get("distance_segment_radius_m", 2.0))
	_distance_beam_material = _material(0.0, true)
	_distance_beam_material.render_priority = 127
	var distance_mesh := CylinderMesh.new()
	distance_mesh.height = distance_height
	distance_mesh.top_radius = distance_radius * 0.72
	distance_mesh.bottom_radius = distance_radius
	distance_mesh.radial_segments = 12
	_distance_beam = _mesh(
		"DistanceSkyBeam", distance_mesh, _distance_beam_material, visible_range)
	_distance_beam.position.y = distance_base + distance_height * 0.5
	_distance_beam.visible = false

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


func _material(opacity: float, depth_independent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = depth_independent
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
	var beam_opacity := float(_config.get("beam_opacity", 0.26))
	var ring_opacity := float(_config.get("ground_ring_opacity", 0.78))
	_beam_material.albedo_color.a = beam_opacity * lerpf(1.0 - amount, 1.0 + amount, pulse)
	_ring_material.albedo_color.a = ring_opacity * lerpf(0.72, 1.0, pulse)
	_ring.scale = Vector3.ONE * lerpf(0.96, 1.04, pulse)
	_ring.rotation.y += get_process_delta_time() * 0.34
	_core.position.y = float(_config.get("core_height_m", 2.9)) + sin(_elapsed * TAU * hz) * 0.18
	_core.rotation.y += get_process_delta_time() * 0.8


func _update_distance_beam() -> void:
	if _distance_beam == null or _distance_beam_material == null:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		_distance_beam.visible = false
		return
	var opacity := distance_segment_opacity(
		camera.global_position.distance_to(global_position),
		float(_config.get("distance_segment_fade_start_m", 180.0)),
		float(_config.get("distance_segment_fade_full_m", 420.0)),
		float(_config.get("distance_segment_opacity", 0.46)))
	_distance_beam.visible = opacity > 0.001
	_distance_beam_material.albedo_color.a = opacity
