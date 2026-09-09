extends Node

const TOKEN := 7
var role := ""
var port := 0
var ids: Dictionary = {"host": 1}
var bodies: Dictionary = {}
var received: Dictionary = {}
var outgoing_denied: Dictionary = {}
var admission_denied: Dictionary = {}
var ready_roles: Dictionary = {}
var fences: Dictionary = {}
var old_realm: Node
var old_spawner: MultiplayerSpawner
var destination: Node
var destination_spawner: MultiplayerSpawner
var destination_body: Node3D
var ready_sent := false
var retiring := false
var host_fence_seen := false
var transition_started := false
var destination_ready := false
var continuing_baseline := 0.0
var host_baseline := 0.0
var checks := 0
var failed := false

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	role = args[0]
	port = int(args[1])
	old_realm = _realm("OldRealm")
	old_spawner = _spawner("OldSpawner", "../OldRealm/Actors", false)
	if role != "departing":
		_build_destination()
	var enet := ENetMultiplayerPeer.new()
	var result := enet.create_server(port, 2) if role == "host" else enet.create_client("127.0.0.1", port)
	if result != OK:
		_fail("ENet create %d" % result)
		return
	multiplayer.multiplayer_peer = enet
	if role != "host":
		multiplayer.connected_to_server.connect(func(): hello.rpc_id(1, role))
	get_tree().create_timer(20.0).timeout.connect(func(): _fail("internal deadline"))
	print("PROTOCOL BOOT %s" % role)

func _realm(label: String) -> Node:
	var realm := Node.new()
	realm.name = label
	add_child(realm)
	var actors := Node.new()
	actors.name = "Actors"
	realm.add_child(actors)
	return realm

func _spawner(label: String, path: String, arriving: bool) -> MultiplayerSpawner:
	var spawn := MultiplayerSpawner.new()
	spawn.name = label
	spawn.spawn_path = NodePath(path)
	spawn.spawn_function = func(data: Variant) -> Node: return _make_body(data, arriving)
	add_child(spawn)
	spawn.spawned.connect(func(node: Node): _spawn_received(node, arriving))
	spawn.despawned.connect(_despawn_received)
	return spawn

func _build_destination() -> void:
	destination = _realm("Destination")
	destination_spawner = _spawner("DestinationSpawner", "../Destination/Actors", true)

func _make_body(data: Variant, arriving: bool) -> Node:
	var owner := int(data.owner)
	var node := Node3D.new()
	node.name = "Body_%d" % owner
	node.set_meta("owner", owner)
	node.set_meta("arriving", arriving)
	node.set_multiplayer_authority(owner)
	var state := MultiplayerSynchronizer.new()
	state.name = "State"
	state.set_multiplayer_authority(owner)
	var config := SceneReplicationConfig.new()
	config.add_property(NodePath(".:position"))
	config.property_set_spawn(NodePath(".:position"), true)
	config.property_set_replication_mode(NodePath(".:position"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	config.add_property(NodePath(".:rotation"))
	config.property_set_spawn(NodePath(".:rotation"), true)
	config.property_set_replication_mode(NodePath(".:rotation"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	state.replication_config = config
	state.visibility_update_mode = MultiplayerSynchronizer.VISIBILITY_PROCESS_NONE
	state.add_visibility_filter(func(observer: int) -> bool:
		if arriving:
			return destination_ready and observer == int(ids.get("departing", -1))
		return not (outgoing_denied.get(owner, {}) as Dictionary).has(observer))
	node.add_child(state)
	# Host authority is explicit and independent of the represented owner.
	var admission := MultiplayerSynchronizer.new()
	admission.name = "Admission"
	admission.set_multiplayer_authority(1)
	admission.replication_config = SceneReplicationConfig.new()
	admission.visibility_update_mode = MultiplayerSynchronizer.VISIBILITY_PROCESS_NONE
	admission.add_visibility_filter(func(observer: int) -> bool:
		if arriving:
			return destination_ready and observer == int(ids.get("departing", -1))
		return not (admission_denied.get(owner, {}) as Dictionary).has(observer))
	node.add_child(admission)
	return node

@rpc("any_peer", "call_remote", "reliable", 0)
func hello(label: String) -> void:
	if role != "host" or label not in ["departing", "staying"]:
		_fail("invalid hello")
		return
	ids[label] = multiplayer.get_remote_sender_id()
	if ids.size() == 3:
		configure.rpc(ids)
		for owner: int in ids.values():
			var body := old_spawner.spawn({"owner": owner}) as Node3D
			bodies[owner] = body
		destination_body = destination_spawner.spawn({"owner": 1}) as Node3D
		_check(destination_body != null, "host destination authored while admission closed")

@rpc("authority", "call_remote", "reliable", 0)
func configure(values: Dictionary) -> void:
	ids = values

func _spawn_received(node: Node, arriving: bool) -> void:
	var owner := int(node.get_meta("owner"))
	if arriving:
		_check(role == "departing" and destination_ready, "destination spawn arrives only after actual receiver ready")
		arrived.rpc_id(1, TOKEN)
		return
	bodies[owner] = node
	received[owner] = true
	_check(not retiring, "old realm spawn precedes departure fence")

func _physics_process(_delta: float) -> void:
	if failed or ids.size() != 3:
		return
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		_fail("transport lost before protocol completed")
		return
	var me := multiplayer.get_unique_id()
	var mine := _live_body(me)
	if is_instance_valid(mine):
		mine.position.x += 0.1
		mine.rotation.y += 0.01
	if is_instance_valid(destination_body):
		destination_body.position.x += 0.1
	var host_body := _live_body(1)
	if role != "host" and not ready_sent and received.size() == 3 \
			and is_instance_valid(host_body) and host_body.position.x > 0.5 and host_body.rotation.y > 0.01:
		ready_sent = true
		_check(true, "received live continuous and on-change host state before crossing")
		client_ready.rpc_id(1, role)

@rpc("any_peer", "call_remote", "reliable", 0)
func client_ready(label: String) -> void:
	if int(ids.get(label, -1)) != multiplayer.get_remote_sender_id():
		_fail("ready identity")
		return
	ready_roles[label] = true
	if ready_roles.size() == 2:
		var staying_body: Node3D = bodies[int(ids.staying)]
		host_baseline = staying_body.position.x
		quiesce.rpc(TOKEN)
		_quiesce_local()

@rpc("authority", "call_remote", "reliable", 0)
func quiesce(token: int) -> void:
	if token == TOKEN:
		_quiesce_local()

func _quiesce_local() -> void:
	retiring = true
	var me := multiplayer.get_unique_id()
	var departing := int(ids.departing)
	var targets: Array[int] = []
	if me == departing:
		targets.append(1)
		targets.append(int(ids.staying))
	else:
		targets.append(departing)
	var deny: Dictionary = {}
	for target: int in targets:
		deny[target] = true
	outgoing_denied[me] = deny
	var state := (bodies[me] as Node).get_node("State") as MultiplayerSynchronizer
	for target: int in targets:
		state.update_visibility(target)
		# Same sender/mode/channel as its already-enqueued on-change deltas.
		sender_fence.rpc_id(target, TOKEN)
	if role == "staying":
		continuing_baseline = (bodies[1] as Node3D).position.x
	_check(true, "recipient-scoped outgoing state gates applied without local body removal")

@rpc("any_peer", "call_remote", "reliable", 0)
func sender_fence(token: int) -> void:
	if token != TOKEN:
		return
	var source := multiplayer.get_remote_sender_id()
	if role == "host":
		_record_fence(source, 1)
	else:
		fence_received.rpc_id(1, TOKEN, source)

@rpc("any_peer", "call_remote", "reliable", 0)
func fence_received(token: int, source: int) -> void:
	if token == TOKEN:
		_record_fence(source, multiplayer.get_remote_sender_id())

func _record_fence(source: int, receiver: int) -> void:
	var departing := int(ids.departing)
	var expected := (receiver == departing and source in [1, int(ids.staying)]) \
		or (source == departing and receiver in [1, int(ids.staying)])
	_check(expected, "authenticated fence matches affected sender/receiver")
	fences["%d:%d" % [source, receiver]] = true
	if fences.size() == 4:
		_retire_host()

func _retire_host() -> void:
	var departing := int(ids.departing)
	for owner: int in bodies.keys():
		var deny := {departing: true}
		if owner == departing:
			deny[int(ids.staying)] = true
		admission_denied[owner] = deny
		var admission := (bodies[owner] as Node).get_node("Admission") as MultiplayerSynchronizer
		for observer: int in deny.keys():
			admission.update_visibility(observer)
	# update_visibility emits synchronously; the engine handler directly calls
	# reliable _send_raw for resulting visibility despawns before returning.
	host_despawn_fence.rpc_id(departing, TOKEN)
	_check(true, "host-owned empty-property admission sync withdrew only departing observer")
	var retired: Node = bodies[departing]
	bodies.erase(departing)
	retired.queue_free()

func _despawn_received(node: Node) -> void:
	var owner := int(node.get_meta("owner"))
	received.erase(owner)
	bodies.erase(owner)
	_check(retiring, "actual engine despawn consumed during transition")
	_try_depart()

@rpc("authority", "call_remote", "reliable", 0)
func host_despawn_fence(token: int) -> void:
	if token == TOKEN:
		host_fence_seen = true
		_try_depart()

func _try_depart() -> void:
	if role != "departing" or not host_fence_seen or not received.is_empty() or transition_started:
		return
	transition_started = true
	_depart_local.call_deferred()

func _depart_local() -> void:
	await get_tree().process_frame
	_check(old_realm.get_node("Actors").get_child_count() == 0, "actual old receiver inventory empty after all engine despawns and host fence")
	old_realm.free()
	old_spawner.free()
	_check(destination == null, "destination not constructed while old-realm drain pending")
	_build_destination()
	_check(destination.get_node("Actors").get_child_count() == 0, "destination contains no pre-ready spawn")
	destination_ready = true
	ready_destination.rpc_id(1, TOKEN)

@rpc("any_peer", "call_remote", "reliable", 0)
func ready_destination(token: int) -> void:
	if token != TOKEN or multiplayer.get_remote_sender_id() != int(ids.departing):
		return
	destination_ready = true
	(destination_body.get_node("State") as MultiplayerSynchronizer).update_visibility(int(ids.departing))
	(destination_body.get_node("Admission") as MultiplayerSynchronizer).update_visibility(int(ids.departing))
	_check(true, "host admitted destination only after authenticated readiness")

@rpc("any_peer", "call_remote", "reliable", 0)
func arrived(token: int) -> void:
	if token == TOKEN and multiplayer.get_remote_sender_id() == int(ids.departing):
		verify_continuing.rpc_id(int(ids.staying), TOKEN)

@rpc("authority", "call_remote", "reliable", 0)
func verify_continuing(token: int) -> void:
	if token != TOKEN:
		return
	var host_body := _live_body(1)
	_check(is_instance_valid(host_body) and received.size() == 2, "continuing viewer retains host and own old-realm bodies")
	_check(is_instance_valid(host_body) and host_body.position.x > continuing_baseline, "continuing viewer received host motion during departure")
	continuing_verified.rpc_id(1, TOKEN)

@rpc("any_peer", "call_remote", "reliable", 0)
func continuing_verified(token: int) -> void:
	if token != TOKEN or multiplayer.get_remote_sender_id() != int(ids.staying):
		return
	var staying_body := _live_body(int(ids.staying))
	_check(is_instance_valid(staying_body) and staying_body.position.x > host_baseline, "host kept receiving continuing peer-owned motion")
	finish.rpc()
	_finish_local()

@rpc("authority", "call_remote", "reliable", 0)
func finish() -> void:
	_finish_local()

func _finish_local() -> void:
	set_physics_process(false)
	print("PROTOCOL PASS %s checks=%d" % [role, checks])
	# Allow the success marker to reach connected peers; never a drain gate.
	await get_tree().create_timer(0.3).timeout
	get_tree().quit(0)

func _check(condition: bool, label: String) -> void:
	if not condition:
		_fail(label)
		return
	checks += 1
	print("PROTOCOL CHECK %s: %s" % [role, label])

func _fail(label: String) -> void:
	if failed:
		return
	failed = true
	set_physics_process(false)
	push_error("PROTOCOL FAILURE %s: %s" % [role, label])
	get_tree().quit(1)

func _live_body(owner: int) -> Node3D:
	var raw: Variant = bodies.get(owner)
	return raw as Node3D if is_instance_valid(raw) and raw is Node3D else null
