extends Node

## The thing that makes the save system happen to a player.
##
## `autoload/save_manager.gd` has been complete and tested since M4 — one
## envelope, one version, domains registering as contributors — and until this
## file existed, nothing in the shipping game ever called it. `SaveManager.save()`
## had callers in `tests/`, in `tools/play_session.gd`, and in the release
## ceremony. None of those are the game. A player who built a stronghold, caught
## four pals and closed the window lost all of it, and every automated check in
## the project passed while that was true, because they all called `save()`
## themselves.
##
## So the split is: SaveManager knows HOW to write a save. This knows WHEN.
##   - boot: restore slot 0 if it is there, start fresh in silence if it is not
##   - autosave: on a timer, and on the two events worth a checkpoint
##   - quit: the window close request writes before the process goes away
##
## Nothing else in the game should call `SaveManager.save()`. The one exception
## already in the tree is `release_prompt.gd`, which saves the instant a pal is
## released because that decision is irreversible and must not be able to be
## un-made by a crash; its own comment explains it. Anything else that wants a
## save should ask this node for one, so there is one place that knows a save is
## in flight and can refuse to start a second.


## --- tunable ---------------------------------------------------------------
##
## These would live in `data/config/` with the rest of the tunables, per
## CLAUDE.md. They are here instead because this file was written by an agent
## that did not own `data/config/`. They are TUNABLE NUMBERS, not mechanics, and
## moving them into `data/config/save.json` is a mechanical change nobody needs
## to think about.

## Seconds of gameplay between backstop autosaves.
##
## GAME_DESIGN §6 asks for "frequent autosave" and does not put a number on it.
## Two minutes is the interval for the things that have no event to hang off —
## walking, looting, levelling — while the two changes a player would be most
## upset to lose (a fight's outcome, a placed structure) do not wait for it at
## all. TUNABLE.
const AUTOSAVE_SECONDS := 120.0

## Minimum seconds between two writes.
##
## Building is the case this exists for: a player laying a floor grid places a
## piece every second or so, and one file write per wall is a stutter the player
## would read as the building system being slow. Requests inside the gap are
## COALESCED, not dropped — the pending one is written as soon as the gap has
## passed, so the last placement of a burst is still on disk a few seconds later.
## TUNABLE.
const MIN_WRITE_GAP := 5.0

## How long to wait at boot for `/root/SaveManager` to exist, in process frames.
##
## Under `--script` — every test, smoke and evidence session in this project —
## Godot attaches autoloads only after the entry script's `_init()` returns, so a
## harness that builds its world inside `_init()` reaches `_ready()` here with no
## singleton in the tree at all. See `docs/decisions/D14`. One frame is always
## enough; the budget is so that a scene genuinely running without the autoload
## says so instead of waiting forever.
const BOOT_WAIT_FRAMES := 120


## Which slot the running game uses. There is no slot-picking screen yet;
## GAME_DESIGN §6 wants 3–5 of them, and when that screen exists it sets this.
@export var slot: int = 0

## The two events worth a checkpoint. Both optional: a scene without them still
## autosaves on the timer and on quit.
@export var combat_path: NodePath
@export var build_path: NodePath


## Emitted after a write that landed. `reason` is why it happened, for the log.
signal wrote(reason: String)

## Emitted once, when boot has finished deciding. `restored` is false for a first
## run, which is not a failure.
signal boot_finished(restored: bool)


var _manager: Object = null
var _booted: bool = false
var _restored: bool = false

## Set for the duration of a `load_slot`, and for the duration of a `save`.
## A save started inside either would write a half-restored world over the file
## it was restored from.
var _loading: bool = false
var _writing: bool = false

## Why a write is owed, or empty. One string rather than a queue: two reasons to
## save are still one save.
var _pending: String = ""

var _since_write: float = 0.0
var _since_autosave: float = 0.0

var _writes: int = 0
var _last_reason: String = ""
var _last_write_usec: int = 0


func _ready() -> void:
	# `screen_stack.gd` sets `get_tree().paused` while a menu is open, which stops
	# `_process` on everything that has not opted out. A player who opens the menu
	# and walks away should still be autosaved, and — the part that actually
	# matters — a player who quits FROM a menu must still be saved, which needs
	# this node running when the close request arrives.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_boot()


## --- boot ------------------------------------------------------------------

func _boot() -> void:
	# ONE FRAME, UNCONDITIONALLY, BEFORE ANYTHING ELSE — including before looking
	# for the manager.
	#
	# `_ready()` propagates synchronously inside `add_child()`, children first. In
	# the REAL game the autoloads are already attached by the time the main scene
	# is built, so a `_boot()` that found the manager on its first look would run
	# to completion inside that propagation — restoring the save before
	# `structures._ready()` had loaded its piece catalogue and before
	# `party_manager._ready()` had made the party it was about to overwrite with
	# an empty one. Measured, exactly once, in `smoke_persistence`: a save file
	# on disk holding a pal and a door, a load that returned true, and a world
	# that came up with neither.
	#
	# It survived the first session of that same smoke because `--script` delays
	# the autoloads, so the poll below awaited anyway and the bug hid. Which is
	# the trap in both directions: the harness and the game disagree about when
	# `/root/SaveManager` exists, so the only safe answer is to never load during
	# `_ready()` under either of them.
	await get_tree().process_frame

	var manager: Object = null
	for _i in BOOT_WAIT_FRAMES:
		manager = get_node_or_null(^"/root/SaveManager")
		if manager != null:
			break
		await get_tree().process_frame
	if manager == null:
		push_warning("no SaveManager autoload after %d frames; this session will not be saved" % BOOT_WAIT_FRAMES)
		boot_finished.emit(false)
		return

	bind(manager)
	_register_contributors(manager)
	_connect_events()
	_restored = restore()
	begin()
	boot_finished.emit(_restored)


## Put every save contributor in the tree into the manager, BEFORE loading.
##
## This is the ordering bug the whole file is arranged around. Contributors
## register themselves in their own `_ready()`, and under `--script` the autoload
## does not exist yet when that runs — `structures.gd` and `party_manager.gd`
## both carry the comment, and both work around it by re-registering lazily when
## something calls their `save()`. Nothing calls their `save()` at boot. A load
## fired before they had re-registered would find an empty contributor list,
## restore nothing, return true, and look exactly like a first run.
##
## So the director does not hope they registered. It finds them and registers
## them itself, which is free because `SaveManager.register()` is idempotent by
## design. A contributor is any node carrying `save_data`, `load_data` and a
## `SAVE_DOMAIN` constant naming its key — the shape both existing domains
## already have, so neither of them had to be touched for this.
func _register_contributors(manager: Object) -> Array[String]:
	var found: Array[String] = []
	for node in get_tree().root.find_children("*", "", true, false):
		if not node.has_method("save_data") or not node.has_method("load_data"):
			continue
		var domain := _domain_of(node)
		if domain.is_empty():
			# Loud, because this is a system that believes it is being saved and
			# is not. The alternative is a save file quietly missing a domain.
			push_warning("%s has save_data()/load_data() but no SAVE_DOMAIN const; it will not be saved" % node.get_path())
			continue
		manager.call("register", domain, node)
		found.append(domain)
	if found.is_empty():
		push_warning("no save contributors found in the tree; a save would be an empty envelope")
	return found


func _domain_of(node: Node) -> String:
	var script := node.get_script() as GDScript
	if script == null:
		return ""
	return str(script.get_script_constant_map().get("SAVE_DOMAIN", ""))


## The two events that earn a checkpoint of their own.
##
## A fight ENDING, because that is the moment everything a fight can change —
## HP, XP, a caught pal, spent orbs — has finished changing, and because it is
## the point a player has just risked something and would be most sour about
## repeating.
##
## A structure being PLACED, because a stronghold is the most expensive thing in
## the game to rebuild by hand, and because `build_mode.placed` is emitted by the
## one door placement goes through.
##
## `party_manager.changed` was considered and rejected: it fires every time the
## player cycles which pal is deployed, which is a D-pad tap, not a checkpoint.
## Every party change that matters — catching, fainting, levelling — is inside a
## fight and is covered by the fight ending.
func _connect_events() -> void:
	var combat := get_node_or_null(combat_path)
	if combat != null and combat.has_signal("exited"):
		combat.connect("exited", _on_combat_exited)
	var build := get_node_or_null(build_path)
	if build != null and build.has_signal("placed"):
		build.connect("placed", _on_structure_placed)


func _on_combat_exited(outcome: String) -> void:
	request_save("fight ended (%s)" % outcome)


func _on_structure_placed(piece_id: String) -> void:
	request_save("placed %s" % piece_id)


## --- the seam boot and the tests share -------------------------------------

## Hand the director its manager. Boot does this with the autoload; a unit test
## does it with a stand-in, which is the only way to exercise the scheduling
## without a scene.
func bind(manager: Object) -> void:
	_manager = manager


## Start the clock. Nothing writes before this, so a request that arrives while
## boot is still deciding cannot land on top of the file boot is reading.
##
## `_since_write` starts AT the gap rather than at zero: the first thing a player
## does after loading in should be saved when they do it, not five seconds later.
func begin() -> void:
	_booted = true
	_since_write = MIN_WRITE_GAP
	_since_autosave = 0.0


## Put slot `slot` back, if it is there. Returns true only if something was
## restored.
##
## An absent slot is a FIRST RUN, not a fault: no warning, no error, no dialog.
## The player pressed New Game; the console saying so once is the whole report.
func restore() -> bool:
	if _manager == null:
		return false
	if _writing:
		push_warning("refusing to load while a save is being written")
		return false
	if not bool(_manager.call("has_slot", slot)):
		print("[save] slot %d is empty; starting a new world" % slot)
		return false

	_loading = true
	var ok := bool(_manager.call("load_slot", slot))
	_loading = false
	if ok:
		print("[save] restored slot %d" % slot)
	else:
		# SaveManager has already said which of the three refusals it was
		# (unreadable, unparseable, wrong version) and left the world untouched.
		push_warning("slot %d exists but could not be loaded; continuing with a fresh world" % slot)
	return ok


## --- writing ---------------------------------------------------------------

## Ask for a save soon. Coalesced: several requests inside `MIN_WRITE_GAP` become
## one write. This is what gameplay code should call.
func request_save(reason: String) -> void:
	if not _booted:
		return
	_pending = reason


## Write now, if it is safe to. Returns whether the file landed.
##
## The two guards are the whole reason saving goes through one node: `_loading`
## stops a save being written from a half-restored world, and `_writing` stops a
## second save starting inside the first one — which a contributor's `save_data()`
## could otherwise cause by emitting a signal something else saves on.
func save_now(reason: String) -> bool:
	if _loading:
		push_warning("refusing to save '%s' during a load" % reason)
		return false
	if _writing:
		push_warning("refusing to save '%s'; a save is already being written" % reason)
		return false
	if _manager == null:
		push_warning("cannot save '%s': there is no SaveManager" % reason)
		return false

	_pending = ""
	_since_write = 0.0
	_since_autosave = 0.0

	_writing = true
	var started := Time.get_ticks_usec()
	var ok := false
	ok = bool(_manager.call("save", slot))
	_last_write_usec = Time.get_ticks_usec() - started
	_writing = false

	if not ok:
		# SaveManager has already pushed the path it could not open. This says
		# what the player lost, which is the half nobody can work out from a
		# file-open error.
		push_error("save failed (%s); this session's progress is not on disk" % reason)
		return false

	_writes += 1
	_last_reason = reason
	wrote.emit(reason)
	return true


func _process(delta: float) -> void:
	tick(delta)


## The scheduler, split out so it can be driven a frame at a time by a test
## without a tree, a clock or a scene.
func tick(delta: float) -> void:
	if not _booted:
		return
	_since_write += delta
	_since_autosave += delta
	if _since_autosave >= AUTOSAVE_SECONDS:
		# Set here rather than written here, so the timer obeys the same gap
		# everything else does and cannot land on top of an event save.
		_pending = "autosave"
		_since_autosave = 0.0
	if not _pending.is_empty() and _since_write >= MIN_WRITE_GAP:
		save_now(_pending)


## --- quit ------------------------------------------------------------------

## Save on the way out.
##
## `auto_accept_quit` is deliberately LEFT ALONE. Turning it off would make the
## game's ability to close depend on this function returning, and a save that
## throws would become a window that will not shut. Godot propagates
## NOTIFICATION_WM_CLOSE_REQUEST to the tree BEFORE it acts on `auto_accept_quit`,
## so writing here happens first and the default quit still happens after,
## whatever this does.
##
## GO_BACK_REQUEST is the Android/console back button. Nothing in the project
## targets those yet and `quit_on_go_back` is at its default, but it is the same
## event as far as a save is concerned and costs one line to be right about.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if not _booted:
			return
		save_now("quit")


## --- what happened, for tests and the log ----------------------------------

func is_booted() -> bool:
	return _booted


func restored_at_boot() -> bool:
	return _restored


func writes() -> int:
	return _writes


func last_reason() -> String:
	return _last_reason


## Microseconds the last write took, measured around `SaveManager.save()`.
func last_write_usec() -> int:
	return _last_write_usec


func has_pending() -> bool:
	return not _pending.is_empty()
