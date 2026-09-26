extends RefCounted

## Saved-completion leg shared by the six F13 Tidewake chain smokes
## (ACCEPTANCE §5 "saved completion"). Writes the finished chain through the
## production `Game.save_game(slot)` -- world half (chain records, world-once
## seams, per-character world receipts) and character half (satchel, party,
## personal receipts) -- destroys the live Water world, resets Game to a fresh
## `reset_for_new_game()` state, then `Game.load_game(slot)` and builds a new
## production Water scene: the title-screen Continue order.
## The caller re-fetches every scene node from the returned world.
const SAVE := preload("res://scripts/save/save_game.gd")
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SLOT := 1

## Point Game at an isolated production SaveGame directory (same class and
## format as the shipped one), so a run never touches another run's slots.
static func isolate(game: Node, tag: String) -> void:
	game.save_system = SAVE.new("user://%s_%d/" % [tag, Time.get_ticks_usec()])


## Returns {"world": Node3D or null, "checks": Array of [bool, String]}.
## `cleared_world_flag` / `cleared_item` must be live before the save; the reset
## must drop them (proving the reload, not the old memory, restores them).
static func save_and_reload(tree: SceneTree, game: Node, world: Node3D,
		cleared_world_flag: String, cleared_item: String) -> Dictionary:
	var out: Array = []
	var character_id := str(game.local.character_id)
	var saved := bool(game.save_game(SLOT))
	out.append([saved, "Completed chain saved through production Game.save_game(%d)" % SLOT])
	if not saved:
		return {"world": null, "checks": out}
	var old: WeakRef = weakref(world)
	tree.current_scene = null
	world.queue_free()
	await tree.process_frame
	await tree.process_frame
	out.append([old.get_ref() == null, "Previous Water world destroyed before the reload"])
	game.reset_for_new_game()
	out.append([not game.world.flags.has(cleared_world_flag) \
		and (cleared_item.is_empty() or int(game.inventory.count(cleared_item)) == 0),
		"Fresh reset_for_new_game state holds none of the chain's results"])
	var loaded := bool(game.load_game(SLOT))
	out.append([loaded, "Production Game.load_game(%d) restores the save" % SLOT])
	if not loaded:
		return {"world": null, "checks": out}
	out.append([str(game.local.character_id) == character_id and str(game.current_realm) == "water",
		"Reload resumes the same character in Water"])
	var fresh: Node3D = WORLD.instantiate()
	tree.root.add_child(fresh)
	tree.current_scene = fresh
	for frame in 900:
		await tree.process_frame
		if fresh.shell_build_complete():
			break
	var built := bool(fresh.shell_build_complete())
	out.append([built, "Fresh production Water world rebuilt from the loaded save"])
	return {"world": fresh if built else null, "checks": out}


## Positive streaming control for a "does not respawn" check: some other
## Water pickup or harvest row within 100 m of `at` (inside the 140 m
## residency radius) is resident, so an absent `exclude` is not just unstreamed.
static func neighbour_resident(pickups: Node, at: Vector3, exclude: String) -> bool:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	for key: String in ["pickups", "harvest"]:
		for row: Dictionary in data.get(key, []):
			var p: Array = row.position
			if str(row.id) != exclude and Vector2(float(p[0]) - at.x, float(p[2]) - at.z).length() <= 100.0 \
					and pickups.call("node_for", str(row.id)) != null:
				return true
	return false
