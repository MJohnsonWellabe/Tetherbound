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
##      {"peer": 1, "action": "load_save", "args": {"from": "path/to/slot.json"}},
##      {"peer": 0, "action": "stormheart_fixture", "args": {"contributors": ["$peer0", "$peer1"]}},
##      {"peer": "all", "action": "screenshot", "args": {"name": "offer"}},
##      {"peer": 1, "probe": "party", "expect_data": {...}},
##      {"peer": "all", "action": "capture_saves", "args": {"label": "after"}}]}
##
## Every step is an ordinary peer_runner step (or a `tools/net/proof_steps.gd`
## one) and must return PASS unless it says `"expect": "FAIL"` or `"any"`.
## `expect_data` is a subset match on the step's (or probe's) `data`. In
## strings, `$peerN` becomes peer N's session id and `$characterN` its
## character id. `PROOF.md` in the output directory lists every step, its
## verdict and detail, and every file captured. A missing scenario fails.

const WORLD_BUILD_BUDGET_FRAMES := 10000

var _proof_out := ""
var _rows: Array = []
var _ids: Dictionary = {}
var _characters: Dictionary = {}
var _host_port := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	var path := OS.get_environment("TB_PROOF_SCENARIO")
	_proof_out = OS.get_environment("TB_PROOF_OUT")
	var scenario: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) \
		if not path.is_empty() and FileAccess.file_exists(path) else null
	if not (scenario is Dictionary):
		check(false, "TB_PROOF_SCENARIO names a readable scenario JSON (got '%s')" % path)
		quit(await finish())
		return
	var s: Dictionary = scenario
	var peers := int(s.get("peers", 2))
	if not await launch(peers, str(s.get("scene", "world"))):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + float(s.get("budget_s", 1500)) * 1000.0
	var index := 0
	for raw: Variant in (s.get("steps", []) as Array):
		index += 1
		if not (raw is Dictionary):
			check(false, "step %d is an object" % index)
			continue
		var entry: Dictionary = raw
		for peer: int in _targets(entry.get("peer", 0), peers):
			if not await _run_entry(index, peer, entry):
				if not bool(entry.get("continue_on_fail", false)):
					_write_report(s, path)
					quit(await finish())
					return
	_write_report(s, path)
	quit(await finish())


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
	var args: Dictionary = await _resolve(entry.get("args", {})) as Dictionary
	var label := str(entry.get("label", ""))
	var result: Dictionary
	var what := ""
	if entry.has("probe"):
		what = "probe %s" % str(entry.probe)
		var value: Variant = await probe(peer, str(entry.probe), args)
		result = {"verdict": "PASS" if value != null else "ERROR",
			"detail": JSON.stringify(value).left(400), "data": value}
	else:
		var action := str(entry.get("action", ""))
		what = action
		if action == "join":
			await _learn_host_port()
			if not args.has("port"):
				args["host"] = "127.0.0.1"
				args["port"] = _host_port
		# A world build (a named save's realm, a boot, a crossing) takes a cold
		# world boot's time, not an ordinary step's; scenarios may still say.
		var budget := int(entry.get("budget_frames",
			WORLD_BUILD_BUDGET_FRAMES if action in ["load_save", "boot", "enter_realm", "screenshot"] else -1))
		result = await step(peer, action, args, budget)
		if action in ["host", "join"] and str(result.get("verdict", "")) == "PASS":
			_ids.clear()
	var verdict := str(result.get("verdict", ""))
	var want := str(entry.get("expect", "PASS"))
	var ok := want == "any" or verdict == want
	var data_ok := true
	if entry.has("expect_data"):
		var expected: Dictionary = await _resolve(entry.get("expect_data", {})) as Dictionary
		data_ok = _subset(expected, result.get("data", {}))
	var message := "#%d peer %d %s%s -> %s%s" % [index, peer, what,
		"" if label.is_empty() else " (%s)" % label, verdict,
		"" if data_ok else "; data did not match %s" % JSON.stringify(entry.get("expect_data"))]
	check(ok and data_ok, message + " -- " + str(result.get("detail", "")).left(300))
	_rows.append({"index": index, "peer": peer, "what": what, "label": label, "verdict": verdict,
		"ok": ok and data_ok, "detail": str(result.get("detail", "")),
		"data": result.get("data", null)})
	return ok and data_ok


func _learn_host_port() -> void:
	if _host_port > 0:
		return
	var sess: Variant = await probe(0, "session")
	_host_port = int((sess as Dictionary).get("enet_port", 0)) if sess is Dictionary else 0


## `$peerN` -> peer N's session id, `$characterN` -> its character id, inside
## any string of `value` (a whole-string match becomes the bare value).
func _resolve(value: Variant) -> Variant:
	if value is Dictionary:
		var out := {}
		for key: Variant in (value as Dictionary).keys():
			out[key] = await _resolve((value as Dictionary)[key])
		return out
	if value is Array:
		var out: Array = []
		for v: Variant in (value as Array):
			out.append(await _resolve(v))
		return out
	if value is String and (value as String).contains("$"):
		var text := value as String
		var tokens := RegEx.create_from_string("\\$(peer|character)(\\d+)")
		var whole := tokens.search(text)
		if whole != null and whole.get_start() == 0 and whole.get_end() == text.length():
			return await _token(whole.get_string(1), int(whole.get_string(2)))
		for m: RegExMatch in tokens.search_all(text):
			text = text.replace(m.get_string(), str(await _token(m.get_string(1), int(m.get_string(2)))))
		return text
	return value


func _token(kind: String, i: int) -> Variant:
	await _learn_identity(i)
	return _ids.get(i, 0) if kind == "peer" else _characters.get(i, "")


func _learn_identity(i: int) -> void:
	if _ids.has(i):
		return
	var sess: Variant = await probe(i, "session")
	var d: Dictionary = sess if sess is Dictionary else {}
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


func _write_report(scenario: Dictionary, path: String) -> void:
	if _proof_out.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(_proof_out)
	var lines: Array[String] = [
		"# Two-peer proof: %s" % str(scenario.get("name", path.get_file())),
		"",
		"Scenario: `%s`  " % path,
		"Run: `%s`  " % OS.get_environment("TB_NET_RUN_ID"),
		"Rendered: %s" % ("yes" if OS.get_environment("TB_NET_RENDER") == "1" else "no (headless)"),
		"",
		str(scenario.get("claim", "")),
		"",
		"| # | Peer | Step | Verdict | Detail |",
		"|---|---|---|---|---|",
	]
	for row: Dictionary in _rows:
		lines.append("| %d | %d | %s%s | %s%s | %s |" % [row.index, row.peer, row.what,
			"" if str(row.label).is_empty() else " — %s" % row.label, row.verdict,
			"" if row.ok else " **(unexpected)**", str(row.detail).replace("|", "/").replace("\n", " ").left(240)])
	lines.append("")
	lines.append("## Captured files")
	lines.append("")
	for file: String in _files_under(_proof_out):
		if not file.ends_with("PROOF.md"):
			lines.append("- `%s`" % file.trim_prefix(_proof_out + "/"))
	var out := FileAccess.open(_proof_out.path_join("PROOF.md"), FileAccess.WRITE)
	if out != null:
		out.store_string("\n".join(lines) + "\n")
		out.close()


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
