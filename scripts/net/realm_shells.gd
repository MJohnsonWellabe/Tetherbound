extends Node

## Stage B Wave 6 lane 6.A. THE REALM SHELLS.
##
## Mounted by `session.gd::_mount_realms()` as `/root/Game/Session/Realms`.
## D97's contract: the host runs one **realm shell** per occupied realm it is
## not itself standing in -- the realm's own world scene, instanced in
## simulation-only mode, so the host stays authoritative over a realm nobody
## on this process can see.
##
## ## Why the shell is NOT a child of this node, and D97 says it is
##
## D97 wrote "the world scene instanced under `Session/Realms/<realm>`". That
## is the one line of the decision this lane could not implement, and the
## reason is Godot's, not a preference:
##
## **Godot's high-level multiplayer addresses a `MultiplayerSpawner` and a
## `MultiplayerSynchronizer` by NODE PATH.** A spawn packet carries the
## spawner's path; the receiving peer resolves that exact path or drops the
## spawn. A client standing in Cloudreach holds its world at
## `/root/CloudreachCliffs` -- `change_scene_to_file()` puts the scene root
## directly under the tree root. A host shell parented here would sit at
## `/root/Game/Session/Realms/cloudreach/CloudreachCliffs`, and every trainer,
## creature and dropped item the host spawned into it would be addressed to a
## path the occupant does not have. Nothing would arrive, and nothing would
## say so.
##
## So a shell is added to the TREE ROOT under the scene's own authored root
## name, which is precisely the path the peer standing in that realm has. The
## names cannot collide: a shell exists only for a realm the host is NOT in,
## and each realm's world scene has a distinct root name
## (`MeadowsPlayground`, `CloudreachCliffs`).
##
## This node still owns them -- it stands them up, tracks them, moves their
## simulation focus and tears them down -- which is what "under
## `Session/Realms`" was actually for. Recorded as a finding in
## `ralph/reports/MP-6A-REALMS-0906/REPORT.md` rather than quietly diverged.
##
## ## The case that sank the first design
##
## D97's first draft delegated an unhosted realm to its first occupant, and
## review killed it because that client's disconnect mid-fight loses encounter
## state nothing else holds. Here the host holds it, so the same disconnect is
## survivable -- but only if the LAST occupant leaving a realm does not take
## the shell's world state with it. `_tear_down()` therefore runs the host's
## own world save (all four scene-facing sync seams plus the file write)
## BEFORE the shell leaves the tree, while its build placers, satchels and
## vegetation are still in the groups `game_state.gd` walks.
##
## ## Authority is asked of the SESSION, every time
##
## Never `multiplayer.is_server()`: with no session at all Godot installs an
## `OfflineMultiplayerPeer` under which `is_server()` is **true** and
## `get_unique_id()` is **1**. And never cached at `_ready()` -- this node is
## built with the session, long before anybody hosts or joins, so every answer
## it holds would be the offline one. `trainer_spawn.gd::_is_host()` carries
## the full account of what that cost the first time.

## How often the shells' simulation focus is re-pointed at their occupants.
## Terrain3D's dynamic collision follows the camera it was handed (spike S2
## item 5), so a shell whose camera never moves has ground only around the
## authored spawn -- a creature the host simulates for a peer two kilometres
## up the corridor would fall through the world. Half a second matches
## `playground_world.gd::COLLISION_STREAM_INTERVAL`.
const FOCUS_INTERVAL_S := 0.5

## realm id -> the world node standing for it (a child of the tree root).
var _shells: Dictionary = {}
## realm id -> the scene path `ResourceLoader.load_threaded_request()` was
## asked for and has not yet been collected. See `_stand_up()`.
var _loading: Dictionary = {}
## realm id -> {"attach_ms", "static_delta_kb", "started_ms", "build_ms"},
## kept for the lane's own measurement against spike S2 and for `report()`.
## `attach_ms` is the walk to the world's first yield; `build_ms` is the whole
## sliced build and is -1 until the shell says it has finished.
var _cost: Dictionary = {}
var _focus_accum: float = 0.0


func _ready() -> void:
	name = "Realms"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _exit_tree() -> void:
	# Free without the save: a session ending has already written the world
	# through `session.gd::leave()`, and a process shutting down must not
	# start a file write from `_exit_tree`.
	for realm: String in _shells.keys():
		var node: Variant = _shells[realm]
		if node is Node and is_instance_valid(node):
			(node as Node).queue_free()
	_shells.clear()
	_loading.clear()


# --- public API ---------------------------------------------------------------

## Bring the standing shells in line with where everybody is. Idempotent, and
## the only entry point: `session.gd` calls it on join, on leave, on a realm
## change and on a disconnect, and it works out the difference itself.
func reconcile() -> void:
	if not _is_host():
		release_all()
		return
	var wanted := _wanted_realms()
	for realm: String in wanted.keys():
		if not _shells.has(realm):
			_stand_up(realm)
	for realm: String in _shells.keys().duplicate():
		if not wanted.has(realm):
			_tear_down(realm)
	# A realm whose last occupant left again while its scene was still being
	# read off disk. Drop the request rather than standing a shell up for
	# nobody and immediately tearing it down through a world save.
	for realm: String in _loading.keys().duplicate():
		if not wanted.has(realm):
			_loading.erase(realm)


## Tear every shell down, saving each first. Called when this process stops
## being a host of a live session.
func release_all() -> void:
	for realm: String in _shells.keys().duplicate():
		_tear_down(realm)
	_loading.clear()


## The realms this process is currently simulating for somebody else.
func hosted_realms() -> Array:
	var out: Array = _shells.keys()
	out.sort()
	return out


func has_shell(realm: String) -> bool:
	return _shells.has(realm)


func shell(realm: String) -> Node:
	var node: Variant = _shells.get(realm)
	return node if node is Node and is_instance_valid(node) else null


## What this lane measures itself with, and what the net smokes probe.
func report() -> Dictionary:
	var rows: Dictionary = {}
	for realm: String in _shells.keys():
		var node: Node = shell(realm)
		var row: Dictionary = (_cost.get(realm, {}) as Dictionary).duplicate()
		row["alive"] = node != null
		row["path"] = str(node.get_path()) if node != null else ""
		row["bodies"] = _bodies_in(realm).size()
		# D97 / lane MP-REALM-REOPEN. A shell is in the tree long before it has
		# finished building itself -- the build is deliberately spread over
		# frames so the host keeps drawing for the players already in the
		# session. Anything that needs the realm to be able to answer for its
		# own ground waits on this, not on `alive`.
		row["ready"] = node != null and (not node.has_method("shell_build_complete")
			or bool(node.call("shell_build_complete")))
		rows[realm] = row
	var pending: Array = _loading.keys()
	pending.sort()
	return {
		"realms": rows,
		"loading": pending,
		"static_memory_kb": int(OS.get_static_memory_usage() / 1024),
		"hosting": _is_host(),
	}


# --- the difference -----------------------------------------------------------

## Every realm somebody is standing in that is not the one this process is
## standing in. Read from the REGISTRY's per-peer realm (D97: every authority
## question carries an explicit realm), never from `Game.current_realm` for
## anybody but the local player.
func _wanted_realms() -> Dictionary:
	var out: Dictionary = {}
	var session := _session()
	var game := _game()
	if session == null or game == null:
		return out
	var here := str(game.get("current_realm"))
	var raw: Variant = session.call("peers")
	if not (raw is Array):
		return out
	for entry: Variant in (raw as Array):
		if not (entry is Dictionary):
			continue
		var realm := str((entry as Dictionary).get("realm", ""))
		if realm.is_empty() or realm == here:
			continue
		out[realm] = true
	return out


func _stand_up(realm: String) -> void:
	var game := _game()
	var tree := get_tree()
	if game == null or tree == null:
		return
	var hearts: Variant = game.get("realm_hearts")
	if hearts == null:
		push_warning("[realms] no realm_hearts; cannot stand up a shell for '%s'" % realm)
		return
	var scene := str((hearts as RefCounted).call("scene_for_realm", realm))
	if scene.is_empty() or not ResourceLoader.exists(scene):
		push_warning("[realms] realm '%s' points at missing scene '%s'" % [realm, scene])
		return
	# D97 / lane MP-REALM-REOPEN. The plain `load()` this used to be was the
	# one HARD freeze in a stand-up: measured on a 4 vCPU box at 3.5 s for the
	# Meadows and 5.6 s for Cloudreach, inside a single frame, on the host
	# every other player depends on. `load()` cannot be interrupted; a
	# threaded request can simply be asked again next tick.
	#
	# `_process()` calls `reconcile()` twice a second, and a realm still being
	# read is not in `_shells`, so this function is re-entered for the same
	# realm until the scene arrives -- which is what makes returning here
	# safe rather than a dropped shell.
	var packed: PackedScene = _collect_scene(realm, scene)
	if packed == null:
		return
	var node: Node = packed.instantiate()
	if node == null:
		return
	# The name the occupant's own `change_scene_to_file()` gives it. See the
	# header: this is the whole reason a shell is a child of the tree root.
	#
	# A collision here is normally NOT an error, it is a race with the local
	# player's own crossing: `change_scene_to_file()` is deferred to the end of
	# the frame, so a host that has just announced its move out of the Meadows
	# is still standing in `/root/MeadowsPlayground` at the moment this runs.
	# Bail quietly; `_process()` reconciles again on the next tick, by which
	# time the old scene has gone. Nothing is retried forever that should not
	# be: a realm the host is standing in is not in `_wanted_realms()` at all.
	if tree.root.has_node(NodePath(node.name)):
		node.queue_free()
		return

	# BEFORE `add_child`, because `add_child` is what runs `_ready()` and
	# `_ready()` is what reads the flag. Setting it afterwards builds the
	# whole visual world first and then apologises.
	node.set("simulation_only", true)
	node.set("shell_realm", realm)

	var t0 := Time.get_ticks_msec()
	var mem0 := OS.get_static_memory_usage()
	tree.root.add_child(node)
	# `add_child` runs the world root's `_ready()`, and in a shell that
	# `_ready()` yields (`scripts/world/shell_build_budget.gd`), so this is
	# the cost of reaching the world's FIRST yield -- not of building it.
	# `build_ms` below is the whole build, filled in when the world says it
	# has finished.
	var attach_ms := Time.get_ticks_msec() - t0
	var static_kb := int((OS.get_static_memory_usage() - mem0) / 1024)
	_shells[realm] = node
	_cost[realm] = {"attach_ms": attach_ms, "static_delta_kb": static_kb,
		"started_ms": t0, "build_ms": -1}
	print("[realms] shell up for '%s' at /root/%s: attached in %d ms, +%d KB static; still building across frames"
		% [realm, node.name, attach_ms, static_kb])


## Ask for the realm's scene on a background thread, and answer with it only
## once it is actually there. Returns null while the read is still running,
## which is not a failure -- `reconcile()` asks again on the next tick.
func _collect_scene(realm: String, scene: String) -> PackedScene:
	if not _loading.has(realm):
		var started := ResourceLoader.load_threaded_request(scene)
		if started != OK:
			# A threaded request the engine declined (an unknown path, no
			# free loader thread). Fall back to the blocking read rather than
			# never standing the shell up at all: a freeze is worse than a
			# threaded load and better than a realm nobody simulates.
			push_warning("[realms] threaded load of '%s' declined (%d); reading it inline" % [scene, started])
			return load(scene) as PackedScene
		_loading[realm] = scene
		print("[realms] reading '%s' for realm '%s' off the loader thread" % [scene, realm])
		return null
	match ResourceLoader.load_threaded_get_status(scene):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return null
		ResourceLoader.THREAD_LOAD_LOADED:
			_loading.erase(realm)
			var packed := ResourceLoader.load_threaded_get(scene) as PackedScene
			if packed == null:
				push_warning("[realms] '%s' loaded but is not a PackedScene" % scene)
			return packed
		_:
			_loading.erase(realm)
			push_warning("[realms] threaded load of '%s' failed for realm '%s'" % [scene, realm])
			return null


## Deliverable 5. The last occupant of a realm has gone -- possibly by
## disconnecting mid-fight -- and this shell holds world state (buildings,
## satchels, chopped vegetation, storage contents) that lives nowhere else
## until it is written. Save FIRST, while the shell is still in the tree and
## its nodes are still in the groups `game_state.gd`'s four sync seams walk.
func _tear_down(realm: String) -> void:
	var node: Node = shell(realm)
	_shells.erase(realm)
	_cost.erase(realm)
	_loading.erase(realm)
	if node == null:
		return
	var game := _game()
	if game != null and bool(game.call("is_host")):
		# `save_game()` runs `_sync_placed_building_state`,
		# `_sync_death_satchel_state`, `_sync_harvest_state` and
		# `_sync_clock_state` before it writes, and every one of them reaches
		# the scene BY GROUP -- so the shell's own nodes are read here exactly
		# as the host's live world's are.
		var wrote := bool(game.call("save_game", int(game.call("autosave_slot"))))
		print("[realms] shell for '%s' folded back into the world (save %s)"
			% [realm, "written" if wrote else "REFUSED"])
	node.queue_free()


# --- simulation focus ---------------------------------------------------------

## Terrain3D builds dynamic collision around the camera it was handed. A shell
## has no player to follow, so it follows the peers who are actually standing
## in it -- otherwise a creature the host simulates for a client two kilometres
## away has no ground under it.
func _process(delta: float) -> void:
	if _shells.is_empty() and not _is_host():
		return
	# A scene still being read off the loader thread is polled EVERY frame,
	# not twice a second: the read finishes when it finishes, and half a
	# second of doing nothing about it is half a second the peer who crossed
	# is standing in a realm nobody is simulating.
	if not _loading.is_empty():
		reconcile()
	_note_finished_builds()
	_focus_accum += delta
	if _focus_accum < FOCUS_INTERVAL_S:
		return
	_focus_accum = 0.0
	# Reconcile on the same tick as the focus update rather than only on the
	# session's own events. It is a dictionary diff over at most four rows,
	# and it is what makes the ordering above safe: a stand-up blocked by the
	# local player's not-yet-swapped scene simply happens half a second later
	# instead of never.
	reconcile()
	for realm: String in _shells.keys():
		var node: Node = shell(realm)
		if node == null or not node.has_method("track_simulation_focus"):
			continue
		var bodies := _bodies_in(realm)
		if bodies.is_empty():
			continue
		var centre := Vector3.ZERO
		for body: Node3D in bodies:
			centre += body.global_position
		node.call("track_simulation_focus", centre / float(bodies.size()))


## Fill in `build_ms` the first tick a shell reports itself finished. This is
## the number that matters for the reopen -- how long the host spends building
## a realm nobody can see -- and it is not `attach_ms`, which is only the walk
## to the world's first yield.
func _note_finished_builds() -> void:
	for realm: String in _shells.keys():
		var row: Variant = _cost.get(realm)
		if not (row is Dictionary) or int((row as Dictionary).get("build_ms", -1)) >= 0:
			continue
		var node: Node = shell(realm)
		if node == null or not node.has_method("shell_build_complete"):
			continue
		if not bool(node.call("shell_build_complete")):
			continue
		var built := Time.get_ticks_msec() - int((row as Dictionary).get("started_ms", 0))
		(row as Dictionary)["build_ms"] = built
		print("[realms] shell for '%s' finished building in %.1f s (S2 full boot: ~85 s cold, 2,783 MB)"
			% [realm, built / 1000.0])


## The remote trainer bodies standing inside one shell. By ancestry rather
## than by realm metadata: the shell IS the realm, and a body under it is in
## it whatever anything else believes.
func _bodies_in(realm: String) -> Array:
	var out: Array = []
	var node: Node = shell(realm)
	var tree := get_tree()
	if node == null or tree == null:
		return out
	for body: Variant in tree.get_nodes_in_group(&"remote_trainer"):
		if body is Node3D and is_instance_valid(body) and node.is_ancestor_of(body as Node):
			out.append(body)
	return out


# --- internals ----------------------------------------------------------------

func _session() -> Node:
	return get_parent()


func _game() -> Node:
	var session := _session()
	return session.get_parent() if session != null else null


## Never `multiplayer.is_server()`, and never cached. See the header.
func _is_host() -> bool:
	if not is_inside_tree():
		return false
	var session := _session()
	if session == null or not session.has_method("is_active") or not session.has_method("is_host"):
		return false
	return bool(session.call("is_active")) and bool(session.call("is_host"))
