extends Node

## Production Session/coordinator/adapter, tiny authored worlds. This does not
## claim Game.enter_realm or procedural-world acceptance. No target receiver
## exists on the staying peer.
const SCOPE := preload("res://scripts/net/realm_replication_scope.gd")
const TRAINERS := preload("res://scripts/net/trainer_spawn.gd")
const SOURCE := "meadows"
const TARGET := "water"

class CancellationCoordinator extends "res://scripts/net/realm_transition.gd":
	var injected := false
	func _check_local_drain() -> void:
		super._check_local_drain()
		if not injected and bool(_local.get("drained", false)) and str(_local.get("phase", "")) == "draining":
			injected = true
			_local["error"] = "fixture_cancel_at_real_drain"
			print("ADAPTER CANCEL actual inventory empty; cancellation injected before loading")

class World extends Node:
	var realm := ""
	var hub: Node
	func world_realm() -> String:
		return realm
	func shell_build_complete() -> bool:
		if is_instance_valid(hub) and hub.cancellation_mode and hub.role == "departing" \
				and bool(hub.transition.get("injected")):
			hub.source_ready_observed = true
			print("ADAPTER CANCEL source readiness observed")
		return true

class ShellSeam extends Node:
	func reconcile() -> void:
		pass
	func release_all() -> void:
		pass

class Producer extends Node:
	var participants: Array[int] = []
	var replies := 0
	var hub: Node
	var realm := ""
	func realm_transition_results_settled() -> bool:
		return true
	func realm_transition_departing(peer: int) -> void:
		participants.erase(peer)
	func realm_transition_committed(_peer: int) -> void:
		pass
	func realm_transition_arrived() -> void:
		pass
	func start_scene_request() -> void:
		_scene_request.rpc_id(1)
	@rpc("any_peer", "call_remote", "reliable", 1)
	func _scene_request() -> void:
		var sender := multiplayer.get_remote_sender_id()
		var coordinator: Node = hub.get("transition")
		if multiplayer.is_server() and bool(coordinator.call("scene_rpc_allowed", realm, sender)):
			_scene_reply.rpc_id(sender)
	@rpc("authority", "call_remote", "reliable", 1)
	func _scene_reply() -> void:
		replies += 1
		hub.call("received_scene_reply", realm)

class Body extends Node3D:
	var presentations := 0
	var visibility_updates: Dictionary = {}
	@rpc("authority", "call_remote", "reliable", 0)
	func presentation() -> void:
		presentations += 1

var role := ""
var session: Node
var transition: Node
var ids: Dictionary = {"host": 1}
var worlds: Dictionary = {}
var prepared: Dictionary = {}
var ready_sent := false
var checks := 0
var failed := false
var stopping := false
var moving := false
var host_motion_before := 0.0
var staying_motion_before := 0.0
var request_sent := false
var request_answered := false
var _last_diagnostic := ""
var observation_only := false
var cancellation_mode := false
var source_ready_observed := false
var latejoin_mode := false
var policy_seen_before_snapshot := false
var latejoin_reported := false
var pending_origin := ""
var departed_motion_before := 0.0

func _process(_delta: float) -> void:
	if stopping or transition == null or not moving:
		return
	var current := JSON.stringify(transition.call("diagnostic_state"))
	if current != _last_diagnostic:
		_last_diagnostic = current
		print("ADAPTER STATE %s %s" % [role, current])

func _ready() -> void:
	var arguments := OS.get_cmdline_user_args()
	observation_only = arguments.has("observe")
	cancellation_mode = arguments.has("cancel")
	latejoin_mode = arguments.has("latejoin")
	var preflight_only := arguments[0] == "preflight"
	role = "host" if preflight_only else arguments[0]
	var port := 0 if preflight_only else int(arguments[1])
	var game := get_node("/root/Game")
	game.set_process(false)
	session = game.get("session")
	session.set_process(false)
	(session.get("_realms") as Node).set_process(false)
	var shell_seam := ShellSeam.new()
	shell_seam.name = "FixtureShellSeam"
	session.add_child(shell_seam)
	session.set("_realms", shell_seam)
	session.set("_mode", "host" if role == "host" else "client")
	transition = session.get("realm_transition")
	if cancellation_mode and role == "departing":
		transition.set_script(CancellationCoordinator)
	_build_world(SOURCE)
	if not _preflight():
		return
	if preflight_only:
		print("ADAPTER PREFLIGHT COMPLETE checks=%d" % checks)
		get_tree().quit(0)
		return
	if latejoin_mode:
		session.set_process(true)
		if role == "host":
			session.peer_joined.connect(_late_peer_joined)
		elif role == "latejoin":
			get_tree().current_scene = worlds[SOURCE]
			session.snapshot_applied.connect(_late_snapshot_applied)
			session.set("_mode", "")
			_check(bool(session.call("join", "127.0.0.1", port,
				{"character_id": "latejoin-fixture", "display_name": "Latejoin fixture", "realm": SOURCE})), "actual Session.join started")
			_check(not bool(session.call("snapshot_ready")), "actual join closes snapshot readiness")
			get_tree().create_timer(60.0).timeout.connect(func(): _fail("native latejoin deadline"))
			print("ADAPTER BOOT latejoin")
			return
	session.connect("peer_realm_changed", _realm_changed)
	var enet := ENetMultiplayerPeer.new()
	var result := enet.create_server(port, 2) if role == "host" else enet.create_client("127.0.0.1", port)
	if result != OK:
		_fail("ENet create %d" % result)
		return
	multiplayer.multiplayer_peer = enet
	session.set("_peer", enet)
	if role != "host":
		multiplayer.connected_to_server.connect(func(): _hello.rpc_id(1, role))
	get_tree().create_timer(60.0 if cancellation_mode or latejoin_mode else 20.0).timeout.connect(func(): _fail("native adapter deadline"))
	print("ADAPTER BOOT %s" % role)

func _preflight() -> bool:
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/realm_hearts.json"))
	if not _check(config is Dictionary and (config as Dictionary).has("realms"), "real realm config has realm table"):
		return false
	var realms: Dictionary = config.realms
	if not _check(SOURCE != TARGET and realms.has(SOURCE) and realms.has(TARGET), "canonical source and target exist and differ"):
		return false
	var game := get_node("/root/Game")
	var hearts: RefCounted = game.get("realm_hearts")
	for realm: String in [SOURCE, TARGET]:
		var path := str(realms[realm].get("scene", ""))
		if not _check(not path.is_empty() and ResourceLoader.exists(path) \
				and str(hearts.call("scene_for_realm", realm)) == path, "real Realm Hearts resolves " + realm):
			return false
	print("ADAPTER PREFLIGHT Game entry flag=%s can_enter_target=%s; component probe does not call Game.enter_realm" % [
		str(realms[TARGET].get("entry_key_flag", "")), str(game.call("can_enter_realm", TARGET))])
	if not _check(transition.get_path() == SCOPE.TRANSITION_PATH and transition.get_parent() == session,
			"actual coordinator is mounted at the production Session path"):
		return false
	print("ADAPTER PREFLIGHT PROCESS %s" % JSON.stringify(transition.call("diagnostic_state")))
	if not _check(bool(session.call("snapshot_ready")), "fixture starts after snapshot-ready contract; join handshake is outside this probe"):
		return false
	for shape: Array in [["begin_client", 2, TYPE_BOOL], ["finish_client", 1, TYPE_BOOL],
			["_prepare_inventory", 1, TYPE_BOOL], ["stamp_spawn", 2, TYPE_STRING]]:
		if not _check(_method_shape(transition, str(shape[0]), int(shape[1]), int(shape[2])),
				"production method shape " + str(shape[0])):
			return false
	if not _check(_method_shape(session, "realm_of", 1, TYPE_STRING) \
			and _method_shape(session, "_apply_realm_change", 3, TYPE_NIL), "actual Session realm API signatures"):
		return false
	if not _check(bool(transition.call("_prepare_inventory", SOURCE)), "all actual authored source spawners register and are supported"):
		return false
	var world: Node = worlds[SOURCE]
	for kind: String in ["Trainer", "Creature", "Item"]:
		var spawner := world.get_node(kind + "Spawner") as MultiplayerSpawner
		var scope := spawner.get_node(SCOPE.ADAPTER_NAME)
		if not _check(spawner.get_node(spawner.spawn_path) == world.get_node(kind + "Bodies") \
				and (transition.get("scopes") as Array).has(scope) \
				and int(scope.call("received_count")) == 0, "matching source path and empty registered inventory " + kind):
			return false
	for kind: String in ["Trainer", "Creature"]:
		var body := _make_body({"owner": 20, "origin": ""}, SOURCE, kind)
		var owner_ok := body.get_node("Sync").get_multiplayer_authority() == 20 \
			and body.get_node("AdmissionSync").get_multiplayer_authority() == 1 \
			and str(body.get_meta(SCOPE.BODY_REALM)) == SOURCE
		body.free()
		if not _check(owner_ok, "factory authority and metadata before tree entry " + kind):
			return false
	return _check(get_tree().root.get_node_or_null(_world_name(TARGET)) == null,
		"no destination or dummy receiving path exists before the transaction")

func _method_shape(object: Object, method_name: String, arguments: int, return_type: int) -> bool:
	for method: Dictionary in object.get_method_list():
		if str(method.name) == method_name:
			return (method.args as Array).size() == arguments and int(method["return"].type) == return_type
	return false

func _world_name(realm: String) -> String:
	return "AdapterMeadows" if realm == SOURCE else "AdapterWater"

func _build_world(realm: String) -> void:
	var world := World.new()
	world.realm = realm
	world.hub = self
	world.name = _world_name(realm)
	get_tree().root.add_child(world)
	worlds[realm] = world
	var producer := Producer.new()
	producer.name = "Producer"
	producer.hub = self
	producer.realm = realm
	world.add_child(producer)
	for kind: String in ["Trainer", "Creature", "Item"]:
		var parent := Node.new()
		parent.name = kind + "Bodies"
		world.add_child(parent)
		var spawner := MultiplayerSpawner.new()
		spawner.name = kind + "Spawner"
		spawner.spawn_path = NodePath("../" + kind + "Bodies")
		spawner.spawn_function = func(data: Variant) -> Node: return _make_body(data, realm, kind)
		world.add_child(spawner)
		SCOPE.attach(spawner, realm, producer if kind == "Creature" else null)

func _make_body(data: Variant, realm: String, kind: String) -> Node:
	if latejoin_mode and role == "latejoin" and kind == "Item":
		_check(policy_seen_before_snapshot and bool(session.call("snapshot_ready")), "new pending cohort admitted after actual policy and snapshot")
	if cancellation_mode and role == "departing" and bool(transition.get("injected")):
		_check(source_ready_observed, "actual respawn follows source readiness")
	var owner := int(data.owner)
	var body := Body.new()
	body.name = "%s_%d" % [kind, owner]
	var state := MultiplayerSynchronizer.new()
	state.name = "Sync"
	state.root_path = ^".."
	var config := SceneReplicationConfig.new()
	for property: String in ["position", "rotation"]:
		var path := NodePath(".:" + property)
		config.add_property(path)
		config.property_set_spawn(path, true)
		config.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ALWAYS \
			if property == "position" else SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	state.replication_config = config
	body.add_child(state)
	body.set_multiplayer_authority(owner)
	var baseline: Callable = Callable()
	if kind == "Trainer":
		baseline = func(observer: int) -> bool:
			return TRAINERS.observer_may_receive(observer, str(session.call("realm_of", observer)), realm, true)
		state.add_visibility_filter(baseline)
	var origin := str(data.get("origin", ""))
	SCOPE.wire_body(body, state, realm, owner, baseline, origin)
	for sync: Node in body.get_children():
		if sync is MultiplayerSynchronizer:
			var sync_name := str(sync.name)
			(sync as MultiplayerSynchronizer).visibility_changed.connect(func(observer: int):
				var key := "%s:%d" % [sync_name, observer]
				body.visibility_updates[key] = int(body.visibility_updates.get(key, 0)) + 1)
	transition.call("track_origin_body", origin, body)
	return body

func _spawn_pair(realm: String, owner: int) -> void:
	var world: Node = worlds[realm]
	for kind: String in ["Trainer", "Creature"]:
		var origin := str(transition.call("stamp_spawn", owner, realm))
		(world.get_node(kind + "Spawner") as MultiplayerSpawner).spawn({"owner": owner, "origin": origin})

@rpc("any_peer", "call_remote", "reliable", 0)
func _hello(label: String) -> void:
	if role != "host" or label not in ["departing", "staying"]:
		_fail("hello identity")
		return
	ids[label] = multiplayer.get_remote_sender_id()
	if ids.size() == (2 if latejoin_mode else 3):
		_configure.rpc(ids)
		_configure_local(ids)
		for owner: int in ids.values():
			_spawn_pair(SOURCE, owner)

@rpc("authority", "call_remote", "reliable", 0)
func _configure(values: Dictionary) -> void:
	_configure_local(values)

func _configure_local(values: Dictionary) -> void:
	ids = values
	var rows: Array = []
	for owner: int in ids.values():
		rows.append({"peer_id": owner, "realm": SOURCE, "character_id": str(owner)})
	(session.get("_registry") as RefCounted).call("load_data", {"rows": rows, "revision": 1})
	var producer: Producer = (worlds[SOURCE] as Node).get_node("Producer")
	for owner: int in ids.values():
		producer.participants.append(owner)

func _body(realm: String, owner: int, kind: String = "Trainer") -> Node3D:
	var world: Variant = worlds.get(realm)
	if not is_instance_valid(world):
		return null
	return (world as Node).get_node_or_null("%sBodies/%s_%d" % [kind, kind, owner]) as Node3D

func _body_count(realm: String) -> int:
	var world: Variant = worlds.get(realm)
	if not is_instance_valid(world):
		return 0
	return (world as Node).get_node("TrainerBodies").get_child_count() \
		+ (world as Node).get_node("CreatureBodies").get_child_count()

func _physics_process(_delta: float) -> void:
	if latejoin_mode and role == "latejoin":
		if not bool(session.call("snapshot_ready")):
			return
		for row: Dictionary in session.call("peers"):
			var id := int(row.peer_id)
			ids["latejoin" if id == multiplayer.get_unique_id() else ("host" if id == 1 else "departing")] = id
	if stopping or failed or ids.size() < (2 if latejoin_mode else 3):
		return
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		_fail("transport lost")
		return
	for realm: String in worlds:
		for kind: String in ["Trainer", "Creature"]:
			var body := _body(realm, multiplayer.get_unique_id(), kind)
			if body != null:
				if latejoin_mode and role == "latejoin" and not policy_seen_before_snapshot:
					_fail("new owner producer preceded policy application")
					return
				body.position.x += 0.1
				body.rotation.y += 0.01
				for observer: int in multiplayer.get_peers():
					if SCOPE.outgoing_allowed(body, observer):
						body.rpc_id(observer, "presentation")
	var host_body := _body(SOURCE, 1)
	if latejoin_mode and role == "latejoin":
		if not latejoin_reported and _body_count(SOURCE) == 4 and host_body != null and host_body.position.x > 0.5 \
				and (worlds[SOURCE] as Node).get_node("ItemBodies").get_child_count() == 1:
			latejoin_reported = true
			_check(policy_seen_before_snapshot, "policy applied before first new-owner producer")
			_check(not worlds.has(TARGET), "actual joiner has no dummy Water receiver")
			_check(int(host_body.get("presentations")) > 0, "new joiner consumes host reliable presentation")
			_latejoin_verified.rpc_id(1)
		return
	if role != "host" and not ready_sent and _body_count(SOURCE) == (4 if latejoin_mode else 6) \
			and host_body != null and host_body.position.x > 0.5 and host_body.rotation.y > 0.01:
		ready_sent = true
		_check(true, "trainer and creature received with live continuous and reliable state")
		_peer_ready.rpc_id(1, role)

@rpc("any_peer", "call_remote", "reliable", 0)
func _peer_ready(label: String) -> void:
	if int(ids.get(label, -1)) != multiplayer.get_remote_sender_id():
		_fail("ready identity")
		return
	prepared[label] = true
	if prepared.size() == (1 if latejoin_mode else 2):
		host_motion_before = _body(SOURCE, int(ids.departing if latejoin_mode else ids.staying)).position.x
		_begin.rpc()
		moving = true
		_start_observation()

@rpc("authority", "call_remote", "reliable", 0)
func _begin() -> void:
	moving = true
	_start_observation()
	staying_motion_before = _body(SOURCE, 1).position.x
	if role == "departing":
		# A real earlier request on the production ledger channel must finish
		# before the old receiver is detached.
		(worlds[SOURCE] as Node).get_node("Producer").call("start_scene_request")
		request_sent = true
		_travel()

func _start_observation() -> void:
	if observation_only:
		get_tree().create_timer(8.0).timeout.connect(func():
			print("ADAPTER OBSERVATION END %s %s" % [role, JSON.stringify(transition.call("diagnostic_state"))]))

func received_scene_reply(realm: String) -> void:
	_check(worlds.has(realm), "prior scene reply consumed before old receiver deletion")
	request_answered = true

func _travel() -> void:
	if cancellation_mode:
		await _cancel_travel()
		return
	var drained: bool = await transition.call("begin_client", SOURCE, TARGET)
	if not drained:
		print("ADAPTER REFUSAL local=%s source_inventory=%s" % [JSON.stringify(transition.get("_local")),
			str(transition.call("_prepare_inventory", SOURCE))])
	if not _check(drained, "production coordinator completed both fence rounds and actual drain"):
		return
	_check(request_sent and request_answered, "earlier scene request result survived quiescence")
	_check(_body_count(SOURCE) == 0, "both actual spawner parents are empty before detach")
	for scope: Node in transition.get("scopes"):
		if str(scope.get("realm")) == SOURCE:
			_check(int(scope.call("received_count")) == 0, "actual engine despawn inventory is empty")
	var old: Node = worlds[SOURCE]
	worlds.erase(SOURCE)
	old.queue_free()
	await get_tree().process_frame
	_build_world(TARGET)
	_check(_body_count(TARGET) == 0, "target remains unspawned before explicit readiness")
	var admitted: bool = await transition.call("finish_client", TARGET)
	if not _check(admitted, "production target readiness completed"):
		return
	while _body_count(TARGET) != 2 and not stopping:
		await get_tree().process_frame
	_check(_body_count(TARGET) == 2, "real target trainer and creature admitted")
	_arrived.rpc_id(1)

func _cancel_travel() -> void:
	var game := get_node("/root/Game")
	var source: Node = worlds[SOURCE]
	get_tree().current_scene = source
	var crossed: bool = await game.call("enter_realm", TARGET, "", true)
	if not _check(not crossed and bool(transition.get("injected")), "actual Game cancels at actual drained inventory"):
		return
	if not _check(get_tree().current_scene == source and source_ready_observed, "actual Game retains and readies original source"):
		return
	if not _check((transition.get("_local") as Dictionary).is_empty() \
		and (transition.get("transactions") as Dictionary).is_empty(), "Game cancellation clears local token after recovery"):
		return
	_check(not bool(transition.call("pins_realm", SOURCE)) and not bool(transition.call("pins_realm", TARGET)), "recovery releases realm pins")
	_check(get_tree().root.get_node_or_null("LoadingOverlay") == null, "actual Game recovery dismisses its overlay")
	while _body_count(SOURCE) != 6 and not stopping:
		await get_tree().process_frame
	_check(_body_count(SOURCE) == 6, "actual source trainer and creature inventory restored")
	_arrived.rpc_id(1)

func _realm_changed(peer: int, from: String, to: String) -> void:
	if role != "host":
		return
	for kind: String in ["Trainer", "Creature"]:
		var body := _body(from, peer, kind)
		if body != null:
			body.queue_free()
	if not worlds.has(to):
		_build_world(to)
	_spawn_pair(to, peer)

func _late_snapshot_applied() -> void:
	var local_join: Dictionary = transition.get("_joining_local")
	var origin_policy: RefCounted = transition.get("origins")
	var pending: Dictionary = origin_policy.get("pending_receivers")
	var identity := multiplayer.get_unique_id()
	policy_seen_before_snapshot = not local_join.is_empty() and pending.has(identity) \
		and str(pending[identity].generation) == str(local_join.permit)
	_check(policy_seen_before_snapshot, "actual snapshot signal observes matching pending generation already applied")
	for row: Dictionary in (origin_policy.get("rows") as Dictionary).values():
		_check(str(row.members.get(identity, "")) == str(local_join.get("permit", "")), "full origin rows match prior pending RPC generation")
		_check(row.denied.has(identity), "snapshot alone has not granted receiver admission")

func _late_peer_joined(peer: int, _character_id: String) -> void:
	ids["latejoin"] = peer
	var joining: Dictionary = transition.get("_joining")
	_check(joining.has(peer) and str(joining[peer].phase) == "receiver", "actual host peer_joined follows policy applied ACK")
	var origin_policy: RefCounted = transition.get("origins")
	_check((origin_policy.get("pending_receivers") as Dictionary).has(peer), "receiver remains pending when owner bodies are created")
	_spawn_pair(SOURCE, peer)
	# Real host-authored extra scoped cohort, created during the pending stage.
	# Its source receiver exists, but admission must wait for actual readiness.
	pending_origin = "fixture-pending:%d" % peer
	origin_policy.call("create", pending_origin, SOURCE, 1, session.call("peers"))
	transition.rpc("_origin_install", pending_origin, (origin_policy.get("rows") as Dictionary)[pending_origin])
	_check(not bool(origin_policy.call("allowed", pending_origin, peer)), "new same-realm origin inherits pending receiver deny")
	((worlds[SOURCE] as Node).get_node("ItemSpawner") as MultiplayerSpawner).spawn({"owner": 1, "origin": pending_origin})

@rpc("any_peer", "call_remote", "reliable", 0)
func _latejoin_verified() -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not latejoin_mode or peer != int(ids.get("latejoin", -1)):
		_fail("latejoin verification identity")
		return
	while not stopping and (_body(SOURCE, peer).position.x <= 0.2 \
			or _body(TARGET, int(ids.departing)).position.x <= departed_motion_before):
		await get_tree().process_frame
	_check((transition.get("_joining") as Dictionary).is_empty(), "actual joined receiver pending state cleared")
	_check(_body(SOURCE, peer).position.x > 0.2 and int(_body(SOURCE, peer).get("presentations")) > 0,
		"host consumes new owner continuous state and reliable presentation")
	_check(_body(TARGET, int(ids.departing)).position.x > departed_motion_before, "existing Water owner movement continues through latejoin")
	_check(bool((transition.get("origins") as RefCounted).call("allowed", pending_origin, peer)), "matching actual source readiness admits pending cohort")
	_finish.rpc()
	_finish_local()

@rpc("any_peer", "call_remote", "reliable", 0)
func _arrived() -> void:
	if multiplayer.get_remote_sender_id() != int(ids.departing):
		_fail("arrival identity")
		return
	if latejoin_mode:
		_check(not (transition.get("origins") as RefCounted).get("rows").is_empty(), "completed departure retains live origin policy")
		departed_motion_before = _body(TARGET, int(ids.departing)).position.x
		print("ADAPTER LATEJOIN READY")
		return
	if cancellation_mode:
		_check(str(session.call("realm_of", int(ids.departing))) == SOURCE, "host membership returned to source")
		_check((transition.get("transactions") as Dictionary).is_empty(), "host recovery transaction finished")
		_check(_body(SOURCE, int(ids.staying)).position.x > host_motion_before, "host retained staying movement during cancellation")
		_check(int(_body(SOURCE, int(ids.staying)).get("presentations")) > 0, "host retained reliable presentations during cancellation")
		_verify_staying.rpc_id(int(ids.staying))
		return
	var retained := _body(SOURCE, 1) as Body
	for sync_name: String in ["Sync", "AdmissionSync"]:
		_check(int(retained.visibility_updates.get(sync_name + ":0", 0)) > 0,
			"native automatic zero-peer refresh remains active " + sync_name)
		for observer: int in [int(ids.departing), int(ids.staying)]:
			_check(int(retained.visibility_updates.get("%s:%d" % [sync_name, observer], 0)) > 0,
				"phase refresh emitted for actual peer %d %s" % [observer, sync_name])
	_check(not SCOPE.outgoing_allowed(retained, 0) and not SCOPE.admission_allowed(retained, 0),
		"automatic public fast path stays closed after departure")
	_check(SCOPE.outgoing_allowed(retained, int(ids.staying)) \
		and SCOPE.admission_allowed(retained, int(ids.staying)), "remaining recipient stays permitted")
	_check(_body(SOURCE, int(ids.staying)).position.x > host_motion_before,
		"host still receives staying player's movement")
	_check(int(_body(SOURCE, int(ids.staying)).get("presentations")) > 0,
		"host consumed staying player's reliable body presentation")
	var producer: Producer = (worlds[SOURCE] as Node).get_node("Producer")
	_check(producer.participants.has(1) and producer.participants.has(int(ids.staying)) \
		and not producer.participants.has(int(ids.departing)), "only mover withdrawn from retained encounter")
	_verify_staying.rpc_id(int(ids.staying))

@rpc("authority", "call_remote", "reliable", 0)
func _verify_staying() -> void:
	_check(not worlds.has(TARGET) and get_tree().root.get_node_or_null(_world_name(TARGET)) == null,
		"staying peer has no dummy target receiver")
	if cancellation_mode:
		while _body_count(SOURCE) != 6 and not stopping:
			await get_tree().process_frame
	_check(_body_count(SOURCE) == (6 if cancellation_mode else 4), "staying peer has expected source inventory")
	_check(_body(SOURCE, 1).position.x > staying_motion_before, "staying peer still receives host movement")
	var origin := str((_body(SOURCE, int(ids.staying)) as Node).get_meta(SCOPE.BODY_ORIGIN, ""))
	_check(origin.is_empty(), "unrelated source body keeps baseline admission")
	_staying_verified.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable", 0)
func _staying_verified() -> void:
	if multiplayer.get_remote_sender_id() == int(ids.staying):
		_finish.rpc()
		_finish_local()

@rpc("authority", "call_remote", "reliable", 0)
func _finish() -> void:
	_finish_local()

func _finish_local() -> void:
	if stopping:
		return
	if observation_only and not failed:
		print("ADAPTER OBSERVATION reached normal completion; no acceptance credit")
		return
	stopping = true
	set_physics_process(false)
	transition.set_process(false)
	session.set("_mode", "")
	print("ADAPTER RESULT %s checks=%d failed=%s" % [role, checks, str(failed)])
	# Terminal notification flush only. No timer participates in admission,
	# sender fencing or proof of actual despawn consumption. Avoid launching
	# the title/saving a fixture profile during deliberate test shutdown.
	for signal_name: String in ["server_disconnected", "peer_disconnected"]:
		for connection: Dictionary in multiplayer.get_signal_connection_list(signal_name):
			var callback: Callable = connection.callable
			if callback.get_object() == session:
				multiplayer.disconnect(signal_name, callback)
	if not failed:
		await get_tree().create_timer(0.3).timeout
	get_tree().quit(1 if failed else 0)

func _check(ok: bool, description: String) -> bool:
	checks += 1
	print("ADAPTER CHECK %s %s %s" % [role, "PASS" if ok else "FAIL", description])
	if not ok:
		_fail(description)
	return ok

func _fail(reason: String) -> void:
	if stopping:
		return
	failed = true
	if transition != null:
		print("ADAPTER FAILURE STATE %s %s" % [role, JSON.stringify(transition.call("diagnostic_state"))])
	print("ADAPTER FAIL %s %s" % [role, reason])
	_finish_local()
