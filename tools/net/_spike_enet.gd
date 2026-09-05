extends SceneTree
## Spike S1 — prove Godot 4.7's built-in high-level multiplayer (ENet, @rpc,
## MultiplayerSpawner, MultiplayerSynchronizer) works headless in this repo,
## and find the exact working invocation. Wave 0 lane 0.C of
## docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md.
##
## Reference only — small and readable on purpose. Not the real net harness
## (that's tests/helpers/net_harness.gd, built by lane 0.F from
## docs/specs/MP_NET_HARNESS_CONTRACT.md). Run only through
## tools/net/_spike_enet.sh, or directly:
##
##   godot --headless --path . --script tools/net/_spike_enet.gd -- \
##       --role=host --port=9999 --peers=1
##   godot --headless --path . --script tools/net/_spike_enet.gd -- \
##       --role=client --port=9999
##
## Exit codes: 0 success, 1 assertion/logic failure, 2 timeout or bad args.

const FRAME_BUDGET := 600 # ~10s of idle frames; every wait is bounded, none hang forever.
const PING_ITERATIONS := 50

var _log := "spike"
var _hub # tools/net/_spike_enet_peer.gd instance


func _initialize() -> void:
	var args := _parse_args()
	var role: String = args.get("role", "")
	_log = "spike[%s]" % role

	match role:
		"host":
			_run_host(int(args.get("port", 9999)), int(args.get("peers", 1)))
		"client":
			_run_client(int(args.get("port", 9999)))
		"spawntest":
			_run_spawntest(String(args.get("outdir", "")))
		"envcheck":
			_run_envcheck(String(args.get("out", "")))
		_:
			push_error("%s: unknown or missing --role (host|client|spawntest|envcheck)" % _log)
			quit(2)


func _parse_args() -> Dictionary:
	var out := {}
	for raw in OS.get_cmdline_user_args():
		var s: String = raw
		if s.begins_with("--"):
			s = s.substr(2)
		var eq := s.find("=")
		if eq >= 0:
			out[s.substr(0, eq)] = s.substr(eq + 1)
		else:
			out[s] = true
	return out


# --- shared helpers ----------------------------------------------------------

func _make_hub() -> void:
	_hub = preload("res://tools/net/_spike_enet_peer.gd").new()
	_hub.name = "RpcHub"
	root.add_child(_hub)


func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame


## Polls `pred` once per idle frame until it returns true or `budget` frames
## pass. Returns the frame count on success, -1 on timeout.
func _await_condition(pred: Callable, budget: int = FRAME_BUDGET) -> int:
	var frames := 0
	while not pred.call():
		if frames >= budget:
			return -1
		await process_frame
		frames += 1
	return frames


func _median(values: Array) -> float:
	var s: Array = values.duplicate()
	s.sort()
	return s[s.size() / 2]


# --- host ---------------------------------------------------------------------

func _run_host(port: int, peers: int) -> void:
	print("%s: starting, port=%d expecting peers=%d" % [_log, port, peers])
	_make_hub()

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, peers)
	if err != OK:
		push_error("%s: create_server failed err=%d" % [_log, err])
		quit(2)
		return
	get_multiplayer().multiplayer_peer = peer
	print("%s: listening, my unique_id=%d" % [_log, get_multiplayer().get_unique_id()])

	var connected_ids: Array[int] = []
	get_multiplayer().peer_connected.connect(func(id: int):
		connected_ids.append(id)
		print("%s: peer_connected id=%d (have %d/%d)" % [_log, id, connected_ids.size(), peers])
	)

	var frames := await _await_condition(func(): return connected_ids.size() >= peers)
	if frames < 0:
		push_error("%s: TIMEOUT waiting for %d peer(s) to connect, got %d" % [_log, peers, connected_ids.size()])
		quit(2)
		return
	print("%s: all %d peer(s) connected after %d frames" % [_log, peers, frames])

	# Phase 2: wait for every client to finish its own ping/pong measurement
	# and announce readiness, so the spawn phase starts only once RPC is
	# proven working both directions.
	var ready_ids: Array[int] = []
	_hub.client_ready.connect(func(id: int):
		if id not in ready_ids:
			ready_ids.append(id)
	)
	frames = await _await_condition(func(): return ready_ids.size() >= peers)
	if frames < 0:
		push_error("%s: TIMEOUT waiting for %d client_ready announce(s), got %d" % [_log, peers, ready_ids.size()])
		quit(2)
		return
	print("%s: all %d client(s) announced ready after %d frames" % [_log, peers, frames])

	# Phase 3: MultiplayerSpawner + authority-before-tree-entry.
	var world := Node.new()
	world.name = "SpikeWorld"
	root.add_child(world)
	var spawned_container := Node.new()
	spawned_container.name = "Spawned"
	world.add_child(spawned_container)
	var spawner := MultiplayerSpawner.new()
	spawner.name = "Spawner"
	world.add_child(spawner) # add before wiring spawn_path/spawn_function — see note in the client half.
	spawner.spawn_path = spawned_container.get_path()
	spawner.spawn_function = Callable(_hub, "spawn_function")

	var target_authority: int = connected_ids[0] # first client to connect owns the spawned node
	var payload: Dictionary = _hub.make_spawn_payload(target_authority, 1)
	var spawned: Node3D = spawner.spawn(payload)
	print("%s: spawned locally path=%s authority=%d is_authority(host)=%s" % [
		_log, spawned.get_path(), spawned.get_multiplayer_authority(), spawned.is_multiplayer_authority()])

	if spawned.is_multiplayer_authority():
		push_error("%s: FAIL host reads is_multiplayer_authority()=true for a node it gave to peer %d" % [_log, target_authority])
	else:
		print("%s: OK host correctly reads is_multiplayer_authority()=false (authority=%d)" % [_log, target_authority])

	# Phase 4: demonstrate setting authority AFTER the node is already in the
	# tree (item 3's second question). This node is host-local only (never
	# spawned/replicated) — the point is only to observe what the engine does.
	var demo := Node3D.new()
	demo.name = "AuthorityOrderDemo"
	world.add_child(demo) # entered the tree with default authority (1)
	print("%s: pre-change authority=%d is_authority=%s" % [_log, demo.get_multiplayer_authority(), demo.is_multiplayer_authority()])
	demo.set_multiplayer_authority(target_authority, true)
	print("%s: post-change (after add_child) authority=%d is_authority=%s (no exception thrown)" % [
		_log, demo.get_multiplayer_authority(), demo.is_multiplayer_authority()])

	# Phase 5: MultiplayerSynchronizer — wait for the authority client to move
	# the spawned node's position, observed on the host's own local instance.
	var start_pos: Vector3 = spawned.position
	frames = await _await_condition(func(): return spawned.position != start_pos)
	if frames < 0:
		push_error("%s: TIMEOUT waiting for synchronized position change (still %s)" % [_log, spawned.position])
		quit(1)
		return
	print("%s: OK position replicated to host after %d frames, new position=%s" % [_log, frames, spawned.position])

	print("%s: DONE (peers=%d)" % [_log, peers])
	quit(0)


# --- client ---------------------------------------------------------------------

func _run_client(port: int) -> void:
	print("%s: starting, connecting 127.0.0.1:%d" % [_log, port])
	_make_hub()

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client("127.0.0.1", port)
	if err != OK:
		push_error("%s: create_client failed err=%d" % [_log, err])
		quit(2)
		return
	get_multiplayer().multiplayer_peer = peer

	# NOTE (spike finding): a GDScript lambda captures an outer local
	# bool/int by value at creation time; setting it inside a signal
	# callback does NOT update the outer scope's variable — only reference
	# types (Array/Dictionary/Object) share mutations back out. A Dictionary
	# used as a mutable box is the fix; two plain `var connected := false`
	# flags toggled from connect()'d lambdas silently never flipped here.
	var state := {"connected": false, "failed": false}
	get_multiplayer().connected_to_server.connect(func(): state.connected = true)
	get_multiplayer().connection_failed.connect(func(): state.failed = true)

	var frames: int = await _await_condition(func(): return state.connected or state.failed)
	if state.failed or frames < 0:
		push_error("%s: TIMEOUT/FAILED connecting to host (failed=%s frames=%d)" % [_log, state.failed, frames])
		quit(2)
		return
	var my_id := get_multiplayer().get_unique_id()
	print("%s: connected after %d frames, my unique_id=%d" % [_log, frames, my_id])

	# Build the spawn container BEFORE the ping test, so the path exists
	# whenever the host's spawn command arrives (a spawner's spawn_path must
	# already exist on every peer — it cannot be replicated implicitly).
	var world := Node.new()
	world.name = "SpikeWorld"
	root.add_child(world)
	var spawned_container := Node.new()
	spawned_container.name = "Spawned"
	world.add_child(spawned_container)
	var spawner := MultiplayerSpawner.new()
	spawner.name = "Spawner"
	# add_child() BEFORE setting spawn_path/spawn_function: doing it in the
	# other order (spike finding) throws "Can't use get_node() with absolute
	# paths from outside the active scene tree" — the spawn_path setter tries
	# to resolve the NodePath immediately, and it can't while the spawner
	# itself isn't in the tree yet. Non-fatal (spawning still worked) but
	# noisy; add-then-configure avoids it.
	world.add_child(spawner)
	spawner.spawn_path = spawned_container.get_path()
	spawner.spawn_function = Callable(_hub, "spawn_function")

	# Phase 1: ping/pong RTT, 50 iterations, sequential (send, await matching
	# pong, then send the next) so each measurement is a clean round trip.
	var rtts: Array[float] = []
	for i in range(PING_ITERATIONS):
		var start_usec := Time.get_ticks_usec()
		_hub.ping.rpc_id(1, i)
		var seq: int = await _hub.pong_received
		if seq != i:
			print("%s: WARN out-of-order pong got=%d want=%d" % [_log, seq, i])
		rtts.append((Time.get_ticks_usec() - start_usec) / 1000.0)
	rtts.sort()
	print("%s: ping rtt ms min=%.3f median=%.3f max=%.3f n=%d" % [
		_log, rtts[0], _median(rtts), rtts[-1], rtts.size()])

	_hub.announce_ready.rpc_id(1)
	print("%s: announced ready, waiting for host spawn" % _log)

	# Phase 3: wait for the host's MultiplayerSpawner to produce a child here.
	frames = await _await_condition(func(): return spawned_container.get_child_count() > 0)
	if frames < 0:
		push_error("%s: TIMEOUT waiting for spawn to appear under %s" % [_log, spawned_container.get_path()])
		quit(1)
		return
	var spawned: Node3D = spawned_container.get_child(0)
	print("%s: OK saw spawn %s after %d frames, authority=%d is_authority=%s" % [
		_log, spawned.get_path(), frames, spawned.get_multiplayer_authority(), spawned.is_multiplayer_authority()])

	if spawned.is_multiplayer_authority():
		if spawned.get_multiplayer_authority() != my_id:
			push_error("%s: FAIL is_multiplayer_authority()=true but authority id=%d != my_id=%d" % [_log, spawned.get_multiplayer_authority(), my_id])
		print("%s: I am the authority for %s — moving it" % [_log, spawned.get_path()])
		spawned.position = Vector3(3.0, 4.0, 5.0)
	else:
		print("%s: not the authority for %s (authority=%d, I am %d) — observing only" % [
			_log, spawned.get_path(), spawned.get_multiplayer_authority(), my_id])

	await _wait_frames(30) # give replication a moment before exit
	print("%s: DONE" % _log)
	quit(0)


# --- process-spawn env-inheritance test (item 6) -----------------------------

func _run_spawntest(outdir: String) -> void:
	if outdir.is_empty():
		push_error("%s: --outdir is required" % _log)
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(outdir)

	var exe := OS.get_executable_path()
	var project_path := ProjectSettings.globalize_path("res://")
	var ambient: String = OS.get_environment("XDG_DATA_HOME")
	print("%s: ambient XDG_DATA_HOME (as seen by this process) = '%s'" % [_log, ambient])

	# Test A: does a child launched via OS.create_process inherit this
	# process's environment (set externally, before Godot even started) with
	# no explicit action on our part?
	var out_a := outdir.path_join("envcheck_inherit.json")
	var pid_a := _spawn_envcheck_child(exe, project_path, out_a)
	var ok_a := await _reap(pid_a)
	var seen_a := _read_json(out_a)
	print("%s: [inherit] child pid=%d exited_ok=%s saw XDG_DATA_HOME='%s' (ambient='%s') match=%s" % [
		_log, pid_a, ok_a, seen_a.get("xdg_data_home", "<missing>"), ambient, seen_a.get("xdg_data_home", "") == ambient])

	# Test B: does OS.set_environment() called before create_process change
	# what the child sees?
	var override_value := outdir.path_join("xdg_override_from_set_environment")
	OS.set_environment("XDG_DATA_HOME", override_value)
	var set_took_locally := OS.get_environment("XDG_DATA_HOME") == override_value
	print("%s: OS.set_environment('XDG_DATA_HOME', ...) — this process now reads back '%s' (took=%s)" % [
		_log, OS.get_environment("XDG_DATA_HOME"), set_took_locally])
	var out_b := outdir.path_join("envcheck_override.json")
	var pid_b := _spawn_envcheck_child(exe, project_path, out_b)
	var ok_b := await _reap(pid_b)
	var seen_b := _read_json(out_b)
	print("%s: [override] child pid=%d exited_ok=%s saw XDG_DATA_HOME='%s' (expected='%s') match=%s" % [
		_log, pid_b, ok_b, seen_b.get("xdg_data_home", "<missing>"), override_value, seen_b.get("xdg_data_home", "") == override_value])

	quit(0)


func _spawn_envcheck_child(exe: String, project_path: String, out_path: String) -> int:
	var cmd_args := PackedStringArray([
		"--headless", "--path", project_path,
		"--script", "res://tools/net/_spike_enet.gd",
		"--", "--role=envcheck", "--out=%s" % out_path,
	])
	var pid := OS.create_process(exe, cmd_args)
	print("%s: create_process -> pid=%d args=%s" % [_log, pid, cmd_args])
	return pid


func _reap(pid: int) -> bool:
	if pid <= 0:
		return false
	var frames := await _await_condition(func(): return not OS.is_process_running(pid), 300)
	return frames >= 0


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	return parsed if parsed is Dictionary else {}


func _run_envcheck(out_path: String) -> void:
	var val: String = OS.get_environment("XDG_DATA_HOME")
	if not out_path.is_empty():
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify({"xdg_data_home": val, "pid": OS.get_process_id()}))
		f.close()
	print("%s: XDG_DATA_HOME='%s'" % [_log, val])
	quit(0)
