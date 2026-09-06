extends SceneTree

## Production menu/character-save fixture smoke. This does not prove the physical
## Cloudreach reveal trigger, rendering quality, or multiplayer transport.
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const CHARACTER_SAVE := preload("res://scripts/save/character_save.gd")
var _failures: Array[String] = []
var _checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(message)
		print("FAIL: ", message)

func _frames(count: int = 4) -> void:
	for _frame in count:
		await process_frame

func _pad(button_index: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(3)
	event = InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(4)

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	await _frames()
	var game := root.get_node_or_null("Game")
	if game == null or game.call("menu") == null:
		_check(false, "Game did not mount its production menu")
		_finish()
		return
	var menu: Node = game.call("menu")
	var local: RefCounted = game.get("local")
	local.reset()
	var other := PLAYER_STATE.new()
	other.configure(game.get("items"))
	other.inventory.add("skill_candy_ii", 2)
	_check(other.inventory.count("skill_candy_ii") == 2, "Other character fixture owns separate Candy")
	var other_before: Dictionary = other.save_data()
	var tabs: Array = menu.get("_tabs")
	var skills_index := -1
	for index in tabs.size():
		if str(tabs[index].get("id", "")) == "skills":
			skills_index = index
	_check(skills_index >= 0, "Skills exists in production menu configuration")
	if skills_index < 0:
		_finish()
		return
	_check(menu.call("open", "skills"), "Fresh menu opens")
	await _frames()
	var tab_buttons: Array = menu.get("_tab_buttons")
	_check(not tab_buttons[skills_index].visible, "Skills button hidden before reveal")
	_check(menu.call("current_tab_id") != "skills", "Hidden Skills cannot be selected directly")
	menu.call("close")
	# Explicit reveal fixture: actual chapter transition is a separate smoke.
	local.skills.enter_realm("cloudreach")
	local.skills.add_xp("swimming", 50.0)
	local.inventory.add("skill_candy_ii", 2)
	local.inventory.add("skill_candy_iii", 1)
	_check(menu.call("open", "skills"), "Revealed Skills opens")
	await _frames()
	_check(tab_buttons[skills_index].visible, "Skills button visible after reveal")
	_check(menu.call("current_tab_id") == "skills", "Skills selected after reveal")
	var bodies: Array = menu.get("_bodies")
	var tab: Node = bodies[skills_index]
	var rows: Dictionary = tab.get("_rows")
	_check(rows.size() == 5, "Five skill rows exist")
	_check(root.gui_get_focus_owner() == tab.call("first_focus"), "Opening Skills establishes controller focus")
	_check(root.gui_get_focus_owner() == rows.running, "First focus belongs to Running")
	for _step in 3:
		await _pad(JOY_BUTTON_DPAD_DOWN)
	_check(root.gui_get_focus_owner() == rows.swimming, "Physical D-pad reaches Swimming")
	await _pad(JOY_BUTTON_A)
	_check(str(tab.get("_selected")) == "swimming", "Physical A selects Swimming")
	var candy_buttons: Dictionary = tab.get("_candy_buttons")
	var candy: Button = candy_buttons.skill_candy_ii
	_check(candy.is_visible_in_tree() and not candy.disabled, "Owned tier-II Candy button is actionable")
	candy.grab_focus()
	await _pad(JOY_BUTTON_A)
	_check(local.skills.level("swimming") == 2, "Candy button adds two Swimming levels")
	_check(absf(local.skills.fraction("swimming") - 0.5) < 0.00001, "Candy preserves fractional progress")
	_check(local.inventory.count("skill_candy_ii") == 1, "Candy button consumes exactly one owned item")
	_check(other.save_data() == other_before, "Other character skills and inventory remain unchanged")
	# Write a uniquely named real CharacterSave file, without touching live saves.
	var test_dir := "user://test_player_skills_menu_%d/" % Time.get_ticks_usec()
	var store := CHARACTER_SAVE.new(test_dir)
	_check(store.write("fixture", local.save_data()), "CharacterSave writes Skills to disk")
	var saved: Dictionary = store.read("fixture")
	_check(saved.has("skills"), "Character disk payload contains Skills")
	var restored := PLAYER_STATE.new()
	restored.configure(game.get("items"))
	restored.load_data(saved)
	_check(restored.skills.level("swimming") == 2, "Character roundtrip restores level")
	_check(absf(restored.skills.fraction("swimming") - 0.5) < 0.00001, "Character roundtrip restores XP")
	_check(restored.skills.revealed, "Character roundtrip restores reveal")
	_check(restored.inventory.count("skill_candy_ii") == 1, "Character roundtrip preserves Candy consumption")
	_check_legacy_characters(store, game.get("items"), local.save_data())
	DirAccess.remove_absolute(store.path_for("fixture"))
	DirAccess.remove_absolute(store.dir_for("fixture"))
	DirAccess.remove_absolute(test_dir)
	local.skills.load_data({"revealed": true, "levels": {"swimming": 29}, "xp": {"swimming": 20.0}})
	tab.call("poll")
	var before_refusal: Dictionary = local.save_data()
	var tier_three: Button = candy_buttons.skill_candy_iii
	_check(tier_three.disabled, "Full tier exceeding cap disables its button")
	# Simulate an already queued button activation: the transaction must also
	# refuse independently of the visible disabled state.
	tier_three.pressed.emit()
	_check(local.save_data() == before_refusal, "Over-cap queued activation preserves XP and inventory")
	_check(other.save_data() == other_before, "Other character remains unchanged after refusal")
	menu.call("close")
	_check(not menu.call("is_open"), "Menu closes after the interaction")
	_finish()

func _check_legacy_characters(store: RefCounted, items: RefCounted, payload: Dictionary) -> void:
	# An actual old portable character file has no Skills key. Loading it into
	# a previously trained object must clear stale XP without changing items.
	for realm_id: String in ["meadows", "cloudreach"]:
		var legacy := payload.duplicate(true)
		legacy.erase("skills")
		legacy["realm"] = realm_id
		var id := "legacy_" + realm_id
		_check(store.write(id, legacy), "Legacy " + realm_id + " fixture writes")
		var fresh := PLAYER_STATE.new()
		fresh.configure(items)
		fresh.skills.add_xp("running", 10000.0)
		fresh.load_data(store.read(id))
		for skill_id: String in ["running", "catching", "riding", "swimming", "flying"]:
			_check(fresh.skills.level(skill_id) == 0 and fresh.skills.fraction(skill_id) == 0.0,
				"Legacy " + realm_id + " receives no historical " + skill_id + " XP")
		_check(fresh.skills.revealed == (realm_id == "cloudreach"),
			"Legacy character reveal follows its saved realm")
		_check(fresh.inventory.count("skill_candy_ii") == 1,
			"Legacy migration preserves inventory without regranting Candy")
		DirAccess.remove_absolute(store.path_for(id))
		DirAccess.remove_absolute(store.dir_for(id))

func _finish() -> void:
	print("Skills menu fixture smoke: %d checks, %d failures" % [_checks, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
