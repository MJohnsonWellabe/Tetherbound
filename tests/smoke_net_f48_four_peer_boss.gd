extends "res://tests/smoke_net_veridian_relic_key.gd"

# peers: 4
## F48#2: a four-peer session completes one biome boss, and every participant
## receives their own key and relic.
##
##   tools/net/run_net_smoke.sh f48_four_peer_boss --peers=4
##
## Four real ENet processes, four saved characters. The host challenges the
## Warden (warden_aldis) through the production press; the three guests join
## that same fight; the host fights it down with real host-arbitrated strike
## intents (win_trainer_battle). Then, on EVERY peer: exactly one Tidewake
## portal key in its own satchel and the Meadows relic once in its own
## character, and its world holds the earned Heart once. A guest's rewards
## survive a leave and a returning-route rejoin.
## Disclosed fixtures: party_grant seeds each home before networking;
## explore_at stands each trainer in the Warden arena; dismiss_dialogue
## continues story lines; win_trainer_battle's enemy_hp_ceiling as in
## smoke_net_veridian_relic_key.
const PEERS := 4
var _ids: Array[String] = []
var _completed := false
var _f25: Dictionary = {}
var _f25_output := ""
var _f25_source := ""


## Opt-in only: --f25-medium=<fresh absolute directory> --f25-profile=<JSON>
## --source-commit=<full SHA>. The profile names four original save carriers,
## their character.json[.gz] byte hashes and deployed owned UID/move/rank/BT.
## review = {reviewer, highest_load_rationale, candidates_sha256}; owned[4] =
## {save_directory, character_id, character_sha256, creature_uid, move_id,
## slot, mastery_rank, breakthrough_count}. warmup_rounds and measured_rounds
## each contain four existing input steps per round: {action,args,budget_frames}.
## Only press/wait/stick/move_to are admitted; no save/HP/meter mutation steps.
## min_frames, max_frames, max_seconds, frame_budget_ms and min_overlap_frames
## are explicit reviewed bounds. Missing inputs fail before any peer launches.
func _f25_preflight() -> bool:
	var profile_path := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--f25-medium="): _f25_output = arg.trim_prefix("--f25-medium=")
		elif arg.begins_with("--f25-profile="): profile_path = arg.trim_prefix("--f25-profile=")
		elif arg.begins_with("--source-commit="): _f25_source = arg.trim_prefix("--source-commit=")
	if _f25_output.is_empty() and profile_path.is_empty(): return true
	var sha := RegEx.create_from_string("^[0-9a-f]{40}$")
	var actual := []
	var source_ok := OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"], actual, true) == 0
	if not _f25_output.is_absolute_path() or DirAccess.dir_exists_absolute(_f25_output) \
			or sha.search(_f25_source) == null or not source_ok or actual.is_empty() or str(actual[0]).strip_edges() != _f25_source:
		check(false, "F25 requires fresh absolute output and the actual full source SHA")
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(profile_path))
	if not parsed is Dictionary:
		check(false, "F25 requires a reviewed highest-load four-save profile")
		return false
	_f25 = parsed
	if not _f25.get("review") is Dictionary or not _f25.get("owned") is Array:
		check(false, "F25 review and owned input types are invalid")
		return false
	var review: Dictionary = _f25.get("review", {})
	var hash := RegEx.create_from_string("^[0-9a-f]{64}$")
	var owned: Array = _f25.get("owned", [])
	var ids := {}
	var uids := {}
	var valid := owned.size() == PEERS and not str(review.get("reviewer", "")).is_empty() \
		and not str(review.get("highest_load_rationale", "")).is_empty() and hash.search(str(review.get("candidates_sha256", ""))) != null
	for value: Variant in owned:
		if not value is Dictionary:
			check(false, "F25 owned input must be an object")
			return false
		var input: Dictionary = value
		var from := str(input.get("save_directory", ""))
		var id := str(input.get("character_id", ""))
		var uid := str(input.get("creature_uid", ""))
		var characters := from.path_join("characters/redesign-v28")
		if not DirAccess.dir_exists_absolute(characters): characters = from.path_join("characters")
		var dir := DirAccess.open(characters)
		var carrier := characters.path_join(id).path_join("character.json")
		if not FileAccess.file_exists(carrier): carrier += ".gz"
		valid = valid and from.is_absolute_path() and dir != null and not id.is_empty() and not uid.is_empty() \
			and not ids.has(id) and not uids.has(uid) and FileAccess.file_exists(carrier) \
			and hash.search(str(input.get("character_sha256", ""))) != null
		if dir != null: valid = valid and dir.get_directories().size() == 1
		if FileAccess.file_exists(carrier): valid = valid and FileAccess.get_sha256(carrier) == str(input.get("character_sha256", ""))
		ids[id] = true
		uids[uid] = true
		valid = valid and not str(input.get("move_id", "")).is_empty() and str(input.get("slot", "")) in ["quick", "charged", "utility", "ultimate"] \
			and int(input.get("mastery_rank", 0)) in range(1, 6) and int(input.get("breakthrough_count", -1)) in range(0, 6)
	for key: String in ["warmup_rounds", "measured_rounds"]:
		if not _f25.get(key, []) is Array:
			check(false, "F25 input rounds must be arrays")
			return false
		var rounds: Array = _f25.get(key, [])
		valid = valid and rounds.size() <= 128 and (key != "measured_rounds" or not rounds.is_empty())
		for raw_round: Variant in rounds:
			if not raw_round is Array:
				check(false, "F25 each input round must be an array")
				return false
			var round_steps: Array = raw_round
			valid = valid and round_steps.size() == PEERS
			for raw_item: Variant in round_steps:
				if not raw_item is Dictionary or not raw_item.get("args", {}) is Dictionary:
					check(false, "F25 each existing input step needs object args")
					return false
				var item: Dictionary = raw_item
				var budget := int(item.get("budget_frames", 0))
				valid = valid and str(item.get("action", "")) in ["press", "wait", "stick", "move_to"] \
					and budget in range(1, 3601)
				var args: Dictionary = item.get("args", {})
				if str(item.get("action")) == "press":
					valid = valid and not args.has("confirm") and str(args.get("action", "")) in ["combat_quick", "combat_charged", "combat_utility", "combat_ultimate_arm", "camera_recenter"] \
						and int(args.get("tap_frames", 1)) in range(1, 4) and int(args.get("times", 1)) in range(1, 33) \
						and int(args.get("gap_frames", 18)) in range(1, 3601) \
						and int(args.get("times", 1)) * (int(args.get("gap_frames", 18)) + int(args.get("tap_frames", 1)) + 2) <= budget
				elif str(item.get("action")) == "wait":
					valid = valid and not args.has("seconds") and int(args.get("frames", 0)) > 0 and int(args.get("frames", 0)) <= budget
				elif str(item.get("action")) == "stick":
					valid = valid and str(args.get("stick", "left")) in ["left", "right"] \
						and int(args.get("frames", 10)) > 0 and int(args.get("frames", 10)) + 1 <= budget \
						and is_finite(float(args.get("x", 0.0))) and absf(float(args.get("x", 0.0))) <= 1.0 \
						and is_finite(float(args.get("y", 0.0))) and absf(float(args.get("y", 0.0))) <= 1.0
				else:
					valid = valid and is_finite(float(args.get("x", 0.0))) and is_finite(float(args.get("z", 0.0))) \
						and int(args.get("budget_frames", 2400)) > 0 and int(args.get("budget_frames", 2400)) < budget \
						and is_finite(float(args.get("close_enough", 0.8))) and float(args.get("close_enough", 0.8)) > 0.0
	valid = valid and int(_f25.get("min_frames", 0)) >= 120 and int(_f25.get("max_frames", 0)) >= int(_f25.get("min_frames", 0)) \
		and int(_f25.get("max_frames", 0)) <= 7200 and float(_f25.get("max_seconds", 0.0)) > 0.0 \
		and float(_f25.get("max_seconds", 0.0)) <= 120.0 and float(_f25.get("frame_budget_ms", 0.0)) > 0.0 \
		and is_finite(float(_f25.get("frame_budget_ms", 0.0))) and int(_f25.get("min_overlap_frames", 0)) > 0 \
		and int(_f25.get("min_overlap_frames", 0)) <= int(_f25.get("min_frames", 0))
	check(valid, "F25 reviewed, hash-bound four-save inputs and bounded ordinary input rounds")
	return valid


func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	if _f25.is_empty(): return super(i, role, control_port, enet_port, scene, home, log_path, extra_args)
	# Preserve the harness's isolation, control protocol and direct Godot PID.
	var args: Array = ["--path", ProjectSettings.globalize_path("res://")]
	if i == 0: args.append_array(["--rendering-method", "forward_plus", "--resolution", "1920x1080"])
	else: args.append("--headless")
	if _is_windows(): args.append_array(["--log-file", log_path])
	args.append_array(["--script", "res://tools/net/proof_peer_runner.gd", "--", "--role=%s" % role,
		"--peer=%d" % i, "--control-port=%d" % control_port, "--enet-port=%d" % enet_port,
		"--scene=%s" % scene, "TB_NET_RUN_ID=%s" % _run_id])
	args.append_array(extra_args)
	if i == 0: args.append_array(["--f25-measured-peer", "--preset=Medium", "--source-commit=" + _f25_source, "--output=" + _f25_output])
	OS.set_environment("XDG_DATA_HOME", home)
	if _is_windows(): OS.set_environment("APPDATA", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", OS.get_environment("TB_NET_WORLD_SEED") if not OS.get_environment("TB_NET_WORLD_SEED").is_empty() else "0")
	if _is_windows(): return OS.create_process(OS.get_executable_path(), args)
	var parts: Array[String] = [_shq(OS.get_executable_path())]
	for arg: Variant in args: parts.append(_shq(str(arg)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" % [" ".join(parts), _shq(log_path)]])


func _run() -> void:
	heartbeat_silence_tolerance_s = 240.0
	if not _f25_preflight():
		quit(await finish())
		return
	if await launch(PEERS, "world" if _f25.is_empty() else "title"):
		await _flow()
	# A script error aborts _flow silently; only a completed flow passes.
	check(_completed, "the four-peer flow ran to its end")
	quit(await finish())


func _flow() -> void:
	_port = int(((_peers[0] as Dictionary).get("hello", {}) as Dictionary).get("enet_port", 0))
	check(_port > 0, "host reported its ENet port (%d)" % _port)
	if _port <= 0: return
	for peer in PEERS:
		if not _f25.is_empty():
			var input: Dictionary = _f25.owned[peer]
			var restored := await step(peer, "load_save", {"from": input.save_directory, "portable_only": peer != 0}, 12000)
			if not _pass(restored, "F25 peer %d restored its original owned save" % peer): return
			var id := str((restored.get("data", {}) as Dictionary).get("character_id", ""))
			check(id == str(input.character_id), "F25 peer %d retained its original stable identity" % peer)
			if id != str(input.character_id): return
			_ids.append(id)
			continue
		await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 0})
		for species: String in PARTY:
			var granted: Dictionary = await step(peer, "party_grant", {"species": species, "level": 18})
			check(str(granted.get("verdict", "")) == "PASS", "FIXTURE: peer %d received %s" % [peer, species])
		_ids.append(str(((await step(peer, "save_character_here", {})).get("data", {}) as Dictionary).get("character_id", "")))
	var distinct := {}
	for id: String in _ids: distinct[id] = true
	check(distinct.size() == PEERS and not distinct.has(""), "four distinct stable characters (%s)" % str(_ids))
	if not _pass(await step(0, "host", {"port": _port}), "host hosted"): return
	for peer in range(1, PEERS):
		var join_args := {"host": "127.0.0.1", "port": _port,
			"character": {"character_id": _ids[peer], "display_name": "Relic Guest %d" % peer}}
		if not _f25.is_empty(): join_args.merge({"returning_route": true, "budget_frames": 14000})
		var joined: Dictionary = await step(peer, "join" if _f25.is_empty() else "production_join", join_args, 15000 if not _f25.is_empty() else 6000)
		if not _pass(joined, "guest %d joined" % peer): return
		await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 0})
	for peer in PEERS:
		if not _pass(await step(peer, "expect_peers", {"count": PEERS}), "peer %d sees four peers" % peer): return
	for peer in PEERS:
		var keys0 := await _keys(peer)
		var relics0 := await _relics_held(peer)
		check(keys0 == 0 and not relics0.has(RELIC), "peer %d holds no key or Meadows relic before the Warden" % peer)
	# The Warden, shared by all four.
	for peer in PEERS:
		if _f25.is_empty(): await step(peer, "deploy_creature", {})
		else:
			# Ordinary recall only: no deploy_creature fallback adoption or grant.
			if not _pass(await step(peer, "press", {"action": "creature_recall", "gap_frames": 60}), "F25 peer %d recalled its owned companion" % peer): return
	var hold: Variant = await probe(0, "stronghold")
	var markers: Dictionary = (hold as Dictionary).get("markers", {}) as Dictionary if hold is Dictionary else {}
	var arena: Array = markers.get("warden_arena", []) as Array
	check(arena.size() == 3, "the Hall names its Warden arena (%s)" % str(arena))
	if arena.size() != 3: return
	for peer in PEERS:
		var offset: float = [-2.0, 2.0, -2.0, 2.0][peer]
		var depth: float = [0.0, 0.0, 2.5, 2.5][peer]
		await step(peer, "explore_at", {"at": [float(arena[0]) + offset, float(arena[2]), float(arena[1]) + depth], "settle": 60})
	if not _pass(await step(0, "trainer_battle", {"trainer": WARDEN_TRAINER, "settle": 45}), "host challenged the Warden"): return
	var record: Variant = await probe(0, "encounter")
	var encounter_id := str((record as Dictionary).get("id", "")) if record is Dictionary else ""
	for peer in range(1, PEERS):
		if not _pass(await step(peer, "join_encounter", {"encounter_id": encounter_id}), "guest %d joined the Warden's fight" % peer): return
	var count := 0
	for _poll in 30:
		var after_join: Variant = await probe(0, "encounter")
		count = ((after_join as Dictionary).get("participants", []) as Array).size() if after_join is Dictionary else 0
		if count == PEERS: break
		await step(0, "wait", {"frames": 10})
	check(count == PEERS, "the Warden's record holds all four participants (%d)" % count)
	if count != PEERS: return
	if not _f25.is_empty() and not await _f25_window(): return
	var after_window: Variant = {}
	if not _f25.is_empty(): after_window = await probe(0, "boss")
	if _f25.is_empty() or bool((after_window as Dictionary).get("battle_active", true)):
		# Existing completion fixture is AFTER the measured window, never inside.
		var won: Dictionary = await step(0, "win_trainer_battle",
			{"budget_frames": BATTLE_FRAMES, "enemy_hp_ceiling": ENEMY_HP_CEILING, "self_hp_topups": false}, BATTLE_FRAMES + 900)
		if not _pass(won, "four peers felled the Warden"): return
	for peer in PEERS:
		await step(peer, "wait", {"frames": 120})
		await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 30})
	for peer in PEERS:
		await _want_paid(peer, "after the Warden")
	# A guest leaves and returns by its character: still exactly one each.
	if not _pass(await step(3, "leave", {}), "guest 3 left"): return
	if not _pass(await step(0, "expect_peers", {"count": PEERS - 1}), "host sees three peers"): return
	if not _pass(await step(3, "production_join", {"host": "127.0.0.1", "port": _port, "budget_frames": 14000,
			"returning_route": true, "character": {"character_id": _ids[3]}}, 15000), "guest 3 rejoined"): return
	await step(3, "wait", {"frames": 240})
	await _want_paid(3, "after guest 3's rejoin")
	_completed = true
	print("F48_FOUR_PEER_BOSS: four participants, one Warden, one key and one relic each")


func _f25_rounds(rounds: Array) -> bool:
	for round_steps: Array in rounds:
		var requests: Array = []
		for peer in PEERS:
			var item: Dictionary = round_steps[peer].duplicate(true)
			item["peer"] = peer
			requests.append(item)
		for result: Dictionary in await race(requests):
			if not _pass(result.verdict, "F25 ordinary input peer %d" % int(result.peer)): return false
	return true


func _f25_window() -> bool:
	if not await _f25_rounds(_f25.get("warmup_rounds", [])): return false
	if not _pass(await step(0, "f25_frame_start", {"profile": _f25}), "F25 native Medium collector started"): return false
	var inputs_ok := await _f25_rounds(_f25.measured_rounds)
	# Always stop/retain failed rows too; no file I/O or PNG readback in window.
	var result := await step(0, "f25_frame_stop", {})
	return _pass(result, "F25 real four-producer GPU frame window") and inputs_ok


func _want_paid(peer: int, label: String) -> void:
	var ok := false
	var heart: Dictionary = {}
	var keys := -1
	var relics: Array = []
	for _poll in POLLS:
		heart = await _heart(peer)
		keys = await _keys(peer)
		relics = await _relics_held(peer)
		if bool(heart.get("earned_in_world", false)) and keys == 1 and relics.count(RELIC) == 1:
			ok = true
			break
		await step(peer, "wait", {"frames": 10})
	check(ok, "%s: peer %d holds its own Tidewake key (x%d) and Meadows relic (%s); world Heart earned (%s)"
		% [label, peer, keys, str(relics), str(heart)])


func _pass(result: Dictionary, label: String) -> bool:
	var ok := str(result.get("verdict", "")) == "PASS"
	check(ok, "%s: %s" % [label, str(result.get("detail", ""))])
	return ok
