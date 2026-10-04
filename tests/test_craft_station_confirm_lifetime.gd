extends "res://tests/test_case.gd"

## Initialized native component input coverage. Station/Session read and
## submission boundaries are doubles: no earned refining or durable write.
## Real Craft Forge controls, callbacks, focus and InputEvents are exercised.
const DATA := preload("res://tests/test_foundation_resources.gd")
const PRESS := preload("res://tools/net/press_inject.gd")
const EXPECTED_ASSERTIONS := 34
const EXPECTED_QUEUED_ASSERTIONS := 42

class FixtureGame extends Node:
	var session: Node
	var items: RefCounted
	var inventory: RefCounted
	var world: RefCounted
	var placed_buildings: Array = []
	func known_recipe_ids() -> Array: return []
	func push_world_message(_message: String) -> void: pass

class FixtureProducer extends Node:
	signal homestead_personal_view_completed
	var revision := 1
	var reads := 0
	var submitted: Array[Dictionary] = []
	func homestead_personal_view() -> Dictionary:
		reads += 1
		return {"registry_revision": revision}
	func homestead_submit_action() -> Dictionary: return {}
	func homestead_start_refining(source: Node3D, recipe: String, amount: int) -> Dictionary:
		submitted.append({"source": source, "recipe": recipe, "amount": amount})
		return {"ok": false, "reason": "Component fixture: no refinement or write"}
	func change_view(value: int) -> void:
		revision=value
		homestead_personal_view_completed.emit()

class FixturePanel extends "res://scripts/ui/craft_panel.gd":
	var fixture: Node
	var native_events: Dictionary = {}
	func _ready() -> void:
		super._ready()
		game=fixture
	func _station_button(parent: VBoxContainer, label: String, action: Callable, focus_key: String = "") -> void:
		super._station_button(parent,label,action,focus_key)
		var button: Button = _station_buttons[-1]
		var id: int = button.get_instance_id()
		native_events[id]={"down":0,"up":0,"pressed":0}
		button.button_down.connect(_note_native.bind(id,"down"))
		button.button_up.connect(_note_native.bind(id,"up"))
		button.pressed.connect(_note_native.bind(id,"pressed"))
	func _note_native(id: int, event: String) -> void:
		native_events[id][event] += 1

class LegacyPanel extends FixturePanel:
	# Negative control: remove only the new lifetime guard, leaving the actual
	# shipping refresh/rebuild and native Button activation intact.
	func _station_button_down(_target: WeakRef) -> void: pass
	func _station_press_active() -> bool: return false

class NativeOnlyPanel extends FixturePanel:
	# Freeze the previous shipping down/up guard. This control distinguishes
	# the queued-before-down gap from the old unprotected mid-press rebuild.
	func _station_press_active() -> bool:
		var button: Button = _station_press.get_ref() as Button if _station_press != null else null
		return _open and is_instance_valid(button) and not button.is_queued_for_deletion() \
			and button.is_inside_tree() and _station_buttons.has(button)

func _fixture(tree: SceneTree, legacy: bool, native_only: bool = false) -> Dictionary:
	var holder := Node.new()
	tree.root.add_child(holder)
	var game := FixtureGame.new()
	var actual: Node = tree.root.get_node("Game")
	game.items=actual.get("items")
	game.inventory=actual.get("inventory")
	game.world=DATA.new()._world()
	var producer := FixtureProducer.new()
	game.session=producer
	holder.add_child(game)
	holder.add_child(producer)
	var station := Node3D.new()
	station.set_meta("building_id", "forge")
	station.set_meta("building_uid", "component-forge-confirm")
	holder.add_child(station)
	var panel: FixturePanel = NativeOnlyPanel.new() if native_only else (LegacyPanel.new() if legacy else FixturePanel.new())
	panel.fixture=game
	holder.add_child(panel)
	panel.open_station(station)
	return {"holder": holder, "panel": panel, "producer": producer, "station": station}

func _button(panel: FixturePanel, key: String = "") -> Button:
	for button: Button in panel._station_buttons:
		var actual := str(button.get_meta("station_focus_key", ""))
		if actual == key or (key.is_empty() and actual.begins_with("refine:")): return button
	return null

func _edge(down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device=0
	event.button_index=JOY_BUTTON_A
	event.pressed=down
	Input.parse_input_event(event)
	# Match the actual proof injector's paired polled action. Release alone
	# must not unlock presentation before the native up event is dispatched.
	if down: Input.action_press("ui_accept")
	else: Input.action_release("ui_accept")

func _frames(tree: SceneTree) -> void:
	await tree.process_frame
	await tree.physics_frame
	await tree.process_frame

func _binding(action: StringName) -> InputEvent:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton: return event
	return null

func run_initialized_queued_case(tree: SceneTree) -> Dictionary:
	# Actual PRESS_INJECT edge + the actual producer view signal, with no frame
	# between them: presentation can run before queued native button_down.
	var legacy := _fixture(tree,false,true)
	await _frames(tree)
	var target: Button = _button(legacy.panel)
	assert_true(legacy.panel.is_open()) # 1
	assert_true(is_instance_valid(target)) # 2
	if target == null:
		legacy.panel.close()
		legacy.holder.free()
		return {"completed":false,"assertions":assertion_count,"failures":failures}
	var original_id: int = target.get_instance_id()
	var original: WeakRef = weakref(target)
	target.grab_focus()
	var down: Dictionary = PRESS.edge(_binding,"ui_accept",true)
	assert_true(down.get("ok") == true) # 3
	legacy.producer.change_view(2)
	await _frames(tree)
	assert_true(original.get_ref() == null,"previous native-only guard misses the queued-before-down rebuild") # 4
	assert_eq(legacy.panel.native_events[original_id].down,0,"native result must prove the gap was before down")
	assert_eq(legacy.panel.native_events[original_id].pressed,0) # 5
	var replacement: Button = _button(legacy.panel)
	assert_true(is_instance_valid(replacement)) # 6
	if replacement == null:
		legacy.panel.close()
		legacy.holder.free()
		return {"completed":false,"assertions":assertion_count,"failures":failures}
	var replacement_id: int = replacement.get_instance_id()
	var up: Dictionary = PRESS.edge(_binding,"ui_accept",false)
	assert_true(up.get("ok") == true) # 7
	await _frames(tree)
	var replacement_pressed: int = legacy.panel.native_events[replacement_id].pressed
	assert_true(replacement_pressed >= 0 and replacement_pressed <= 1) # 8
	assert_eq(legacy.producer.submitted.size(),replacement_pressed,
		"observe actual replacement activation/submission rather than assuming queued release behavior") # 9
	var negative := {"original":legacy.panel.native_events[original_id].duplicate(true),
		"replacement":legacy.panel.native_events[replacement_id].duplicate(true),
		"submissions":legacy.producer.submitted.size()}
	legacy.panel.close()
	legacy.holder.free()
	await _frames(tree)

	var fixed := _fixture(tree,false)
	await _frames(tree)
	target=_button(fixed.panel)
	assert_true(is_instance_valid(target)) # 10
	assert_true(fixed.panel.is_open()) # 11
	if target == null:
		fixed.panel.close()
		fixed.holder.free()
		return {"completed":false,"assertions":assertion_count,"failures":failures}
	original_id=target.get_instance_id()
	original=weakref(target)
	var recipe: String = str(target.get_meta("station_focus_key")).trim_prefix("refine:")
	target.grab_focus()
	down=PRESS.edge(_binding,"ui_accept",true)
	assert_true(down.get("ok") == true) # 12
	var reads: int = fixed.producer.reads
	fixed.producer.change_view(2)
	await _frames(tree)
	assert_eq(_button(fixed.panel),original.get_ref(),"queued down keeps the original focused target") # 13
	assert_true(original.get_ref() != null) # 14
	assert_eq(fixed.panel.native_events[original_id].down,1) # 15
	assert_eq(fixed.panel._presented_station_view.registry_revision,1) # 16
	assert_true(fixed.producer.reads > reads) # 17
	up=PRESS.edge(_binding,"ui_accept",false)
	assert_true(up.get("ok") == true) # 18
	fixed.producer.change_view(3)
	await _frames(tree)
	assert_eq(fixed.panel.native_events[original_id].pressed,1) # 19
	assert_eq(fixed.panel.native_events[original_id].up,1) # 20
	assert_eq(fixed.producer.submitted.size(),1) # 21
	if fixed.producer.submitted.size() != 1:
		fixed.panel.close()
		fixed.holder.free()
		return {"completed":false,"assertions":assertion_count,"failures":failures,"negative":negative}
	assert_eq(fixed.producer.submitted[0].source,fixed.station) # 22
	assert_eq(fixed.producer.submitted[0].recipe,recipe) # 23
	assert_eq(fixed.producer.submitted[0].amount,1) # 24
	assert_false(fixed.panel.is_open()) # 25
	var positive: Dictionary = fixed.panel.native_events[original_id].duplicate(true)
	fixed.holder.free()
	await _frames(tree)

	# A polled edge can be cancelled before its native event arrives. This
	# separately disclosed control emits no physical event and no action.
	var cancelled := _fixture(tree,false)
	await _frames(tree)
	target=_button(cancelled.panel)
	original_id=target.get_instance_id()
	original=weakref(target)
	target.grab_focus()
	Input.action_press("ui_accept")
	cancelled.producer.change_view(9)
	await _frames(tree)
	assert_true(original.get_ref() != null)
	assert_true(cancelled.panel._station_presentation_deferred)
	assert_eq(cancelled.panel._presented_station_view.registry_revision,1)
	assert_eq(cancelled.panel.native_events[original_id].down,0)
	Input.action_release("ui_accept")
	await _frames(tree)
	assert_eq(cancelled.panel._presented_station_view.registry_revision,9,"process drains a cancelled polled-only refresh")
	assert_false(cancelled.panel._station_presentation_deferred)
	assert_true(original.get_ref() == null)
	assert_eq(cancelled.producer.submitted.size(),0)
	cancelled.panel.close()
	cancelled.holder.free()
	await _frames(tree)

	var guards := _fixture(tree,false)
	await _frames(tree)
	target=_button(guards.panel)
	original=weakref(target)
	target.grab_focus()
	target.set_meta("station_available",false)
	target.disabled=true
	Input.action_press("ui_accept")
	assert_true(target.disabled)
	assert_false(guards.panel._station_press_active(),"disabled focused controls cannot establish the polled bridge")
	guards.producer.change_view(2)
	await _frames(tree)
	assert_true(original.get_ref() == null)
	assert_eq(guards.panel._presented_station_view.registry_revision,2)
	var foreign := Button.new()
	guards.holder.add_child(foreign)
	foreign.grab_focus()
	assert_true(foreign.has_focus())
	assert_false(guards.panel._station_press_active(),"foreign focus cannot establish station press ownership")
	guards.producer.change_view(3)
	await _frames(tree)
	assert_eq(guards.panel._presented_station_view.registry_revision,3)
	assert_eq(guards.producer.submitted.size(),0)
	Input.action_release("ui_accept")
	guards.panel.close()
	guards.holder.free()
	await _frames(tree)
	return {"completed":true,"assertions":assertion_count,"failures":failures,"negative":negative,"positive":positive}

func run_initialized_case(tree: SceneTree) -> Dictionary:
	tree.root.size=Vector2i(1920,1080)
	var legacy := _fixture(tree, true)
	await _frames(tree)
	var old: Button = _button(legacy.panel)
	assert_true(legacy.panel.is_open()) # 1
	assert_true(is_instance_valid(old)) # 2
	if old == null:
		legacy.panel.close()
		legacy.holder.free()
		return {"completed": false, "assertions": assertion_count, "failures": failures}
	old.grab_focus()
	_edge(true)
	await _frames(tree)
	assert_true(old.is_pressed(), "native Button received the physical down") # 3
	var obsolete: WeakRef = weakref(old)
	legacy.producer.change_view(2)
	await _frames(tree)
	assert_true(obsolete.get_ref() == null, "old refresh destroys the held Button") # 4
	var replacement: Button = _button(legacy.panel)
	assert_true(is_instance_valid(replacement)) # 5
	replacement.grab_focus()
	_edge(false)
	await _frames(tree)
	assert_eq(legacy.producer.submitted.size(), 0, "release on rebuilt Button loses the original action") # 6
	assert_true(legacy.panel.is_open()) # 7
	legacy.panel.close()
	legacy.holder.free()
	await _frames(tree)

	var fixed := _fixture(tree, false)
	await _frames(tree)
	var target: Button = _button(fixed.panel)
	assert_true(fixed.panel.is_open()) # 8
	assert_true(is_instance_valid(target)) # 9
	if target == null:
		fixed.panel.close()
		fixed.holder.free()
		return {"completed": false, "assertions": assertion_count, "failures": failures}
	var recipe: String = str(target.get_meta("station_focus_key")).trim_prefix("refine:")
	var signals := {"down": 0, "up": 0, "pressed": 0}
	target.button_down.connect(func() -> void: signals.down += 1)
	target.button_up.connect(func() -> void: signals.up += 1)
	target.pressed.connect(func() -> void: signals.pressed += 1)
	target.grab_focus()
	_edge(true)
	await _frames(tree)
	assert_eq(signals.down, 1) # 10
	assert_true(target.is_pressed()) # 11
	var reads: int = fixed.producer.reads
	fixed.producer.change_view(2)
	await _frames(tree)
	fixed.producer.change_view(3)
	await _frames(tree)
	assert_true(fixed.producer.reads > reads, "current producer reads continue while held") # 12
	assert_eq(_button(fixed.panel), target, "both refreshes preserve the original native target") # 13
	assert_eq(fixed.panel._presented_station_view.registry_revision, 1) # 14
	assert_true(fixed.panel._station_presentation_deferred) # 15
	assert_eq(fixed.producer.submitted.size(), 0) # 16
	_edge(false)
	fixed.producer.change_view(4)
	await _frames(tree)
	assert_eq(signals.up, 1) # 17
	assert_eq(signals.pressed, 1) # 18
	assert_eq(fixed.producer.submitted.size(), 1, "one real release invokes the shipping refining callback once") # 19
	if fixed.producer.submitted.size() != 1:
		fixed.panel.close()
		fixed.holder.free()
		return {"completed": false, "assertions": assertion_count, "failures": failures}
	assert_eq(fixed.producer.submitted[0].source, fixed.station) # 20
	assert_eq(fixed.producer.submitted[0].recipe, recipe) # 21
	assert_eq(fixed.producer.submitted[0].amount, 1) # 22
	assert_false(fixed.panel.is_open(), "shipping refining closes the modal before submission") # 23
	assert_true(fixed.panel._station_press == null) # 24
	fixed.holder.free()
	await _frames(tree)

	var remaining := _fixture(tree, false)
	await _frames(tree)
	var amount: Button = _button(remaining.panel, "More refining units")
	assert_true(is_instance_valid(amount)) # 25
	if amount == null:
		remaining.panel.close()
		remaining.holder.free()
		return {"completed": false, "assertions": assertion_count, "failures": failures}
	amount.grab_focus()
	_edge(true)
	await _frames(tree)
	remaining.producer.change_view(7)
	await _frames(tree)
	assert_eq(_button(remaining.panel, "More refining units"), amount) # 26
	_edge(false)
	remaining.producer.change_view(8)
	await _frames(tree)
	assert_true(remaining.panel.is_open()) # 27
	assert_eq(remaining.panel._refining_amount, 2, "nonclosing station action also activates exactly once") # 28
	assert_eq(remaining.producer.submitted.size(), 0) # 29
	assert_eq(remaining.panel._presented_station_view.registry_revision, 8, "deferred rebuild rereads the latest view") # 30
	assert_ne(_button(remaining.panel, "More refining units"), amount) # 31
	assert_true(remaining.panel._station_press == null) # 32
	assert_false(remaining.panel._station_presentation_deferred) # 33
	assert_true(_button(remaining.panel, "More refining units").has_focus()) # 34
	remaining.panel.close()
	remaining.holder.free()
	await _frames(tree)
	return {"completed": true, "assertions": assertion_count, "failures": failures}

func test_initialized_native_station_confirm_survives_actual_view_rebuild() -> void:
	var suffix := "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var path := "user://craft-confirm-" + suffix + ".gd"
	var log_path := ProjectSettings.globalize_path("user://craft-confirm-" + suffix + ".log")
	var runner := FileAccess.open(path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null: return
	runner.store_string('''extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var test: RefCounted = load("res://tests/test_craft_station_confirm_lifetime.gd").new()
	var result: Dictionary = await test.call("run_initialized_case", self)
	test=null
	await process_frame
	var queued_test: RefCounted = load("res://tests/test_craft_station_confirm_lifetime.gd").new()
	var queued_result: Dictionary = await queued_test.call("run_initialized_queued_case", self)
	queued_test=null
	await process_frame
	print("CRAFT_CONFIRM_RESULT=" + JSON.stringify(result))
	print("CRAFT_QUEUED_CONFIRM_RESULT=" + JSON.stringify(queued_result))
	quit(0 if result.completed == true and result.assertions == 34 and result.failures.is_empty() \
		and queued_result.completed == true and queued_result.assertions == 42 and queued_result.failures.is_empty() else 1)
''')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_true(FileAccess.file_exists(log_path), "retain initialized child diagnostics")
	if FileAccess.file_exists(log_path): combined += "\n" + FileAccess.get_file_as_string(log_path)
	var result: Dictionary = {}
	var markers := 0
	var queued_result: Dictionary = {}
	var queued_markers := 0
	for line: String in "\n".join(output).split("\n"):
		if line.begins_with("CRAFT_QUEUED_CONFIRM_RESULT="):
			print(line)
			queued_markers += 1
			var queued_parsed: Variant = JSON.parse_string(line.trim_prefix("CRAFT_QUEUED_CONFIRM_RESULT="))
			if queued_parsed is Dictionary: queued_result=queued_parsed
			continue
		if not line.begins_with("CRAFT_CONFIRM_RESULT="): continue
		print(line)
		markers += 1
		var parsed: Variant = JSON.parse_string(line.trim_prefix("CRAFT_CONFIRM_RESULT="))
		if parsed is Dictionary: result=parsed
	assert_eq(markers, 1, combined)
	assert_true(result.get("completed") == true, combined)
	assert_eq(result.get("assertions", 0), EXPECTED_ASSERTIONS, "all native input assertions must execute")
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_eq(queued_markers,1,combined)
	assert_true(queued_result.get("completed") == true,combined)
	assert_eq(queued_result.get("assertions",0),EXPECTED_QUEUED_ASSERTIONS)
	assert_eq(queued_result.get("failures",["missing queued result"]),[],combined)
	assert_false(combined.contains("ERROR:") or combined.contains("SCRIPT ERROR"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use") \
		or combined.contains("RID allocations") or combined.contains("RIDs of type"), combined)
	assert_eq(code, 0, combined)
