extends RefCounted

## A host-validated touch uses the existing full-character journal and owner
## save/ACK protocol. It changes only this character's waystones and receipt.
static func stage(current: Dictionary, intent: Dictionary, context: Dictionary) -> Dictionary:
	var deny := {"ok": false, "code": "waystone_context_changed"}
	if intent.size() != 2 or not intent.get("waystone_id") is String \
		or not intent.get("touch_id") is String or intent.touch_id.is_empty() \
		or intent.touch_id.length() > 192 or context.get("validated_touch") != true \
		or context.get("source_key") != "waystone:" + intent.waystone_id \
		or context.get("touch_id") != intent.touch_id:
		return deny
	var config: Dictionary = preload("res://scripts/world/waystone.gd").load_config()
	var stone: Dictionary = preload("res://scripts/net/portal_action_policy.gd")._find_stone(config, intent.waystone_id)
	if stone.is_empty() or context.get("realm") != stone.realm_id:
		return deny
	var receipt := "craft:waystone_%s:%s" % [intent.touch_id.sha256_text(), current.character_id]
	if current.redesign_character.transaction_receipts.has(receipt):
		return {"ok": false, "code": "reconcile_original_decision"}
	if current.redesign_character.transaction_receipts.size() >= int(preload("res://scripts/creatures/essence.gd").config().maximum_transaction_receipts):
		return {"ok": false, "code": "transaction_receipt_limit"}
	var next := current.duplicate(true)
	var active: Array = next.redesign_character.waystones_activated.get(stone.biome, []).duplicate()
	if not active.has(stone.id): active.append(stone.id)
	next.redesign_character.waystones_activated[stone.biome] = active
	next.redesign_character.last_waystones[stone.biome] = stone.id
	next.redesign_character.transaction_receipts.append(receipt)
	return {"ok": true, "state": next, "receipt": receipt}
