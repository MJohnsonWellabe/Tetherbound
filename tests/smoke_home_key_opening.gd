extends "res://tests/smoke_save_redesign_title.gd"

## F18#0 gift/death witness. Reuses the physical title/bed/house-dialogue path.
## Naming and the production death callback are explicit harness shortcuts.

func _exercise_grandpa_opening(sequence: Node, game: Node) -> void:
	await super._exercise_grandpa_opening(sequence, game)
	if not _failures.is_empty():
		return
	await _opening_pad(&"menu_confirm")
	var naming: CanvasLayer = sequence.get("_name_prompt")
	for index in 90:
		if bool(naming.call("is_open")):
			break
		await physics_frame
	if not bool(naming.call("is_open")):
		_fail("physical starter confirmation did not open the real creature name prompt")
		return
	# The actual naming panel starts empty. Enter a real grid letter rather than
	# assuming that the species label is an accepted name, then use the disclosed
	# production confirmation callback to avoid a second grid-navigation fixture.
	if str(naming.call("current_text")).is_empty():
		await _opening_pad(&"menu_confirm")
	if str(naming.call("current_text")).is_empty():
		_fail("physical naming-grid confirmation did not enter a name")
		return
	print("HomeKey naming observation: controller grid entered '%s'; _confirm callback disclosed." % str(naming.call("current_text")))
	naming.call("_confirm")
	for index in 240:
		if sequence.call("beat") == "return_starter":
			break
		await physics_frame
	if sequence.call("beat") != "return_starter" or game.party.size() != 1:
		_fail("named starter was not admitted through the real opening path")
		return
	var dialogue: CanvasLayer = sequence.get("_dialogue")
	var grandpa: Node3D = sequence.get("_grandpa_prompt")
	var arbiter: Node = sequence.get("_arbiter")
	for index in 120:
		if arbiter.call("winning_provider") == grandpa:
			break
		await physics_frame
	if arbiter.call("winning_provider") != grandpa:
		_fail("the required return to Grandpa was not reachable from the existing disclosed position")
		return
	await _opening_pad(&"interact")
	var runner: RefCounted = dialogue.call("runner")
	if not bool(dialogue.call("is_open")) or runner.call("conversation_id") != "grandpa_first_catch":
		_fail("real Grandpa interaction did not open the Home Key gift conversation")
		return
	var authored: Dictionary = DIALOGUE_RUNNER.table()["grandpa_first_catch"]
	var expected: Array[String] = []
	var gifts: Dictionary = {}
	for raw: Variant in authored.lines:
		var row: Dictionary = raw if raw is Dictionary else {"text": str(raw)}
		expected.append(str(row.get("text", "")))
		var effect: PackedStringArray = str(row.get("effect", "")).split(":")
		if effect.size() == 3 and effect[0] == "give":
			gifts[effect[1]] = int(gifts.get(effect[1], 0)) + int(effect[2])
	var seen: Array[String] = []
	for index in 48:
		if not bool(dialogue.call("is_open")):
			break
		var text := str((runner.call("line") as Dictionary).get("text", ""))
		if seen.is_empty() or seen.back() != text:
			seen.append(text)
		_check_authored_satchel(game, gifts, false)
		await _opening_pad(&"interact")
	if bool(dialogue.call("is_open")) or seen != expected:
		_fail("Home Key gift did not complete every actual authored line through physical dialogue taps")
		return
	_check_authored_satchel(game, gifts, true)
	var key_slot := -1
	for index in game.inventory.slot_count():
		if str(game.inventory.stack_at(index).get("id", "")) == "home_key":
			key_slot = index
	if key_slot < 0 or game.inventory.count("home_key") != 1:
		_fail("the actual opening did not grant exactly one backpack Home Key")
		return
	var transport: Node = game.get("ledger")
	var player: CharacterBody3D = sequence.get("_player")
	var before_count: int = game.world.death_satchels.size()
	# Simulate the event through the exact production death transaction entry;
	# no actual falling/drowning damage is claimed by this bounded witness.
	var result: Dictionary = transport.call("drop_satchel", player.global_position, str(game.current_realm))
	if not bool(result.get("ok", false)) or game.world.death_satchels.size() != before_count + 1:
		_fail("production death callback did not commit the ordinary gift satchel")
		return
	if game.inventory.count("home_key") != 1 or str(game.inventory.stack_at(key_slot).get("id", "")) != "home_key":
		_fail("production death moved or lost the personal key")
	var dropped: Dictionary = {}
	for raw: Variant in game.world.death_satchels.back().state:
		if raw != null:
			dropped[str(raw.id)] = int(dropped.get(str(raw.id), 0)) + int(raw.n)
	var ordinary := gifts.duplicate(true)
	ordinary.erase("home_key")
	if dropped != ordinary:
		_fail("world death satchel differs from the exact normal authored gifts: %s" % str(dropped))
	if not bool(game.call("autosave_here")) or not bool(game.save_system.load_slot(game, 0)):
		_fail("production save/reload of the protected key/death satchel refused")
		return
	if game.inventory.count("home_key") != 1 or str(game.inventory.stack_at(key_slot).get("id", "")) != "home_key":
		_fail("actual file reload did not retain exactly the original key slot")
	if game.world.death_satchels.size() != before_count + 1:
		_fail("actual file reload did not retain the committed ordinary death satchel")
	print("F18 Home Key opening observations: physical starter choice and all %d first-catch gift lines; exact gifts %s; protected slot %d survives production death callback and actual save/reload. Shortcuts disclosed: inherited isolated saves/refusal/title/trainer-name callbacks and loft-to-Grandpa placement; creature-name _confirm callback; injected joypad taps; direct LedgerRpc death callback simulates death, without health-triggered-death/device/visual/travel claims." % [seen.size(), str(gifts), key_slot])
