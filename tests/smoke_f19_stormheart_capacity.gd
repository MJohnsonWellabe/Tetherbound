extends "res://tests/smoke_stormwood_stormheart_choice.gd"

## Real Stormheart dialogue and five-holder roster UI in the inherited scene
## fixture. Hub/chapter/Dynamo remain disclosed stubs, with no host ACK or
## earned-fight claim. Every newcomer is the production level55 Fulgocobra.
var _case := ""
var _game: Node

func _run() -> void:
	_game = root.get_node("Game")
	var conversations: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/stormwood.json")).conversations
	for id: String in conversations: RUNNER.table()[id] = conversations[id].duplicate(true)
	for choice: String in ["refuse-at-prompt", "accept-let-newcomer-go", "accept-release-owned-holder"]:
		_case = choice
		_game.reset_for_new_game()
		_game.current_realm = "stormwood"
		_game.local.character_id = CHARACTER
		for index: int in 5:
			var keeper: RefCounted = _game.make_creature("terrapup", "Keeper %d" % (index + 1))
			_game.party.add(keeper)
		var original := _uids()
		_check(original.size() == 5, "declared fixture starts with exactly five owned holders")
		var mounted := await _mount(_game, "f19-stormheart-" + choice)
		await _offer(mounted.ending, mounted.panel, _game)
		await _to_question(mounted.panel)
		if choice == "refuse-at-prompt":
			await _press_decline()
			await _frames(3)
			_check(_uids() == original and _game.pending_catch == null, "prompt refusal retains all five and no newcomer")
			_check(_receipt(_game) and not _accepted(_game), "prompt refusal records an answer without acceptance")
		else:
			mounted.panel.runner().advance()
			await _frames(6)
			var pending: RefCounted = _game.pending_catch
			_check(pending != null and _uids() == original, "acceptance at capacity keeps newcomer pending outside five holders")
			if pending == null:
				await _unmount(mounted)
				continue
			_check(pending.species_id == ENDING.LEGENDARY_SPECIES and pending.level == 55, "actual new-order finale offer is Fulgocobra at level55")
			var menu: Node = _game.menu()
			var tab: Node
			for index: int in menu.get("_tabs").size():
				if menu.get("_tabs")[index].id == "creatures": tab = menu.get("_bodies")[index]
			_check(tab != null and menu.is_open() and tab.get("_release_stage") == "choose", "actual five-holder release choice opens")
			if tab == null or tab.get("_release_stage") != "choose":
				await _unmount(mounted)
				continue
			if choice == "accept-release-owned-holder":
				(tab.get("_rows")[0] as Control).grab_focus() # Disclosed focus fixture; all choices are native button input.
			await _tap("ui_accept")
			_check(tab.get("_release_stage") == "confirm", "controller chooses a holder and sees farewell confirmation")
			var release: Control = tab.get("_farewell_release")
			release.grab_focus()
			await _tap("ui_accept")
			_check(tab.get("_release_stage") == "done" and _game.pending_catch == null, "controller farewell completes the actual roster choice")
			await _tap("ui_accept") # Back to the belt, already focused by actual UI.
			menu.close()
			await _frames(6) # Closing the real pause menu lets the ending consume its roster outcome.
			if choice == "accept-let-newcomer-go":
				_check(_uids() == original and not _holds_stormheart(_game), "letting newcomer go preserves the exact original five")
				_check(_receipt(_game) and not _accepted(_game), "declined pending newcomer never marks portable acceptance")
			else:
				_check(_game.party.size() == 5 and _game.party.at(4).uid == pending.uid, "kept Stormheart fills released capacity with exactly five owned")
				for index: int in range(1, 5): _check(_game.party.at(index - 1).uid == original[index], "other owned identity survives from holder%d" % index)
				_check(_receipt(_game) and _accepted(_game), "keeping newcomer records portable acceptance")
		var settled: Array = mounted.hub.intents.filter(func(intent: Dictionary) -> bool: return intent.kind == "ending_settled")
		_check(settled.size() == 1 and settled[0].kept == (choice == "accept-release-owned-holder"), "character sends exactly its original decision to host stub")
		print("F19 STORMHEART CAPACITY CASE " + JSON.stringify({"case": choice, "party": _uids(), "pending": _game.pending_catch != null, "failures": failures.duplicate()}))
		await _unmount(mounted)
	_finish()

func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await physics_frame
	await physics_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await _frames(3)

func _uids() -> Array:
	return _game.party.members().map(func(creature: RefCounted) -> String: return str(creature.uid))

func _frames(count: int) -> void:
	for index: int in count:
		await process_frame
		if _game != null: _check(_game.party.size() <= 5, "owned roster never acquires a sixth during " + _case)
