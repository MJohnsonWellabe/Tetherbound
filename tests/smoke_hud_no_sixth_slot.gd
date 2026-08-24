extends SceneTree

## OP23-16 (owner playtest 2026-08-23): "With five creatures, the HUD still
## shows an empty sixth creature slot while the menu correctly shows five."
## Hard rule adjacency (CLAUDE.md): nothing may imply a sixth slot exists.
##
## `party_strip.gd::SLOTS` and `playground_hud.gd`'s party-pip loop were both
## already hardcoded to 5 as of this test's authoring -- a static read finds
## no drift. This drives the REAL mounted HUD against a genuinely full party
## (five real `CreatureInstance`s through `Game.party.add()`, the same seam
## `smoke_release.gd` fills the belt with) because a widget that is correct
## in isolation can still be fed the wrong data by its mount point, and a
## poll-only static check would not catch that.
##
##   godot --headless --path . --script tests/smoke_hud_no_sixth_slot.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 90
const SETTLE_AFTER_FILL := 30

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await process_frame

	var game: Node = root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return
	var party: RefCounted = game.get("party")
	if party == null:
		print("FAIL: Game has no party")
		quit(1)
		return

	var n := 0
	while not bool(party.call("is_full")):
		n += 1
		var creature: RefCounted = game.call("make_creature", "terrapup", "Keeper %d" % n)
		if creature == null:
			print("FAIL: could not build a creature from species.json")
			quit(1)
			return
		party.call("add", creature)

	if int(party.call("size")) != 5:
		_failures.append("party did not fill to exactly five (got %d)" % int(party.call("size")))

	for i in SETTLE_AFTER_FILL:
		await process_frame

	var hud: Node = world.get_node_or_null(^"PlaygroundHUD")
	if hud == null:
		print("FAIL: no PlaygroundHUD node in the real scene")
		quit(1)
		return

	var strip: Control = hud.get("_party_strip")
	if strip == null:
		print("FAIL: PlaygroundHUD has no _party_strip mounted")
		quit(1)
		return

	var name_labels: Array = strip.get("_name_labels")
	var last_vacant: Array = strip.get("_last_vacant")
	if name_labels.size() != 5:
		_failures.append(
			"the party strip built %d rows for a five-creature party, not exactly five"
				% name_labels.size())
	for i in name_labels.size():
		var vacant := bool(last_vacant[i]) if i < last_vacant.size() else true
		if vacant:
			_failures.append(
				"row %d reads vacant with a full five-creature party -- an implied "
				+ "empty slot the hard rule forbids" % i)

	var pips: Array = hud.get("_party_pips")
	if pips != null and pips.size() != 5:
		_failures.append("the party pip row built %d pips, not exactly five" % pips.size())

	_report()


func _report() -> void:
	if _failures.is_empty():
		print("PASS: HUD shows exactly five filled slots for a five-creature party, never six")
		quit(0)
	else:
		for f in _failures:
			print("FAIL: %s" % f)
		quit(1)
