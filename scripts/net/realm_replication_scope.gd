extends Node

## Scoped client-transition adapter. No coordinator/token means the original
## spawn/outgoing policy is unchanged. Created before replicated body tree entry.
const TRANSITION_PATH := ^"/root/Game/Session/RealmTransition"
const ADAPTER_NAME := "RealmReplicationScope"
const ADMISSION_NAME := "AdmissionSync"
const BODY_REALM := &"replication_realm"
const BODY_OWNER := &"replication_owner"
const BODY_ORIGIN := &"replication_origin"
signal inventory_changed

var spawner: MultiplayerSpawner
var realm := ""
var received: Dictionary = {}
var producer: Node

static func attach(source: MultiplayerSpawner, source_realm: String, source_producer: Node = null) -> Node:
	if source == null:
		return null
	var existing := source.get_node_or_null(ADAPTER_NAME)
	if existing != null:
		if source_producer != null:
			existing.set("producer", source_producer)
		return existing
	var adapter := load("res://scripts/net/realm_replication_scope.gd").new() as Node
	adapter.name = ADAPTER_NAME
	adapter.set("spawner", source)
	adapter.set("realm", source_realm)
	adapter.set("producer", source_producer)
	source.add_child(adapter)
	return adapter

static func wire_body(body: Node, state: MultiplayerSynchronizer,
		source_realm: String, owner: int, host_baseline: Callable = Callable(), origin: String = "") -> void:
	if body == null or state == null or body.has_node(ADMISSION_NAME):
		return
	body.set_meta(BODY_REALM, source_realm)
	body.set_meta(BODY_OWNER, owner)
	body.set_meta(BODY_ORIGIN, origin)
	state.add_visibility_filter(func(observer: int) -> bool:
		return outgoing_allowed(body, observer))
	var admission := MultiplayerSynchronizer.new()
	admission.name = ADMISSION_NAME
	admission.root_path = ^".."
	admission.replication_config = SceneReplicationConfig.new()
	admission.set_multiplayer_authority(1)
	admission.add_visibility_filter(func(observer: int) -> bool:
		# Engine's previous remote-owner fallback was visible. On a host-owned
		# body OR composition must not widen its existing state-sync policy.
		return baseline_admission(owner, observer, host_baseline) and admission_allowed(body, observer))
	body.add_child(admission)

static func baseline_admission(owner: int, observer: int, host_baseline: Callable = Callable()) -> bool:
	return bool(host_baseline.call(observer)) if owner == 1 and host_baseline.is_valid() else true

static func coordinator(node: Node) -> Node:
	return node.get_node_or_null(TRANSITION_PATH) if node != null and node.is_inside_tree() else null

static func outgoing_allowed(body: Node, observer: int) -> bool:
	var transition := coordinator(body)
	if transition == null:
		return true
	return public_or_recipient_allowed(observer, body.multiplayer.get_peers(), func(peer: int) -> bool:
		return bool(transition.call("outgoing_allowed", int(body.get_meta(BODY_OWNER, 0)),
			str(body.get_meta(BODY_REALM, "")), peer, str(body.get_meta(BODY_ORIGIN, "")))))

static func admission_allowed(body: Node, observer: int) -> bool:
	var transition := coordinator(body)
	if transition == null:
		return true
	return public_or_recipient_allowed(observer, body.multiplayer.get_peers(), func(peer: int) -> bool:
		return bool(transition.call("admission_allowed", str(body.get_meta(BODY_REALM, "")),
			peer, int(body.get_meta(BODY_OWNER, 0)), str(body.get_meta(BODY_ORIGIN, "")))))

static func public_or_recipient_allowed(observer: int, recipients: PackedInt32Array, predicate: Callable) -> bool:
	if observer != 0:
		return bool(predicate.call(observer))
	# Native automatic visibility updates pass zero. True here means public,
	# allowing the engine to skip individual checks; it must mean ALL actual
	# recipients pass the scoped policy. Never recurse into a zero predicate.
	for peer: int in recipients:
		if not bool(predicate.call(peer)):
			return false
	return true

static func realm_of(node: Node) -> String:
	var cursor := node
	while cursor != null:
		if cursor.has_method("world_realm"):
			return str(cursor.call("world_realm"))
		cursor = cursor.get_parent()
	return ""

func _ready() -> void:
	if spawner == null:
		return
	spawner.spawned.connect(_spawned)
	spawner.despawned.connect(_despawned)
	var transition := coordinator(self)
	if transition != null:
		transition.call("register_scope", self)

func _exit_tree() -> void:
	var transition := coordinator(self)
	if transition != null:
		transition.call("unregister_scope", self)

func _spawned(body: Node) -> void:
	received[body.get_instance_id()] = weakref(body)
	inventory_changed.emit()

func _despawned(body: Node) -> void:
	received.erase(body.get_instance_id())
	inventory_changed.emit()

func received_count() -> int:
	# Do not remove a freed body here: that would manufacture a successful
	# drain after an unauthorized local free. Only actual despawn removes it.
	return received.size()

func bodies() -> Array[Node]:
	var result: Array[Node] = []
	if not is_instance_valid(spawner):
		return result
	var parent := spawner.get_node_or_null(spawner.spawn_path)
	if parent == null:
		return result
	for child: Node in parent.get_children():
		result.append(child)
	return result

func refresh_visibility(observer: int = 0) -> void:
	var observers: Array[int] = []
	if observer != 0:
		observers.append(observer)
	elif is_inside_tree() and multiplayer.has_multiplayer_peer():
		# Peer zero asks the engine to evaluate public visibility first. A
		# recipient-specific deny must refresh each actual connection instead.
		for peer: int in multiplayer.get_peers():
			observers.append(peer)
	for body: Node in bodies():
		for child: Node in body.get_children():
			if child is MultiplayerSynchronizer:
				for peer: int in observers:
					(child as MultiplayerSynchronizer).update_visibility(peer)

func unsupported_bodies() -> Array[String]:
	var result: Array[String] = []
	for body: Node in bodies():
		if not body.has_meta(BODY_OWNER) or not body.has_node(ADMISSION_NAME):
			result.append(str(body.get_path()))
	return result
