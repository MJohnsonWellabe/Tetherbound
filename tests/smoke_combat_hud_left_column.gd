extends SceneTree

## `HIST-013` — "the combat HUD overlaps itself."
##
##   godot --headless --path . --script tests/smoke_combat_hud_left_column.gd
##
## The reported defect: in a fight, the active creature's name and level print
## on top of another team member's, its HP bar runs under the mini-bar, and an
## "Energy" label floats loose under the pile — *"the player cannot read their
## own team during combat."* Located precisely by a blind pass (frames 10 and
## 11, bottom-left).
##
## `combat_hud.gd::_party_strip_position()` fixed the stale-constant half: the
## rest position used to be a hand-measured `Vector2(56, 380)` justified by
## arithmetic that was wrong the day it was written, and it now derives from
## `AllyPanel`'s own anchored offset and the strip's own measured height. The
## register's note on what is left is exact: *"the remaining overlap is the
## plate's own height or the strip's row count."* This file measures both, on
## the real scene, and asserts the two columns cannot land on each other.
##
## THE SHAPE OF THE REMAINING RISK, and why authored offsets are not enough.
## `AllyPanel` is a bottom-anchored `PanelContainer` with `grow_vertical = 0`,
## so when its content needs more than the 150px its offsets declare it grows
## UPWARD — and a Control forced past its minimum size grows its cached rect
## without ever writing that growth back to its offsets (the same distinction
## `smoke_prompt_hotbar_dock.gd`'s header draws). `_party_strip_position()`
## computes from `offset_top`. If the panel's real top is higher than its
## authored one, the strip is placed against an edge that is not where the
## panel actually is, and the bottom rows land inside it — which is exactly
## the reported symptom.
##
## So this file asserts the offset against the REAL rect first, and then the
## real rects against each other. Neither check trusts the numbers in the
## scene file.

const HUD_SCENE := "res://scenes/combat/combat_hud.tscn"
const PARTY_STRIP := preload("res://scripts/ui/party_strip.gd")
const SETTLE := 8

## A full five, the cap CLAUDE.md fixes the roster at, with real content in
## every row: the strip is at its tallest with five entries, and a check run
## against a party of one would pass on a HUD that cannot draw a party of five.
const PARTY := [
	{"label": "Terrapup", "level": 7, "hp_fraction": 1.0, "fainted": false},
	{"label": "Thunderbristle", "level": 6, "hp_fraction": 0.4, "fainted": false},
	{"label": "Bramblebun", "level": 5, "hp_fraction": 0.0, "fainted": true},
	{"label": "Brooktail", "level": 6, "hp_fraction": 0.8, "fainted": false},
	{"label": "Tuskroot", "level": 5, "hp_fraction": 1.0, "fainted": false},
]

var _failures: Array[String] = []
var _screen := Vector2i(1920, 1080)
var _hud: Node = null
var _root: Control = null
var _ally: PanelContainer = null
var _strip: Control = null


func _init() -> void:
	_run()


func _run() -> void:
	for i in SETTLE:
		await process_frame
	_screen = Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 1080)),
	)
	root.size = _screen
	for i in SETTLE:
		await process_frame

	var packed: PackedScene = load(HUD_SCENE)
	if packed == null:
		print("FAIL: could not load %s" % HUD_SCENE)
		quit(1)
		return
	_hud = packed.instantiate()
	root.add_child(_hud)
	for i in SETTLE:
		await process_frame

	_root = _hud.get_node_or_null(^"Root") as Control
	_ally = _hud.get_node_or_null(^"Root/AllyPanel") as PanelContainer
	_strip = _hud.get(&"_party_strip") as Control
	if _root == null or _ally == null or _strip == null:
		print("FAIL: combat HUD is missing Root, AllyPanel or its party strip")
		quit(1)
		return

	# The fight state. `_process()` returns early when nothing is fighting, so
	# the two panels are driven directly rather than through a stub manager:
	# this file is about where they land, not about the fight.
	_ally.visible = true
	_strip.call("update_from_party", PARTY, 0)
	_strip.call("set_pinned", true)
	_strip.call("show_strip")
	for i in SETTLE:
		await process_frame
	_strip.call("set_rest_position", _hud.call("_party_strip_position"))
	for i in SETTLE:
		await process_frame

	_check_the_ally_panel_is_where_its_offsets_say()
	_check_the_strip_clears_the_ally_panel()
	_check_the_strip_holds_its_own_rows()
	_check_the_ally_panel_holds_its_own_children()

	print("")
	print("combat HUD left column, measured at %s" % _screen)
	if _failures.is_empty():
		print("PASS: the roster and the active-creature plate cannot land on each other")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


## The load-bearing one, and it is a check on WHICH EDGE, not on a gap.
##
## `AllyPanel`'s authored offsets and its real rect disagree — measured, it
## grows 41px above them, because it is a bottom-anchored `PanelContainer` with
## `grow_vertical = 0` whose content needs more than the 150px the scene gives
## it. That disagreement is not itself a defect: the panel is allowed to grow,
## and its children stay inside it (checked below). The defect was reading the
## authored number and calling it the panel's top.
##
## So this asserts the contract that actually matters — that
## `_party_strip_position()` places the roster's bottom `SWITCH_PANEL_GAP`
## above the plate's REAL top — which fails the moment anyone puts the offset
## arithmetic back, whatever the drift happens to be that day. The drift is
## printed as information rather than asserted, since the scene is free to
## change and the code no longer depends on it.
func _check_the_ally_panel_is_where_its_offsets_say() -> void:
	var authored_top: float = _root.size.y + _ally.offset_top
	var real_top: float = _ally.get_global_rect().position.y
	print("  info  AllyPanel authored top %.0f, real top %.0f (grows %.0fpx above its own offsets)" % [
		authored_top, real_top, authored_top - real_top,
	])

	var placed: Vector2 = _hud.call("_party_strip_position")
	var want := real_top - _strip.size.y - float(_hud.get_script().get_script_constant_map()["SWITCH_PANEL_GAP"])
	if absf(placed.y - want) > 0.5:
		_failures.append(
			"_party_strip_position() put the roster at y %.1f; against the plate's REAL top (%.0f) it belongs at %.1f. "
			% [placed.y, real_top, want]
			+ "A %.0fpx error is the authored offset (%.0f) being used as the plate's top edge."
			% [absf(placed.y - want), authored_top]
		)
		return
	print("  ok    _party_strip_position() measures from the plate's real top, not its offsets")


func _check_the_strip_clears_the_ally_panel() -> void:
	var strip_rect := _strip.get_global_rect()
	var ally_rect := _ally.get_global_rect()
	if not _strip.visible:
		_failures.append("the party strip is not visible; the clearance check would pass vacuously")
		return
	if strip_rect.intersects(ally_rect):
		_failures.append("the roster overlaps the active-creature plate (strip %s, plate %s)" % [
			strip_rect, ally_rect,
		])
		return
	print("  ok    roster %s clears the plate %s by %.0fpx" % [
		strip_rect, ally_rect, ally_rect.position.y - strip_rect.end.y,
	])


## `party_strip.gd`'s `TOTAL_HEIGHT` is called "a hard contract other code
## measures against" by its own comment, and `_party_strip_position()` is one
## of the places measuring. `GF-B-006` found that contract broken once already
## -- a `PanelContainer` grows past its `custom_minimum_size`, so a declared row
## height under the real one makes every bound derived from it wrong, and a
## render at the old number drew the fifth row 10px into the vitals plate. This
## asserts the contract itself rather than the number.
func _check_the_strip_holds_its_own_rows() -> void:
	var bounds := Rect2(
		_strip.get_global_rect().position,
		Vector2(PARTY_STRIP.ROW_SIZE.x, PARTY_STRIP.TOTAL_HEIGHT)
	)
	var deepest := _deepest_bottom(_strip, -INF)
	if deepest > bounds.end.y + 0.5:
		_failures.append(
			"the roster's rows run %.0fpx past the TOTAL_HEIGHT (%.0f) every bound derived from it assumes (%s) -- "
			% [deepest - bounds.end.y, PARTY_STRIP.TOTAL_HEIGHT, _name_the_deepest(_strip)]
			+ "combat_hud.gd::_party_strip_position() is one of those bounds"
		)
		return
	print("  ok    the roster's five rows fit its declared TOTAL_HEIGHT (%.0f, deepest child %.0f)" % [
		PARTY_STRIP.TOTAL_HEIGHT, deepest - _strip.get_global_rect().position.y,
	])


## The plate's own half of the reported defect: "an Energy label floats loose
## under the pile", i.e. a child drawn outside the panel that holds it.
func _check_the_ally_panel_holds_its_own_children() -> void:
	var bounds := _ally.get_global_rect()
	var escaped := _first_escapee(_ally, bounds)
	if not escaped.is_empty():
		_failures.append("active-creature plate child '%s' escapes it (child %s, plate %s)" % [
			escaped["name"], escaped["rect"], bounds,
		])
		return
	print("  ok    every child of the active-creature plate stays inside it")


## Names the child that reaches furthest down, for a failure message that says
## WHICH row grew rather than only that something did.
func _name_the_deepest(strip: Control) -> String:
	var best := -INF
	var best_name := "<none>"
	var best_rect := Rect2()
	var stack: Array[Node] = [strip]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			var c := child as Control
			if c != null and c.is_visible_in_tree() and c.size.x > 0.0 and c.size.y > 0.0:
				var r := c.get_global_rect()
				if r.end.y > best:
					best = r.end.y
					best_name = "%s (%s)" % [c.name, c.get_class()]
					best_rect = r
			stack.append(child)
	return "%s at %s" % [best_name, best_rect]


func _deepest_bottom(node: Node, so_far: float) -> float:
	var out := so_far
	for child in node.get_children():
		var c := child as Control
		if c != null and c.is_visible_in_tree() and c.size.x > 0.0 and c.size.y > 0.0:
			out = maxf(out, c.get_global_rect().end.y)
		out = maxf(out, _deepest_bottom(child, out))
	return out


func _first_escapee(node: Node, bounds: Rect2) -> Dictionary:
	for child in node.get_children():
		var c := child as Control
		if c != null and c.is_visible_in_tree() and c.size.x > 0.0 and c.size.y > 0.0:
			var r := c.get_global_rect()
			if not bounds.encloses(r.grow(-0.5)):
				return {"name": c.name if not c.name.is_empty() else c.get_class(), "rect": r}
		var deeper := _first_escapee(child, bounds)
		if not deeper.is_empty():
			return deeper
	return {}
