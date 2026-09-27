extends RefCounted

## Tidewake reward-pocket peer steps for the two-peer proof command
## (`tools/net/run_two_peer_proof.sh`), handed over by `proof_peer_runner.gd`
## beside the shared `proof_steps.gd`. Own file so F13#2's steps never collide
## with other lanes' edits there (the Stormwood lane's pattern).
##
##   water_pocket_claim {pickup_id, tool?, settle?, budget_frames?}
##        Stand this peer's trainer beside the production `WaterPickups` body
##        for authored row `pickup_id` (a teleport: DISCLOSED FIXTURE, the walk
##        itself is tests/smoke_water_pocket_walk_claim.gd), wait until the
##        interaction arbiter offers that body's prompt, and press `interact`
##        once through the peer runner's input edge. With `tool`, the tool is
##        bound to hotbar slot 5 (DISCLOSED FIXTURE; the scenario first puts it
##        in the satchel with `storage_grant`) and equipped by pressing
##        `hotbar_5`. Waits for this character's own receipt. Reports the item
##        gained, the personal receipt, the row's `learn_recipe_flag` and
##        whether the recipe it teaches is known before and after.
##   water_pocket_state {pickup_id, require?}
##        Read-only: this peer's receipt, learned recipe, satchel count of the
##        row's item and whether the body is resident for it. `require` is a
##        subset of `data` that must hold, or the step FAILS.
##   water_pocket_resend {pickup_id}
##        Replays this character's claim as a hand-made request that denies the
##        personal receipt (`personal_claimed: false`), straight to the ledger
##        transport, and reports the host's answer. A repeat must be refused
##        (`already_taken`) and pay nothing.
##
## The claim, grant and refusal are the game's own code (production streamer,
## arbiter, harvest node, LedgerRpc host validation). Nothing here writes a
## flag or an item.

const ACTIONS := ["water_pocket_claim", "water_pocket_state", "water_pocket_resend"]
const RULE := preload("res://scripts/world/water_personal_pickup.gd")
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
const TEACHES := {"water_cordage_recipe_learned": "water_camp_cordage"}
const TOOL_SLOT := 4


static func handles(action: String) -> bool:
	return ACTIONS.has(action)


static func run(tree: SceneTree, action: String, args: Dictionary) -> Dictionary:
	match action:
		"water_pocket_claim":
			return await _claim(tree, args)
		"water_pocket_state":
			return _state(tree, args)
		"water_pocket_resend":
			return await _resend(tree, args)
	return {"verdict": "ERROR", "detail": "proof_steps_tidewake_pockets: unknown action '%s'" % action}


static func _row(id: String) -> Dictionary:
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(RULE.DATA))
	return RULE.personal_row(source as Dictionary, id) if source is Dictionary else {}


static func _service(tree: SceneTree) -> Node:
	return tree.current_scene.get_node_or_null(^"WaterPickups") if tree.current_scene != null else null


static func _snapshot(tree: SceneTree, id: String) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	var row := _row(id)
	var learn := str(row.get("learn_recipe_flag", ""))
	var service := _service(tree)
	var data := {
		"pickup_id": id,
		"character_id": str(game.local.get("character_id")) if game != null else "",
		"item": str(row.get("item_id", "")),
		"count": int(game.inventory.count(str(row.get("item_id", "")))) if game != null else -1,
		"receipt": game != null and bool(game.local.flags.has(RULE.personal_flag(id))),
		"learn_flag": learn,
		"learned": game != null and not learn.is_empty() and bool(game.local.flags.has(learn)),
		"recipe": str(TEACHES.get(learn, "")),
		"recipe_known": game != null and TEACHES.has(learn) and bool(game.recipe_known(str(TEACHES[learn]))),
		"resident": service != null and service.call("node_for", id) != null,
	}
	return data


static func _state(tree: SceneTree, args: Dictionary) -> Dictionary:
	var id := str(args.get("pickup_id", ""))
	if _row(id).is_empty():
		return {"verdict": "ERROR", "detail": "no personal row '%s'" % id, "data": {}}
	var data := _snapshot(tree, id)
	var require: Dictionary = args.get("require", {}) as Dictionary
	for key: Variant in require:
		if not data.has(key) or data[key] != require[key]:
			return {"verdict": "FAIL", "detail": "%s: %s is %s, required %s" % [id, key, str(data.get(key)), str(require[key])], "data": data}
	return {"verdict": "PASS", "detail": str(data), "data": data}


static func _claim(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	var id := str(args.get("pickup_id", ""))
	var row := _row(id)
	var service := _service(tree)
	if game == null or row.is_empty() or service == null:
		return {"verdict": "ERROR", "detail": "needs Game, a personal row '%s' and the Water scene's WaterPickups" % id, "data": {}}
	var before := _snapshot(tree, id)
	if bool(before.receipt):
		return {"verdict": "FAIL", "detail": "%s already claimed by this character" % id, "data": before}
	var at: Array = row.position
	var spot := Vector3(float(at[0]) + 1.0, 0.0, float(at[2]) + 0.6)
	var ground: float = tree.current_scene.call("ground_height_at", spot.x, spot.z)
	await tree.call("_step_teleport", {"at": [spot.x, ground + 0.3, spot.z], "settle": int(args.get("settle", 60))})
	var body: Node3D = null
	for f in 600:
		service.call("refresh")
		body = service.call("node_for", id)
		if body != null:
			break
		await tree.physics_frame
	if body == null:
		return {"verdict": "FAIL", "detail": "%s never became resident beside the trainer" % id, "data": _snapshot(tree, id)}
	var tool := str(args.get("tool", ""))
	if not tool.is_empty():
		if int(game.inventory.count(tool)) < 1 or not bool(game.assign_hotbar(TOOL_SLOT, tool)):
			return {"verdict": "ERROR", "detail": "no %s in the satchel to bind (storage_grant it first)" % tool, "data": _snapshot(tree, id)}
		await _tap(tree, "hotbar_%d" % (TOOL_SLOT + 1))
		for f in 20:
			await tree.physics_frame
		if str(game.equipped_tool) != tool:
			return {"verdict": "FAIL", "detail": "hotbar press did not equip %s (holding '%s')" % [tool, str(game.equipped_tool)], "data": _snapshot(tree, id)}
	var prompt := body.get_node_or_null(^"Interactable")
	var arbiter := tree.get_first_node_in_group("interaction_arbiter")
	var offered := false
	for f in 300:
		if arbiter != null and prompt != null and arbiter.call("winning_provider") == prompt:
			offered = true
			break
		await tree.physics_frame
	if not offered:
		return {"verdict": "FAIL", "detail": "arbiter never offered %s's prompt (winner %s)" % [id, str(arbiter.call("prompt") if arbiter != null else null)], "data": _snapshot(tree, id)}
	await _tap(tree, "interact")
	for f in maxi(60, int(args.get("budget_frames", 600))):
		if bool(game.local.flags.has(RULE.personal_flag(id))):
			break
		await tree.physics_frame
	for f in 30:
		await tree.physics_frame
	service.call("refresh")
	await tree.physics_frame
	var after := _snapshot(tree, id)
	var data := {"before": before, "after": after, "gained": int(after.count) - int(before.count)}
	var ok := bool(after.receipt) and int(data.gained) > 0 and not bool(after.resident)
	if not str(before.learn_flag).is_empty():
		ok = ok and not bool(before.recipe_known) and bool(after.learned) and bool(after.recipe_known)
	return {"verdict": "PASS" if ok else "FAIL", "detail": "%s: +%d %s receipt=%s recipe_known %s -> %s resident_after=%s" % [
		id, int(data.gained), str(after.item), after.receipt, before.recipe_known, after.recipe_known, after.resident], "data": data}


static func _resend(tree: SceneTree, args: Dictionary) -> Dictionary:
	var game := tree.root.get_node_or_null(^"Game")
	var id := str(args.get("pickup_id", ""))
	if game == null or _row(id).is_empty():
		return {"verdict": "ERROR", "detail": "needs Game and a personal row '%s'" % id, "data": {}}
	var before := _snapshot(tree, id)
	var transport := LEDGER_CLAIM.transport(tree.root)
	if transport == null:
		return {"verdict": "ERROR", "detail": "no ledger transport", "data": before}
	var heard := {"code": "", "committed": false}
	var on_refused := func(kind: String, code: String, _reason: String, _detail: Dictionary) -> void:
		if kind == "water_personal_pickup":
			heard.code = code
	var on_delta := func(delta: Dictionary) -> void:
		for op: Dictionary in delta.get("ops", []):
			if str(op.get("id", "")) == RULE.personal_flag(id):
				heard.committed = true
	transport.connect("intent_refused", on_refused)
	transport.connect("delta_applied", on_delta)
	var verdict := LEDGER_CLAIM.submit(tree.root, {"kind": "water_personal_pickup", "realm": "water",
		"pickup_id": id, "personal_claimed": false})
	if not bool(verdict.get("pending", false)):
		heard.code = str(verdict.get("code", ""))
		heard.committed = bool(verdict.get("ok", false))
	else:
		for f in 300:
			if not str(heard.code).is_empty() or bool(heard.committed):
				break
			await tree.physics_frame
	transport.disconnect("intent_refused", on_refused)
	transport.disconnect("delta_applied", on_delta)
	for f in 10:
		await tree.physics_frame
	var after := _snapshot(tree, id)
	var data := {"code": heard.code, "committed": heard.committed, "count_before": before.count, "count_after": after.count}
	var ok := str(heard.code) == "already_taken" and not bool(heard.committed) and int(after.count) == int(before.count)
	return {"verdict": "PASS" if ok else "FAIL", "detail": "%s resend: code=%s committed=%s count %d -> %d" % [
		id, heard.code, heard.committed, int(before.count), int(after.count)], "data": data}


static func _tap(tree: SceneTree, action: String) -> void:
	await tree.call("_press_edge", action, true)
	for f in 2:
		await tree.physics_frame
	await tree.call("_press_edge", action, false)
	for f in 8:
		await tree.physics_frame
