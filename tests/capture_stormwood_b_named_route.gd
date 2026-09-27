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

const NAMED_RECORDER := preload("res://tests/helpers/stormwood_b_named_fight_recorder.gd")


func _init() -> void:
	var out := "res://shots/sw_b_named_route"
	var interval := 1.0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--named-out="):
			out = arg.trim_prefix("--named-out=")
		elif arg.begins_with("--named-interval="):
			interval = float(arg.trim_prefix("--named-interval="))
	print("NAMED_ROUTE DRY RUN — does not count (inherits the chapter-entry seam)")
	root.add_child.call_deferred(NAMED_RECORDER.new(out, interval, true))
	super()
