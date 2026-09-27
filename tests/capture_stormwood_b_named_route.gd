extends "res://tests/smoke_stormwood_continuous.gd"

## F10#2 named fights on the route a player walks (DRY RUN — does not count).
##
## This is the unchanged Stormwood continuous smoke with one passive addition:
## `tests/helpers/stormwood_b_named_fight_recorder.gd` watches every fight and
## records each one against a Stormwood named wild (tells, hits, outcome and,
## with a display, production-camera frames). Nothing the smoke does changes.
##
## It inherits the smoke's disclosed chapter-entry seam (an in-memory
## completed-Cloudreach party and entitlement), so its footage is a DRY RUN.
## The earned version rides the four-biome run from an earned
## `stormwood_arrived` checkpoint instead.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tests/capture_stormwood_b_named_route.gd \
##     -- --through-aftermath --named-out=res://shots/sw_b_named_route [--named-interval=1.0]
##
## Headless it still writes `named_route.json` rows (no frames).
##
## `--named-detours`: once the inherited route has PASSED, before it quits, the
## same live player detours to every named wild the route never fought and
## has not cleared (`stormwood_b_named_detour_segment.gd`: rest at the nearest
## camp, walk the road, one Engage press, ordinary controller fight).

const NAMED_RECORDER := preload("res://tests/helpers/stormwood_b_named_fight_recorder.gd")
const NAMED_DETOURS := preload("res://tests/helpers/stormwood_b_named_detour_segment.gd")
const NAMED_IDS := ["hollows_alpha", "capacitor_alpha", "crown_guardian",
	"old_rodfolk_hall_guardian", "blackwater_elder", "glass_field_alpha"]

var _named_recorder: Node = null
var _named_detours_done := false


func _init() -> void:
	var out := "res://shots/sw_b_named_route"
	var interval := 1.0
	var gate := not OS.get_cmdline_user_args().has("--named-no-gate")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--named-out="):
			out = arg.trim_prefix("--named-out=")
		elif arg.begins_with("--named-interval="):
			interval = float(arg.trim_prefix("--named-interval="))
	print("NAMED_ROUTE DRY RUN — does not count (inherits the chapter-entry seam)")
	_named_recorder = NAMED_RECORDER.new(out, interval, gate)
	root.add_child.call_deferred(_named_recorder)
	super()


func _finish() -> void:
	if _named_detours_done or _finished or not _failures.is_empty() \
			or not OS.get_cmdline_user_args().has("--named-detours"):
		_named_summary()
		super._finish()
		return
	_named_detours_done = true
	var game := root.get_node_or_null(^"Game")
	var world := current_scene as Node3D
	var seen := {}
	for row: Dictionary in _named_recorder.get("rows"):
		seen[str(row.id)] = true
	var todo: Array = []
	for id: String in NAMED_IDS:
		if not seen.has(id):
			todo.append(id)
	print("NAMED_ROUTE route fought %s; detouring to %s" % [str(seen.keys()), str(todo)])
	if game != null and world != null and str(game.get("current_realm")) == "stormwood" and not todo.is_empty():
		Engine.time_scale = 8.0
		Engine.physics_ticks_per_second = 480
		var detours := NAMED_DETOURS.new()
		var result: Dictionary = await detours.run_named(self, world, game, todo)
		print("NAMED_ROUTE detours %s" % JSON.stringify(result.get("outcomes", {})))
		for line: Variant in result.get("failures", []):
			print("NAMED_ROUTE detour note (not a route failure): %s" % str(line))
	_named_summary()
	super._finish()


func _named_summary() -> void:
	if _named_recorder == null:
		return
	for row: Dictionary in _named_recorder.get("rows"):
		print("NAMED_ROUTE SUMMARY %s attempt=%d outcome=%s seconds=%s tells=%d hits=%d frames=%d" % [
			str(row.id), int(row.attempt), str(row.outcome), str(row.get("seconds", "?")),
			(row.tells as Array).size(), (row.hits as Array).size(), (row.frames as Array).size()])
