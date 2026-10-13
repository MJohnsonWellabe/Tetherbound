extends "res://tests/helpers/meadows_earned_camp_segment.gd"

## Earned-chain homestead side of the Master/feast loop (TRAINING §2–§4,
## HOMESTEAD; CARD:M2). Ordinary input only, through the production surfaces:
## the Satchel's Home Key, the build catalogue (paid, `free_build` off), the
## Storage Chest panel, the Forge's refining channel, the Kitchen's station
## panel and the Breakthrough cook/feed chooser. Nothing is granted, set or
## healed directly; every result is read back from the owner's own record.
##
## The three wrappers expose `run(tree, world, game, args)` and return keys the chain
## runner's `_take` reads ({passed, failures, transcript}). `args.step` is one of:
##   "storage_trip": {keep: [item ids], return: bool = true}
##       Home Key → (gather wood if short) → a Storage Chest on the plot →
##       store every stack not in `keep` → the Hall's home arch back to the
##       last activated Meadows waystone, then walk to the departure point.
##   "kitchen": {station_tier: int = 1}
##       At the homestead: Forge (if absent) → refine the attachment's ingots →
##       Kitchen (if absent) → its tier attachments up to `station_tier`.
##   "cook_feed": {feast_id: "feast_t1", choices: {uid: "evolve"|"stay"}}
##       Cook one matching feast per creature now at that tier's cap, then feed
##       each through the Breakthrough chooser. Creatures below the cap are
##       reported as deferred, not failed (they are fed when they reach it).
const TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
const GATHER := preload("res://tests/helpers/meadows_earned_material_segment.gd")
const STATION_RULES := preload("res://scripts/build/station_rules.gd")
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const RECORD_RULES := preload("res://scripts/net/character_record_rules.gd")
const STORAGE_PANEL := preload("res://scripts/ui/storage_panel.gd")
## The homestead plot (stations.json homestead_plot: centre [-4, 19], 40 x 30 m)
## minus its exclusions. Candidate build spots, tried in order.
const PLOT_SPOTS: Array[Vector2] = [Vector2(-16.0, 28.0), Vector2(-8.0, 30.0), Vector2(-18.0, 20.0),
	Vector2(-12.0, 24.0), Vector2(10.0, 28.0), Vector2(12.0, 22.0), Vector2(-20.0, 8.0), Vector2(-14.0, 6.0)]
const PLOT_CENTRE := Vector2(-4.0, 19.0)
const AT_HOME_M := 40.0
const FOCUS_STEPS := 80
const SETTLE_TX_FRAMES := 900
const REFINE_FRAMES := 7200
var receipts: Array = []
var _travel: RefCounted
var _used_spots: Array[Vector2] = []


func run_step(tree: SceneTree, world: Node3D, game: Node, args: Dictionary) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_progression = game.get("progression")
	_party = game.get("party")
	if _player == null or _rig == null or bool(game.get("free_build")) or not _collect_nodes():
		_fail("The homestead loop needs the live player, camera, paid building and world nodes")
		return _out()
	_resolve_move_bindings()
	_travel = TRAVEL.new(tree, game)
	var ok := false
	match str(args.get("step", "")):
		"storage_trip": ok = await storage_trip(args.get("keep", []), bool(args.get("return", true)))
		"kitchen": ok = await kitchen(int(args.get("station_tier", 1)))
		"cook_feed": ok = await cook_feed(str(args.get("feast_id", "")), args.get("choices", {}))
		_: _fail("Unknown homestead step: " + str(args.get("step", "")))
	if not ok and failures.is_empty():
		_fail("The homestead step stopped without a reason: " + str(args.get("step", "")))
	return _out()


func _out() -> Dictionary:
	var out := _result()
	out["receipts"] = receipts.duplicate(true)
	return out


# ---------------------------------------------------------------- storage --

func storage_trip(keep: Array, come_back: bool) -> bool:
	var departure := _player.global_position
	var departure_realm := str(_game.get("current_realm"))
	if come_back and departure_realm != "meadows":
		return _fail_b("The storage return route currently requires a Meadows departure")
	keep = keep.duplicate()
	for required: String in ["axe", "pickaxe", "knife", "hammer", "home_key"]:
		if not keep.has(required):
			keep.append(required)
	if not await _go_home():
		return false
	var chest := _placed("storage")
	if chest == null:
		if not await _fund({"storage": 1}):
			return false
		chest = await _place_on_plot("storage")
		if chest == null:
			return false
	var prompt := chest.get_node_or_null("Interactable") as Node3D
	if prompt == null or not await _walk_to_prompt(prompt, "Storage Chest"):
		return _fail_b("The Storage Chest's Open prompt was not reached")
	var before := _stacks()
	await _tap(&"interact")
	var panel := await _owner_of(STORAGE_PANEL)
	if panel == null or panel.get("_chest") != chest:
		return _fail_b("Interact did not open the intended Storage Chest panel")
	var stored: Array[String] = []
	var transfers: Array[Dictionary] = []
	for _round in 64:
		var ids := _deposit_ids()
		var index := -1
		for i in ids.size():
			if not keep.has(ids[i]):
				index = i
				break
		if index < 0:
			break
		var rows: Array = panel.get("_deposit_rows")
		if index >= rows.size() or not await _focus(panel, rows[index] as Control):
			return _fail_b("Controller focus could not reach the Satchel row for " + ids[index])
		var count := int(_game.get("inventory").call("count", ids[index]))
		var chest_before := _chest_count(chest, ids[index])
		await _tap(&"ui_accept")
		if not await _until(func() -> bool: return storage_transfer_matches(count, _count(ids[index]), chest_before, _chest_count(chest, ids[index]))):
			return _fail_b("Storing %s was not saved (%s)" % [ids[index], str((panel.get("_message") as Label).text) if panel.get("_message") is Label else ""])
		stored.append(ids[index])
		transfers.append({"item": ids[index], "bag_before": count, "bag_after": _count(ids[index]),
			"chest_before": chest_before, "chest_after": _chest_count(chest, ids[index])})
	for item: String in _deposit_ids():
		if not keep.has(item):
			return _fail_b("Storage stopped with an unstored stack: " + item)
	for item: Variant in keep:
		if _count(str(item)) != int(before.get(str(item), 0)):
			return _fail_b("Storage changed a protected stack: " + str(item))
	await _tap(&"menu_cancel")
	if not await _until(func() -> bool: return INPUT_OWNER.current(_tree) == null):
		return _fail_b("Cancel did not close the Storage Chest panel")
	_receipt("storage_trip", {"stored": stored, "kept": keep, "stacks_before": before, "stacks_after": _stacks(),
		"free_slots": _free_slots(), "transfers": transfers, "chest_uid": str(chest.get_meta("building_uid", ""))})
	if come_back:
		if not await _home_arch():
			return false
		return await _walk_to(departure, "storage departure", 2.0)
	return true


static func storage_transfer_matches(bag_before: int, bag_after: int, chest_before: int, chest_after: int) -> bool:
	return (mini(mini(bag_before, bag_after), mini(chest_before, chest_after)) >= 0
		and bag_before > bag_after
		and chest_after - chest_before == bag_before - bag_after)

func _chest_count(chest: Node3D, item: String) -> int:
	var state: RefCounted = chest.get("state")
	var inventory: RefCounted = state.get("inventory") if state != null else null
	return int(inventory.call("count", item)) if inventory != null else -1


# ---------------------------------------------------------------- kitchen --

func kitchen(station_tier: int) -> bool:
	if not await _go_home():
		return false
	var cfg := STATION_RULES.config()
	var tiers: Array = []
	for row: Dictionary in cfg.get("attachments", []):
		if str(row.get("station_id")) == "kitchen" and int(row.get("tier", 0)) <= station_tier and str(row.get("status")) == "live":
			tiers.append(row)
	tiers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.tier) < int(b.tier))
	if tiers.size() != station_tier:
		return _fail_b("The Kitchen has no live attachment for every tier up to %d" % station_tier)
	var kitchen := _placed("kitchen")
	if kitchen == null:
		if not await _fund({"kitchen": 1}):
			return false
		kitchen = await _place_on_plot("kitchen")
		if kitchen == null:
			return false
	for row: Dictionary in tiers:
		if _kitchen_tier(kitchen) >= int(row.tier):
			continue
		# Ingots are refined at the Forge (their cost's source_hint).
		for cost: Dictionary in row.get("cost", []):
			if not _forge_recipe(str(cost.get("id", ""))).is_empty() and _count(str(cost.id)) < int(cost.n):
				if not await _refine(str(cost.id), int(cost.n) - _count(str(cost.id))):
					return false
		if not await _fund({str(row.id): 1}):
			return false
		var attached := await _place_near(str(row.id), kitchen)
		if attached == null:
			return false
		if not await _until(func() -> bool: return _kitchen_tier(kitchen) >= int(row.tier)):
			return _fail_b("The %s did not raise the Kitchen to tier %d" % [row.id, row.tier])
		_receipt("kitchen_tier", {"attachment": row.id, "tier": _kitchen_tier(kitchen)})
	return true


func _kitchen_tier(kitchen: Node3D) -> int:
	var uid := str(kitchen.get_meta("building_uid", ""))
	var tier: Dictionary = STATION_RULES.effective_tier(STATION_RULES.config(), _game.get("placed_buildings"), uid)
	return int(tier.get("effective_tier", 0)) if tier.get("ok") == true else 0


## The Forge's tap-start channel: open the Forge, set the units, start, and
## stand beside it until every unit has landed in the Satchel.
func _refine(item: String, units: int) -> bool:
	var maximum := int(STATION_RULES.config().forge.maximum_manual_units)
	if units < 1 or units > maximum:
		return _fail_b("Refining request is outside the Forge's manual-unit limit")
	var forge := _placed("forge")
	if forge == null:
		if not await _fund({"forge": 1}):
			return false
		forge = await _place_on_plot("forge")
		if forge == null:
			return false
	var recipe := _forge_recipe(item)
	if recipe.is_empty():
		return _fail_b("No Forge recipe refines " + item)
	var need := {}
	for cost: Dictionary in recipe.get("cost", []):
		need[str(cost.id)] = int(cost.n) * units
	if not await _gather(need):
		return false
	var target := _count(item) + units
	var panel := await _open_station(forge, "Forge")
	if panel == null:
		return false
	# The production panel remembers the prior channel's amount across opens.
	# Read its displayed state and adjust with input; never assume it reset to 1.
	for _adjust in maximum:
		var shown := int(panel.get("_refining_amount"))
		if shown == units:
			break
		if not await _press(panel, "More refining units" if shown < units else "Fewer refining units"):
			return false
	if int(panel.get("_refining_amount")) != units:
		return _fail_b("The Forge amount controls did not select the requested units")
	if not await _press(panel, "Refine " + str(recipe.get("name", item))):
		return false
	if not await _until(func() -> bool: return _count(item) >= target, REFINE_FRAMES):
		return _fail_b("The Forge channel did not refine %d %s (have %d)" % [units, item, _count(item)])
	_receipt("refined", {"item": item, "units": units, "count": _count(item)})
	# Starting the channel already closes the Forge. Another Cancel here would
	# act on world input (and can open a different menu).
	if not await _until(func() -> bool: return INPUT_OWNER.current(_tree) == null):
		return _fail_b("The Forge channel did not return ordinary world input")
	return true


func _forge_recipe(item: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/recipes/recipes_forge.json"))
	if not raw is Dictionary:
		return {}
	for id: String in raw.get("recipes", {}):
		var row: Dictionary = raw.recipes[id]
		if str((row.get("output", {}) as Dictionary).get("id", "")) == item:
			return row
	return {}


# -------------------------------------------------------------- cook/feed --

func cook_feed(feast_id: String, choices: Dictionary) -> bool:
	if not await _go_home():
		return false
	var state := _view()
	if not (state.get("redesign_character", {}).get("feast_recipes", []) as Array).has(feast_id):
		return _fail_b("The character has not learned %s from its Master chest" % feast_id)
	var kitchen := _placed("kitchen")
	if kitchen == null:
		return _fail_b("There is no Kitchen on the homestead plot")
	var plan := _feed_plan(feast_id, choices)
	_receipt("feed_plan", plan)
	if not failures.is_empty():
		return false
	if (plan.feed as Array).is_empty():
		return _fail_b("No owned creature has a matching feast at its current cap")
	var needed := {}
	var planned := {}
	for row: Dictionary in plan.feed:
		var item := str(row.item)
		planned[item] = int(planned.get(item, 0)) + 1
		if int(planned[item]) <= _count(item):
			continue
		var recipe: Dictionary = BREAKTHROUGH.feasts().recipes[row.recipe]
		for ingredient: String in recipe.cost:
			needed[ingredient] = int(needed.get(ingredient, 0)) + int(recipe.cost[ingredient])
	if not await _gather(needed):
		return false
	var panel := await _open_station(kitchen, "Kitchen")
	if panel == null or not await _press(panel, "Cook learned Ascension Feasts"):
		return false
	var chooser := await _owner_with_mode("cook")
	if chooser == null:
		return _fail_b("The Kitchen did not open the Ascension Feast cook list")
	for row: Dictionary in plan.feed:
		var item := str(row.item)
		var have := _count(item)
		if have > _wanted(plan.feed, item) - 1:
			continue
		if not await _press(chooser, str(row.recipe_name) + " · "):
			return false
		if not await _until(func() -> bool: return _count(item) > have):
			return _fail_b("Cooking %s was not saved (%s)" % [item, str(chooser.get("_message").text)])
		_receipt("cooked", {"recipe": row.recipe, "count": _count(item)})
	if not await _press(chooser, "Feed creatures"):
		return false
	chooser = await _owner_with_mode("feed")
	if chooser == null:
		return _fail_b("Feed creatures did not open the feed chooser")
	for row: Dictionary in plan.feed:
		var uid := str(row.uid)
		var label := feed_label(row)
		var before := _breakthroughs(uid)
		var feast_before := _count(str(row.item))
		var species_before := _species(uid)
		if not await _press(chooser, label, func(text: String) -> bool: return text == label):
			return false
		if not await _until(func() -> bool: return _breakthroughs(uid).size() > before.size()):
			return _fail_b("Feeding %s was not saved (%s)" % [uid, str(chooser.get("_message").text)])
		if _count(str(row.item)) != feast_before - 1:
			return _fail_b("Feeding did not consume exactly one feast for " + uid)
		var expected_species := str(row.target) if row.choice == "evolve" else species_before
		if _species(uid) != expected_species:
			return _fail_b("The saved evolution choice did not preserve the expected species for " + uid)
		_receipt("fed", {"uid": uid, "feast": row.item, "choice": row.choice, "breakthroughs": _breakthroughs(uid),
			"species": _species(uid)})
	await _tap(&"ui_cancel")
	if not await _until(func() -> bool: return INPUT_OWNER.current(_tree) == null):
		return _fail_b("Cancel did not close the feed chooser")
	return true


## Exact production feed label, including the specific feast or destination.
## Never accept nickname prefixes or a generic Evolve suffix.
static func feed_label(row: Dictionary) -> String:
	var label := "%s · %s" % [str(row.nickname), str(row.status)]
	if str(row.choice) == "evolve":
		return label + " · Evolve to " + str(row.target)
	label += " · " + str(row.item_name)
	if bool(row.choice_required):
		label += " · Stay (permanent this tier)"
	return label


func _wanted(feed: Array, item: String) -> int:
	return feed.filter(func(row: Dictionary) -> bool: return row.item == item).size()


## Each creature at the tier's cap gets the recipe matching one of its types
## (the evolve branch's catalyst recipe only when chosen). Others are deferred.
func _feed_plan(feast_id: String, choices: Dictionary) -> Dictionary:
	var feasts: Dictionary = BREAKTHROUGH.feasts()
	var state := _view()
	var mirrors: Dictionary = state.get("redesign_character", {}).get("creatures", {})
	var names := {}
	var owned := {}
	for card: Dictionary in state.get("party", []):
		var nickname := str(card.get("nickname", card.species_id))
		names[nickname] = int(names.get(nickname, 0)) + 1
		owned[str(card.uid)] = true
	for uid: Variant in choices:
		if not owned.has(str(uid)):
			_fail("Evolution choice names a creature outside the current party: " + str(uid))
	var feed: Array = []
	var deferred: Array = []
	for card: Dictionary in state.get("party", []):
		var uid := str(card.uid)
		var choice := str(choices.get(uid, "stay"))
		if choice not in ["stay", "evolve"]:
			_fail("Unknown evolution choice for " + uid)
			continue
		var picked := {}
		var at_requested_cap := false
		for id: String in feasts.get("recipes", {}):
			var recipe: Dictionary = feasts.recipes[id]
			if str(recipe.feast_id) != feast_id:
				continue
			var item := str((recipe.output as Dictionary).keys()[0])
			var def: Dictionary = feasts.get("items", {}).get(item, {})
			if not BREAKTHROUGH_PANEL.feast_matches_current_cap(card, mirrors.get(uid, {}), def):
				continue
			at_requested_cap = true
			if not ESSENCE._species_types(card).has(str(recipe.attuned_type)):
				continue
			var planning := card.duplicate(true)
			planning.evolution_choices = mirrors.get(uid, {}).get("evolution_choices", {}).duplicate(true)
			var offer := EVOLUTION.feast_offer(planning, int(def.tier))
			var catalyst := str(recipe.get("catalyst", ""))
			var target := ""
			if choice == "evolve":
				for branch: Dictionary in offer.get("branches", []):
					if str(branch.get("extra_ingredient", "")) == catalyst:
						target = str(branch.target)
						break
				if target.is_empty():
					continue
			elif not catalyst.is_empty():
				continue
			picked = {"target": target, "uid": uid, "nickname": str(card.get("nickname", card.species_id)), "recipe": id,
				"recipe_name": str(recipe.name), "item": item, "item_name": str(def.name), "choice": choice,
				"status": BREAKTHROUGH.status(card, mirrors.get(uid, {})),
				"choice_required": bool(offer.get("choice_required", false))}
			break
		if picked.is_empty():
			if at_requested_cap:
				_fail("No valid %s feast choice at the requested cap for %s" % [choice, uid])
				continue
			deferred.append({"uid": uid, "level": int(card.get("level", 0)), "types": ESSENCE._species_types(card)})
		else:
			# The production list does not expose a UID in its visible label.
			# Refuse ambiguity before cooking or irreversible feeding.
			if int(names.get(str(picked.nickname), 0)) != 1:
				_fail("Feed chooser nickname is not unique: " + str(picked.nickname))
				continue
			feed.append(picked)
	return {"feast_id": feast_id, "feed": feed, "deferred": deferred}


const BREAKTHROUGH_PANEL := preload("res://scripts/masters/breakthrough_panel.gd")
const EVOLUTION := preload("res://scripts/creatures/evolution.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")


func _view() -> Dictionary:
	var service := _tree.root.get_node_or_null(^"Game/Session/FoundationComposition/BreakthroughService")
	var state: Variant = service.call("view") if service != null else {}
	return state if state is Dictionary else {}


func _breakthroughs(uid: String) -> Array:
	var local: RefCounted = _game.get("local")
	var record: Dictionary = RECORD_RULES.portable_projection(local.call("save_data")) if local != null else {}
	return ((record.get("redesign_character", {}).get("creatures", {}) as Dictionary).get(uid, {}) as Dictionary) \
		.get("breakthroughs", []).duplicate()


func _species(uid: String) -> String:
	for member: RefCounted in _party.call("members"):
		if str(member.get("uid")) == uid:
			return str(member.get("species_id"))
	return ""


# ----------------------------------------------------------------- travel --

func _at_home() -> bool:
	return str(_game.get("current_realm")) == "meadows" \
		and Vector2(_player.global_position.x, _player.global_position.z).distance_to(PLOT_CENTRE) <= AT_HOME_M


func _go_home() -> bool:
	if not _at_home():
		var far := Vector2(_player.global_position.x, _player.global_position.z).distance_to(PLOT_CENTRE)
		if not await _travel.home_key():
			failures.append_array(_travel.failures)
			return false
		_rebind()
		_receipt("home_key", {"from_m": far, "landed": _player.global_position})
	var centre := Vector3(PLOT_CENTRE.x, float(_world.call("ground_height_at", PLOT_CENTRE.x, PLOT_CENTRE.y)), PLOT_CENTRE.y)
	if not await _walk_to(centre + Vector3(-10.0, 0.0, 8.0), "the homestead plot", 3.0):
		return _fail_b("Ordinary movement did not reach the homestead plot")
	return true


## The Crossing Hall's home arch returns to the last activated Meadows waystone.
func _home_arch() -> bool:
	var arch: Node3D
	for candidate: Node in _tree.get_nodes_in_group("portal_arches"):
		if candidate.get("arch_id") == "home":
			arch = candidate as Node3D
	if arch == null:
		return _fail_b("The Crossing Hall has no live home arch")
	var at := _player.global_position
	if not await _travel.activate(arch.get_node_or_null("Interactable") as Node3D):
		failures.append_array(_travel.failures)
		return false
	if not await _until(func() -> bool:
			var player := _tree.current_scene.get_node_or_null("Player") as Node3D if _tree.current_scene != null else null
			return player != null and player.global_position.distance_to(at) > 60.0 and INPUT_OWNER.current(_tree) == null, 7200):
		return _fail_b("The home arch did not return the player to a Meadows waystone")
	_rebind()
	_receipt("home_arch", {"landed": _player.global_position})
	return true


func _rebind() -> void:
	_world = _tree.current_scene as Node3D
	_player = _world.get_node_or_null("Player") as CharacterBody3D
	_rig = _world.get_node_or_null("CameraRig") as Node3D
	_nav = null
	_collect_nodes()


# ---------------------------------------------------------------- building --

func _placed(id: String) -> Node3D:
	for node: Node in _tree.get_nodes_in_group(&"placed_building"):
		if str(node.get_meta("building_id", "")) == id and node is Node3D:
			return node as Node3D
	return null


## Pay for `pieces` (building ids → count) from the Satchel, gathering what is
## short with the production gathering route.
func _fund(pieces: Dictionary) -> bool:
	var need := {}
	for id: String in pieces:
		for requirement: Dictionary in _game.call("build_cost_for", id):
			need[str(requirement.id)] = int(need.get(str(requirement.id), 0)) + int(requirement.n) * int(pieces[id])
	if need.is_empty():
		return _fail_b("No payable catalogue cost for " + str(pieces.keys()))
	return await _gather(need)


func _gather(need: Dictionary) -> bool:
	var short := {}
	for item: String in need:
		if _count(item) < int(need[item]):
			short[item] = int(need[item])
	if short.is_empty():
		return true
	_receipt("gather", {"need": need, "short": short})
	var gather := GATHER.new()
	gather.stock_override = short
	var back := _player.global_position
	gather.return_to = back
	var result: Dictionary = await gather.run(_tree, _world, _game, _player, _rig, false)
	transcript.append_array(result.get("transcript", []))
	if result.get("passed") != true:
		failures.append_array(result.get("failures", []))
		return false
	return true


func _place_on_plot(id: String) -> Node3D:
	for spot: Vector2 in PLOT_SPOTS:
		if _used_spots.has(spot) or _occupied(spot):
			continue
		var placed := await _place_at(id, spot)
		if placed != null:
			_used_spots.append(spot)
			return placed
		if not failures.is_empty():
			return null
	_fail("No plot spot took a green %s ghost" % id)
	return null


func _place_near(id: String, parent: Node3D) -> Node3D:
	# The ghost snaps to the parent's tier socket from anywhere within reach.
	for offset: Vector2 in [Vector2(2.5, 0.0), Vector2(-2.5, 0.0), Vector2(0.0, 2.5), Vector2(0.0, -2.5)]:
		var placed := await _place_at(id, Vector2(parent.global_position.x, parent.global_position.z) + offset)
		if placed != null or not failures.is_empty():
			return placed
	_fail("No stance near the %s took a green %s ghost" % [parent.get_meta("building_id", ""), id])
	return null


func _occupied(spot: Vector2) -> bool:
	for node: Node in _tree.get_nodes_in_group(&"placed_building"):
		if node is Node3D and Vector2((node as Node3D).global_position.x, (node as Node3D).global_position.z).distance_to(spot) < 3.0:
			return true
	return false


## gate_b's `_place_fixture` at an explicit spot, with the camp segment's
## exact-payment and saved-record checks.
func _place_at(id: String, at: Vector2) -> Node3D:
	var before := _cost_snapshot(id)
	var target := Vector3(at.x, _player.global_position.y, at.y)
	if not await _stow_piece():
		return null
	if not await _walk_to(target - _forward() * PLACE_AHEAD, "%s stance at %s" % [id, at], MOVE_EPSILON, true, false):
		transcript.append("%s stance at %s unreachable" % [id, at])
		return null
	if not await _select_piece(id):
		return null
	await _settle(10)
	var placer := _tree.get_first_node_in_group(&"build_placer")
	if placer == null:
		_fail("no BuildPlacer in the world")
		return null
	if not bool(placer.get("_ghost_ok")):
		transcript.append("%s ghost is red at %s" % [id, at])
		await _stow_piece()
		return null
	var existing: Array[Node] = _tree.get_nodes_in_group(&"placed_building")
	await _tap(&"build_place")
	await _settle(12)
	for node: Node in _tree.get_nodes_in_group(&"placed_building"):
		if not existing.has(node) and str(node.get_meta("building_id", "")) == id:
			await _stow_piece()
			if not _paid_exactly(id, before) or not _paid_record(node, id):
				return null
			_receipt("built", {"id": id, "at": (node as Node3D).global_position})
			return node as Node3D
	_fail("a green %s ghost at %s placed nothing" % [id, at])
	return null


# ------------------------------------------------------------------ input --

func _open_station(station: Node3D, what: String) -> Node:
	var prompt := station.get_node_or_null("Interactable") as Node3D
	if prompt == null:
		for child: Node in station.find_children("*", "", true, false):
			if child.has_method("interaction_offer"):
				prompt = child as Node3D
				break
	if prompt == null or not await _walk_to_prompt(prompt, what):
		_fail("The %s's prompt was not reached" % what)
		return null
	await _tap(&"interact")
	var panel: Node = null
	for _frame in 120:
		await _tree.physics_frame
		panel = INPUT_OWNER.current(_tree)
		if panel != null:
			break
	if panel == null:
		_fail("Interact did not open the %s panel" % what)
	return panel


## Move controller focus to the unique enabled Button whose text starts with
## `prefix` (or satisfies `matches`) and press it.
func _press(panel: Node, prefix: String, matches: Callable = Callable()) -> bool:
	var target: Button = null
	for _attempt in 60:
		for node: Node in panel.find_children("*", "Button", true, false):
			var button := node as Button
			var text := button.text
			if button.disabled or not button.is_visible_in_tree():
				continue
			if (matches.is_valid() and matches.call(text)) or (not matches.is_valid() and text.begins_with(prefix)):
				if target != null:
					return _fail_b("Ambiguous enabled '%s' buttons; no input sent" % prefix)
				target = button
		if target != null:
			break
		await _tree.physics_frame
	if target == null:
		return _fail_b("No enabled '%s' button on %s" % [prefix, str(panel)])
	if not await _focus(panel, target):
		return _fail_b("Controller focus could not reach '%s'" % target.text)
	await _tap(&"ui_accept")
	await _settle(4)
	return true


func _focus(panel: Node, target: Control) -> bool:
	var viewport := (panel as Node).get_viewport() if panel is Node else _tree.root
	for direction: StringName in [&"ui_down", &"ui_up"]:
		for _step in FOCUS_STEPS:
			if not is_instance_valid(target):
				return false
			if viewport.gui_get_focus_owner() == target:
				return true
			var was := viewport.gui_get_focus_owner()
			await _tap(direction)
			await _settle(2)
			if viewport.gui_get_focus_owner() == was:
				break
	return is_instance_valid(target) and viewport.gui_get_focus_owner() == target


func _owner_of(script: Script) -> Node:
	for _frame in 120:
		var owner := INPUT_OWNER.current(_tree)
		if owner != null and owner.get_script() == script:
			await _settle(2)
			return owner
		await _tree.physics_frame
	return null


func _owner_with_mode(mode: String) -> Node:
	for _frame in 300:
		var owner := INPUT_OWNER.current(_tree)
		if owner != null and owner.get("_mode") == mode and owner.has_method("is_open") and bool(owner.call("is_open")):
			await _settle(2)
			return owner
		await _tree.physics_frame
	return null


func _until(condition: Callable, frames: int = SETTLE_TX_FRAMES) -> bool:
	for _frame in frames:
		if condition.call():
			return true
		await _tree.physics_frame
	return bool(condition.call())


# ------------------------------------------------------------------ state --

## The Storage panel lists one deposit row per held item id, sorted by id.
func _deposit_ids() -> Array[String]:
	var out: Array[String] = []
	var ids: Array = _game.get("items").call("ids") as Array
	ids.sort()
	for id: Variant in ids:
		if int(_game.get("inventory").call("count", str(id))) > 0:
			out.append(str(id))
	return out


func _stacks() -> Dictionary:
	var out := {}
	for id: String in _deposit_ids():
		out[id] = _count(id)
	return out


func _free_slots() -> int:
	var inventory: Object = _game.get("inventory")
	return int(inventory.call("slot_count")) - int(inventory.call("used_slots"))


func _count(item: String) -> int:
	return int(_game.get("inventory").call("count", item))


func _receipt(beat: String, detail: Dictionary) -> void:
	detail["beat"] = beat
	receipts.append(detail)
	transcript.append("%s %s" % [beat, JSON.stringify(detail)])
	print("EARNED HOMESTEAD — ", detail)


func _fail_b(message: String) -> bool:
	_fail(message)
	print("EARNED HOMESTEAD FAIL — ", message)
	return false
