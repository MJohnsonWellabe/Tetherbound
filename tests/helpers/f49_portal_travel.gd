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
const _F49_LESSON_PANEL := preload("res://scripts/onboarding/lesson_panel.gd")
var _f49_walk_serial := 0

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
	if not await activate(prompt, _hall_entry_via(arch)): return false
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

## A return visit uses the already opened personal arch, without another key.
func reenter(arch_id: String, realm: String) -> bool:
	if not _bind() or str(game.current_realm) != "meadows":
		return _fail("F49 re-entry requires the actual home world")
	var arch: Node3D
	for candidate: Node in tree.get_nodes_in_group("portal_arches"):
		if candidate.get("arch_id") == arch_id: arch = candidate as Node3D
	if arch == null: return _fail("F49 re-entry lacks live arch " + arch_id)
	var view: Dictionary = game.call("portal_view", arch_id)
	if not return_view_valid(view): return _fail("F49 re-entry requires the saved open personal arch " + arch_id)
	var before := _uids()
	if not await activate(arch.get_node_or_null("Interactable") as Node3D, _hall_entry_via(arch)): return false
	for frame in 7200:
		await tree.process_frame
		if _ready_world(realm):
			return _uids() == before or _fail("F49 re-entry changed the carried party")
	return _fail("F49 re-entry never produced the ready " + realm + " scene")

static func return_view_valid(view: Dictionary) -> bool:
	return view.get("ready") == true and view.get("open") == true and view.get("character_open") == true


## After the hang the Shrine Room offers its one-relic-power chooser
## (crossing_hall.gd). With no `power` the player defers the choice
## (menu_cancel); with one, ordinary focus/accept inputs choose that power.
func hang_relic(biome: String, power: String = "") -> bool:
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
			if _uids() != before: return _fail("F49 relic hanging changed the actual party")
			return await settle_power_chooser(power)
	return _fail("F49 relic hanging produced no actual portable relics_hung state")

## Closes the Shrine Room relic power chooser after choosing `power` (ordinary
## ui_down/ui_accept) or deferring it (menu_cancel). Absent chooser: nothing
## to close unless a power was asked for.
func settle_power_chooser(power: String = "") -> bool:
	var panel: Node
	for frame in 300:
		var owner := INPUT_OWNER.current(tree)
		if owner != null and owner.name == "RelicPowerPanel" and owner.call("is_open") == true:
			panel = owner
			break
		await tree.process_frame
	if panel == null:
		return power.is_empty() or _fail("F49 the Shrine Room offered no relic power chooser for " + power)
	if not power.is_empty():
		var hung: Array = game.local.get("redesign_character").get("relics_hung", [])
		var index: int = panel.call("choices", game.get("realm_hearts"), hung).find(power)
		if index < 0: return _fail("F49 relic power chooser does not offer " + power)
		var rows: Array = panel.get("_rows")
		for step in rows.size() + 1:
			if rows.size() > index and panel.get_viewport().gui_get_focus_owner() == rows[index]: break
			await tap("ui_down")
			rows = panel.get("_rows")
		if rows.size() <= index or panel.get_viewport().gui_get_focus_owner() != rows[index]:
			return _fail("F49 controller focus could not reach the " + power + " relic power")
		await tap("ui_accept")
		for frame in 1800:
			if str(game.get("realm_hearts").call("active_id")) == power: break
			await tree.process_frame
		if str(game.get("realm_hearts").call("active_id")) != power:
			return _fail("F49 relic power choice was not accepted: " + str(panel.get("_message").text))
	await tap("menu_cancel")
	for frame in 300:
		if INPUT_OWNER.current(tree) == null: return true
		await tree.process_frame
	return _fail("F49 relic power chooser did not close")

## Diagnostic only: which readiness condition a long Home Key wait is on.
func _print_home_key_wait(frame: int) -> void:
	var owner := INPUT_OWNER.current(tree)
	print("F49 HOME WAIT frame=%d result=%s realm=%s pending_entry='%s' scene_ready=%s owner=%s" % [frame,
		str(_home_result.get("ok", "none")), str(game.current_realm), str(game.pending_realm_entry),
		str(tree.current_scene != null and bool(game.call("_realm_scene_ready", tree.current_scene, "meadows"))),
		str(owner.get_path()) if owner != null else "none"])
	# Read-only: the arrival producer's pending stage and the saver gate.
	for node: Node in tree.root.find_children("*", "", true, false):
		var script := node.get_script() as Script
		if script == null or script.resource_path != "res://scripts/net/foundation_portal_arrival.gd": continue
		var pending: Dictionary = node.get("_pending")
		var saver: Variant = game.get("save_system")
		print("F49 HOME WAIT arrival %s seated=%s pose_saved=%s journal_started=%s keys=%s saver_busy=%s" % [
			str(node.get_path()), str(pending.get("seated")), str(pending.get("pose_saved")),
			str(pending.get("journal_started")), str(pending.keys()),
			str(saver.call("fallback_busy")) if saver is Object and (saver as Object).has_method("fallback_busy") else "?"])
	# Read-only: this character's single training-delivery row and the three
	# conditions session._training_decision needs before it reports saved.
	var session: Node = game.get("session") as Node
	var world: RefCounted = game.get("world")
	var character := str(game.get("local").get("character_id"))
	if session != null and world != null:
		var id := preload("res://scripts/creatures/essence.gd").training_delivery_id(world.reward_delivery_namespace, character)
		var row: Dictionary = world.reward_deliveries.get(id, {})
		var authority: Object = session.get("_character_authority")
		print("F49 HOME WAIT training row action=%s status=%s intent=%s pending=%s local_has_receipt=%s" % [
			str(row.get("action")), str(row.get("status")), str(row.get("intent")),
			str(authority.call("creature_training_is_pending", character)) if authority != null else "?",
			str((game.get("local").redesign_character.transaction_receipts as Array).has(row.get("receipt", "")))])

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

## `via` are ordinary walk waypoints taken first, e.g. the doorway of a
## building whose provider is indoors: a straight line from outside pins the
## capsule against a wall, short of the provider, beside another one.
func activate(prompt: Node3D, via: Array[Vector3] = []) -> bool:
	if prompt == null or not _bind(): return _fail("F49 lacks the actual interaction provider")
	var arbiter: Node = tree.current_scene.get_node_or_null("InteractionArbiter")
	if arbiter == null: return _fail("F49 lacks the actual interaction arbiter")
	var nav := NAV.new(tree, _player, _rig, _stick)
	_f49_walk_serial += 1
	_f49_confirm_lesson_cards(_f49_walk_serial)
	for point: Vector3 in via:
		if not await nav.walk_to(point, maxi(1200, int(_player.global_position.distance_to(point) * 65.0)), 0.8):
			_stick(0, 0)
			_f49_walk_serial += 1
			return _fail("F49 ordinary capsule walk failed to waypoint " + str(point))
	var distance := _player.global_position.distance_to(prompt.global_position)
	var recoveries_before := int(_player.get("_unstick_count"))
	# Original navigator retains capsule probes, confined watchdog and support
	# tests. No floor snap, shape waiver, target relocation or budget relaxation.
	if not await nav.walk_to(prompt.global_position, maxi(1200, int(distance * 65.0)), 2.5):
		_stick(0, 0)
		_f49_walk_serial += 1
		return _fail("F49 ordinary capsule walk failed to " + str(prompt.get_path()))
	_stick(0, 0)
	for frame in 8: await tree.physics_frame
	# Adjacent providers (the Shrine Room's pedestals) share the 2.5 m arrival
	# ring: a player steps closer until the intended prompt is the one offered.
	if arbiter.call("winning_provider") != prompt:
		if not await nav.walk_to(prompt.global_position, 600, 1.2):
			_stick(0, 0)
			_f49_walk_serial += 1
			return _fail("F49 ordinary capsule walk failed to close on " + str(prompt.get_path()))
		_stick(0, 0)
		for frame in 8: await tree.physics_frame
	_f49_walk_serial += 1
	if int(_player.get("_unstick_count")) != recoveries_before:
		return _fail("F49 unexpected entombment recovery interrupted ordinary capsule travel")
	if not _player.is_on_floor() or arbiter.call("winning_provider") != prompt:
		return _fail("F49 reached provider without grounded, exact actionable ownership: " + str(prompt.get_path()))
	var offer: Dictionary = arbiter.call("winner")
	if offer.get("actionable") != true: return _fail("F49 actual provider refused its action")
	_activated = null
	# What the first press met (coordinator, 2026-10-11): a re-press below is
	# a helper timing alignment only if the prompt was not yet up and focused.
	var at_press := {"winner": str(arbiter.call("winning_provider")), "offer": prompt.call("interaction_offer", _player.global_position),
		"owner": str(INPUT_OWNER.current(tree)) if INPUT_OWNER.current(tree) != null else "none",
		"distance_m": _player.global_position.distance_to(prompt.global_position), "enabled": arbiter.call("enabled")}
	arbiter.connect("activated", _activation)
	# The exact prompt may activate a few frames after the tap returns (the
	# relay helper's press_late_activation); a press that activated nothing
	# while the same prompt still offers its action is pressed again once, as
	# a player would (F19#5 tidewake_handoff, the arch's Enter after Use).
	for press in 2:
		await tap("interact")
		for frame in 30:
			if _activated != null: break
			await tree.physics_frame
		if _activated != null or not is_instance_valid(prompt) or arbiter.call("winning_provider") != prompt \
				or (prompt.call("interaction_offer", _player.global_position) as Dictionary).get("actionable") != true:
			break
		print("F49 press activated nothing; pressing the same actionable prompt again: ", prompt.get_path(),
			" first_press=", JSON.stringify(at_press), " now_distance_m=", _player.global_position.distance_to(prompt.global_position))
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
	# Grandpa is indoors: enter by the east door, as a player does.
	var house: Node = tree.current_scene.find_child("GrandpaHouse", true, false)
	var via: Array[Vector3] = []
	if house != null and house.has_method("marker"):
		via.append(house.call("marker", "door") as Vector3)
	if not await activate(prompt, via): return false
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
	# Apply now, in order. Without this a release sent in the same physics
	# frame as the last push was lost in Godot's buffered input, and the stick
	# kept walking the trainer out of an arch's radius during the press
	# (F19#5 tidewake_handoff: joy axis 0.17,0.65 after _stick(0, 0)).
	Input.flush_buffered_events()


## Tam's/Grandpa's onboarding lesson cards (`lesson_rules.gd`) open by
## themselves when the trainer passes a teacher and own input until confirmed
## (the body freezes with the stick pushed). As in gate_b_tail_segment.gd, a
## player confirms them with the physical confirm button during the walk.
func _f49_confirm_lesson_cards(serial: int) -> void:
	while serial == _f49_walk_serial and tree != null:
		var owner: Node = INPUT_OWNER.current(tree)
		if owner != null and owner.get_script() == _F49_LESSON_PANEL:
			print("F49 confirmed onboarding lesson card at ", _player.global_position)
			await tap("menu_confirm")
		else:
			await tree.physics_frame


## A straight walk from the village to an arch ends against the Hall's back
## wall: the prompt sits 0.9 m inside it and the wall blocks its line of sight
## (training_t4_return: trainer at (102.4,0.9,21.6), Arch_cloudreach offer {}).
## From outside the Hall, walk in through its authored entrance, as a player
## does: outside the doorway, the doorway, the home arrival inside, then the
## arch's own Approach marker. A trainer already inside gets no waypoints.
func _hall_entry_via(arch: Node3D) -> Array[Vector3]:
	var via: Array[Vector3] = []
	var slot := arch.get_parent() as Node3D
	var hall := slot.get_parent() as Node3D if slot != null else null
	var approach := slot.get_node_or_null("Approach") as Node3D if slot != null else null
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/crossing_hall.json"))
	if hall == null or approach == null or not config is Dictionary \
			or not config.get("entrance") is Array or not config.get("home_arrival") is Array:
		return via
	var local := hall.to_local(_player.global_position)
	var inside := (absf(local.x) < 7.0 and absf(local.z) < 15.0) or (local.x >= 7.0 and local.x < 17.0 and absf(local.z) < 7.0)
	if inside: return via
	var entrance := Vector3(float(config.entrance[0]), float(config.entrance[1]), float(config.entrance[2]))
	var arrival := Vector3(float(config.home_arrival[0]), float(config.home_arrival[1]), float(config.home_arrival[2]))
	via.append(hall.to_global(entrance + Vector3(0, 0, -2.5)))
	via.append(hall.to_global(entrance))
	via.append(hall.to_global(arrival))
	via.append(approach.global_position)
	return via
