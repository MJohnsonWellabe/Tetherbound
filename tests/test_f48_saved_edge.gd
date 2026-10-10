extends "res://tests/test_case.gd"

const PROOF := preload("res://tools/net/proof_steps_f48.gd")
const RECORDS := preload("res://scripts/net/character_record_rules.gd")
const PORTAL := preload("res://scripts/net/portal_delivery.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")

var memory: Dictionary
var edge: Dictionary

func test_named_warden_input_cadence_preserves_legacy_and_refuses_foreign_or_weakened_schedule() -> void:
	var baseline := {"stride_frames": 20, "stage_when_ready": false}
	var ready := {"stride_frames": 4, "stage_when_ready": true}
	assert_eq(PROOF._fixture_fight_cadence("warden_aldis", {}), baseline)
	assert_eq(PROOF._fixture_fight_cadence("master_t1", {}), baseline)
	assert_eq(PROOF._fixture_fight_cadence("warden_aldis", {"input_cadence": ready}), ready)
	assert_true(PROOF._fixture_fight_cadence("master_t1", {"input_cadence": ready}).is_empty())
	for invalid: Variant in [null, [], {}, {"stride_frames": 0, "stage_when_ready": true},
		{"stride_frames": 4, "stage_when_ready": false}, {"stride_frames": 4, "stage_when_ready": 1},
		{"stride_frames": "4", "stage_when_ready": true}, {"stride_frames": 4, "stage_when_ready": true, "budget_frames": 12000}]:
		assert_true(PROOF._fixture_fight_cadence("warden_aldis", {"input_cadence": invalid}).is_empty())
	var original := {"input_cadence": ready.duplicate(true)}
	var selected: Dictionary = PROOF._fixture_fight_cadence("warden_aldis", original)
	selected.stride_frames = 100
	assert_eq(original.input_cadence, ready, "Schedule selection never rewrites caller disclosure")

class RefusingPreparedSaver extends SAVE:
	func _write_snapshot_locked(_request: Dictionary) -> bool:
		return false

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

func test_actual_locked_fallback_full_receipt_matches_frozen_request_and_rejects_tampering() -> void:
	var directory: String = "user://test_f48_fallback_receipt_" + Crypto.new().generate_random_bytes(12).hex_encode() + "/"
	var game: RefCounted = FIXTURE.game(ITEM_DB.new(),false)
	var saver: RefCounted = SAVE.new(directory)
	var request: Dictionary = saver.call("_prepare_snapshot",game,0)
	assert_false(request.is_empty())
	assert_true(saver.call("write_snapshot_observed",request) == true)
	var receipt: Dictionary = saver.call("fallback_write_receipt")
	var paths := {"slot":saver.call("slot_path",0),
		"character":saver.get("_characters").call("path_for",str(request.character_id)),
		"world":saver.get("_worlds").call("path_for",str(request.world_id))}
	var files: Dictionary = PROOF._fallback_receipt_files(request,receipt,paths,saver.get_instance_id())
	assert_eq(files.size(),3,"Actual writer full byte receipts, not synthetic certificates")
	assert_eq(files.get("character",{}),receipt.get("files",{}).get("character",{}).get("payload"))
	assert_eq(files.get("slot",{}).get("satiety"),request.data.satiety)
	var changed_request: Dictionary = request.duplicate(true)
	changed_request.data.satiety -= 1.0
	assert_true(PROOF._fallback_receipt_files(changed_request,receipt,paths,saver.get_instance_id()).is_empty())
	assert_true(PROOF._fallback_receipt_files(request,receipt,paths,saver.get_instance_id()+1).is_empty(),"Another source writer cannot certify this request")
	var foreign_paths: Dictionary = paths.duplicate(true)
	foreign_paths.character += ".foreign"
	assert_true(PROOF._fallback_receipt_files(request,receipt,foreign_paths,saver.get_instance_id()).is_empty())
	for field: String in ["sha256","bytes_base64"]:
		var altered: Dictionary = receipt.duplicate(true)
		altered.files.character[field] = "changed"
		assert_true(PROOF._fallback_receipt_files(request,altered,paths,saver.get_instance_id()).is_empty(),field+" mismatch")
	var changed_payload: Dictionary = receipt.duplicate(true)
	changed_payload.files.character.payload.last_played = "replaced"
	assert_true(PROOF._fallback_receipt_files(request,changed_payload,paths,saver.get_instance_id()).is_empty(),"Complete metadata must still equal its original raw bytes")
	var changed_full_card: Dictionary = receipt.duplicate(true)
	changed_full_card.files.character.payload.satiety -= 1.0
	var bytes: PackedByteArray = DOCUMENT.stringify(changed_full_card.files.character.payload).to_utf8_buffer()
	var hasher: HashingContext = HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(bytes)
	changed_full_card.files.character.bytes_base64 = Marshalls.raw_to_base64(bytes)
	changed_full_card.files.character.sha256 = hasher.finish().hex_encode()
	assert_true(PROOF._fallback_receipt_files(request,changed_full_card,paths,saver.get_instance_id()).is_empty(),"Even internally valid changed full bytes must match every frozen request field")
	FIXTURE.wipe(directory)

func test_actual_character_only_receipt_retains_full_snapshot_without_world_partition() -> void:
	var directory: String = "user://test_f48_character_only_" + Crypto.new().generate_random_bytes(12).hex_encode() + "/"
	var game: RefCounted = FIXTURE.game(ITEM_DB.new(),false)
	var saver: RefCounted = SAVE.new(directory)
	var initial: Dictionary = saver.call("_prepare_snapshot",game,0)
	assert_false(initial.is_empty())
	if initial.is_empty():
		FIXTURE.wipe(directory)
		return
	game.set("host",false)
	game.set("satiety",63.25)
	var request: Dictionary = saver.call("_prepare_snapshot",game,0,false,str(initial.character_id))
	assert_false(request.is_empty())
	if request.is_empty():
		FIXTURE.wipe(directory)
		return
	assert_true(request.character_only)
	assert_false(request.write_split)
	assert_false(request.host)
	assert_true(request.world_data.is_empty(),"Guest character-only writer has no world partition")
	assert_true(request.data.has("reward_deliveries"),"Its original full frozen snapshot still carries the journal source")
	assert_true(saver.call("write_snapshot_observed",request) == true)
	var receipt: Dictionary = saver.call("fallback_write_receipt")
	var paths := {"character":saver.get("_characters").call("path_for",str(request.character_id))}
	var files: Dictionary = PROOF._fallback_receipt_files(request,receipt,paths,saver.get_instance_id())
	assert_eq(files.size(),1,"Actual character-only transaction certifies one full primary")
	assert_eq(files.get("character",{}).get("satiety"),63.25)
	assert_eq(files.get("character",{}),receipt.get("files",{}).get("character",{}).get("payload"))
	assert_false(FileAccess.file_exists(str(saver.call("slot_path",0))),"Character-only BOOL does not create a merged slot")
	assert_false(FileAccess.file_exists(str(saver.get("_worlds").call("path_for",str(request.world_id)))),"Guest does not invent a world write")
	var changed_hash: Dictionary = receipt.duplicate(true)
	changed_hash.files.character.sha256 = "changed"
	assert_true(PROOF._fallback_receipt_files(request,changed_hash,paths,saver.get_instance_id()).is_empty())
	var changed_request: Dictionary = request.duplicate(true)
	changed_request.character_data.satiety -= 1.0
	assert_true(PROOF._fallback_receipt_files(changed_request,receipt,paths,saver.get_instance_id()).is_empty())
	var changed_party: Dictionary = receipt.duplicate(true)
	changed_party.files.character.payload.party.append(memory.party[0].duplicate(true))
	var bytes: PackedByteArray = DOCUMENT.stringify(changed_party.files.character.payload).to_utf8_buffer()
	var hasher: HashingContext = HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(bytes)
	changed_party.files.character.bytes_base64 = Marshalls.raw_to_base64(bytes)
	changed_party.files.character.sha256 = hasher.finish().hex_encode()
	assert_true(PROOF._fallback_receipt_files(request,changed_party,paths,saver.get_instance_id()).is_empty(),"Internally matching raw bytes cannot add an owned card absent from the actual frozen request")
	FIXTURE.wipe(directory)

func test_actual_prepared_character_observer_binds_original_request_bool_and_locked_bytes() -> void:
	var directory: String = "user://test_f48_prepared_receipt_" + Crypto.new().generate_random_bytes(12).hex_encode() + "/"
	var game: RefCounted = FIXTURE.game(ITEM_DB.new(),false)
	var saver: RefCounted = SAVE.new(directory)
	var initial: Dictionary = saver.call("_prepare_snapshot",game,0)
	assert_false(initial.is_empty())
	if initial.is_empty():
		FIXTURE.wipe(directory)
		return
	game.set("host",false)
	game.set("satiety",62.75)
	var observed := {"submitted":{},"completed":{},"saved":false,"receipt":{},"calls":0,"id":"","original":{}}
	var submitted := func(id: String, request: Dictionary) -> void:
		observed.id=id
		observed.submitted=request
		var actual: Dictionary = PROOF._prepared_character_call_matches(saver,id,request,"submitted")
		assert_false(actual.is_empty())
		observed.original=actual.get("call",{})
		assert_true(PROOF._prepared_character_call_matches(saver,id,request.duplicate(true),"submitted").is_empty(),"Equivalent request bytes are not the active original object")
	var completed := func(id: String, request: Dictionary, saved: bool, receipt: Dictionary) -> void:
		observed.completed=request
		observed.saved=saved
		observed.receipt=receipt
		observed.calls+=1
		assert_eq(id,observed.id)
		assert_false(PROOF._prepared_character_call_matches(saver,id,request,"completed",observed.original,receipt).is_empty())
		assert_true(PROOF._prepared_character_call_matches(saver,id,request,"completed",observed.original,receipt.duplicate(true)).is_empty(),"Equivalent receipt bytes cannot impersonate the actual locked receipt object")
		assert_true(PROOF._prepared_character_call_matches(saver,id,request,"completed",observed.original.duplicate(true),receipt).is_empty())
	saver.connect("prepared_character_submitted",submitted)
	saver.connect("prepared_character_completed",completed)
	assert_true(saver.call("save_character_prepared",game,str(initial.character_id)) == true)
	assert_true(observed.saved)
	assert_eq(observed.calls,1)
	assert_true(PROOF._prepared_character_call_matches(saver,observed.id,observed.submitted,"submitted").is_empty(),"Manual or replayed submission after the real invocation has no source")
	assert_true(PROOF._prepared_character_call_matches(saver,observed.id,observed.completed,"completed",observed.original,observed.receipt).is_empty(),"A replayed TRUE callback cannot revive the expired call")
	assert_true(is_same(observed.submitted,observed.completed),"Both signals carry the same actual request, not reconstructed state")
	assert_true(observed.submitted.is_read_only())
	assert_true(observed.submitted.character_data.is_read_only())
	assert_eq(observed.submitted.character_data.satiety,62.75)
	var paths := {"character":saver.get("_characters").call("path_for",str(initial.character_id))}
	var files := PROOF._fallback_receipt_files(observed.submitted,observed.receipt,paths,saver.get_instance_id(),"SaveGame_locked_prepared_character_write_TRUE_BOOL")
	assert_eq(files.size(),1)
	assert_eq(files.get("character",{}).get("satiety"),62.75)
	assert_eq(FileAccess.get_sha256(str(paths.character)),observed.receipt.files.character.sha256,"Receipt proves complete actual primary bytes")
	assert_true(PROOF._fallback_receipt_files(observed.submitted,observed.receipt,paths,saver.get_instance_id()).is_empty(),"A synchronous receipt cannot masquerade as a worker receipt")
	var changed: Dictionary = observed.submitted.duplicate(true)
	changed.character_data.satiety-=1.0
	assert_true(PROOF._fallback_receipt_files(changed,observed.receipt,paths,saver.get_instance_id(),"SaveGame_locked_prepared_character_write_TRUE_BOOL").is_empty())
	assert_false(FileAccess.file_exists(str(saver.call("slot_path",0))))
	assert_false(saver.call("save_character_prepared",null,str(initial.character_id)) == true)
	assert_eq(observed.calls,1,"An invalid/no-write attempt cannot invent a completed BOOL")
	saver.disconnect("prepared_character_submitted",submitted)
	saver.disconnect("prepared_character_completed",completed)
	FIXTURE.wipe(directory)

func test_prepared_invocations_keep_nested_calls_separate_and_reject_false_actual_bool() -> void:
	var directory: String = "user://test_f48_prepared_nested_" + Crypto.new().generate_random_bytes(12).hex_encode() + "/"
	var game: RefCounted = FIXTURE.game(ITEM_DB.new(),false)
	var saver: RefCounted = SAVE.new(directory)
	var initial: Dictionary = saver.call("_prepare_snapshot",game,0)
	assert_false(initial.is_empty())
	if initial.is_empty():
		FIXTURE.wipe(directory)
		return
	var calls := {"nested":false,"originals":{},"completed":[]}
	var submitted := func(id: String, request: Dictionary) -> void:
		var actual: Dictionary = PROOF._prepared_character_call_matches(saver,id,request,"submitted")
		assert_false(actual.is_empty())
		calls.originals[id]=actual.get("call",{})
		if not calls.nested:
			calls.nested=true
			assert_true(saver.call("save_character_prepared",game,str(initial.character_id)) == true)
			assert_true(is_same(PROOF._prepared_character_call_matches(saver,id,request,"submitted").get("call"),calls.originals[id]),"The child cannot replace its still-active parent")
	var completed := func(id: String, request: Dictionary, saved: bool, receipt: Dictionary) -> void:
		assert_true(saved)
		assert_false(PROOF._prepared_character_call_matches(saver,id,request,"completed",calls.originals[id],receipt).is_empty())
		for other: String in calls.originals:
			if other != id:
				assert_true(PROOF._prepared_character_call_matches(saver,id,request,"completed",calls.originals[other],receipt).is_empty())
		calls.completed.append(id)
	saver.connect("prepared_character_submitted",submitted)
	saver.connect("prepared_character_completed",completed)
	assert_true(saver.call("save_character_prepared",game,str(initial.character_id)) == true)
	assert_eq(calls.originals.size(),2)
	assert_eq(calls.completed.size(),2)
	assert_ne(calls.completed[0],calls.completed[1])
	for id: String in calls.originals: assert_true(saver.call("prepared_character_call",id).is_empty())
	saver.disconnect("prepared_character_submitted",submitted)
	saver.disconnect("prepared_character_completed",completed)
	var refusing: RefCounted = RefusingPreparedSaver.new(directory)
	var failed := {"original":{},"called":false}
	var failing_submit := func(id: String, request: Dictionary) -> void:
		failed.original=PROOF._prepared_character_call_matches(refusing,id,request,"submitted").get("call",{})
	var failing_complete := func(id: String, request: Dictionary, saved: bool, receipt: Dictionary) -> void:
		failed.called=true
		assert_false(saved)
		assert_false(refusing.call("prepared_character_call",id).success)
		assert_true(PROOF._prepared_character_call_matches(refusing,id,request,"completed",failed.original,receipt).is_empty(),"A true callback argument cannot certify an actual FALSE writer result")
	refusing.connect("prepared_character_submitted",failing_submit)
	refusing.connect("prepared_character_completed",failing_complete)
	assert_false(refusing.call("save_character_prepared",game,str(initial.character_id)) == true)
	assert_true(failed.called)
	refusing.disconnect("prepared_character_submitted",failing_submit)
	refusing.disconnect("prepared_character_completed",failing_complete)
	FIXTURE.wipe(directory)

func test_descendant_keeps_original_full_canonical_parent_and_exact_replayed_party() -> void:
	edge.row.status = "pending"
	edge.row.receipt = "original-receipt"
	var accepted: Dictionary = edge.row.duplicate(true)
	accepted.status = "accepted"
	assert_true(PROOF._fallback_parent_matches(edge,accepted))
	var changed: Dictionary = accepted.duplicate(true)
	changed.receipt = "foreign-receipt"
	assert_false(PROOF._fallback_parent_matches(edge,changed))
	changed = accepted.duplicate(true)
	changed.after.party[0].attack += 1.0
	assert_false(PROOF._fallback_parent_matches(edge,changed),"Accepted status cannot hide a changed original full after")
	changed = accepted.duplicate(true)
	changed.status = "pending"
	assert_false(PROOF._fallback_parent_matches(edge,changed),"A pending original has no actual accepted ACK")
	var replayed: Array = memory.party.duplicate(true)
	replayed[0].nourishment -= 0.25
	var personal: Dictionary = memory.duplicate(true)
	personal.party = replayed.duplicate(true)
	var request := {"character_id":"owner","character_data":personal}
	assert_true(PROOF._fallback_request_carrier_matches(edge,request,replayed),"Pure comparator requires an independently supplied complete replay; live observer separately authenticates it")
	assert_false(PROOF._fallback_request_carrier_matches(edge,request,memory.party))
	for field: String in ["inventory","redesign_character","equipment","realm_hearts","satchel_escrow"]:
		var altered: Dictionary = request.duplicate(true)
		altered.character_data[field] = {"foreign":true}
		assert_false(PROOF._fallback_request_carrier_matches(edge,altered,replayed),"Complete carrier " + field)
	request.character_id = "foreign-owner"
	assert_false(PROOF._fallback_request_carrier_matches(edge,request,replayed))

func test_false_completion_and_lost_source_lifetime_cannot_make_a_descendant() -> void:
	var request := {"character_id":"owner"}
	var bound := {"jobs":{"original":{"request":request}}}
	PROOF._fallback_request_completed(bound,"original",request,false,{"source":"SaveGame_locked_fallback_write_TRUE_BOOL"})
	assert_true(bound.jobs.is_empty(),"Failed BOOL retires this submitted job without reading/certifying a current file")
	var dead_tree: RefCounted = RefCounted.new()
	var dead_game: RefCounted = RefCounted.new()
	var dead_saver: RefCounted = RefCounted.new()
	var dead_writer: RefCounted = RefCounted.new()
	bound = {"tree":weakref(dead_tree),"game":weakref(dead_game),"saver":weakref(dead_saver),
		"jobs":{"original":{"request":request,"writer_ref":weakref(dead_writer)}}}
	dead_tree = null
	dead_game = null
	dead_saver = null
	dead_writer = null
	PROOF._fallback_request_completed(bound,"original",request,true,{})
	assert_true(bound.jobs.is_empty(),"A once retained source that expired cannot certify a successful-looking completion")
