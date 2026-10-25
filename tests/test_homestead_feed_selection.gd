extends "res://tests/test_case.gd"
const HOME := preload("res://tools/earned_saves/wip_fights/homestead_common.gd")

func test_evolution_label_names_exact_destination() -> void:
	var row := {"nickname": "Mud", "status": "Lv 10", "choice": "evolve", "target": "ashtusk",
		"item_name": "Ground Feast", "choice_required": true}
	assert_eq(HOME.feed_label(row), "Mud · Lv 10 · Evolve to ashtusk")
	assert_false(HOME.feed_label(row) == "Mud · Lv 10 · Evolve to tuskroot")
	assert_false(HOME.feed_label(row) == "Mud · Lv 10 · Evolve to ashtusk_extra")

func test_stay_and_no_offer_labels_bind_the_consumed_feast() -> void:
	var row := {"nickname": "Mud", "status": "Lv 10", "choice": "stay", "target": "",
		"item_name": "Ground Feast", "choice_required": true}
	assert_eq(HOME.feed_label(row), "Mud · Lv 10 · Ground Feast · Stay (permanent this tier)")
	assert_false(HOME.feed_label(row).contains("Water Feast"))
	row.choice_required = false
	assert_eq(HOME.feed_label(row), "Mud · Lv 10 · Ground Feast")

func test_storage_receipt_requires_conserved_transfer_to_the_chest() -> void:
	assert_true(HOME.storage_transfer_matches(8, 0, 3, 11))
	assert_true(HOME.storage_transfer_matches(8, 5, 3, 6))
	assert_false(HOME.storage_transfer_matches(8, 0, 3, 3), "a disappearing Satchel stack is not storage")
	assert_false(HOME.storage_transfer_matches(8, 5, 3, 8), "the chest must receive exactly the removed quantity")
	assert_false(HOME.storage_transfer_matches(8, 8, 3, 3), "no transfer is not success")
	assert_false(HOME.storage_transfer_matches(8, 0, -1, 7), "missing chest state is not proof")

func test_storage_candidates_include_later_chests_but_exclude_other_worlds() -> void:
	var world := Node3D.new()
	var foreign := Node3D.new()
	var first := Node3D.new()
	var second := Node3D.new()
	var other := Node3D.new()
	var kitchen := Node3D.new()
	for chest: Node3D in [first, second, other]: chest.set_meta("building_id", "storage")
	kitchen.set_meta("building_id", "kitchen")
	world.add_child(first)
	world.add_child(second)
	world.add_child(kitchen)
	foreign.add_child(other)
	var nodes: Array[Node] = [first, other, kitchen, second]
	var selected := HOME.storage_chests(world, nodes)
	assert_eq(selected.size(), 2)
	assert_eq(selected[0], first)
	assert_eq(selected[1], second)
	world.free()
	foreign.free()

func test_evolve_planning_reserves_earned_catalyst_once_and_reuses_cooked_feast() -> void:
	var stock := {"sunstone": 1, "feast_t2_ground_heartstone": 1}
	assert_true(HOME.reserve_earned_feast(stock, "feast_t2_ground_heartstone", "heartstone"), "cooked feast needs no second catalyst")
	assert_false(HOME.reserve_earned_feast(stock, "feast_t2_ground_heartstone", "heartstone"), "same feast cannot serve two creatures")
	assert_true(HOME.reserve_earned_feast(stock, "feast_t2_ground_sunstone", "sunstone"), "owned alternate branch remains usable")
	assert_false(HOME.reserve_earned_feast(stock, "feast_t2_ground_sunstone", "sunstone"), "same catalyst cannot fund two recipes")
	assert_true(HOME.reserve_earned_feast(stock, "feast_t2_ground", ""), "renewable ordinary ingredients may still be gathered")

func test_cooked_alternate_precedes_spending_loose_catalyst_and_is_reserved_once() -> void:
	var recipes := {
		"heart": {"output": {"feast_heart": 1}},
		"sun": {"output": {"feast_sun": 1}},
		"plain": {"output": {"feast_plain": 1}}}
	var stock := {"heartstone": 1, "feast_sun": 1}
	assert_eq(HOME.feast_recipe_order(recipes, stock), ["sun", "heart", "plain"])
	assert_true(HOME.reserve_earned_feast(stock, "feast_sun", "sunstone"))
	assert_eq(stock.heartstone, 1, "using the cooked alternate preserves the loose catalyst")
	assert_eq(HOME.feast_recipe_order(recipes, stock), ["heart", "sun", "plain"])
	assert_false(HOME.reserve_earned_feast(stock, "feast_sun", "sunstone"))

func test_stay_reuses_only_cooked_catalysts_valid_for_the_offered_branches() -> void:
	var stock := {"feast_sun": 1, "heartstone": 1}
	var branches := [{"extra_ingredient": "sunstone"}]
	assert_true(HOME.stay_feast_available(stock, "feast_sun", "sunstone", branches))
	assert_false(HOME.stay_feast_available(stock, "feast_sun", "sunstone", []), "no evolution offer cannot consume a catalyst feast")
	assert_false(HOME.stay_feast_available(stock, "feast_sun", "sunstone", [{"extra_ingredient": "heartstone"}]))
	assert_false(HOME.stay_feast_available(stock, "feast_heart", "heartstone", [{"extra_ingredient": "heartstone"}]), "Stay must not spend a loose catalyst")
	assert_true(HOME.stay_feast_available(stock, "feast_plain", "", []))
	assert_true(HOME.reserve_earned_feast(stock, "feast_sun", "sunstone"))
	assert_false(HOME.stay_feast_available(stock, "feast_sun", "sunstone", branches))
	assert_eq(stock.heartstone, 1)

func test_earlier_stay_does_not_take_later_evolves_only_cooked_catalyst() -> void:
	var stay_uid := "creature-%032x" % 1
	var evolve_uid := "creature-%032x" % 2
	var state := {"party": [
		{"uid": stay_uid, "nickname": "Stays", "species_id": "mudsnout", "creature_type": "ground", "level": 20, "xp": 0},
		{"uid": evolve_uid, "nickname": "Evolves", "species_id": "mudsnout", "creature_type": "ground", "level": 20, "xp": 0}],
		"redesign_character": {"creatures": {
			stay_uid: {"cap_level": 20, "breakthroughs": [1], "evolution_choices": {}},
			evolve_uid: {"cap_level": 20, "breakthroughs": [1], "evolution_choices": {}}}}}
	var stock := {"feast_t2_ground_sunstone": 1, "ironwood": 2, "attuned_ground": 1, "berries": 6}
	var helper := HOME.new()
	var plan := helper._feed_plan_from_stock(state, stock, "feast_t2", {evolve_uid: "evolve"})
	assert_true(helper.failures.is_empty(), str(helper.failures))
	assert_eq(plan.feed.size(), 2)
	assert_true(plan.deferred.is_empty())
	if plan.feed.size() != 2: return
	assert_eq(plan.feed[0].uid, stay_uid, "actions retain original party order")
	assert_eq(plan.feed[0].choice, "stay")
	assert_eq(plan.feed[0].item, "feast_t2_ground", "Stay can cook the ordinary recipe")
	assert_eq(plan.feed[1].uid, evolve_uid)
	assert_eq(plan.feed[1].item, "feast_t2_ground_sunstone")
	assert_eq(plan.feed[1].target, "ashtusk")
	assert_eq(stock, {"feast_t2_ground_sunstone": 1, "ironwood": 2, "attuned_ground": 1, "berries": 6}, "planning cannot consume real stock")
	state.party.reverse()
	var reversed := helper._feed_plan_from_stock(state, stock, "feast_t2", {evolve_uid: "evolve"})
	assert_true(helper.failures.is_empty(), str(helper.failures))
	assert_eq(reversed.feed.size(), 2)
	if reversed.feed.size() != 2: return
	assert_eq(reversed.feed[0].item, "feast_t2_ground_sunstone")
	assert_eq(reversed.feed[1].item, "feast_t2_ground")


func test_station_candidates_reject_foreign_detached_and_deleted_buildings() -> void:
	var world := Node3D.new()
	var old_world := Node3D.new()
	var foreign := Node3D.new()
	var detached := Node3D.new()
	var pending := Node3D.new()
	var current := Node3D.new()
	var forge := Node3D.new()
	for node: Node3D in [foreign, detached, pending, current]: node.set_meta("building_id", "kitchen")
	forge.set_meta("building_id", "forge")
	old_world.add_child(foreign)
	world.add_child(pending)
	world.add_child(current)
	world.add_child(forge)
	pending.queue_free()
	var nodes: Array[Node] = [foreign, detached, pending, forge, current]
	var kitchens := HOME.placed_buildings(world, nodes, "kitchen")
	assert_eq(kitchens.size(), 1, "a stale earlier Kitchen cannot hide the current one")
	if kitchens.size() == 1: assert_eq(kitchens[0], current)
	assert_eq(HOME.placed_buildings(world, nodes, "forge"), [forge])
	assert_eq(HOME.placed_buildings(world, nodes), [forge, current], "placement space and result checks use the same live-world scope")
	assert_true(HOME.placed_buildings(null, nodes).is_empty())
	detached.free()
	old_world.free()
	world.free()

func test_station_candidates_refuse_a_world_queued_for_deletion() -> void:
	var world := Node3D.new()
	var kitchen := Node3D.new()
	kitchen.set_meta("building_id", "kitchen")
	world.add_child(kitchen)
	world.queue_free()
	var nodes: Array[Node] = [kitchen]
	assert_true(HOME.placed_buildings(world, nodes, "kitchen").is_empty())
	world.free()

## A station placed beside the Kitchen must leave its tier 1-4 attachment
## sockets clear: the Forge east of it covered tier 3 (training_t4_kitchen_3).
func test_plot_spots_keep_the_kitchen_attachment_sockets_clear() -> void:
	var sockets: Array[Vector2] = HOME.kitchen_sockets(Vector2(-10.0, 14.0), 0.0)
	assert_eq(sockets.size(), 4)
	assert_true(sockets[0].distance_to(Vector2(-13.0, 14.0)) < 0.01, "tier 1 west")
	assert_true(sockets[1].distance_to(Vector2(-10.0, 16.5)) < 0.01, "tier 2 north")
	assert_true(sockets[2].distance_to(Vector2(-7.0, 14.0)) < 0.01, "tier 3 east")
	assert_true(sockets[3].distance_to(Vector2(-10.0, 11.5)) < 0.01, "tier 4 south")
	assert_false(HOME.spot_clear_of_sockets(Vector2(-6.0, 14.0), sockets), "the old Forge spot covers tier 3")
	assert_false(HOME.spot_clear_of_sockets(Vector2(-10.0, 10.0), sockets), "covers tier 4")
	assert_true(HOME.spot_clear_of_sockets(Vector2(-8.0, 20.0), sockets))
	assert_true(HOME.spot_clear_of_sockets(Vector2(-12.0, 20.0), sockets), "the Altar spot")

## A save made before the socket rule keeps its Forge on the tier-3 socket;
## kitchen() dismantles a non-attachment building found there.
func test_only_non_attachment_buildings_count_as_socket_blockers() -> void:
	var cfg: Dictionary = preload("res://scripts/build/station_rules.gd").config()
	assert_false(preload("res://scripts/build/station_rules.gd").attachment(cfg, "kitchen_meadows").is_empty())
	assert_true(preload("res://scripts/build/station_rules.gd").attachment(cfg, "forge").is_empty())
	assert_eq(HOME.DISMANTLE_STANDOFFS.size(), 5)

## From behind a station, the walk to its prompt comes round the player's own
## side to the working face (training_t4_feed: the Kitchen's north-face prompt
## from the south-west).
func test_prompt_walk_comes_round_to_the_working_face() -> void:
	var kitchen := Vector3(-10.0, 0.9, 14.0)
	var prompt := Vector3(-10.0, 1.8, 14.95)
	var side := HOME.front_side_waypoint(prompt, kitchen, Vector3(-11.6, 0.9, 12.4))
	assert_true(side != Vector3.INF)
	assert_true(side.x < -11.2, "west of the Kitchen body, on the player's side")
	assert_true(side.z > 14.7 and side.z < 15.95, "in the pocket before the tier-2 attachment")
	var north := HOME.front_side_waypoint(prompt, kitchen, Vector3(-10.6, 0.9, 21.6))
	assert_true(north.x < -10.55 and north.z < 15.95, "from the north: into the pocket beside the tier-2 attachment")
	assert_eq(HOME.front_side_waypoint(prompt, kitchen, Vector3(-10.5, 0.9, 15.6)), Vector3.INF, "already at the face")
	assert_true(HOME.front_side_waypoint(prompt, kitchen, Vector3(-8.0, 0.9, 12.0)).x > -8.8, "east side from the south-east")
