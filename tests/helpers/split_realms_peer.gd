extends "res://tools/net/peer_runner.gd"

## Transport-only setup: one Home Key and free-play opening flags before
## admission, plus Hall proximity/unlock context for fixed Cloudreach
## departures. The original party/deploy fixture is preserved. No earned F18
## credit. Production PortalArrival owns consumption, loading, capsule contact,
## journals and owner ACKs; this helper never installs its pending/remote rows.
var _split_fixture_done: bool = false
var _split_endpoint: Node
var _split_reply: Dictionary = {}
var _split_raw_refusal: String = ""
var _split_raw_proved: bool = false
var _split_raw_granted: bool = false
const SPLIT_INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SPLIT_LESSON := preload("res://scripts/onboarding/lesson_panel.gd")

class PermissionEndpoint extends Node:
	var runner: SceneTree
	var prepared: Dictionary = {}
	var used: Dictionary = {}
	var error: String = ""
	var evidence: Dictionary = {}
	var safety: Dictionary = {}

	func safety_snapshot(peer: int) -> Dictionary:
		var owner: Node = session()
		if owner.call("is_host") != true or owner.call("admitted_character_state", peer).is_empty(): return {}
		var context: Dictionary = owner.call("_host_portal_context", peer)
		if context.is_empty(): return {}
		return {"peer": peer, "character_id": context.character_id, "world_instance_id": context.world_instance_id,
			"session_epoch": owner.call("_altar_current_epoch"), "realm": context.realm,
			"combat": context.combat, "dialogue": context.dialogue, "cutscene": context.cutscene}

	@rpc("any_peer", "call_remote", "reliable", 0)
	func read_safety() -> void:
		var peer: int = multiplayer.get_remote_sender_id()
		if peer > 1 and session().call("is_host") == true: safety_observed.rpc_id(peer, safety_snapshot(peer))

	@rpc("authority", "call_remote", "reliable", 0)
	func safety_observed(value: Dictionary) -> void:
		if session().call("is_host") != true: safety = value.duplicate(true)

	func session() -> Node: return get_parent().get("session")

	@rpc("any_peer", "call_remote", "reliable", 0)
	func request_cloudreach() -> void:
		var owner: Node = session()
		var peer: int = multiplayer.get_remote_sender_id()
		if owner.call("is_host") == true and peer > 1:
			prepare_cloudreach(peer)

	func prepare_cloudreach(peer: int) -> void:
		var owner: Node = session()
		var game: Node = get_parent()
		if owner.call("is_host") != true or owner.call("portal_runtime_ready") != true \
				or owner.call("realm_of", peer) != "meadows" or used.has(peer): return
		var context: Dictionary = owner.call("_host_portal_context", peer)
		var arrival: Node = owner.get_node_or_null(^"FoundationComposition/PortalArrival")
		if context.is_empty() or arrival == null or not (arrival.get("_pending") as Dictionary).is_empty() \
				or (arrival.get("_remote") as Dictionary).has(peer):
			refuse(peer, "Actual source/arrival service is unavailable."); return
		# Only these two context fields are fixture facts. Identity, source,
		# position and all safety observations remain actual host observations.
		context = context.duplicate(true)
		context.arch_positions["cloudreach"] = context.position
		if not context.world_unlocks.has("cloudreach"): context.world_unlocks.append("cloudreach")
		var epoch: String = owner.call("_altar_current_epoch")
		var envelope: Dictionary = {"request_id": epoch + ":split-cloudreach:" + Crypto.new().generate_random_bytes(8).hex_encode(),
			"session_epoch": epoch, "character_id": context.character_id,
			"world_instance_id": context.world_instance_id, "payload": {"kind": "portal_enter", "arch_id": "cloudreach"}}
		var policy: RefCounted = owner.get("_portal_policy")
		policy.call("bind_world", context.world_instance_id)
		var result: Dictionary = policy.call("evaluate", envelope.payload, context,
			JSON.parse_string(FileAccess.get_file_as_string("res://data/config/portals.json")),
			JSON.parse_string(FileAccess.get_file_as_string("res://data/config/waystones.json")), Time.get_ticks_msec())
		if result.get("ok") != true or owner.call("_portal_envelope_valid", peer, envelope) != true:
			var observations: Array = []
			for director: Node in owner.call("_foundation_directors_under", owner.call("_foundation_realm_roots")):
				var arbiter: Variant = director.get("_encounter_host")
				var manager: Node = director.get("_manager")
				observations.append({"director": str(director.get_path()), "session_owned": director.get("_session") == owner,
					"arbiter_present": arbiter is RefCounted, "manager_fighting": manager.call("is_fighting") if manager != null else null})
			refuse(peer, str(result.get("reason", "Invalid actual owner envelope.")) + " [actual host combat observation: " \
				+ JSON.stringify({"peer": peer, "combat": context.get("combat"), "dialogue": context.get("dialogue"),
					"cutscene": context.get("cutscene"), "directors": observations}) + "]"); return
		used[peer] = true
		prepared[envelope.request_id] = {"peer": peer, "envelope": envelope, "result": result,
			"world": weakref(game.get("world")), "session": weakref(owner)}
		if peer == owner.call("local_peer_id"):
			if register_owner(envelope): begin_consumed(envelope.request_id)
			else: refuse(peer, "Host owner registration rejected its actual identity.")
		else: register_remote_owner.rpc_id(peer, envelope)

	func register_owner(envelope: Dictionary) -> bool:
		var owner: Node = session()
		var game: Node = get_parent()
		var actor: Node = game.call("find_player")
		if envelope.size() != 5 or envelope.get("payload") != {"kind": "portal_enter", "arch_id": "cloudreach"} \
				or envelope.get("character_id") != game.get("local").character_id \
				or envelope.get("world_instance_id") != game.get("world").reward_delivery_namespace \
				or envelope.get("session_epoch") != owner.call("_altar_current_epoch") \
				or not envelope.get("request_id") is String \
				or not envelope.request_id.begins_with(str(envelope.session_epoch) + ":split-cloudreach:") \
				or envelope.request_id.length() > 192 or game.get("current_realm") != "meadows" \
				or owner.call("realm_of", owner.call("local_peer_id")) != "meadows" \
				or actor == null or runner.current_scene == null or not runner.current_scene.is_ancestor_of(actor): return false
		var requests: Dictionary = owner.get("_portal_requests")
		if requests.has(envelope.request_id): return false
		# Disclosed request-registration fixture only; all production permit RPC
		# and arrival/save checks still require this exact owner envelope.
		requests[envelope.request_id] = envelope.duplicate(true)
		return true

	@rpc("authority", "call_remote", "reliable", 0)
	func register_remote_owner(envelope: Dictionary) -> void:
		if session().call("is_host") == true: return
		if not register_owner(envelope): error = "Owner registration rejected its actual identity."; return
		owner_registered.rpc_id(1, str(envelope.request_id))

	@rpc("any_peer", "call_remote", "reliable", 0)
	func owner_registered(request: String) -> void:
		var row: Dictionary = prepared.get(request, {})
		if session().call("is_host") == true and not row.is_empty() and row.peer == multiplayer.get_remote_sender_id():
			begin_consumed(request)

	func begin_consumed(request: String) -> void:
		var row: Dictionary = prepared.get(request, {})
		var owner: Node = session()
		if row.is_empty() or row.session.get_ref() != owner or row.world.get_ref() != get_parent().get("world") \
				or owner.call("_portal_envelope_valid", row.peer, row.envelope) != true: return
		prepared.erase(request) # An ACK cannot invoke the consumer twice.
		var arrival: Node = owner.get_node(^"FoundationComposition/PortalArrival")
		arrival.call("travel", owner, row.peer, row.envelope, row.result)
		var original: Dictionary = arrival.get("_pending") if row.peer == owner.call("local_peer_id") \
			else (arrival.get("_remote") as Dictionary).get(row.peer, {})
		if original.is_empty() or original.envelope != row.envelope or original.permit.get("realm") != "cloudreach" \
				or original.permit.get("origin_realm") != "meadows" \
				or not (owner.get("_portal_policy").call("consume_permit", original.permit.request_id,
				row.peer, row.envelope.character_id, row.envelope.world_instance_id, "meadows") as Dictionary).is_empty():
			refuse(row.peer, "Production consumer did not retain exactly one consumed permission."); return
		evidence = {"fixture": "fixed Cloudreach Hall proximity/world unlock context and owner request registration",
			"request_id": request, "permit_id": original.permit.request_id, "mover": row.peer,
			"host_local_pending": row.peer == owner.call("local_peer_id"), "consumed_once": true, "earned_credit": false}
		if row.peer != owner.call("local_peer_id"): permission_evidence.rpc_id(row.peer, evidence)

	@rpc("authority", "call_remote", "reliable", 0)
	func permission_evidence(value: Dictionary) -> void:
		if session().call("is_host") != true: evidence = value.duplicate(true)

	func refuse(peer: int, reason: String) -> void:
		if peer == session().call("local_peer_id"): error = reason
		else: permission_refused.rpc_id(peer, reason)

	@rpc("authority", "call_remote", "reliable", 0)
	func permission_refused(reason: String) -> void: error = reason

func _execute_step(msg: Dictionary) -> Dictionary:
	if msg.get("action") != "split_realms_permission_fixture": return await super._execute_step(msg)
	var game: Node = root.get_node(^"Game")
	if _split_fixture_done or _session().call("is_active") == true or _session().call("portal_runtime_ready") != true:
		return {"verdict": "FAIL", "detail": "transport fixture requires fresh disconnected shipping runtime"}
	var local: RefCounted = game.get("local")
	local.get("flags").call("set_flag", "opening:beat:free_play", true)
	local.get("flags").call("set_flag", "opening:starter_granted", true)
	if game.get("inventory").call("count", "home_key") != 0 or game.get("inventory").call("add", "home_key", 1) != 0:
		return {"verdict": "FAIL", "detail": "cannot add one disclosed pre-admission Home Key"}
	local.get("flags").call("set_flag", "home_key_given", true)
	for node: Node in get_nodes_in_group("progression_restore"):
		if node.has_method("restore_progression_from_game"): node.call("restore_progression_from_game", game)
	for frame in 30: await physics_frame
	# The fixture can naturally trigger Grandpa's real Home Key teaching card.
	# Read/acknowledge it before the existing save; never seed lesson flags.
	var teaching: Dictionary = await _split_settle_presentation(Engine.get_physics_frames(), 180, true)
	if teaching.get("verdict") != "PASS": return teaching
	if game.get("save_system").call("save_character", game, str(local.character_id)) != true:
		return {"verdict": "FAIL", "detail": "pre-admission Home Key fixture could not save"}
	var endpoint := PermissionEndpoint.new()
	endpoint.name = "SplitRealmsPermissionFixture"
	endpoint.runner = self
	game.add_child(endpoint)
	_split_endpoint = endpoint
	_split_fixture_done = true
	game.connect("portal_action_result", func(reply: Dictionary) -> void:
		if reply.get("kind") in ["portal_enter", "home_key_finish"]: _split_reply = reply.duplicate(true))
	return {"verdict": "PASS", "detail": "DISCLOSED transport-only pre-admission Home Key, free-play/starter flags and observers; fixed Cloudreach permission context; original party/deploy fixture unchanged; no earned F18 credit; actual teaching: " + JSON.stringify(teaching.data)}

func _split_note_raw_refusal() -> void:
	var transition: Node = _session().get("realm_transition")
	var pending: Dictionary = transition.get("_local")
	if pending.has("token"): _split_raw_granted = true
	if not str(pending.get("error", "")).is_empty(): _split_raw_refusal = str(pending.error)

func _split_inventory() -> Array:
	var inventory: RefCounted = root.get_node(^"Game").get("inventory")
	var slots: Array = []
	for index in int(inventory.call("slot_count")): slots.append(inventory.call("stack_at", index))
	return slots

func _split_presentation_observation() -> Dictionary:
	var game: Node = root.get_node(^"Game")
	var holder: Node = SPLIT_INPUT_OWNER.current(self)
	var service: Node = game.get_node_or_null(^"OnboardingLessons")
	var lesson: Node = service.get("_panel") if service != null else null
	var recognized: bool = holder != null and holder == lesson and holder.get_script() == SPLIT_LESSON \
		and holder.call("is_open") == true and service.get("_identity") == game.get("local").character_id \
		and holder.get("_row").get("id") == "home_key" and holder.get("_row").get("conversation") == "lesson_home_key"
	var fades: Array[String] = []
	for node: Node in get_nodes_in_group("progression_restore"):
		if current_scene != null and current_scene.is_ancestor_of(node) and node.has_method("is_fading") and node.call("is_fading") == true:
			fades.append(str(node.get_path()))
	var lifecycle: Node = _session().get_node_or_null(^"FoundationComposition/TravelLifecycle")
	var sample: Dictionary = lifecycle.call("local_sample") if lifecycle != null else {}
	return {"holder": str(holder.get_path()) if holder != null else "", "script": holder.get_script().resource_path if holder != null and holder.get_script() != null else "",
		"lesson_id": str(lesson.get("_row").get("id", "")) if holder != null and holder == lesson and holder.get_script() == SPLIT_LESSON else "",
		"recognized_home_key_lesson": recognized, "lesson_line": int(lesson.get("_line")) if recognized else -1,
		"lesson_text": str(lesson.get("_text").get("text")) if recognized else "", "fades": fades,
		"dialogue": sample.get("dialogue"), "cutscene": sample.get("cutscene")}

func _split_settle_presentation(started_frame: int, budget: int, before_admission: bool = false) -> Dictionary:
	var source: Node = current_scene
	var owner: Node = _session()
	var presses: Array[Dictionary] = []
	var observation: Dictionary = {}
	while Engine.get_physics_frames() - started_frame <= budget:
		if current_scene != source or _session() != owner: return {"verdict": "FAIL", "detail": "actual source/session changed during teaching"}
		observation = _split_presentation_observation()
		if observation.recognized_home_key_lesson == true:
			presses.append(observation.duplicate(true))
			# Ordinary paired action edges enter the real panel's _input handler.
			for pressed: bool in [true, false]:
				var event := InputEventAction.new()
				event.action = "menu_confirm"
				event.pressed = pressed
				Input.parse_input_event(event)
				for frame in 4: await process_frame
		elif observation.holder == "" and observation.fades.is_empty() \
			and (before_admission or (observation.cutscene == false and observation.dialogue == false)):
			var service: Node = root.get_node(^"Game").get_node_or_null(^"OnboardingLessons")
			if service == null or not (service.get("_pending") as Dictionary).has("opening:lesson:home_key"):
				return {"verdict": "PASS", "data": {"menu_confirm_presses": presses, "actual_local_presentation": observation}}
		await physics_frame
	return {"verdict": "FAIL", "detail": "actual presentation did not settle within unchanged budget: " + JSON.stringify({"menu_confirm_presses": presses, "actual_local_presentation": observation})}

func _split_wait_host_safety(started_frame: int, budget: int) -> Dictionary:
	var owner: Node = _session()
	var game: Node = root.get_node(^"Game")
	var actual: Dictionary = {}
	while Engine.get_physics_frames() - started_frame <= budget:
		_split_endpoint.set("safety", {})
		if owner.call("is_host") == true: actual = _split_endpoint.call("safety_snapshot", owner.call("local_peer_id"))
		else:
			_split_endpoint.rpc_id(1, "read_safety")
			for frame in 12:
				if Engine.get_physics_frames() - started_frame > budget: break
				await physics_frame
			actual = _split_endpoint.get("safety")
		if actual.get("peer") == owner.call("local_peer_id") and actual.get("character_id") == game.get("local").character_id \
			and actual.get("world_instance_id") == game.get("world").reward_delivery_namespace and actual.get("session_epoch") == owner.call("_altar_current_epoch") \
			and actual.get("realm") == game.get("current_realm") and actual.get("combat") == false \
			and actual.get("dialogue") == false and actual.get("cutscene") == false: return {"verdict": "PASS", "data": actual}
		await physics_frame
	return {"verdict": "FAIL", "detail": "unchanged host safety never settled within original travel budget: " + JSON.stringify({"actual_host": actual, "actual_local": _split_presentation_observation()})}

func _split_settle_combat(started_frame: int, budget: int) -> Dictionary:
	var owner: Node = _session()
	var manager: Node = _combat_manager()
	var source: Node = current_scene
	if manager == null: return {"verdict": "FAIL", "detail": "actual local combat observer is unavailable"}
	var was_fighting: bool = manager.call("is_fighting") == true
	if was_fighting:
		# Either owner may already be fighting. Use the inherited ordinary
		# wild-fight exit; never clear manager state or any host encounter row.
		var fled: Dictionary = await _step_press({"action": "combat_run"})
		if fled.get("verdict") != "PASS": return fled
	while Engine.get_physics_frames() - started_frame <= budget:
		if not is_instance_valid(manager) or current_scene != source or _session() != owner:
			return {"verdict": "FAIL", "detail": "actual source/session changed while settling combat"}
		var observed_combat: bool = owner.call("_altar_peer_in_combat", owner.call("local_peer_id")) == true
		if manager.call("is_fighting") != true and not observed_combat:
			if was_fighting: print("SPLIT_TRANSPORT_COMBAT_SETTLED " + JSON.stringify({"peer": owner.call("local_peer_id"), "input": "combat_run", "manager_fighting": false, "observed_combat": false}))
			return {"verdict": "PASS", "detail": "actual local manager and combat observation settled before travel setup",
				"data": {"was_fighting": was_fighting, "input": "combat_run" if was_fighting else "none", "manager_fighting": false, "observed_combat": false}}
		await physics_frame
	return {"verdict": "FAIL", "detail": "ordinary fight departure and actual combat observation did not settle within original travel budget"}

func _step_enter_realm(args: Dictionary) -> Dictionary:
	if not _split_fixture_done: return await super._step_enter_realm(args)
	var game: Node = root.get_node(^"Game")
	var realm: String = str(args.get("realm", ""))
	var was: String = str(game.get("current_realm"))
	var budget: int = maxi(1, int(args.get("budget_frames", 6000)))
	var started_frame: int = Engine.get_physics_frames()
	if not ((was == "meadows" and realm == "cloudreach") or (was == "cloudreach" and realm == "meadows")):
		return {"verdict": "FAIL", "detail": "transport fixture allows only the original split-realm boundaries"}
	if not _split_raw_proved and _session().call("is_host") != true:
		var source: Node = current_scene
		var actor: Node = game.call("find_player")
		var inventory: Array = _split_inventory()
		process_frame.connect(_split_note_raw_refusal)
		var raw: Dictionary = await super._step_enter_realm(args)
		process_frame.disconnect(_split_note_raw_refusal)
		if raw.get("verdict") != "FAIL" or _split_raw_granted or not _split_raw_refusal.contains("Crossing Hall portals") \
				or current_scene != source or game.call("find_player") != actor or game.get("current_realm") != was \
				or _session().call("realm_of", _session().call("local_peer_id")) != was \
				or _split_inventory() != inventory:
			return {"verdict": "FAIL", "detail": "raw Game entry must visibly refuse without source drain", "data": raw}
		_split_raw_proved = true
		print("SPLIT_TRANSPORT_RAW_REFUSAL " + JSON.stringify({"reason": _split_raw_refusal, "source_unchanged": true, "inventory_unchanged": true, "accepted_permit": false}))
	# Keep the first raw refusal before all preparation. Both the fixed arch
	# departure and actual Home Key return require the same real safety state.
	var settled: Dictionary = await _split_settle_combat(started_frame, budget)
	if settled.get("verdict") != "PASS": return settled
	var presentation: Dictionary = await _split_settle_presentation(started_frame, budget)
	if presentation.get("verdict") != "PASS": return presentation
	var host_safety: Dictionary = await _split_wait_host_safety(started_frame, budget)
	if host_safety.get("verdict") != "PASS": return host_safety
	_split_reply.clear()
	_split_endpoint.set("error", "")
	_split_endpoint.set("evidence", {})
	if realm == "cloudreach":
		if _session().call("is_host") == true:
			_split_endpoint.call("prepare_cloudreach", _session().call("local_peer_id"))
		else: _split_endpoint.rpc_id(1, "request_cloudreach")
	else:
		if game.call("use_home_key") != true: return {"verdict": "FAIL", "detail": "actual fixture Home Key refused: " + str(game.call("home_key_refusal"))}
	var wanted: String = str(REALM_ROOT_NAMES.get(realm, ""))
	while Engine.get_physics_frames() - started_frame <= budget:
		await physics_frame
		if not str(_split_endpoint.get("error")).is_empty():
			return {"verdict": "FAIL", "detail": str(_split_endpoint.get("error")) + " [actual local combat observation: " + JSON.stringify(settled.data) + "] [actual presentation: " + JSON.stringify(presentation.data) + "] [actual host safety: " + JSON.stringify(host_safety.data) + "]"}
		if _split_reply.get("ok") == false: return {"verdict": "FAIL", "detail": _split_reply.get("reason", "production arrival refused")}
		if _split_reply.get("ok") != true: continue
		var permission: Dictionary = _split_endpoint.get("evidence")
		if realm == "cloudreach" and permission.is_empty(): continue
		if _split_reply.get("kind") != ("portal_enter" if realm == "cloudreach" else "home_key_finish") \
				or _split_reply.get("character_id") != game.get("local").character_id \
				or _split_reply.get("world_instance_id") != game.get("world").reward_delivery_namespace \
				or _split_reply.get("session_epoch") != _session().call("_altar_current_epoch") \
				or (realm == "cloudreach" and (_split_reply.get("request_id") != permission.get("request_id") \
					or _split_reply.get("permit_id") != permission.get("permit_id"))):
			return {"verdict": "FAIL", "detail": "arrival result must match the actual owner and original consumed permission"}
		var world: Node = root.get_node_or_null(NodePath(wanted))
		var body: CharacterBody3D = game.call("find_player")
		if game.get("current_realm") != realm or world != current_scene or world == null \
				or (world.has_method("shell_build_complete") and world.call("shell_build_complete") != true): continue
		if _split_reply.get("saved") != true or _split_reply.get("durable") != true \
				or body == null or not body.is_on_floor() or not body.is_physics_processing() \
				or not world.is_ancestor_of(body) or game.get("inventory").call("count", "home_key") != 1:
			return {"verdict": "FAIL", "detail": "actual grounded capsule arrival and owner/world saves required", "data": _split_reply}
		_scene_name = str(REALM_SCENE_NAMES.get(realm, _scene_name))
		for frame in int(args.get("settle_frames", DEFAULT_SETTLE_FRAMES)): await physics_frame
		if Engine.get_physics_frames() - started_frame > budget: break
		return {"verdict": "PASS", "detail": "production consumed-permit arrival '%s' -> '%s'; real receiver/capsule and durable owner ACK, no earned credit" % [was, realm],
			"data": {"reply": _split_reply, "permission": _split_endpoint.get("evidence"), "raw_refusal": _split_raw_refusal, "combat": settled.data,
				"presentation": presentation.data, "host_safety": host_safety.data,
				"orchestration": "PortalArrival invokes original Game.enter_realm; inherited receiver/shell/heartbeat machinery unchanged"}}
	return {"verdict": "FAIL", "detail": "production consumed-permit arrival exceeded original %d-physics-frame budget" % budget}
