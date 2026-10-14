extends "res://tests/helpers/stormwood_crown_build_segment.gd"

## Reuse the established Stormwood walker, exact prompt activation and duel
## pilot without the Crown-construction-only unbuilt-footing precondition.
var chest_only := false
var master_receipts: Array = []

func _init() -> void:
	stage = "rowan"

func _preconditions_hold() -> bool:
	if _tree == null or _world == null or _game == null or _player == null \
			or _camera == null or _arbiter == null or _manager == null or _director == null:
		return _fail("Rowan requires the live production world and ordinary services")
	if str(_game.current_realm) != "stormwood" or not bool(_world.call("shell_build_complete")):
		return _fail("Rowan requires the ready Stormwood realm")
	if bool(_game.get("free_build")) or str(_game.get("pending_build")) != "" \
			or not _player.is_on_floor() or not bool(_player.call("locomotion_enabled")) \
			or INPUT_OWNER.current(_tree) != null or _game.get("pending_catch") != null:
		return _fail("Rowan requires grounded ordinary input outside Build mode")
	var members: Array = _game.get("party").call("members")
	var seen := {}
	for member: RefCounted in members:
		var uid := str(member.get("uid"))
		if uid.is_empty() or seen.has(uid): return _fail("Rowan requires unique retained companions")
		seen[uid] = true
	if members.size() != 5: return _fail("Rowan requires the retained five")
	if chest_only and not _game.local.redesign_character.get("master_wins", []).has(ROWAN):
		return _fail("Rowan chest requires the saved duel win")
	return true

func _rowan_visit() -> Dictionary:
	if not chest_only: return await super._rowan_visit()
	var visit: RefCounted = load("res://tools/earned_saves/master_visit.gd").new()
	var outcome: Dictionary = await visit.run(_tree, _world, _game, {
		"master_id": ROWAN,
		"travel": func(site: Node3D) -> bool:
			return _player.global_position.distance_to(site.global_position) < 30.0,
		"interact": func(prompt: Node3D) -> bool: return await _activate_exact(prompt.get_parent() as Node3D, prompt,
			Vector2(prompt.global_position.x, prompt.global_position.z) + Vector2(0.0, -1.2), "Rowan's recipe chest"),
		"tap": func(action: String) -> void: await _tap(StringName(action)),
		"chest": true,
	})
	master_receipts = outcome.get("receipts", []).duplicate(true)
	for line: Variant in outcome.get("failures", []): _fail("Rowan chest: " + str(line))
	if not bool(outcome.get("passed", false)) and failures.is_empty(): _fail("Rowan chest did not complete")
	return result()

func result() -> Dictionary:
	var value := super.result()
	value["receipts"] = master_receipts.duplicate(true)
	if chest_only and bool(value.get("passed", false)) \
			and not _game.local.redesign_character.get("feast_recipes", []).has("feast_t5"):
		value["passed"] = false
		value["failures"] = value.get("failures", []) + ["Rowan chest did not retain feast_t5"]
	return value
