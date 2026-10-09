extends RefCounted

const NAV := preload("res://tests/helpers/stick_navigator.gd")
const CARE := preload("res://tests/helpers/meadows_earned_team_segment.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const HOME := preload("res://scripts/story/regional_homecoming.gd")
var tree: SceneTree
var game: Node
var failures: Array[String] = []
var _player: CharacterBody3D
var _rig: Node3D
var _activated: Object
var _home_result: Dictionary = {}
var home_key_observation: Dictionary = {}
var last_approach: Dictionary = {}
var _enter_binding: Dictionary = {}
var _enter_result: Dictionary = {}

func _init(owner: SceneTree, actual_game: Node) -> void:
	tree = owner
	game = actual_game

func _fail(message: String) -> bool:
	failures.append(message)
	return false

func _bind() -> bool:
	if tree.current_scene == null: return _fail("F49 travel has no retained world")
	_player = tree.current_scene.get_node_or_null("Player") as CharacterBody3D
	_rig = tree.current_scene.get_node_or_null("CameraRig") as Node3D
	return (_player != null and _rig != null and INPUT_OWNER.current(tree) == null \
		and game.party.size() > 0 and game.party.size() <= 5 and game.pending_catch == null) \
		or _fail("F49 travel requires ordinary world input and one to five actually owned creatures (input owner %s, party %d, pending catch %s, session hold '%s')" % [
			str(INPUT_OWNER.current(tree)), game.party.size(), str(game.pending_catch != null),
			str(game.session.call("_owner_snapshot_block_reason", game.local)) if game.get("session") != null and game.session.has_method("_owner_snapshot_block_reason") else "-"])

func _uids() -> Array[String]:
	var out: Array[String] = []
	for member: RefCounted in game.party.members(): out.append(str(member.get("uid")))
	return out

func home_key() -> bool:
	_home_result = {}
	home_key_observation = {"replies": [], "snapshots": [],
		"immediate_use_return_source": "HOME KEY SATCHEL USE event; not inferred from arrival."}
	if not game.has_signal("portal_action_result"):
		return _fail("F49 missing producer: Game has no authoritative portal result signal")
	game.connect("portal_action_result", _portal_result)
	var passed := await _use_home_key()
	_observe_home_key("terminal")
	home_key_observation["passed"] = passed
	game.disconnect("portal_action_result", _portal_result)
	return passed

func _portal_result(result: Dictionary) -> void:
	if not home_key_observation.is_empty() and result.get("kind") in ["home_key_begin", "home_key_cancel", "home_key_finish"]:
		var reply := {}
		for field: String in ["kind", "ok", "reason", "code", "request_id", "use_id", "permit_id",
				"character_id", "world_instance_id", "session_epoch", "saved", "durable", "settled", "arrived", "arrival_applied", "cancelled"]:
			if result.has(field): reply[field] = result[field]
		home_key_observation.replies.append(reply)
		print("F49 HOME KEY REPLY " + JSON.stringify(reply))
	if result.get("kind") == "home_key_finish": _home_result = result.duplicate(true)
	# Game emits only Session-authenticated replies. Bind this observer to the
	# exact request queued by the actual arch, rather than scene/menu readiness.
	if result.get("kind") != "portal_enter" or _enter_binding.is_empty(): return
	for field: String in ["request_id", "character_id", "world_instance_id", "session_epoch"]:
		if not _enter_binding.has(field) or result.get(field) != _enter_binding[field]: return
	_enter_result = result.duplicate(true)

func _use_home_key() -> bool:
	if not _bind(): return false
	var before := _uids()
	var inventory: RefCounted = game.get("inventory")
	var slot := int(inventory.call("find_slot", "home_key"))
	if slot < 0: return _fail("F49 missing producer: Grandpa's actual opening did not deliver the personal Home Key")
	if not str(game.call("home_key_refusal")).is_empty():
		return _fail("F49 Home Key refused in the actual position: " + str(game.call("home_key_refusal")))
	var key: Node = game.get_node_or_null("HomeKey")
	if key == null: return _fail("F49 Home Key lacks its production presentation owner")
	var refusal_before: float = float(key.get("_refusal_at"))
	var binding := {"character_id": str(game.local.character_id),
		"world_instance_id": str(game.world.reward_delivery_namespace),
		"session_epoch": str(game.session.call("_altar_current_epoch"))}
	await tap("inventory")
	var menu: Node = game.call("menu")
	if menu == null or not menu.call("is_open") or menu.call("current_tab_id") != "backpack":
		return _fail("F49 inventory input did not open the actual Satchel")
	var backpack: Node = (menu.get("_bodies") as Array)[0]
	var care := CARE.new()
	care.set("_tree", tree)
	if not await care.call("_focus_slot", backpack.get("_buttons"), slot):
		return _fail("F49 controller focus could not reach the actual Home Key")
	# Production Satchel Use must close the menu and route to HomeKey.use().
	# This deliberately exposes the currently missing shared input producer.
	_observe_home_key("before_satchel_use")
	await tap("interact")
	_observe_home_key("after_satchel_use")
	for frame in 7200:
		await tree.process_frame
		# A local refusal resets the approved raise before a finish request.
		# Retain failure instead of waiting for a reply that cannot be produced.
		var approved_begin := false
		for reply: Dictionary in home_key_observation.replies:
			if reply.get("kind") == "home_key_begin" and reply.get("ok") == true \
				and reply.get("character_id") == binding.character_id \
				and reply.get("world_instance_id") == binding.world_instance_id \
				and reply.get("session_epoch") == binding.session_epoch \
				and not str(reply.get("request_id", "")).is_empty() and not str(reply.get("use_id", "")).is_empty():
				approved_begin = true
		if approved_begin and is_instance_valid(key) and game.get_node_or_null("HomeKey") == key \
			and key.get("_phase") == "idle" and float(key.get("_refusal_at")) > refusal_before:
			var label: Label = key.get("_refusal_label") as Label
			if is_instance_valid(label) and not label.text.is_empty():
				_observe_home_key("local_terminal_refusal")
				return _fail("F49 Home Key approved raise ended with a new local refusal: " + label.text)
		if not _home_result.is_empty() and _home_result.get("ok") != true:
			return _fail("F49 Home Key authoritative refusal: " + str(_home_result.get("reason")))
		if _home_result.get("ok") == true and _ready_world("meadows"):
			return _uids() == before and int(inventory.call("count", "home_key")) == 1 \
				or _fail("F49 actual Home Key return changed the party or lost/duplicated its key")
		if frame == 120 and menu.call("is_open"):
			return _fail("F49 missing producer: Satchel Use did not route the earned Home Key to its production owner")
		if frame % 300 == 299: _print_home_key_wait(frame)
	return _fail("F49 actual Home Key return never reached the ready home arch")

func enter(arch_id: String, realm: String) -> bool:
	if not _bind() or str(game.current_realm) != "meadows":
		return _fail("F49 portals must be approached from the actual Home Key return")
	var arch: Node3D
	for candidate: Node in tree.get_nodes_in_group("portal_arches"):
		if candidate.get("arch_id") == arch_id: arch = candidate as Node3D
	if arch == null: return _fail("F49 missing producer: authored Hall has no live " + arch_id + " arch")
	var view: Dictionary = game.call("portal_view", arch_id)
	if view.get("ready") != true or view.get("has_key") != true or view.get("character_open") == true:
		return _fail("F49 missing earned boss-key delivery for still-locked personal arch " + arch_id)
	var before := _uids()
	var prompt := arch.get_node_or_null("Interactable") as Node3D
	if not _recommended_sign(arch_id, prompt, view, "before_unlock"): return false
	if not await activate(prompt): return false
	for frame in 720:
		await tree.process_frame
		view = game.call("portal_view", arch_id)
		if view.get("character_open") == true: break
	if view.get("character_open") != true or view.get("has_key") == true:
		return _fail("F49 actual arch Use did not durably consume exactly the earned key: " + arch_id)
	if not _recommended_sign(arch_id, prompt, view, "after_unlock"): return false
	return await _enter_open_arch(arch, prompt, realm, before)

## Disclosed journal/revisit callers may already own this personal unlock.
## Keep enter()'s fresh earned-key gate intact and share its terminal arrival
## proof rather than accepting scene readiness after an authority refusal.
func enter_unlocked(arch_id: String, realm: String) -> bool:
	if not _bind() or str(game.current_realm) != "meadows":
		return _fail("Already-open portals require the actual Hall world and input")
	var arch: Node3D
	for candidate: Node in tree.get_nodes_in_group("portal_arches"):
		if candidate.get("arch_id") == arch_id: arch = candidate as Node3D
	var view: Dictionary = game.call("portal_view", arch_id)
	if arch == null or view.get("ready") != true or view.get("character_open") != true:
		return _fail("Already-open Enter requires this character's actual durable unlock: " + arch_id)
	var prompt := arch.get_node_or_null("Interactable") as Node3D
	if not _recommended_sign(arch_id, prompt, view, "already_open"): return false
	return await _enter_open_arch(arch, prompt, realm, _uids())

func _enter_open_arch(arch: Node3D, prompt: Node3D, realm: String, before: Array[String]) -> bool:
	if not game.has_signal("portal_action_result"):
		return _fail("F49 missing producer: Game has no authoritative portal result signal")
	_enter_result = {}
	_enter_binding = {"character_id": game.local.character_id,
		"world_instance_id": game.world.reward_delivery_namespace,
		"session_epoch": game.session.call("_altar_current_epoch")}
	# PortalArch's own activated listener queues the request first. Observe
	# that actual request ID before its deferred authority reply/scene swap.
	var bind_request := func() -> void: _enter_binding.request_id = str(arch.get("_pending"))
	prompt.connect("activated", bind_request)
	game.connect("portal_action_result", _portal_result)
	var activated := await activate(prompt)
	if is_instance_valid(prompt) and prompt.is_connected("activated", bind_request):
		prompt.disconnect("activated", bind_request)
	var passed := false
	if activated and not str(_enter_binding.get("request_id", "")).is_empty():
		for frame in 7200:
			await tree.process_frame
			if _enter_result.is_empty(): continue
			if _enter_result.get("ok") != true:
				_fail("F49 portal Enter authoritative refusal: " + str(_enter_result.get("reason")))
				break
			if _enter_result.get("saved") != true or _enter_result.get("durable") != true \
					or _enter_result.get("arrived") != true or _enter_result.get("arrival_applied") != true \
					or str(_enter_result.get("permit_id", "")).is_empty():
				_fail("F49 portal Enter did not confirm its saved, durable grounded arrival")
				break
			if _ready_world(realm):
				passed = _uids() == before or _fail("F49 actual portal travel changed the carried party")
				break
		if not passed and _enter_result.is_empty():
			_fail("F49 portal Enter never confirmed the saved arrival in " + realm)
		elif not passed and failures.is_empty():
			_fail("F49 portal Enter never produced the ready " + realm + " scene")
	elif activated:
		_fail("F49 actual arch Enter did not queue a correlated travel request")
	game.disconnect("portal_action_result", _portal_result)
	if passed: print("F18 PORTAL ENTER ARRIVAL " + JSON.stringify(_enter_result))
	_enter_binding = {}
	return passed

func _recommended_sign(arch_id: String, prompt: Node3D, view: Dictionary, phase: String) -> bool:
	var expected: int = {"tidewake": 20, "cloudreach": 31, "stormwood": 42}.get(arch_id, 0)
	var label := str(prompt.get("label")) if prompt != null else ""
	if expected == 0 or int(view.get("recommended_level", 0)) != expected \
		or not label.contains("Recommended Lv %d" % expected):
		return _fail("F19 actual portal recommendation missing or out of chapter order at " + arch_id + ":" + phase)
	print("F19 PORTAL SIGN " + JSON.stringify({"arch": arch_id, "phase": phase,
		"recommended_level": expected, "label": label, "party": _uids()}))
	return true

func hang_relic(biome: String) -> bool:
	if not _bind(): return false
	var pedestal: Node3D
	for candidate: Node in tree.get_nodes_in_group("crossing_hall_pedestals"):
		if candidate.get_meta("biome", "") == biome: pedestal = candidate as Node3D
	if pedestal == null: return _fail("F49 missing producer: authored Shrine Room has no " + biome + " pedestal")
	var prompt: Node3D
	for child: Node in pedestal.find_children("*", "", true, false):
		if child.has_method("interaction_offer"): prompt = child as Node3D
	if prompt == null: return _fail("F49 missing producer: Shrine Room pedestal has display geometry but no ordinary relic-hanging interaction")
	var before := _uids()
	if not await activate(prompt): return false
	for frame in 720:
		await tree.process_frame
		var character: Dictionary = game.local.get("redesign_character")
		if (character.get("relics_hung", []) as Array).has(biome):
			return _uids() == before or _fail("F49 relic hanging changed the actual party")
	return _fail("F49 relic hanging produced no actual portable relics_hung state")

## Stored operands only: no policy getters, admission recovery or UI factories.
func _observe_home_key(phase: String) -> void:
	var scene := tree.current_scene
	var menu: Node = game.get("_menu")
	var session: Node = game.get("session")
	var key := game.get_node_or_null(^"HomeKey")
	var row := {"phase": phase, "paused": tree.paused,
		"menu_open": menu != null and menu.get("_open") == true,
		"menu_closing_action": str(menu.get("_closing_action")) if menu != null else "",
		"realm": str(game.current_realm), "pending_entry": str(game.pending_realm_entry),
		"scene": str(scene.get_path()) if scene != null else "",
		"home_key_present": key != null, "session": {}}
	var input_owner: Node = INPUT_OWNER.current(tree)
	row["input_owner"] = _stored_modal_observation(input_owner) if input_owner != null else {}
	row["story_modals"] = []
	for modal: Node in tree.get_nodes_in_group("story_modal"):
		row.story_modals.append(_stored_modal_observation(modal))
	if is_instance_valid(_player): row["player_position"] = str(_player.global_position)
	if key != null:
		row["key"] = {}
		var label: Label = key.get("_refusal_label")
		row.key["last_refusal_text"] = label.text if is_instance_valid(label) else ""
		for field: String in ["_phase", "_pending", "_use_id", "_elapsed", "_wait", "_fade_locked", "_closing_edge"]:
			row.key[field] = key.get(field)
	if session != null:
		row.session = {"mode": session.get("_mode"),
			"preparing_client": session.get("_preparing_client"),
			"snapshot": (session.get("_box") as Dictionary).get("snapshot"),
			"host_epoch": session.get("_altar_epoch"),
			"received_host_epoch": session.get("_altar_host_epoch"), "queued_requests": []}
		for request: Variant in (session.get("_portal_requests") as Dictionary).values():
			if request is Dictionary and request.get("payload", {}).get("kind", "") in ["home_key_begin", "home_key_finish", "home_key_cancel"]:
				var queued := {}
				for field: String in ["request_id", "character_id", "world_instance_id", "session_epoch"]:
					if request.has(field): queued[field] = request[field]
				queued["payload"] = {}
				for field: String in ["kind", "use_id"]:
					if request.payload.has(field): queued.payload[field] = request.payload[field]
				row.session.queued_requests.append(queued)
	home_key_observation.snapshots.append(row)
	print("F49 HOME KEY OPERANDS " + JSON.stringify(row))

## Pure stored operands, including the actual conversation if still present.
func _stored_modal_observation(node: Node) -> Dictionary:
	var script: Script = node.get_script() as Script
	var row := {"path": str(node.get_path()), "script": script.resource_path if script != null else ""}
	for property: Dictionary in node.get_property_list():
		var name: String = str(property.name)
		if name in ["_open", "_line", "_guard", "_closing_interact"]: row[name] = node.get(name)
		elif name == "_runner":
			var runner: RefCounted = node.get(name) as RefCounted
			if runner != null:
				row["conversation"] = {"id": runner.get("_id"), "line": runner.get("_index"), "active": runner.get("_active")}
	return row

## Diagnostic only: which readiness condition a long Home Key wait is on.
func _print_home_key_wait(frame: int) -> void:
	var owner := INPUT_OWNER.current(tree)
	print("F49 HOME WAIT frame=%d result=%s realm=%s pending_entry='%s' scene_ready=%s owner=%s" % [frame,
		str(_home_result.get("ok", "none")), str(game.current_realm), str(game.pending_realm_entry),
		str(tree.current_scene != null and bool(game.call("_realm_scene_ready", tree.current_scene, "meadows"))),
		str(owner.get_path()) if owner != null else "none"])

func _ready_world(realm: String) -> bool:
	return tree.current_scene != null and str(game.current_realm) == realm \
		and str(game.pending_realm_entry).is_empty() \
		and bool(game.call("_realm_scene_ready", tree.current_scene, realm)) \
		and INPUT_OWNER.current(tree) == null

## Station craft (F31#2 relic power): the ordinary capsule walk to a Shrine
## Room pedestal, stopping inside the host's interaction radius without Use.
func walk_to_pedestal(biome: String) -> bool:
	if not _bind(): return false
	var pedestal: Node3D
	for candidate: Node in tree.get_nodes_in_group("crossing_hall_pedestals"):
		if candidate.get_meta("biome", "") == biome: pedestal = candidate as Node3D
	if pedestal == null: return _fail("F49 missing producer: authored Shrine Room has no " + biome + " pedestal")
	var nav := NAV.new(tree, _player, _rig, _stick)
	var distance := _player.global_position.distance_to(pedestal.global_position)
	if not await nav.walk_to(pedestal.global_position, maxi(1200, int(distance * 65.0)), 2.5):
		_stick(0, 0)
		return _fail("F49 ordinary capsule walk failed to the " + biome + " pedestal")
	_stick(0, 0)
	for frame in 30: await tree.physics_frame # The host samples the replicated body.
	var radius := float(preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json").arch.interaction_radius_m)
	distance = _player.global_position.distance_to(pedestal.global_position)
	return distance <= radius or _fail("F49 walk stopped %.2f m from the %s pedestal (radius %.1f m)" % [distance, biome, radius])

func activate(prompt: Node3D, approach_headings: Array[Vector3] = []) -> bool:
	last_approach = {}
	if prompt == null or not _bind(): return _fail("F49 lacks the actual interaction provider")
	var arbiter: Node = tree.current_scene.get_node_or_null("InteractionArbiter")
	if arbiter == null: return _fail("F49 lacks the actual interaction arbiter")
	var nav := NAV.new(tree, _player, _rig, _stick)
	var distance := _player.global_position.distance_to(prompt.global_position)
	var recoveries_before := int(_player.get("_unstick_count"))
	var start := _player.global_position
	var budget := maxi(1200, int(distance * 65.0))
	# Original navigator retains capsule probes, confined watchdog and support
	# tests. No floor snap, shape waiver, target relocation or budget relaxation.
	var arrived := false
	# Shrine stands are only three metres apart. A generic 2.5m arrival
	# can offer this relic while a neighbour still owns Interact. Walk closer
	# with the same navigator and budget; exact ownership remains required.
	var close_enough := 1.0 if prompt.get_parent().is_in_group("crossing_hall_pedestals") else 2.5
	if approach_headings.is_empty():
		arrived = await nav.walk_to(prompt.global_position, budget, close_enough)
	else:
		arrived = await nav.walk_to_guided(prompt.global_position, budget, close_enough, approach_headings)
	last_approach = {"phase": "portal_approach", "provider": str(prompt.get_path()), "start": str(start),
		"target": str(prompt.global_position), "end": str(_player.global_position), "arrived": arrived,
		"grounded": _player.is_on_floor(), "can_walk": nav.can_walk(), "original_frame_budget": budget,
		"unstick_count_before": recoveries_before, "unstick_count_after": int(_player.get("_unstick_count")),
		"confined_resets": nav.confined_resets(), "headings": approach_headings.map(func(point: Vector3) -> String: return str(point))}
	if not arrived:
		var slide_colliders: Array[String] = []
		if is_instance_valid(_player):
			for index: int in _player.get_slide_collision_count():
				var collision := _player.get_slide_collision(index)
				if collision == null: continue
				var collider: Object = collision.get_collider()
				if is_instance_valid(collider) and collider is Node:
					slide_colliders.append(str((collider as Node).get_path()))
		last_approach["terminal_slide_colliders"] = slide_colliders
		last_approach["current_scene"] = str(tree.current_scene.get_path()) if is_instance_valid(tree.current_scene) else ""
		print("F49 APPROACH FAILURE " + JSON.stringify(last_approach))
		_stick(0, 0)
		return _fail("F49 ordinary capsule walk failed to " + str(prompt.get_path()))
	_stick(0, 0)
	for frame in 8: await tree.physics_frame
	if int(_player.get("_unstick_count")) != recoveries_before:
		return _fail("F49 unexpected entombment recovery interrupted ordinary capsule travel")
	if not _player.is_on_floor() or arbiter.call("winning_provider") != prompt:
		return _fail("F49 reached provider without grounded, exact actionable ownership: " + str(prompt.get_path()))
	var offer: Dictionary = arbiter.call("winner")
	if offer.get("actionable") != true: return _fail("F49 actual provider refused its action")
	_activated = null
	arbiter.connect("activated", _activation)
	await tap("interact")
	if is_instance_valid(arbiter) and arbiter.is_connected("activated", _activation):
		arbiter.disconnect("activated", _activation)
	return _activated == prompt or _fail("F49 input activated another provider")

func _activation(provider: Object) -> void:
	_activated = provider

func grandpa_and_credits() -> bool:
	if not _bind(): return false
	var before := _uids()
	var names := HOME.party_names(game.party)
	var prompt: Node3D
	for node: Node in tree.current_scene.find_children("*", "", true, false):
		if node.has_method("interaction_offer") and node.get_parent().name == "Grandpa":
			prompt = node as Node3D
	if prompt == null: return _fail("F49 missing producer: Grandpa has no actual farm prompt")
	var panel: Node = tree.current_scene.get_node_or_null("DialoguePanel")
	if panel == null: return _fail("F49 homecoming has no actual dialogue panel")
	if not await activate(prompt): return false
	var context := HOME.context(game)
	if (context.get("chapter_choices", []) as Array).size() != 4:
		return _fail("F49 homecoming lacks the four actual personal chapter choices")
	var prose := HOME.substitutions(game)
	if prose.is_empty(): return _fail("F49 actual homecoming context supplied no current-team prose")
	var saw_initial := false
	var rendered := ""
	for frame in 1800:
		await tree.process_frame
		if panel.call("is_open"):
			var id := str(panel.get("_runner").call("conversation_id"))
			if not HOME.is_initial(id): return _fail("F49 Grandpa did not start the actual initial homecoming")
			saw_initial = true
			rendered += "\n" + str((panel.get("_body") as Label).text)
			await tap("interact")
		elif HOME.context(game).get("homecoming_seen") == true:
			break
	if not saw_initial or HOME.context(game).get("homecoming_seen") != true:
		return _fail("F49 natural Grandpa completion produced no saved homecoming acknowledgement")
	for companion: String in names:
		if not rendered.contains(companion): return _fail("F49 Grandpa failed to name actual current companion " + companion)
	for field: String in ["starter_status", "bond_memory", "chapter_choices"]:
		if str(prose.get(field, "")).is_empty() or not rendered.contains(str(prose[field])):
			return _fail("F49 Grandpa omitted the actual personal " + field)
	# Credits are opened by the real sequence director after the acknowledgement.
	var credits: Node
	for frame in 600:
		await tree.process_frame
		var owner := INPUT_OWNER.current(tree)
		if owner != null and owner.get_script() == load("res://scripts/ui/regional_credits.gd"):
			credits = owner as Node
			break
	if credits == null or not credits.call("is_open"): return _fail("F49 saved homecoming did not open production credits")
	for frame in 30: await tree.process_frame
	await tap("menu_cancel") # Ordinary Skip; disclose it in the result.
	for frame in 600:
		await tree.process_frame
		if not credits.call("is_open") and HOME.context(game).get("regional_credits_seen") == true:
			return _uids() == before or _fail("F49 acknowledgement changed the actual current team")
	return _fail("F49 credits Skip produced no durable acknowledgement")

func walk_continuation() -> bool:
	if not _bind(): return false
	var before := _player.global_position
	_stick(0, -0.5)
	for frame in 30: await tree.physics_frame
	_stick(0, 0)
	return _player.global_position.distance_to(before) > 0.1 \
		and HOME.context(game).get("regional_credits_seen") == true \
		or _fail("F49 completed-world continuation did not regain ordinary movement")

func tap(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		for frame in 4: await tree.process_frame

func _stick(x: float, y: float) -> void:
	for pair: Array in [[JOY_AXIS_LEFT_X, x], [JOY_AXIS_LEFT_Y, y]]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = int(pair[0])
		event.axis_value = float(pair[1])
		Input.parse_input_event(event)
