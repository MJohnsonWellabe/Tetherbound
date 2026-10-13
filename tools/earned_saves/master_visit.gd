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
##       "walk": func(at: Vector3) -> bool,  # await-able, ordinary stick input
##       "interact": func(prompt: Node3D) -> bool,
##       "tap": func(action: String) -> void,
##       "fight_round": func() -> Dictionary,  # pilots one live round to its end
##       "creature_uid": "",                 # optional; default: highest-level healthy
##       "storage": <script with run(tree, world, game, {keep}) or null>,
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
	var rounds: Array = []
	while Engine.get_physics_frames() - started < DUEL_FRAME_LIMIT:
		if _won(master_id):
			break
		if manager != null and bool(manager.call("is_fighting")):
			rounds.append(await args.fight_round.call())
			continue
		await _tree.physics_frame
	_receipt("duel_rounds", {"rounds": rounds.size(), "results": rounds})
	if not _won(master_id):
		return _fail("The 1v1 duel did not produce this character's saved Master win")
	_receipt("master_win", {"master_id": master_id, "creature_uid": chosen.uid})
	return true


func _chest(site: Node3D, master_id: String, definition: Dictionary, args: Dictionary) -> bool:
	var feast_id := str(definition.get("feast_id", ""))
	var chest := site.get_node_or_null("RecipeChest") as Node3D
	var prompt := chest.find_child("*", true, false) as Node3D if chest != null else null
	for node: Node in (chest.get_children() if chest != null else []):
		if node.has_signal("activated"): prompt = node as Node3D
	if prompt == null:
		return _fail("The Master has no recipe chest prompt")
	for attempt in 2:
		if _recipe(feast_id):
			break
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
			continue
		return _fail("The chest did not teach %s (Satchel free slots %d; the kit needs room)" % [feast_id, _free_slots()])
	_receipt("chest", {"feast_recipe": feast_id, "satchel_free": _free_slots()})
	return true


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
