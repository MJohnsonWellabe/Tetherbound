extends Node3D

## Host-owned ground strikes. A client draws received warnings and applies
## only a host verdict addressed to its local trainer; it never chooses a hit.
const RULES := preload("res://scripts/world/stormwood_surge_rules.gd")
const SHELTER := preload("res://scripts/world/stormwood_shelter.gd")
const COMBAT_MATH := preload("res://scripts/combat/combat_math.gd")
const MOTION_PREFS := preload("res://scripts/ui/motion_prefs.gd")
var rules := RULES.new()
var world: Node3D
var surge: Node
var session: Node
var _next := 0.0
var _pending: Array[Dictionary] = []
var _visuals: Dictionary = {}
## Each drawn warning's ring centre by strike id, so its bolt lands there.
var _warning_centres: Dictionary = {}
var _received_impacts: Array[int] = []
var _rng := RandomNumberGenerator.new()

var _road_zones_clear := true

func _ready() -> void:
	world = get_parent() as Node3D
	surge = world.get_node("StormwoodSurge")
	session = get_node("/root/Game/Session")
	session.stormwood_strike_received.connect(_receive)
	_rng.randomize()
	_next = _rng.randf_range(4, 8)
	if not bool(world.get("simulation_only")):
		_prewarm_telegraph()

func _process(delta: float) -> void:
	_sync_road_warnings()
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
	var in_fight := _trainer_in_fight(peer)
	var creature_body := _creature_body_for(peer) if in_fight else null
	var aim: Variant = strike_aim(body.global_position, in_fight,
		creature_body.global_position if is_instance_valid(creature_body) else null, _spare_trainer_in_fight())
	if aim == null:
		return
	if in_fight and _spare_trainer_in_fight():
		body = creature_body
	var at: Vector3 = aim
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

## F10#3 round 2: the road current's gold cracks dim inside every live
## warning ring, so they do not pulse through the one cue that matters.
## Presentation only; at most four zones (the shader's array size).
func _sync_road_warnings() -> void:
	if world == null or bool(world.get("simulation_only")):
		return
	var road := world.get_node_or_null(^"StormwoodRoadCurrent")
	var road_material: ShaderMaterial = road.get("material") if road != null else null
	if road_material == null:
		return
	var radius := float(rules.config.strike.radius_m) if rules != null else 3.0
	var zones: Array[Vector4] = []
	for id: Variant in _visuals:
		if zones.size() >= 4:
			break
		if is_instance_valid(_visuals[id]) and _warning_centres.has(id):
			var at: Vector3 = _warning_centres[id]
			zones.append(Vector4(at.x, at.z, radius, 1.0))
	if zones.is_empty() and _road_zones_clear:
		return
	_road_zones_clear = zones.is_empty()
	while zones.size() < 4:
		zones.append(Vector4.ZERO)
	road_material.set_shader_parameter("warn_zones", zones)


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
		# Fight state is checked here, at impact, not only when the warning
		# was chosen: a trainer who entered a fight during the 1.2 s telegraph
		# is spared, and one whose fight ended in it is hit as normal.
		if not trainer_can_be_hit(_trainer_in_fight(peer), _spare_trainer_in_fight()):
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
		# Hold decorative sky bolts while this warning is drawn (F10#3).
		if surge != null and surge.has_method("hold_sky_bolts"):
			surge.hold_sky_bolts(float(rules.config.strike.telegraph_seconds) + 0.3)
		_warning_centres[id] = event.at
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
	_strike_flash(bolt_centre(_warning_centres.get(id), event.at))
	_warning_centres.erase(id)
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
## decides the phase/distance gate for this peer, multiplied by the local
## impact's restrained strike_sky_strength (see
## stormwood_surge.gd::sky_flash_for_strike). Values:
## stormwood_surge.json presentation.flash.strike_*.
static var _bolt_mesh: ArrayMesh
static var _bolt_material: ShaderMaterial
static var _bolt_glow_mesh: ArrayMesh
static var _bolt_glow_material: ShaderMaterial
static var _telegraph_shader: Shader

func _strike_flash(at: Vector3) -> void:
	var cfg: Dictionary = rules.config.get("presentation", {}).get("flash", {})
	var colour := Color(str(cfg.get("strike_colour", "#dc7aff")))
	var seconds := float(cfg.get("strike_bolt_seconds", 0.18))
	if _bolt_mesh == null:
		_bolt_mesh = _build_strike_bolt(cfg)
		var core_shader := Shader.new()
		core_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 tint : source_color;
void vertex() {
	vec3 centre = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 tangent = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 across = cross(tangent, -centre / max(length(centre), 0.0001));
	if (dot(across, across) < 0.0001) { across = vec3(1.0, 0.0, 0.0); }
	centre += normalize(across) * UV.x * UV.y;
	POSITION = PROJECTION_MATRIX * vec4(centre, 1.0);
}
void fragment() {
	ALBEDO = tint.rgb;
	float end_distance = max(max(-UV2.x, UV2.x - UV2.y), 0.0) / max(UV.y, 0.0001);
	float d2 = UV.x * UV.x + end_distance * end_distance;
	ALPHA = exp(-6.0 * d2) * (1.0 - smoothstep(0.64, 1.0, d2)) * tint.a;
}
"""
		_bolt_material = ShaderMaterial.new()
		_bolt_material.shader = core_shader
		_bolt_material.set_shader_parameter("tint", colour.lerp(Color.WHITE, 0.85))
		_bolt_glow_mesh = _build_strike_bolt(cfg, float(cfg.get("strike_glow_radius_scale", 4.0)))
		var glow_shader := Shader.new()
		glow_shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 tint : source_color;
void vertex() {
	vec3 centre = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 tangent = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 across = cross(tangent, -centre / max(length(centre), 0.0001));
	if (dot(across, across) < 0.0001) { across = vec3(1.0, 0.0, 0.0); }
	centre += normalize(across) * UV.x * UV.y;
	POSITION = PROJECTION_MATRIX * vec4(centre, 1.0);
}
void fragment() {
	ALBEDO = tint.rgb;
	float end_distance = max(max(-UV2.x, UV2.x - UV2.y), 0.0) / max(UV.y, 0.0001);
	float d2 = UV.x * UV.x + end_distance * end_distance;
	ALPHA = exp(-4.0 * d2) * (1.0 - smoothstep(0.64, 1.0, d2)) * tint.a;
}
"""
		_bolt_glow_material = ShaderMaterial.new()
		_bolt_glow_material.shader = glow_shader
		_bolt_glow_material.set_shader_parameter("tint", Color(colour, float(cfg.get("strike_glow_opacity", 0.32))))
	var bolt := MeshInstance3D.new()
	bolt.name = "StrikeBolt"
	bolt.extra_cull_margin = 1.0
	bolt.mesh = _bolt_mesh
	bolt.material_override = _bolt_material
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bolt)
	bolt.global_position = at
	var glow := MeshInstance3D.new()
	glow.name = "StrikeGlow"
	glow.extra_cull_margin = 1.0
	glow.mesh = _bolt_glow_mesh
	glow.material_override = _bolt_glow_material
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bolt.add_child(glow)
	var light := OmniLight3D.new()
	light.name = "StrikeLight"
	light.light_color = colour
	# The local light is a flash too: reduced motion scales it like the sky
	# flash. The bolt itself is the gameplay tell and stays.
	var motion := float(surge.call("flash_motion_scale")) if surge != null and surge.has_method("flash_motion_scale") else 1.0
	light.light_energy = float(cfg.get("strike_light_energy", 8.0)) * motion
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
		var strength := float(surge.call("sky_flash_for_strike", at)) * float(cfg.get("strike_sky_strength", 0.18))
		if strength > 0.0:
			surge.call("flash", strength)


## Cached tapered forks. Deterministic visual geometry never consumes the RNG
## that schedules host strikes or chooses their targets. Every branch joins
## the main discharge; only its bottom point touches the impact position.
func _build_strike_bolt(cfg: Dictionary, radius_scale: float = 1.0) -> ArrayMesh:
	var height := float(cfg.get("strike_bolt_height_m", 45.0))
	var width := float(cfg.get("strike_bolt_bottom_radius_m", 0.08))
	var tip := float(cfg.get("strike_bolt_top_radius_m", 0.025))
	var jitter := float(cfg.get("strike_bolt_jitter_m", 0.9))
	var spine := PackedVector3Array()
	var heights := PackedFloat32Array([0.0, 0.012, 0.027, 0.036, 0.052, 0.065, 0.080, 0.105, 0.125, 0.150, 0.177, 0.21, 0.25, 0.31, 0.38, 0.44, 0.53, 0.61, 0.69, 0.78, 0.89, 1.0])
	for k in heights.size():
		var fraction := heights[k]
		spine.append(Vector3(sin(k * 2.37) * jitter * minf(fraction * 8.0, 1.0),
			fraction * height, sin(k * 1.73) * jitter * 0.55 * minf(fraction * 8.0, 1.0)))
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var capsule_uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var paths: Array[PackedVector3Array] = [spine]
	var widths: Array[float] = [1.0]
	for joint in [7, 11, 15]:
		var start: Vector3 = spine[joint]
		var away := Vector3(start.x, 0.0, start.z).normalized()
		var across := Vector3(-away.z, 0.0, away.x)
		# Side leaders diverge out of the main channel's envelope. They
		# never double back through it to draw closed diamond-shaped loops.
		paths.append(PackedVector3Array([start,
			start + away * 1.1 + Vector3.DOWN * 0.65,
			start + away * 1.55 + across * 0.20 + Vector3.DOWN * 1.2,
			start + away * 1.75 - across * 0.13 + Vector3.DOWN * 1.6,
			start + away * 2.55 + across * 0.16 + Vector3.DOWN * 2.8,
			start + away * 2.95 + Vector3.DOWN * 3.9]))
		widths.append(0.48)
	# A second scale of hairline leaders supplies the irregular branching
	# hierarchy of the inspected electrical-channel reference. This visual
	# generator owns its seed and never touches encounter or weather RNG.
	for joint in [3, 5, 8, 10, 13]:
		var start: Vector3 = spine[joint]
		var side := -1.0 if joint % 2 == 0 else 1.0
		paths.append(PackedVector3Array([start,
			start + Vector3(side * 0.34, -0.19, 0.12),
			start + Vector3(side * 0.65, -0.55, 0.25),
			start + Vector3(side * 0.88, -0.91, 0.3)]))
		widths.append(0.26)
	# Short upward return leaders give the discharge a visible termination
	# outside the trainer's boots, instead of burying all contact under them.
	for k in 7:
		var angle := float(k) * TAU / 7.0 + 0.31
		var outward := Vector3(cos(angle), 0.0, sin(angle))
		var sideways := Vector3(-outward.z, 0.0, outward.x)
		paths.append(PackedVector3Array([Vector3.ZERO,
			outward * 0.33 + Vector3.UP * 0.22,
			outward * 0.53 + sideways * 0.13 + Vector3.UP * 0.54,
			outward * 0.78 - sideways * 0.08 + Vector3.UP * 0.29,
			outward * 1.12 + Vector3.UP * 0.08]))
		widths.append(0.42)
	for path_index in paths.size():
		var points := _fracture_channel(paths[path_index], 7139 + path_index * 277)
		for k in points.size() - 1:
			# Capsule ends overlap softly at bends instead of exposing hard
			# triangular gaps. UV2 carries longitudinal metres and channel length.
			var a := vertices.size()
			var tangent := (points[k + 1] - points[k]).normalized()
			var length_m := points[k].distance_to(points[k + 1])
			var fraction := (float(k) + 0.5) / float(points.size() - 1)
			var radius := lerpf(tip, width, fraction) if path_index == 0 else lerpf(width * widths[path_index], 0.004, fraction)
			radius *= radius_scale * (0.82 + 0.18 * sin((float(k) + 0.5) * 0.39 + float(path_index)))
			for endpoint in [k, k + 1]:
				var extension := -radius if endpoint == k else radius
				var along := -radius if endpoint == k else length_m + radius
				for side in [-1.0, 1.0]:
					vertices.append(points[endpoint] + tangent * extension)
					normals.append(tangent)
					uvs.append(Vector2(side, radius))
					capsule_uvs.append(Vector2(along, length_m))
			indices.append_array(PackedInt32Array([a, a + 1, a + 2, a + 1, a + 3, a + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = capsule_uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Refine each coarse bend at three spatial scales. Midpoint displacement
## keeps all authored junctions/contact points while removing long straight
## spans. Core and halo receive identical paths from the same local seed.
func _fracture_channel(control: PackedVector3Array, visual_seed: int) -> PackedVector3Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = visual_seed
	var points := control
	for depth in 3:
		var refined := PackedVector3Array()
		for k in points.size() - 1:
			var a := points[k]
			var b := points[k + 1]
			var amount := minf(a.distance_to(b) * 0.23, 0.40)
			var offset := Vector3(rng.randf_range(-amount, amount),
				0.0, rng.randf_range(-amount, amount))
			refined.append(a)
			refined.append((a + b) * 0.5 + offset)
		refined.append(points[points.size() - 1])
		points = refined
	return points


## The 1.2 s warning: a hazard, not a selection circle or a reward. A flat
## ring on the ground whose rim and glow are the game's one hazard colour,
## combat.json telegraph.colour (magenta; white-violet read as a heal circle
## and amber as reward gold, the same findings combat.json records), exactly
## at strike.radius_m (the 3 m damage contract), a glow past it
## (`edge_falloff_m`). Jagged ground leaders charge inward over the real
## warning time; fine broken perimeter marks retain the exact damage radius.
## Reduced motion keeps the inward countdown and final charge while removing
## faint rim modulation. No opaque disc competes with the strike point.
##
## Cost (review R2-1): one cached, indexed unit mesh is shared by every
## warning. Per strike only the centre plus `height_samples` rim points are
## read from the terrain (<= 25 ground_height_near calls), passed to the
## shader as a height array, and the vertex shader interpolates each vertex's
## height from them (angularly between rim samples, radially from the
## centre, extrapolating past the rim). The rim and glow only (not the
## fill) are pulled toward the camera along the view ray by `depth_pull_m`,
## about grass height, so grass cannot cover the rim while its screen
## position is unchanged.
const TELEGRAPH_SAMPLES := 16
const TELEGRAPH_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec3 rim_colour : source_color = vec3(1.0, 0.25, 0.9);
uniform vec3 edge_colour : source_color = vec3(1.0, 0.25, 0.9);
uniform float rim_fraction = 0.87;
uniform float rim_width = 0.05;
uniform float intensity = 2.2;
uniform float leader_count = 6.0;
uniform float leader_width = 0.055;
uniform float leader_kink = 0.18;
uniform float leader_head_width = 0.32;
uniform float pulse_hz_start = 2.0;
uniform float pulse_hz_end = 7.0;
uniform float telegraph_seconds = 1.2;
uniform float progress = 0.0;
uniform float pulse_enabled = 1.0;
uniform float strike = 0.0;
uniform float fade = 1.0;
uniform float outer_radius = 3.45;
uniform float rim_radius = 3.0;
uniform float centre_height = 0.0;
uniform float rim_heights[16];
uniform float lift = 0.07;
uniform float depth_pull = 0.28;
uniform float pull_start_radius = 2.88;
uniform float ramp_start = 0.75;
uniform float fill_alpha = 0.14;
uniform float charged_fill_alpha = 0.34;
uniform float final_fill_alpha = 0.5;
varying float r;
varying vec2 ground_xz;
void vertex() {
	ground_xz = VERTEX.xz;
	float len = length(VERTEX.xz);
	r = len / outer_radius;
	// The centre vertices have no direction; atan(0, 0) is undefined.
	float angle = len < 0.0001 ? 0.0 : atan(VERTEX.z, VERTEX.x);
	float s = fract(angle / 6.2831853) * 16.0;
	int i0 = int(floor(s)) % 16;
	int i1 = (i0 + 1) % 16;
	float rim_h = mix(rim_heights[i0], rim_heights[i1], fract(s));
	// Unclamped: past the rim the glow band keeps the centre-to-rim slope
	// instead of floating (or cutting in) at rim height on steep ground.
	float radial = len / rim_radius;
	VERTEX.y = centre_height + (rim_h - centre_height) * radial + lift;
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float dist = length(view.xyz);
	// Only the rim and glow are pulled toward the camera (about grass
	// height), never the dark fill, so the fill cannot draw over a trainer
	// standing at the near rim.
	float pull = len >= pull_start_radius ? depth_pull : 0.0;
	view.xyz *= max(0.2, 1.0 - pull / max(dist, 0.001));
	POSITION = PROJECTION_MATRIX * view;
}
void fragment() {
	// Chirp: the pulse rate climbs linearly over the telegraph, integrated
	// so the phase never jumps.
	float t = progress * telegraph_seconds;
	float phase = pulse_hz_start * t + (pulse_hz_end - pulse_hz_start) * t * t / (2.0 * telegraph_seconds);
	// Under reduced motion the rim is steady; the leaders growing with
	// `progress` still carry the timing.
	float pulse = mix(1.0, 0.94 + 0.06 * cos(phase * 6.2832), pulse_enabled);
	float rim = 1.0 - smoothstep(0.0, rim_width, abs(r - rim_fraction));
	float outer = r > rim_fraction ? 1.0 - smoothstep(rim_fraction, 1.0, r) : 0.0;
	float distance_m = length(ground_xz);
	float inside = 1.0 - smoothstep(rim_radius - 0.06, rim_radius, distance_m);
	// Six irregular ground leaders converge on a single strike point.
	// Their bright tips travel inward over the actual warning duration;
	// the continuous timing cue is identical in reduced-motion mode.
	float angle = distance_m < 0.001 ? 0.0 : atan(ground_xz.y, ground_xz.x);
	float sector = floor(angle * leader_count / 6.2831853 + 0.5);
	float lateral = sin(angle - sector * 6.2831853 / leader_count) * distance_m;
	float noise_sector = mod(sector + leader_count, leader_count);
	float step_m = distance_m / 0.38;
	float joint = floor(step_m);
	float a = sin(joint * 2.31 + noise_sector * 1.7);
	float b = sin((joint + 1.0) * 2.31 + noise_sector * 1.7);
	float kink = mix(a, b, fract(step_m)) * leader_kink * min(distance_m, 1.0);
	float tapered_width = leader_width * (0.45 + 0.55 * min(distance_m / rim_radius, 1.0));
	float leader_distance = abs(lateral - kink) / max(tapered_width, 0.005);
	float leader = (exp(-leader_distance * leader_distance) + 0.12 * exp(-leader_distance * leader_distance / 9.0)) * inside;
	float charge_radius = rim_radius * (1.0 - progress);
	float head = 1.0 - smoothstep(leader_head_width * 0.25, leader_head_width, abs(distance_m - charge_radius));
	float charged = smoothstep(charge_radius - 0.08, charge_radius + 0.08, distance_m);
	float urgency = smoothstep(ramp_start, 1.0, progress);
	float leaders = leader * (charged * 0.45 + head * 0.5 + urgency * 0.12);
	// A compact lightning-shaped contact mark distinguishes the intended
	// impact point from a persistent electrical floor. It stays readable
	// while the six surrounding leaders visibly grow toward it.
	vec2 mark = ground_xz / 0.45;
	float mark_x = -0.27 * sign(mark.y) + mark.y * 0.45;
	float contact = (1.0 - smoothstep(0.08, 0.13, abs(mark.x - mark_x)))
		* (1.0 - smoothstep(0.75, 1.0, abs(mark.y)));
	leaders += contact * (0.65 + urgency * 0.25);
	// Fine broken perimeter marks preserve the exact 3 m hazard boundary
	// without making a second broad disc compete with the impact point.
	float dash = 1.0 - smoothstep(0.27, 0.49, abs(fract((angle / 6.2831853 + 0.5) * 24.0) - 0.5));
	// F10#3 round 2 (code-blind judge: "an unfilled dashed outline reads as
	// a target selector"; "t080 and t110 look the same"): a translucent
	// danger fill from the first frame, a stronger charged band that closes
	// from the rim onto the contact point with the leader heads (the whole
	// countdown as one shrinking uncharged disc), and in the final ramp the
	// dashes join into a solid rim and the whole zone brightens.
	float dash_solid = mix(dash, 1.0, urgency);
	float a_rim = rim * dash_solid * (0.32 + urgency * 0.55) * mix(pulse, 1.0, strike);
	float a_edge = outer * dash_solid * 0.10;
	float a_fill = inside * (fill_alpha + charged * (charged_fill_alpha - fill_alpha)
		+ urgency * (final_fill_alpha - charged_fill_alpha) * (1.0 - strike));
	vec3 hot = mix(rim_colour, vec3(0.92, 0.72, 1.0), strike);
	vec3 fill_colour = rim_colour * 0.55;
	vec3 colour = (hot * intensity * (a_rim + leaders) + edge_colour * a_edge + fill_colour * a_fill)
		/ max(a_rim + a_edge + leaders + a_fill, 0.001);
	ALBEDO = colour;
	ALPHA = clamp(a_rim + a_edge + leaders + a_fill, 0.0, 1.0) * fade;
}
"""
static var _telegraph_mesh: ArrayMesh
## Test/probe hook: ground_height_near calls made by the last warning build.
var last_telegraph_height_calls := 0

## Where the final brightening ramp starts, as a fraction of the telegraph.
static func telegraph_ramp_start(telegraph_seconds: float, final_ramp_seconds: float) -> float:
	return clampf(1.0 - final_ramp_seconds / maxf(telegraph_seconds, 0.001), 0.0, 1.0)


## The leader heads advance from rim to contact over the warning duration.
## This probe reports their remaining radius and final charge ramp.
static func telegraph_state(elapsed: float, telegraph_seconds: float, final_ramp_seconds: float) -> Dictionary:
	var progress := clampf(elapsed / maxf(telegraph_seconds, 0.001), 0.0, 1.0)
	var ramp := smoothstep(telegraph_ramp_start(telegraph_seconds, final_ramp_seconds), 1.0, progress)
	return {"progress": progress, "closing_radius_fraction": 1.0 - progress,
		"ramp": ramp}


## The bolt lands at the centre of the ring that warned of it: the warning's
## own position, whatever an impact event carries.
static func bolt_centre(warning_at: Variant, impact_at: Vector3) -> Vector3:
	return warning_at if warning_at is Vector3 else impact_at


## The game's one hazard colour: combat.json telegraph.colour (magenta,
## settled by its `_why_colour_0905` note after amber read as reward gold,
## the same finding this ring's round-3 judge made). Read, never copied.
static func telegraph_colour() -> Color:
	return Color(str(COMBAT_MATH.config().get("telegraph", {}).get("colour", "#ff40e6")))

func _telegraph_config() -> Dictionary:
	return rules.config.get("presentation", {}).get("telegraph", {})

func telegraph_rim_radius() -> float:
	return float(rules.config.strike.radius_m)

func _telegraph_outer_radius() -> float:
	return telegraph_rim_radius() + float(_telegraph_config().get("edge_falloff_m", 0.45))

## One indexed ring mesh in metres, built once and shared.
func _telegraph_unit_mesh() -> ArrayMesh:
	if _telegraph_mesh != null:
		return _telegraph_mesh
	var rim_r := telegraph_rim_radius()
	var outer_r := _telegraph_outer_radius()
	var segments := int(_telegraph_config().get("segments", 48))
	# rim - 0.2 is the last unpulled (fill) row; rim - 0.12 and beyond are
	# the pulled rim/glow rows (see `pull_start_radius`).
	var radii: Array[float] = [0.0, rim_r * 0.45, rim_r * 0.8, rim_r - 0.2, rim_r - 0.12, rim_r, rim_r + 0.12, outer_r]
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for radius: float in radii:
		for k in segments:
			var angle := TAU * float(k) / float(segments)
			vertices.append(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))
	for ring_index in radii.size() - 1:
		for k in segments:
			var a := ring_index * segments + k
			var b := ring_index * segments + (k + 1) % segments
			var c := (ring_index + 1) * segments + (k + 1) % segments
			var d := (ring_index + 1) * segments + k
			indices.append_array(PackedInt32Array([a, b, c, a, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	_telegraph_mesh = ArrayMesh.new()
	_telegraph_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Heights are applied in the shader; give culling room for slopes.
	_telegraph_mesh.custom_aabb = AABB(Vector3(-outer_r, -6.0, -outer_r), Vector3(outer_r * 2.0, 12.0, outer_r * 2.0))
	return _telegraph_mesh

func _telegraph_material() -> ShaderMaterial:
	var cfg := _telegraph_config()
	if _telegraph_shader == null:
		_telegraph_shader = Shader.new()
		_telegraph_shader.code = TELEGRAPH_SHADER
	var rim_r := telegraph_rim_radius()
	var outer_r := _telegraph_outer_radius()
	var material := ShaderMaterial.new()
	material.shader = _telegraph_shader
	var hazard := telegraph_colour()
	material.set_shader_parameter("rim_colour", hazard)
	material.set_shader_parameter("edge_colour", hazard)
	material.set_shader_parameter("rim_fraction", rim_r / outer_r)
	material.set_shader_parameter("rim_width", float(cfg.get("rim_width_m", 0.16)) / outer_r)
	material.set_shader_parameter("intensity", float(cfg.get("rim_intensity", 2.4)))
	material.set_shader_parameter("leader_count", float(cfg.get("leader_count", 6.0)))
	material.set_shader_parameter("leader_width", float(cfg.get("leader_width_m", 0.055)))
	material.set_shader_parameter("leader_kink", float(cfg.get("leader_kink_m", 0.18)))
	material.set_shader_parameter("leader_head_width", float(cfg.get("leader_head_width_m", 0.32)))
	material.set_shader_parameter("fill_alpha", float(cfg.get("fill_alpha", 0.14)))
	material.set_shader_parameter("charged_fill_alpha", float(cfg.get("charged_fill_alpha", 0.34)))
	material.set_shader_parameter("final_fill_alpha", float(cfg.get("final_fill_alpha", 0.5)))
	material.set_shader_parameter("pulse_hz_start", float(cfg.get("pulse_hz_start", 2.0)))
	material.set_shader_parameter("pulse_hz_end", float(cfg.get("pulse_hz_end", 7.0)))
	material.set_shader_parameter("telegraph_seconds", float(rules.config.strike.telegraph_seconds))
	material.set_shader_parameter("outer_radius", outer_r)
	material.set_shader_parameter("rim_radius", rim_r)
	material.set_shader_parameter("lift", float(cfg.get("ground_lift_m", 0.07)))
	material.set_shader_parameter("depth_pull", float(cfg.get("depth_pull_m", 0.28)))
	material.set_shader_parameter("pulse_enabled", 0.0 if MOTION_PREFS.reduced_motion() else 1.0)
	material.set_shader_parameter("ramp_start", telegraph_ramp_start(float(rules.config.strike.telegraph_seconds),
		float(cfg.get("final_ramp_seconds", 0.3))))
	material.set_shader_parameter("pull_start_radius", rim_r - 0.15)
	return material

func _build_telegraph(at: Vector3) -> MeshInstance3D:
	var rim_r := telegraph_rim_radius()
	var material := _telegraph_material()
	var sample := world != null and world.has_method("ground_height_near")
	var calls := 0
	var centre := 0.0
	var heights := PackedFloat32Array()
	heights.resize(TELEGRAPH_SAMPLES)
	if sample:
		centre = float(world.call("ground_height_near", at)) - at.y
		calls += 1
	for k in TELEGRAPH_SAMPLES:
		var angle := TAU * float(k) / float(TELEGRAPH_SAMPLES)
		if sample:
			var offset := Vector3(cos(angle), 0.0, sin(angle)) * rim_r
			heights[k] = float(world.call("ground_height_near", at + offset)) - at.y
			calls += 1
	last_telegraph_height_calls = calls
	material.set_shader_parameter("centre_height", centre)
	material.set_shader_parameter("rim_heights", heights)
	var ring := MeshInstance3D.new()
	ring.name = "StrikeTelegraph"
	ring.mesh = _telegraph_unit_mesh()
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.material_override = material
	ring.set_meta("rim_radius_m", rim_r)
	ring.set_meta("telegraph_seconds", float(rules.config.strike.telegraph_seconds))
	return ring

## Compile the telegraph shader at realm load rather than on the first
## warning's frame. The ring must actually DRAW for its variant to compile,
## so it waits for the active camera, sits briefly 4 m in front of it fully
## faded (alpha 0), and is freed a few frames later.
func _prewarm_telegraph() -> void:
	var camera: Camera3D = null
	for _frame in 240:
		if not is_inside_tree():
			return
		camera = get_viewport().get_camera_3d()
		if camera != null:
			break
		await get_tree().process_frame
	if camera == null or not is_inside_tree():
		return
	var ring := MeshInstance3D.new()
	ring.name = "TelegraphPrewarm"
	ring.mesh = _telegraph_unit_mesh()
	var material := _telegraph_material()
	material.set_shader_parameter("fade", 0.0)
	material.set_shader_parameter("rim_heights", PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	ring.global_position = camera.global_position - camera.global_basis.z * 4.0
	for _frame in 4:
		# The realm can be freed mid-warmup on a quick transition; stop cleanly.
		if not is_inside_tree():
			return
		await get_tree().process_frame
	if is_instance_valid(ring):
		ring.queue_free()


func _expire_warning(id: int) -> void:
	var ring: Variant = _visuals.get(id)
	_visuals.erase(id)
	_warning_centres.erase(id)
	if is_instance_valid(ring):
		ring.queue_free()


## Coordinator interim ruling (stormwood_surge.json strike
## `_why_spare_trainer_in_fight`): a trainer committed to a creature fight is
## neither aimed at nor hit; the strike may aim at the piloted creature instead.
func _spare_trainer_in_fight() -> bool:
	return bool(rules.config.strike.get("spare_trainer_in_fight", false))


## Host view of whether `peer`'s trainer is in a creature fight: the local
## combat manager or hosted trainer battle for the host's own trainer, and for
## any peer an open host encounter record (shared wild, hosted trainer) that
## lists it, or a registered Stormwood hosted fight that does. A guest's
## unshared local wild fight is not visible to the host (MULTIPLAYER §4).
func _trainer_in_fight(peer: int) -> bool:
	if world == null or session == null or not _spare_trainer_in_fight():
		return false
	var local := peer == int(session.local_peer_id()) and not bool(world.get("simulation_only"))
	var manager := world.get_node_or_null(^"CombatManager")
	var director := world.get_node_or_null(^"EncounterDirector")
	var local_fighting := local and ((manager != null and bool(manager.call("is_fighting"))) \
		or (director != null and bool(director.call("trainer_battle_active"))))
	var hub := world.get_node_or_null(^"StormwoodEncounterHub")
	var records: Dictionary = {}
	var fight_participants: Array = []
	if hub != null:
		var authority: Variant = hub.get("authority")
		if authority is Object:
			records = (authority as Object).get("encounters")
		for fight: Variant in (hub.get("fights") as Dictionary).values():
			if is_instance_valid(fight) and not bool((fight as Object).get("finished")):
				fight_participants.append_array((fight as Object).get("participants"))
	return peer_in_fight(peer, local_fighting, records, fight_participants)


func _creature_body_for(peer: int) -> Node3D:
	var director := world.get_node_or_null(^"EncounterDirector") if world != null else null
	if director == null:
		return null
	var body: Variant = director.call("deployed_body_for", peer)
	return body as Node3D if is_instance_valid(body) else null


## Pure: is `peer` in a creature fight, from the host's records.
static func peer_in_fight(peer: int, local_fighting: bool, records: Dictionary,
		fight_participants: Array) -> bool:
	if local_fighting or fight_participants.has(peer):
		return true
	for record: Variant in records.values():
		if not record is Dictionary or str((record as Dictionary).get("phase", "")) == "done":
			continue
		var participants: Variant = (record as Dictionary).get("participants", {})
		if participants is Dictionary and (participants as Dictionary).has(peer):
			return true
		if participants is Array and (participants as Array).has(peer):
			return true
	return false


## Pure: where a strike chosen for this trainer aims, or null for none. A
## fighting trainer is spared; the strike aims at the piloted creature, or
## is skipped when no creature body is out.
static func strike_aim(trainer_at: Vector3, in_fight: bool, creature_at: Variant, spare: bool) -> Variant:
	if not (spare and in_fight):
		return trainer_at
	return creature_at if creature_at is Vector3 else null


## Pure: may an impact damage this trainer.
static func trainer_can_be_hit(in_fight: bool, spare: bool) -> bool:
	return not (spare and in_fight)
