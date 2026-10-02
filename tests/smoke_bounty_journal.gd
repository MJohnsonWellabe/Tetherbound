extends SceneTree

## UI lifecycle regression using the ordinary Game/menu and a disclosed
## personal-board fixture. This is not proof of earned or paid bounties.
const TAB := preload("res://scripts/ui/tab_quest_log.gd")
var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game := root.get_node(^"Game")
	var local: RefCounted = game.get("local")
	var personal: Dictionary = local.get("redesign_character")
	var character: String = str(local.get("character_id"))
	var instance := "journal-fixture".sha256_text()
	personal["bounties"] = {"anchor_world": "journal-world", "anchor_day": 1, "cycle": 1,
		"slots": [{"instance": instance, "template": "meadows_defeat_alpha", "complete": false},
			{"instance": "trait".sha256_text(), "template": "meadows_catch_trait", "complete": false},
			{"instance": "rematch".sha256_text(), "template": "meadows_rematch", "complete": false}]}
	var tab := TAB.new()
	tab.menu = game.call("menu")
	root.add_child(tab)
	tab.build()
	var focus := tab.first_focus()
	_check(is_instance_valid(focus), "production Research entry is available")
	var story_revision: int = int(game.get("progression").get("revision"))
	_check(_rows(tab).contains("In progress"), "initial personal bounty is shown")
	personal.bounties.slots[0].complete = true
	tab.poll()
	_check(_rows(tab).contains("Return to board"), "completed bounty refreshes without story progress")
	personal.bounty_receipts.append("bounty:%s:%s" % [instance, character])
	tab.poll()
	_check(_rows(tab).contains("Claimed"), "personal paid receipt refreshes journal")
	personal.bounties.slots[0] = {"instance": "tomorrow".sha256_text(), "template": "meadows_material_delivery", "complete": false}
	tab.poll()
	_check(_rows(tab).contains("Deliver 6 wood"), "new morning replaces yesterday's title")
	_check(not _rows(tab).contains("Defeat an alpha"), "old rows leave the journal")
	_check(tab.first_focus() == focus, "refresh preserves Research button and focus graph")
	_check(int(game.get("progression").get("revision")) == story_revision, "fixture changed no story progression")
	tab.queue_free()
	await process_frame
	for failure: String in _failures: push_error(failure)
	print("BOUNTY JOURNAL: PASS" if _failures.is_empty() else "BOUNTY JOURNAL: FAIL")
	quit(0 if _failures.is_empty() else 1)

func _rows(tab: Control) -> String:
	var lines: Array[String] = []
	var list: VBoxContainer = tab.get("_bounty_list")
	if list != null:
		for child: Node in list.get_children():
			if child is Label: lines.append(child.text)
	return "\n".join(lines)

func _check(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
