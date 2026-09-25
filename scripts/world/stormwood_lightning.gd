extends Node3D

## Host-owned ground strikes. A client draws received warnings and applies
## only a host verdict addressed to its local trainer; it never chooses a hit.
const RULES := preload("res://scripts/world/stormwood_surge_rules.gd")
const SHELTER := preload("res://scripts/world/stormwood_shelter.gd")
var rules := RULES.new()
var world: Node3D
var surge: Node
var session: Node
var _next := 0.0
var _pending: Array[Dictionary] = []
var _visuals: Dictionary = {}
var _received_impacts: Array[int] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	world = get_parent() as Node3D
	surge = world.get_node("StormwoodSurge")
	session = get_node("/root/Game/Session")
	session.stormwood_strike_received.connect(_receive)
	_rng.randomize()
	_next = _rng.randf_range(4, 8)

func _process(delta: float) -> void:
	if not session.is_host():
		return
	for i in range(_pending.size() - 1, -1, -1):
		_pending[i].remaining = float(_pending[i].remaining) - delta
		if float(_pending[i].remaining) <= 0:
			_resolve(_pending[i])
			_pending.remove_at(i)
	_next -= delta
	if _next > 0:
		return
	_next = _rng.randf_range(float(rules.config.strike.interval_min), float(rules.config.strike.interval_max))
	var actors := _actors()
	if actors.is_empty():
		return
	var peer: int = actors.keys()[_rng.randi_range(0, actors.size() - 1)]
	var body: Node3D = actors[peer]
	var at := body.global_position
	if not rules.strike_window(at, surge.phase_at_position(at)) or not exposed(at, body):
		return
	at.y = world.ground_height_near(at) + 0.08
	# Vertical arenas have their own hazard controller; a forest strike must
	# not hit a trainer standing on a platform far above its ground warning.
	if absf(body.global_position.y - at.y) > 4:
		return
	var game := get_node("/root/Game")
	var environment: Dictionary = game.get("realm_environment")
	var storm: Dictionary = environment.get("stormwood", {}).duplicate(true)
	var serial := int(storm.get("strike_serial", 0)) + 1
	storm["strike_serial"] = serial
	environment["stormwood"] = storm
	game.set("realm_environment", environment)
	var event := {"id": serial, "kind": "warning", "at": at,
		"remaining": float(rules.config.strike.telegraph_seconds), "peers": actors.keys()}
	_pending.append(event.duplicate(true))
	session.publish_stormwood_strike(event)

func _actors() -> Dictionary:
	var result := {}
	if not bool(world.get("simulation_only")):
		result[session.local_peer_id()] = world.get_node("Player")
	for remote: Node in get_tree().get_nodes_in_group("remote_trainer"):
		var id := int(remote.get("peer_id"))
		if str(remote.get("net_realm")) == "stormwood" and session.realm_of(id) == "stormwood" and id != session.local_peer_id():
			result[id] = remote
	return result

func exposed(at: Vector3, body: Node3D = null) -> bool:
	if rules.in_glass_sink(at): return true
	return rules.eligible_ground(at, str(surge.region_at(at)), sheltered(at, body))

func sheltered(at: Vector3, body: Node3D = null) -> bool:
	if rules.in_glass_sink(at): return false
	var region := str(surge.region_at(at))
	# Physical roofs and live baked leaf envelopes both shelter the ground.
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 2.2, at + Vector3.UP * 100, 1)
	if body is CollisionObject3D:
		query.exclude = [body.get_rid()]
	var covered := not get_world_3d().direct_space_state.intersect_ray(query).is_empty()
	var vegetation := world.get_node_or_null("Vegetation")
	if not covered and vegetation != null:
		covered = SHELTER.under_canopy(at, vegetation.get("_collision_batches"))
	var camps := world.get_node_or_null("StormwoodCampsRuntime")
	var rods: Array = camps.rod_positions(world) if camps != null else []
	for record: Variant in get_node("/root/Game").get("placed_buildings"):
		if not record is Dictionary or str(record.get("realm", "meadows")) != "stormwood" or bool(record.get("removed", false)) or str(record.get("id", "")) != "lightning_rod":
			continue
		var raw: Array = record.get("position", [])
		if raw.size() == 3:
			rods.append(Vector3(float(raw[0]), float(raw[1]), float(raw[2])))
	return rules.sheltered(at, region, covered, rods)

func _resolve(event: Dictionary) -> void:
	var at: Vector3 = event.at
	var hits := {}
	var actors := _actors()
	for peer: int in event.peers:
		if not actors.has(peer):
			continue
		var body: Node3D = actors[peer]
		if body.global_position.distance_to(at) <= float(rules.config.strike.radius_m) and exposed(body.global_position, body):
			# Player base health is 100. The receiving vitals also caps against
			# its actual capacity; equipment integration can only reduce this.
			hits[peer] = rules.strike_effect(str(surge.region_at(at)), 100.0, 0)
	session.publish_stormwood_strike({"id": event.id, "kind": "impact", "at": at, "hits": hits})

func _receive(event: Dictionary) -> void:
	if bool(world.get("simulation_only")):
		return
	var id := int(event.get("id", -1))
	if str(event.get("kind", "")) == "warning":
		if _visuals.has(id) or _received_impacts.has(id):
			return
		var ring := _build_telegraph(event.at)
		add_child(ring)
		ring.global_position = event.at
		var ring_material := ring.material_override as ShaderMaterial
		var clock := ring.create_tween()
		clock.tween_method(func(v: float) -> void: ring_material.set_shader_parameter("progress", v),
			0.0, 1.0, float(rules.config.strike.telegraph_seconds))
		_visuals[id] = ring
		# An impact normally frees the ring before this fallback timeout. Bind
		# only its ID: capturing the Node emits a freed-capture error before a
		# lambda's is_instance_valid guard can even run.
		get_tree().create_timer(3.0).timeout.connect(_expire_warning.bind(id))
		return
	if str(event.get("kind", "")) != "impact":
		return
	if _received_impacts.has(id):
		return
	_received_impacts.append(id)
	if _received_impacts.size() > 256:
		_received_impacts.pop_front()
	if _visuals.has(id):
		var ring: MeshInstance3D = _visuals[id]
		_visuals.erase(id)
		# The rim flares white and fades as the bolt lands, then frees.
		var ring_material := ring.material_override as ShaderMaterial
		var tween := ring.create_tween()
		if ring_material != null:
			ring_material.set_shader_parameter("strike", 1.0)
			tween.tween_method(func(v: float) -> void: ring_material.set_shader_parameter("fade", v), 1.0, 0.0, 0.25)
		else:
			tween.tween_interval(0.12)
		tween.tween_callback(ring.queue_free)
	_strike_flash(event.at)
	var hits: Dictionary = event.get("hits", {})
	if not hits.has(session.local_peer_id()):
		return
	var player := world.get_node("Player") as CharacterBody3D
	var vitals: RefCounted = player.get("vitals")
	if vitals == null or vitals.is_dead():
		return
	var effect: Dictionary = hits[session.local_peer_id()]
	# The host decides only who the strike hit and publishes its base regional
	# effect. This receiver owns local vitals and applies this trainer's worn gear
	# once, after replay rejection. Inventory contents never protect a player.
	var mitigation := {"damage_scale": 1.0, "static_scale": 1.0}
	var game := get_node_or_null("/root/Game")
	var equipment: Variant = game.get("player_equipment") if game != null else null
	if equipment is RefCounted and equipment.has_method("storm_mitigation"):
		mitigation = equipment.call("storm_mitigation",
			int(rules.config.strike.insulation_pieces_for_immunity))
	var unarmoured_damage := minf(float(effect.damage), float(vitals.max_health) * 0.25)
	var damage := unarmoured_damage * float(mitigation.damage_scale)
	var static_seconds := float(effect.static_seconds) * float(mitigation.static_scale)
	vitals.health = maxf(0.0, float(vitals.health) - damage)
	if static_seconds > 0.0:
		vitals._apply_buff({"id": "stormwood_static", "stat": "stamina_regen_scale",
			"amount": 0.5, "duration_s": static_seconds})
	player.velocity *= 0.25
	if vitals.is_dead():
		player.died.emit()


## The visible strike: a brief white-violet bolt and local light where the
## telegraph stood (ART_DIRECTION §3.3 flash rhythm, §4 white-violet
## lightning). Both stay at the impact. The whole-sky flash is a separate,
## gated request: the host broadcasts every impact to every Stormwood peer,
## including glass-sink strikes that happen in any phase, so the surge node
## decides how much sky flash a strike this far from the local player earns
## (full in Break, distance-limited otherwise; see
## stormwood_surge.gd::sky_flash_for_strike). Values:
## stormwood_surge.json presentation.flash.strike_*.
static var _bolt_mesh: CylinderMesh
static var _bolt_material: StandardMaterial3D
static var _telegraph_shader: Shader

func _strike_flash(at: Vector3) -> void:
	var cfg: Dictionary = rules.config.get("presentation", {}).get("flash", {})
	var colour := Color(str(cfg.get("colour", "#e6dcff")))
	var seconds := float(cfg.get("strike_bolt_seconds", 0.18))
	var height := float(cfg.get("strike_bolt_height_m", 45.0))
	if _bolt_mesh == null:
		_bolt_mesh = CylinderMesh.new()
		_bolt_mesh.top_radius = float(cfg.get("strike_bolt_top_radius_m", 0.06))
		_bolt_mesh.bottom_radius = float(cfg.get("strike_bolt_bottom_radius_m", 0.16))
		_bolt_mesh.height = height
		_bolt_mesh.radial_segments = 6
		_bolt_mesh.rings = 1
		_bolt_material = StandardMaterial3D.new()
		_bolt_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_bolt_material.albedo_color = colour
		_bolt_material.emission_enabled = true
		_bolt_material.emission = colour
		_bolt_material.emission_energy_multiplier = float(cfg.get("strike_bolt_emission", 6.0))
	var bolt := MeshInstance3D.new()
	bolt.name = "StrikeBolt"
	bolt.mesh = _bolt_mesh
	bolt.material_override = _bolt_material
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bolt)
	bolt.global_position = at + Vector3.UP * height * 0.5
	var light := OmniLight3D.new()
	light.name = "StrikeLight"
	light.light_color = colour
	light.light_energy = float(cfg.get("strike_light_energy", 8.0))
	light.omni_range = float(cfg.get("strike_light_range_m", 18.0))
	light.shadow_enabled = false
	add_child(light)
	light.global_position = at + Vector3.UP * 2.0
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, seconds * 2.0)
	tween.tween_callback(light.queue_free)
	var fade := bolt.create_tween()
	fade.tween_interval(seconds)
	fade.tween_callback(bolt.queue_free)
	if surge != null and surge.has_method("sky_flash_for_strike"):
		var strength := float(surge.call("sky_flash_for_strike", at))
		if strength > 0.0:
			surge.call("flash", strength)


## J1: the 1.2 s warning. A flat ring laid on the ground (every vertex sampled
## from the terrain, lifted a few cm, so it hugs slopes instead of sitting on
## them as a tube), drawn unshaded with a bright white-violet rim, a cyan
## outer edge that softly falls off past the rim, a faint fill that grows as
## the strike nears, and a pulse that quickens toward impact. The rim sits at
## exactly strike.radius_m (the 3 m damage contract); the glow beyond it is
## `edge_falloff_m`. No red: oxblood is Team Tether's.
const TELEGRAPH_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec3 rim_colour : source_color = vec3(0.96, 0.93, 1.0);
uniform vec3 edge_colour : source_color = vec3(0.6, 0.85, 1.0);
uniform vec3 fill_colour : source_color = vec3(0.72, 0.66, 1.0);
uniform float rim_fraction = 0.92;
uniform float rim_width = 0.05;
uniform float intensity = 2.2;
uniform float pulse_hz_start = 2.0;
uniform float pulse_hz_end = 7.0;
uniform float telegraph_seconds = 1.2;
uniform float progress = 0.0;
uniform float strike = 0.0;
uniform float fade = 1.0;
void fragment() {
	float r = UV.x;
	// Chirp: the pulse rate climbs linearly from start to end over the
	// telegraph, integrated so the phase never jumps.
	float t = progress * telegraph_seconds;
	float phase = pulse_hz_start * t + (pulse_hz_end - pulse_hz_start) * t * t / (2.0 * telegraph_seconds);
	float pulse = 0.65 + 0.35 * cos(phase * 6.2832);
	float rim = 1.0 - smoothstep(0.0, rim_width, abs(r - rim_fraction));
	float outer = r > rim_fraction ? 1.0 - smoothstep(rim_fraction, 1.0, r) : 0.0;
	float fill = r < rim_fraction ? smoothstep(0.0, rim_fraction, r) * (0.12 + 0.28 * progress) : 0.0;
	vec3 colour = rim_colour * rim * intensity * mix(pulse, 1.6, strike)
		+ edge_colour * outer * 0.9 + fill_colour * fill;
	ALBEDO = colour;
	ALPHA = clamp(rim * mix(pulse, 1.0, strike) + outer * 0.55 * pulse + fill, 0.0, 1.0) * fade;
}
"""

func _telegraph_config() -> Dictionary:
	return rules.config.get("presentation", {}).get("telegraph", {})

## Rim radius and fill/falloff geometry for a warning at `at`.
func telegraph_rim_radius() -> float:
	return float(rules.config.strike.radius_m)

func _build_telegraph(at: Vector3) -> MeshInstance3D:
	var cfg := _telegraph_config()
	var rim_r := telegraph_rim_radius()
	var outer_r := rim_r + float(cfg.get("edge_falloff_m", 0.35))
	var lift := float(cfg.get("ground_lift_m", 0.07))
	var segments := int(cfg.get("segments", 48))
	var radii: Array[float] = [0.0, rim_r * 0.45, rim_r * 0.8, rim_r - 0.12, rim_r, rim_r + 0.12, outer_r]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base_y := at.y
	var sample := world != null and world.has_method("ground_height_near")
	var points: Array = []
	for ring_index in radii.size():
		var row: Array[Vector3] = []
		for k in segments:
			var angle := TAU * float(k) / float(segments)
			var offset := Vector3(cos(angle), 0.0, sin(angle)) * radii[ring_index]
			var y := base_y
			if sample:
				y = float(world.call("ground_height_near", at + offset))
			row.append(Vector3(offset.x, y - base_y + lift, offset.z))
		points.append(row)
	for ring_index in radii.size() - 1:
		for k in segments:
			var k2 := (k + 1) % segments
			var quad: Array[Vector3] = [points[ring_index][k], points[ring_index][k2], points[ring_index + 1][k2], points[ring_index + 1][k]]
			var rs: Array[float] = [radii[ring_index], radii[ring_index], radii[ring_index + 1], radii[ring_index + 1]]
			for idx: int in [0, 1, 2, 0, 2, 3]:
				st.set_uv(Vector2(rs[idx] / outer_r, 0.0))
				st.set_normal(Vector3.UP)
				st.add_vertex(quad[idx])
	var ring := MeshInstance3D.new()
	ring.name = "StrikeTelegraph"
	ring.mesh = st.commit()
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _telegraph_shader == null:
		_telegraph_shader = Shader.new()
		_telegraph_shader.code = TELEGRAPH_SHADER
	var material := ShaderMaterial.new()
	material.shader = _telegraph_shader
	material.set_shader_parameter("rim_colour", Color(str(cfg.get("rim_colour", "#f4eeff"))))
	material.set_shader_parameter("edge_colour", Color(str(cfg.get("edge_colour", "#9ad8ff"))))
	material.set_shader_parameter("fill_colour", Color(str(cfg.get("fill_colour", "#b8aaff"))))
	material.set_shader_parameter("rim_fraction", rim_r / outer_r)
	material.set_shader_parameter("rim_width", float(cfg.get("rim_width_m", 0.14)) / outer_r)
	material.set_shader_parameter("intensity", float(cfg.get("rim_intensity", 2.2)))
	material.set_shader_parameter("pulse_hz_start", float(cfg.get("pulse_hz_start", 2.0)))
	material.set_shader_parameter("pulse_hz_end", float(cfg.get("pulse_hz_end", 7.0)))
	material.set_shader_parameter("telegraph_seconds", float(rules.config.strike.telegraph_seconds))
	ring.material_override = material
	ring.set_meta("rim_radius_m", rim_r)
	ring.set_meta("telegraph_seconds", float(rules.config.strike.telegraph_seconds))
	return ring


func _expire_warning(id: int) -> void:
	var ring: Variant = _visuals.get(id)
	_visuals.erase(id)
	if is_instance_valid(ring):
		ring.queue_free()
