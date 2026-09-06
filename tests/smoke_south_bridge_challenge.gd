extends SceneTree

## OP-0905-13, owner playtest 2026-09-05: "At the bridge you can't open it and
## it doesn't tell you to go challenge the guy. When you try the bridge it
## should make you challenge him. He should walk up and start talking to
## you."
##
##   godot --headless --path . --script tests/smoke_south_bridge_challenge.gd
##
## **Headless, never under xvfb** — same as every other scene-booting test
## here.
##
## Proves the whole mechanism end to end, on the real scene:
##
##   1. trying the locked gate with the grunt unbeaten sends his real body
##      walking toward the player, at a walking pace, and lands the shared
##      dialogue panel on his real challenge conversation — not a jar, not
##      silence, and not a second copy of his team or his lines
##      (`trainer_npc.gd::_on_challenged()` is the one thing that opens it);
##   2. the base gate still jars while he is on his way, for the tactile
##      feedback `gated_crossing.gd`'s own header asks for;
##   3. once he is beaten and the key is in the satchel, the gate opens on its
##      own — the player is not made to back off and press the button again
##      for a fight they already won standing right beside it.
##
## What this does NOT do is fight the battle his challenge line would open —
## `smoke_trainer_battle.gd` and `smoke_village_trainer.gd` already prove a
## trainer fight plays out and pays its reward; this lane's own subject is the
## walk-and-challenge trigger and the auto-open, so the defeat flag and the
## key are set directly, the same shortcut `smoke_tournament_heal.gd` and
## others take to reach a post-fight state without re-running combat.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")

const GRUNT_ID := "south_bridge_grunt"
const CHALLENGE_CONVERSATION := "south_bridge_grunt_challenge"
const KEY_ITEM := "south_bridge_key"
const DEFEAT_FLAG := "defeated_south_bridge_grunt"
const OPEN_FLAG := "south_bridge_open"

const SETTLE_FRAMES := 300
## How far back from the crossing's own centre, on the village side, the
## player stands to try the gate — `smoke_traversal.gd`'s own
## `BRIDGE_START_BACK`, the distance that test already found clear of the
## carved gully (`reach` there is ~7.0m; 6m put a first version of this test
## standing over the trench itself and the severed-spokes failsafe carried the
## player off to its recovery road, well outside `AUTO_OPEN_RANGE`, before the
## guardian ever arrived). Also comfortably inside the grunt's own 9.6m
## stand-off from the gate (his `_why_here` in trainers.json), so his walk
## here is a real distance and not the zero-length case `walk_to()`
## short-circuits.
const PLAYER_BACK_M := 11.0
## Generous: the grunt's own walk is ~2.2 m/s over roughly 7-10m depending on
## exactly where the player stands, so this is comfortably more frames than
## the trip should ever take. A guard failure is a real regression, not a
## slow CI box — `smoke_gate_e_finale.gd`'s own battle loops budget frames
## the same way.
const ARRIVAL_FRAME_LIMIT := 1200

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _director: Node = null
var _panel: Node = null
var _game: Node = null
var _bridge: Node3D = null
var _trainers: Node = null
var _grunt: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	if not _collect_nodes():
		_report()
		return

	await _ensure_ally()
	var start := _stand_the_player_at_the_gate()
	await _settle_the_player(start)
	if not _failures.is_empty():
		_report()
		return

	var progression: RefCounted = _game.get("progression")
	var inventory: RefCounted = _game.get("inventory")
	# A fresh world should already read this way; asserted rather than assumed,
	# so a failure here reads as "the fixture changed" and not as this test's
	# own later assertions misfiring on stale state.
	if bool(progression.call("has", DEFEAT_FLAG)):
		_fail("the grunt started beaten on a fresh world; nothing here would be testing the locked path")
		_report()
		return
	if int(inventory.call("count", KEY_ITEM)) > 0:
		inventory.call("remove", KEY_ITEM, int(inventory.call("count", KEY_ITEM)))

	if not await _trying_the_locked_gate_sends_the_guardian(_player.global_position):
		_report()
		return
	if not _the_gate_stayed_shut():
		_report()
		return
	await _beating_him_opens_the_gate_on_its_own(progression, inventory)

	_report()


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	_bridge = _world.get_node_or_null(^"SouthBridge") as Node3D
	_trainers = _world.get_node_or_null(^"Trainers")
	_game = root.get_node_or_null(^"/root/Game")
	if _player == null or _director == null or _panel == null:
		_fail("the scene is missing the player, the encounter director or the dialogue panel")
		return false
	if _bridge == null:
		_fail("no SouthBridge in the scene; this lane has nothing to try")
		return false
	if _trainers == null:
		_fail("no Trainers node in the scene; the guardian was never placed")
		return false
	if _game == null:
		_fail("no Game autoload; there is no inventory or progression to read")
		return false
	_grunt = _trainers.call("body_for", GRUNT_ID) as Node3D
	if _grunt == null:
		_fail("trainer_npc.gd placed nobody as '%s'; the gate has no guardian to send" % GRUNT_ID)
		return false
	return true


## A usable ally out — otherwise `encounter_director.gd::no_usable_ally()` is
## true and the grunt opens the generic "nothing to fight with" line instead
## of his own challenge, which is a real and already-covered path
## (`smoke_trainer_no_ally_deployed.gd`) but not this one's.
func _ensure_ally() -> void:
	if _director.call("ally_instance") != null:
		return
	await _director.call("adopt_starter", "terrapup")


## Inside the grunt's own 9.6m stand-off from the gate (trainers.json's
## `_why_here`), so trying the gate from here is the real distance his walk
## actually covers in play — not a contrived zero-length approach.
func _stand_the_player_at_the_gate() -> Vector3:
	var at: Vector2 = _bridge.call("near_point", PLAYER_BACK_M)
	var ground: float = float(_world.call("ground_height_at", at.x, at.y))
	var spot := Vector3(at.x, ground + 1.0, at.y)
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	return spot


## Lets the player settle onto real ground before anything else runs, and
## says so loudly if that ground was not where `_stand_the_player_at_the_gate`
## thought it was — the severed-spokes failsafe carrying a mis-placed player
## off to its recovery road (see `PLAYER_BACK_M`'s own history) would
## otherwise show up many frames later as an unrelated-looking auto-open
## timeout instead of here, at the actual cause.
func _settle_the_player(spot: Vector3) -> void:
	for i in 60:
		await physics_frame
		if _player.call("is_on_floor"):
			break
	if _player.global_position.distance_to(spot) > 4.0:
		_fail("the player did not settle near the intended spot (%.1fm away) — likely fell through or off the gate approach" % _player.global_position.distance_to(spot))


## --- 1: the locked try sends him walking, and lands the real challenge ------

func _trying_the_locked_gate_sends_the_guardian(player_spot: Vector3) -> bool:
	var prompt: Node3D = _bridge.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		_fail("the South Bridge gate has no Interactable; it cannot be tried at all")
		return false

	var grunt_home := _grunt.global_position
	prompt.call("interaction_activate")
	await physics_frame

	# OP-0905-13's own mechanism: `south_bridge.gd::_on_locked()` sets this the
	# instant a locked try starts the walk. Checked before waiting for arrival
	# so a regression that skips the walk entirely (the old, jar-only
	# behaviour) fails here rather than timing out below.
	if not bool(_bridge.get("_grunt_challenge_pending")):
		_fail("trying the locked gate did not send the guardian to challenge the player — the old silent jar is still all that happens")
		return false

	var frames := 0
	while bool(_bridge.get("_grunt_challenge_pending")) and frames < ARRIVAL_FRAME_LIMIT:
		frames += 1
		await physics_frame
	if frames >= ARRIVAL_FRAME_LIMIT:
		_fail("the guardian never finished his walk to the player within %d frames" % ARRIVAL_FRAME_LIMIT)
		return false
	print("guardian walk: arrived after %d frames" % frames)

	var travelled := grunt_home.distance_to(_grunt.global_position)
	if travelled < 1.0:
		_fail("the guardian's body barely moved (%.2fm) — this reads as a teleport or a no-op, not a walk" % travelled)
		return false
	var to_player := _grunt.global_position.distance_to(player_spot)
	print("guardian walk: moved %.2fm, now %.2fm from where the player was standing" % [travelled, to_player])

	if not bool(_panel.call("is_open")):
		_fail("the guardian arrived but no dialogue opened")
		return false
	var runner: RefCounted = _panel.call("runner")
	var opened := str(runner.call("conversation_id")) if runner != null else ""
	if opened != CHALLENGE_CONVERSATION:
		_fail("the guardian's arrival opened '%s', not his own challenge '%s'" % [opened, CHALLENGE_CONVERSATION])
		return false
	print("dialogue: '%s' opened on arrival, as a walk-up to his own prompt would" % opened)
	return true


## --- 2: the base jar still ran, and the gate is still shut ------------------

func _the_gate_stayed_shut() -> bool:
	if bool(_bridge.call("is_open")):
		_fail("the gate opened on its own from the challenge alone; a jar/challenge must never substitute for the key")
		return false
	return true


## --- 3: beating him (simulated) opens the gate without a second interact ----

func _beating_him_opens_the_gate_on_its_own(progression: RefCounted, inventory: RefCounted) -> void:
	# The dialogue from step 1 is left open deliberately — closing it would
	# fire trainer_npc.gd's own `finished` listener and start the real fight,
	# which is `smoke_trainer_battle.gd`'s subject, not this one's. Setting
	# the defeat flag and the key directly is the same shortcut to a
	# post-fight state `smoke_tournament_heal.gd` already takes.
	progression.call("set_flag", DEFEAT_FLAG)
	inventory.call("add", KEY_ITEM, 1)

	var frames := 0
	while not bool(_bridge.call("is_open")) and frames < 120:
		frames += 1
		await physics_frame

	if not bool(_bridge.call("is_open")):
		_fail("the gate did not auto-open within %d frames of the defeat flag + key with the player still at it" % frames)
		return
	print("auto-open: the gate opened on its own %d frame(s) after the defeat flag and key landed" % frames)
	if not bool(progression.call("has", OPEN_FLAG)):
		_fail("the gate opened but '%s' was never set; a reload would relock it" % OPEN_FLAG)
	if int(inventory.call("count", KEY_ITEM)) != 0:
		_fail("'%s' was not consumed by the auto-open" % KEY_ITEM)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("smoke: OK — trying the locked South Bridge sends its guardian to challenge the player in person, and beating him opens the gate without a second interact.")
		quit(0)
	else:
		for line in _failures:
			print("smoke FAIL: %s" % line)
		quit(1)
