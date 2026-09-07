extends SceneTree
## Production pickups, harvest nodes and LedgerRPC in an analytic-ground world
## fixture. Teleports test residency/claims; this is not a traversal/render test.
const SERVICE := preload("res://scripts/world/water_scene_pickups.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
class FixtureWorld extends Node3D:
	var field := FIELD.new()
	func local_rig() -> Node3D:
		return get_node("Player")
	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x, z)
class RemoteFixture extends Node3D:
	var net_realm := "water"
var failures: Array[String] = []
var checks := 0
func _init() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: ", message)
func frames() -> void:
	await process_frame
	await process_frame
func position_of(row: Dictionary) -> Vector3:
	return Vector3(row.position[0], row.position[1], row.position[2])
func run() -> void:
	var world := FixtureWorld.new()
	var player := Node3D.new()
	player.name = "Player"
	world.add_child(player)
	root.add_child(world)
	current_scene = world
	var game: Node = root.get_node("Game")
	game.set("current_realm", "water")
	game.get("local").character_id = "water-pickup-smoke-character"
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SERVICE.DATA))
	var ordinary: Dictionary = {}
	var candy: Dictionary = {}
	var herb: Dictionary = {}
	for row: Dictionary in data.pickups:
		if row.category == "skill_candy" and candy.is_empty():
			candy = row
		elif row.category == "potion" and ordinary.is_empty():
			ordinary = row
	for row: Dictionary in data.harvest:
		if row.item_id == "tide_bloom":
			herb = row
			break
	check(not ordinary.is_empty() and not candy.is_empty() and not herb.is_empty(), "Fixture finds ordinary, Candy and tool-free herb")
	if ordinary.is_empty() or candy.is_empty() or herb.is_empty():
		quit(1)
		return
	player.global_position = position_of(ordinary)
	var service := SERVICE.new()
	var census := service.build(world)
	check(census.ready and census.authored_pickups == 200 and census.authored_harvest == 182, "Catalogue builds all 382 identities")
	check(census.active_pickups + census.active_harvest <= service.active_cap_per_peer, "Local residency respects budget")
	var ordinary_node := service.node_for(ordinary.id)
	check(ordinary_node != null, "Nearby ordinary pickup physically instantiated")
	var before := int(game.get("inventory").count(ordinary.item_id))
	ordinary_node.call("_on_picked_up")
	await frames()
	check(game.get("inventory").count(ordinary.item_id) == before + int(ordinary.quantity), "Production claim awards exact ordinary amount")
	service.refresh()
	check(service.node_for(ordinary.id) == null, "Committed cache no longer resident")
	check(SERVICE.CACHE.was_taken(game, ordinary.item_id, str(ordinary.id).trim_prefix("water:"), "water"), "Ordinary receipt is durable world state")
	service.restore_progression_from_game(game)
	check(service.node_for(ordinary.id) == null, "Restore does not resurrect claimed cache")
	player.global_position = position_of(herb)
	service.refresh()
	var herb_node := service.node_for(herb.id)
	check(herb_node != null, "Nearby production harvest body instantiates")
	before = game.get("inventory").count(herb.item_id)
	if herb_node != null:
		herb_node.call("gather", "")
	await frames()
	check(game.get("inventory").count(herb.item_id) == before + int(herb.get("yield", 1)), "Production harvest grants configured resource")
	check(SERVICE.HARVEST.was_taken(game, "order:" + str(herb.id)), "Harvest receipt persists under Water identity")
	player.global_position = position_of(candy)
	service.refresh()
	var candy_node := service.node_for(candy.id)
	check(candy_node != null, "Personal Candy physically instantiates")
	var saved_slots: Array = []
	for index in game.get("inventory").slot_count():
		saved_slots.append(game.get("inventory").stack_at(index))
		game.get("inventory").set_slot(index, {"id": "wood", "n": 99})
	if candy_node != null:
		candy_node.call("_on_picked_up")
	check(not game.get("local").flags.has(SERVICE.PERSONAL.personal_flag(candy.id)), "Full inventory preserves personal find")
	check(candy_node != null and not candy_node.is_queued_for_deletion(), "Full inventory leaves Candy available")
	for index in saved_slots.size():
		game.get("inventory").set_slot(index, null if saved_slots[index].is_empty() else saved_slots[index])
	var skills_before: Dictionary = game.get("local").skills.save_data().duplicate(true)
	# Simulate the asynchronous refusal signal clients receive from the host.
	candy_node.set("_claiming", true)
	game.get("ledger").intent_refused.emit("water_personal_pickup", "too_far", "Move closer.", {})
	check(not candy_node.get("_claiming"), "Remote refusal releases Candy interaction for retry")
	before = game.get("inventory").count(candy.item_id)
	if candy_node != null:
		candy_node.call("_on_picked_up")
	await frames()
	check(game.get("inventory").count(candy.item_id) == before + int(candy.quantity), "Personal Candy production LedgerRPC awards owning inventory")
	check(game.get("local").flags.has(SERVICE.PERSONAL.personal_flag(candy.id)), "Personal Candy portable receipt recorded")
	check(game.get("local").skills.save_data() == skills_before, "Picking up Candy grants no skill XP")
	service.restore_progression_from_game(game)
	check(service.node_for(candy.id) == null, "Personal receipt survives runtime reconstruction")
	# Residency includes another Water peer thousands of metres away.
	var remote := RemoteFixture.new()
	world.add_child(remote)
	remote.add_to_group("remote_trainer")
	var far_row: Dictionary = data.pickups.back()
	remote.global_position = position_of(far_row)
	service.refresh()
	check(service.node_for(far_row.id) != null, "Distant Water peer keeps its island pickups resident")
	remote.net_realm = "stormwood"
	service.refresh()
	check(service.node_for(far_row.id) == null, "Peer in another realm does not retain Water objects")
	check(service.census().errors.is_empty(), "No registration or ground errors in visited slices")
	service.residency_radius_m = 100000.0
	service.active_cap_per_peer = 382
	service.refresh()
	var all := service.census()
	check(all.active_pickups == 198 and all.active_harvest == 181 and all.errors.is_empty(), "Every remaining authored pickup and harvest body builds with registered items and dry ground")
	print("Water pickup smoke: ", checks, " checks, ", failures.size(), " failures; census=", service.census())
	world.queue_free()
	await frames()
	# Production gather sound must finish before the audio server is torn down.
	await create_timer(1.5).timeout
	quit(0 if failures.is_empty() else 1)
