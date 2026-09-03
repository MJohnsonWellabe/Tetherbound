extends SceneTree

## OWNER DIRECTIVE 2026-08-23 §3: "Build wins while the hammer is out."
##
##   godot --headless --path . --script tests/smoke_build_wins_while_hammer_is_out.gd
##
## With the build hammer equipped, Build owns the Interact button, and the
## player's own deployed creature stops bidding for it. Without that, a
## controller player standing in open meadow with a rideable creature out
## cannot open the build catalogue AT ALL: `riding_controller.gd`'s
## "Ride <name>" is an ACTIONABLE offer, the creature making it follows the
## player, and `playground_hud.gd::_hammer_opens_the_catalogue()` forfeits the
## press to any actionable winner. There is nowhere to stand clear of a
## creature that walks after you. That is the shape of the owner's original
## "building doesn't work" report.
##
## Measured before it was fixed (`tools/_probe_hammer_gate.gd`, meadowhart
## deployed in open meadow, hammer in hand):
##
##   RidingController   Ride Meadowhart      d=2.78  prio=0  actionable=true
##   EncounterDirector  Put Meadowhart away  d=0.00  prio=-1 actionable=false
##   WINNER: 'Ride Meadowhart' -> the hammer gate would FORFEIT the press
##
## Note which provider it was. `archive/ralph/DONE.md`'s GATEB-TAIL entry blamed the
## "Put away" line; that line is built `actionable: false` and the hammer gate
## already ignores those. Blaming the wrong one is why this test asserts on the
## RIDE offer specifically.
##
## Four things are proven, and the last two are what stop this being a fix that
## quietly removes riding:
##
##   1. hammer out, creature deployed -> nothing actionable wins, so Build opens
##   2. hammer out -> the creature-control line has left the prompt entirely
##   3. hammer away -> "Ride" is back the same frame
##   4. hammer out and MOUNTED -> "Dismount" still wins, or a player who
##      equips the hammer in the saddle is stuck in it
##
## `meadowhart` on purpose: it is one of the two rideable species
## (`data/creatures/species.json`) and the only one whose saddle is a real
## item, so this exercises the offer rather than the "needs a saddle"
## statement.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const PROMPTS := preload("res://scripts/world/prompt_arbiter.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SETTLE_FRAMES := 300
## Open meadow, well clear of GrandpaHouse's bed prompt at the spawn point.
const OPEN_FIELD := Vector3(-25.0, 5.0, -60.0)
const RIDEABLE := "meadowhart"

var _failures: Array[String] = []
var _world: Node3D = null
var _game: Node = null
var _player: Node3D = null
var _arbiter: Node = null
var _director: Node = null
var _riding: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for _i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_player = _find(_world, "locomotion_enabled") as Node3D
	_arbiter = get_first_node_in_group(&"interaction_arbiter")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_riding = _find(_world, "is_mounted")
	if _game == null or _player == null or _arbiter == null or _director == null \
			or _riding == null:
		_fail("real Meadows boot is missing Game/player/arbiter/director/riding")
		_report()
		return

	if not await _stage_a_rideable_creature_in_open_meadow():
		_report()
		return

	await _check_the_ride_offer_is_a_real_blocker()
	await _check_build_wins_with_the_hammer_out()
	await _check_riding_comes_back_when_the_hammer_goes_away()
	await _check_dismount_survives_the_hammer()
	_report()


func _stage_a_rideable_creature_in_open_meadow() -> bool:
	var party: RefCounted = _game.get("party")
	party.call("clear")
	var creature: RefCounted = SPECIES.spawn(RIDEABLE)
	if creature == null or not bool(party.call("add", creature)):
		_fail("could not put a %s in the party; nothing rideable to stand near" % RIDEABLE)
		return false
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "saddle", 1)
	inventory.call("add", "hammer", 1)
	_player.global_position = OPEN_FIELD
	for _i in 90:
		await physics_frame
	_director.call("summon_active_creature")
	for _i in 150:
		await physics_frame
	if _director.call("ally_body") == null:
		_fail("the creature would not come out; the whole point is a deployed creature")
		return false
	return true


## The control case. If "Ride" does not actually take the button with the
## hammer AWAY, then every check below passes for the wrong reason.
func _check_the_ride_offer_is_a_real_blocker() -> void:
	await _equip("")
	var offer: Dictionary = _riding.call("interaction_offer", _player.global_position)
	if not PROMPTS.is_actionable(offer) or not str(offer.get("label", "")).begins_with("Ride"):
		_fail(("with the hammer away, the deployed %s offers '%s' -- this test needs it to "
			+ "offer an ACTIONABLE Ride, or it proves nothing about Build losing to it")
			% [RIDEABLE, str(offer.get("label", "<nothing>"))])
		return
	print("  ok    control: a deployed %s does hold Interact with 'Ride' (actionable)" % RIDEABLE)


func _check_build_wins_with_the_hammer_out() -> void:
	await _equip("hammer")
	var ride: Dictionary = _riding.call("interaction_offer", _player.global_position)
	if not ride.is_empty():
		_fail("hammer in hand and the riding controller still offers '%s'; Build cannot own "
			% str(ride.get("label", "")) + "Interact while something actionable follows the player")
	var control: Dictionary = _director.call("interaction_offer", _player.global_position)
	if not control.is_empty():
		_fail(("hammer in hand and the director still offers '%s'; the directive moves that "
			+ "line to the party-cycle button context for the duration")
			% str(control.get("label", "")))
	var winner: Dictionary = _arbiter.call("winner")
	if PROMPTS.is_actionable(winner):
		_fail(("hammer in hand in open meadow and '%s' is still winning Interact; "
			+ "`playground_hud.gd::_hammer_opens_the_catalogue()` forfeits to any actionable "
			+ "winner, so the build catalogue cannot be opened") % str(winner.get("label", "")))
		return
	print("  ok    hammer out: nothing actionable holds Interact, so Build opens")


func _check_riding_comes_back_when_the_hammer_goes_away() -> void:
	await _equip("")
	var offer: Dictionary = _riding.call("interaction_offer", _player.global_position)
	if not PROMPTS.is_actionable(offer) or not str(offer.get("label", "")).begins_with("Ride"):
		_fail(("the hammer went away and the deployed %s offers '%s'; standing down is for "
			+ "the hammer only -- riding must not be lost to fix Build")
			% [RIDEABLE, str(offer.get("label", "<nothing>"))])
		return
	print("  ok    hammer away: 'Ride' is back the same frame")


## The carve-out. Dismount has to keep the button whatever is in hand, or a
## player who equips the hammer while mounted has no way off the creature.
func _check_dismount_survives_the_hammer() -> void:
	if not bool(_riding.call("mount")):
		print("  skip  could not mount here; the dismount carve-out is unproven this run")
		return
	for _i in 60:
		await physics_frame
	await _equip("hammer")
	var offer: Dictionary = _riding.call("interaction_offer", _player.global_position)
	if str(offer.get("label", "")) != "Dismount":
		_fail("mounted with the hammer in hand and the offer is '%s'; a player who equips "
			% str(offer.get("label", "<nothing>")) + "the hammer in the saddle must still get off")
	else:
		print("  ok    mounted: 'Dismount' still owns Interact with the hammer out")
	_riding.call("dismount")
	for _i in 60:
		await physics_frame


## Put `tool_id` in hand and let the arbiter catch up.
##
## `interaction_arbiter.gd::_recompute()` runs on `_process`, so the WINNER it
## publishes is always a frame behind whatever just changed. Reading it in the
## same call that set `equipped_tool` reads the previous frame's answer, which
## is how the first version of this test reported a fix that works as broken.
## Production always reads it a frame later; so does this.
func _equip(tool_id: String) -> void:
	_game.set("equipped_tool", tool_id)
	for _i in 10:
		await process_frame
	for _i in 4:
		await physics_frame


func _find(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child: Node in node.get_children():
		var found := _find(child, method)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("Build wins while the hammer is out: OK")
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
