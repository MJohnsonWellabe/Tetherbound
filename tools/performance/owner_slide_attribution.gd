extends RefCounted

# Diagnostic only: no gameplay writes, physics queries, printing or timed I/O.
static var enabled := false
static var rows: Array[Array] = []
static var identities: Dictionary = {}
static var property_names: Dictionary = {}
static var source := ""
static var route_context: Dictionary = {}
static var start_process := -1
static var start_physics := -1
static var end_process := -1
static var end_physics := -1
static var capacity_reached := false
const ROW_LIMIT := 20000
const SLOW_USEC := 2000
const CONTACT_LIMIT := 4

static func prepare(world: Node, actual_source: String) -> void:
	enabled = false
	rows.clear()
	identities.clear()
	property_names.clear()
	source = actual_source
	start_process = -1
	start_physics = -1
	end_process = -1
	end_physics = -1
	capacity_reached = false
	route_context.clear()
	_register_tree(world)

static func _register_tree(node: Node) -> void:
	if node is CharacterBody3D and node.has_method("body_radius"):
		_register(node)
	for child: Node in node.get_children():
		_register_tree(child)

static func _register(body: CharacterBody3D) -> void:
	var id := body.get_instance_id()
	if identities.has(id):
		return
	var names := {}
	for item: Dictionary in body.get_property_list():
		names[str(item.name)] = true
	property_names[id] = names
	var world: Node = body.get_parent()
	while world != null:
		var script: Script = world.get_script() as Script
		if script != null and script.resource_path.ends_with("_world.gd"):
			break
		world = world.get_parent()
	var script: Script = body.get_script() as Script
	var identity := {"instance_id": id, "path": str(body.get_path()),
		"name": str(body.name), "script": script.resource_path if script != null else "",
		"species_id": str(body.get("species_id")), "world_path": str(world.get_path()) if world != null else "",
		"world_script": str(world.get_script().resource_path) if world != null else "",
		"configured_route_realm": "water", "body_authority_initial": body.get_multiplayer_authority(),
		"is_multiplayer_authority_initial": body.is_multiplayer_authority(),
		"authority_meaning": "Observed Node authority only; not inferred encounter-host ownership"}
	if world != null:
		for item: Dictionary in world.get_property_list():
			if str(item.name) == "simulation_only":
				identity["world_simulation_only"] = bool(world.get("simulation_only"))
	for key: String in ["owner_peer_id", "trainer_owned"]:
		if names.has(key):
			identity[key + "_initial"] = body.get(key)
	if names.has("authority_node"):
		var authority: Node = body.get("authority_node") as Node
		identity["authority_node_initial"] = str(authority.get_path()) if is_instance_valid(authority) else ""
	identities[id] = identity

static func start(context: Dictionary) -> void:
	if start_process >= 0:
		return
	route_context = context.duplicate(true)
	start_process = Engine.get_process_frames()
	start_physics = Engine.get_physics_frames()
	enabled = true

static func stop() -> void:
	enabled = false
	end_process = Engine.get_process_frames()
	end_physics = Engine.get_physics_frames()

static func before_slide(body: CharacterBody3D, requested: Vector3) -> int:
	if not enabled:
		return -1
	if rows.size() >= ROW_LIMIT:
		capacity_reached = true
		enabled = false
		return -1
	var outside_start := Time.get_ticks_usec()
	_register(body)
	var id := body.get_instance_id()
	var names: Dictionary = property_names[id]
	var engaged := bool(body.get("engaged")) if names.has("engaged") else false
	var owner: Variant = body.get("owner_peer_id") if names.has("owner_peer_id") else null
	var index := rows.size()
	rows.append([id, Engine.get_physics_frames(), Engine.get_process_frames(),
		body.global_position, body.velocity, body.is_on_floor(), requested,
		body.get_multiplayer_authority(), engaged, owner, outside_start])
	return index

static func after_slide(body: CharacterBody3D, index: int, begin_usec: int, end_usec: int) -> void:
	var row: Array = rows[index]
	var duration := end_usec - begin_usec
	var contacts: Array[Dictionary] = []
	var contact_count := body.get_slide_collision_count()
	if duration >= SLOW_USEC:
		for at in mini(contact_count, CONTACT_LIMIT):
			var contact := body.get_slide_collision(at)
			var collider: Object = contact.get_collider()
			contacts.append({"index": at, "collider_id": contact.get_collider_id(),
				"collider_class": collider.get_class() if is_instance_valid(collider) else "",
				"collider_path": str(collider.get_path()) if collider is Node else "",
				"collider_shape": contact.get_collider_shape(), "local_shape": contact.get_local_shape(),
				"normal": contact.get_normal(), "position": contact.get_position()})
	row.append_array([body.global_position, body.velocity, body.is_on_floor(),
		duration, contact_count, contacts, begin_usec - int(row[10]), 0])
	row[18] = Time.get_ticks_usec() - end_usec

static func _json_value(value: Variant) -> Variant:
	if value is Vector3:
		return [value.x, value.y, value.z]
	if value is Array:
		var converted: Array = []
		for item: Variant in value:
			converted.append(_json_value(item))
		return converted
	if value is Dictionary:
		var converted := {}
		for key: Variant in value:
			converted[key] = _json_value(value[key])
		return converted
	return value

static func flush(path: String, route_complete: bool, route_finished_usec: int) -> Error:
	if enabled:
		return ERR_BUSY
	var summaries := {}
	for row: Array in rows:
		var id: int = row[0]
		if not summaries.has(id):
			summaries[id] = {"calls": 0, "total_slide_usec": 0, "maximum_slide_usec": 0,
				"slow_calls": 0, "observed_contacts": 0, "outside_timer_pre_usec": 0,
				"outside_timer_post_usec": 0}
		var item: Dictionary = summaries[id]
		item.calls += 1
		item.total_slide_usec += int(row[14])
		item.maximum_slide_usec = maxi(item.maximum_slide_usec, int(row[14]))
		item.slow_calls += int(int(row[14]) >= SLOW_USEC)
		item.observed_contacts += int(row[15])
		item.outside_timer_pre_usec += int(row[17])
		item.outside_timer_post_usec += int(row[18])
	var data := {"schema_version": 1, "diagnostic_only": true, "source": source,
		"complete": route_complete and start_process >= 0 and not rows.is_empty() and not capacity_reached,
		"engine": Engine.get_version_info(), "is_debug_build": OS.is_debug_build(),
		"route_context": route_context, "start_process": start_process, "start_physics": start_physics,
		"end_process": end_process, "end_physics": end_physics, "route_finished_usec": route_finished_usec,
		"row_limit": ROW_LIMIT, "capacity_reached": capacity_reached, "slow_usec": SLOW_USEC,
		"identities": identities, "summaries": summaries, "row_count": rows.size(),
		"columns": ["body_id", "physics_tick", "process_frame", "position_before", "integrated_velocity_before",
			"on_floor_before", "requested", "node_authority", "engaged", "owner_peer_id", "outside_pre_start_usec",
			"position_after", "velocity_after", "on_floor_after", "slide_usec", "existing_slide_contact_count",
			"slow_call_existing_contacts", "outside_timer_pre_usec", "outside_timer_post_usec"],
		"rows": rows,
		"limits": "Base CreatureBody slide only: wild/follower/authority subclasses reaching it. Player and remote proxy own slide paths are not instrumented. Timings include wall-clock native call plus return dispatch and clock-read boundary cost. Probe and existing route frame timings are instrumented diagnostics, not shipping performance acceptance. Outside-timer overhead totals do not include all wrapper/clock/branch costs. Existing contacts are observed results, not native recovery-vs-sweep phase timing. No extra physics queries; no timed printing or I/O."}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(_json_value(data), "\t") + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	return error
