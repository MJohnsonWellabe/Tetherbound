extends SceneTree

## F05 (ROADMAP §3) / ACCEPTANCE §6.1 F05 and card M4, solo half:
## "Solo space/capacity accept and refuse paths complete Veridian without a
## sixth slot or accidental release", with a real save/reload after each
## answer and a save taken while the choice itself is open.
##
##   godot --headless --path . --script tests/smoke_veridian_offer_choice.gd
##
## Every answer is given the way a player gives it: the player stands at the
## accept or refuse prompt and presses `interact`, which the live interaction
## arbiter routes to that prompt. At five, the release ceremony's own buttons
## are pressed with injected `ui_*` input. Nothing calls `accept_offer()` or
## `refuse_offer()` directly.
##
## Everything happens IN the Legendary Chamber, on its built floor: the player
## is placed on the machine control, pulls the real lever with `interact`, and
## reads through the chamber's own conversations to the offer. (An earlier
## version answered around the default spawn, where terrain IS the floor, and
## so could not see that the prompts had been placed at terrain height under
## the chamber's slab -- found by independent review.)
##
## DISCLOSED FIXTURES, not earned play (ROADMAP §3: focused fixtures until the
## Meadows core lane's F01-F04 route exists; the M4 continuous-path card stays
## open until then):
##   * `defeated_warden` is set directly. No Warden fight is played here;
##     `smoke_boss.gd` owns that.
##   * The party is built with `Game.make_creature`.
##   * The player is placed on the machine control, and later on each prompt's
##     anchor, rather than walked there. The prompts are one step from where
##     the player stands; the ordinary walk is not the claim.
##
## Checked every frame of every scenario: the party never holds a sixth.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const SLOT := 3
const CHOICE_FRAME_BUDGET := 900
const NO_REOFFER_FRAMES := 240

var _failures: Array[String] = []
var _game: Node = null
var _world: Node = null
var _max_party_seen := 0


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL: %s" % message)


func _run() -> void:
	await _boot_world()
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("veridian-offer-choice FAIL: no Game autoload")
		quit(1)
		return

	await _scenario("space-accept", 4, "accept", "")
	await _scenario("space-refuse", 4, "refuse", "")
	await _scenario("capacity-refuse-at-prompt", 5, "refuse", "")
	await _scenario("capacity-accept-then-let-newcomer-go", 5, "accept", "newcomer")
	await _scenario("capacity-accept-release-one", 5, "accept", "slot0")
	await _a_save_while_the_choice_is_open_keeps_the_offer()

	print("")
	if _max_party_seen > 5:
		_fail("the party held %d at some frame; a sixth slot existed" % _max_party_seen)
	if _failures.is_empty():
		print("veridian offer choice smoke test passed")
		quit(0)
		return
	print("veridian offer choice smoke test FAILED (%d)" % _failures.size())
	quit(1)


## One answer, end to end: fresh freed-but-unanswered state, the choice opens,
## the player answers at a prompt (and at five, in the ceremony), the result is
## checked, saved, reloaded into a fresh world and checked again for no
## re-offer and no change.
func _scenario(label: String, party_size: int, answer: String, ceremony: String) -> void:
	print("--- %s" % label)
	_reset_state(party_size)
	var before: Array = (_game.get("party").call("members") as Array).duplicate()
	await _boot_world()
	var climax := _world.get_node_or_null(^"StrongholdClimax")
	if climax == null:
		_fail("(%s) no StrongholdClimax in the world" % label)
		return
	if not await _pull_the_lever(climax, label):
		return
	if not await _drive_to_choice(climax, label):
		return
	var character := str(_game.get("local").get("character_id"))

	if not await _answer_at_prompt(climax, answer, label):
		return

	if ceremony != "":
		if not await _drive_ceremony(ceremony, label):
			return

	for i in 30:
		await _frame()
	var party: RefCounted = _game.get("party")
	var members: Array = party.call("members")
	var veridians := _count_veridian(members)
	var accepted := answer == "accept" and ceremony != "newcomer"
	var flags: RefCounted = _game.get("progression")

	if accepted:
		if veridians != 1:
			_fail("(%s) accepted, but the belt holds %d veridian" % [label, veridians])
		if not bool(flags.call("has", "legendary_joined")) or bool(flags.call("has", "legendary_refused")):
			_fail("(%s) accepted, but the personal receipt is wrong" % label)
		var expected_size := party_size + 1 if party_size < 5 else 5
		if members.size() != expected_size:
			_fail("(%s) accepted into %d, holding %d" % [label, expected_size, members.size()])
		if ceremony == "slot0" and members.has(before[0]):
			_fail("(%s) the chosen creature was not the one released" % label)
		if ceremony == "slot0":
			for i in range(1, before.size()):
				if not members.has(before[i]):
					_fail("(%s) a creature the player did NOT choose was released (%s)" % [label, str(before[i].get("nickname"))])
	else:
		if veridians != 0:
			_fail("(%s) refused, but the belt holds %d veridian" % [label, veridians])
		if members.size() != before.size():
			_fail("(%s) refused, but the party changed size %d -> %d" % [label, before.size(), members.size()])
		for member: Variant in before:
			if not members.has(member):
				_fail("(%s) refused, and '%s' was released anyway -- an accidental release" % [label, str((member as RefCounted).get("nickname"))])
		if not bool(flags.call("has", "legendary_refused")) or bool(flags.call("has", "legendary_joined")):
			_fail("(%s) refused, but the personal receipt is wrong" % label)
	var receipt := str(climax.call("resolution_flag", accepted, character if not character.is_empty() else "solo"))
	if not bool(flags.call("has", receipt)):
		_fail("(%s) the world receipt '%s' was not recorded" % [label, receipt])
	if not bool(flags.call("has", "legendary_settled")):
		_fail("(%s) the world never settled after this character answered" % label)
	if _game.get("pending_catch") != null:
		_fail("(%s) a pending catch is still parked after the answer" % label)
	await _check_herd_display(label, not accepted, "after the answer")
	var snapshot := _party_ids()
	print("(%s) answered: party %d, veridian %d, receipt %s" % [label, members.size(), veridians, receipt])

	# Save, throw the world and the in-memory state away, boot fresh, load.
	if not bool(_game.call("save_game", SLOT)):
		_fail("(%s) Game.save_game() returned false" % label)
		return
	_reset_state(0)
	await _boot_world()
	if not bool(_game.call("load_game", SLOT)):
		_fail("(%s) Game.load_game() returned false" % label)
		return
	var reloaded := _world.get_node_or_null(^"StrongholdClimax")
	_to_chamber(reloaded)
	if await _reoffered(reloaded):
		_fail("(%s) after a real save/reload the same freeing was offered AGAIN" % label)
	if _party_ids() != snapshot:
		_fail("(%s) the reloaded party differs from the saved one: %s vs %s" % [label, str(_party_ids()), str(snapshot)])
	if not bool(_game.get("progression").call("has", receipt)):
		_fail("(%s) the world receipt did not survive the reload" % label)
	await _check_herd_display(label, not accepted, "after reload")
	print("(%s) reload: no re-offer, same party, receipts kept" % label)

	# The personal receipt ALONE must hold. In solo, `legendary_settled`
	# already sends a reloaded chamber straight to DONE, which would hide a
	# missing receipt; co-op resumes unanswered participants past it. Take the
	# settled flag away and stand in the chamber again.
	_game.get("progression").call("set_flag", "legendary_settled", false)
	await _boot_world()
	var bare := _world.get_node_or_null(^"StrongholdClimax")
	_to_chamber(bare)
	if await _reoffered(bare):
		_fail("(%s) with only the personal receipt, the freeing was offered AGAIN" % label)
	else:
		print("(%s) the personal receipt alone prevents a second offer" % label)


## A save taken WHILE this character's choice is open must bring the offer back
## unanswered, not lose it and not answer it.
func _a_save_while_the_choice_is_open_keeps_the_offer() -> void:
	var label := "save-while-choice-open"
	print("--- %s" % label)
	_reset_state(4)
	await _boot_world()
	var climax := _world.get_node_or_null(^"StrongholdClimax")
	if climax == null or not await _pull_the_lever(climax, label) \
			or not await _drive_to_choice(climax, label):
		return
	if not bool(_game.call("save_game", SLOT)):
		_fail("(%s) Game.save_game() returned false" % label)
		return
	_reset_state(0)
	await _boot_world()
	if not bool(_game.call("load_game", SLOT)):
		_fail("(%s) Game.load_game() returned false" % label)
		return
	var reloaded := _world.get_node_or_null(^"StrongholdClimax")
	_to_chamber(reloaded)
	if reloaded == null or not await _drive_to_choice(reloaded, label):
		_fail("(%s) the unanswered offer did not come back after a reload" % label)
		return
	var flags: RefCounted = _game.get("progression")
	if bool(flags.call("has", "legendary_joined")) or bool(flags.call("has", "legendary_refused")):
		_fail("(%s) the reload answered the offer by itself" % label)
	if _count_veridian(_game.get("party").call("members")) != 0:
		_fail("(%s) the reload put the creature on the belt without an answer" % label)
	print("(%s) reload brought the same unanswered choice back" % label)


## WORLD §3.2: solo, a refusal is a full refusal, so the unengageable stag
## stands with the Highfield herd; any acceptance means it is absent.
func _check_herd_display(label: String, expected: bool, when: String) -> void:
	var healing := _world.get_node_or_null(^"MeadowHealing")
	if healing == null:
		_fail("(%s) no MeadowHealing node %s" % [label, when])
		return
	for i in 10:
		await _frame()
	var display: Node3D = healing.call("herd_display") as Node3D
	if expected and display == null:
		_fail("(%s) full solo refusal, but no stag stands with the Highfield herd %s" % [label, when])
	elif not expected and display != null:
		_fail("(%s) accepted, but the herd display stands anyway %s" % [label, when])
	elif display != null:
		if display.is_physics_processing() or display.get_node_or_null(^"Interactable") != null:
			_fail("(%s) the herd display is live or interactable %s" % [label, when])
		print("(%s) herd display stands at %s %s" % [label, str(display.global_position), when])


## --- driving ---

## Stand the player on the chamber's machine control.
func _to_chamber(climax: Node) -> void:
	var player := _world.get_node_or_null(^"Player") as Node3D
	var control := climax.find_child("MachineControl", true, false) as Node3D if climax != null else null
	if player == null or control == null:
		return
	player.global_position = control.global_position + Vector3(0.0, 0.3, 0.0)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO


## The real lever: stand on the control and press interact.
func _pull_the_lever(climax: Node, label: String) -> bool:
	_to_chamber(climax)
	for i in 20:
		await _frame()
	for attempt in 5:
		await _press("interact")
		for i in 10:
			await _frame()
		if str(climax.get("_stage")) != "":
			return true
	_fail("(%s) pressing interact on the machine control did not pull the lever" % label)
	return false


## Read through anything the chamber says for `NO_REOFFER_FRAMES` and report
## whether this character was offered the freeing again: the join beat, the
## choice, or the ceremony seam.
func _reoffered(climax: Node) -> bool:
	var panel := _world.get_node_or_null(^"DialoguePanel")
	for i in NO_REOFFER_FRAMES:
		await _frame()
		if panel != null and bool(panel.call("is_open")):
			await _press("interact")
		if climax != null and str(climax.get("_stage")) in ["join", "choice"]:
			return true
		if _game.get("pending_catch") != null:
			return true
	return false


## --- driving: the choice ------------------------------------------------------------------

## Dismiss whatever the chamber says until this character's choice is open.
func _drive_to_choice(climax: Node, label: String) -> bool:
	var panel := _world.get_node_or_null(^"DialoguePanel")
	for i in CHOICE_FRAME_BUDGET:
		await _frame()
		if bool(climax.call("choice_open")):
			return true
		if panel != null and bool(panel.call("is_open")):
			await _press("interact")
	_fail("(%s) the choice never opened (stage '%s')" % [label, str(climax.get("_stage"))])
	return false


## Stand at the named prompt and press interact through the live arbiter.
## Also proves the OTHER prompt is not what the press reached, and that where
## the player stood when the choice opened, neither prompt was live.
func _answer_at_prompt(climax: Node, answer: String, label: String) -> bool:
	var accept_prompt: Node3D = climax.get("_accept_prompt")
	var refuse_prompt: Node3D = climax.get("_refuse_prompt")
	if accept_prompt == null or refuse_prompt == null:
		_fail("(%s) the choice opened without both prompts" % label)
		return false
	var player := _world.get_node_or_null(^"Player") as Node3D
	if player == null:
		_fail("(%s) no Player" % label)
		return false
	for prompt: Node3D in [accept_prompt, refuse_prompt]:
		var offer: Dictionary = prompt.call("interaction_offer", player.global_position)
		if not offer.is_empty():
			_fail("(%s) '%s' was live where the player stood when the offer landed" % [label, str(offer.get("label", ""))])
	var target: Node3D = accept_prompt if answer == "accept" else refuse_prompt
	var anchor := target.get_parent() as Node3D
	player.global_position = anchor.global_position + Vector3(0.0, 0.2, 0.0)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	for i in 8:
		await _frame()
	await _press("interact")
	for i in 20:
		await _frame()
		if not bool(climax.call("choice_open")):
			return true
	_fail("(%s) pressing interact at the %s prompt did not answer the offer" % [label, answer])
	return false


## At five, the release ceremony, pressed through its own buttons:
## "newcomer" lets the offered creature go (a refusal), "slot0" releases the
## first belt creature for it.
func _drive_ceremony(mode: String, label: String) -> bool:
	var menu: CanvasLayer = _game.call("menu")
	for i in 120:
		await _frame()
		if menu != null and bool(menu.call("is_open")):
			break
	if menu == null or not bool(menu.call("is_open")) or _game.get("pending_catch") == null:
		_fail("(%s) accepting at five did not open the release ceremony" % label)
		return false
	var tab := _creatures_tab(menu)
	if tab == null:
		_fail("(%s) no creatures tab" % label)
		return false
	for i in 20:
		await _frame()
	if mode == "slot0":
		var rows: Array = tab.get("_rows")
		(rows[0] as Control).grab_focus()
		await _press("ui_accept")
	else:
		await _press("ui_accept")  # focus starts on the newcomer's row
	await _press("ui_down")  # 'Keep them' -> 'Let them go'
	if int(_game.get("party").call("size")) > 5:
		_fail("(%s) a sixth appeared mid-ceremony" % label)
	await _press("ui_accept")
	await _press("ui_accept")  # done
	for i in 30:
		await _frame()
	if bool(menu.call("is_open")):
		await _press("menu_cancel")
	if _game.get("pending_catch") != null:
		_fail("(%s) the ceremony ended with the offer still parked" % label)
		return false
	return true


func _creatures_tab(menu: CanvasLayer) -> Node:
	var tabs: Array = menu.get("_tabs")
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == "creatures":
			return (menu.get("_bodies") as Array)[i]
	return null


## --- state --------------------------------------------------------------------

## Freed-but-unanswered: the Warden is down and the lever pulled, nothing else.
## `party_size` 0 leaves the party empty for a load to fill.
func _reset_state(party_size: int) -> void:
	_game.get("progression").call("load_data", {})
	_game.set("pending_catch", null)
	var party: RefCounted = _game.get("party")
	party.call("clear")
	if party_size == 0:
		return
	var recipe: Array = ["terrapup", "mudsnout", "bramblebun", "brooktail", "tuskroot"]
	for i in party_size:
		var creature: RefCounted = _game.call("make_creature", recipe[i], str(recipe[i]).capitalize())
		creature.set("hp", float(creature.get("max_hp")))
		party.call("add", creature)
	_game.get("progression").call("set_flag", "defeated_warden")


func _party_ids() -> Array:
	var out: Array = []
	for member: Variant in (_game.get("party").call("members") as Array):
		out.append("%s:%s" % [str((member as RefCounted).get("species_id")), str((member as RefCounted).get("uid"))])
	return out


func _count_veridian(members: Array) -> int:
	var n := 0
	for member: Variant in members:
		if str((member as RefCounted).get("species_id")) == "veridian":
			n += 1
	return n


func _frame() -> void:
	await physics_frame
	var party: RefCounted = _game.get("party") if _game != null else null
	if party != null:
		_max_party_seen = maxi(_max_party_seen, int(party.call("size")))


func _boot_world() -> void:
	for child in root.get_children():
		if child.name != "Game":
			child.queue_free()
	for i in 4:
		await process_frame
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame


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
