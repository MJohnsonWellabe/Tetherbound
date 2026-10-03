extends "res://tests/test_case.gd"

## Pure codec controls with disclosed retained-event/observation fixtures.
## No transport, real movement, owner file write, or F48 acceptance is claimed.
const PREP := preload("res://scripts/net/research_passive_preparation.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const PASSIVE := preload("res://scripts/net/groom_passive_sync.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const GROOM := preload("res://tests/test_den_groom_saved_transaction.gd")
const E := preload("res://scripts/creatures/essence.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")

func _event() -> Dictionary:
	var duty := {"character_id": DATA.CHARACTER, "action": "research_event", "intent": {},
		"context": {"source_key": "encounter:original", "event_confirmed": true,
			"world_namespace": "resource-namespace", "session_id": "original-epoch", "event_id": "original-sight",
			"participants": [DATA.CHARACTER], "species_id": "terrapup", "kind": "sight"}}
	return EVENT.make(DATA.new()._world(), "original-epoch", "original-sight", [duty])

func _prepared(event: Dictionary, before: Dictionary) -> Dictionary:
	return PREP.make(event, event.duties[0], before, 3, "current-epoch", 2.0, 4.0, 1,
		{"meadows": ["observed_landmark"]}, DATA.TXN)

func test_exact_retained_duty_derivation_and_input_isolation() -> void:
	var event := _event()
	var before := GROOM.new()._before()
	var original := before.duplicate(true)
	var retained := event.duplicate(true)
	var prepared := _prepared(event, before)
	assert_true(PREP.valid(prepared, event))
	assert_true(E._equivalent(before, original))
	assert_true(E._equivalent(event, retained))
	assert_true(E._equivalent(prepared.after, PASSIVE.derive(before, 2.0, 4.0, 1)))
	assert_true(E._equivalent(PASSIVE.unchanged_core(prepared.after), PASSIVE.unchanged_core(before)))
	assert_eq(prepared.duty.context.session_id, "original-epoch", "retained event keeps its original session")
	assert_eq(prepared.session_epoch, "current-epoch", "preparation binds the current transport epoch separately")
	before.party[0].hp = 0.0
	event.duties[0].context.species_id = "changed"
	assert_true(E._equivalent(prepared.before, original), "host-owned inputs are detached")
	assert_true(PREP.valid(prepared, retained))
	assert_false(PREP.valid(prepared, event), "caller must supply unchanged retained world evidence")

func test_rejects_unretained_foreign_operation_identity_and_tampering() -> void:
	var event := _event()
	var prepared := _prepared(event, GROOM.new()._before())
	for field: String in ["character_id", "world_id", "world_namespace", "retained_event", "preparation_id", "duty_hash", "hash"]:
		var changed := prepared.duplicate(true)
		changed[field] = "foreign"
		assert_false(PREP.valid(changed, event), field)
	var wrong_op := prepared.duplicate(true)
	wrong_op.duty.action = "groom"
	wrong_op.duty_hash = PREP.fingerprint(wrong_op.duty)
	wrong_op.hash = PREP.preparation_hash(wrong_op)
	assert_false(PREP.valid(wrong_op, event), "a fresh hash cannot invent a research source")
	var invented := prepared.duplicate(true)
	invented.duty.context.species_id = "mudsnout"
	invented.duty_hash = PREP.fingerprint(invented.duty)
	invented.hash = PREP.preparation_hash(invented)
	assert_false(PREP.valid(invented, event))
	var hp := prepared.duplicate(true)
	hp.after.party[0].hp = maxf(0.0, float(hp.after.party[0].hp) - 1.0)
	hp.hash = PREP.preparation_hash(hp)
	assert_false(PREP.valid(hp, event), "rehashed outputs still require canonical passive derivation")
	var ambiguous := event.duplicate(true)
	ambiguous.duties.append(event.duties[0].duplicate(true))
	assert_false(PREP.valid(prepared, ambiguous), "one original duty must bind uniquely")

func test_malformed_shapes_revisions_observations_and_discoveries_refuse() -> void:
	var event := _event()
	var before := GROOM.new()._before()
	var prepared := _prepared(event, before)
	for replacement: Variant in [-1, 2147483646, 1.5, "3", true]:
		var changed := prepared.duplicate(true)
		changed.revision = replacement
		changed.hash = PREP.preparation_hash(changed)
		assert_false(PREP.valid(changed, event))
	for field: String in PREP.FIELDS:
		var missing := prepared.duplicate(true)
		missing.erase(field)
		assert_false(PREP.valid(missing, event), "missing " + field)
	var extra := prepared.duplicate(true)
	extra.owner_record = before
	assert_false(PREP.valid(extra, event))
	assert_false(PREP.valid([], event))
	assert_false(PREP.valid(prepared, {}))
	assert_true(PREP.make(event, event.duties[0], before, 3, "current-epoch", INF, 0.0, 0, {}, DATA.TXN).is_empty())
	assert_true(PREP.make(event, event.duties[0], before, 3, "current-epoch", 1.0, -1.0, 0, {}, DATA.TXN).is_empty())
	assert_true(PREP.make(event, event.duties[0], before, 3, "current-epoch", 1.0, 0.0, 1, {}, DATA.TXN).is_empty())
	assert_true(PREP.make(event, event.duties[0], before, 3, "current-epoch", 1.0, 0.0, 0, {"unknown": []}, DATA.TXN).is_empty())

func test_owner_plan_preserves_progress_maps_and_every_nonpassive_field() -> void:
	var event := _event()
	var before := GROOM.new()._before()
	var prepared := _prepared(event, before)
	var discoveries := {"meadows": ["local_history"], "water": ["other_history"]}
	var plan := PREP.owner_plan(before, prepared, event, discoveries)
	assert_true(plan.ok)
	assert_eq(plan.discoveries.meadows, ["local_history", "observed_landmark"])
	assert_eq(plan.discoveries.water, ["other_history"])
	assert_eq(discoveries.meadows, ["local_history"], "planning does not mutate map inputs")
	plan.state.party[0].hp = 0.0
	assert_true(PREP.valid(prepared, event), "plan output is detached")
	for field: String in PASSIVE.COUNTERS:
		var ahead: Dictionary = prepared.after.duplicate(true)
		ahead.party[0][field] += 1
		assert_eq(PREP.owner_plan(ahead, prepared, event, discoveries).code, "research_passive_unobserved_progress")
	var healed := before.duplicate(true)
	healed.party[0].hp = maxf(0.0, float(healed.party[0].hp) - 1.0)
	assert_false(PREP.owner_plan(healed, prepared, event, discoveries).ok)
	var inventory := before.duplicate(true)
	inventory.inventory[0] = null
	assert_false(PREP.owner_plan(inventory, prepared, event, discoveries).ok)
	var reordered := before.duplicate(true)
	reordered.party[0].uid = "foreign_uid"
	assert_false(PREP.owner_plan(reordered, prepared, event, discoveries).ok)
	assert_true(PREP.owner_plan(prepared.after, prepared, event, plan.discoveries).ok, "same saved preparation is idempotent")

func test_hash_retains_float_bits_and_lossless_document_roundtrip() -> void:
	var event := _event()
	var before := GROOM.new()._before()
	before.party[0].distance_m_together = 0.12345678901234566
	var prepared := _prepared(event, before)
	var decoded: Dictionary = DOCUMENT.parse(DOCUMENT.stringify(prepared))
	assert_true(PREP.valid(decoded, event))
	assert_true(E._equivalent(prepared, decoded))
	assert_eq(PREP.fingerprint({"b": 1, "a": 2.0}), PREP.fingerprint({"a": 2, "b": 1.0}))
	assert_ne(PREP.fingerprint({"value": 0.12345678901234566}), PREP.fingerprint({"value": 0.12345678901234568}), "sub-JSON differences cannot share an ACK hash")

func test_hash_keeps_large_integral_floats_without_int64_conversion() -> void:
	var original := {"large": [1.0e20, 2.0e20, -1.0e20], "edge": 9007199254740992.0}
	var canonical: Dictionary = PREP._canonical(original)
	for value: Variant in canonical.large:
		assert_true(value is float, "out-of-int64 integral float stays lossless")
	assert_true(canonical.edge is float, "outside exact integer range stays float64")
	assert_ne(PREP.fingerprint({"value": 1.0e20}), PREP.fingerprint({"value": 2.0e20}))
	assert_ne(PREP.fingerprint({"value": 1.0e20}), PREP.fingerprint({"value": -1.0e20}))
	var decoded: Dictionary = DOCUMENT.parse(DOCUMENT.stringify(original))
	assert_eq(var_to_bytes(decoded.large), var_to_bytes(original.large), "float bytes survive document roundtrip")
	assert_eq(var_to_bytes(decoded.edge), var_to_bytes(original.edge))
	assert_eq(PREP.fingerprint(decoded), PREP.fingerprint(original))
	assert_eq(PREP.fingerprint({"value": 9007199254740991.0}), PREP.fingerprint({"value": 9007199254740991}))

func _assert_bad_passive(before: Dictionary, event: Dictionary, prepared: Dictionary, label: String) -> void:
	assert_true(_prepared(event, before).is_empty(), "make refuses " + label)
	var changed := prepared.duplicate(true)
	changed.before = before
	assert_false(PREP.valid(changed, event), "valid refuses before " + label)
	changed = prepared.duplicate(true)
	changed.after = before
	assert_false(PREP.valid(changed, event), "valid refuses after " + label)
	assert_false(PREP.owner_plan(before, prepared, event, {}).ok, "owner refuses " + label)

func test_passive_field_omissions_and_invalid_scalars_refuse_cleanly() -> void:
	var event := _event()
	var before := GROOM.new()._before()
	var prepared := _prepared(event, before)
	for field: String in PASSIVE.FIELDS + ["resting"]:
		var missing := before.duplicate(true)
		missing.party[0].erase(field)
		_assert_bad_passive(missing, event, prepared, "missing " + field)
		var replacements: Array = [null, "0", [], {}, NAN, INF, -INF]
		if field in ["rested", "resting"]: replacements.append_array([0, 1.0])
		else: replacements.append_array([true, -1.0])
		if field == "landmarks_visited_together": replacements.append_array([1.5, 9223372036854775808.0])
		for replacement: Variant in replacements:
			var changed := before.duplicate(true)
			changed.party[0][field] = replacement
			_assert_bad_passive(changed, event, prepared, field + "=" + str(replacement))
	for party: Variant in [null, {}, [null]]:
		var changed := before.duplicate(true)
		changed.party = party
		_assert_bad_passive(changed, event, prepared, "invalid party shape")

func test_passive_counters_keep_existing_storage_range_and_exact_owner_progress() -> void:
	var event := _event()
	var before := GROOM.new()._before()
	before.party[0].distance_m_together = 1.0e20
	before.party[0].landmarks_visited_together = 9007199254740992
	var prepared := _prepared(event, before)
	assert_true(PREP.valid(prepared, event), "no new gameplay counter ceiling")
	var ahead: Dictionary = prepared.after.duplicate(true)
	ahead.party[0].landmarks_visited_together += 1
	assert_eq(PREP.owner_plan(ahead, prepared, event, {}).code, "research_passive_unobserved_progress", "integer history is not rounded to float for comparison")
	before.party[0].landmarks_visited_together = 3.0
	assert_false(_prepared(event, before).is_empty(), "legacy integral numeric counter is accepted")
