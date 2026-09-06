extends RefCounted

## D97 / Stage B lane MP-REALM-REOPEN. THE TIME SLICE A REALM SHELL BUILDS IN.
##
## A realm shell is the host building a whole second world while people are
## playing in the first one. Lane 6.A stood one up with a plain `add_child()`,
## and `add_child()` is what runs the world root's `_ready()` -- which is the
## entire world build, on the host's main thread, inside one call.
##
## Measured on a 4 vCPU box with `tools/net/_probe_6a_shell.gd`:
##
##   Cloudreach shell   worst single frame 21.9 s   worst 60-frame window 22.8 s
##   Meadows shell      worst single frame 30.5 s   worst 60-frame window 41.2 s
##
## Both numbers are the same freeze seen two ways, and 60 frames is the one
## that decides whether the feature can ship: `tools/net/peer_runner.gd`
## heartbeats every 60 PHYSICS frames and `tests/helpers/net_harness.gd` calls
## a peer silent after 15 s of no heartbeat. A host that needs 22 s to get
## through 60 frames is a host every other player has already lost.
##
## ## Why spreading the build over a handful of frames is NOT enough
##
## The obvious fix -- one `await` between each top-level build step -- fails
## this criterion even though it looks like it should pass. Sixty consecutive
## physics frames on an idle server span about one second, so a build cut into
## fourteen one-and-a-half-second steps still puts every one of those steps
## inside a single 60-frame window: the same 22 s, still no heartbeat. What
## the window actually needs is for sixty frames to KEEP HAPPENING while the
## build runs, which means bounding the work in each individual frame rather
## than counting the pieces.
##
## So this is a time slice, not a step counter. `breathe()` is called inside
## the build's own loops and yields the moment this frame has spent its budget
## on world building. The build takes longer in wall-clock terms and the host
## runs at a reduced frame rate for the duration -- which is the honest cost,
## and is stated as such in `ralph/reports/MP-REALM-REOPEN-0906/REPORT.md` --
## but no frame is ever held, so the session survives and so does everyone
## standing in it.
##
## ## Inert outside a shell
##
## `begin(world, false)` makes every call here a synchronous no-op that does
## not yield, so a player crossing into a realm for real still gets the world
## built before the first frame is drawn, exactly as it always was. GDScript's
## `await` on a coroutine that returns without suspending resumes immediately
## in the same frame, so the awaits threaded through the world scripts cost a
## live build nothing. That is what keeps `smoke_cloudreach_transition` and
## `smoke_cloudreach_arrival_walk` unchanged.

const PERF_CONFIG := preload("res://scripts/world/performance_config.gd")

## How many milliseconds of world building one frame may do while a shell is
## standing up. Overridable as `shell_build_budget_ms` in
## `data/config/performance.json`.
##
## 8 ms is half a 60 Hz frame: the host keeps drawing, at a visibly reduced
## rate, instead of stopping. Lower is smoother and slower; higher approaches
## the freeze this exists to remove.
const DEFAULT_BUDGET_MS := 8

## The budget for the OTHER sliced case: a peer building a real world for
## itself -- the player who actually walked through the gate -- while a session
## is live. Measured on the same box, this build blocks for about 21 s
## (Cloudreach) with nothing sliced, and `smoke_net_split_realms` failed on
## exactly that after the shell was fixed: the CLIENT went heartbeat-silent
## crossing into Cloudreach, on its own ordinary `change_scene_to_file()`.
##
## That is a different problem from the host's and wants a different answer.
## Nobody else is waiting on this peer's frames -- it is looking at a loading
## transition and expects to. What it cannot afford is going quiet: a peer that
## stops pumping its `MultiplayerAPI` for twenty seconds is a peer ENet and the
## harness both give up on. So the slice here is coarse -- the build stays
## nearly as fast as it was -- and its only job is that frames keep happening.
##
## Solo play is NOT sliced at any budget. `begin()` asks the session, and with
## no session it slices nothing, so single-player boot is byte-for-byte the
## build it always was.
const CROSSING_BUDGET_MS := 100

## `tools/net/peer_runner.gd` heartbeats every 60 PHYSICS frames and
## `tests/helpers/net_harness.gd` declares a peer silent after 15 s without
## one. Everything below is written against those two numbers.
const HEARTBEAT_FRAMES := 60

## A slice at or above this is treated as INDIVISIBLE -- Terrain3D loading the
## Meadows' baked region data is one engine call that holds the frame for
## about 7.6 s and no amount of GDScript slicing touches it. What can be done
## about a slice like that is make sure it does not have to SHARE a heartbeat
## window: it is followed by a whole window of cheap frames, so the worst
## 60-frame window is that one slice plus idle rather than that slice plus
## everything else the build was doing around it. Measured on the Meadows
## shell: the same build reads 13.8 s worst window without this and 8-9 s
## with it, against a 15 s limit.
const LONG_SLICE_MS := 250

var _tree: SceneTree = null
var _active := false
var _budget_ms := DEFAULT_BUDGET_MS
var _frame_started_ms := 0
var _step_started_ms := 0
var _yields := 0
var _steps: Array[String] = []
## The longest stretch of build work between two yields, and the step it fell
## in. This is the number that decides whether the slicing is fine-grained
## enough: an indivisible 8 s call is still an 8 s held frame however many
## yields surround it.
var _worst_slice_ms := 0
## How many slices were long enough to be given a heartbeat window to
## themselves. Reported so the wall-clock cost of that policy is visible.
var _paybacks := 0
var _worst_slice_step := ""
var _current_step := "boot"
var _began_ms := 0


## Decide whether this build is sliced at all, and how finely. `shell` is the
## world's own `simulation_only`.
##
## Three cases, and only the third is the common one:
##
##   1. a SHELL on a host -- the finest slice, because other people are
##      playing in a different world on this same process and every
##      millisecond spent here is taken from them;
##   2. a real world build during a LIVE MULTI-PEER SESSION -- a coarse slice.
##      This is the player who walked through the gate, building their own
##      destination. They are looking at a loading transition and know it; the
##      only thing that must survive is their connection;
##   3. everything else, which is all of single-player -- not sliced, not
##      yielded, not changed in any way. Every `await` on this object resumes
##      in the same frame.
func begin(world: Node, shell: bool) -> void:
	_active = world != null and world.is_inside_tree()
	if not _active:
		return
	_tree = world.get_tree()
	_active = _tree != null
	if not _active:
		return
	var cfg := PERF_CONFIG.config()
	if shell:
		_budget_ms = DEFAULT_BUDGET_MS
		if cfg.has("shell_build_budget_ms"):
			_budget_ms = maxi(1, int(cfg["shell_build_budget_ms"]))
	elif _in_live_session(world):
		_budget_ms = CROSSING_BUDGET_MS
		if cfg.has("crossing_build_budget_ms"):
			_budget_ms = maxi(1, int(cfg["crossing_build_budget_ms"]))
	else:
		_active = false
		return
	_frame_started_ms = Time.get_ticks_msec()
	_step_started_ms = _frame_started_ms
	_began_ms = _frame_started_ms


## Yield IF this frame has already spent its build budget. Call it inside the
## build's own loops -- per region, per landmark, per scatter batch -- not only
## between them: a single loop that runs for eight seconds is the whole
## problem, and a yield placed after it does not help.
func breathe() -> void:
	if not _active:
		return
	var slice := Time.get_ticks_msec() - _frame_started_ms
	if slice < _budget_ms:
		return
	_note_slice(slice)
	await _let_frames_out(slice)


## `breathe()`, plus a named record of what the build has just finished, so a
## shell prints its own profile once and the next lane does not have to
## re-derive where the time goes. Yields unconditionally: a step boundary is a
## natural place to let a frame out even if this one has budget left.
func step(label: String) -> void:
	if not _active:
		return
	var now := Time.get_ticks_msec()
	_steps.append("%s=%d" % [label, now - _step_started_ms])
	_note_slice(now - _frame_started_ms)
	await _let_frames_out(now - _frame_started_ms)
	_step_started_ms = _frame_started_ms
	# The label of the step just FINISHED, so the next slice recorded is
	# attributed as "the step after this one" rather than to itself.
	_current_step = label


## One frame normally; a whole heartbeat window after an indivisible slice.
## Physics frames rather than process frames because the heartbeat this is
## protecting is sent from `_physics_process`.
func _let_frames_out(slice_ms: int) -> void:
	var frames := 1
	if slice_ms >= LONG_SLICE_MS:
		frames = HEARTBEAT_FRAMES + 5
		_paybacks += 1
	for i in frames:
		await _tree.physics_frame
	_yields += frames
	_frame_started_ms = Time.get_ticks_msec()


## Ask the SESSION, never `multiplayer.is_server()` -- with no session Godot
## installs an `OfflineMultiplayerPeer` under which every multiplayer question
## answers as though a session existed. `realm_shells.gd`'s own header carries
## the full account of what that cost the first time.
func _in_live_session(world: Node) -> bool:
	var game := world.get_node_or_null(^"/root/Game")
	if game == null or not game.has_method("is_multi_peer"):
		return false
	return bool(game.call("is_multi_peer"))


func _note_slice(slice_ms: int) -> void:
	if slice_ms > _worst_slice_ms:
		_worst_slice_ms = slice_ms
		_worst_slice_step = _current_step


## One line, printed by the world at the end of its own `_ready()`.
func summary() -> String:
	if not _active:
		return ""
	return ("%.1f s wall, %d yields at %d ms/frame, %d indivisible slices given a "
		+ "heartbeat window each, worst held slice %d ms (in the step following '%s'); "
		+ "steps (ms): %s") % [
		(Time.get_ticks_msec() - _began_ms) / 1000.0, _yields, _budget_ms, _paybacks,
		_worst_slice_ms, _worst_slice_step, " ".join(_steps)]
