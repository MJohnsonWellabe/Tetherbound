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
		or _fail("F49 travel requires ordinary world input and one to five actually owned creatures")

func _uids() -> Array[String]:
	var out: Array[String] = []
	for member: RefCounted in game.party.members(): out.append(str(member.get("uid")))
	return out

func home_key() -> bool:
	_home_result = {}
	if not game.has_signal("portal_action_result"):
		return _fail("F49 missing producer: Game has no authoritative portal result signal")
	game.connect("portal_action_result", _portal_result)
	var passed := await _use_home_key()
	game.disconnect("portal_action_result", _portal_result)
	return passed

func _portal_result(result: Dictionary) -> void:
	if result.get("kind") == "home_key_finish": _home_result = result.duplicate(true)

func _use_home_key() -> bool:
	if not _bind(): return false
	var before := _uids()
	var inventory: RefCounted = game.get("inventory")
	var slot := int(inventory.call("find_slot", "home_key"))
	if slot < 0: return _fail("F49 missing producer: Grandpa's actual opening did not deliver the personal Home Key")
	if not str(game.call("home_key_refusal")).is_empty():
		return _fail("F49 Home Key refused in the actual position: " + str(game.call("home_key_refusal")))
	await tap("inventory")
	var menu: Node = game.call("menu")
	if menu == null or not menu.call("is_open") or menu.call("current_tab_id") != "backpack":
		var modals: Array[String] = []
		for node: Node in tree.get_nodes_in_group(&"story_modal"):
			if node.has_method("is_open") and bool(node.call("is_open")): modals.append(str(node.get_path()))
		var owner: Node = INPUT_OWNER.current(tree)
		var beat := ""
		for node: Node in tree.current_scene.find_children("*", "Node", true, false):
			if node.get_script() != null and node.get_script().resource_path == "res://scripts/story/sequence_director.gd": beat = str(node.get("_beat"))
		print("F49 SATCHEL menu=%s open=%s tab=%s refusal=%s modals=%s owner=%s beat=%s" % [str(menu != null),
			str(menu.call("is_open")) if menu != null else "-", str(menu.call("current_tab_id")) if menu != null else "-",
			str(menu.call("_refusal_reason")) if menu != null else "-", str(modals), str(owner.get_path()) if owner != null else "none", beat])
		return _fail("F49 inventory input did not open the actual Satchel")
	var backpack: Node = (menu.get("_bodies") as Array)[0]
	var care := CARE.new()
	care.set("_tree", tree)
	if not await care.call("_focus_slot", backpack.get("_buttons"), slot):
		return _fail("F49 controller focus could not reach the actual Home Key")
	# Production Satchel Use must close the menu and route to HomeKey.use().
	# This deliberately exposes the currently missing shared input producer.
	await tap("interact")
	for frame in 7200:
		await tree.process_frame
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
	if not await activate(prompt): return false
	for frame in 720:
		await tree.process_frame
		view = game.call("portal_view", arch_id)
		if view.get("character_open") == true: break
	if view.get("character_open") != true or view.get("has_key") == true:
		return _fail("F49 actual arch Use did not durably consume exactly the earned key: " + arch_id)
	if not await activate(prompt): return false
	for frame in 7200:
		await tree.process_frame
		if _ready_world(realm):
			return _uids() == before or _fail("F49 actual portal travel changed the carried party")
	return _fail("F49 portal Enter never produced the ready " + realm + " scene")

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

func activate(prompt: Node3D) -> bool:
	if prompt == null or not _bind(): return _fail("F49 lacks the actual interaction provider")
	var arbiter: Node = tree.current_scene.get_node_or_null("InteractionArbiter")
	if arbiter == null: return _fail("F49 lacks the actual interaction arbiter")
	var nav := NAV.new(tree, _player, _rig, _stick)
	var distance := _player.global_position.distance_to(prompt.global_position)
	var recoveries_before := int(_player.get("_unstick_count"))
	# Original navigator retains capsule probes, confined watchdog and support
	# tests. No floor snap, shape waiver, target relocation or budget relaxation.
	if not await nav.walk_to(prompt.global_position, maxi(1200, int(distance * 65.0)), 2.5):
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
