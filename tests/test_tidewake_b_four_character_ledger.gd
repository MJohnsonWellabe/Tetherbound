extends "res://tests/test_case.gd"

## ACCEPTANCE §6.1 F13#4: "Six selected local chains, one per group ... leave
## four-character supplies solvent without a new catch or repeated wild."
## PROGRESSION §6: ledger from reachable source rows; four characters sharing
## permanent nodes; four personal required kits plus shared structures once;
## basic-material supply >= 150% of that; emergency reserve (legal bed, two
## basic heals) before the major gauntlet; never enemy drops or leather.
##
## Pure data. Every figure is read from shipping Tidewake data:
##   water_world.json      island gate order (docks), saddle-gated islands
##   water_pickups.json    harvest yields (world-once, first gatherer keeps
##                         them: harvest_node:order:<id>; the one
##                         character_once pocket patch, reed_root_hollow, is
##                         still counted once -- conservative) and pickups
##                         (existing_world_pickup_policy = world-once;
##                         character_once = per character)
##   water_dock_actions.json / water_local_chains.json   material debits
##                         (both commit world-scoped records: paid once)
##   water_crafting.json   Swim Saddle recipe (personal kit), small potion
##   water_camps.json      free authored beds
## No wild encounter, enemy drop or trainer payout is counted as supply: the
## ledger is solvent on harvest + world pickups alone, so repeated wilds and
## a new catch cannot be what makes it pass.

const WORLD := "res://data/config/water_world.json"
const PICKUPS := "res://data/config/water_pickups.json"
const DOCKS := "res://data/config/water_dock_actions.json"
const CHAINS := "res://data/config/water_local_chains.json"
const CRAFTING := "res://data/config/water_crafting.json"
const SWIMMING := "res://data/config/water_swimming.json"
const CAMPS := "res://data/config/water_camps.json"
const ROSTER := "res://data/config/water_roster.json"
const SPAWN_TABLES := "res://data/config/spawn_tables.json"

const CHARACTERS := 4
## PROGRESSION §6 "available basic-material supply >= 150% of ... cost".
const MARGIN := 1.5
## PROGRESSION §6 emergency reserve: two basic heals per character.
const HEALS_PER_CHARACTER := 2
const BASIC_HEALS := ["potion_small", "potion_large"]
const BASE_RESOURCES := ["reed_fiber", "driftwood", "reef_stone", "tide_bloom"]
const CRADLE_SEAM := "water:tidal_cradle:harvest:007"

var _stage: Dictionary = {}       # island_id -> gate stage (0 = First Shore)
var _saddle_gated: Dictionary = {} # island_id -> true when its dock needs a swim mount
var _veilfall_stage := -1


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func before_each() -> void:
	super.before_each()
	_stage.clear()
	_saddle_gated.clear()
	var docks: Array = _json(WORLD).get("docks", [])
	var targets := {}
	for dock: Dictionary in docks:
		targets[str(dock.outbound_edge).split("_to_")[1]] = true
	for dock: Dictionary in docks:
		var from := str(dock.outbound_edge).split("_to_")[0]
		if bool(dock.get("mandatory", false)) and not targets.has(from):
			_stage[from] = 0
	var changed := true
	while changed:
		changed = false
		for dock: Dictionary in docks:
			var parts := str(dock.outbound_edge).split("_to_")
			if not _stage.has(parts[0]) or _stage.has(parts[1]):
				continue
			var mandatory := bool(dock.get("mandatory", false))
			_stage[parts[1]] = int(_stage[parts[0]]) + (1 if mandatory else 0)
			if not (dock.get("required_equipment", []) as Array).is_empty() \
					or bool(dock.get("requires_compatible_active_swim_mount", false)):
				_saddle_gated[parts[1]] = true
			changed = true
	_veilfall_stage = int(_stage.get("veilfall", -1))


func _island_of_anchor(anchor: String) -> String:
	var parts := anchor.split("_to_")
	if anchor.ends_with("_arrival"):
		return parts[1].trim_suffix("_arrival")
	return parts[0]


func _island_at(xz: Array) -> String:
	var best := ""
	var best_d := INF
	for island: Dictionary in _json(WORLD).get("islands", []):
		var c: Array = island.center_xz_m
		var d := Vector2(float(xz[0]) - float(c[0]), float(xz[1]) - float(c[1])).length()
		if d < best_d:
			best_d = d
			best = str(island.id)
	return best


## World-once harvest yield of `item` on islands a retained-five, no-saddle
## character reaches by gate stage `cut`.
func _harvest(item: String, cut: int) -> int:
	var total := 0
	for row: Dictionary in _json(PICKUPS).get("harvest", []):
		var island := str(row.island_id)
		if str(row.item_id) == item and _stage.has(island) and int(_stage[island]) <= cut \
				and not _saddle_gated.has(island):
			total += int(row.get("yield", 0))
	return total


func _world_pickups(items: Array, cut: int) -> int:
	var total := 0
	for row: Dictionary in _json(PICKUPS).get("pickups", []):
		var island := str(row.island_id)
		if items.has(str(row.item_id)) and str(row.claim_policy) != "character_once" \
				and _stage.has(island) and int(_stage[island]) <= cut and not _saddle_gated.has(island) \
				and (row.get("requires_world_flags", []) as Array).is_empty():
			total += int(row.get("quantity", 1))
	return total


## Every material debit on the earned route plus the six chains:
## {label, item, n, cut, scope}. scope "world" = paid once per world (host
## records are world flags); "character" = one kit per character.
func _debits() -> Array:
	var out: Array = []
	for action: Dictionary in _json(DOCKS).get("actions", []):
		var cost: Dictionary = action.get("cost", {})
		var island := _island_of_anchor(str(action.anchor))
		for item: String in cost:
			out.append({"label": "dock " + str(action.id), "item": item, "n": int(cost[item]),
				"cut": int(_stage.get(island, 99)), "scope": "world"})
	for step: Dictionary in _json(CHAINS).get("steps", []):
		var cost: Dictionary = step.get("cost", {})
		if cost.is_empty():
			continue
		var island := _island_at(step.at_xz)
		for item: String in cost:
			out.append({"label": "chain " + str(step.id), "item": item, "n": int(cost[item]),
				"cut": int(_stage.get(island, 99)), "scope": "world"})
	# Swim Saddle: Drowned Garden and Deep Watch (two of the six chains) are
	# behind swim-mount docks. It must be paid from what is reachable before the
	# first of those docks, once per character who wants to follow.
	var saddle_cut := 99
	for dock: Dictionary in _json(WORLD).get("docks", []):
		var parts := str(dock.outbound_edge).split("_to_")
		if _saddle_gated.has(parts[1]):
			saddle_cut = mini(saddle_cut, int(_stage[parts[0]]))
	var recipe: Dictionary = (_json(CRAFTING).recipes as Dictionary).water_swim_saddle
	for cost: Dictionary in recipe.cost:
		out.append({"label": "craft water_swim_saddle", "item": str(cost.id), "n": int(cost.n),
			"cut": saddle_cut, "scope": "character"})
	return out


func _required(item: String, cut: int, debits: Array) -> Dictionary:
	var world := 0
	var personal := 0
	for d: Dictionary in debits:
		if str(d.item) == item and int(d.cut) <= cut:
			if str(d.scope) == "world":
				world += int(d.n)
			else:
				personal += int(d.n)
	return {"world": world, "personal": personal, "total": world + CHARACTERS * personal}


func test_gate_order_is_derived_and_the_mandatory_route_needs_no_swimmer() -> void:
	assert_eq(int(_stage.get("first_shore", -1)), 0)
	assert_true(_veilfall_stage >= 6, "Veilfall sits behind the mandatory dock chain")
	for dock: Dictionary in _json(WORLD).get("docks", []):
		if bool(dock.get("mandatory", false)):
			assert_true((dock.get("required_equipment", []) as Array).is_empty()
				and not bool(dock.get("requires_compatible_active_swim_mount", false)),
				"%s: the mandatory route must not require a saddle or owned swimmer (no new catch)" % dock.id)
	var sheltered_checked := 0
	for route: Dictionary in _json(WORLD).get("water_routes", []):
		var to := str(route.edge_id).split("_to_")[1]
		if str(route.choice) == "sheltered" and not _saddle_gated.has(to):
			sheltered_checked += 1
			assert_true((route.get("required_equipment", []) as Array).is_empty()
				and not bool(route.get("requires_compatible_active_swim_mount", false)),
				"%s: sheltered human route stays open to the retained five" % route.id)
	assert_true(sheltered_checked > 0, "sheltered human routes exist to check")


func test_four_character_material_ledger_is_solvent_by_gate() -> void:
	var debits := _debits()
	assert_false(debits.is_empty(), "the route has material debits to account for")
	var cuts := {}
	for d: Dictionary in debits:
		cuts[int(d.cut)] = true
		assert_true(int(d.cut) < 99, "%s: debit resolves to a gate stage" % d.label)
	var lines: PackedStringArray = []
	lines.append("F13#4 LEDGER (4 characters; world-once debits once, personal kits x4; supply = world-once harvest on islands reachable without a swim mount)")
	for d: Dictionary in debits:
		lines.append("  DEBIT %-34s %-11s %2d  by stage %d  scope=%s" % [d.label, d.item, d.n, d.cut, d.scope])
	lines.append("  %-11s %5s %6s %8s %9s %6s %8s %7s %s" % ["item", "stage", "world", "personal", "required", "supply", "margin", "per-chr", "verdict"])
	var sorted_cuts: Array = cuts.keys()
	sorted_cuts.sort()
	for item: String in BASE_RESOURCES:
		for cut: int in sorted_cuts:
			var need := _required(item, cut, debits)
			if int(need.total) == 0:
				continue
			var supply := _harvest(item, cut)
			var margin := float(supply) / float(need.total)
			var share := (supply - int(need.world)) / CHARACTERS
			var ok := supply >= int(need.total) and margin >= MARGIN
			lines.append("  %-11s %5d %6d %8d %9d %6d %7.2fx %7d %s" % [item, cut, need.world, need.personal,
				need.total, supply, margin, share, "SOLVENT" if ok else "INSOLVENT"])
			assert_true(supply >= int(need.total),
				"INSOLVENT %s by gate stage %d: need %d (world %d + %d x %d personal), reachable world-once supply %d"
				% [item, cut, need.total, need.world, CHARACTERS, need.personal, supply])
			assert_true(margin >= MARGIN,
				"%s by stage %d: supply %d is below PROGRESSION's 150%% of %d" % [item, cut, supply, need.total])
			assert_true(share >= int(need.personal),
				"%s by stage %d: an even four-way split (%d each) cannot cover a personal kit of %d" % [item, cut, share, need.personal])
	print("\n".join(lines))


func test_saddle_recipe_matches_swimming_config_and_is_a_personal_optional_kit() -> void:
	var recipe: Dictionary = (_json(CRAFTING).recipes as Dictionary).water_swim_saddle
	var configured: Dictionary = _json(SWIMMING).saddle_recipe
	for cost: Dictionary in recipe.cost:
		assert_eq(int(cost.n), int(configured.get(str(cost.id), -1)), "saddle %s cost agrees across configs" % cost.id)
	assert_true((recipe.get("requires_personal_flags", []) as Array).has("water_swim_saddle_recipe_learned"))


func test_emergency_reserve_before_veilfall_for_four_characters() -> void:
	var before := _veilfall_stage - 1
	var heals := _world_pickups(BASIC_HEALS, before)
	var need := CHARACTERS * HEALS_PER_CHARACTER
	# Craft capacity from what is left after every material debit is paid.
	var debits := _debits()
	var bloom := _harvest("tide_bloom", before) - int(_required("tide_bloom", before, debits).total)
	var reed := _harvest("reed_fiber", before) - int(_required("reed_fiber", before, debits).total)
	var potion: Dictionary = (_json(CRAFTING).recipes as Dictionary).water_small_potion
	var per := {}
	for cost: Dictionary in potion.cost:
		per[str(cost.id)] = int(cost.n)
	var crafted := mini(bloom / int(per.get("tide_bloom", 1)), reed / int(per.get("reed_fiber", 1)))
	print("F13#4 RESERVE before Veilfall (stage<=%d): world-once basic-heal pickups=%d (+%d craftable Small Potions from residual tide_bloom=%d reed=%d) vs %d required (%d chars x %d); %d each on an even split"
		% [before, heals, crafted, bloom, reed, need, CHARACTERS, HEALS_PER_CHARACTER, (heals + crafted) / CHARACTERS])
	assert_true(heals + crafted >= need, "two basic heals per character before Veilfall")
	var veilfall_bed := false
	for camp: Dictionary in _json(CAMPS).get("camps", []):
		assert_false(camp.has("cost"), "%s: authored camp beds are free services" % camp.id)
		if str(camp.island_id) == "veilfall" and camp.has("creature_bed_index"):
			veilfall_bed = true
	assert_true(veilfall_bed, "a legal free recovery bed stands on Veilfall before the gauntlet")


func test_chain_payouts_and_swimmer_precondition_are_disclosed() -> void:
	# Cradle: the chain's 4 Reef Stone is one world-once seam (first gatherer).
	var seam := {}
	for row: Dictionary in _json(PICKUPS).get("harvest", []):
		if str(row.id) == CRADLE_SEAM:
			seam = row
	assert_eq(str(seam.get("gather_action", "")), "pickaxe")
	var lines: PackedStringArray = ["F13#4 CHAIN PAYOUTS (who is paid)"]
	lines.append("  side_water_cradle_care seam %s reef_stone x%d -> first gatherer only (world-once harvest)" % [CRADLE_SEAM, int(seam.get("yield", 0))])
	for step: Dictionary in _json(CHAINS).get("steps", []):
		if step.has("grant"):
			lines.append("  %s grant %s -> reporting character only (world-scoped step record)" % [step.id, JSON.stringify(step.grant)])
	var pockets := {}
	for row: Dictionary in _json(PICKUPS).get("pickups", []):
		if row.has("reward_pocket_id"):
			pockets[str(row.id)] = row
			lines.append("  pocket %s %s x%d -> %s" % [row.reward_pocket_id, row.item_id, int(row.quantity),
				"each character (character_once)" if str(row.claim_policy) == "character_once" else "first taker (world-once)"])
	# Swimmer: two chains need an owned compatible swim mount. Report which
	# compatible species a retained five can already hold from earlier chapters.
	var spawn_text := FileAccess.get_file_as_string(SPAWN_TABLES)
	var earlier: PackedStringArray = []
	var compatible: PackedStringArray = []
	var species: Dictionary = _json(ROSTER).species
	for id: String in species:
		if bool(((species[id] as Dictionary).get("swim_mount", {}) as Dictionary).get("compatible", false)):
			compatible.append(id)
			if spawn_text.contains("\"species\": \"%s\"" % id):
				earlier.append(id)
	lines.append("  swim-mount compatible: %s; wild before Tidewake: %s" % [", ".join(compatible), ", ".join(earlier)])
	lines.append("  saddle-gated chain islands: %s" % ", ".join(PackedStringArray(_saddle_gated.keys())))
	print("\n".join(lines))
	assert_false(earlier.is_empty(), "a retained five can already hold a swim-mount species (no Tidewake catch needed)")
