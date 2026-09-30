extends RefCounted

## F32 detached host proposals. These functions cannot authenticate a sender:
## the authority registry supplies trusted outcomes, the actual owned roster,
## host world/day and the existing character receipt map. No request may carry
## an outcome, roster, inventory baseline, day, cost, yield or random roll.
## Foundation commits this with the training care proposal in one character
## transaction, including an empty-output receipt so a miss cannot be rerolled.

const DATA_PATH := "res://data/config/shed_drops.json"


static func read(path: String = DATA_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func _positive_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and float(value) == float(int(value)) and int(value) > 0


static func _profile(config: Dictionary, species: String) -> Dictionary:
	var table: Variant = config.get("species", {})
	if not table is Dictionary:
		return {}
	var raw: Variant = table.get(species)
	if not raw is Dictionary:
		return {}
	var allowed: Variant = config.get("allowed_shed_items")
	if not allowed is Array or not raw.get("item") is String \
			or str(raw["item"]).is_empty() or not allowed.has(raw["item"]) \
			or not _positive_integer(raw.get("wild_amount")) \
			or not _positive_integer(raw.get("den_amount")) or not raw.get("wild_realms") is Array:
		return {}
	return raw.duplicate(true)


## Hash a structured identity to avoid delimiter collisions between realms,
## world instances, encounters, characters and owned creature UIDs.
static func _receipt(kind: String, identity: Array) -> String:
	return "shed:" + kind + ":" + JSON.stringify(identity).sha256_text()


## Trusted outcome shape: world_instance_id, encounter_id, realm, kind=wild,
## won, settled, participants (stable character ids), defeated (uid/species).
## Rolls are host-journalled per defeated UID and this recipient, not client
## RNG; callers use the same rolls when reconciling an interrupted commit.
static func wild_win_candidate(outcome: Dictionary, character_id: String,
		received_receipts: Dictionary, host_rolls: Dictionary, config: Dictionary) -> Dictionary:
	var instance := str(outcome.get("world_instance_id", ""))
	var encounter := str(outcome.get("encounter_id", ""))
	var realm := str(outcome.get("realm", ""))
	var table: Variant = config.get("species")
	if not table is Dictionary:
		return {"ok": false, "code": "invalid_shed_table"}
	var participants: Variant = outcome.get("participants")
	if instance.is_empty() or encounter.is_empty() or character_id.is_empty() \
			or str(outcome.get("kind", "")) != "wild" or outcome.get("won") != true \
			or outcome.get("settled") != true or not participants is Array \
			or not participants.has(character_id):
		return {"ok": false, "code": "not_a_participating_wild_winner"}
	var receipt := _receipt("win", [instance, encounter, character_id])
	if received_receipts.has(receipt):
		return {"ok": false, "code": "already_received", "receipt_id": receipt}
	var chance_value: Variant = config.get("wild_win_chance")
	if not (typeof(chance_value) in [TYPE_INT, TYPE_FLOAT]) or not is_finite(float(chance_value)) \
			or float(chance_value) < 0.0 or float(chance_value) > 1.0:
		return {"ok": false, "code": "invalid_shed_table"}
	var defeated: Variant = outcome.get("defeated")
	if not defeated is Array or defeated.is_empty():
		return {"ok": false, "code": "missing_trusted_defeated_roster"}
	var outputs := {}
	var seen := {}
	for raw: Variant in defeated:
		if not raw is Dictionary:
			return {"ok": false, "code": "invalid_trusted_defeated_roster"}
		var uid := str(raw.get("uid", ""))
		var species := str(raw.get("species", ""))
		if uid.is_empty() or species.is_empty() or seen.has(uid):
			return {"ok": false, "code": "invalid_trusted_defeated_roster"}
		seen[uid] = true
		var profile := _profile(config, species)
		if table.has(species) and profile.is_empty():
			return {"ok": false, "code": "invalid_shed_table"}
		if profile.is_empty() or not (profile["wild_realms"] as Array).has(realm):
			continue
		var roll: Variant = host_rolls.get(uid)
		if not (typeof(roll) in [TYPE_INT, TYPE_FLOAT]) or not is_finite(float(roll)) \
				or float(roll) < 0.0 or float(roll) >= 1.0:
			return {"ok": false, "code": "missing_host_roll"}
		if float(roll) < float(chance_value):
			var item := str(profile["item"])
			outputs[item] = int(outputs.get(item, 0)) + int(profile["wild_amount"])
	return {"ok": true, "receipt_id": receipt, "source": "wild_win",
		"character_id": character_id, "outputs": outputs}


## One manually requested grooming per actual owned UID/host-world day.
## This proposal pays only shed material. The same receipt must cover the
## training care-essence cap/stamp and all inventory outputs atomically.
static func den_groom_candidate(character_id: String, owned_party: Array,
		selected_uid: String, host_world_day: int, world_instance_id: String,
		received_receipts: Dictionary, config: Dictionary) -> Dictionary:
	if character_id.is_empty() or selected_uid.is_empty() or world_instance_id.is_empty() \
			or host_world_day < 1 or owned_party.is_empty() or owned_party.size() > 5:
		return {"ok": false, "code": "invalid_host_groom_context"}
	var policy: Variant = config.get("den_grooming")
	var table: Variant = config.get("species")
	if not table is Dictionary:
		return {"ok": false, "code": "invalid_shed_table"}
	if not policy is Dictionary or policy.get("clock") != "host_world_day" \
			or not bool(policy.get("manual_tap", false)) \
			or not bool(policy.get("once_per_owned_uid_per_day", false)) \
			or bool(policy.get("offline_production", true)) \
			or bool(policy.get("automatic_production", true)) \
			or not bool(policy.get("compose_with_care_essence", false)):
		return {"ok": false, "code": "invalid_shed_table"}
	var selected := {}
	var seen := {}
	for raw: Variant in owned_party:
		if not raw is Dictionary:
			return {"ok": false, "code": "invalid_owned_roster"}
		var uid := str(raw.get("uid", ""))
		if uid.is_empty() or seen.has(uid):
			return {"ok": false, "code": "invalid_owned_roster"}
		seen[uid] = true
		if uid == selected_uid:
			selected = raw.duplicate(true)
	if selected.is_empty():
		return {"ok": false, "code": "not_owned"}
	var receipt := _receipt("groom", [world_instance_id, character_id, host_world_day, selected_uid])
	if received_receipts.has(receipt):
		return {"ok": false, "code": "already_groomed", "receipt_id": receipt}
	var profile := _profile(config, str(selected.get("species", "")))
	if table.has(str(selected.get("species", ""))) and profile.is_empty():
		return {"ok": false, "code": "invalid_shed_table"}
	var outputs := {}
	if not profile.is_empty():
		outputs[str(profile["item"])] = int(profile["den_amount"])
	return {"ok": true, "receipt_id": receipt, "source": "den_groom",
		"character_id": character_id, "creature_uid": selected_uid,
		"host_world_day": host_world_day, "outputs": outputs}
