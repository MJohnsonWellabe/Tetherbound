extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/stormwood_crown_build_segment.gd")
const ARCH_RULES := preload("res://scripts/world/stormwood_arch_build_rules.gd")
const SEGMENT_PATH := "res://tests/helpers/stormwood_crown_build_segment.gd"
const HARVEST_PATH := "res://data/config/stormwood_harvests.json"
const RECIPES_PATH := "res://data/recipes/recipes_stormwood.json"
const BUILDABLES_PATH := "res://data/items/buildables.json"


func test_segment_parses_and_declares_the_paid_terminal_contract() -> void:
	var segment: RefCounted = SEGMENT.new()
	assert_true(segment != null, "the Crown continuation must remain loadable")
	var contract: Dictionary = SEGMENT.resource_contract()
	assert_eq(contract.gathered, {
		"stormglass_crown": 6, "thunderwood": 8, "conductor_vine": 6})
	assert_eq(contract.frame_cost, {"thunderwood": 6, "conductor_vine": 2})
	assert_eq(contract.arch_cost, {
		"stormglass_crown": 6, "thunderwood_frame": 2, "conductor_vine": 4})
	assert_eq(contract.surplus, {
		"thunderwood": 2, "conductor_vine": 0, "stormglass_crown": 0})


func test_six_selected_sources_match_the_live_catalogue_and_indivisible_yields() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HARVEST_PATH))
	assert_true(parsed is Dictionary, "Stormwood harvest catalogue must parse")
	var authored := {}
	if parsed is Dictionary:
		for row: Dictionary in parsed.get("sites", []):
			authored[str(row.get("id", ""))] = row
	var totals := {"stormglass_crown": 0, "thunderwood": 0, "conductor_vine": 0}
	var plan: Array[Dictionary] = SEGMENT.site_plan()
	assert_eq(plan.size(), 6, "the helper must gather six exact production nodes")
	for stop: Dictionary in plan:
		var id := str(stop.id)
		assert_true(authored.has(id), "named helper source must exist: " + id)
		if not authored.has(id):
			continue
		var row := authored[id] as Dictionary
		assert_eq(str(row.get("region_id", "")), "conductor_run")
		assert_eq(str(row.get("item", "")), str(stop.item))
		assert_eq(int(row.get("amount", 0)), int(stop.amount))
		var position: Array = row.get("position", [])
		assert_eq(position, [float(stop.at.x), float(stop.at.y)])
		totals[str(stop.item)] += int(stop.amount)
	assert_eq(totals, SEGMENT.resource_contract().gathered,
		"the route must report exact all-or-nothing authored yields")


func test_frame_and_crown_costs_balance_the_authored_route() -> void:
	var recipes: Variant = JSON.parse_string(FileAccess.get_file_as_string(RECIPES_PATH))
	var buildables: Variant = JSON.parse_string(FileAccess.get_file_as_string(BUILDABLES_PATH))
	assert_true(recipes is Dictionary and buildables is Dictionary,
		"recipe/buildable catalogues must parse")
	if not recipes is Dictionary or not buildables is Dictionary:
		return
	var frame: Dictionary = (recipes.get("recipes", {}) as Dictionary).get(
		"thunderwood_frame", {}) as Dictionary
	var arch := {}
	for row: Dictionary in buildables.get("buildables", []):
		if str(row.get("id", "")) == "stormglass_arch":
			arch = row
			break
	assert_false(frame.is_empty(), "thunderwood_frame recipe must remain authored")
	assert_false(arch.is_empty(), "Stormglass Arch must remain in the live catalogue")
	assert_eq(_cost_map(frame.get("cost", [])), {"thunderwood": 3, "conductor_vine": 1})
	# The catalogue uses ordinary glass for generic footings; the fixed Crown
	# socket's dynamic rule substitutes stormglass_crown at placement time.
	assert_eq(_cost_map(arch.get("cost", [])), {
		"stormglass": 6, "thunderwood_frame": 2, "conductor_vine": 4})
	assert_eq(str(arch.get("unlocked_by", "")), "stormwood:arch_recipe_known")
	assert_eq(_cost_map(ARCH_RULES.cost(Vector3(-160.0, 0.0, 2750.0))),
		SEGMENT.resource_contract().arch_cost,
		"the fixed Still Grove socket must substitute the exact Crown-grade cost")


func test_segment_uses_live_controller_surfaces_and_contains_no_state_bypass() -> void:
	var source := FileAccess.get_file_as_string(SEGMENT_PATH).replace("\r\n", "\n")
	for banned in [
		"global_position =",
		"inventory.call(\"add\"",
		"inventory.call(\"remove\"",
		"set(\"pending_build\"",
		"set(\"free_build\"",
		"progression.call(\"set\"",
		"ledger.call(\"submit\"",
		"panel.call(\"_craft\"",
		"placer.call(\"_place\"",
		"call(\"face_towards\"",
	]:
		assert_false(source.contains(banned), "Crown segment must not use bypass '%s'" % banned)
	for required in [
		"Input.parse_input_event",
		"Input.action_press",
		"winning_provider",
		"CraftInteractable",
		"_recipe_ids",
		"build_shortcut",
		"menu_tab_right",
		"build_place",
		"_ghost_ok",
		"arch_twin",
		"stormwood:crown_arch_built",
		"stormwood:named:capacitor_alpha:cleared",
	]:
		assert_true(source.contains(required), "Crown segment must retain live path '%s'" % required)


func _cost_map(raw: Array) -> Dictionary:
	var result := {}
	for value: Variant in raw:
		if value is Dictionary:
			result[str(value.get("id", ""))] = int(value.get("n", 0))
	return result
