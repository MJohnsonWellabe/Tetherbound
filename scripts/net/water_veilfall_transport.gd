extends "res://scripts/net/water_alpha_transport.gd"

## Fixed persistent path, identical to Alpha transport's sender authentication.
## Only Veilfall's host service can interpret a cave-control request.
func _commit(intent: Dictionary, peer: int) -> Dictionary:
	var service := get_node_or_null("/root/WaterArchipelago/WaterVeilfall")
	if service == null or not bool(service.get("ready_for_intents")):
		return {"ok": false, "pending": false, "reason": "The Veilfall is still loading."}
	var actor: Dictionary = get_parent().call("_water_actor_context", peer, {})
	return service.call("host_commit", intent, peer, actor)

func _receive(kind: String, payload: Dictionary) -> void:
	var service := get_node_or_null("/root/WaterArchipelago/WaterVeilfall")
	if service != null and bool(service.get("ready_for_intents")):
		service.call("receive_authority", kind, payload)
