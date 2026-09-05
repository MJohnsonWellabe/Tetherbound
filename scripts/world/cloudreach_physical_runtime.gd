extends Node3D

## Full physical chapter adapter. Configure after adding to a realm scene.
## Dialogue queue and modal input ownership stay in CloudreachChapter.
signal interaction_completed(id: String)
signal trial_progress(gates_passed: int, gate_count: int)
signal placement_failed(id: String, position: Vector3)
signal encounter_recorded(id: String, first_victory: bool)

const RULES := preload("res://scripts/world/cloudreach_physical_rules.gd")
const BOND_FEEDBACK := preload("res://scripts/creatures/bond_milestones.gd")
const PROGRESSION_FEEDBACK := preload("res://scripts/creatures/progression_feed.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const REST := preload("res://scripts/world/rest_point.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")
const NPCS := preload("res://scripts/world/village_npcs.gd")
const DATA_PATH := "res://data/config/cloudreach_physical_runtime.json"
const CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const NPC_PATH := "res://data/config/cloudreach_npc_runtime.json"

var config: Dictionary = {}
var chapter: Dictionary = {}
var npc_runtime: Dictionary = {}
var trial_active := false
var trial_gate_index := 0
var trial_flight_seconds := 0.0
var _player: CharacterBody3D
var _fly: Node
var _game: Node
var _event: Callable
var _ground: Callable
var _reward: Callable
var _flags: RefCounted
var _revision := -1
var _prompts: Dictionary = {}
var _placements: Dictionary = {}
var _people: Node3D
var _npc_positions: Dictionary = {}
var _previous := Vector3.INF
var _last_flight_position := Vector3.INF
var _flight_observed := false
var _air_approaches: Dictionary = {}
var _gate_root: Node3D
var _topic_root: Node3D
var _build_content := true
var _registered_flight_ids: Array[String] = []
var _pylon_material: StandardMaterial3D


## ground_resolver(Vector3) returns Vector3 on the intended walkable surface or
## Vector3.INF to reject. reward_callback(id) returns true after durable payout;
## if absent, defeat is recorded but payout stays pending for combat integration.
func configure(player: CharacterBody3D, fly: Node, event_adapter: Callable,
		ground_resolver: Callable, data: Dictionary = {}, reward_callback: Callable = Callable(),
		build_content: bool = true) -> void:
	_player = player
	_fly = fly
	_game = get_node_or_null(^"/root/Game")
	_flags = _game.get("progression") if _game != null else null
	_event = event_adapter
	_ground = ground_resolver
	_reward = reward_callback
	_build_content = build_content
	config = RULES.read(DATA_PATH) if data.is_empty() else data.duplicate(true)
	chapter = RULES.read(CHAPTER_PATH)
	npc_runtime = RULES.read(NPC_PATH)
	add_to_group("progression_restore")
	if _fly != null:
		_register_flight()
		if not _fly.is_connected("landed", _on_landed):
			_fly.connect("landed", _on_landed)
		if not _fly.is_connected("recovered", _on_recovered):
			_fly.connect("recovered", _on_recovered)
	_build_interactions()
	_build_trial_markers()
	sync_progression()


func _ready() -> void:
	set_physics_process(true)


func _in_realm() -> bool:
	return _game != null and str(_game.get("current_realm")) == "cloudreach" and _flags != null


func _emit(event: String) -> Dictionary:
	if not _in_realm() or not _event.is_valid():
		return {"accepted": false, "changed": false}
	return _event.call(event)


func _physics_process(delta: float) -> void:
	if not _in_realm() or not is_instance_valid(_player):
		return
	if int(_flags.get("revision")) != _revision:
		sync_progression()
	var at := _player.global_position
	var flying := _fly != null and bool(_fly.call("is_flying"))
	if flying:
		_flight_observed = true
		_last_flight_position = at
		for spec: Dictionary in config.get("landing_objectives", []):
			if spec.has("approach_position") and RULES.holds(_flags, spec.get("requires_flags", [])) \
				and at.distance_to(RULES.vec(spec["approach_position"])) <= float(spec.get("approach_radius_m", 20)):
				_air_approaches[spec["id"]] = true
		if trial_active:
			trial_flight_seconds += delta
			var bounds := _bounds(config["trial"])
			if not bounds.has_point(at):
				_cancel_trial("Return to the launch marker to retry the flight trial.")
			elif _previous != Vector3.INF and at.distance_to(_previous) < 10.0:
				var next := RULES.next_gate(trial_gate_index, _previous, at, config["trial"]["gates"], true)
				if next != trial_gate_index:
					trial_gate_index = next
					trial_progress.emit(next, config["trial"]["gates"].size())
					_message("Flight gates: %d/%d" % [next, config["trial"]["gates"].size()])
	elif _player.is_on_floor():
		for spec: Dictionary in config.get("ground_triggers", []):
			if RULES.available(_flags, spec) and RULES.in_landing(at, spec):
				_emit(spec["event"])
		if _fly != null:
			_fly.call("observe_ground")
	_previous = at
	# Fly handles aerial recovery. This extends the same verified anchor to an
	# ordinary grounded walk off a cliff; it cannot snap to an upper XZ surface.
	if _fly != null and not flying:
		var anchor: Vector3 = _fly.get("safe_anchor")
		if anchor != Vector3.INF and at.y < anchor.y - 100.0:
			_fly.call("recover_to_anchor", "Recovered at your last safe landing.")


func _register_flight() -> void:
	# Remove only this adapter's old registration on explicit reconfiguration.
	for field: String in ["updrafts", "restrictions"]:
		var entries: Array = _fly.get(field)
		for i in range(entries.size() - 1, -1, -1):
			if _registered_flight_ids.has(str(entries[i].get("id", ""))):
				entries.remove_at(i)
	_registered_flight_ids.clear()
	for spec: Dictionary in config.get("updrafts", []):
		_fly.call("register_updraft", spec["id"], _box(spec), float(spec["lift_speed"]), float(spec["ceiling_y"]), str(spec.get("requires_flag", "")))
		_registered_flight_ids.append(spec["id"])
	for spec: Dictionary in config.get("restrictions", []):
		_fly.call("register_restriction", spec["id"], _box(spec), spec["requires_flag"])
		_registered_flight_ids.append(spec["id"])
	var lift: Dictionary = config.get("trial", {}).get("updraft", {})
	if not lift.is_empty():
		_fly.call("register_updraft", lift["id"], _box(lift), float(lift["lift_speed"]), float(lift["ceiling_y"]), "cloudreach_act_i_complete")
		_registered_flight_ids.append(lift["id"])
	_fly.call("set_trial_authorization", AABB())


func _build_interactions() -> void:
	for spec: Dictionary in config.get("interactions", []):
		var at := _resolve(spec["id"], RULES.vec(spec["position"]))
		if at == Vector3.INF:
			continue
		var root := Node3D.new()
		root.name = str(spec["id"])
		add_child(root)
		root.global_position = at
		var prompt := INTERACTABLE.new()
		prompt.name = "Interactable"
		prompt.position = Vector3.UP * 0.8
		prompt.configure(spec["label"], float(config.get("interaction_radius_m", 3.8)), false)
		root.add_child(prompt)
		prompt.activated.connect(activate.bind(str(spec["id"])))
		_prompts[spec["id"]] = {"prompt": prompt, "spec": spec, "root": root}
		if _build_content:
			_build_prop(root, spec)


## Called by the real prompt, and still independently checks physical access.
func activate(id: String) -> bool:
	if not _in_realm() or not _prompts.has(id) or _player == null:
		return false
	var entry: Dictionary = _prompts[id]
	var spec: Dictionary = entry["spec"]
	var root: Node3D = entry["root"]
	if not RULES.available(_flags, spec) or not _player.is_on_floor() \
		or _player.global_position.distance_to(root.global_position) > float(config.get("interaction_radius_m", 3.8)):
		return false
	if _player.has_method("locomotion_enabled") and not _player.call("locomotion_enabled"):
		return false
	if spec.get("action", "") == "start_trial":
		return _start_trial()
	var cost: Dictionary = spec.get("cost", {})
	var inventory: RefCounted = _game.get("inventory")
	if not cost.is_empty() and (inventory == null or int(inventory.call("count", cost["item_id"])) < int(cost["count"])):
		_message("Bring %d %s to finish this repair." % [int(cost["count"]), str(cost["item_id"]).replace("_", " ")])
		return false
	var changed := false
	if spec.has("set_physical_flag"):
		var flag := str(spec["set_physical_flag"])
		if not (npc_runtime.get("physical_state_flags", []) as Array).has(flag):
			return false
		_flags.call("set_flag", flag)
		changed = true
	else:
		changed = bool(_emit(str(spec.get("event", ""))).get("changed", false))
	if not changed:
		return false
	if not cost.is_empty():
		inventory.call("remove", cost["item_id"], int(cost["count"]))
	interaction_completed.emit(id)
	_message(str(spec["label"]).split(" (")[0] + " — complete")
	sync_progression()
	return true


func _start_trial() -> bool:
	if _fly == null or trial_active or bool(_fly.call("is_flying")):
		return false
	_fly.call("observe_ground")
	trial_active = true
	trial_gate_index = 0
	trial_flight_seconds = 0.0
	_flight_observed = false
	_previous = _player.global_position
	_fly.call("set_trial_authorization", _bounds(config["trial"]))
	_gate_root.visible = true
	_message("Jump, then press Jump again to deploy. Hold Jump in the current; pass each ring and land back on the perch.")
	return true


func _on_landed(at: Vector3, _species_id: String) -> void:
	if not _in_realm() or _player == null or not _player.is_on_floor() \
		or not _flight_observed or at.distance_to(_player.global_position) > 0.5 \
		or _last_flight_position == Vector3.INF or at.distance_to(_last_flight_position) > 10.0:
		return
	if trial_active:
		var trial: Dictionary = config["trial"]
		var landing := {"position": trial["landing_position"], "radius_m": trial["landing_radius_m"], "height_tolerance_m": trial["landing_height_tolerance_m"]}
		if trial_gate_index == trial["gates"].size() and trial_flight_seconds >= float(trial["minimum_flight_seconds"]) and RULES.in_landing(at, landing):
			var result := _emit("flight_trial_completed")
			if result.get("changed", false):
				_credit_fly_route_bond()
			_cancel_trial("Fly unlocked. Follow the rising currents to the Sky Shrine." if result.get("changed", false) else "Trial complete; return to Maela.")
		else:
			_cancel_trial("Land after all three wind gates. Return to the launch marker to retry.")
	for spec: Dictionary in config.get("landing_objectives", []):
		if RULES.available(_flags, spec) and RULES.in_landing(at, spec) \
			and (not spec.has("approach_position") or _air_approaches.has(spec["id"])):
			if _emit(spec["event"]).get("changed", false):
				_credit_fly_route_bond()
				_message("Landing recorded: " + str(spec["id"]).replace("_", " "))
	_flight_observed = false
	_air_approaches.clear()
	sync_progression()


## Only reached after the production landing/gate/flight-duration checks and
## a newly committed canonical completion event. Repeated landing/load cannot
## farm this small existing travel-task credit or invent a sixth bond task.
func _credit_fly_route_bond() -> void:
	# Maela's safety carrier is not owned and must not quietly credit an unrelated
	# active party member as though that creature performed the flight.
	if _fly != null and _fly.has_method("last_flight_used_mentor_loaner") \
			and bool(_fly.call("last_flight_used_mentor_loaner")):
		return
	var party: RefCounted = _game.get("party") if _game != null else null
	var creature: RefCounted = party.call("active") if party != null else null
	if creature != null and not bool(creature.get("fainted")):
		BOND_FEEDBACK.credit_distance(creature, float(PROGRESSION_FEEDBACK.config().fly_route_bond_meters), "fly_route")


func _on_recovered(_reason: String) -> void:
	_cancel_trial("")
	_flight_observed = false
	_air_approaches.clear()


func _cancel_trial(message: String) -> void:
	trial_active = false
	trial_gate_index = 0
	trial_flight_seconds = 0.0
	if _fly != null:
		# Revoking the trial volume while still in unauthorized flight would
		# remove its containment. Recover first; retain containment if recovery
		# cannot yet verify a floor (the ordinary landing will revoke it).
		if _fly.call("is_flying") and not _flags.call("has", "fly_traversal_unlocked"):
			_fly.call("recover_to_anchor", "Returned to the trial launch.")
		if not _fly.call("is_flying") or _flags.call("has", "fly_traversal_unlocked"):
			_fly.call("set_trial_authorization", AABB())
	if _gate_root != null:
		_gate_root.visible = false
	if not message.is_empty():
		_message(message)


## The existing chapter drains its panel and delegates only Cloudreach effects.
## No queue is read here, avoiding two listeners consuming each other's events.
func consume_dialogue_effect(effect: String) -> bool:
	if not _in_realm():
		return false
	var guard := RULES.dialogue_guard(_flags, npc_runtime, effect)
	if guard.is_empty():
		return false
	return bool(_emit(guard["event"]).get("accepted", false))


## Trusted combat seam. Caller owns genuine victory detection, never a Talk
## effect. Returns false for unknown/wrong-order IDs; duplicate wins are safe.
func encounter_won(id: String) -> bool:
	if not _in_realm() or not RULES.encounter_allowed(_flags, chapter, config, id):
		return false
	var spec := RULES.encounter_spec(chapter, id)
	var defeat_flag := str(spec["defeat_flag"])
	var first := not bool(_flags.call("has", defeat_flag))
	if id == "captain_veyra_storm_anchor":
		if not _emit("encounter:captain_veyra_storm_anchor_won").get("accepted", false):
			return false
	else:
		_flags.call("set_flag", defeat_flag)
	var payout_flag := "cloudreach_payout:" + id
	if not bool(_flags.call("has", payout_flag)) and _reward.is_valid() and bool(_reward.call(id)):
		_flags.call("set_flag", payout_flag)
	for event: String in RULES.circuit_events(_flags, config):
		_emit(event)
	encounter_recorded.emit(id, first)
	sync_progression()
	return true


func sync_progression() -> void:
	if not _in_realm():
		return
	for event: String in RULES.circuit_events(_flags, config):
		_emit(event)
	_revision = int(_flags.get("revision"))
	for entry: Dictionary in _prompts.values():
		entry["prompt"].call("set_enabled", RULES.available(_flags, entry["spec"]))
		var visual: Node3D = entry["root"].get_node_or_null("Presentation")
		if visual != null:
			visual.rotation.y = PI * 0.5 if _flags.call("has", entry["spec"].get("completion_flag", "")) else 0.0
	if _build_content:
		_sync_pickups_and_camps()
		_sync_npcs()
		if is_instance_valid(_topic_root):
			for prompt: Node in _topic_root.get_children():
				prompt.call("set_enabled", RULES.holds(_flags, prompt.get_meta("requires_flags", [])))


func restore_progression_from_game(game: Node) -> void:
	_game = game
	_flags = game.get("progression")
	_cancel_trial("")
	_flight_observed = false
	_air_approaches.clear()
	_previous = Vector3.INF
	# Rebuild disposable placements: loading an earlier save must restore a
	# previously taken cache and remove a camp unlocked only in the later save.
	for candidate: Variant in _placements.values():
		if is_instance_valid(candidate):
			var node := candidate as Node3D
			PICKUP_GLOW.detach(node)
			node.queue_free()
	_placements.clear()
	_npc_positions.clear()
	sync_progression()


func _sync_pickups_and_camps() -> void:
	for spec: Dictionary in chapter.get("pickups", []):
		var id := str(spec["id"])
		var flag := str(spec.get("requires_unlock", ""))
		if (not flag.is_empty() and not _flags.call("has", flag)) or CACHE.was_taken(_game, spec["item_id"], id, "cloudreach"):
			continue
		if _placements.has(id) and is_instance_valid(_placements[id]):
			continue
		var at := _resolve(id, RULES.vec(config.get("pickup_overrides", {}).get(id, spec["position"])))
		if at == Vector3.INF:
			continue
		var pickup := CACHE.new()
		pickup.name = id
		add_child(pickup)
		pickup.global_position = at
		var definition: Dictionary = _game.get("items").call("definition", spec["item_id"])
		pickup.setup(spec["item_id"], "Take " + str(definition.get("name", spec["item_id"])), str(definition.get("world_model", "")), float(definition.get("world_model_scale", 1)), id, "cloudreach", int(spec.get("count", 1)))
		_placements[id] = pickup
	for spec: Dictionary in chapter.get("camping_contract", {}).get("camps", []):
		var id := str(spec["id"])
		var flag := str(spec.get("requires_flag", ""))
		if _placements.has(id) or (not flag.is_empty() and not _flags.call("has", flag)):
			continue
		var at := _resolve(id, RULES.vec(spec["position"]))
		if at == Vector3.INF:
			continue
		var rest := REST.new()
		rest.name = id
		add_child(rest)
		var rest_spec := camp_rest_spec(spec, at)
		rest.build(rest_spec)
		# rest_point.gd's authored-data API is shared with the Meadows props
		# clusters, whose parent is at the world origin. Cloudreach camps are
		# mounted below this runtime at their own world position, so correct the
		# child bed's global transform after the shared build call; otherwise its
		# world-coordinate `at` would be applied twice. The decorative trainer
		# bed remains a local camp prop, deliberately separate from this pad.
		_place_camp_creature_bed(rest, spec, at)
		var bed_path := "res://assets/props/quaternius_fantasy/Bed_Twin1.gltf"
		if ResourceLoader.exists(bed_path):
			var bed_scene := load(bed_path) as PackedScene
			if bed_scene != null:
				var trainer_bed := bed_scene.instantiate() as Node3D
				if trainer_bed != null:
					# Keep the installed human/trainer bed as camp dressing, but
					# give it its own side of the fire so it cannot overlap the
					# creature pad or either interaction prompt.
					trainer_bed.position = Vector3(-1.8, 0.0, -1.2)
					rest.add_child(trainer_bed)
		_placements[id] = rest


## Build the common authored-rest payload. Creature recovery is opt-in from
## chapter data so a future camp that offers only player rest/craft cannot gain
## a hidden party-healing bed merely by reusing this runtime path.
static func camp_rest_spec(camp: Dictionary, resolved: Vector3) -> Dictionary:
	var id := str(camp.get("id", "camp"))
	var payload := {
		"at": [resolved.x, resolved.z],
		"height": resolved.y,
		"label": "Rest at " + id.replace("_", " "),
		"craft": true,
		"radius": 3.2,
	}
	var services: Variant = camp.get("services", [])
	var bed: Variant = camp.get("creature_bed", {})
	if services is Array and (services as Array).has("creature_recovery") \
			and bed is Dictionary and not (bed as Dictionary).is_empty():
		payload["creature_bed"] = (bed as Dictionary).duplicate(true)
	return payload


func _place_camp_creature_bed(rest: Node3D, camp: Dictionary, resolved: Vector3) -> void:
	var services: Variant = camp.get("services", [])
	var raw: Variant = camp.get("creature_bed", {})
	if not services is Array or not (services as Array).has("creature_recovery") \
			or not raw is Dictionary or (raw as Dictionary).is_empty():
		return
	var bed_at: Variant = (raw as Dictionary).get("at", [])
	if not bed_at is Array or (bed_at as Array).size() < 2:
		return
	var bed_world := _resolve(str(camp.get("id", "camp")) + "_creature_bed",
		Vector3(float((bed_at as Array)[0]), resolved.y, float((bed_at as Array)[1])))
	if bed_world == Vector3.INF:
		return
	var bed := rest.get_node_or_null(^"CampCreatureBed") as Node3D
	if bed != null:
		bed.global_position = bed_world


func _sync_npcs() -> void:
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel != null and panel.call("is_open"):
		_revision = -1
		return
	var specs := RULES.npc_specs(chapter, npc_runtime, _flags, config.get("npc_position_overrides", {}))
	var positions: Dictionary = {}
	for spec: Dictionary in specs:
		var at := _resolve(spec["id"], RULES.vec(spec["position"]))
		if at == Vector3.INF:
			continue
		spec["position"] = [at.x, at.y, at.z]
		positions[spec["id"]] = spec["position"]
	if positions == _npc_positions and is_instance_valid(_people):
		return
	_npc_positions = positions
	if is_instance_valid(_people):
		remove_child(_people)
		_people.queue_free()
	_people = NPCS.new()
	_people.name = "CloudreachPeople"
	add_child(_people)
	_people.call("build_specs", _player, specs.filter(func(spec: Dictionary) -> bool: return positions.has(spec["id"])))
	if is_instance_valid(_topic_root):
		remove_child(_topic_root)
		_topic_root.queue_free()
	_topic_root = Node3D.new()
	_topic_root.name = "ConversationTopics"
	add_child(_topic_root)
	for spec: Dictionary in specs:
		if not positions.has(spec["id"]):
			continue
		for topic: Dictionary in spec.get("topic_interactions", []):
			var prompt := INTERACTABLE.new()
			prompt.name = str(topic["id"])
			_topic_root.add_child(prompt)
			prompt.global_position = RULES.vec(spec["position"]) + RULES.vec(topic.get("offset", [0, 0, 0])) + Vector3.UP * 0.8
			prompt.configure(topic["label"], 3.2, true)
			prompt.set_meta("requires_flags", topic.get("requires_flags", []))
			prompt.activated.connect(_show_topic.bind(topic))


func _show_topic(topic: Dictionary) -> void:
	if not RULES.holds(_flags, topic.get("requires_flags", [])):
		return
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel != null and not panel.call("is_open"):
		panel.call("start", topic["conversation"])


func _build_trial_markers() -> void:
	_gate_root = Node3D.new()
	_gate_root.name = "TrialWindGates"
	add_child(_gate_root)
	for spec: Dictionary in config.get("trial", {}).get("gates", []):
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = float(spec.get("radius_m", 6)) - 0.4
		mesh.outer_radius = float(spec.get("radius_m", 6))
		mesh.rings = 24
		mesh.ring_segments = 8
		ring.mesh = mesh
		ring.rotation.x = PI * 0.5
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.85, 0.68, 0.3)
		material.emission_enabled = true
		material.emission = Color(0.28, 0.18, 0.04)
		ring.material_override = material
		_gate_root.add_child(ring)
		ring.global_position = RULES.vec(spec["position"])
	_gate_root.visible = false


func _build_prop(root: Node3D, spec: Dictionary) -> void:
	var kind := str(spec.get("kind", ""))
	if kind in ["bell", "vane", "windlass", "launch"]:
		_build_authored_marker(root, kind)
		return
	var path := "res://assets/props/quaternius_fantasy/Crate_Wooden.gltf"
	if spec.get("kind", "") == "pack":
		path = "res://assets/props/quaternius_fantasy/Bag.gltf"
	if spec.get("kind", "") == "anchor":
		path = "res://assets/environment/team_tether/tether_pylon.glb"
	# Reuse installed props when present. Functional marker geometry remains
	# deliberately small; the world environment owns its architectural setting.
	var visual := Node3D.new()
	visual.name = "Presentation"
	root.add_child(visual)
	if ResourceLoader.exists(path):
		var resource: Resource = load(path)
		if resource is PackedScene:
			var prop: Node = (resource as PackedScene).instantiate()
			visual.add_child(prop)
			if kind == "anchor":
				_apply_pylon_material(prop)
			return
	var marker := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.3
	mesh.bottom_radius = 0.5
	mesh.height = 1.1
	marker.mesh = mesh
	marker.position.y = 0.55
	visual.add_child(marker)


func _apply_pylon_material(node: Node) -> void:
	if _pylon_material == null:
		_pylon_material = StandardMaterial3D.new()
		_pylon_material.albedo_texture = load("res://assets/environment/team_tether/tether_pylon_albedo.png") as Texture2D
		_pylon_material.roughness = 0.82
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = _pylon_material
	for child: Node in node.get_children():
		_apply_pylon_material(child)


func _build_authored_marker(root: Node3D, kind: String) -> void:
	var visual := Node3D.new()
	visual.name = "Presentation"
	root.add_child(visual)
	var wood := Color(0.30, 0.21, 0.13)
	var brass := Color(0.72, 0.53, 0.23)
	var stone := Color(0.52, 0.49, 0.39)
	var post := CylinderMesh.new()
	post.height = 1.7
	post.top_radius = 0.09
	post.bottom_radius = 0.13
	_piece(visual, post, Vector3(0,0.85,0), wood)
	if kind == "bell":
		var arm := BoxMesh.new()
		arm.size = Vector3(0.85,0.12,0.12)
		_piece(visual, arm, Vector3(0.3,1.65,0), wood)
		var bell := CylinderMesh.new()
		bell.height = 0.56
		bell.top_radius = 0.12
		bell.bottom_radius = 0.37
		_piece(visual, bell, Vector3(0.55,1.26,0), brass)
		var lip := TorusMesh.new()
		lip.inner_radius = 0.30
		lip.outer_radius = 0.38
		_piece(visual, lip, Vector3(0.55,0.99,0), brass)
	elif kind == "vane":
		var blade := PrismMesh.new()
		blade.size = Vector3(1.3,0.45,0.12)
		_piece(visual, blade, Vector3(0.25,1.55,0), brass)
		var base := CylinderMesh.new()
		base.height = 0.3
		base.top_radius = 0.5
		base.bottom_radius = 0.6
		_piece(visual, base, Vector3(0,0.15,0), stone)
	elif kind == "windlass":
		var wheel := TorusMesh.new()
		wheel.inner_radius = 0.5
		wheel.outer_radius = 0.62
		var ring := _piece(visual, wheel, Vector3(0,1.15,0), wood)
		ring.rotation.x = PI * 0.5
		for angle: float in [0.0, PI * 0.5]:
			var spoke := BoxMesh.new()
			spoke.size = Vector3(1.15,0.09,0.09)
			_piece(visual, spoke, Vector3(0,1.15,0), brass).rotation.z = angle
	else:
		var pennant := PrismMesh.new()
		pennant.size = Vector3(0.95,0.55,0.04)
		_piece(visual, pennant, Vector3(0.45,1.6,0), Color(0.82,0.65,0.30))


func _piece(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _resolve(id: String, at: Vector3) -> Vector3:
	var resolved: Vector3 = _ground.call(at) if _ground.is_valid() else at
	if not resolved.is_finite():
		placement_failed.emit(id, at)
		push_warning("Cloudreach physical placement needs a surface: %s %s" % [id, at])
		return Vector3.INF
	return resolved


func _message(message: String) -> void:
	if _game != null and _game.has_method("push_world_message"):
		_game.call("push_world_message", message)


static func _box(spec: Dictionary) -> AABB:
	return AABB(RULES.vec(spec["position"]), RULES.vec(spec["size"]))


static func _bounds(spec: Dictionary) -> AABB:
	return AABB(RULES.vec(spec["bounds_position"]), RULES.vec(spec["bounds_size"]))
