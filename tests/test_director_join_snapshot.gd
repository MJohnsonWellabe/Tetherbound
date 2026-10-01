extends "res://tests/test_case.gd"

const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

class SessionStub extends Node:
	var applied := false
	var multi_peer := true
	func is_active() -> bool:
		return true
	func is_host() -> bool:
		return false
	func is_multi_peer() -> bool:
		return multi_peer
	func snapshot_ready() -> bool:
		return applied
	func local_peer_id() -> int:
		return 20

class DirectorProbe extends "res://scripts/combat/encounter_director.gd":
	var sent: Array[String] = []
	var hosting := false
	var host_rows := 0
	func _is_host() -> bool:
		return hosting
	func _host_set_deployed(_peer_id: int, _row: Dictionary) -> void:
		host_rows += 1
	func _local_character_id() -> String:
		return "fixture"
	func _creature_card(_creature: RefCounted) -> Dictionary:
		return {}
	func _send_realm_rpc(peer: int, method: String, _arguments: Array, completing: bool = false) -> bool:
		if not _realm_rpc_allowed(peer, completing):
			return false
		sent.append(method)
		return true

func test_initial_join_and_reconnect_hold_then_resume_deployed_creature_announcement() -> void:
	var session := SessionStub.new()
	var director := DirectorProbe.new()
	director.set("_session", session)
	var ally := CREATURE.from_species("terrapup", {"display_name": "Partner", "base_hp": 100.0})
	director.set("_ally", ally)
	director._announce_deployment(ally)
	assert_true(director.sent.is_empty())
	assert_true(bool(director.get("_deployment_waiting_for_receiver")))
	session.applied = true
	director.realm_transition_arrived()
	assert_eq(director.sent.size(), 1)
	assert_false(bool(director.get("_deployment_waiting_for_receiver")))
	session.applied = false
	director._announce_deployment(ally)
	assert_eq(director.sent.size(), 1)
	session.applied = true
	director.realm_transition_arrived()
	assert_eq(director.sent.size(), 2)
	assert_false(bool(director.get("_deployment_waiting_for_receiver")))
	director.free()
	session.free()


## Returning route: the Water world restores a mid-water ride (and announces the
## ally) before any session exists. The host must still hear about it once the
## rejoined session is multi-peer, or other players see the rider on nothing.
func test_deployment_announced_before_any_session_is_sent_once_the_session_is_multi_peer() -> void:
	var director := DirectorProbe.new()
	var ally := CREATURE.from_species("terrapup", {"display_name": "Partner", "base_hp": 100.0})
	director.set("_ally", ally)
	director._announce_deployment(ally)
	assert_true(director.sent.is_empty())
	assert_true(bool(director.get("_deployment_waiting_for_receiver")),
		"an ally restored before the session exists must wait for a receiver")
	var session := SessionStub.new()
	session.multi_peer = false
	director.set("_session", session)
	director._announce_deployment(ally)
	assert_true(director.sent.is_empty())
	assert_true(bool(director.get("_deployment_waiting_for_receiver")),
		"a one-peer session is still no receiver")
	session.multi_peer = true
	session.applied = true
	director._resend_waiting_deployment()
	assert_eq(director.sent, ["_rpc_creature_deployed"] as Array[String])
	assert_false(bool(director.get("_deployment_waiting_for_receiver")))
	director.free()
	session.free()


## A player who deployed solo and then hosts must not re-announce every frame
## once a guest joins: the host records its own row once and stops holding.
func test_solo_deployment_that_becomes_a_host_records_once_and_stops_holding() -> void:
	var director := DirectorProbe.new()
	var ally := CREATURE.from_species("terrapup", {"display_name": "Partner", "base_hp": 100.0})
	director.set("_ally", ally)
	director._announce_deployment(ally)
	assert_true(bool(director.get("_deployment_waiting_for_receiver")))
	var session := SessionStub.new()
	session.applied = true
	director.set("_session", session)
	director.hosting = true
	for _frame in 5:
		director._resend_waiting_deployment()
	assert_eq(director.host_rows, 1, "the host records its own deployment once, not every frame")
	assert_false(bool(director.get("_deployment_waiting_for_receiver")))
	assert_true(director.sent.is_empty(), "a host never sends its deployment to itself")
	director.free()
	session.free()


## The production publishers and send helper run through two native APIs and
## actual loopback ENet. Only presentation sinks and the participant list are
## fixtures; no send, transport membership, or realm/snapshot gate is overridden.
class NativeDirector extends "res://scripts/combat/encounter_director.gd":
	var probes: Array[String] = []
	func _ready() -> void:
		pass
	func _process(_delta: float) -> void:
		pass
	func _is_host() -> bool:
		return multiplayer.is_server()
	func _local_peer_id() -> int:
		return multiplayer.get_unique_id()
	func _encounter_realm() -> String:
		return "meadows"
	@rpc("any_peer", "call_remote", "reliable", 1)
	func _rpc_transport_probe(value: String) -> void:
		probes.append(value)

class NativeParticipants extends RefCounted:
	var ids: Array = []
	func participants_of(_encounter_id: String) -> Array:
		return ids.duplicate()

class NativePresentation extends Node:
	var _encounter_id := "transport-regression"
	var launches: Array[Dictionary] = []
	var impacts: Array[Dictionary] = []
	func present_host_attack_launch(launch: Dictionary, _striker: Node3D = null) -> void:
		launches.append(launch.duplicate(true))
	func present_host_peer_impact(impact: Dictionary) -> void:
		impacts.append(impact.duplicate(true))

var _native_fixture: Node
var _native_host_api: SceneMultiplayer
var _native_guest_api: SceneMultiplayer
var _native_host_peer: ENetMultiplayerPeer
var _native_guest_peer: ENetMultiplayerPeer
var _native_host: NativeDirector
var _native_guest: NativeDirector
var _native_transition: Node
var _native_denied_before: Dictionary = {}
var _native_disconnected: Array[int] = []

func _native_poll() -> void:
	for api: SceneMultiplayer in [_native_host_api, _native_guest_api]:
		if api != null and api.has_multiplayer_peer() \
			and api.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
			api.poll()
	OS.delay_msec(1)

func _native_until(condition: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while not bool(condition.call()) and Time.get_ticks_msec() < deadline:
		_native_poll()
	return bool(condition.call())

func _native_drain() -> void:
	for _round in 16:
		_native_poll()

func _native_build() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	_native_fixture = Node.new()
	_native_fixture.name = "DirectorTransportRegression"
	tree.root.add_child(_native_fixture)
	var roots: Array[Node] = []
	for side: String in ["Host", "Guest"]:
		var branch := Node.new()
		branch.name = side
		_native_fixture.add_child(branch)
		roots.append(branch)
	_native_host_api = SceneMultiplayer.new()
	_native_guest_api = SceneMultiplayer.new()
	tree.set_multiplayer(_native_host_api, roots[0].get_path())
	tree.set_multiplayer(_native_guest_api, roots[1].get_path())
	_native_host_peer = ENetMultiplayerPeer.new()
	_native_host_peer.set_bind_ip("127.0.0.1")
	var server_error := _native_host_peer.create_server(0, 1, 2)
	assert_eq(server_error, OK, "native loopback server binds an ephemeral port")
	if server_error != OK: return false
	var port := _native_host_peer.host.get_local_port()
	assert_true(port > 0, "the OS assigned a real UDP port")
	_native_guest_peer = ENetMultiplayerPeer.new()
	var client_error := _native_guest_peer.create_client("127.0.0.1", port, 2)
	assert_eq(client_error, OK, "native client dials the loopback server")
	if client_error != OK: return false
	_native_host_api.multiplayer_peer = _native_host_peer
	_native_guest_api.multiplayer_peer = _native_guest_peer
	_native_host_api.peer_disconnected.connect(func(peer: int) -> void: _native_disconnected.append(peer))
	_native_host = NativeDirector.new()
	_native_guest = NativeDirector.new()
	for index in 2:
		var director := _native_host if index == 0 else _native_guest
		director.name = "EncounterDirector"
		roots[index].add_child(director)
		var session := SessionStub.new()
		session.applied = index == 0
		roots[index].add_child(session)
		director.set("_session", session)
		var manager := NativePresentation.new()
		roots[index].add_child(manager)
		director.set("_manager", manager)
	var connected := _native_until(func() -> bool:
		return _native_host_api.get_peers().size() == 1 and _native_guest_api.get_peers().has(1))
	assert_true(connected, "both native APIs completed their real ENet connection")
	return connected

func _native_cleanup() -> void:
	if is_instance_valid(_native_transition):
		_native_transition.set("retired_receivers", _native_denied_before)
	if is_instance_valid(_native_fixture):
		var tree := Engine.get_main_loop() as SceneTree
		var host_path := _native_fixture.get_node("Host").get_path()
		var guest_path := _native_fixture.get_node("Guest").get_path()
		_native_fixture.free()
		tree.set_multiplayer(null, host_path)
		tree.set_multiplayer(null, guest_path)
	if _native_host_peer != null: _native_host_peer.close()
	if _native_guest_peer != null: _native_guest_peer.close()
	_native_fixture = null
	_native_host = null
	_native_guest = null
	_native_host_api = null
	_native_guest_api = null
	_native_host_peer = null
	_native_guest_peer = null
	_native_transition = null

func _case_native_realm_rpc_membership_and_admission() -> void:
	if not _native_build(): return
	var guest_id := _native_guest_api.get_unique_id()
	assert_true(guest_id > 1, "use the actual ENet guest identity")
	var participants := NativeParticipants.new()
	participants.ids = [1, guest_id]
	_native_host.set("_encounter_host", participants)
	var local := _native_host.get("_manager") as NativePresentation
	var remote := _native_guest.get("_manager") as NativePresentation
	var launch := {"action_id": "transport-regression:1:1"}
	var impact := {"action_id": "transport-regression:1:1", "damage": 7.0}
	launch.make_read_only()
	impact.make_read_only()
	assert_true(_native_host._send_realm_rpc(guest_id, "_rpc_transport_probe", ["connected"]),
		"a connected admitted recipient accepts the ordinary dispatch")
	assert_true(_native_until(func() -> bool: return _native_guest.probes == ["connected"] as Array[String]),
		"the RPC actually crossed ENet and reached the remote node")
	_native_host._publish_host_attack_launch("transport-regression", 1, launch)
	_native_host._host_publish_peer_impact("transport-regression", 999, impact)
	assert_true(_native_until(func() -> bool: return remote.launches.size() == 1 and remote.impacts.size() == 1),
		"both original publication RPCs reach the connected guest")
	assert_eq(remote.launches.front() if not remote.launches.is_empty() else {}, launch, "native RPC preserves the launch payload")
	assert_eq(remote.impacts.front() if not remote.impacts.is_empty() else {}, impact, "native RPC preserves the impact payload")
	assert_eq(local.launches.size(), 1, "listen host still uses local launch presentation")
	assert_eq(local.impacts.size(), 1, "listen host still uses local impact presentation")
	assert_false(_native_guest._send_realm_rpc(1, "_rpc_transport_probe", ["before-snapshot"]),
		"connected transport cannot bypass the client's snapshot-ready gate")
	_native_drain()
	assert_true(_native_host.probes.is_empty(), "the refused snapshot packet was never delivered")
	(_native_guest.get("_session") as SessionStub).applied = true
	assert_true(_native_guest._send_realm_rpc(1, "_rpc_transport_probe", ["snapshot-ready"]),
		"the same connected client may send once its snapshot applies")
	assert_true(_native_until(func() -> bool: return _native_host.probes == ["snapshot-ready"] as Array[String]),
		"client dispatch reaches the actual host after readiness")
	_native_transition = _native_host.get_node_or_null(^"/root/Game/Session/RealmTransition")
	assert_true(_native_transition != null, "the native fixture uses the real scene-admission coordinator")
	if _native_transition == null: return
	_native_denied_before = (_native_transition.get("retired_receivers") as Dictionary).duplicate(true)
	var history: RefCounted = _native_transition.get("history")
	history.call("retire", guest_id, "meadows", "transport-regression")
	assert_true(_native_host_api.get_peers().has(guest_id), "realm refusal is tested while transport remains connected")
	assert_false(_native_host._send_realm_rpc(guest_id, "_rpc_transport_probe", ["receiver-not-ready"]),
		"membership must not bypass the original scene/realm refusal")
	_native_host._publish_host_attack_launch("transport-regression", 1, launch)
	_native_host._host_publish_peer_impact("transport-regression", 999, impact)
	_native_drain()
	assert_eq(remote.launches.size(), 1, "closed realm receives no additional launch")
	assert_eq(remote.impacts.size(), 1, "closed realm receives no additional impact")
	assert_true(bool(history.call("admit_ready", guest_id, "meadows", "transport-regression", int(history.get("epoch")))),
		"matching receiver readiness restores the original scene gate")
	_native_host_peer.disconnect_peer(guest_id)
	assert_true(_native_until(func() -> bool: return not _native_host_api.get_peers().has(guest_id)),
		"a real ENet disconnect removed the guest from native membership")
	assert_true(_native_disconnected.has(guest_id), "native peer_disconnected was observed")
	assert_eq(participants.ids, [1, guest_id], "participant bookkeeping intentionally still retains the departed ID")
	assert_false(_native_host._send_realm_rpc(guest_id, "_rpc_transport_probe", ["departed"]),
		"the real helper refuses a departed transport before rpc_id")
	_native_host._publish_host_attack_launch("transport-regression", 1, launch)
	_native_host._host_publish_peer_impact("transport-regression", 999, impact)
	assert_eq(local.launches.size(), 3, "listen-host launch handling survives realm refusal and disconnect")
	assert_eq(local.impacts.size(), 3, "listen-host impact handling survives realm refusal and disconnect")
	assert_eq(remote.launches.size(), 1, "departed guest receives no launch")
	assert_eq(remote.impacts.size(), 1, "departed guest receives no impact")
	_native_host_api.multiplayer_peer = null
	assert_false(_native_host._send_realm_rpc(guest_id, "_rpc_transport_probe", ["transport-closed"]),
		"a torn-down transport is refused without a native RPC attempt")
	_native_fixture.get_node("Host").remove_child(_native_host)
	assert_false(_native_host._send_realm_rpc(guest_id, "_rpc_transport_probe", ["detached"]),
		"a detached director is refused before querying its API")
	_native_host.free()
	_native_host = null

const EXPECTED_NATIVE_TRANSPORT_ASSERTIONS := 32

func test_native_realm_rpc_reaches_connected_peer_and_refuses_departed_or_unready_receiver() -> void:
	# The standard runner calls tests during SceneTree._init. As in the existing
	# water replication regression, an initialized child supplies native APIs.
	var runner_path := "user://director_transport_regression_runner.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null: return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_director_join_snapshot.gd").new()\n\ttest._case_native_realm_rpc_membership_and_admission()\n\ttest._native_cleanup()\n\tprint("DIRECTOR_TRANSPORT_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count == %d else 1)\n' % EXPECTED_NATIVE_TRANSPORT_ASSERTIONS)
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(runner_path)
	var log_path := ProjectSettings.globalize_path("user://director-transport-regression-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("DIRECTOR_TRANSPORT_RESULT="):
			result = JSON.parse_string(line.trim_prefix("DIRECTOR_TRANSPORT_RESULT="))
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_eq(int(result.get("assertions", 0)), EXPECTED_NATIVE_TRANSPORT_ASSERTIONS, "every native-network assertion must finish")
	assert_false(combined.contains("ERROR:"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use"), combined)
	assert_eq(code, 0, combined)
