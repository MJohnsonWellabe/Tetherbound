extends "res://tests/test_case.gd"

const PEER_REGISTRY := preload("res://scripts/net/peer_registry.gd")


func test_rows_always_carry_a_normalized_appearance_id() -> void:
	var default_row: Dictionary = PEER_REGISTRY.make_row(1)
	assert_eq(str(default_row.get("appearance_id")), "trainer")
	var selected: Dictionary = PEER_REGISTRY.make_row(42, "save-42", "Ren", "water", "sera")
	assert_eq(str(selected.get("appearance_id")), "sera")


func test_appearance_survives_registry_replication() -> void:
	var host := PEER_REGISTRY.new()
	host.add(42, "save-42", "Ren", "stormwood", "kael")
	var client := PEER_REGISTRY.new()
	client.load_data(host.save_data())
	assert_eq(str(client.row(42).get("appearance_id")), "kael")
	assert_eq(client.fingerprint(), host.fingerprint())


func test_old_registry_payload_defaults_to_original_trainer() -> void:
	var registry := PEER_REGISTRY.new()
	registry.load_data({"revision": 3, "rows": [{
		"peer_id": 42, "character_id": "old-save", "display_name": "Old",
		"realm": "meadows",
	}]})
	assert_eq(str(registry.row(42).get("appearance_id")), "trainer")
