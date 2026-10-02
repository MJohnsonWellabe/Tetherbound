extends "res://tests/test_case.gd"

const PROOF := preload("res://tools/net/proof_steps_f48.gd")
const RECORDS := preload("res://scripts/net/character_record_rules.gd")
const PORTAL := preload("res://scripts/net/portal_delivery.gd")

var memory: Dictionary
var edge: Dictionary

func test_float_diagnostic_retains_exact_bits_when_json_hides_difference() -> void:
	var original := 100.0 - (1.0 / 60.0) * 0.2
	var saved: float = JSON.parse_string(JSON.stringify(original))
	assert_false(PROOF._json_equal(original, saved))
	var difference: Dictionary = PROOF._json_difference({"party": [{"nourishment": original}]}, {"party": [{"nourishment": saved}]})
	assert_eq(difference.path, "$/party/0/nourishment")
	assert_eq(difference.left_variant_hex, var_to_bytes(original).hex_encode())
	assert_eq(difference.right_variant_hex, var_to_bytes(saved).hex_encode())
	assert_eq(JSON.parse_string(JSON.stringify(difference)), difference)
	assert_true(PROOF._json_difference({"count": 1}, {"count": 1.0}).is_empty())

func before_each() -> void:
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/f48-passive-card.json"))
	memory = {"character_id": "owner", "party": [original.card], "inventory": [],
		"redesign_character": {"transaction_receipts": ["receipt"], "portal_unlocks": []},
		"satchel_escrow": {}, "equipment": RECORDS.empty_equipment(), "realm_hearts": {"active_id": ""}}
	edge = {"row": {"kind": "altar_building", "version": 1,
		"after": {"inventory": memory.inventory.duplicate(true), "party": memory.party.duplicate(true), "redesign_character": memory.redesign_character.duplicate(true)}},
		"files": {"memory": memory.duplicate(true), "disk": memory.duplicate(true)}}

func test_complete_v1_carriers_at_actual_edge_match_original_after() -> void:
	assert_true(PROOF._saved_edge_errors(edge).is_empty())

func test_saved_edge_cannot_accept_old_party_even_if_writer_reported_true() -> void:
	edge.files.disk.party[0].attack += 1.0
	assert_false(PROOF._saved_edge_errors(edge).is_empty())

func test_new_owned_uid_missing_from_disk_is_refused() -> void:
	edge.files.disk.party.clear()
	assert_false(PROOF._saved_edge_errors(edge).is_empty())

func test_memory_party_cannot_change_against_immutable_row_after() -> void:
	edge.files.memory.party[0].hp -= 1.0
	assert_false(PROOF._saved_edge_errors(edge).is_empty())

func test_v2_and_json_v3_require_all_eight_canonical_fields() -> void:
	for version: Variant in [2, 3.0]:
		edge.row = {"kind": "creature_training", "version": version, "after": RECORDS.portable_projection(memory)}
		assert_true(PROOF._saved_edge_errors(edge).is_empty())
		edge.files.disk.equipment.helmet = "changed"
		assert_false(PROOF._saved_edge_errors(edge).is_empty())
		edge.files.disk = memory.duplicate(true)
		edge.files.memory.realm_hearts.active_id = "changed"
		assert_false(PROOF._saved_edge_errors(edge).is_empty())
		edge.files.memory = memory.duplicate(true)

func test_portal_edge_requires_full_party_and_exact_settled_receipt_and_key_debit() -> void:
	var id := PORTAL.receipt("world", "tidewake", "owner")
	var row := {"kind": "portal_unlock", "version": 2, "status": "pending", "biome": "tidewake",
		"item": "tidewake_portal_key", "character_id": "owner", "world_id": "slot-0", "world_instance_id": "world", "receipt": id, "key_slot": 0}
	var settled := row.duplicate(true)
	settled.status = "settled"
	memory.satchel_escrow[id] = settled
	memory.redesign_character.transaction_receipts = [id]
	memory.redesign_character.portal_unlocks = ["tidewake"]
	edge.row = row
	edge.files = {"memory": memory.duplicate(true), "disk": memory.duplicate(true)}
	assert_true(PROOF._saved_edge_errors(edge).is_empty())
	edge.files.disk.party[0].nourishment -= 0.1
	assert_false(PROOF._saved_edge_errors(edge).is_empty(), "even passive-looking saved edge mismatch must fail")
	edge.files.disk = memory.duplicate(true)
	edge.files.disk.inventory = [{"id": "tidewake_portal_key", "n": 1}]
	assert_false(PROOF._saved_edge_errors(edge).is_empty())

func test_journal_epoch_and_transport_epoch_are_independently_bound() -> void:
	var packet := {"session_id": "journal"}
	var row := {"kind": "altar_building", "session_id": "journal"}
	assert_true(PROOF._boundary_epochs_match(packet, row, "journal", "transport", "transport"))
	assert_false(PROOF._boundary_epochs_match(packet, row, "transport", "transport", "transport"), "distinct epochs cannot be substituted")
	assert_false(PROOF._boundary_epochs_match(packet, row, "journal", "transport", "replacement"))
	assert_false(PROOF._boundary_epochs_match(packet, row, "journal", "", ""))
	row.session_id = "changed"
	assert_false(PROOF._boundary_epochs_match(packet, row, "journal", "transport", "transport"))

func test_retained_authenticated_training_epoch_is_not_current_local_writer_epoch() -> void:
	var packet := {"session_id": "retained-source"}
	var row := {"kind": "creature_training", "session_id": "retained-source"}
	assert_true(PROOF._boundary_epochs_match(packet, row, "retained-source", "fresh-transport", "fresh-transport"))
	packet.session_id = "guest-local-writer"
	assert_false(PROOF._boundary_epochs_match(packet, row, "retained-source", "fresh-transport", "fresh-transport"))

func test_portal_observation_retains_explicit_live_transport_epoch() -> void:
	var row := {"kind": "portal_unlock"}
	assert_true(PROOF._boundary_epochs_match({"session_id": "transport"}, row, "transport", "transport", "transport"))
	assert_false(PROOF._boundary_epochs_match({"session_id": "journal"}, row, "transport", "transport", "transport"))
	assert_false(PROOF._boundary_epochs_match({"session_id": "transport"}, row, "transport", "transport", "replacement"))
