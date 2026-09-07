extends "res://tests/test_case.gd"
const RULE := preload("res://scripts/world/water_personal_pickup.gd")
func check(ok: bool, message: String) -> void:
	assert_true(ok, message)
func test_authored_ownership_and_host_proximity() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RULE.DATA))
	var candy_count := 0
	for row: Dictionary in data.pickups:
		var intent := {"pickup_id": row.id, "realm": "water", "personal_claimed": false,
			"item": "forged", "count": 999, "peer": 333, "character_id": "forged"}
		var at: Array = row.position
		var context := {"peer": 7, "character_id": "character-A", "realm": "water", "position": Vector3(at[0], RULE.FIELD.new().height_at(at[0], at[2]), at[2])}
		var result := RULE.evaluate(intent, context, {})
		if str(row.category) != "skill_candy":
			check(not result.ok and result.ops.is_empty(), "Ordinary pickup cannot use personal Candy route")
			continue
		candy_count += 1
		check(result.ok and result.ops.size() == 3, "Authored Candy grants three atomic operations")
		check(result.ops[2].item == row.item_id and result.ops[2].count == row.quantity and result.ops[2].peers == [7], "Caller cannot forge reward or recipient")
		check(result.ops[1].id == RULE.personal_flag(row.id), "Portable personal flag uses fixed authored ID")
		var flags := {str(result.ops[0].id): true}
		context.peer = 9
		check(RULE.evaluate(intent, context, flags).code == "already_taken", "Reconnect with new peer cannot replay same character receipt")
		context.character_id = "character-B"
		check(RULE.evaluate(intent, context, flags).ok, "Second character owns a separate find")
		intent.personal_claimed = true
		check(RULE.evaluate(intent, context, {}).code == "already_taken", "Portable proof prevents second world award")
		intent.personal_claimed = "false"
		check(RULE.evaluate(intent, context, {}).code == "malformed", "Malformed proof refuses")
		intent.personal_claimed = false
		context.position += Vector3(4, 0, 0)
		check(RULE.evaluate(intent, context, {}).code == "too_far", "Host position controls proximity")
		context.position = Vector3(NAN, 0, 0)
		check(RULE.evaluate(intent, context, {}).code == "missing_position", "Nonfinite position refuses")
		context.realm = "stormwood"
		check(RULE.evaluate(intent, context, {}).code == "wrong_realm", "Host realm controls access")
	check(candy_count == 12, "Exactly twelve authored personal Candy finds")
	check(RULE.evaluate({"pickup_id": "forged"}, {}, {}).code == "unknown_pickup", "Unknown ID refuses")
