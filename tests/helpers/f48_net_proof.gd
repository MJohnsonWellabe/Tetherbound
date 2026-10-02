extends "res://tests/smoke_net_proof_two_peer.gd"

## F48 uses the existing process/session/save owners. A reviewed route profile
## supplies concrete controller taps/waypoints and disclosed saved inputs.
## An explicitly disclosed existing mechanics fight may top up self HP and
## place the actual owned ally; opponent HP ceiling stays zero. Every win,
## host verdict, event, journal, owner save and ACK must still be real.
## Named authored Master/Warden approach fixtures record actual actor/ally
## writes and require real floor/proximity before ordinary interaction.
## There are no grants or fabricated outcomes/intents/receipts.
## Missing producers/routes/cut observation are failures, never skips or PASS.
const INPUT_ACTIONS := ["press", "move_to", "stick", "wait", "f48_button", "f48_build_cell", "f48_choice", "f48_fixture_trainer_fight", "f48_fixture_approach", "f48_fixture_join_boss"]
const TRANSACTIONS := ["craft", "release", "feast", "key", "relic", "essence_spend"]
const CUTS := ["before_input", "after_settlement", "after_host_write_before_delivery", "after_owner_write_before_ack"]
const REPLAY_FIELDS := ["inventory", "redesign_character", "satchel_escrow"]
const DETACHED := preload("res://tools/net/f48_detached_file.gd")
var _profile: Dictionary = {}
var _profile_errors: Array[String] = []
var _boundary_pending: Dictionary = {}
var _boundary_observations: Dictionary = {}
var _saved_transactions: Dictionary = {}
var _root_profile: Dictionary = {}

func _process_guard(pid: int, identity: String = "", stop: bool = false) -> Dictionary:
	var python := OS.get_environment("TB_F48_PROCESS_PYTHON")
	if python.is_empty(): python = "python" if OS.get_name() == "Windows" else "python3"
	var arguments := PackedStringArray([ProjectSettings.globalize_path("res://tools/net/f48_process_guard.py"),
		"--pid", str(pid), "--image", OS.get_executable_path()])
	if not identity.is_empty(): arguments.append_array(["--identity", identity])
	if stop: arguments.append("--stop")
	var output: Array = []
	var code := OS.execute(python, arguments, output, true)
	var raw: Variant = JSON.parse_string("".join(output))
	if code != 0 or not raw is Dictionary or raw.get("ok") != true or raw.get("pid") != pid:
		return {"ok": false, "pid": pid, "error": "Native process witness failed", "exit_code": code, "output": output}
	return raw

func _pump_once() -> void:
	# step() pumps while its guest is awaiting a verdict. Service the host's
	# blocked synchronous boundary first, so the coordinator/host cannot deadlock.
	if not _boundary_pending.is_empty() and not _boundary_pending.get("serviced", false):
		var path: String = _boundary_pending.path
		var marker: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		if marker is Dictionary:
			_boundary_pending.serviced = true
			var matches: bool = marker.get("token") == _boundary_pending.token \
				and marker.get("guest_pid") == _boundary_pending.pid \
				and marker.get("coordinator_pid") == OS.get_process_id() \
				and marker.get("process_identity") == _boundary_pending.identity \
				and marker.get("phase") == _boundary_pending.phase \
				and marker.get("transaction") == _boundary_pending.transaction \
				and marker.get("observation", {}).get("character_id") == _boundary_pending.character \
				and marker.get("observer_pid") == _boundary_pending.observer_pid \
				and not str(marker.get("observation", {}).get("delivery_id", "")).is_empty() \
				and not str(marker.get("observation", {}).get("receipt", "")).is_empty()
			var exit_witness := _process_guard(_boundary_pending.pid, _boundary_pending.identity, true) if matches \
				else {"ok": false, "error": "Boundary marker identity mismatch; target not killed"}
			var ack := {"token": _boundary_pending.token, "guest_pid": _boundary_pending.pid,
				"coordinator_pid": OS.get_process_id(), "process_identity": _boundary_pending.identity,
				"marker_sha256": FileAccess.get_sha256(path), "exit": exit_witness}
			_boundary_pending.ack = ack
			DETACHED.publish(path + ".ack.json", ack)
			if exit_witness.get("ok") == true and exit_witness.get("exited") == true:
				_peers[_boundary_pending.peer].exited = true
				_peers[_boundary_pending.peer].f48_exit_confirmed = ack
	super._pump_once()

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
	_root_profile = raw.duplicate(true)
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
			_profile_errors.append("Route " + name + " requires actual inputs or explicitly disclosed mechanics fight; no authored outcomes/hand-grants")
			continue
		if raw.has("expect") or raw.has("expect_data") or raw.has("continue_on_fail"):
			_profile_errors.append("Route cannot supply its own outcome or suppress failure: " + name)
			continue
		if raw.action == "f48_button" and str(raw.args.get("text", "")).is_empty():
			_profile_errors.append("Empty button target: " + name)
		if raw.action == "f48_build_cell" and str(raw.args.get("id", "")).is_empty():
			_profile_errors.append("Empty actual build cell target: " + name)
		if raw.action == "f48_choice" and str(raw.args.get("uid", "")).is_empty():
			_profile_errors.append("Empty original owned choice UID: " + name)
		for field: String in ["frames", "gap_frames", "budget_frames", "times"]:
			if raw.args.has(field):
				var value: Variant = raw.args[field]
				var maximum := 120 if field == "times" else 10000
				if not value is float and not value is int:
					_profile_errors.append("Non-numeric input bound: " + name + "/" + field)
				elif value < 0 or value > maximum or floor(float(value)) != float(value):
					_profile_errors.append("Unbounded input: " + name + "/" + field)
		var row := _entry(peer, raw.action, raw.args, name + (": disclosed mechanics fixture" if str(raw.action).begins_with("f48_fixture_") else ": ordinary input"))
		row.budget_frames = 10000 if raw.action == "move_to" else 3000
		out.append(row)
	return out

func _build() -> Dictionary:
	var peers := 4 if suite() == "boss_four" else 2
	var steps: Array = []
	if not _select_profile("suite_profiles", suite()): return {}
	var saves: Variant = _profile.get("saves", [])
	if not saves is Array or saves.size() != peers:
		_profile_errors.append("F48 requires exactly %d independently captured v28 save directories" % peers)
		return {}
	if str(_profile.get("provenance", "")).is_empty(): _profile_errors.append("Disclose saved-input origin and any mechanics setup in profile.provenance")
	var transaction := _argument("transaction", "")
	var cut := _argument("cut", "")
	if suite() == "transactions" and transaction.is_empty() and cut.is_empty():
		var first := true
		for operation: String in TRANSACTIONS:
			for boundary: String in CUTS:
				if not _select_profile("transaction_profiles", operation): return {}
				var case_saves: Variant = _profile.get("saves", [])
				if not case_saves is Array or case_saves.size() != peers:
					_profile_errors.append("Each original transaction start requires exactly %d actual saved inputs: %s" % [peers, operation])
					return {}
				var case_id := operation + "_" + boundary
				if not first:
					steps.append(_entry(1, "leave", {}, "End prior independent transaction case"))
					steps.append(_entry(0, "leave", {}, "End prior original host session"))
				steps.append(_entry("all", "f48_start_case", {"case": case_id}))
				_admit(steps, case_saves, peers)
				_transactions(steps, operation, boundary, case_id)
				first = false
		return {"name": "F48 transactions complete6x4 matrix", "claim": "24 independent original saved-input mechanics cases; no earned campaign PASS. " + str(_profile.get("provenance", "")),
			"peers": peers, "scene": "title", "budget_s": 3600, "build_allowance_s": 300, "steps": steps}
	if suite() == "transactions" and not _select_profile("transaction_profiles", transaction): return {}
	if suite() == "transactions":
		saves = _profile.get("saves", [])
		if not saves is Array or saves.size() != peers:
			_profile_errors.append("Explicit original transaction start requires exactly %d saved inputs" % peers)
			return {}
	_admit(steps, saves, peers)
	match suite():
		"loop": _loop(steps)
		"boss_four": _boss(steps, peers)
		"behind": _behind(steps)
		"transactions": _transactions(steps)
		_: _profile_errors.append("Unknown F48 suite")
	return {"name": "F48 " + suite(), "claim": "Named mechanics proof only; no earned campaign PASS. " + str(_profile.get("provenance", "")),
		"peers": peers, "scene": "title", "budget_s": 3600, "build_allowance_s": 300, "steps": steps}

func _select_profile(group: String, key: String) -> bool:
	# Actual producer snapshots may differ by suite/operation: a pre-boss start
	# must not be replaced by a character already holding the boss rewards.
	# This selects original saved inputs only; the existing independent oracles,
	# native cuts, full default matrix and runtime file witnesses stay identical.
	_profile = _root_profile.duplicate(true)
	var suites: Variant = _root_profile.get("suite_profiles", {})
	if suites is Dictionary and suites.has(suite()):
		if not _apply_profile_start(suites[suite()], "suite " + suite()): return false
	elif not suites is Dictionary:
		_profile_errors.append("Actual suite profiles must be an object")
		return false
	if group == "transaction_profiles":
		var starts: Variant = _root_profile.get(group, {})
		if not starts is Dictionary:
			_profile_errors.append("Actual transaction profiles must be an object")
			return false
		if not starts.is_empty():
			if not starts.has(key):
				_profile_errors.append("Missing original actual-input transaction profile: " + key)
				return false
			return _apply_profile_start(starts[key], "transaction " + key)
	return true

func _apply_profile_start(raw: Variant, label: String) -> bool:
	if not raw is Dictionary or not raw.has_all(["saves", "routes", "outcomes", "provenance"]) \
		or not raw.saves is Array or not raw.routes is Dictionary or not raw.outcomes is Dictionary \
		or not raw.provenance is String or str(raw.provenance).is_empty():
		_profile_errors.append("Require disclosed actual saved inputs, ordinary routes and independent outcomes for " + label)
		return false
	for field: Variant in raw:
		if field not in ["saves", "routes", "outcomes", "provenance"]:
			_profile_errors.append("Actual-input start cannot replace proof configuration or semantics: " + label + "/" + str(field))
			return false
	_profile.saves = raw.saves.duplicate(true)
	_profile.routes.merge(raw.routes, true)
	_profile.outcomes.merge(raw.outcomes, true)
	_profile.provenance = str(_root_profile.get("provenance", "")) + " Actual start: " + raw.provenance
	return true

func _admit(steps: Array, saves: Array, peers: int, witness_label: String = "admitted") -> void:
	if _profile.has("test_configuration"):
		steps.append(_entry("all", "f48_require_configuration", {"files": _profile.test_configuration, "scope": _profile.get("configuration_scope", "bootstrap")}, "Pin disclosed effective mechanics configuration before any saved-input admission"))
	for peer: int in peers:
		if not saves[peer] is String or not DirAccess.dir_exists_absolute(saves[peer]):
			_profile_errors.append("Missing actual saved input for peer %d" % peer)
		steps.append(_entry(peer, "load_save", {"from": saves[peer], "portable_only": peer > 0}, "DISCLOSED saved-input setup; original guest character only, no borrowed world"))
	steps.append(_entry(0, "host"))
	for peer: int in range(1, peers): steps.append(_entry(peer, "production_join", {"returning_route": true, "character": {"character_id": "$character%d" % peer}}))
	steps.append(_entry("all", "expect_peers", {"count": peers}))
	steps.append(_entry("all", "f48_witness", {"remember": witness_label}))

func _prerequisites(steps: Array) -> void:
	steps.append(_entry("all", "f48_require", {"flags": [
		{"file": "res://data/config/stations.json", "path": "runtime_enabled"},
		{"file": "res://data/config/stations.json", "path": "craft_runtime_enabled"}],
		"nodes": [{"path": "Game/Session", "methods": ["homestead_breakthrough_service"]}]},
		"Refuse disabled stations or missing actual Foundation Master/Kitchen composition; never bind stand-ins"))

func _capture_prepared_start(steps: Array, label: String) -> void:
	steps.append(_entry("all", "f48_assert_snapshot", {}, "Read actual memory/disk carriers before any capture autosave"))
	steps.append(_entry("all", "capture_saves", {"label": label}, "Retain actual producer input bytes; no earned campaign credit"))

func _loop(steps: Array, capture_inputs: bool = false) -> void:
	_prerequisites(steps)
	for stage: String in ["hub", "craft", "portal", "master", "feast_cook", "feast", "boss", "relic"]:
		if stage == "boss":
			_boss(steps, 2)
			if capture_inputs: _capture_prepared_start(steps, "f48-before-key")
			continue
		steps.append(_entry("all", "f48_witness", {"remember": stage + "_before"}))
		for peer: int in 2:
			if capture_inputs and peer == 1 and stage in ["craft", "feast", "relic"]:
				_capture_prepared_start(steps, "f48-before-" + stage)
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
			if transaction in ["feast", "essence_spend"]:
				if not expected.get("creature") is Dictionary or not expected.creature.has_all(["uid", "level", "breakthroughs"]):
					_profile_errors.append("Independent owned UID/exact level/breakthroughs required for " + transaction)
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
		steps.append(_entry(peer, "production_join", {"returning_route": true, "character": {"character_id": "$character%d" % peer}}))
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
	honest.unchanged = ["redesign_character/portal_unlocks", "redesign_character/relics_held"]
	honest.item_delta = {"tidewake_portal_key": 0}
	honest.guest_world_empty = true
	honest.portal_enter = true
	honest.behind_arrival = true
	steps.append(_entry(1, "wait", {"frames": 180}))
	steps.append(_entry(1, "f48_assert", honest))
	steps.append(_entry(1, "f48_witness", {"remember": "behind_arrived"}))
	steps.append(_entry(1, "leave"))
	steps.append(_entry(1, "production_join", {"returning_route": true, "character": {"character_id": "$character1"}}))
	var rejoined := honest.duplicate(true)
	rejoined.since = "behind_arrived"
	rejoined.erase("behind_arrival")
	rejoined.erase("portal_enter")
	rejoined.unchanged = ["redesign_character/portal_unlocks", "redesign_character/relics_held", "redesign_character/transaction_receipts"]
	steps.append(_entry(1, "f48_assert", rejoined))

func _transactions(steps: Array, operation: String = "", boundary: String = "", case_id: String = "") -> void:
	var transaction := operation if not operation.is_empty() else _argument("transaction", "")
	var cut := boundary if not boundary.is_empty() else _argument("cut", "")
	if not TRANSACTIONS.has(transaction) or not CUTS.has(cut):
		_profile_errors.append("Choose --transaction=" + ",".join(TRANSACTIONS) + " and --cut=" + ",".join(CUTS))
		return
	if transaction in ["craft", "feast", "relic"]: _prerequisites(steps)
	steps.append_array(_route(transaction + "_prepare", 1))
	steps.append(_entry(1, "f48_witness", {"remember": "transaction_before"}))
	if cut in ["after_host_write_before_delivery", "after_owner_write_before_ack"]:
		steps.append(_entry(1, "f48_boundary_transaction", {"transaction": transaction, "phase": cut,
			"route": _route(transaction + "_commit", 1), "case": case_id}, "Hard guest death at the original production writer boundary"))
	if cut == "after_settlement":
		steps.append_array(_route(transaction + "_commit", 1))
		steps.append(_entry(1, "wait", {"frames": 180}))
		var settled := _outcome(transaction, "transaction_before")
		settled.saved_transaction = transaction
		steps.append(_entry(1, "f48_assert", settled))
		steps.append(_entry(1, "f48_witness", {"remember": "settled"}))
	steps.append(_entry(1, "restart_peer", {"scene": "title"}, "F48 hard process kill; no Session.leave or autosave"))
	if not case_id.is_empty(): steps.append(_entry(1, "f48_start_case", {"case": case_id}, "Restore detached case directory in fresh guest process"))
	steps.append(_entry(0, "expect_peers", {"count": 1}))
	steps.append(_entry(1, "production_join", {"returning_route": true, "pick_saved": true, "character": {"character_id": "$character1"}}, "Fresh process selects the original actual saved character through the real title picker"))
	steps.append(_entry("all", "expect_peers", {"count": 2}))
	# A process-local before witness is gone after a real kill. Copy its DETACHED
	# evidence into the fresh process metadata, never into the production state.
	steps.append(_entry(1, "f48_restore_witness", {"remember": "transaction_before"}))
	steps.append(_entry(1, "f48_restore_witness", {"remember": "admitted"}))
	if cut == "before_input":
		# No original decision exists yet. Reopen ordinary controls without
		# repeating preparation grants/actions, then make the FIRST commit.
		steps.append_array(_route(transaction + "_reopen", 1))
		steps.append_array(_route(transaction + "_commit", 1))
	elif cut == "after_settlement":
		steps.append(_entry(1, "f48_restore_witness", {"remember": "settled"}))
	# Admission reconciles the original retained journal through real delivery,
	# owner bool save and ACK. A new button press would be a new transaction.
	steps.append(_entry(1, "wait", {"frames": 180}))
	var recovered := _outcome(transaction, "transaction_before")
	recovered.saved_transaction = transaction
	if cut == "after_settlement": recovered.same_transaction_as = "settled"
	if cut in ["after_host_write_before_delivery", "after_owner_write_before_ack"]:
		recovered.boundary_case = case_id if not case_id.is_empty() else transaction
	steps.append(_entry(1, "f48_assert", recovered, "Actual original admission replay; exact receipt and personal outcome"))
	steps.append(_entry(0, "f48_assert", {"match_guest_transaction": transaction}, "Actual host durable row matches the original guest saved transaction"))
	steps.append(_entry(0, "f48_assert", {"since": "admitted", "unchanged": REPLAY_FIELDS}, "Host bystander personal state unchanged"))
	steps.append(_entry(1, "f48_witness", {"remember": "retry_settled"}))
	steps.append(_entry(1, "leave", {}, "Second ordinary disconnect after settlement"))
	steps.append(_entry(0, "expect_peers", {"count": 1}))
	steps.append(_entry(1, "production_join", {"returning_route": true, "character": {"character_id": "$character1"}}, "Replay the same actual accepted journal through ordinary returning admission"))
	steps.append(_entry("all", "expect_peers", {"count": 2}))
	steps.append(_entry(1, "wait", {"frames": 120}))
	steps.append(_entry(1, "f48_assert", {"since": "retry_settled", "unchanged": REPLAY_FIELDS, "guest_world_empty": true,
		"saved_transaction": transaction, "same_transaction_as": "retry_settled"}))
	steps.append(_entry(0, "f48_assert", {"match_guest_transaction": transaction}, "Second replay preserved the same actual host file journal"))
	steps.append(_entry(0, "f48_assert", {"since": "admitted", "unchanged": REPLAY_FIELDS}, "No duplicate guest transaction debited the host"))

func _argument(key: String, fallback: String) -> String:
	for value: String in OS.get_cmdline_user_args():
		if value.begins_with("--" + key + "="): return value.trim_prefix("--" + key + "=")
	return fallback

func _restart_peer(i: int, scene: String) -> Dictionary:
	# Existing restart sends quit first. F48 must also test a real process crash.
	# Kernel process exit is confirmed before the inherited restart is entered.
	if i <= 0 or i >= _peers.size(): return {"verdict": "FAIL", "detail": "F48 crashes only an admitted guest"}
	var old: Dictionary = _peers[i]
	var pid := int(old.get("pid", -1))
	old.quit_sent = true
	if not old.has("f48_exit_confirmed"):
		var before := _process_guard(pid)
		if before.get("ok") != true: return {"verdict": "FAIL", "detail": "Cannot identify original live guest process", "data": before}
		var stopped := _process_guard(pid, str(before.identity), true)
		if stopped.get("ok") != true or stopped.get("exited") != true:
			return {"verdict": "FAIL", "detail": "Native guest process exit not confirmed", "data": stopped}
		old.f48_exit_confirmed = stopped
	old.exited = true
	var result: Dictionary = await super._restart_peer(i, scene)
	if result.get("verdict") == "PASS": result.detail = "HARD CRASH (no graceful save): " + str(result.detail)
	return result

func _run_entry(index: int, peer: int, entry: Dictionary) -> bool:
	if entry.get("action") != "f48_boundary_transaction":
		if entry.get("action") == "f48_assert" and entry.get("args", {}).has("match_guest_transaction"):
			var original: Dictionary = _saved_transactions.get(str(entry.args.match_guest_transaction), {})
			if original.is_empty():
				check(false, "Original guest accepted transaction observation unavailable for host disk check")
				return false
			entry = entry.duplicate(true)
			entry.args.host_transaction_row = original.duplicate(true)
			entry.args.erase("match_guest_transaction")
		if entry.get("action") == "f48_assert" and entry.get("args", {}).has("boundary_case"):
			var observed: Dictionary = _boundary_observations.get(str(entry.args.boundary_case), {})
			if observed.is_empty():
				check(false, "Original native writer receipt unavailable after admission replay")
				return false
			entry = entry.duplicate(true)
			entry.args.boundary_receipt = observed.receipt
			entry.args.boundary_delivery_id = observed.delivery_id
			entry.args.erase("boundary_case")
		var passed: bool = await super._run_entry(index, peer, entry)
		if passed and entry.get("action") == "f48_assert" and entry.get("args", {}).has("saved_transaction"):
			var observed_row: Dictionary = _peers[peer].get("last_verdict", {}).get("data", {}).get("saved_transaction_row", {})
			if observed_row.is_empty():
				check(false, "Accepted original transaction row was not preserved in detached observation")
				return false
			_saved_transactions[str(entry.args.saved_transaction)] = observed_row.duplicate(true)
		if passed and entry.get("action") == "load_save":
			# Before admission the generic resolver can learn no active registry
			# identity. Pin the actual production loader's character result now;
			# later host admission/rejoin must still report that original identity.
			var loaded: Dictionary = _peers[peer].get("last_verdict", {}).get("data", {})
			var character_id := str(loaded.get("character_id", ""))
			if character_id.is_empty():
				check(false, "Actual saved-input character identity missing before admission")
				return false
			_characters[peer] = character_id
		return passed
	var args: Dictionary = entry.args
	var pid := int(_peers[peer].get("pid", -1))
	var character := str(_characters.get(peer, ""))
	var token := "%s_%s_%d" % [args.transaction, args.phase, pid]
	var output := _proof_out
	if not str(args.get("case", "")).is_empty(): output = output.path_join("cases").path_join(str(args.case))
	var path := output.path_join("f48-boundaries").path_join(token + ".json")
	var observer_peer := 0 if args.phase == "after_host_write_before_delivery" else peer
	var before := _process_guard(pid)
	if before.get("ok") != true:
		check(false, "F48 boundary cannot identify original guest process: " + str(before))
		return false
	_boundary_pending = {"path": path, "token": token, "pid": pid, "identity": str(before.identity),
		"peer": peer, "observer_pid": int(_peers[observer_peer].pid), "character": character,
		"phase": args.phase, "transaction": args.transaction, "serviced": false}
	var armed: Dictionary = await step(observer_peer, "f48_arm_boundary", {"transaction": args.transaction,
		"phase": args.phase, "guest_pid": pid, "character_id": character, "token": token,
		"coordinator_pid": OS.get_process_id(), "process_identity": str(before.identity)})
	if armed.get("verdict") != "PASS":
		_boundary_pending = {}
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
		if _boundary_pending.get("serviced", false):
			if args.phase != "after_host_write_before_delivery" or FileAccess.file_exists(path + ".resume.json"): break
		await process_frame
		_pump_once()
	var ack: Dictionary = _boundary_pending.get("ack", {})
	var durable_ack: Variant = JSON.parse_string(FileAccess.get_file_as_string(path + ".ack.json")) if FileAccess.file_exists(path + ".ack.json") else null
	var resume: Variant = JSON.parse_string(FileAccess.get_file_as_string(path + ".resume.json")) if FileAccess.file_exists(path + ".resume.json") else null
	var exit_confirmed: bool = durable_ack is Dictionary and durable_ack == ack \
		and ack.get("exit", {}).get("ok") == true and ack.get("exit", {}).get("exited") == true \
		and ack.get("exit", {}).get("identity") == before.identity and ack.get("marker_sha256") == FileAccess.get_sha256(path)
	var host_resume_confirmed: bool = args.phase != "after_host_write_before_delivery" or (resume is Dictionary \
		and resume.get("token") == token and resume.get("marker_sha256") == ack.get("marker_sha256") \
		and resume.get("ack_sha256") == FileAccess.get_sha256(path + ".ack.json") \
		and resume.get("observer_pid") == int(_peers[observer_peer].pid))
	var ok: bool = not input_failed and exit_confirmed and host_resume_confirmed and evidence is Dictionary \
		and evidence.get("guest_pid") == pid and evidence.get("token") == token and evidence.get("phase") == args.phase \
		and evidence.get("transaction") == args.transaction and evidence.get("observation", {}).get("character_id") == character \
		and not str(evidence.get("observation", {}).get("delivery_id", "")).is_empty() \
		and not str(evidence.get("observation", {}).get("receipt", "")).is_empty()
	check(ok, "F48 original production boundary and hard guest process death: " + token)
	if ok:
		var case_key := str(args.get("case", ""))
		if case_key.is_empty(): case_key = str(args.transaction)
		_boundary_observations[case_key] = evidence.observation.duplicate(true)
	_rows.append({"index": index, "peer": peer, "what": "f48_boundary_transaction", "label": entry.get("label", ""),
		"verdict": "PASS" if ok else "FAIL", "ok": ok, "expect": "PASS", "expect_data": {}, "detail": path})
	if not ok and not exit_confirmed: _peers[peer].quit_sent = false
	_boundary_pending = {}
	return ok
