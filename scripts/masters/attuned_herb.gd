extends "res://scripts/world/harvest_node.gd"
## Uses the existing harvest presentation, but NOT its generic item/amount
## intent. Foundation re-derives this authored source by ID in the same atomic
## character transaction as every F28 action. Personal claims preserve co-op.
var source_id := ""
var service: Node

func _on_gathered(_equipped_tool: Variant = null) -> void:
	if service != null and service.has_method("submit"):
		service.call("submit", "attuned_gather", {"source_id": source_id}, self)

func _already_taken(game: Node) -> bool:
	if game == null or game.get("local") == null: return false
	var owner: RefCounted = game.get("local")
	var personal: Variant = owner.get("redesign_character")
	if not personal is Dictionary: return false
	return personal.get("transaction_receipts", []).has("craft:%s:attuned:%s" % [str(owner.get("character_id")), source_id])

func _claim_committed(_delta: Dictionary) -> bool:
	# Absolute typed training reconciliation refreshes this node from saved
	# character state; a generic reward delta can never retire a personal herb.
	return false
