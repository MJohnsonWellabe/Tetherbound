extends SceneTree
## Actual PlayerDeath/DownedState/storage behavior with analytic terrain and a
## stationary rig fixture. The simulated two-peer switch is not transport proof.
const DEATH := preload("res://scripts/world/water_player_death.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const SWIM := preload("res://scripts/player/swim_controller.gd")
class WorldFixture extends Node3D:
	var field := FIELD.new()
	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x, z)
class PlayerFixture extends CharacterBody3D:
	signal died()
	var vitals := preload("res://scripts/player/player_vitals.gd").new()
	var swim_controller: Node
	var locomotion := true
	var carrier_node: Node3D
	func set_locomotion_enabled(value: bool) -> void:
		locomotion = value
	func set_carrier(value: Node3D) -> void:
		carrier_node = value
class DownedFixture extends "res://scripts/player/downed_state.gd":
	var two_peers := false
	func _multi_peer() -> bool:
		return two_peers
	func _broadcast_downed() -> void:
		pass
	func _broadcast_up() -> void:
		pass
class FailingJournal extends RefCounted:
	func save_character(_game: Object, _id: String) -> bool: return true
	func save_world(_game: Object, _id: String) -> bool: return false
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var game := root.get_node("Game")
	game.set("current_realm", "water")
	game.get("local").character_id = "water-death-owner"
	var downed := DownedFixture.new()
	downed.name = "DownedState"
	game.add_child(downed)
	var world := WorldFixture.new()
	root.add_child(world)
	current_scene = world
	var player := PlayerFixture.new()
	player.name = "Player"
	world.add_child(player)
	var swim := SWIM.new()
	player.add_child(swim)
	player.swim_controller = swim
	var service := DEATH.new()
	world.add_child(service)
	var fallback := Vector3(0, world.ground_height_at(0, 0) + 1, 0)
	service.build(world, player, fallback)
	check(downed.get("_death_handler").get_object() == service, "Production downed timeout targets Water death handler")
	check(service.recovery_position(game, Vector3.ZERO).distance_to(fallback) < 0.01, "No landing history recovers at First Shore")
	var config := FIELD.load_config()
	var center: Array = config.islands[1].center_xz_m
	var anchor := Vector3(float(center[0]), world.ground_height_at(center[0], center[1]), float(center[1]))
	swim.state.reach_land(anchor)
	check(service.recovery_position(game, Vector3.ZERO).distance_to(anchor + Vector3.UP) < 0.01, "Owned second-island safe landing determines recovery")
	game.get("placed_buildings").append({"id": "bedroll", "realm": "stormwood", "position": [0, 36, 0]})
	check(service.recovery_position(game, Vector3.ZERO).distance_to(anchor + Vector3.UP) < 0.01, "Other-realm bed cannot teleport the Water player")
	game.get("placed_buildings").append({"id": "bedroll", "realm": "water", "position": [200, -40, 260]})
	check(service.recovery_position(game, Vector3.ZERO).distance_to(anchor + Vector3.UP) < 0.01, "Submerged bed cannot become recovery trap")
	game.get("placed_buildings").append({"id": "bedroll", "realm": "water", "position": [0, 36, 0]})
	var bed_result := service.recovery_position(game, Vector3.ZERO)
	check(Vector2(bed_result.x, bed_result.z) == Vector2(2, 2), "Valid Water bed retains existing home priority with clearance")
	game.get("placed_buildings").clear()
	# Downed revive is not a death: inventory and world records stay intact.
	game.get("inventory").add("wood", 3)
	var skills_before: Dictionary = game.get("local").skills.save_data().duplicate(true)
	player.global_position = Vector3(200, -0.7, 260)
	check(world.ground_height_at(200, 260) < -2.0, "Drowning fixture is over confirmed deep water")
	swim.state.enter_water(false, 0)
	swim.state.drowning = true
	player.vitals.health = 0
	downed.two_peers = true
	player.died.emit()
	check(downed.is_downed() and game.get("death_satchels").is_empty() and game.get("inventory").count("wood") == 3, "Downed window delays satchel and inventory loss")
	downed.call("_end", true)
	check(not downed.is_downed() and player.vitals.health > 0 and game.get("death_satchels").is_empty(), "Teammate revive avoids death entirely")
	player.vitals.health = 0
	player.died.emit()
	downed.call("_tick_window", downed.window_s + 1.0)
	check(game.get("death_satchels").size() == 1 and game.get("inventory").count("wood") == 0, "Expired downed window runs ordinary inventory drop exactly once")
	player.died.emit()
	check(game.get("death_satchels").size() == 1, "Duplicate lethal signal during fade cannot create another bag")
	await create_timer(1.8).timeout
	check(player.global_position.distance_to(anchor + Vector3.UP) < 0.01, "Fade recovers on owned island")
	check(swim.state.mode == swim.STATE.Mode.LAND and not swim.state.drowning and swim.state.stamina_fraction == 1.0 and player.vitals.stamina == player.vitals.max_stamina, "Respawn clears aquatic mode and restores actual stamina")
	check(player.locomotion and player.velocity == Vector3.ZERO, "Respawn restores locomotion and stops old movement")
	var first: Dictionary = game.get("death_satchels")[0]
	check(first.owner == "water-death-owner" and first.realm == "water" and absf(first.position[1] - 0.15) < 0.001 and first.position[2] == 260.0, "Drowned satchel persists owner and surface position at death X/Z")
	var bags: Array = get_nodes_in_group(DEATH.DEATH_SATCHEL.GROUP)
	check(bags.size() == 1 and bags[0].can_open() and bags[0].state.inventory.count("wood") == 3, "Production owned satchel contains all carried stacks")
	game.get("local").character_id = "other-character"
	check(not bags[0].can_open(), "Other character cannot open the drowned owner's satchel")
	game.get("local").character_id = "water-death-owner"
	# A second solo death leaves the first bag exactly where it was.
	downed.two_peers = false
	game.get("inventory").add("reed_fiber", 2)
	player.global_position = Vector3(220, -0.7, 260)
	swim.state.enter_water(false, 0)
	player.vitals.health = 0
	player.died.emit()
	await create_timer(1.8).timeout
	check(game.get("death_satchels").size() == 2 and game.get("death_satchels")[0].position == first.position, "Multiple surface satchels coexist without moving older bag")
	service.sync_state_to_game(game)
	var roundtrip: Array = JSON.parse_string(JSON.stringify(game.get("death_satchels")))
	game.get("death_satchels").assign(roundtrip)
	service.restore_from_game(game)
	await process_frame
	bags = get_nodes_in_group(DEATH.DEATH_SATCHEL.GROUP)
	check(bags.size() == 2, "JSON record reconstruction restores both bags once")
	var total_wood := 0
	var total_reed := 0
	for bag: Node in bags:
		total_wood += int(bag.state.inventory.count("wood"))
		total_reed += int(bag.state.inventory.count("reed_fiber"))
		check(bag.can_open() and absf(bag.global_position.y - 0.15) < 0.001, "Restored owned bag remains surface retrievable")
	check(total_wood == 3 and total_reed == 2, "Reconstruction preserves exact contents across deaths")
	var wood_bag: Node3D
	for bag: Node3D in bags:
		if bag.state.inventory.count("wood") == 3:
			wood_bag = bag
	player.global_position = wood_bag.global_position + Vector3(0, -0.85, 0.7)
	check(player.global_position.distance_to(wood_bag.get_node("Interactable").global_position) < 2.6, "Swimming body can reach floating satchel prompt without diving")
	wood_bag.get_node("Interactable").activated.emit()
	var panel: Node = DEATH.DEATH_SATCHEL._panel
	check(panel != null and panel.is_open(), "Actual floating satchel prompt opens production storage panel")
	var buttons: Array = panel.get("_withdraw_rows")
	check(not buttons.is_empty(), "Production panel exposes carried stack for recovery")
	if not buttons.is_empty():
		buttons[0].pressed.emit()
	check(game.get("inventory").count("wood") == 3 and wood_bag.state.inventory.count("wood") == 0, "Actual panel button recovers contents through ledger")
	panel.close()
	# Durable tool metadata survives deposit and withdrawal through the same path.
	game.get("inventory").add("pickaxe", 1)
	var tool_slot: int = game.get("inventory").find_slot("pickaxe")
	var tool: Dictionary = game.get("inventory").stack_at(tool_slot)
	tool.durability = 7
	tool.durability_bonus = 3
	game.get("inventory").set_slot(tool_slot, tool)
	check(wood_bag.submit_deposit("pickaxe", 1).ok, "Owner may deposit tool through satchel ledger")
	check(wood_bag.submit_withdraw("pickaxe", 1).ok, "Owner may retrieve same tool")
	tool = game.get("inventory").stack_at(game.get("inventory").find_slot("pickaxe"))
	check(tool.get("durability") == 7 and tool.get("durability_bonus") == 3, "Recovered tool retains wear and reinforcement")
	var uid: String = wood_bag.call("_record_uid")
	wood_bag.free()
	service.call("_on_satchel_delta", {"ops": [{"op": "satchel_add", "realm": "water", "uid": uid, "position": [200, 0.15, 260], "state": [{"id": "wood", "n": 3}]}]})
	service.sync_state_to_game(game)
	var index: int = game.get("world").call("death_satchel_index_of", uid)
	check(game.get("death_satchels")[index].state[0] == null, "Delayed creation presentation cannot resurrect withdrawn contents during save")
	var original_saver: RefCounted = game.get("save_system")
	game.set("save_system", FailingJournal.new())
	game.get("world").world_id = "water-smoke-journal-fixture"
	var count_before: int = game.get("death_satchels").size()
	var failed_drop: Dictionary = game.get("ledger").drop_satchel(player.global_position, "water")
	check(not failed_drop.ok and failed_drop.code == "journal_failed" and game.get("death_satchels").size() == count_before, "Failed world journal publishes no death record")
	check(game.get("inventory").count("wood") == 3 and game.get("inventory").count("pickaxe") == 1, "Failed creation journal refunds only its durable escrow")
	var failed_deposit: Dictionary = game.get("ledger").transfer_satchel(uid, "deposit", "pickaxe", 1)
	check(not failed_deposit.ok and failed_deposit.code == "journal_failed" and game.get("inventory").count("pickaxe") == 1, "Failed deposit journal preserves carried tool")
	var reed_uid: String = game.get("death_satchels")[1].uid
	var reed_at: Array = game.get("death_satchels")[1].position
	player.global_position = Vector3(reed_at[0], reed_at[1], reed_at[2])
	var failed_withdraw: Dictionary = game.get("ledger").transfer_satchel(reed_uid, "withdraw", "reed_fiber", 2)
	check(not failed_withdraw.ok and failed_withdraw.code == "journal_failed" and game.get("inventory").count("reed_fiber") == 0, "Failed withdrawal journal grants nothing")
	check(game.get("death_satchels")[1].state[0].n == 2, "Failed withdrawal leaves authoritative container unchanged")
	game.set("save_system", original_saver)
	game.get("world").world_id = ""
	check(game.get("local").skills.save_data() == skills_before, "Death changes no skill progression")
	print("Water death smoke: ", checks, " checks, ", failures, " failures")
	world.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
