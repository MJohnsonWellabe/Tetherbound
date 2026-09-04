extends SceneTree

## G3-OPENING-FIX-0904 (2.11). GATE2-EVIDENCE-0903's own finding: a fresh
## handoff (a save load, or the tournament's own last round) can leave the
## party's ACTIVE creature fainted with no ally body ever created --
## `encounter_director.gd::summon_active_creature()` refuses to deploy a
## fainted creature, so nothing stands beside the trainer at all. Reviving
## that creature through the Satchel restored its stats but left it
## undeployed: `can_challenge()`/`no_usable_ally()` stayed exactly as blocked
## as before the revive, and the game's own refusal line pointed the player at
## a bed or food rather than at the real cause (see docs/prompts and
## data/dialogue/bands/band1_lower_meadows.json for the other half of this
## fix). "One creature_recall press after the revives fixes it" -- this test
## proves the press should not have been necessary.
##
## Drives the REAL Satchel: a real pad press opens the Use picker on a real
## Revive item slot, exactly like `tests/smoke_backpack_player_eats.gd`. The
## confirm step calls `tab_backpack.gd::_on_target_row()` directly rather than
## walking focus row-by-row with the d-pad -- that IS the same handler a
## confirmed button press on the row calls, so this still exercises the real
## revive-and-redeploy code path end to end, not a hand-rolled shortcut around
## it.
##
##   godot --headless --path . --script tests/smoke_revive_redeploy.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const SETTLE_FRAMES := 300
const USE_ACTION := "interact"

var _world: Node = null
var _player: CharacterBody3D = null
var _director: Node = null
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	# `tab_backpack.gd::_encounter_director()`/`_player_node()` read
	# `get_tree().get_current_scene()`, a SceneTree property this harness
	# entry point never sets on its own -- see
	# `smoke_backpack_player_eats.gd`'s own comment on the same gotcha.
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _director == null:
		_fail("scene is missing the player or the encounter director")
		_report()
		return

	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		_fail("no Game autoload")
		_report()
		return
	var party: RefCounted = game.get("party")
	if party == null:
		_fail("no Game.party")
		_report()
		return

	# `adopt_starter()` builds a body directly and deliberately does not touch
	# `Game.party` (`tests/smoke_catching.gd`'s own R4.10 comment: "the
	# sandbox ally comes from adopt_starter() and is not in the party"). This
	# test needs a REAL party member -- `summon_active_creature()` reads
	# `party.call("active")` -- so it builds one the same way the opening
	# does once a starter is confirmed, adds it to the party directly, and
	# deploys it through the real `summon_active_creature()` path.
	if int(party.call("size")) == 0:
		var starter: RefCounted = SPECIES.spawn("terrapup")
		if starter == null:
			_fail("species.json has no terrapup to build a party member from")
			_report()
			return
		if not bool(party.call("add", starter)):
			_fail("could not add a starter to Game.party")
			_report()
			return
	if not bool(_director.call("summon_active_creature")):
		_fail("summon_active_creature() could not deploy the party's active creature")
		_report()
		return
	for i in 30:
		await physics_frame

	var active: RefCounted = party.call("active")
	if active == null:
		_fail("no active party creature")
		_report()
		return
	if _director.call("ally_body") == null:
		_fail("summon_active_creature() reported success but ally_body() is still null")
		_report()
		return

	# Faint the active creature directly -- the exact stat this produces
	# through a real fight, without needing to run one.
	active.call("take_damage", float(active.get("max_hp")) * 2.0)
	if not bool(active.get("fainted")):
		_fail("take_damage did not faint the active creature; nothing to revive")
		_report()
		return

	# Free the ally body while it is fainted, the same state a fresh scene
	# load leaves: `summon_active_creature()` refuses a fainted creature, so
	# a load never creates one in the first place. `dismiss_active_creature()`
	# carries no fainted guard, so this reaches the identical `_ally_body ==
	# null` state without needing an actual save/load round trip.
	if not bool(_director.call("dismiss_active_creature")):
		_fail("could not dismiss the ally body to set up the undeployed-fainted state")
		_report()
		return
	if _director.call("ally_body") != null:
		_fail("ally_body() is not null after dismiss_active_creature()")
		_report()
		return

	var spec := TRAINERS.trainer("practice_trainer")
	if spec.is_empty():
		_fail("practice_trainer is missing from trainers.json; nothing to challenge")
		_report()
		return

	if not bool(_director.call("no_usable_ally")):
		_fail("no_usable_ally() is false before the revive -- the trap this test exists "
			+ "to catch is not actually set up")
		_report()
		return
	if bool(_director.call("can_challenge", spec)):
		_fail("can_challenge() is true before the revive; nothing was proven")
		_report()
		return
	print("setup confirmed: active creature fainted, ally_body null, "
		+ "no_usable_ally=true, can_challenge=false")

	# Seed a Revive and open the real Satchel.
	var inventory: RefCounted = game.get("inventory")
	inventory.call("add", "revive", 1)
	var slot := int(inventory.call("find_slot", "revive"))
	if slot < 0:
		_fail("the revive item never reached a satchel slot")
		_report()
		return

	var menu: CanvasLayer = game.call("menu")
	menu.call("open", "backpack")
	for i in 8:
		await process_frame
	var body := _tab_body(menu, "backpack")
	if body == null:
		_fail("could not open the Satchel tab")
		_report()
		return
	var buttons: Array = body.get("_buttons")
	if slot >= buttons.size():
		_fail("the revive landed in slot %d, past the rendered grid" % slot)
		_report()
		return
	(buttons[slot] as Button).grab_focus()
	await process_frame

	var use_button := _pad_button_for(USE_ACTION)
	if use_button < 0:
		_fail("%s has no joypad binding; a controller cannot reach this screen" % USE_ACTION)
		_report()
		return

	await _pad(use_button)
	if int(body.get("_targeting")) < 0:
		_fail("a pad press of %s on the Revive opened no picker at all" % USE_ACTION)
		_report()
		return
	print("  ok    Use on Revive opened the target picker")

	var active_index := int(party.call("active_index"))
	body.call("_on_target_row", active_index)
	for i in 30:
		await physics_frame
	if int(body.get("_targeting")) != -1:
		_fail("confirming the revive on the fainted creature's row left the picker open")
	if bool(active.get("fainted")):
		_fail("the creature is still fainted after the revive")
	print("  ok    the fainted creature was revived through the real menu")

	menu.call("close")
	for i in 10:
		await process_frame

	# The bar this whole test exists to clear: no creature_recall press
	# anywhere above this line.
	if _director.call("ally_body") == null:
		_fail("ally_body() is still null after the revive -- a Revive used from "
			+ "the Satchel does not put the party's active creature back beside "
			+ "the trainer; the player must press recall by hand. This is "
			+ "GAME2.11: the healed party still cannot start the next fight.")
	if bool(_director.call("no_usable_ally")):
		_fail("no_usable_ally() is still true after the revive")
	if not bool(_director.call("can_challenge", spec)):
		_fail("can_challenge() is still false after the revive; the practice_trainer "
			+ "fight cannot be started without a manual recall press")
	else:
		print("  ok    can_challenge(practice_trainer) is true -- a trainer fight can "
			+ "start without pressing recall")

	_report()


func _tab_body(menu: CanvasLayer, tab_id: String) -> Node:
	var tabs: Array = menu.get("_tabs") as Array
	var bodies: Array = menu.get("_bodies") as Array
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == tab_id:
			menu.call("select", i)
			return bodies[i] as Node
	return null


func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


## A real controller button, the way hardware delivers it -- routed through
## the InputMap rather than an InputEventAction, matching
## `smoke_backpack_player_eats.gd::_pad()`.
func _pad(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await process_frame


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("revive redeploy: OK -- a Revive used from the Satchel puts the active "
			+ "creature back out without a recall press.")
		quit(0)
		return
	for line in _failures:
		print("revive redeploy FAIL: %s" % line)
	quit(1)
