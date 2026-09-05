extends SceneTree

## GATE-E persistence, through the REAL save/load path.
##
##   godot --headless --path . --script tests/smoke_finale_persistence.gd
##
## `smoke_stronghold_reload.gd` proves that a FRESH WORLD reads finale flags
## correctly when they are set directly on `Game.progression` before the
## scene builds -- a strong test of `StrongholdClimax.build()`'s own guards,
## but not a test of SAVING at all: it never calls `Game.save_game()` and
## never calls `Game.load_game()`, so it cannot catch a defect that only
## exists in `save_game.gd`'s own JSON round trip (`_party_to_array` /
## `_array_to_party`, `progression.save_data()` / `load_data()`, a field that
## silently fails to serialize, a slot file that never gets read back
## correctly). The Gate 3 coordinator's brief for this lane calls exactly
## that gap out: "test it by actually saving and reloading, not by
## asserting a flag was written."
##
## So this file does what that one does not: build a party and a flag set
## for each finale window, call `Game.save_game(slot)` (the real
## `user://saves/slot_N.json` write, same path `camp.gd`'s autosave and the
## manual save menu both use), throw the whole scene away, boot a second
## fresh one, and call `Game.load_game(slot)` -- the same call a player's
## "Continue" does -- before asking any of the same questions
## `smoke_stronghold_reload.gd` asks about the freshly BUILT world. If the
## flags, the party, or the climax's own stage disagree with what was saved,
## this is where that would show up; the other file cannot see it.
##
## Two windows, same as `smoke_stronghold_reload.gd`, for the same reason:
## the ordinary case (a player saves any time after the ceremony resolves)
## and the narrow risky one (the lever was pulled but the roster decision
## was not yet made when the autosave landed -- real, because the dialogue
## panel does not pause the tree the way the ceremony's own menu does).
## A third scenario below is new: a save taken WHILE the release ceremony's
## menu is actually open, mid-decision -- `Game.pending_catch` is
## deliberately never saved (`game_state.gd`'s own comment: "the player
## cannot walk around owning six"), so this is the sharpest version of "does
## a reload lose or duplicate the offer" this lane can construct.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const SLOT := 3

var _failures: Array[String] = []
var _game: Node = null


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	await _boot_world()
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("finale-persistence FAIL: no Game autoload")
		quit(1)
		return

	await _settled_ending_round_trips_through_a_real_save()
	_game.get("progression").call("load_data", {})
	await _freed_but_unsettled_round_trips_through_a_real_save()
	_game.get("progression").call("load_data", {})
	await _a_save_mid_ceremony_does_not_lose_or_duplicate_the_offer()

	print("")
	if _failures.is_empty():
		print("finale persistence smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## --- scenario 1: the ordinary case -------------------------------------

func _settled_ending_round_trips_through_a_real_save() -> void:
	var party: RefCounted = _game.get("party")
	_fill_party_of_five(party, true)
	for flag in ["defeated_warden", "legendary_freed", "legendary_joined",
			"legendary_settled", "meadows_acknowledged"]:
		_game.get("progression").call("set_flag", flag)

	if not bool(_game.call("save_game", SLOT)):
		_fail("(settled) Game.save_game() returned false; the write itself failed")
		return

	var world := await _boot_world()
	if not bool(_game.call("load_game", SLOT)):
		_fail("(settled) Game.load_game() returned false after a save that just succeeded")
		return
	for i in 20:
		await physics_frame

	var loaded_party: RefCounted = _game.get("party")
	if int(loaded_party.call("size")) != 5:
		_fail("(settled) reloaded party holds %d, not 5" % int(loaded_party.call("size")))
	var veridian_count := 0
	for member: Variant in (loaded_party.call("members") as Array):
		if str((member as RefCounted).get("species_id")) == "veridian":
			veridian_count += 1
	if veridian_count != 1:
		_fail("(settled) reloaded party holds %d veridian, not exactly 1 -- a real save-round-trip duplicate/loss" % veridian_count)

	var climax := world.get_node_or_null(^"StrongholdClimax")
	if climax == null:
		_fail("(settled) the reloaded world built no StrongholdClimax")
		return
	if climax.call("legendary_body") != null:
		_fail("(settled) a REAL save/load round trip still stood a Bound Legendary body back up")
	if str(climax.get("_stage")) != "done":
		_fail("(settled) the reloaded climax's stage is '%s', not 'done'" % str(climax.get("_stage")))
	var prompt := world.find_child("MachinePrompt", true, false)
	if prompt != null and bool(prompt.get("enabled")):
		_fail("(settled) the machine control is still live after a real reload of the settled ending")

	var healing := world.get_node_or_null(^"MeadowHealing")
	if healing == null:
		_fail("(settled) the reloaded world built no MeadowHealing node")
	elif not bool(healing.call("applied")):
		_fail("(settled) the reloaded world did not re-apply healing from the saved 'legendary_freed' flag")
	else:
		print("settled ending, through a real save/load round trip: 5 party (1 veridian), no caged legendary, "
			+ "stage 'done', machine refused, healing re-applied")

	# CL-G5: the Hall's garrison is withdrawn ON LOAD too -- a save carrying
	# `legendary_freed` must come back to a dark, unmanned gate, not to the
	# fires and sentries the player watched stand down before saving.
	var watcher: Node = climax.call("garrison_withdrawal")
	var hold := world.get_node_or_null(^"Stronghold")
	if watcher == null or hold == null:
		_fail("(settled) the reloaded climax hung no garrison watcher off the Hall")
	elif not bool(watcher.call("withdrawn")):
		_fail("(settled) the reloaded Hall's garrison is back at its posts with 'legendary_freed' saved")
	else:
		var sentries: Node3D = hold.find_child("GateSentries", false, false) as Node3D
		var lit := 0
		var fires: Node = hold.find_child("HallBraziers", false, false)
		if fires != null:
			for light in fires.find_children("*", "Light3D", true, false):
				if (light as Light3D).visible:
					lit += 1
		if (sentries != null and sentries.visible) or lit > 0:
			_fail("(settled) after reload the gate is still manned (%s) or lit (%d fires)" % [
				str(sentries != null and sentries.visible), lit])
		else:
			print("settled ending: the Hall's garrison came back withdrawn (%s)" % str(watcher.call("withdrawal_report")))


## --- scenario 2: the narrow risky window --------------------------------

func _freed_but_unsettled_round_trips_through_a_real_save() -> void:
	var party: RefCounted = _game.get("party")
	_fill_party_of_five(party, false)
	for flag in ["defeated_warden", "legendary_freed"]:
		_game.get("progression").call("set_flag", flag)

	if not bool(_game.call("save_game", SLOT)):
		_fail("(freed) Game.save_game() returned false")
		return

	var world := await _boot_world()
	if not bool(_game.call("load_game", SLOT)):
		_fail("(freed) Game.load_game() returned false after a save that just succeeded")
		return
	for i in 20:
		await physics_frame

	var loaded_party: RefCounted = _game.get("party")
	if int(loaded_party.call("size")) != 5:
		_fail("(freed) reloaded party holds %d, not the full five that was saved" % int(loaded_party.call("size")))
	for member: Variant in (loaded_party.call("members") as Array):
		if str((member as RefCounted).get("species_id")) == "veridian":
			_fail("(freed) the not-yet-joined legendary is already on the reloaded belt; it should still be offered")

	var climax := world.get_node_or_null(^"StrongholdClimax")
	if climax == null:
		_fail("(freed) the reloaded world built no StrongholdClimax")
		return
	var legendary: Node3D = climax.call("legendary_body") as Node3D
	if legendary == null:
		_fail("(freed) after a real reload the legendary never came back at all; the join offer is unreachable")
		return
	if legendary.get_node_or_null(^"ContainmentVFX") != null:
		_fail("(freed) after a real reload the legendary is standing caged even though 'legendary_freed' was saved")

	for i in 12:
		await physics_frame
	var stage := str(climax.get("_stage"))
	if stage != "freed" and stage != "join" and stage != "ceremony" and stage != "done":
		_fail("(freed) the reloaded climax's stage is '%s'; the sequence did not resume toward the join offer" % stage)
	else:
		print("freed-not-settled window, through a real save/load round trip: legendary back freed (not caged), "
			+ "stage resumed to '%s', no premature join" % stage)


## --- scenario 3: a save taken WHILE the ceremony's own menu is open -----
##
## `pending_catch` is deliberately excluded from the save format
## (`game_state.gd`'s own comment). This asks the sharpest version of the
## question: does that omission LOSE the offer on reload (the player who
## saved mid-decision comes back to a legendary that vanished, never
## on the belt, never offered again), or does the climax's own re-entry
## into STAGE_CEREMONY correctly re-park it once the fresh world notices
## the belt is still full?
##
## FIRST DRAFT OF THIS SCENARIO WAS WRONG and is worth recording rather than
## quietly fixing: it set the same two flags scenario 2 sets, saved
## immediately, and then waited 300 frames on the RELOAD with no input,
## expecting `pending_catch` to appear on its own. It does not, and that is
## not a bug -- `_advance()`'s STAGE_FREED -> STAGE_JOIN transition opens the
## join-offer CONVERSATION (`_offer_to_join()`), and `_panel_busy()` blocks
## STAGE_JOIN -> STAGE_CEREMONY (the transition that actually sets
## `pending_catch`) until that conversation is dismissed. A save taken right
## after the lever is pulled has not reached the ceremony yet by definition,
## so scenario 2 already covers it; asserting `pending_catch` should exist
## with zero input driven was testing a state the game was never in. This
## version DRIVES the join conversation closed first, so `pending_catch` is
## genuinely non-null at the moment of save -- the actual "mid-ceremony"
## window scenario 2 cannot reach.
func _a_save_mid_ceremony_does_not_lose_or_duplicate_the_offer() -> void:
	var party: RefCounted = _game.get("party")
	_fill_party_of_five(party, false)
	for flag in ["defeated_warden", "legendary_freed"]:
		_game.get("progression").call("set_flag", flag)

	var world := await _boot_world()
	var panel := world.get_node_or_null(^"DialoguePanel")
	if panel == null:
		_fail("(mid-ceremony) no DialoguePanel in the world; cannot drive the join conversation")
		return
	# Drive the climax's own stage machine through STAGE_FREED -> STAGE_JOIN
	# -> STAGE_CEREMONY the way a real player does: dismiss whatever
	# conversation is open, the same technique smoke_gate_e_finale.gd's
	# `_pull_the_lever()` uses.
	var reached_ceremony := false
	for i in 600:
		await physics_frame
		if bool(panel.call("is_open")):
			await _press("interact")
		if _game.get("pending_catch") != null:
			reached_ceremony = true
			break
	if not reached_ceremony:
		_fail("(mid-ceremony) could not drive the climax to the ceremony (pending_catch never appeared) "
			+ "within budget; the scenario cannot test what it is meant to")
		return
	var mid_ceremony_creature: RefCounted = _game.get("pending_catch")
	if str(mid_ceremony_creature.get("species_id")) != "veridian":
		_fail("(mid-ceremony) the pending catch reached before saving is '%s', not the legendary"
			% str(mid_ceremony_creature.get("species_id")))
		return

	# THE moment: save with the ceremony's own menu live and `pending_catch`
	# genuinely set, exactly as `game_state.gd`'s autosave could catch a
	# player sitting on this screen.
	if not bool(_game.call("save_game", SLOT)):
		_fail("(mid-ceremony) Game.save_game() returned false while pending_catch was live")
		return

	world = await _boot_world()
	if not bool(_game.call("load_game", SLOT)):
		_fail("(mid-ceremony) Game.load_game() returned false")
		return
	# Same drive again: `pending_catch` was never saved, so the climax has to
	# re-derive the offer through its own stage machine, which means
	# re-showing (and this time re-dismissing) the same join conversation.
	var pending: Variant = null
	for i in 600:
		await physics_frame
		var panel2 := world.get_node_or_null(^"DialoguePanel")
		if panel2 != null and bool(panel2.call("is_open")):
			await _press("interact")
		pending = _game.get("pending_catch")
		if pending != null:
			break

	var loaded_party: RefCounted = _game.get("party")
	var party_full := bool(loaded_party.call("is_full"))
	if party_full and pending == null:
		_fail("(mid-ceremony) after a real reload of a save taken WITH the ceremony live, the belt is still full "
			+ "and nothing re-offered the legendary -- the offer was LOST across the save, not merely re-asked")
		return
	if pending != null and str((pending as RefCounted).get("species_id")) != "veridian":
		_fail("(mid-ceremony) something other than the legendary is sitting on the reload's own pending-catch seam")
	var veridian_on_belt := 0
	for member: Variant in (loaded_party.call("members") as Array):
		if str((member as RefCounted).get("species_id")) == "veridian":
			veridian_on_belt += 1
	if veridian_on_belt > 0:
		_fail("(mid-ceremony) the legendary is already on the belt after a reload -- the ceremony was never "
			+ "actually resolved before this scenario saved, so this would be a duplicate/skip")
	else:
		print("mid-ceremony reload: a save taken WITH the ceremony live re-offers the legendary correctly "
			+ "(pending_catch=veridian), belt untouched, no duplicate, no loss")


## --- harness ----------------------------------------------------------------

func _fill_party_of_five(party: RefCounted, include_veridian: bool) -> void:
	party.call("clear")
	var recipe: Array = ["terrapup", "mudsnout", "bramblebun", "brooktail", "tuskroot"]
	if include_veridian:
		recipe[4] = "veridian"
	for species: String in recipe:
		var creature: RefCounted = _game.call("make_creature", species, species.capitalize())
		if creature == null:
			_fail("could not build '%s' from species.json" % species)
			continue
		creature.set("hp", float(creature.get("max_hp")))
		party.call("add", creature)


## Same technique `smoke_stronghold_reload.gd` documents: `Game` is the one
## autoload that survives every world swap, so only the scene under it is
## thrown away and rebuilt -- the same shape a real "load game" hands a
## freshly-read save to a from-nothing scene.
func _boot_world() -> Node:
	for child in root.get_children():
		if child.name != "Game":
			child.queue_free()
	for i in 4:
		await process_frame
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame
	return world


## Same technique every other smoke test in this suite uses
## (`smoke_gate_e_finale.gd`, `smoke_release.gd`): a real injected input
## event, not a poll, because `Input.action_press` alone does not reach a
## `_gui_input`/UI action binding the way `parse_input_event` does.
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
