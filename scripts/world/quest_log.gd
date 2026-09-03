extends RefCounted

## SB11: the smallest reader over SB9's flag store that turns
## `data/progression/objectives.json` into the HUD's one tracked line and the
## menu's two-list quest log (spec §16). Invents no state of its own -- every
## answer here is a pure function of `progression_state.gd`'s flags plus this
## static data, so there is nothing here to save/load and nothing that can
## drift out of sync with `progression`.
##
## Deliberately NOT a quest engine (spec §19, CLAUDE.md): no branching, no
## prerequisites. An entry is DONE the instant its own `flag_id` is set -- or,
## for an entry carrying `retired_by` (T5-STORY-2), once that single flag says
## its moment has passed; see `_done()` for the measured chapter-scale failure
## that answer exists for, and OBJECTIVE-CAMP-0903 for the second, unrelated
## rung it now also covers. The tracked line is still just the first "main"
## entry not yet done, in file order.
##
## TUTORIAL-CHAIN (OP23-04) added the second and third, both PRESENTATION and
## neither a prerequisite:
##
## - `how`: an entry may carry one short line naming the concrete action and
##   the controller verb for it. `{action}` placeholders are project.godot
##   input-action ids, resolved here through `input_glyph.gd` so the hint
##   names the button the player has actually bound.
## - `guided_entries()`: what is DONE, plus the ONE current rung, and nothing
##   after it. The owner's directive is a chain that "tells you the NEXT thing
##   to do ... one step at a time like Palworld's early game, never fronting
##   the full list", and this is that rule -- ONE uniform sentence about
##   presentation, applied to the whole list. It is not branching: no entry
##   carries a condition, nothing is skipped, and the underlying order is
##   still file order. `main_entries()` is untouched and still returns the
##   whole chain, because the two questions are genuinely different -- "what
##   is authored" and "what may the player see".
##
## SF34 added the first exception, and kept it as small as it sounds: an entry
## may carry `count_flags`, a list of flags whose set-count is appended to its
## label as " n/total" (spec §16's own example line is "Defeat the Upper
## Meadows captains. 2/3"). It changes nothing about DONE — that is still the
## entry's own `flag_id` — and an entry without `count_flags` renders exactly
## as it did before. See `data/progression/objectives.json`'s own comment for
## why this is not the counter system §19 bans.

const DATA_PATH := "res://data/progression/objectives.json"
## For `how`'s `{action}` placeholders only. `input_glyph.gd` is a pure static
## reader over `InputMap`; it stands up no node and needs no scene tree, so
## this file stays as headlessly testable as it was.
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")

var _main: Array = []
var _local: Array = []


func _init() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("quest_log.gd: %s missing" % DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("quest_log.gd: %s is not a JSON object" % DATA_PATH)
		return
	var data := parsed as Dictionary
	var main_raw: Variant = data.get("main", [])
	var local_raw: Variant = data.get("local", [])
	_main = main_raw if typeof(main_raw) == TYPE_ARRAY else []
	_local = local_raw if typeof(local_raw) == TYPE_ARRAY else []


## The Main Story list, `{label, done, how}` in file order -- the WHOLE chain,
## authored order, nothing hidden. `guided_entries()` below is what the player
## is shown; this is what exists.
func main_entries(progression: RefCounted) -> Array:
	return _entries(_main, progression)


## The Local Requests list, same shape. Not guided: an optional request is
## revealed by meeting the person who asks for it (`revealed_by`), which is
## already its own one-at-a-time rule.
func local_entries(progression: RefCounted) -> Array:
	return _entries(_local, progression)


func _entries(source: Array, progression: RefCounted) -> Array:
	var out: Array = []
	for raw: Variant in source:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry := raw as Dictionary
		# `revealed_by` (optional, BAND1-D1): the entry does not exist for the
		# player until that flag is set. Absent means always listed, which is
		# every entry that existed before this and every Main Story beat, so
		# nothing already in the file changes.
		#
		# It exists because optional content and the Main Story want opposite
		# things from this list. A main beat should be visible before you do
		# it -- that is the whole point of a tracked objective. An optional
		# one should not: prompt 30's rule is that some optional content is
		# discoverable through curiosity rather than a quest giver and that
		# secrets are not pre-labelled from game start, and an entry reading
		# "Beat the Old Champion" on a fresh save tells the player about a man
		# they have not met, in a field they have not walked to. This panel's
		# own empty state says "Nothing outstanding right now", which is a
		# promise that what is listed is something the player actually knows
		# about.
		if _hidden(entry, progression):
			continue
		out.append({
			"label": _label(entry, progression),
			"done": _done(entry, progression),
			"how": hint_text(entry),
		})
	return out


## Is this entry not yet part of the player's world at all? `revealed_by`
## (optional, BAND1-D1) is the only thing that can say so; see `_entries()`.
func _hidden(entry: Dictionary, progression: RefCounted) -> bool:
	var revealed_by := str(entry.get("revealed_by", ""))
	return not revealed_by.is_empty() and not bool(progression.call("has", revealed_by))


## Is this entry behind the player?
##
## Normally that is exactly its own `flag_id`. `retired_by` (optional,
## T5-STORY-2) adds the second answer: **this rung's moment has passed**,
## whatever its own flag says now.
##
## It exists because of one measured, chapter-scale failure.
## `tournament_team_fed` is the chain's one VOLATILE flag -- `tournament.gd`'s
## `_process` rewrites it from the live team once a second, for the whole game,
## with no gate on whether the tournament is still ahead. `tracked_text()` is
## "first unset flag in file order", so the moment a team goes hungry -- which,
## on a ~1.1/min satiety drain across a three-to-four-hour chapter, is most of
## it -- the HUD's one tracked line snaps back to "Feed your team before you
## sign up" and STAYS there. Measured by `tools/_probe_story_drive.gd`: walking
## the chapter's own flags in order, that string was the tracked line at every
## rung from the tournament run-up to the end of the chapter, the Warden and the
## freeing included. The game's single answer to "what now" spent the last two
## thirds of its own story naming a tutorial about food.
##
## `retired_by` is deliberately the same shape as `revealed_by` above and not a
## gram more: ONE flag id, checked with `has`, no arrays, no `unless`, no
## nesting, no per-entry visibility beyond the one `revealed_by` already
## established. It is the mirror of it -- one says "not yet", this says "no
## longer" -- and it is not the prerequisite graph spec sec19 and CLAUDE.md ban,
## because it cannot express an order the file does not already have.
##
## A retired rung reads as DONE rather than vanishing. That is the honest
## reading: a player standing at the Warden with `tournament_entered` set did
## feed their team before they signed up, months of game-time ago, and the log
## is a record of what they have done.
##
## OBJECTIVE-CAMP-0903 gave the mechanism its second user: `home_built` retires
## `home_materials_gathered` (owner playtest 2026-09-03 item 1 -- a camp built
## in free-build mode never triggers the tracked harvest that sets the gather
## flag, so the rung outlived the camp it exists for). Same shape, same
## honesty -- a camp standing IS the proof gathering happened, whichever route
## got there.
func _done(entry: Dictionary, progression: RefCounted) -> bool:
	var retired_by := str(entry.get("retired_by", ""))
	if not retired_by.is_empty() and bool(progression.call("has", retired_by)):
		return true
	var flag_id := str(entry.get("flag_id", ""))
	return not flag_id.is_empty() and bool(progression.call("has", flag_id))


## The guided view (TUTORIAL-CHAIN / OP23-04): every Main Story entry the
## player has finished, plus the one they are on, and nothing beyond it.
##
## Empty only when the chain itself is empty; a chapter with everything done
## returns every entry and no open one, which is the finished state the tab's
## own header describes. The current rung is always the LAST element when one
## is open, so a caller wanting to draw it differently does not have to
## re-derive which it is -- `current_index()` says so directly.
##
## OUT-OF-ORDER COMPLETION. `objectives.json` has always allowed a later beat's
## flag to be set early, and this stops short of it exactly as it stops short
## of any other unreached beat: the row is not shown, even though it is done.
## That is the right answer to both halves of the promise -- the tracked line
## still steps over it when the player gets there (`tracked_text()` is
## unchanged), and until then the log does not tell them about a beat they have
## not reached. Pinned by
## `test_finishing_a_later_beat_early_neither_strands_nor_spoils_the_chain`.
func guided_entries(progression: RefCounted) -> Array:
	var out: Array = []
	for entry: Variant in main_entries(progression):
		out.append(entry)
		if not bool((entry as Dictionary).get("done", false)):
			break
	return out


## Where the current rung sits in `guided_entries()`, or -1 when the chapter is
## finished and nothing is open.
func current_index(progression: RefCounted) -> int:
	var guided := guided_entries(progression)
	if guided.is_empty():
		return -1
	var last: Dictionary = guided[guided.size() - 1] as Dictionary
	return -1 if bool(last.get("done", false)) else guided.size() - 1


## The entry's label, with SF34's " n/total" appended when it carries
## `count_flags`. One place, so the HUD's tracked line and the quest-log row
## can never disagree about the count.
func _label(entry: Dictionary, progression: RefCounted) -> String:
	var label := str(entry.get("label", ""))
	var raw: Variant = entry.get("count_flags", [])
	if typeof(raw) != TYPE_ARRAY:
		return label
	var flags := raw as Array
	if flags.is_empty():
		return label
	var have := 0
	for flag: Variant in flags:
		if bool(progression.call("has", str(flag))):
			have += 1
	return "%s %d/%d" % [label, have, flags.size()]


## An entry's `how` line with its `{action}` placeholders replaced by the real
## bound button for the live device -- "{interact} at the gate" -> "X at the
## gate" on a pad, "E at the gate" on a keyboard. "" when the entry authors no
## hint, and a caller must treat that as "draw nothing", never as a blank line.
##
## That used to read "which every beat past the opening ladder currently does".
## It no longer does: T5-STORY-2 wrote the eleven missing ones, so every Main
## Story rung in the chapter now carries a hint. The empty case is still real --
## an entry may author none, and `local` entries do not -- so the contract is
## unchanged and this is the only sentence about it that had to move.
##
## An unknown action id is left as the id itself rather than silently deleted,
## the same way `input_glyph.gd::icon()` shows "[typo]" instead of a gap: a
## hint that quietly loses half its sentence reads as authored prose and never
## gets fixed.
func hint_text(entry: Dictionary) -> String:
	var how := str(entry.get("how", ""))
	if how.is_empty():
		return ""
	var out := ""
	var rest := how
	while true:
		var open_at := rest.find("{")
		if open_at == -1:
			out += rest
			break
		var close_at := rest.find("}", open_at)
		if close_at == -1:
			out += rest
			break
		out += rest.substr(0, open_at)
		out += INPUT_GLYPH.action_name(rest.substr(open_at + 1, close_at - open_at - 1))
		rest = rest.substr(close_at + 1)
	return out


## The hint for the one tracked line, as a single string.
##
## The quest-log tab does not use this -- it reads `how` off the row it is
## already drawing -- so this exists for the OTHER surface the guidance
## belongs on: the HUD's objective block, under its tracked line.
##
## It is NOT wired there today, and that is a measurement rather than an
## oversight. That block is `OBJECTIVE_MAX_WIDTH` (420) wide with a 20px inset
## and a `HUD_READABLE_FONT_SIZE` (38) floor its own header fought a blind
## critic to win -- about twenty characters to a line. A hint long enough to
## name an action AND a button is four or five of those lines, which grows the
## block from 170px to nearly 300 on a HUD the owner has just reported
## (OP23-09) as taking far too much screen already. Shortening the hints until
## they fit costs the teaching that is the whole point of them.
##
## So the guidance lives in the quest log, where there is room for it, and this
## function waits for the HUD lane to re-proportion that corner -- the same
## "wired ahead of its caller" shape `input_glyph.gd`'s own build/torch entries
## document. Anyone giving it a home: measure the wrapped height first.
##
## "" when the chapter is finished or the current rung authors no `how`; a
## caller must draw that as nothing, never as a blank line.
func tracked_hint(progression: RefCounted) -> String:
	for raw: Variant in _main:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry := raw as Dictionary
		if _hidden(entry, progression):
			continue
		if not _done(entry, progression):
			return hint_text(entry)
	return ""


## Spec §16's one concise HUD line: the first Main Story entry not yet done,
## in file order. "" once every authored Main Story objective is complete --
## the chapter's later phases simply have not authored the next one yet, not
## a bug.
func tracked_text(progression: RefCounted) -> String:
	for raw: Variant in _main:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry := raw as Dictionary
		if not _done(entry, progression):
			return _label(entry, progression)
	return ""
