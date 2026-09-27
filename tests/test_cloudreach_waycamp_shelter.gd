extends "res://tests/test_case.gd"

## F07#0 (WORLD §11 Lower Cliffs, coordinator ruling (b) on #356): Waycamp
## shelter upgrades Galefoot Waycamp. Neri's canvas bundle -> 4 Gale Fiber
## (optional) -> a companion settled in Galefoot's existing creature bed.

const RULES := preload("res://scripts/world/cloudreach_physical_rules.gd")
const RUNTIME := preload("res://scripts/world/cloudreach_physical_runtime.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const STEPS := ["waycamp_canvas_bundle", "waycamp_shelter_supply", "waycamp_shelter_rest"]


class FakeGame extends Node:
	var party: RefCounted = PARTY.new()


func _specs() -> Dictionary:
	var out := {}
	for spec: Dictionary in RULES.read(RUNTIME.DATA_PATH)["interactions"]:
		out[str(spec.id)] = spec
	return out


func _chain() -> Dictionary:
	for chain: Dictionary in RULES.read(RUNTIME.CHAPTER_PATH).get("side_chains", []):
		if str(chain.id) == "waycamp_shelter":
			return chain
	return {}


func test_the_chain_completes_in_order_through_real_events() -> void:
	var chapter := RULES.read(RUNTIME.CHAPTER_PATH)
	var specs := _specs()
	var flags: RefCounted = FLAGS.new()
	flags.set_flag("cloudreach_crisis_learned")
	for id: String in STEPS:
		assert_true(RULES.available(flags, specs[id]), id + " is available once its predecessor is done")
		flags.set_flag(str(specs[id].completion_flag))
		assert_false(RULES.available(flags, specs[id]), id + " is one-time")
	# Out of order is refused.
	var fresh: RefCounted = FLAGS.new()
	fresh.set_flag("cloudreach_crisis_learned")
	assert_false(bool(LOGIC.dispatch(fresh, chapter, str(specs["waycamp_shelter_rest"].event))["accepted"]), "no skipping to the end")
	for id: String in STEPS:
		var result: Dictionary = LOGIC.dispatch(fresh, chapter, str(specs[id].event))
		assert_true(bool(result["accepted"]), id + " event accepted in order")
		assert_true(fresh.has(str(specs[id].completion_flag)), id + " sets its step flag")
	assert_true(fresh.has("side_waycamp_shelter_complete"))
	assert_eq(str(_chain().get("completion_flag", "")), "side_waycamp_shelter_complete")


func test_the_shelter_costs_four_fiber_and_leaves_a_rain_cover() -> void:
	var supply: Dictionary = _specs()["waycamp_shelter_supply"]
	assert_eq(str(supply.cost.item_id), "gale_fiber")
	assert_eq(int(supply.cost.count), 4)
	assert_true(ResourceLoader.exists(str(supply.completion_decor.scene)), "the rain cover is an installed camp-family scene")


func test_it_upgrades_galefoot_and_adds_no_camp() -> void:
	var camps: Array = RULES.read(RUNTIME.CHAPTER_PATH)["camping_contract"]["camps"]
	assert_eq(camps.size(), 5, "no new camp (ruling (b))")
	var galefoot: Dictionary = {}
	for camp: Dictionary in camps:
		if str(camp.id) == "galefoot_waycamp":
			galefoot = camp
	assert_eq(int(galefoot.creature_bed.bed_index), int(_specs()["waycamp_shelter_rest"].requires_resting_bed_index),
		"the rest step uses Galefoot's own creature bed")
	for id: String in STEPS:
		var at: Vector3 = RULES.vec(_specs()[id].position)
		if id != "waycamp_canvas_bundle":
			assert_true(Vector2(at.x + 280.0, at.z - 520.0).length() < 20.0, id + " stands at Galefoot")


func test_it_is_optional_and_gates_no_story() -> void:
	var chapter := RULES.read(RUNTIME.CHAPTER_PATH)
	var text := JSON.stringify(chapter.get("main_story", chapter.get("acts", {})))
	for flag: String in ["side_waycamp_bundle_found", "side_waycamp_shelter_supplied", "side_waycamp_shelter_complete"]:
		assert_false(text.contains(flag), flag + " never gates the main story")
	for spec: Dictionary in RULES.read(RUNTIME.DATA_PATH)["interactions"]:
		if not str(spec.id).begins_with("waycamp_"):
			for flag: String in spec.get("requires_flags", []):
				assert_false(flag.begins_with("side_waycamp_"), str(spec.id) + " does not wait on the shelter")


func test_the_bed_check_reads_this_peers_resting_companion() -> void:
	var runtime: Node = RUNTIME.new()
	var game := FakeGame.new()
	runtime.set("_game", game)
	var member: RefCounted = SPECIES.spawn("sparkit")
	game.party.add(member)
	assert_false(bool(runtime.call("party_resting_in_bed", -21)), "nobody resting")
	member.set("resting", true)
	member.set("rest_bed_index", -21)
	assert_true(bool(runtime.call("party_resting_in_bed", -21)), "a companion in Galefoot's bed")
	assert_false(bool(runtime.call("party_resting_in_bed", -25)), "a different camp's bed does not count")
	runtime.free()
	game.free()


func test_the_sheltered_bed_pays_its_rest_xp_once_more() -> void:
	var cfg: Dictionary = RULES.read(RUNTIME.DATA_PATH)["sheltered_rest"]
	assert_eq(int(cfg.bed_index), int(_specs()["waycamp_shelter_rest"].requires_resting_bed_index), "Galefoot's own bed")
	var progression := preload("res://scripts/creatures/progression.gd")
	var rest_xp: int = progression.rest_xp(progression.config())
	assert_true(rest_xp > 0, "the bed pays rest XP")
	var flags: RefCounted = FLAGS.new()
	var member: RefCounted = SPECIES.spawn("sparkit")
	assert_eq(RUNTIME.sheltered_rest_xp(member, -21, flags, cfg), 0, "nothing before the shelter is built")
	flags.set_flag("side_waycamp_shelter_complete")
	assert_eq(RUNTIME.sheltered_rest_xp(member, -25, flags, cfg), 0, "another camp's bed pays nothing extra")
	assert_eq(RUNTIME.sheltered_rest_xp(member, -1, flags, cfg), 0, "no bed pays nothing extra")
	var before := int(member.get("xp"))
	assert_eq(RUNTIME.sheltered_rest_xp(member, -21, flags, cfg), int(round(rest_xp * float(cfg.rest_xp_multiplier))), "the sheltered bed pays rest XP again")
	assert_eq(int(member.get("xp")), before + rest_xp, "the companion actually gains it")
