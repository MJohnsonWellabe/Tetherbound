extends Node3D

## A short, local picture of an observed touchdown. No collision, replication,
## party membership or movement ownership; both trainer presentations use it.
var finished := false
var _visual: Node3D
var _from := Transform3D.IDENTITY
var _to := Transform3D.IDENTITY
var _seconds := 0.0
var _duration := 0.85
var _settle_fraction := 0.7
var _rig: Skeleton3D
var _feet: Array[int] = []
var _ground := Vector3.ZERO


static func begin(actor: CharacterBody3D, visual: Node3D, capability: Dictionary,
		settings: Dictionary, ground_origin := Vector3.INF) -> Node3D:
	if not is_instance_valid(actor) or not is_instance_valid(visual) or not actor.is_inside_tree():
		return null
	var right := visual.global_basis.x
	right.y = 0.0
	right = right.normalized() if right.length_squared() > 0.001 else Vector3.RIGHT
	var origin := ground_origin if ground_origin.is_finite() else actor.global_position
	# Match the ordinary follower's existing summon spot, so the handoff does
	# not jump from a perch on one side to a new body on the other.
	var side := origin + actor.global_basis.x * float(settings.get("side_m", 1.2)) \
		- actor.global_basis.z * float(settings.get("forward_m", 2.4))
	var rise := float(settings.get("probe_up_m", 0.6))
	var drop := float(settings.get("probe_down_m", 1.0))
	var query := PhysicsRayQueryParameters3D.create(side + Vector3.UP * rise,
		side + Vector3.DOWN * drop, actor.collision_mask, [actor.get_rid()])
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.get("collider") is CharacterBody3D \
			or (hit["normal"] as Vector3).y < cos(actor.floor_max_angle):
		return null
	var landing := new()
	actor.add_child(landing)
	landing.top_level = true
	landing.global_transform = Transform3D.IDENTITY
	landing._visual = visual
	landing._from = visual.global_transform
	visual.reparent(landing, true)
	landing._duration = clampf(float(settings.get("duration_s", 0.85)), 0.1, 1.5)
	landing._settle_fraction = clampf(float(settings.get("settle_fraction", 0.7)), 0.2, 1.0)
	# Stop sampling the grip. Resume the installed idle (folded/resting wings),
	# keeping the same mesh rather than spawning a second creature.
	for skeleton: Skeleton3D in visual.find_children("*", "Skeleton3D", true, false):
		skeleton.clear_bones_global_pose_override()
	for animation: AnimationPlayer in visual.find_children("*", "AnimationPlayer", true, false):
		var clip := str(capability.get("landing_animation", capability.get("animation", "idle")))
		if animation.has_animation(clip):
			animation.play(clip, float(settings.get("fold_blend_s", 0.18)))
			animation.advance(0.0)
		else:
			animation.stop()
	# The grip clip may pitch the presentation root. Settle toward an upright
	# root while the native resting clip controls its bones.
	var yaw := atan2(-right.z, right.x)
	visual.global_basis = Basis(Vector3.UP, yaw)
	var feet := Vector3.ZERO
	var count := 0
	var rigs := visual.find_children("*", "Skeleton3D", true, false)
	if not rigs.is_empty():
		var rig := rigs[0] as Skeleton3D
		landing._rig = rig
		for bone_name: String in capability.get("grip_bones", []):
			var bone := rig.find_bone(bone_name)
			if bone >= 0:
				landing._feet.append(bone)
				feet += rig.to_global(rig.get_bone_global_pose(bone).origin)
				count += 1
	if count == 0:
		# No authored feet: avoid claiming a grounded pose for unknown anatomy.
		visual.reparent(actor, true)
		visual.global_transform = landing._from
		landing.queue_free()
		return null
	feet /= float(count)
	landing._to = visual.global_transform
	landing._ground = (hit["position"] as Vector3) + Vector3.UP * float(settings.get("foot_clearance_m", 0.08))
	landing._to.origin += landing._ground - feet
	visual.global_transform = landing._from
	return landing


func _process(delta: float) -> void:
	if not is_instance_valid(_visual):
		finished = true
		set_process(false)
		return
	_seconds += delta
	var phase := clampf(_seconds / (_duration * _settle_fraction), 0.0, 1.0)
	var eased := phase * phase * (3.0 - 2.0 * phase)
	_visual.global_transform = _from.interpolate_with(_to, eased)
	# The native resting clip continues folding the legs. Seat its current
	# foot joints, not the transient grip pose sampled when touchdown began.
	if is_instance_valid(_rig) and not _feet.is_empty():
		var feet := Vector3.ZERO
		for bone: int in _feet:
			feet += _rig.to_global(_rig.get_bone_global_pose(bone).origin)
		feet /= float(_feet.size())
		var seated_origin := _ground - (feet - _visual.global_position)
		_visual.global_position = _from.origin.lerp(seated_origin, eased)
	if _seconds >= _duration:
		finished = true
		_visual.hide()
		set_process(false)


func cancel() -> void:
	if is_instance_valid(_visual):
		_visual.hide()
	queue_free()
