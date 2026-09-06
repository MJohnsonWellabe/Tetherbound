extends Node

## D101 + D97 -- the host stands up one remote trainer body per joined peer,
## and tears it down when they leave.
##
## Mounted in both world scenes beside D97's authored `Spawned` containers.
## The containers and their `MultiplayerSpawner`s are AUTHORED, not built here,
## precisely so a spawn that arrives while a peer is still running its
## procedural world build finds a `spawn_path` that already exists.
##
## ## Three rules taken straight from the ENet spike
##
## `ralph/reports/MP-0C-SPIKE-ENET-0905/REPORT.md`:
##
## 1. Authority is set INSIDE `spawn_function`, before the node enters the
##    tree. Setting it afterwards raises nothing and silently changes it on
##    the calling peer only -- authority is not a replicated property. The
##    spawn function is the one place that runs identically on every peer
##    before `add_child`, which is why it is the only correct place.
## 2. Peer ids are large random 32-bit numbers (`2098775056`), never 2, 3, 4.
##    Nothing here indexes by peer id or assumes an ordering; the registry maps
##    id to character explicitly and the node name carries the real id.
## 3. `add_child()` before wiring `spawn_path`/`spawn_function`. The spawners
##    are authored in the scene, so they are in the tree before this node's
##    `_ready()` runs and the ordering is satisfied by construction; the
##    `spawn_function` assignment below is therefore always a wire onto a node
##    that is already inside the tree.
##
## ## Solo is untouched
##
## Lane 2.A owns `Session`. Until it lands, and in any solo session after it
## does, `_session()` returns null or reports one peer and this node does
## nothing at all beyond wiring the spawn function. That is deliberate: every
## existing single-player smoke must stay a meaningful regression test, which
## is the whole reason D101 keeps one local rig per process.

const REMOTE_TRAINER := preload("res://scenes/player/remote_trainer.tscn")

## Where `Session` is mounted: a `Node` child of the `Game` autoload
## (`ralph/briefs/MP-W2/2A-SESSION.md` -- the one-autoload rule stands, so it
## is not its own singleton).
const SESSION_PATH := ^"/root/Game/Session"

@export var spawner_path: NodePath
## Where a freshly spawned trainer stands before its first replicated
## position arrives. Read from the world's own spawn point when it exposes
## one, so a joiner does not flash in at the origin.
@export var world_path: NodePath

var _spawner: MultiplayerSpawner = null
var _session: Node = null
## peer id -> the node standing for that peer, host side only. Clients receive
## their copies through the spawner and never index them here.
var _bodies: Dictionary = {}


func _ready() -> void:
	_spawner = get_node_or_null(spawner_path) as MultiplayerSpawner
	if _spawner == null:
		push_warning("trainer_spawn: no MultiplayerSpawner at '%s'" % str(spawner_path))
		return
	# Every peer wires the spawn function: it is what turns the host's
	# `spawn(data)` into a node locally, on each side.
	_spawner.spawn_function = _spawn_trainer

	_session = get_node_or_null(SESSION_PATH)
	if _session == null:
		return
	if _session.has_signal("peer_joined") \
			and not _session.is_connected("peer_joined", _on_peer_joined):
		_session.connect("peer_joined", _on_peer_joined)
	if _session.has_signal("peer_left") \
			and not _session.is_connected("peer_left", _on_peer_left):
		_session.connect("peer_left", _on_peer_left)
	if _session.has_signal("session_ended") \
			and not _session.is_connected("session_ended", _on_session_ended):
		_session.connect("session_ended", _on_session_ended)
	# Usually a no-op: the world is normally standing before anyone hosts, and
	# nothing may be spawned until there is a real peer under the spawner (see
	# `_is_host()`). It matters for the reverse order — a world loaded while a
	# session is already up, which is what a realm shell does.
	_reconcile()


func _exit_tree() -> void:
	_bodies.clear()


## Whether THIS process is the host of a real, live session.
##
## This is the lane's one real defect and it is worth the paragraph. It used to
## read `multiplayer.is_server()`, guarded only by `multiplayer_peer != null`.
## In Godot 4 that guard can never fail: a process with no session at all still
## has an `OfflineMultiplayerPeer` installed by default, and under it
## `is_server()` returns **true** and `get_unique_id()` returns **1** — the
## host's own id. So every process, host and client alike, believed it was the
## host with peer id 1 while the world was still booting, and each one spawned
## itself a phantom `Trainer_1` through the spawner before any session existed.
##
## Three things then went wrong at once, all of them loud only much later.
## The client's phantom occupied the name `Trainer_1`, so when the real host's
## body arrived the engine refused it with
## `Condition "parent->has_node(name)" is true` and the host simply never
## existed on the client. The phantom was tracked by the spawner while an
## offline peer was installed, so the moment `join()` swapped in the ENet peer
## the engine walked its tracked spawns and hit
## `Condition "!_has_authority(spawner)" is true` — a client is not the
## spawner's authority. And every delta the host sent for its body was refused
## as `non-authority or invalid synchronizer`, because the node those deltas
## belonged to had never been created.
##
## The fix is to ask the SESSION, which knows the difference between "no
## session" and "host", instead of asking the multiplayer API, which does not.
## `Session.is_host()` alone is not enough either — it is deliberately true
## when there is no session at all, because that is the honest answer for the
## D100 autosave sites. Both questions together mean exactly `_mode == "host"`.
func _is_host() -> bool:
	if not is_inside_tree() or _session == null:
		return false
	if not _session.has_method("is_active") or not _session.has_method("is_host"):
		return false
	return bool(_session.call("is_active")) and bool(_session.call("is_host"))


## Bring the spawned set in line with the registry: one body per peer,
## including the host's own, because a client has to see the host walk around
## just as much as the host has to see the client.
func _reconcile() -> void:
	if not _is_host() or _spawner == null or _session == null:
		return
	var wanted := _peer_ids()
	for peer_id in wanted:
		if not _bodies.has(peer_id):
			_spawn_for(int(peer_id))
	for held in _bodies.keys().duplicate():
		if not wanted.has(held):
			_despawn_for(int(held))


## `Session.peers()` (2.A). Read defensively: it may hand back plain ids or
## registry rows, and it may not exist yet at all.
func _peer_ids() -> Array:
	var out: Array = []
	if _session == null or not _session.has_method("peers"):
		return out
	var raw: Variant = _session.call("peers")
	if not (raw is Array):
		return out
	for entry in (raw as Array):
		if entry is Dictionary:
			var d: Dictionary = entry
			if d.has("peer_id"):
				out.append(int(d["peer_id"]))
			elif d.has("id"):
				out.append(int(d["id"]))
		elif entry is int or entry is float:
			out.append(int(entry))
	return out


## The registry's display name for a peer, read defensively (deliverable 4):
## the row may not exist yet, and there is no registry at all in solo.
func _display_name_for(peer_id: int) -> String:
	if _session == null:
		return ""
	for method in [&"display_name_for", &"display_name", &"name_for"]:
		if _session.has_method(method):
			var value: Variant = _session.call(method, peer_id)
			if value is String and not (value as String).is_empty():
				return value
	if _session.has_method("peers"):
		var raw: Variant = _session.call("peers")
		if raw is Array:
			for entry in (raw as Array):
				if entry is Dictionary:
					var d: Dictionary = entry
					if int(d.get("peer_id", d.get("id", 0))) == peer_id:
						return str(d.get("display_name", d.get("name", "")))
	return ""


func _character_id_for(peer_id: int) -> String:
	if _session != null and _session.has_method("character_id_for"):
		return str(_session.call("character_id_for", peer_id))
	if _session != null and _session.has_method("peers"):
		var raw: Variant = _session.call("peers")
		if raw is Array:
			for entry in (raw as Array):
				if entry is Dictionary:
					var d: Dictionary = entry
					if int(d.get("peer_id", d.get("id", 0))) == peer_id:
						return str(d.get("character_id", ""))
	return ""


func _spawn_for(peer_id: int) -> void:
	if _spawner == null or _bodies.has(peer_id):
		return
	var at := _spawn_position()
	var data := {
		"peer_id": peer_id,
		"character_id": _character_id_for(peer_id),
		"display_name": _display_name_for(peer_id),
		"at": [at.x, at.y, at.z],
	}
	print("[trainers] spawning a body for peer %d at (%.1f, %.1f)" % [peer_id, at.x, at.z])
	var node: Node = _spawner.spawn(data)
	if node != null:
		_bodies[peer_id] = node


func _despawn_for(peer_id: int) -> void:
	var node: Variant = _bodies.get(peer_id)
	_bodies.erase(peer_id)
	if node is Node and is_instance_valid(node):
		# Freeing on the host is what the spawner replicates as a despawn.
		(node as Node).queue_free()


## THE ONE PLACE authority is set. Runs on every peer, identically, before the
## node is added to the tree -- see the header's rule 1.
func _spawn_trainer(data: Variant) -> Node:
	var d: Dictionary = data if data is Dictionary else {}
	var node := REMOTE_TRAINER.instantiate()
	var peer_id := int(d.get("peer_id", 0))
	node.name = "Trainer_%d" % peer_id
	node.set("peer_id", peer_id)
	node.set("character_id", str(d.get("character_id", "")))
	node.set("display_name", str(d.get("display_name", "")))
	var at: Variant = d.get("at", [])
	if at is Array and (at as Array).size() == 3:
		var a: Array = at
		(node as Node3D).position = Vector3(float(a[0]), float(a[1]), float(a[2]))
		node.set("net_position", (node as Node3D).position)
	if peer_id != 0:
		# Recursive by default, which is what is wanted: the child
		# `MultiplayerSynchronizer` has to carry the same authority or its
		# deltas are refused at the far end. Logged with the real ids because
		# they are large random numbers and a swapped pair is otherwise
		# indistinguishable from a working one.
		node.set_multiplayer_authority(peer_id)
	print("[trainers] built %s for peer %d, authority %d (this peer is %d)"
		% [node.name, peer_id, node.get_multiplayer_authority(), multiplayer.get_unique_id()])
	return node


func _spawn_position() -> Vector3:
	var world := get_node_or_null(world_path)
	if world == null:
		world = get_parent()
	if world != null and world.has_method("local_rig"):
		var rig := world.call("local_rig") as Node3D
		if rig != null and is_instance_valid(rig):
			return rig.global_position
	if world is Node3D:
		return (world as Node3D).global_position
	return Vector3.ZERO


## `_reconcile()`, not `_spawn_for(peer_id)`. The host's OWN body has to be
## spawned too, and the join is the first moment at which it can be: before it
## there is no live peer under the spawner, and a body spawned without one is
## the phantom `_is_host()` above exists to prevent. Reconciling here covers
## both in one idempotent pass.
func _on_peer_joined(peer_id: int, _character_id: Variant = null) -> void:
	if not _is_host():
		return
	_reconcile()


func _on_peer_left(peer_id: int, _reason: Variant = null) -> void:
	if not _is_host():
		return
	_despawn_for(int(peer_id))


## The mirror of the boot-time defect. When the session ends, the multiplayer
## peer goes back to the offline default; any body still tracked by the spawner
## would then be a spawn held under a peer that is not the one it was made
## under — the same shape that produced `!_has_authority(spawner)` on join.
## Drop them all, on host and client alike.
func _on_session_ended(_reason: Variant = null) -> void:
	_bodies.clear()
	if _spawner == null:
		return
	var root := _spawner.get_node_or_null(_spawner.spawn_path)
	if root == null:
		return
	for child in root.get_children():
		child.queue_free()


## Test/inspection door: the remote bodies standing in this world right now.
func remote_trainers() -> Array:
	var out: Array = []
	if not is_inside_tree():
		return out
	for node in get_tree().get_nodes_in_group(&"remote_trainer"):
		if is_instance_valid(node):
			out.append(node)
	return out
