extends "res://tools/net/peer_runner.gd"

## F18 integration witness. Fixtures are explicitly separate from evidence:
## one creature, protected keys and free-play flags BEFORE hosting/admission;
## grounded staging BEFORE gameplay evidence. Scoped traversal fixtures are
## disclosed by their runner. No setup writes follow its gameplay input seam.
const F18_TRAVEL := preload("res://tests/helpers/f49_portal_travel.gd")
const F18_STONE := preload("res://scripts/world/waystone.gd")
const F18_TEACHING := preload("res://scripts/creatures/teaching.gd")
const F18_NAV := preload("res://tests/helpers/stick_navigator.gd")
const F18_INPUT := preload("res://scripts/ui/input_owner.gd")
const F18_LESSON := preload("res://scripts/onboarding/lesson_panel.gd")
const F18_GUARDS := preload("res://tests/helpers/f18_player_guards.gd")
const F18_CARE := preload("res://tests/helpers/meadows_earned_team_segment.gd")
var _f18_fixture_done := false
var _f18_started := false
var _f18_staged := false
var _f18_results: Array[Dictionary] = []
var _f18_presentation: Node

func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if not action.begins_with("f18_"): return await super._execute_step(msg)
	var game := root.get_node_or_null(^"Game")
	if game == null: return {"verdict": "ERROR", "detail": "F18 has no Game"}
	if action in ["f18_home_key", "f18_arch"] and DisplayServer.get_name() != "headless" and not is_instance_valid(_f18_presentation):
		_f18_presentation = preload("res://tests/helpers/f18_presentation_capture.gd").attach(self, game,
			"res://ralph/reports/HUB/f18/native/peer_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	if not game.is_connected("portal_action_result", _f18_note):
		game.connect("portal_action_result", _f18_note)
	var before := _physics_count
	var args: Dictionary = msg.get("args", {})
	var result: Dictionary
	_f18_tracing = action
	_f18_trace_loop(action)
	match action:
		"f18_boot_world":
			if _f18_started or _f18_fixture_done or _session().call("is_active") == true:
				result = _f18_verdict(false, "direct world fixture boot must precede setup/admission")
			else:
				await _boot_scene("world", 30)
				result = _f18_verdict(current_scene != null and current_scene.scene_file_path == WORLD_SCENE,
					"disclosed sequential world fixture boot after lightweight title hello")
		"f18_fixture": result = await _f18_fixture(game, args)
		"f18_boot_water_fixture":
			if _f18_started or _f18_fixture_done or _session().call("is_active") == true:
				result = _f18_verdict(false, "Water fixture boot must precede setup/admission")
			else:
				await _boot_scene("water", 30)
				result = _f18_verdict(current_scene != null and current_scene.scene_file_path == WATER_SCENE,
					"DISCLOSED direct Water fixture boot; no earned portal crossing")
		"f18_stage_water_lesson": result = await _f18_stage_water_lesson(game)
		"f18_traversal_refusal": result = await _f18_traversal_refusal(game, str(args.get("kind", "")))
		"f18_stage": result = await _f18_stage(game, args)
		"f18_inspect": result = _f18_verdict(true, "read-only production/disk witness", _f18_state(game, args))
		"f18_settled":
			# Read-only wait: the last owner transaction finishes its ordinary
			# settlement (owner-passive fence and training row released).
			var deadline := Time.get_ticks_msec() + 20000
			while _session().call("_owner_training_mutation_blocked", game.get("local")) == true and Time.get_ticks_msec() < deadline:
				await physics_frame
			var blocked: bool = _session().call("_owner_training_mutation_blocked", game.get("local")) == true
			result = _f18_verdict(not blocked, "owner transactions settled before the session ends",
				{"reason": str(_session().call("_owner_snapshot_block_reason", game.get("local"))) if blocked else ""})
		"f18_touch":
			_f18_started = true
			result = await _f18_touch(game, args)
		"f18_home_key":
			_f18_started = true
			result = await _f18_home_key(game)
		"f18_arch":
			_f18_started = true
			result = await _f18_arch(game, args)
		_: result = _f18_verdict(false, "unknown F18 action " + action)
	_f18_tracing = ""
	result.frames_used = _physics_count - before
	if is_instance_valid(_f18_presentation): _f18_presentation.call("_flush")
	return result

func _f18_verdict(ok: bool, detail: String, data: Dictionary = {}) -> Dictionary:
	if not ok: detail += " [" + _f18_owner_diagnosis() + "]"
	return {"verdict": "PASS" if ok else "FAIL", "detail": detail, "data": data}

## Diagnostic only: a step that never returns a verdict still leaves a trail.
var _f18_tracing := ""

func _f18_trace_loop(action: String) -> void:
	var next := Time.get_ticks_msec() + 4000
	while _f18_tracing == action:
		await physics_frame
		if Time.get_ticks_msec() < next: continue
		next += 4000
		var requests: Variant = _session().get("_portal_requests") if _session() != null else null
		print("F18_OWNER_TRACE step=%s t=%d %s portal_requests=%d" % [action, Time.get_ticks_msec(),
			_f18_owner_diagnosis(), (requests as Dictionary).size() if requests is Dictionary else -1])

## Diagnostic only: why the local owner record may still be held.
func _f18_owner_diagnosis() -> String:
	var session: Node = _session()
	var game := root.get_node_or_null(^"Game")
	if session == null or game == null or game.get("local") == null: return "no session/local"
	var row: Dictionary = session.call("_owner_training_row")
	var passive: Variant = session.get("_owner_passive")
	var phase: Variant = passive.get("pending").get("phase") if passive != null and passive.get("pending") is Dictionary else ""
	return "block=%s row=%s/%s passive_phase=%s" % [str(session.call("_owner_snapshot_block_reason", game.get("local"))),
		str(row.get("action", "")), str(row.get("status", "")), str(phase)]

func _f18_note(result: Dictionary) -> void:
	_f18_results.append(result.duplicate(true))

func _f18_fixture(game: Node, args: Dictionary) -> Dictionary:
	if _f18_fixture_done or _f18_started or _session().call("is_active") == true:
		return _f18_verdict(false, "fixtures require a fresh disconnected peer")
	if _session().call("portal_runtime_ready") != true:
		return _f18_verdict(false, "production F18 runtime is disabled; smoke must not override it")
	var local: RefCounted = game.get("local")
	var party: RefCounted = game.get("party")
	if party.call("size") == 0:
		var creature: RefCounted = game.call("make_creature", "terrapup", "F18 fixture")
		if creature == null or party.call("add", creature) != true:
			return _f18_verdict(false, "disclosed one-creature fixture could not be installed")
	# These are fixture facts, never proof of Grandpa's gift or earned boss keys.
	local.get("flags").call("set_flag", "opening:beat:free_play", true)
	local.get("flags").call("set_flag", "opening:starter_granted", true)
	var inventory: RefCounted = game.get("inventory")
	var fixture_items: Array[String] = ["home_key"]
	if bool(args.get("guest", false)): fixture_items.append("tidewake_portal_key")
	for item: String in fixture_items:
		if inventory.call("count", item) != 0 or inventory.call("add", item, 1) != 0:
			return _f18_verdict(false, "cannot install exactly one disclosed fixture " + item)
	local.get("flags").call("set_flag", "home_key_given", true)
	var snapshot: Dictionary = game.get("save_system").call("snapshot", game)
	local.set("redesign_character", F18_TEACHING.character_loadout_mirror(snapshot.party,
		local.get("redesign_character")))
	for node: Node in get_nodes_in_group("progression_restore"):
		if node.has_method("restore_progression_from_game"): node.call("restore_progression_from_game", game)
	for frame in 30: await physics_frame
	# The disclosed key fixture naturally opens Grandpa's real teaching card.
	# Continue its actual lines before admission/save, never seed lesson flags.
	var teaching: Dictionary = await _f18_finish_fixture_teaching(game)
	if teaching.get("verdict") != "PASS": return teaching
	# The joiner relinquished world-save ownership before its initial scene;
	# disconnected solo autosave consequently refuses. This PUBLIC portable
	# save is fixture setup only, before admission or gameplay evidence.
	if bool(args.get("guest", false)):
		if game.get("save_system").call("save_character", game, str(local.get("character_id"))) != true:
			return _f18_verdict(false, "disclosed pre-admission portable fixture save refused")
	else:
		var saved: Dictionary = await _step_save_character_here({})
		if saved.get("verdict") != "PASS": return saved
	_f18_fixture_done = true
	var state: Dictionary = _f18_state(game, {})
	state.fixture_teaching = teaching.data
	return _f18_verdict(true, "DISCLOSED setup only: starter/free-play flags and own HomeKey per peer; guest Tidewake key, not earned opening",
		state)

func _f18_finish_fixture_teaching(game: Node) -> Dictionary:
	var scene: Node = current_scene
	var session: Node = _session()
	var local: RefCounted = game.get("local")
	var identity: String = str(local.get("character_id"))
	var service: Node = game.get_node_or_null(^"OnboardingLessons")
	var lesson: Node = service.get("_panel") if service != null else null
	var travel := F18_TRAVEL.new(self, game)
	var started: int = Engine.get_physics_frames()
	var presses: Array[Dictionary] = []
	var row: Dictionary = {}
	var previous_line := -1
	while Engine.get_physics_frames() - started <= 180:
		if current_scene != scene or _session() != session or game.get("local") != local \
				or str(local.get("character_id")) != identity or session.call("is_active") == true:
			return _f18_verdict(false, "fixture teaching changed source/character/session before admission")
		var holder: Node = F18_INPUT.current(self)
		if holder != null and holder == lesson and lesson.get_script() == F18_LESSON \
				and lesson.call("is_open") == true and service.get("_identity") == identity:
			var actual: Dictionary = lesson.get("_row")
			var line: int = int(lesson.get("_line"))
			var lines: Array = actual.get("lines", [])
			if actual.get("id") != "home_key" or actual.get("conversation") != "lesson_home_key" \
					or lines.is_empty() or lines.size() > 20 or line != previous_line + 1 \
					or (not row.is_empty() and actual != row):
				return _f18_verdict(false, "fixture teaching is not the unchanged actual Home Key lesson/cursor")
			if row.is_empty(): row = actual.duplicate(true)
			presses.append({"line": line, "text": str(lesson.get("_text").get("text")),
				"character_id": identity, "panel": str(lesson.get_path())})
			previous_line = line
			await travel.tap("menu_confirm")
		elif holder == null and not paused:
			var pending: bool = service != null and (service.get("_pending") as Dictionary).has("opening:lesson:home_key")
			if not pending:
				if not presses.is_empty() and (presses.size() != (row.get("lines") as Array).size() \
						or local.get("flags").call("has", "opening:lesson:home_key") != true):
					return _f18_verdict(false, "ordinary fixture lesson continuation lacks all lines/production acknowledgement")
				return _f18_verdict(true, "actual pre-admission teaching released ordinary input", {
					"menu_confirm_presses": presses, "budget_frames": 180,
					"frames_used": Engine.get_physics_frames() - started,
					"character_id": identity, "earned_opening_credit": false})
		await physics_frame
	return _f18_verdict(false, "actual fixture teaching did not release input within 180 frames", {
		"menu_confirm_presses": presses, "holder": str(F18_INPUT.current(self))})

func _f18_stage(game: Node, args: Dictionary) -> Dictionary:
	if not _f18_fixture_done or _f18_staged or _f18_started:
		return _f18_verdict(false, "one disclosed position fixture is closed after first gameplay evidence")
	var stone := _f18_find_stone(str(args.get("stone", "")))
	var player := game.call("find_player") as CharacterBody3D
	if stone == null or player == null or current_scene == null:
		return _f18_verdict(false, "staging requires the actual mounted stone/player")
	var at := stone.global_position + Vector3(0, 0, 5.3)
	at.y = float(current_scene.call("ground_height_at", at.x, at.z)) + player.safe_margin
	if not at.is_finite(): return _f18_verdict(false, "staging fixture lacks ordinary ground")
	REMOTE_CREATURE_TP.teleport_body(player, at)
	player.velocity = Vector3.ZERO
	for frame in 60: await physics_frame
	_f18_staged = true
	return _f18_verdict(player.is_on_floor() and player.global_position.distance_to(stone.global_position) > 2.4,
		"DISCLOSED grounded staging outside touch radius; gameplay starts after this seam", _f18_state(game, {}))

func _f18_find_stone(id: String) -> Node3D:
	for node: Node in get_nodes_in_group("waystones"):
		if current_scene != null and current_scene.is_ancestor_of(node) and node.get("waystone_id") == id:
			return node as Node3D
	return null

func _f18_stage_water_lesson(game: Node) -> Dictionary:
	if not _f18_fixture_done or _f18_staged or _f18_started or _session().call("is_active") == true \
			or game.get("current_realm") != "water" or current_scene == null:
		return _f18_verdict(false, "Water lesson staging requires the disconnected pre-evidence fixture")
	var player := game.call("find_player") as CharacterBody3D
	if player == null or not current_scene.is_ancestor_of(player): return _f18_verdict(false, "actual Water Player missing")
	var config: Dictionary = current_scene.get("config")
	var at := Vector3.INF
	for row: Dictionary in config.anchors:
		if row.get("id") == config.swim_lesson.start_anchor:
			var raw: Array = row.safe_position
			at = Vector3(float(raw[0]), 0, float(raw[2]))
			at.y = float(current_scene.call("ground_height_at", at.x, at.z)) + player.safe_margin
			break
	if not at.is_finite(): return _f18_verdict(false, "authored Water lesson dry landing missing")
	REMOTE_CREATURE_TP.teleport_body(player, at)
	player.velocity = Vector3.ZERO
	for frame in 60: await physics_frame
	_f18_staged = true
	var swim: Node = player.get("swim_controller")
	return _f18_verdict(player.is_on_floor() and swim != null and swim.call("is_swimming") == false,
		"DISCLOSED one grounded dry-lesson staging fixture; subsequent movement is ordinary input", {
			"position": [player.global_position.x, player.global_position.y, player.global_position.z],
			"grounded": player.is_on_floor(), "earned_crossing_credit": false})

func _f18_traversal_refusal(game: Node, kind: String) -> Dictionary:
	if not _f18_fixture_done or _f18_started or _session().call("is_active") == true \
			or kind not in ["swimming", "flying"] or F18_INPUT.current(self) != null:
		return _f18_verdict(false, "traversal refusal needs the disconnected fixture and actual world input")
	var player := game.call("find_player") as CharacterBody3D
	var rig := current_scene.get_node_or_null(^"CameraRig") as Node3D
	if player == null or rig == null: return _f18_verdict(false, "actual traversal Player/rig missing")
	_f18_started = true
	var travel := F18_TRAVEL.new(self, game)
	var guards := F18_GUARDS.new(self, game, travel)
	# Bind the real fixture key through the actual Satchel verb, not a setter.
	await travel.tap("inventory")
	var menu: Node = game.call("menu")
	if menu == null or menu.call("is_open") != true or menu.call("current_tab_id") != "backpack":
		return _f18_verdict(false, "actual Satchel did not open for traversal key binding")
	var care := F18_CARE.new()
	care.set("_tree", self)
	var tab: Node = (menu.get("_bodies") as Array)[0]
	if not await guards._assign_in_satchel(tab, care, "home_key", 4):
		return _f18_verdict(false, "ordinary traversal key assignment failed", {"failures": guards.failures})
	await travel.tap("menu_cancel")
	for frame in 30:
		if F18_INPUT.current(self) == null: break
		await physics_frame
	if F18_INPUT.current(self) != null: return _f18_verdict(false, "actual Satchel did not release input")
	var recoveries: int = int(player.get("_unstick_count"))
	var source: Node
	var inputs: Array[String]
	if kind == "swimming":
		if not _f18_staged or game.get("current_realm") != "water":
			return _f18_verdict(false, "swimming proof requires the declared dry Water lesson start")
		var raw: Array = current_scene.get("config").swim_lesson.surface_polyline[0]
		var target := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
		var nav := F18_NAV.new(self, player, rig, travel._stick)
		var walked: bool = await nav.walk_to(target, 900, 0.4)
		travel._stick(0, 0)
		if not walked or int(player.get("_unstick_count")) != recoveries:
			return _f18_verdict(false, "ordinary dry-to-water lesson walk failed or recovered")
		source = player.get("swim_controller")
		inputs = ["Satchel Assign", "left stick dry-to-water", "hotbar_5"]
	else:
		# Height stays ZERO: two actual Jump presses launch from actual ground.
		var fly: Node = player.get("fly_controller")
		if not player.is_on_floor() or fly == null or fly.call("is_flying") != false:
			return _f18_verdict(false, "actual ground double Jump requires grounded nonflying start")
		var launched: Dictionary = await _step_fly_launch({"height": 0.0, "settle": 0, "attempts": 1})
		if launched.get("verdict") != "PASS": return launched
		source = player.get("fly_controller")
		var climbing: Dictionary = _press_edge("jump", true)
		if climbing.get("ok") != true: return _f18_verdict(false, "ordinary flight climb input failed")
		inputs = ["Satchel Assign", "double Jump from ground", "hold Jump to climb", "hotbar_5", "release Jump"]
	var refused: bool = await guards.bound_refusal(kind, source)
	var pixels: Dictionary = {}
	if refused and DisplayServer.get_name() != "headless":
		print("F18_REFUSAL_CAPTURE_PHASE " + JSON.stringify({"phase": "before_native_capture", "kind": kind,
			"monotonic_msec": Time.get_ticks_msec(), "process_frame": Engine.get_process_frames(),
			"guard_receipt": guards.receipts.back()}))
		pixels = await _f18_capture_refusal(game, guards, kind, source, player)
		print("F18_REFUSAL_CAPTURE_PHASE " + JSON.stringify({"phase": "after_native_capture", "kind": kind,
			"monotonic_msec": Time.get_ticks_msec(), "passed": pixels.get("passed"), "captured": pixels.get("captured")}))
	var released: bool = true
	if kind == "flying":
		var release_edge: Dictionary = _press_edge("jump", false)
		released = release_edge.get("ok") == true and not Input.is_action_pressed("jump")
	return _f18_verdict(refused and released and (pixels.is_empty() or pixels.get("passed") == true) \
			and int(player.get("_unstick_count")) == recoveries,
		"actual traversal + bound key input requires stated refusal without travel/inventory/channel changes", {
			"kind": kind, "inputs": inputs, "receipts": guards.receipts, "failures": guards.failures,
			"jump_released": released if kind == "flying" else null, "native_pixels": pixels,
			"unstick_count_before": recoveries, "unstick_count_after": player.get("_unstick_count"),
			"position": [player.global_position.x, player.global_position.y, player.global_position.z],
			"earned_opening_or_traversal_unlock_credit": false})

func _f18_capture_refusal(game: Node, guards: RefCounted, kind: String, source: Node, player: CharacterBody3D) -> Dictionary:
	# Native-only observation after the existing refusal proof. Capture pixels
	# and their actual state in the same post-draw callback, without moving actors.
	var folder := "res://ralph/reports/HUB/f18/native/refusal_%s_%d_%d" % [kind, OS.get_process_id(), Time.get_ticks_usec()]
	var result := {"passed": false, "captured": false, "path": folder.path_join("refusal.png"),
		"display_server": DisplayServer.get_name(), "visual_verdict": "UNASSESSED; independent pixel review required"}
	if not preload("res://tools/fresh_capture_output.gd").create_fresh(folder, "F18 actual refusal pixels"): return result
	var scene: Node = current_scene
	var capture := func() -> void:
		result.captured = true
		if not is_instance_valid(game) or not is_instance_valid(source) or not is_instance_valid(player) \
				or current_scene != scene or game.call("find_player") != player: return
		var key: Node = game.get_node_or_null(^"HomeKey")
		var label: Label = key.get("_refusal_label") if key != null else null
		var panel: Control = key.get("_refusal_panel") if key != null else null
		var expected: String = "Land first." if kind == "flying" else "Reach solid ground first."
		if not is_instance_valid(label) or not is_instance_valid(panel) or not label.is_visible_in_tree() \
				or not panel.is_visible_in_tree() or label.text != expected or not guards._refusal_context(kind, source, scene): return
		var image: Image = root.get_texture().get_image()
		if image == null or image.is_empty(): return
		var rect: Rect2 = label.get_global_rect()
		result.merge({"reason": label.text, "label_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
			"width": image.get_width(), "height": image.get_height(), "process_frame": Engine.get_process_frames(),
			"physics_frame": Engine.get_physics_frames(), "traversal": guards._traversal_snapshot(kind, source, player),
			"input": "actual hotbar_5; flight retains ordinary climb hold until capture then verifies Jump release",
			"capture_source": "actual peer root viewport texture in frame_post_draw callback"})
		result.passed = image.save_png(result.path) == OK
	result.automatic_render_loop = RenderingServer.is_render_loop_enabled()
	result.renderer_sampling = "continuous native frames" if result.automatic_render_loop else "disclosed one explicit native draw; no continuous-render performance acceptance"
	RenderingServer.frame_post_draw.connect(capture, CONNECT_ONE_SHOT)
	if not result.automatic_render_loop: RenderingServer.force_draw()
	for frame in 120:
		if result.captured: break
		await process_frame
	if RenderingServer.frame_post_draw.is_connected(capture): RenderingServer.frame_post_draw.disconnect(capture)
	var file := FileAccess.open(folder.path_join("receipt.json"), FileAccess.WRITE)
	if file == null: result.passed = false
	else: file.store_string(JSON.stringify(result, "\t"))
	return result

func _f18_find_arch(id: String) -> Node3D:
	for node: Node in get_nodes_in_group("portal_arches"):
		if current_scene != null and current_scene.is_ancestor_of(node) and node.get("arch_id") == id:
			return node as Node3D
	return null

func _f18_touch(game: Node, args: Dictionary) -> Dictionary:
	var id := str(args.get("stone", ""))
	var stone := _f18_find_stone(id)
	var player := game.call("find_player") as CharacterBody3D
	var rig := current_scene.get_node_or_null(^"CameraRig") as Node3D
	if stone == null or player == null or rig == null or F18_INPUT.current(self) != null:
		return _f18_verdict(false, "touch needs actual stone and ordinary world input")
	var local: RefCounted = game.get("local")
	var before: Array = local.get("redesign_character").transaction_receipts.duplicate()
	var result_start := _f18_results.size()
	var travel := F18_TRAVEL.new(self, game)
	var nav := F18_NAV.new(self, player, rig, travel._stick)
	var recoveries := int(player.get("_unstick_count"))
	var walked: bool = await nav.walk_to(stone.global_position, 1200, 2.1)
	travel._stick(0, 0)
	if not walked or not player.is_on_floor() or int(player.get("_unstick_count")) != recoveries:
		return _f18_verdict(false, "ordinary capsule walk did not actually touch the stone")
	var deadline := Time.get_ticks_msec() + 16000
	while Time.get_ticks_msec() < deadline:
		await physics_frame
		for index in range(result_start, _f18_results.size()):
			var reply := _f18_results[index]
			if reply.get("kind") != "waystone_touch" or reply.get("waystone_id") != id: continue
			var state := _f18_state(game, {})
			var receipt := ""
			for candidate: String in state.character.get("transaction_receipts", []):
				if candidate.begins_with("craft:waystone_") and not before.has(candidate): receipt = candidate
			var disk: Dictionary = state.character_disk.get("redesign_character", {})
			var ok: bool = reply.get("ok") == true and reply.get("durable") == true \
				and reply.get("character_id") == state.character_id and not receipt.is_empty() \
				and state.character.last_waystones.get("meadows") == id \
				and disk.get("last_waystones", {}).get("meadows") == id \
				and disk.get("transaction_receipts", []).has(receipt) \
				and disk.get("waystones_activated", {}).get("meadows", []).has(id)
			state.observed_reply = reply
			state.touch_receipt = receipt
			return _f18_verdict(ok, "actual walk/touch requires bound durable reply + new receipt on portable disk", state)
	return _f18_verdict(false, "actual stone emitted no successful durable acknowledgement", _f18_state(game, {}))

func _f18_home_key(game: Node) -> Dictionary:
	var start := _f18_results.size()
	var before := _f18_state(game, {})
	var travel := F18_TRAVEL.new(self, game)
	if not await travel.home_key():
		return _f18_verdict(false, "actual Satchel HomeKey input: " + str(travel.failures), _f18_state(game, {}))
	var reply := _f18_latest(start, "home_key_finish")
	var after := _f18_state(game, {})
	var target := Vector3(INF, INF, INF)
	for hall: Node in get_nodes_in_group("crossing_halls"):
		if current_scene.is_ancestor_of(hall): target = hall.call("home_arrival")
	var ok: bool = reply.get("ok") == true and reply.get("durable") == true and reply.get("saved") == true \
		and reply.get("character_id") == after.character_id and after.realm == "meadows" \
		and after.home_key_count == 1 and before.home_key_count == 1 and target.is_finite() \
		and _f18_at_arrival_slot(_f18_vector(after.position), target) \
		and _f18_disk_pose_at(after, "meadows", _f18_vector(after.position))
	after.observed_reply = reply
	after.before_position = before.position
	return _f18_verdict(ok, "production Satchel Use requires saved authoritative HomeKey return at actual Hall", after)

## The anchor itself, or (co-op, occupied anchor) one of its authored slots.
## Same 1 m arrival tolerance as before; a slot is never an arbitrary point.
func _f18_at_arrival_slot(at: Vector3, anchor: Vector3) -> bool:
	if not at.is_finite() or not anchor.is_finite(): return false
	for slot: Vector3 in preload("res://scripts/net/foundation_portal_arrival.gd").arrival_slots(anchor):
		if at.distance_to(slot) < 1.0: return true
	return false

func _f18_arch(game: Node, args: Dictionary) -> Dictionary:
	var id := str(args.get("arch", ""))
	var mode := str(args.get("mode", ""))
	var arch := _f18_find_arch(id)
	if arch == null or mode not in ["unlock", "enter"]: return _f18_verdict(false, "missing actual arch/mode")
	var before := _f18_state(game, {})
	var view: Dictionary = game.call("portal_view", id)
	if mode == "unlock" and (view.get("has_key") != true or view.get("character_open") == true):
		return _f18_verdict(false, "unlock requires matching fixture key and locked personal arch", before)
	if mode == "enter" and (view.get("open") != true or view.get("has_key") == true):
		return _f18_verdict(false, "Enter requires an already open arch without a consumable key", before)
	var start := _f18_results.size()
	var travel := F18_TRAVEL.new(self, game)
	if not await travel.activate(arch.get_node_or_null(^"Interactable") as Node3D):
		return _f18_verdict(false, "actual controller arch prompt: " + str(travel.failures))
	var kind := "portal_unlock" if mode == "unlock" else "portal_enter"
	var deadline := Time.get_ticks_msec() + 180000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var reply := _f18_latest(start, kind)
		if reply.is_empty(): continue
		var state := _f18_state(game, {})
		var disk: Dictionary = state.character_disk.get("redesign_character", {})
		var ok: bool = reply.get("ok") == true and reply.get("durable") == true and reply.get("character_id") == state.character_id
		if mode == "unlock":
			var receipt := str(reply.get("receipt", ""))
			ok = ok and not receipt.is_empty() and before.tidewake_key_count == 1 and state.tidewake_key_count == 0 \
				and state.character.portal_unlocks.has(id) and disk.get("portal_unlocks", []).has(id) \
				and disk.get("transaction_receipts", []).has(receipt) \
				and not before.character.get("transaction_receipts", []).has(receipt) \
				and _f18_stack_count(state.character_disk.get("inventory", []), "tidewake_portal_key") == 0
		else:
			var realm := str(args.get("realm", ""))
			ok = ok and reply.get("saved") == true and state.realm == realm and state.grounded == true \
				and _f18_disk_pose_at(state, realm, _f18_vector(state.position)) and F18_INPUT.current(self) == null
			if args.has("stone"):
				var stone := _f18_find_stone(str(args.stone))
				var target := F18_STONE.resolve_position(current_scene, stone.get("_row"), true) if stone != null else Vector3(INF, INF, INF)
				ok = ok and target.is_finite() and _f18_vector(state.position).distance_to(target) < 1.0
			if args.get("hall") == true:
				# Home-only home arch (STATE decision #11): the Hall's own home
				# arrival, at the anchor or one of its authored co-op slots.
				var at_hall := false
				for hall: Node in get_nodes_in_group("crossing_halls"):
					if _f18_at_arrival_slot(_f18_vector(state.position), hall.call("home_arrival")): at_hall = true
				ok = ok and at_hall
		state.observed_reply = reply
		return _f18_verdict(ok, "actual prompt " + mode + " requires bound durable reply and exact portable outcome", state)
	return _f18_verdict(false, "actual arch produced no authoritative outcome within bounded deadline", _f18_state(game, {}))

func _f18_latest(start: int, kind: String) -> Dictionary:
	for index in range(start, _f18_results.size()):
		if _f18_results[index].get("kind") == kind: return _f18_results[index]
	return {}

func _f18_stack_count(stacks: Array, item: String) -> int:
	var count := 0
	for stack: Variant in stacks:
		if stack is Dictionary and stack.get("id") == item: count += int(stack.get("n", 0))
	return count

func _f18_vector(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2])) if values.size() == 3 else Vector3(INF, INF, INF)

func _f18_disk_pose_at(state: Dictionary, realm: String, at: Vector3) -> bool:
	var pose: Dictionary = state.character_disk.get("player_pose", {})
	return pose.get("realm") == realm and _f18_vector(pose.get("position", [])).distance_to(at) < 0.5

func _f18_read(path: String) -> Dictionary:
	var raw: Variant = preload("res://scripts/save/save_document.gd").parse(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return raw if raw is Dictionary else {}

func _f18_state(game: Node, args: Dictionary) -> Dictionary:
	var local: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	var saver: RefCounted = game.get("save_system")
	var character: String = local.get("character_id")
	var target: String = str(args.get("character_id", character))
	var world_id: String = world.get("world_id")
	var character_path: String = saver.call("characters").call("path_for", character)
	var world_path: String = saver.call("worlds").call("path_for", world_id)
	var player := game.call("find_player") as CharacterBody3D
	var inventory: RefCounted = game.get("inventory")
	var admitted: Dictionary = {}
	for row: Dictionary in _session().call("peers"):
		if row.get("character_id") == target: admitted = _session().call("admitted_character_state", int(row.get("peer_id", 0)))
	var disk := _f18_read(world_path)
	# Compare native decoded Variants before the JSON verdict wire can round
	# doubles. A rounded report dictionary cannot prove immutable disk equality.
	var exact_rows := {}
	for id: String in world.get("reward_deliveries"):
		exact_rows[id] = preload("res://scripts/creatures/essence.gd")._equivalent(
			world.get("reward_deliveries")[id], disk.get("reward_deliveries", {}).get(id))
	var payload := {"character_id": character, "world_id": world_id,
		"world_instance": world.get("reward_delivery_namespace"), "realm": game.get("current_realm"),
		"position": [player.global_position.x, player.global_position.y, player.global_position.z] if player != null else [],
		"grounded": player != null and player.is_on_floor(), "character": local.get("redesign_character").duplicate(true),
		"world": world.get("redesign_world").duplicate(true), "world_disk": disk,
		"character_disk": _f18_read(character_path), "admitted": admitted,
		"deliveries": world.get("reward_deliveries").duplicate(true), "deliveries_disk_exact": exact_rows,
		"home_key_count": inventory.call("count", "home_key"), "tidewake_key_count": inventory.call("count", "tidewake_portal_key"),
		"tidewake_view": game.call("portal_view", "tidewake"), "runtime_enabled": _session().call("portal_runtime_ready")}
	# JSON normalizes int/float domains and makes verdict transport explicit.
	return JSON.parse_string(JSON.stringify(payload)) as Dictionary
