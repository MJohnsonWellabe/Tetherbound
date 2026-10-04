extends "res://tests/test_case.gd"

## Retained journal projection and transport are doubles. The real Altar
## bridge must adopt that original intent rather than mint/resubmit a spend.
class SessionFixture extends Node:
	var original := {"spend_id": "0123456789abcdef0123456789abcdef", "creature_uid": "original_uid",
		"payment_item": "tether_candy", "expected_level": 4, "expected_character_revision": 7}
	var reconciled: Dictionary = {}
	func retained_training_transaction(_actions: Array) -> Dictionary:
		return {"action": "altar_spend", "intent": original.duplicate(true), "status": "pending"}
	func reconcile_altar_essence_spend(station_key: String, intent: Dictionary) -> Dictionary:
		reconciled = {"station_key": station_key, "intent": intent.duplicate(true)}
		return {"ok": false, "resolved": false, "durable": true, "code": "awaiting_saved_decision"}

class ServiceFixture extends "res://scripts/ui/altar_service.gd":
	func _bind_session() -> bool: return is_instance_valid(_session)
	func _context() -> Dictionary:
		return {"character_id": "original_character", "world_namespace": "original_world", "world_id": "world_id"}

func test_restarted_altar_bridge_recovers_exact_original_spend_and_keeps_failed_save_pending() -> void:
	var session := SessionFixture.new()
	var service := ServiceFixture.new()
	service._session = session
	assert_true(service._pending.is_empty())
	service.retry_retained_transaction("altar:meadows:original_station", session.original.spend_id)
	assert_eq(session.reconciled.intent, session.original)
	assert_eq(service._pending.request, session.original)
	assert_true(service._pending.durable)
	assert_eq(service._pending.station_key, "altar:meadows:original_station")
	var before := service._pending.duplicate(true)
	service.retry_retained_transaction("another_station", "ffffffffffffffffffffffffffffffff")
	assert_eq(service._pending, before)
	service.reconcile_essence_spend(session.original.spend_id)
	assert_eq(session.reconciled.intent, session.original)
	assert_eq(service._pending.request, session.original)
	service.free()
	session.free()
