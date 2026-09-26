extends "res://tests/helpers/net_harness.gd"

# peers: scenario (not in the CI net shard; run through the command below)

## The reusable two-peer PROOF runner. Real host and guest processes, a
## scenario of scripted steps, and each peer's saved world plus screenshots.
##
##   tools/net/run_two_peer_proof.sh <scenario.json> [--render] [--out=DIR]
##
## The scenario is JSON (worked example: `tools/net/proof_scenarios/f11_stormheart_accept_refuse.json`):
##
##   {"name": "...", "peers": 2, "scene": "world", "budget_s": 1500,
##    "steps": [
##      {"peer": 0, "action": "host"},
##      {"peer": 1, "action": "join"},                  # host/port filled in
##      {"peer": "all", "action": "expect_peers", "args": {"count": 2}},
##      {"peer": 1, "action": "load_save", "args": {"from": "tools/net/proof_saves/<name>"}},
##      {"peer": 0, "action": "stormheart_fixture", "args": {"contributors": ["$peer0", "$peer1"]}},
##      {"peer": "all", "action": "screenshot", "args": {"name": "offer"}},
##      {"peer": 1, "probe": "party", "expect_data": {...}},
##      {"peer": "all", "action": "capture_saves", "args": {"label": "after"}}]}
##
## Every step is an ordinary peer_runner step (or a `tools/net/proof_steps.gd`
## one) and must return PASS unless it says `"expect": "FAIL"` or `"any"`.
## `expect_data` is a subset match on the step's (or probe's) `data`. In
## strings, `$peerN` becomes peer N's session id and `$characterN` its
## character id (an unresolved token fails the step). Keys a step may carry:
## peer, action | probe, args, budget_frames, expect, expect_data, label,
## continue_on_fail, _comment; anything else fails the run rather than being
## silently ignored. Top level: name, claim, peers, scene, host_peer (default
## 0), budget_s, steps, _comment*. `PROOF.md` in the output directory has the
## overall verdict (after the harness's own end-of-run checks), every step with
## what it expected, and every file captured. A missing scenario fails.

const WORLD_BUILD_BUDGET_FRAMES := 10000
## Peers run `proof_peer_runner.gd`: the shared peer runner plus the proof steps.
const PROOF_PEER_SCRIPT := "res://tools/net/proof_peer_runner.gd"
## A world build (a named save's realm, a boot) or a rendered peer's first
## forced frame blocks for a cold world boot's time. The harness's own named
## allowance covers `enter_realm`; this runner grants the same figure to the
## proof's other world-building steps itself, so the shared harness is unchanged.
const PROOF_BUILD_ALLOWANCE_S := 150.0
## Rendered peers open a display and GL context before their first hello.
const RENDER_HELLO_BUDGET_S := 900.0
## The harness's world-build figure, for a rendered step's in-step forced draw.
const RENDERED_DRAW_ALLOWANCE_S := 150.0
const WORLD_BUILD_ACTIONS := ["load_save", "boot", "enter_realm", "screenshot", "title_continue"]
## Steps after which a peer's session id may have changed (character ids persist unless the
## peer loads a save or reboots; see _run_entry).
const IDENTITY_ACTIONS := ["host", "join", "production_join", "load_save", "boot", "leave"]
const SCENARIO_KEYS := ["name", "claim", "peers", "scene", "host_peer", "budget_s", "steps"]
const STEP_KEYS := ["peer", "action", "probe", "args", "budget_frames", "expect", "expect_data",
	"label", "continue_on_fail", "_comment"]

var _proof_out := ""
var _rows: Array = []
var _ids: Dictionary = {}
var _characters: Dictionary = {}
var _host_peer := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	var path := OS.get_environment("TB_PROOF_SCENARIO")
	_proof_out = OS.get_environment("TB_PROOF_OUT")
	var scenario: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) \
		if not path.is_empty() and FileAccess.file_exists(path) else null
	if not (scenario is Dictionary):
		check(false, "TB_PROOF_SCENARIO names a readable scenario JSON (got '%s')" % path)
		await _end({}, path)
		return
	var s: Dictionary = scenario
	var unknown_top: Array = s.keys().filter(func(k: Variant) -> bool:
		return not SCENARIO_KEYS.has(str(k)) and not str(k).begins_with("_comment"))
	if not unknown_top.is_empty():
		check(false, "the scenario has only known top-level keys (unknown: %s)" % str(unknown_top))
		await _end(s, path)
		return
	var peers := int(s.get("peers", 2))
	_host_peer = int(s.get("host_peer", 0))
	if not await launch(peers, str(s.get("scene", "world"))):
		await _end(s, path)
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + float(s.get("budget_s", 1500)) * 1000.0
	var index := 0
	for raw: Variant in (s.get("steps", []) as Array):
		index += 1
		if not (raw is Dictionary):
			check(false, "step %d is a JSON object" % index)
			break
		var entry: Dictionary = raw
		var unknown: Array = entry.keys().filter(func(k: Variant) -> bool: return not STEP_KEYS.has(str(k)))
		if not unknown.is_empty() or (entry.has("action") == entry.has("probe")):
			check(false, "step %d has exactly one of action/probe and only known keys (unknown: %s)"
				% [index, str(unknown)])
			break
		var stop := false
		for peer: int in _targets(entry.get("peer", 0), peers):
			if not await _run_entry(index, peer, entry) and not bool(entry.get("continue_on_fail", false)):
				stop = true
				break
		if stop:
			break
	await _end(s, path)


## Finish first (it runs the harness's own end-of-run checks and may add
## failures), then write PROOF.md with the overall verdict, then exit.
func _end(scenario: Dictionary, path: String) -> void:
	var code := await finish()
	_write_report(scenario, path, code)
	quit(code)


static func _render() -> bool:
	return OS.get_environment("TB_NET_PROOF_RENDER") == "1"


func _init_budgets() -> void:
	super()
	if _render():
		_budgets["hello_budget_s"] = maxf(float(_budgets.get("hello_budget_s", DEFAULT_HELLO_BUDGET_S)),
			RENDER_HELLO_BUDGET_S)


## `net_harness.gd::_spawn_peer` for the proof: the same isolation (own
## XDG_DATA_HOME/APPDATA, run id, pinned world seed, `exec` so the pid is
## Godot's), launching `PROOF_PEER_SCRIPT`. With `--render`
## (TB_NET_PROOF_RENDER=1) peers open opengl3 on the command's xvfb display
## with the render loop off -- a `screenshot` step forces its own frame -- and
## the dummy audio driver; otherwise they are headless like every smoke.
func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var exe := OS.get_executable_path()
	var project_path := ProjectSettings.globalize_path("res://")
	var args: Array = ["--headless", "--path", project_path]
	if _render():
		var resolution := OS.get_environment("TB_NET_PROOF_RESOLUTION")
		args = ["--path", project_path, "--rendering-driver", "opengl3", "--disable-render-loop",
			"--audio-driver", "Dummy", "--resolution", resolution if not resolution.is_empty() else "960x540"]
	if _is_windows():
		args.append_array(["--log-file", log_path])
	args.append_array([
		"--script", PROOF_PEER_SCRIPT, "--",
		"--role=%s" % role, "--peer=%d" % i,
		"--control-port=%d" % control_port, "--enet-port=%d" % enet_port,
		"--scene=%s" % scene,
		"TB_NET_RUN_ID=%s" % _run_id,
	])
	for extra in extra_args:
		args.append(str(extra))
	OS.set_environment("XDG_DATA_HOME", home)
	if _is_windows():
		OS.set_environment("APPDATA", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", OS.get_environment("TB_NET_WORLD_SEED") \
		if not OS.get_environment("TB_NET_WORLD_SEED").is_empty() else "0")
	if _is_windows():
		return OS.create_process(exe, args)
	var parts: Array[String] = [_shq(exe)]
	for a in args:
		parts.append(_shq(str(a)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" % [" ".join(parts), _shq(log_path)]])


func _targets(raw: Variant, peers: int) -> Array[int]:
	var out: Array[int] = []
	if str(raw) == "all":
		for i in peers:
			out.append(i)
	elif raw is Array:
		for v: Variant in raw:
			out.append(int(v))
	else:
		out.append(int(raw))
	return out


func _run_entry(index: int, peer: int, entry: Dictionary) -> bool:
	var unresolved: Array = []
	var args: Dictionary = await _resolve(entry.get("args", {}), unresolved) as Dictionary
	var expected: Dictionary = await _resolve(entry.get("expect_data", {}), unresolved) as Dictionary
	var label := str(entry.get("label", ""))
	var want := str(entry.get("expect", "PASS"))
	var result: Dictionary
	var what := ""
	if not unresolved.is_empty():
		result = {"verdict": "ERROR", "detail": "unresolved %s (no session/character for that peer yet)" % str(unresolved)}
		what = str(entry.get("action", entry.get("probe", "")))
	elif entry.has("probe"):
		what = "probe %s" % str(entry.probe)
		var value: Variant = await probe(peer, str(entry.probe), args)
		result = {"verdict": "PASS" if value != null else "ERROR",
			"detail": JSON.stringify(value), "data": value}
	else:
		var action := str(entry.get("action", ""))
		what = action
		if action in ["join", "production_join"]:
			if not args.has("host"):
				args["host"] = "127.0.0.1"
			if not args.has("port"):
				args["port"] = _host_port()
		var budget := int(entry.get("budget_frames",
			WORLD_BUILD_BUDGET_FRAMES if action in WORLD_BUILD_ACTIONS else -1))
		var p: Dictionary = _peers[peer]
		# World-building steps (a cold boot) and a rendered step that forces its
		# own frame (an in-step `screenshot`, software-GL shader compile) both
		# block for a named allowance; grant the deferral and, on PASS, the same
		# liveness credit the harness gives its own named build step.
		var draws := OS.get_environment("TB_NET_PROOF_RENDER") == "1" and args.has("screenshot")
		var builds := action in WORLD_BUILD_ACTIONS
		if builds:
			p["heartbeat_deferred_until_s"] = Time.get_ticks_msec() / 1000.0 + PROOF_BUILD_ALLOWANCE_S
		elif draws:
			p["heartbeat_deferred_until_s"] = Time.get_ticks_msec() / 1000.0 + RENDERED_DRAW_ALLOWANCE_S
		result = await step(peer, action, args, budget)
		if (builds or draws) and str(result.get("verdict", "")) == "PASS":
			p["last_heartbeat_t"] = Time.get_ticks_msec() / 1000.0
		if action in IDENTITY_ACTIONS:
			# A peer id can change (rejoin mints a new one); a character id is the
			# identity that survives, so it is kept for `$characterN` and only
			# replaced when that peer's session reports a new one -- except after
			# load_save/boot, which can put a different character on that peer.
			_ids.clear()
			if action in ["load_save", "boot"]:
				_characters.erase(peer)
	var verdict := str(result.get("verdict", ""))
	var ok := want == "any" or verdict == want
	var data_ok := expected.is_empty() or _subset(expected, result.get("data", {}))
	check(ok and data_ok, "#%d peer %d %s%s -> %s%s -- %s" % [index, peer, what,
		"" if label.is_empty() else " (%s)" % label, verdict,
		"" if data_ok else "; data did not match %s" % JSON.stringify(expected),
		str(result.get("detail", "")).left(300)])
	_rows.append({"index": index, "peer": peer, "what": what, "label": label, "verdict": verdict,
		"ok": ok and data_ok, "expect": want, "expect_data": expected,
		"detail": str(result.get("detail", ""))})
	return ok and data_ok


## The host's ENet port from its own hello (net_harness.gd::launch).
func _host_port() -> int:
	if _host_peer < 0 or _host_peer >= _peers.size():
		return 0
	var hello: Variant = (_peers[_host_peer] as Dictionary).get("hello")
	return int((hello as Dictionary).get("enet_port", 0)) if hello is Dictionary else 0


## `$peerN` -> peer N's session id, `$characterN` -> its character id, inside
## any string of `value` (a whole-string token becomes the bare value). Tokens
## that cannot be resolved are appended to `unresolved`.
func _resolve(value: Variant, unresolved: Array) -> Variant:
	if value is Dictionary:
		var out := {}
		for key: Variant in (value as Dictionary).keys():
			out[key] = await _resolve((value as Dictionary)[key], unresolved)
		return out
	if value is Array:
		var out: Array = []
		for v: Variant in (value as Array):
			out.append(await _resolve(v, unresolved))
		return out
	if value is String and (value as String).contains("$"):
		var text := value as String
		var tokens := RegEx.create_from_string("\\$(peer|character)(\\d+)")
		var matches := tokens.search_all(text)
		if matches.size() == 1 and matches[0].get_start() == 0 and matches[0].get_end() == text.length():
			return await _token(matches[0], unresolved)
		var built := ""
		var at := 0
		for m: RegExMatch in matches:
			built += text.substr(at, m.get_start() - at) + str(await _token(m, unresolved))
			at = m.get_end()
		return built + text.substr(at)
	return value


func _token(m: RegExMatch, unresolved: Array) -> Variant:
	var i := int(m.get_string(2))
	await _learn_identity(i)
	var value: Variant = _ids.get(i, 0) if m.get_string(1) == "peer" else _characters.get(i, "")
	if (value is int and int(value) <= 0) or (value is String and str(value).is_empty()):
		unresolved.append(m.get_string())
	return value


func _learn_identity(i: int) -> void:
	if _ids.has(i) or i < 0 or i >= _peers.size():
		return
	var sess: Variant = await probe(i, "session")
	var d: Dictionary = sess if sess is Dictionary else {}
	if not bool(d.get("active", false)):
		return
	_ids[i] = int(d.get("peer_id", 0))
	for row: Variant in (d.get("rows", []) as Array):
		if row is Dictionary and int((row as Dictionary).get("peer_id", 0)) == _ids[i]:
			_characters[i] = str((row as Dictionary).get("character_id", ""))


static func _subset(expected: Dictionary, actual: Variant) -> bool:
	if not (actual is Dictionary):
		return false
	for key: Variant in expected.keys():
		if not (actual as Dictionary).has(key):
			return false
		var want: Variant = expected[key]
		var got: Variant = (actual as Dictionary)[key]
		if want is Dictionary:
			if not _subset(want, got):
				return false
		elif typeof(want) in [TYPE_INT, TYPE_FLOAT] and typeof(got) in [TYPE_INT, TYPE_FLOAT]:
			if not is_equal_approx(float(want), float(got)):
				return false
		elif want != got:
			return false
	return true


func _write_report(scenario: Dictionary, path: String, code: int) -> void:
	if _proof_out.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(_proof_out)
	var lines: Array[String] = [
		"# Two-peer proof: %s" % str(scenario.get("name", path.get_file())),
		"",
		"**Verdict: %s** (exit %d)" % ["PASS" if code == 0 and failures.is_empty() else "FAIL", code],
		"",
		"Scenario: `%s`  " % path,
		"Run: `%s`  " % OS.get_environment("TB_NET_RUN_ID"),
		"Rendered: %s" % ("yes" if OS.get_environment("TB_NET_PROOF_RENDER") == "1" else "no (headless)"),
		"",
		str(scenario.get("claim", "")),
		"",
	]
	if not failures.is_empty():
		lines.append("## Failures")
		lines.append("")
		for f: Variant in failures:
			lines.append("- %s" % str(f).replace("\n", " "))
		lines.append("")
	lines.append_array(["| # | Peer | Step | Expected | Verdict | Detail |", "|---|---|---|---|---|---|"])
	for row: Dictionary in _rows:
		var expectation := str(row.expect)
		if not (row.expect_data as Dictionary).is_empty():
			expectation += " + %s" % JSON.stringify(row.expect_data)
		lines.append("| %d | %d | %s%s | %s | %s%s | %s |" % [row.index, row.peer, row.what,
			"" if str(row.label).is_empty() else " — %s" % row.label, _cell(expectation), row.verdict,
			"" if row.ok else " **(unexpected)**", _cell(str(row.detail))])
	lines.append("")
	lines.append("## Captured files")
	lines.append("")
	for file: String in _files_under(_proof_out):
		var rel := file.trim_prefix(_proof_out + "/")
		if rel != "PROOF.md" and not rel.begins_with("net/"):
			lines.append("- `%s`" % rel)
	var out := FileAccess.open(_proof_out.path_join("PROOF.md"), FileAccess.WRITE)
	if out != null:
		out.store_string("\n".join(lines) + "\n")
		out.close()


static func _cell(text: String) -> String:
	return text.replace("|", "/").replace("\n", " ").left(900)


static func _files_under(dir: String) -> Array[String]:
	var found: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return found
	d.list_dir_begin()
	var entry := d.get_next()
	while entry != "":
		if not entry.begins_with("."):
			if d.current_is_dir():
				found.append_array(_files_under(dir.path_join(entry)))
			else:
				found.append(dir.path_join(entry))
		entry = d.get_next()
	d.list_dir_end()
	found.sort()
	return found
