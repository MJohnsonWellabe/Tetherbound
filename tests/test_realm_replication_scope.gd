extends "res://tests/test_case.gd"

const SCOPE := preload("res://scripts/net/realm_replication_scope.gd")

func test_public_visibility_means_every_recipient_without_changing_individual_permissions() -> void:
	var recipients := PackedInt32Array([11, 22, 33])
	var called: Array[int] = []
	var policy := func(peer: int) -> bool:
		called.append(peer)
		return peer != 22
	assert_false(SCOPE.public_or_recipient_allowed(0, recipients, policy))
	assert_false(called.has(0), "public aggregation must never call the zero predicate")
	assert_true(SCOPE.public_or_recipient_allowed(11, recipients, policy))
	assert_false(SCOPE.public_or_recipient_allowed(22, recipients, policy))
	assert_true(SCOPE.public_or_recipient_allowed(33, recipients, policy))
	assert_false(SCOPE.public_or_recipient_allowed(0, recipients, func(_peer: int) -> bool: return false))
	assert_true(SCOPE.public_or_recipient_allowed(0, recipients, func(_peer: int) -> bool: return true),
		"without a scoped denial the original public baseline is unchanged")
	assert_true(SCOPE.public_or_recipient_allowed(0, PackedInt32Array(), policy))

func test_native_automatic_visibility_cadence_is_preserved() -> void:
	var body := _body(20)
	assert_eq((body.get_node("Sync") as MultiplayerSynchronizer).visibility_update_mode,
		MultiplayerSynchronizer.VISIBILITY_PROCESS_IDLE)
	assert_eq((body.get_node("AdmissionSync") as MultiplayerSynchronizer).visibility_update_mode,
		MultiplayerSynchronizer.VISIBILITY_PROCESS_IDLE)
	body.free()

func _body(owner: int, baseline: Callable = Callable()) -> Node3D:
	var body := Node3D.new()
	var state := MultiplayerSynchronizer.new()
	state.name = "Sync"
	body.add_child(state)
	body.set_multiplayer_authority(owner)
	SCOPE.wire_body(body, state, "meadows", owner, baseline)
	return body

func test_host_owned_admission_preserves_existing_realm_filter() -> void:
	var body := _body(1, func(observer: int) -> bool: return observer == 20)
	var admission := body.get_node("AdmissionSync") as MultiplayerSynchronizer
	var baseline := func(observer: int) -> bool: return observer == 20
	assert_true(SCOPE.baseline_admission(1, 20, baseline))
	assert_false(SCOPE.baseline_admission(1, 30, baseline), "OR composition must not broaden the host State filter")
	assert_eq(admission.get_multiplayer_authority(), 1)
	body.free()

func test_remote_owned_admission_preserves_original_host_fallback() -> void:
	var body := _body(20, func(_observer: int) -> bool: return false)
	var admission := body.get_node("AdmissionSync") as MultiplayerSynchronizer
	assert_true(SCOPE.baseline_admission(20, 30, func(_observer: int) -> bool: return false),
		"remote-owned state had no host-owned spawn filter before Phase1")
	assert_eq((body.get_node("Sync") as Node).get_multiplayer_authority(), 20)
	assert_eq(admission.get_multiplayer_authority(), 1, "must override recursive owner assignment before tree entry")
	assert_eq(str(body.get_meta(SCOPE.BODY_REALM)), "meadows")
	assert_eq(int(body.get_meta(SCOPE.BODY_OWNER)), 20)
	body.free()

func test_wire_is_idempotent_and_empty_admission_has_no_gameplay_properties() -> void:
	var body := _body(20)
	SCOPE.wire_body(body, body.get_node("Sync"), "meadows", 20)
	assert_eq(body.get_child_count(), 2)
	var admission := body.get_node("AdmissionSync") as MultiplayerSynchronizer
	assert_eq(admission.replication_config.get_properties().size(), 0)
	body.free()

func test_locally_freed_received_body_does_not_manufacture_drained_inventory() -> void:
	var scope := SCOPE.new()
	var body := _body(20)
	scope._spawned(body)
	assert_eq(scope.received_count(), 1)
	body.free()
	assert_eq(scope.received_count(), 1, "only the actual engine despawn callback may retire a receipt")
	scope.free()
