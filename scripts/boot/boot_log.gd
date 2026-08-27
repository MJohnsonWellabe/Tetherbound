extends RefCounted

## RB4: a startup diagnostic log for the ROG Ally's "Not Responding" freeze.
##
## Appends timestamped lines to user://boot_log.txt as the game passes each
## major startup phase. On an exported Windows build user:// resolves to
## %APPDATA%/Godot/app_userdata/Tetherbound/boot_log.txt — the same directory
## user://settings.json already writes to (D15).
##
## The freeze this chases leaves the process "Not Responding" rather than
## crashing, so it never gets a chance to write anything after the point it
## actually stalls — which line is LAST in the file on a frozen Ally is the
## whole diagnostic. Appends rather than truncates, because a killed-and-
## relaunched attempt must not erase the stalled run it was trying to
## capture; each launch gets its own marker line instead.
##
## Never fatal: if the file cannot be opened, the line is dropped, not boot.

const PATH := "user://boot_log.txt"

static var _marked_launch := false

## Ticks at the previous `phase()` call, so each line can carry the cost of the
## step that just finished rather than only when it finished.
static var _phase_started_ms: int = -1


## `line()`, plus the milliseconds since the last `phase()` call.
##
## GF-B-001: the plain timestamps this file already wrote were enough to see
## that New Game costs the better part of a minute, and not enough to say what
## it is spent on -- they carry one-second granularity and no per-step figure,
## so a reader has to subtract adjacent lines by hand and cannot separate a
## 900ms step from a 1.4s one at all. The stall is the product's first
## impression and it is going to take several passes to bring down; each of
## those passes needs to be able to say which number it moved.
##
## Costs one `Time.get_ticks_msec()` per boot phase. `boot_phase_ms()` hands the
## same figures back in-process so a probe can report them without parsing the
## file.
static func phase(message: String) -> void:
	var now := Time.get_ticks_msec()
	var elapsed := -1 if _phase_started_ms < 0 else now - _phase_started_ms
	_phase_started_ms = now
	if elapsed < 0:
		line("%s  [first phase]" % message)
	else:
		line("%s  [+%d ms]" % [message, elapsed])
	_phases.append([message, elapsed])


static var _phases: Array = []


## Every `phase()` recorded this launch, as `[[message, ms], ...]` with -1 for
## the first. Read by `tools/_probe_new_game_stall.gd`.
static func boot_phase_ms() -> Array:
	return _phases.duplicate(true)


static func line(message: String) -> void:
	var existed := FileAccess.file_exists(PATH)
	var file: FileAccess = FileAccess.open(PATH, FileAccess.READ_WRITE if existed else FileAccess.WRITE)
	if file == null:
		return
	if existed:
		file.seek_end()
	if not _marked_launch:
		_marked_launch = true
		file.store_line("=== launch %s (Godot %s) ===" % [
			Time.get_datetime_string_from_system(), Engine.get_version_info().string
		])
	file.store_line("[%s] %s" % [Time.get_datetime_string_from_system(), message])
	file.close()
