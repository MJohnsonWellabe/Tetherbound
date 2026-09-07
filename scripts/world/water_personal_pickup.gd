extends RefCounted
## Host-only decision helper. Context comes from session/proxy identity, never
## caller-supplied peer/character/position fields. Portable claimed proof remains
## within the existing trusted-character model; same-world receipts are durable.
const DATA := "res://data/config/water_pickups.json"
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const TUNING := "res://data/config/water_swimming.json"
static func personal_flag(id: String) -> String:
	return "water_candy:" + id
static func evaluate(intent: Dictionary, host_context: Dictionary, world_flags: Variant) -> Dictionary:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var id := str(intent.get("pickup_id", ""))
	var selected: Dictionary = {}
	for row: Dictionary in source.get("pickups", []):
		if str(row.id) == id and str(row.get("claim_policy", "")) == "character_once" and str(row.get("category", "")) == "skill_candy":
			selected = row
			break
	if selected.is_empty():
		return _refuse("unknown_pickup", "That Skill Candy is not an authored find.")
	if str(intent.get("realm", "")) != "water" or str(host_context.get("realm", "")) != "water":
		return _refuse("wrong_realm", "Reach this Water island before collecting its Candy.")
	var peer := int(host_context.get("peer", 0))
	var character := str(host_context.get("character_id", ""))
	if peer <= 0 or character.is_empty():
		return _refuse("unknown_character", "Your character is not connected to this world.")
	var position: Variant = host_context.get("position")
	if not position is Vector3 or not position.is_finite():
		return _refuse("missing_position", "Your position is not ready yet.")
	var at: Array = selected.position
	var target := Vector3(float(at[0]), FIELD.new().height_at(float(at[0]), float(at[2])), float(at[2]))
	var trusted_target: Variant = host_context.get("pickup_position")
	if trusted_target is Vector3 and trusted_target.is_finite() and Vector2(trusted_target.x, trusted_target.z).distance_to(Vector2(target.x, target.z)) < 0.01:
		target = trusted_target
	var tuning: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TUNING))
	var radius := float(tuning.get("pickups", {}).get("claim_radius_m", 3.6))
	if not target.is_finite() or position.distance_to(target) > radius:
		return _refuse("too_far", "Move closer to collect this Skill Candy.")
	var proof: Variant = intent.get("personal_claimed", false)
	if not proof is bool:
		return _refuse("malformed", "The character claim could not be checked.")
	var receipt := "water_claim:" + character + ":" + id
	if proof or (world_flags != null and world_flags.has(receipt)):
		return _refuse("already_taken", "This character has already collected this Skill Candy.")
	return {"ok": true, "code": "", "reason": "", "ops": [
		{"op": "flag", "scope": "world", "realm": "water", "id": receipt, "value": true},
		{"op": "flag", "scope": "player", "realm": "water", "id": personal_flag(id), "value": true, "peers": [peer]},
		{"op": "item_grant", "scope": "player", "peers": [peer], "item": str(selected.item_id), "count": int(selected.quantity), "txn_id": receipt}
	]}
static func _refuse(code: String, reason: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": reason, "ops": []}
