extends SceneTree

## Can the pause shell open on top of a screen the player must answer?
##
##   godot --headless --path . --script tests/smoke_modal_stacking.gd
##
## The blind playtest pressed the menu button while the starter orbs were up and
## got both at once: the shell opened, paused the tree, and the picker — which
## is not `PROCESS_MODE_ALWAYS`, so the pause stops it processing but not
## drawing — kept its title and its "look / choose" hints on screen through the
## menu, over a selector that could no longer be answered. The same hole was
## open under a conversation.
##
## `game_menu.gd::open()` used to refuse for exactly two reasons (already open,
## fight in progress); the only thing keeping it off a modal was that modal
## calling `hold_input()` itself, which `name_prompt.gd` did and the other two
## did not. The rule now lives in `open()`, asked of `STORY_MODAL_GROUP`, so a
## fourth modal cannot forget to opt in — and this test is what says so: it
## drives the real button rather than calling `open()`, and it checks the
## on-screen reason appeared, because a refusal nobody can see is the silent
## no-op `_flash_refusal()` exists to prevent.
##
## No world scene. The shell is an autoload and both modals are ordinary
## CanvasLayers; booting the meadow would add four minutes of terrain to a check
## about one guard. The opt-in --lesson-service-fixtures continuation below
## mounts the actual Meadows world with disclosed unlock/approach fixtures;
## it does not change the default isolated modal proof or claim an earned run.

const PICKER_SCENE := "res://scenes/ui/starter_picker.tscn"
const DIALOGUE_SCENE := "res://scenes/ui/dialogue_panel.tscn"
const OPENING_CONFIG := "res://data/config/opening.json"
## Grandpa's briefing — any real conversation id would do; this one is the first
## the opening plays, so a rename of it is worth failing on.
const CONVERSATION := "grandpa_house"

var _failures: Array[String] = []
var _menu: CanvasLayer = null
var _capture_output := ""
var _lesson_service_fixtures := false


func _init() -> void:
	_run()


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-output="):
			_capture_output = argument.trim_prefix("--capture-output=")
		if argument.begins_with("--lesson-service-fixtures"):
			if argument != "--lesson-service-fixtures":
				_fail("Use --lesson-service-fixtures without a value")
			_lesson_service_fixtures = true
	if _lesson_service_fixtures:
		for required: String in ["--lesson-controller-witness", "--lesson-replay-witness", "--lesson-skip-line=0"]:
			if not OS.get_cmdline_user_args().has(required): _fail("lesson service fixtures require " + required)
		if not _failures.is_empty():
			quit(1)
			return
	if not _capture_output.is_empty():
		if not _capture_output.begins_with("res://shots/") or _capture_output.contains(".."):
			push_error("Modal captures must stay under res://shots/")
			quit(1)
			return
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_output))
	# `_init()` runs before the autoloads are mounted, so asking for `Game` right
	# away finds nothing and reports it as a missing autoload — a false failure
	# that would look exactly like project.godot's `[autoload]` block breaking.
	for i in 4:
		await process_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return
	_menu = game.call("menu")
	if _menu == null:
		print("FAIL: the autoload did not stand up the menu")
		quit(1)
		return
	if not _capture_output.is_empty():
		# Select the real last-input device with a parsed controller edge;
		# there is no world actor for this sprint binding to move or affect.
		var pad_edge := InputEventJoypadButton.new()
		pad_edge.button_index = JOY_BUTTON_LEFT_STICK
		pad_edge.pressed = true
		Input.parse_input_event(pad_edge)
		await process_frame
		pad_edge.pressed = false
		Input.parse_input_event(pad_edge)
		await process_frame

	await _check_the_shell_opens_with_nothing_in_the_way()
	await _check_the_shell_refuses_over_the_starter_picker()
	await _check_the_shell_refuses_over_a_conversation()
	await _check_lessons_own_skip_and_menu_input()
	await _check_lesson_service_departures(game)
	if _failures.is_empty() and _lesson_service_fixtures:
		await _check_actual_lesson_service_fixtures(game)

	print("")
	if _failures.is_empty():
		print("modal stacking smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)


## The control. Without this, every check below would pass on a menu that never
## opens at all — the "passes because the feature is absent" failure
## docs/AGENT_WORKFLOW.md names.
func _check_the_shell_opens_with_nothing_in_the_way() -> void:
	await _press("inventory")
	if not bool(_menu.call("is_open")):
		_fail("the menu does not open even with nothing on screen; the checks below prove nothing")
		return
	_menu.call("close")
	for i in 4:
		await process_frame
	print("control: the shell opens and closes with no modal up")


func _check_the_shell_refuses_over_the_starter_picker() -> void:
	var picker := _instantiate(PICKER_SCENE)
	if picker == null:
		return
	picker.call("open", _species())
	await process_frame
	if not bool(picker.call("is_open")):
		_fail("the starter picker would not open; nothing was tested")
		picker.queue_free()
		return

	await _press("inventory")
	if bool(_menu.call("is_open")):
		_fail(
			"the pause shell opened on top of the starter picker. The picker keeps DRAWING while "
			+ "the tree is paused, so its title and hints ghost through the menu over a selector "
			+ "the player can no longer answer."
		)
		_menu.call("close")
	else:
		_expect_reason("the starter picker")

	# And the same button through its other route: the shortcut keys read a
	# separate branch of `_read_actions`, and a guard fixed on one of them only
	# is a guard that holds until somebody presses Escape instead.
	await _press("menu_cancel")
	if bool(_menu.call("is_open")):
		_fail("`menu_cancel` opened the shell over the starter picker even though `inventory` was refused")
		_menu.call("close")

	picker.call("close")
	picker.queue_free()
	for i in 4:
		await process_frame

	await _press("inventory")
	if not bool(_menu.call("is_open")):
		_fail("the shell would not open after the picker closed; the guard latched instead of being asked per press")
		return
	_menu.call("close")
	for i in 4:
		await process_frame
	print("picker: shell refused while open, allowed again after it closed")


func _check_the_shell_refuses_over_a_conversation() -> void:
	var panel := _instantiate(DIALOGUE_SCENE)
	if panel == null:
		return
	if not bool(panel.call("start", CONVERSATION)):
		_fail("conversation '%s' would not start; data/dialogue no longer has it under that id" % CONVERSATION)
		panel.queue_free()
		return
	await process_frame
	if not bool(panel.call("is_open")):
		_fail("the dialogue panel reported the conversation started but is not open")
		panel.queue_free()
		return

	await _press("inventory")
	if bool(_menu.call("is_open")):
		_fail("the pause shell opened on top of an active conversation; Grandpa keeps talking behind it")
		_menu.call("close")
	else:
		_expect_reason("a conversation")

	panel.call("close")
	panel.queue_free()
	for i in 4:
		await process_frame
	print("dialogue: shell refused while a conversation was on screen")


## Real configured lesson cards; this proves local input/lifecycle only, not
## earned unlocks, character receipts, persistence or comprehension at a gate.
func _check_lessons_own_skip_and_menu_input() -> void:
	var owner := preload("res://scripts/ui/input_owner.gd")
	var rules := preload("res://scripts/onboarding/lesson_rules.gd")
	var lesson := preload("res://scripts/onboarding/lesson_panel.gd").new()
	root.add_child(lesson)
	var acknowledgements: Array[String] = []
	lesson.dismissed.connect(func(id: String) -> void: acknowledgements.append(id))
	for source: Dictionary in rules.config().get("lessons", []):
		var row := source.duplicate(true)
		var dialogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(row.dialogue_path)))
		var conversation: Dictionary = dialogue.get("conversations", {}).get(str(row.conversation), {})
		row["speaker"] = conversation.get("speaker", "")
		row["lines"] = conversation.get("lines", [])
		if row.lines.is_empty():
			_fail("lesson %s has no configured exchange" % str(row.id))
			continue
		for line: int in row.lines.size():
			if not lesson.open(row):
				_fail("lesson %s would not open for skip at line %d" % [str(row.id), line])
				break
			for advance_index: int in line: await _press("menu_confirm")
			if owner.current(self) != lesson: _fail("lesson did not own input")
			# Direct callers and physical shortcuts must obey the same guard.
			if _menu.call("open") == true:
				_fail("menu opened over lesson %s" % str(row.id))
				_menu.call("close")
			await _press("inventory")
			if _menu.call("is_open") == true:
				_fail("inventory shortcut stacked over lesson %s" % str(row.id))
				_menu.call("close")
			else: _expect_reason("lesson " + str(row.id))
			if line == 0: await _capture_lesson(str(row.id))
			var skip_ack_count := acknowledgements.size()
			await _press("menu_cancel")
			if lesson.is_open() or _menu.call("is_open") == true or owner.current(self) != null:
				_fail("lesson skip did not restore world input without opening pause")
			if acknowledgements.size() != skip_ack_count + 1 or acknowledgements.back() != str(row.id):
				_fail("lesson skip did not acknowledge exactly its own lesson")
		# Scene/character departure disposes presentation without teaching credit.
		var departure_ack_count := acknowledgements.size()
		if lesson.open(row):
			lesson.close(false)
			for departure_frame: int in 4: await process_frame
			if acknowledgements.size() != departure_ack_count: _fail("departing lesson granted acknowledgement")
	# The Help/interaction edge that opens a card cannot also advance it.
	var edge_row: Dictionary = rules.config().get("lessons", [])[0].duplicate(true)
	edge_row["speaker"] = "Grandpa Elias"
	edge_row["lines"] = ["First", "Second"]
	Input.action_press("menu_confirm")
	if lesson.open(edge_row):
		_send("menu_confirm", true)
		await process_frame
		if int(lesson.get("_line")) != 0: _fail("opening confirm edge advanced lesson")
		Input.action_release("menu_confirm")
		_send("menu_confirm", false)
		for edge_frame: int in 4: await process_frame
		await _press("menu_confirm")
		if int(lesson.get("_line")) != 1: _fail("fresh confirm did not advance lesson")
		await _press("menu_cancel")
	else:
		_fail("opening-edge lesson would not open")
		Input.action_release("menu_confirm")
	lesson.queue_free()
	for release_frame: int in 4: await process_frame
	print("lessons: every configured exchange skips at every line; menu refused; departure and opening edge preserved")


## Exercise the actual mounted service's departure handling, not just panel
## close(false). Identity/realm changes are disclosed lifecycle inputs in this
## isolated smoke; no unlocks or earned progression are claimed or granted.
func _check_lesson_service_departures(game: Node) -> void:
	var rules := preload("res://scripts/onboarding/lesson_rules.gd")
	var owner := preload("res://scripts/ui/input_owner.gd")
	var service := preload("res://scripts/onboarding/lesson_service.gd").attach(game)
	service.set_process(false)
	var panel: CanvasLayer = service.get("_panel")
	var player: RefCounted = game.get("local")
	var identity: String = str(player.get("character_id"))
	var realm: String = str(game.get("current_realm"))
	var flags: Array = player.get("flags").call("all_set").duplicate()
	var acknowledgements: Array[String] = []
	var observe := func(id: String) -> void: acknowledgements.append(id)
	panel.connect("dismissed", observe)
	service.call("_process", 0.0)
	var row: Dictionary = rules.config().get("lessons", [])[0].duplicate(true)
	var dialogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(row.dialogue_path)))
	var conversation: Dictionary = dialogue.get("conversations", {}).get(str(row.conversation), {})
	row["speaker"] = conversation.get("speaker", "")
	row["lines"] = conversation.get("lines", [])
	for departure: String in ["character", "realm"]:
		if not panel.call("open", row):
			_fail("mounted lesson service would not open for " + departure + " departure")
			continue
		if owner.current(self) != panel: _fail("mounted lesson service did not own input")
		if departure == "character": player.set("character_id", identity + "-departed")
		else: game.set("current_realm", "water" if realm != "water" else "meadows")
		service.call("_process", 0.0)
		for departure_frame: int in 4: await process_frame
		if panel.call("is_open") == true or owner.current(self) != null:
			_fail("service " + departure + " departure did not release the lesson/world input")
		if not acknowledgements.is_empty() or not (service.get("_pending") as Dictionary).is_empty() \
				or player.get("flags").call("all_set") != flags:
			_fail("service " + departure + " departure acknowledged a lesson for either identity")
		player.set("character_id", identity)
		game.set("current_realm", realm)
		service.call("_process", 0.0)
	panel.disconnect("dismissed", observe)
	service.queue_free()
	for release_frame: int in 4: await process_frame
	print("lesson service: actual character/realm departures release input without dismissal or lesson receipt")


## F46 focused service proof, never an earned campaign claim. All progress
## setup occurs offline before the actual saved character enters Meadows.
## Teacher approaches are disclosed actor placement; cards themselves must
## come from the normally processing service, not panel.open/_process calls.
func _check_actual_lesson_service_fixtures(game: Node) -> void:
	var rules := preload("res://scripts/onboarding/lesson_rules.gd")
	if not _lesson_service_check(rules.config().get("enabled") == true and rules.config().get("lessons", []).size() == 8,
		"shipping service is enabled with exactly eight authored lessons"): return
	var saver := preload("res://scripts/save/save_game.gd").new("user://f46_service_%d" % OS.get_process_id())
	var slot := int(game.call("autosave_slot"))
	game.call("reset_for_new_game")
	game.set("save_system", saver)
	var local: RefCounted = game.get("local")
	var member: RefCounted = local.call("make_creature", "terrapup", "Lesson Fixture")
	if not _lesson_service_check(member != null and game.get("party").call("add", member) == true,
		"one owned starter fixture must be admitted without a sixth creature"): return
	for flag: String in ["opening:starter_granted", "opening:beat:free_play"]:
		local.get("flags").call("set_flag", flag)
	if not _lesson_service_check(game.call("save_game", slot) == true, "locked fixture production save"): return
	var character := str(local.get("character_id"))
	var uid := str(member.get("uid"))
	if not _lesson_service_check(not character.is_empty() and not uid.is_empty(), "stable fixture identities"): return
	for row: Dictionary in rules.config().get("lessons", []):
		if not _lesson_service_check(not rules.available(str(row.id), local), "locked system unavailable: " + str(row.id)): return
	if not _lesson_service_check(change_scene_to_file("res://scenes/world/meadows_playground.tscn") == OK, "actual locked Meadows load"): return
	if not await _lesson_service_world_ready(game): return
	for teacher: String in ["Grandpa", "Tam"]:
		if not await _lesson_service_place(game, teacher): return
		for frame in 60:
			await process_frame
			if not _lesson_service_check(preload("res://scripts/ui/input_owner.gd").current(self) == null,
				"actual service stays silent beside locked teacher " + teacher): return
	print("F46 SERVICE LOCKED " + JSON.stringify({"character_id": character, "owned_uid": uid,
		"teachers": ["Grandpa", "Tam"], "all_eight_unavailable": true, "teacher_near_service_silent": true}))
	if not await _lesson_service_place(game, ""): return
	if not _lesson_service_check(game.call("save_game", slot) == true, "locked fixture saves its away pose"): return
	if not await _lesson_service_title(): return
	game.call("reset_for_new_game")
	if not _lesson_service_check(saver.call("load_slot", game, slot) == true, "offline fixture restores original saved character"): return
	local = game.get("local")
	if not _lesson_service_check(str(local.get("character_id")) == character and game.get("session").call("is_active") != true,
		"declared unlock setup is offline and belongs to the original character"): return
	# Per-lesson declarations. No boss, release, feast, portal or Home Key
	# producer is claimed by these records; no lesson acknowledgement is seeded.
	local.get("flags").call("set_flag", "home_key_given")
	local.get("flags").call("set_flag", rules.PREFIX + "trigger:home_return")
	for item: String in ["home_key", "essence_ground", "tidewake_portal_key"]:
		local.get("inventory").call("add", item, 1)
	member = game.get("party").call("at", 0)
	member.set("level", 40)
	var personal: Dictionary = local.get("redesign_character").duplicate(true)
	personal.creatures[uid]["breakthroughs"] = [1, 2, 3]
	personal.creatures[uid]["cap_level"] = 40
	personal.feast_recipes = ["feast_t1"]
	personal.release_receipts = ["release:f46_declared_fixture:" + character]
	personal.relics_held = ["meadows"]
	local.set("redesign_character", personal)
	var declarations := {"home_key": "home_key_given + one Home Key", "homestead": "declared saved home_return trigger",
		"altar": "one Ground Essence", "masters": "original owned UID at L40 with breakthroughs [1,2,3]",
		"feasts": "declared feast_t1 recipe", "traits": "declared release receipt; no actual release",
		"portals": "one Tidewake key; no earned boss or portal entry", "shrines": "held Meadows relic; no earned boss or hang"}
	for row: Dictionary in rules.config().get("lessons", []):
		if not _lesson_service_check(rules.available(str(row.id), local) and local.get("flags").call("has", rules.PREFIX + str(row.id)) != true,
			"declared unlock is available without seeded acknowledgement: " + str(row.id)): return
	if not _lesson_service_check(game.call("save_game", slot) == true, "declared unlocks save through production schema"): return
	print("F46 SERVICE FIXTURES " + JSON.stringify({"character_id": character, "owned_uid": uid, "per_lesson": declarations,
		"unlock_fixtures_loaded_together": true, "earned_progression": false, "approach": "actual actor placement at authored teacher/away yard"}))
	if not await _lesson_service_title_load(game, slot): return
	var before := _lesson_service_stable(game)
	if not _lesson_service_check(str(before.character_id) == character and before.party_uids == [uid], "unlock fixture keeps original owner and one companion"): return
	if not await _lesson_service_place(game, ""): return
	for frame in 60:
		await process_frame
		if not _lesson_service_check(preload("res://scripts/ui/input_owner.gd").current(self) == null,
			"unlocked service stays silent outside both actual teacher radii"): return
	var service: Node = game.get_node_or_null("OnboardingLessons")
	var panel: Node = service.get("_panel")
	var dismissed: Array[String] = []
	var observe := func(id: String) -> void: dismissed.append(id)
	panel.connect("dismissed", observe)
	var seen: Array[String] = []
	var observed_rows: Array[Dictionary] = []
	var travel_script := load("res://tests/helpers/f20_portal_travel.gd") as GDScript
	if not _lesson_service_check(travel_script != null, "existing controller/reader adapter loads"): return
	var travel: RefCounted = travel_script.new(self, game)
	for teacher: String in ["Grandpa", "Tam"]:
		if not await _lesson_service_place(game, teacher): return
		var expected: Array[String] = ["home_key", "homestead", "altar", "traits"] if teacher == "Grandpa" else ["masters", "feasts", "portals", "shrines"]
		for id: String in expected:
			var appeared := false
			for frame in 180:
				await process_frame
				if panel.call("is_open") == true: appeared = true; break
			var row: Dictionary = (panel.get("_row") as Dictionary).duplicate(true)
			if not _lesson_service_check(appeared and row.get("id") == id and row.get("teacher_node") == teacher \
				and service.get("_replaying") == false and preload("res://scripts/ui/input_owner.gd").current(self) == panel,
				"actual teacher service owns its next expected card: " + id): return
			if id == "masters":
				var master := preload("res://scripts/creatures/breakthrough.gd").master("master_t4")
				if not _lesson_service_check(row.get("goal") == "Challenge %s for the L40 feast recipe." % str(master.name),
					"returning L40 character gets its actual Master goal instead of Orin/L10"): return
			observed_rows.append(row)
			travel.set("_lesson_active", true)
			var generation := int(travel.get("_lesson_generation")) + 1
			travel.set("_lesson_generation", generation)
			await travel.call("_continue_navigation_lesson", generation)
			travel.set("_lesson_active", false)
			if not _lesson_service_check((travel.get("failures") as Array).is_empty(), "actual controller Skip reader: " + id): return
			seen.append(id)
			if not _lesson_service_check(dismissed == seen and _lesson_service_stable(game) == before,
				"one callback per lesson; Skip preserves original owner, team and progression: " + id): return
			var deadline := Time.get_ticks_msec() + 30000
			while not (service.get("_pending") as Dictionary).is_empty() and Time.get_ticks_msec() < deadline: await process_frame
			if not _lesson_service_check((service.get("_pending") as Dictionary).is_empty() and game.call("save_game", slot) == true,
				"actual callback settles and production autosave accepts: " + id): return
			if not _lesson_service_disk(game, seen): return
			print("F46 SERVICE ACK " + JSON.stringify({"lesson": id, "teacher": teacher, "character_id": character,
				"owned_uid": uid, "fixture": declarations[id], "source": "actual proximity/eligibility service",
				"physical_skip": true, "callback_once": true, "personal_ack_on_disk": true, "progression_unchanged": true}))
	panel.disconnect("dismissed", observe)
	if not _lesson_service_check(seen.size() == 8 and preload("res://scripts/ui/input_owner.gd").current(self) == null,
		"all eight service cards skipped with free world input"): return
	if not await _lesson_service_place(game, ""): return
	if not _lesson_service_check(game.call("save_game", slot) == true, "all-eight production autosave before memory clear"): return
	if not await _lesson_service_title_load(game, slot): return
	if not _lesson_service_check(_lesson_service_stable(game) == before, "actual title Load retains owner/team and declared progression"): return
	if not _lesson_service_disk(game, seen): return
	for teacher: String in ["Grandpa", "Tam"]:
		if not await _lesson_service_place(game, teacher): return
		for frame in 60:
			await process_frame
			if not _lesson_service_check(preload("res://scripts/ui/input_owner.gd").current(self) == null,
				"actual teacher return after disk Load does not repeat acknowledged cards: " + teacher): return
	for row: Dictionary in observed_rows:
		travel = travel_script.new(self, game)
		travel.set("_lesson_replay_row", row.duplicate(true))
		travel.set("_lesson_replay_identity", {"character_id": character, "party_uids": [uid]})
		if not _lesson_service_check(await travel.call("replay_observed_lesson"), "actual Settings Help replay after disk Load: " + str(row.id)): return
		if not _lesson_service_check(_lesson_service_stable(game) == before, "Help replay grants no progression: " + str(row.id)): return
	if not _lesson_service_disk(game, seen): return
	print("F46 SERVICE RESULT " + JSON.stringify({"passed": true, "lessons": seen, "character_id": character,
		"party_uids": [uid], "locked_teacher_control": true, "unlocked_outside_radius_control": true,
		"actual_service_trigger": true, "all_skipped_by_controller": true, "callback_ack_saved": true,
		"memory_cleared_before_physical_title_load": true, "no_repeat_at_teachers": true, "all_help_replays": true,
		"save_root": saver.get("_dir"), "per_lesson_fixtures": declarations,
		"scope": "Focused F46#0 service/skip/save/replay proof from declared unlock and approach fixtures; no earned producers, full campaign or F46#1 comprehension claim"}))


func _lesson_service_check(ok: bool, message: String) -> bool:
	if not ok: _fail("F46 service: " + message)
	return ok


func _lesson_service_world_ready(game: Node) -> bool:
	for frame in 7200:
		await process_frame
		var scene := current_scene
		var actor := game.call("find_player") as CharacterBody3D
		if scene != null and scene.scene_file_path == "res://scenes/world/meadows_playground.tscn" \
			and scene.has_method("shell_build_complete") and scene.call("shell_build_complete") == true \
			and actor != null and actor.is_on_floor() and game.get("session").call("snapshot_ready") == true \
			and game.get_node_or_null("OnboardingLessons") != null and preload("res://scripts/ui/input_owner.gd").current(self) == null:
			return true
	return _lesson_service_check(false, "actual Meadows shell, grounded actor, session and mounted service become ready")


## This fixture changes only the real actor's approach, never the teacher,
## interaction radii, eligibility, service schedule or presentation ownership.
func _lesson_service_place(game: Node, teacher_name: String) -> bool:
	var actor := game.call("find_player") as CharacterBody3D
	var teacher := current_scene.find_child(teacher_name, true, false) as Node3D if not teacher_name.is_empty() else null
	if not _lesson_service_check(actor != null and (teacher_name.is_empty() or teacher != null), "actual teacher/actor for approach " + teacher_name): return false
	var target := Vector3(-6, 1.4, 22) if teacher == null else teacher.global_position + Vector3(0, 0.2, 2)
	preload("res://scripts/creatures/remote_creature.gd").teleport_body(actor, target)
	actor.velocity = Vector3.ZERO
	for frame in 90: await physics_frame
	for frame in 2: await process_frame
	if not _lesson_service_check(actor.is_on_floor(), "fixture approach is grounded: " + teacher_name): return false
	for row: Dictionary in preload("res://scripts/onboarding/lesson_rules.gd").config().get("lessons", []):
		var npc := current_scene.find_child(str(row.teacher_node), true, false) as Node3D
		if not _lesson_service_check(npc != null, "authored teacher is mounted: " + str(row.teacher_node)): return false
		if teacher_name.is_empty() and not _lesson_service_check(actor.global_position.distance_to(npc.global_position) > float(row.radius_m),
			"away fixture is outside actual teacher radius"): return false
		if str(row.teacher_node) == teacher_name and not _lesson_service_check(actor.global_position.distance_to(npc.global_position) <= float(row.radius_m),
			"near fixture is within actual teacher radius"): return false
	return true


func _lesson_service_title() -> bool:
	if not _lesson_service_check(change_scene_to_file("res://scenes/ui/title_screen.tscn") == OK, "production title transition"): return false
	for frame in 10: await process_frame
	return _lesson_service_check(current_scene != null and current_scene.scene_file_path == "res://scenes/ui/title_screen.tscn", "actual title loaded")


func _lesson_service_title_load(game: Node, slot: int) -> bool:
	if not _lesson_service_check(slot == int(game.call("autosave_slot")), "physical title Load uses the original production autosave slot"): return false
	if current_scene == null or current_scene.scene_file_path != "res://scenes/ui/title_screen.tscn":
		if not await _lesson_service_title(): return false
	game.call("reset_for_new_game")
	if not _lesson_service_check(game.get("party").call("size") == 0, "memory cleared before physical title Load"): return false
	for row: Dictionary in preload("res://scripts/onboarding/lesson_rules.gd").config().get("lessons", []):
		if not _lesson_service_check(game.get("local").get("flags").call("has", "opening:lesson:" + str(row.id)) != true, "old lesson memory cleared"): return false
	var travel: RefCounted = (load("res://tests/helpers/f20_portal_travel.gd") as GDScript).new(self, game)
	travel.set("_lesson_controller_input", true)
	var button := current_scene.get("_load_button") as Button
	if not _lesson_service_check(button != null and not button.disabled, "enabled actual title Load Game"): return false
	for step in 8:
		if root.gui_get_focus_owner() == button: break
		await travel.call("tap", "ui_down")
	if not _lesson_service_check(root.gui_get_focus_owner() == button, "controller focuses actual Load Game"): return false
	await travel.call("tap", "ui_accept")
	var autosave := root.gui_get_focus_owner() as Button
	if not _lesson_service_check(autosave != null and not autosave.disabled and autosave.text.begins_with("Autosave —"), "controller offers actual saved autosave"): return false
	await travel.call("tap", "ui_accept")
	if not _lesson_service_check((travel.get("failures") as Array).is_empty(), "title controller adapter succeeds"): return false
	return await _lesson_service_world_ready(game)


## Exclude lesson acknowledgements and changing HP/food/clock from the stable
## comparison. A lesson may teach; it may never pay inventory/XP or alter team.
func _lesson_service_stable(game: Node) -> Dictionary:
	var local: RefCounted = game.get("local")
	var party: Array[Dictionary] = []
	var uids: Array[String] = []
	for member: RefCounted in game.get("party").call("members"):
		var card := {}
		for field: String in ["uid", "species_id", "level", "xp", "known_moves", "move_quick", "move_charged", "move_utility", "move_ultimate", "move_mastery_uses", "move_mastery_receipts", "loadout_revision"]:
			card[field] = member.get(field)
		party.append(card)
		uids.append(str(member.get("uid")))
	var inventory: Array = []
	for slot: int in int(local.get("inventory").call("slot_count")): inventory.append(local.get("inventory").call("stack_at", slot))
	return {"character_id": str(local.get("character_id")), "party_uids": uids, "party": party,
		"inventory": inventory, "redesign_character": local.get("redesign_character")}.duplicate(true)


func _lesson_service_disk(game: Node, expected: Array[String]) -> bool:
	var character := str(game.get("local").get("character_id"))
	var path: String = game.get("save_system").call("characters").call("path_for", character)
	var disk: Variant = preload("res://scripts/save/save_document.gd").parse(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not _lesson_service_check(disk is Dictionary and disk.get("character_id") == character, "actual character disk belongs to original owner"): return false
	var flags: Array = disk.get("flags", {}).get("flags", [])
	for row: Dictionary in preload("res://scripts/onboarding/lesson_rules.gd").config().get("lessons", []):
		var id := str(row.id)
		if not _lesson_service_check(flags.count("opening:lesson:" + id) == (1 if expected.has(id) else 0) \
			and game.get("local").get("flags").call("has", "opening:lesson:" + id) == expected.has(id),
			"only actual skipped lesson acknowledges once in memory/disk: " + id): return false
	return true


## Optional native frames from this existing smoke's actual configured cards.
## The default headless proof has no capture waits or output changes.
func _capture_lesson(id: String) -> void:
	if _capture_output.is_empty(): return
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	if frame == null or frame.is_empty():
		_fail("modal capture has no native viewport: " + id)
		return
	if frame.save_png(_capture_output.path_join(id + ".png")) != OK:
		_fail("modal capture could not be written: " + id)


## A refusal the player cannot see is the same broken-looking dead button
## `_flash_refusal()` was written to stop, so the hint is part of the pass.
func _expect_reason(what: String) -> void:
	var hint: Label = _menu.get_node_or_null(^"RefusalStatus/RefusalHint") as Label
	if hint == null:
		_fail("the shell refused over %s with no RefusalHint node to explain it" % what)
		return
	if not hint.get_parent() is CanvasLayer or (hint.get_parent() as CanvasLayer).layer <= 30 \
		or hint.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("the refusal hint must stay above lesson shade without intercepting input")
		return
	if not hint.visible or hint.text.is_empty():
		_fail("the shell refused over %s silently; the button just looks broken" % what)
		return
	print("refused over %s: \"%s\"" % [what, hint.text])


func _instantiate(path: String) -> CanvasLayer:
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		_fail("%s does not load" % path)
		return null
	var node := scene.instantiate() as CanvasLayer
	root.add_child(node)
	return node


func _species() -> Array[String]:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OPENING_CONFIG))
	var out: Array[String] = []
	if typeof(parsed) != TYPE_DICTIONARY:
		return out
	var starters: Variant = (parsed as Dictionary).get("starters", {})
	if typeof(starters) != TYPE_DICTIONARY:
		return out
	for id in (starters as Dictionary).get("species", []):
		out.append(str(id))
	return out


## Both paths, because the shell uses both: `Input.action_press` for its own
## polling and a parsed event for the focus half of a controller menu
## (archive/docs/HANDOFF.md §10, and smoke_menu.gd is where that was learned).
##
## Process frames, not physics: `game_menu.gd` reads its actions in `_process`.
func _press(action: String) -> void:
	Input.action_press(action)
	_send(action, true)
	await process_frame
	await process_frame
	Input.action_release(action)
	_send(action, false)
	for i in 4:
		await process_frame


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
