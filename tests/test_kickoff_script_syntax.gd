extends "res://tests/test_case.gd"

## `tools/owner/kickoff.ps1` -- the one script the owner double-clicks.
##
## Why a GDScript test guards a PowerShell file. This repo's CI has no Windows
## runner, so nothing executes this script before it reaches the owner's
## machine; the first parse is on their ROG Ally, and a parse error there costs
## a whole evidence run and the trip to report it. That is exactly what
## happened on 2026-09-04: the kickoff aborted with `exit code 1` and a wall of
## `Variable reference is not valid. ':' was not followed by a valid variable
## name character`, and none of the run happened.
##
## The defect class, stated once so it is not reintroduced. Inside an
## expandable (double-quoted) PowerShell string, `$Seg:` is not "the variable
## Seg followed by a colon" -- the parser reads `Seg:` as a DRIVE OR SCOPE
## qualifier, the way `$env:PATH` and `$script:Repo` work, and then fails
## because a space is not a valid variable-name character. The fix is
## `${Seg}:`, which ends the variable name explicitly. Real qualifiers
## (`script:`, `env:`, `global:`, `using:`, `local:`, `private:`) are correct
## and are allowed here.
##
## This is a text check, not a parse: it cannot prove the script runs. It
## catches one specific, silent, expensive mistake, which is the one that has
## actually been made.

const KICKOFF := "res://tools/owner/kickoff.ps1"
const OPENING_SEGMENTS: Array[String] = [
	"res://tools/gate_f/segments/S01.json",
	"res://tools/gate_f/segments/S02.json",
	"res://tools/gate_f/segments/S02C.json",
]

const REAL_QUALIFIERS: Array[String] = [
	"script", "env", "global", "using", "local", "private",
]


func test_no_interpolation_is_read_as_a_drive_qualified_variable() -> void:
	var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(KICKOFF))
	assert_false(text.is_empty(), "kickoff.ps1 is missing or unreadable; this test would prove nothing")

	var offenders: Array[String] = []
	var lines := text.split("\n")
	for index in lines.size():
		var line: String = lines[index]
		# Only expandable strings interpolate. A single-quoted PowerShell string
		# is literal, so `'$Seg: ...'` is fine and must not be flagged.
		if not line.contains("\""):
			continue
		var regex := RegEx.new()
		regex.compile("\\$([A-Za-z_][A-Za-z0-9_]*):")
		for found: RegExMatch in regex.search_all(line):
			var name := found.get_string(1)
			if REAL_QUALIFIERS.has(name):
				continue
			offenders.append("line %d: $%s: -- write ${%s}: instead" % [index + 1, name, name])

	assert_true(offenders.is_empty(),
		"kickoff.ps1 interpolates a variable immediately followed by a colon, which "
		+ "PowerShell parses as a drive/scope qualifier and refuses:\n  "
		+ "\n  ".join(offenders))


func test_logic_journey_lanes_do_not_record_fixed_fps_movies() -> void:
	var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(KICKOFF)).replace("\r\n", "\n")
	assert_true(text.contains(
		"foreach ($seg in $Journey) {\n    Run-Segment $seg $false $false"),
		"logic journey lanes must run without Movie Maker; their production frames belong to the capture lanes")
	assert_false(text.contains(
		"foreach ($seg in $Journey) { Run-Segment $seg $false $true }"),
		"fixed-FPS movies turn long logic waits into multi-hour encodes and trip pre-flight before gameplay")


func test_opening_segments_choose_a_character_before_waiting_for_the_world() -> void:
	for path in OPENING_SEGMENTS:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_true(parsed is Dictionary, "%s must parse" % path)
		if not parsed is Dictionary:
			continue
		var actions: Array[String] = []
		var confirms_name := false
		for raw: Variant in (parsed as Dictionary).get("steps", []):
			if raw is Dictionary:
				var step := raw as Dictionary
				if str(step.get("action", "")) == "press" \
						and str((step.get("args", {}) as Dictionary).get("control", "")) == "ui_accept":
					actions.append(str(step.get("id", "")))
				elif str(step.get("action", "")) == "type_name" \
						and str((step.get("args", {}) as Dictionary).get("name", "")) == "Arlo":
					confirms_name = true
				elif str(step.get("action", "")) == "wait":
					break
		assert_true(actions.size() >= 2,
			"%s must select Start New Game and then the focused production character card before its world wait" % path)
		assert_true(confirms_name,
			"%s must confirm the mandatory production trainer-name prefill before its world wait" % path)
