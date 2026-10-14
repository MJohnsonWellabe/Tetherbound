extends RefCounted

## Ordinary-input Master visit (coordinator progression decision b, 13 Oct):
## travel to a Master, open the real challenge prompt, choose ONE owned
## creature in the production Master panel, win the director's own 1v1 duel,
## then press the recipe chest. Reusable for all five Masters: the calling
## realm piece supplies its own proven movement, interaction, input and combat
## pilot as callables, so this file owns only the Master-specific steps.
##
##   var visit := preload("res://tools/earned_saves/master_visit.gd").new()
##   var result: Dictionary = await visit.run(tree, world, game, {
##       "master_id": "master_t5",
##       "approach": [Vector3...],          # optional waypoints before the Master
##       "travel": func(site: Node3D) -> bool, # optional realm-specific Fly/swim route
##       "walk": func(at: Vector3) -> bool,  # await-able, ordinary stick input
##       "interact": func(prompt: Node3D) -> bool,
##       "tap": func(action: String) -> void,
##       "fight_round": func() -> Dictionary,  # pilots one live round to its end
##       "creature_uid": "",                 # optional; default: highest-level healthy
##       "storage": <script with run(tree, world, game, {keep}) or null>,
##       "rebind": func(world: Node3D) -> bool, # required if storage replaces the caller's scene
##       "chest": true,                      # press the chest after the win
##   })
##   -> {passed, failures, receipts}
## Nothing here grants a win, recipe, item, level or receipt; each result is
## read back from the character's own saved record.
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const SITE_GROUP := &"foundation_master_sites"
const DUEL_FRAME_LIMIT := 36000
const CHEST_FRAMES := 900

var failures: Array[String] = []
var receipts: Array[Dictionary] = []
var _tree: SceneTree
var _world: Node3D
var _game: Node


func run(tree: SceneTree, world: Node3D, game: Node, args: Dictionary) -> Dictionary:
	failures.clear()
	receipts.clear()
	_tree = tree
	_world = world
	_game = game
	var master_id := str(args.get("master_id", ""))
	var definition := BREAKTHROUGH.master(master_id)
	if definition.is_empty():
		return _done(_fail("Unknown Master " + master_id))
	var site := _site(master_id)
	if site == null:
		return _done(_fail("No mounted %s site in the current realm %s" % [master_id, str(game.get("current_realm"))]))
	_receipt("master_site", {"master_id": master_id, "name": str(definition.get("name", "")), "at": str(site.global_position)})
	var travel: Callable = args.get("travel", Callable())
	if travel.is_valid() and not await travel.call(site):
		return _done(_fail("Ordinary travel did not reach " + master_id))
	for point: Vector3 in args.get("approach", []):
		if not await args.walk.call(point):
			return _done(_fail("Ordinary travel did not reach the approach point " + str(point)))
	if not _won(master_id):
		if not await _duel(site, master_id, args):
			return _done(false)
	else:
		_receipt("master_already_won", {"master_id": master_id})
	if bool(args.get("chest", true)) and not await _chest(site, master_id, definition, args):
		return _done(false)
	return _done(true)


func _duel(site: Node3D, master_id: String, args: Dictionary) -> bool:
	var npc := site.get_node_or_null("Master") as Node3D
	var prompt := npc.find_child("Interactable", true, false) as Node3D if npc != null else null
	if prompt == null:
		return _fail("The Master has no challenge prompt")
	if not await args.interact.call(prompt):
		return _fail("The ordinary challenge press was not accepted")
	var panel := await _panel("duel")
	if panel == null:
		return _fail("The challenge did not open the production Master panel in duel mode")
	var wanted := str(args.get("creature_uid", ""))
	var chosen := _choose(wanted)
	if chosen.is_empty():
		return _fail("No healthy owned creature can take the duel")
	# Rows follow the party order; the first enabled row holds focus.
	var rows: Array = []
	for node: Node in (panel.get("_list") as Node).get_children():
		if node is Button and not (node as Button).disabled and str((node as Button).text) != "Back":
			rows.append(node)
	var index := int(chosen.index_in_enabled)
	if index < 0 or index >= rows.size():
		return _fail("The chosen creature has no enabled row in the Master panel")
	for _step in index:
		await args.tap.call("ui_down")
	if _tree.root.gui_get_focus_owner() != rows[index]:
		return _fail("Controller focus did not reach the chosen creature's row")
	await args.tap.call("ui_accept")
	_receipt("duel_choice", {"uid": chosen.uid, "species": chosen.species, "level": chosen.level})
	var manager: Node = _world.get_node_or_null("CombatManager")
	var started := Engine.get_physics_frames()
	var last_active := started
	var rounds: Array = []
	while Engine.get_physics_frames() - started < DUEL_FRAME_LIMIT:
		if _won(master_id):
			break
		if manager != null and bool(manager.call("is_fighting")):
			var round_result: Dictionary = await args.fight_round.call()
			if not _record_round(round_result, rounds):
				return false
			last_active = Engine.get_physics_frames()
			continue
		if Engine.get_physics_frames() - last_active > 180:
			return _fail("The Master duel was refused or ended without a saved win")
		await _tree.physics_frame
	_receipt("duel_rounds", {"rounds": rounds.size(), "results": rounds})
	if not _won(master_id):
		return _fail("The 1v1 duel did not produce this character's saved Master win")
	_receipt("master_win", {"master_id": master_id, "creature_uid": chosen.uid})
	return true


## The Meadows adapter returns passed, Rowan returns ok, and the established
## Cloudreach pilot returns diagnostic outcome/timed_out fields. Preserve
## result-only legacy rounds, but never invoke a failed pilot again while
## waiting for a win that its callback has already said it cannot produce.
func _record_round(result: Dictionary, rounds: Array) -> bool:
	rounds.append(result.duplicate(true))
	if result.get("passed", true) == false or result.get("ok", true) == false \
			or result.get("timed_out", false) == true:
		_receipt("duel_rounds", {"rounds": rounds.size(), "results": rounds.duplicate(true)})
		return _fail("The ordinary-input Master pilot failed: " + JSON.stringify(result))
	return true


func _chest(site: Node3D, master_id: String, definition: Dictionary, args: Dictionary) -> bool:
	var feast_id := str(definition.get("feast_id", ""))
	var departure_realm := str(_game.get("current_realm"))
	for attempt in 2:
		if _recipe(feast_id):
			break
		var prompt := chest_prompt(site)
		if prompt == null:
			return _fail("The Master has no recipe chest prompt")
		if not await args.interact.call(prompt):
			return _fail("The ordinary chest press was not accepted")
		for _frame in CHEST_FRAMES:
			if _recipe(feast_id): break
			await _tree.physics_frame
		if _recipe(feast_id):
			break
		var storage: Variant = args.get("storage")
		if attempt == 0 and storage is Script:
			_receipt("chest_needs_room", {"satchel_free": _free_slots()})
			var trip: Dictionary = await (storage as Script).new().run(_tree, _world, _game, {"keep": ["home_key"]})
			if not bool(trip.get("passed", false)):
				return _fail("The storage trip for the chest kit failed: " + str(trip.get("failures", [])))
			_receipt("storage_return", {"receipts": trip.get("receipts", [])})
			if str(_game.get("current_realm")) != departure_realm:
				return _fail("Storage did not return to the Master's realm")
			var returned_world := _tree.current_scene as Node3D
			if returned_world == null:
				return _fail("Storage returned without a live world")
			if not is_instance_valid(_world) or returned_world != _world:
				var rebind: Callable = args.get("rebind", Callable())
				if not rebind.is_valid() or not await rebind.call(returned_world):
					return _fail("Storage replaced the scene; the caller must rebind its movement and interaction helpers")
			_world = returned_world
			site = _site(master_id)
			if site == null:
				return _fail("Storage returned without the mounted Master site")
			continue
		return _fail("The chest did not teach %s (Satchel free slots %d; the kit needs room)" % [feast_id, _free_slots()])
	_receipt("chest", {"feast_recipe": feast_id, "satchel_free": _free_slots()})
	return true


static func chest_prompt(site: Node3D) -> Node3D:
	if not is_instance_valid(site):
		return null
	var chest := site.get_node_or_null("RecipeChest")
	if chest == null:
		return null
	for node: Node in chest.get_children():
		if node is Node3D and node.has_signal("activated"):
			return node as Node3D
	return null


func _choose(wanted: String) -> Dictionary:
	var party: RefCounted = _game.get("party")
	var best := {}
	var enabled := 0
	for index in int(party.call("size")):
		var member: RefCounted = party.call("at", index)
		if bool(member.get("fainted")) or bool(member.get("resting")):
			continue
		var row := {"uid": str(member.get("uid")), "species": str(member.get("species_id")),
			"level": int(member.get("level")), "index_in_enabled": enabled}
		enabled += 1
		if not wanted.is_empty():
			if row.uid == wanted: return row
		elif best.is_empty() or int(row.level) > int(best.level):
			best = row
	return best


func _panel(mode: String) -> Node:
	for _frame in 180:
		var owner: Node = INPUT_OWNER.current(_tree)
		if owner != null and owner.has_method("is_open") and bool(owner.call("is_open")) and str(owner.get("_mode")) == mode:
			for _settle in 3: await _tree.process_frame
			return owner
		await _tree.process_frame
	return null


func _site(master_id: String) -> Node3D:
	for node: Node in _tree.get_nodes_in_group(SITE_GROUP):
		if node.get("master_id") == master_id and _world.is_ancestor_of(node) and node.get("_mounted") == true:
			return node as Node3D
	return null


func _personal() -> Dictionary:
	var local: Variant = _game.get("local")
	var personal: Variant = (local as Object).get("redesign_character") if local is Object else null
	return personal if personal is Dictionary else {}


func _won(master_id: String) -> bool:
	return (_personal().get("master_wins", []) as Array).has(master_id)


func _recipe(feast_id: String) -> bool:
	return (_personal().get("feast_recipes", []) as Array).has(feast_id)


func _free_slots() -> int:
	var inventory: RefCounted = _game.get("inventory")
	var free := 0
	for i in int(inventory.call("slot_count")):
		if (inventory.call("stack_at", i) as Dictionary).is_empty(): free += 1
	return free


func _receipt(beat: String, detail: Dictionary) -> void:
	detail["beat"] = beat
	receipts.append(detail)
	print("MASTER VISIT — ", JSON.stringify(detail))


func _fail(message: String) -> bool:
	failures.append(message)
	print("MASTER VISIT FAIL — " + message)
	return false


func _done(ok: bool) -> Dictionary:
	return {"passed": ok and failures.is_empty(), "failures": failures.duplicate(), "receipts": receipts.duplicate(true)}
