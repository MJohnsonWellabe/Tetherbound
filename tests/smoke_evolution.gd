extends SceneTree

## RD/F29 spec update: evolution belongs to T2 Ascension Feast feeding.
## Existing disclosed mechanics setup: two owned Lv20 Mudsnouts, prior T1,
## cooked catalyst feasts and individuality/mastery. No earned catch, recipe,
## Kitchen crafting, controller navigation or campaign credit. The real
## mounted chooser receives input; Session must commit/save/ACK the choice.
## No private completion call, authored reward or legacy config override.
## Run with an isolated user home under the shared native-engine lease.
const SCENE := "res://scenes/world/meadows_playground.tscn"
const RULES := preload("res://scripts/creatures/breakthrough.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")
const FEED := preload("res://scripts/creatures/progression_feed.gd")
const CHARACTER_SAVE := preload("res://scripts/save/character_save.gd")
const PRESERVED := ["uid", "nickname", "level", "xp", "bond", "battles_fought", "landmarks_visited_together", "distance_m_together", "iv_hp", "iv_attack", "iv_defence", "trait_primary", "trait_secondary", "move_quick", "move_charged", "move_utility", "move_ultimate", "move_mastery_uses", "move_mastery_receipts"]
var _failures: Array[String] = []
var _checks := 0
var _game: Node
var _menu: CanvasLayer
var _service: Node
var _uids: Array[String] = []
var _saved_completions: Array[Dictionary] = []

func _init() -> void:
	_run.call_deferred()

func _check(value: bool, reason: String) -> void:
	_checks += 1
	if not value: _failures.append(reason)

func _run() -> void:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_check(false, "Game autoload unavailable")
		_report()
		return
	_game.call("reset_for_new_game")
	_check(PROGRESSION.config().get("evolution_mode") == "breakthrough", "shipping RD/F29 breakthrough mode is required")
	if not _seed_existing_setup():
		_report()
		return
	var world := (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for _frame: int in 240: await physics_frame
	_menu = _game.call("menu")
	_service = _game.session.call("homestead_breakthrough_service")
	_check(_menu != null and _service != null, "actual menu and Foundation breakthrough service mounted")
	if _menu == null or _service == null:
		_report()
		return
	_game.session.connect("homestead_action_completed", _completed)
	_check(_game.call("save_game", int(_game.call("autosave_slot"))) == true, "disclosed pre-choice state BOOL-saved")
	_check(not _game.session.call("homestead_personal_view").is_empty(), "real host admits the disclosed original character")
	_capped_live_growth_refused()
	await _held_stone_shortcut_refused()
	await _choose_and_reload(_uids[0], "evolve", "tuskroot")
	await _choose_and_reload(_uids[1], "stay", "mudsnout")
	_check(int(_game.inventory.call("count", "feast_t2_ground_heartstone")) == 0, "each cooked feast consumed exactly once")
	_check(int(_game.inventory.call("count", "heartstone")) == 1, "held stone is never charged again")
	_game.session.disconnect("homestead_action_completed", _completed)
	_report()

func _seed_existing_setup() -> bool:
	for nickname: String in ["Snorty", "Still Snorty"]:
		var creature: RefCounted = _game.call("make_creature", "mudsnout", nickname)
		if creature == null:
			_check(false, "existing Mudsnout setup unavailable")
			return false
		creature.set("iv_hp", 0.21)
		creature.set("iv_attack", 0.63)
		creature.set("iv_defence", 0.87)
		creature.call("set_level", 20, PROGRESSION.config())
		creature.set("bond", 37)
		creature.set("traits_initialized", true)
		creature.set("rolled_traits", [TRAITS.config().traits.keys()[0]])
		creature.set("battles_fought", 17)
		creature.set("landmarks_visited_together", 3)
		creature.set("distance_m_together", 2400.0)
		var mastery_history: Array[String] = []
		for use: int in 77: mastery_history.append("disclosed-evolution-smoke-prior-use-%d" % use)
		creature.set("move_mastery_uses", {str(creature.get("move_quick")): 77})
		creature.set("move_mastery_receipts", {str(creature.get("move_quick")): mastery_history})
		_check(_game.party.call("add", creature) == true, "existing setup fits five-owned limit")
		_uids.append(str(creature.get("uid")))
	var owner: RefCounted = _game.get("local")
	var saved: Dictionary = owner.call("save_data")
	for card: Dictionary in saved.party:
		saved.redesign_character = RULES.initialize_caught(saved.redesign_character, card)
		var creature: RefCounted = _game.party.call("at", saved.party.find(card))
		saved.redesign_character.creatures[card.uid].traits_initialized = true
		saved.redesign_character.creatures[card.uid].rolled_traits = creature.get("rolled_traits").duplicate()
	owner.set("redesign_character", saved.redesign_character)
	_check(_game.inventory.call("add", "feast_t2_ground_heartstone", 2) == 0, "existing setup contains two cooked T2 catalyst feasts")
	_check(_game.inventory.call("add", "heartstone", 1) == 0, "legacy held stone retained for refusal/double-debit check")
	var errors := RECORD.errors(RECORD.portable_projection(owner.call("save_data")), str(owner.get("character_id")))
	_check(errors.is_empty(), "canonical disclosed setup: " + str(errors))
	return errors.is_empty()

## F28#0 shares this existing capped setup. These are the actual live legacy
## callers, not an earned combat award or a host transaction proof.
func _capped_live_growth_refused() -> void:
	var before: Dictionary = _game.local.call("save_data")
	var cursor := FEED.latest_seq()
	for index: int in _uids.size():
		var creature: RefCounted = _game.party.call("at", index)
		var uid := _uids[index]
		_check(str(creature.get("uid")) == uid and int(creature.get("level")) == 20
			and int(before.redesign_character.creatures[uid].cap_level) == 20,
			"existing individual starts at its admitted Lv20 cap")
		_check(int(creature.call("gain_xp", int(creature.call("xp_to_next", PROGRESSION.config())) * 10, PROGRESSION.config())) == 0,
			"capped live-owned XP caller grants no levels")
		_check(int(creature.call("gain_levels", 3, PROGRESSION.config())) == 0,
			"capped live-owned legacy candy caller grants no levels")
		_check(int(creature.get("level")) == 20 and int(creature.get("xp")) == 0,
			"locked cap discards XP rather than banking it")
	_check(_game.local.call("save_data") == before, "cap refusals leave original character state unchanged")
	_check(FEED.latest_seq() == cursor, "cap refusals announce no unearned XP or level-up")

func _held_stone_shortcut_refused() -> void:
	await _press("inventory")
	_check(bool(_menu.call("is_open")), "inventory input opens the actual menu")
	_menu.call("select", 1)
	for _frame: int in 4: await process_frame
	var body: Node = _menu.get("_bodies")[1]
	for index: int in _uids.size():
		(body.get("_rows")[index] as Button).grab_focus()
		for _frame: int in 4: await process_frame
		var cap_label: Label = body.get("_detail_training_cap")
		var next_label: Label = body.get("_detail_xp_next")
		_check(cap_label != null and cap_label.is_visible_in_tree()
			and cap_label.text == "Level 20 / Cap 20 · Breakthrough needed",
			"actual focused Team row visibly names its locked personal cap")
		_check(next_label != null and next_label.is_visible_in_tree() and next_label.text == "Breakthrough needed",
			"actual Team XP-next label explains why growth stopped")
	(body.get("_rows")[0] as Button).grab_focus()
	for _frame: int in 4: await process_frame
	await _press("backpack_drop")
	_check(str(body.get("_evolution_stage")).is_empty(), "held stone cannot start the retired Team ceremony")
	_check(str(_menu.get("_status").text).contains("Ascension Feast"), "Team explains the current feast path")
	_check(str(_game.party.call("at", 0).get("species_id")) == "mudsnout", "legacy input leaves original species")
	await _press("menu_cancel")
	_check(not bool(_menu.call("is_open")), "menu remains usable after refusal")

func _card(state: Dictionary, uid: String) -> Dictionary:
	for card: Dictionary in state.get("party", []):
		if card.get("uid") == uid: return card
	return {}

func _completed(action: String, original: Dictionary, result: Dictionary) -> void:
	if action == "feast_feed":
		_saved_completions.append({"intent": original.duplicate(true), "result": result.duplicate(true)})

func _choose_and_reload(uid: String, choice: String, species: String) -> void:
	var before: Dictionary = _game.local.call("save_data")
	var original := _card(before, uid)
	var completion_count := _saved_completions.size()
	_service.call("open_feed") # Same mounted feed opener used by the Kitchen.
	for _frame: int in 4: await process_frame
	var panel: Control = _service.get("_panel")
	_check(panel != null and panel.visible, "real breakthrough chooser opens")
	if panel == null or not panel.visible: return
	var feast_name := str(RULES.feasts().items.feast_t2_ground_heartstone.name)
	var suffix := " · Evolve to " + species if choice == "evolve" else " · " + feast_name + " · Stay (permanent this tier)"
	var wanted := str(original.nickname) + " · Breakthrough needed" + suffix
	var selected: Button
	var stay_seen := false
	var evolve_seen := false
	for node: Node in panel.get("_list").get_children():
		if not node is Button: continue
		if node.text.begins_with(str(original.nickname) + " ·"):
			stay_seen = stay_seen or node.text.contains("Stay (permanent this tier)")
			evolve_seen = evolve_seen or node.text.contains("Evolve to tuskroot")
		if node.text == wanted: selected = node
	_check(stay_seen and evolve_seen, "same canonical T2 offer visibly includes evolve and permanent stay")
	_check(selected != null, "exact real choice button exists: " + wanted)
	if selected == null:
		panel.call("close")
		return
	selected.grab_focus()
	await _press("ui_accept")
	for _frame: int in 600:
		if _saved_completions.size() > completion_count: break
		await physics_frame
	_check(_saved_completions.size() == completion_count + 1, "choice produces exactly one real completed feed")
	if _saved_completions.size() <= completion_count:
		_check(false, "feed did not settle: " + str(panel.get("_message").text))
		panel.call("close")
		return
	var completion: Dictionary = _saved_completions.back()
	_check(completion.intent == {"creature_uid": uid, "feast_item": "feast_t2_ground_heartstone", "choice": choice}, "completion belongs to original exact choice")
	for field: String in ["ok", "settled", "durable", "owner_saved", "owner_acknowledged"]:
		_check(completion.result.get(field) == true, "real feed completion " + field)
	var after: Dictionary = _game.local.call("save_data")
	_assert_identity(original, _card(after, uid), choice + " live")
	_check(_card(after, uid).get("species_id") == species, "choice applies its intended species")
	for move: String in original.get("known_moves", []):
		_check(_card(after, uid).get("known_moves", []).has(move), "choice preserves ancestor knowledge " + move)
	for field: String in ["rolled_traits", "taught_traits", "mastery", "mastery_receipts", "traits_initialized"]:
		_check(after.redesign_character.creatures[uid].get(field) == before.redesign_character.creatures[uid].get(field), "choice preserves personal mirror " + field)
	_check(after.redesign_character.creatures[uid].evolution_choices.get("2") == (species if choice == "evolve" else "stay"), "permanent T2 choice is recorded")
	_check(after.redesign_character.creatures[uid].breakthroughs == [1, 2] and int(after.redesign_character.creatures[uid].cap_level) == 30, "T2 lifts only the cap, with no free level")
	var disk := CHARACTER_SAVE.new().state(str(_game.local.character_id))
	_assert_identity(original, _card(disk, uid), choice + " owner disk before extra save")
	_check(disk.get("redesign_character", {}) == after.redesign_character, "producer saved the complete personal choice before any smoke autosave")
	panel.call("close")
	_check(_game.call("save_game", int(_game.call("autosave_slot"))) == true, "post-choice regular save succeeds")
	_check(_game.call("load_game", int(_game.call("autosave_slot"))) == true, "regular saved slot reload succeeds")
	var restored: Dictionary = _game.local.call("save_data")
	_assert_identity(original, _card(restored, uid), choice + " reloaded")
	_check(_card(restored, uid).get("species_id") == species, "reload keeps chosen species")
	_check(restored.redesign_character.creatures[uid] == after.redesign_character.creatures[uid], "reload keeps traits/mastery/cap/permanent choice mirror")
	_service.call("open_feed")
	for _frame: int in 4: await process_frame
	for node: Node in panel.get("_list").get_children():
		if node is Button:
			_check(not node.text.begins_with(str(original.nickname) + " ·"), "saved choice offers no second T2 feed or retroactive evolve")
	await _press("ui_cancel")
	_check(not panel.visible, "cancel input releases the actual chooser")

func _assert_identity(before: Dictionary, after: Dictionary, label: String) -> void:
	_check(not after.is_empty(), label + " contains the same UID")
	for field: String in PRESERVED:
		_check(before.has(field) and after.get(field) == before.get(field), label + " preserves " + field)

func _press(action: String) -> void:
	Input.action_press(action)
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	Input.action_release(action)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	for _frame: int in 4: await process_frame

func _report() -> void:
	print("RD/F29 evolution smoke: %d checks, %d failures; disclosed setup, no earned-route credit" % [_checks, _failures.size()])
	for line: String in _failures: print("  FAIL: " + line)
	quit(0 if _failures.is_empty() else 1)
