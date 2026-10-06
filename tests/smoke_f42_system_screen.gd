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
	var claimed: Dictionary = actions.stage(model.record, 2, "research_claim",
		{"species_id": "bramblebun", "task_id": "sight"},
		{"character_id": model.record.character_id, "expected_revision": 2,
			"in_range": true, "source_key": "research_journal"}, records.errors)
	_check(claimed.get("ok") == true, "canonical component claim produces paid projection")
	if claimed.get("ok") == true:
		model.record = JSON.parse_string(JSON.stringify(claimed.state))
		panel.call("_process", 0.6)
		await process_frame
		_check(_research_text(panel).contains("Paid ✓"), "restored paid task renders its paid tick")
		await _capture_research(panel, "bramblebun-caught-history-paid", "species:bramblebun")
	panel.queue_free()
	await process_frame
	_check(OWNER.current(self) == null, "research disposal releases modal ownership")


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
