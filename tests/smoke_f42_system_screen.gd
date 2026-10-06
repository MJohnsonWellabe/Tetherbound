extends SceneTree

## Shared-queue native proof of modal ownership and controller back release.
## Research rows also exercise the real panel with disclosed canonical event
## proposals restored through JSON. No actual encounter/owner-save/visual
## acceptance is implied by those component fixtures.
const SCREEN := preload("res://scripts/ui/system_screen.gd")
const OWNER := preload("res://scripts/ui/input_owner.gd")
var _failures: Array[String] = []
var _checks := 0

func _init() -> void:
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
	panel.queue_free()
	await process_frame
	_check(OWNER.current(self) == null, "research disposal releases modal ownership")


func _research_button(panel: Node, key: String) -> Button:
	for child: Node in panel.get("body").get_children():
		if child is Button and child.get_meta("system_focus_key", "") == key: return child
	return null


func _research_text(panel: Node) -> String:
	var lines: PackedStringArray = []
	for child: Node in panel.get("body").get_children():
		if child is Label: lines.append(child.text)
	return "\n".join(lines)
