extends SceneTree

## Gate F operator harness: plays a segment step-script against the REAL game
## and writes the telemetry `ralph/GATE_F_MASTER_PROTOCOL.md` §C specifies.
##
##   # logic-only (fast, renders nothing, capture steps become file:null)
##   godot --headless --path . --script tools/gate_f/operator_harness.gd -- \
##     --gatef-segment=tools/gate_f/segments/selfcheck_menu.json \
##     --gatef-out=ralph/reports/gate-f-run-local/selfcheck_menu
##
##   # capture mode -- NEVER `--headless` with a rendering driver, see below
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/gate_f/operator_harness.gd -- --gatef-capture ...
##
## Drive it through `tools/gate_f/run_segment.sh`, which wires both invocations,
## the zombie guard and the capture smoke gate. The raw commands above are here
## because a harness whose only documentation is a shell script is a harness
## nobody can debug.
##
## ## The two traps this file is shaped around
##
## **`--headless` plus `--rendering-driver opengl3` hangs forever.** No error,
## no partial output, exit 124 from `timeout` (`ralph/conventions.md`, the most
## expensive trap in this repo). So there is no flag here that produces that
## combination: capture mode is xvfb WITHOUT `--headless`, and logic mode is
## `--headless` WITHOUT a driver. `_capture_available()` decides which world it
## is in by asking `DisplayServer`, not by trusting a flag.
##
## **`Input.action_press` alone cannot move UI focus.** A Control's focus
## neighbours are walked by `ui_*` actions arriving as real InputEvents through
## the viewport; `Input.action_press` writes the action's polled state and
## reaches `Input.is_action_pressed` only. The reverse is also true and is the
## reason the two existing families of harness in this repo each only work on
## half the game: `gate_a_build_segment.gd` measured 0.00 m of walking from a
## parsed `InputEventJoypadMotion` because `player_controller.gd` reads
## `Input.get_vector()`, a poll.
##
## So `_inject()` sends **both, always** — the physical event AND the paired
## `action_press`/`action_release`. Not "both where it matters": the whole point
## of the §8 exhaustion matrix is to find the cell where a press reaches a
## surface it should not, and a harness that decided per-action which half to
## send would be deciding the answer in advance.
##
## ## Non-invasive
##
## Nothing under `scripts/` (except the read-only `scripts/debug/gate_f_probe.gd`,
## which nothing in the game loads) changes for this. The harness observes
## through the probe and drives through `Input`; it never calls a gameplay
## method to make something happen that a player would have to press a button
## for. Where a step is allowed to cheat -- a teleport, a granted flag -- the
## step must carry `"diag": true` and the event records it, so a DIAG shortcut
## can never be mistaken in Phase B for something the game did on its own.
##
## ## What it does not measure, and will not pretend to
##
## No VRAM, no device frame rate: §C.1 marks both [OWNER-ONLY]. `perf` carries
## CPU frame-time shape from `Performance` monitors on THIS box, which is a
## real number about a software rasteriser and says nothing about a ROG Ally.
## A planned capture that cannot be taken is a manifest row with `file: null`
## and a reason -- an absent frame is evidence.

const PROBE := preload("res://scripts/debug/gate_f_probe.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"

## Harness tunables live in a file so a run can be re-cadenced without editing
## GDScript. NOT under `data/config/`: nothing the game ships reads this, and
## `ralph/GATE_F_INSTRUMENTATION_REQUEST.md` §10 forbids touching the game's
## data configs. Missing file = the defaults below, so the harness still runs
## from a bare checkout.
const CONFIG_PATH := "res://tools/gate_f/harness_config.json"

## Hold lengths in PHYSICS frames, named so a step script says "long" instead
## of a number whose meaning nobody remembers. Overridable per step with an
## integer.
const HOLD_TAP := 1
const HOLD_SHORT := 10
const HOLD_LONG := 60

var _cfg := {
	"trace_hz": 2.0,
	"settle_frames": 240,
	"walk_budget_frames": 2400,
	"walk_close_enough": 1.2,
	"walk_held_budget_frames": 3600,
	"perf_window_frames": 60,
	"capture_settle_frames": 4,
	"overhead_seconds": 60.0,
}

# --- run identity and output -------------------------------------------------

var _out_dir := ""
var _run_id := ""
var _sha := ""
var _segment_id := "unknown"
var _segment_path := ""
var _want_capture := false
var _mode := "segment"

var _events: FileAccess = null
var _route: FileAccess = null
var _manifest: Array = []
var _notes: Array = []
var _harness_errors: Array[String] = []

# --- live counters -----------------------------------------------------------

var _probe: RefCounted = null
var _t0_usec := 0
var _boot_usec := 0
var _distance_m := 0.0
var _since_interaction_s := 0.0
var _dead_travel_m := 0.0
var _last_pos := Vector3.ZERO
var _have_last_pos := false
var _next_trace_t := 0.0
var _trace_rows := 0

## Previous snapshots, for the change-detection that turns live state into
## events without a single hook inside gameplay code.
var _prev_flags: Array = []
var _prev_objective := {}
var _prev_region := ""
var _prev_combat_running := false
var _prev_context := ""
var _prev_levels: Dictionary = {}
var _prev_party_size := -1

## The last physical input injected, for the `input` field of the next event.
var _last_input := {}

## Rolling frame-time window for `perf`.
var _frame_ms: Array[float] = []

## Stick state, so `route.csv` and a walk can share one drive path.
var _stick_left := Vector2.ZERO
var _stick_right := Vector2.ZERO

## Which analogue axes the live InputMap actually binds. Read from the map
## rather than assumed, so a rebind moves the harness with it.
var _axis_bindings := {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_parse_args()
	_load_config()
	if _segment_path.is_empty() and _mode == "segment":
		_die("no --gatef-segment=<path>; nothing to play")
		return
	var segment: Dictionary = {}
	if not _segment_path.is_empty():
		segment = _read_json(_segment_path)
		if segment.is_empty():
			_die("segment script %s is missing or not a JSON object" % _segment_path)
			return
		_segment_id = str(segment.get("id", _segment_path.get_file().get_basename()))

	if not _open_outputs():
		return

	_probe = PROBE.new(self)
	_t0_usec = Time.get_ticks_usec()

	if _mode == "overhead":
		await _run_overhead_probe()
	else:
		await _play(segment)

	_close_outputs()
	quit(1 if not _harness_errors.is_empty() else 0)


# --- command line ------------------------------------------------------------

## Flags are read from BOTH `get_cmdline_user_args()` (after `--`) and
## `get_cmdline_args()`, because half the tools in this repo pass them one way
## and half the other, and a flag silently ignored is a run that writes nothing
## and reports success.
func _parse_args() -> void:
	var seen: Array[String] = []
	for arg: String in OS.get_cmdline_user_args():
		seen.append(arg)
	for arg: String in OS.get_cmdline_args():
		if arg.begins_with("--gatef"):
			seen.append(arg)
	for arg in seen:
		if arg.begins_with("--gatef-out="):
			_out_dir = arg.substr("--gatef-out=".length())
		elif arg.begins_with("--gatef-telemetry="):
			# §I names this spelling; §1.4 names the other. Same flag.
			_out_dir = arg.substr("--gatef-telemetry=".length())
		elif arg.begins_with("--gatef-segment="):
			_segment_path = arg.substr("--gatef-segment=".length())
		elif arg.begins_with("--gatef-run-id="):
			_run_id = arg.substr("--gatef-run-id=".length())
		elif arg.begins_with("--gatef-sha="):
			_sha = arg.substr("--gatef-sha=".length())
		elif arg.begins_with("--gatef-mode="):
			_mode = arg.substr("--gatef-mode=".length())
		elif arg == "--gatef-capture":
			_want_capture = true
	if _run_id.is_empty():
		_run_id = _out_dir.get_base_dir().get_file()
	if _run_id.is_empty():
		_run_id = "gate-f-run-unnamed"


func _load_config() -> void:
	var raw := _read_json(CONFIG_PATH)
	for key: String in _cfg.keys():
		if raw.has(key):
			_cfg[key] = raw[key]


# --- output files ------------------------------------------------------------

## True when the run has somewhere to write. **A run with no `--gatef-out`
## writes nothing at all** and is the "telemetry off" case the request's
## acceptance item 5 asks for: same code path, same input, zero new files.
func _telemetry_on() -> bool:
	return not _out_dir.is_empty()


func _open_outputs() -> bool:
	if not _telemetry_on():
		print("gate-f harness: no --gatef-out, telemetry OFF (nothing will be written)")
		return true
	var abs_dir := ProjectSettings.globalize_path(_out_dir) if _out_dir.begins_with("res://") else _out_dir
	# Restart protection lives in run_segment.sh, which owns the naming. Here
	# the check is only that a half-written previous attempt is not silently
	# appended to: an events.jsonl with two runs in it reads as one long run.
	if FileAccess.file_exists(abs_dir.path_join("telemetry/events.jsonl")):
		_die("%s already holds telemetry; rename it -superseded-<n> first (run_segment.sh does this)" % abs_dir)
		return false
	for sub in ["telemetry", "shots", "notes", "saves"]:
		DirAccess.make_dir_recursive_absolute(abs_dir.path_join(sub))
	_events = FileAccess.open(abs_dir.path_join("telemetry/events.jsonl"), FileAccess.WRITE)
	_route = FileAccess.open(abs_dir.path_join("telemetry/route.csv"), FileAccess.WRITE)
	if _events == null or _route == null:
		_die("could not open telemetry files under %s" % abs_dir)
		return false
	_route.store_line("t,wall,x,y,z,heading,region,clock_hour,weather,frame_ms,"
		+ "physics_ms,dead_travel_m,nearest_poi_dist_m,input_context")
	_out_dir = abs_dir
	return true


## Idempotent: `_die()` closes on its way out and `_run()` closes at the end,
## and a run that died during setup would otherwise write its manifest twice.
var _closed := false


func _close_outputs() -> void:
	if not _telemetry_on() or _closed:
		return
	_closed = true
	if _events != null:
		_events.close()
	if _route != null:
		_route.close()
	_write_json(_out_dir.path_join("shots/manifest.json"), {"shots": _manifest})
	_write_text(_out_dir.path_join("notes/%s.md" % _segment_id), "\n".join(_notes))
	_write_json(_out_dir.path_join("RUN_METADATA.json"), _run_metadata())


## §C.5 and §8: the overhead note is part of the run record, not a separate
## report, and it says what was measured rather than asserting the trace is
## free. `instrumentation_overhead_note` is left as an explicit "not measured"
## string when this was not an overhead run — a blank field would read as zero.
func _run_metadata() -> Dictionary:
	return {
		"run_id": _run_id,
		"sha": _sha,
		"segment": _segment_id,
		"segment_script": _segment_path,
		"started_wall": Time.get_datetime_string_from_system(true, true),
		"godot": Engine.get_version_info().get("string", ""),
		"display_server": DisplayServer.get_name(),
		"rendering_driver": _rendering_driver(),
		"capture_requested": _want_capture,
		"capture_available": _capture_available(),
		"viewport_size": [_viewport_size().x, _viewport_size().y],
		"trace_hz": _cfg["trace_hz"],
		"trace_rows": _trace_rows,
		"instrumentation_overhead_note": _overhead_note,
		"harness_errors": _harness_errors,
	}


var _overhead_note := "not measured in this run (--gatef-mode=overhead measures it)"


func _rendering_driver() -> String:
	var rs := RenderingServer.get_video_adapter_name()
	return "headless" if rs.is_empty() else rs


func _viewport_size() -> Vector2i:
	if root == null:
		return Vector2i.ZERO
	return root.get_viewport().get_visible_rect().size


## Can this process actually produce a frame?
##
## Asked of `DisplayServer`, never of `_want_capture`. A logic run that was
## handed `--gatef-capture` by mistake must degrade to `file: null` manifest
## rows, not write a black PNG that Phase B then reads as a rendering defect.
func _capture_available() -> bool:
	return DisplayServer.get_name() != "headless"


# --- the run -----------------------------------------------------------------

func _play(segment: Dictionary) -> void:
	var steps: Array = segment.get("steps", []) as Array
	if steps.is_empty():
		_die("segment %s has no steps" % _segment_id)
		return
	_note_line("# %s — %s" % [_segment_id, str(segment.get("title", ""))])
	_note_line("")
	for raw: Variant in steps:
		if typeof(raw) != TYPE_DICTIONARY:
			_harness_error("a step is not a JSON object: %s" % str(raw))
			continue
		var step := raw as Dictionary
		await _do_step(step)
		if not _harness_errors.is_empty():
			# A harness error means the run's own machinery is broken (a bad
			# step script, an unopenable file). Unlike a failed EXPECTATION,
			# which is evidence, it invalidates everything after it.
			break
	_release_everything()


## One step. Never raises; a step whose expectation fails records a FAIL event
## and the run continues (§1.6), because a segment that stops at the first
## defect finds one defect.
func _do_step(step: Dictionary) -> void:
	var id := str(step.get("id", "?"))
	var action := str(step.get("action", ""))
	var args: Dictionary = step.get("args", {}) as Dictionary
	var expected := str(step.get("expected", ""))
	var diag := bool(step.get("diag", false))
	var verdict := "PASS"
	var actual := ""

	match action:
		"boot":
			actual = await _step_boot(args)
		"wait":
			actual = await _step_wait(args)
		"press":
			actual = await _step_press(args, id)
		"press_multi":
			actual = await _step_press_multi(args, id)
		"hold":
			actual = _step_hold(args, id)
		"release":
			actual = _step_release(args, id)
		"stick":
			actual = await _step_stick(args)
		"move_to":
			actual = await _step_move_to(args)
		"face":
			actual = await _step_face(args)
		"open_menu":
			actual = await _step_open_menu(args, id)
		"close_menu":
			actual = await _step_close_menu(args, id)
		"focus_move":
			actual = await _step_focus_move(args, id)
		"capture":
			actual = await _step_capture(args, id)
		"capture_seq":
			actual = await _step_capture_seq(args, id)
		"probe_cell":
			actual = await _step_probe_cell(args, id)
		"assert":
			var checked := _step_assert(args)
			actual = str(checked.get("actual", ""))
			verdict = "PASS" if bool(checked.get("ok", false)) else "FAIL"
		"note":
			actual = str(args.get("text", ""))
		"save_out":
			actual = _step_save_out(args)
		"seed_save":
			actual = _step_seed_save(args)
		"wipe_saves":
			actual = _step_wipe_saves(args)
		"teleport":
			if not diag:
				verdict = "FAIL"
				actual = "teleport refused: step is not marked \"diag\": true (§J: teleport only in DIAG segments)"
			else:
				actual = await _step_teleport(args)
		"refresh_pois":
			actual = "%d points of interest in the tree" % int(_probe.call("refresh_pois"))
		_:
			_harness_error("step %s: unknown action '%s'" % [id, action])
			return

	if actual.begins_with("HARNESS-ERROR"):
		_harness_error("step %s: %s" % [id, actual])
		return
	if actual.begins_with("FAIL"):
		verdict = "FAIL"

	# Every step gets exactly one event of its own, carrying the protocol's
	# `expected` verbatim beside what actually happened. A step that already
	# emitted a richer event of its own (`probe_cell`, `capture`) still gets
	# this one: the richer event is the measurement, this one is the step
	# record, and `notes/<segment>.md` indexes into the second.
	_emit(_event_type_for(action), {
		"expected": expected,
		"actual": actual,
		"observation": str(step.get("observation", "")),
		"severity_candidate": step.get("severity_candidate", null),
	})

	_note_line("### %s — %s" % [id, str(step.get("title", action))])
	_note_line("- expected: %s" % expected)
	_note_line("- actual: %s" % actual)
	_note_line("- events: t=%.2f" % _t())
	_note_line("- verdict: %s" % verdict)
	if not str(step.get("observation", "")).is_empty():
		_note_line("- observation: %s" % str(step.get("observation")))
	_note_line("")


## Which §C.1 `type` a step's own event carries. Steps whose action IS a schema
## event type use it; everything else is a `note`, because inventing a type
## outside the enum would break every reader downstream.
func _event_type_for(action: String) -> String:
	match action:
		"capture", "capture_seq":
			return "screenshot"
		"probe_cell":
			return "input_probe"
		"open_menu":
			return "menu_open"
		"close_menu":
			return "menu_close"
		"save_out":
			return "save"
		"seed_save":
			return "load"
		_:
			return "note"


# --- steps -------------------------------------------------------------------

func _step_boot(args: Dictionary) -> String:
	var which := str(args.get("scene", "world"))
	var path := WORLD_SCENE if which == "world" else TITLE_SCENE
	if args.has("path"):
		path = str(args["path"])
	var started := Time.get_ticks_usec()
	var packed := load(path) as PackedScene
	if packed == null:
		return "HARNESS-ERROR could not load %s" % path
	if current_scene != null:
		var old := current_scene
		root.remove_child(old)
		old.queue_free()
		await process_frame
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	var settle := int(args.get("settle_frames", _cfg["settle_frames"]))
	for i in settle:
		await physics_frame
		_sample_frame()
	_boot_usec = Time.get_ticks_usec()
	_probe.call("refresh_pois")
	_seed_change_detection()
	# The stand-up costs whole seconds in a single frame -- 466k scattered props
	# and a terrain build. Leaving those samples in the rolling window makes the
	# `perf` field on every early event a statement about world construction
	# wearing the name of gameplay frame time. The cost is not lost: it is the
	# `duration_ms` on this event, which is where a boot cost belongs.
	_frame_ms.clear()
	# One trace row at t=boot, so route.csv always opens with where the segment
	# started even if the next step never advances a frame.
	_write_trace_row()
	var ms := float(Time.get_ticks_usec() - started) / 1000.0
	# §3's boot timers. Named by which scene came up so `title` and `world`
	# rows are distinguishable without reading the segment script back.
	_emit("region_enter", {"duration_ms": ms,
		"observation": "boot:%s settled over %d physics frames" % [which, settle]})
	return "booted %s in %.0f ms (%d settle frames)" % [which, ms, settle]


func _step_wait(args: Dictionary) -> String:
	var seconds := float(args.get("seconds", 0.0))
	var frames := int(args.get("frames", 0))
	if seconds > 0.0:
		frames = maxi(frames, int(seconds * float(Engine.physics_ticks_per_second)))
	for i in frames:
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))
	return "waited %d physics frames" % frames


func _step_press(args: Dictionary, step_id: String) -> String:
	var control := str(args.get("control", ""))
	if control.is_empty():
		return "HARNESS-ERROR press step %s has no control" % step_id
	var frames := _hold_frames(args.get("hold", "tap"))
	var sent := await _inject(control, frames)
	if not bool(sent.get("ok", false)):
		return "HARNESS-ERROR %s" % str(sent.get("why", "injection failed"))
	return "pressed %s (%s, %d frames), resolved to %s" % [control,
		str(args.get("hold", "tap")), frames, str(sent.get("raw", ""))]


## Same-frame multi-press, for the collision probes §8 needs: two controls
## whose physical bindings share a button are supposed to be impossible, and
## the way to find out is to press both on one frame and see what the world did.
func _step_press_multi(args: Dictionary, step_id: String) -> String:
	var controls: Array = args.get("controls", []) as Array
	if controls.size() < 2:
		return "HARNESS-ERROR press_multi step %s needs at least two controls" % step_id
	var frames := _hold_frames(args.get("hold", "tap"))
	var raws: Array[String] = []
	for c: Variant in controls:
		var down := _edge(str(c), true)
		if not bool(down.get("ok", false)):
			return "HARNESS-ERROR %s" % str(down.get("why", ""))
		raws.append(str(down.get("raw", "")))
	# Every down edge is delivered before a single frame advances: that is what
	# makes it same-frame rather than a fast sequence.
	for i in frames:
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))
	for c: Variant in controls:
		_edge(str(c), false)
	await physics_frame
	_last_input = {"device": "synthetic", "raw": " + ".join(raws),
		"action": " + ".join(controls), "edge": "press"}
	return "pressed %s together for %d frames" % [" + ".join(controls), frames]


func _step_hold(args: Dictionary, step_id: String) -> String:
	var control := str(args.get("control", ""))
	var down := _edge(control, true)
	if not bool(down.get("ok", false)):
		return "HARNESS-ERROR hold step %s: %s" % [step_id, str(down.get("why", ""))]
	return "holding %s (%s)" % [control, str(down.get("raw", ""))]


func _step_release(args: Dictionary, step_id: String) -> String:
	var control := str(args.get("control", ""))
	var up := _edge(control, false)
	if not bool(up.get("ok", false)):
		return "HARNESS-ERROR release step %s: %s" % [step_id, str(up.get("why", ""))]
	return "released %s" % control


func _step_stick(args: Dictionary) -> String:
	var which := str(args.get("stick", "left"))
	var v := Vector2(float(args.get("x", 0.0)), float(args.get("y", 0.0)))
	var frames := int(args.get("frames", HOLD_SHORT))
	if which == "left":
		_stick_left = v
	else:
		_stick_right = v
	_drive_sticks()
	for i in frames:
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))
	if which == "left":
		_stick_left = Vector2.ZERO
	else:
		_stick_right = Vector2.ZERO
	_drive_sticks()
	await physics_frame
	return "%s stick held (%.2f, %.2f) for %d frames" % [which, v.x, v.y, frames]


## Walked, never teleported. `tests/helpers/stick_navigator.gd` is the repo's
## one walker that can get around geometry, and it exists because every
## straight-line walk in this project failed on the same village wall. Reused
## rather than copied: a second copy of it is one that stops being fixed.
func _step_move_to(args: Dictionary) -> String:
	var player := _probe.call("player") as Node3D
	var rig := _probe.call("camera_rig") as Node3D
	if player == null or rig == null:
		return "HARNESS-ERROR move_to with no live Player/CameraRig"
	var at: Array = args.get("at", []) as Array
	if at.size() < 2:
		return "HARNESS-ERROR move_to needs at:[x,z]"
	var world: Node = _probe.call("world") as Node
	var target := Vector3(float(at[0]), player.global_position.y, float(at[1]))
	if world != null and world.has_method("ground_height_at"):
		target.y = float(world.call("ground_height_at", target.x, target.z))
	var budget := int(args.get("budget_frames", _cfg["walk_budget_frames"]))
	var close := float(args.get("close_enough", _cfg["walk_close_enough"]))
	# Frames the walk will wait, in total, for locomotion to come back before
	# giving up. `stick_navigator.gd` waits ten minutes and then returns false;
	# a harness cannot afford that, because a walk that hangs produces NO
	# evidence at all -- worse than a walk that reports where it stopped and
	# what was holding it. Measured on `main`: walking out of the spawn point
	# triggers Grandpa's opening conversation, `narrative_modal` takes
	# locomotion, and the walk waited indefinitely for a dialogue nobody was
	# answering.
	var held_budget := int(args.get("held_budget_frames", _cfg["walk_held_budget_frames"]))
	# Answer a conversation that stops the walk, by pressing the button a player
	# would. OFF by default and deliberately so: a segment testing whether a
	# conversation blocks travel must not have the harness quietly answering it.
	var answer := bool(args.get("answer_prompts", false))
	var nav: RefCounted = NAVIGATOR.new(self, player, rig,
		func(x: float, y: float) -> void: _stick_left = Vector2(x, y); _drive_sticks())
	var started := player.global_position
	var walked := 0
	var held := 0
	var arrived := false
	var held_by := ""
	nav.call("reset")
	while walked < budget:
		var to := target - player.global_position
		to.y = 0.0
		if to.length() <= close:
			arrived = true
			break
		if not bool(nav.call("can_walk")):
			# Locomotion is off: a fight, a fade, a conversation. Frames spent
			# held are not frames spent walking, so they do not count against
			# the WALK budget -- the navigator's own rule, kept here -- but they
			# do count against the held budget above.
			held += 1
			held_by = str(_probe.call("input_context"))
			if held > held_budget:
				break
			_stick_left = Vector2.ZERO
			_drive_sticks()
			nav.call("reset")
			if answer and held % 20 == 0:
				# Both verbs, alternating. `input_contexts.json`'s
				# `narrative_modal` context lists interact / ui_accept /
				# menu_confirm as the answers to a modal, and the three panels
				# that own that context do NOT all read the same one:
				# `dialogue_panel.gd` advances on `interact`, while
				# `starter_picker.gd::_read_input` polls `menu_confirm`. Tapping
				# only `interact` walked past Grandpa's conversation and then
				# sat in front of the starter picker for the whole held budget,
				# which is how this was found.
				await _inject("interact" if (held / 20) % 2 == 0 else "menu_confirm", HOLD_TAP)
			await physics_frame
			_tick(1.0 / float(Engine.physics_ticks_per_second))
			continue
		walked += 1
		await nav.call("step", target)
		_tick(1.0 / float(Engine.physics_ticks_per_second))
	_stick_left = Vector2.ZERO
	_drive_sticks()
	await physics_frame
	var gap := Vector2(player.global_position.x - target.x,
		player.global_position.z - target.z).length()
	if arrived:
		return "walked %.1f m to (%.0f, %.0f) in %d walking frames (%d held)" % [
			started.distance_to(player.global_position), target.x, target.z, walked, held]
	if held > held_budget:
		return ("FAIL locomotion never came back: held %d frames by input_context '%s' while %.1f m "
			+ "short of (%.0f, %.0f) at %s") % [held, held_by, gap, target.x, target.z,
				str(player.global_position.round())]
	return "FAIL did not reach (%.0f, %.0f) in %d walking frames; stopped %.1f m short at %s (%d held)" % [
		target.x, target.z, budget, gap, str(player.global_position.round()), held]


## Turn the camera. `yaw_deg` is an absolute world heading; `at:[x,z]` points
## the camera at a place. Driven by the look stick, not by writing `rig.yaw` --
## a written yaw proves nothing about whether the stick can reach it, and §9's
## camera-correction count only means something if the corrections are real.
func _step_face(args: Dictionary) -> String:
	var rig := _probe.call("camera_rig") as Node3D
	var player := _probe.call("player") as Node3D
	if rig == null:
		return "HARNESS-ERROR face with no live CameraRig"
	var want := float(args.get("yaw_deg", 0.0))
	if args.has("at") and player != null:
		var at: Array = args["at"] as Array
		var d := Vector2(float(at[0]) - player.global_position.x,
			float(at[1]) - player.global_position.z)
		want = rad_to_deg(atan2(-d.x, -d.y))
	var budget := int(args.get("budget_frames", 240))
	var tolerance := float(args.get("tolerance_deg", 4.0))
	var turned := 0
	while turned < budget:
		var have := rad_to_deg(float(rig.get("yaw")))
		var delta := rad_to_deg(angle_difference(deg_to_rad(have), deg_to_rad(want)))
		if absf(delta) <= tolerance:
			break
		_stick_right = Vector2(clampf(-delta / 45.0, -1.0, 1.0), 0.0)
		_drive_sticks()
		turned += 1
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))
	_stick_right = Vector2.ZERO
	_drive_sticks()
	await physics_frame
	var final := rad_to_deg(float(rig.get("yaw")))
	if turned >= budget:
		return "FAIL camera would not reach %.0f deg in %d frames (stopped at %.0f)" % [
			want, budget, final]
	return "camera turned to %.0f deg in %d frames" % [final, turned]


## Open the pause shell the way a player does: the bound action, as a real
## physical event plus the paired poll. Never `Game.menu().open()` -- calling
## open() proves open() works and nothing about whether the button reaches it,
## which is `smoke_menu.gd`'s own stated reason for existing.
func _step_open_menu(args: Dictionary, step_id: String) -> String:
	var tab := str(args.get("tab", ""))
	# `menu.json`'s `shortcuts` maps an action to a tab in both directions, so
	# a tab-targeted open is one press of that tab's own shortcut. With no tab
	# named it is the `game_menu` button.
	var control := str(args.get("control", "game_menu" if tab.is_empty() else _shortcut_for(tab)))
	if control.is_empty():
		return "HARNESS-ERROR open_menu step %s: no shortcut action opens tab '%s'" % [step_id, tab]
	var before := str(_probe.call("input_context"))
	var sent := await _inject(control, HOLD_TAP)
	if not bool(sent.get("ok", false)):
		return "HARNESS-ERROR %s" % str(sent.get("why", ""))
	# Polled rather than a fixed settle. `game_menu.gd::open()` builds its tabs
	# on first open and the focus lands a frame or two later; a fixed wait that
	# was long enough on this box would be a flake somewhere slower.
	await _settle_until(func() -> bool: return str(_probe.call("input_context")).begins_with("menu"))
	var after := str(_probe.call("input_context"))
	var state: Dictionary = _probe.call("input_state")
	if not after.begins_with("menu"):
		return "FAIL %s did not open the pause shell: context %s -> %s (owner=%s)" % [
			control, before, after, str(state.get("owner", ""))]
	return "%s opened the shell: context %s -> %s, focus on '%s' (%s)" % [control, before, after,
		str(state.get("focus_text", "")), str(state.get("focus_owner", ""))]


func _step_close_menu(args: Dictionary, step_id: String) -> String:
	var control := str(args.get("control", "menu_cancel"))
	var before := str(_probe.call("input_context"))
	var sent := await _inject(control, HOLD_TAP)
	if not bool(sent.get("ok", false)):
		return "HARNESS-ERROR %s" % str(sent.get("why", ""))
	await _settle_until(func() -> bool: return not str(_probe.call("input_context")).begins_with("menu"))
	var after := str(_probe.call("input_context"))
	if after.begins_with("menu"):
		return "FAIL %s left the shell open: context %s -> %s" % [control, before, after]
	return "%s closed the shell: context %s -> %s" % [control, before, after]


## Move GUI focus. This is the step that cannot work without
## `Input.parse_input_event` and is why `_inject` sends the physical event
## first: `ui_down` as a bare `Input.action_press` writes a polled bit that no
## Control ever reads, and the focus stays exactly where it was.
func _step_focus_move(args: Dictionary, step_id: String) -> String:
	var direction := str(args.get("direction", "down"))
	var control := "ui_%s" % direction
	var times := int(args.get("times", 1))
	if not InputMap.has_action(control):
		return "HARNESS-ERROR focus_move step %s: no action '%s'" % [step_id, control]
	var before: Dictionary = _probe.call("input_state")
	for i in times:
		var sent := await _inject(control, HOLD_TAP)
		if not bool(sent.get("ok", false)):
			return "HARNESS-ERROR %s" % str(sent.get("why", ""))
		for f in 3:
			await process_frame
	var after: Dictionary = _probe.call("input_state")
	if str(before.get("focus_owner", "")) == str(after.get("focus_owner", "")) \
			and str(before.get("focus_text", "")) == str(after.get("focus_text", "")):
		return "FAIL %d x %s did not move focus off %s" % [times, control, _focus_name(before)]
	return "%d x %s moved focus %s -> %s" % [times, control, _focus_name(before), _focus_name(after)]


## A focused control's label if it has one, its node name otherwise.
##
## Both, because neither alone is readable: the satchel's slot buttons are icon
## chips with empty `text`, so a text-only report of a real focus move reads as
## "'' -> ''" and looks like nothing happened. The node name is auto-generated
## and meaningless on its own, which is why the label wins when there is one.
func _focus_name(state: Dictionary) -> String:
	var text := str(state.get("focus_text", ""))
	var owner := str(state.get("focus_owner", ""))
	if owner.is_empty():
		return "nothing"
	return "'%s' (%s)" % [text, owner] if not text.is_empty() else owner


func _step_capture(args: Dictionary, step_id: String) -> String:
	var shot_id := str(args.get("id", step_id))
	var row := {
		"id": shot_id,
		"class": str(args.get("class", "context")),
		"segment": _segment_id,
		"t": _t(),
		"trigger": str(args.get("trigger", "planned")),
		"pos": _pos_array(),
		"camera_kind": str(args.get("camera_kind", "gameplay")),
		"clock_hour": float((_probe.call("clock_weather") as Dictionary).get("hour", 0.0)),
		"weather": str((_probe.call("clock_weather") as Dictionary).get("weather", "")),
		"hud": str(args.get("hud", "on")),
		"intended_proof": str(args.get("intended_proof", "")),
		"file": null,
	}
	if not _capture_available():
		# §C.4: an absent frame is evidence. The reason is recorded rather than
		# the row being dropped, so a planned shot cannot go missing silently.
		row["reason"] = "headless: this process has no display server and cannot render a frame"
		_manifest.append(row)
		_emit("screenshot", {"artifacts": [shot_id], "observation": str(row["reason"])})
		return "capture %s skipped (headless run); manifest row written with file:null" % shot_id
	if not _telemetry_on():
		row["reason"] = "telemetry off: no --gatef-out, nowhere to write a PNG"
		_manifest.append(row)
		return "capture %s skipped (telemetry off)" % shot_id
	for i in int(_cfg["capture_settle_frames"]):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		row["reason"] = "viewport returned an empty image"
		_manifest.append(row)
		_emit("screenshot", {"artifacts": [shot_id], "observation": str(row["reason"])})
		return "FAIL capture %s produced no image" % shot_id
	var rel := "shots/%s.png" % shot_id
	var err := image.save_png(_out_dir.path_join(rel))
	if err != OK:
		row["reason"] = "save_png failed with error %d" % err
		_manifest.append(row)
		return "FAIL capture %s could not be written (%d)" % [shot_id, err]
	row["file"] = rel
	row["size"] = [image.get_width(), image.get_height()]
	_manifest.append(row)
	_emit("screenshot", {"artifacts": [shot_id]})
	return "captured %s at %dx%d" % [shot_id, image.get_width(), image.get_height()]


## A timed run of frames, for a motion the operator has to be able to watch
## back (a combat exchange, a transition). Each frame is its own manifest row
## so a single missing frame is visible rather than averaged away.
func _step_capture_seq(args: Dictionary, step_id: String) -> String:
	var hz := maxf(1.0, float(args.get("hz", 5.0)))
	var seconds := maxf(0.2, float(args.get("seconds", 2.0)))
	var count := int(hz * seconds)
	var gap := int(maxf(1.0, float(Engine.physics_ticks_per_second) / hz))
	var written := 0
	for i in count:
		var sub: Dictionary = args.duplicate()
		sub["id"] = "%s-%03d" % [str(args.get("id", step_id)), i]
		var line := await _step_capture(sub, step_id)
		if line.begins_with("captured"):
			written += 1
		for f in gap:
			await physics_frame
			_tick(1.0 / float(Engine.physics_ticks_per_second))
	return "capture_seq %s: %d/%d frames written at %.0f Hz" % [
		str(args.get("id", step_id)), written, count, hz]


## §5. One (control, context) cell of the exhaustion matrix.
##
## The context is expected to be already established by the steps before this
## one, through the production path -- this routine does not open anything
## itself, because a context this file set up is not the context the player
## reaches. It snapshots, injects one tap, snapshots again, and reports the
## DELTAS. World side effects are read off live state (did the player move, did
## the satchel change, did the camera turn, did a ghost arm, did the party's
## active member change), never scraped from a log line.
func _step_probe_cell(args: Dictionary, step_id: String) -> String:
	var control := str(args.get("control", ""))
	if control.is_empty():
		return "HARNESS-ERROR probe_cell step %s has no control" % step_id
	var before := _cell_snapshot()
	var sent := await _inject(control, HOLD_TAP)
	if not bool(sent.get("ok", false)):
		return "HARNESS-ERROR %s" % str(sent.get("why", ""))
	# The release edge is where leakage most often shows: a surface that
	# consumes the press and a second one that acts on the release.
	await physics_frame
	var on_release := _cell_snapshot()
	for i in 6:
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))
	var after := _cell_snapshot()
	var world_effect := _describe_delta(before, after, ["pos", "inventory", "equipped",
		"pending_build", "active_creature", "camera_yaw", "party_size", "flags"])
	var ui_effect := _describe_delta(before, after, ["context", "focus_owner", "focus_text",
		"tree_paused", "mouse_mode"])
	var release_effect := _describe_delta(before, on_release, ["pos", "context", "focus_text",
		"inventory", "pending_build"])
	_emit("input_probe", {
		"input": _last_input,
		"expected": str(args.get("expected", "")),
		"actual": "world=[%s] ui=[%s] release_edge=[%s]" % [world_effect, ui_effect, release_effect],
		"observation": "cell control=%s context_before=%s context_after=%s focus_before=%s focus_after=%s" % [
			control, str(before.get("context")), str(after.get("context")),
			str(before.get("focus_text")), str(after.get("focus_text"))],
	})
	return "cell %s in %s: world=[%s] ui=[%s] release=[%s]" % [control,
		str(before.get("context")), world_effect, ui_effect, release_effect]


func _step_assert(args: Dictionary) -> Dictionary:
	var check := str(args.get("check", ""))
	match check:
		"input_context":
			var want := str(args.get("equals", ""))
			var have := str(_probe.call("input_context"))
			return {"ok": have == want, "actual": "input_context=%s (wanted %s)" % [have, want]}
		"context_prefix":
			var want := str(args.get("prefix", ""))
			var have := str(_probe.call("input_context"))
			return {"ok": have.begins_with(want), "actual": "input_context=%s (wanted prefix %s)" % [have, want]}
		"focus_owned":
			var state: Dictionary = _probe.call("input_state")
			var who := str(state.get("focus_owner", ""))
			return {"ok": not who.is_empty(),
				"actual": "focus_owner=%s focus_text=%s" % [who, str(state.get("focus_text", ""))]}
		"flag_set":
			var flag := str(args.get("flag", ""))
			var have: Array = _probe.call("flags")
			return {"ok": have.has(flag), "actual": "flag %s %s" % [flag,
				"set" if have.has(flag) else "NOT set"]}
		"objective_is":
			var want := str(args.get("id", ""))
			var obj: Dictionary = _probe.call("tracked_objective")
			return {"ok": str(obj.get("id", "")) == want,
				"actual": "tracked objective id=%s text=%s (wanted %s)" % [
					str(obj.get("id", "")), str(obj.get("text", "")), want]}
		"party_size":
			var want := int(args.get("equals", -1))
			var have := (_probe.call("party_state") as Array).size()
			return {"ok": have == want, "actual": "party size %d (wanted %d)" % [have, want]}
		"region_is":
			var want := str(args.get("equals", ""))
			var player := _probe.call("player") as Node3D
			var have := "" if player == null else str(_probe.call("region_at", player.global_position))
			return {"ok": have == want, "actual": "region=%s (wanted %s)" % [have, want]}
		"near":
			var at: Array = args.get("at", []) as Array
			var within := float(args.get("within", 5.0))
			var player := _probe.call("player") as Node3D
			if player == null or at.size() < 2:
				return {"ok": false, "actual": "no live player, or at:[x,z] missing"}
			var d := Vector2(player.global_position.x - float(at[0]),
				player.global_position.z - float(at[1])).length()
			return {"ok": d <= within,
				"actual": "%.1f m from (%.0f, %.0f), wanted within %.1f" % [d, float(at[0]), float(at[1]), within]}
		"dead_travel_below":
			var ceiling := float(args.get("metres", 0.0))
			return {"ok": _dead_travel_m <= ceiling,
				"actual": "dead_travel=%.1f m (ceiling %.1f)" % [_dead_travel_m, ceiling]}
		"route_rows_at_least":
			var want := int(args.get("rows", 0))
			return {"ok": _trace_rows >= want,
				"actual": "route.csv has %d rows (wanted >= %d)" % [_trace_rows, want]}
		_:
			return {"ok": false, "actual": "unknown assert check '%s'" % check}


# --- save handoff (§7) -------------------------------------------------------

## Copy a slot file OUT of `user://` into the run directory after a save made
## through the production Save tab.
##
## Deliberately does NOT save anything itself. §7's point is that the operator
## saves the way a player does, and this only preserves the artefact. Calling
## `Game.save_game()` here would prove the serializer works and nothing about
## whether the Save tab reaches it.
func _step_save_out(args: Dictionary) -> String:
	var slot := int(args.get("slot", 4))
	var src := _slot_path(slot)
	if src.is_empty():
		return "HARNESS-ERROR no live save system to ask for slot %d's path" % slot
	if not FileAccess.file_exists(src):
		return "FAIL slot %d has no file at %s -- did the Save tab actually write?" % [slot, src]
	if not _telemetry_on():
		return "slot %d exists at %s (not copied: telemetry off)" % [slot, src]
	var name := str(args.get("name", "slot_%d.json" % slot))
	var dst := _out_dir.path_join("saves").path_join(name)
	var bytes := FileAccess.get_file_as_bytes(src)
	var out := FileAccess.open(dst, FileAccess.WRITE)
	if out == null:
		return "HARNESS-ERROR could not write %s" % dst
	out.store_buffer(bytes)
	out.close()
	_emit("save", {"artifacts": [name], "observation": "slot %d copied out (%d bytes)" % [slot, bytes.size()]})
	return "slot %d copied to saves/%s (%d bytes)" % [slot, name, bytes.size()]


## Put a slot file back into `user://` before booting the title, so the next
## segment's Load Game finds the previous segment's ending state.
func _step_seed_save(args: Dictionary) -> String:
	var slot := int(args.get("slot", 4))
	var from := str(args.get("from", ""))
	if from.is_empty():
		return "HARNESS-ERROR seed_save needs from:<path to a slot json>"
	# `run://` resolves against this run's own saves/ directory. A segment
	# script cannot know the run directory's name -- it is stamped with a
	# timestamp at launch -- so without this a handoff could only be expressed
	# as an absolute path that is wrong for every run but the one it was
	# written during.
	if from.begins_with("run://"):
		if not _telemetry_on():
			return "HARNESS-ERROR seed_save from run:// needs --gatef-out to know which run"
		from = _out_dir.path_join("saves").path_join(from.trim_prefix("run://"))
	if not FileAccess.file_exists(from):
		return "FAIL seed source %s does not exist" % from
	var dst := _slot_path(slot)
	if dst.is_empty():
		return "HARNESS-ERROR no live save system to ask for slot %d's path" % slot
	DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
	var bytes := FileAccess.get_file_as_bytes(from)
	var out := FileAccess.open(dst, FileAccess.WRITE)
	if out == null:
		return "HARNESS-ERROR could not write %s" % dst
	out.store_buffer(bytes)
	out.close()
	_emit("load", {"observation": "seeded slot %d from %s (%d bytes)" % [slot, from, bytes.size()]})
	return "seeded slot %d from %s (%d bytes)" % [slot, from, bytes.size()]


## Empty the live save directory. The wipe half of the round trip: a load that
## found the state still sitting in memory would prove nothing.
func _step_wipe_saves(args: Dictionary) -> String:
	var keep: Array = args.get("keep_slots", []) as Array
	var dir_path := _slot_path(0).get_base_dir()
	if dir_path.is_empty():
		return "HARNESS-ERROR no live save system to locate the save directory"
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return "save directory %s does not exist yet; nothing to wipe" % dir_path
	var removed := 0
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir():
			var slot_kept := false
			for k: Variant in keep:
				if name == "slot_%d.json" % int(k):
					slot_kept = true
			if not slot_kept:
				dir.remove(name)
				removed += 1
		name = dir.get_next()
	dir.list_dir_end()
	return "wiped %d files from %s (kept slots %s)" % [removed, dir_path, str(keep)]


## Where the LIVE save system puts a slot. Asked of `Game.save_system` rather
## than hard-coded as `user://saves/slot_N.json`, so a run that has swapped in
## an isolated directory (every regression test does) is copied from the
## directory it actually used.
func _slot_path(slot: int) -> String:
	var g := _probe.call("game") as Node
	if g == null:
		return ""
	var system: Variant = g.get("save_system")
	if system == null:
		return ""
	return ProjectSettings.globalize_path(str(system.call("slot_path", slot)))


## DIAG only, and refused above unless the step says so. Recorded as its own
## observation so Phase B can never read a teleported arrival as a walk.
func _step_teleport(args: Dictionary) -> String:
	var player := _probe.call("player") as Node3D
	if player == null:
		return "HARNESS-ERROR teleport with no live Player"
	var at: Array = args.get("at", []) as Array
	if at.size() < 2:
		return "HARNESS-ERROR teleport needs at:[x,z]"
	var world: Node = _probe.call("world") as Node
	var y := player.global_position.y
	if world != null and world.has_method("ground_height_at"):
		y = float(world.call("ground_height_at", float(at[0]), float(at[1]))) + 1.0
	player.global_position = Vector3(float(at[0]), y, float(at[1]))
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	var rig := _probe.call("camera_rig") as Node3D
	if rig != null:
		rig.global_position = player.global_position
	for i in int(args.get("resettle_frames", 60)):
		await physics_frame
	# A teleport is not travel. Resetting the accumulators here stops a 2 km
	# jump appearing in the pacing study as 2 km of dead walking.
	_have_last_pos = false
	_probe.call("refresh_pois")
	return "DIAG teleport to (%.0f, %.0f); distance/dead-travel accumulators reset" % [
		float(at[0]), float(at[1])]


# --- input injection ---------------------------------------------------------

## Send one control, both ways, for `frames` physics frames.
##
## Returns `{ok, raw, why}`. `raw` is the physical event in the shorthand §C.1's
## `input.raw` field wants ("JoyBtn:2", "JoyAxis:1:-1.0", "Key:70").
func _inject(control: String, frames: int) -> Dictionary:
	var down := _edge(control, true)
	if not bool(down.get("ok", false)):
		return down
	for i in maxi(1, frames):
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))
	var up := _edge(control, false)
	await physics_frame
	_tick(1.0 / float(Engine.physics_ticks_per_second))
	_last_input = {"device": "synthetic", "raw": str(down.get("raw", "")),
		"action": control, "edge": "press"}
	return {"ok": bool(up.get("ok", false)), "raw": str(down.get("raw", ""))}


## One edge of one control: the physical event AND the paired action state.
##
## Both, always. See this file's header for the two measured failures that
## sending only one half causes. The physical event goes first because the
## viewport's focus walk happens on the event, and a poll set beforehand can
## make a same-frame reader see a press that has not physically arrived yet.
func _edge(control: String, pressed: bool) -> Dictionary:
	var action := StringName(control)
	if not InputMap.has_action(action):
		return {"ok": false, "why": "no input action '%s' in the live InputMap" % control}
	var binding := _physical_binding(action)
	if binding == null:
		return {"ok": false, "why": "action '%s' has no physical binding to inject" % control}
	var raw := ""
	if binding is InputEventJoypadButton:
		var b := InputEventJoypadButton.new()
		b.button_index = (binding as InputEventJoypadButton).button_index
		b.pressed = pressed
		Input.parse_input_event(b)
		raw = "JoyBtn:%d" % b.button_index
	elif binding is InputEventJoypadMotion:
		var m := InputEventJoypadMotion.new()
		m.axis = (binding as InputEventJoypadMotion).axis
		m.axis_value = (binding as InputEventJoypadMotion).axis_value if pressed else 0.0
		Input.parse_input_event(m)
		raw = "JoyAxis:%d:%.1f" % [int(m.axis), m.axis_value]
	elif binding is InputEventKey:
		var k := InputEventKey.new()
		k.keycode = (binding as InputEventKey).keycode
		k.physical_keycode = (binding as InputEventKey).physical_keycode
		k.pressed = pressed
		Input.parse_input_event(k)
		raw = "Key:%d" % int(k.keycode)
	elif binding is InputEventMouseButton:
		var mb := InputEventMouseButton.new()
		mb.button_index = (binding as InputEventMouseButton).button_index
		mb.pressed = pressed
		mb.position = Vector2(_viewport_size()) * 0.5
		Input.parse_input_event(mb)
		raw = "MouseBtn:%d" % int(mb.button_index)
	else:
		return {"ok": false, "why": "action '%s' binds an event type this harness cannot synthesize (%s)"
			% [control, binding.get_class()]}

	if pressed:
		Input.action_press(action, 1.0)
	else:
		Input.action_release(action)
	return {"ok": true, "raw": raw}


## The physical event to synthesize for an action.
##
## Joypad first: this ships controller-first on a handheld, so a pad binding is
## the one a segment is really testing. Keyboard and mouse are the fallbacks,
## in that order, for the actions `input_contexts.json` records as
## keyboard-only (torch, the hammer, the tool swing) -- a harness that refused
## those would have no way to reach half the world verbs.
func _physical_binding(action: StringName) -> InputEvent:
	var by_kind := {"joy": null, "key": null, "mouse": null}
	for event in InputMap.action_get_events(action):
		if (event is InputEventJoypadButton or event is InputEventJoypadMotion) \
				and by_kind["joy"] == null:
			by_kind["joy"] = event
		elif event is InputEventKey and by_kind["key"] == null:
			by_kind["key"] = event
		elif event is InputEventMouseButton and by_kind["mouse"] == null:
			by_kind["mouse"] = event
	for kind in ["joy", "key", "mouse"]:
		if by_kind[kind] != null:
			return by_kind[kind] as InputEvent
	return null


## Advance process frames until `condition` is true, up to `budget`.
##
## Process frames, not physics: a paused tree still runs `_process` on
## PROCESS_ALWAYS nodes, which is every menu, and a physics-frame wait inside an
## open pause shell would spin for the full budget every time.
func _settle_until(condition: Callable, budget: int = 40) -> bool:
	for i in budget:
		await process_frame
		if bool(condition.call()):
			# Two more frames after the condition first reads true: a Control's
			# focus is granted deferred, so the frame the panel reports open is
			# routinely the frame before anything holds focus.
			await process_frame
			await process_frame
			return true
	return false


func _hold_frames(spec: Variant) -> int:
	match typeof(spec):
		TYPE_INT, TYPE_FLOAT:
			return maxi(1, int(spec))
		_:
			match str(spec):
				"tap":
					return HOLD_TAP
				"short":
					return HOLD_SHORT
				"long":
					return HOLD_LONG
				_:
					return HOLD_TAP


## Push both analogue sticks, both ways.
##
## The polled half is what `player_controller.gd` and `camera_rig.gd` read
## (`Input.get_vector`), and it is the ONLY half that moves the player -- proven
## by measurement in `gate_a_build_segment.gd`'s own header. The parsed half is
## sent anyway so that anything listening for a stick as an EVENT (a Control's
## focus walk, an `_unhandled_input` reader) sees the same deflection. Sending
## one and not the other is how a harness ends up able to walk but not able to
## navigate a menu, or the reverse.
func _drive_sticks() -> void:
	_press_axis(&"move_right", clampf(_stick_left.x, 0.0, 1.0))
	_press_axis(&"move_left", clampf(-_stick_left.x, 0.0, 1.0))
	_press_axis(&"move_back", clampf(_stick_left.y, 0.0, 1.0))
	_press_axis(&"move_forward", clampf(-_stick_left.y, 0.0, 1.0))
	_press_axis(&"look_right", clampf(_stick_right.x, 0.0, 1.0))
	_press_axis(&"look_left", clampf(-_stick_right.x, 0.0, 1.0))
	_press_axis(&"look_down", clampf(_stick_right.y, 0.0, 1.0))
	_press_axis(&"look_up", clampf(-_stick_right.y, 0.0, 1.0))


func _press_axis(action: StringName, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength <= 0.001:
		Input.action_release(action)
	else:
		Input.action_press(action, strength)
	var binding := _physical_binding(action)
	var motion := binding as InputEventJoypadMotion
	if motion == null:
		return
	var m := InputEventJoypadMotion.new()
	m.axis = motion.axis
	m.axis_value = signf(motion.axis_value) * strength
	Input.parse_input_event(m)


## Let go of everything at the end of a run, so a crashed segment cannot leave
## an action latched into the next process on the same virtual device.
func _release_everything() -> void:
	_stick_left = Vector2.ZERO
	_stick_right = Vector2.ZERO
	_drive_sticks()
	for action in InputMap.get_actions():
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _shortcut_for(tab: String) -> String:
	var menu := _read_json("res://data/config/menu.json")
	var shortcuts: Dictionary = menu.get("shortcuts", {}) as Dictionary
	for action: Variant in shortcuts.keys():
		if str(shortcuts[action]) == tab:
			return str(action)
	return ""


# --- telemetry ---------------------------------------------------------------

## Seconds since the segment started. Monotonic; `Time.get_ticks_usec()` does
## not move when the tree is paused but wall clock does, and a menu segment
## spends most of its length paused.
func _t() -> float:
	return float(Time.get_ticks_usec() - _t0_usec) / 1_000_000.0


## One event, with the whole §C.1 record filled from live state.
##
## `overrides` supplies the per-event-type fields (`expected`, `actual`,
## `duration_ms`, `artifacts`, ...). Anything not applicable is OMITTED, never
## emitted as a zero or an empty string: §C.1's own instruction, and the reason
## `vram` and a device fps have no code path here at all.
func _emit(type: String, overrides: Dictionary = {}) -> void:
	if not _telemetry_on() or _events == null:
		return
	var player := _probe.call("player") as Node3D
	var pos := player.global_position if player != null else Vector3.ZERO
	var record := {
		"run_id": _run_id,
		"sha": _sha,
		"segment": _segment_id,
		"t": snappedf(_t(), 0.001),
		"wall": Time.get_datetime_string_from_system(true, true),
		"type": type,
		"region": str(_probe.call("region_at", pos)),
		"pos": [snappedf(pos.x, 0.01), snappedf(pos.y, 0.01), snappedf(pos.z, 0.01)],
		"input_context": str(_probe.call("input_context")),
		"input_state": _probe.call("input_state"),
		"distance_m": snappedf(_distance_m, 0.01),
		"since_interaction_s": snappedf(_since_interaction_s, 0.01),
		"dead_travel_m": snappedf(_dead_travel_m, 0.01),
	}
	var objective: Dictionary = _probe.call("tracked_objective")
	if not objective.is_empty():
		record["objective"] = objective
	if player != null:
		var model := player.get_node_or_null(^"Model") as Node3D
		if model != null:
			record["heading"] = snappedf(rad_to_deg(model.global_rotation.y), 0.1)
	var camera: Dictionary = _probe.call("camera_pose")
	if not camera.is_empty():
		record["camera"] = camera
	var party: Array = _probe.call("party_state")
	if not party.is_empty():
		record["party"] = party
	var active: Variant = _probe.call("active_creature")
	if active != null:
		record["active_creature"] = active
	var vitals: Dictionary = _probe.call("player_vitals")
	if not vitals.is_empty():
		record["player"] = vitals
	var equipped: Dictionary = _probe.call("equipped")
	if not equipped.is_empty():
		record["equipped"] = equipped
	var combat: Dictionary = _probe.call("combat_state")
	if not combat.is_empty():
		record["combat"] = combat
	var clock: Dictionary = _probe.call("clock_weather")
	record["clock_hour"] = snappedf(float(clock.get("hour", 0.0)), 0.01)
	record["weather"] = str(clock.get("weather", ""))
	record["light"] = {"sun_energy": clock.get("sun_energy", 0.0), "preset": clock.get("preset", "")}
	if not _last_input.is_empty():
		record["input"] = _last_input
	# A full inventory snapshot on the event types §C.1 names; the delta is
	# carried by the 2 Hz trace's neighbours everywhere else, and a 24-slot
	# dictionary on every note event would triple the file for no reader.
	if type in ["gather", "craft", "build_place", "build_cancel", "build_dismantle", "save", "load"]:
		record["inventory"] = _probe.call("inventory_snapshot")
	var perf := _perf_window()
	if not perf.is_empty():
		record["perf"] = perf
	# §C.1: "Omit a field when not applicable to the event type; never emit
	# fabricated values." A null `severity_candidate` on every note event is not
	# a fabrication but it is noise, and noise in an evidence file is how a real
	# `severity_candidate` stops standing out.
	for key: Variant in overrides.keys():
		var value: Variant = overrides[key]
		if value == null:
			continue
		if typeof(value) == TYPE_STRING and (value as String).is_empty():
			continue
		record[key] = value
	_events.store_line(JSON.stringify(record))
	_events.flush()
	if _is_meaningful(type):
		_since_interaction_s = 0.0
		_dead_travel_m = 0.0


## §F's list, verbatim: dialogue, combat, catch, gather, craft, build, rest,
## feed, objective change, landmark discovery, item pickup, shop/trade. A
## `note` or a `screenshot` is the operator writing something down, not the
## player doing something, and must not reset the dead-travel meter.
func _is_meaningful(type: String) -> bool:
	return type in ["dialogue", "combat_start", "combat_hit", "combat_switch", "combat_end",
		"catch_throw", "catch_result", "gather", "craft", "build_place", "build_dismantle",
		"rest", "feed", "objective", "landmark_discover", "level_up"]


## Per-frame bookkeeping. Called from every step that advances frames, so the
## counters move with the game rather than with wall clock.
func _tick(delta: float) -> void:
	_sample_frame()
	_since_interaction_s += delta
	var player := _probe.call("player") as Node3D
	if player != null:
		var here := player.global_position
		if _have_last_pos:
			var moved := Vector2(here.x - _last_pos.x, here.z - _last_pos.z).length()
			# A jump larger than a physics step can travel is a teleport or a
			# scene swap, not walking; counting it would put kilometres into
			# the pacing study that nobody walked.
			if moved < 5.0:
				_distance_m += moved
				_dead_travel_m += moved
		_last_pos = here
		_have_last_pos = true
		# §F: the dead-travel run resets on a POI within 30 m as well as on an
		# interaction. This is the "and could they choose to go to it" half of
		# the definition -- passing a wild creature ends a dead walk whether or
		# not the player stops.
		if float(_probe.call("nearest_poi_dist", here)) <= PROBE.POI_RADIUS_M:
			_dead_travel_m = 0.0
	_watch_for_events()
	if _t() >= _next_trace_t:
		_write_trace_row()
		_next_trace_t = _t() + (1.0 / maxf(0.1, float(_cfg["trace_hz"])))


func _sample_frame() -> void:
	_frame_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	if _frame_ms.size() > int(_cfg["perf_window_frames"]):
		_frame_ms.remove_at(0)


## `{frame_ms_avg, frame_ms_p95, frame_ms_max}` over the trailing window.
##
## CPU process time on THIS box and nothing else. No fps figure: a headless or
## software-rasterised process has a frame rate that is a property of the
## container, and reporting it as the game's would be the exact fabrication
## §C.1 forbids.
func _perf_window() -> Dictionary:
	if _frame_ms.is_empty():
		return {}
	var sorted := _frame_ms.duplicate()
	sorted.sort()
	var sum := 0.0
	for v: float in sorted:
		sum += v
	var p95_index := clampi(int(float(sorted.size()) * 0.95), 0, sorted.size() - 1)
	return {
		"frame_ms_avg": snappedf(sum / float(sorted.size()), 0.01),
		"frame_ms_p95": snappedf(sorted[p95_index], 0.01),
		"frame_ms_max": snappedf(sorted[sorted.size() - 1], 0.01),
	}


func _write_trace_row() -> void:
	if not _telemetry_on() or _route == null:
		return
	var player := _probe.call("player") as Node3D
	var pos := player.global_position if player != null else Vector3.ZERO
	var heading := 0.0
	if player != null:
		var model := player.get_node_or_null(^"Model") as Node3D
		if model != null:
			heading = rad_to_deg(model.global_rotation.y)
	var clock: Dictionary = _probe.call("clock_weather")
	var poi := INF if player == null else float(_probe.call("nearest_poi_dist", pos))
	_route.store_line("%.2f,%s,%.2f,%.2f,%.2f,%.1f,%s,%.2f,%s,%.3f,%.3f,%.2f,%s,%s" % [
		_t(), Time.get_datetime_string_from_system(true, true),
		pos.x, pos.y, pos.z, heading,
		str(_probe.call("region_at", pos)),
		float(clock.get("hour", 0.0)), str(clock.get("weather", "")),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		_dead_travel_m,
		"" if is_inf(poi) else "%.2f" % poi,
		str(_probe.call("input_context")),
	])
	_route.flush()
	_trace_rows += 1


## Turn live-state changes into schema events, with no hook inside gameplay.
##
## This is the whole reason the prime directive is affordable. A signal
## connected inside `combat_manager.gd` would be one more line running in a
## shipped build; watching the state the manager already exposes costs the game
## nothing and cannot alter what it does.
##
## The honest limit: an event is timestamped when the harness NOTICES it, which
## is the next frame it ticks, not the frame the game set it. At 60 Hz that is
## under 17 ms and irrelevant to the pacing study; it would matter to a
## frame-exact input study and does not claim to serve one.
func _watch_for_events() -> void:
	if not _telemetry_on():
		return
	var objective: Dictionary = _probe.call("tracked_objective")
	if str(objective.get("id", "")) != str(_prev_objective.get("id", "")):
		_prev_objective = objective
		_emit("objective", {"observation": "tracked objective changed"})

	var flags: Array = _probe.call("flags")
	if flags.size() != _prev_flags.size():
		var added: Array = []
		for f: Variant in flags:
			if not _prev_flags.has(f):
				added.append(f)
		_prev_flags = flags
		if not added.is_empty():
			_emit("flag_set", {"flags": added})

	var player := _probe.call("player") as Node3D
	if player != null:
		var region := str(_probe.call("region_at", player.global_position))
		if region != _prev_region:
			var was := _prev_region
			_prev_region = region
			_emit("region_enter", {"observation": "region %s -> %s" % [was, region]})
			_probe.call("refresh_pois")

	var state: Dictionary = _probe.call("input_state")
	var fighting := bool(state.get("combat_running", false))
	if fighting != _prev_combat_running:
		_prev_combat_running = fighting
		_emit("combat_start" if fighting else "combat_end")
		if not fighting:
			# A fight that ended may have removed a wild creature from the
			# world; the POI cache has to hear about it or dead-travel keeps
			# resetting on something that is no longer there.
			_probe.call("refresh_pois")

	var context := str(_probe.call("input_context"))
	if context != _prev_context:
		var was_ctx := _prev_context
		_prev_context = context
		if context.begins_with("menu") and not was_ctx.begins_with("menu"):
			_emit("menu_open", {"observation": "input_context %s -> %s" % [was_ctx, context]})
		elif was_ctx.begins_with("menu") and not context.begins_with("menu"):
			_emit("menu_close", {"observation": "input_context %s -> %s" % [was_ctx, context]})
		elif context.begins_with("menu") and was_ctx.begins_with("menu"):
			_emit("tab_change", {"observation": "input_context %s -> %s" % [was_ctx, context]})
		else:
			_emit("note", {"observation": "input_context %s -> %s" % [was_ctx, context]})

	var party: Array = _probe.call("party_state")
	if _prev_party_size >= 0 and party.size() > _prev_party_size:
		_emit("catch_result", {"observation": "party grew %d -> %d" % [_prev_party_size, party.size()]})
	_prev_party_size = party.size()
	for entry: Variant in party:
		var creature: Dictionary = entry
		var name := str(creature.get("name", ""))
		var level := int(creature.get("level", 0))
		if _prev_levels.has(name) and level > int(_prev_levels[name]):
			_emit("level_up", {"observation": "%s reached level %d" % [name, level]})
		if float(creature.get("hp", 1.0)) <= 0.0 and float(_prev_levels.get("%s:hp" % name, 1.0)) > 0.0:
			_emit("faint", {"observation": "%s fainted" % name})
		_prev_levels[name] = level
		_prev_levels["%s:hp" % name] = creature.get("hp", 1.0)


## Prime the change detectors after a boot, so the first tick does not report
## every flag on the save as newly set and every creature as newly caught.
func _seed_change_detection() -> void:
	_prev_flags = _probe.call("flags")
	_prev_objective = _probe.call("tracked_objective")
	_prev_context = str(_probe.call("input_context"))
	var player := _probe.call("player") as Node3D
	_prev_region = "" if player == null else str(_probe.call("region_at", player.global_position))
	var state: Dictionary = _probe.call("input_state")
	_prev_combat_running = bool(state.get("combat_running", false))
	var party: Array = _probe.call("party_state")
	_prev_party_size = party.size()
	_prev_levels.clear()
	for entry: Variant in party:
		var creature: Dictionary = entry
		_prev_levels[str(creature.get("name", ""))] = int(creature.get("level", 0))
		_prev_levels["%s:hp" % str(creature.get("name", ""))] = creature.get("hp", 1.0)
	_have_last_pos = false


# --- input-cell snapshots ----------------------------------------------------

func _cell_snapshot() -> Dictionary:
	var player := _probe.call("player") as Node3D
	var state: Dictionary = _probe.call("input_state")
	var camera: Dictionary = _probe.call("camera_pose")
	return {
		"pos": player.global_position if player != null else Vector3.ZERO,
		"context": str(_probe.call("input_context")),
		"focus_owner": str(state.get("focus_owner", "")),
		"focus_text": str(state.get("focus_text", "")),
		"tree_paused": bool(state.get("tree_paused", false)),
		"mouse_mode": int(state.get("mouse_mode", 0)),
		"pending_build": str(state.get("pending_build", "")),
		"inventory": _probe.call("inventory_snapshot"),
		"equipped": _probe.call("equipped"),
		"active_creature": _probe.call("active_creature"),
		"camera_yaw": float(camera.get("yaw", 0.0)),
		"party_size": (_probe.call("party_state") as Array).size(),
		"flags": (_probe.call("flags") as Array).size(),
	}


## Human-readable list of which watched keys changed. "none" is the answer §8
## most wants to see for a cell that is supposed to be inert.
func _describe_delta(before: Dictionary, after: Dictionary, keys: Array) -> String:
	var out: Array[String] = []
	for key: Variant in keys:
		var a: Variant = before.get(key)
		var b: Variant = after.get(key)
		if key == "pos":
			var moved := (b as Vector3).distance_to(a as Vector3)
			if moved > 0.05:
				out.append("pos +%.2fm" % moved)
			continue
		if key == "camera_yaw":
			if absf(float(b) - float(a)) > 0.5:
				out.append("camera_yaw %.1f -> %.1f" % [float(a), float(b)])
			continue
		if str(a) != str(b):
			out.append("%s %s -> %s" % [key, str(a), str(b)])
	return "none" if out.is_empty() else ", ".join(out)


# --- §8 overhead self-measurement --------------------------------------------

## Idle at a fixed site for `overhead_seconds`, twice: once with the trace and
## capture cadence running, once with them off. Writes the difference into
## `RUN_METADATA.json`'s `instrumentation_overhead_note`.
##
## Reported whatever the number is. §3's last clause is explicit: if the cost
## is over about 1 ms/frame mean, say so — do not silently thin the trace to
## make the number look better, because the thinned trace is then what every
## later run produces and nobody knows why.
func _run_overhead_probe() -> void:
	var packed := load(WORLD_SCENE) as PackedScene
	if packed == null:
		_die("overhead probe could not load the world scene")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in int(_cfg["settle_frames"]):
		await physics_frame
	_probe.call("refresh_pois")
	_seed_change_detection()

	var seconds := float(_cfg["overhead_seconds"])
	var frames := int(seconds * float(Engine.physics_ticks_per_second))
	var with_on := await _idle_frame_ms(frames, true)
	var with_off := await _idle_frame_ms(frames, false)
	var delta := with_on - with_off
	var verdict := "within budget"
	if delta > 1.0:
		verdict = "OVER the ~1 ms/frame the protocol asks about; the trace was NOT thinned to hide it"
	_overhead_note = ("%.1f s idle at %s: telemetry+capture ON mean %.3f ms/frame, OFF mean %.3f ms/frame, "
		+ "delta %+.3f ms/frame (%s). Measured on this container's CPU only; no device fps, no VRAM.") % [
			seconds, str(_pos_array()), with_on, with_off, delta, verdict]
	print("gate-f overhead: %s" % _overhead_note)


func _idle_frame_ms(frames: int, telemetry: bool) -> float:
	var samples: Array[float] = []
	for i in frames:
		await physics_frame
		samples.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		if telemetry:
			_tick(1.0 / float(Engine.physics_ticks_per_second))
	if samples.is_empty():
		return 0.0
	var sum := 0.0
	for v: float in samples:
		sum += v
	return sum / float(samples.size())


# --- small helpers -----------------------------------------------------------

func _pos_array() -> Array:
	var player := _probe.call("player") as Node3D
	if player == null:
		return [0.0, 0.0, 0.0]
	var p := player.global_position
	return [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)]


func _note_line(line: String) -> void:
	_notes.append(line)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _write_json(path: String, data: Dictionary) -> void:
	_write_text(path, JSON.stringify(data, "  "))


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("gate-f harness: could not write %s" % path)
		return
	file.store_string(text)
	file.close()


## A harness error, as distinct from a failed expectation. Exits nonzero (§1.6);
## a game-side FAIL does not.
func _harness_error(message: String) -> void:
	_harness_errors.append(message)
	push_error("gate-f harness: %s" % message)
	print("gate-f harness ERROR: %s" % message)


func _die(message: String) -> void:
	_harness_error(message)
	_close_outputs()
	quit(1)
