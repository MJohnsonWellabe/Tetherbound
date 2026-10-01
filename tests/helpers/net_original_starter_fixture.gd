extends RefCounted

## Disclosed combat setup, performed while both peers are still standalone.
## The opening owns the single creature: this supplies movement and UI input,
## then observes the exact party/body UID that must cross later admission.
## No grant, receipt, story flag, private adoption, or authority mutation here.

var _harness: Object


func _check(value: bool, message: String) -> bool:
	_harness.call("check", value, "original starter fixture: " + message)
	return value


func _probe(peer: int, what: String, args: Dictionary = {}) -> Dictionary:
	var value: Variant = await _harness.call("probe", peer, what, args)
	return value if value is Dictionary else {}


func _pair(action: String, arguments: Array, budget: int = -1) -> bool:
	var commands: Array = []
	for peer in 2:
		var command := {"peer": peer, "action": action, "args": arguments[peer]}
		if budget >= 0:
			command["budget_frames"] = budget
		commands.append(command)
	var results: Array = await _harness.call("race", commands)
	var passed := results.size() == 2
	for result: Dictionary in results:
		var verdict: Dictionary = result.get("verdict", {})
		passed = _check(str(verdict.get("verdict", "")) == "PASS",
			"peer %d %s (%s)" % [int(result.get("peer", -1)), action,
			str(verdict.get("detail", ""))]) and passed
	return _check(passed, "both peers completed %s" % action)


func _press(action: String) -> bool:
	return await _pair("press", [{"action": action}, {"action": action}])


func _move(key: String, close_enough: float) -> bool:
	var args: Array = []
	for peer in 2:
		var opening := await _probe(peer, "meadows_opening")
		var raw: Variant = opening.get(key, (opening.get("markers", {}) as Dictionary).get(key, []))
		if not _check(raw is Array and raw.size() == 3,
				"peer %d has the production %s marker" % [peer, key]):
			return false
		args.append({"x": float(raw[0]), "z": float(raw[2]),
			"close_enough": close_enough, "budget_frames": 1200})
	return await _pair("move_to", args, 1200)


func _wait_modal(key: String, attempts: int) -> bool:
	for _attempt in attempts:
		var opened := true
		for peer in 2:
			var opening := await _probe(peer, "meadows_opening")
			opened = bool((opening.get(key, {}) as Dictionary).get("is_open", false)) and opened
		if opened:
			return _check(true, "both real %s panels opened" % key)
		if not await _pair("wait", [{"frames": 2}, {"frames": 2}]):
			return false
	return _check(false, "both real %s panels did not open within %d polls" % [key, attempts])


func _open_briefing() -> bool:
	var pending: Array = []
	for peer in 2:
		var opening := await _probe(peer, "meadows_opening")
		if not bool((opening.get("dialogue", {}) as Dictionary).get("is_open", false)):
			pending.append({"peer": peer, "action": "press", "args": {"action": "interact"}})
	if not pending.is_empty():
		var results: Array = await _harness.call("race", pending)
		for result: Dictionary in results:
			if not _check(str((result.get("verdict", {}) as Dictionary).get("verdict", "")) == "PASS",
					"peer %d opened the real briefing" % int(result.get("peer", -1))):
				return false
	return await _wait_modal("dialogue", 60)


func prepare(harness: Object) -> Array[Dictionary]:
	_harness = harness
	for peer in 2:
		var session := await _probe(peer, "session")
		var owner := await _probe(peer, "original_starter_ownership")
		var opening := await _probe(peer, "meadows_opening")
		if not _check(session.get("available") == true and session.get("active") == false
				and owner.get("party_size", -1) == 0 and owner.get("body_present") == false
				and opening.get("sequence_present") == true,
				"peer %d starts standalone with no existing party or body" % peer):
			return []
	# Same passive markers and physical input as the existing fresh-opening witness.
	if not await _move("bed_prompt", 1.5) or not await _press("interact"):
		return []
	if not await _move("stairs_top", 0.8) or not await _move("stairs_bottom", 0.8):
		return []
	if not await _move("grandpa_prompt", 0.9) or not await _open_briefing():
		return []
	if not await _pair("dismiss_dialogue", [{"presses": 40, "settle": 30}, {"presses": 40, "settle": 30}]):
		return []
	if not await _wait_modal("starter_picker", 120) or not await _press("menu_confirm"):
		return []
	if not await _wait_modal("name_prompt", 120):
		return []
	if not await _pair("wait", [{"frames": 12}, {"frames": 12}]):
		return []
	# Different real names prevent one peer's observation standing in for the other.
	var moved: Dictionary = await _harness.call("step", 1, "press", {"action": "ui_right", "tap_frames": 3})
	if not _check(str(moved.get("verdict", "")) == "PASS", "guest selected its own first letter"):
		return []
	if not await _pair("wait", [{"frames": 12}, {"frames": 12}]) or not await _press("menu_confirm"):
		return []
	var names: Array[String] = []
	for peer in 2:
		var opening := await _probe(peer, "meadows_opening")
		var entry: Dictionary = (opening.get("name_prompt", {}) as Dictionary).get("entry", {})
		names.append(str(entry.get("text", "")))
	if not _check(not names[0].is_empty() and not names[1].is_empty() and names[0] != names[1],
			"each peer typed its own nonempty companion name"):
		return []
	var done := false
	for _attempt in 20:
		var pending: Array = []
		for peer in 2:
			var opening := await _probe(peer, "meadows_opening")
			var entry: Dictionary = (opening.get("name_prompt", {}) as Dictionary).get("entry", {})
			if str(entry.get("cell", "")) != "\n":
				pending.append({"peer": peer, "action": "press", "args": {
					"action": "ui_down" if int(entry.get("row", -1)) < 7 else "ui_right", "tap_frames": 3}})
		if pending.is_empty():
			done = true
			break
		var results: Array = await _harness.call("race", pending)
		for result: Dictionary in results:
			if not _check(str((result.get("verdict", {}) as Dictionary).get("verdict", "")) == "PASS",
					"peer %d moved its real naming cursor" % int(result.get("peer", -1))):
				return []
		if not await _pair("wait", [{"frames": 12}, {"frames": 12}]):
			return []
	if not _check(done, "both naming cursors reached Done within 20 attempts"):
		return []
	if not await _press("menu_confirm"):
		return []
	# The production confirmation awaits ground, registers that instance, and writes its fact.
	for _attempt in 120:
		var owners: Array[Dictionary] = []
		var ready := true
		for peer in 2:
			var owner := await _probe(peer, "original_starter_ownership")
			owners.append(owner)
			ready = owned_original_starter(owner, names[peer]) and ready
		if ready:
			_check(true, "both production original starters own their exact deployed UID before admission")
			return owners
		if not await _pair("wait", [{"frames": 2}, {"frames": 2}]):
			return []
	_check(false, "production original starter ownership did not finish within 120 polls")
	return []


static func owned_original_starter(owner: Dictionary, nickname: String) -> bool:
	var uid := str(owner.get("body_uid", ""))
	return (not uid.is_empty() and owner.get("party_size", -1) == 1
		and owner.get("party_uids", []) == [uid] and owner.get("body_is_owned_instance") == true
		and owner.get("body_present") == true and owner.get("body_ready") == true
		and owner.get("body_species") == "terrapup" and owner.get("body_nickname") == nickname
		and owner.get("starter_granted") == true)


func verify_after_admission(harness: Object, prepared: Array[Dictionary]) -> bool:
	_harness = harness
	if not _check(prepared.size() == 2, "two actual pre-admission ownership rows were retained"):
		return false
	for peer in 2:
		var local := await _probe(peer, "original_starter_ownership")
		var session := await _probe(peer, "session")
		var peer_id := int(session.get("peer_id", 0))
		var admitted := await _probe(0, "original_starter_ownership", {"peer_id": peer_id})
		var uid := str(prepared[peer].get("body_uid", ""))
		if not _check(owned_original_starter(local, str(prepared[peer].get("body_nickname", "")))
				and local.get("body_uid") == uid and peer_id > 0
				and admitted.get("admitted_character_id", "") == local.get("character_id", "")
				and not str(local.get("character_id", "")).is_empty()
				and admitted.get("admitted_party_uids", []) == [uid],
				"peer %d retained that SAME UID in actual party/body and host-admitted roster" % peer):
			return false
	return true
