extends "res://tests/smoke_net_proof_two_peer.gd"

## F48 uses the existing process/session/save owners. A reviewed route profile
## supplies only concrete controller taps/waypoints and existing saved inputs.
## There are no grant, win, teleport, fixture, intent or receipt-injection steps.
## Missing producers/routes/cut observation are failures, never skips or PASS.
const INPUT_ACTIONS := ["press", "move_to", "stick", "wait", "f48_button"]
const TRANSACTIONS := ["craft", "release", "feast", "key", "relic", "essence_spend"]
const CUTS := ["before_input", "after_settlement", "after_host_write_before_delivery", "after_owner_write_before_ack"]
const REPLAY_FIELDS := ["inventory", "redesign_character", "satchel_escrow"]
var _profile: Dictionary = {}
var _profile_errors: Array[String] = []

func suite() -> String:
	return "loop"

func _run() -> void:
	var profile_path := OS.get_environment("TB_F48_PROFILE")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(profile_path)) \
		if FileAccess.file_exists(profile_path) else null
	if not raw is Dictionary:
		check(false, "F48 prerequisite unavailable: TB_F48_PROFILE must name a reviewed actual-input route with real v28 save directories")
		quit(await finish())
		return
	_profile = raw
	if not _profile.get("routes") is Dictionary or not _profile.get("outcomes", {}) is Dictionary:
		check(false, "Reviewed profile routes/outcomes must be objects")
		quit(await finish())
		return
	if OS.get_environment("TB_PROOF_OUT").is_empty():
		OS.set_environment("TB_PROOF_OUT", ProjectSettings.globalize_path("user://f48-proof-output"))
	var scenario := _build()
	if not _profile_errors.is_empty():
		for error: String in _profile_errors: check(false, error)
		quit(await finish())
		return
	var path := "user://f48-%s-scenario.json" % suite()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		check(false, "Could not write F48 scenario in isolated coordinator home")
		quit(await finish())
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()
	OS.set_environment("TB_PROOF_SCENARIO", ProjectSettings.globalize_path(path))
	# Output contains the profile digest: route/fixture provenance is not proof
	# of earned progression. ROOT must independently judge the saved inputs.
	print("F48 route profile SHA256: " + FileAccess.get_sha256(profile_path))
	await super._run()

func _entry(peer: Variant, action: String, args: Dictionary = {}, label: String = "") -> Dictionary:
	return {"peer": peer, "action": action, "args": args, "label": label}

func _route(name: String, peer: int) -> Array:
	var stages: Variant = _profile.get("routes", {})
	var routes: Variant = stages.get(name, []) if stages is Dictionary else []
	if not routes is Array or routes.is_empty() or routes.size() > 1000:
		_profile_errors.append("Actual producer/UI/input route unavailable: " + name)
		return []
	var out: Array = []
	for raw: Variant in routes:
		if not raw is Dictionary or not INPUT_ACTIONS.has(raw.get("action")) or not raw.get("args", {}) is Dictionary:
			_profile_errors.append("Route " + name + " accepts ordinary input only; no authored outcomes/hand-grants")
			continue
		if raw.has("expect") or raw.has("expect_data") or raw.has("continue_on_fail"):
			_profile_errors.append("Route cannot supply its own outcome or suppress failure: " + name)
			continue
		if raw.action == "f48_button" and str(raw.args.get("text", "")).is_empty():
			_profile_errors.append("Empty button target: " + name)
		for field: String in ["frames", "gap_frames", "budget_frames", "times"]:
			if raw.args.has(field):
				var value: Variant = raw.args[field]
				var maximum := 120 if field == "times" else 10000
				if not value is float and not value is int:
					_profile_errors.append("Non-numeric input bound: " + name + "/" + field)
				elif value < 0 or value > maximum or floor(float(value)) != float(value):
					_profile_errors.append("Unbounded input: " + name + "/" + field)
		var row := _entry(peer, raw.action, raw.args, name + ": ordinary input")
		row.budget_frames = 10000 if raw.action == "move_to" else 3000
		out.append(row)
	return out

func _build() -> Dictionary:
	var peers := 4 if suite() == "boss_four" else 2
	var steps: Array = []
	var saves: Variant = _profile.get("saves", [])
	if not saves is Array or saves.size() != peers:
		_profile_errors.append("F48 requires exactly %d independently captured v28 save directories" % peers)
		return {}
	if str(_profile.get("provenance", "")).is_empty(): _profile_errors.append("Disclose saved-input origin and any mechanics setup in profile.provenance")
	for peer: int in peers:
		if not saves[peer] is String or not DirAccess.dir_exists_absolute(saves[peer]):
			_profile_errors.append("Missing actual saved input for peer %d" % peer)
		steps.append(_entry(peer, "load_save", {"from": saves[peer]}, "DISCLOSED saved-input setup; not earned full-loop acceptance"))
	steps.append(_entry(0, "host"))
	for peer: int in range(1, peers): steps.append(_entry(peer, "production_join", {"returning_route": true}))
	steps.append(_entry("all", "expect_peers", {"count": peers}))
	steps.append(_entry("all", "f48_witness", {"remember": "admitted"}))
	match suite():
		"loop": _loop(steps)
		"boss_four": _boss(steps, peers)
		"behind": _behind(steps)
		"transactions": _transactions(steps)
		_: _profile_errors.append("Unknown F48 suite")
	return {"name": "F48 " + suite(), "claim": "Named mechanics proof only; no earned campaign PASS. " + str(_profile.get("provenance", "")),
		"peers": peers, "scene": "title", "budget_s": 3600, "build_allowance_s": 300, "steps": steps}

func _prerequisites(steps: Array) -> void:
	steps.append(_entry("all", "f48_require", {"flags": [
		{"file": "res://data/config/stations.json", "path": "runtime_enabled"},
		{"file": "res://data/config/stations.json", "path": "craft_runtime_enabled"}],
		"nodes": [{"path": "Game/Session", "methods": ["homestead_breakthrough_service"]}]},
		"Refuse disabled stations or missing actual Foundation Master/Kitchen composition; never bind stand-ins"))

func _loop(steps: Array) -> void:
	_prerequisites(steps)
	for stage: String in ["hub", "craft", "portal", "master", "feast_cook", "feast", "boss", "relic"]:
		if stage == "boss":
			_boss(steps, 2)
			continue
		steps.append(_entry("all", "f48_witness", {"remember": stage + "_before"}))
		for peer: int in 2:
			if stage == "portal": steps.append(_entry(peer, "f48_watch_portal"))
			steps.append_array(_route(stage + "_%d" % peer, peer))
			steps.append(_entry(peer, "wait", {"frames": 180}))
			if stage in ["craft", "feast_cook", "feast", "relic"]:
				steps.append(_entry(peer, "f48_assert", _outcome(stage, stage + "_before", peer)))
			elif stage == "master":
				steps.append(_entry(peer, "f48_assert", {"contains": {"redesign_character/master_wins": "master_t1", "redesign_character/feast_recipes": "feast_t1"}}))
			elif stage == "portal": steps.append(_entry(peer, "f48_assert", {"portal_enter": true}))
			if stage in ["craft", "master", "feast_cook", "feast", "relic"]:
				steps.append(_entry(peer, "f48_witness", {"remember": stage + "_done"}))
				steps.append(_entry(1 - peer, "f48_assert", {"since": stage + ("_before" if peer == 0 else "_done"), "unchanged": REPLAY_FIELDS}, "Bystander keeps their own receipts and inventory"))
		steps.append(_entry("all", "f48_witness", {"remember": stage + "_after"}))
	steps.append(_entry(0, "f48_assert", {"participants": ["$character0", "$character1"]}))
	steps.append(_entry(1, "f48_assert", {"guest_world_empty": true}))

func _outcome(transaction: String, since: String, peer: int = 1) -> Dictionary:
	var fixed := {"since": since}
	match transaction:
		"craft":
			fixed.item_delta = {"rootstone": -2, "ironwood": -1, "rootiron_ingot": 1}
			fixed.append_count = {"redesign_character/transaction_receipts": 1}
		"key":
			fixed.item_delta = {"tidewake_portal_key": -1}
			fixed.contains = {"redesign_character/portal_unlocks": "tidewake"}
			fixed.append_count = {"redesign_character/transaction_receipts": 1}
		"relic":
			fixed.contains = {"redesign_character/relics_hung": "meadows"}
			fixed.contains_all = {"redesign_character/attachment_recipes": ["forge_tidewake", "kitchen_tidewake", "altar_tidewake", "den_tidewake"]}
			fixed.append_count = {"redesign_character/transaction_receipts": 1}
		"feast":
			fixed.item_delta = {"feast_t1_ground": -1}
			fixed.append_count = {"redesign_character/transaction_receipts": 1}
		"feast_cook":
			fixed.item_delta = {"berries": -4, "rootstone": -2, "attuned_ground": -1, "feast_t1_ground": 1}
			fixed.append_count = {"redesign_character/transaction_receipts": 1}
		"release":
			fixed.append_count = {"redesign_character/release_receipts": 1}
		"essence_spend": fixed.append_count = {"redesign_character/transaction_receipts": 1}
	# Species/UID-dependent outcomes must be independently fixed in the reviewed
	# profile; neither this proof nor the producer computes the other's oracle.
	if transaction in ["feast", "release", "essence_spend"]:
		var expected: Variant = _profile.get("outcomes", {}).get(transaction + "_%d" % peer, {})
		if not expected is Dictionary or expected.is_empty():
			_profile_errors.append("Independent exact UID/cap/essence outcome unavailable: " + transaction)
		else:
			if transaction == "feast":
				if not expected.get("creature") is Dictionary or not expected.creature.has_all(["uid", "level", "breakthroughs"]):
					_profile_errors.append("Independent owned UID/unchanged level/exact cleared tiers required for feast")
				else: fixed.creature = expected.creature
			if transaction == "release":
				if not expected.get("released_uid") is String or str(expected.released_uid).is_empty():
					_profile_errors.append("Independent originally owned release UID required")
				else: fixed.released_uid = expected.released_uid
			if not expected.get("item_delta") is Dictionary or expected.item_delta.is_empty():
				_profile_errors.append("Exact independently specified essence/cost delta required: " + transaction)
			for key: String in ["equals", "item_delta"]:
				if expected.has(key):
					if not expected[key] is Dictionary: _profile_errors.append("Invalid independent outcome: " + transaction)
					else:
						if not fixed.has(key): fixed[key] = {}
						fixed[key].merge(expected[key], false)
	return fixed

func _boss(steps: Array, peers: int) -> void:
	for peer: int in peers:
		steps.append(_entry(peer, "f48_assert", {"lacks": {"redesign_character/relics_held": "meadows"}, "equals": {"redesign_character/portal_unlocks": []}, "item_counts": {"tidewake_portal_key": 0}}))
		steps.append_array(_route("boss_prepare_%d" % peer, peer))
	steps.append_array(_route("boss_start", 0))
	for peer: int in range(1, peers): steps.append_array(_route("boss_join_%d" % peer, peer))
	steps.append({"peer": 0, "probe": "encounter", "expect_data": {"kind": "boss", "phase": "active"}, "label": "Actual host encounter before victory"})
	var participants: Array = []
	for peer: int in peers: participants.append("$character%d" % peer)
	steps.append(_entry(0, "f48_participants", {"characters": participants}))
	steps.append_array(_route("boss_fight", 0))
	steps.append(_entry("all", "wait", {"frames": 240}))
	steps.append(_entry("all", "f48_assert", {"boss_rewards": true}))
	steps.append(_entry(0, "f48_assert", {"participants": participants}))
	for peer: int in range(1, peers): steps.append(_entry(peer, "f48_assert", {"guest_world_empty": true}))
	steps.append(_entry("all", "f48_witness", {"remember": "boss_settled"}))
	for peer: int in range(1, peers):
		steps.append(_entry(peer, "leave"))
		steps.append(_entry(peer, "production_join", {"returning_route": true}))
		steps.append(_entry(peer, "f48_assert", {"boss_rewards": true, "since": "boss_settled", "unchanged": REPLAY_FIELDS}))

func _behind(steps: Array) -> void:
	var honest := {"lacks": {"redesign_character/portal_unlocks": "tidewake", "redesign_character/relics_held": "meadows"}, "item_counts": {"tidewake_portal_key": 0}}
	steps.append(_entry(1, "f48_assert", honest))
	steps.append_array(_route("host_unlock_tidewake", 0))
	steps.append_array(_route("host_enter_tidewake", 0))
	steps.append(_entry(1, "f48_watch_portal"))
	steps.append_array(_route("behind_enter_tidewake", 1))
	honest.since = "admitted"
	honest.equals = {"realm": "water"}
	honest.unchanged = ["redesign_character/portal_unlocks", "redesign_character/relics_held", "redesign_character/transaction_receipts"]
	honest.item_delta = {"tidewake_portal_key": 0}
	honest.guest_world_empty = true
	honest.portal_enter = true
	steps.append(_entry(1, "wait", {"frames": 180}))
	steps.append(_entry(1, "f48_assert", honest))
	steps.append(_entry(1, "leave"))
	steps.append(_entry(1, "production_join", {"returning_route": true}))
	steps.append(_entry(1, "f48_assert", honest))

func _transactions(steps: Array) -> void:
	var transaction := _argument("transaction", "")
	var cut := _argument("cut", "")
	if not TRANSACTIONS.has(transaction) or not CUTS.has(cut):
		_profile_errors.append("Choose --transaction=" + ",".join(TRANSACTIONS) + " and --cut=" + ",".join(CUTS))
		return
	if transaction in ["craft", "feast", "relic"]: _prerequisites(steps)
	steps.append_array(_route(transaction + "_prepare", 1))
	steps.append(_entry(1, "f48_witness", {"remember": "transaction_before"}))
	if cut in ["after_host_write_before_delivery", "after_owner_write_before_ack"]:
		steps.append(_entry(1, "f48_boundary_transaction", {"transaction": transaction, "phase": cut,
			"route": _route(transaction + "_commit", 1)}, "Hard guest death at the original production writer boundary"))
	if cut == "after_settlement":
		steps.append_array(_route(transaction + "_commit", 1))
		steps.append(_entry(1, "wait", {"frames": 180}))
		steps.append(_entry(1, "f48_assert", _outcome(transaction, "transaction_before")))
		steps.append(_entry(1, "f48_witness", {"remember": "settled"}))
	steps.append(_entry(1, "restart_peer", {"scene": "title"}, "F48 hard process kill; no Session.leave or autosave"))
	steps.append(_entry(0, "expect_peers", {"count": 1}))
	steps.append(_entry(1, "production_join", {"returning_route": true}))
	steps.append(_entry("all", "expect_peers", {"count": 2}))
	# A process-local before witness is gone after a real kill. Copy its DETACHED
	# evidence into the fresh process metadata, never into the production state.
	steps.append(_entry(1, "f48_restore_witness", {"remember": "transaction_before"}))
	steps.append(_entry(1, "f48_restore_witness", {"remember": "admitted"}))
	steps.append_array(_route(transaction + "_retry", 1))
	steps.append(_entry(1, "wait", {"frames": 180}))
	steps.append(_entry(1, "f48_assert", _outcome(transaction, "transaction_before")))
	steps.append(_entry(1, "f48_witness", {"remember": "retry_settled"}))
	steps.append_array(_route(transaction + "_retry", 1))
	steps.append(_entry(1, "wait", {"frames": 120}))
	steps.append(_entry(1, "f48_assert", {"since": "retry_settled", "unchanged": REPLAY_FIELDS, "guest_world_empty": true}))

func _argument(key: String, fallback: String) -> String:
	for value: String in OS.get_cmdline_user_args():
		if value.begins_with("--" + key + "="): return value.trim_prefix("--" + key + "=")
	return fallback

func _restart_peer(i: int, scene: String) -> Dictionary:
	# Existing restart sends quit first. F48 must also test a real process crash.
	# OS.kill is Godot's native Windows/POSIX API; no Unix kill command on Windows.
	if i <= 0 or i >= _peers.size(): return {"verdict": "FAIL", "detail": "F48 crashes only an admitted guest"}
	var old: Dictionary = _peers[i]
	var pid := int(old.get("pid", -1))
	old.quit_sent = true
	if pid <= 0 or (OS.is_process_running(pid) and OS.kill(pid) != OK): return {"verdict": "FAIL", "detail": "Could not kill actual guest process"}
	var deadline := Time.get_ticks_msec() + 10000
	while OS.is_process_running(pid) and Time.get_ticks_msec() < deadline: await process_frame
	if OS.is_process_running(pid): return {"verdict": "FAIL", "detail": "Guest process did not die within 10 seconds"}
	var result: Dictionary = await super._restart_peer(i, scene)
	if result.get("verdict") == "PASS": result.detail = "HARD CRASH (no graceful save): " + str(result.detail)
	return result

func _run_entry(index: int, peer: int, entry: Dictionary) -> bool:
	if entry.get("action") != "f48_boundary_transaction": return await super._run_entry(index, peer, entry)
	var args: Dictionary = entry.args
	var pid := int(_peers[peer].get("pid", -1))
	var character := str(_characters.get(peer, ""))
	var token := "%s_%s_%d" % [args.transaction, args.phase, pid]
	var path := _proof_out.path_join("f48-boundaries").path_join(token + ".json")
	var observer_peer := 0 if args.phase == "after_host_write_before_delivery" else peer
	var armed: Dictionary = await step(observer_peer, "f48_arm_boundary", {"transaction": args.transaction,
		"phase": args.phase, "guest_pid": pid, "character_id": character, "token": token})
	if armed.get("verdict") != "PASS":
		check(false, "F48 boundary arm failed: " + str(armed.get("detail")))
		return false
	# Suppress only the expected process exit while this boundary is armed.
	# The marker and exact pid/identity below are mandatory; unrelated death fails.
	_peers[peer].quit_sent = true
	var input_failed := false
	for route: Dictionary in args.route:
		var unresolved: Array = []
		var input: Dictionary = await _resolve(route.args, unresolved)
		if not unresolved.is_empty(): input_failed = true; break
		var result: Dictionary = await step(peer, route.action, input, int(route.get("budget_frames", 3000)))
		if FileAccess.file_exists(path): break
		if result.get("verdict") != "PASS": input_failed = true; break
	var deadline := Time.get_ticks_msec() + 10000
	var evidence: Variant = null
	while not input_failed and Time.get_ticks_msec() < deadline:
		evidence = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		if evidence is Dictionary and evidence.get("kill_failed", false) == true: break
		if not OS.is_process_running(pid) and evidence is Dictionary \
			and (args.phase != "after_host_write_before_delivery" or evidence.get("guest_exit_observed") == true): break
		await process_frame
		_pump_once()
	var ok := not input_failed and not OS.is_process_running(pid) and evidence is Dictionary \
		and evidence.get("guest_pid") == pid and evidence.get("token") == token and evidence.get("phase") == args.phase \
		and evidence.get("kill_failed", false) != true \
		and (args.phase != "after_host_write_before_delivery" or evidence.get("guest_exit_observed") == true) \
		and evidence.get("transaction") == args.transaction and evidence.get("observation", {}).get("character_id") == character \
		and not str(evidence.get("observation", {}).get("delivery_id", "")).is_empty() \
		and not str(evidence.get("observation", {}).get("receipt", "")).is_empty()
	check(ok, "F48 original production boundary and hard guest process death: " + token)
	_rows.append({"index": index, "peer": peer, "what": "f48_boundary_transaction", "label": entry.get("label", ""),
		"verdict": "PASS" if ok else "FAIL", "ok": ok, "expect": "PASS", "expect_data": {}, "detail": path})
	if not ok and OS.is_process_running(pid): _peers[peer].quit_sent = false
	return ok
