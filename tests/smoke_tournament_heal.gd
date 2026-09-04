extends SceneTree

## G3-OPENING-FIX-0904 (2.10). The owner instruction "give revives after the
## tournament" (2026-09-03), proven live. GATE2-EVIDENCE-0903 measured the
## tournament's three rounds reliably leaving three of five creatures on 0
## HP, with nothing between the arena and the South Bridge gatekeeper ever
## picking the team back up. `tournament_final_beaten` (data/dialogue/bands/
## band1_lower_meadows.json) now carries a `heal_party` effect, drained by
## `sequence_director.gd::_drain_effects()` the same seam
## `smoke_village_smith.gd` already proved reaches the real satchel for
## `give:` -- this proves it reaches the real party for `heal_party`.
##
## Deliberately does not play a real three-round tournament (`tournament.gd`'s
## own concern, and expensive); starts `tournament_final_beaten` exactly the
## way `trainer_npc.gd::_on_conversation_finished` does on a real win, on a
## party battered the way GATE2-EVIDENCE-0903 measured it.
##
##   godot --headless --path . --script tests/smoke_tournament_heal.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SETTLE_FRAMES := 240
const CONVERSATION := "tournament_final_beaten"

var _failures: Array[String] = []
var _game: Node = null
var _panel: Node = null
var _world: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		print("FAIL: could not load %s" % SCENE)
		quit(1)
		return

	_world = packed.instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"/root/Game")
	if _game == null:
		_fail("no Game autoload; nothing can be healed")
		_report()
		return
	_panel = get_first_node_in_group("dialogue_panel")
	if _panel == null:
		_fail("nothing is in the 'dialogue_panel' group; nowhere for the conversation to open")
		_report()
		return

	var party: RefCounted = _game.get("party")
	if party == null:
		_fail("no Game.party")
		_report()
		return

	# Build a battered five-creature team, matching GATE2-EVIDENCE-0903's own
	# measured state: three fainted, the rest short of full.
	var faint_at := [0, 2, 4]
	for i in 5:
		var creature: RefCounted = SPECIES.spawn("terrapup")
		if creature == null:
			_fail("species.json has no terrapup to build a party from")
			_report()
			return
		party.call("add", creature)
		if i in faint_at:
			creature.call("take_damage", float(creature.get("max_hp")) * 2.0)
		else:
			creature.call("take_damage", float(creature.get("max_hp")) * 0.7)

	var fainted_before := 0
	var hurt_before := 0
	for i in int(party.call("size")):
		var creature: RefCounted = party.call("at", i)
		if bool(creature.get("fainted")):
			fainted_before += 1
		elif float(creature.call("hp_fraction")) < 1.0:
			hurt_before += 1
	if fainted_before == 0:
		_fail("the setup produced no fainted creature; GATE2-EVIDENCE-0903's own state was not reproduced")
		_report()
		return
	print("before: %d fainted, %d hurt (of %d)" % [
		fainted_before, hurt_before, int(party.call("size"))])

	if not bool(_panel.call("start", CONVERSATION)):
		_fail("the dialogue panel refused to start '%s'" % CONVERSATION)
		_report()
		return
	var guard := 0
	while bool(_panel.call("is_open")) and guard < 64:
		await process_frame
		_panel.call("advance")
		guard += 1
	await process_frame
	await process_frame
	if guard >= 64:
		_fail("'%s' never closed" % CONVERSATION)

	var fainted_after := 0
	var short_of_full_after := 0
	for i in int(party.call("size")):
		var creature: RefCounted = party.call("at", i)
		if bool(creature.get("fainted")):
			fainted_after += 1
		if float(creature.call("hp_fraction")) < 1.0:
			short_of_full_after += 1
	print("after: %d fainted, %d short of full HP" % [fainted_after, short_of_full_after])

	if fainted_after > 0:
		_fail("%d creature(s) still fainted after '%s'; heal_party did not revive them" % [
			fainted_after, CONVERSATION])
	if short_of_full_after > 0:
		_fail("%d creature(s) still short of full HP after '%s'" % [
			short_of_full_after, CONVERSATION])
	if _failures.is_empty():
		print(("the whole party (%d fainted, %d hurt) came back full after the tournament's own "
			+ "closing line") % [fainted_before, hurt_before])

	_report()


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("tournament heal: OK — the champion beat restores the whole party, no menu recovery needed.")
		quit(0)
		return
	for line in _failures:
		print("tournament heal FAIL: %s" % line)
	quit(1)
