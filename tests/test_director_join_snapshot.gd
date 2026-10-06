extends "res://tests/test_case.gd"

const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const WORLD := preload("res://autoload/world_state.gd")
const RESEARCH := preload("res://scripts/creatures/research_log.gd")
const BOUNTY := preload("res://scripts/world/bounty_board.gd")

class SessionStub extends Node:
	# Actual typed character registry behind the transport fixture. No client
	# baseline or derived stat claim is admitted by a strike request.
	var _character_authority := AUTHORITY.new()
	func _init() -> void:
		_character_authority.bind_world("native_director_namespace")
	func _game() -> Node: return get_parent()
	func _altar_current_epoch() -> String: return "native_director_epoch"
	func foundation_combat_mastery(_director: Node, _encounter: String, _peer: Variant, _action: int) -> Dictionary:
		# This transport/round fixture has no disk writer. Refuse honestly and
		# retain the production original; saved mastery has its own disk tests.
		return {"ok": false, "durable": false, "code": "fixture_writer_missing"}
	func admitted_character_state(peer: int) -> Dictionary:
		return _character_authority.actor_stat_state(_authority_character(peer))
	func foundation_rematch_participant_context(peer: int) -> Dictionary:
		var character := _authority_character(peer)
		if character.is_empty(): return {}
		return {"character_id": character, "world_flags": [], "personal_flags": [], "bounty_instances": []}
	func foundation_research_source(_director: Node, _encounter: String, _peer: int, kind: String,
		_source: String, _species: String, _move: String = "", _night: Variant = null) -> Dictionary:
		# This native combat fixture has no research/bounty writer. OFF is a
		# genuine no-duty result; enabled duties remain retained and unpaid.
		var disabled: bool = RESEARCH.config().get("runtime_enabled") != true \
			and (kind != "catch" or BOUNTY.config().get("runtime_enabled") != true)
		return {"ok": disabled, "durable": disabled, "disabled": disabled}
	var applied := false
	var multi_peer := true
	var owners: Dictionary = {}
	func _authority_character(peer_id: int) -> String:
		return str(owners.get(peer_id, ""))
	func peers() -> Array:
		return owners.keys()
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
	func _local_character_id() -> String:
		return str(_session.call("_authority_character", _local_peer_id())) if _session != null else ""
	func _encounter_realm() -> String:
		return "meadows"
	@rpc("any_peer", "call_remote", "reliable", 1)
	func _rpc_transport_probe(value: String) -> void:
		probes.append(value)

class NativeParticipants extends RefCounted:
	var ids: Array = []
	func participants_of(_encounter_id: String) -> Array:
		return ids.duplicate()

class NativeGame extends Node:
	var world := WORLD.new()
	var session: Node
	func _init() -> void:
		world.world_id = "native_director_world"
		world.reward_delivery_namespace = "native_director_namespace"

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
		var branch := NativeGame.new()
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
		roots[index].set("session", session)
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
	# F27: this guest's own wild is local. It cannot ask the host-only
	# canonical opener for readiness, regardless of the shipped tracking flag.
	assert_true(_native_guest._is_guest(), "the regression uses a live guest director")
	var actor_config: Dictionary = NATIVE_COMBAT.MATH.config().get("actor_vitals", {})
	var original_tracking: Variant = actor_config.get("runtime_enabled")
	for tracking: bool in [false, true]:
		actor_config["runtime_enabled"] = tracking
		assert_eq(_native_guest._canonical_wild_start_state(null), {"enabled": false, "ready": false},
			"a guest's local wild retains legacy admission with tracking %s" % str(tracking))
	actor_config["runtime_enabled"] = original_tracking
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
	assert_true(_native_until(func() -> bool: return _native_guest.probes == (["connected"] as Array[String])),
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
	assert_true(_native_until(func() -> bool: return _native_host.probes == (["snapshot-ready"] as Array[String])),
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

const EXPECTED_NATIVE_TRANSPORT_ASSERTIONS := 35

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


var _native_hp_fixture_completed := false
var _native_hp_fixture_observation: Dictionary = {}
var _native_hp_fixture_observations: Array[Dictionary] = []

## Real scene timers must advance for the projectile's host-owned arrival.
func _native_projectile_until(condition: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while not bool(condition.call()) and Time.get_ticks_msec() < deadline:
		_native_poll()
		await (Engine.get_main_loop() as SceneTree).process_frame
	_native_drain()
	return bool(condition.call())


func _native_prepare_quick_start(director: NativeDirector, manager: Node) -> bool:
	# Only presentation clocks are manually driven in this fixture. The real
	# host owns start admission, Wind, action identity, cooldown and strike time;
	# a guest start still crosses the existing loopback ENet connection.
	var arbiter: RefCounted = _native_host.get("_encounter_host")
	var encounter: String = manager.call("encounter_id")
	var peer := director._local_peer_id()
	var uid: String = str(manager.call("active_creature").get("uid"))
	var authority: Dictionary = arbiter.call("strike_authority_state", encounter, peer)
	var previous := int(authority.get("last_action", 0))
	var actor: Dictionary = (arbiter.call("record", encounter) as Dictionary).get("participants", {}).get(peer, {}).get("move_resources", {}).get(uid, {})
	var ready_at := maxi(int(authority.get("deadline_ms", 0)), int(actor.get("cooldowns", {}).get("quick", 0)))
	if not await _native_projectile_until(func() -> bool: return Time.get_ticks_msec() >= ready_at): return false
	# Disabled fixture physics cannot advance its local animation state. This
	# does not touch the arbiter's retained commitment or resource state.
	manager.set("_action", NATIVE_COMBAT.Action.READY)
	manager.call("_start_action", {}, "quick")
	if not await _native_projectile_until(func() -> bool:
		return not bool(manager.get("_move_awaiting_host"))): return false
	var pending: Dictionary = manager.get("_pending_move")
	var started: Dictionary = arbiter.call("move_commit", encounter, peer)
	if int(pending.get("accepted_action", 0)) <= previous or int(started.get("action", 0)) != int(pending.get("accepted_action", 0)): return false
	return await _native_projectile_until(func() -> bool: return Time.get_ticks_msec() >= int(started.get("strike_at_ms", 0)))

## The old live-only six-HP setup is a negative control, followed by the exact
## helper used by win_trainer_battle. Production authority/presentation stays
## unchanged; this witnesses the fixture and arrival, not a complete Warden win.
func _case_native_trainer_hp_fixture_survives_projectile_snapshot(warden_boss: bool = false) -> void:
	_native_hp_fixture_completed = false
	if not _native_build(): return
	assert_true(NATIVE_COMBAT.MATH.config().get("actor_vitals", {}).get("runtime_enabled") is bool,
		"the native fixture uses the actual configured actor-publication contract")
	var guest_id := _native_guest_api.get_unique_id()
	var owners := {1: "native-hp-host", guest_id: "native-hp-guest"}
	for director: NativeDirector in [_native_host, _native_guest]:
		var session := director.get("_session") as SessionStub
		session.applied = true
		session.owners = owners.duplicate()
		(director.get("_manager") as Node).free()
	var host_root := _native_fixture.get_node("Host")
	var guest_root := _native_fixture.get_node("Guest")
	var host_manager := NativeTrainerManager.new()
	var guest_manager := NativeTrainerManager.new()
	host_root.add_child(host_manager)
	guest_root.add_child(guest_manager)
	host_manager.set_physics_process(false)
	guest_manager.set_physics_process(false)
	_native_host.set("_manager", host_manager)
	_native_guest.set("_manager", guest_manager)
	var striker := NATIVE_SPECIES.spawn("terrapup")
	var guest_creature := NATIVE_SPECIES.spawn("trailpup")
	var enemy := NATIVE_SPECIES.spawn("bramblebun")
	var mirror := NATIVE_CREATURE_CODEC.decode(NATIVE_CREATURE_CODEC.encode(enemy))
	assert_true(mirror != null)
	if mirror == null: return
	_native_admit_owned_creatures(owners, {1: striker, guest_id: guest_creature})
	var ally := _native_trainer_body(host_root, striker, Vector3(0.0, 0.0, 1.1), 1)
	ally.add_to_group("deployed_creature")
	var guest_ally := _native_trainer_body(guest_root, guest_creature, Vector3(4.0, 0.0, 0.0), guest_id)
	var foe := _native_trainer_body(host_root, enemy, Vector3.ZERO)
	var guest_foe := _native_trainer_body(guest_root, mirror, Vector3.ZERO)
	var player := Node3D.new()
	var guest_player := Node3D.new()
	host_root.add_child(player)
	guest_root.add_child(guest_player)
	_native_host.set("_ally", striker)
	_native_host.set("_ally_body", ally)
	_native_host.set("_player", player)
	var trainer_spec: Dictionary = NATIVE_TRAINERS.trainer("warden_aldis") if warden_boss else {"id": "native-hp-fixture"}
	assert_false(trainer_spec.is_empty(), "the boss mode uses the actual Warden trainer data")
	_native_host.set("_trainer_spec", trainer_spec)
	_native_host.set("_trainer_body", foe)
	_native_host.set("_engaged_with", foe)
	_native_host._host_set_deployed(1, {"creature_uid": striker.uid,
		"species_id": striker.species_id, "shiny": false, "card": _native_host._creature_card(striker)})
	assert_true(host_manager.begin(player, foe, ally, [striker] as Array[RefCounted], null, null, true))
	assert_true(guest_manager.begin(guest_player, guest_foe, guest_ally, [guest_creature] as Array[RefCounted], null, null, true))
	# Let production mint/bind the record as the real trainer send-out does.
	# The old handcrafted "trainer" row missed Warden's actual "boss" kind.
	_native_host._open_encounter_if_networked(foe, true)
	var arbiter: RefCounted = _native_host.get("_encounter_host")
	var rec: Dictionary = _native_host.get("_encounter") as Dictionary
	assert_false(rec.is_empty(), "the production opener created the actual opponent-owned record")
	if rec.is_empty(): return
	var encounter_id := str(rec.encounter_id)
	var kind := str(rec.kind)
	assert_eq(kind, "boss" if warden_boss else "trainer", "production classifies the Warden from boss_ranks")
	assert_eq(str(rec.get("opponent", {}).get("owner_npc", "")), str(trainer_spec.get("id", "")))
	assert_eq(host_manager.encounter_id(), encounter_id, "production opener bound the manager to that record")
	guest_manager.bind_encounter(_native_guest, encounter_id, kind)
	var join := _native_guest.submit_encounter_intent({"kind": "engage", "encounter_id": encounter_id,
		"character_id": owners[guest_id]})
	assert_true(bool(join.get("pending", false)))
	assert_true(_native_until(func() -> bool: return (arbiter.call("participants_of", encounter_id) as Array).has(guest_id)))
	_native_drain()
	var exits: Array[String] = []
	host_manager.exited.connect(func(outcome: String) -> void: exits.append(outcome))
	var finished: Array[Dictionary] = []
	_native_host.host_strike_finished.connect(func(_intent: Dictionary, author: int, verdict: Dictionary) -> void:
		finished.append({"author": author, "verdict": verdict.duplicate(true)}))
	var pending := host_manager._move_profile("player_quick", str(striker.move_quick))
	pending["is_quick"] = true
	host_manager.set("_pending_move", pending)
	assert_eq(str(striker.move_quick), "pebble_toss")
	var hp_full := float(enemy.hp)
	# Ordinary full-health control: admission does not change HP; arrival does.
	assert_true(await _native_prepare_quick_start(_native_host, host_manager), "a real host start precedes the strike")
	host_manager._submit_strike_intent()
	assert_almost_eq(float(enemy.hp), hp_full)
	assert_true(await _native_projectile_until(func() -> bool: return finished.size() == 1))
	assert_true(bool(finished.back().get("verdict", {}).get("delta", {}).get("hit", false)))
	_native_assert_actor_publication_contract(arbiter, encounter_id, 1, ally)
	assert_true(float(enemy.hp) > 6.0 and float(enemy.hp) < hp_full)
	assert_false((arbiter.call("pending_move_mastery") as Array).is_empty(), "the absent fixture writer cannot fake saved mastery")
	assert_almost_eq(float(arbiter.call("opponent_hp", encounter_id)), float(enemy.hp))
	assert_almost_eq(float(mirror.hp), float(enemy.hp))
	var hp_after_control := float(enemy.hp)
	var deadline := int((arbiter.call("strike_authority_state", encounter_id, 1) as Dictionary).get("deadline_ms", 0))
	assert_true(await _native_projectile_until(func() -> bool: return Time.get_ticks_msec() >= deadline))
	# Reproduce only the original smoke's live-only cap, without changing authority.
	enemy.set("hp", 6.0)
	assert_true(await _native_prepare_quick_start(_native_host, host_manager))
	host_manager._submit_strike_intent()
	assert_almost_eq(float(enemy.hp), hp_after_control, 0.001, "the authoritative launch snapshot correctly overwrites the invalid live-only fixture")
	assert_true(await _native_projectile_until(func() -> bool: return finished.size() == 2))
	assert_true(float(enemy.hp) > 6.0 and float(enemy.hp) < hp_after_control)
	var fixture_script: Script = load("res://tools/net/peer_runner.gd")
	var hp_before_wrong_body := float(enemy.hp)
	var seq_before_wrong_body := int((arbiter.call("record", encounter_id) as Dictionary).get("seq", 0))
	assert_eq(str(mirror.get("uid")), str(enemy.get("uid")), "the refused body represents the same opponent UID")
	var wrong_body: Dictionary = fixture_script.call("_stage_trainer_hp_ceiling", _native_host, host_manager, guest_foe, 6.0)
	assert_false(bool(wrong_body.get("ok", true)), "another body with the same opponent UID cannot stage canonical HP")
	assert_almost_eq(float(enemy.hp), hp_before_wrong_body)
	assert_eq(int((arbiter.call("record", encounter_id) as Dictionary).get("seq", 0)), seq_before_wrong_body)
	var before_authority: Dictionary = arbiter.call("strike_authority_state", encounter_id, 1)
	var max_hp_before := float(enemy.max_hp)
	var phase_before := str(arbiter.call("phase", encounter_id))
	var staged: Dictionary = fixture_script.call("_stage_trainer_hp_ceiling", _native_host, host_manager, foe, 6.0)
	assert_true(bool(staged.get("ok", false)))
	_native_drain()
	assert_almost_eq(float(enemy.hp), 6.0)
	assert_almost_eq(float(arbiter.call("opponent_hp", encounter_id)), 6.0)
	assert_almost_eq(float(mirror.hp), 6.0)
	assert_almost_eq(float(enemy.max_hp), max_hp_before)
	assert_eq(str(arbiter.call("phase", encounter_id)), phase_before)
	assert_eq(arbiter.call("strike_authority_state", encounter_id, 1), before_authority, "setup cannot reset cooldown or accepted-action authority")
	assert_false(bool(enemy.fainted), "HP setup cannot cause a faint or won outcome")
	assert_eq(host_manager.state, NATIVE_COMBAT.State.ACTIVE)
	assert_true(exits.is_empty())
	assert_eq(int(striker.battles_fought), 0)
	var staged_seq := int((arbiter.call("record", encounter_id) as Dictionary).get("seq", 0))
	assert_true(bool((fixture_script.call("_stage_trainer_hp_ceiling", _native_host, host_manager, foe, 6.0) as Dictionary).get("ok", false)))
	assert_eq(int((arbiter.call("record", encounter_id) as Dictionary).get("seq", 0)), staged_seq,
		"an already consistent ceiling cannot churn state sequence")
	var refused: Dictionary = fixture_script.call("_stage_trainer_hp_ceiling", _native_guest, guest_manager, guest_foe, 6.0)
	assert_false(bool(refused.get("ok", true)), "a guest cannot stage shared authoritative HP")
	assert_almost_eq(float(mirror.hp), 6.0)
	# The same six-HP fixture must survive the next real scheduled projectile.
	for attempt in 8:
		deadline = int((arbiter.call("strike_authority_state", encounter_id, 1) as Dictionary).get("deadline_ms", 0))
		assert_true(await _native_projectile_until(func() -> bool: return Time.get_ticks_msec() >= deadline))
		var hp_before := float(enemy.hp)
		var count_before := finished.size()
		assert_true(await _native_prepare_quick_start(_native_host, host_manager))
		host_manager._submit_strike_intent()
		assert_almost_eq(float(enemy.hp), hp_before, 0.001, "launch cannot undo the consistent canonical fixture")
		assert_true(await _native_projectile_until(func() -> bool: return finished.size() > count_before))
		assert_true(float(enemy.hp) < hp_before, "only the real host arrival reduces HP")
		if bool(enemy.fainted): break
	assert_true(bool(enemy.fainted), "the real CreatureInstance.take_damage, never fixture setup, causes the faint")
	assert_true(bool(finished.back().get("verdict", {}).get("delta", {}).get("killed", false)))
	assert_almost_eq(float(enemy.hp), 0.0)
	assert_eq(str(arbiter.call("phase", encounter_id)), "done")
	assert_eq(host_manager.state, NATIVE_COMBAT.State.RESOLVING)
	assert_eq(guest_manager.state, NATIVE_COMBAT.State.RESOLVING)
	assert_true(exits.is_empty(), "the original faint pause still precedes round exit")
	_native_hp_fixture_observation = {"kind": kind, "owner_npc": trainer_spec.get("id", ""),
		"tracked_runtime": NATIVE_COMBAT.MATH.config().get("actor_vitals", {}).get("runtime_enabled"),
		"record_created_by_production_opener": true, "full_hp": hp_full, "hp_after_control": hp_after_control,
		"ceiling": 6.0, "max_hp": enemy.max_hp, "accepted_arrivals": finished.size(),
		"killed_by_host_arrival": enemy.fainted, "record_phase": arbiter.call("phase", encounter_id)}
	_native_hp_fixture_completed = true
	_native_hp_fixture_observations.append(_native_hp_fixture_observation.duplicate(true))

func test_native_trainer_hp_fixture_survives_projectile_snapshot() -> void:
	var runner_path := "user://director_hp_fixture_regression_runner.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null: return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_director_join_snapshot.gd").new()\n\tfor boss in [false, true]:\n\t\tawait test._case_native_trainer_hp_fixture_survives_projectile_snapshot(boss)\n\t\ttest._native_cleanup()\n\t\tif not test._native_hp_fixture_completed: break\n\tprint("DIRECTOR_HP_FIXTURE_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures,"completed":test._native_hp_fixture_completed and test._native_hp_fixture_observations.size() == 2,"observations":test._native_hp_fixture_observations}))\n\tquit(0 if test.failures.is_empty() and test._native_hp_fixture_completed and test._native_hp_fixture_observations.size() == 2 else 1)\n')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(runner_path)
	var log_path := ProjectSettings.globalize_path("user://director-hp-fixture-regression-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("DIRECTOR_HP_FIXTURE_RESULT="):
			result = JSON.parse_string(line.trim_prefix("DIRECTOR_HP_FIXTURE_RESULT="))
	assert_true(bool(result.get("completed", false)), combined)
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_true(int(result.get("assertions", 0)) >= 90, "both native modes must execute their full cause and arrival checks")
	assert_eq((result.get("observations", []) as Array).size(), 2, "both production trainer and Warden boss records must finish")
	assert_false(combined.contains("ERROR:"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use"), combined)
	assert_eq(code, 0, combined)


## Scene presentation only. Creature HP/fainted, move profiles, cooldown/Wind,
## host admission, snapshots, verdict consumption, XP and round exit are real.
class NativeTrainerBody extends Node3D:
	signal strike_ready()
	signal telegraph_started(seconds: float)
	var instance: RefCounted
	var species_id := ""
	var owner_peer_id := 0
	var arena: Node3D
	var combat_override: Dictionary = {}
	var body_scale := 1.0
	var engaged := false
	var faint_presentations := 0
	var faint_notifications := 0
	func centre() -> Vector3:
		return global_position + Vector3.UP
	func facing() -> Vector3:
		return Vector3.FORWARD
	func body_radius() -> float:
		return 0.45
	func body_height() -> float:
		return 2.0
	func combat_config() -> Dictionary:
		return {}
	func set_engaged(value: bool, _target: Node3D = null) -> void:
		engaged = value
	func add_impulse(_direction: Vector3, _amount: float) -> void:
		pass
	func face_towards(_point: Vector3) -> void:
		pass
	func play_attack() -> void:
		pass
	func play_hit() -> void:
		pass
	func play_faint() -> void:
		faint_presentations += 1
	func notify_fainted() -> void:
		faint_notifications += 1

class NativeTrainerManager extends "res://scripts/combat/combat_manager.gd":
	func _open_arena() -> void:
		_arena = Node3D.new()
		_player.get_parent().add_child(_arena)
	func _place_fighters() -> void:
		# Both sides use the same fixed host-held geometry; no terrain in this fixture.
		pass
	func _flash_host_impact(_where: Vector3, _charged: bool, _tint: Variant = null,
			_struck: Node3D = null, _damage_fraction: float = 0.0,
			_impact: Dictionary = {}, _shake_camera: bool = true) -> void:
		pass

const NATIVE_COMBAT := preload("res://scripts/combat/combat_manager.gd")
const NATIVE_SPECIES := preload("res://scripts/creatures/creature_species.gd")
const NATIVE_TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const NATIVE_CREATURE_CODEC := preload("res://scripts/save/water_capture_codec.gd")
var _native_trainer_completed := false
var _native_trainer_observation: Dictionary = {}

func _native_admit_owned_creatures(owners: Dictionary, creatures: Dictionary) -> void:
	# Disclosed stock creature fixture, through the real portable serializer and
	# CharacterAuthority admission. It proves no capture, earned tier, or save.
	for director: NativeDirector in [_native_host, _native_guest]:
		var session := director.get("_session") as SessionStub
		for peer: int in creatures:
			var player := preload("res://autoload/player_state.gd").new()
			player.configure(preload("res://autoload/item_db.gd").new())
			player.character_id = str(owners[peer])
			assert_true(player.party.add(creatures[peer]), "the actual five-cap portable party owns this fixture creature")
			var saved: Dictionary = player.save_data()
			saved.redesign_character = preload("res://scripts/creatures/teaching.gd").character_loadout_mirror(saved.party, saved.redesign_character)
			var admitted: Dictionary = session._character_authority.seed_admitted_character(AUTHORITY.portable_projection(saved), player.character_id)
			assert_true(admitted.get("ok") == true, "actual CharacterAuthority validates original portable state: " + str(admitted))
			assert_eq(session.admitted_character_state(peer).party[0].uid, creatures[peer].uid)
			player.party.remove_at(0)

func _native_assert_actor_publication_contract(arbiter: RefCounted, encounter: String, peer: int, body: Node3D) -> void:
	var participant: Dictionary = arbiter.call("record", encounter).get("participants", {}).get(peer, {})
	var uid: String = str(body.get("instance").get("uid"))
	if NATIVE_COMBAT.MATH.config().get("actor_vitals", {}).get("runtime_enabled") == true:
		var actor: Dictionary = participant.get("actor_vitals", {}).get(uid, {})
		assert_eq(participant.get("actor_bound_uid"), uid, "tracked arrival bound the actual owned attacker")
		assert_eq(actor.get("body_instance_id"), body.get_instance_id(), "tracked arrival retained the exact host body")
		assert_true(int(actor.get("body_generation", 0)) > 0, "tracked publication has a real actor lifetime")
	else:
		assert_eq(participant.get("actor_vitals", {}), {}, "ordinary configured mode creates no tracked actor-vitals carrier")

func _native_trainer_body(parent: Node, creature: RefCounted, at: Vector3,
		owner: int = 0) -> NativeTrainerBody:
	var body := NativeTrainerBody.new()
	body.instance = creature
	body.species_id = str(creature.get("species_id"))
	body.owner_peer_id = owner
	parent.add_child(body)
	body.global_position = at
	return body

func _native_trainer_request(intent: Dictionary, completed: Array[Dictionary]) -> Dictionary:
	completed.clear()
	var pending := _native_guest.submit_encounter_intent(intent)
	assert_true(bool(pending.get("pending", false)), "the guest sends over actual ENet, without a host fast path")
	var arrived := _native_until(func() -> bool: return not completed.is_empty())
	assert_true(arrived, "the native sender reached ordinary host strike arbitration")
	if not arrived: return {}
	_native_drain()
	return completed.back().duplicate(true)

func _case_native_guest_kill_advances_host_trainer_round() -> void:
	if not _native_build(): return
	assert_true(NATIVE_COMBAT.MATH.config().get("actor_vitals", {}).get("runtime_enabled") is bool,
		"ordinary trainer strikes use the actual configured actor-publication contract")
	var guest_id := _native_guest_api.get_unique_id()
	var owners := {1: "native-trainer-host", guest_id: "native-trainer-guest"}
	for director: NativeDirector in [_native_host, _native_guest]:
		var session := director.get("_session") as SessionStub
		session.applied = true
		session.owners = owners.duplicate()
		(director.get("_manager") as Node).free()
	var host_root := _native_fixture.get_node("Host")
	var guest_root := _native_fixture.get_node("Guest")
	var host_manager := NativeTrainerManager.new()
	var guest_manager := NativeTrainerManager.new()
	host_root.add_child(host_manager)
	guest_root.add_child(guest_manager)
	host_manager.set_physics_process(false)
	guest_manager.set_physics_process(false)
	_native_host.set("_manager", host_manager)
	_native_guest.set("_manager", guest_manager)
	var host_creature := NATIVE_SPECIES.spawn("terrapup")
	var guest_creature := NATIVE_SPECIES.spawn("trailpup")
	var enemy := NATIVE_SPECIES.spawn("bramblebun")
	var mirror := NATIVE_CREATURE_CODEC.decode(NATIVE_CREATURE_CODEC.encode(enemy))
	assert_true(mirror != null, "the production creature codec reconstructs the host opponent")
	if mirror == null: return
	assert_eq(str(mirror.get("uid")), str(enemy.get("uid")), "the author's verdict targets the actual mirrored UID")
	var next_creature := NATIVE_SPECIES.spawn("mudsnout")
	_native_admit_owned_creatures(owners, {1: host_creature, guest_id: guest_creature})
	var host_ally := _native_trainer_body(host_root, host_creature, Vector3(-4.0, 0.0, 0.0), 1)
	var guest_proxy := _native_trainer_body(host_root, guest_creature, Vector3(0.0, 0.0, 1.1), guest_id)
	var guest_ally := _native_trainer_body(guest_root, guest_creature, guest_proxy.global_position, guest_id)
	host_ally.add_to_group("deployed_creature")
	guest_proxy.add_to_group("deployed_creature")
	var foe := _native_trainer_body(host_root, enemy, Vector3.ZERO)
	var guest_foe := _native_trainer_body(guest_root, mirror, Vector3.ZERO)
	var host_player := Node3D.new()
	var guest_player := Node3D.new()
	host_root.add_child(host_player)
	guest_root.add_child(guest_player)
	host_player.global_position = Vector3(-8.0, 0.0, 0.0)
	guest_player.global_position = Vector3(-8.0, 0.0, 0.0)
	_native_host.set("_ally", host_creature)
	_native_host.set("_ally_body", host_ally)
	_native_host.set("_player", host_player)
	_native_host.set("_trainer_spec", {"id": "native-trainer-regression"})
	_native_host.set("_trainer_queue", [next_creature] as Array[RefCounted])
	_native_host.set("_trainer_body", foe)
	_native_host.set("_trainer_sent", 1)
	_native_host.set("_engaged_with", foe)
	_native_host._host_set_deployed(guest_id, {"creature_uid": guest_creature.uid,
		"species_id": guest_creature.species_id, "shiny": false,
		"card": _native_host._creature_card(guest_creature)})
	_native_host._ensure_encounter_arbiters()
	var arbiter: RefCounted = _native_host.get("_encounter_host")
	var rec: Dictionary = arbiter.call("open", 1, "meadows", "trainer", {
		"species_id": enemy.species_id, "level": enemy.level, "hp": enemy.hp,
		"hp_max": enemy.max_hp, "owner_npc": "native-trainer-regression",
		"card": NATIVE_CREATURE_CODEC.encode(enemy),
		"position": [foe.centre().x, foe.centre().y, foe.centre().z]}, host_creature.uid, owners[1])
	var encounter_id := str(rec.encounter_id)
	_native_host.set("_encounter", rec)
	assert_true(host_manager.begin(host_player, foe, host_ally, [host_creature] as Array[RefCounted], null, null, true),
		"production begin opens the host's full-health trainer round")
	assert_true(guest_manager.begin(guest_player, guest_foe, guest_ally, [guest_creature] as Array[RefCounted], null, null, true),
		"production begin opens the guest's full-health presentation")
	host_manager.bind_encounter(_native_host, encounter_id, "trainer")
	guest_manager.bind_encounter(_native_guest, encounter_id, "trainer")
	host_manager.exited.connect(_native_host._on_combat_exited)
	var exits: Array[String] = []
	host_manager.exited.connect(func(outcome: String) -> void: exits.append(outcome))
	var joined := _native_guest.submit_encounter_intent({"kind": "engage",
		"encounter_id": encounter_id, "character_id": owners[guest_id]})
	assert_true(bool(joined.get("pending", false)))
	assert_true(_native_until(func() -> bool: return (arbiter.call("participants_of", encounter_id) as Array).has(guest_id)),
		"the actual guest sender is admitted through production engage and join")
	_native_drain()
	_native_host._note_trainer_participants(encounter_id)
	var roster_before: Dictionary = (_native_host.get("_trainer_battle_participants") as Dictionary).duplicate()
	assert_eq(roster_before.size(), 2, "the battle retains both fighting participants for its eventual payout")
	assert_almost_eq(float(enemy.hp), float(enemy.max_hp), 0.001, "no HP cap or damage fixture")
	assert_eq(str(guest_creature.move_quick), "pack_bite", "use the species' real named quick move")
	var completed: Array[Dictionary] = []
	_native_host.host_strike_finished.connect(func(_intent: Dictionary, author: int, verdict: Dictionary) -> void:
		completed.append({"author": author, "verdict": verdict.duplicate(true)}))
	var intent := {"kind": "strike_intent", "encounter_id": encounter_id, "action": 1,
		"slot": "quick", "move_id": guest_creature.move_quick,
		"origin": [guest_proxy.centre().x, guest_proxy.centre().y, guest_proxy.centre().z],
		"facing": [0.0, 0.0, -1.0]}
	assert_true(await _native_prepare_quick_start(_native_guest, guest_manager), "the guest's real ENet move start precedes its strike")
	intent["action"] = int((guest_manager.get("_pending_move") as Dictionary).get("accepted_action", 0))
	var first := _native_trainer_request(intent, completed)
	var first_verdict: Dictionary = first.get("verdict", {})
	assert_eq(int(first.get("author", 0)), guest_id, "authorship is the real remote sender, not the listen host")
	assert_true(bool(first_verdict.get("ok", false)))
	assert_true(bool(first_verdict.get("delta", {}).get("hit", false)))
	_native_assert_actor_publication_contract(arbiter, encounter_id, guest_id, guest_proxy)
	assert_false(bool(first_verdict.get("delta", {}).get("killed", true)), "a non-killing hit cannot advance a round")
	assert_true(float(enemy.hp) > 0.0 and float(enemy.hp) < float(enemy.max_hp))
	assert_eq(host_manager.state, NATIVE_COMBAT.State.ACTIVE)
	assert_true(exits.is_empty())
	assert_almost_eq(float(_native_host.get("_trainer_send_delay")), 0.0)
	assert_eq(int(host_creature.battles_fought), 0)
	assert_eq(int(guest_creature.battles_fought), 0)
	assert_almost_eq(float(mirror.hp), float(enemy.hp), 0.001, "the ordinary snapshot/verdict reconciles absolute HP")
	var hp_after_first := float(enemy.hp)
	var duplicate := _native_trainer_request(intent, completed)
	assert_eq(str(duplicate.get("verdict", {}).get("code", "")), "move_start_required",
		"a resolved committed move cannot be reused as a current start")
	assert_almost_eq(float(enemy.hp), hp_after_first)
	assert_true(exits.is_empty(), "replayed non-killing intent cannot fake a won round")
	var host_energy_before := float(host_creature.energy)
	var killing: Dictionary = {}
	for action in range(2, 65):
		var deadline := int((arbiter.call("strike_authority_state", encounter_id, guest_id) as Dictionary).get("deadline_ms", 0))
		if not _native_until(func() -> bool: return Time.get_ticks_msec() >= deadline): break
		assert_true(await _native_prepare_quick_start(_native_guest, guest_manager))
		intent["action"] = int((guest_manager.get("_pending_move") as Dictionary).get("accepted_action", 0))
		var answer := _native_trainer_request(intent, completed)
		var verdict: Dictionary = answer.get("verdict", {})
		if not bool(verdict.get("ok", false)): break
		if bool(verdict.get("delta", {}).get("killed", false)):
			killing = answer
			break
	assert_false(killing.is_empty(), "ordinary admitted strikes must cause a real CreatureInstance faint")
	assert_eq(int(killing.get("author", 0)), guest_id)
	assert_almost_eq(float(enemy.hp), 0.0)
	assert_true(bool(enemy.fainted), "the host's actual take_damage caused the faint")
	assert_false((arbiter.call("pending_move_mastery") as Array).is_empty(), "real accepted hits remain pending without a disk writer")
	_native_trainer_observation = {"host_state": host_manager.state, "guest_state": guest_manager.state,
		"tracked_runtime": NATIVE_COMBAT.MATH.config().get("actor_vitals", {}).get("runtime_enabled"),
		"record_phase": str(arbiter.call("phase", encounter_id)), "enemy_hp": enemy.hp,
		"enemy_fainted": enemy.fainted, "author": killing.get("author", 0), "guest_id": guest_id}
	assert_eq(host_manager.state, NATIVE_COMBAT.State.RESOLVING, "a guest kill must start the host's ordinary faint pause")
	assert_eq(guest_manager.state, NATIVE_COMBAT.State.RESOLVING, "the author consumes its richer killing verdict")
	assert_almost_eq(float(host_creature.energy), host_energy_before, 0.001, "the observer must not gain energy for the guest's strike")
	var guest_energy := float(guest_creature.energy)
	var guest_battles := int(guest_creature.battles_fought)
	var delta: Dictionary = killing.get("verdict", {}).get("delta", {})
	guest_manager.apply_host_strike_verdict(delta)
	_native_host._host_after_encounter_change(encounter_id, guest_id)
	assert_almost_eq(float(guest_creature.energy), guest_energy)
	assert_eq(int(guest_creature.battles_fought), guest_battles, "duplicate verdict cannot pay another round award")
	assert_true(exits.is_empty(), "the faint pause is preserved; no immediate exit shortcut")
	var pause := float(NATIVE_COMBAT.MATH.config().get("flow", {}).get("faint_pause", 1.6))
	for _tick in int(ceil(pause * 60.0)) + 1:
		# Elapse the unchanged production resolution clock; never set state/timer/outcome.
		if host_manager.state == NATIVE_COMBAT.State.RESOLVING: host_manager._physics_process(1.0 / 60.0)
		if guest_manager.state == NATIVE_COMBAT.State.RESOLVING: guest_manager._physics_process(1.0 / 60.0)
	_native_drain()
	assert_eq(exits, ["won"] as Array[String], "the real manager exit advances the host trainer round exactly once")
	assert_eq(host_manager.state, NATIVE_COMBAT.State.INACTIVE)
	assert_eq(foe.faint_notifications, 1, "production trainer round teardown notifies the original fainted body")
	assert_eq(_native_host.get("_trainer_body"), null)
	assert_true(float(_native_host.get("_trainer_send_delay")) > 0.0, "the ordinary next-send-out clock is armed")
	assert_eq(_native_host.get("_trainer_queue"), [next_creature] as Array[RefCounted], "the next creature remains queued until that clock expires")
	assert_true(_native_host.trainer_battle_active(), "a won round is not a fabricated complete trainer victory")
	assert_eq(_native_host.get("_trainer_battle_participants"), roster_before, "round teardown preserves the eventual participant payout roster")
	assert_eq(int(host_creature.battles_fought), 1, "the observing host receives one ordinary round award")
	assert_eq(int(guest_creature.battles_fought), 1, "the guest author receives one ordinary round award")
	_native_trainer_observation.merge({"host_state_after_pause": host_manager.state,
		"host_exits": exits.duplicate(), "send_delay": _native_host.get("_trainer_send_delay"),
		"queued": (_native_host.get("_trainer_queue") as Array).size(),
		"host_round_awards": host_creature.battles_fought, "guest_round_awards": guest_creature.battles_fought})
	var stale := _native_trainer_request(intent, completed)
	assert_false(bool(stale.get("verdict", {}).get("ok", true)), "a stale killing intent cannot be admitted in the completed round")
	guest_manager.apply_host_strike_verdict(delta)
	_native_host._host_after_encounter_change(encounter_id, guest_id)
	assert_eq(exits, ["won"] as Array[String])
	assert_eq(foe.faint_notifications, 1)
	assert_eq(int(host_creature.battles_fought), 1)
	assert_eq(int(guest_creature.battles_fought), 1)
	_native_trainer_completed = true

func test_native_guest_killing_strike_advances_host_trainer_round_once() -> void:
	var runner_path := "user://director_guest_trainer_regression_runner.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null: return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_director_join_snapshot.gd").new()\n\tawait test._case_native_guest_kill_advances_host_trainer_round()\n\ttest._native_cleanup()\n\tprint("DIRECTOR_GUEST_TRAINER_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures,"completed":test._native_trainer_completed,"observation":test._native_trainer_observation}))\n\tquit(0 if test.failures.is_empty() and test._native_trainer_completed else 1)\n')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(runner_path)
	var log_path := ProjectSettings.globalize_path("user://director-guest-trainer-regression-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("DIRECTOR_GUEST_TRAINER_RESULT="):
			result = JSON.parse_string(line.trim_prefix("DIRECTOR_GUEST_TRAINER_RESULT="))
	assert_true(bool(result.get("completed", false)), combined)
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_true(int(result.get("assertions", 0)) >= 45, "the native cause and advancement assertions must finish")
	assert_false(combined.contains("ERROR:"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use"), combined)
	assert_eq(code, 0, combined)
