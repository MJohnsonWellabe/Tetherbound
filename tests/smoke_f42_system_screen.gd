extends SceneTree

## Shared-queue native proof of modal ownership and controller back release.
## Research rows also exercise the real panel with disclosed canonical event
## proposals restored through JSON. No actual encounter/owner-save/visual
## acceptance is implied by those component fixtures.
const SCREEN := preload("res://scripts/ui/system_screen.gd")
const OWNER := preload("res://scripts/ui/input_owner.gd")
var _failures: Array[String] = []
var _checks := 0
var _capture_root := ""

func _init() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-research="):
			_capture_root = argument.trim_prefix("--capture-research=")
	_run.call_deferred()

func _run() -> void:
	var mouse_before := Input.mouse_mode
	var panel := SCREEN.new()
	root.add_child(panel)
	_check(panel.begin("Controller ownership proof", "A Select · B Back"), "surface opens")
	var action := panel.button(panel.body, "Focus target", func() -> void: pass, "stable-target")
	panel.finish("stable-target")
	await process_frame
	await process_frame
	_check(OWNER.current(self) == panel, "modal owns input")
	_check(root.gui_get_focus_owner() == action, "initial focus targets enabled content")
	var competing := SCREEN.new()
	root.add_child(competing)
	_check(not competing.begin("Competing modal", "Back"), "second modal cannot steal input")
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_B
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	_check(not panel.is_open(), "physical B closes the modal")
	_check(OWNER.current(self) == panel, "closing B remains owned until release")
	event = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_B
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	_check(OWNER.current(self) == null, "ownership releases after B release")
	_check(Input.mouse_mode == mouse_before, "mouse state restored")
	_check(panel.begin("Reopen", "Back"), "closed surface reopens cleanly")
	panel.queue_free()
	competing.queue_free()
	await process_frame
	_check(OWNER.current(self) == null, "disposal releases input")
	await _research_rows()
	await _system_screens()
	for failure: String in _failures: push_error(failure)
	print("SYSTEM SCREEN CHECKS: %d checks, %d failures" % [_checks, _failures.size()])
	print("F42 MODAL SMOKE: PASS" if _failures.is_empty() else "F42 MODAL SMOKE: FAIL")
	quit(0 if _failures.is_empty() else 1)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures.append(message)


func _research_rows() -> void:
	var fixture: RefCounted = preload("res://tests/test_research_log.gd").new()
	var actions := preload("res://scripts/net/character_action_rules.gd")
	var records := preload("res://scripts/net/character_record_rules.gd")
	var research := preload("res://scripts/creatures/research_log.gd")
	var current: Dictionary = fixture.call("_record")
	# Disclosed host-event fixtures: one caught history with an empty roster
	# represents retained post-release history; a cast-only history was never
	# owned. No live catch, release, or encounter is claimed here.
	var caught: Dictionary = actions.stage(current, 0, "research_event", {},
		fixture.call("_context", current, 0, "catch", "ui-catch"), records.errors)
	_check(caught.get("ok") == true, "canonical caught-history fixture stages")
	if caught.get("ok") != true: return
	current = caught.state
	var seen: Dictionary = actions.stage(current, 1, "research_event", {},
		fixture.call("_context", current, 1, "cast", "ui-cast", "terrapup"), records.errors)
	_check(seen.get("ok") == true, "canonical never-owned cast fixture stages")
	if seen.get("ok") != true: return
	var model := {"record": JSON.parse_string(JSON.stringify(seen.state))}
	_check(model.record.party.is_empty(), "research presentation needs no retained creature slot")
	var panel := preload("res://scripts/ui/research_log_panel.gd").new()
	root.add_child(panel)
	_check(panel.open(func(biome: String) -> Dictionary:
		return research.view(model.record.redesign_character, model.record.character_id, biome)),
		"real research panel opens from restored personal projection")
	await process_frame
	await process_frame
	var target := _research_button(panel, "species:terrapup")
	_check(target != null, "never-owned seen species has a journal row")
	if target != null:
		target.grab_focus()
		await process_frame
		await process_frame
		_check(_research_text(panel).contains("Observe its signature move · 1 / 1"),
			"focusing never-owned species displays its restored signature progress")
		_check(_research_text(panel).contains("Observe three completed move casts · 1 / 3"),
			"task progress is read from the personal log, not party membership")
		_check(_research_text(panel).contains("Essence Ground ×10"), "task states its type essence payout")
		var focus := root.gui_get_focus_owner()
		_check(is_instance_valid(focus) and str(focus.get_meta("system_focus_key", "")) == "species:terrapup",
			"task rebuild retains focused species identity")
		await _capture_research(panel, "terrapup-never-owned", "species:terrapup")
	var released := _research_button(panel, "species:bramblebun")
	_check(released != null and released.text.contains("Caught"), "caught history remains visible with an empty roster")
	if released != null:
		released.grab_focus()
		await process_frame
		await process_frame
		_check(_research_text(panel).contains("Meet this species in an encounter · 1 / 1"),
			"focusing post-release history shows its retained task progress")
	# Disclosed unresolved service replies exercise only the actual panel's
	# consumer; Session still owns authentication, journal/BOOL-save and ACK.
	var submissions: Array[Dictionary] = []
	panel.claim_task = func(species: String, task: String) -> Dictionary:
		submissions.append({"species_id": species, "task_id": task})
		return {"ok": false, "resolved": false, "code": "awaiting_saved_decision"}
	var original_claim := {"species_id": "bramblebun", "task_id": "sight"}
	panel.call("_claim", "bramblebun", "sight")
	_check(submissions == [original_claim] and panel.get("_pending_claim") == original_claim,
		"unresolved claim retains its exact original intent")
	panel.call("_claim", "terrapup", "signature")
	_check(submissions == [original_claim] and panel.get("_pending_claim") == original_claim,
		"a second task cannot submit or replace the original pending claim")
	var context: Dictionary = panel.get("_opened_context")
	var original_envelope := {"op": "research_claim", "station_key": "research_journal",
		"intent": original_claim, "character_id": context.get("character_id"),
		"world_namespace": context.get("world_namespace")}
	var foreign_envelope := original_envelope.duplicate(true)
	foreign_envelope.intent = {"species_id": "terrapup", "task_id": "signature"}
	var refused := {"ok": false, "resolved": true, "terminal_refusal": true, "durable": false,
		"code": "disclosed_component_refusal"}
	panel.call("_claim_reply", foreign_envelope, refused)
	_check(panel.get("_pending_claim") == original_claim,
		"another task's terminal reply cannot release the original claim")
	panel.call("_claim_reply", original_envelope, refused)
	_check((panel.get("_pending_claim") as Dictionary).is_empty(),
		"matching terminal refusal releases the original claim for retry")
	panel.call("_claim", "bramblebun", "sight")
	_check(submissions == [original_claim, original_claim] and panel.get("_pending_claim") == original_claim,
		"ordinary retry submits the same task after its original refusal")
	var claimed: Dictionary = actions.stage(model.record, 2, "research_claim",
		{"species_id": "bramblebun", "task_id": "sight"},
		{"character_id": model.record.character_id, "expected_revision": 2,
			"in_range": true, "source_key": "research_journal"}, records.errors)
	_check(claimed.get("ok") == true, "canonical component claim produces paid projection")
	if claimed.get("ok") == true:
		model.record = JSON.parse_string(JSON.stringify(claimed.state))
		panel.call("_claim_reply", original_envelope, {"ok": true, "resolved": true})
		_check((panel.get("_pending_claim") as Dictionary).is_empty(),
			"matching resolved component reply releases the original pending claim")
		panel.call("_process", 0.6)
		await process_frame
		_check(_research_text(panel).contains("Paid ✓"), "restored paid task renders its paid tick")
		await _capture_research(panel, "bramblebun-caught-history-paid", "species:bramblebun")
	await _modal_lifecycle(panel, "Research")
	panel.queue_free()
	await process_frame
	_check(OWNER.current(self) == null, "research disposal releases modal ownership")

func _system_screens() -> void:
	# Reuse the existing disclosed layout doubles and station component.
	# These exercise production Controls and input, never earned transactions.
	var fixtures := preload("res://tools/capture_f42_layout_fixtures.gd")
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	var creature: RefCounted = preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")
	game.get("party").call("add", creature)
	var level_service := fixtures.AltarFixture.new()
	level_service.uid = str(creature.get("uid"))
	level_service.level = int(creature.get("level"))
	root.add_child(level_service)
	var altar := preload("res://scripts/ui/altar_panel.gd").new()
	root.add_child(altar)
	_check(altar.configure_service(level_service), "Altar binds existing disclosed layout service")
	_check(altar.open("layout-altar"), "Altar Level/Essence opens")
	await _modal_lifecycle(altar, "Altar Level/Essence")
	altar.queue_free()
	level_service.queue_free()
	await process_frame
	for tab: String in ["Loadout", "Mastery", "Gear"]:
		var details := preload("res://scripts/ui/companion_details_panel.gd").new()
		root.add_child(details)
		_check(details.open(game, str(creature.get("uid")), tab), "actual companion " + tab + " opens")
		await _modal_lifecycle(details, "Companion " + tab)
		details.queue_free()
		await process_frame
	var traits_service := fixtures.TraitsFixture.new()
	traits_service.uid = str(creature.get("uid"))
	root.add_child(traits_service)
	var traits := preload("res://scripts/ui/altar_traits_panel.gd").new()
	root.add_child(traits)
	_check(traits.open(traits_service, "layout-altar"), "actual Altar Traits opens")
	await _modal_lifecycle(traits, "Altar Traits")
	traits.queue_free()
	traits_service.queue_free()
	await process_frame
	var station: Dictionary = preload("res://tests/test_craft_station_confirm_lifetime.gd").new().call("_fixture", self, false)
	_check(station.panel.is_open(), "actual station Craft controls open")
	await _modal_lifecycle(station.panel, "Station Forge")
	station.holder.queue_free()
	await process_frame
	var board := fixtures.BountyFixture.new()
	root.add_child(board)
	var bounties := preload("res://scripts/ui/bounty_board_panel.gd").new()
	root.add_child(bounties)
	_check(bounties.open(board), "actual Bounty opens")
	await _modal_lifecycle(bounties, "Bounty")
	bounties.queue_free()
	board.queue_free()
	await process_frame

func _modal_lifecycle(panel: Node, name: String) -> void:
	await process_frame
	await process_frame
	_check(OWNER.current(self) == panel, name + " owns input")
	var focused := root.gui_get_focus_owner()
	_check(is_instance_valid(focused) and panel.is_ancestor_of(focused) and focused.is_visible_in_tree(),
		name + " has visible controller focus")
	var injector := preload("res://tools/net/press_inject.gd")
	_check(injector.edge(_pad_binding, "menu_cancel", true).get("ok") == true, name + " physical B down is injected")
	await process_frame
	await process_frame
	var surface: Variant = panel.get("_root")
	_check(not is_instance_valid(surface) or not surface.is_visible_in_tree(), name + " physical B closes its surface")
	_check(OWNER.current(self) == null or OWNER.current(self) == panel, name + " closing B does not transfer input to another modal")
	_check(injector.edge(_pad_binding, "menu_cancel", false).get("ok") == true, name + " physical B up is injected")
	await process_frame
	await process_frame
	_check(OWNER.current(self) == null, name + " releases ownership after physical B release")
	_check(not paused, name + " returns an unpaused tree")

func _pad_binding(action: StringName) -> InputEvent:
	for binding: InputEvent in InputMap.action_get_events(action):
		if binding is InputEventJoypadButton: return binding
	return null


func _research_button(panel: Node, key: String) -> Button:
	for child: Button in panel.get("body").find_children("*", "Button", true, false):
		if child.get_meta("system_focus_key", "") == key: return child
	return null


func _research_text(panel: Node) -> String:
	var lines: PackedStringArray = []
	for child: Label in panel.get("body").find_children("*", "Label", true, false):
		lines.append(child.text)
	return "\n".join(lines)


func _capture_research(panel: Node, tag: String, focus_key: String) -> void:
	if _capture_root.is_empty(): return
	if DisplayServer.get_name() == "headless":
		_check(false, "research readability capture needs the native render mode")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_capture_root))
	root.content_scale_size = Vector2i.ZERO
	for size: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = size
		for _frame in 4: await process_frame
		var selected := _research_button(panel, focus_key)
		if selected != null: selected.grab_focus()
		for _frame in 4: await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := _capture_root.path_join("%s-%dx%d.png" % [tag, size.x, size.y])
		_check(image != null and image.get_size() == size, "readability frame has the requested native dimensions")
		if image != null:
			_check(image.save_png(ProjectSettings.globalize_path(path)) == OK, "readability PNG saved")
			print("RESEARCH CAPTURE: " + path)
		if selected != null:
			_check(_visible_rect(selected, size).encloses(selected.get_global_rect()),
				"selected species row remains visible after native resize: " + focus_key)
		for label: Label in panel.get("body").find_children("*", "Label", true, false):
			if not label.text.contains(" / "): continue
			_check(_visible_rect(label, size).encloses(label.get_global_rect()),
				"selected task is fully visible at %dx%d: %s" % [size.x, size.y, label.text])

func _visible_rect(control: Control, size: Vector2i) -> Rect2:
	var visible_rect := Rect2(Vector2.ZERO, Vector2(size))
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents:
			visible_rect = visible_rect.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return visible_rect
