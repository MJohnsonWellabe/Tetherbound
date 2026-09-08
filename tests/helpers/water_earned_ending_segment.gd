extends "res://tests/helpers/water_shellwatch_segment.gd"

## Ordinary full-belt ending: invite the actually freed Guardian, decline the
## pending newcomer through its GUI, and observe saved personal/world receipts.
const RETAINED := preload("res://tests/helpers/water_earned_opening_segment.gd")
const END_FLAGS := ["water_guardian_settled", "water_currents_restored", "realm_relic_water_earned"]
var _carried_ids: Array[int] = []
var _claim_id := ""

func run_earned(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	if tree == null or world == null or game == null or tree.current_scene != world \
			or str(game.get("current_realm")) != "water":
		_fail("Ending requires the retained actual Water world")
		return result()
	setup(tree, world, world.get_node_or_null("Player"), world.get_node_or_null("CameraRig"))
	_carried_ids = _party_ids()
	var cave := world.get_node_or_null("WaterVeilfall")
	if _player == null or _camera == null or _arbiter == null or cave == null \
			or not RETAINED.retained_five(_carried_ids, _carried_ids) \
			or game.get("pending_catch") != null or not cave.contains_interior(_player.global_position):
		_fail("Ending requires the same five inside the physically reached Veilfall")
		return result()
	for flag in ["water_captain_nerissa_defeated", "water_tether_disabled", "water_guardian_freed"]:
		if not game.world.flags.has(flag):
			_fail("Ending lacks earned " + flag)
			return result()
	for flag in END_FLAGS + ["water_guardian_claimed"]:
		if game.world.flags.has(flag):
			_fail("Ending cannot credit pre-completed " + flag)
			return result()
	var prompt := cave.get("_guardian_prompt") as Node3D
	if not await _invite_guardian(prompt):
		return result()
	# The existing ending's600 physics frames are ten seconds at its normal
	# clock. Use that same time bound while waiting for the UI, whose opening
	# pauses world processing. No direct reward or transaction call.
	var pending_deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < pending_deadline:
		if _game.pending_catch != null:
			break
		await _tree.process_frame
	var pending: RefCounted = _game.pending_catch
	if pending == null or str(pending.get("species_id")) != str(cave.rules.guardian_species_id) \
			or int(pending.get("level")) != int(cave.rules.guardian_level):
		_fail("Guardian invitation did not create its actual authored pending creature")
		return result()
	_claim_id = str(pending.get_meta("water_capture_claim", ""))
	var claim: Dictionary = game.world.water_capture_claims.get(_claim_id, {})
	if _claim_id.is_empty() or str(claim.get("source", "")) != "guardian" \
			or str(claim.get("character_id", "")) != str(game.local.character_id) \
			or str(claim.get("world_id", "")) != str(game.world.world_id):
		_fail("Pending Guardian lacks its actual character/world claim")
		return result()
	if not await _decline_pending(pending):
		return result()
	for frame in 600:
		if _settled():
			_completed = true
			_note("Tidewake ending earned: Guardian farewell saved, currents restored, relic earned; retained five")
			return result()
		await _tree.physics_frame
	_fail("Guardian farewell did not publish its saved ending receipts")
	return result()

func _invite_guardian(prompt: Node3D) -> bool:
	if not is_instance_valid(prompt):
		return _fail("Freed Guardian has no actual invitation provider")
	for index in 8:
		var angle := TAU * float(index) / 8.0
		# Interior geometry supplies the floor. Never substitute outside terrain
		# height or move the player; navigator emits ordinary horizontal input.
		var stance := prompt.global_position + Vector3(cos(angle), 0, sin(angle)) * 2.5
		if not await _walk_to(stance, "freed Guardian stance", 1.0):
			return false
		await _frames(8)
		if _arbiter.winning_provider() != prompt:
			continue
		_activated = null
		await _tap(&"interact")
		if _activated == prompt:
			return true
	return _fail("Guardian invitation did not receive the exact controller interaction")

func _decline_pending(pending: RefCounted) -> bool:
	var menu: Node = _game.menu()
	var tab: Node
	if menu == null:
		return _fail("Actual Guardian farewell menu is absent")
	for index in (menu.get("_tabs") as Array).size():
		if str(menu.get("_tabs")[index].get("id", "")) == "creatures":
			tab = menu.get("_bodies")[index]
	if tab == null:
		return _fail("Actual Guardian farewell has no creatures tab")
	for frame in 60:
		if menu.is_open() and str(tab.get("_release_stage")) == "choose":
			break
		await _tree.process_frame
	if not menu.is_open() or str(tab.get("_release_stage")) != "choose" \
			or _tree.root.gui_get_focus_owner() != tab.get("_pending_button") \
			or not RETAINED.retained_five(_carried_ids, _party_ids()):
		return _fail("Guardian ceremony did not focus the pending newcomer beside the same five")
	await _gui_tap("ui_accept")
	if str(tab.get("_release_stage")) != "confirm" or int(tab.get("_release_target")) != 5 \
			or _tree.root.gui_get_focus_owner() != tab.get("_farewell_keep") or _game.pending_catch != pending:
		return _fail("Guardian farewell must target only the pending newcomer, with Keep as default")
	await _gui_tap("ui_down")
	if _tree.root.gui_get_focus_owner() != tab.get("_farewell_release"):
		return _fail("Controller Down did not select Let them go")
	await _gui_tap("ui_accept")
	if str(tab.get("_release_stage")) != "done" or _game.pending_catch != null \
			or not RETAINED.retained_five(_carried_ids, _party_ids()) \
			or _tree.root.gui_get_focus_owner() != tab.get("_farewell_done"):
		return _fail("Actual Guardian farewell changed the five or left an unsettled choice")
	await _gui_tap("ui_accept")
	if str(tab.get("_release_stage")) != "":
		return _fail("Back to belt did not close Guardian farewell")
	await _gui_tap("menu_cancel")
	return (not menu.is_open() and not _tree.paused and _tree.current_scene == _world) \
		or _fail("Guardian farewell did not return control to its retained world")

func _gui_tap(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	down.strength = 1.0
	Input.parse_input_event(down)
	for frame in 3:
		await _tree.process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	for frame in 5:
		await _tree.process_frame

func _party_ids() -> Array[int]:
	var ids: Array[int] = []
	for member: RefCounted in _game.party.members():
		ids.append(member.get_instance_id())
	return ids

func _settled() -> bool:
	if not _game.local.flags.has("water_capture_receipt:" + _claim_id) \
			or _game.world.water_capture_claims.has(_claim_id) or _game.pending_catch != null \
			or not RETAINED.retained_five(_carried_ids, _party_ids()):
		return false
	for flag in END_FLAGS:
		if not _game.world.flags.has(flag):
			return false
	return true
