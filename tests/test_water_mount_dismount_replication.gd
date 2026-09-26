extends "res://tests/test_case.gd"

## F12 host-MOUNTED regression: a dismount must reach the host even while the
## owner's unreliable stream is being dropped.
##
## ENet throttles UNRELIABLE sends from its measured round-trip time. At
## throttle 0 it passes one packet in 32, so a slow frame stretch starves the
## always-mode (unreliable) sync for hundreds of physics ticks. Reliable
## on-change deltas are not throttled that way. The owner's aquatic snapshot
## carries the MOUNTED/HUMAN mode. When it rode the unreliable stream, the host
## got `net_riding=false` but kept the last pre-dismount MOUNTED packet.
## `smoke_net_water_mounted_swimming` reproduced this with the owner at HUMAN
## rev508 and the host at MOUNTED rev377, while the owner's ENet throttle to the
## host read 0.
##
## Two real SceneMultiplayer instances run the production remote_trainer.tscn
## replication config. They share an in-memory link that can drop unreliable
## sends, which makes the throttle's effect deterministic.
const TRAINER := preload("res://scenes/player/remote_trainer.tscn")
const STATE := preload("res://scripts/player/swim_state.gd")
const HOST_ID := 1
const OWNER_ID := 2

class Link extends MultiplayerPeerExtension:
	var id := 0
	var partner: Link
	var drop_unreliable := false
	var dropped := 0
	var _inbox: Array = []
	var _mode := MultiplayerPeer.TRANSFER_MODE_RELIABLE
	var _channel := 0

	func _get_available_packet_count() -> int:
		return _inbox.size()
	func _get_max_packet_size() -> int:
		return 1 << 20
	## SceneMultiplayer asks for the next packet's sender, channel and mode
	## BEFORE it takes the packet, so those read the head of the queue.
	func _head() -> Dictionary:
		return _inbox.front() if not _inbox.is_empty() else {}
	func _get_packet_script() -> PackedByteArray:
		return (_inbox.pop_front() as Dictionary).data
	func _put_packet_script(buffer: PackedByteArray) -> Error:
		if drop_unreliable and _mode != MultiplayerPeer.TRANSFER_MODE_RELIABLE:
			dropped += 1
			return OK
		partner._inbox.append({"data": buffer, "from": id, "mode": _mode, "channel": _channel})
		return OK
	func _get_packet_channel() -> int:
		return int(_head().get("channel", 0))
	func _get_packet_mode() -> MultiplayerPeer.TransferMode:
		return int(_head().get("mode", MultiplayerPeer.TRANSFER_MODE_RELIABLE)) as MultiplayerPeer.TransferMode
	func _get_packet_peer() -> int:
		return int(_head().get("from", 0))
	func _set_transfer_channel(channel: int) -> void:
		_channel = channel
	func _get_transfer_channel() -> int:
		return _channel
	func _set_transfer_mode(mode: MultiplayerPeer.TransferMode) -> void:
		_mode = mode
	func _get_transfer_mode() -> MultiplayerPeer.TransferMode:
		return _mode
	func _set_target_peer(_peer: int) -> void:
		pass
	func _is_server() -> bool:
		return id == HOST_ID
	func _is_server_relay_supported() -> bool:
		return false
	func _poll() -> void:
		pass
	func _close() -> void:
		pass
	func _disconnect_peer(_peer: int, _force: bool) -> void:
		pass
	func _get_unique_id() -> int:
		return id
	func _get_connection_status() -> MultiplayerPeer.ConnectionStatus:
		return MultiplayerPeer.CONNECTION_CONNECTED

var _fixture: Node
var _host_api: SceneMultiplayer
var _owner_api: SceneMultiplayer
var _owner_link: Link
var _host_body: Node
var _owner_body: Node
var _owner_state: RefCounted


func _build() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	_fixture = Node.new()
	_fixture.name = "WaterDismountReplication"
	tree.root.add_child(_fixture)
	var host_link := Link.new()
	host_link.id = HOST_ID
	_owner_link = Link.new()
	_owner_link.id = OWNER_ID
	host_link.partner = _owner_link
	_owner_link.partner = host_link
	_host_api = SceneMultiplayer.new()
	_owner_api = SceneMultiplayer.new()
	var host_root := Node.new()
	host_root.name = "Host"
	var owner_root := Node.new()
	owner_root.name = "Owner"
	_fixture.add_child(host_root)
	_fixture.add_child(owner_root)
	tree.set_multiplayer(_host_api, host_root.get_path())
	tree.set_multiplayer(_owner_api, owner_root.get_path())
	_host_api.multiplayer_peer = host_link
	_owner_api.multiplayer_peer = _owner_link
	host_link.emit_signal("peer_connected", OWNER_ID)
	_owner_link.emit_signal("peer_connected", HOST_ID)
	# The same production scene on both sides, owned by the rider, exactly as
	# trainer_spawn.gd builds it. No frame runs in this test, so its own
	# _physics_process never overwrites the replicated fields set below.
	_host_body = _trainer(host_root)
	_owner_body = _trainer(owner_root)
	_owner_state = STATE.new()
	_owner_state.owner_peer_id = OWNER_ID
	_owner_state.enter_water(true, 0.0)
	_publish(true)
	_pump(8)


func _trainer(parent: Node) -> Node:
	var body := TRAINER.instantiate()
	body.name = "Trainer_%d" % OWNER_ID
	body.set("peer_id", OWNER_ID)
	body.set_multiplayer_authority(OWNER_ID)
	parent.add_child(body)
	return body


## The owner's `_push_from_local_rig()`, reduced to the ride fields.
func _publish(riding: bool) -> void:
	_owner_body.set("net_riding", riding)
	_owner_body.set("net_carried", riding)
	_owner_body.set("net_aquatic", _owner_state.snapshot())


func _pump(rounds: int) -> void:
	for _i in rounds:
		_owner_api.poll()
		_host_api.poll()
		# Distinct microsecond stamps per replication round, as real frames have.
		OS.delay_usec(50)


func _teardown() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if is_instance_valid(_fixture):
		var host_path := _fixture.get_node("Host").get_path()
		var owner_path := _fixture.get_node("Owner").get_path()
		# Bodies leave while their API is still attached, so each synchronizer
		# unregisters from the replication interface that tracked it.
		_fixture.free()
		tree.set_multiplayer(null, host_path)
		tree.set_multiplayer(null, owner_path)
	_host_api = null
	_owner_api = null


func _host_mode() -> int:
	return int((_host_body.get("net_aquatic") as Dictionary).get("mode", -1))


func _case_dismount_reaches_host_while_unreliable_sync_is_throttled() -> void:
	_build()
	assert_true(bool(_host_body.get("net_riding")), "fixture: host received the ride")
	assert_eq(_host_mode(), STATE.Mode.MOUNTED, "fixture: host received the MOUNTED swimmer")
	# ENet throttle at zero: every unreliable send from the owner is dropped
	# for this window, reliable traffic still flows.
	_owner_link.drop_unreliable = true
	# water_riding_controller.gd::dismount() in deep water.
	_owner_state.enter_water(false, 0.0)
	_publish(false)
	_pump(8)
	assert_true(_owner_link.dropped > 0, "fixture: unreliable sends were actually dropped")
	assert_false(bool(_host_body.get("net_riding")), "host clears the ride (reliable)")
	assert_eq(_host_mode(), STATE.Mode.HUMAN,
		"host reconstructs the dismounted HUMAN swimmer, not the last MOUNTED packet: %s" % _host_body.get("net_aquatic"))
	var applied := STATE.new()
	applied.owner_peer_id = OWNER_ID
	assert_true(applied.apply_remote_snapshot(_host_body.get("net_aquatic"), OWNER_ID), "host decoder accepts the dismount packet")
	assert_eq(applied.mode, STATE.Mode.HUMAN, "applied host state is HUMAN")
	_teardown()


func _case_remount_reaches_host_while_unreliable_sync_is_throttled() -> void:
	_build()
	_owner_state.enter_water(false, 0.0)
	_publish(false)
	_pump(8)
	assert_eq(_host_mode(), STATE.Mode.HUMAN, "fixture: host holds the human swimmer")
	_owner_link.drop_unreliable = true
	_owner_state.enter_water(true, 0.0)
	_publish(true)
	_pump(8)
	assert_true(bool(_host_body.get("net_riding")), "host restores the ride (reliable)")
	assert_eq(_host_mode(), STATE.Mode.MOUNTED, "host restores MOUNTED with the ride")
	_teardown()


## Assertions the two cases above make; the child must finish all of them.
const EXPECTED_ASSERTIONS := 10


func test_water_mount_dismount_reaches_host_while_unreliable_sync_is_throttled() -> void:
	# run_tests invokes cases during SceneTree._init, before a subtree can be
	# given its own MultiplayerAPI. A tiny initialized child tree supplies it,
	# the same arrangement as test_water_mounted_replication.gd.
	var runner_path := "user://water_mount_dismount_replication_runner.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_water_mount_dismount_replication.gd").new()\n\tfor method in ["_case_dismount_reaches_host_while_unreliable_sync_is_throttled", "_case_remount_reaches_host_while_unreliable_sync_is_throttled"]:\n\t\ttest.call(method)\n\tprint("WATER_DISMOUNT_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count == %d else 1)\n' % EXPECTED_ASSERTIONS)
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(runner_path)
	var log_path := ProjectSettings.globalize_path("user://water-mount-dismount-replication-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("WATER_DISMOUNT_RESULT="):
			result = JSON.parse_string(line.trim_prefix("WATER_DISMOUNT_RESULT="))
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_eq(int(result.get("assertions", 0)), EXPECTED_ASSERTIONS, "child must finish all replication assertions")
	assert_false(combined.contains("SCRIPT ERROR"), combined)
	assert_eq(code, 0, combined)
