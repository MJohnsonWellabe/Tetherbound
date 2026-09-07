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
	if surge.phase_at_position(at) != "break" or not exposed(at, body):
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
	return rules.eligible_ground(at, str(surge.region_at(at)), sheltered(at, body))

func sheltered(at: Vector3, body: Node3D = null) -> bool:
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
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = 2.7
		mesh.outer_radius = 3.0
		ring.mesh = mesh
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("d4b8ff")
		material.emission_enabled = true
		material.emission = Color("b49bff")
		material.emission_energy_multiplier = 4
		ring.material_override = material
		add_child(ring)
		ring.global_position = event.at
		_visuals[id] = ring
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if is_instance_valid(ring):
				ring.queue_free()
			_visuals.erase(id))
		return
	if str(event.get("kind", "")) != "impact":
		return
	if _received_impacts.has(id):
		return
	_received_impacts.append(id)
	if _received_impacts.size() > 256:
		_received_impacts.pop_front()
	if _visuals.has(id):
		var ring: Node3D = _visuals[id]
		_visuals.erase(id)
		var tween := ring.create_tween()
		tween.tween_property(ring, "scale", Vector3(1.15, 8, 1.15), 0.12)
		tween.tween_callback(ring.queue_free)
	var hits: Dictionary = event.get("hits", {})
	if not hits.has(session.local_peer_id()):
		return
	var player := world.get_node("Player") as CharacterBody3D
	var vitals: RefCounted = player.get("vitals")
	if vitals == null or vitals.is_dead():
		return
	var effect: Dictionary = hits[session.local_peer_id()]
	vitals.health = maxf(0.0, float(vitals.health) - minf(float(effect.damage), float(vitals.max_health) * 0.25))
	vitals._apply_buff({"id": "stormwood_static", "stat": "stamina_regen_scale", "amount": 0.5, "duration_s": float(effect.static_seconds)})
	player.velocity *= 0.25
	if vitals.is_dead():
		player.died.emit()
