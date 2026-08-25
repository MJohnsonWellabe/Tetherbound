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
	"record_default_hz": 0.1,
	"record_window_hz": 0.5,
	"record_forced_frames": true,
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

# --- continuous evidence recorder (§H) ---------------------------------------
#
# §H's substitute for full-run video: a PNG every N seconds plus a forced frame
# on every JSONL event, filed `frames/<segment>/<t>.png` and correlated back
# through `events.jsonl` and `route.csv` by timestamp.
#
# Kept in `frames/`, deliberately NOT in `shots/`. The §G plan is
# evidence-of-record -- every non-defect entry defined before play, none to be
# deleted or re-staged -- and mixing a thousand cadence frames into that
# manifest would bury the twenty frames somebody chose. Two directories, two
# manifests, one timestamp axis joining them.
#
# `_record_hz` is the LIVE rate; `_record_baseline_hz` is the segment's own,
# which `record_stop` returns to. §H sets the baseline at 0.1 Hz for journey
# segments and 0.5 Hz for the high-risk list, so a segment declares its
# baseline once at the top of its file and `record_start` raises it for a
# window rather than every step carrying a rate.
var _frames: Array = []
var _record_hz := 0.0
var _record_baseline_hz := 0.0
var _record_args: Dictionary = {}
var _record_next_t := 0.0
var _record_written := 0
var _record_absent := 0
## Event types that fired since the last recorder tick, and are owed a frame.
var _record_forced_by: Array[String] = []
## True while a `capture`/`capture_seq` STEP is executing. The recorder stands
## down for the length of it -- see `_recorder_tick`'s own note on why the
## prescribed shot wins a tie.
var _capture_step_active := false
var _notes: Array = []
var _harness_errors: Array[String] = []

# --- live counters -----------------------------------------------------------

var _probe: RefCounted = null
var _t0_usec := 0
var _boot_usec := 0
var _distance_m := 0.0
var _since_interaction_s := 0.0
var _dead_travel_m := 0.0
## The largest dead-travel run this segment has seen. Kept because the CURRENT
## value is almost always small -- a segment ends near something -- so it can
## only ever prove the meter resets, never that it accumulates. Both halves have
## to be checkable or "the meter works" is half a claim.
var _dead_travel_peak := 0.0
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
		elif arg.begins_with("--gatef-cfg="):
			# One-off override of a `harness_config.json` key, for a diagnostic
			# rerun that must not leave an edited config behind. Applied after
			# the file is read; the value is parsed as JSON so numbers stay
			# numbers ("--gatef-cfg=trace_hz=4.0").
			_cfg_overrides.append(arg.substr("--gatef-cfg=".length()))
	if _run_id.is_empty():
		_run_id = _out_dir.get_base_dir().get_file()
	if _run_id.is_empty():
		_run_id = "gate-f-run-unnamed"


var _cfg_overrides: Array[String] = []


func _load_config() -> void:
	var raw := _read_json(CONFIG_PATH)
	for key: String in _cfg.keys():
		if raw.has(key):
			_cfg[key] = raw[key]
	for override in _cfg_overrides:
		var parts := override.split("=", true, 1)
		if parts.size() != 2 or not _cfg.has(parts[0]):
			_harness_error("--gatef-cfg=%s names no harness_config key" % override)
			continue
		var parsed: Variant = JSON.parse_string(parts[1])
		_cfg[parts[0]] = parsed if parsed != null else parts[1]
		print("gate-f harness: config override %s = %s" % [parts[0], str(_cfg[parts[0]])])


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
	# §H files continuous frames under `frames/<segment>/`, so a run directory
	# holding several segments keeps them apart without the filename carrying
	# the segment twice.
	DirAccess.make_dir_recursive_absolute(abs_dir.path_join("frames").path_join(_segment_id))
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
	_write_json(_out_dir.path_join("frames/manifest.json"), {
		"segment": _segment_id,
		"baseline_hz": _record_baseline_hz,
		"written": _record_written,
		"absent": _record_absent,
		"frames": _frames,
	})
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
		"record_baseline_hz": _record_baseline_hz,
		"frames_written": _record_written,
		"frames_absent": _record_absent,
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
	# §H's baseline, declared once at the top of the segment file. 0.1 Hz for a
	# journey segment, 0.5 Hz for the mandatory high-risk list; `record_hz: 0`
	# turns the continuous record off for a segment that must not have it
	# (X08's perf audit, per §H's own last clause).
	_record_baseline_hz = float(segment.get("record_hz", _cfg["record_default_hz"]))
	_record_hz = _record_baseline_hz
	_record_args = {
		"hud": str(segment.get("record_hud", "on")),
		"camera_kind": str(segment.get("record_camera_kind", "gameplay")),
	}
	_record_next_t = 0.0
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
		"type_name":
			actual = await _step_type_name(args, id)
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
		"pin_clock":
			if not diag:
				verdict = "FAIL"
				actual = ("pin_clock refused: step is not marked \"diag\": true. Freezing the world "
					+ "clock is a diagnostic instrument, not something a player can do.")
			else:
				actual = await _step_pin_clock(args)
		"record_start":
			actual = _step_record_start(args)
		"record_stop":
			actual = _step_record_stop(args)
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
		"record_start", "record_stop", "pin_clock":
			return "note"
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
	# `times` rather than N identical steps. Five copies is how the save-handoff
	# self-check was first written and it hid the answer: one result line per
	# press, and no way to see which press did not land.
	var times := maxi(1, int(args.get("times", 1)))
	# Idle frames between repeats. Every menu-side reader in this game polls
	# `Input.is_action_just_pressed` from `_process` (`game_menu.gd::_process`),
	# and a tab switch rebuilds a whole tab body -- the map tab bakes a map -- so
	# back-to-back presses with only the injection's own frames between them can
	# arrive while the previous one is still being digested.
	var gap := maxi(0, int(args.get("settle_frames", 8)))
	# `device` names which BINDING to inject: "joypad", "key" or "mouse".
	# Omitted keeps the old preference order, so every script written before
	# this argument existed behaves identically.
	var device := str(args.get("device", ""))
	var raw := ""
	for i in times:
		var sent := await _inject(control, frames, device)
		if not bool(sent.get("ok", false)):
			if bool(sent.get("device_miss", false)):
				return str(sent.get("why", ""))
			return "HARNESS-ERROR %s" % str(sent.get("why", "injection failed"))
		raw = str(sent.get("raw", ""))
		for f in gap:
			await process_frame
	return "pressed %s x%d (%s, %d frames each) on %s, resolved to %s" % [control, times,
		str(args.get("hold", "tap")), frames,
		device if not device.is_empty() else "the default device", raw]


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
		# Floored well above `camera_rig.gd`'s own 0.18 stick deadzone. A pure
		# proportional push eases below the deadzone about 8 degrees out and
		# then pushes nothing at all: measured on the band 1 spine, a `face`
		# step asking for 138 degrees stalled at 124 and reported the camera as
		# unable to turn, when the harness had simply stopped asking it to.
		var push := clampf(absf(delta) / 45.0, 0.4, 1.0) * signf(-delta)
		_stick_right = Vector2(push, 0.0)
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


## Type a name into the live naming prompt on the pad's on-screen grid.
##
## Naming is mandatory (`docs/OPENING_SEQUENCE.md`) and it is the one beat the
## rest of this vocabulary cannot reach: `name_prompt.gd` in gamepad mode is a
## letter grid driven by `ui_*` and `menu_confirm`, so "press confirm until it
## goes away" types the same letter forever and never finds Done. Without this
## action the protocol's S01 could not be transcribed at all -- which is the
## test of a vocabulary, not a convenience.
##
## Still production input: every press below is a real physical event through
## the live InputMap, the same as every other step. What it reads from the panel
## is only WHERE THE CURSOR IS (`name_prompt.gd::entry()`'s row/column), because
## a blind walk of a grid whose layout it cannot see would be guessing. Nothing
## is written into the panel and `_confirm()` is never called directly.
##
## The grid walk is `tests/helpers/gate_a_opening_drive.gd::_select_name_cell`'s,
## reimplemented here rather than imported: that helper is a test fixture that
## reports through a test's own `_fail`, and the harness has to report through a
## step verdict instead. The cell-finding rule is the same one, and
## `name_entry.gd::ROWS` is the single source both read.
func _step_type_name(args: Dictionary, step_id: String) -> String:
	var wanted := str(args.get("name", ""))
	if wanted.is_empty():
		return "HARNESS-ERROR type_name step %s has no name" % step_id
	var owner := _probe.call("input_owner_node") as Node
	if owner == null or not owner.has_method("entry"):
		return "FAIL no naming prompt is open (input owner is '%s')" % (
			"nothing" if owner == null else str(owner.name))
	# The panel switches between keyboard and pad presentation on the last
	# device it saw. Every press this harness sends is a joypad event where one
	# exists, so it should already be in pad mode; if it is not, the grid is not
	# drawn and the walk below has nothing to walk.
	if not bool(owner.get("_using_gamepad")):
		return "FAIL the naming prompt is in keyboard mode; the pad grid is not drawn"
	var entry: Variant = owner.call("entry")
	var grid := load("res://scripts/ui/name_entry.gd") as GDScript
	if entry == null or grid == null:
		return "HARNESS-ERROR the naming prompt exposes no entry grid"
	for character in wanted:
		if not await _walk_to_name_cell(entry, grid, character):
			return "FAIL could not reach the '%s' cell in the naming grid" % character
		await _inject("menu_confirm", HOLD_TAP)
	var typed := str(owner.call("current_text"))
	if typed != wanted:
		return "FAIL typed '%s' on the pad grid, wanted '%s'" % [typed, wanted]
	if not await _walk_to_name_cell(entry, grid, grid.DONE):
		return "FAIL typed '%s' and could not reach the Done cell" % typed
	await _inject("menu_confirm", HOLD_TAP)
	var closed := await _settle_until(func() -> bool:
		return not bool(owner.call("is_open")), 180)
	if not closed:
		return "FAIL Done did not close the naming prompt after typing '%s'" % typed
	return "typed '%s' on the pad grid and confirmed Done" % typed


## Move the naming cursor onto `cell`, one d-pad tap at a time.
func _walk_to_name_cell(entry: Variant, grid: GDScript, cell: String) -> bool:
	var target := Vector2i(-1, -1)
	var rows: Array = grid.ROWS
	for row_index in rows.size():
		var row: Array = rows[row_index]
		for column_index in row.size():
			if str(row[column_index]) == cell:
				target = Vector2i(row_index, column_index)
	if target.x < 0:
		return false
	# Bounded rather than "until it arrives": a grid walk that could not reach
	# its cell would otherwise spin for the rest of the segment. The bounds are
	# a row/column count with slack, so overshooting wraps rather than hanging.
	for i in 16:
		if int(entry.get("row")) == target.x:
			break
		await _inject("ui_down", HOLD_TAP)
	for i in 20:
		if int(entry.get("column")) == target.y:
			break
		await _inject("ui_right", HOLD_TAP)
	return str(entry.call("selected")) == cell


# --- continuous evidence recorder (§H) ---------------------------------------

## Raise the background frame rate for a window. §H.
##
## The recorder is already running at the segment's baseline before this; what
## `record_start` does is raise the rate for the stretch that matters -- the
## opening, the tournament final, a band handoff plus or minus sixty seconds --
## and `record_stop` puts it back. That is why it is a rate change rather than
## an on switch: §H wants the record CONTINUOUS, with the mandatory list simply
## denser, and a recorder that only ran between explicit start/stop pairs would
## leave the rest of the segment with no frames at all.
##
## Unlike `capture_seq` this does not block. The frames are taken from inside
## the per-frame tick every other step already drives, so walking, fighting and
## menu navigation all keep happening while it records.
func _step_record_start(args: Dictionary) -> String:
	var hz := float(args.get("hz", _cfg["record_window_hz"]))
	if hz <= 0.0:
		return "FAIL record_start needs a positive hz (use record_stop to end a window)"
	_record_hz = hz
	_record_args = args.duplicate()
	# Due immediately, so a window that exists to catch a transition gets a
	# frame at its start rather than one interval later.
	_record_next_t = _t()
	var label := str(args.get("label", ""))
	_emit("note", {"observation": "record_start: background frames raised to %.2f Hz%s"
		% [hz, "" if label.is_empty() else " (%s)" % label]})
	return "recording at %.2f Hz%s (baseline %.2f Hz)" % [
		hz, "" if label.is_empty() else " for %s" % label, _record_baseline_hz]


## End a raised window.
##
## Returns to the segment's BASELINE rate by default, not to off: §H's record is
## continuous and a window ending is not the segment ending. `{"baseline": false}`
## stops the recorder outright, for the one case the protocol names -- X08's
## perf audit, which §H's own last clause says runs without capture.
func _step_record_stop(args: Dictionary) -> String:
	var to_baseline := bool(args.get("baseline", true))
	_record_hz = _record_baseline_hz if to_baseline else 0.0
	_record_args = {}
	_record_next_t = _t() + (1.0 / maxf(0.01, _record_hz)) if _record_hz > 0.0 else 0.0
	_emit("note", {"observation": "record_stop: background frames now %.2f Hz" % _record_hz})
	if _record_hz > 0.0:
		return "window ended; back to the segment baseline of %.2f Hz" % _record_hz
	return "recording stopped entirely (baseline:false)"


## One recorder tick. Called from `_tick`, so it runs at whatever rate the
## current step is advancing frames -- which is every frame of walking, waiting,
## fighting and menu navigation.
##
## **Deterministic against `capture`/`capture_seq`: the prescribed shot wins.**
## The recorder stands down for the whole of a capture step and its next frame
## is pushed forward past it. Two reasons, and the first is the one that
## matters: §G frames are evidence-of-record chosen before play, and a §H
## cadence frame landing on the same frame would put two files of the identical
## image into two manifests, which is how a reader ends up citing the wrong one.
## The second is mechanical -- both want the same framebuffer on the same frame,
## and letting them race would make which file exists depend on step ordering.
func _recorder_tick() -> void:
	if not _telemetry_on() or _capture_step_active:
		return
	var forced := not _record_forced_by.is_empty()
	var due := _record_hz > 0.0 and _t() >= _record_next_t
	if not (forced or due):
		return
	var trigger := "cadence"
	if forced:
		# Every event that fired since the last tick, named. Coalesced into ONE
		# frame on purpose: two events on the same frame describe the same
		# image, and writing it twice would inflate the record without adding
		# a pixel of evidence.
		trigger = "event:" + ",".join(_record_forced_by)
		_record_forced_by.clear()
	if due:
		_record_next_t = _t() + (1.0 / maxf(0.01, _record_hz))
	_write_frame(trigger)


## Ask for a frame on the next recorder tick, per §H's "forced frame on every
## JSONL event".
##
## Latency is at most one frame: an event emitted from inside `_tick` is
## recorded on the same tick, and one emitted from a step handler on the next
## frame that step advances. Under 17 ms at 60 Hz, and stated rather than
## claimed exact -- the correlation §H asks for is by TIMESTAMP through
## `events.jsonl`, and both records carry the same `t` axis.
func _force_frame(type: String) -> void:
	if not _telemetry_on() or not bool(_cfg["record_forced_frames"]):
		return
	if _record_hz <= 0.0 and _record_baseline_hz <= 0.0:
		return
	if not _record_forced_by.has(type):
		_record_forced_by.append(type)


## Write one continuous-evidence frame and its manifest row.
##
## Files as `frames/<segment>/<t>.png` per §H, with `t` zero-padded so the
## directory sorts in time order rather than lexically scrambling 9 s and 100 s.
func _write_frame(trigger: String) -> void:
	var t := _t()
	var clock: Dictionary = _probe.call("clock_weather")
	var row := {
		"t": snappedf(t, 0.01),
		"wall": Time.get_datetime_string_from_system(true, true),
		"segment": _segment_id,
		"trigger": trigger,
		"hz": _record_hz,
		"pos": _pos_array(),
		"camera_kind": str(_record_args.get("camera_kind", "gameplay")),
		"hud": str(_record_args.get("hud", "on")),
		"clock_hour": snappedf(float(clock.get("hour", 0.0)), 0.01),
		"weather": str(clock.get("weather", "")),
		"input_context": str(_probe.call("input_context")),
		"file": null,
	}
	if not _capture_available():
		# Same rule as `capture`: an absent frame is evidence (§C.4). The row is
		# still written so the cadence itself is auditable -- a headless run
		# proves the recorder fired at the right times even though it could not
		# draw anything.
		row["reason"] = "headless: this process has no display server and cannot render a frame"
		_frames.append(row)
		_record_absent += 1
		return
	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		row["reason"] = "viewport returned an empty image"
		_frames.append(row)
		_record_absent += 1
		return
	var rel := "frames/%s/%09.2f.png" % [_segment_id, t]
	var err := image.save_png(_out_dir.path_join(rel))
	if err != OK:
		row["reason"] = "save_png failed with error %d" % err
		_frames.append(row)
		_record_absent += 1
		return
	row["file"] = rel
	row["size"] = [image.get_width(), image.get_height()]
	_frames.append(row)
	_record_written += 1


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
	# The §H recorder stands down for the length of this step. See
	# `_recorder_tick`'s note: the prescribed shot wins the tie, deterministically.
	_capture_step_active = true
	for i in int(_cfg["capture_settle_frames"]):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		row["reason"] = "viewport returned an empty image"
		_manifest.append(row)
		_capture_step_active = false
		_emit("screenshot", {"artifacts": [shot_id], "observation": str(row["reason"])})
		return "FAIL capture %s produced no image" % shot_id
	var rel := "shots/%s.png" % shot_id
	var err := image.save_png(_out_dir.path_join(rel))
	if err != OK:
		row["reason"] = "save_png failed with error %d" % err
		_manifest.append(row)
		_capture_step_active = false
		return "FAIL capture %s could not be written (%d)" % [shot_id, err]
	row["file"] = rel
	row["size"] = [image.get_width(), image.get_height()]
	_manifest.append(row)
	_capture_step_active = false
	# Push the recorder's next cadence frame past this shot rather than letting
	# it fire on the very next tick with an identical image.
	if _record_hz > 0.0:
		_record_next_t = maxf(_record_next_t, _t() + (1.0 / maxf(0.01, _record_hz)))
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
	var device := str(args.get("device", ""))
	var before := _cell_snapshot()
	var sent := await _inject(control, HOLD_TAP, device)
	if not bool(sent.get("ok", false)):
		if bool(sent.get("device_miss", false)):
			# The cell is still reported -- "unreachable on this device" is a
			# real matrix answer, and an empty cell is not.
			_emit("input_probe", {"input": {"device": "synthetic", "device_kind": device,
					"action": control, "edge": "none"},
				"expected": str(args.get("expected", "")),
				"actual": str(sent.get("why", "")),
				"observation": "cell control=%s device=%s context=%s: no binding for that device"
					% [control, device, str(before.get("context"))]})
			return str(sent.get("why", ""))
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
				"actual": "dead_travel=%.1f m now, peak %.1f m this segment (ceiling %.1f)"
					% [_dead_travel_m, _dead_travel_peak, ceiling]}
		"dead_travel_peak_above":
			var floor_m := float(args.get("metres", 0.0))
			return {"ok": _dead_travel_peak >= floor_m,
				"actual": "dead_travel peaked at %.1f m this segment (wanted >= %.1f); %.1f m walked in total"
					% [_dead_travel_peak, floor_m, _distance_m]}
		"distance_above":
			var walked := float(args.get("metres", 0.0))
			return {"ok": _distance_m >= walked,
				"actual": "walked %.1f m this segment (wanted >= %.1f)" % [_distance_m, walked]}
		"mouse_captured":
			# §E.4's restoration checklist and §L.6-T01: the pause shell releases
			# the mouse on open and must RESTORE it on close. A menu that does
			# not give it back leaves the camera dead afterwards, which reads as
			# a camera bug rather than a menu one -- `smoke_menu.gd` exists
			# partly for this and had no verdict on the operator side.
			var want_captured := bool(args.get("equals", true))
			var mode := int((_probe.call("input_state") as Dictionary).get("mouse_mode", 0))
			var captured := mode == Input.MOUSE_MODE_CAPTURED
			return {"ok": captured == want_captured,
				"actual": "mouse_mode=%s (wanted %s)" % [
					_mouse_mode_name(mode), "captured" if want_captured else "not captured"]}
		"satiety":
			var vitals: Dictionary = _probe.call("player_vitals")
			if vitals.is_empty():
				return {"ok": false, "actual": "no live vitals to read satiety from"}
			return _compare("satiety", float(vitals.get("satiety", 0.0)), args)
		"clock_hour":
			# Tolerance, not equality: the day cycle is continuous and a load
			# restores an elapsed-seconds value, so the hour comes back close
			# rather than identical. Wraps across midnight -- 23.9 and 0.1 are
			# 0.2 apart, not 23.8.
			var have := float((_probe.call("clock_weather") as Dictionary).get("hour", 0.0))
			var want := float(args.get("equals", 0.0))
			var tolerance := float(args.get("tolerance", 0.5))
			var gap := absf(fmod(absf(have - want) + 12.0, 24.0) - 12.0)
			return {"ok": gap <= tolerance,
				"actual": "clock_hour=%.2f (wanted %.2f +/- %.2f, off by %.2f)"
					% [have, want, tolerance, gap]}
		"placed_buildings":
			# A load that silently dropped the player's structures would
			# otherwise read as PASS: X05 records the number and verdicts
			# nothing without this.
			var g := _probe.call("game") as Node
			if g == null:
				return {"ok": false, "actual": "no live Game to read placed_buildings from"}
			var raw: Variant = g.get("placed_buildings")
			var count := (raw as Array).size() if typeof(raw) == TYPE_ARRAY else -1
			return _compare("placed_buildings", float(count), args)
		"route_rows_at_least":
			var want := int(args.get("rows", 0))
			return {"ok": _trace_rows >= want,
				"actual": "route.csv has %d rows (wanted >= %d)" % [_trace_rows, want]}
		_:
			return {"ok": false, "actual": "unknown assert check '%s'" % check}


## A numeric check with a comparator, for the assert checks that need one.
##
## `equals` (with optional `tolerance`), `at_least`, `at_most`. Named rather
## than positional so a step reads as a sentence and a missing comparator is a
## visible mistake rather than a silent equality test against zero.
func _compare(label: String, have: float, args: Dictionary) -> Dictionary:
	if args.has("at_least"):
		var floor_v := float(args["at_least"])
		return {"ok": have >= floor_v, "actual": "%s=%.2f (wanted >= %.2f)" % [label, have, floor_v]}
	if args.has("at_most"):
		var ceil_v := float(args["at_most"])
		return {"ok": have <= ceil_v, "actual": "%s=%.2f (wanted <= %.2f)" % [label, have, ceil_v]}
	if args.has("equals"):
		var want := float(args["equals"])
		var tolerance := float(args.get("tolerance", 0.001))
		return {"ok": absf(have - want) <= tolerance,
			"actual": "%s=%.2f (wanted %.2f +/- %.2f)" % [label, have, want, tolerance]}
	return {"ok": false, "actual": "%s=%.2f but the check named no comparator (equals / at_least / at_most)"
		% [label, have]}


func _mouse_mode_name(mode: int) -> String:
	match mode:
		Input.MOUSE_MODE_VISIBLE:
			return "visible"
		Input.MOUSE_MODE_HIDDEN:
			return "hidden"
		Input.MOUSE_MODE_CAPTURED:
			return "captured"
		Input.MOUSE_MODE_CONFINED:
			return "confined"
		_:
			return "mode:%d" % mode


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


## Pin the world clock and weather, then FREEZE both. DIAG only (§E.7).
##
## §E.7's regional audit compares sites against each other, and it can only do
## that if the light is the same in every frame. The unpinned variant is not a
## hypothetical: the 2026-08-23 pass let `apply_time("day")` be undone by the
## day cycle's own `_process` during the settle between shots, and the run came
## back with a crimson artefact nobody could reproduce because the clock had
## moved underneath it.
##
## **The order is the whole instrument, and it is `capture_band3_region.gd`'s:
## pin AFTER the settle, then stop both clocks.** Pinning before the settle is
## the bug -- `world_look.gd::_process` re-blends every `BLEND_INTERVAL`, so a
## pin that precedes a 240-frame settle has been overwritten four seconds later.
## The caller settles first (a `boot` or `wait` step), this pins and freezes.
##
## `preset` takes a named keyframe from `art.json` (`day`, `golden`, `night`)
## through the game's own `apply_time()`. `hour` takes an arbitrary float and
## goes through `_apply_blended()`, which is the continuous path
## `world_look.gd::_process` itself uses -- not a second interpolation written
## here. Pass either or both; `hour` is applied last so it wins.
func _step_pin_clock(args: Dictionary) -> String:
	var look := _probe.call("world_look") as Node
	if look == null:
		return "HARNESS-ERROR pin_clock with no live WorldLook"
	var applied: Array[String] = []

	var weather_node := _probe.call("world_weather") as Node
	if args.has("weather"):
		if weather_node == null:
			return "HARNESS-ERROR pin_clock asked for weather with no live WorldWeather"
		weather_node.call("set_weather", str(args["weather"]))
		applied.append("weather=%s" % str(args["weather"]))

	if args.has("preset"):
		look.call("apply_time", str(args["preset"]))
		applied.append("preset=%s" % str(args["preset"]))

	if args.has("hour"):
		var cycle: Variant = look.get("_cycle")
		if cycle == null:
			return "HARNESS-ERROR WorldLook has no day cycle to pin an hour against"
		var hour := clampf(float(args["hour"]), 0.0, 24.0)
		look.set("_elapsed_seconds", float(cycle.call("elapsed_for_hour", hour)))
		look.call("_apply_blended", hour)
		applied.append("hour=%.2f" % hour)

	# Let the applied look reach the sun, sky and environment before the clocks
	# stop -- `_apply_sun`/`_apply_environment` write immediately, but a frame
	# here also lets anything watching them settle.
	for i in int(args.get("settle_frames", 4)):
		await physics_frame

	# Freeze. Both nodes, both process kinds: `world_look.gd` re-blends in
	# `_process` and `world_weather.gd` rolls its own preset on a timer, so
	# stopping one leaves the other free to move the light.
	var frozen: Array[String] = []
	if bool(args.get("freeze", true)):
		look.set_process(false)
		look.set_physics_process(false)
		frozen.append("WorldLook")
		if weather_node != null:
			weather_node.set_process(false)
			weather_node.set_physics_process(false)
			frozen.append("WorldWeather")

	var now: Dictionary = _probe.call("clock_weather")
	_emit("note", {"observation": "DIAG pin_clock: %s; froze %s" % [
		", ".join(applied) if not applied.is_empty() else "nothing", ", ".join(frozen)]})
	return "DIAG pinned %s and froze %s; clock now reads hour=%.2f preset=%s weather=%s" % [
		", ".join(applied) if not applied.is_empty() else "nothing",
		", ".join(frozen) if not frozen.is_empty() else "nothing",
		float(now.get("hour", 0.0)), str(now.get("preset", "")), str(now.get("weather", ""))]


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
func _inject(control: String, frames: int, device: String = "") -> Dictionary:
	var down := _edge(control, true, device)
	if not bool(down.get("ok", false)):
		return down
	# One IDLE frame with the control held, before any physics frame. Every menu
	# in this game polls `Input.is_action_just_pressed` from `_process`, which is
	# idle; a press that only ever spanned physics frames can be pressed and
	# released without a single `_process` seeing it down.
	await process_frame
	for i in maxi(1, frames):
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))
	var up := _edge(control, false, device)
	# And an idle frame on the release edge, for the readers that act on it.
	await process_frame
	await physics_frame
	_tick(1.0 / float(Engine.physics_ticks_per_second))
	# §C.1's `device` field is honest: no physical controller exists here, so it
	# says "synthetic". `device_kind` says which BINDING was injected, which is
	# the thing §L.1's parity row is actually about.
	_last_input = {"device": "synthetic", "device_kind": _kind_of(str(down.get("raw", ""))),
		"raw": str(down.get("raw", "")), "action": control, "edge": "press"}
	return {"ok": bool(up.get("ok", false)), "raw": str(down.get("raw", ""))}


## Which physical device a `raw` shorthand describes. Derived from the shorthand
## rather than passed down, so it always names what was actually injected --
## including on a default-device press where the segment named nothing.
func _kind_of(raw: String) -> String:
	if raw.begins_with("Joy"):
		return "joypad"
	if raw.begins_with("Key"):
		return "key"
	if raw.begins_with("Mouse"):
		return "mouse"
	return "unknown"


## One edge of one control: the physical event AND the paired action state.
##
## Both, always. See this file's header for the two measured failures that
## sending only one half causes. The physical event goes first because the
## viewport's focus walk happens on the event, and a poll set beforehand can
## make a same-frame reader see a press that has not physically arrived yet.
func _edge(control: String, pressed: bool, device: String = "") -> Dictionary:
	var action := StringName(control)
	if not InputMap.has_action(action):
		return {"ok": false, "why": "no input action '%s' in the live InputMap" % control}
	if not device.is_empty() and not device in ["joypad", "key", "mouse"]:
		return {"ok": false, "why": "unknown device '%s' (joypad, key or mouse)" % device}
	var binding := _physical_binding(action, device)
	if binding == null:
		if device.is_empty():
			return {"ok": false, "why": "action '%s' has no physical binding to inject" % control}
		# Named-device miss is a FINDING, not a harness error: it is precisely
		# the answer §L.1 wants for a verb the player cannot reach on that
		# device. Reported as FAIL so the run records it and continues.
		return {"ok": false, "device_miss": true,
			"why": "FAIL action '%s' has no %s binding -- that verb is unreachable on that device"
				% [control, device]}
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


## The physical event to synthesize for an action, optionally on a named device.
##
## With `device` empty the preference is joypad, then keyboard, then mouse. This
## ships controller-first on a handheld, so a pad binding is the one a segment
## is usually testing, and the keyboard fallback is what reaches the actions
## `input_contexts.json` records as keyboard-only (torch, the hammer, the tool
## swing) -- a harness that refused those could not reach half the world verbs.
##
## **`device` exists because that preference silently halved §L.1's KBM parity
## row.** Every dual-bound action -- W/A/S/D, E, I, M, Esc, Tab -- resolved to
## its pad binding, so the keyboard half was unreachable while the matrix cell
## read as covered. Only the five keyboard-or-mouse-exclusive actions ever
## reached the KBM path at all. Naming a device makes the other half reachable.
##
## An action with no binding for the REQUESTED device returns null and the
## caller records a FAIL. Deliberately not a fallback to another device: a
## silent fallback is exactly how this stayed invisible, and a KBM cell that
## quietly injected a pad event is worse evidence than an honest gap.
func _physical_binding(action: StringName, device: String = "") -> InputEvent:
	var by_kind := {"joypad": null, "key": null, "mouse": null}
	for event in InputMap.action_get_events(action):
		if (event is InputEventJoypadButton or event is InputEventJoypadMotion) \
				and by_kind["joypad"] == null:
			by_kind["joypad"] = event
		elif event is InputEventKey and by_kind["key"] == null:
			by_kind["key"] = event
		elif event is InputEventMouseButton and by_kind["mouse"] == null:
			by_kind["mouse"] = event
	if not device.is_empty():
		return by_kind.get(device) as InputEvent
	for kind in ["joypad", "key", "mouse"]:
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
	# §H: a forced frame on every JSONL event. Requested here rather than taken
	# here, because `_emit` is called from inside `_write_frame`'s own caller
	# chain in one case (`record_start`'s note) and a capture inside an emit
	# would reenter.
	_force_frame(type)
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
				_dead_travel_peak = maxf(_dead_travel_peak, _dead_travel_m)
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
	# Last, so an event raised by `_watch_for_events` above gets its forced
	# frame on THIS tick rather than the next one.
	_recorder_tick()


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
	_frame_ms.clear()

	# Half-length windows, run forwards then backwards: off, telemetry,
	# recording, recording, telemetry, off.
	#
	# The reversal is not decoration. The first version of this ran one window
	# per condition, ON then OFF, and came back at -0.607 ms/frame -- telemetry
	# apparently making the game FASTER, which is drift between two windows
	# landing wholly in the difference. Running each condition twice, on either
	# side of the turn, cancels any linear drift; the spread BETWEEN a
	# condition's two windows then measures the noise floor directly, so the
	# note can say whether a difference is real instead of asserting it.
	var half := maxf(5.0, float(_cfg["overhead_seconds"]) * 0.5)
	var frames := int(half * float(Engine.physics_ticks_per_second))
	var order := ["off", "telemetry", "recording", "recording", "telemetry", "off"]
	var runs := {"off": [], "telemetry": [], "recording": []}
	for condition: String in order:
		var mean := await _idle_frame_ms(frames, condition)
		(runs[condition] as Array).append(mean)

	var means := {}
	var spreads := {}
	for condition: String in runs.keys():
		var pair: Array = runs[condition]
		means[condition] = (float(pair[0]) + float(pair[1])) * 0.5
		spreads[condition] = absf(float(pair[0]) - float(pair[1]))
	# The noise floor is the widest disagreement any single condition had with
	# itself. A delta smaller than that is not a measurement.
	var noise := 0.0
	for condition: String in spreads.keys():
		noise = maxf(noise, float(spreads[condition]))

	var d_telemetry := float(means["telemetry"]) - float(means["off"])
	var d_recording := float(means["recording"]) - float(means["off"])
	_overhead_note = ("%.0f s x 2 windows per condition at %s, order off/telemetry/recording/recording/"
		+ "telemetry/off (reversed to cancel drift). Means: off %.3f, telemetry %.3f, "
		+ "telemetry+recording@%.2fHz %.3f ms/frame. Deltas vs off: telemetry %+.3f (%s), "
		+ "recording %+.3f (%s). Noise floor %.3f ms/frame, taken as the widest a single condition "
		+ "disagreed with itself. Display server %s, viewport %dx%d, frames written %d. "
		+ "CPU frame time on this container only -- no device fps, no VRAM.") % [
			half, str(_pos_array()),
			float(means["off"]), float(means["telemetry"]),
			float(_cfg["record_window_hz"]), float(means["recording"]),
			d_telemetry, _overhead_verdict(d_telemetry, noise),
			d_recording, _overhead_verdict(d_recording, noise),
			noise, DisplayServer.get_name(), _viewport_size().x, _viewport_size().y,
			_record_written]
	print("gate-f overhead: %s" % _overhead_note)


## How to read one delta, honestly.
##
## Three outcomes and they are genuinely different claims: over the protocol's
## ~1 ms/frame line (say so, and do NOT thin the trace to hide it -- §3's last
## clause); measurable and under it; or smaller than this measurement can
## separate from noise, which is not the same as zero and must not be written
## as zero.
func _overhead_verdict(delta: float, noise: float) -> String:
	if delta > 1.0:
		return "OVER the ~1 ms/frame the protocol asks about; the trace was NOT thinned to hide it"
	if absf(delta) <= noise:
		return "below the noise floor -- read as 'under ~%.2f ms/frame', not as zero" % maxf(noise, 0.01)
	if delta < 0.0:
		return "negative beyond the noise floor, which cannot be a real speed-up -- treat as unresolved"
	return "measurable and within budget"


## Mean CPU frame time over `frames`, under one of three conditions:
## `off` (no telemetry tick at all), `telemetry` (the 2 Hz trace and the event
## watch), `recording` (both, plus the §H frame recorder).
func _idle_frame_ms(frames: int, condition: String) -> float:
	var restore_hz := _record_hz
	_record_hz = float(_cfg["record_window_hz"]) if condition == "recording" else 0.0
	_record_next_t = _t()
	var samples: Array[float] = []
	for i in frames:
		await physics_frame
		samples.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		if condition != "off":
			_tick(1.0 / float(Engine.physics_ticks_per_second))
	_record_hz = restore_hz
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
