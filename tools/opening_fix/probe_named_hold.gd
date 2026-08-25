extends SceneTree
## Developer-lane probe (branch ralph/OPENING-STARTER-FOCUS). NOT Gate F tooling.
##
## Question: after the starter is named, does `grandpa_named` close on its own,
## and what is the beat while it is open? S02 attempts 2-4 all ended with a
## DialoguePanel owning input for ~120 s with NOTHING pressing anything, and the
## block ending exactly when the harness's walk gave up waiting.
##
## This drives the opening to the post-naming state and then WATCHES, sending no
## input at all, logging every state change.

const WORLD := "res://scenes/world/meadows_playground.tscn"

var _director: Node = null
var _dialogue: Node = null
var _picker: Node = null
var _prompt: Node = null
var _player: Node3D = null
var _last := ""

func _initialize() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(WORLD) as PackedScene).instantiate()
	root.add_child(world)
	for i in 400:
		await physics_frame

	_director = _find(world, "sequence_director.gd")
	_dialogue = _find(world, "dialogue_panel.gd")
	_picker = _find(world, "starter_picker.gd")
	_prompt = _find(world, "name_prompt.gd")
	_player = _find(world, "player_controller.gd") as Node3D
	print("=== named-hold probe ===")
	print("director=%s dialogue=%s picker=%s prompt=%s player=%s" % [
		_director != null, _dialogue != null, _picker != null, _prompt != null, _player != null])

	# Get up (advances wake -> house), then go downstairs beside Grandpa.
	await _tap("interact")
	var house := world.get_node_or_null(^"GrandpaHouse")
	var g: Vector3 = house.call("marker", "grandpa")
	_player.global_position = g + Vector3(1.0, 0.2, 0.0)
	for i in 60:
		await physics_frame
	_state("downstairs beside Grandpa")

	# Briefing: tap until the picker is open, bounded.
	for i in 40:
		if bool(_picker.call("is_open")):
			break
		await _tap("interact")
		_state("briefing tap %d" % (i + 1))

	# Choose a starter -- the picker polls menu_confirm.
	if bool(_picker.call("is_open")):
		await _tap("menu_confirm")
		_state("after menu_confirm on the picker")

	for i in 120:
		if bool(_prompt.call("is_open")):
			break
		await physics_frame
	_state("naming prompt open=%s" % str(_prompt.call("is_open")))

	# Confirm a name straight through the prompt's own confirm path.
	if bool(_prompt.call("is_open")):
		var entry: Object = _prompt.call("entry")
		for ch in "Moss":
			entry.call("type", ch)
		print("  entry buffer now '%s' valid=%s" % [str(_prompt.call("current_text")), str(entry.call("is_valid"))])
		_prompt.call("_confirm")
		for i in 60:
			await physics_frame
		_state("after naming")

	print("--- now WATCHING for 150 s with NO input at all ---")
	for t in 30:
		for i in 300:
			await physics_frame
		_state("watch %d s" % ((t + 1) * 5))
	print("--- end of watch ---")
	quit()

func _tap(action: String) -> void:
	var ev := InputMap.action_get_events(StringName(action))
	var pad: InputEvent = null
	for e in ev:
		if e is InputEventJoypadButton:
			pad = e
			break
	var b := InputEventJoypadButton.new()
	b.button_index = (pad as InputEventJoypadButton).button_index
	b.pressed = true
	Input.parse_input_event(b)
	await process_frame
	await physics_frame
	var u := InputEventJoypadButton.new()
	u.button_index = b.button_index
	u.pressed = false
	Input.parse_input_event(u)
	await process_frame
	for i in 30:
		await physics_frame

func _state(tag: String) -> void:
	var beat := str(_director.get("_beat")) if _director != null else "?"
	var dlg := bool(_dialogue.call("is_open")) if _dialogue != null and _dialogue.has_method("is_open") else false
	var line := ""
	var runner: Object = _dialogue.get("_runner") if _dialogue != null else null
	if runner != null and runner.has_method("line"):
		var l: Variant = runner.call("line")
		if l is Dictionary and not (l as Dictionary).is_empty():
			line = str((l as Dictionary).get("text", "")).substr(0, 44)
	var owners := root.get_tree().get_nodes_in_group("input_owner")
	var owner_name := "none"
	for o in owners:
		if o.has_method("is_open") and bool(o.call("is_open")):
			owner_name = str((o as Node).name)
			break
	var s := "beat=%s dlg=%s owner=%s line='%s'" % [beat, dlg, owner_name, line]
	if s != _last:
		print("  [%s] %s" % [tag, s])
		_last = s
	else:
		print("  [%s] (unchanged)" % tag)

func _find(from: Node, tail: String) -> Node:
	if from.get_script() != null and str(from.get_script().resource_path).ends_with(tail):
		return from
	for c in from.get_children():
		var r := _find(c, tail)
		if r != null:
			return r
	return null
