extends "res://tests/smoke_four_biome_continuous.gd"

## F04 #2/#3/#6 evidence run: the continuous Meadows smoke, unchanged, from an
## earned checkpoint, with `smoke_meadows_f04_bosses_observer.gd` attached to
## save production-camera frames of the captains' and the Warden's named tells
## and of each fight's aftermath. Every fight is won by the smoke's own
## controller-input fighting; nothing here moves, heals or writes state.
##
## Captains (Oreth, Halder, Vess), from the earned seed-15 relay checkpoint:
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1600x900 --script res://tests/smoke_meadows_f04_bosses_run.gd -- \
##     --resume-from=<relay-checkpoint-seed15 dir> --through-hall --fight-log \
##     --f04-out=<abs dir> [--f04-render-fights-only | --f04-render-captures-only]
## Warden (Aldis), from the earned seed4_hall checkpoint:
##   ... -- --world-seed=4 --resume-from=seed4_hall --m4-finale --through-meadows \
##     --fight-log --f04-out=<abs dir> [--f04-render-fights-only]

const F04_OBSERVER := preload("res://tests/smoke_meadows_f04_bosses_observer.gd")

var f04_observer: Node = null


func _init() -> void:
	# Godot 4 does not call the parent's _init implicitly; it defers `_run`.
	super()
	_attach_f04_observer.call_deferred()


func _attach_f04_observer() -> void:
	var out := "user://f04_bosses"
	var fights_only := false
	var captures_only := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--f04-out="):
			out = arg.trim_prefix("--f04-out=")
		elif arg == "--f04-render-fights-only":
			fights_only = true
		elif arg == "--f04-render-captures-only":
			captures_only = true
	f04_observer = F04_OBSERVER.new(out, fights_only, captures_only)
	root.add_child(f04_observer)
