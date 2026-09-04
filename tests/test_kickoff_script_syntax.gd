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
