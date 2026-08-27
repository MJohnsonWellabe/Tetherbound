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
	"overhead_scene": "world",
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
## Milliseconds spent inside the readback + PNG encode, per frame written.
##
## Measured DIRECTLY because the frame-time difference cannot resolve it here:
## llvmpipe at 1920x1080 renders the title at ~70 ms/frame with a spread of
## ~8 ms between two identical 30 s windows, so a 1 ms/frame effect -- the line
## the protocol asks about -- sits eight times below the noise floor of a
## before/after comparison. Timing the grab itself is immune to that: it is the
## cost of the thing, not the difference between two noisy totals.
var _record_grab_ms: Array[float] = []
## The rate in effect when each of those frames was taken, kept alongside.
##
## Not read back from `_record_hz` at reporting time: the overhead probe restores
## the rate to zero between conditions, so a summary that asked afterwards
## divided by nothing and reported the amortised cost as 0.000 ms/frame -- a
## clean pass produced by a bookkeeping mistake, which is the exact shape of
## dishonest number this file is written to avoid.
var _record_grab_hz: Array[float] = []
## Event types that fired since the last recorder tick, and are owed a frame.
var _record_forced_by: Array[String] = []
## True while a `capture`/`capture_seq` STEP is executing. The recorder stands
## down for the length of it -- see `_recorder_tick`'s own note on why the
## prescribed shot wins a tie.
var _capture_step_active := false
var _notes: Array = []
var _harness_errors: Array[String] = []

# --- rig integrity (CD-1/CD-2/CD-3, GF-B-002/GF-B-003) -----------------------
#
# Three counters below exist because the 2026-08-27 run against `f082bdf6`
# reported PASS for 9,231 captures it never took and PASS for step after step
# pressed at a modal that owned input. Both failures share one shape: the
# harness had no way to say "I could not do that", so it said nothing and the
# reader read silence as success.

## Non-empty when the capture pre-flight refused to start the segment. Nothing
## after step 1 runs; the segment is BLOCKED and says so in `INVENTORY.json`.
var _blocked := ""
## Non-empty when a step's `require_context` did not hold. The segment is off
## its rails from that step onward: every following step is SKIPPED, with the
## derail named, until one whose `require_context` holds resynchronises it.
## §1.6 still stands -- a failed EXPECTATION continues -- but a step that could
## not be PERFORMED invalidates the ones after it, and forty assertions taken in
## the wrong context are forty findings about the harness.
var _derailed := ""
var _derailed_at := ""
## Every capture the segment DECLARED, resolved before the first step runs.
## `INVENTORY.json` is this list joined to what is on disk at the end.
var _planned_captures: Array = []
## Step bookkeeping, so `INVENTORY.json` can say how much of the segment ran.
var _step_total := 0
var _step_ran := 0
var _verdicts := {"PASS": 0, "FAIL": 0, "SKIP": 0}
## What the pre-flight found, verbatim, in `RUN_METADATA.json` and the inventory.
var _preflight: Dictionary = {}
## `--gatef-allow-no-capture`: an explicit, recorded acknowledgement that this
## invocation cannot capture. It does NOT make the segment complete -- the
## inventory still marks every planned shot absent and `complete: false` -- it
## only lets a developer run a capture-bearing segment for its logic while
## knowing the evidence half is void.
var _allow_no_capture := false

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

## GF-B-011. Thirteen of §C.1's twenty-nine event types had never been emitted
## by anything: `dialogue`, `combat_hit`, `combat_switch`, `catch_throw`,
## `gather`, `craft`, `build_place`, `build_cancel`, `build_dismantle`, `rest`,
## `feed`, `landmark_discover`, `defect`. A schema that cannot evidence itself
## is a schema nobody can trust the absence of: a Phase B reader querying
## `type == "gather"` and finding nothing could not tell "the player never
## gathered" from "the harness never says that word".
##
## Detected the same way every existing detector works -- by comparing live
## state to the last sample, with no hook anywhere inside gameplay code.
var _prev_dialogue_line := ""
var _prev_opponent_hp := -1.0
var _prev_my_hp := -1.0
var _prev_catch_phase := ""
var _prev_active_creature := ""
var _prev_inventory: Dictionary = {}
var _prev_placed := -1
var _prev_pending_build := ""
var _prev_condition: Dictionary = {}
var _prev_satiety := -1.0
var _prev_landmarks := -1
## The expensive half of the watch -- a 24-slot inventory walk, a landmark list,
## a per-member condition summary -- runs at 10 Hz rather than 60. §3 asks
## whether the instrumentation costs more than about 1 ms/frame, and three whole
## state walks on every physics frame is how an instrument starts measuring
## itself. 10 Hz is six times the fastest thing being watched: an inventory
## cannot change twice in 100 ms of play.
const SLOW_WATCH_EVERY := 6
var _slow_watch_tick := 0

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
		elif arg == "--gatef-allow-no-capture":
			# Recorded, never silent. See `_allow_no_capture`'s note.
			_allow_no_capture = true
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
	# §M's closing inventory, as code. Last, so it sees every manifest row and
	# every file the writes above put on disk.
	_write_inventory()


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
		"frame_grab_ms": _grab_summary(),
		"instrumentation_overhead_note": _overhead_note,
		"harness_errors": _harness_errors,
		"capture_preflight": _preflight,
		"blocked": _blocked,
		"derailed": _derailed,
		"derailed_at": _derailed_at,
		"planned_captures": _planned_captures.size(),
		"steps_total": _step_total,
		"steps_ran": _step_ran,
		"verdicts": _verdicts,
		# CD-8. The freeze record is supposed to carry graphics settings and did
		# not, which is how a full Gate F run happened with the procedural grass
		# field silently off. A run cannot amend a freeze record it did not
		# write, so it records what the build it is playing actually had on.
		"feature_flags": _feature_flags(),
	}


## CD-8: every `data/config/` file's boolean/enabled switches, read off disk at
## run time.
##
## §1.2 requires the freeze record to name "graphics settings" and
## `ralph/reports/gate-f-candidate/RUN_METADATA.json` names none. The
## consequence is on the record: the 2026-08-26 candidate ran the whole journey
## with the procedural grass field off and nothing in the run said so, because
## nothing in the run had ever been asked to look.
##
## Read-only, and deliberately NOT a list of flag names kept here -- a list in
## the harness is a list that goes stale against `data/config/`. Anything whose
## value is a bool, or whose key looks like a switch, is reported with the file
## it came from.
func _feature_flags() -> Dictionary:
	var out := {}
	var dir := DirAccess.open("res://data/config")
	if dir == null:
		return {"_error": "res://data/config is not readable from this process"}
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".json"):
			var parsed := _read_json("res://data/config/%s" % name)
			var flags := {}
			_collect_flags(parsed, "", flags)
			if not flags.is_empty():
				out[name] = flags
		name = dir.get_next()
	dir.list_dir_end()
	return out


## Walk a parsed config and keep the switches. Recurses two levels deeper than
## the top so a `{"grass": {"enabled": false}}` shape is not reported as "no
## flags in this file" -- which is the shape the grass field actually has.
func _collect_flags(node: Variant, prefix: String, out: Dictionary, depth: int = 0) -> void:
	if typeof(node) != TYPE_DICTIONARY or depth > 4:
		return
	for key: Variant in (node as Dictionary).keys():
		var k := str(key)
		if k.begins_with("_"):
			continue
		var value: Variant = (node as Dictionary)[key]
		var path := k if prefix.is_empty() else "%s.%s" % [prefix, k]
		if typeof(value) == TYPE_BOOL:
			out[path] = value
		elif typeof(value) == TYPE_DICTIONARY:
			_collect_flags(value, path, out, depth + 1)


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
	_step_total = steps.size()
	_planned_captures = _plan_captures(steps)
	# CD-1. Before step 1, not after step 40: a segment whose evidence cannot be
	# taken has to say so at the top, where the operator is still looking, and
	# the run has to stop rather than spend an hour producing `file: null`.
	if not await _preflight_capture():
		_release_everything()
		return
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


# --- capture pre-flight and the closing inventory (CD-1, CD-2, §M) -----------

## Every capture this segment DECLARES, resolved from the step list before a
## single step runs.
##
## `capture_seq` is expanded to the individual ids it will write (`<id>-000`…),
## because a sequence that produced three of twenty frames is a partial absence
## and a plan that counted it as one row could not show that.
func _plan_captures(steps: Array) -> Array:
	var out: Array = []
	for raw: Variant in steps:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var step := raw as Dictionary
		var action := str(step.get("action", ""))
		if action != "capture" and action != "capture_seq":
			continue
		var args: Dictionary = step.get("args", {}) as Dictionary
		var step_id := str(step.get("id", "?"))
		var base := str(args.get("id", step_id))
		if action == "capture":
			out.append({"id": base, "step": step_id, "action": action,
				"class": str(args.get("class", "context")),
				"intended_proof": str(args.get("intended_proof", ""))})
			continue
		var hz := maxf(1.0, float(args.get("hz", 5.0)))
		var seconds := maxf(0.2, float(args.get("seconds", 2.0)))
		for i in int(hz * seconds):
			out.append({"id": "%s-%03d" % [base, i], "step": step_id, "action": action,
				"class": str(args.get("class", "context")),
				"intended_proof": str(args.get("intended_proof", ""))})
	return out


## CD-1: can this process actually take the pictures the segment plans?
##
## The 2026-08-27 run answered that question 9,231 times, one `file: null` at a
## time, and reported PASS for every one of them. It had been launched without
## the §0.1 xvfb invocation; every capture step silently no-opped and the
## segments still read as executed. That is not evidence of absence -- it is a
## run that did not happen, wearing the shape of one that did.
##
## So this asks, once, at the top, and it asks three separate things because
## they fail separately:
##
##   1. Is there a display server at all? (`--headless` was passed, or xvfb was
##      not.) This is the failure that produced the 9,231.
##   2. Did `tools/capture_diag_minimal.gd` write its PNG beside this run?
##      `run_segment.sh` gates capture mode on it; a missing `capture_smoke.png`
##      means the segment was started by hand, around the gate.
##   3. Can THIS process, in THIS scene state, actually read back a frame and
##      encode it? A display server that exists and a viewport that returns an
##      empty image are different faults with the same symptom.
##
## A segment that plans no captures and runs no continuous record needs none of
## this and is let through -- the self-check `selfcheck_walk`/`selfcheck_save_handoff`
## are logic segments by design, and blocking them would be the "fixed a rig
## problem by making a test pass" move in reverse.
func _preflight_capture() -> bool:
	var plans_shots := not _planned_captures.is_empty()
	var plans_record := _record_baseline_hz > 0.0
	_preflight = {
		"planned_captures": _planned_captures.size(),
		"record_baseline_hz": _record_baseline_hz,
		"display_server": DisplayServer.get_name(),
		"capture_requested": _want_capture,
		"capture_available": _capture_available(),
		"allow_no_capture": _allow_no_capture,
	}
	if not (plans_shots or plans_record):
		_preflight["verdict"] = "not required"
		_preflight["why"] = "segment declares no captures and no continuous record"
		_note_line("### preflight — capture not required")
		_note_line("- %s" % str(_preflight["why"]))
		_note_line("")
		return true
	if not _telemetry_on():
		_preflight["verdict"] = "not required"
		_preflight["why"] = "telemetry off (no --gatef-out); nowhere to write a PNG and nothing claiming there was"
		return true

	var why := ""
	if not _capture_available():
		why = ("no display server: DisplayServer reports '%s'. This process cannot render, so all "
			+ "%d planned capture(s) and every continuous frame would be written as file:null while "
			+ "the steps reported PASS. Relaunch through tools/gate_f/run_segment.sh --capture "
			+ "(§0.1: xvfb-run WITHOUT --headless, --rendering-driver opengl3).") % [
				DisplayServer.get_name(), _planned_captures.size()]
	else:
		var smoke := _out_dir.path_join("capture_smoke.png")
		if not FileAccess.file_exists(smoke) or _file_bytes(smoke) <= 0:
			why = ("tools/capture_diag_minimal.gd left no capture_smoke.png in %s. run_segment.sh "
				+ "--capture writes one before it starts a segment, so its absence means this "
				+ "segment was launched around the §A.4 smoke gate.") % _out_dir
		else:
			_preflight["smoke_bytes"] = _file_bytes(smoke)
			var probe := await _preflight_png()
			_preflight["self_test"] = probe
			if not bool(probe.get("ok", false)):
				why = "this process has a display server but could not write its own PNG: %s" % str(probe.get("why", ""))

	if why.is_empty():
		_preflight["verdict"] = "PASS"
		_note_line("### preflight — capture available")
		_note_line("- display_server: %s, smoke %d bytes, self-test %s" % [
			DisplayServer.get_name(), int(_preflight.get("smoke_bytes", 0)),
			str((_preflight.get("self_test", {}) as Dictionary).get("file", ""))])
		_note_line("")
		_emit("note", {"observation": "capture pre-flight PASS: %d planned capture(s), display server %s"
			% [_planned_captures.size(), DisplayServer.get_name()]})
		return true

	if _allow_no_capture:
		# Explicitly acknowledged. Still not a run: the inventory marks every
		# planned shot absent and the segment incomplete, so this can only ever
		# buy a developer a fast logic pass, never an evidence claim.
		_preflight["verdict"] = "DEGRADED (--gatef-allow-no-capture)"
		_preflight["why"] = why
		_note_line("### preflight — DEGRADED, capture unavailable and acknowledged")
		_note_line("- %s" % why)
		_note_line("- this segment CANNOT be marked complete; INVENTORY.json says so.")
		_note_line("")
		_emit("note", {"severity_candidate": "BLOCKER",
			"observation": "capture pre-flight failed and was overridden with --gatef-allow-no-capture: %s" % why})
		return true

	_blocked = why
	_preflight["verdict"] = "BLOCKER"
	_preflight["why"] = why
	_note_line("### preflight — BLOCKER")
	_note_line("- %s" % why)
	_note_line("- no step of this segment was run.")
	_note_line("")
	_emit("defect", {"severity_candidate": "BLOCKER", "expected": "the segment can take its planned captures",
		"actual": why, "observation": "capture pre-flight BLOCKER; segment %s did not run" % _segment_id})
	_write_text(_out_dir.path_join("BLOCKER.md"),
		"# BLOCKER — %s did not run\n\n%s\n\nNo step of this segment executed. Per §A's blocker rule the\n"
		% [_segment_id, why]
		+ "evidence for this segment is absent, not negative: nothing here is a finding about the game.\n")
	_harness_error("capture pre-flight BLOCKER: %s" % why)
	return false


## Can this process read back a frame and encode it, here, now?
func _preflight_png() -> Dictionary:
	for i in maxi(2, int(_cfg["capture_settle_frames"])):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return {"ok": false, "why": "the viewport returned an empty image"}
	var rel := "shots/_preflight.png"
	var err := image.save_png(_out_dir.path_join(rel))
	if err != OK:
		return {"ok": false, "why": "save_png returned %d writing %s" % [err, rel]}
	var bytes := _file_bytes(_out_dir.path_join(rel))
	if bytes <= 0:
		return {"ok": false, "why": "%s was written but is %d bytes" % [rel, bytes]}
	return {"ok": true, "file": rel, "bytes": bytes,
		"size": [image.get_width(), image.get_height()]}


func _file_bytes(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return -1
	var n := int(f.get_length())
	f.close()
	return n


## CD-2 / §M as CODE. The protocol's closing inventory check -- "every planned
## artifact exists or carries a recorded reason it does not" -- was a sentence
## addressed to a human, and the human it was addressed to reported a complete
## run in which no prescribed screenshot existed anywhere.
##
## Written on every close, blocked runs included. Planned id -> file -> exists
## -> bytes, joined against what is actually on disk, plus the step ledger, so
## "this segment is complete" is a computed field rather than a claim.
func _write_inventory() -> void:
	var rows: Array = []
	var by_id := {}
	for row: Variant in _manifest:
		by_id[str((row as Dictionary).get("id", ""))] = row
	var present := 0
	var absent := 0
	for plan: Variant in _planned_captures:
		var entry: Dictionary = plan
		var out := {"id": str(entry.get("id", "")), "step": str(entry.get("step", "")),
			"action": str(entry.get("action", "")), "class": str(entry.get("class", "")),
			"intended_proof": str(entry.get("intended_proof", "")),
			"file": null, "exists": false, "bytes": 0, "reason": ""}
		var taken: Variant = by_id.get(out["id"])
		if taken == null:
			out["reason"] = ("the step that would have written it never ran"
				if not _blocked.is_empty() or not _derailed.is_empty()
				else "no manifest row: the capture step did not execute")
		else:
			var row: Dictionary = taken
			out["reason"] = str(row.get("reason", ""))
			if row.get("file") != null:
				out["file"] = str(row["file"])
				var bytes := _file_bytes(_out_dir.path_join(str(row["file"])))
				out["bytes"] = bytes
				# On disk or it did not happen. A manifest row naming a file
				# that is not there is exactly the claim CD-2 found.
				out["exists"] = bytes > 0
				if not out["exists"]:
					out["reason"] = "manifest names %s and it is %d bytes on disk" % [str(row["file"]), bytes]
		if bool(out["exists"]):
			present += 1
		else:
			absent += 1
		rows.append(out)
	var frames_absent_reasons := {}
	for f: Variant in _frames:
		var frame: Dictionary = f
		if frame.get("file") == null:
			var reason := str(frame.get("reason", "unrecorded"))
			frames_absent_reasons[reason] = int(frames_absent_reasons.get(reason, 0)) + 1
	var complete := _blocked.is_empty() \
		and absent == 0 \
		and _derailed.is_empty() \
		and _harness_errors.is_empty() \
		and _record_absent == 0 \
		and _step_ran == _step_total
	var inventory := {
		"segment": _segment_id,
		"run_id": _run_id,
		"sha": _sha,
		"complete": complete,
		"blocked": _blocked,
		"derailed": _derailed,
		"derailed_at": _derailed_at,
		"preflight": _preflight,
		"captures": {"planned": _planned_captures.size(), "present": present, "absent": absent,
			"rows": rows},
		"frames": {"baseline_hz": _record_baseline_hz, "written": _record_written,
			"absent": _record_absent, "absent_reasons": frames_absent_reasons},
		"steps": {"total": _step_total, "ran": _step_ran,
			"pass": int(_verdicts["PASS"]), "fail": int(_verdicts["FAIL"]),
			"skipped": int(_verdicts["SKIP"])},
		"harness_errors": _harness_errors,
	}
	_write_json(_out_dir.path_join("INVENTORY.json"), inventory)
	if complete:
		return
	# A second, unmissable marker. A reader scanning a run directory sees the
	# filename before they open anything.
	var lines: Array[String] = ["# %s is INCOMPLETE" % _segment_id, ""]
	if not _blocked.is_empty():
		lines.append("- BLOCKED before step 1: %s" % _blocked)
	if not _derailed.is_empty():
		lines.append("- DERAILED at step %s: %s" % [_derailed_at, _derailed])
	if absent > 0:
		lines.append("- %d of %d planned captures are absent from disk." % [absent, _planned_captures.size()])
	if _record_absent > 0:
		lines.append("- %d continuous frames were planned and not written: %s"
			% [_record_absent, JSON.stringify(frames_absent_reasons)])
	if _step_ran != _step_total:
		lines.append("- %d of %d steps ran." % [_step_ran, _step_total])
	if not _harness_errors.is_empty():
		lines.append("- harness errors: %s" % JSON.stringify(_harness_errors))
	lines.append("")
	lines.append("See INVENTORY.json for the per-capture ledger.")
	_write_text(_out_dir.path_join("INCOMPLETE.md"), "\n".join(lines))


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

	# GF-B-002, primitive 1: assert-context-before-proceeding.
	#
	# A step declares the input context it expects to be acting in. The check
	# happens BEFORE the action, because the failure this exists for is a world
	# control pressed at a modal: by the time the assertion 40 steps later
	# notices, the run has recorded 40 findings about a game that was never in
	# the state the script assumed. Phase B's reading of the f082bdf6 run is
	# that this one primitive accounts for most of the "input ownership never
	# handed back" findings -- they are the harness's own presses, not the
	# game's failure to yield.
	var guard := _context_guard(step)
	if not str(guard.get("skip", "")).is_empty():
		_verdicts["SKIP"] = int(_verdicts["SKIP"]) + 1
		_emit("note", {"expected": expected, "actual": str(guard["skip"]),
			"observation": "SKIPPED: %s" % str(guard["skip"])})
		_note_line("### %s — %s" % [id, str(step.get("title", action))])
		_note_line("- expected: %s" % expected)
		_note_line("- actual: %s" % str(guard["skip"]))
		_note_line("- verdict: SKIP")
		_note_line("")
		return
	if not str(guard.get("fail", "")).is_empty():
		_verdicts["FAIL"] = int(_verdicts["FAIL"]) + 1
		_step_ran += 1
		_emit("defect", {"expected": expected, "actual": str(guard["fail"]),
			"severity_candidate": step.get("severity_candidate", "SHIP"),
			"observation": "require_context failed at step %s; the segment is off its rails from here" % id})
		_note_line("### %s — %s" % [id, str(step.get("title", action))])
		_note_line("- expected: %s" % expected)
		_note_line("- actual: %s" % str(guard["fail"]))
		_note_line("- verdict: FAIL (context guard; the step did not run)")
		_note_line("")
		return
	_step_ran += 1

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
		"move_to_entity":
			actual = await _step_move_to_entity(args)
		"face":
			actual = await _step_face(args)
		"open_menu":
			actual = await _step_open_menu(args, id)
		"close_menu":
			actual = await _step_close_menu(args, id)
		"focus_move":
			actual = await _step_focus_move(args, id)
		"advance_dialogue_until_closed":
			actual = await _step_advance_dialogue(args, id)
		"assert_context":
			actual = _step_context_check(args, id)
		"defect":
			actual = _step_defect(args, id)
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
	if actual.begins_with("BLOCKER"):
		# A step that could not drive the game at all. Distinct from a FAIL,
		# which is a verdict about the GAME: this one says the instrument could
		# not take a reading, and everything after it is taken in an unknown
		# state.
		verdict = "FAIL"
		_derailed = actual
		_derailed_at = id
	_verdicts[verdict] = int(_verdicts.get(verdict, 0)) + 1

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
	# GF-B-011: `defect` is in §C.1's enum and had never once been emitted, so
	# the schema could not evidence its own most important type. A FAILED step
	# carrying a severity candidate IS a candidate defect; saying so in the
	# stream means Phase B can select defects by type instead of re-deriving
	# them from prose in `actual`.
	if verdict == "FAIL":
		_emit("defect", {
			"expected": expected,
			"actual": actual,
			"observation": "step %s (%s) failed" % [id, action],
			"severity_candidate": step.get("severity_candidate", "SHIP"),
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
		"advance_dialogue_until_closed":
			return "dialogue"
		"defect":
			return "defect"
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


# --- context guard (GF-B-002 primitive 1) ------------------------------------

## Does this step's declared context hold, and is the segment still on rails?
##
## Returns `{}` to proceed, `{"fail": why}` for a step that must not run because
## the game is not where the script thinks it is, `{"skip": why}` for a step
## being skipped because an earlier one derailed.
##
## ## Why a derail SKIPS rather than continuing
##
## §1.6 is explicit that a failed EXPECTATION does not stop a segment -- a
## segment that stops at the first defect finds one defect. That rule is about
## verdicts on the GAME. A step whose required context does not hold is a
## different animal: it is a statement that the instrument is pointed at the
## wrong thing. Running the next forty steps anyway is how the f082bdf6 run
## produced 118 X01 failures that Phase B then had to refute from the run's own
## data. So the derail is recorded once, loudly, at the step that could not
## drive the game, and everything after it is SKIPPED with that reason attached
## -- absent evidence, honestly labelled, instead of forty fabricated findings.
##
## ## Resynchronising
##
## A segment recovers the moment a step's own `require_context` holds again,
## which is the natural shape of the scripts: X01 walks the matrix
## context-by-context and each block opens with the context it is about. A
## `boot` starts a fresh scene and always resyncs. `"resync": true` is the
## explicit escape for a step that re-establishes state some other way.
func _context_guard(step: Dictionary) -> Dictionary:
	var id := str(step.get("id", "?"))
	var action := str(step.get("action", ""))
	var required: Variant = step.get("require_context", null)
	var have := str(_probe.call("input_context"))
	var holds := required == null or _context_matches(have, required)

	if not _derailed.is_empty():
		if action == "boot" or bool(step.get("resync", false)) or (required != null and holds):
			_note_line("- resync at %s: input_context is %s; the segment is back on rails "
				% [id, have] + "(derailed at %s)" % _derailed_at)
			_emit("note", {"observation": "resync at step %s: input_context=%s (derailed at %s)"
				% [id, have, _derailed_at]})
			_derailed = ""
			_derailed_at = ""
		else:
			return {"skip": "SKIPPED: the segment derailed at step %s (%s) and this step declares no "
				% [_derailed_at, _derailed]
				+ "resync point. input_context is '%s' now." % have}

	if required == null or holds:
		return {}
	_derailed = "required context %s, input_context was '%s'" % [JSON.stringify(required), have]
	_derailed_at = id
	var state: Dictionary = _probe.call("input_state")
	return {"fail": ("BLOCKER step %s (%s) requires context %s and input is owned by '%s' "
		+ "(owner=%s, focus=%s, tree_paused=%s). The step did NOT run: acting here would have "
		+ "pressed a world control at whatever holds input, and recorded the result as a defect "
		+ "in the game.") % [id, action, JSON.stringify(required), have,
			str(state.get("owner", "")), str(state.get("focus_text", "")),
			str(state.get("tree_paused", false))]}


## Does `have` satisfy `want`?
##
## `want` is a string or a list of them. A trailing `*` is a prefix match, which
## is how `menu*` covers every tab of the pause shell without naming all seven,
## and a leading `!` negates -- `"!narrative_modal"` is "anything but a modal",
## which is what most world-verb steps actually mean.
func _context_matches(have: String, want: Variant) -> bool:
	if typeof(want) == TYPE_ARRAY:
		for entry: Variant in (want as Array):
			if _context_matches(have, entry):
				return true
		return false
	var pattern := str(want)
	if pattern.begins_with("!"):
		return not _context_matches(have, pattern.substr(1))
	if pattern.ends_with("*"):
		return have.begins_with(pattern.trim_suffix("*"))
	return have == pattern


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
	var at: Array = args.get("at", []) as Array
	if at.size() < 2:
		return "HARNESS-ERROR move_to needs at:[x,z]"
	var here := Vector2(float(at[0]), float(at[1]))
	# A fixed place: the target callable answers the same thing every time it is
	# asked. `move_to_entity` hands the same loop a moving answer.
	return await _walk_loop(args,
		func() -> Dictionary: return {"ok": true, "at": here,
			"what": "(%.0f, %.0f)" % [here.x, here.y]})


## GF-B-002, primitive 3: walk to a THING, not to a pair of numbers.
##
## Every journey step in the protocol is written as "go to the trainer", "reach
## the gathering node", "approach the pylon" -- and every one of them was
## transcribed as a coordinate, because a coordinate was all the vocabulary
## had. Two failure modes follow from that, and both are in the f082bdf6 run:
##
##   * The thing moves. A wild creature, a trainer on a patrol, a villager --
##     the coordinate was where it stood when the segment was written, and the
##     walk arrives at empty grass and reports the world as broken.
##   * The thing is not there at all. A coordinate walk cannot tell "I arrived
##     and nothing was here" from "I arrived"; it reports success either way,
##     and the missing entity is found forty steps later as an interaction that
##     did nothing.
##
## Resolved by identity and re-read every frame, so the walk tracks. Arriving is
## `within` metres of where the entity IS, and an entity that cannot be found is
## a FAIL that names the search -- an honest "not in the world" is a finding.
func _step_move_to_entity(args: Dictionary) -> String:
	var spec := str(args.get("entity", ""))
	if spec.is_empty():
		return "HARNESS-ERROR move_to_entity needs entity:\"<name|group|label|species>\""
	var found := _find_entity(spec, args)
	if not bool(found.get("ok", false)):
		return "FAIL %s" % str(found.get("why", ""))
	var node: Node3D = found["node"]
	var what := "%s (%s)" % [spec, str(found.get("how", ""))]
	# `within` rather than `close_enough`: an entity has a body, and the
	# interaction range the game uses is about reaching it, not about standing
	# on its origin.
	var within := float(args.get("within", 2.5))
	var walk := args.duplicate()
	walk["close_enough"] = within
	return await _walk_loop(walk, func() -> Dictionary:
		if node == null or not is_instance_valid(node) or not node.is_inside_tree():
			return {"ok": false, "why": "%s left the tree mid-walk" % what}
		return {"ok": true, "at": Vector2(node.global_position.x, node.global_position.z),
			"what": what})


## Find one live entity by identity.
##
## In order: exact node name, membership of a group of that name, a `label()`
## that matches, a `species_id` that matches, then a unique case-insensitive
## substring of a node name. Ambiguity is a FAIL naming the candidates -- a
## walk that silently picked the first of four Grazers is a walk whose evidence
## nobody can check.
func _find_entity(spec: String, args: Dictionary) -> Dictionary:
	var scene := _probe.call("world") as Node
	if scene == null:
		return {"ok": false, "why": "no live scene to search for '%s'" % spec}
	var all: Array[Node3D] = []
	_collect_node3ds(scene, all)
	var by_name: Array[Node3D] = []
	var by_group: Array[Node3D] = []
	var by_label: Array[Node3D] = []
	var by_species: Array[Node3D] = []
	var by_substring: Array[Node3D] = []
	var lowered := spec.to_lower()
	for node in all:
		if str(node.name) == spec:
			by_name.append(node)
		if node.is_in_group(StringName(spec)):
			by_group.append(node)
		if node.has_method("label") and str(node.call("label")).to_lower() == lowered:
			by_label.append(node)
		var species: Variant = node.get("species_id")
		if species != null and str(species).to_lower() == lowered:
			by_species.append(node)
		if str(node.name).to_lower().contains(lowered):
			by_substring.append(node)
	for pair: Array in [[by_name, "node name"], [by_group, "group"], [by_label, "label()"],
			[by_species, "species_id"], [by_substring, "name substring"]]:
		var hits: Array[Node3D] = pair[0]
		if hits.is_empty():
			continue
		if hits.size() > 1 and not bool(args.get("nearest", true)):
			return {"ok": false, "why": "'%s' matched %d nodes by %s (%s) and nearest:false was set"
				% [spec, hits.size(), str(pair[1]), _names_of(hits)]}
		if hits.size() == 1:
			return {"ok": true, "node": hits[0], "how": str(pair[1])}
		# `nearest` (the default) picks the closest to the player and SAYS it
		# did, with the count -- so a segment that meant a specific one can see
		# from the note that it was ambiguous.
		var player := _probe.call("player") as Node3D
		var best: Node3D = hits[0]
		if player != null:
			var best_d := INF
			for node in hits:
				var d := player.global_position.distance_to(node.global_position)
				if d < best_d:
					best_d = d
					best = node
		return {"ok": true, "node": best,
			"how": "%s, nearest of %d (%s)" % [str(pair[1]), hits.size(), _names_of(hits)]}
	return {"ok": false, "why": "no node named, grouped, labelled or speciesed '%s' among the %d Node3Ds in %s"
		% [spec, all.size(), scene.name]}


func _collect_node3ds(node: Node, out: Array[Node3D]) -> void:
	for child in node.get_children():
		if child is Node3D:
			out.append(child as Node3D)
		_collect_node3ds(child, out)


func _names_of(nodes: Array[Node3D]) -> String:
	var out: Array[String] = []
	for node in nodes:
		out.append(str(node.name))
		if out.size() >= 6:
			out.append("...")
			break
	return ", ".join(out)


## The shared walk. `target_fn` is re-asked EVERY frame, which is what lets one
## loop serve a fixed coordinate and a moving entity.
##
## Walked, never teleported. `tests/helpers/stick_navigator.gd` is the repo's
## one walker that can get around geometry, and it exists because every
## straight-line walk in this project failed on the same village wall. Reused
## rather than copied: a second copy of it is one that stops being fixed.
func _walk_loop(args: Dictionary, target_fn: Callable) -> String:
	var player := _probe.call("player") as Node3D
	var rig := _probe.call("camera_rig") as Node3D
	if player == null or rig == null:
		return "HARNESS-ERROR walk with no live Player/CameraRig"
	var world: Node = _probe.call("world") as Node
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
	var what := "?"
	var target := player.global_position
	nav.call("reset")
	while walked < budget:
		var aim: Dictionary = target_fn.call()
		if not bool(aim.get("ok", false)):
			_stick_left = Vector2.ZERO
			_drive_sticks()
			return "FAIL %s" % str(aim.get("why", "the walk lost its target"))
		var flat: Vector2 = aim["at"]
		what = str(aim.get("what", "?"))
		target = Vector3(flat.x, player.global_position.y, flat.y)
		if world != null and world.has_method("ground_height_at"):
			target.y = float(world.call("ground_height_at", target.x, target.z))
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
				#
				# This alternation is a WALK's fallback, not the dialogue
				# primitive: a step that means to answer a conversation uses
				# `advance_dialogue_until_closed`, which reads the panel instead
				# of guessing at it (CD-3).
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
		return "walked %.1f m to %s in %d walking frames (%d held)" % [
			started.distance_to(player.global_position), what, walked, held]
	if held > held_budget:
		return ("FAIL locomotion never came back: held %d frames by input_context '%s' while %.1f m "
			+ "short of %s at %s") % [held, held_by, gap, what,
				str(player.global_position.round())]
	return "FAIL did not reach %s in %d walking frames; stopped %.1f m short at %s (%d held)" % [
		what, budget, gap, str(player.global_position.round()), held]


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


# --- dialogue (GF-B-002 primitive 2 / CD-3) ----------------------------------

## Advance a narrative modal until it is CLOSED, by predicate.
##
## CD-3: every segment in the f082bdf6 run advanced dialogue with a guessed
## fixed press count, and a guess is wrong in both directions. Under-press and
## the modal is still open when the next step presses a world control at it --
## which is most of the "input ownership never handed back" family. Over-press
## and the extra `interact` lands on the interaction arbiter the frame after the
## panel closed, re-opening the very conversation the previous press ended, and
## the step after that finds a modal it was told had gone.
##
## Neither failure is possible against a predicate. This presses, then WAITS for
## the panel to say it either moved to a new line or closed, and it never
## presses again once closed. A panel that stops responding is a FAIL naming the
## line it stuck on, which is a finding about the game rather than a mystery
## forty steps downstream.
##
## ## Which button
##
## Read off the panel, not guessed. `dialogue_panel.gd` advances on `interact`
## from `_physics_process`; `starter_picker.gd` polls `menu_confirm`;
## `name_prompt.gd` is a letter grid and is not advanceable at all -- that one
## is `type_name`, and this step says so rather than mashing confirm through it.
func _step_advance_dialogue(args: Dictionary, step_id: String) -> String:
	var max_presses := int(args.get("max_presses", 60))
	var settle := int(args.get("settle_frames", 90))
	var allow_chain := bool(args.get("chain", true))
	var owner := _probe.call("input_owner_node") as Node
	var context := str(_probe.call("input_context"))
	if owner == null or not _is_open(owner):
		return ("BLOCKER advance_dialogue_until_closed at step %s: no narrative modal is open. "
			+ "input_context is '%s' and the input owner is %s. Advancing nothing would have "
			+ "sent %s into the world.") % [step_id, context,
				"nothing" if owner == null else "'%s'" % str(owner.name),
				str(args.get("control", "the advance button"))]
	var kind := _panel_kind(owner)
	if kind == "name_prompt":
		return ("FAIL the open modal is the naming prompt, which is a letter grid and does not "
			+ "advance -- use the `type_name` action. Pressing confirm here types one letter "
			+ "per press and never finds Done.")
	if kind == "unknown":
		return ("FAIL '%s' owns input and this harness does not know how to advance it. "
			+ "Add it to `_panel_kind` rather than guessing at a button.") % str(owner.name)
	var control := str(args.get("control", "interact" if kind == "dialogue" else "menu_confirm"))

	var lines: Array[String] = []
	var presses := 0
	var conversations := 1
	var first := _line_signature(owner, kind)
	if not first.is_empty():
		lines.append(first)
		_emit("dialogue", {"observation": first,
			"actual": "line 1 of the conversation %s opened" % str(owner.name)})
	while presses < max_presses:
		if not _is_open(owner):
			break
		var before := _line_signature(owner, kind)
		var sent := await _inject(control, HOLD_TAP)
		if not bool(sent.get("ok", false)):
			return "HARNESS-ERROR %s" % str(sent.get("why", ""))
		presses += 1
		var moved := await _settle_until(func() -> bool:
			return not _is_open(owner) or _line_signature(owner, kind) != before, settle)
		if not _is_open(owner):
			break
		if not moved:
			return ("FAIL the modal did not respond to press %d of %s: still on \"%s\" after %d "
				+ "frames. It is still open and still owns input (context '%s').") % [
					presses, control, before, settle, str(_probe.call("input_context"))]
		var now := _line_signature(owner, kind)
		lines.append(now)
		_emit("dialogue", {"observation": now,
			"actual": "advanced to line %d with %s" % [lines.size(), control]})

	if _is_open(owner):
		return ("FAIL %s was still open after %d presses of %s (the budget). Last line: \"%s\". "
			+ "input_context is '%s'.") % [str(owner.name), presses, control,
				lines[-1] if not lines.is_empty() else "?", str(_probe.call("input_context"))]

	# Closed. Now prove it STAYED closed, and find out whether something else
	# took input in its place -- a conversation that hands straight to the
	# starter picker is real game behaviour and belongs in the record; the same
	# panel re-opening is the over-press signature and is not.
	for i in maxi(4, int(args.get("close_settle_frames", 30))):
		await process_frame
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))
	var after_owner := _probe.call("input_owner_node") as Node
	var after_context := str(_probe.call("input_context"))
	if after_owner == owner and _is_open(owner):
		return ("FAIL %s closed and RE-OPENED within %d frames of the last press -- the advance "
			+ "button reached the interaction that starts the conversation. %d presses, %d lines.")\
				% [str(owner.name), int(args.get("close_settle_frames", 30)), presses, lines.size()]
	if after_owner != null and _is_open(after_owner):
		var next_kind := _panel_kind(after_owner)
		if not allow_chain:
			return ("FAIL %s closed after %d lines and '%s' took input immediately (chain:false). "
				+ "context '%s'.") % [str(owner.name), lines.size(), str(after_owner.name), after_context]
		conversations += 1
		_emit("dialogue", {"observation": "handover: %s closed and %s (%s) took input"
			% [str(owner.name), str(after_owner.name), next_kind]})
		return ("advanced %d line(s) over %d press(es); %s closed and handed straight to '%s' "
			+ "(%s, context '%s') -- a chained modal, not a failure to close") % [
				lines.size(), presses, str(owner.name), str(after_owner.name), next_kind, after_context]
	return "advanced %d line(s) over %d press(es) of %s; %s closed, context '%s' -> '%s'" % [
		lines.size(), presses, control, str(owner.name), context, after_context]


## Which advanceable panel is this?
func _panel_kind(node: Node) -> String:
	if node == null or node.get_script() == null:
		return "unknown"
	var path := str(node.get_script().resource_path)
	if path.ends_with("dialogue_panel.gd"):
		return "dialogue"
	if path.ends_with("starter_picker.gd"):
		return "starter_picker"
	if path.ends_with("name_prompt.gd"):
		return "name_prompt"
	return "unknown"


func _is_open(node: Node) -> bool:
	if node == null or not is_instance_valid(node) or not node.is_inside_tree():
		return false
	if not node.has_method("is_open"):
		return false
	return bool(node.call("is_open"))


## What the panel is showing, as one comparable string.
##
## The PREDICATE this whole step turns on. Read from the panel's own state --
## `dialogue_runner.gd::line()` for a conversation, the highlighted index for
## the starter picker -- never from a frame counter, because a frame counter is
## the guess this replaces.
func _line_signature(node: Node, kind: String) -> String:
	if not _is_open(node):
		return ""
	if kind == "dialogue" and node.has_method("runner"):
		var runner: Variant = node.call("runner")
		if runner == null or not runner.has_method("line"):
			return ""
		var line: Dictionary = runner.call("line")
		if line.is_empty():
			return ""
		return "%s: %s" % [str(line.get("speaker", "")), str(line.get("text", ""))]
	if kind == "starter_picker":
		var index: Variant = node.get("_index")
		var species: Variant = node.get("_species")
		var name := ""
		if typeof(species) == TYPE_ARRAY and index != null \
				and int(index) >= 0 and int(index) < (species as Array).size():
			name = str((species as Array)[int(index)])
		return "starter_picker[%s] %s" % [str(index), name]
	return ""


# --- explicit context assertion ----------------------------------------------

## `require_context` as a step of its own, for a checkpoint between blocks.
##
## Same predicate, same derail. The difference is intent: `require_context` on a
## step says "do not do this here", and `assert_context` says "the previous
## block was supposed to leave the game here, and if it did not, stop believing
## the rest of this segment".
func _step_context_check(args: Dictionary, step_id: String) -> String:
	var want: Variant = args.get("is", args.get("one_of", args.get("prefix", null)))
	if want == null:
		return "HARNESS-ERROR assert_context step %s names no is/one_of/prefix" % step_id
	if args.has("prefix"):
		want = "%s*" % str(args["prefix"])
	var have := str(_probe.call("input_context"))
	var state: Dictionary = _probe.call("input_state")
	if _context_matches(have, want):
		return "input_context is '%s', which satisfies %s (owner=%s, focus='%s')" % [
			have, JSON.stringify(want), str(state.get("owner", "")), str(state.get("focus_text", ""))]
	_derailed = "assert_context wanted %s, input_context was '%s'" % [JSON.stringify(want), have]
	_derailed_at = step_id
	return ("BLOCKER input_context is '%s', not %s. owner=%s focus='%s' tree_paused=%s "
		+ "pending_build='%s'. Every step after this one is skipped until a step resynchronises.") % [
			have, JSON.stringify(want), str(state.get("owner", "")), str(state.get("focus_text", "")),
			str(state.get("tree_paused", false)), str(state.get("pending_build", ""))]


## An operator-recorded defect, as a first-class event.
##
## GF-B-011: `defect` is in §C.1's enum and was never emitted by anything, so a
## reader could not select defects out of `events.jsonl` -- they had to be
## re-derived from prose. A step that finds one now says so in the stream.
func _step_defect(args: Dictionary, step_id: String) -> String:
	var what := str(args.get("what", ""))
	if what.is_empty():
		return "HARNESS-ERROR defect step %s has no what:\"...\"" % step_id
	var severity := str(args.get("severity_candidate", "SHIP"))
	_emit("defect", {"actual": what, "severity_candidate": severity,
		"observation": str(args.get("observation", "")),
		"repro": args.get("repro", null)})
	return "recorded defect (%s): %s" % [severity, what]


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
	var grab_started := Time.get_ticks_usec()
	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		row["reason"] = "viewport returned an empty image"
		_frames.append(row)
		_record_absent += 1
		return
	var rel := "frames/%s/%09.2f.png" % [_segment_id, t]
	var err := image.save_png(_out_dir.path_join(rel))
	var grab_ms := float(Time.get_ticks_usec() - grab_started) / 1000.0
	_record_grab_ms.append(grab_ms)
	_record_grab_hz.append(_record_hz)
	row["grab_ms"] = snappedf(grab_ms, 0.01)
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
		# §C.4 says an absent frame is evidence, and it is -- but evidence of
		# ABSENCE, which is a FAIL, not a PASS.
		#
		# This line used to return "capture skipped", which does not begin with
		# FAIL, so `_do_step` recorded PASS. That is CD-1: the 2026-08-27 run
		# reported PASS for 9,231 captures it could not take, and a reader of
		# those notes had no way to see it. §C.4's rule is about not DELETING
		# the row; it was never a licence to call a missing picture a pass.
		#
		# The pre-flight above normally means this is unreachable in a segment
		# that plans captures. It is kept, and kept failing, because the two
		# guards protect against different mistakes: the pre-flight catches the
		# wrong invocation, this catches a display server lost mid-segment.
		row["reason"] = "headless: this process has no display server and cannot render a frame"
		_manifest.append(row)
		_emit("screenshot", {"artifacts": [shot_id], "observation": str(row["reason"]),
			"severity_candidate": "BLOCKER"})
		return "FAIL capture %s could not be taken: %s" % [shot_id, str(row["reason"])]
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
	if written == 0:
		return "FAIL capture_seq %s wrote 0 of %d planned frames at %.0f Hz" % [
			str(args.get("id", step_id)), count, hz]
	if written < count:
		return "FAIL capture_seq %s wrote only %d of %d planned frames at %.0f Hz" % [
			str(args.get("id", step_id)), written, count, hz]
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
		# BLOCKING-ERROR FIX (operator lane, 2026-08-26). `_out_dir` is the
		# SEGMENT's directory, not the run's, so this resolved S03's
		# `run://S02-exit.json` to `<run>/S03/saves/S02-exit.json` -- inside the
		# segment that is asking, which by definition cannot hold the previous
		# segment's exit save. `save_out` writes to `<run>/<segment>/saves/`, so
		# the two halves of the handoff never met and EVERY chained segment
		# S03-S10 failed at its first step with "seed source does not exist",
		# then ran on against a title screen it never left.
		#
		# The comment below this block already stated the intent -- "resolves
		# against this run's own saves/ directory" -- so this is the documented
		# behaviour, restored, not a new one. Looks in the run root first, then
		# in each segment's own saves/, which is where `save_out` actually puts
		# them.
		var want := from.trim_prefix("run://")
		var run_root := _out_dir.get_base_dir()
		from = run_root.path_join("saves").path_join(want)
		if not FileAccess.file_exists(from):
			var found := ""
			var dir := DirAccess.open(run_root)
			if dir != null:
				dir.list_dir_begin()
				var entry := dir.get_next()
				while entry != "":
					if dir.current_is_dir() and not entry.begins_with("."):
						var candidate := run_root.path_join(entry).path_join("saves").path_join(want)
						if FileAccess.file_exists(candidate):
							found = candidate
					entry = dir.get_next()
				dir.list_dir_end()
			if not found.is_empty():
				from = found
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

	# --- combat interior (GF-B-011) -----------------------------------------
	#
	# Only while a fight is running: `combat_state()` returns `{}` otherwise and
	# asking it 60 times a second in the overworld would be pure cost.
	if fighting:
		var cs: Dictionary = _probe.call("combat_state")
		var hps: Array = cs.get("opponent_hp", []) as Array
		var opponent := float(hps[0]) if not hps.is_empty() else -1.0
		var mine := float(cs.get("my_hp", -1.0))
		if _prev_opponent_hp >= 0.0 and opponent >= 0.0 and opponent < _prev_opponent_hp - 0.01:
			_emit("combat_hit", {"observation": "%s took %.1f damage (%.1f -> %.1f)" % [
				str(cs.get("opponent_id", "the opponent")), _prev_opponent_hp - opponent,
				_prev_opponent_hp, opponent]})
		if _prev_my_hp >= 0.0 and mine >= 0.0 and mine < _prev_my_hp - 0.01:
			_emit("combat_hit", {"observation": "my creature took %.1f damage (%.1f -> %.1f)" % [
				_prev_my_hp - mine, _prev_my_hp, mine]})
		_prev_opponent_hp = opponent
		_prev_my_hp = mine
		# The catch phases are `combat_manager.gd`'s own enum, read through the
		# probe: `absorb` is the throw leaving the hand. `catch_result` already
		# had a detector (the party growing); this is the other half, and
		# without it a failed catch left no trace at all.
		var phase := str(cs.get("phase", ""))
		if phase == "absorb" and _prev_catch_phase != "absorb":
			_emit("catch_throw", {"observation": "catch thrown at %s" % str(cs.get("opponent_id", ""))})
		if _prev_catch_phase == "shaking" and phase == "verdict":
			_emit("catch_result", {"observation": "catch resolved to a verdict"})
		_prev_catch_phase = phase
		var out_now: Variant = _probe.call("active_creature")
		var out_name := "" if out_now == null else str(out_now)
		if not _prev_active_creature.is_empty() and not out_name.is_empty() \
				and out_name != _prev_active_creature:
			_emit("combat_switch", {"observation": "switched %s -> %s mid-fight"
				% [_prev_active_creature, out_name]})
		_prev_active_creature = out_name
	else:
		_prev_opponent_hp = -1.0
		_prev_my_hp = -1.0
		_prev_catch_phase = ""
		_prev_active_creature = ""

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

	_slow_watch_tick += 1
	if _slow_watch_tick % SLOW_WATCH_EVERY == 0:
		_watch_slow(context, party)


## The 10 Hz half: inventory, buildings, condition, landmarks, dialogue.
##
## Split out for cost (see `SLOW_WATCH_EVERY`) and because these five share a
## shape the fast half does not -- each is a whole-collection walk whose answer
## is a set difference rather than a scalar comparison.
func _watch_slow(context: String, party: Array) -> void:
	var g := _probe.call("game") as Node

	# --- dialogue -----------------------------------------------------------
	#
	# Passive, so a conversation that started on its own -- Grandpa's, which
	# fires the moment the player walks out of the spawn -- is in the record
	# even when no `advance_dialogue_until_closed` step drove it.
	var owner := _probe.call("input_owner_node") as Node
	var line := ""
	if owner != null and _panel_kind(owner) == "dialogue":
		line = _line_signature(owner, "dialogue")
	if line != _prev_dialogue_line:
		if not line.is_empty():
			_emit("dialogue", {"observation": line})
		_prev_dialogue_line = line

	# --- inventory: gather vs craft vs build cost ---------------------------
	var inventory: Dictionary = _probe.call("inventory_snapshot")
	if not _prev_inventory.is_empty() or not inventory.is_empty():
		var gained: Array[String] = []
		var lost: Array[String] = []
		for id: Variant in inventory.keys():
			var was := int(_prev_inventory.get(id, 0))
			var now := int(inventory[id])
			if now > was:
				gained.append("%s +%d" % [str(id), now - was])
		for id: Variant in _prev_inventory.keys():
			var now2 := int(inventory.get(id, 0))
			var was2 := int(_prev_inventory[id])
			if now2 < was2:
				lost.append("%s -%d" % [str(id), was2 - now2])
		if not (gained.is_empty() and lost.is_empty()):
			# Which verb this was is decided by WHERE it happened, because the
			# satchel is the only thing all three touch. A menu is the craft
			# bench; an armed ghost is a build charging its cost; the world with
			# neither is a gather. Anything else is a `note` rather than a
			# guessed verb -- §C.1's own "never emit fabricated values".
			var pending := str((_probe.call("input_state") as Dictionary).get("pending_build", ""))
			var moved := "gained [%s] lost [%s]" % [", ".join(gained), ", ".join(lost)]
			if context.begins_with("menu") or context == "build_catalogue":
				_emit("craft", {"observation": "%s in %s" % [moved, context]})
			elif not pending.is_empty() or not _prev_pending_build.is_empty():
				_emit("note", {"observation": "%s while a build ghost was armed" % moved})
			elif gained.is_empty():
				_emit("note", {"observation": "%s in %s" % [moved, context]})
			else:
				_emit("gather", {"observation": "%s in %s" % [moved, context]})
		_prev_inventory = inventory

	# --- buildings ----------------------------------------------------------
	if g != null:
		var raw: Variant = g.get("placed_buildings")
		var placed := (raw as Array).size() if typeof(raw) == TYPE_ARRAY else -1
		if _prev_placed >= 0 and placed >= 0:
			if placed > _prev_placed:
				_emit("build_place", {"observation": "placed_buildings %d -> %d" % [_prev_placed, placed]})
			elif placed < _prev_placed:
				_emit("build_dismantle", {"observation": "placed_buildings %d -> %d" % [_prev_placed, placed]})
		var pending_now := str(g.get("pending_build"))
		# Armed and then disarmed with nothing new on the ground is a cancel.
		# Checked against the building count on the SAME sample so a placement
		# -- which also clears the ghost -- is never miscounted as a cancel.
		if not _prev_pending_build.is_empty() and pending_now.is_empty() \
				and placed == _prev_placed:
			_emit("build_cancel", {"observation": "the '%s' ghost was disarmed without placing"
				% _prev_pending_build})
		_prev_pending_build = pending_now
		_prev_placed = placed

		# --- landmarks ------------------------------------------------------
		var map: Variant = g.get("map")
		if map != null and map.has_method("landmarks"):
			var discovered := 0
			var newest := ""
			for entry: Variant in (map.call("landmarks") as Array):
				var landmark: Dictionary = entry
				if bool(landmark.get("discovered", false)):
					discovered += 1
					newest = str(landmark.get("display_name", landmark.get("id", "")))
			if _prev_landmarks >= 0 and discovered > _prev_landmarks:
				_emit("landmark_discover", {"observation": "%d -> %d landmarks discovered (latest: %s)"
					% [_prev_landmarks, discovered, newest]})
			_prev_landmarks = discovered

	# --- rest and feed ------------------------------------------------------
	#
	# Read off `creature_condition.gd`'s own summary through the probe, which is
	# what the HUD shows the player. A creature going from not-fed to fed IS the
	# feed event; there is no other observable moment.
	for entry: Variant in party:
		var creature: Dictionary = entry
		var who := str(creature.get("name", ""))
		var fed := bool(creature.get("fed", false))
		var rested := bool(creature.get("rested", false))
		var was_fed: Variant = _prev_condition.get("%s:fed" % who)
		var was_rested: Variant = _prev_condition.get("%s:rested" % who)
		if was_fed != null and fed and not bool(was_fed):
			_emit("feed", {"observation": "%s is fed" % who})
		if was_rested != null and rested and not bool(was_rested):
			_emit("rest", {"observation": "%s is rested" % who})
		_prev_condition["%s:fed" % who] = fed
		_prev_condition["%s:rested" % who] = rested

	var vitals: Dictionary = _probe.call("player_vitals")
	if not vitals.is_empty():
		var satiety := float(vitals.get("satiety", 0.0))
		# A rise, not any change: satiety drains continuously by design, and an
		# event on the drain would fire forever. The threshold is above the
		# per-100ms drain and below any food's restore.
		if _prev_satiety >= 0.0 and satiety > _prev_satiety + 1.0:
			_emit("feed", {"observation": "player satiety %.1f -> %.1f" % [_prev_satiety, satiety]})
		_prev_satiety = satiety


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
	# The new GF-B-011 detectors, seeded the same way and for the same reason:
	# a boot must not report every item already in the satchel as newly
	# gathered, nor every landmark on the save as newly discovered.
	_prev_dialogue_line = ""
	_prev_opponent_hp = -1.0
	_prev_my_hp = -1.0
	_prev_catch_phase = ""
	_prev_active_creature = ""
	_prev_inventory = _probe.call("inventory_snapshot")
	_prev_condition.clear()
	for entry: Variant in party:
		var creature: Dictionary = entry
		var who := str(creature.get("name", ""))
		_prev_condition["%s:fed" % who] = bool(creature.get("fed", false))
		_prev_condition["%s:rested" % who] = bool(creature.get("rested", false))
	var vitals: Dictionary = _probe.call("player_vitals")
	_prev_satiety = float(vitals.get("satiety", -1.0)) if not vitals.is_empty() else -1.0
	var g := _probe.call("game") as Node
	_prev_placed = -1
	_prev_pending_build = ""
	_prev_landmarks = -1
	if g != null:
		var raw: Variant = g.get("placed_buildings")
		_prev_placed = (raw as Array).size() if typeof(raw) == TYPE_ARRAY else -1
		_prev_pending_build = str(g.get("pending_build"))
		var map: Variant = g.get("map")
		if map != null and map.has_method("landmarks"):
			var discovered := 0
			for entry2: Variant in (map.call("landmarks") as Array):
				if bool((entry2 as Dictionary).get("discovered", false)):
					discovered += 1
			_prev_landmarks = discovered
	_slow_watch_tick = 0


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
	# `overhead_scene` exists because the two costs this probe adds up do not
	# live in the same place, and on this container only one of them can be
	# measured on the Meadows.
	#
	# The TELEMETRY tick costs what the scene costs -- it walks the party, the
	# quest log and the point-of-interest cache -- so it has to be measured on
	# the real world, and can be, headless.
	#
	# The RECORDER's cost is a framebuffer readback and a PNG encode. It scales
	# with pixels, not with scene complexity, so the title scene at the capture
	# resolution measures it honestly. Measuring it on the Meadows would be
	# better and is not available here: under llvmpipe the world renders slowly
	# enough that six twenty-second windows did not complete in fifty minutes,
	# and a measurement taken while the box is that saturated says more about
	# the container than about the instrument.
	#
	# So the note names the scene it ran on, and a reader composes the two
	# rather than being handed one number pretending to be both.
	var which := str(_cfg["overhead_scene"])
	var path := TITLE_SCENE if which == "title" else WORLD_SCENE
	var packed := load(path) as PackedScene
	if packed == null:
		_die("overhead probe could not load %s" % path)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in int(_cfg["settle_frames"]):
		await physics_frame
	_probe.call("refresh_pois")
	_seed_change_detection()
	_frame_ms.clear()
	# The recorder is what is under test in the third condition, so its output
	# has somewhere to go regardless of which scene this ran on.
	_record_args = {"hud": "on", "camera_kind": "probe"}

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
	_overhead_note = ("scene=%s. %.0f s x 2 windows per condition at %s, order off/telemetry/recording/recording/"
		+ "telemetry/off (reversed to cancel drift). Means: off %.3f, telemetry %.3f, "
		+ "telemetry+recording@%.2fHz %.3f ms/frame. Deltas vs off: telemetry %+.3f (%s), "
		+ "recording %+.3f (%s). Noise floor %.3f ms/frame, taken as the widest a single condition "
		+ "disagreed with itself. Display server %s, viewport %dx%d, frames written %d. "
		+ "Recorder cost measured DIRECTLY as well, because the frame-time difference cannot resolve "
		+ "a 1 ms/frame effect against this noise floor: %s. "
		+ "CPU frame time on this container only -- no device fps, no VRAM.") % [
			which, half, str(_pos_array()),
			float(means["off"]), float(means["telemetry"]),
			float(_cfg["record_window_hz"]), float(means["recording"]),
			d_telemetry, _overhead_verdict(d_telemetry, noise),
			d_recording, _overhead_verdict(d_recording, noise),
			noise, DisplayServer.get_name(), _viewport_size().x, _viewport_size().y,
			_record_written, _grab_line()]
	print("gate-f overhead: %s" % _overhead_note)


## `{mean, max, n}` milliseconds per recorded frame, or `{}` if none were taken.
##
## This is the number §H's last clause actually needs. The amortised per-frame
## cost of the recorder is `mean * hz / ticks_per_second` -- a 0.5 Hz recorder
## at 60 Hz spreads each grab over 120 frames -- and stating both lets a reader
## recompute it for whatever rate a segment used instead of trusting one figure.
func _grab_summary() -> Dictionary:
	if _record_grab_ms.is_empty():
		return {}
	var sum := 0.0
	var peak := 0.0
	for v: float in _record_grab_ms:
		sum += v
		peak = maxf(peak, v)
	var mean := sum / float(_record_grab_ms.size())
	var hz_sum := 0.0
	for v: float in _record_grab_hz:
		hz_sum += v
	var hz := hz_sum / float(maxi(1, _record_grab_hz.size()))
	return {
		"mean_ms": snappedf(mean, 0.01),
		"max_ms": snappedf(peak, 0.01),
		"n": _record_grab_ms.size(),
		"amortised_ms_per_frame_at_hz": snappedf(
			mean * hz / float(Engine.physics_ticks_per_second), 0.001),
		"hz": hz,
	}


## How to read one delta, honestly.
##
## Three outcomes and they are genuinely different claims: over the protocol's
## ~1 ms/frame line (say so, and do NOT thin the trace to hide it -- §3's last
## clause); measurable and under it; or smaller than this measurement can
## separate from noise, which is not the same as zero and must not be written
## as zero.
## The direct measurement, as a sentence, with its own verdict against the
## protocol's ~1 ms/frame line.
func _grab_line() -> String:
	var g := _grab_summary()
	if g.is_empty():
		return "no frames were recorded, so the grab cost was not measured"
	var amortised := float(g["amortised_ms_per_frame_at_hz"])
	var verdict := "under the ~1 ms/frame line"
	if amortised > 1.0:
		verdict = ("OVER the ~1 ms/frame line -- §H's own clause applies and X08's perf audit should "
			+ "run with record_hz 0; the trace was NOT thinned to hide this")
	return ("%d frames, %.1f ms mean and %.1f ms max per readback+encode, which at %.2f Hz amortises to "
		+ "%.3f ms/frame (%s)") % [int(g["n"]), float(g["mean_ms"]), float(g["max_ms"]),
			float(g["hz"]), amortised, verdict]


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
