extends "res://tests/smoke_solo_duel_meter.gd"

## F42#2 r4 evidence: production-camera frames of a SOLO ordinary trainer
## duel whose Tether Command meter and Ultimate fill from landed hits (RD-12).
## Runs tests/smoke_solo_duel_meter.gd unchanged (its disclosed generated
## boundary profile, one-peer hosted session, begin_trainer_battle and route
## pilot) and only saves the viewport every --interval seconds of game time
## while the fight is live. Asserts nothing new.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x800 --fixed-fps 20 --script res://tools/capture_solo_duel_meter.gd \
##     -- --profile=relay --trainer=captain_riverwatch --out=/abs/dir [--interval=2.0]

var _frames_out := ""
var _interval := 2.0
var _shot := 0
var _clock: Timer


func _run() -> void:
	var rest: Array[String] = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _frames_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--interval="): _interval = float(arg.trim_prefix("--interval="))
	if _frames_out.is_empty() or DisplayServer.get_name() == "headless":
		push_error("needs --out=<absolute dir> and a rendering display")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_frames_out)
	_clock = Timer.new()
	_clock.wait_time = _interval
	_clock.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_clock.timeout.connect(_on_clock)
	root.add_child.call_deferred(_clock)
	_clock.autostart = true
	await super._run()


func _on_clock() -> void:
	var world := current_scene
	if world == null: return
	var director: Node = world.find_child("EncounterDirector", true, false)
	var manager: Node = director.get("_manager") if director != null else null
	if manager == null or not bool(manager.call("is_fighting")): return
	var snapshot: Dictionary = manager.call("tether_command_snapshot")
	var path := _frames_out.path_join("duel-%02d.png" % _shot)
	root.get_texture().get_image().save_png(path)
	print("SOLO_DUEL_FRAME %s meter=%.0f ultimate=%.2f" % [path, float(snapshot.get("meter", 0.0)), float(manager.call("ultimate_fraction"))])
	_shot += 1
