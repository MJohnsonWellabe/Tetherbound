extends Node

var role := ""
var mode := ""
var port := 0
var realm: Node
var actors: Node
var spawner: MultiplayerSpawner
var body: Node
var remote_id := 0
var despawn_seen := false
var checks := 0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	role = args[0]
	mode = args[1]
	port = int(args[2])
	realm = Node.new()
	realm.name = "Realm"
	add_child(realm)
	actors = Node.new()
	actors.name = "Actors"
	realm.add_child(actors)
	spawner = MultiplayerSpawner.new()
	spawner.name = "Spawner"
	spawner.spawn_path = NodePath("../Realm/Actors")
	spawner.spawn_function = _spawn
	add_child(spawner)
	spawner.spawned.connect(_received_spawn)
	spawner.despawned.connect(_received_despawn)
	var enet := ENetMultiplayerPeer.new()
	var result := enet.create_server(port, 1) if role == "host" else enet.create_client("127.0.0.1", port)
	if result != OK:
		_fail("ENet create failed %s" % result)
		return
	multiplayer.multiplayer_peer = enet
	if role == "client":
		multiplayer.connected_to_server.connect(func(): ready_peer.rpc_id(1))
	get_tree().create_timer(15.0).timeout.connect(func(): _fail("internal deadline"))
	print("PROBE BOOT %s %s" % [role, mode])

func _spawn(_data: Variant) -> Node:
	var node := Node3D.new()
	node.name = "RemoteBody"
	return node

@rpc("any_peer", "call_remote", "reliable")
func ready_peer() -> void:
	remote_id = multiplayer.get_remote_sender_id()
	body = spawner.spawn({})
	_check(is_instance_valid(body), "host authored body spawned")

func _received_spawn(node: Node) -> void:
	body = node
	_check(role == "client" and is_instance_valid(body), "client received real replicated body")
	_after_spawn.call_deferred()

func _after_spawn() -> void:
	if mode == "negative":
		realm.free()
		_check(not is_instance_valid(body), "client removed receiving subtree before host despawn")
		client_removed.rpc_id(1)
	else:
		request_host_despawn.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func client_removed() -> void:
	_check(is_instance_valid(body), "host body still live after client subtree removal")
	body.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not is_instance_valid(body), "host authoritative body freed after client acknowledgement")
	# This marker bounds observation; no ordering claim depends on this RPC.
	observe_negative.rpc_id(remote_id)

@rpc("any_peer", "call_remote", "reliable")
func request_host_despawn() -> void:
	_check(is_instance_valid(body), "host body live until explicit control request")
	body.queue_free()

func _received_despawn(node: Node) -> void:
	despawn_seen = true
	_check(mode == "control" and node == body, "client consumed actual host despawn signal")
	_after_despawn.call_deferred()

func _after_despawn() -> void:
	await get_tree().process_frame
	_check(not is_instance_valid(body), "remote body gone before local realm teardown")
	realm.free()
	_check(despawn_seen and not is_instance_valid(realm), "realm removed only after actual host despawn")
	done.rpc_id(1, checks)
	await get_tree().create_timer(0.2).timeout
	print("PROBE PASS client control checks=%d" % checks)
	get_tree().quit(0)

@rpc("authority", "call_remote", "reliable")
func observe_negative() -> void:
	await get_tree().create_timer(0.3).timeout
	_check(not despawn_seen, "locally deleted body cannot consume later host despawn")
	done.rpc_id(1, checks)
	await get_tree().create_timer(0.2).timeout
	print("PROBE PASS client negative checks=%d (expected native rejection required separately)" % checks)
	get_tree().quit(0)

@rpc("any_peer", "call_remote", "reliable")
func done(client_checks: int) -> void:
	print("PROBE PASS host %s checks=%d client_checks=%d" % [mode, checks, client_checks])
	await get_tree().create_timer(0.4).timeout
	get_tree().quit(0)

func _check(condition: bool, label: String) -> void:
	if not condition:
		_fail(label)
		return
	checks += 1
	print("PROBE CHECK %s: %s" % [role, label])

func _fail(label: String) -> void:
	push_error("PROBE FAILURE %s: %s" % [role, label])
	get_tree().quit(1)
