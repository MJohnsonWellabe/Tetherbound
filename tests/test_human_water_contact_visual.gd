extends "res://tests/test_case.gd"

## Ownership/lifecycle tests, not rendered acceptance of water blending.
const VIEW := preload("res://scripts/player/human_water_contact_view.gd")
const SWIM := preload("res://scripts/player/swim_state.gd")

class LocalSwim:
	extends Node
	var state := SWIM.new()
	func snapshot() -> Dictionary:
		return state.snapshot()

class RemoteBody:
	extends CharacterBody3D
	var aquatic := SWIM.new()
	func animation_state() -> String:
		return "jump"


func _view() -> VIEW:
	var view := VIEW.new()
	view.settings = VIEW.load_settings()
	view.settings.enabled = true
	return view


func _human() -> Dictionary:
	var state := SWIM.new()
	state.enter_water(false, 2.5)
	return state.snapshot()


func test_shipped_on_attaches_and_gate_off_generates_nothing() -> void:
	# F39 P2-072: shipped on. A null body still attaches nothing; a view whose
	# settings are switched off generates nothing.
	assert_true(bool(VIEW.load_settings().get("enabled", false)))
	var model := Node3D.new()
	var body := CharacterBody3D.new()
	assert_eq(VIEW.attach(model, null), null)
	assert_eq(model.get_child_count(), 0)
	var attached := VIEW.attach(model, body)
	assert_true(attached != null)
	assert_eq(model.get_child_count(), 1)
	var view := _view()
	view.settings.enabled = false
	view.step_visual(0.2, _human(), Vector3.ZERO)
	assert_eq(view.get_child_count(), 0)
	view.free()
	model.free()
	body.free()


func test_existing_local_and_remote_snapshots_match_without_writes() -> void:
	var local := CharacterBody3D.new()
	var swim := LocalSwim.new()
	swim.name = "SwimController"
	local.add_child(swim)
	swim.state.enter_water(false, 2.5)
	local.velocity = Vector3(2.0, 0.0, 1.0)
	local.position = Vector3(4.0, 2.1, 6.0)
	var remote := RemoteBody.new()
	remote.aquatic.enter_water(false, 2.5)
	remote.position = local.position
	var before := swim.state.snapshot()
	var transform_before := local.transform
	var velocity_before := local.velocity
	assert_eq(VIEW.snapshot(local), VIEW.snapshot(remote))
	var local_view := _view()
	var remote_view := _view()
	local_view.step_visual(0.2, VIEW.snapshot(local), local.position)
	remote_view.step_visual(0.2, VIEW.snapshot(remote), remote.position)
	assert_true(local_view._contact.transform.is_equal_approx(remote_view._contact.transform))
	assert_almost_eq(local_view._contact.position.y, 2.545)
	assert_eq(local_view._contact.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_eq((local_view._contact.material_override as ShaderMaterial).render_priority, 2)
	assert_eq(swim.state.snapshot(), before)
	assert_eq(remote.aquatic.snapshot(), before)
	assert_true(local.transform.is_equal_approx(transform_before))
	assert_eq(local.velocity, velocity_before)
	local_view.free()
	remote_view.free()
	local.free()
	remote.free()


func test_pause_freezes_position_phase_and_emission_then_resumes() -> void:
	var view := _view()
	var packet := _human()
	view.step_visual(0.2, packet, Vector3.ZERO)
	view.step_visual(0.2, packet, Vector3(0.5, 0.0, 0.0))
	assert_eq(view._trail.size(), 1)
	var phase: float = view._phase
	var contact_position: Vector3 = view._contact.position
	packet.mode = SWIM.Mode.COMBAT_PAUSED
	packet.resume_mode = SWIM.Mode.HUMAN
	var before := packet.duplicate(true)
	view.step_visual(0.4, packet, Vector3(1.0, 0.0, 0.0))
	assert_almost_eq(view._phase, phase)
	assert_eq(view._contact.position, contact_position)
	assert_eq(view._trail.size(), 1)
	assert_almost_eq(view._fade, 0.0)
	assert_eq(packet, before)
	packet.mode = SWIM.Mode.HUMAN
	view.step_visual(0.2, packet, Vector3(1.1, 0.0, 0.0))
	assert_true(view._phase > phase)
	assert_true(view._fade > 0.0)
	assert_almost_eq(view._contact.position.x, 1.1)
	view.free()


func test_nonhuman_and_paused_late_spawn_generate_nothing() -> void:
	var view := _view()
	var packet := _human()
	for mode in [SWIM.Mode.LAND, SWIM.Mode.MOUNTED, SWIM.Mode.COMBAT_PAUSED]:
		packet.mode = mode
		packet.resume_mode = SWIM.Mode.MOUNTED
		view.step_visual(0.2, packet, Vector3.ZERO)
		assert_eq(view.get_child_count(), 0)
	packet.resume_mode = SWIM.Mode.HUMAN
	view.step_visual(0.2, packet, Vector3.ZERO)
	assert_eq(view.get_child_count(), 0)
	view.free()


func test_trail_is_bounded_expires_and_clears_on_land_and_disable() -> void:
	var view := _view()
	var packet := _human()
	view.settings.max_trail_rings = 2
	view.step_visual(0.2, packet, Vector3.ZERO)
	for index in 8:
		view.step_visual(0.2, packet, Vector3(float(index + 1) * 0.5, 0.0, 0.0))
		assert_true(view._trail.size() <= 2)
	assert_eq(view._trail.size(), 2)
	# Idle does not repeatedly stamp foam. Existing footprints finish fading.
	view.step_visual(2.0, packet, Vector3(4.0, 0.0, 0.0))
	assert_eq(view._trail.size(), 0)
	packet.mode = SWIM.Mode.LAND
	view.step_visual(0.1, packet, Vector3(4.0, 0.0, 0.0))
	assert_eq(view.get_child_count(), 0)
	assert_eq(view._contact, null)
	packet.mode = SWIM.Mode.HUMAN
	view.step_visual(0.1, packet, Vector3.ZERO)
	assert_eq(view.get_child_count(), 1)
	view.settings.enabled = false
	view.step_visual(0.1, packet, Vector3.ZERO)
	assert_eq(view.get_child_count(), 0)
	view.free()


func test_teleport_clears_old_trail_and_invalid_surface_clears_all() -> void:
	var view := _view()
	var packet := _human()
	view.step_visual(0.2, packet, Vector3.ZERO)
	view.step_visual(0.2, packet, Vector3(0.5, 0.0, 0.0))
	assert_eq(view._trail.size(), 1)
	view.step_visual(0.2, packet, Vector3(30.0, 0.0, 0.0))
	assert_eq(view._trail.size(), 0)
	packet.surface_y = NAN
	view.step_visual(0.2, packet, Vector3.ZERO)
	assert_eq(view.get_child_count(), 0)
	view.free()


func test_owner_teardown_frees_contact_and_trail_children() -> void:
	var owner := Node3D.new()
	var view := _view()
	owner.add_child(view)
	view.step_visual(0.2, _human(), Vector3.ZERO)
	view.step_visual(0.2, _human(), Vector3(0.5, 0.0, 0.0))
	var contact: MeshInstance3D = view._contact
	var trail_ring: MeshInstance3D = view._trail[0].node
	owner.free()
	assert_false(is_instance_valid(view))
	assert_false(is_instance_valid(contact))
	assert_false(is_instance_valid(trail_ring))
