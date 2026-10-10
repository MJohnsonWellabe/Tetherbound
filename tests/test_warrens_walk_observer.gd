extends "res://tests/test_case.gd"

## Buffer/identity/source-refusal component controls, never public geometry PASS.
## No replacement /root/Game, input press, steering or body step is performed.
const OBSERVER := preload("res://tests/helpers/warrens_walk_observer.gd")


func _note(phase: String, frame: int, generation: int = 0) -> Dictionary:
	return {"phase": phase, "physics_frame": frame, "process_frame": 7,
		"delta": 1.0 / 60.0, "ground_generation": generation,
		"position_world": [1.0, 2.0, 3.0], "input": {"vector": [0.0, -1.0]}}


func test_only_complete_same_frame_ordered_pairs_enter_bounded_ring() -> void:
	var buffer := OBSERVER.PairBuffer.new()
	assert_false(buffer.accept("post", _note("post", 0, 1)), "no missing-pre reconstruction")
	assert_true(buffer.accept("pre", _note("pre", 1, 0)))
	assert_false(buffer.accept("post", _note("post", 2, 1)), "foreign frame cannot complete original pre")
	assert_true(buffer.pairs.is_empty())
	assert_true(buffer.accept("post", _note("post", 1, 1)))
	assert_true(buffer.pairs[0].ordinary_ground_step)
	assert_false(buffer.accept("post", _note("post", 1, 1)), "duplicate post refused")
	assert_false(buffer.accept("pre", _note("pre", 1, 1)), "replay refused")
	for frame: int in range(2, 82):
		assert_true(buffer.accept("pre", _note("pre", frame, frame)))
		assert_true(buffer.accept("post", _note("post", frame, frame + 1)))
	assert_eq(buffer.completed, 81)
	assert_eq(buffer.pairs.size(), 64)
	assert_eq(buffer.pairs[0].frame, 18)
	assert_eq(buffer.pairs[-1].frame, 81)
	assert_true(buffer.pending.is_empty())


func test_missing_posts_are_counted_and_never_synthesized_or_cross_frame_joined() -> void:
	var buffer := OBSERVER.PairBuffer.new()
	assert_true(buffer.accept("pre", _note("pre", 3, 5)))
	assert_true(buffer.accept("pre", _note("pre", 4, 5)))
	assert_eq(buffer.dropped, 1)
	assert_false(buffer.accept("post", _note("post", 3, 6)))
	assert_true(buffer.pairs.is_empty())
	assert_true(buffer.accept("post", _note("post", 4, 5)))
	assert_false(buffer.pairs[0].ordinary_ground_step, "short-circuit physics remains an observation, not invented ground progress")
	assert_true(buffer.accept("pre", _note("pre", 5, 5)))
	buffer.seal()
	assert_eq(buffer.dropped, 2)
	assert_true(buffer.pending.is_empty())
	assert_eq(buffer.pairs.size(), 1)


func test_malformed_counter_phase_delta_and_missing_fields_refuse_without_pair_credit() -> void:
	for field: String in ["physics_frame", "process_frame", "ground_generation"]:
		for invalid: Variant in [true, "1", 1.0, 1.5, -1, null]:
			var buffer := OBSERVER.PairBuffer.new()
			var note := _note("pre", 1)
			note[field] = invalid
			assert_false(buffer.accept("pre", note), field)
			assert_true(buffer.pending.is_empty())
	for invalid: Variant in [true, "0.016", 0, -1.0, NAN, INF, null]:
		var buffer := OBSERVER.PairBuffer.new()
		var note := _note("pre", 1)
		note.delta = invalid
		assert_false(buffer.accept("pre", note))
	for field: String in ["phase", "physics_frame", "process_frame", "ground_generation", "delta"]:
		var buffer := OBSERVER.PairBuffer.new()
		var note := _note("pre", 1)
		note.erase(field)
		assert_false(buffer.accept("pre", note), "missing " + field)
	var buffer := OBSERVER.PairBuffer.new()
	assert_false(buffer.accept("post", _note("pre", 1)))
	assert_false(buffer.accept("foreign", _note("pre", 1)))
	assert_true(buffer.accept("pre", _note("pre", 1)))
	var post := _note("post", 1)
	post.delta = 1.0 / 30.0
	assert_false(buffer.accept("post", post), "same frame with conflicting actual delta refuses")
	assert_true(buffer.pairs.is_empty())


func test_report_and_original_samples_are_deep_immutable_copies_without_acceptance_credit() -> void:
	var observer := OBSERVER.new()
	var pre := _note("pre", 8, 0)
	var post := _note("post", 8, 1)
	assert_true(observer._buffer.accept("pre", pre))
	pre.input.vector[0] = 9.0
	assert_true(observer._buffer.accept("post", post))
	post.position_world[0] = 9.0
	var report := observer.report()
	assert_true(report.read_only)
	assert_false(report.acceptance_credit)
	assert_false(report.cause_proven)
	assert_false(report.begun, "pure buffer control cannot mint authentic public begin")
	assert_eq(report.pairs[0].pre.input.vector[0], 0.0)
	assert_eq(report.pairs[0].post.position_world[0], 1.0)
	report.pairs[0].pre.input.vector[1] = 0.0
	report.scope.forged = true
	assert_eq(observer.report().pairs[0].pre.input.vector[1], -1.0)
	assert_true(observer.report().scope.is_empty())
	observer.close()
	observer.close()
	assert_true(observer.report().closed)


func _inert_view() -> Dictionary:
	var world := Node3D.new()
	world.name = "WarrensObserverControl"
	world.process_mode = Node.PROCESS_MODE_DISABLED
	(Engine.get_main_loop() as SceneTree).root.add_child(world)
	var view := {}
	for key: String in OBSERVER.SCRIPTS:
		var node: Node
		if key == "player": node = CharacterBody3D.new()
		elif key == "rig": node = SpringArm3D.new()
		elif key in ["warrens", "world"]: node = Node3D.new()
		else: node = Node.new()
		node.name = {"player": "Player", "rig": "CameraRig", "warrens": "BurrowWarrens", "manager": "CombatManager"}.get(key, key)
		world.add_child(node)
		# Actual production scripts on already mounted inert nodes avoid ready
		# world construction. This control never mounts the actual /root/Game.
		node.set_script(load(OBSERVER.SCRIPTS[key]))
		view[key] = node
	view.player.set("_camera_rig", view.rig)
	return {"holder": world, "view": view}


func test_original_weak_identity_script_and_lifetime_cannot_rebind_equal_named_sources() -> void:
	var fixture := _inert_view()
	var refs := {}
	var scripts := {}
	for key: String in fixture.view:
		refs[key] = weakref(fixture.view[key])
		scripts[key] = fixture.view[key].get_script()
	assert_true(OBSERVER.same_original(refs, scripts, fixture.view))
	for key: String in fixture.view:
		var changed: Dictionary = fixture.view.duplicate()
		var replacement := Node.new()
		replacement.name = fixture.view[key].name
		changed[key] = replacement
		assert_false(OBSERVER.same_original(refs, scripts, changed), "equal named foreign " + key)
		replacement.free()
	var changed_scripts := scripts.duplicate()
	changed_scripts.player = scripts.rig
	assert_false(OBSERVER.same_original(refs, changed_scripts, fixture.view))
	var shortened := refs.duplicate()
	shortened.erase("world")
	assert_false(OBSERVER.same_original(shortened, scripts, fixture.view))
	fixture.view.player.free()
	assert_false(OBSERVER.same_original(refs, scripts, fixture.view))
	fixture.holder.free()


func test_public_mount_callback_authentication_and_close_refuse_detached_or_manual_controls() -> void:
	var fixture := _inert_view()
	var observer := OBSERVER.new()
	var before_position: Vector3 = fixture.view.player.global_position
	var before_velocity: Vector3 = fixture.view.player.velocity
	var before_yaw: float = fixture.view.rig.get("yaw")
	assert_false(observer.begin(fixture.view.player, fixture.view.warrens, Vector3.ZERO, fixture.view.rig), "actual scripts alone do not authenticate mounted production Game/world")
	assert_false(observer.report().lifetime_refusal.is_empty())
	assert_true(observer.report().pairs.is_empty())
	assert_eq(fixture.view.player.global_position, before_position)
	assert_eq(fixture.view.player.velocity, before_velocity)
	assert_eq(fixture.view.rig.get("yaw"), before_yaw)
	var fresh := OBSERVER.new()
	var foreign := Node.new()
	fresh._native_sample(foreign, "pre", 1.0 / 60.0, RefCounted.new())
	assert_false(fresh.report().lifetime_refusal.is_empty())
	assert_true(fresh.report().pairs.is_empty())
	foreign.free()
	var missing := OBSERVER.new()
	missing._native_sample(null, "pre", 1.0 / 60.0, null)
	assert_true(missing.report().pairs.is_empty())
	assert_false(missing.report().lifetime_refusal.is_empty())
	fresh.close()
	assert_false(fresh.begin(fixture.view.player, fixture.view.warrens, Vector3.ZERO, fixture.view.rig), "closed object never rebinds")
	fixture.holder.free()


func test_actual_environment_projection_reads_without_invoking_modifier_or_changing_original_state() -> void:
	var fixture := _inert_view()
	var observer := OBSERVER.new()
	var service: RefCounted = fixture.view.player.get("_environment_velocity")
	var calls := {"count": 0}
	var modifier := func(_body: CharacterBody3D, _delta: float) -> void: calls.count += 1
	assert_true(service.call("register_modifier", &"diagnostic-control", fixture.view.manager, modifier))
	service.set("_added", Vector3(1.0, 2.0, 3.0))
	service.set("_surviving", Vector3(0.5, 0.0, 1.0))
	var original_entries: Dictionary = service.get("_entries").duplicate(true)
	var original_velocity: Vector3 = fixture.view.player.velocity
	var projected := observer._environment(fixture.view.player)
	assert_true(projected.available)
	assert_eq(projected.entries.size(), 1)
	assert_eq(projected.entries[0].owner.instance_id, str(fixture.view.manager.get_instance_id()))
	assert_true(projected.entries[0].callback_valid)
	assert_eq(projected.added, [1.0, 2.0, 3.0])
	assert_eq(projected.surviving, [0.5, 0.0, 1.0])
	assert_true(projected.last_velocity is Dictionary, "original nonfinite sentinel is recorded safely")
	assert_true(JSON.parse_string(JSON.stringify(projected)) is Dictionary, "no raw callbacks or node objects in report")
	projected.entries[0].owner.path = "forged"
	projected.added[0] = 9.0
	assert_eq(calls.count, 0, "observer never invokes actual modifier")
	assert_eq(service.get("_entries"), original_entries)
	assert_eq(service.get("_added"), Vector3(1.0, 2.0, 3.0))
	assert_eq(fixture.view.player.velocity, original_velocity)
	assert_ne(observer._environment(fixture.view.player).entries[0].owner.path, "forged")
	fixture.holder.free()
