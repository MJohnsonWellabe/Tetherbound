extends SceneTree

## HUD-SCALE. What fraction of the screen the exploration HUD actually
## occupies, measured off the live scene rather than read off constants.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_measure_hud_footprint.gd -- --tag=before
##
## NEVER `--headless` with a real rendering driver -- see
## `tools/_capture_ui_survey.gd`'s header for that trap.
##
## The owner's report is "the hud on screen is way too big", which is a claim
## about area and about element size, and this repo has argued both from
## constants. This walks every visible Control under the HUD's `Root`, prints
## its authored rect, and sums the union area of the leaf widgets that are
## PERMANENTLY on screen -- so "too big" gets a percentage instead of an
## adjective, before and after.
##
## Two numbers, because they answer different halves of the complaint:
##   OCCUPANCY  union area of permanently-visible HUD rects / canvas area
##   GLYPH mm   the physical size an authored pixel lands at on the owner's
##              panel. `canvas_items` stretch maps the authored canvas onto
##              the whole panel, so this depends ONLY on authored px and the
##              panel's width in mm -- NOT on render resolution. That is the
##              thing this project has repeatedly got wrong; see the
##              PANEL_* constants below.

const HUD_SCENE := "res://scenes/ui/playground_hud.tscn"
const PARTY_SPECIES: Array[String] = ["terrapup", "ripplet", "galewisp", "brooktail", "tuskroot"]

## ROG Ally: 7.0" diagonal, 16:9. project.godot's own [display] comment states
## the panel; these two derive the millimetre-per-authored-pixel figure that
## every legibility argument in this repo should have been made in.
const PANEL_DIAGONAL_INCHES := 7.0
const PANEL_ASPECT_W := 16.0
const PANEL_ASPECT_H := 9.0
## Handheld viewing distance in mm. A 7-inch handheld is held nearer than a
## monitor and further than a phone; 450mm is the middle of the usual range
## and is stated here so the arcminute figures below can be re-derived
## against a different number rather than argued about.
const VIEW_DISTANCE_MM := 450.0

var _tag := "frame"
var _rows: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	_read_args()
	for i in 4:
		await process_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: no Game autoload")
		quit(1)
		return
	var party: RefCounted = game.get("party")
	party.call("clear")
	for id: String in PARTY_SPECIES:
		var c: RefCounted = game.call("make_creature", id, id.capitalize())
		if c != null:
			party.call("add", c)

	var world := Node3D.new()
	world.name = "MeasureWorld"
	root.add_child(world)
	current_scene = world
	var player := CharacterBody3D.new()
	player.name = "Player"
	world.add_child(player)
	var hud: CanvasLayer = load(HUD_SCENE).instantiate()
	world.add_child(hud)
	for i in 30:
		await process_frame

	var canvas := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	)
	var hud_root := hud.get_node_or_null(^"Root") as Control
	if hud_root == null:
		print("FAIL: HUD has no Root control")
		quit(1)
		return

	_collect(hud_root, 0, false)
	_report(canvas)
	quit(0)


func _read_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_tag = arg.substr(6)


## Every visible Control that actually puts ink on the screen: a leaf widget,
## or a PanelContainer/Panel, which draws a filled stylebox behind its own
## children and is therefore part of the footprint even though it is a
## container. A first pass counted leaves only and undercounted the
## exploration legend by its whole backing plate.
##
## Transient widgets are collected but reported separately. "Too big" is a
## complaint about what is on screen while you walk around, and the party
## strip, the region banner and the hotbar message are not.
const TRANSIENT_NAMES: Array[String] = [
	"PartyStrip", "RegionBanner", "Message", "Prompt", "DebugReadout",
	# Times out on its own clock (`_tick_objective_hint()`), so it is not part
	# of what is on screen while the player walks around.
	"ObjectiveHintCard",
]


func _collect(node: Node, depth: int, transient: bool) -> void:
	for child in node.get_children():
		if child is Control:
			var c := child as Control
			if not c.is_visible_in_tree():
				continue
			var here := transient or TRANSIENT_NAMES.has(String(c.name)) \
				or c.get_script() != null and String(c.get_script().resource_path).ends_with("party_strip.gd")
			var draws_ink := true
			for grand in c.get_children():
				if grand is Control and (grand as Control).is_visible_in_tree():
					draws_ink = false
					break
			if not draws_ink and (c is PanelContainer or c is Panel):
				draws_ink = c.has_theme_stylebox_override("panel")
			if draws_ink:
				var r := c.get_global_rect()
				if r.size.x > 1.0 and r.size.y > 1.0:
					_rows.append({"path": _short_path(c), "rect": r, "transient": here})
			_collect(c, depth + 1, here)


func _short_path(c: Control) -> String:
	var parts := PackedStringArray()
	var n: Node = c
	for i in 4:
		if n == null:
			break
		parts.insert(0, n.name)
		n = n.get_parent()
	return "/".join(parts)


func _report(canvas: Vector2) -> void:
	var panel_w_mm := PANEL_DIAGONAL_INCHES * 25.4 * PANEL_ASPECT_W \
		/ sqrt(PANEL_ASPECT_W * PANEL_ASPECT_W + PANEL_ASPECT_H * PANEL_ASPECT_H)
	var mm_per_px := panel_w_mm / canvas.x
	print("=== HUD FOOTPRINT (%s) ===" % _tag)
	print("canvas %dx%d ; panel %.1f mm wide ; 1 authored px = %.4f mm ; view %.0f mm"
		% [int(canvas.x), int(canvas.y), panel_w_mm, mm_per_px, VIEW_DISTANCE_MM])
	print("")

	# Coverage by sample-grid union -- rects overlap, so summed areas lie.
	var covered := _coverage(canvas, false)
	var covered_all := _coverage(canvas, true)

	_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["rect"] as Rect2).get_area() > (b["rect"] as Rect2).get_area())
	print("%-52s %-26s %8s %7s %s" % ["widget", "rect (authored px)", "area px", "% scr", "when"])
	for row: Dictionary in _rows:
		var r: Rect2 = row["rect"]
		var area := r.size.x * r.size.y
		print("%-52s %-26s %8d %6.2f%% %s" % [
			row["path"],
			"%d,%d %dx%d" % [int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)],
			int(area), 100.0 * area / (canvas.x * canvas.y),
			"transient" if bool(row["transient"]) else "PERSISTENT",
		])
	print("")
	print("WIDGETS: %d" % _rows.size())
	print("OCCUPANCY persistent: %.2f%%" % (100.0 * covered / (canvas.x * canvas.y)))
	print("OCCUPANCY with transients up: %.2f%%" % (100.0 * covered_all / (canvas.x * canvas.y)))
	print("")
	print("=== authored px -> panel millimetres -> arcminutes at %.0f mm ===" % VIEW_DISTANCE_MM)
	for px: int in [16, 20, 22, 24, 26, 28, 32, 36, 44, 66]:
		var mm := float(px) * mm_per_px
		var arcmin := atan(mm / VIEW_DISTANCE_MM) * 180.0 * 60.0 / PI
		print("  %3d px -> %5.2f mm -> %5.1f arcmin" % [px, mm, arcmin])


func _coverage(canvas: Vector2, include_transient: bool) -> float:
	var covered := 0.0
	var step := 4.0
	var y := 0.0
	while y < canvas.y:
		var x := 0.0
		while x < canvas.x:
			var p := Vector2(x, y)
			for row: Dictionary in _rows:
				if not include_transient and bool(row["transient"]):
					continue
				if (row["rect"] as Rect2).has_point(p):
					covered += step * step
					break
			x += step
		y += step
	return covered

