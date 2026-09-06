extends SceneTree

## MP net harness coordinator. Stage B Wave 0 lane 0.F.
## docs/specs/MP_NET_HARNESS_CONTRACT.md §2-§8.
##
## Not run directly. A `tests/smoke_net_*.gd` coordinator EXTENDS this file by
## path, the way `scripts/ui/tab_map.gd` extends `scripts/ui/menu_tab.gd`:
##
##   extends "res://tests/helpers/net_harness.gd"
##   # peers: 2
##   func _initialize() -> void:
##       _run()   # fire-and-forget coroutine, same pattern as every SceneTree
##                # harness in this repo (see tools/net/_spike_enet.gd)
##
##   func _run() -> void:
##       if not await launch(2, "world"):
##           quit(await finish())
##           return
##       check(await probe(0, "input_context") == "world", "peer 0 booted into the world")
##       ...
##       quit(await finish())
##
## ## What this owns (contract §2)
##
## Launching one `tools/net/peer_runner.gd` process per peer, each with its
## own `XDG_DATA_HOME`, ENet port and control port (isolation is
## non-negotiable -- the `tools/flake_rate.sh` rule: one machine, many runs, no
## shared `user://`); serving the TCP control channel peers connect OUT to
## (the coordinator is the `TCPServer`); sequencing `step`/`probe` and reading
## `hello`/`verdict`/`value`/`heartbeat`/`log`; running the desync detector
## (§7); and writing `NET_RUN.json`/`SUMMARY.md` into the run directory.
##
## Peers are launched directly with `OS.create_process` from here (contract
## §2's first option), following spike item 6
## (`ralph/reports/MP-0C-SPIKE-ENET-0905/REPORT.md`): both `OS.set_environment`
## before `create_process` and ambient inheritance were proven to work. Each
## child is wrapped in `/bin/sh -c '... > peer-N.log 2>&1'` so its stdout/
## stderr lands in the run directory without a second polling process --
## `OS.create_process` itself has no redirection argument.
##
## ## Wire format
##
## Newline-delimited JSON, one object per line, both directions. Every object
## carries a `"type"` field naming which row of contract §3's tables it is
## (`hello`, `step`, `verdict`, `probe`, `value`, `heartbeat`, `log`, `quit`).

const PEER_RUNNER := preload("res://tools/net/peer_runner.gd")

const DEFAULT_STEP_BUDGET_FRAMES := 3000
## Contract §8 as amended (`f090076c`): hello and the step phase are budgeted
## SEPARATELY -- a cold Meadows boot is ~85 s per peer (spike S2,
## `ralph/reports/MP-0D-SPIKE-HOSTCOST-0905/`), both booting concurrently on
## one runner, so 180 s covers hello with real margin; the smoke's own STEPS
## get their own 300 s clock starting only once hello is done, so a slow boot
## cannot eat into the budget a smoke's assertions actually need.
const DEFAULT_HELLO_BUDGET_S := 180.0
const DEFAULT_SMOKE_STEP_BUDGET_S_2PEER := 300.0
const DEFAULT_SMOKE_STEP_BUDGET_S_WIDE := 1500.0
const DEFAULT_HEARTBEAT_FRAMES := 60
const DEFAULT_DESYNC_FRAMES := 240
const DEFAULT_NEAR_REST_M := 1.5
const DEFAULT_NEAR_MOTION_M := 4.0
const CONTROL_BASE_PORT := 27901
const ENET_BASE_PORT := 27801
## Contract §3: "A peer whose heartbeat stops for 15s wall clock is
## `ERROR: peer silent`".
const HEARTBEAT_SILENT_TIMEOUT_S := 15.0
## Contract §6's own budgets are frame-denominated per PEER; the coordinator
## itself only ever waits in wall-clock (it does not tick the peer's physics),
## so every frame budget below is converted at this nominal rate plus a fixed
## slack, matching §3's own "budget_frames (plus 5s of wall clock)" rule.
const NOMINAL_MS_PER_PHYSICS_FRAME := 1000.0 / 60.0
const WALL_SLACK_MS := 5000.0

## The live tolerance, which a smoke may raise BEFORE `launch()`. Fifteen
## seconds is right for a peer that is only ever asked to walk and press
## things: silence that long means it died or hung.
##
## It is wrong for a peer that changes scene AFTER hello.
## `tests/smoke_net_join_by_address.gd`'s joiner reaches the world the way a
## player does -- from the title screen, once the host's snapshot lands -- and
## building the Meadows is ONE blocking frame that spike S2
## (`ralph/reports/MP-0D-SPIKE-HOSTCOST-0905/`) measured at ~85 s. That peer is
## working, not hung, and the detector cannot tell the difference from outside;
## the smoke that knows it is about to happen says so. Every smoke that does
## not touch this keeps §3's number exactly.
##
## `_init_budgets()` deliberately does not reset this: it runs inside
## `launch()`, which is after the only useful moment to set it.
var heartbeat_silence_tolerance_s := HEARTBEAT_SILENT_TIMEOUT_S

var failures: Array[String] = []
var _peers: Array = []
var _run_dir := ""
var _run_id := ""
var _scene_for_run := ""
var _peer_count_for_run := 0
var _budgets := {}
var _next_step_id := 0
## Set once, the first time the run becomes unrecoverable (a peer died
## unexpectedly, went heartbeat-silent, sent an ERROR verdict, produced no
## state hash, or the smoke's own step-phase budget ran out). Every wait loop
## below checks it and bails rather than spinning out its own budget once the
## run is already dead.
var _fatal_reason := ""
## Wall-clock deadline for every STEP the smoke issues after `launch()`'s own
## hello wait succeeds (contract §8 amended, item 9's "enforce the per-smoke
## step wall clock"). 0 until `launch()` sets it.
var _step_phase_deadline_ms := 0.0


func _init_budgets() -> void:
	_budgets = {
		"step_budget_frames": DEFAULT_STEP_BUDGET_FRAMES,
		"hello_budget_s": DEFAULT_HELLO_BUDGET_S,
		"smoke_step_budget_s_2peer": DEFAULT_SMOKE_STEP_BUDGET_S_2PEER,
		"smoke_step_budget_s_wide": DEFAULT_SMOKE_STEP_BUDGET_S_WIDE,
		"heartbeat_frames": DEFAULT_HEARTBEAT_FRAMES,
		"desync_frames": DEFAULT_DESYNC_FRAMES,
		"near_tolerance_rest_m": DEFAULT_NEAR_REST_M,
		"near_tolerance_motion_m": DEFAULT_NEAR_MOTION_M,
	}
	var cfg_path := "res://data/config/multiplayer.json"
	if not FileAccess.file_exists(cfg_path):
		return
	var f := FileAccess.open(cfg_path, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY and (parsed as Dictionary).has("test_budgets"):
		var tb: Dictionary = (parsed as Dictionary)["test_budgets"]
		for k in tb.keys():
			# `_comment*` keys are this repo's own JSON-doesn't-support-comments
			# convention (see data/config/spawn_tables.json) -- not a budget.
			if str(k).begins_with("_comment"):
				continue
			_budgets[k] = tb[k]


# =====================================================================
# launch()
# =====================================================================

## Starts `peer_count` `tools/net/peer_runner.gd` processes (peer 0 = host,
## every other index = client), each with `--scene=<scene>`, waits for every
## one of them to connect and say `hello`. Returns false (with `failures`
## appended) on any launch problem; a caller that gets false should call
## `finish()` and quit rather than try to drive a peer that never came up.
## `per_peer_args` (lane 2.B) adds tokens to ONE peer's argv, keyed by index,
## on top of `extra_args`, which every peer gets. It exists because a
## command-line flag is fixed at process start: a joiner that reaches the
## session through `--mp-join <host>:<port>` (the path a player and
## `tools/owner/`'s launcher take) has to carry the HOST's port in the argv it
## boots with, which is long before any `hello` could report it -- see
## `enet_port_for()`. Empty by default, so every smoke written before it is
## byte-for-byte unchanged.
func launch(peer_count: int, scene: String, extra_args: Array = [],
		per_peer_args: Dictionary = {}) -> bool:
	_init_budgets()
	_scene_for_run = scene
	_peer_count_for_run = peer_count

	_run_id = run_id()

	_run_dir = _resolve_run_dir()
	DirAccess.make_dir_recursive_absolute(_run_dir)

	# Item 13 (review): derive the port bases from the run id itself, so two
	# runs on one box do not collide by default -- a human who wants exact
	# ports still can via TB_NET_CONTROL_BASE/TB_NET_ENET_BASE, which win over
	# the derived offset (contract §8: "both overridable by argument").
	var offset := _port_offset_from_run_id(_run_id)
	var control_base := _env_int("TB_NET_CONTROL_BASE", CONTROL_BASE_PORT + offset)
	var enet_base := _env_int("TB_NET_ENET_BASE", ENET_BASE_PORT + offset)

	_peers.clear()
	for i in peer_count:
		var control_port := control_base + i
		var server := TCPServer.new()
		if server.listen(control_port) != OK:
			var why := "coordinator: could not listen on control port %d for peer %d" % [control_port, i]
			failures.append(why)
			_fatal_reason = why # item 1: a launch-time harness fault is exit 2, not 1
			return false
		var home := _run_dir.path_join("home-%d" % i)
		DirAccess.make_dir_recursive_absolute(home)
		var role := "host" if i == 0 else "client"
		var log_path := _run_dir.path_join("peer-%d.log" % i)
		var args_for_peer: Array = extra_args.duplicate()
		var mine: Variant = per_peer_args.get(i, [])
		if mine is Array:
			args_for_peer.append_array(mine as Array)
		var pid := _spawn_peer(i, role, control_port, enet_base + i, scene, home, log_path, args_for_peer)
		if pid <= 0:
			var why2 := "coordinator: OS.create_process failed for peer %d" % i
			failures.append(why2)
			_fatal_reason = why2
			return false
		print("coordinator: launched peer %d (%s) pid=%d control_port=%d home=%s log=%s" %
			[i, role, pid, control_port, home, log_path])
		_peers.append({
			"index": i, "role": role, "server": server, "sock": null, "rx_buf": "",
			"pid": pid, "home": home, "log_path": log_path, "control_port": control_port,
			"hashes": [], "hello": null, "exited": false, "unexpected_exit": false,
			"quit_sent": false, "last_heartbeat_t": 0.0, "last_heartbeat": null,
			"last_verdict": null, "last_value": null,
		})

	var hello_budget_s: float = float(_budgets.get("hello_budget_s", DEFAULT_HELLO_BUDGET_S))
	var deadline := Time.get_ticks_msec() + hello_budget_s * 1000.0
	while true:
		await process_frame
		_pump_once()
		if not _fatal_reason.is_empty():
			if not failures.has(_fatal_reason):
				failures.append(_fatal_reason)
			return false
		var all_hello := true
		for p in _peers:
			if (p as Dictionary).get("hello") == null:
				all_hello = false
				break
		if all_hello:
			print("coordinator: all %d peer(s) said hello" % peer_count)
			var step_budget_s: float = float(_budgets.get(
				"smoke_step_budget_s_2peer" if peer_count <= 2 else "smoke_step_budget_s_wide",
				DEFAULT_SMOKE_STEP_BUDGET_S_2PEER if peer_count <= 2 else DEFAULT_SMOKE_STEP_BUDGET_S_WIDE))
			_step_phase_deadline_ms = Time.get_ticks_msec() + step_budget_s * 1000.0
			return true
		if Time.get_ticks_msec() > deadline:
			var why3 := "ERROR: not every peer said hello within %.0f s" % hello_budget_s
			failures.append(why3)
			_fatal_reason = why3 # item 1: hello timeout is a harness fault, exit 2
			return false
	return false # unreachable; satisfies static return-path analysis on `while true`


## This run's id, resolved once. `launch()` reads it through here so a smoke
## may ask BEFORE launching -- `enet_port_for()` needs it, and a smoke that
## computed its own would get a different answer every call for a run with no
## TB_NET_RUN_ID in the environment.
func run_id() -> String:
	if _run_id.is_empty():
		_run_id = OS.get_environment("TB_NET_RUN_ID")
		if _run_id.is_empty():
			_run_id = "local-%d" % Time.get_ticks_usec()
	return _run_id


## The ENet port `launch()` WILL hand peer `index`. The same derivation
## `launch()` itself uses, called from one place rather than restated, because
## a second formula here is a smoke that puts a port nothing is listening on
## into a joiner's command line and then reports a join failure that is really
## an arithmetic failure.
func enet_port_for(index: int) -> int:
	return _env_int("TB_NET_ENET_BASE", ENET_BASE_PORT + _port_offset_from_run_id(run_id())) + index


## Item 13 (review): a small, deterministic, bounded offset from the run id so
## concurrent runs land in different port ranges without a human passing
## --port by hand. Stride 20 leaves room for up to 4 peers per run before the
## next run's range begins; modulo 400 keeps the whole span (base..base+8000)
## comfortably inside the ephemeral port range.
func _port_offset_from_run_id(run_id: String) -> int:
	return (absi(hash(run_id)) % 400) * 20


func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var exe := OS.get_executable_path()
	var project_path := ProjectSettings.globalize_path("res://")
	var args := [
		"--headless", "--path", project_path,
		"--script", "res://tools/net/peer_runner.gd", "--",
		"--role=%s" % role, "--peer=%d" % i,
		"--control-port=%d" % control_port, "--enet-port=%d" % enet_port,
		"--scene=%s" % scene,
		# A literal argv token, not only an env var: `run_net_smoke.sh`'s
		# orphan sweep uses `pgrep -f "TB_NET_RUN_ID=<id>"`, and `pgrep -f`
		# matches a process's COMMAND LINE, not its environment.
		"TB_NET_RUN_ID=%s" % _run_id,
	]
	for extra in extra_args:
		args.append(str(extra))
	# Spike item 6: OS.set_environment() before OS.create_process() reaches the
	# child. Isolation per peer (contract §2): its own XDG_DATA_HOME.
	OS.set_environment("XDG_DATA_HOME", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	# `data/config/spawn_tables.json`'s `roll_new_worlds` ships true (owner
	# directive D-0830-1), so a fresh New Game rolls itself a random
	# `world_seed` unless pinned -- exactly the reason
	# `tools/gate_f/operator_harness.gd::_pin_world_seed()` exists. Two
	# independently-booted peers with no Session to negotiate a shared seed
	# yet (contract §1) would otherwise disagree on their very first
	# heartbeat for a reason that has nothing to do with the harness: measured
	# live before this line existed (490178442 vs 736055304, one `world_seed`
	# key, nothing else). Every peer in a run is pinned to the SAME value --
	# the authored world, seed 0, matching Gate F's own default -- so the
	# desync detector is proving what contract §1 says Wave 0 can prove
	# ("two Meadows worlds ... prove the instrument"), not failing on a
	# divergence Wave 2's Session is what will actually fix.
	OS.set_environment("TB_WORLD_SEED", OS.get_environment("TB_NET_WORLD_SEED") if not OS.get_environment("TB_NET_WORLD_SEED").is_empty() else "0")
	var parts: Array[String] = [_shq(exe)]
	for a in args:
		parts.append(_shq(str(a)))
	# `exec` replaces the /bin/sh process image with godot IN PLACE (same
	# pid), rather than forking godot as sh's child and waiting on it. Without
	# it, the pid OS.create_process() returns is the SHELL's, and
	# OS.kill()/OS.is_process_running() on it would only ever touch the shell
	# -- leaving the real godot process an orphan, reparented to init, exactly
	# the leak this run's own zombie guard (`tools/net/run_net_smoke.sh`'s
	# `pgrep -f "TB_NET_RUN_ID=..."` sweep) would otherwise have to paper
	# over silently. With `exec`, the coordinator's own pid bookkeeping is
	# correct on its own.
	var shell_cmd := "exec %s >%s 2>&1" % [" ".join(parts), _shq(log_path)]
	return OS.create_process("/bin/sh", ["-c", shell_cmd])


func _shq(s: String) -> String:
	return "'" + s.replace("'", "'\\''") + "'"


func _env_int(name: String, default: int) -> int:
	var v := OS.get_environment(name)
	return int(v) if not v.is_empty() else default


func _resolve_run_dir() -> String:
	var out := OS.get_environment("TB_NET_OUT_DIR")
	if not out.is_empty():
		return out
	# Item 13 (review): the fallback default (no run_net_smoke.sh, which
	# always sets TB_NET_OUT_DIR itself) folds `_run_id` in too -- two bare
	# invocations in the same wall-clock second used to collide on the
	# timestamp alone; `_run_id` is already unique per invocation (env or the
	# microsecond fallback above it).
	var safe_id := _run_id.replace("/", "_").replace(":", "_").replace(" ", "_")
	return "/tmp/net-run-%s" % safe_id


# =====================================================================
# control-channel pump -- runs opportunistically every time anything below
# awaits a frame, servicing every peer's socket (accept, read, dispatch).
# =====================================================================

## Item 9 (review): the smoke's own step-phase wall clock (contract §8
## amended), enforced in ONE place -- `_pump_once()` runs inside every wait
## loop in this file (`step`, `probe`, `race`, `assert_all_hashes_equal`,
## `expect_desync_free`), so checking it here covers all of them without a
## duplicate deadline check in each.
func _check_step_budget() -> void:
	if _step_phase_deadline_ms <= 0.0 or not _fatal_reason.is_empty():
		return
	if Time.get_ticks_msec() > _step_phase_deadline_ms:
		_fatal_reason = "ERROR: smoke budget exceeded"
		print("coordinator: %s" % _fatal_reason)


func _pump_once() -> void:
	_check_step_budget()
	for entry in _peers:
		var p: Dictionary = entry
		if bool(p.get("exited", false)):
			continue
		var server: TCPServer = p.get("server")
		if server != null and p.get("sock") == null and server.is_connection_available():
			p["sock"] = server.take_connection()
		var sock: StreamPeerTCP = p.get("sock")
		if sock != null:
			sock.poll()
			if sock.get_status() == StreamPeerTCP.STATUS_CONNECTED:
				var n := sock.get_available_bytes()
				if n > 0:
					var res: Array = sock.get_data(n)
					if int(res[0]) == OK:
						p["rx_buf"] = str(p.get("rx_buf", "")) + (res[1] as PackedByteArray).get_string_from_utf8()
				while true:
					var buf: String = str(p.get("rx_buf", ""))
					var idx := buf.find("\n")
					if idx < 0:
						break
					var line := buf.substr(0, idx)
					p["rx_buf"] = buf.substr(idx + 1)
					_handle_peer_line(p, line)
		_check_liveness(p)


func _handle_peer_line(p: Dictionary, line: String) -> void:
	var msg = JSON.parse_string(line)
	if typeof(msg) != TYPE_DICTIONARY:
		return
	var kind := str((msg as Dictionary).get("type", ""))
	match kind:
		"hello":
			p["hello"] = msg
			# Item 10 (review): the reference point a silence check needs
			# BEFORE the first heartbeat has ever arrived -- `last_heartbeat_t`
			# stays 0.0 until then, and a peer that said hello and then never
			# heartbeats at all must still trip the 15 s guard.
			p["hello_at"] = Time.get_ticks_msec() / 1000.0
			print("coordinator: peer %d hello: %s" % [int(p["index"]), JSON.stringify(msg)])
		"verdict":
			p["last_verdict"] = msg
			# Item 1 (review): an ERROR verdict from a peer is a harness fault
			# per contract §4 ("stops the run"), not a check the caller can
			# choose to treat as a mere FAIL -- so this sets `_fatal_reason`
			# itself, independent of whatever `step()`'s own caller does with
			# the returned Dictionary.
			if str((msg as Dictionary).get("verdict", "")) == "ERROR":
				var why := "ERROR: peer %d reported ERROR: %s" % [int(p["index"]), str((msg as Dictionary).get("detail", ""))]
				print("coordinator: %s" % why)
				if _fatal_reason.is_empty():
					_fatal_reason = why
		"value":
			p["last_value"] = msg
		"heartbeat":
			p["last_heartbeat_t"] = Time.get_ticks_msec() / 1000.0
			p["last_heartbeat"] = msg
			# Item 2 (review): `null` means the peer could not produce a hash
			# at all (peer_runner.gd::_compute_state_hash's own contract) --
			# never coerce that into the legal hash value 0. A missing key
			# (an old peer build, or a malformed message) is treated the same
			# way: absence is not zero either.
			if not (msg as Dictionary).has("state_hash") or (msg as Dictionary)["state_hash"] == null:
				var why2 := "ERROR: state hash unavailable (peer %d)" % int(p["index"])
				print("coordinator: %s" % why2)
				if _fatal_reason.is_empty():
					_fatal_reason = why2
			else:
				var hashes: Array = p.get("hashes", [])
				hashes.append(int((msg as Dictionary)["state_hash"]))
				while hashes.size() > 3:
					hashes.pop_front()
				p["hashes"] = hashes
		"log":
			print("peer[%d] log[%s]: %s" % [int(p["index"]), str((msg as Dictionary).get("level", "")),
				str((msg as Dictionary).get("text", ""))])
		_:
			print("coordinator: peer %d sent unknown message type '%s'" % [int(p["index"]), kind])


func _check_liveness(p: Dictionary) -> void:
	var pid := int(p.get("pid", -1))
	if pid > 0 and not bool(p.get("exited", false)) and not OS.is_process_running(pid):
		p["exited"] = true
		if not bool(p.get("quit_sent", false)):
			p["unexpected_exit"] = true
			# Contract §3's own wording is `ERROR: peer exited <code>`. This
			# harness cannot recover a real exit code for a child launched
			# via `OS.create_process` and reaped only by polling
			# `OS.is_process_running` (no waitpid-style status here) -- see
			# the lane report's limitations section. The peer index stands in
			# for the code; "peer exited" is kept verbatim so a caller
			# matching on that substring (this repo's own negative control,
			# `tests/smoke_net_peer_death.gd`) still finds it.
			var reason := "ERROR: peer exited (peer %d, pid %d)" % [int(p["index"]), pid]
			print("coordinator: %s" % reason)
			if _fatal_reason.is_empty():
				_fatal_reason = reason
	if bool(p.get("hello") != null) and not bool(p.get("exited", false)):
		var last: float = float(p.get("last_heartbeat_t", 0.0))
		# Item 10 (review): `last > 0.0` alone means a peer that said hello and
		# then NEVER heartbeated at all (last_heartbeat_t stays its 0.0
		# default forever) can never trip this guard -- it would just sit
		# silently until whatever OUTER budget eventually times the run out,
		# reporting the wrong reason. Fall back to `hello_at` as the reference
		# point when no heartbeat has ever arrived.
		var reference: float = last if last > 0.0 else float(p.get("hello_at", 0.0))
		if reference > 0.0 and (Time.get_ticks_msec() / 1000.0 - reference) > heartbeat_silence_tolerance_s:
			var reason2 := "ERROR: peer silent (peer %d, no heartbeat for >%.0f s)" % [int(p["index"]), heartbeat_silence_tolerance_s]
			if _fatal_reason.is_empty():
				_fatal_reason = reason2
				print("coordinator: %s" % reason2)


func _send_to(p: Dictionary, msg: Dictionary) -> void:
	var sock: StreamPeerTCP = p.get("sock")
	if sock == null:
		return
	sock.poll()
	if sock.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return
	sock.put_data((JSON.stringify(msg) + "\n").to_utf8_buffer())


# =====================================================================
# Coordinator API (contract §6)
# =====================================================================

## One step, on one peer; awaits its `verdict`. `budget` in physics frames
## (contract §4 default 3000) -- converted to the wall-clock bound the
## coordinator itself can actually wait on (contract §3: "budget_frames plus
## 5s of wall clock").
func step(peer: int, action: String, args := {}, budget: int = -1) -> Dictionary:
	if budget < 0:
		budget = int(_budgets.get("step_budget_frames", DEFAULT_STEP_BUDGET_FRAMES))
	var p: Dictionary = _peers[peer]
	var id := "s%d" % _next_step_id
	_next_step_id += 1
	p["last_verdict"] = null
	_send_to(p, {"type": "step", "id": id, "action": action, "args": args, "budget_frames": budget})
	var deadline := Time.get_ticks_msec() + float(budget) * NOMINAL_MS_PER_PHYSICS_FRAME + WALL_SLACK_MS
	while true:
		await process_frame
		_pump_once()
		var v = p.get("last_verdict")
		if v != null and str((v as Dictionary).get("id", "")) == id:
			return v
		if not _fatal_reason.is_empty():
			return {"id": id, "verdict": "ERROR", "detail": _fatal_reason, "frames_used": 0}
		if bool(p.get("exited", false)):
			return {"id": id, "verdict": "ERROR", "detail": "peer %d exited before a verdict for '%s'"
				% [peer, action], "frames_used": 0}
		if Time.get_ticks_msec() > deadline:
			return {"id": id, "verdict": "FAIL", "detail": "no verdict", "frames_used": 0}
	return {} # unreachable; satisfies static return-path analysis on `while true`


## Runs `list` (each `{action, args, budget_frames}`) sequentially on `peer`.
func steps(peer: int, list: Array) -> Array:
	var out: Array = []
	for item in list:
		var d: Dictionary = item
		var budget := int(d["budget_frames"]) if d.has("budget_frames") else -1
		out.append(await step(peer, str(d.get("action", "")), d.get("args", {}), budget))
	return out


## `list` of `{peer, action, args, budget_frames}` issued in ONE coordinator
## frame -- contract §6's honest limit: proves "no duplication regardless of
## order", not true simultaneity (that needs the pure ledger/arbiter unit
## tests named in the contract). Returns `[{peer, verdict}, ...]` once every
## entry has a verdict or the shared deadline passes.
func race(list: Array) -> Array:
	# Item 11 (review): `p["last_verdict"]` is ONE slot per peer, not a queue
	# keyed by step id -- two entries addressing the SAME peer in one race can
	# have the second verdict overwrite the first before this function ever
	# observes it, silently losing a verdict rather than mismatching one.
	# Rejected as a harness ERROR until verdicts are tracked per id (contract
	# §6's own carry-over, not this lane's to fix here).
	var seen_peers := {}
	for item0 in list:
		var peer_idx0 := int((item0 as Dictionary).get("peer"))
		if seen_peers.has(peer_idx0):
			var why := "ERROR: race() cannot address peer %d twice in one call until verdicts are keyed by id" % peer_idx0
			print("coordinator: %s" % why)
			if _fatal_reason.is_empty():
				_fatal_reason = why
			var err_out: Array = []
			for item1 in list:
				err_out.append({"peer": (item1 as Dictionary).get("peer"),
					"verdict": {"verdict": "ERROR", "detail": why}})
			return err_out
		seen_peers[peer_idx0] = true

	var ids: Array = []
	var default_budget := int(_budgets.get("step_budget_frames", DEFAULT_STEP_BUDGET_FRAMES))
	var max_budget := default_budget
	for item in list:
		var d: Dictionary = item
		var peer_idx := int(d.get("peer"))
		var p: Dictionary = _peers[peer_idx]
		var id := "r%d" % _next_step_id
		_next_step_id += 1
		var budget := int(d.get("budget_frames", default_budget))
		max_budget = maxi(max_budget, budget)
		p["last_verdict"] = null
		_send_to(p, {"type": "step", "id": id, "action": str(d.get("action", "")),
			"args": d.get("args", {}), "budget_frames": budget})
		ids.append({"peer": peer_idx, "id": id})
	var out: Array = []
	var seen := {}
	var deadline := Time.get_ticks_msec() + float(max_budget) * NOMINAL_MS_PER_PHYSICS_FRAME + WALL_SLACK_MS
	while out.size() < ids.size():
		await process_frame
		_pump_once()
		for entry in ids:
			var key: String = str(entry["id"])
			if seen.has(key):
				continue
			var p2: Dictionary = _peers[int(entry["peer"])]
			var v = p2.get("last_verdict")
			if v != null and str((v as Dictionary).get("id", "")) == key:
				seen[key] = true
				out.append({"peer": entry["peer"], "verdict": v})
		if not _fatal_reason.is_empty() or Time.get_ticks_msec() > deadline:
			for entry in ids:
				var key2: String = str(entry["id"])
				if not seen.has(key2):
					seen[key2] = true
					out.append({"peer": entry["peer"],
						"verdict": {"verdict": "ERROR", "detail": _fatal_reason if not _fatal_reason.is_empty() else "no verdict"}})
			break
	return out


## Reads `what` off `peer` (contract §5) and returns its `value`.
func probe(peer: int, what: String, args := {}) -> Variant:
	var p: Dictionary = _peers[peer]
	var id := "p%d" % _next_step_id
	_next_step_id += 1
	p["last_value"] = null
	_send_to(p, {"type": "probe", "id": id, "what": what, "args": args})
	var deadline := Time.get_ticks_msec() + 20000.0
	while true:
		await process_frame
		_pump_once()
		var v = p.get("last_value")
		if v != null and str((v as Dictionary).get("id", "")) == id:
			return (v as Dictionary).get("value")
		if not _fatal_reason.is_empty() or bool(p.get("exited", false)):
			return null
		if Time.get_ticks_msec() > deadline:
			return null
	return null # unreachable; satisfies static return-path analysis on `while true`


## Contract §7: true once a hash appears in every peer's last-three-heartbeat
## window within `budget_frames` (converted to wall clock as `step()` does).
func assert_all_hashes_equal(budget_frames: int = 300) -> bool:
	var deadline := Time.get_ticks_msec() + float(budget_frames) * NOMINAL_MS_PER_PHYSICS_FRAME + WALL_SLACK_MS
	while Time.get_ticks_msec() < deadline:
		await process_frame
		_pump_once()
		if not _fatal_reason.is_empty():
			failures.append("state hash check aborted: %s" % _fatal_reason)
			return false
		if _hashes_agree():
			return true
	failures.append("state hashes never agreed across peers within %d frames" % budget_frames)
	_dump_desync()
	return false


func _hashes_agree() -> bool:
	if _peers.is_empty():
		return false
	var windows: Array = []
	for entry in _peers:
		var p: Dictionary = entry
		var h: Array = p.get("hashes", [])
		if h.is_empty():
			return false
		windows.append(h)
	var first: Array = windows[0]
	for h in first:
		var common := true
		for w in windows:
			if not (w as Array).has(h):
				common = false
				break
		if common:
			return true
	return false


## Contract §7: watches for `seconds` of real play; a divergence sustained for
## `desync_frames` (config, default 240) fails. Returns true if no such
## sustained divergence occurred.
func expect_desync_free(seconds: float) -> bool:
	var frames := int(round(seconds * 60.0))
	var divergent_frames := 0
	var desync_ceiling := int(_budgets.get("desync_frames", DEFAULT_DESYNC_FRAMES))
	for i in frames:
		await process_frame
		_pump_once()
		if not _fatal_reason.is_empty():
			failures.append("desync watch aborted: %s" % _fatal_reason)
			return false
		if _hashes_agree():
			divergent_frames = 0
		else:
			divergent_frames += 1
			if divergent_frames >= desync_ceiling:
				failures.append("desync: no common state_hash across peers for %d consecutive frames" % divergent_frames)
				_dump_desync()
				return false
	return true


## Contract §7: on a confirmed divergence, dump each peer's own state so the
## diff is in the evidence. Wave 0's `peer_runner.gd` does not yet implement
## the `save_dict` probe (only `position`/`input_context`/`state_hash`/
## `session` -- item 1's minimum), so this records the hash windows that
## proved the divergence instead of a full dictionary diff; noted as a
## limitation in the lane report.
func _dump_desync() -> void:
	var doc := {"run_id": _run_id, "peers": []}
	for entry in _peers:
		var p: Dictionary = entry
		(doc["peers"] as Array).append({"index": p.get("index"), "hashes": p.get("hashes", []),
			"last_heartbeat": p.get("last_heartbeat")})
	var f := FileAccess.open(_run_dir.path_join("desync.json"), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(doc, "\t"))
		f.close()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
	print(("PASS: " if condition else "FAIL: ") + message)


## Sends `quit` to every still-connected peer, waits (briefly) for clean exit,
## kills stragglers, writes NET_RUN.json/SUMMARY.md, and returns the exit code
## (contract §6): 2 if the run died on a harness fault (a peer exited
## unexpectedly, or went silent), 1 if any `check`/assert failed, else 0.
func finish() -> int:
	for entry in _peers:
		var p: Dictionary = entry
		if not bool(p.get("exited", false)):
			p["quit_sent"] = true
			_send_to(p, {"type": "quit", "code": 0})
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		_pump_once()
		var all_exited := true
		for entry2 in _peers:
			if not bool((entry2 as Dictionary).get("exited", false)):
				all_exited = false
				break
		if all_exited:
			break
	for entry3 in _peers:
		var p3: Dictionary = entry3
		var pid := int(p3.get("pid", -1))
		if pid > 0 and OS.is_process_running(pid):
			OS.kill(pid)

	_write_run_json()
	_write_summary()

	if not _fatal_reason.is_empty():
		if not failures.has(_fatal_reason):
			failures.append(_fatal_reason)
		print("FAIL: %s" % _fatal_reason)
		return 2
	if not failures.is_empty():
		for f in failures:
			print("FAIL: %s" % f)
		return 1
	print("ALL CHECKS PASSED")
	return 0


func _write_run_json() -> void:
	var peers_out := []
	for entry in _peers:
		var p: Dictionary = entry
		peers_out.append({
			"index": p.get("index"), "role": p.get("role"), "pid": p.get("pid"),
			"control_port": p.get("control_port"), "hello": p.get("hello"),
			"exited": p.get("exited"), "unexpected_exit": p.get("unexpected_exit"),
			"last_heartbeat": p.get("last_heartbeat"), "hashes": p.get("hashes", []),
		})
	var doc := {
		"run_id": _run_id, "scene": _scene_for_run, "peers": peers_out,
		"failures": failures, "fatal": _fatal_reason,
		# Contract §7 as amended (`f090076c`): one key, the allowlist actually
		# hashed. `EXCLUDED_KEYS` is printed alongside it as the record of
		# what was deliberately left out, not a second mechanism.
		"state_hash_hashed_keys": PEER_RUNNER.HASHED_KEYS,
		"state_hash_excluded_keys": PEER_RUNNER.EXCLUDED_KEYS,
		"budgets": _budgets,
	}
	var f := FileAccess.open(_run_dir.path_join("NET_RUN.json"), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(doc, "\t"))
		f.close()


func _write_summary() -> void:
	var lines := ["# Net smoke run %s" % _run_id, "", "Scene: %s" % _scene_for_run,
		"Peers: %d" % _peers.size(), ""]
	for entry in _peers:
		var p: Dictionary = entry
		lines.append("- peer %d (%s) pid=%s exited=%s unexpected_exit=%s" % [
			p.get("index"), p.get("role"), str(p.get("pid")), str(p.get("exited")),
			str(p.get("unexpected_exit"))])
	lines.append("")
	if not _fatal_reason.is_empty():
		lines.append("FATAL: %s" % _fatal_reason)
	elif failures.is_empty():
		lines.append("ALL CHECKS PASSED")
	else:
		lines.append("FAILURES:")
		for f2 in failures:
			lines.append("- %s" % f2)
	var f := FileAccess.open(_run_dir.path_join("SUMMARY.md"), FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines) + "\n")
		f.close()
