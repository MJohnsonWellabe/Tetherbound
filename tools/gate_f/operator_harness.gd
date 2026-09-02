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
	# CD-7. The ceiling a predicted segment cost may not exceed, in seconds.
	# X07 stopped at step 184 of 266 with two `{"seconds": 90}` steps still
	# ahead of it: at the measured llvmpipe cost of ~10.5 s per rendered frame
	# those two alone were ~31 hours. The protocol's waits are not the problem
	# -- they exist so fights resolve -- so the fix is to price the segment
	# before launching it and refuse, rather than to discover it 15 hours in.
	# Four hours; a segment over it needs a GPU or a re-cadenced script.
	"segment_cost_ceiling_s": 14400.0,
	## Frames timed during the pre-flight to measure what one costs here.
	"cost_probe_frames": 20,
	## ...but never spend more than this measuring. Added 2026-08-28: the probe
	## was written when a frame cost 6 ms, and 20 of them cost 0.12 s. The run-2
	## BLOCKER measured 6.465 s per in-world frame under llvmpipe, at which
	## price the same 20-frame probe costs over two minutes EVERY time a scene
	## comes up. The measurement stops as soon as it has both a floor on the
	## sample count and enough elapsed time to be meaningful.
	"cost_probe_budget_s": 20.0,
	"cost_probe_min_frames": 4,
	## How often, in physics frames actually ticked, the segment re-prices its
	## REMAINDER against what frames are costing right now. A one-shot price
	## taken on a title screen and applied to hours of Meadows is the defect
	## this exists for; a price that is never revisited is the same defect with
	## a longer fuse.
	"cost_recheck_frames": 120,
	## How far the measured frame cost has to move before a recheck is worth a
	## row in the ledger. A heartbeat that logs the same number a hundred times
	## buries the two rows that matter and bloats every artefact carrying them.
	"cost_log_change_fraction": 0.25,
	## Disk. Added 2026-08-28 from the run-2 BLOCKER: at §H's planned cadences
	## the eighteen segments were about 25 GB before the frame-cost multiplier,
	## into a container with 23 GB free, and nothing anywhere had priced it.
	## Bytes are estimated from a MEASURED PNG (the pre-flight self-test at the
	## real capture resolution), never from an assumed size.
	"disk_reserve_bytes": 2147483648.0,
	## A run directory inside a work tree costs its bytes TWICE: once in the
	## working tree and once in `.git` when the evidence is committed, which it
	## must be or it dies with the container.
	"disk_git_factor": 2.0,
	## A prescribed capture whose frame is this flat AND this dark is a picture
	## of an obstruction, not of the game. Calibrated against X07's own 79
	## frames -- see `_frame_stats`.
	"degenerate_dark_fraction": 0.65,
	"degenerate_stddev": 35.0,
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
## Every derail this segment suffered, resynced ones included.
##
## `_derailed` is cleared by a resync, which is correct -- and it means a
## segment that lost the thread and found it again would close with an empty
## `derailed` field and look clean. It is not clean: the steps between the
## derail and the resync did not run, and a reader has to be able to see that
## without diffing the notes file.
var _derails: Array = []
## Every capture the segment DECLARED, resolved before the first step runs.
## `INVENTORY.json` is this list joined to what is on disk at the end.
var _planned_captures: Array = []
## Step bookkeeping, so `INVENTORY.json` can say how much of the segment ran.
var _step_total := 0
var _step_ran := 0
## Steps the context guard refused to run. Distinct from `_step_ran` and from
## a SKIP: a refusal is one step that could not be performed, a skip is the
## consequence for the ones after it.
var _step_refused := 0
var _verdicts := {"PASS": 0, "FAIL": 0, "SKIP": 0, "DELEGATED": 0}
## What the pre-flight found, verbatim, in `RUN_METADATA.json` and the inventory.
var _preflight: Dictionary = {}
## `--gatef-allow-no-capture`: an explicit, recorded acknowledgement that this
## invocation cannot capture. It does NOT make the segment complete -- the
## inventory still marks every planned shot absent and `complete: false` -- it
## only lets a developer run a capture-bearing segment for its logic while
## knowing the evidence half is void.
var _allow_no_capture := false
## CD-7's two measured numbers, kept for `RUN_METADATA.json`.
var _frame_cost_s := 0.0
var _predicted_cost_s := 0.0
## Set by `_write_inventory` when a planned capture is not on disk. Distinct
## from a FAIL verdict, which never fails the process.
var _evidence_missing := false
## What `git check-ignore` was able to say about this segment's captures.
## Carried into `INVENTORY.json` verbatim: "unknown" must read as unknown and
## never as clean.
var _git_check := "not run"
## CD-7's second measurement. The pre-flight runs BEFORE step 1, on an empty
## tree, so the frame cost it measures is an empty tree's -- which under xvfb
## is nothing like the Meadows'. The prediction is therefore re-taken and
## re-checked immediately after the first `boot`, where the number is finally
## about the scene the segment will actually render.
var _predicted_frames := 0
var _cost_gated := false
## §H/§G evidence split, owner decision 2026-08-27. "logic" | "capture" | "both".
## `both` is what every segment written before the split means, and is the
## default, so an unconverted segment keeps its old meaning exactly.
var _objective_ids: Dictionary = {}
var _evidence_lane := "both"
## On a logic lane: who owes the §G frames this lane is not taking, and which
## ids they are. A delegation that nobody has accepted is a BLOCKER at step 1 --
## the whole point of writing the debt down is that it cannot evaporate.
var _capture_lane := ""
var _delegated_captures: Array = []
## RIG-9. The §H continuous-record WINDOWS a logic lane handed to its capture
## lane, kept apart from `_delegated_captures` because a window is not a §G id
## and must not be checked against the capture lane's `owes` list, which names
## frames. Same rule though: debt transferred and recorded, never erased.
var _delegated_records: Array = []
## On a capture lane: the §G ids it accepts responsibility for.
var _segment_owes: Array = []
## The step list and where in it we are, so a re-price can cost the REMAINDER
## rather than re-costing steps that have already been paid for.
var _steps: Array = []
var _step_index := 0
## Rolling in-play cost sampling: physics frames ticked, and the wall clock at
## the top of the current sampling window.
var _cost_window_frames := 0
var _cost_window_usec := 0

## CD-7d (T5-PLAY, 2026-08-30). The last few in-play window prices, so the
## PREDICTION can use a median instead of the single most recent sample.
##
## Why: `_apply_price` multiplies `remaining_frames` by one observed price, and
## `_cost_recheck` observes over a 120-frame window. A window that happens to
## contain a one-off scene cost -- a fight staging, a region load, an arena
## build -- reads that cost as the price of EVERY remaining frame.
##
## Measured, on this lane's own S03: the gate refused the segment at step 136 of
## 406, predicting 5.7 h from a window that priced 0.2027 s/frame. The segment's
## own route.csv, which carries both clocks, says the sustained rate either side
## of it was 0.0167-0.0172 s/frame at a wall/play ratio of 1.0 -- the game runs
## at real time headless. The true remaining cost was about 29 minutes. The run
## had already paid for the whole world stand-up before that window opened, so
## this is not the boot being double-charged (`_reprice` resets the window for
## exactly that); it is a transient inside one window being extrapolated.
##
## A median over nine windows still refuses a segment that is GENUINELY too
## expensive -- capture mode's 10.5 s/frame is sustained, so its median is
## 10.5 -- while a single spike moves the median by nothing. The raw sample is
## still recorded in the ledger, so a spike stays visible rather than smoothed
## away.
const COST_SAMPLE_WINDOW := 9
## Samples needed before an in-play price may REFUSE a segment. Three windows is
## 360 frames, about six seconds of play: cheap insurance against the first
## window after a scene change deciding the whole segment.
const COST_SAMPLES_BEFORE_REFUSAL := 3
var _cost_samples: Array[float] = []
## Every re-price this segment took, in order, so the notes show a cost that
## moved rather than one number that happened to be the last.
var _reprices: Array = []
var _cost_rechecks := 0
## CD-7c: an in-play sample over the ceiling arms a refusal that the NEXT
## window confirms or clears. See `_apply_price`.
var _cost_over_armed := false
## 0 = not asked yet, 1 = inside a work tree, -1 = not. See `_inside_work_tree`.
var _work_tree_cached := 0
## Largest evidence PNG actually written. See `_note_png_bytes`.
var _evidence_png_bytes := 0
var _disk: Dictionary = {}

# --- live counters -----------------------------------------------------------

## RIG-10. slot (int) -> md5 hex string of the slot file's content at the
## moment `seed_save` last wrote it. `save_out` compares against this to tell
## a segment that genuinely saved through the Save tab from one that is just
## handing back the save it was seeded with.
var _seeded_slot_md5: Dictionary = {}

var _probe: RefCounted = null
## Wall clock origin (the box) and PLAY clock origin (the game). Two clocks,
## kept apart on purpose since the run-2 BLOCKER: see `_wall_t()`/`_play_t()`.
var _t0_usec := 0
var _t0_frames := 0
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
	_t0_frames = Engine.get_physics_frames()

	if _mode == "overhead":
		await _run_overhead_probe()
	else:
		await _play(segment)

	_close_outputs()
	# §1.6: a failed EXPECTATION is evidence and does not fail the process. A
	# missing ARTEFACT is not evidence, it is the absence of evidence, and
	# CD-2's regression asks for exactly this: "fail the segment if any
	# manifest row claims a capture whose file is absent".
	quit(1 if (not _harness_errors.is_empty() or _evidence_missing) else 0)


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
		# Which clock every consumer reads, said out loud so nobody has to infer
		# it from the source again. Added 2026-08-28 from the run-2 BLOCKER.
		"clocks": {
			"route_csv_t": "play (Engine.get_physics_frames() / physics_ticks_per_second)",
			"events_jsonl_t": "play",
			"frames_manifest_t": "play",
			"route_csv_wall": "wall datetime, so the two clocks can be lined up",
			"trace_hz_and_record_hz": "play seconds",
			"cost_gate_and_disk_gate": "wall (they are questions about the box)",
			"duration_ms": "wall (a boot/save/load cost is a wall-clock fact)",
			"play_seconds_elapsed": snappedf(_play_t(), 0.01),
			"wall_seconds_elapsed": snappedf(_wall_t(), 0.01),
		},
		"evidence_lane": _evidence_lane,
		"capture_lane": _capture_lane,
		"delegated_captures": _delegated_captures.map(func(r: Variant) -> String:
			return str((r as Dictionary).get("id", ""))),
		"owes": _segment_owes,
		"cost_reprices": _reprices,
		"disk": _disk,
		"record_baseline_hz": _record_baseline_hz,
		"frames_written": _record_written,
		"frames_absent": _record_absent,
		"frame_grab_ms": _grab_summary(),
		"instrumentation_overhead_note": _overhead_note,
		"harness_errors": _harness_errors,
		"capture_preflight": _preflight,
		"measured_frame_cost_s": snappedf(_frame_cost_s, 0.000001),
		"predicted_segment_cost_s": snappedf(_predicted_cost_s, 0.1),
		"blocked": _blocked,
		"derailed": _derailed,
		"derailed_at": _derailed_at,
		"planned_captures": _planned_captures.size(),
		"steps_total": _step_total,
		"steps_ran": _step_ran,
		"steps_refused": _step_refused,
		"derails": _derails,
		"verdicts": _verdicts,
		# CD-8. The freeze record is supposed to carry graphics settings and did
		# not, which is how a full Gate F run happened with the procedural grass
		# field silently off. A run cannot amend a freeze record it did not
		# write, so it records what the build it is playing actually had on.
		"config_flags": _config_flags(),
		# Every flag that is OFF, gathered into one field. CD-8 asks for the
		# divergent-from-default flags to be called out so a reviewer sees them
		# without diffing; the configs carry no machine-readable defaults, and a
		# subsystem switched off is the case that actually changed what rendered.
		"config_flags_off": _config_flags_off(),
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
func _config_flags() -> Dictionary:
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


## The switches that are OFF, as `["grass_field.json:enabled", ...]`.
##
## CD-8's whole example is one of these: `data/config/grass_field.json` has
## `"enabled": false` on the candidate, `grass_field.gd::_ready()` returns
## before building anything, and the procedural ground cover is therefore
## absent from every frame of the run -- with no artefact anywhere saying so.
## A reviewer judging ground cover from those frames was judging the baked
## scatter while believing they were judging the shipped ground system.
func _config_flags_off() -> Array:
	var out: Array = []
	var flags := _config_flags()
	for file: Variant in flags.keys():
		var block: Variant = flags[file]
		if typeof(block) != TYPE_DICTIONARY:
			continue
		for key: Variant in (block as Dictionary).keys():
			if not bool((block as Dictionary)[key]):
				out.append("%s:%s" % [str(file), str(key)])
	out.sort()
	return out


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
	_steps = steps
	if steps.is_empty():
		_die("segment %s has no steps" % _segment_id)
		return
	# §H's baseline, declared once at the top of the segment file. 0.1 Hz for a
	# journey segment, 0.5 Hz for the mandatory high-risk list; `record_hz: 0`
	# turns the continuous record off for a segment that must not have it
	# (X08's perf audit, per §H's own last clause).
	# §H/§G evidence split (owner decision 2026-08-27). A logic lane runs the
	# journey headless for mechanics, telemetry and step verdicts; it takes no
	# prescribed shot and keeps no continuous record, and it names the capture
	# lane that owes what it did not take.
	_evidence_lane = str(segment.get("evidence_lane", "both"))
	_capture_lane = str(segment.get("capture_lane", ""))
	_segment_owes = segment.get("owes", []) as Array
	_record_baseline_hz = float(segment.get("record_hz", _cfg["record_default_hz"]))
	if _evidence_lane == "logic":
		# Not "the operator forgot to set record_hz": the continuous record is
		# the thing the split exists to remove. 4.6 million rendered frames is
		# what was unaffordable, not capture.
		_record_baseline_hz = 0.0
	_record_hz = _record_baseline_hz
	_record_args = {
		"hud": str(segment.get("record_hud", "on")),
		"camera_kind": str(segment.get("record_camera_kind", "gameplay")),
	}
	_record_next_t = 0.0
	_note_line("# %s — %s" % [_segment_id, str(segment.get("title", ""))])
	_note_line("")
	_step_total = steps.size()
	if _evidence_lane == "logic":
		# The ids stay written down; they move from "this segment owes them" to
		# "this segment handed them to a named lane". Round 1 made an untakeable
		# capture a FAIL, which was right when the alternative was 9,231 false
		# PASSes. With the lanes split the question changes: a segment is judged
		# against what ITS LANE owes, and the debt itself is judged one level up,
		# by `tools/gate_f/run_inventory.py` over the whole run directory. Debt
		# transferred and recorded -- never debt erased.
		_planned_captures = []
		_delegated_captures = _plan_captures(steps)
	else:
		_planned_captures = _plan_captures(steps)
	# CD-1. Before step 1, not after step 40: a segment whose evidence cannot be
	# taken has to say so at the top, where the operator is still looking, and
	# the run has to stop rather than spend an hour producing `file: null`.
	if not await _preflight_capture(steps):
		_release_everything()
		return
	for i in steps.size():
		_step_index = i
		var raw: Variant = steps[i]
		if typeof(raw) != TYPE_DICTIONARY:
			_harness_error("a step is not a JSON object: %s" % str(raw))
			continue
		var step := raw as Dictionary
		await _do_step(step)
		if not _blocked.is_empty():
			# The post-boot cost gate. Everything after this would be spent
			# proving the prediction right at the price it predicted.
			_harness_error("segment BLOCKED after step %s: %s" % [str(step.get("id", "?")), _blocked])
			break
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
## Static so `tests/test_gate_f_rig.gd` can call it directly. A SceneTree
## subclass cannot be instantiated in a unit test, and the alternative --
## grepping the source for the behaviour -- tests the spelling, not the rule.
## `objective_is` speaks the protocol's id space; the probe speaks the game's.
##
## Two different ids name one beat. `data/progression/objectives.json` gives
## each main entry an `id` -- `opening_first_catch` -- and a `flag_id` -- the
## progression flag that closes it, `opening:beat:road`. §E.5 tracks "27 main-
## chain objectives from `opening_hear_grandpa`", so every `objective_is` in
## every segment was transcribed in ENTRY ids. `gate_f_probe.gd::tracked_
## objective()` returns the FLAG id, deliberately and under its own smoke test
## (`tests/smoke_gate_f_probe.gd`), because a flag id is what Phase B can cite
## and check against the store.
##
## Neither side is wrong and neither should move: the probe's contract is
## tested, and rewriting the segments into flag ids would make them stop
## matching the protocol they were transcribed from. So the COMPARISON
## resolves, and says in its own `actual` text which space it matched on.
##
## Found on the first segment of run 3: S01-12 asserted `opening_first_catch`,
## the game was tracking exactly the right beat with exactly the right text,
## and the step recorded FAIL. Twenty-six asserts across ten segments would
## have failed the same way -- a whole run of findings about the instrument
## wearing the shape of findings about the game, which is the specific failure
## round 2 of this rig exists to stop repeating.
##
## 2026-08-30 (ralph/GATE-F-E5): the §E.5 quote above moved from 24 rungs to 27
## and its first rung from `opening_first_catch` to `opening_hear_grandpa`,
## because OP-0830-4 added three rungs ahead of the catch. This function needed
## NO change -- it builds the id map by reading `objectives.json` at call time,
## so it absorbed a reordered chain without being touched, which is what it was
## written for. Only the three segment steps that named the old first rung by
## hand had to move. If a future rung is added, this stays correct and the
## transcription is again the thing to check.
func _objective_flag_id(entry_id: String) -> String:
	if entry_id.is_empty():
		return ""
	if _objective_ids.is_empty():
		var doc := _read_json("res://data/progression/objectives.json")
		for raw: Variant in (doc.get("main", []) as Array):
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var entry := raw as Dictionary
			var id := str(entry.get("id", ""))
			if not id.is_empty():
				_objective_ids[id] = str(entry.get("flag_id", ""))
	return str(_objective_ids.get(entry_id, ""))


static func _plan_captures(steps: Array) -> Array:
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
## time, and reported PASS for every one of them.
##
## The cause is not that somebody forgot the §0.1 invocation. The operator's
## check-in 30 is explicit: the journey and study lanes ran logic mode by a
## RECORDED DECISION, and that decision was legitimate -- `run_segment.sh`
## applies xvfb only in capture mode, and logic mode is deliberately
## `--headless` with no driver because `--headless` WITH one hangs forever.
## What was illegitimate is that nothing stopped a capture-BEARING segment
## being run that way, and that the steps then said PASS. That is not evidence
## of absence -- it is a run that did not happen, wearing the shape of one that
## did.
##
## Which is why this is a gate and not a convention: the operator's choice
## stays available, through `--gatef-allow-no-capture`, and stays recorded.
##
## So this asks, once, at the top, and it asks three separate things because
## they fail separately:
##
##   1. Is there a display server at all? (`--headless` was passed, or xvfb was
##      not.) This is the failure that produced the 9,231.
##   2. Did `tools/capture_diag_minimal.gd` write its PNG beside this run?
##      `run_segment.sh` gates capture mode on it; a missing `capture_smoke.png`
##      means this segment did not come through the capture path.
##   3. Can THIS process, in THIS scene state, actually read back a frame and
##      encode it? A display server that exists and a viewport that returns an
##      empty image are different faults with the same symptom.
##
## A segment that plans no captures and runs no continuous record needs none of
## this and is let through -- the self-check `selfcheck_walk`/`selfcheck_save_handoff`
## are logic segments by design, and blocking them would be the "fixed a rig
## problem by making a test pass" move in reverse.
func _preflight_capture(steps: Array) -> bool:
	var plans_shots := not _planned_captures.is_empty()
	var plans_record := _record_baseline_hz > 0.0
	_preflight = {
		"evidence_lane": _evidence_lane,
		"capture_lane": _capture_lane,
		"delegated_captures": _delegated_captures.size(),
		"planned_captures": _planned_captures.size(),
		"record_baseline_hz": _record_baseline_hz,
		"display_server": DisplayServer.get_name(),
		"capture_requested": _want_capture,
		"capture_available": _capture_available(),
		"allow_no_capture": _allow_no_capture,
	}
	# CD-8b: the freeze record and the artefacts must not contradict each other.
	#
	# `ralph/reports/gate-f-candidate/RUN_METADATA.json` recorded
	# `"display_server": "X11 under xvfb-run"`, and every journey segment's
	# frame manifest said the opposite -- 9,231 rows of "headless: this process
	# has no display server". The freeze record and the evidence disagreed
	# about the single fact that decided whether §11 could execute at all, and
	# nothing reconciled them for the length of the run. A metadata field
	# asserting a capability is not evidence that the capability existed, so
	# the pre-flight writes back what it FOUND and fails on a contradiction.
	var claim := _freeze_display_claim()
	if not str(claim.get("claim", "")).is_empty():
		_preflight["freeze_record"] = claim
		var claims_server := not str(claim["claim"]).to_lower().contains("headless")
		var have_server := _capture_available()
		if claims_server and not have_server:
			_preflight["contradiction"] = ("the freeze record at %s says display_server=%s; this "
				+ "process has none") % [str(claim.get("from", "")), str(claim["claim"])]
		elif have_server and not claims_server:
			_preflight["contradiction"] = ("the freeze record at %s says display_server=%s; this "
				+ "process HAS one") % [str(claim.get("from", "")), str(claim["claim"])]

	# §H/§G evidence split: the handover has to be REAL before a step runs.
	#
	# The failure this guards is the one round 1 argued about one level down. A
	# logic-lane segment that lists ids nobody takes would be a segment that
	# quietly stops owing its evidence, which is exactly the shape of the 9,231
	# `file: null` PASSes: a debt discharged by not mentioning it. So the
	# delegation is checked against the capture lane's own declaration, on disk,
	# before step 1, and an unbacked one is a hard refusal.
	var lane_why := _check_evidence_lane(steps)

	# CD-7: price the segment before launching it.
	var frames := _predict_frames(steps)
	var frame_cost := await _measure_frame_cost()
	var predicted := float(frames) * frame_cost
	_frame_cost_s = frame_cost
	_predicted_cost_s = predicted
	_preflight["predicted_frames"] = frames
	_preflight["measured_frame_cost_s"] = snappedf(frame_cost, 0.000001)
	_preflight["predicted_segment_cost_s"] = snappedf(predicted, 0.1)
	_predicted_frames = frames
	var plans_evidence := plans_shots or plans_record
	# The cost gate is about THE BOX'S TIME, not about pictures, so it applies
	# to every segment that has somewhere to write. Round 1 gated only
	# capture-bearing segments, which was defensible while capture was the only
	# expensive thing; the evidence split (§H, 2026-08-27) makes a logic lane
	# the normal way to run a journey, and a logic lane can spend a week too.
	_cost_gated = _telemetry_on()
	var ceiling := float(_cfg["segment_cost_ceiling_s"])

	if not _telemetry_on():
		_preflight["verdict"] = "not required"
		_preflight["why"] = "telemetry off (no --gatef-out); nowhere to write a PNG and nothing claiming there was"
		return true

	# Two kinds of reason to refuse, and they are NOT interchangeable.
	#
	# `capture_why` is "this invocation cannot take pictures". That is what
	# `--gatef-allow-no-capture` acknowledges, and acknowledging it buys a
	# developer a logic pass over a capture-bearing segment at the price of
	# never being able to call it complete.
	#
	# `hard_why` is a refusal the flag has no business waiving: a segment priced
	# over the time ceiling, a segment that cannot fit its evidence on the disk,
	# or a freeze record that contradicts what this process can see. None of the
	# three is about pictures. An earlier cut of this function ran all four
	# reasons through one string, so the display-server message overwrote the
	# cost message and the acknowledgement flag waved through a cost breach --
	# which would have reproduced X07's fifteen wasted hours with a flag on it.
	var capture_why := ""
	var hard_why := ""
	if not lane_why.is_empty():
		hard_why = lane_why
	if predicted > ceiling:
		var cost_why := ("predicted cost %.0f s (%.1f h) exceeds the %.0f s ceiling: %d planned frames "
			+ "at a MEASURED %.3f s/frame on this box. The protocol's waits are not the problem -- "
			+ "they exist so fights resolve -- so this segment needs a GPU or a split evidence "
			+ "lane, not a shorter wait. X07 stopped at step 184 of 266 for exactly this, ~15 "
			+ "hours in. NOTE this number is the EMPTY TREE price and is the optimistic one: the "
			+ "re-price after each boot is the honest one.") % [
				predicted, predicted / 3600.0, ceiling, frames, frame_cost]
		hard_why = cost_why if hard_why.is_empty() else "%s ALSO: %s" % [hard_why, cost_why]
	# CD-8b, and only in the direction that cost the last run everything: the
	# record promised a display server and there is none. The reverse -- a
	# record saying headless on a box that can render -- is recorded in
	# `_preflight.contradiction` and does not stop anything, because it cannot
	# cause a segment to produce nothing.
	if not str(_preflight.get("contradiction", "")).is_empty() and not _capture_available():
		var claimed := "the freeze record contradicts this process: %s" % str(_preflight["contradiction"])
		hard_why = claimed if hard_why.is_empty() else "%s ALSO: %s" % [hard_why, claimed]
	if not _capture_available():
		if plans_evidence:
			capture_why = ("no display server: DisplayServer reports '%s'. This process cannot render, "
				+ "so all %d planned capture(s) and every continuous frame would be written as file:null "
				+ "while the steps reported PASS. Relaunch through tools/gate_f/run_segment.sh --capture "
				+ "(§0.1: xvfb-run WITHOUT --headless, --rendering-driver opengl3).") % [
					DisplayServer.get_name(), _planned_captures.size()]
	elif plans_evidence:
		var smoke := _out_dir.path_join("capture_smoke.png")
		if not FileAccess.file_exists(smoke) or _file_bytes(smoke) <= 0:
			capture_why = ("tools/capture_diag_minimal.gd left no capture_smoke.png in %s. "
				+ "run_segment.sh --capture writes one before it starts a segment, so its absence "
				+ "means this segment did not come through the capture path.") % _out_dir
		else:
			_preflight["smoke_bytes"] = _file_bytes(smoke)
			var probe := await _preflight_png()
			_preflight["self_test"] = probe
			if not bool(probe.get("ok", false)):
				capture_why = ("this process has a display server but could not write its own PNG: %s"
					% str(probe.get("why", "")))
			else:
				# The measured input to the disk estimate: a real frame of a
				# real scene at the real capture resolution, encoded by the
				# same code path every evidence frame will use.
				_preflight["png_bytes"] = int(probe.get("bytes", 0))

	# The disk gate. Third of the run-2 BLOCKER's three findings and the one
	# nothing had ever asked about: at §H's cadences the eighteen segments were
	# ~25 GB before the frame-cost multiplier, into 23 GB free, doubled again by
	# the copy git has to carry. Priced here because a segment that cannot fit
	# its evidence must refuse at step 1, exactly as one that cannot afford its
	# time does.
	if plans_evidence:
		var disk := _price_disk(frames)
		_preflight["disk"] = disk
		if bool(disk.get("over", false)):
			var disk_why := "disk: %s" % str(disk.get("why", ""))
			hard_why = disk_why if hard_why.is_empty() else "%s ALSO: %s" % [hard_why, disk_why]

	if not plans_evidence and hard_why.is_empty():
		_preflight["verdict"] = "not required"
		_preflight["why"] = "segment declares no captures and no continuous record"
		_note_line("### preflight — capture not required")
		_note_line("- %s" % str(_preflight["why"]))
		_note_line("- predicted cost %.0f s over %d frames at %.4f s/frame (re-priced after each boot)"
			% [predicted, frames, frame_cost])
		_note_line("")
		return true

	# A capture failure the operator acknowledged in advance stops being the
	# reason to refuse -- and is still recorded, at BLOCKER severity, and still
	# makes the segment incomplete.
	if not capture_why.is_empty() and _allow_no_capture:
		_preflight["verdict"] = "DEGRADED (--gatef-allow-no-capture)"
		_preflight["degraded_why"] = capture_why
		_note_line("### preflight — DEGRADED, capture unavailable and acknowledged")
		_note_line("- %s" % capture_why)
		_note_line("- this segment CANNOT be marked complete; INVENTORY.json says so.")
		_note_line("")
		_emit("note", {"severity_candidate": "BLOCKER",
			"observation": "capture pre-flight failed and was overridden with --gatef-allow-no-capture: %s"
				% capture_why})
		capture_why = ""

	var why := hard_why
	if why.is_empty():
		why = capture_why
	elif not capture_why.is_empty():
		why = "%s ALSO: %s" % [hard_why, capture_why]

	if why.is_empty():
		if not str(_preflight.get("degraded_why", "")).is_empty():
			# Acknowledged and degraded, not passing. `verdict` is already
			# DEGRADED and the inventory will mark every planned shot absent.
			return true
		_preflight["verdict"] = "PASS"
		_note_line("### preflight — capture available")
		_note_line("- display_server: %s, smoke %d bytes, self-test %s" % [
			DisplayServer.get_name(), int(_preflight.get("smoke_bytes", 0)),
			str((_preflight.get("self_test", {}) as Dictionary).get("file", ""))])
		_note_line("")
		_emit("note", {"observation": "capture pre-flight PASS: %d planned capture(s), display server %s"
			% [_planned_captures.size(), DisplayServer.get_name()]})
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


## What the freeze record claims about the display server, and where it says it.
##
## Two places, nearest first: the run directory's own `RUN_METADATA.json`
## (§A.2, written by the coordinator at freeze) and the candidate freeze record.
## Absent from both is fine and reported as such -- a missing claim cannot
## contradict anything. A PRESENT and wrong claim is CD-8b.
func _freeze_display_claim() -> Dictionary:
	var candidates: Array[String] = []
	if not _out_dir.is_empty():
		candidates.append(_out_dir.get_base_dir().path_join("RUN_METADATA.json"))
	candidates.append(ProjectSettings.globalize_path(
		"res://ralph/reports/gate-f-candidate/RUN_METADATA.json"))
	for path in candidates:
		var record := _read_json(path)
		if record.is_empty():
			continue
		# Lane-aware, and ONLY where the freeze record itself says so.
		#
		# The evidence split (2026-08-27) makes a run that is headless for its
		# logic lane and X11 for its capture lane the normal shape, and a single
		# flat `display_server` cannot describe it truthfully. So a record MAY
		# carry `"lanes": {"logic": {...}, "capture": {...}}` and this reads the
		# entry for the lane the segment declared.
		#
		# This is a refinement of CD-8b and deliberately not a softening of it.
		# A record with no `lanes` block still binds every segment by its flat
		# claim, exactly as before -- so a run that wants a logic lane must SAY
		# SO IN THE FREEZE RECORD BEFORE THE RUN, which is precisely what the
		# run-2 operator asked the coordinator to decide rather than amending a
		# record mid-run to get a segment to start. The contradiction check
		# below is unchanged and is still not waivable by the acknowledgement
		# flag.
		var lanes: Dictionary = record.get("lanes", {}) as Dictionary
		if lanes.has(_evidence_lane):
			var lane: Dictionary = lanes[_evidence_lane] as Dictionary
			for key in ["display_server", "renderer"]:
				if lane.has(key) and not str(lane[key]).is_empty():
					return {"from": path, "key": "lanes.%s.%s" % [_evidence_lane, key],
						"claim": str(lane[key]), "lane": _evidence_lane}
		for key in ["display_server", "renderer"]:
			if record.has(key) and not str(record[key]).is_empty():
				return {"from": path, "key": key, "claim": str(record[key]),
					"lane": "(all lanes; the record declares none)"}
	return {}


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


## §H/§G evidence split: is this segment's declaration coherent, and is its
## handover actually accepted?
##
## Owner decision, 2026-08-27. The measurement behind it: a rendered frame of
## the Meadows costs 12,721 ms on this container against 6.1 ms in logic mode,
## and the protocol's eighteen segments ask for 4,607,802 physics frames --
## about 8,283 hours in capture mode. Continuous recording of every frame is
## what is unaffordable, not capture itself: `tools/_probe_grass_pass.gd` took
## 14 real 1920x1080 frames across four bands in about 28 minutes on this same
## box with the grass field ON. Frames from targeted probes are cheap; 4.6
## million rendered physics frames are not.
##
## So a segment declares which lane it is:
##
##   "logic"   -- the journey, run headless, for mechanics, telemetry and step
##                verdicts. Takes no prescribed frame and keeps no continuous
##                record. MUST name a `capture_lane`, and every §G id its steps
##                would have taken is handed to it.
##   "capture" -- the prescribed screenshots, taken at named states. MUST
##                declare `owes`, and every id in `owes` must actually be shot
##                by one of its own steps. A lane that claims an id it never
##                takes is CD-1 wearing a different hat.
##   "both"    -- what every segment written before the split means. Unchanged.
##
## Returns "" when the declaration is coherent, or the refusal text.
func _check_evidence_lane(steps: Array) -> String:
	if _evidence_lane == "both":
		if not _capture_lane.is_empty():
			return ("this segment declares capture_lane=%s but no evidence_lane. A handover with "
				+ "no lane to hand FROM is a declaration that does nothing; say "
				+ "\"evidence_lane\": \"logic\" or drop the key.") % _capture_lane
		return ""
	if _evidence_lane == "capture":
		var owes: Array = _segment_owes
		if owes.is_empty():
			return ("evidence_lane=capture with an empty \"owes\": a capture lane exists to pay a "
				+ "named debt. List the §G ids it takes, or make this segment evidence_lane=both.")
		# Resolved from the step list handed in, not from `_planned_captures`:
		# this check is about whether the FILE is coherent, and asking the file
		# rather than a field set from it keeps the two from drifting apart.
		var planned := {}
		for entry: Variant in _plan_captures(steps):
			planned[str((entry as Dictionary).get("id", ""))] = true
		var missing: Array[String] = []
		for id: Variant in owes:
			if not planned.has(str(id)):
				missing.append(str(id))
		if not missing.is_empty():
			return ("evidence_lane=capture claims to owe %s but no capture step in this segment "
				+ "takes them. A lane that claims an id it never shoots is exactly the 2026-08-27 "
				+ "run's `file: null` PASS with a different label on it.") % str(missing)
		return ""
	if _evidence_lane != "logic":
		return ("unknown evidence_lane \"%s\": expected \"logic\", \"capture\" or \"both\"."
			% _evidence_lane)
	# --- logic lane -----------------------------------------------------------
	if _delegated_captures.is_empty():
		# Nothing to hand over. A journey segment with no §G frame in it is
		# perfectly ordinary (X06 has none) and needs no capture lane.
		return ""
	if _capture_lane.is_empty():
		return ("evidence_lane=logic with %d prescribed capture(s) in its steps and no "
			+ "\"capture_lane\". The split moves a debt; it does not cancel one. Name the "
			+ "segment that takes these frames.") % _delegated_captures.size()
	var path := "res://tools/gate_f/segments/%s.json" % _capture_lane
	var target := _read_json(path)
	if target.is_empty():
		return ("evidence_lane=logic delegates to \"%s\" and %s does not exist or does not parse. "
			+ "A handover to a file that is not there is a debt that has quietly stopped existing."
			) % [_capture_lane, path]
	if str(target.get("evidence_lane", "")) != "capture":
		return ("evidence_lane=logic delegates to \"%s\", which declares evidence_lane=%s. Only a "
			+ "capture lane can accept a capture debt.") % [
				_capture_lane, str(target.get("evidence_lane", "(none)"))]
	var accepted := {}
	for id: Variant in (target.get("owes", []) as Array):
		accepted[str(id)] = true
	var unaccepted: Array[String] = []
	for entry: Variant in _delegated_captures:
		var id := str((entry as Dictionary).get("id", ""))
		if not accepted.has(id):
			unaccepted.append(id)
	if not unaccepted.is_empty():
		return ("evidence_lane=logic hands %d id(s) to \"%s\" that its \"owes\" list does not "
			+ "accept: %s. An unaccepted delegation is how a segment would become "
			+ "capture-incomplete forever without anything ever saying so.") % [
				unaccepted.size(), _capture_lane, str(unaccepted)]
	# RIG-9's other half. A §H continuous-record window is a second kind of
	# evidence debt and it needs the same guarantee the §G ids get: the lane it
	# is handed to has to actually open one. Checked structurally, by looking for
	# `record_start` in the capture lane's own steps, because "the capture lane
	# will surely record something" is the assumption CD-1 already paid for once.
	var windows := 0
	for raw: Variant in steps:
		if typeof(raw) == TYPE_DICTIONARY and str((raw as Dictionary).get("action", "")) == "record_start":
			windows += 1
	if windows > 0:
		var target_windows := 0
		for raw: Variant in (target.get("steps", []) as Array):
			if typeof(raw) == TYPE_DICTIONARY \
					and str((raw as Dictionary).get("action", "")) == "record_start":
				target_windows += 1
		if target_windows == 0:
			return ("evidence_lane=logic declares %d §H continuous-record window(s) and hands them "
				+ "to \"%s\", which opens none. §H.1 lets a capture lane run BOUNDED record "
				+ "windows around a named state -- that is where these belong. A window handed "
				+ "to a lane that never records is a debt that has quietly stopped existing."
				) % [windows, _capture_lane]
	return ""


## CD-7: what will this segment cost, in seconds, on THIS box?
##
## `_step_wait` converts seconds to physics frames, and in capture mode every
## physics frame is a rendered 1920x1080 frame. A protocol written in seconds
## has to be costed in FRAMES before it is launched. This counts the frames
## each step will advance -- upper bounds where a step has a budget, because a
## budget is what it may actually spend -- and multiplies by the measured cost
## of one frame here.
static func _predict_frames(steps: Array) -> int:
	var total := 0
	for raw: Variant in steps:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var step := raw as Dictionary
		var args: Dictionary = step.get("args", {}) as Dictionary
		match str(step.get("action", "")):
			"boot":
				total += int(args.get("settle_frames", 240))
			"wait":
				var frames := int(args.get("frames", 0))
				if float(args.get("seconds", 0.0)) > 0.0:
					frames = maxi(frames, int(float(args["seconds"]) * 60.0))
				total += frames
			"stick":
				total += int(args.get("frames", 10))
			"move_to", "move_to_entity":
				# The WALK budget, not an estimate of the walk: a segment is
				# only safe to launch if its worst case fits.
				total += int(args.get("budget_frames", 2400))
			"face":
				total += int(args.get("budget_frames", 240))
			"wait_until":
				# The worst case, like a walk: the budget, not the hoped-for
				# early exit. A segment is only safe to launch if the whole
				# budget fits.
				total += int(args.get("budget_frames", 600))
			"press":
				total += maxi(1, int(args.get("times", 1))) * (int(args.get("settle_frames", 8)) + 4)
			"press_multi", "focus_move", "focus_item", "open_menu", "close_menu", "probe_cell", \
					"interact_with":
				total += 12
			"advance_dialogue_until_closed":
				total += int(args.get("max_presses", 60)) * 4
			"fight_until_resolved":
				# Its own ceiling, same as a walk's `budget_frames`: the step
				# cannot run longer than this whatever the fight does.
				total += int(args.get("budget_frames", 9000))
			"press_until":
				# RIG-F2. Priced at its FULL budget, never at the early exit --
				# same rule `move_to`'s walk budget follows. A step that usually
				# stops after one press must not be able to talk the cost gate
				# into launching a segment it cannot afford in the worst case.
				total += maxi(1, int(args.get("max_presses", 4))) \
					* (int(args.get("settle_frames", 20)) + 4)
			"track_aim":
				# RIG-F3. Same rule as `press_until` just above it: priced at its
				# FULL budget, never at the early exit a clean track usually takes.
				total += int(args.get("budget_frames", 240))
			"force_aim":
				# Harness-only shortcut, cheap and single-frame by construction --
				# see _step_force_aim's own header for why this exists.
				total += 6
			"capture":
				total += 6
			"capture_seq":
				var hz := maxf(1.0, float(args.get("hz", 5.0)))
				var seconds := maxf(0.2, float(args.get("seconds", 2.0)))
				total += int(hz * seconds) * (6 + int(60.0 / hz))
			"teleport":
				total += int(args.get("resettle_frames", 60))
			"pin_clock":
				total += int(args.get("settle_frames", 30))
			_:
				total += 1
	return total


## Seconds one frame costs here, measured rather than assumed.
##
## `Performance.TIME_PROCESS` is a CPU number and misses the readback; this
## times wall clock across real frames, which is the number the prediction
## needs. In logic mode it is a fraction of a millisecond; under llvmpipe at
## 1920x1080 it was measured at ~10.5 s.
func _measure_frame_cost() -> float:
	var frames := maxi(4, int(_cfg["cost_probe_frames"]))
	var floor_frames := maxi(1, int(_cfg["cost_probe_min_frames"]))
	var budget := maxf(0.5, float(_cfg["cost_probe_budget_s"]))
	var started := Time.get_ticks_usec()
	var taken := 0
	for i in frames:
		await process_frame
		taken += 1
		# The probe must not become the cost it is measuring. At the 6.465 s
		# per frame the run-2 BLOCKER measured in the Meadows, twenty frames is
		# over two minutes -- every time a scene comes up. Once there are enough
		# samples to mean something AND enough elapsed time to be resolvable,
		# stop; the answer does not get better and the segment is paying for it.
		if taken >= floor_frames and float(Time.get_ticks_usec() - started) / 1e6 >= budget:
			break
	return (float(Time.get_ticks_usec() - started) / 1000000.0) / float(maxi(1, taken))


## Which of these captures will git refuse to carry?
##
## Asked of `git check-ignore` rather than by reimplementing gitignore matching
## here. Every subtlety that made CD-2 possible -- a bare directory pattern
## matching at any depth, negations, precedence between `.gitignore` files --
## lives in that command, and a second implementation of it in GDScript would be
## a second set of answers.
##
## An unavailable or unhappy git is reported as "unknown", never as "fine": this
## check exists because a silent success was mistaken for a real one, and it
## must not repeat that shape itself.
func _uncommittable(rows: Array) -> Array:
	var out: Array = []
	var paths := PackedStringArray()
	var by_path := {}
	for entry: Variant in rows:
		var row: Dictionary = entry
		if not bool(row.get("exists", false)):
			continue
		var abs_path := _out_dir.path_join(str(row.get("file", "")))
		paths.append(abs_path)
		by_path[abs_path] = str(row.get("file", ""))
	if paths.is_empty():
		return out
	var args := PackedStringArray(["check-ignore", "-v"])
	args.append_array(paths)
	var output: Array = []
	# exit 0 = at least one path IS ignored; 1 = none are; anything else is git
	# failing to answer.
	var code := OS.execute("git", args, output, true)
	if code == 1:
		_git_check = "clean: git will carry all %d capture(s)" % paths.size()
		return out
	if code != 0:
		# 128 is git's "I cannot answer that" -- most often because the run
		# directory is outside a work tree, which is a perfectly ordinary way
		# to run a segment and says nothing bad about the captures.
		#
		# Recorded, never guessed, and NOT a completeness failure. An
		# unanswerable check that failed every run would be this lane's own
		# mistake in mirror image: making the rig refuse work it can do.
		_git_check = "unknown: git check-ignore returned %d (is %s inside a work tree?)" % [
			code, _out_dir]
		push_warning("gate-f harness: %s" % _git_check)
		return out
	_git_check = "checked %d capture(s) against git" % paths.size()
	for chunk: Variant in output:
		for line in str(chunk).split("\n"):
			# `<source>:<line>:<pattern>\t<path>`
			var parts := line.split("\t")
			if parts.size() < 2:
				continue
			var hit := parts[parts.size() - 1].strip_edges()
			if not by_path.has(hit):
				continue
			out.append({"file": str(by_path[hit]), "rule": parts[0].strip_edges()})
	return out


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
			# Carried into the ledger so "show me the frames with no contrast"
			# is a sort over INVENTORY.json rather than an afternoon of opening
			# PNGs one at a time -- which is how the 2026-08-27 run's two
			# useless frames stayed unnoticed among 79 good ones.
			if row.has("luma"):
				out["luma"] = row["luma"]
			if row.has("degenerate"):
				out["degenerate"] = str(row["degenerate"])
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
	# CD-2's real mechanism, checked at the segment that wrote the files.
	#
	# The 2026-08-27 run's X07 took 79 real 1920x1080 PNGs and git carried none
	# of them: `.gitignore` held a bare `shots/`, which matches at any depth, so
	# it swallowed every Gate F segment's own captures. `git add <dir>` skips
	# ignored contents SILENTLY -- exit 0, no output -- which is how fourteen
	# per-segment evidence commits looked clean while carrying no frames.
	#
	# An inventory that only checks the working tree cannot see that. A file
	# that exists and can never be committed is not evidence: it lives on a
	# container that gets reclaimed. So the last question the inventory asks is
	# whether git will actually take what was written.
	var uncommittable := _uncommittable(rows)
	for entry: Variant in uncommittable:
		var row: Dictionary = entry
		for candidate: Variant in rows:
			var target: Dictionary = candidate
			if str(target.get("file", "")) == str(row.get("file", "")):
				target["git_ignored_by"] = str(row.get("rule", ""))
	var complete := _blocked.is_empty() \
		and uncommittable.is_empty() \
		and str(_preflight.get("degraded_why", "")).is_empty() \
		and absent == 0 \
		and _derails.is_empty() \
		and _step_refused == 0 \
		and int(_verdicts["SKIP"]) == 0 \
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
		# §H/§G evidence split. `planned` is what THIS LANE owes; `delegated` is
		# what it handed over and to whom. Completeness below is judged against
		# the first. The second is judged one level up, over the whole run
		# directory, by `tools/gate_f/run_inventory.py` -- because that is the
		# level at which "does this frame exist anywhere" is answerable.
		"evidence_lane": _evidence_lane,
		"captures": {"planned": _planned_captures.size(), "present": present, "absent": absent,
			"delegated_to": _capture_lane,
			"delegated": _delegated_captures.map(func(r: Variant) -> String:
				return str((r as Dictionary).get("id", ""))),
			"owes": _segment_owes,
			"rows": rows},
		"frames": {"baseline_hz": _record_baseline_hz, "written": _record_written,
			"absent": _record_absent, "absent_reasons": frames_absent_reasons,
			"delegated_windows": _delegated_records},
		"uncommittable": uncommittable,
		"git_check": _git_check,
		"steps": {"total": _step_total, "ran": _step_ran, "refused": _step_refused,
			"pass": int(_verdicts["PASS"]), "fail": int(_verdicts["FAIL"]),
			"skipped": int(_verdicts["SKIP"]),
			"delegated": int(_verdicts.get("DELEGATED", 0))},
		"cost": {"reprices": _reprices, "frame_cost_s": snappedf(_frame_cost_s, 0.000001)},
		# The estimate the gate acted on, and beside it what the segment
		# actually wrote. The second is the input the NEXT pre-flight wants: an
		# estimate is only as good as its per-frame size, and the pre-flight's
		# self-test photographs an empty tree. Measured, not predicted.
		"disk": _disk,
		"disk_actual": _disk_actual(),
		"derails": _derails,
		"harness_errors": _harness_errors,
	}
	_write_json(_out_dir.path_join("INVENTORY.json"), inventory)
	# An unmissable filename for the other half of the split. A logic lane that
	# finished cleanly is COMPLETE for what it owed, and a reader scanning the
	# run directory must still be able to see, without opening anything, that
	# frames are owed elsewhere. `run_inventory.py` is what checks they arrived.
	if _evidence_lane == "logic" \
			and not (_delegated_captures.is_empty() and _delegated_records.is_empty()):
		var owed: Array[String] = []
		for entry: Variant in _delegated_captures:
			owed.append("- %s  (step %s)" % [str((entry as Dictionary).get("id", "")),
				str((entry as Dictionary).get("step", ""))])
		for entry: Variant in _delegated_records:
			var rec := entry as Dictionary
			owed.append("- §H continuous-record window \"%s\" at %.2f Hz  (step %s)" % [
				str(rec.get("label", "")), float(rec.get("hz", 0.0)), str(rec.get("step", ""))])
		_write_text(_out_dir.path_join("DELEGATED.md"),
			("# %s is the LOGIC lane\n\n%d item(s) of evidence are owed by capture lane `%s`, "
			+ "not by this\nsegment. This segment is judged against what its lane owes; the debt "
			+ "itself is\nchecked over the whole run directory by `tools/gate_f/run_inventory.py`, "
			+ "which is\nthe level at which \"does this frame exist anywhere\" can be answered.\n\n%s\n")
			% [_segment_id, _delegated_captures.size() + _delegated_records.size(),
				_capture_lane, "\n".join(owed)])
	# A capture git will never carry is, from the run's point of view, a missing
	# artefact: it lives on a container that gets reclaimed.
	_evidence_missing = absent > 0 or not _blocked.is_empty() or _record_absent > 0 \
		or not uncommittable.is_empty()
	if complete:
		return
	# A second, unmissable marker. A reader scanning a run directory sees the
	# filename before they open anything.
	var lines: Array[String] = ["# %s is INCOMPLETE" % _segment_id, ""]
	if not _blocked.is_empty():
		lines.append("- BLOCKED before step 1: %s" % _blocked)
	for entry: Variant in _derails:
		var derail: Dictionary = entry
		lines.append("- DERAILED at step %s (%s): %s" % [str(derail.get("at", "?")),
			str(derail.get("action", "?")), str(derail.get("why", ""))])
		lines.append("  - %d step(s) skipped; resynced at %s" % [int(derail.get("skipped", 0)),
			str(derail.get("resynced_at", "never -- the segment never recovered"))])
	if _step_refused > 0:
		lines.append("- %d step(s) were REFUSED by the context guard and did not run." % _step_refused)
	if absent > 0:
		lines.append("- %d of %d planned captures are absent from disk." % [absent, _planned_captures.size()])
	if not uncommittable.is_empty():
		lines.append("- %d capture(s) exist on disk and git WILL NOT CARRY THEM:" % uncommittable.size())
		for entry: Variant in uncommittable:
			var row: Dictionary = entry
			lines.append("  - %s  (ignored by %s)" % [str(row.get("file", "")), str(row.get("rule", ""))])
		lines.append("  `git add <dir>` skips these silently and exits 0. Committing this segment "
			+ "would look clean and carry nothing.")
	if _record_absent > 0:
		lines.append("- %d continuous frames were planned and not written: %s"
			% [_record_absent, JSON.stringify(frames_absent_reasons)])
	if _step_ran != _step_total:
		lines.append("- %d of %d steps executed (%d refused, %d skipped)." % [
			_step_ran, _step_total, _step_refused, int(_verdicts["SKIP"])])
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
		# NOT `_step_ran`: the step was refused, not executed. Counting a
		# refusal as a run is how a derailed segment reads as having happened.
		_step_refused += 1
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

	# §H/§G evidence split. On a logic lane a prescribed capture is not skipped,
	# refused or failed -- it is HANDED OVER, to the capture lane this segment
	# named before it started, which the pre-flight has already checked accepts
	# it. The verdict word is its own so it can never be read as either a PASS
	# or a FAIL, and `run_inventory.py` is what turns the handover back into a
	# debt at the level where it can actually be paid.
	# RIG-9, found in this run at S05. `record_hz` is zeroed for a logic lane at
	# segment load, but `record_start` set `_record_hz` from its own args and
	# re-armed the recorder anyway -- so a headless lane spent the window asking
	# for frames it cannot take, wrote 46 `absent` rows, and was marked
	# INCOMPLETE. That is precisely the outcome §H.1 forbids: "A logic-lane
	# segment is judged against what ITS LANE owes, and is not
	# 'capture-incomplete forever' for a frame it never undertook to take."
	# S06-S09 each declare the same two windows and would each have inherited it.
	if _evidence_lane == "logic" and (action == "record_start" or action == "record_stop"):
		var window := str(args.get("label", id))
		if action == "record_start":
			_delegated_records.append({"label": window, "step": id,
				"hz": float(args.get("hz", _cfg["record_window_hz"]))})
			actual = ("DELEGATED the §H record window \"%s\" to capture lane %s "
				+ "(this is the logic lane; it keeps no continuous record)") % [window, _capture_lane]
		else:
			actual = ("DELEGATED the close of the §H record window to capture lane %s "
				+ "(this is the logic lane; no window was opened here)") % _capture_lane
		_verdicts["DELEGATED"] = int(_verdicts.get("DELEGATED", 0)) + 1
		_emit("note", {"expected": expected, "actual": actual,
			"observation": "evidence split: the logic lane keeps no §H continuous record"})
		_note_line("### %s — %s" % [id, str(step.get("title", action))])
		_note_line("- expected: %s" % expected)
		_note_line("- actual: %s" % actual)
		_note_line("- events: t=%.2f" % _play_t())
		_note_line("- verdict: DELEGATED")
		_note_line("")
		return

	if _evidence_lane == "logic" and (action == "capture" or action == "capture_seq"):
		var handed := str(args.get("id", id))
		actual = ("DELEGATED %s to capture lane %s (this is the logic lane; it takes no frames)"
			% [handed, _capture_lane])
		_verdicts["DELEGATED"] = int(_verdicts.get("DELEGATED", 0)) + 1
		_emit("screenshot", {"expected": expected, "actual": actual,
			"observation": "evidence split: the logic lane does not take %s" % handed})
		_note_line("### %s — %s" % [id, str(step.get("title", action))])
		_note_line("- expected: %s" % expected)
		_note_line("- actual: %s" % actual)
		_note_line("- events: t=%.2f" % _play_t())
		_note_line("- verdict: DELEGATED")
		_note_line("")
		return

	match action:
		"boot":
			actual = await _step_boot(args)
		"wait":
			actual = await _step_wait(args)
		"press":
			actual = await _step_press(args, id)
		"fight_until_resolved":
			actual = await _step_fight(args, id)
		"press_multi":
			actual = await _step_press_multi(args, id)
		"press_until":
			actual = await _step_press_until(args, id)
		"chip_to_floor":
			actual = await _step_chip_to_floor(args, id)
		"equip_tool":
			actual = await _step_equip_tool(args, id)
		"throw_until_caught":
			actual = await _step_throw_until_caught(args, id)
		"track_aim":
			actual = await _step_track_aim(args, id)
		"force_aim":
			actual = await _step_force_aim(args, id)
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
		"interact_with":
			actual = await _step_interact_with(args, id)
		"face":
			actual = await _step_face(args)
		"open_menu":
			actual = await _step_open_menu(args, id)
		"close_menu":
			actual = await _step_close_menu(args, id)
		"focus_move":
			actual = await _step_focus_move(args, id)
		"focus_item":
			actual = await _step_focus_item(args, id)
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
		"wait_until":
			var settled := await _step_wait_until(args)
			actual = str(settled.get("actual", ""))
			verdict = "PASS" if bool(settled.get("ok", false)) else "FAIL"
			if bool(settled.get("skip", false)):
				verdict = "SKIP"
		"assert":
			var checked := _step_assert(args)
			actual = str(checked.get("actual", ""))
			verdict = "PASS" if bool(checked.get("ok", false)) else "FAIL"
			if bool(checked.get("skip", false)):
				# The check could not be evaluated in this envelope. `actual`
				# already begins SKIPPED, which the ledger below reads.
				verdict = "SKIP"
		"note":
			actual = str(args.get("text", ""))
		"save_out":
			actual = _step_save_out(args)
		"await_save":
			actual = await _step_await_save(args, id)
		"await_load":
			actual = await _step_await_load(args, id)
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
	if actual.begins_with("SKIPPED"):
		# CD-4: "context not reached" is neither a pass nor a finding, and the
		# f082bdf6 run conflated it with both. 303 of X01's 418 cells were
		# injected in a context other than the one the step named, and the
		# matrix's headline "1085 PASS / 118 FAIL" therefore described mostly
		# nothing.
		verdict = "SKIP"
	if actual.begins_with("BLOCKER"):
		# A step that could not drive the game at all. Distinct from a FAIL,
		# which is a verdict about the GAME: this one says the instrument could
		# not take a reading, and everything after it is taken in an unknown
		# state.
		verdict = "FAIL"
		_derailed = actual
		_derailed_at = id
		_derails.append({"at": id, "action": action, "why": actual,
			"context": str(_probe.call("input_context")), "resynced_at": null, "skipped": 0})
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
	_note_line("- events: t=%.2f" % _play_t())
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
		"await_save":
			return "save"
		"await_load":
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
			if not _derails.is_empty():
				(_derails[-1] as Dictionary)["resynced_at"] = id
			_derailed = ""
			_derailed_at = ""
		else:
			if not _derails.is_empty():
				var last: Dictionary = _derails[-1]
				last["skipped"] = int(last.get("skipped", 0)) + 1
			return {"skip": "SKIPPED: the segment derailed at step %s (%s) and this step declares no "
				% [_derailed_at, _derailed]
				+ "resync point. input_context is '%s' now." % have}

	if required == null or holds:
		return {}
	_derailed = "required context %s, input_context was '%s'" % [JSON.stringify(required), have]
	_derailed_at = id
	_derails.append({"at": id, "action": action, "why": _derailed, "context": have,
		"resynced_at": null, "skipped": 0})
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
## Static: see `_plan_captures`. This is the predicate the whole context guard
## turns on and it is worth testing directly.
static func _context_matches(have: String, want: Variant) -> bool:
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
	# Re-price against THIS scene, every boot, not just the first. A journey
	# segment's first boot is the title screen; the scene it spends its hours in
	# is the one that comes up second.
	var repriced := await _reprice("boot:%s" % which, ms)
	return "booted %s in %.0f ms (%d settle frames)%s" % [which, ms, settle, repriced]


## CD-7, second half: re-price the REMAINDER of the segment against the scene
## it is actually standing in, every time that scene changes.
##
## Round 1 shipped this as a one-shot after the FIRST boot, on the reasoning
## that "the pre-flight's frame cost is measured on an empty tree". That
## reasoning is right and the implementation was still wrong, because **for
## every journey segment the first boot is the title screen**, which is not the
## scene the segment spends its time in either. The run-2 BLOCKER measured all
## three prices on the same box, same segment, same day:
##
##   | when                            | s/frame | S01 predicted |
##   |---------------------------------|---------|---------------|
##   | pre-flight, empty tree          |  0.0065 |          71 s |
##   | re-priced after `boot: title`   |  0.0465 | 505 s  <- used|
##   | measured, in the Meadows        |  6.465  |      70,197 s |
##
## A 139x under-price against the row cadence and 274x against `TIME_PROCESS`.
## At the real price the 14,400 s ceiling buys 2,225 frames and the SMALLEST of
## the eighteen segments asks for 26,835. Every capture-bearing segment should
## have blocked. Two did.
##
## So this now runs after EVERY boot, and the periodic in-play recheck in
## `_tick` runs between them. Three things changed with it:
##
##   1. It prices the frames that are LEFT (`_predict_frames_from`), not the
##      whole segment. Re-charging a segment for a boot it has already paid for
##      would refuse work that is genuinely affordable.
##   2. It measures the budget that is LEFT: the ceiling minus the wall clock
##      already spent. A ceiling is a bound on the run, not on each estimate.
##   3. The disk estimate is re-taken with it, because the frames remaining is
##      the input to both.
func _reprice(reason: String, boot_ms: float = 0.0) -> String:
	if not _cost_gated:
		return ""
	var before := _frame_cost_s
	var now := await _measure_frame_cost()
	# The scene has changed, so the rolling window either side of the change is
	# not one price. Reset it here rather than in each caller: a window that
	# straddles a boot or a load is the whole of CD-7c.
	_cost_window_frames = 0
	_cost_window_usec = 0
	# From the step AFTER this one: the boot's own settle frames are spent, and
	# its real cost is `boot_ms`, added separately. Charging both would price a
	# 240-frame settle twice -- 1,560 s of phantom cost at the price the run-2
	# BLOCKER measured, which is enough to refuse a segment that fits.
	return _apply_price(reason, now, boot_ms, before, true, _step_index + 1)


## The arithmetic half of `_reprice`, split out so the periodic in-play recheck
## can reuse it with a cost it OBSERVED rather than one it stopped to measure.
## `from_index` is the first step still to be paid for. A re-price taken after a
## COMPLETED step passes the next one; the in-play recheck passes the current
## one, because a step half-spent may still spend the rest of its budget.
func _apply_price(reason: String, now: float, boot_ms: float, before: float,
		verbose: bool, from_index: int, observed_raw: float = -1.0) -> String:
	var remaining_frames := _predict_frames_from(_steps, from_index)
	var spent := _wall_t()
	var ceiling := float(_cfg["segment_cost_ceiling_s"])
	var budget := ceiling - spent
	var predicted := (boot_ms / 1000.0) + (float(remaining_frames) * now)
	_frame_cost_s = now
	_predicted_cost_s = spent + predicted
	_predicted_frames = remaining_frames
	var disk := _price_disk(remaining_frames)
	var disk_over_now := bool(disk.get("over", false))
	var record := {
		"at": reason,
		"step_index": _step_index,
		"frame_cost_s": snappedf(now, 0.000001),
		"was_frame_cost_s": snappedf(before, 0.000001),
		"frames_remaining": remaining_frames,
		"wall_spent_s": snappedf(spent, 0.1),
		"budget_remaining_s": snappedf(budget, 0.1),
		"predicted_remaining_s": snappedf(predicted, 0.1),
	}
	# CD-7d: what THIS window actually measured, beside the median the
	# prediction used. A spike must stay visible in the evidence -- smoothing it
	# out of the record would hide a real regression starting.
	if observed_raw >= 0.0:
		record["observed_window_s"] = snappedf(observed_raw, 0.000001)
		record["samples"] = _cost_samples.size()
	# The ledger records a price that MOVED, not a heartbeat. A recheck every
	# 120 frames over a 12,000-frame segment is a hundred rows saying the same
	# 16.6 ms, which buries the two rows that matter -- the boot re-price and
	# the moment the number changed -- and bloats every artefact carrying it.
	# A boot and a refusal are always kept; an in-play sample is kept when it
	# moves the price by more than the logged fraction.
	var material := reason.begins_with("boot") or predicted > budget \
		or bool(disk_over_now) or _reprices.is_empty()
	if not material:
		var last: Dictionary = _reprices[_reprices.size() - 1]
		var was := maxf(1e-9, float(last.get("frame_cost_s", 0.0)))
		material = absf(now - was) / was >= float(_cfg["cost_log_change_fraction"])
	if material:
		_reprices.append(record)
	_cost_rechecks += 1
	_preflight["reprices"] = _reprices
	_preflight["cost_rechecks"] = _cost_rechecks
	_preflight["measured_frame_cost_s_in_scene"] = snappedf(now, 0.000001)
	_preflight["predicted_segment_cost_s_in_scene"] = snappedf(_predicted_cost_s, 0.1)
	if boot_ms > 0.0:
		_preflight["boot_cost_s"] = snappedf(boot_ms / 1000.0, 0.01)
	var line := ("; re-priced at %s: %.4f s/frame (was %.4f), %d frames left + %.0f s boot "
		+ "= %.0f s against %.0f s of budget left") % [reason, now, before, remaining_frames,
			boot_ms / 1000.0, predicted, budget]
	if predicted <= budget and not disk_over_now:
		# A window that came in under budget clears any armed refusal: the
		# spike that armed it was a transient, which is the case this exists
		# to tell apart from a scene that really is unaffordable.
		_cost_over_armed = false
		if verbose:
			_emit("note", {"observation": "cost re-priced%s" % line})
		return line
	# CD-7c, second half. A boot/load re-price STOPS AND MEASURES a settled
	# scene, so it may refuse immediately. The in-play recheck cannot: it
	# divides wall already spent by frames already ticked, so any one-off cost
	# inside its 120-frame window -- a world stand-up, a region streaming in --
	# lands on every frame of that window. S01's own ledger shows the shape: an
	# in-play sample of 0.671 s/frame, then 0.017 s/frame two seconds later. The
	# first number is not a price, it is a construction.
	#
	# So an in-play sample that trips the ceiling ARMS the refusal and the next
	# window decides it. A scene that is genuinely too expensive is still too
	# expensive 120 frames later and still blocks, at a cost of about two
	# seconds of play. A transient disarms itself. Disk is exempt: bytes on
	# disk are not a transient.
	# CD-7d widens CD-7c's arming from one window to a median, because arming
	# alone was not enough: a one-off cost that spans MORE than one 120-frame
	# window -- a fight staging, an arena build -- reads high in two consecutive
	# windows, and the second confirms the first. That is what refused S03 here
	# at step 136 of 406, predicting 5.7 h against a sustained rate its own
	# route.csv puts at 0.0167 s/frame. So a refusal now also requires enough
	# samples for the median to mean anything.
	var too_few_samples := reason == "in-play" \
		and _cost_samples.size() < COST_SAMPLES_BEFORE_REFUSAL
	if predicted > budget and reason == "in-play" and not disk_over_now \
			and (not _cost_over_armed or too_few_samples):
		_cost_over_armed = true
		record["armed"] = ("in-play sample over budget: %.0f s predicted against %.0f s left. "
			+ "Armed, not blocked -- an in-play price is an average over a window and a scene "
			+ "stand-up inside one is a construction, not a per-frame cost. The next window "
			+ "decides.") % [predicted, budget]
		if not material:
			_reprices.append(record)
		return "; " + str(record["armed"])
	if predicted <= budget:
		_cost_over_armed = false

	var why := ""
	if predicted > budget:
		why = ("re-priced at %s, the REST of this segment predicts %.0f s (%.1f h) against %.0f s "
			+ "of the %.0f s ceiling left: %d planned frames at a MEASURED %.3f s/frame in THIS "
			+ "scene, plus a %.0f s boot. The last price was %.4f s/frame. A GPU or a split "
			+ "evidence lane -- not a shorter wait; the waits exist so fights resolve.") % [
				reason, predicted, predicted / 3600.0, budget, ceiling, remaining_frames, now,
				boot_ms / 1000.0, before]
	if disk_over_now:
		var disk_why := str(disk.get("why", ""))
		why = disk_why if why.is_empty() else "%s ALSO: %s" % [why, disk_why]
	record["blocked"] = why
	_derailed = why
	_derailed_at = reason
	_derails.append({"at": reason, "action": "reprice", "why": why,
		"context": str(_probe.call("input_context")), "resynced_at": null, "skipped": 0})
	_emit("defect", {"severity_candidate": "BLOCKER", "actual": why,
		"observation": "CD-7 cost gate tripped at %s" % reason})
	_write_text(_out_dir.path_join("BLOCKER.md"),
		"# BLOCKER — %s is too expensive to finish here\n\n%s\n" % [_segment_id, why])
	_blocked = why
	return "; " + why


## The periodic in-play recheck, called from `_tick`.
##
## It costs nothing: the price it uses is the wall clock the segment has ALREADY
## spent divided by the physics frames it actually ticked, which is the most
## honest number available and the only one that tracks a scene getting more
## expensive as the player walks into it. `_reprice`'s stop-and-measure is for
## the moment a scene CHANGES, where there is no history to read.
func _cost_recheck() -> void:
	if not _cost_gated or not _blocked.is_empty():
		return
	_cost_window_frames += 1
	if _cost_window_usec == 0:
		_cost_window_usec = Time.get_ticks_usec()
		return
	if _cost_window_frames < int(_cfg["cost_recheck_frames"]):
		return
	var elapsed := float(Time.get_ticks_usec() - _cost_window_usec) / 1_000_000.0
	var observed := elapsed / float(_cost_window_frames)
	_cost_window_frames = 0
	_cost_window_usec = Time.get_ticks_usec()
	# CD-7d: predict from the median of recent windows, not from this one. See
	# `_cost_samples`. The raw observation still reaches the ledger through
	# `_apply_price`'s `observed_raw`, so a spike is recorded, not hidden.
	_cost_samples.append(observed)
	while _cost_samples.size() > COST_SAMPLE_WINDOW:
		_cost_samples.remove_at(0)
	_apply_price("in-play", _cost_median(), 0.0, _frame_cost_s, false, _step_index, observed)


## Median of the recent in-play window prices. Median rather than mean because
## one 12x outlier drags a nine-sample mean by more than a third and leaves the
## same refusal in place; it moves a median not at all.
func _cost_median() -> float:
	if _cost_samples.is_empty():
		return _frame_cost_s
	var sorted := _cost_samples.duplicate()
	sorted.sort()
	var n := sorted.size()
	if n % 2 == 1:
		return float(sorted[n / 2])
	return (float(sorted[n / 2 - 1]) + float(sorted[n / 2])) * 0.5


## Frames this segment has still to advance, from `at` onward.
static func _predict_frames_from(steps: Array, at: int) -> int:
	if at <= 0:
		return _predict_frames(steps)
	if at >= steps.size():
		return 0
	return _predict_frames(steps.slice(at))


## What this segment will still WRITE, in bytes, and whether the box has room.
##
## Added 2026-08-28 from the run-2 BLOCKER's third finding: "disk is a ceiling
## nobody has priced". S01 was on course for about 5,400 PNGs -- roughly 10 GB,
## into 23 GB free -- and a second copy into `.git` to be committable at all.
## The eighteen segments were about 25 GB at §H's planned cadences before the
## frame-cost multiplier was applied.
##
## Every input is measured rather than assumed:
##
##   * bytes per PNG comes from the pre-flight self-test, which wrote a real
##     frame of the real scene at the real capture resolution;
##   * free space comes from `df`, asked of the run directory itself;
##   * the doubling for `.git` applies only if the run directory is inside a
##     work tree, which is asked of git.
##
## A process that cannot render writes no frames, so the estimate is zero and
## the gate is silent -- disk is not a reason to refuse a logic lane.
func _price_disk(frames_remaining: int) -> Dictionary:
	var out := {"applies": false}
	if not _capture_available() or not _telemetry_on():
		_disk = out
		return out
	# The self-test is the floor, not the answer: it photographs an empty tree.
	# A real evidence frame, once one exists, is what this segment's frames
	# actually cost.
	var per_png := maxf(float(_preflight.get("png_bytes", 0.0)), float(_evidence_png_bytes))
	if per_png <= 0.0:
		out["why"] = "no measured PNG size (the pre-flight self-test did not write one)"
		_disk = out
		return out
	# Cadence frames are priced in PLAY seconds, because that is what the
	# recorder now counts in. Forced frames are bounded by one per remaining
	# step: §H coalesces every event raised on a tick into a single frame.
	var play_seconds := float(frames_remaining) / float(maxi(1, Engine.physics_ticks_per_second))
	var cadence_frames := int(play_seconds * maxf(_record_hz, _record_baseline_hz))
	var forced_frames := maxi(0, _steps.size() - _step_index)
	var taken := {}
	for entry: Variant in _manifest:
		taken[str((entry as Dictionary).get("id", ""))] = true
	var shots := 0
	for entry: Variant in _planned_captures:
		if not taken.has(str((entry as Dictionary).get("id", ""))):
			shots += 1
	var files := cadence_frames + forced_frames + shots
	var factor := float(_cfg["disk_git_factor"]) if _inside_work_tree() else 1.0
	var bytes := float(files) * per_png * factor
	var free_bytes := _free_bytes(_out_dir)
	var reserve := float(_cfg["disk_reserve_bytes"])
	out = {
		"applies": true,
		"png_bytes": int(per_png),
		"cadence_frames": cadence_frames,
		"forced_frames_upper_bound": forced_frames,
		"shots_remaining": shots,
		"files": files,
		"git_factor": factor,
		"predicted_bytes": int(bytes),
		"free_bytes": int(free_bytes),
		"reserve_bytes": int(reserve),
		"over": false,
	}
	if free_bytes <= 0.0:
		out["why"] = "df could not answer for %s; disk NOT gated" % _out_dir
		_disk = out
		return out
	if bytes > (free_bytes - reserve):
		out["over"] = true
		# What DOMINATES matters more than the total: a segment over budget on
		# cadence frames is telling you to split its evidence lane, and one over
		# budget on prescribed shots is telling you the box is simply full.
		var dominant := "the continuous record (%d cadence frames at %.2f Hz)" % [
			cadence_frames, maxf(_record_hz, _record_baseline_hz)]
		if cadence_frames <= (shots + forced_frames):
			dominant = "%d prescribed shot(s) and up to %d event-forced frame(s)" % [
				shots, forced_frames]
		out["why"] = ("predicted %s of evidence (%d files at a measured %s each, x%.0f for the "
			+ "copy git has to carry), of which the bulk is %s -- against %s free with a %s "
			+ "reserve. A split evidence lane (§H.1), a bigger disk, or fewer segments per "
			+ "container.") % [_bytes_h(bytes), files, _bytes_h(per_png), factor, dominant,
				_bytes_h(free_bytes), _bytes_h(reserve)]
	_disk = out
	return out


## Bytes at a scale a human reads. 84,768 printed as "0.0 GB" is a number that
## tells a reader nothing and reads like a bug in the gate.
static func _bytes_h(n: float) -> String:
	if n >= 1e9:
		return "%.2f GB" % (n / 1e9)
	if n >= 1e6:
		return "%.1f MB" % (n / 1e6)
	if n >= 1e3:
		return "%.0f kB" % (n / 1e3)
	return "%d B" % int(n)


## Free bytes on the filesystem holding `path`, asked of `df`.
##
## Godot has no free-space API. `df -Pk` is POSIX-specified output: one header
## line, then `filesystem 1024-blocks used available capacity mounted-on`.
## Anything unexpected returns 0, which the caller reads as "not gated" rather
## than as "no room" -- a disk check that refused every run it could not measure
## would be this lane's own mistake in mirror image.
func _free_bytes(path: String) -> float:
	if path.is_empty():
		return 0.0
	var output: Array = []
	if OS.execute("df", PackedStringArray(["-Pk", path]), output, true) != 0:
		return 0.0
	var lines := str("" if output.is_empty() else output[0]).split("\n", false)
	if lines.size() < 2:
		return 0.0
	var fields := lines[1].split(" ", false)
	if fields.size() < 4:
		return 0.0
	return float(fields[3]) * 1024.0


func _inside_work_tree() -> bool:
	if _out_dir.is_empty():
		return false
	# Cached: the disk price is re-taken on every cost recheck, and spawning
	# git a few hundred times to re-answer a question whose answer cannot
	# change mid-segment would make the gate cost more than it saves.
	if _work_tree_cached != 0:
		return _work_tree_cached == 1
	var output: Array = []
	var code := OS.execute("git", PackedStringArray(
		["-C", _out_dir, "rev-parse", "--is-inside-work-tree"]), output, true)
	var inside := code == 0 and str("" if output.is_empty() else output[0]).strip_edges() == "true"
	_work_tree_cached = 1 if inside else -1
	return inside


func _step_wait(args: Dictionary) -> String:
	var seconds := float(args.get("seconds", 0.0))
	var frames := int(args.get("frames", 0))
	if seconds > 0.0:
		frames = maxi(frames, int(seconds * float(Engine.physics_ticks_per_second)))
	var done := 0
	for i in frames:
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))
		done += 1
		# The one loop that honours a mid-step cost abort, and the one that
		# needs to: `wait` is where the protocol's hours live. S01-09 asks for
		# 10,800 physics frames, which is 19.4 hours at the price the run-2
		# BLOCKER measured, and a gate that could only act at the NEXT step
		# boundary would watch the whole of it go past. Every other
		# frame-advancing step is bounded by a walk or a press budget and stops
		# at its own boundary, which the step loop then sees.
		if not _blocked.is_empty():
			return "FAIL waited %d of %d physics frames before the cost gate stopped it" % [done, frames]
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


## Fight the fight in front of you until it resolves, by PREDICATE rather than
## by a press count.
##
## GATE-F-LEG-S10AB, 2026-08-31, and the schema's own argument for it is already
## written twice in this file: `advance_dialogue_until_closed` exists because
## "press confirm N times" is right for exactly one conversation, and
## `focus_item` exists because "press right N times" is right for exactly one
## arrangement of the bag. A fight is the same class of problem and a worse one.
## How long it takes depends on the species, both levels, the type chart and a
## +/-10% roll on every hit, and none of that is knowable when the step-script
## is written. Driven by counted presses, S10a's gauntlet came apart three
## different ways on three runs: the presses budgeted for a trainer's three
## creatures were all spent on the FIRST one when the matchup went badly (a
## water pilot against a water defender took 46.8 s to clear a 247 HP creature),
## the switch presses then landed mid-round instead of between rounds, and the
## fights were lost with three untouched creatures on the belt.
##
## What it drives, and what it deliberately does NOT:
##
##   * `combat_quick`, on the down edge, only while the action machine reads
##     READY -- so it never mashes into the commitment guard that
##     `can_switch()` respects, and never buffers an attack the player did not
##     choose.
##   * `party_cycle`, ONCE, when the piloted creature drops to `switch_below`
##     of its max HP and the manager says a switch is possible. This is the
##     verb a five-creature belt exists for, and
##     `encounter_director.gd::_on_trainer_round_ended()` makes it load-bearing:
##     the piloted creature fainting loses the WHOLE battle, however many
##     healthy creatures are behind it.
##   * NOTHING else. No potions, no items, no menu, no granted state. The
##     player's satchel is untouched -- so a fight this step wins is won on
##     levels, types and the belt alone, which is the harder claim and the one
##     worth having.
##
## It stops when the fight is over -- `is_fighting()` false AND
## `trainer_battle_active()` false for `quiet_frames`, because a trainer battle
## goes quiet BETWEEN its creatures and a driver that stopped on the first gap
## would abandon a five-creature Warden after his first one fell -- or when
## `budget_frames` runs out, or when the cost gate stops the run.
func _step_fight(args: Dictionary, step_id: String) -> String:
	var budget := maxi(60, int(args.get("budget_frames", 9000)))
	var switch_below := clampf(float(args.get("switch_below", 0.35)), 0.0, 1.0)
	var gap := maxi(1, int(args.get("gap_frames", 18)))
	var quiet_needed := maxi(30, int(args.get("quiet_frames", 240)))
	var until_flag := str(args.get("until_flag", ""))

	var manager := _probe.call("combat_manager") as Node
	if manager == null:
		return "HARNESS-ERROR fight step %s has no CombatManager in the world" % step_id
	var director := _probe.call("encounter_director") as Node

	var quicks := 0
	var switches := 0
	var refused := 0
	var quiet := 0
	var spent := 0
	var ended := ""

	while spent < budget:
		if not _blocked.is_empty():
			return "FAIL fought %d frames before the cost gate stopped it" % spent
		if until_flag != "" and (_probe.call("flags") as Array).has(until_flag):
			ended = "flag '%s' set" % until_flag
			break

		var fighting := bool(manager.call("is_fighting"))
		var battle := director != null and bool(director.call("trainer_battle_active"))
		if not fighting and not battle:
			quiet += 1
			if quiet >= quiet_needed:
				ended = "no fight running for %d frames" % quiet
				break
			await physics_frame
			_tick(1.0 / float(Engine.physics_ticks_per_second))
			spent += 1
			continue
		quiet = 0

		if not fighting:
			# Between a trainer's creatures. Wait it out rather than pressing
			# into the send-out beat.
			await physics_frame
			_tick(1.0 / float(Engine.physics_ticks_per_second))
			spent += 1
			continue

		var state: Dictionary = _probe.call("combat_state")
		if str(state.get("phase", "")) != "ready":
			await physics_frame
			_tick(1.0 / float(Engine.physics_ticks_per_second))
			spent += 1
			continue

		var mine: Variant = manager.call("active_creature")
		var max_hp := float(mine.get("max_hp")) if mine != null else 0.0
		var frac := (float(mine.get("hp")) / max_hp) if (mine != null and max_hp > 0.0) else 1.0
		var wants_switch := frac <= switch_below \
			and bool(manager.call("can_switch")) \
			and not (manager.call("switchable_indices") as Array).is_empty()

		if wants_switch:
			var was: String = str(mine.call("label"))
			var sent := await _inject("party_cycle", HOLD_TAP)
			if not bool(sent.get("ok", false)):
				return "HARNESS-ERROR %s" % str(sent.get("why", "party_cycle injection failed"))
			var now: Variant = manager.call("active_creature")
			if now != null and now != mine:
				switches += 1
				_emit("combat_switch", {"observation":
					"fight step %s handed over: %s (%.0f%% hp) -> %s" % [
						step_id, was, frac * 100.0, str(now.call("label"))]})
			else:
				# Recorded, not retried in a tight loop: a refusal is a real
				# property of the fight (`can_switch()` said yes and the swap
				# still did not happen) and is worth a line rather than a spin.
				refused += 1
		else:
			var sent2 := await _inject("combat_quick", HOLD_TAP)
			if not bool(sent2.get("ok", false)):
				return "HARNESS-ERROR %s" % str(sent2.get("why", "combat_quick injection failed"))
			quicks += 1

		# `_inject` advances its own frames (two idle, two physics for a tap);
		# charge them flat, then idle the gap.
		spent += 3
		for f in gap:
			await physics_frame
			_tick(1.0 / float(Engine.physics_ticks_per_second))
			spent += 1

	if ended.is_empty():
		ended = "budget of %d frames exhausted with the fight still running" % budget
	var flag_note := ""
	if until_flag != "":
		flag_note = ", %s '%s'" % [
			"SET" if (_probe.call("flags") as Array).has(until_flag) else "NOT SET", until_flag]
	var line := "fought %d frames: %d quick, %d handover(s), %d refused switch(es); ended because %s%s" % [
		spent, quicks, switches, refused, ended, flag_note]
	_emit("note", {"observation": "fight step %s: %s" % [step_id, line]})
	if until_flag != "" and not (_probe.call("flags") as Array).has(until_flag):
		return "FAIL " + line
	return line


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
	var skip_if: Dictionary = args.get("skip_if", {}) as Dictionary
	if not skip_if.is_empty():
		var moot := _step_assert(skip_if)
		if bool(moot.get("ok", false)):
			return "SKIPPED move_to_entity: not needed (%s)" % str(moot.get("actual", ""))
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
	# CD-5: an entity has a height. Overridable, because a walk to a landmark's
	# marker legitimately does not care.
	walk["close_3d"] = bool(args.get("close_3d", true))
	return await _walk_loop(walk, func() -> Dictionary:
		if node == null or not is_instance_valid(node) or not node.is_inside_tree():
			return {"ok": false, "why": "%s left the tree mid-walk" % what}
		return {"ok": true, "at": Vector2(node.global_position.x, node.global_position.z),
			"y": node.global_position.y, "what": what})


## Find one live entity by identity.
##
## Six forms, tried in order:
##
##   `poi:<kind>`   -- `poi:gather`, `poi:wild`, `poi:rest`, `poi:trainer`,
##                     `poi:landmark`, `poi:tm`, `poi:key`. Classified by
##                     `gate_f_probe.gd::_poi_kind`, the same script-path table
##                     the dead-travel meter uses. This is the form a journey
##                     step usually wants: a harvest node has no name worth
##                     writing down, and there are hundreds of them.
##   `<name>.gd`    -- anything running that script.
##   exact node name, group membership, a matching `label()`, a matching
##   `species_id`, then a unique case-insensitive substring of a node name.
##
## Several matches picks the nearest to the player and SAYS so, with the count
## and the candidates -- a walk that silently picked the first of four Grazers
## is a walk whose evidence nobody can check. `nearest: false` makes ambiguity
## a FAIL instead.
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
	var by_kind: Array[Node3D] = []
	var by_script: Array[Node3D] = []
	var lowered := spec.to_lower()
	# `poi:<kind>` and `<script>.gd` exist because the things a journey step
	# most often means -- a harvest node, a wild creature, a camp -- have no
	# name worth writing down. `gate_f_probe.gd` already classifies them by
	# script path for the dead-travel meter, and `_poi_kind` is asked here
	# rather than reimplemented: a second copy of that table is a second answer
	# to "is this a point of interest".
	var want_kind := spec.substr(4).to_lower() if lowered.begins_with("poi:") else ""
	for node in all:
		if not want_kind.is_empty():
			if str(_probe.call("_poi_kind", node)).to_lower() == want_kind:
				by_kind.append(node)
			continue
		if lowered.ends_with(".gd"):
			var script: Script = node.get_script()
			if script != null and str(script.resource_path).to_lower().ends_with(lowered):
				by_script.append(node)
			continue
		if str(node.name) == spec:
			by_name.append(node)
		if node.is_in_group(StringName(spec)):
			by_group.append(node)
		if node.has_method("label") and str(node.call("label")).to_lower() == lowered:
			by_label.append(node)
		# species_id is shared by wild bodies (wild_creature.gd) AND the
		# player's own deployed party creature (follower_creature.gd,
		# node name "AllyCreature") -- a caught Bramblebun walking behind the
		# trainer answers to species_id "bramblebun" exactly like a wild one.
		# Unfiltered, a ladder that walks to "a live bramblebun" ten times
		# started resolving its OWN ally instead of a wild target the moment
		# the first Bramblebun was caught and deployed -- the ally is always
		# close, so it kept winning `rank 0`, `move_to_entity` "arrived" at
		# it in ~0 m, and `interact_with` FAILed on "Put Bramblebun away" /
		# "Bramblebun is out of the fight" instead of "Engage" (S03 attempt 7
		# §4, attempts b/d/g/j). Restricted to `_poi_kind == "wild"` so a
		# species match can only ever mean a wild creature, the same
		# classification `poi:wild` already uses.
		var species: Variant = node.get("species_id")
		if species != null and str(species).to_lower() == lowered \
				and str(_probe.call("_poi_kind", node)).to_lower() == "wild":
			by_species.append(node)
		if str(node.name).to_lower().contains(lowered):
			by_substring.append(node)
	for pair: Array in [[by_kind, "poi kind"], [by_script, "script path"], [by_name, "node name"],
			[by_group, "group"], [by_label, "label()"], [by_species, "species_id"],
			[by_substring, "name substring"]]:
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
		#
		# `rank` (RIG-F4, ralph/GATE-F-FULL 2026-08-30) picks the Nth-nearest
		# instead of the nearest, and it exists because a RETRY LADDER THAT
		# ALWAYS RESOLVES THE SAME THING IS NOT A RETRY LADDER. S03's engage
		# ladder walks to "a live bramblebun" ten times; every attempt resolved
		# the same nearest creature, the walker reported "walked 0.0 m" because
		# the player was already inside `within`, and all ten attempts pressed
		# from the identical spot and lost the interaction arbiter to the same
		# deadwood node at (26,-44) -- ten identical failures over 180 s of
		# play, and a team that never reached three. Varying the rank makes each
		# attempt a genuinely different attempt.
		#
		# Out-of-range ranks CLAMP rather than fail, and the note says the rank
		# was clamped: a ladder authored for five candidates must not blow up in
		# a boot that spawned three.
		var player := _probe.call("player") as Node3D
		var ordered: Array[Node3D] = hits.duplicate()
		if player != null:
			var origin := player.global_position
			ordered.sort_custom(func(a: Node3D, b: Node3D) -> bool:
				return origin.distance_to(a.global_position) < origin.distance_to(b.global_position))
		var rank := clampi(int(args.get("rank", 0)), 0, ordered.size() - 1)
		var asked := int(args.get("rank", 0))
		var how := "%s, nearest of %d (%s)" % [str(pair[1]), hits.size(), _names_of(hits)]
		if asked != 0:
			how = "%s, #%d nearest of %d%s (%s)" % [str(pair[1]), rank + 1, hits.size(),
				"" if rank == asked else " [rank %d clamped to %d]" % [asked, rank],
				_names_of(hits)]
		return {"ok": true, "node": ordered[rank], "how": how}
	var how := "of point-of-interest kind" if not want_kind.is_empty() \
		else ("running the script" if lowered.ends_with(".gd") \
		else "named, grouped, labelled or speciesed")
	return {"ok": false, "why": "no node %s '%s' among the %d Node3Ds in %s"
		% [how, spec, all.size(), scene.name]}


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
	# CD-5. Arrival is a 3D question when the target is a THING.
	#
	# `move_to` compares x and z only, and the operator diagnosed the cost of
	# that himself: Grandpa's bed is 0.89 m from him in plan view and 3.3 m
	# above him, so S02-15 "arrived", pressed `interact` 31 times through the
	# floor, and recorded 31 findings about an interaction that was never in
	# range. Steering stays flat -- you walk in x/z -- but arriving does not.
	var close_3d := bool(args.get("close_3d", false))
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
	# RIG-F5 correction (Fable, 2026-09-02): a flat arrival with a small
	# vertical gap (a slope, a curb, a step up to a node) is a walk that has
	# not finished climbing, not an unreachable target -- failing on it
	# immediately is what turned ordinary gather-node terrain into FAILs
	# after the VP terrain change. Track whether the 3D gap is still
	# shrinking; only give up when it stops.
	var close_3d_best_solid := INF
	var close_3d_stall_frames := 0
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
		if aim.has("y"):
			# An entity knows where it is vertically; the terrain query does
			# not know it is standing on a bed frame, on a deck, or in a tree.
			target.y = float(aim["y"])
		elif world != null and world.has_method("ground_height_at"):
			target.y = float(world.call("ground_height_at", target.x, target.z))
		var to := target - player.global_position
		to.y = 0.0
		if to.length() <= close:
			if not close_3d:
				arrived = true
				break
			var solid := player.global_position.distance_to(target)
			if solid <= close:
				arrived = true
				break
			var vertical := absf(target.y - player.global_position.y)
			if vertical >= close:
				# The gap is vertical alone -- directly under (or over) the
				# target and unable to close it by walking, no matter how
				# long this loop runs. Reported as the vertical fact it is,
				# rather than as an arrival: this is the exact shape that
				# produced 31 interacts through a floor.
				_stick_left = Vector2.ZERO
				_drive_sticks()
				await physics_frame
				return ("FAIL reached %s in plan view (%.2f m in x/z) but it is %.2f m away in 3D -- "
					+ "%.2f m of that is vertical, which alone is at or past the %.2f m tolerance. "
					+ "Walking cannot close it, and an `interact` from here would press through "
					+ "the floor.") % [what, to.length(), solid, vertical, close]
			# Small vertical gap: keep walking rather than failing on the
			# flat distance alone. Fail only once the 3D gap stops shrinking
			# (stalled, not merely not-yet-arrived) while genuinely close
			# flat, which means the remaining gap is not something walking
			# is going to fix.
			elif solid < close_3d_best_solid - 0.02:
				close_3d_best_solid = solid
				close_3d_stall_frames = 0
			else:
				close_3d_stall_frames += 1
				if close_3d_stall_frames > 90 and to.length() < 0.8:
					_stick_left = Vector2.ZERO
					_drive_sticks()
					await physics_frame
					return ("FAIL stalled %.2f m away (3D) from %s -- %.2f m flat, %.2f m vertical -- "
						+ "and not closing after %d frames of walking. The remaining gap is not one "
						+ "walking is fixing.") % [solid, what, to.length(), vertical,
							close_3d_stall_frames]
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
			if answer and held % 20 == 0 and held_by == "narrative_modal":
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
				#
				# `held_by == "narrative_modal"` (added 2026-09-02): held used to
				# be enough on its own, and that pressed blind into ANY reason
				# locomotion was disabled -- including a wild creature standing
				# close enough to win `interaction_arbiter.gd`'s priority
				# contest with its own live "Engage <creature>" prompt, which
				# this then pressed, starting a real unplanned fight a travel
				# script has no way to resolve. Measured directly: a gather
				# ladder's second-swing press got the same `optional:true`
				# guard for the identical reason: press only what you meant to
				# press. Narrowed to the one input_context this mechanism was
				# actually written for -- a held walk blocked by anything else
				# (combat, a fade, a creature physically in the way) now just
				# waits, the same as `answer_prompts:false` already does for it.
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


## CD-5: press `interact` only when there is something to interact WITH.
##
## `interaction_arbiter.gd` is the one place `interact` is read outside combat.
## It publishes a prompt when a provider is in range and clears it when one is
## not, and `prompt()`, `winner()` and `winning_provider()` are already public.
## So "is this press going to do anything?" is a question with an answer, and
## the harness has been pressing without asking it.
##
## The cost of not asking is on the record: S02-15 pressed `interact` 31 times
## through a floor, and S02-32 pressed it once at a walked-to coordinate where
## the chapter's first wild fight was supposed to stage -- S02-34 then measured
## `input_context=world` and the whole rest of the segment ran without a fight
## having happened.
##
## A press with no live prompt is a FAIL that says so, and names what the
## arbiter could see instead. That is a finding about reach, which is what it
## always was.
func _step_interact_with(args: Dictionary, step_id: String) -> String:
	var skip_if: Dictionary = args.get("skip_if", {}) as Dictionary
	if not skip_if.is_empty():
		var moot := _step_assert(skip_if)
		if bool(moot.get("ok", false)):
			return "SKIPPED interact_with: not needed (%s)" % str(moot.get("actual", ""))
	# `optional`: this press is legitimately a maybe, and the three reasons
	# below not to press are not failures of it -- they are SKIPS. Written for
	# a harvest node's second swing: the node (and its prompt) may already be
	# gone after a good first hit, which is fine and is not what this guards.
	# What it actually guards, found live on a run that reached one: a wild
	# creature can wander up to a node WHILE it is being worked and win the
	# arbiter's priority-then-nearest contest over the node's own prompt
	# before the second tap lands. A plain, unconditional press there does not
	# know the difference and presses "Engage <creature>" instead of the
	# node -- starting a real, unplanned wild fight the rest of this ladder
	# has no script to resolve, which then FAILs every following step for as
	# long as the world stays in combat. `optional` makes every one of those
	# three conditions a SKIP instead of a press: no live prompt, the wrong
	# live prompt, or the arbiter disabled outright.
	var optional := bool(args.get("optional", false))
	var arbiter := _probe.call("interaction_arbiter") as Node
	if arbiter == null:
		return "HARNESS-ERROR interact_with step %s: no live InteractionArbiter" % step_id
	if arbiter.has_method("enabled") and not bool(arbiter.call("enabled")):
		if optional:
			return ("SKIPPED interact_with (optional): the interaction arbiter is DISABLED "
				+ "(input_context '%s') -- not pressed, to avoid pressing into whatever owns "
				+ "input instead.") % str(_probe.call("input_context"))
		return ("FAIL the interaction arbiter is DISABLED -- a conversation, a naming prompt or "
			+ "a fight owns the screen (input_context '%s'). No prompt is offered here and "
			+ "`interact` would go to whatever does own input.") % str(_probe.call("input_context"))
	var prompt := str(arbiter.call("prompt")) if arbiter.has_method("prompt") else ""
	var spec := str(args.get("entity", ""))
	var player := _probe.call("player") as Node3D
	if prompt.is_empty():
		if optional:
			return "SKIPPED interact_with (optional): no interact prompt is live -- not pressed"
		var nearest := ""
		if not spec.is_empty():
			var found := _find_entity(spec, args)
			if bool(found.get("ok", false)) and player != null:
				var node: Node3D = found["node"]
				nearest = " The nearest '%s' is %.2f m away in 3D (%.2f m in x/z, %.2f m vertical)." % [
					spec, player.global_position.distance_to(node.global_position),
					Vector2(player.global_position.x - node.global_position.x,
						player.global_position.z - node.global_position.z).length(),
					absf(player.global_position.y - node.global_position.y)]
			else:
				nearest = " '%s' could not be found in the world at all." % spec
		return ("FAIL no interact prompt is live, so `interact` was NOT pressed: there is nothing "
			+ "here to interact with.%s") % nearest
	# The prompt is live. Is it the RIGHT one? A prompt from the wrong provider
	# is how a step that meant to talk to Grandpa opens a chest instead, and it
	# reads in the notes as a successful interaction either way.
	var want_text := str(args.get("expect_prompt", ""))
	if not want_text.is_empty() and not prompt.to_lower().contains(want_text.to_lower()):
		if optional:
			return ("SKIPPED interact_with (optional): the live prompt is \"%s\", not \"%s\" -- "
				+ "not pressed, to avoid activating a different provider.") % [prompt, want_text]
		return ("FAIL the live prompt is \"%s\", which does not contain \"%s\" -- pressing here "
			+ "would activate a different provider. Not pressed.") % [prompt, want_text]
	var provider: Object = arbiter.call("winning_provider") if arbiter.has_method("winning_provider") else null
	var provider_name := "?" if provider == null else str((provider as Node).name if provider is Node else provider)
	if not spec.is_empty() and bool(args.get("check_provider", true)):
		var found2 := _find_entity(spec, args)
		if bool(found2.get("ok", false)) and provider is Node:
			var node2: Node3D = found2["node"]
			var owner_node := provider as Node
			# The provider is usually a prompt child of the entity rather than
			# the entity itself, so relatedness -- not identity -- is the test.
			var related := owner_node == node2 or node2.is_ancestor_of(owner_node) \
				or owner_node.is_ancestor_of(node2)
			if not related:
				return ("FAIL the live prompt \"%s\" belongs to '%s', which is not '%s' nor part "
					+ "of it. Not pressed: this press would have activated the wrong thing.") % [
						prompt, provider_name, spec]
	var before := _cell_snapshot()
	# Not every live prompt answers to `interact` -- `encounter_director.gd`'s
	# "Put <creature> away" is bound to `creature_recall`, not `interact`
	# (CONTROLLER-MAP: "Fleeing is RB. Putting the creature away IS
	# disengaging."), and pressing the wrong control here would silently do
	# nothing while every check above still said the right prompt was live.
	# `control` defaults to `interact` -- the verb this action is named and
	# documented for -- and is only overridden by a step that means to press
	# something else at a verified, specific prompt.
	var sent := await _inject(str(args.get("control", "interact")), _hold_frames(args.get("hold", "tap")))
	if not bool(sent.get("ok", false)):
		return "HARNESS-ERROR %s" % str(sent.get("why", ""))
	for i in maxi(2, int(args.get("settle_frames", 20))):
		await process_frame
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))
	var after := _cell_snapshot()
	var pressed_control := str(args.get("control", "interact"))
	var changed := _describe_delta(before, after, ["context", "focus_text", "inventory",
		"pending_build", "party_size", "flags", "active_creature"])
	if changed == "none":
		if not bool(args.get("expect_change", true)):
			# An acknowledged no-op. Requires the step to say so in advance, so
			# a press that quietly did nothing can never be read as one that
			# was expected to: the default is FAIL, and this is the exception
			# an operator writes down before playing.
			return ("pressed `%s` on \"%s\" (provider '%s') and nothing observable changed "
				+ "-- the step declared expect_change:false") % [pressed_control, prompt, provider_name]
		return ("FAIL pressed `%s` with the prompt \"%s\" live (provider '%s') and nothing "
			+ "changed: no context, focus, satchel, build, party or flag moved.") % [
				pressed_control, prompt, provider_name]
	return "pressed `%s` on \"%s\" (provider '%s'): %s" % [pressed_control, prompt, provider_name, changed]


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
## RIG-F2 — press an action until the world says the press landed.
##
## The primitive the Gate F audit named as missing and could not write mid-run:
## *"the correct rig fix is 'press until the context is `combat_aim`', and the
## step vocabulary has no press-until-predicate action -- `wait_until` waits, it
## does not act."*
##
## Why it is needed, from measured evidence rather than from theory. `interact`
## TOGGLES the catch aim, and every catch block in S02/S03 was written as a
## fixed pattern -- "aim" as `interact` x2, then "throw" as `interact` x1. That
## pattern lands on a different PARITY depending on whether the aim happened to
## be armed when the block started, so it arms-and-disarms and throws nothing.
## This lane measured one `catch_throw` out of four throw blocks in S02, and the
## cost is not just the missed throws: the segment stands still through four
## six-second waits while the opponent keeps attacking, which is what actually
## fainted the starter and left the handoff save with a party of one.
##
## This is CD-3's rule ("no step may encode a guessed repetition count for a
## state-changing UI; reach a state, then assert it") applied to a PRESS. The
## predicate vocabulary is `_step_assert`'s own, so a check that works in an
## `assert` works here and there is no second implementation to drift.
##
## Contract: PASSes the instant the predicate holds, reporting how many presses
## that took -- including ZERO, when the world was already in the wanted state,
## which is the case the fixed pattern got wrong. FAILs at `max_presses` naming
## the last thing it saw. A predicate this envelope cannot evaluate is a SKIP
## rather than a press storm.
func _step_press_until(args: Dictionary, step_id: String) -> String:
	var control := str(args.get("control", ""))
	if control.is_empty():
		return "HARNESS-ERROR press_until step %s: no control named" % step_id
	var check: Dictionary = args.get("check", {}) as Dictionary
	if check.is_empty():
		return "HARNESS-ERROR press_until step %s: no check named" % step_id
	var budget := maxi(1, int(args.get("max_presses", 4)))
	var settle := maxi(1, int(args.get("settle_frames", 20)))
	var hold := _hold_frames(args.get("hold", "tap"))

	# CD-4's rule ("a cell whose context assert fails is SKIPPED, never PASS and
	# never FAIL -- those are different facts"), applied to a retry ladder. A
	# catch ladder runs four throw blocks so that a real, non-buggy miss can be
	# retried; the blocks AFTER a successful catch have nothing to press at, and
	# reporting those as FAIL files a defect against a segment that did exactly
	# what it was supposed to. `skip_if` names the state in which this step is
	# moot -- combat no longer running, say -- and is checked before any press.
	var skip_if: Dictionary = args.get("skip_if", {}) as Dictionary
	if not skip_if.is_empty():
		var moot := _step_assert(skip_if)
		if bool(moot.get("ok", false)):
			return "SKIPPED press_until: not needed (%s)" % str(moot.get("actual", ""))

	var first := _step_assert(check)
	if bool(first.get("skip", false)):
		return "SKIPPED press_until: %s" % str(first.get("actual", ""))
	if bool(first.get("ok", false)):
		return "already true before any press (%s), 0 x %s sent" % [
			str(first.get("actual", "")), control]

	var last := str(first.get("actual", ""))
	for attempt in budget:
		var sent := await _inject(control, hold)
		if not bool(sent.get("ok", false)):
			return "HARNESS-ERROR %s" % str(sent.get("why", ""))
		for i in settle:
			await physics_frame
		var now := _step_assert(check)
		last = str(now.get("actual", ""))
		if bool(now.get("ok", false)):
			return "%d x %s reached it: %s" % [attempt + 1, control, last]
	return "FAIL %d x %s did not reach it; last saw %s" % [budget, control, last]


## Equip a named tool by its own hotbar slot, verified and retried -- never a
## blind press.
##
## Fable's diagnosis (2026-09-02, `FINDING-S03-POSTMERGE-TERRAIN-VARIANCE-
## 2026-09-02.md`'s correction): S03's gather ladder pressed `hotbar_N` blind
## before every node, no verification, and it silently failed roughly a
## third of the time. Two real reasons, both invisible to a bare `press`:
## (1) the SAME slot's button TOGGLES -- pressing the currently-equipped
## tool's own slot un-equips it rather than re-equipping it, which is
## harmless here because this step never presses a slot that already holds
## the wanted tool; (2) a press landing while a swing from the PREVIOUS
## gather is still resolving (`tool_hold.gd`) is dropped outright, not
## queued -- correlating every equip press in a real run against
## `equipped.item` showed exactly this shape, presses that took immediately
## after `harvest_logic.gd`'s own gather animation and presses that silently
## missed while one was still finishing. `harvest_node.gd` then correctly
## REFUSES a wrong-tool gather ("Needs a Knife.") -- the old script read
## that refusal as a reach problem because nothing ever checked what tool
## was actually in hand.
##
## Contract: no-ops (0 presses) if the tool is already equipped. Otherwise
## presses `control`, settles (long enough for an in-flight swing to
## finish), and checks `equipped().item`; retries up to `max_attempts`
## (default 3) before FAILing loud with what is actually equipped instead
## of what was wanted.
func _step_equip_tool(args: Dictionary, step_id: String) -> String:
	var tool := str(args.get("tool", ""))
	if tool.is_empty():
		return "HARNESS-ERROR equip_tool step %s needs tool" % step_id
	var max_attempts := maxi(1, int(args.get("max_attempts", 3)))
	var settle := maxi(1, int(args.get("settle_frames", 60)))

	var have := str((_probe.call("equipped") as Dictionary).get("item", ""))
	if have == tool:
		return "already equipped (%s)" % tool

	# Live-read the slot, same reason `focus_item` reads the satchel cursor
	# live instead of trusting a fixed offset: a step script's `control`
	# argument is a claim about where an earlier assign sequence PUT the
	# tool, and that claim goes stale. Measured directly on this run:
	# `hotbar_4` held 'pickaxe', not the knife the SAME assign sequence put
	# there in an earlier run and two independent probes confirmed -- the
	# "if a future run's save ever again shows the knife somewhere else"
	# case the previous ground-truth note asked to be watched for. A
	# `control` argument, if the step script still carries one from before
	# this fix, is accepted but ignored: it is no longer authoritative.
	var slot := int(_probe.call("hotbar_slot_of", tool))
	if slot < 0:
		return ("FAIL equip_tool: '%s' is not on the hotbar at all (checked live via "
			+ "hotbar_slot_of, not a fixed slot guess) -- the assign step never bound it, "
			+ "or something since removed it from the bar.") % tool
	var control := "hotbar_%d" % (slot + 1)

	for attempt in max_attempts:
		var sent := await _inject(control, _hold_frames("tap"))
		if not bool(sent.get("ok", false)):
			return "HARNESS-ERROR %s" % str(sent.get("why", ""))
		for i in settle:
			await physics_frame
		have = str((_probe.call("equipped") as Dictionary).get("item", ""))
		if have == tool:
			return "%d x %s (live slot %d): equipped %s" % [attempt + 1, control, slot, tool]
		# The slot can itself have moved between attempts (another gather, a
		# bag change) -- re-read it rather than hammering a control that may
		# no longer be the right one.
		var reslot := int(_probe.call("hotbar_slot_of", tool))
		if reslot != slot and reslot >= 0:
			slot = reslot
			control = "hotbar_%d" % (slot + 1)
	return "FAIL equip_tool: wanted %s, holding '%s' after %d press(es) (last tried %s, live slot %d)" % [
		tool, have, max_attempts, control, slot]


## Chip a live wild target down to as close to zero HP as the fight will
## actually bear, WITHOUT a fixed hit count or a fixed HP-fraction floor
## guessed in advance.
##
## S03's catch ladder first used a blind `times: 3` (real defect: `times: 20`
## had killed the target outright once, `fainted` and uncatchable), then a
## fixed `enemy_hp_fraction at_most: 0.3` press_until -- both leave a real,
## computable amount of catching.json's own reward curve on the table,
## because neither one asks how much damage THIS fight's quick attack is
## actually dealing before deciding when to stop. It can be asked:
## `combat_math.gd::rolled_damage()`'s only per-swing randomness against a
## fixed target is `variance` (+/-10% of the roll) -- `type_mult`/`power`/
## attack/defence are the SAME for every quick attack this creature throws at
## this target, so the first hit already reveals, within +/-10%, what every
## later one will cost. This step learns that from the fight itself: after
## each swing it records the actual damage dealt, and refuses to throw the
## NEXT swing only once the target's remaining HP would not survive the
## LARGEST hit seen so far scaled up by `safety_factor` (default 1.25,
## comfortably past the 1.1/0.9 = 1.222 worst-case roll-to-roll swing) --
## which is the same arithmetic a player would do in their head: "that hit
## took 13, I have 16 left, one more could take 14.3, still safe; a fourth
## could not." `floor_fraction` (default 0.01, i.e. 1% of max HP) is a small
## absolute cushion on top of that prediction, against float rounding and
## anything this model has not accounted for -- never the primary guard.
func _step_chip_to_floor(args: Dictionary, step_id: String) -> String:
	var control := str(args.get("control", "combat_quick"))
	var hold := _hold_frames(args.get("hold", "tap"))
	var settle := maxi(1, int(args.get("settle_frames", 30)))
	var budget := maxi(1, int(args.get("max_presses", 15)))
	var safety := float(args.get("safety_factor", 1.25))
	var floor_frac := float(args.get("floor_fraction", 0.01))

	var skip_if: Dictionary = args.get("skip_if", {}) as Dictionary
	if not skip_if.is_empty():
		var moot := _step_assert(skip_if)
		if bool(moot.get("ok", false)):
			return "SKIPPED chip_to_floor: not needed (%s)" % str(moot.get("actual", ""))

	var mgr := _probe.call("combat_manager") as Node
	if mgr == null or not mgr.has_method("enemy"):
		return "HARNESS-ERROR chip_to_floor step %s has no CombatManager" % step_id
	var foe: RefCounted = mgr.call("enemy")
	if foe == null:
		return "FAIL chip_to_floor: no live enemy to chip"
	var max_hp := float(foe.get("max_hp"))
	if max_hp <= 0.0:
		return "FAIL chip_to_floor: enemy max_hp is %.1f, cannot compute a floor" % max_hp
	var floor_hp := max_hp * floor_frac

	var hp := float(foe.get("hp"))
	var max_hit := 0.0
	var presses := 0
	var hits: Array[String] = []
	for attempt in budget:
		# The predictive stop: only reached once at least one real hit has
		# been observed. The very first swing always goes in blind -- there
		# is no data yet, and a single hit has never come close to fainting
		# a fresh, healthy practice-cluster target in any run measured so far.
		if max_hit > 0.0 and hp - max_hit * safety <= floor_hp:
			break
		if not is_instance_valid(foe):
			return "FAIL chip_to_floor: enemy left the fight after %d press(es) (hits: %s)" % [
				presses, ", ".join(hits)]
		var sent := await _inject(control, hold)
		if not bool(sent.get("ok", false)):
			return "HARNESS-ERROR %s" % str(sent.get("why", ""))
		for i in settle:
			await physics_frame
		if not is_instance_valid(foe):
			return "FAIL chip_to_floor: enemy left the fight mid-swing after %d press(es) (hits: %s)" % [
				presses, ", ".join(hits)]
		var now := float(foe.get("hp"))
		var dealt := hp - now
		if dealt > max_hit:
			max_hit = dealt
		hp = now
		presses += 1
		hits.append("%.1f" % dealt)
		if bool(foe.get("fainted")) or hp <= 0.0:
			return ("FAIL chip_to_floor: target fainted after %d press(es) (hits: %s) -- " +
				"safety_factor %.2f was not enough margin against this target, widen it") % [
					presses, ", ".join(hits), safety]

	return "%d x %s: enemy hp %.1f/%.1f (%.1f%%), hits dealt [%s], largest %.1f" % [
		presses, control, hp, max_hp, 100.0 * hp / max_hp, ", ".join(hits), max_hit]


## Aim, throw, and if it misses, DO IT AGAIN -- against the same chipped-down
## target, in the same fight -- instead of walking away after one orb.
##
## Owner directive, this session: "we should chip down then throw orbs til we
## catch." A single scripted throw per numbered attempt was leaving real
## catch chances on the table for a reason that has nothing to do with the
## catch roll: `catching.json`'s own `throw.cooldown` (0.9s, "stops a failed
## catch from being instantly re-thrown while the wobble is still on
## screen") and `combat_manager.gd::_finish_catch()`'s failure branch
## (`_wild.call("set_engaged", true, _ally_body)`, no fight-ending) both say
## outright that a missed throw is meant to be followed by another one in the
## SAME encounter -- a real player does not lose access to their target
## because one orb bounced off. This step re-arms the aim
## (`press_until input_context == combat_aim`, idempotent the same way
## `press_until` always is), re-tracks the live target (`track_aim`, since
## it keeps walking through the wait), throws, and waits for the verdict --
## repeating up to `max_throws` times, stopping the INSTANT the party grows
## (caught) or the fight ends some other way (fled, or `is_fighting()` goes
## false). Bounded, not unconditional: `max_throws` (default 4) keeps one
## stubborn target from spending the whole trip's orb supply, the same
## reasoning `chip_to_floor`'s own `max_presses` cap uses.
func _step_throw_until_caught(args: Dictionary, step_id: String) -> String:
	var skip_if: Dictionary = args.get("skip_if", {}) as Dictionary
	if not skip_if.is_empty():
		var moot := _step_assert(skip_if)
		if bool(moot.get("ok", false)):
			return "SKIPPED throw_until_caught: not needed (%s)" % str(moot.get("actual", ""))

	var mgr := _probe.call("combat_manager") as Node
	if mgr == null or not mgr.has_method("is_fighting"):
		return "HARNESS-ERROR throw_until_caught step %s has no CombatManager" % step_id
	var max_throws := maxi(1, int(args.get("max_throws", 4)))
	var aim_budget := int(args.get("aim_budget_frames", 240))
	var resolve_seconds := float(args.get("resolve_seconds", 6.0))
	var throw_control := str(args.get("throw_control", "interact"))

	var party_before := (_probe.call("party_state") as Array).size()
	var log: Array[String] = []
	for attempt in max_throws:
		if not bool(mgr.call("is_fighting")):
			return "FAIL throw_until_caught: fight ended before throw %d (%s)" % [
				attempt + 1, ", ".join(log)]
		var armed := await _step_press_until({
			"control": "interact",
			"check": {"check": "input_context", "equals": "combat_aim"},
			"max_presses": 5,
			"settle_frames": 20,
		}, "%s-arm%d" % [step_id, attempt + 1])
		if armed.begins_with("FAIL") or armed.begins_with("HARNESS-ERROR"):
			return "FAIL throw_until_caught: could not arm aim for throw %d (%s) -- prior: %s" % [
				attempt + 1, armed, ", ".join(log)]
		var tracked := await _step_track_aim({"budget_frames": aim_budget},
			"%s-track%d" % [step_id, attempt + 1])
		# A tracking FAIL (budget exhausted, LOS blocked) is not fatal on its
		# own: the throw below still goes out unassisted rather than wasting
		# the whole attempt on a step that only steers, never presses --
		# matching the ladder's own pre-existing behaviour when tracking ran
		# out. Recorded in the log either way.
		var sent := await _inject(throw_control, _hold_frames("tap"))
		if not bool(sent.get("ok", false)):
			return "HARNESS-ERROR %s" % str(sent.get("why", ""))
		# NOT a fixed wait: `combat_manager.gd`'s post-strike resolve sequence
		# (absorb -> shake x N -> settle -> verdict) runs to a length that
		# depends on the SHAKE COUNT catching.json rolls per throw (a near
		# miss shakes more than a hopeless one), which a guessed duration
		# cannot know -- a fixed 6.0s here once undershot a max-shake resolve
		# and cost a whole re-arm cycle, `_read_player_input()` silently
		# dropping interact presses because `_catch_phase` was still
		# non-NONE. Phase 1 confirms the strike actually started resolving
		# (skips itself harmlessly if the orb missed the body outright and
		# there is nothing to resolve); phase 2 waits for the real end.
		await _step_wait_until({"check": "catch_resolving", "equals": true,
			"budget_frames": 180, "poll_frames": 3})
		await _step_wait_until({"check": "catch_resolving", "equals": false,
			"budget_frames": maxi(60, int(resolve_seconds * float(Engine.physics_ticks_per_second))),
			"poll_frames": 3})
		# `catch_resolving` clearing is the VERDICT, not the outcome finishing.
		# Measured directly: a caught creature is not actually added to the
		# party, and the fight does not actually end, until ~2.7s AFTER the
		# verdict resolves (combat_manager.gd's post-catch sequence has its
		# own beat past `_finish_catch()`). Checking party size the instant
		# `catch_resolving` clears reads a real catch as a miss and burns the
		# rest of this attempt trying to re-arm a fight that has already
		# ended. So: wait, up to `resolve_seconds` again, for whichever
		# happens first -- the party growing (caught) or the fight actually
		# ending some other way (fled) -- and only conclude "still fighting,
		# genuine miss" if neither happens in that window.
		var settle_budget := maxi(1, int(resolve_seconds * float(Engine.physics_ticks_per_second)))
		var settled := 0
		var party_now := (_probe.call("party_state") as Array).size()
		while party_now <= party_before and bool(mgr.call("is_fighting")) and settled < settle_budget:
			await physics_frame
			_tick(1.0 / float(Engine.physics_ticks_per_second))
			settled += 1
			party_now = (_probe.call("party_state") as Array).size()
		log.append("throw %d (%s)" % [attempt + 1, "tracked" if not tracked.begins_with("FAIL") else "untracked"])
		if party_now > party_before:
			return "caught on throw %d of %d (%s)" % [attempt + 1, max_throws, ", ".join(log)]
		if not bool(mgr.call("is_fighting")):
			return "FAIL throw_until_caught: fight ended after throw %d without a catch (%s)" % [
				attempt + 1, ", ".join(log)]
	return "FAIL throw_until_caught: %d throw(s) spent, no catch (%s)" % [max_throws, ", ".join(log)]


## RIG-F3 — track the live target during aim; do not throw at a stale point.
##
## `ralph/GATE-F-CAPSTONE-3`'s S02 run found the second generation of RIG-F2's
## bug in the same catch sequence: all 3 scripted throws missed the wild
## bramblebun's body entirely (`reason=reticle_outside_body`/`reason=ground`)
## rather than landing and failing the catch roll on its own merits. RIG-F2
## fixed the AIM TOGGLE (press until `input_context == combat_aim`); this
## fixes the AIM DIRECTION once inside it. Every S02 throw block re-aimed
## exactly once, at aim entry, via `press_until` -- there was nothing between
## that snap and the eventual `press interact` release except a `capture`
## step, but the bramblebun is a live `CharacterBody3D` that keeps walking
## through both, and `throw_aim.gd::_acquire_target()` only SNAPS the camera
## once, on the frame the aim opens (see its own header: "Snapped rather than
## glided"). A camera pointed at where the target stood is exactly the fixed
## aim-then-throw pattern CD-3 already named as the wrong shape for a press;
## the same shape is wrong for an aim.
##
## So this steers, every frame, at the target's CURRENT `centre()` -- the
## same yaw/pitch formula `_acquire_target()` snaps once, re-applied
## continuously here -- and reads eligibility off `throw_aim.gd::aim_report()`,
## the exact live diagnostic `_commit_launch_assist()` itself is built from
## (`reticle_outside_body`/`line_of_sight_blocked`/`eligible`). That is the
## same "reach a state, then assert it, never guess a repetition count"
## primitive RIG-F2 used for a press, applied here to a continuous analogue
## input: PASS the instant the reticle is confirmed on the body, reporting
## how many frames that took; FAIL at `budget_frames` naming the last reason
## seen. This step only STEERS -- the throw itself stays a separate `press`
## step immediately after it, so a segment can still see (and evidence) the
## release as its own step.
func _step_track_aim(args: Dictionary, step_id: String) -> String:
	# CD-4's rule, the same way `press_until`'s own `skip_if` applies it: a
	# retry block that runs after the catch already landed has nothing to aim
	# at, and that is the segment succeeding early, not a defect. Measured on
	# this segment: once `party_size` reaches its target after throw 2, throws
	# 3 and 4's `press_until` (aim entry) already reports FAIL rather than
	# SKIP because neither carries a `skip_if` of its own — this step must not
	# repeat that shape by reporting a hard FAIL for the same moot case.
	var skip_if: Dictionary = args.get("skip_if", {}) as Dictionary
	if not skip_if.is_empty():
		var moot := _step_assert(skip_if)
		if bool(moot.get("ok", false)):
			return "SKIPPED track_aim: not needed (%s)" % str(moot.get("actual", ""))

	var manager := _probe.call("combat_manager") as Node
	if manager == null:
		return "HARNESS-ERROR track_aim step %s has no CombatManager in the world" % step_id
	var throw: Node = manager.call("throw_aim") if manager.has_method("throw_aim") else null
	if throw == null:
		return "HARNESS-ERROR track_aim step %s: CombatManager has no throw_aim node" % step_id
	if not bool(throw.call("is_aiming")):
		return "FAIL track_aim: input_context is not combat_aim -- enter it with press_until first"
	var rig := _probe.call("camera_rig") as Node
	if rig == null:
		return "HARNESS-ERROR track_aim step %s: no live camera rig" % step_id
	# The RETICLE ray is cast from the CAMERA's eye (`launch_assist_diagnostics()`
	# uses `camera.global_position`), not the trainer's — the aim camera sits
	# about a shoulder's width off to one side (`_shoulder`, `_apply_aim_camera`'s
	# own header explains why). Steering toward the target from the PLAYER's
	# position instead (what `_acquire_target()`'s one-shot snap does, and what
	# this step's first cut also did) is off by exactly that parallax, and
	# because the offset does not shrink as the camera turns, it never converges
	# -- measured: four tracked blocks, every one still `reticle_outside_body`
	# after the full 240-frame budget, with the offset if anything larger than
	# the single un-tracked snap it was meant to fix. Aiming from the camera's
	# own eye is the ray the eligibility check will actually judge.
	var camera := rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return "HARNESS-ERROR track_aim step %s: camera rig has no live Camera3D" % step_id

	var budget := maxi(1, int(args.get("budget_frames", 240)))
	var last_reason := "unavailable"
	var turned := 0
	while turned < budget:
		if not bool(throw.call("is_aiming")):
			return "FAIL track_aim: left combat_aim mid-track after %d frame(s) (last: %s)" % [
				turned, last_reason]
		var report: Dictionary = throw.call("aim_report")
		last_reason = str(report.get("reason", "unavailable"))
		if bool(report.get("eligible", false)):
			_stick_right = Vector2.ZERO
			_drive_sticks()
			await physics_frame
			return "reticle confirmed on body after %d tracked frame(s): %s" % [turned, last_reason]

		var body: Node3D = manager.call("enemy_body") as Node3D
		if body == null or not is_instance_valid(body) or not body.has_method("centre"):
			_stick_right = Vector2.ZERO
			_drive_sticks()
			return "FAIL track_aim: no live target body to track after %d frame(s)" % turned

		# Same formula `_acquire_target()` snaps once at aim entry -- resampled
		# every frame here because the target keeps walking through the gap a
		# fixed snap leaves open, and measured FROM THE CAMERA rather than the
		# trainer (see the header above).
		var centre: Vector3 = body.call("centre")
		var to_target: Vector3 = centre - camera.global_position
		var have_yaw := float(rig.get("yaw"))
		var want_yaw := atan2(-to_target.x, -to_target.z)
		var yaw_delta := rad_to_deg(angle_difference(have_yaw, want_yaw))
		var yaw_push := clampf(absf(yaw_delta) / 45.0, 0.4, 1.0) * signf(-yaw_delta)

		var pitch_push := 0.0
		var flat := Vector2(to_target.x, to_target.z).length()
		if flat > 0.01:
			var have_pitch := float(rig.get("pitch"))
			var want_pitch := atan2(to_target.y, flat)
			var pitch_delta := rad_to_deg(angle_difference(have_pitch, want_pitch))
			pitch_push = clampf(absf(pitch_delta) / 45.0, 0.4, 1.0) * signf(-pitch_delta)

		_stick_right = Vector2(yaw_push, pitch_push)
		_drive_sticks()
		turned += 1
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))

	_stick_right = Vector2.ZERO
	_drive_sticks()
	return "FAIL track_aim: reticle never confirmed on body in %d frame(s); last saw %s" % [
		budget, last_reason]


## Harness-only test shortcut: put the reticle on the target's body in one
## frame instead of steering toward it with rate-limited analog stick input.
##
## `track_aim` above is the honest player-input simulation, and stays that
## way -- it is what a real controller does. But this catch-loop's own
## purpose in the current work (ralph/GATE-F-S03-CATCH-LOOP) is exercising
## team-building/revive/economy logic downstream of a successful catch, not
## re-proving aim-input responsiveness, and a live gameplay fix for aim
## tracking itself (creatures slow down on entering catch mode) is already
## landing in a separate lane. Until that lands, `track_aim`'s clamped
## per-frame turn rate against a full-speed wild creature is a second,
## independent source of flakiness on top of whatever this lane is actually
## trying to verify -- gate_f-run-20260901T220548Z-s03fix's attempt 5 spent
## its whole 966s segment on exactly one successful catch (the S02 carry-
## over) with every scripted throw missing on `reticle_outside_body`/`ground`.
##
## This step reuses `track_aim`'s own camera-eye/centre() geometry (see its
## header for why the ray is cast from the camera, not the trainer) but
## assigns `camera_rig.gd`'s public `yaw`/`pitch` floats directly rather
## than nudging them via `_stick_right`, so there is no turn-rate limit to
## outrun a moving target with. It still goes through the same live
## `aim_report()` eligibility check afterward and FAILs loudly if that
## somehow still does not confirm -- this shortcuts the STEERING, not the
## catch roll, the orb physics, or anything downstream of the throw.
func _step_force_aim(args: Dictionary, step_id: String) -> String:
	var skip_if: Dictionary = args.get("skip_if", {}) as Dictionary
	if not skip_if.is_empty():
		var moot := _step_assert(skip_if)
		if bool(moot.get("ok", false)):
			return "SKIPPED force_aim: not needed (%s)" % str(moot.get("actual", ""))

	var manager := _probe.call("combat_manager") as Node
	if manager == null:
		return "HARNESS-ERROR force_aim step %s has no CombatManager in the world" % step_id
	var throw: Node = manager.call("throw_aim") if manager.has_method("throw_aim") else null
	if throw == null:
		return "HARNESS-ERROR force_aim step %s: CombatManager has no throw_aim node" % step_id
	if not bool(throw.call("is_aiming")):
		return "FAIL force_aim: input_context is not combat_aim -- enter it with press_until first"
	var rig := _probe.call("camera_rig") as Node
	if rig == null:
		return "HARNESS-ERROR force_aim step %s: no live camera rig" % step_id
	var camera := rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return "HARNESS-ERROR force_aim step %s: camera rig has no live Camera3D" % step_id
	var body: Node3D = manager.call("enemy_body") as Node3D
	if body == null or not is_instance_valid(body) or not body.has_method("centre"):
		return "FAIL force_aim: no live target body to aim at"

	var budget := maxi(1, int(args.get("budget_frames", 10)))
	var last_reason := "unavailable"
	var attempts := 0
	while attempts < budget:
		# Resampled every attempt, same as track_aim: the target may still be
		# moving between the previous miss and this retry.
		var centre: Vector3 = body.call("centre")
		var to_target: Vector3 = centre - camera.global_position
		rig.set("yaw", atan2(-to_target.x, -to_target.z))
		var flat := Vector2(to_target.x, to_target.z).length()
		if flat > 0.01:
			rig.set("pitch", atan2(to_target.y, flat))
		_stick_right = Vector2.ZERO
		_drive_sticks()
		await physics_frame
		var report: Dictionary = throw.call("aim_report")
		last_reason = str(report.get("reason", "unavailable"))
		attempts += 1
		if bool(report.get("eligible", false)):
			return "reticle forced onto body in %d attempt(s): %s" % [attempts, last_reason]

	return "FAIL force_aim: reticle not confirmed on body after %d forced attempt(s); last saw %s" % [
		budget, last_reason]


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
	# Retried (added 2026-09-02), same reason `equip_tool` retries a hotbar
	# press instead of trusting one: measured directly on S03's feed sequence,
	# a `menu_cancel` here can land in a frame the shell is not actually
	# reading it in (a sub-mode ending the same frame -- `tab_backpack.gd`'s
	# `_end_targeting()`/`_end_confirm()`/`_end_held()` all restore grid focus
	# synchronously, but not every one-frame window in between is guaranteed
	# open to a fresh press) and reports "left the shell open" even though a
	# SECOND press moments later closes it cleanly. A real player facing an
	# unresponsive first B press just presses it again.
	var max_attempts := maxi(1, int(args.get("max_attempts", 3)))
	var after := before
	for attempt in max_attempts:
		var sent := await _inject(control, HOLD_TAP)
		if not bool(sent.get("ok", false)):
			return "HARNESS-ERROR %s" % str(sent.get("why", ""))
		await _settle_until(func() -> bool: return not str(_probe.call("input_context")).begins_with("menu"))
		after = str(_probe.call("input_context"))
		if not after.begins_with("menu"):
			if attempt > 0:
				return "%s closed the shell on press %d: context %s -> %s" % [
					control, attempt + 1, before, after]
			return "%s closed the shell: context %s -> %s" % [control, before, after]
	return "FAIL %s left the shell open after %d press(es): context %s -> %s" % [
		control, max_attempts, before, after]


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
	# CD-3's own regression, verbatim: "after any dialogue step, `input_context`
	# must not be `narrative_modal`." Checked here rather than left to the next
	# step's `require_context`, because the next step is where the cost lands
	# and this is where the cause is.
	if after_context == "narrative_modal":
		return ("FAIL %s reports closed after %d line(s) but input_context is still "
			+ "'narrative_modal' and no panel says it is open. Input has not been handed back; "
			+ "the next world control pressed would go to whatever is holding it.") % [
				str(owner.name), lines.size()]
	return "advanced %d line(s) over %d press(es) of %s; %s closed, context '%s' -> '%s'" % [
		lines.size(), presses, control, str(owner.name), context, after_context]


## Which advanceable panel is this?
static func _panel_kind(node: Node) -> String:
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


## Move the satchel cursor onto the cell holding a named ITEM.
##
## GAME-9 / RIG-24. `focus_move` counts presses, and a count is only ever right
## for one arrangement of the bag. S03 binds its three tools by counting cells
## from the grid's opening focus along the order a FRESH save fills the satchel
## in -- and the run-4 evidence
## (`ralph/reports/gate-f-run4-s03-validation-2/S03/telemetry/events.jsonl`)
## shows the bag it actually meets: both Revive draughts spent on the two live
## revives, potions down from three to one, before a single tool is bound. The
## presses all landed, the focus all moved, every step reported PASS -- onto the
## wrong items. Six real gathers then carried the same wrong tool and
## `home_materials_gathered` never set. Nothing about that failure is visible
## from a fresh-load probe, which is why `probe_tool_equip_sequence.gd` PASSed
## the same sequence in isolation.
##
## Still production input. Every move below is a real `ui_left`/`ui_right`
## through the live InputMap, the same events `focus_move` sends; the only thing
## that changes is that the harness reads WHERE THE CURSOR IS between presses
## instead of assuming. That is what a player does: they can see the bag.
##
## Navigated in ROWS AND COLUMNS, not by walking a linear index. `ui_left` at a
## row's start does not wrap up to the previous row's end and `ui_right` at a
## row's end does not wrap down -- S03 assumed both ("wrapping up a grid row")
## and that assumption is the second half of GAME-9: even reading the cursor,
## a linear walk sits at the row edge pressing a direction that will never
## move. Column first, then row, is `probe_tool_equip_sequence.gd`'s own proven
## navigation, which is exactly why that probe PASSed while S03 did not.
##
## The cursor is re-read from the live grid after every press rather than
## tracked in a local, so a press that does not land shows up as a FAIL here
## instead of as a wrong binding three steps later.
func _step_focus_item(args: Dictionary, step_id: String) -> String:
	var item := str(args.get("item", ""))
	if item.is_empty():
		return "HARNESS-ERROR focus_item step %s has no item:\"...\"" % step_id
	var max_moves := int(args.get("max_moves", 60))
	var target: int = int(_probe.call("satchel_slot_of", item))
	if target < 0:
		return ("FAIL focus_item '%s': the satchel does not hold it at all. Carrying: %s"
			% [item, JSON.stringify(_probe.call("inventory_snapshot"))])
	var start: Dictionary = _probe.call("satchel_focus")
	if not bool(start.get("ok", false)):
		return ("FAIL focus_item '%s': the Satchel is not the surface holding focus "
			+ "(input_context '%s'). Open it first.") % [item, str(_probe.call("input_context"))]
	var columns: int = int(_probe.call("satchel_columns"))
	if columns <= 0:
		return "FAIL focus_item '%s': the satchel grid reports no columns" % item
	var moves := 0
	while moves < max_moves:
		var slot := int((_probe.call("satchel_focus") as Dictionary).get("slot", -1))
		if slot == target:
			return "focus_item '%s': cursor on cell %d after %d move(s) (from cell %d)" % [
				item, slot, moves, int(start.get("slot", -1))]
		if slot < 0:
			return "FAIL focus_item '%s': the satchel cursor is nowhere (cell %d)" % [item, slot]
		var control := ""
		if slot % columns != target % columns:
			control = "ui_right" if target % columns > slot % columns else "ui_left"
		else:
			control = "ui_down" if target / columns > slot / columns else "ui_up"
		var sent := await _inject(control, HOLD_TAP)
		if not bool(sent.get("ok", false)):
			return "HARNESS-ERROR %s" % str(sent.get("why", ""))
		for f in 3:
			await process_frame
		moves += 1
		if int((_probe.call("satchel_focus") as Dictionary).get("slot", -1)) == slot:
			return ("FAIL focus_item '%s': %s did not move the cursor off cell %d "
				+ "(wanted cell %d, %d columns)") % [item, control, slot, target, columns]
	var final: Dictionary = _probe.call("satchel_focus")
	return "FAIL focus_item '%s': %d moves did not reach cell %d (cursor on cell %d, holding '%s')" % [
		item, max_moves, target, int(final.get("slot", -1)), str(final.get("item", ""))]


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
	_record_next_t = _play_t()
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
	_record_next_t = _play_t() + (1.0 / maxf(0.01, _record_hz)) if _record_hz > 0.0 else 0.0
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
	var due := _record_hz > 0.0 and _play_t() >= _record_next_t
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
		_record_next_t = _play_t() + (1.0 / maxf(0.01, _record_hz))
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
	var t := _play_t()
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
	var wrote := _file_bytes(_out_dir.path_join(rel))
	row["bytes"] = wrote
	_note_png_bytes(wrote)
	_frames.append(row)
	_record_written += 1


## What this segment actually put on disk, from the rows that recorded it.
##
## Deliberately summed from the manifests rather than by walking the directory:
## a byte count that agrees with the rows is a byte count a reader can reconcile
## against them, and a directory walk would also sweep up `_preflight.png` and
## `capture_smoke.png`, which are instrument artefacts and not evidence.
func _disk_actual() -> Dictionary:
	var shot_bytes := 0
	for entry: Variant in _manifest:
		shot_bytes += int((entry as Dictionary).get("bytes", 0))
	var frame_bytes := 0
	for entry: Variant in _frames:
		frame_bytes += int((entry as Dictionary).get("bytes", 0))
	return {
		"shot_bytes": shot_bytes,
		"frame_bytes": frame_bytes,
		"total_bytes": shot_bytes + frame_bytes,
		"largest_evidence_png_bytes": _evidence_png_bytes,
		"preflight_self_test_png_bytes": int(_preflight.get("png_bytes", 0)),
	}


## The largest evidence PNG this segment has actually written.
##
## The disk estimate starts from the pre-flight self-test, which is the only
## measurement available before step 1 -- and it is a frame of an EMPTY TREE.
## Measured on S01C: the self-test was 10,596 bytes and the real title frame was
## **65,297**, a 6x under-estimate. Pricing a segment's disk against the cheapest
## possible frame is the same mistake as pricing its time against the cheapest
## possible scene, which is the defect this whole round exists to fix -- so as
## soon as a real frame exists, the estimate uses it.
##
## The MAX rather than the mean, deliberately. A budget is what a segment may
## still spend, and a scene that has produced one 200 kB frame will produce
## more; an average dragged down by a title screen would clear a ceiling the
## rest of the segment cannot.
func _note_png_bytes(bytes: int) -> void:
	if bytes > _evidence_png_bytes:
		_evidence_png_bytes = bytes


## Mean luminance, standard deviation and dark fraction of a frame.
##
## Sampled every 8th pixel in both axes -- 32,400 samples at 1920x1080, which is
## plenty for a distribution and cheap enough to run on every prescribed shot.
##
## Recorded on EVERY capture, whatever the verdict. That is most of the value:
## the 2026-08-27 run produced 79 X07 frames and the only way to find the bad
## ones was to open them one at a time. Three numbers per row makes "show me the
## frames with no contrast" a sort rather than an afternoon.
static func _frame_stats(image: Image) -> Dictionary:
	var w := image.get_width()
	var h := image.get_height()
	if w == 0 or h == 0:
		return {}
	var step := 8
	var total := 0.0
	var samples := 0
	var dark := 0
	var values: Array[float] = []
	for y in range(0, h, step):
		for x in range(0, w, step):
			var c := image.get_pixel(x, y)
			# Rec. 709 luma, on the 0-255 scale the thresholds are quoted in.
			var luma := (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) * 255.0
			values.append(luma)
			total += luma
			samples += 1
			if luma < 24.0:
				dark += 1
	if samples == 0:
		return {}
	var mean := total / float(samples)
	var acc := 0.0
	for v in values:
		acc += (v - mean) * (v - mean)
	return {
		"mean_luma": snappedf(mean, 0.1),
		"stddev_luma": snappedf(sqrt(acc / float(samples)), 0.1),
		"dark_fraction": snappedf(float(dark) / float(samples), 0.001),
	}


## Is this frame a picture of an obstruction rather than of the game?
##
## The defects lane reported that X07's `hall` and `the_rise` audit cameras end
## up INSIDE masonry. Checked against the recovered frames, that diagnosis does
## not hold: `hall-gameplay` is a clean exterior of the stronghold gate (mean
## luma 72.8, 2.4% dark) and all six `the_rise` frames share ONE camera
## position -- four of them are wide, fully-lit vistas. A camera inside solid
## geometry would be black at every yaw.
##
## Two of the six are still useless, and that is the real defect: at those yaws
## the camera's near field is filled by something opaque. So the check is on the
## IMAGE, not on a physics query -- it catches a buried camera, an occluded near
## field, a fade caught mid-frame and a black screen alike, and it needs no
## assumption about why.
##
## Calibrated against X07's own 79 frames. The separation is clean and it is not
## the one you would guess -- mean luminance does NOT work, because the darkest
## frames in the set are legitimate NIGHT frames:
##
##   frame                             mean  stddev  frac<24
##   the_pond-night-gameplay           25.1    41.1    0.584   <- legitimate
##   the_rise-gameplay                 26.6    29.0    0.755   <- degenerate
##   the_rise-arrival                  26.6    29.0    0.755   <- degenerate
##   the_pond-night-arrival            26.8    43.0    0.584   <- legitimate
##   (next darkest of the other 75)    48.2    48.8    0.284
##
## The night frames are DARKER in the mean and still have sky, moon and
## silhouette, so they hold their contrast. The degenerate pair is flat. Dark
## fraction separates at 0.584 / 0.755 and stddev at 43.0 / 29.0; the defaults
## sit between both, and both must trip together.
##
## Note the dark fraction tops out near 0.755 rather than 1.0 because the HUD is
## in the frame. The thresholds are measured against that reality, not against
## an idealised bare viewport.
func _degenerate_reason(stats: Dictionary) -> String:
	if stats.is_empty():
		return ""
	var dark := float(stats.get("dark_fraction", 0.0))
	var spread := float(stats.get("stddev_luma", 255.0))
	if dark <= float(_cfg["degenerate_dark_fraction"]) or spread >= float(_cfg["degenerate_stddev"]):
		return ""
	return ("%.1f%% of the frame is below luma 24 and its luminance spread is only %.1f "
		+ "(mean %.1f). That is a photograph of an obstruction, not of the game: a camera "
		+ "inside geometry, a near field filled by something opaque, or a fade caught "
		+ "mid-frame. A legitimate night frame is darker in the mean and keeps its contrast "
		+ "-- X07's own night captures sit at %.0f%% dark with a spread of ~42.") % [
			dark * 100.0, spread, float(stats.get("mean_luma", 0.0)), 58.4]


func _step_capture(args: Dictionary, step_id: String) -> String:
	var shot_id := str(args.get("id", step_id))
	var row := {
		"id": shot_id,
		"class": str(args.get("class", "context")),
		"segment": _segment_id,
		"t": _play_t(),
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
	row["bytes"] = _file_bytes(_out_dir.path_join(rel))
	_note_png_bytes(int(row["bytes"]))
	var stats := _frame_stats(image)
	row["luma"] = stats
	_manifest.append(row)
	_capture_step_active = false
	# Push the recorder's next cadence frame past this shot rather than letting
	# it fire on the very next tick with an identical image.
	if _record_hz > 0.0:
		_record_next_t = maxf(_record_next_t, _play_t() + (1.0 / maxf(0.01, _record_hz)))
	var degenerate := _degenerate_reason(stats)
	if not degenerate.is_empty():
		row["degenerate"] = degenerate
		_emit("screenshot", {"artifacts": [shot_id], "severity_candidate": "SHIP",
			"observation": "degenerate frame: %s" % degenerate})
		return "FAIL capture %s is a degenerate frame. %s" % [shot_id, degenerate]
	_emit("screenshot", {"artifacts": [shot_id]})
	return "captured %s at %dx%d (mean luma %.1f, spread %.1f, %.1f%% dark)" % [shot_id,
		image.get_width(), image.get_height(), float(stats.get("mean_luma", 0.0)),
		float(stats.get("stddev_luma", 0.0)), float(stats.get("dark_fraction", 0.0)) * 100.0]


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
	# CD-4. A cell is coverage only if the probe happened in the named context.
	#
	# X01 walks a list of (control, context) cells and presses each in sequence.
	# A press that changes context is not undone, so the next cell fires into
	# whatever the last one opened: eight different surfaces were all actually
	# probed inside `menu_map`, twelve named surfaces were never entered at all,
	# and the matrix's only trustworthy content was the 115 cells that did land
	# in their own context -- which were 115/115 clean.
	#
	# `intended_context` rather than `require_context` deliberately. A cell in
	# the wrong context is SKIPPED and the segment carries on to the next cell;
	# it does not derail, because a matrix of 418 cells that stopped at the
	# first drift would be worse evidence than one that reports which cells
	# were real. The mismatch is a first-class field so counting it is one
	# query rather than a regex over `expected`.
	var intended: Variant = args.get("intended_context", null)
	var context_before := str(before.get("context", ""))
	if intended != null and not _context_matches(context_before, intended):
		_emit("input_probe", {
			"input": {"device": "synthetic", "device_kind": device, "action": control,
				"edge": "none"},
			"intended_context": intended,
			"context_before": context_before,
			"expected": str(args.get("expected", "")),
			"actual": "SKIPPED (context not reached)",
			"observation": ("cell control=%s device=%s was NOT probed: it names context %s and "
				+ "input was owned by '%s' (owner=%s, focus=%s). Pressing anyway would have "
				+ "measured a different surface under this cell's name.") % [control,
					device if not device.is_empty() else "default", JSON.stringify(intended),
					context_before, str(before.get("focus_owner", "")), str(before.get("focus_text", ""))],
		})
		return ("SKIPPED cell %s: names context %s, input_context was '%s'. Not probed, and not "
			+ "counted as either a pass or a failure.") % [control, JSON.stringify(intended),
				context_before]
	var sent := await _inject(control, HOLD_TAP, device)
	if not bool(sent.get("ok", false)):
		if bool(sent.get("device_miss", false)):
			# The cell is still reported -- "unreachable on this device" is a
			# real matrix answer, and an empty cell is not.
			_emit("input_probe", {"input": {"device": "synthetic", "device_kind": device,
					"action": control, "edge": "none"},
				"intended_context": intended,
				"context_before": context_before,
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
		# Present on every probed cell, not only the skipped ones: "this cell
		# was in context" has to be a positive fact a post-processor can count,
		# or in-context coverage stays a number nobody can produce.
		"intended_context": intended,
		"context_before": context_before,
		"expected": str(args.get("expected", "")),
		"actual": "world=[%s] ui=[%s] release_edge=[%s]" % [world_effect, ui_effect, release_effect],
		"observation": "cell control=%s context_before=%s context_after=%s focus_before=%s focus_after=%s" % [
			control, str(before.get("context")), str(after.get("context")),
			str(before.get("focus_text")), str(after.get("focus_text"))],
	})
	return "cell %s in %s: world=[%s] ui=[%s] release=[%s]" % [control,
		str(before.get("context")), world_effect, ui_effect, release_effect]


## CD-3's missing half: reach a state, then assert it.
##
## `assert` asks its question once, at the instant the step runs, so every
## assertion that follows an asynchronous game event has to be preceded by a
## `wait` with a GUESSED frame count -- and the protocol's own CD-3 rule says a
## guessed count for a state-changing operation is wrong in both directions.
## Under-wait and a true state reads as false; over-wait and the segment pays
## for frames it did not need.
##
## The cost of the missing half was measured by ralph/GATE-F-FULL on
## 2026-08-30, on the chapter's own first catch. `S02-43iw` waited 360 physics
## frames (6.0 s of play) after the fourth throw; the throw resolved to a
## verdict at t=265.38 and CombatManager granted the creature at t=268.00, and
## the wait ended at t=267.47. `S02-45` ("the catch counted") therefore read
## `party size 1 (wanted 2)` **0.53 s of play before the party became 2**, and
## `S02-46` ("the chain advanced to the road") read the stale objective for the
## same reason. Both were recorded as FAILs against a run whose own exit save
## carries the caught bramblebun. Three previous runs have reported this shape.
##
## So: same `check` vocabulary as `assert`, same args, plus a budget. It polls
## rather than guesses, PASSes the moment the predicate is true and says how
## long it took, and FAILs at the budget naming the last thing it saw -- which
## is strictly more informative than a bare `assert`, because a FAIL here means
## "still false after N frames", not "false at one instant".
##
## A check the envelope cannot evaluate (`skip`) is returned immediately and
## unchanged: polling a question that cannot be asked is just a slower SKIP.
func _step_wait_until(args: Dictionary) -> Dictionary:
	var budget := maxi(1, int(args.get("budget_frames", 600)))
	var poll := maxi(1, int(args.get("poll_frames", 5)))
	var checked := _step_assert(args)
	if bool(checked.get("skip", false)):
		return checked
	var waited := 0
	while not bool(checked.get("ok", false)) and waited < budget:
		for i in poll:
			await physics_frame
			_tick(1.0 / float(Engine.physics_ticks_per_second))
			waited += 1
			# `wait`'s own rule: this is a loop the protocol's hours can live
			# in, so it honours a mid-step cost abort rather than watching the
			# whole budget go past.
			if not _blocked.is_empty():
				return {"ok": false, "actual": "waited %d of %d physics frames before the cost gate stopped it"
					% [waited, budget]}
			if waited >= budget:
				break
		checked = _step_assert(args)
	var actual := str(checked.get("actual", ""))
	if bool(checked.get("ok", false)):
		return {"ok": true, "actual": "%s [true after %d physics frames]" % [actual, waited]}
	return {"ok": false, "actual": "%s [still false after %d physics frames]" % [actual, waited]}


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
		"catch_resolving":
			# combat_manager.gd::_tick_active() reads `_catch_phase` (ABSORB ->
			# WAIT -> SHAKING -> VERDICT) BEFORE `_read_player_input()` and
			# returns early while it is anything but NONE -- interact presses
			# during that window are silently dropped, not queued. The window's
			# real length depends on the SHAKE COUNT catching.json's own
			# `resolve` block rolls per throw (a near miss shakes more times
			# than a hopeless one, `resolve.max_shakes_on_failure`), which a
			# fixed `wait` cannot know in advance -- `throw_until_caught`
			# guessed 6.0s once and a throw that rolled the max shake count
			# outlasted it, so three re-arm presses all landed while
			# `_catch_phase` was still non-NONE and none of them registered.
			# `combat_manager.gd::is_resolving_catch()` is the live truth.
			var want_resolving := bool(args.get("equals", false))
			var mgr2 := _probe.call("combat_manager") as Node
			var resolving := bool(mgr2.call("is_resolving_catch")) if mgr2 != null and mgr2.has_method("is_resolving_catch") else false
			return {"ok": resolving == want_resolving, "actual": "catch_resolving=%s (wanted %s)" % [resolving, want_resolving]}
		"enemy_hp_fraction":
			# S03's catch ladder chipped a fixed `times: 3` regardless of how
			# much that actually left on the target -- measured across a real
			# run (gate-f-run-20260902T053310Z-s03enginefix) at 57%-75% of max
			# HP depending on the creature's own defence, not the "sliver"
			# catching.json's steep hp_curve actually rewards (hp_factor goes
			# from ~0.10 at full HP toward 1.0 near zero). A live threshold
			# lets `press_until` chip exactly as far as needed instead of a
			# guessed hit count -- pairs with `combat_quick` the same way
			# `combat_running` pairs with an engage press.
			var mgr := _probe.call("combat_manager") as Node
			var foe: RefCounted = mgr.call("enemy") if mgr != null and mgr.has_method("enemy") else null
			if foe == null:
				return {"ok": false, "actual": "no live enemy to read HP from"}
			var max_hp := float(foe.get("max_hp"))
			if max_hp <= 0.0:
				return {"ok": false, "actual": "enemy max_hp is %.1f, cannot fraction" % max_hp}
			var frac: float = float(foe.get("hp")) / max_hp
			var ok := true
			if args.has("at_most"):
				ok = ok and frac <= float(args["at_most"])
			if args.has("at_least"):
				ok = ok and frac >= float(args["at_least"])
			return {"ok": ok, "actual": "enemy hp fraction %.3f (%.1f/%.1f)" % [frac, float(foe.get("hp")), max_hp]}
		"combat_running":
			# T2-GATEF-RUN6 / RIG-26. The engage steps in this protocol asserted
			# that `interact` was INJECTED, not that a fight received it, so a
			# press into an unengaged world PASSed and the visible failure
			# surfaced several steps later as "combat never took input
			# ownership". Two instrumented segments produced 128 events with
			# zero `combat_start` in them that way, and it was read as a
			# candidate GAME blocker for six runs. `input_context == "combat"`
			# is close but not the same claim: it says something combat-shaped
			# owns input, not that CombatManager is actually running a fight.
			# This asks CombatManager directly, through the `combat_running`
			# field `gate_f_probe.gd::input_state()` already publishes.
			var want_fight := bool(args.get("equals", true))
			var st: Dictionary = _probe.call("input_state")
			var running := bool(st.get("combat_running", false))
			return {"ok": running == want_fight,
				"actual": "combat_running=%s (wanted %s)" % [running, want_fight]}
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
			var have := str(obj.get("id", ""))
			var resolved := _objective_flag_id(want)
			var matched := "flag_id" if have == want else (
				"entry id -> flag_id" if not resolved.is_empty() and have == resolved else "")
			return {"ok": not matched.is_empty(),
				"actual": "tracked objective id=%s text=%s (wanted %s%s)%s" % [
					have, str(obj.get("text", "")), want,
					"" if resolved.is_empty() or resolved == want else " = flag_id %s" % resolved,
					"" if matched.is_empty() else " [matched on %s]" % matched]}
		"party_size":
			# RIG-15: catching is probabilistic (data/config/catching.json's own
			# words -- "nothing is ever certain") and a step-script's catch
			# attempt can miss on a real, non-buggy roll. `equals` demanded the
			# team land on EXACTLY the milestone size, so a script that threw
			# more than once to cover a miss (or one that simply caught an
			# extra creature along the way) would FAIL a check that a bigger,
			# perfectly healthy team should pass. `min` is what every one of
			# these checks actually means -- "did the team reach at least N" --
			# and is additive with `equals`, which stays for a caller that
			# genuinely wants exact equality.
			var have := (_probe.call("party_state") as Array).size()
			if args.has("min"):
				var want_min := int(args["min"])
				return {"ok": have >= want_min, "actual": "party size %d (wanted >= %d)" % [have, want_min]}
			var want := int(args.get("equals", -1))
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
			# An assertion that cannot be EVALUATED is not a verdict on the
			# game. A process with no display server has no mouse to capture,
			# and `Input.MOUSE_MODE_CAPTURED` never holds in it -- so this
			# check run headless reports the pause shell as failing to restore
			# the mouse, every time, on a build where it restores it fine.
			#
			# That is precisely the harness-artefact class Phase B had to
			# refute from the run's own data: three of the four loudest
			# findings against candidate f082bdf6 were the instrument's, not
			# the game's. A capture that cannot be TAKEN is a FAIL, because
			# the evidence is missing and that is a real deficiency in the run.
			# A measurement that cannot be MADE is a SKIP, because the game
			# never got a chance to be wrong. The two are not the same and
			# collapsing them in either direction produces a lie.
			if not _capture_available():
				return {"ok": true, "skip": true,
					"actual": ("SKIPPED mouse_captured: this process has no display server "
						+ "(DisplayServer reports '%s'), so mouse mode says nothing about the game. "
						+ "Run this segment under tools/gate_f/run_segment.sh --capture for a "
						+ "verdict.") % DisplayServer.get_name()}
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

## Wait for a production save to land, and TIME it.
##
## CD-6's second half: no `save` or `load` event in the f082bdf6 run carried
## `duration_ms`, so §18's required save/load timings do not exist. The harness
## must not call `Game.save_game()` -- §7's whole point is that the operator
## saves the way a player does -- but it can watch the artefact appear. Placed
## immediately after the Save tab's confirm press, this measures the interval a
## player actually experiences: button to file on disk.
func _step_await_save(args: Dictionary, step_id: String) -> String:
	var slot := int(args.get("slot", 4))
	var path := _slot_path(slot)
	var was := FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else 0
	var was_bytes := _file_bytes(path)
	var timeout := float(args.get("timeout_s", 30.0))
	var started := Time.get_ticks_usec()
	while (float(Time.get_ticks_usec() - started) / 1000000.0) < timeout:
		await process_frame
		await physics_frame
		_tick(1.0 / float(Engine.physics_ticks_per_second))
		if not FileAccess.file_exists(path):
			continue
		var now := FileAccess.get_modified_time(path)
		var bytes := _file_bytes(path)
		if now > was or bytes != was_bytes:
			var ms := float(Time.get_ticks_usec() - started) / 1000.0
			_emit("save", {"duration_ms": snappedf(ms, 0.01),
				"observation": "slot %d written: %d bytes" % [slot, bytes]})
			return "slot %d landed %.0f ms after the press (%d bytes)" % [slot, ms, bytes]
	return ("FAIL slot %d did not change within %.0f s of this step (step %s). The Save tab's "
		+ "confirm either did not reach the serializer or the write failed silently.") % [
			slot, timeout, step_id]


## Wait for a production load to finish, and TIME it.
##
## The other half of §18's pair. Placed immediately after the title screen's
## Load press: it waits for a live world scene with a live Player and reports
## the interval, which is the load a player experiences rather than the
## serializer's own cost.
func _step_await_load(args: Dictionary, step_id: String) -> String:
	var timeout := float(args.get("timeout_s", 180.0))
	var started := Time.get_ticks_usec()
	while (float(Time.get_ticks_usec() - started) / 1000000.0) < timeout:
		await process_frame
		await physics_frame
		if (_probe.call("player") as Node3D) != null:
			var ms := float(Time.get_ticks_usec() - started) / 1000.0
			# The change detectors have to be re-primed here for the same
			# reason `boot` primes them: everything on the loaded save would
			# otherwise be reported as having just happened.
			_probe.call("refresh_pois")
			_seed_change_detection()
			_frame_ms.clear()
			_emit("load", {"duration_ms": snappedf(ms, 0.01),
				"observation": "a live Player exists %.0f ms after the Load press" % ms})
			# CD-7c. §H's amendment says the harness "re-prices after EVERY
			# boot" -- but a journey segment does not BOOT into its world, it
			# LOADS into it, and nothing re-priced here. The consequence was
			# measured on run 3's S03: the load spent 42.8 s of wall building
			# the world, the in-play recheck divided that by the 122 physics
			# frames that had ticked, got 0.351 s/frame -- 21x the real in-scene
			# price -- projected it across 119,472 remaining frames, and refused
			# a segment that costs minutes. So a load re-prices and resets the
			# sampling window, for the same reason and in the same place a boot
			# does: a scene has just CHANGED, and the history either side of the
			# change is not one price.
			var repriced := await _reprice("load", ms)
			return "the world came up %.0f ms after the press%s" % [ms, repriced]
		_tick(1.0 / float(Engine.physics_ticks_per_second))
	return ("FAIL no live Player within %.0f s of this step (step %s); input_context is '%s'. "
		+ "The Load path did not reach a playable world.") % [timeout, step_id,
			str(_probe.call("input_context"))]



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
	# RIG-10. A `seed_save` earlier in this segment already put a file at `src`
	# -- the file-exists check above can never fail on a segment that skipped
	# the Save tab entirely, because it is looking at seed_save's own leftover
	# file. Compare content against the hash recorded when that seed happened:
	# unchanged bytes mean this segment never actually wrote through the Save
	# tab, whatever else in it reported PASS.
	if _seeded_slot_md5.has(slot):
		var current_md5 := FileAccess.get_md5(src)
		if current_md5 == _seeded_slot_md5[slot]:
			return ("FAIL slot %d's content is byte-identical to what seed_save wrote at the start "
				+ "of this segment -- the Save tab was never actually used") % slot
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
		# in the OWNING segment's own saves/ (the id named by `want` itself,
		# e.g. "S05-exit.json" -> "S05/saves/"), which is where `save_out`
		# actually puts them.
		#
		# RIG-12 (2026-08-29): the scan below this used to walk every directory
		# in the run root and take whichever candidate it saw LAST, with no
		# ordering guarantee from `DirAccess.list_dir_begin()`. When a restart
		# leaves a `-superseded-N/` directory sitting beside the real one --
		# exactly what `RESTARTS.md` says happens -- and BOTH carry a
		# same-named exit save (a segment superseded after it reached its own
		# save step), the scan could hand a segment its predecessor's
		# SUPERSEDED save instead of the kept one. That is what happened to
		# this run's own first S06 attempt: it loaded
		# `S05-superseded-2/saves/S05-exit.json` (1 flag, party 1) instead of
		# the kept `S05/saves/S05-exit.json` (4 flags). The owning-directory
		# check below closes it deterministically for the normal case; the
		# fallback scan is kept only for a save whose owning directory is
		# named differently than its filename, and now skips
		# `-superseded-` directories and stops at the first match rather than
		# overwriting it.
		var want := from.trim_prefix("run://")
		var run_root := _out_dir.get_base_dir()
		from = run_root.path_join("saves").path_join(want)
		if not FileAccess.file_exists(from):
			var owning_id := want.get_basename()
			if owning_id.ends_with("-exit"):
				owning_id = owning_id.substr(0, owning_id.length() - "-exit".length())
			var owned := run_root.path_join(owning_id).path_join("saves").path_join(want)
			if not owning_id.is_empty() and FileAccess.file_exists(owned):
				from = owned
		if not FileAccess.file_exists(from):
			var found := ""
			var dir := DirAccess.open(run_root)
			if dir != null:
				dir.list_dir_begin()
				var entry := dir.get_next()
				while entry != "":
					if dir.current_is_dir() and not entry.begins_with(".") and not entry.contains("-superseded-"):
						var candidate := run_root.path_join(entry).path_join("saves").path_join(want)
						if FileAccess.file_exists(candidate) and found.is_empty():
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
	# RIG-10. Record what this slot looks like right now, so a later save_out
	# can tell whether the Save tab actually changed it or just handed it back.
	_seeded_slot_md5[slot] = FileAccess.get_md5(dst)
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
				# RIG-10. The file a seed_save hash referred to is gone; a slot
				# reused after this wipe needs a fresh seed_save (or none) before
				# save_out can compare against it again.
				if name.begins_with("slot_") and name.ends_with(".json"):
					var slot_num := name.trim_prefix("slot_").trim_suffix(".json")
					if slot_num.is_valid_int():
						_seeded_slot_md5.erase(int(slot_num))
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

## WALL seconds since the segment started, on the box.
##
## This is the cost of running the segment, not the length of anything that
## happened in the game. Under llvmpipe at 1920x1080 the 2026-08-27 run measured
## a median 6.465 s between two consecutive in-world frames; on that box one
## wall second is a sixth of a physics step.
##
## **Nothing whose meaning is "how long did this take the player" may read
## this.** Use `_play_t()`. The consumers that legitimately do read wall time
## are the ones asking about the box: the cost gate, the disk gate, the frame
## grab timings, `duration_ms` on a boot/save/load, and the `wall` datetime
## column that lets a reader line the two clocks up.
func _wall_t() -> float:
	return float(Time.get_ticks_usec() - _t0_usec) / 1_000_000.0


## PLAY seconds since the segment started: the elapsed time the GAME believes
## in, counted in the only unit the game has -- its own physics steps.
##
## Added 2026-08-28 from the run-2 BLOCKER. `route.csv`'s `t` and the §H
## recorder both read `_wall_t()`, and §D takes elapsed time,
## `since_interaction_s` and every dead-travel interval out of `route.csv`
## *precisely because* "harness wall time lies" (§D's own words). It was harness
## wall time. Distances were unaffected; every duration in the pacing study was
## inflated by the ratio between a 6.465 s frame and the 1/60 s the game thinks
## it just simulated -- a factor of about 388 on that box, and a different
## factor on any other, which is the part that makes the numbers uncomparable
## rather than merely large.
##
## `Engine.get_physics_frames()` is the right source and an accumulator is not:
## it advances on every physics step the engine actually ran, including the
## steps a slow rendered frame packs in (Godot runs up to
## `Engine.max_physics_steps_per_frame` of them per drawn frame), and it keeps
## advancing while the tree is paused -- which is most of a menu segment.
func _play_t() -> float:
	return float(Engine.get_physics_frames() - _t0_frames) \
		/ float(maxi(1, Engine.physics_ticks_per_second))


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
		"t": snappedf(_play_t(), 0.001),
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
	# CD-7's third half. Cheap by construction: it divides wall already spent by
	# frames already ticked, and only acts every `cost_recheck_frames`.
	_cost_recheck()
	if _play_t() >= _next_trace_t:
		_write_trace_row()
		_next_trace_t = _play_t() + (1.0 / maxf(0.1, float(_cfg["trace_hz"])))
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
		_play_t(), Time.get_datetime_string_from_system(true, true),
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
		# Spelled out rather than a ternary inside the call: `tests/test_gate_f_rig.gd`
		# checks that every §C.1 event type is emitted by SOMETHING, by looking
		# for the literal, and a type that only ever exists inside a conditional
		# expression reads to that check as a type nothing emits.
		if fighting:
			_emit("combat_start")
		else:
			_emit("combat_end")
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
	for i in party.size():
		var creature: Dictionary = party[i]
		var name := str(creature.get("name", ""))
		var level := int(creature.get("level", 0))
		# Keyed by SLOT INDEX, not `name`: two wild-caught creatures of the same
		# species share the same default label (a run's own party can carry
		# three creatures all called "Bramblebun" -- exactly what this segment's
		# own catch loop produces), and a name-keyed dict collapses them onto one
		# shared "previous hp" cell. Whichever same-named entry the loop visited
		# LAST each frame won that cell, so a fainted one and a healthy one
		# alternating which wrote last re-triggered the hp>0 -> hp<=0 edge on
		# every single tick -- measured on gate-f-run-20260901T220548Z-s03fix
		# attempt 6: 8733 "faint" events, nearly all repeats of one already-
		# fainted Bramblebun, one per physics frame for the rest of the segment.
		# Party order is stable absent an explicit reorder action, which this
		# loop never takes, so the slot index is the stable identity a shared
		# name is not.
		if _prev_levels.has(i) and level > int(_prev_levels[i]):
			_emit("level_up", {"observation": "%s reached level %d" % [name, level]})
		if float(creature.get("hp", 1.0)) <= 0.0 and float(_prev_levels.get("%d:hp" % i, 1.0)) > 0.0:
			_emit("faint", {"observation": "%s fainted" % name})
		_prev_levels[i] = level
		_prev_levels["%d:hp" % i] = creature.get("hp", 1.0)

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
	for i in party.size():
		var creature: Dictionary = party[i]
		# Keyed by slot index -- see the matching comment at the watch loop's
		# own use of _prev_levels for why `name` collides across same-species
		# party members.
		_prev_levels[i] = int(creature.get("level", 0))
		_prev_levels["%d:hp" % i] = creature.get("hp", 1.0)
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
	_record_next_t = _play_t()
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
