extends SceneTree

## T2-BUILDPLACE. Live-engine check: does S03's own recorded interaction with
## Mira (`S03-53`..`S03-59`, exactly reproduced below with the same control
## names, `times` and `settle_frames` from `tools/gate_f/segments/S03.json`)
## actually receive `village_mira_shop_intro`'s axe/pickaxe/coin/recipe grant
## (`data/dialogue/village.json:29-39`, gated only by `unless_flag:
## mira_shop_open` -- unconditional on party/combat state, per
## `data/config/village_npcs.json:26-28`)?
##
## Motivation: the run's own kept `S03-exit.json` has NO axe and NO pickaxe
## anywhere in inventory, only `knife` (Tam's gift) and `torch`. Tam's own
## gift (`village.json:181`) is ONLY `give:knife:1, give:torch:1` -- axe and
## pickaxe come exclusively from Mira's first-visit conversation. If S03's
## own recorded button sequence at Mira does not actually collect them, wood
## and stone can never be gathered (`gathered_with: axe`/`pickaxe`,
## `harvest_logic.gd`) regardless of any tool-EQUIP step added later, which
## would make a tool-equip-only fix incomplete.
##
##   godot --headless --path . --script tools/gate_f/probe_mira_intro_grant.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MIRA_SPOT := Vector3(19.0, 0.0, -1.0)
const SETTLE_FRAMES := 240

var _failures: Array[String] = []
var _world: Node
var _game: Node
var _player: CharacterBody3D


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL: %s" % message)


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	if _game == null or _player == null:
		print("PROBE FAIL: Meadows did not stand up Game and Player")
		quit(1)
		return

	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")

	var y := float(_world.call("ground_height_at", MIRA_SPOT.x, MIRA_SPOT.z)) if _world.has_method("ground_height_at") else 0.0
	_player.global_position = Vector3(MIRA_SPOT.x, y + 0.2, MIRA_SPOT.z)
	_player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame

	var inventory: RefCounted = _game.get("inventory")

	# T2-BUILDPLACE round 2: the first pass of this probe (fresh party, never
	# fainted) got a clean PASS -- axe+pickaxe land and stay. But the REAL
	# S03 run's own telemetry has Moss fainting at t=256, well BEFORE this
	# Mira visit (t=372) -- so the real run's party was already fainted the
	# whole time it stood here. Reproduce that exact precondition before
	# touching Mira, the same "read the actual save contents" method the
	# South Bridge finding used, rather than trusting the first (unfainted)
	# pass to stand in for what actually happened.
	var party: RefCounted = _game.get("party")
	var active: RefCounted = party.call("active")
	if active == null:
		# A fresh boot deploys nothing (RIG-13's own point). The real S03 run
		# reached Mira with Moss already caught, deployed and then fainted
		# mid-fight -- reproduce a real deployed-then-fainted creature, not an
		# absent one, the same distinction the South Bridge finding drew
		# between "null ally" and "fainted ally".
		var creature: RefCounted = _game.call("make_creature", "terrapup")
		party.call("add", creature)
		party.call("set_active", 0)
		active = party.call("active")
	if active != null:
		active.set("hp", 0.0)
		active.set("fainted", true)
	print("--- before Mira, at her position, ACTIVE CREATURE FAINTED (matches the real S03 run's state at this point) ---")
	print("  active: %s fainted=%s hp=%s" % [str(active.call("label")) if active != null else "null", str(active.get("fainted")) if active != null else "?", str(active.get("hp")) if active != null else "?"])
	for id in ["axe", "pickaxe", "knife", "coin"]:
		print("  %s: %d" % [id, int(inventory.call("count", id))])
	print("  mira_shop_open flag: %s" % str(bool(_game.get("progression").call("has", "mira_shop_open"))))

	var arbiter := _world.find_child("InteractionArbiter", true, false)
	if arbiter == null:
		arbiter = _find_by_script(root, "interaction_arbiter.gd")
	for i in 10:
		await physics_frame
	if arbiter != null and arbiter.has_method("prompt"):
		print("  live prompt near Mira: \"%s\"" % str(arbiter.call("prompt")))

	# --- S03-53: "challenge Mira" -- interact tap x1 ---
	await _tap("interact")
	# --- S03-54: "hear the challenge out" -- interact tap x10, 20-frame settle ---
	for i in 10:
		await _tap("interact")
		for j in 20:
			await physics_frame

	print("")
	print("--- after the exact S03-53/S03-54 button sequence (interact x1, then x10 @ 20f settle) ---")
	for id in ["axe", "pickaxe", "knife", "coin"]:
		print("  %s: %d" % [id, int(inventory.call("count", id))])
	print("  mira_shop_open flag: %s" % str(bool(_game.get("progression").call("has", "mira_shop_open"))))
	var axe_after_dialogue := int(inventory.call("count", "axe"))
	var pick_after_dialogue := int(inventory.call("count", "pickaxe"))

	# --- S03-55..59: the scripted "fight" sequence, unmodified ---
	for i in int(3.0 * 60.0):
		await physics_frame
	for i in 28:
		await _tap("combat_quick")
		for j in 30:
			await physics_frame
	await _tap("combat_charged", 60)
	for i in 16:
		await _tap("combat_quick")
		for j in 30:
			await physics_frame
	for i in int(6.0 * 60.0):
		await physics_frame

	print("")
	print("--- after also running S03-55..59's scripted 'fight' presses on top ---")
	for id in ["axe", "pickaxe", "knife", "coin"]:
		print("  %s: %d" % [id, int(inventory.call("count", id))])

	if axe_after_dialogue <= 0:
		_fail("axe was never granted by the S03-53/S03-54 button sequence at Mira")
	if pick_after_dialogue <= 0:
		_fail("pickaxe was never granted by the S03-53/S03-54 button sequence at Mira")
	var axe_final := int(inventory.call("count", "axe"))
	var pick_final := int(inventory.call("count", "pickaxe"))
	if axe_after_dialogue > 0 and axe_final <= 0:
		_fail("axe was granted by the dialogue but is GONE after the scripted S03-56..58 'fight' presses")
	if pick_after_dialogue > 0 and pick_final <= 0:
		_fail("pickaxe was granted by the dialogue but is GONE after the scripted S03-56..58 'fight' presses")

	print("")
	if _failures.is_empty():
		print("PROBE PASS: S03's own recorded button sequence at Mira does receive and keep the axe/pickaxe.")
		quit(0)
	else:
		print("PROBE FOUND PROBLEMS (%d):" % _failures.size())
		for line in _failures:
			print("  - %s" % line)
		quit(1)


func _tap(action: String, hold_frames: int = 1) -> void:
	var down := _joy_event_for(action, true)
	if down == null:
		_fail("InputMap action '%s' has no joypad button or axis" % action)
		return
	Input.parse_input_event(down)
	for i in hold_frames:
		await process_frame
	Input.parse_input_event(_joy_event_for(action, false))
	for i in 5:
		await process_frame


func _joy_event_for(action: String, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			var out := InputEventJoypadButton.new()
			out.device = 0
			out.button_index = button.button_index
			out.pressed = pressed
			return out
		var motion := event as InputEventJoypadMotion
		if motion != null:
			var out := InputEventJoypadMotion.new()
			out.device = 0
			out.axis = motion.axis
			out.axis_value = motion.axis_value if pressed else 0.0
			return out
	return null


func _find_by_script(node: Node, suffix: String) -> Node:
	var script: Script = node.get_script()
	if script != null and str(script.resource_path).ends_with(suffix):
		return node
	for child in node.get_children():
		var found := _find_by_script(child, suffix)
		if found != null:
			return found
	return null
