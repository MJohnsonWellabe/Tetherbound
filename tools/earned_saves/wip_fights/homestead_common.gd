extends "res://tests/helpers/meadows_earned_camp_segment.gd"

const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

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
const FEAST_RECEIPTS := preload("res://tools/earned_saves/wip_fights/feast_receipts.gd")
const CRAFT_PANEL := preload("res://scripts/ui/craft_panel.gd")
const STORAGE_PANEL := preload("res://scripts/ui/storage_panel.gd")
const VILLAGE_BOUNDARY := preload("res://scripts/world/village_boundary.gd")
## The homestead plot (stations.json homestead_plot: centre [-4, 19], 40 x 30 m)
## minus its exclusions. Candidate build spots, tried in order.
## Spots three to six (x -10/-6, z 14/10) are the interior plot ground south
## of the Altar/Kitchen row whose 3 m stance stays inside the village fence;
## the north spots' stances fall beyond the fence and the west edge is steep
## (live forge ghost scan, Routes close-1020).
const PLOT_SPOTS: Array[Vector2] = [Vector2(-12.0, 20.0), Vector2(-8.0, 20.0),
	Vector2(-10.0, 14.0), Vector2(-6.0, 14.0), Vector2(-10.0, 10.0), Vector2(-6.0, 10.0),
	Vector2(-16.0, 28.0), Vector2(-8.0, 30.0), Vector2(-18.0, 20.0),
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
	# Key items (portal keys) stay in the Satchel like the Home Key; the chest
	# refused a held stormwood_portal_key with no reason, stopping the trip.
	for id: String in _deposit_ids():
		if str(_game.get("items").call("kind", id)) == "key" and not keep.has(id):
			keep.append(id)
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
	var cfg := STATION_RULES.config()
	var tiers: Array = []
	for row: Dictionary in cfg.get("attachments", []):
		if str(row.get("station_id")) == "kitchen" and int(row.get("tier", 0)) <= station_tier and str(row.get("status")) == "live":
			tiers.append(row)
	tiers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.tier) < int(b.tier))
	if station_tier < 1 or tiers.size() != station_tier:
		return _fail_b("The Kitchen has no live attachment for every tier up to %d" % station_tier)
	if not await _go_home():
		return false
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
		var costs := {}
		for cost: Dictionary in row.get("cost", []):
			costs[str(cost.id)] = int(cost.n)
		if not await _withdraw_available(costs):
			return false
		# Ingots are refined at the Forge (their cost's source_hint).
		for cost: Dictionary in row.get("cost", []):
			if not _forge_recipe(str(cost.get("id", ""))).is_empty() and _count(str(cost.id)) < int(cost.n):
				if not await _refine(str(cost.id), int(cost.n) - _count(str(cost.id))):
					return false
		if not await _fund({str(row.id): 1}):
			return false
		if not await _clear_socket(kitchen, int(row.tier), str(row.id)):
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
	var before := _saved_record()
	if not await _press(panel, "Refine " + str(recipe.get("name", item))):
		return false
	if not await _until(func() -> bool: return _count(item) >= target, REFINE_FRAMES):
		return _fail_b("The Forge channel did not refine %d %s (have %d)" % [units, item, _count(item)])
	if not await _until(func() -> bool: return FEAST_RECEIPTS.inventory_matches(before, _saved_record(), need, {item: units})):
		return _fail_b("The Forge did not save the exact raw-material bill and refined output")
	_receipt("refined", {"item": item, "units": units, "count": _count(item), "exact_saved_bill": true})
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
	var planned := {}
	for row: Dictionary in plan.feed:
		planned[str(row.item)] = int(planned.get(str(row.item), 0)) + 1
	if not await _withdraw_available(planned):
		return false
	var needed := {}
	var counted := {}
	for row: Dictionary in plan.feed:
		var item := str(row.item)
		counted[item] = int(counted.get(item, 0)) + 1
		if int(counted[item]) <= _count(item):
			continue
		var recipe: Dictionary = BREAKTHROUGH.feasts().recipes[row.recipe]
		if _kitchen_tier(kitchen) < int(recipe.station_tier):
			return _fail_b("Kitchen attachment tier is below the actual recipe requirement")
		for ingredient: String in recipe.cost:
			needed[ingredient] = int(needed.get(ingredient, 0)) + int(recipe.cost[ingredient])
	if not await _gather(needed):
		return false
	var panel := await _open_station(kitchen, "Kitchen")
	if panel == null or not await _press(panel, "Cook learned Ascension Feasts"):
		return false
	var chooser := await _owner_with_mode("cook")
	if chooser == null or chooser.get("_source") != kitchen:
		return _fail_b("The intended Kitchen did not open its Ascension Feast cook list")
	for row: Dictionary in plan.feed:
		var item := str(row.item)
		var have := _count(item)
		if have > _wanted(plan.feed, item) - 1:
			continue
		var cook_before := _saved_record()
		if not await _press(chooser, str(row.recipe_name) + " · "):
			return false
		if not await _until(func() -> bool: return _count(item) > have):
			return _fail_b("Cooking %s was not saved (%s)" % [item, str(chooser.get("_message").text)])
		var recipe: Dictionary = BREAKTHROUGH.feasts().recipes[row.recipe]
		if not await _until(func() -> bool: return FEAST_RECEIPTS.cook_errors(cook_before, _saved_record(), recipe).is_empty()):
			return _fail_b("Cook saved-record mismatch: " + str(FEAST_RECEIPTS.cook_errors(cook_before, _saved_record(), recipe)))
		_receipt("cooked", {"recipe": row.recipe, "count": _count(item), "exact_saved_bill": true})
	if not await _press(chooser, "Feed creatures"):
		return false
	chooser = await _owner_with_mode("feed")
	if chooser == null:
		return _fail_b("Feed creatures did not open the feed chooser")
	for row: Dictionary in plan.feed:
		var uid := str(row.uid)
		var label := feed_label(row)
		var feed_before := _saved_record()
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
		if not await _until(func() -> bool: return FEAST_RECEIPTS.feed_errors(feed_before, _saved_record(), row).is_empty()):
			return _fail_b("Feed saved-record mismatch: " + str(FEAST_RECEIPTS.feed_errors(feed_before, _saved_record(), row)))
		_receipt("fed", {"exact_saved_transition": true, "uid": uid, "feast": row.item, "choice": row.choice, "breakthroughs": _breakthroughs(uid),
			"species": _species(uid)})
	await _tap(&"menu_cancel")
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
	var state := _view()
	var available := _stacks()
	for chest: Node3D in storage_chests(_world, _tree.get_nodes_in_group(&"placed_building")):
		for item: Variant in _game.get("items").call("ids"):
			available[str(item)] = int(available.get(str(item), 0)) + maxi(0, _chest_count(chest, str(item)))
	return _feed_plan_from_stock(state, available, feast_id, choices)


## Allocation uses the same production catalogs as the live input helper.
## Reserve Evolve requirements first: Stay can cook a renewable ordinary feast.
## Return actions in party order; only planner-local reservations are reordered.
func _feed_plan_from_stock(state: Dictionary, stock: Dictionary, feast_id: String, choices: Dictionary) -> Dictionary:
	var feasts: Dictionary = BREAKTHROUGH.feasts()
	var available := stock.duplicate(true)
	var mirrors: Dictionary = state.get("redesign_character", {}).get("creatures", {})
	var names := {}
	var owned := {}
	var labels := BREAKTHROUGH_PANEL.party_labels(state.get("party", []))
	var label_of := {}
	for index in (state.get("party", []) as Array).size():
		var card: Dictionary = state.party[index]
		names[labels[index]] = int(names.get(labels[index], 0)) + 1
		label_of[str(card.uid)] = labels[index]
		owned[str(card.uid)] = true
	for uid: Variant in choices:
		if not owned.has(str(uid)):
			_fail("Evolution choice names a creature outside the current party: " + str(uid))
	var planning_order: Array = []
	for card: Dictionary in state.get("party", []):
		if str(choices.get(str(card.uid), "stay")) == "evolve": planning_order.append(card)
	for card: Dictionary in state.get("party", []):
		if str(choices.get(str(card.uid), "stay")) != "evolve": planning_order.append(card)
	var planned := {}
	var deferred: Array = []
	for card: Dictionary in planning_order:
		var uid := str(card.uid)
		var choice := str(choices.get(uid, "stay"))
		if choice not in ["stay", "evolve"]:
			_fail("Unknown evolution choice for " + uid)
			continue
		var picked := {}
		var at_requested_cap := false
		for id: String in feast_recipe_order(feasts.get("recipes", {}), available):
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
			elif not stay_feast_available(available, item, catalyst, offer.get("branches", [])):
				continue
			if not reserve_earned_feast(available, item, catalyst):
				continue
			picked = {"target": target, "uid": uid, "nickname": str(label_of.get(uid, "")), "recipe": id,
				"recipe_name": str(recipe.name), "item": item, "item_name": str(def.name), "choice": choice,
				"status": BREAKTHROUGH.status(card, mirrors.get(uid, {})),
				"choice_required": bool(offer.get("choice_required", false))}
			break
		if picked.is_empty():
			if at_requested_cap:
				_fail("No valid %s feast choice with an earned cooked feast or required catalyst at the requested cap for %s" % [choice, uid])
				continue
			deferred.append({"uid": uid, "level": int(card.get("level", 0)), "types": ESSENCE._species_types(card)})
		else:
			# The production list does not expose a UID in its visible label.
			# Refuse ambiguity before cooking or irreversible feeding.
			if int(names.get(str(picked.nickname), 0)) != 1:
				_fail("Feed chooser nickname is not unique: " + str(picked.nickname))
				continue
			planned[uid] = picked
	var feed: Array = []
	for card: Dictionary in state.get("party", []):
		if planned.has(str(card.uid)): feed.append(planned[str(card.uid)])
	return {"feast_id": feast_id, "feed": feed, "deferred": deferred}


## Recompute for each creature after reservations. Prefer existing cooked meals
## before spending another earned catalyst or gathering another recipe's bill.
static func feast_recipe_order(recipes: Dictionary, stock: Dictionary) -> Array[String]:
	var cooked: Array[String] = []
	var uncooked: Array[String] = []
	for id: String in recipes:
		var output: Dictionary = recipes[id].get("output", {})
		var item := str(output.keys()[0]) if not output.is_empty() else ""
		if int(stock.get(item, 0)) > 0:
			cooked.append(id)
		else:
			uncooked.append(id)
	cooked.append_array(uncooked)
	return cooked


## Production permits declining a valid cooked catalyst feast without refund.
## Stay never spends a loose catalyst to cook a new catalyst feast.
static func stay_feast_available(stock: Dictionary, item: String, catalyst: String, branches: Array) -> bool:
	if catalyst.is_empty(): return true
	if int(stock.get(item, 0)) <= 0: return false
	for branch: Dictionary in branches:
		if str(branch.get("extra_ingredient", "")) == catalyst:
			return true
	return false


## Planner-local accounting only. Catalysts are one-time earned pickups, not
## renewable gathering targets. A cooked feast already includes its catalyst.
static func reserve_earned_feast(stock: Dictionary, item: String, catalyst: String) -> bool:
	if int(stock.get(item, 0)) > 0:
		stock[item] = int(stock[item]) - 1
		return true
	if catalyst.is_empty(): return true
	if int(stock.get(catalyst, 0)) <= 0: return false
	stock[catalyst] = int(stock[catalyst]) - 1
	return true


const BREAKTHROUGH_PANEL := preload("res://scripts/masters/breakthrough_panel.gd")
const EVOLUTION := preload("res://scripts/creatures/evolution.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")


func _view() -> Dictionary:
	var service := _tree.root.get_node_or_null(^"Game/Session/FoundationComposition/BreakthroughService")
	var state: Variant = service.call("view") if service != null else {}
	return state if state is Dictionary else {}


func _saved_record() -> Dictionary:
	var local: RefCounted = _game.get("local")
	return RECORD_RULES.portable_projection(local.call("save_data")) if local != null else {}


func _breakthroughs(uid: String) -> Array:
	var record := _saved_record()
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
	var returning_from_hall := not _at_home()
	if returning_from_hall:
		var far := Vector2(_player.global_position.x, _player.global_position.z).distance_to(PLOT_CENTRE)
		if not await _travel.home_key():
			failures.append_array(_travel.failures)
			return false
		_rebind()
		_receipt("home_key", {"from_m": far, "landed": _player.global_position})
		# The Hall and Grandpa's home share the authored village road. A straight
		# line to the old (-14, 27) target cut across Tam and ended on the fence.
		for point: Vector2 in [Vector2(8.3, 14.0), Vector2(8.3, 20.0)]:
			var road := Vector3(point.x, float(_world.call("ground_height_at", point.x, point.y)), point.y)
			if not await _walk_to(road, "the village road to the homestead", 2.0):
				return _fail_b("Ordinary movement did not follow the village road home")
	else:
		var outline := VILLAGE_BOUNDARY.outline(VILLAGE_BOUNDARY.load_config())
		var at := Vector2(_player.global_position.x, _player.global_position.z)
		if outline.size() >= 3 and not VILLAGE_BOUNDARY.contains(outline, at):
			# A placed Altar can save outside the north fence but within the plot's
			# home radius. Enter by the already-open TrailGate on its authored road.
			if not _flag("road_gate_open"):
				return _fail_b("The village road gate is still closed")
			for point: Vector2 in [Vector2(13.3, 29.0), Vector2(14.0, 18.0), Vector2(8.3, 20.0)]:
				var road := Vector3(point.x, float(_world.call("ground_height_at", point.x, point.y)), point.y)
				if not await _walk_to(road, "the open TrailGate road to the homestead", 2.0):
					return _fail_b("Ordinary movement did not enter the village by TrailGate")
	var plot := Vector2(-12.0, 24.0) # Authored interior plot stance, inside the fence.
	var stance := Vector3(plot.x, float(_world.call("ground_height_at", plot.x, plot.y)), plot.y)
	if not await _walk_to(stance, "the homestead plot", 3.0):
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
	var buildings := placed_buildings(_world, _tree.get_nodes_in_group(&"placed_building"), id)
	return buildings[0] if not buildings.is_empty() else null


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
	if not await _withdraw_available(need):
		return false
	var short := {}
	for item: String in need:
		if _count(item) < int(need[item]):
			short[item] = int(need[item])
	if short.is_empty():
		return true
	_receipt("gather", {"need": need, "short": short})
	var gather := GATHER.new()
	gather.stock_override = short
	gather.prefer_same_boundary_side = true
	var back := _player.global_position
	# Carry real supplies back by Stoneyard Lane and Main Street. The direct
	# chord from the stone yard to the plot intersects Grandpa's wall footprint.
	var street := Vector2(20.0, 14.0)
	gather.return_to = Vector3(street.x, float(_world.call("ground_height_at", street.x, street.y)), street.y)
	var result: Dictionary = await gather.run(_tree, _world, _game, _player, _rig, false)
	transcript.append_array(result.get("transcript", []))
	if result.get("passed") != true:
		failures.append_array(result.get("failures", []))
		return false
	for point: Vector2 in [Vector2(8.3, 14.0), Vector2(8.3, 20.0)]:
		var road := Vector3(point.x, float(_world.call("ground_height_at", point.x, point.y)), point.y)
		if not await _walk_to(road, "carrying earned materials along Main Street", 2.0):
			return _fail_b("Ordinary movement could not carry earned materials along Main Street")
	# The chord from Main Street to a stance beside the plot's stations crosses
	# Grandpa's crop beds (z 21-23.4); enter by _go_home's interior plot stance.
	var plot := Vector3(-12.0, float(_world.call("ground_height_at", -12.0, 24.0)), 24.0)
	if not await _walk_to(plot, "carrying earned materials into the homestead plot", 3.0):
		return _fail_b("Ordinary movement could not carry earned materials into the homestead plot")
	if not await _walk_to(back, "carrying earned materials to the original homestead stance", 1.65):
		return _fail_b("Ordinary movement could not return earned materials to the original homestead stance")
	return true


## Stored items remain earned inventory. Retrieve through the actual chest UI
## before asking the resource walker for deficits. A whole-stack withdrawal may
## be partial when the Satchel fills; only the conserved quantity is accepted.
func _withdraw_available(need: Dictionary) -> bool:
	if not _at_home():
		return true
	# Recompute deficits at each chest: a previous chest may supply only part
	# of the bill, or the earned catalyst may live in a later chest.
	for chest: Node3D in storage_chests(_world, _tree.get_nodes_in_group(&"placed_building")):
		if not await _withdraw_from(chest, need): return false
	return true


static func storage_chests(world: Node, nodes: Array[Node]) -> Array[Node3D]:
	return placed_buildings(world, nodes, "storage")


## Scene transitions can leave old buildings in the global group until the
## old world is freed. Bind all homestead interactions and build-space reads
## to live descendants of the caller's current world, just like chest reads.
static func placed_buildings(world: Node, nodes: Array[Node], id: String = "") -> Array[Node3D]:
	var result: Array[Node3D] = []
	if not is_instance_valid(world) or world.is_queued_for_deletion(): return result
	for node: Node in nodes:
		if is_instance_valid(node) and node is Node3D and not node.is_queued_for_deletion() \
				and world.is_ancestor_of(node) \
				and (id.is_empty() or str(node.get_meta("building_id", "")) == id):
			result.append(node as Node3D)
	return result


func _withdraw_from(chest: Node3D, need: Dictionary) -> bool:
	var wanted: Array[String] = []
	for item: String in need:
		if _count(item) < int(need[item]) and _chest_count(chest, item) > 0:
			wanted.append(item)
	if wanted.is_empty():
		return true
	var prompt := chest.get_node_or_null("Interactable") as Node3D
	if prompt == null or not await _walk_to_prompt(prompt, "stored crafting ingredients"):
		return _fail_b("Could not reach the Storage Chest for earned ingredients")
	await _tap(&"interact")
	var panel := await _owner_of(STORAGE_PANEL)
	if panel == null or panel.get("_chest") != chest:
		return _fail_b("Ingredient retrieval did not open the intended chest")
	for item: String in wanted:
		var state: RefCounted = chest.get("state")
		var stock: RefCounted = state.get("inventory")
		var ids: Array = _game.get("items").call("ids")
		ids.sort()
		var held: Array[String] = []
		for id: Variant in ids:
			if int(stock.call("count", str(id))) > 0:
				held.append(str(id))
		var index := held.find(item)
		var rows: Array = panel.get("_withdraw_rows")
		if index < 0 or index >= rows.size() or not await _focus(panel, rows[index] as Control):
			return _fail_b("Controller focus could not reach stored " + item)
		var bag_before := _count(item)
		var chest_before := _chest_count(chest, item)
		await _tap(&"ui_accept")
		if not await _until(func() -> bool: return storage_transfer_matches(chest_before, _chest_count(chest, item), bag_before, _count(item))):
			return _fail_b("Stored ingredient withdrawal did not conserve " + item)
		_receipt("ingredient_withdrawal", {"chest_uid": str(chest.get_meta("building_uid", "")), "item": item, "bag_before": bag_before, "bag_after": _count(item),
			"chest_before": chest_before, "chest_after": _chest_count(chest, item)})
	await _tap(&"menu_cancel")
	if not await _until(func() -> bool: return INPUT_OWNER.current(_tree) == null):
		return _fail_b("Ingredient chest did not release world input")
	return true


## A station must not stand on the Kitchen's attachment sockets (station_rules
## `socket`: tier 1 west, 2 north, 3 east, 4 south). The Forge on the plot spot
## east of the Kitchen covered its tier-3 socket, so kitchen_cloudreach's ghost
## was red at every stance (training_t4_kitchen_3, 24 Oct).
const SOCKET_CLEAR_M := 2.8
const KITCHEN_SOCKET_TIERS := 4

static func kitchen_sockets(centre: Vector2, yaw_deg: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var record := {"id": "kitchen", "position": [centre.x, 0.0, centre.y], "yaw_deg": yaw_deg}
	for tier in range(1, KITCHEN_SOCKET_TIERS + 1):
		var at: Vector3 = STATION_RULES.socket(STATION_RULES.config(), record, tier)
		out.append(Vector2(at.x, at.z))
	return out

static func spot_clear_of_sockets(spot: Vector2, sockets: Array[Vector2]) -> bool:
	for socket: Vector2 in sockets:
		if socket.distance_to(spot) < SOCKET_CLEAR_M: return false
	return true

func _spot_keeps_sockets_clear(id: String, spot: Vector2) -> bool:
	var placed := placed_buildings(_world, _tree.get_nodes_in_group(&"placed_building"))
	for node: Node3D in placed:
		if str(node.get_meta("building_id", "")) == "kitchen" and id != "kitchen":
			if not spot_clear_of_sockets(spot, kitchen_sockets(Vector2(node.global_position.x, node.global_position.z), rad_to_deg(node.global_rotation.y))):
				return false
	if id == "kitchen":
		var sockets := kitchen_sockets(spot, 0.0)
		for node: Node3D in placed:
			if not spot_clear_of_sockets(Vector2(node.global_position.x, node.global_position.z), sockets):
				return false
	return true


## A station already standing on the Kitchen's next socket (a save made before
## the socket rule, e.g. the Forge east of the Kitchen) is taken down the way a
## player would: Build armed, aim at it until the placer highlights it, then
## the production dismantle (Y). Its job is done (the tier's ingots are already
## refined); `_refine` rebuilds a Forge on a socket-clear spot if a later tier
## needs one.
const DISMANTLE_STANDOFFS: Array[float] = [2.0, 2.4, 2.8, 1.7, 3.2]

func _clear_socket(kitchen: Node3D, tier: int, armed_id: String) -> bool:
	var record := {"id": "kitchen", "position": [kitchen.global_position.x, kitchen.global_position.y, kitchen.global_position.z],
		"yaw_deg": rad_to_deg(kitchen.global_rotation.y)}
	var at: Vector3 = STATION_RULES.socket(STATION_RULES.config(), record, tier)
	var socket := Vector2(at.x, at.z)
	var blocker: Node3D = null
	for node: Node3D in placed_buildings(_world, _tree.get_nodes_in_group(&"placed_building")):
		var id := str(node.get_meta("building_id", ""))
		if node == kitchen or not STATION_RULES.attachment(STATION_RULES.config(), id).is_empty():
			continue
		if socket.distance_to(Vector2(node.global_position.x, node.global_position.z)) < SOCKET_CLEAR_M:
			blocker = node
	if blocker == null:
		return true
	var blocker_id := str(blocker.get_meta("building_id", ""))
	var uid := str(blocker.get_meta("building_uid", ""))
	var centre := Vector2(blocker.global_position.x, blocker.global_position.z)
	var away := (Vector2(_player.global_position.x, _player.global_position.z) - centre)
	if away.length() < 0.5: away = Vector2(0.0, 1.0)
	if not await _select_piece(armed_id):
		return false
	for standoff: float in DISMANTLE_STANDOFFS:
		var stance2 := centre + away.normalized() * standoff
		var stance := Vector3(stance2.x, float(_world.call("ground_height_at", stance2.x, stance2.y)), stance2.y)
		if not await _walk_to(stance, "dismantle %s stance (armed)" % blocker_id, MOVE_EPSILON, true, false):
			continue
		if not await _face_with_input(blocker.global_position - _player.global_position):
			failures.clear()
			continue
		await _settle(10)
		var placer := _tree.get_first_node_in_group(&"build_placer")
		if placer == null or placer.get("_dismantle_target") != blocker:
			continue
		await _tap(&"build_dismantle")
		if await _until(func() -> bool: return not _uids().has(uid)):
			await _stow_piece()
			_receipt("socket_cleared", {"id": blocker_id, "uid": uid, "socket_tier": tier, "socket": socket})
			return true
	await _stow_piece()
	return _fail_b("The %s on the Kitchen's tier-%d socket could not be dismantled" % [blocker_id, tier])

func _uids() -> Array:
	var out: Array = []
	for record: Variant in _game.get("placed_buildings"):
		if record is Dictionary and record.get("removed", false) != true: out.append(str(record.get("uid", "")))
	return out


func _place_on_plot(id: String) -> Node3D:
	for spot: Vector2 in PLOT_SPOTS:
		if _used_spots.has(spot) or _occupied(spot) or not _spot_keeps_sockets_clear(id, spot):
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
	for node: Node3D in placed_buildings(_world, _tree.get_nodes_in_group(&"placed_building")):
		if Vector2(node.global_position.x, node.global_position.z).distance_to(spot) < 3.0:
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
	var stance := target - _forward() * PLACE_AHEAD
	if not await _select_piece(id):
		return null
	# Opening Build may first step clear of a nearby prompt (the Forge beside
	# the Kitchen); a green ghost pressed from there places nothing. Carry the
	# armed piece back to the stance before placing.
	# On a crowded plot the step-clear can carry the trainer past Grandpa's
	# house (training_t4_kitchen: to (5.9,12.1)); a straight walk back stops
	# on the farmhouse wall. Return by `_go_home`'s village road and the
	# interior plot stance first.
	if Vector2(_player.global_position.x - stance.x, _player.global_position.z - stance.z).length() > 6.0:
		for point: Vector2 in [Vector2(8.3, 14.0), Vector2(8.3, 20.0), Vector2(-12.0, 24.0)]:
			var road := Vector3(point.x, float(_world.call("ground_height_at", point.x, point.y)), point.y)
			if not await _walk_to(road, "%s back to the plot (armed)" % id, 2.0):
				break
	if Vector2(_player.global_position.x - stance.x, _player.global_position.z - stance.z).length() > 0.5 \
			and not await _walk_to(stance, "%s stance at %s (armed)" % [id, at], MOVE_EPSILON, true, false):
		transcript.append("%s stance at %s unreachable with the piece armed" % [id, at])
		await _stow_piece()
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
	var existing := placed_buildings(_world, _tree.get_nodes_in_group(&"placed_building"))
	await _tap(&"build_place")
	await _settle(12)
	for node: Node3D in placed_buildings(_world, _tree.get_nodes_in_group(&"placed_building"), id):
		if not existing.has(node):
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
	var panel := await _owner_of(CRAFT_PANEL)
	if panel == null or not bool(panel.call("is_open")) or panel.get("_station") != station:
		_fail("Interact did not open the intended %s station panel" % what)
		return null
	return panel


## Move controller focus to the unique enabled Button whose text starts with
## `prefix` (or satisfies `matches`) and press it.
func _press(panel: Node, prefix: String, matches: Callable = Callable()) -> bool:
	# A panel may rebuild its rows once its asynchronous view arrives (the
	# Kitchen cook list did), freeing the button focus was steering to. Find
	# the live button again rather than give up on a replaced one.
	for _rebuilt in 3:
		var target := await _find_button(panel, prefix, matches)
		if target == null:
			return false
		if await _focus(panel, target):
			await _tap(&"ui_accept")
			await _settle(4)
			return true
		if is_instance_valid(target):
			return _fail_b("Controller focus could not reach '%s'" % target.text)
	return _fail_b("The '%s' button kept being rebuilt before focus reached it" % prefix)


func _find_button(panel: Node, prefix: String, matches: Callable) -> Button:
	var target: Button = null
	for _attempt in 60:
		for node: Node in panel.find_children("*", "Button", true, false):
			var button := node as Button
			var text := button.text
			if button.disabled or not button.is_visible_in_tree():
				continue
			if (matches.is_valid() and matches.call(text)) or (not matches.is_valid() and text.begins_with(prefix)):
				if target != null:
					_fail("Ambiguous enabled '%s' buttons; no input sent" % prefix)
					return null
				target = button
		if target != null:
			break
		await _tree.physics_frame
	if target == null:
		_fail("No enabled '%s' button on %s" % [prefix, str(panel)])
	return target


func _focus(panel: Node, target: Control) -> bool:
	var viewport := (panel as Node).get_viewport() if panel is Node else _tree.root
	for direction: StringName in [&"ui_down", &"ui_up", &"ui_right", &"ui_down", &"ui_up", &"ui_left", &"ui_down", &"ui_up"]:
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
		if owner != null and owner.get_script() == BREAKTHROUGH_PANEL and owner.get("_mode") == mode and bool(owner.call("is_open")):
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
