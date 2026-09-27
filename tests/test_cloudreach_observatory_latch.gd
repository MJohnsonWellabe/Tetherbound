extends "res://tests/test_case.gd"

## F07#0 Summit: Observatory return latch (WORLD §11, coordinator ruling (b) on
## #356). Sight the latch from the plateau fork, throw it at the summit loop's
## west pad, and the existing Fly-only drop between them gains a walkable stone
## stair (`observatory_latch_stair`, built by `side_observatory_latch_complete`).

const RULES := preload("res://scripts/world/cloudreach_physical_rules.gd")
const RUNTIME := preload("res://scripts/world/cloudreach_physical_runtime.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const WORLD_PATH := "res://data/config/cloudreach_world.json"
const LATCH := "side_observatory_latch_complete"
const STEPS := ["observatory_latch_sighting", "observatory_return_latch"]


func _specs() -> Dictionary:
	var out := {}
	for spec: Dictionary in RULES.read(RUNTIME.DATA_PATH)["interactions"]:
		out[str(spec.id)] = spec
	return out


func _by_id(list: Array) -> Dictionary:
	var out := {}
	for entry: Dictionary in list:
		out[str(entry.id)] = entry
	return out


func test_the_chain_runs_in_order_and_needs_the_summit_open() -> void:
	var chapter := RULES.read(RUNTIME.CHAPTER_PATH)
	var specs := _specs()
	var flags: RefCounted = FLAGS.new()
	flags.set_flag("cloudreach_upper_route_unlocked")
	assert_true(RULES.available(flags, specs["observatory_latch_sighting"]), "sighted from the upper route")
	assert_false(bool(LOGIC.dispatch(flags, chapter, str(specs["observatory_return_latch"].event))["accepted"]), "no latch before the sighting")
	assert_true(bool(LOGIC.dispatch(flags, chapter, str(specs["observatory_latch_sighting"].event))["accepted"]))
	assert_true(flags.has("side_observatory_latch_sighted"))
	assert_false(RULES.available(flags, specs["observatory_return_latch"]), "the summit's far side waits on the upper anchors")
	flags.set_flag("cloudreach_upper_anchors_disabled")
	assert_true(RULES.available(flags, specs["observatory_return_latch"]))
	assert_true(bool(LOGIC.dispatch(flags, chapter, str(specs["observatory_return_latch"].event))["accepted"]))
	assert_true(flags.has(LATCH), "the latch is saved world state")
	assert_false(RULES.available(flags, specs["observatory_return_latch"]), "one-time")


func test_the_latch_builds_a_walkable_descent_between_existing_pads() -> void:
	var world: Dictionary = RULES.read(WORLD_PATH)
	var route: Dictionary = _by_id(world.routes).get("observatory_latch_descent", {})
	assert_eq(str(route.get("requires_unlock", "")), LATCH, "the route opens with the latch")
	assert_eq(str(route.get("traversal_mode", "")), "ground")
	var bridge: Dictionary = _by_id(world.bridges).get("observatory_latch_stair", {})
	assert_eq(str(bridge.get("built_by_flag", "")), LATCH, "the deck exists only after the latch")
	assert_eq(str(bridge.get("route_id", "")), "observatory_latch_descent")
	assert_eq(bridge.endpoints, route.polyline, "the stair is the whole route: no new ground crown")
	# Both ends are existing route pads: the summit loop and the plateau fork.
	var summit: Array = _by_id(world.routes).summit_overlook_loop.polyline
	var plateau: Array = _by_id(world.routes).upper_plateau_circuit.polyline
	assert_true(summit.has(route.polyline[0]), "top pad is on the summit loop")
	assert_true(plateau.has(route.polyline[-1]), "bottom pad is the plateau fork")
	var a := RULES.vec(route.polyline[0])
	var b := RULES.vec(route.polyline[-1])
	var slope := rad_to_deg(atan2(a.y - b.y, Vector2(a.x - b.x, a.z - b.z).length()))
	assert_true(slope < 20.0, "a walkable descent (%.1f deg)" % slope)
	# The latch stands at the top pad; the sighting at the fork.
	var specs := _specs()
	assert_true(RULES.vec(specs["observatory_return_latch"].position).distance_to(a) < 8.0)
	assert_true(RULES.vec(specs["observatory_latch_sighting"].position).distance_to(b) < 8.0)
	assert_eq(str(specs["observatory_return_latch"].kind), "latch")


func test_it_is_optional() -> void:
	var chapter := RULES.read(RUNTIME.CHAPTER_PATH)
	var text := JSON.stringify(chapter.get("main_story", chapter.get("acts", {})))
	assert_false(text.contains("side_observatory_latch"), "never gates the story")
	for spec: Dictionary in RULES.read(RUNTIME.DATA_PATH)["interactions"]:
		if not STEPS.has(str(spec.id)):
			for flag: String in spec.get("requires_flags", []):
				assert_false(flag.begins_with("side_observatory_latch"), str(spec.id) + " does not wait on the latch")
