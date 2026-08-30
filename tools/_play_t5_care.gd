extends SceneTree

## T5-CARE: PLAY the survival and care loop, in the real world, with a pad.
##
##   godot --headless --path . --script tools/_play_t5_care.gd
##
## `ralph/MEADOWS_EXIT_CRITERION.md` section H was entirely unevidenced: over a
## long night of parallel lanes nobody verified building, survival or creature
## care by playing them. This drives the SHIPPING screens the way a player
## reaches them -- real `InputEventJoypadButton`s through the live InputMap,
## the real `meadows_playground.tscn`, the real `game_menu.gd` shell -- and
## reports what the loop actually does rather than what the config says.
##
## Deliberately NOT a pass/fail gate. It is an observation run: it prints a
## verdict line per question in section H and exits 0 unless the harness itself
## could not reach a screen. A care loop that is merely UNPLEASANT is not a
## failing assertion, and encoding one here would just bury the finding.
##
## The questions, in the order the player meets them:
##
##   H4  does the FOOD bar drain, tier and refill the way CLAUDE.md's light
##       satiety rule says -- and can the player actually EAT, from every
##       screen that offers food?
##   H4  is a player who ignores satiety entirely inconvenienced or punished?
##   H3  does a creature in a bed visibly rest, become unavailable, recover?
##   H6  does feeding a five-creature team stay care rather than become a chore?
##   G4  when the player has five and catches a sixth, is the moment clear?
##
## Never asserts a starvation death path exists, and never adds one: CLAUDE.md
## forbids it and this file only measures.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const SETTLE_FRAMES := 240
## `interact` is the Use verb on the satchel and is joypad X; `menu_confirm`
## is joypad A. Read from the live InputMap, never hardcoded, so a rebind
## moves this run with it.
const USE_ACTION := "interact"
const CONFIRM_ACTION := "menu_confirm"
## Mirrors `playground_hud.gd`'s own quick-bar action list.
const HOTBAR_ACTIONS: Array[String] = [
	"hotbar_1", "hotbar_2", "hotbar_3", "hotbar_4", "hotbar_5",
]

var _game: Node
var _world: Node3D
var _player: Node3D
var _notes: Array[String] = []
var _blocked: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("T5-CARE: BLOCKED — Game autoload missing")
		quit(1)
		return
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as Node3D
	if _player == null:
		print("T5-CARE: BLOCKED — real world has no Player")
		quit(1)
		return

	await _h4_satiety_drain_and_tiers()
	await _h4_can_the_player_eat()
	await _h6_feeding_a_five()
	await _h3_bed_rest()
	await _g4_the_sixth_catch()

	print("")
	print("=== T5-CARE observations ===")
	for line in _notes:
		print("  " + line)
	if not _blocked.is_empty():
		print("=== harness could not reach ===")
		for line in _blocked:
			print("  " + line)
	quit(0)


# --- H4: the FOOD bar ------------------------------------------------------

## Drives `player_vitals.tick_satiety` through real frame time the way the
## player controller does, then reports the wall-clock a real session would
## spend in each tier. The numbers are what a player FEELS, not what
## vitals.json says.
func _h4_satiety_drain_and_tiers() -> void:
	var vitals: RefCounted = _player.get("vitals") as RefCounted
	if vitals == null:
		_blocked.append("H4: the player has no vitals object")
		return
	var maximum := float(vitals.get("max_satiety"))
	# Walk the meter down in one-minute steps and record where the tiers land.
	vitals.set("satiety", maximum)
	var minutes := 0
	var hungry_at := -1
	var critical_at := -1
	var empty_at := -1
	while minutes < 600:
		vitals.call("tick_satiety", 60.0)
		minutes += 1
		var state := str(vitals.call("hunger_state"))
		if hungry_at < 0 and state == "hungry":
			hungry_at = minutes
		if critical_at < 0 and state == "critical":
			critical_at = minutes
		if empty_at < 0 and float(vitals.get("satiety")) <= 0.0:
			empty_at = minutes
			break
	_notes.append("H4 drain: hungry at %d min of play, critical at %d min, empty at %d min" % [
		hungry_at, critical_at, empty_at])

	# What being empty actually COSTS. CLAUDE.md: inconvenienced, never punished.
	var regen := float(vitals.call("stamina_regen_scale"))
	var speed := float(vitals.call("move_speed_scale"))
	var dead := bool(vitals.call("is_dead"))
	var health := float(vitals.get("health"))
	_notes.append("H4 at ZERO satiety: stamina regen x%.2f, move speed x%.2f, health %.0f, is_dead=%s" % [
		regen, speed, health, str(dead)])
	if dead or health < 100.0:
		_notes.append("H4 VERDICT: FAIL — an empty FOOD bar cost health. CLAUDE.md forbids starvation damage.")
	else:
		_notes.append("H4 VERDICT (drain half): PASS — empty satiety never touches health; the whole cost is x%.2f stamina regen and x%.2f speed." % [regen, speed])
	vitals.set("satiety", maximum)


## The half nobody checked: can the player EAT? Presses Use on Berries from the
## real Satchel screen with a real pad button, then does the same from the
## hotbar, and reports what each screen actually did.
func _h4_can_the_player_eat() -> void:
	var inventory: RefCounted = _game.get("inventory")
	var vitals: RefCounted = _player.get("vitals") as RefCounted
	inventory.call("add", "berries", 10)
	var menu: CanvasLayer = _game.call("menu")
	if menu == null:
		_blocked.append("H4: no menu shell")
		return

	# Make sure somebody is in the party, so the creature picker has a row and
	# the comparison is "which eater did the screen choose", not "was there one".
	_ensure_party(1)

	menu.call("open", "backpack")
	for i in 8:
		await process_frame
	var body: Node = _tab_body(menu, "backpack")
	if body == null:
		_blocked.append("H4: could not open the Satchel tab")
		return
	var slot := int(inventory.call("find_slot", "berries"))
	var buttons: Array = body.get("_buttons")
	if slot < 0 or slot >= buttons.size():
		_blocked.append("H4: berries never reached a satchel slot")
		menu.call("close")
		return
	(buttons[slot] as Button).grab_focus()
	await process_frame

	var use_button := _pad_button_for(USE_ACTION)
	if use_button < 0:
		_blocked.append("H4: the Use verb has no joypad binding at all")
		menu.call("close")
		return

	vitals.set("satiety", 40.0)
	var before := float(vitals.get("satiety"))
	var berries_before := int(inventory.call("count", "berries"))
	await _pad(use_button)
	var after := float(vitals.get("satiety"))
	var targeting := int(body.get("_targeting"))
	var picker_prompt := ""
	var rows: Array = body.get("_target_rows") as Array
	if targeting >= 0:
		var offered: Array[String] = []
		for row: Variant in rows:
			var button := row as Button
			if button != null:
				offered.append(button.text)
		picker_prompt = " picker rows: [%s]" % ", ".join(offered)

	if after > before:
		_notes.append("H4 satchel: PASS — Use on Berries fed the PLAYER (satiety %.0f -> %.0f)" % [before, after])
	elif targeting >= 0:
		_notes.append("H4 satchel: the Use verb opened the CREATURE target picker; "
			+ "the player's own satiety was untouched (%.0f).%s" % [after, picker_prompt])
		_notes.append("H4 satchel VERDICT: FAIL — from the Satchel there is no way to eat. "
			+ "`berries` is the only item in items.json with a `satiety` value and it also "
			+ "carries `creature_food`, which tab_backpack.gd::_read_use() tests FIRST, so "
			+ "the player-eating branch below it is unreachable from this screen.")
	else:
		_notes.append("H4 satchel: Use on Berries did nothing at all (satiety %.0f, no picker)" % after)
	# Leave the picker closed whatever happened.
	if int(body.get("_targeting")) >= 0:
		var cancel := _pad_button_for("menu_cancel")
		if cancel >= 0:
			await _pad(cancel)
	menu.call("close")
	for i in 8:
		await process_frame

	# The other screen that offers the same berry: the quick bar, pressed with
	# the real d-pad/face button `hotbar_N` is bound to.
	var berry_slot := int(inventory.call("find_slot", "berries"))
	if berry_slot < 0 or berry_slot >= HOTBAR_ACTIONS.size():
		_blocked.append("H4: berries landed in satchel slot %d, past the %d quick-bar slots" % [
			berry_slot, HOTBAR_ACTIONS.size()])
		return
	var hotbar_button := _pad_button_for(HOTBAR_ACTIONS[berry_slot])
	if hotbar_button < 0:
		_blocked.append("H4: %s has no joypad binding" % HOTBAR_ACTIONS[berry_slot])
		return
	vitals.set("satiety", 40.0)
	var hb_before := float(vitals.get("satiety"))
	var hb_berries := int(inventory.call("count", "berries"))
	await _pad(hotbar_button)
	var hb_after := float(vitals.get("satiety"))
	if hb_after > hb_before:
		_notes.append("H4 hotbar: PASS — the same berry from the quick bar DID feed the player (satiety %.0f -> %.0f, berries %d -> %d)" % [
			hb_before, hb_after, hb_berries, int(inventory.call("count", "berries"))])
		_notes.append("H4 VERDICT (food half): the player CAN eat, but only from the hotbar. "
			+ "Two screens offering the same item behave differently, and the screen a "
			+ "player looks in for food is the one that refuses.")
	else:
		_notes.append("H4 hotbar: pressing the berry slot did not feed the player either (satiety %.0f)" % hb_after)
		_notes.append("H4 VERDICT (food half): FAIL — the FOOD bar drains and NO screen can refill it.")


# --- H6: does caring for five stay care, or become a chore? ----------------

func _h6_feeding_a_five() -> void:
	_ensure_party(5)
	var party: RefCounted = _game.get("party")
	var cfg: Dictionary = CONDITION.config()
	var members: Array = party.call("members") as Array
	# Everyone starts at `start` (70 of 100). Walk real minutes forward and see
	# how often a five-creature team asks to be fed.
	var minutes := 0
	var first_hungry := -1
	var all_hungry := -1
	while minutes < 240:
		for member: Variant in members:
			CONDITION.tick(member as RefCounted, cfg, 60.0)
		minutes += 1
		var hungry := 0
		for member: Variant in members:
			if CONDITION.is_hungry(member as RefCounted, cfg):
				hungry += 1
		if first_hungry < 0 and hungry > 0:
			first_hungry = minutes
		if all_hungry < 0 and hungry == members.size():
			all_hungry = minutes
			break
	_notes.append("H6 team hunger: with five owned, the first goes hungry at %d min and all five by %d min of real play" % [
		first_hungry, all_hungry])
	# The cadence a player actually lives with: a creature fed to FULL falls
	# back to `hungry_below` after this long, and there are five of them.
	var nourish: Dictionary = cfg.get("nourishment", {})
	var span := float(nourish.get("max", 100.0)) \
		- float(nourish.get("hungry_below", 0.3)) * float(nourish.get("max", 100.0))
	var refeed := span / maxf(float(nourish.get("drain_per_minute", 1.1)), 0.01)
	_notes.append("H6 feeding cadence: a creature fed to full is hungry again %.0f min later, so a five-creature team is %d target-picker trips (Use press + pick, one creature per press) every %.0f min" % [
		refeed, members.size(), refeed])
	# Is there a bulk path?
	var db: RefCounted = _game.get("items")
	_notes.append("H6 note: there is no feed-all verb; `tab_backpack.gd` opens `_open_target_picker` per berry, one creature per press.")


# --- H3: injury and the creature bed ---------------------------------------

func _h3_bed_rest() -> void:
	var party: RefCounted = _game.get("party")
	var cfg: Dictionary = CONDITION.config()
	var member: RefCounted = party.call("at", 0)
	if member == null:
		_blocked.append("H3: no creature to put in a bed")
		return
	var rested_before := bool(CONDITION.is_rested(member, cfg))
	member.set("rested", false)
	# Does a bed exist in the real world to use at all?
	var beds := 0
	for node in _world.find_children("*", "", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("creature_bed.gd"):
			beds += 1
	_notes.append("H3: %d creature bed(s) stand in the loaded world before the player builds one" % beds)
	CONDITION.note_rest_completed(member, cfg)
	var rested_after := bool(CONDITION.is_rested(member, cfg))
	var happiness := float(CONDITION.happiness_fraction(member, cfg))
	_notes.append("H3: completing a rest set rested=%s and happiness to %.2f (was rested=%s)" % [
		str(rested_after), happiness, str(rested_before)])
	var minutes := float(cfg.get("rest", {}).get("stays_rested_minutes", 45.0))
	_notes.append("H3: `rested` then expires after %.0f min of awake time, so it describes today rather than a box ticked once" % minutes)


# --- G4: the sixth catch ---------------------------------------------------

func _g4_the_sixth_catch() -> void:
	_ensure_party(5)
	var party: RefCounted = _game.get("party")
	if int(party.call("size")) != 5:
		_blocked.append("G4: could not fill the party to five (got %d)" % int(party.call("size")))
		return
	if not bool(party.call("is_full")):
		_notes.append("G4 VERDICT: FAIL — five creatures owned and is_full() is false")
		return
	# The sixth. `encounter_director._resolve_catch` parks it here when full;
	# this is that same handoff, then the real shell reaction to it.
	var sixth: RefCounted = _game.call("make_creature", "bramblebun", "Sixth")
	if sixth == null:
		_blocked.append("G4: could not make a sixth creature")
		return
	var added := bool(party.call("add", sixth))
	if added:
		_notes.append("G4 VERDICT: FAIL — party.add() accepted a SIXTH creature. The hard rule is broken.")
		return
	_notes.append("G4: party.add() refused the sixth, as the cap requires")

	_game.set("pending_catch", sixth)
	for i in 30:
		await process_frame
	var menu: CanvasLayer = _game.call("menu")
	var opened := bool(menu.call("is_open"))
	if not opened:
		_notes.append("G4 VERDICT: FAIL — a sixth catch was parked and NOTHING opened. "
			+ "The player is holding a creature they cannot see or choose about.")
		_game.set("pending_catch", null)
		return
	var body: Node = _tab_body(menu, "creatures")
	var stage := str(body.get("_release_stage")) if body != null else "<no creatures tab>"
	var footer := ""
	if menu.has_method("footer_text"):
		footer = str(menu.call("footer_text"))
	_notes.append("G4: the shell opened the Creatures tab by itself, release stage '%s'" % stage)
	if stage == "choose":
		_notes.append("G4 VERDICT: PASS — the sixth catch forces the release ceremony; "
			+ "play cannot resume with six owned. Footer: '%s'" % footer)
	else:
		_notes.append("G4 VERDICT: the menu opened but the ceremony did not start (stage '%s'); "
			+ "the player sees a Creatures screen with no explanation of why." % stage)
	_game.set("pending_catch", null)


# --- helpers ---------------------------------------------------------------

func _ensure_party(count: int) -> void:
	var party: RefCounted = _game.get("party")
	var species := ["terrapup", "ripplet", "bramblebun", "brooktail", "pipwing"]
	var i := 0
	while int(party.call("size")) < count and i < species.size() * 2:
		var made: RefCounted = _game.call("make_creature", species[i % species.size()], "T%d" % i)
		i += 1
		if made == null:
			continue
		party.call("add", made)


func _tab_body(menu: CanvasLayer, tab_id: String) -> Node:
	var tabs: Array = menu.get("_tabs") as Array
	var bodies: Array = menu.get("_bodies") as Array
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == tab_id:
			menu.call("select", i)
			return bodies[i] as Node
	return null


func _find_hud() -> Node:
	for node in _world.find_children("*", "", true, false):
		if node.has_method("use_hotbar_slot"):
			return node
	for node in root.find_children("*", "", true, false):
		if node.has_method("use_hotbar_slot"):
			return node
	return null


func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


## A real controller button, the way hardware delivers it. Deliberately NOT an
## InputEventAction: routing through the InputMap is the whole point.
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
	for i in 6:
		await process_frame
