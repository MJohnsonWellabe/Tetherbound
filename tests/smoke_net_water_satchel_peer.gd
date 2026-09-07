extends SceneTree
## Two processes, actual ENet/LedgerRPC, stationary actor/proxy fixtures.
## Membership is supplied; no join UI or movement replication claim.
const DEATH := preload("res://scripts/world/water_player_death.gd")
class SessionFixture extends Node:
	func is_host() -> bool: return multiplayer.is_server()
	func is_multi_peer() -> bool: return multiplayer.get_peers().size() > 0
	func local_peer_id() -> int: return multiplayer.get_unique_id()
	func is_active() -> bool: return true
	func peers() -> Array: return []
class WorldFixture extends Node3D:
	var field := preload("res://scripts/world/water_heightfield.gd").new()
	func ground_height_at(x: float, z: float) -> float: return field.height_at(x, z)
class PlayerFixture extends CharacterBody3D:
	signal died()
	var vitals := preload("res://scripts/player/player_vitals.gd").new()
	var swim_controller: Node
	func set_locomotion_enabled(_value: bool) -> void: pass
class ProxyFixture extends Node3D:
	var net_realm := "water"
	var character_id := "client-owner"
	var peer_id := 0
class LostAckTransport extends "res://scripts/net/ledger_rpc.gd":
	var discard_transfer_reply := false
	var discarded := false
	@rpc("authority", "call_remote", "reliable", 1)
	func _rpc_delta(delta: Dictionary) -> void:
		for op: Dictionary in delta.get("ops", []):
			if discard_transfer_reply and str(op.get("op", "")) == "satchel_set":
				discard_transfer_reply = false
				discarded = true
				return # Explicit lost-ack fixture: host committed, client saw nothing.
		super._rpc_delta(delta)
var failures := 0
var checks := 0
var role := "host"
var game: Node
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", role, ": ", message)
func until(predicate: Callable, label: String) -> bool:
	var deadline := Time.get_ticks_msec() + 20000
	while not predicate.call():
		if Time.get_ticks_msec() > deadline:
			check(false, label + " timeout")
			return false
		await create_timer(0.03).timeout
	return true
func run() -> void:
	var port := 19481
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--role="): role = arg.trim_prefix("--role=")
		if arg.begins_with("--port="): port = int(arg.trim_prefix("--port="))
	game = root.get_node("Game")
	var old_session: Node = game.get("session")
	game.set("ledger", null)
	game.set("session", null)
	if old_session != null: old_session.free()
	var session := SessionFixture.new()
	session.name = "Session"
	game.add_child(session)
	game.set("session", session)
	var transport := LostAckTransport.new()
	transport.name = "LedgerRpc"
	session.add_child(transport)
	game.set("ledger", transport)
	transport.discard_transfer_reply = role == "client"
	game.set("current_realm", "water")
	game.get("local").character_id = "host-owner" if role == "host" else "client-owner"
	var world := WorldFixture.new()
	root.add_child(world)
	current_scene = world
	var player := PlayerFixture.new()
	player.name = "Player"
	world.add_child(player)
	player.global_position = Vector3(0, 37, 0) if role == "host" else Vector3(200, -0.7, 260)
	var swim := preload("res://scripts/player/swim_controller.gd").new()
	player.add_child(swim)
	player.swim_controller = swim
	var death := DEATH.new()
	world.add_child(death)
	death.build(world, player, Vector3(0, 37, 0))
	game.get_node("DownedState").window_s = 0.1
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, 1, 3) if role == "host" else peer.create_client("127.0.0.1", port, 3)
	check(error == OK, "ENet endpoint opens")
	root.multiplayer.multiplayer_peer = peer
	if not await until(func() -> bool: return root.multiplayer.get_peers().size() == 1, "peer connection"):
		quit(1)
		return
	if role == "host":
		var proxy := ProxyFixture.new()
		world.add_child(proxy)
		proxy.set_multiplayer_authority(root.multiplayer.get_peers()[0])
		proxy.peer_id = root.multiplayer.get_peers()[0]
		proxy.add_to_group("remote_trainer")
		proxy.global_position = Vector3(200, -0.7, 260)
		game.get("inventory").add("wood", 11)
		if await until(func() -> bool: return game.get("death_satchels").size() == 1, "remote death record"):
			var record: Dictionary = game.get("death_satchels")[0]
			check(record.owner == "client-owner" and record.realm == "water" and absf(record.position[1] - 0.15) < 0.001, "Client death becomes owned floating host-world record")
			var bags := get_nodes_in_group(DEATH.DEATH_SATCHEL.GROUP)
			check(bags.size() == 1 and not bags[0].can_open(), "Host sees bag owned by client")
			if not bags.is_empty():
				check(not bags[0].submit_withdraw("wood", 3).ok, "Host cannot steal client contents")
				await until(func() -> bool: return bags[0].state.inventory.count("wood") == 0, "remote retrieval delta")
			check(game.get("inventory").count("wood") == 11, "Client retrieval leaves host inventory unchanged")
			var saved: Dictionary = JSON.parse_string(JSON.stringify(game.get("world").save_data()))
			var restored := preload("res://autoload/world_state.gd").new()
			restored.load_data(saved)
			check(restored.death_satchels.size() == 1 and restored.death_satchels[0].owner == "client-owner", "Host save retains client-created record")
		await create_timer(5.0).timeout
	else:
		await create_timer(0.4).timeout
		game.get("inventory").add("wood", 3)
		swim.state.enter_water(false, 0)
		player.vitals.health = 0
		player.died.emit()
		if await until(func() -> bool: return game.get("death_satchels").size() == 1, "creation broadcast"):
			check(game.get("inventory").count("wood") == 0, "Client drops carried stack once")
			await create_timer(1.8).timeout
			var bags := get_nodes_in_group(DEATH.DEATH_SATCHEL.GROUP)
			check(bags.size() == 1 and bags[0].can_open(), "Client reconstructs owned bag from host delta")
			player.global_position = Vector3(200, -0.7, 260)
			var result: Dictionary = bags[0].submit_withdraw("wood", 3)
			check(result.get("pending", false), "Client transfer genuinely awaits host")
			bags[0].free()
			await until(func() -> bool: return game.get("inventory").count("wood") == 3, "owned retrieval")
			death.restore_from_game(game)
			bags = get_nodes_in_group(DEATH.DEATH_SATCHEL.GROUP)
			check(bags.size() == 1, "Scene node teardown before reply cannot lose personal settlement")
			check(transport.discarded, "Host-committed reply was deliberately lost; retry snapshot recovers it")
			check(bags[0].state.inventory.count("wood") == 0, "Retrieval empties client bag mirror")
			check(game.get("death_satchels")[0].state == bags[0].state.save_data(), "Client world record agrees with bag")
		await create_timer(0.5).timeout
	print("Water satchel ENet ", role, ": ", checks, " checks, ", failures, " failures")
	peer.close()
	world.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
