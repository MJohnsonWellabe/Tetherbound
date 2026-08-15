extends SceneTree

## OF30. Does Tam the blacksmith actually hand anything over?
##
##   godot --headless --path . --script tests/smoke_village_smith.gd
##
## **Headless, never under xvfb** — docs/HANDOFF.md §10, same as every other
## scene-booting test here.
##
## This is the test the OF30 brief asked for first, before any new plumbing was
## written: **does a VILLAGE conversation's `give:` effects reach the real
## satchel with the code that already exists?** The answer is yes, and the
## reason is a seam nobody planned — `sequence_director.gd::_drain_effects()`
## drains the ONE dialogue panel every frame and never asks whose conversation
## is in it, while `village_npcs.gd` opens village lines on that very panel
## (through the `dialogue_panel` group). So the effect pipeline Grandpa's
## briefing uses was already the villagers' pipeline too. Nothing in
## `village_npcs.gd` or `dialogue_panel.gd` had to learn about effects.
##
## It cannot live in `tests/test_dialogue_runner.gd` with the rest of the
## dialogue coverage: that runner drives plain objects, and the drain being
## proven here happens on a Node, in `_process`, reading `/root/Game`. Neither
## exists for the whole life of `tests/run_tests.gd` — see
## `tests/test_party_seam.gd`'s own note on `Engine.get_main_loop()` being null
## there. `test_dialogue_runner.gd` covers the DATA half (the conversation
## carries the right effects, spelled the way the director parses them) and
## `village_npcs.greeting_for()`'s branch selection; this covers the wiring.
##
## Deliberately does NOT walk to Tam. `smoke_opening.gd` already proves a
## villager-style prompt reaches `dialogue_panel.start()`; what is unproven is
## everything AFTER `start()`, so this starts the conversation exactly the way
## `village_npcs.gd::_on_greeted` does and spends its time on the effects.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const VILLAGERS_PATH := "res://data/config/village_npcs.json"
const VILLAGE_NPCS := preload("res://scripts/world/village_npcs.gd")

## Long enough for the terrain to build and the opening's cast to be stood on
## it. Matches smoke_playground's own settle.
const SETTLE_FRAMES := 240

## The flags OF30 introduces. Named here rather than typed inline so a rename
## in the dialogue data fails loudly in one place.
const TOOLS_FLAG := "tam_tools_given"
const RECIPE_FLAG := "recipe_orb_basic"

const TOOLS_CONVERSATION := "village_tam_tools"
const ORBS_CONVERSATION := "village_tam_orbs"

## What the handover is expected to contain. Three, not the owner's two — see
## data/dialogue/village.json's `_comment_of30_knife` and D42: without the
## knife, owning the other two makes fiber ungatherable outright.
const HANDOVER: Array[String] = ["axe", "pickaxe", "knife"]

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
		_fail("no Game autoload; nothing can be given to anybody")
		_report()
		return

	_panel = get_first_node_in_group("dialogue_panel")
	if _panel == null:
		_fail("nothing is in the 'dialogue_panel' group; village_npcs.gd has nowhere to speak")
		_report()
		return

	# Only the three that actually drive frames are awaited; the two selector
	# checks are plain calls, and `await`ing them would be the redundant kind.
	_the_branch_selector_offers_the_handover_first()
	await _the_handover_lands_the_smiths_tools_in_the_real_satchel()
	await _greeting_him_again_does_not_hand_over_a_second_set()
	await _the_follow_up_conversation_unlocks_the_orb_recipe()
	_after_both_he_goes_back_to_being_a_villager()

	_report()


## --- the branches -------------------------------------------------------------

## `greeting_when` in data/config/village_npcs.json, resolved against the LIVE
## flag store rather than a fixture. `test_dialogue_runner.gd` covers the
## selector's logic exhaustively; what this adds is that the real Tam entry in
## the real config points at conversations that really exist.
func _the_branch_selector_offers_the_handover_first() -> void:
	var progression: RefCounted = _game.get("progression")
	if progression == null:
		_fail("the Game autoload has no progression store")
		return
	# A save carried in from a previous run of this file would start with the
	# flags already set and every assertion below would be meaningless.
	progression.call("set_flag", TOOLS_FLAG, false)
	progression.call("set_flag", RECIPE_FLAG, false)

	var tam := _tam()
	if tam.is_empty():
		_fail("village_npcs.json has no villager named Tam")
		return
	var chosen := VILLAGE_NPCS.greeting_for(tam, progression)
	if chosen != TOOLS_CONVERSATION:
		_fail("a fresh save should greet Tam with '%s'; got '%s'" % [TOOLS_CONVERSATION, chosen])
	print("branch: fresh save -> %s" % chosen)


## The whole point. Opened the way a villager opens it, advanced the way the
## interact button advances it, and then the REAL satchel is asked.
func _the_handover_lands_the_smiths_tools_in_the_real_satchel() -> void:
	var inventory: RefCounted = _game.get("inventory")
	var before := {}
	for tool_id in HANDOVER:
		before[tool_id] = int(inventory.call("count", tool_id))

	await _play(TOOLS_CONVERSATION)

	for tool_id in HANDOVER:
		var after := int(inventory.call("count", tool_id))
		print("satchel: %s %d -> %d" % [tool_id, int(before[tool_id]), after])
		if after != int(before[tool_id]) + 1:
			_fail("Tam's handover should have added exactly one %s; %d -> %d" % [
				tool_id, int(before[tool_id]), after
			])

	var progression: RefCounted = _game.get("progression")
	if not bool(progression.call("has", TOOLS_FLAG)):
		_fail("the handover did not set '%s'; it would repeat forever" % TOOLS_FLAG)


## The one-time half of OF30's done-when. Re-greeting must not re-gift, and the
## mechanism is the branch no longer matching rather than the conversation
## refusing itself.
func _greeting_him_again_does_not_hand_over_a_second_set() -> void:
	var inventory: RefCounted = _game.get("inventory")
	var progression: RefCounted = _game.get("progression")
	var before := {}
	for tool_id in HANDOVER:
		before[tool_id] = int(inventory.call("count", tool_id))

	var chosen := VILLAGE_NPCS.greeting_for(_tam(), progression)
	if chosen == TOOLS_CONVERSATION:
		_fail("Tam is still offering the tool handover after giving it")
		return
	print("branch: after the handover -> %s" % chosen)

	await _play(chosen)

	for tool_id in HANDOVER:
		if int(inventory.call("count", tool_id)) != int(before[tool_id]):
			_fail("greeting Tam again handed over a second %s" % tool_id)


## The follow-up conversation is the one that unlocks the recipe, and the
## unlock has to be real: craftable, not merely flagged.
func _the_follow_up_conversation_unlocks_the_orb_recipe() -> void:
	var progression: RefCounted = _game.get("progression")
	if bool(progression.call("has", RECIPE_FLAG)):
		# _greeting_him_again already played the orbs conversation, which is the
		# expected path: the second branch is what it fell through to.
		print("recipe: unlocked by the follow-up conversation")
	else:
		var chosen := VILLAGE_NPCS.greeting_for(_tam(), progression)
		if chosen != ORBS_CONVERSATION:
			_fail("nothing offers '%s'; the orb recipe can never be taught" % ORBS_CONVERSATION)
			return
		await _play(chosen)

	if not bool(progression.call("has", RECIPE_FLAG)):
		_fail("the follow-up conversation did not set '%s'" % RECIPE_FLAG)
		return
	if not bool(_game.call("recipe_known", "orb_basic")):
		_fail("the flag is set but game_state still calls the orb recipe unknown")
	if not (_game.call("known_recipe_ids") as Array).has("orb_basic"):
		_fail("the orb recipe is known but the craft screen would not list it")

	# And it crafts. Materials are put in by hand -- gathering is OF20's.
	var inventory: RefCounted = _game.get("inventory")
	for requirement: Variant in (_game.call("recipe_cost_for", "orb_basic") as Array):
		var entry := requirement as Dictionary
		inventory.call("add", str(entry.get("id", "")), int(entry.get("n", 0)))
	var orbs := int(inventory.call("count", "orb_basic"))
	if not bool(_game.call("craft", "orb_basic")):
		_fail("the taught orb recipe still refuses to craft")
		return
	if int(inventory.call("count", "orb_basic")) != orbs + 1:
		_fail("crafting the orb produced nothing")
	print("recipe: orb_basic taught and crafted")


## Nothing left to hand over: he is a Field Scout with opinions about the
## bramblebun again, exactly as NP3 wrote him. This is the dual-role rule
## (D39/D42) holding — a vendor branch that ran out did not eat his greeting.
func _after_both_he_goes_back_to_being_a_villager() -> void:
	var progression: RefCounted = _game.get("progression")
	var chosen := VILLAGE_NPCS.greeting_for(_tam(), progression)
	if chosen != str(_tam().get("greeting", "")):
		_fail("with both branches spent Tam should fall back to '%s'; got '%s'" % [
			str(_tam().get("greeting", "")), chosen
		])
	print("branch: both spent -> %s" % chosen)


## --- driving ------------------------------------------------------------------

## Play a conversation to the end on the shared panel, one line per pass, with
## an idle frame between each so the director's per-frame drain actually runs.
## `advance()` is what the interact button calls; pressing the button itself is
## `smoke_opening.gd`'s job and is not what is in question here.
func _play(conversation_id: String) -> void:
	if not bool(_panel.call("start", conversation_id)):
		_fail("the dialogue panel refused to start '%s'" % conversation_id)
		return
	var guard := 0
	while bool(_panel.call("is_open")) and guard < 64:
		await process_frame
		_panel.call("advance")
		guard += 1
	await process_frame
	await process_frame
	if guard >= 64:
		_fail("'%s' never closed" % conversation_id)


func _tam() -> Dictionary:
	var file := FileAccess.open(VILLAGERS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	for entry: Variant in ((parsed as Dictionary).get("villagers", []) as Array):
		if entry is Dictionary and str((entry as Dictionary).get("name", "")) == "Tam":
			return entry as Dictionary
	return {}


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("smoke: OK")
		quit(0)
	else:
		for line in _failures:
			print("smoke FAIL: %s" % line)
		quit(1)
