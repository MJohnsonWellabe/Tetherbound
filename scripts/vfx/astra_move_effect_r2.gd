extends "res://scripts/vfx/astra_move_effect.gd"

## Sibling candidate for the three held examples only. The accepted slash
## remains on r1. The r2 finish guard handles source loss during body updates;
## host timing, audio ownership and lease accounting retain the base contract.
const ROUND_R2 := preload("res://scripts/vfx/astra_geometry_r2.gd")
const TORSO_R2 := preload("res://scripts/vfx/astra_torso_bounds_r2.gd")
const ENERGY_R2 := preload("res://scripts/vfx/astra_energy_r2.gdshader")
var _anatomy := TORSO_R2.new()
var _halos: Array[MeshInstance3D] = []
var _cancelled := false
var _arrival_emitted := false
var _presentation_arrival_emitted := false

func bind_source(source: Node3D) -> bool:
	if not super.bind_source(source): return false
	var pivot := _source_pivot.get_ref() as Node3D
	if not _anatomy.bind(pivot, tuning.get("torso_bones", ["pelvis", "spine", "neck"]),
			float(tuning.get("torso_weight_threshold", 0.65))): return false
	_source_bounds = _anatomy.measure()
	return true

func _ready() -> void:
	super._ready()
	if _cancelled or is_queued_for_deletion(): return
	for body: MeshInstance3D in _bodies:
		if _kind == "bubble_volley":
			(body.material_override as ShaderMaterial).set_shader_parameter("opacity",
				float(tuning.get("bubble_opacity", 1.65)) * _peer_opacity)
		else:
			body.material_override = _energy(1.0)
			var halo := MeshInstance3D.new()
			halo.mesh = body.mesh
			halo.material_override = _energy(float(tuning.get("halo_opacity", 0.24)), true,
				_tube_radius() * float(tuning.get("halo_width_scale", 0.85)))
			halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			halo.extra_cull_margin = _tube_radius() * float(tuning.get("halo_width_scale", 0.85))
			body.add_child(halo)
			_halos.append(halo)
	for wake: MeshInstance3D in _wake:
		wake.material_override = _presentation_material(VOLUME.surface(_colour.lerp(Color("75ddff"), 0.45), 0.9))

func _energy(alpha: float, halo: bool = false, width: float = 0.0) -> Material:
	var material := ShaderMaterial.new()
	material.shader = ENERGY_R2
	var key := "aura_colour" if _kind == "buff_aura" else "beam_colour"
	material.set_shader_parameter("energy_colour", _colour.lerp(Color(str(tuning.get(key, "36bfff"))),
		clampf(float(tuning.get("energy_colour_mix", 0.85)), 0.0, 1.0)))
	material.set_shader_parameter("opacity", alpha)
	material.set_shader_parameter("halo", halo)
	material.set_shader_parameter("shell_width", width)
	return _presentation_material(material)

func _tube_radius() -> float:
	var key := "aura_tube_radius_scale" if _kind == "buff_aura" else "beam_radius_scale"
	return float(_params.size) * float(tuning.get(key, 0.22 if _kind == "buff_aura" else 0.9))

func _process(delta: float) -> void:
	super._process(delta)
	if is_queued_for_deletion(): return
	# r1 retains converging wakes after arrival. r2 bubbles stop their wakes at
	# contact; the beam retains its full volume instead of leaving a thin wake.
	if _kind != "bubble_volley" or _arrived:
		for wake: MeshInstance3D in _wake: wake.visible = false
	if _kind in ["catch_tether_beam", "buff_aura"]:
		var fade := 1.0 if not _arrived else 1.0 - clampf((_elapsed - _travel) / maxf(_lifetime_after_contact(), 0.001), 0.0, 1.0)
		for body: MeshInstance3D in _bodies:
			body.visible = not _contact_retired and fade > 0.0
			_set_opacity(body.material_override, fade)
		for halo: MeshInstance3D in _halos:
			_set_opacity(halo.material_override, float(tuning.get("halo_opacity", 0.24)) * fade)

func _update_bodies(t: float) -> void:
	if _kind == "bubble_volley":
		super._update_bodies(t)
		return
	var pivot: Node3D
	if _kind == "buff_aura":
		pivot = _source_pivot.get_ref() as Node3D if _source_pivot != null else null
		if not is_instance_valid(pivot):
			cancel_presentation(); return
		_source_bounds = _anatomy.measure()
		if _source_bounds.size.is_zero_approx():
			cancel_presentation(); return
	var steps := clampi(int(tuning.get("body_steps", 64)), 32, 80)
	var sides := clampi(int(tuning.get("tube_sides", 12)), 8, 12)
	for i in _bodies.size():
		var body := _bodies[i]
		var points: Array[Vector3] = []
		if _kind == "catch_tether_beam":
			for k in steps + 1: points.append(_from.lerp(_path(t, i), float(k) / float(steps)))
		elif _kind == "buff_aura":
			var centre := _source_bounds.get_center()
			var half := _source_bounds.size * 0.5 * float(tuning.get("aura_padding", 1.16))
			for k in steps + 1:
				var f := float(k) / float(steps)
				var angle := f * TAU * float(tuning.get("aura_turns", 1.75)) + _elapsed * 2.2 + float(i) * PI
				points.append(pivot.to_global(centre + Vector3(cos(angle) * half.x,
					lerpf(-0.85, 0.85, f) * half.y, sin(angle) * half.z)))
		body.transform = Transform3D.IDENTITY
		body.mesh = ROUND_R2.tube(points, _tube_radius(), sides)
		if i < _halos.size(): _halos[i].mesh = body.mesh

func _update_trail() -> void:
	var granted := int(BUDGET.allocation(_lease).get("trail", 0))
	var samples := mini(32, floori(float(granted) / float(maxi(1, _wake.size()))))
	var progress := 1.0 if _travel <= 0.0 else clampf(_elapsed / _travel, 0.0, 1.0)
	var span := float(_params.trail) * 2.4 / maxf(_from.distance_to(_to), 0.001)
	for i in _wake.size():
		var wake := _wake[i]
		wake.visible = _kind == "bubble_volley" and not _arrived and not _contact_retired and samples >= 2 and progress > 0.0
		if not wake.visible: continue
		var points: Array[Vector3] = []
		for k in samples:
			var f := float(k) / float(samples - 1)
			points.append(_path(lerpf(maxf(0.0, progress - span), progress, f), i))
		wake.mesh = ROUND_R2.tube(points, float(_params.size) * float(tuning.get("bubble_trail_radius_scale", 0.36))
			* sqrt(float(_params.trail)), 8, true)

func _build_impact() -> void:
	if _cancelled or _contact_retired or is_queued_for_deletion(): return
	super._build_impact()
	for wake: MeshInstance3D in _wake: wake.visible = false
	if _kind in ["catch_tether_beam", "buff_aura"]:
		_contact_core.material_override = _energy(0.95)
		_lobes.material_override = _energy(0.9)

func _update_impact(u: float, delta: float) -> void:
	if _cancelled or _contact_retired or is_queued_for_deletion(): return
	super._update_impact(u, delta)
	if _contact_core == null: return
	if _kind == "bubble_volley":
		var count := _lobes.multimesh.visible_instance_count
		var spread := float(tuning.get("bubble_spray_radius_scale", 1.55))
		for i in count:
			var pose := _lobes.multimesh.get_instance_transform(i)
			pose.origin *= spread
			_lobes.multimesh.set_instance_transform(i, pose)
	elif _kind == "buff_aura":
		# A bounded soft bead ring brightens the same torso envelope. Never use
		# the whole tail-inclusive box for either coils or the contact particles.
		for i in _lobes.multimesh.visible_instance_count:
			var pose := _lobes.multimesh.get_instance_transform(i)
			pose.basis = pose.basis.scaled(Vector3.ONE * 0.55)
			_lobes.multimesh.set_instance_transform(i, pose)

## Keep the base ordering, with a cancellation barrier after virtual updates.
## Source loss inside _update_bodies must not fall through to contact/signals.
func _finish_presentation() -> void:
	if _cancelled or _arrived or is_queued_for_deletion(): return
	_elapsed = _travel
	_update_bodies(1.0)
	if _cancelled or is_queued_for_deletion(): return
	_arrived = true
	if _impact == null: _build_impact()
	if _cancelled or is_queued_for_deletion(): return
	_update_signature_shapes()
	_play_impact()
	_arrival_emitted = true
	arrived.emit()
	if _cancelled or is_queued_for_deletion(): return
	_presentation_arrival_emitted = true
	presentation_arrived.emit(_context)

func cancel_presentation() -> void:
	if _cancelled: return
	_cancelled = true
	# Retire synchronously even when cancellation happens during finish. The
	# base's deferred _exit_tree release remains safe because release is idempotent.
	_retire_contact_drawing()
	if is_instance_valid(_impact): _impact.free()
	_impact = null
	_contact_core = null
	_lobes = null
	_directions.clear()
	super.cancel_presentation()

func diagnostic_receipt() -> Dictionary:
	var result := {"candidate": "astra_r2", "archetype": _kind,
		"arrived": _arrived, "contact_retired": _contact_retired,
		"cancelled": _cancelled, "arrival_emitted": _arrival_emitted,
		"presentation_arrival_emitted": _presentation_arrival_emitted,
		"impact_present": is_instance_valid(_impact),
		"elapsed": _elapsed, "travel_seconds": _travel, "lease": BUDGET.allocation(_lease),
		"body_visible": [], "wake_visible": [], "tube_radius_world": _tube_radius()}
	for body: MeshInstance3D in _bodies: result.body_visible.append(body.visible)
	for wake: MeshInstance3D in _wake: result.wake_visible.append(wake.visible)
	if _kind == "buff_aura": result["anatomy"] = _anatomy.receipt()
	return result
