extends SceneTree

## Drive a system through the real game and write down what it did.
##
##   godot --headless --path . --script tools/play_session.gd -- party
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/play_session.gd -- party
##
## This produces the evidence a blind judge reads (`.claude/skills/systems-judge`).
## It is not a test: it asserts nothing and it never fails. Its whole job is to
## exercise a system in the real scene and record what the game did, so that
## somebody who has not seen the code can decide whether the milestone's
## acceptance bullets are met.
##
## THE ONE RULE THIS FILE HAS: **log facts, never conclusions.**
##
## `party is full, refused: "you can only keep five"` is a fact. `the five-pal
## cap works correctly` is a conclusion, and writing it here would hand the judge
## the answer instead of the evidence — which is the entire thing the blind gate
## exists to prevent. If a line in this file could be wrong while the game is
## right, or right while the game is wrong, it does not belong here.
##
## The corollary is uncomfortable and deliberate: a bullet this session does not
## exercise comes back NOT SHOWN, and the judge treats that as a failure. A
## harness that quietly skips the hard part produces a transcript full of
## silences, and the rubric is written to refuse on silences.
##
## Input is driven through the real actions, like every smoke test, so a broken
## binding shows up here rather than on the handheld.

const SCENE := "res://scenes/world/meadows_playground.tscn"

## Long enough for terrain to stream, collision to build and the director to
## place its creatures. Same figure the smokes use.
const SETTLE_FRAMES := 240

var _log: PackedStringArray = []
var _system: String = ""
var _shots: int = 0
var _world: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	_system = _requested_system()
	if _system == "":
		print("usage: play_session.gd -- <system>   (party | release | inventory | home)")
		quit(2)
		return

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	note("session: %s" % _system)
	note("scene: %s" % SCENE)

	match _system:
		"party":
			await _session_party()
		_:
			note("no session is written for '%s' yet" % _system)

	_write()
	quit(0)


## --- the sessions ---------------------------------------------------------
##
## Each one walks the acceptance bullets of its milestone in order and records
## what the game did at each step. Where a bullet cannot be exercised yet, it
## says so IN THE LOG rather than skipping quietly — an admitted gap is evidence,
## a silent one is a lie by omission.

func _session_party() -> void:
	var director: Node = _world.get_node_or_null(^"EncounterDirector")
	var party: Node = _world.get_node_or_null(^"Party")
	if director == null:
		note("EncounterDirector: ABSENT")
		return

	note("--- catching, and the cap ---")
	if party == null:
		note("Party node: ABSENT — no party system is present in the scene")
	else:
		note("party size at start: %d" % int(party.call("size")))
		note("party capacity: %d" % int(party.call("capacity")))

	note("--- what the transcript could not reach ---")
	note("this session is a stub; the party steps are written when the system exists")


## --- recording ------------------------------------------------------------

## One observed fact. Printed as well as stored, so a crashed session still
## leaves everything it got as far as.
func note(line: String) -> void:
	_log.append(line)
	print("  %s" % line)


## A numbered frame, for anything the judge has to look at rather than read.
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		note("frame '%s': not captured (headless)" % label)
		return
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		note("frame '%s': capture failed" % label)
		return
	_shots += 1
	var path := "res://shots/session_%s_%02d_%s.png" % [_system, _shots, label]
	image.save_png(path)
	note("frame '%s' -> %s" % [label, path])


func _write() -> void:
	var path := "res://shots/session_%s.log" % _system
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("could not write %s" % path)
		return
	file.store_string("\n".join(_log) + "\n")
	print("wrote %s (%d lines, %d frames)" % [path, _log.size(), _shots])


## Everything after `--`, so Godot's own arguments are not mistaken for ours.
func _requested_system() -> String:
	var args := OS.get_cmdline_user_args()
	return str(args[0]) if args.size() > 0 else ""
