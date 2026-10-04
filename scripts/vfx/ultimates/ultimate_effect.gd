extends Node3D

## Rendering clock only. Host arrival survives culling, refusal and teardown.
## Implements the F25 facade's arrived/confirm/cancel lifetime contract.
const GEOMETRY := preload("res://scripts/vfx/ultimates/ultimate_geometry.gd")
const CHOREOGRAPHY := preload("res://scripts/vfx/ultimates/ultimate_choreography.gd")
const BUDGET_PATH := "res://scripts/vfx/move_effect_budget.gd"
const ARCHETYPES_PATH := "res://scripts/vfx/move_effect_library.gd"
const AUDIO_PATH := "res://scripts/audio/audio_manager.gd"
signal arrived()
signal presentation_arrived(receipt: Dictionary)

static var _active: Dictionary = {}
var _from: Vector3
var _to: Vector3
var _row: Dictionary
var _context: Dictionary
var _config: Dictionary
var _parts: Array[Dictionary] = []
var _nodes: Array[MeshInstance3D] = []
var _elapsed := 0.0
var _arrival := 0.0
var _duration := 0.0
var _did_arrive := false
var _did_notify := false
var _cancelled := false
var _clock: SceneTreeTimer
var _budget: Script
var _lease := 0
var _mesh_count := 0
var _motes: MultiMeshInstance3D
var _mote_count := 0

func configure(from: Vector3, to: Vector3, row: Dictionary, context: Dictionary, data: Dictionary) -> void:
	_from = from
	_to = to
	_row = row.duplicate(true)
	_context = context
	_config = data.duplicate(true)
	_arrival = float(context.travel_seconds)
	_duration = float(context.duration_seconds)

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	add_to_group("move_effect_presentation")
	add_to_group("ultimate_presentation")
	var limits: Dictionary = _config.get("budget", {})
	var scope := encounter_id()
	var used := int(_active.get(scope, 0))
	var room := maxi(0, int(limits.get("encounter_mesh_cap", 192)) - used)
	var scene_used := 0
	for value: int in _active.values(): scene_used += value
	room = mini(room, maxi(0, int(limits.get("scene_mesh_cap", 256)) - scene_used))
	# Reserve one mesh-instance slot for the shared decorative MultiMesh.
	var cap := mini(room, int(limits.get("effect_mesh_cap", 48))) - 1
	if cap < int(limits.get("minimum_body_parts", 6)):
		cancel_presentation()
		return
	var context: Dictionary = _context.duplicate(true)
	context["component_cap"] = cap
	_parts = CHOREOGRAPHY.compose(_row, _row.growth, context)
	if _parts.size() > cap: _parts.resize(cap)
	_mesh_count = _parts.size() + 1
	_active[scope] = used + _mesh_count
	var palette: Dictionary = _row.get("palette", {})
	var colour := Color(str(palette.get("body", "#d9b26a")))
	var peer := bool(_context.peer_view)
	var opacity := float((_config.get("peer", {}) as Dictionary).get("opacity", 0.48)) if peer else 1.0
	var mesh_cache: Dictionary = {}
	for part: Dictionary in _parts:
		var node := MeshInstance3D.new()
		var key := str(part.shape) + JSON.stringify(part.get("params", {}))
		if not mesh_cache.has(key):
			mesh_cache[key] = GEOMETRY.shape(str(part.shape), 1.0, part.get("params", {}))
		node.mesh = mesh_cache[key]
		if node.mesh == null or bool(node.mesh.get_meta("ultimate_budget_clipped", false)):
			node.free()
			cancel_presentation()
			return
		var tint := Color(str(palette.get("accent", "#fff0c9"))) if str(part.phase) == "aftermath" else colour
		node.material_override = GEOMETRY.material(tint, opacity, true)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		_nodes.append(node)
	if ResourceLoader.exists(BUDGET_PATH):
		_budget = load(BUDGET_PATH)
		_lease = int(_budget.call("reserve", scope, int(limits.get("impact_motes", 32)),
			int(limits.get("trail_motes", 16)), int(limits.get("encounter_particle_cap", 384))))
		_build_motes(colour, opacity)
	_update_parts()
	_play_launch_cue()
	if _arrival == 0.0:
		# Host-contact actions already arrived. Build contact at birth, but let
		# the caller attach its observer after launch returns before notifying.
		_finish_presentation()
		return
	# The same idle timer class used by F25. A separate host timer/accepted
	# receipt owns damage. Tree pause freezes presentation; hitstop does not.
	_clock = get_tree().create_timer(_arrival, false)
	_clock.timeout.connect(_finish_presentation, CONNECT_ONE_SHOT)

func _play_launch_cue() -> void:
	# Reuse F25's actual installed cue contract. Contact audio is owned by the
	# accepted host receipt; this function cannot play a second impact cue.
	if not ResourceLoader.exists(ARCHETYPES_PATH) or not ResourceLoader.exists(AUDIO_PATH): return
	var library: Script = load(ARCHETYPES_PATH)
	var audio: Script = load(AUDIO_PATH)
	var shared: Dictionary = library.call("config")
	var rows: Dictionary = shared.get("archetypes", {})
	var archetype: Dictionary = rows.get(str(_row.get("sound_archetype", "")), {})
	var sound: Dictionary = archetype.get("sound", {})
	var cue_id := str(sound.get("launch_mastery" if int(_context.mastery_rank) >= 5 else "launch", ""))
	var cues: Dictionary = audio.call("section", "move_effect_cues")
	var cue := str(cues.get(cue_id, ""))
	if cue.is_empty(): return
	var gain := float(sound.get("gain_db", -7.0))
	if bool(_context.peer_view): gain += float((_config.get("peer", {}) as Dictionary).get("launch_gain_db", -6.0))
	audio.call("play_file_at", cue, "ultimate:" + action_id(), _from, "SFX", gain)

func _build_motes(colour: Color, opacity: float) -> void:
	var allocation: Dictionary = _budget.call("allocation", _lease)
	_mote_count = int(allocation.get("impact", 0)) + int(allocation.get("trail", 0))
	if _mote_count <= 0: return
	_motes = MultiMeshInstance3D.new()
	var mesh := MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.mesh = GEOMETRY.shape(str(_row.get("mote_shape", "gale_feather")),
		float((_config.get("budget", {}) as Dictionary).get("mote_size_m", 0.08)), _config.get("mote_geometry", {}))
	if mesh.mesh == null or bool(mesh.mesh.get_meta("ultimate_budget_clipped", false)):
		_motes.free()
		_motes = null
		return
	mesh.instance_count = _mote_count
	_motes.multimesh = mesh
	_motes.material_override = GEOMETRY.material(colour, opacity, false)
	_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_motes.visible = false
	add_child(_motes)

func _process(delta: float) -> void:
	if _cancelled: return
	if not _did_arrive and _clock != null:
		_elapsed = maxf(0.0, _arrival - _clock.time_left)
	else: _elapsed += delta
	_update_parts()
	_update_motes()
	if _elapsed >= _duration: cancel_presentation()

func _update_parts() -> void:
	var peer: Dictionary = _config.get("peer", {})
	var end := _duration
	if bool(_context.peer_view): end = minf(end, _arrival + float(peer.get("aftermath_seconds", 0.65)))
	var visible_now := _elapsed <= end
	var visual_arrival := maxf(_arrival, 0.001)
	var visual_elapsed := maxf(_elapsed, visual_arrival) if _did_arrive else _elapsed
	for i in _nodes.size():
		var motion := str(_parts[i].get("motion", ""))
		var ground := motion in ["jaw_charge", "jaw_clamp", "ground_skip", "settle", "antler_bud", "antler_rise", "root_canopy", "root_curl", "root_rush", "root_sink", "grove_fold", "forge_compress", "forge_open", "paw_plant", "paw_stamp", "sky_ground", "ground_drain", "shelter", "shelter_gather"]
		var from: Vector3 = _context.source_ground if ground else _from
		var to: Vector3 = _context.target_ground if ground else _to
		var pose: Transform3D = CHOREOGRAPHY.pose(_parts[i], visual_elapsed, visual_arrival, _duration,
			from, to, int(_context.seed))
		_nodes[i].transform = _clear_side_lane(pose, _nodes[i].mesh.get_aabb(), _parts[i], from, to)
		_nodes[i].visible = visible_now and _nodes[i].basis.determinant() > 0.0000001

func _clear_side_lane(pose: Transform3D, bounds: AABB, part: Dictionary,
		from: Vector3, to: Vector3) -> Transform3D:
	# Center offsets alone cannot guarantee clearance once tier/mastery scale
	# and object rotation are applied. Project all eight actual mesh corners
	# onto the authored lateral axis and keep side objects outside the gap.
	# This moves disposable drawing only; no strike or collision shape changes.
	var offset: Array = part.get("offset", [])
	if offset.is_empty() or float(offset[0]) <= 0.0: return pose
	var forward := Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
	if forward.length_squared() < 0.001: forward = Vector3.FORWARD
	var right := forward.cross(Vector3.UP).normalized()
	var smallest := INF
	var largest := -INF
	for x in 2:
		for y in 2:
			for z in 2:
				var corner := bounds.position + Vector3(bounds.size.x * x, bounds.size.y * y, bounds.size.z * z)
				var lateral := (pose * corner - from).dot(right)
				smallest = minf(smallest, lateral)
				largest = maxf(largest, lateral)
	var gap := float((part.get("params", {}) as Dictionary).get("head_gap_m", 1.5))
	var left := int(part.get("index", 0)) % 2 == 0
	var shift := minf(0.0, -gap - largest) if left else maxf(0.0, gap - smallest)
	pose.origin += right * shift
	return pose

func _update_motes() -> void:
	if _motes == null: return
	var allocation: Dictionary = _budget.call("allocation", _lease)
	var visible_count := mini(_mote_count, int(allocation.get("impact", 0)) + int(allocation.get("trail", 0)))
	_motes.multimesh.visible_instance_count = visible_count
	var age := _elapsed - _arrival
	var profile: Dictionary = _config.get("motes", {})
	var lifetime := float(profile.get("lifetime_seconds", 0.5))
	_motes.visible = _did_arrive and age >= 0.0 and age < lifetime
	if not _motes.visible: return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_context.seed)
	for i in visible_count:
		var direction := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(0.2, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		var position := _to + direction * age * float(profile.get("speed_mps", 3.2))
		position.y -= age * age * float(profile.get("fall_mps2", 2.0))
		var scale := maxf(0.01, 1.0 - age / lifetime)
		_motes.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale), position))

func _finish_presentation() -> void:
	if _did_arrive or _cancelled or is_queued_for_deletion(): return
	_did_arrive = true
	_elapsed = _arrival
	_update_parts()
	if _arrival == 0.0:
		call_deferred("_notify_arrival")
	else: _notify_arrival()

func _notify_arrival() -> void:
	if _did_notify or _cancelled or is_queued_for_deletion(): return
	_did_notify = true
	arrived.emit()
	presentation_arrived.emit(_context)

func confirm_presentation_impact() -> void:
	_finish_presentation()

func reconcile_actor(current: Dictionary) -> void:
	# Called from the existing registry/body lifecycle owner, never a peer card.
	if current.get("character_id") != _context.actor_binding.get("character_id") \
			or current.get("encounter_id") != _context.actor_binding.get("encounter_id"): return
	if bool(current.get("fainted", false)):
		cancel_presentation()
		return
	# A newer accepted action on the same body must not erase an earlier
	# airborne visual. Explicit action refusal uses cancel_action separately.
	for key: String in ["character_id", "creature_uid", "encounter_id", "generation"]:
		if current.get(key) != _context.actor_binding.get(key):
			cancel_presentation()
			return

func cancel_presentation() -> void:
	if _cancelled: return
	_cancelled = true
	set_process(false)
	visible = false
	queue_free()

func action_id() -> String:
	return str(_context.get("action_id", ""))

func encounter_id() -> String:
	return str(_context.get("encounter_id", ""))

func actor_binding() -> Dictionary:
	# Facade first scopes reconciliation to the same character and encounter;
	# other participants' effects must never be reconciled against this actor.
	return (_context.get("actor_binding", {}) as Dictionary).duplicate(true)

func _exit_tree() -> void:
	var scope := encounter_id()
	_active[scope] = maxi(0, int(_active.get(scope, 0)) - _mesh_count)
	if int(_active[scope]) == 0: _active.erase(scope)
	if _budget != null and _lease != 0: _budget.call("release", _lease)
