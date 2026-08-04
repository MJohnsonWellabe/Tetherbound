extends SceneTree

## Drive a system through the real game and write down what it did.
##
##   godot --headless --path . --script tools/play_session.gd -- party
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/play_session.gd -- party
##
## This produces the evidence a blind judge reads (`.claude/skills/systems-judge`).
## It is not a test: it asserts nothing and it never fails. Its whole job is to
## exercise a system in the real scene and record what the game did, so that
## somebody who has not seen the code can decide whether the milestone's
## acceptance bullets are met.
##
## THE ONE RULE THIS FILE HAS: **log facts, never conclusions.**
##
## `party is full, refused: "you can only keep five"` is a fact. `the five-pal
## cap works correctly` is a conclusion, and writing it here would hand the judge
## the answer instead of the evidence — which is the entire thing the blind gate
## exists to prevent. If a line in this file could be wrong while the game is
## right, or right while the game is wrong, it does not belong here.
##
## The corollary is uncomfortable and deliberate: a bullet this session does not
## exercise comes back NOT SHOWN, and the judge treats that as a failure. A
## harness that quietly skips the hard part produces a transcript full of
## silences, and the rubric is written to refuse on silences.
##
## Input is driven through the real actions, like every smoke test, so a broken
## binding shows up here rather than on the handheld.

const SCENE := "res://scenes/world/meadows_playground.tscn"

## Long enough for terrain to stream, collision to build and the director to
## place its creatures. Same figure the smokes use.
const SETTLE_FRAMES := 240

var _log: PackedStringArray = []
var _system: String = ""
var _shots: int = 0
var _world: Node = null

## What the director said about a pal it caught and could not keep. Recorded from
## its signal rather than asked for afterwards, because "the game caught a sixth
## creature while full" is an event, and an event you did not watch happen can
## only be inferred from state that several other things could also have produced.
var _refusals: int = 0
var _refused_token: String = ""
var _refused_instance: Object = null


func _init() -> void:
	_run()


func _run() -> void:
	_system = _requested_system()
	if _system == "":
		print("usage: play_session.gd -- <system>   (party | release | inventory | home)")
		quit(2)
		return

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	note("session: %s" % _system)
	note("scene: %s" % SCENE)

	match _system:
		"party":
			await _session_party()
		"release":
			await _session_release()
		_:
			note("no session is written for '%s' yet" % _system)

	_write()
	quit(0)


## --- the sessions ---------------------------------------------------------
##
## Each one walks the acceptance bullets of its milestone in order and records
## what the game did at each step. Where a bullet cannot be exercised yet, it
## says so IN THE LOG rather than skipping quietly — an admitted gap is evidence,
## a silent one is a lie by omission.

## M4 — Party.
##
## Written from the acceptance bullets in `docs/MEADOWS_VERTICAL_SLICE.md`
## BEFORE the system was built, and deliberately not adjusted afterwards to suit
## what got built. That ordering is the point: a session written from the
## implementation only ever exercises the parts that happen to work, and its
## silences are exactly where the bugs live.
##
## It walks the ten bullets in order. Anything missing is reported as missing —
## `probe()` below never crashes on an absent API, because a session that dies
## halfway produces a short transcript that reads like a clean run.
func _session_party() -> void:
	var party: Object = _find("Party")
	var director: Object = _find("EncounterDirector")
	var save: Object = root.get_node_or_null(^"/root/SaveManager")

	note("--- bullet: catch pal ---")
	await _catch_one(party)

	note("--- bullet: up to five pals ---")
	note("capacity reported: %s" % probe(party, "capacity"))
	note("size before filling: %s" % probe(party, "size"))

	# Fill the rest, then push past the ceiling. The refusal IS the bullet — a cap
	# that only holds because nothing ever leans on it is not a cap.
	var species: Array = ["starter_ground", "wild_rabbit", "wild_bristler"]
	for i in 6:
		var id: String = species[i % species.size()]
		var added: Variant = _add_pal(party, id)
		note("add #%d (%s): accepted=%s  size now=%s" % [i + 1, id, added, probe(party, "size")])
	note("refusal message: %s" % probe(party, "last_refusal"))
	note("size after pushing past the ceiling: %s" % probe(party, "size"))

	note("--- bullet: nickname ---")
	var to_name: Object = _member(party, 0)
	if to_name == null:
		note("no member to rename")
	else:
		note("name before renaming: %s (nickname field: '%s')" % [
			probe(to_name, "display"), field(to_name, "nickname")
		])
		# A name nothing could mistake for a default or a slot label. The first
		# version of this session named every pal "Pal1".."Pal5" as it added them,
		# which a blind reviewer correctly read as positional labels rather than
		# as evidence anybody could rename anything.
		note("rename to 'Thistle' accepted: %s" % probe(to_name, "rename", ["Thistle"]))
		note("name after renaming: %s (nickname field: '%s')" % [
			probe(to_name, "display"), field(to_name, "nickname")
		])
		# The refusal: an all-whitespace name must not leave a nameless pal.
		note("rename to '   ' accepted: %s" % probe(to_name, "rename", ["   "]))
		note("name after the refused rename: %s" % probe(to_name, "display"))
		# EVERY other member, not a sample. The first version printed two of the
		# three distinct species in the party, and a blind reviewer noticed the
		# omission — "a summary line that does not match the party it just
		# described is a line to fix before it is trusted on something less
		# checkable."
		var others: Array[String] = []
		for i in range(1, int(probe(party, "size"))):
			others.append(str(probe(_member(party, i), "display")))
		note("every other member, still unnamed: %s" % ", ".join(others))

	note("--- bullet: levels, HP/ATK/DEF, trait, nickname, appraisal ---")
	var first: Object = _member(party, 0)
	if first == null:
		note("no member at index 0; per-pal bullets unevidenced")
	else:
		note("member 0 display: %s" % probe(first, "display"))
		for name: String in ["level", "xp", "nickname", "trait_id", "hp", "max_hp", "attack", "defence"]:
			note("member 0 %s: %s" % [name, field(first, name)])
		note("member 0 appraisal: %s" % [probe(first, "appraisal")])
		if first.has_method("grant_xp"):
			var before: Variant = field(first, "level")
			first.call("grant_xp", 100000)
			note("after granting 100000 xp: level %s -> %s, max_hp now %s" % [
				before, field(first, "level"), field(first, "max_hp")
			])
		else:
			note("grant_xp: ABSENT — levelling unevidenced")

	note("--- bullet: switching ---")
	note("active index before: %s" % field(party, "active_index"))
	note("set_active(2) accepted: %s" % probe(party, "set_active", [2]))
	note("active index after: %s" % field(party, "active_index"))
	note("set_active(99) accepted: %s" % probe(party, "set_active", [99]))
	note("active index after out-of-range: %s" % field(party, "active_index"))

	note("--- bullet: persistent party data ---")
	var before_records: Variant = probe(party, "to_records")
	note("records before save: %s" % [before_records])
	if save != null and save.has_method("save"):
		note("save() returned: %s" % save.call("save", 0))
		# Clear in memory, then reload. Reading back a number the same object
		# still holds proves nothing about persistence.
		if party.has_method("clear"):
			party.call("clear")
			note("size after clearing in memory: %s" % probe(party, "size"))
		note("load_slot(0) returned: %s" % save.call("load_slot", 0))
		note("size after reload: %s" % probe(party, "size"))
		note("records after reload: %s" % [probe(party, "to_records")])
	else:
		note("SaveManager.save: ABSENT — persistence unevidenced")

	note("--- bullet: simple party menu ---")
	await _open_party_menu()


## M5 — Release ceremony.
##
## Written from the acceptance bullets WITHOUT reading the ceremony's
## implementation, and deliberately not adjusted afterwards to suit what got
## built. Nothing below calls a method that belongs to the ceremony: it presses
## the actions a player presses, reads back the text the game actually put on the
## screen, and compares the party before and after. A session written against the
## implementation only ever proves the implementation agrees with itself.
##
## The bullets, verbatim:
##   - Capture while full.
##   - Present six.
##   - Inspect meaningful info.
##   - Keep one / release one.
##   - Released pal leaves permanently.
func _session_release() -> void:
	var party: Object = _find("Party")
	var stack: Object = _find("ScreenStack")
	var director: Object = _find("EncounterDirector")
	var save: Object = root.get_node_or_null(^"/root/SaveManager")

	# The director announces a creature it caught and could not hand to the party.
	# Connected BEFORE anything is caught, so the transcript records the event and
	# not a state left behind by it.
	if director != null and director.has_signal("caught_refused"):
		director.connect("caught_refused", _on_caught_refused)
		note("listening to the director's 'caught_refused' signal")
	else:
		note("director's 'caught_refused' signal: ABSENT — a catch made while full cannot be witnessed as an event")

	# Start from no save file at all, so that everything read back off the disk at
	# the end was written by THIS session. A reload that loads a file an earlier
	# run left behind is not evidence about this one.
	if save != null and save.has_method("has_slot"):
		note("save slot 0 existed before this session: %s" % save.call("has_slot", 0))
		note("deleted save slot 0 before starting: %s" % probe(save, "delete_slot", [0]))
		note("save slot 0 exists now: %s" % probe(save, "has_slot", [0]))
	else:
		note("SaveManager: ABSENT — nothing in this session can speak to persistence")

	note("--- bullet: capture while full — first, fill the party by catching ---")
	note("capacity reported: %s" % probe(party, "capacity"))
	note("party at session start: size %s = %s" % [
		probe(party, "size"), ", ".join(_names(party))
	])

	# Filled by CATCHING, one creature at a time, not by handing the party five
	# instances. "Capture while full" is a bullet about what happens at the sixth
	# catch, and a party filled by fiat has never been caught into.
	var capacity: int = int(probe(party, "capacity"))
	for attempt in 10:
		if int(probe(party, "size")) >= capacity:
			break
		note("- catch %d, to fill the party -" % (attempt + 1))
		await _wait_for_wild()
		await _attempt_catch(party, false)
		note("party size now: %s (%s)" % [probe(party, "size"), ", ".join(_names(party))])

	if int(probe(party, "size")) < capacity:
		# Said plainly rather than papered over: the judge has to be able to weigh
		# how the party got full.
		note("THE SESSION COULD NOT FILL THE PARTY BY CATCHING; the remaining slots below were")
		note("filled by handing instances to the party directly. Those are not catches.")
		for i in 6:
			if int(probe(party, "size")) >= capacity:
				break
			note("direct add (%s): accepted=%s  size now=%s" % [
				"wild_rabbit", _add_pal(party, "wild_rabbit"), probe(party, "size")
			])

	# Distinct names, so that "which pal left" has one unambiguous answer later.
	# Renaming is M4's bullet and is evidenced in the party session; it is used
	# here only to tell six creatures of three species apart in a transcript.
	note("--- setup: give each member a distinct name so six pals can be told apart ---")
	var chosen: Array[String] = ["Thistle", "Bracken", "Sorrel", "Clover", "Nettle"]
	for i in int(probe(party, "size")):
		var member: Object = _member(party, i)
		var was: Variant = probe(member, "display")
		note("member %d renamed '%s' -> '%s': accepted=%s" % [
			i, was, chosen[i % chosen.size()], probe(member, "rename", [chosen[i % chosen.size()]])
		])

	note("--- the party immediately before the sixth catch ---")
	note("size: %s   capacity: %s   full: %s" % [
		probe(party, "size"), probe(party, "capacity"),
		int(probe(party, "size")) >= capacity
	])
	var full_names: PackedStringArray = _names(party)
	note("the five: %s" % ", ".join(full_names))
	for i in int(probe(party, "size")):
		var member: Object = _member(party, i)
		note("  member %d: %s  species=%s  level=%s  hp=%s/%s  trait=%s" % [
			i, probe(member, "display"), field(member, "species_id"), field(member, "level"),
			field(member, "hp"), field(member, "max_hp"), field(member, "trait_id")
		])
	note("records: %s" % [probe(party, "to_records")])
	note("one more add offered to a full party: accepted=%s, refusal='%s'" % [
		_add_pal(party, "wild_rabbit"), probe(party, "last_refusal")
	])

	note("--- bullet: capture while full — now catch a sixth ---")
	await _wait_for_wild()
	var caught_sixth: bool = await _attempt_catch(party, true)
	note("party size straight after the sixth catch: %s" % probe(party, "size"))
	note("times the director reported a caught pal it could not keep: %d" % _refusals)
	note("the pal caught while full: %s (species %s)" % [
		probe(_refused_instance, "display"), field(_refused_instance, "species_id")
	])
	if _refused_instance != null:
		note("its appraisal: %s" % [probe(_refused_instance, "appraisal")])

	# The six the player is choosing between: the five they had, plus the one just
	# caught. Named here so every later line can be checked against this list.
	var six: PackedStringArray = full_names.duplicate()
	if _refused_instance != null:
		six.append(str(probe(_refused_instance, "display")))
	note("the six, by name: %s" % ", ".join(six))

	note("--- bullet: present six ---")
	# Wait for a screen rather than assuming one is already up: the catch resolves
	# over several frames and a screen that arrives late is still a screen.
	for i in 300:
		if _screen_open():
			break
		await physics_frame
	if not _screen_open():
		note("no screen opened in the 300 frames after the sixth catch")
	_dump_screens(stack, "presented")
	_count_names(_screen_lines(stack), six)
	_probe_for_a_count(stack)
	await shot("ceremony_presented")

	note("--- bullet: inspect meaningful info ---")
	# Step the selection and photograph it each time. What changes between these
	# dumps is what the screen tells a player about the pal they are looking at.
	for step in 3:
		await _tap("move_back")
		note("- after pressing 'move_back' %d time(s) -" % (step + 1))
		_dump_screens(stack, "moved %d" % (step + 1))
		await shot("ceremony_moved_%d" % (step + 1))

	note("--- can the choice be left without making it? ---")
	var size_before_cancel: Variant = probe(party, "size")
	await _tap("menu_cancel")
	note("after 'menu_cancel': screen open=%s  depth=%s  party size %s -> %s" % [
		probe(stack, "is_open"), probe(stack, "depth"), size_before_cancel, probe(party, "size")
	])
	_dump_screens(stack, "after cancel")
	await shot("ceremony_after_cancel")
	# Pressing B a second time, in case the first one only backed out of a
	# sub-state. A screen that survives both is refusing to be left.
	await _tap("menu_cancel")
	note("after a second 'menu_cancel': screen open=%s  depth=%s  party size=%s" % [
		probe(stack, "is_open"), probe(stack, "depth"), probe(party, "size")
	])
	_dump_screens(stack, "after second cancel")

	# If backing out closed the ceremony for good, the keep/release bullet would go
	# unexercised for a reason that is itself a finding. Catch another sixth so
	# both facts end up in the transcript.
	if not _screen_open():
		note("the ceremony is not on screen after the cancel presses; catching another sixth pal")
		note("so that the keep/release choice can still be exercised")
		await _wait_for_wild()
		await _attempt_catch(party, true)
		for i in 300:
			if _screen_open():
				break
			await physics_frame
		note("screen open again: %s (top: %s)" % [probe(stack, "is_open"), _top_name(stack)])
		six = _names(party)
		if _refused_instance != null:
			six.append(str(probe(_refused_instance, "display")))
		note("the six, by name, now: %s" % ", ".join(six))
		_dump_screens(stack, "re-presented")
		await shot("ceremony_re_presented")

	note("--- bullet: keep one / release one ---")
	var before_names: PackedStringArray = _names(party)
	note("party before the choice: %d = %s" % [before_names.size(), ", ".join(before_names)])
	note("records before the choice: %s" % [probe(party, "to_records")])
	await shot("ceremony_choice")

	# Confirm, then look. Repeated only while nothing has changed, so a ceremony
	# that takes two presses is followed through and one that takes one press is
	# not pressed a second time into releasing another pal.
	var presses := 0
	for step in 4:
		if not _screen_open():
			note("no screen is open; nothing left to confirm")
			break
		note("- what is on screen at the moment of press %d -" % (step + 1))
		_dump_screens(stack, "before press %d" % (step + 1))
		await _tap("menu_confirm")
		presses += 1
		for i in 40:
			await physics_frame
		note("after press %d: screen open=%s  depth=%s  party size=%s" % [
			presses, probe(stack, "is_open"), probe(stack, "depth"), probe(party, "size")
		])
		_dump_screens(stack, "after press %d" % presses)
		await shot("ceremony_after_press_%d" % presses)
		var now: PackedStringArray = _names(party)
		note("party after press %d: %d = %s" % [presses, now.size(), ", ".join(now)])
		if now != before_names:
			note("the party's contents changed on press %d" % presses)
			break

	note("--- what the party holds after the ceremony ---")
	var after_names: PackedStringArray = _names(party)
	note("size: %s" % probe(party, "size"))
	note("names: %s" % ", ".join(after_names))
	note("records: %s" % [probe(party, "to_records")])
	for pal_name: String in six:
		note("  of the six, '%s' is in the party now: %s" % [pal_name, after_names.has(pal_name)])
	if _refused_instance != null:
		var members: Variant = probe(party, "members")
		var same_object: bool = members is Array and (members as Array).has(_refused_instance)
		note("the exact instance caught while full is in the party now (object identity): %s" % same_object)

	# A frame of the party the player is left with, opened the way a player opens
	# it. The stack must be clear first or the toggle will not open from inside
	# another screen.
	if _screen_open():
		note("a screen is still open before opening the party menu: %s" % _top_name(stack))
		for i in 3:
			if not _screen_open():
				break
			await _tap("menu_cancel")
	await _tap("party_menu")
	note("party menu open: %s (top: %s)" % [probe(stack, "is_open"), _top_name(stack)])
	_dump_screens(stack, "party after release")
	await shot("party_after_release")
	await _tap("menu_cancel")

	note("--- bullet: released pal leaves permanently ---")
	if save == null or not save.has_method("save"):
		note("SaveManager.save: ABSENT — permanence unevidenced")
		return
	note("save(0) returned: %s" % save.call("save", 0))
	var path: String = str(probe(save, "slot_path", [0]))
	note("save file: %s" % path)
	note("save file exists on disk: %s" % FileAccess.file_exists(path))
	var text: String = FileAccess.get_file_as_string(path)
	note("save file size on disk: %d bytes" % text.length())
	# The bytes themselves. A released pal that is still written to the file has
	# not left, whatever the running party says, and this is also where a hidden
	# sixth slot would show up.
	var file_lines: PackedStringArray = text.split("\n")
	note("save file contents (%d lines):" % file_lines.size())
	for i in mini(file_lines.size(), 400):
		note("  save| %s" % file_lines[i])
	if file_lines.size() > 400:
		note("  save| ... %d further lines not printed" % (file_lines.size() - 400))
	for pal_name: String in six:
		note("  occurrences of '%s' in the file on disk: %d" % [pal_name, text.count(pal_name)])

	# Cleared in memory first. Reading a number back out of the same object that
	# still holds it proves nothing about a file.
	if party.has_method("clear"):
		party.call("clear")
	note("party size after clearing it in memory: %s" % probe(party, "size"))
	note("load_slot(0) returned: %s" % probe(save, "load_slot", [0]))
	var reloaded: PackedStringArray = _names(party)
	note("size after reloading from disk: %s" % probe(party, "size"))
	note("names after reloading from disk: %s" % ", ".join(reloaded))
	note("records after reloading from disk: %s" % [probe(party, "to_records")])
	for pal_name: String in six:
		note("  of the six, '%s' came back from disk: %s" % [pal_name, reloaded.has(pal_name)])

	await _tap("party_menu")
	note("party menu open after the reload: %s (top: %s)" % [probe(stack, "is_open"), _top_name(stack)])
	_dump_screens(stack, "party after reload")
	await shot("party_after_reload")
	await _tap("menu_cancel")

	note("the sixth catch reached a resolution: %s" % caught_sixth)


func _on_caught_refused(token: String, instance: RefCounted) -> void:
	_refusals += 1
	_refused_token = token
	_refused_instance = instance
	note("the director reports a pal it caught and could not keep: token='%s', species=%s, name=%s" % [
		token, field(instance, "species_id"), probe(instance, "display")
	])


## --- reading what is on the screen -----------------------------------------
##
## Everything here reads the RENDERED tree — the text nodes the game filled in —
## rather than asking a screen what it thinks it is showing. A screen's own
## account of its contents is the screen marking its own homework, and this
## session is not allowed to know that a screen has such a method anyway.

func _screen_open() -> bool:
	var stack: Object = _find("ScreenStack")
	return stack != null and bool(probe(stack, "is_open"))


func _top_name(stack: Object) -> String:
	var top: Variant = probe(stack, "top")
	return (top as Node).name if top is Node else str(top)


## Every visible string in the whole menu layer, in tree order. The layer, not
## just the top screen: the stack deliberately leaves lower screens visible, so
## what a player is looking at is the whole thing.
func _screen_lines(stack: Object) -> PackedStringArray:
	if stack == null:
		return PackedStringArray()
	return _visible_text(stack as Node)


func _visible_text(node: Node) -> PackedStringArray:
	var out := PackedStringArray()
	if node == null:
		return out
	var layer := node as CanvasLayer
	if layer != null and not layer.visible:
		return out
	var item := node as CanvasItem
	if item != null and not item.is_visible_in_tree():
		return out
	var text: Variant = node.get("text")
	if text is String and not (text as String).strip_edges().is_empty():
		# Newlines escaped rather than printed, so one label is one transcript
		# line and the characters can be counted.
		out.append("%s: '%s'" % [node.name, (text as String).replace("\n", "\\n")])
	for child in node.get_children():
		out.append_array(_visible_text(child))
	return out


func _dump_screens(stack: Object, label: String) -> void:
	if stack == null:
		note("[%s] ScreenStack: ABSENT" % label)
		return
	note("[%s] screen open=%s  depth=%s  top=%s" % [
		label, probe(stack, "is_open"), probe(stack, "depth"), _top_name(stack)
	])
	var lines: PackedStringArray = _screen_lines(stack)
	note("[%s] %d visible strings on screen:" % [label, lines.size()])
	for line: String in lines:
		note("[%s]   %s" % [label, line])


## How many of the pals this session knows about are named on the screen.
##
## Counted from the text the game rendered rather than from a count the screen
## reports, because "present six" is a claim about what a player can see.
func _count_names(lines: PackedStringArray, names: PackedStringArray) -> void:
	var found := 0
	for wanted: String in names:
		var hits := 0
		for line: String in lines:
			if line.contains(wanted):
				hits += 1
		if hits > 0:
			found += 1
		note("  '%s' appears in %d of the screen's visible strings" % [wanted, hits])
	note("  distinct known pals named on screen: %d of %d" % [found, names.size()])


## A blind sweep for a count and a cursor. Nothing here is known to exist; each
## line is a fact about whether it does, and an absent name is as informative as
## a present one.
func _probe_for_a_count(stack: Object) -> void:
	var top: Variant = probe(stack, "top")
	if not (top is Object):
		note("  no top screen to ask for a count")
		return
	var screen: Object = top
	for method: String in ["count", "entry_count", "option_count", "choice_count", "size"]:
		note("  top screen %s(): %s" % [method, probe(screen, method)])
	for property: String in ["entries", "options", "choices", "candidates", "pals", "index", "cursor", "selected", "selected_index"]:
		var value: Variant = field(screen, property)
		if value is Array:
			note("  top screen .%s: Array of %d" % [property, (value as Array).size()])
		else:
			note("  top screen .%s: %s" % [property, value])


func _names(party: Object) -> PackedStringArray:
	var out := PackedStringArray()
	for i in int(probe(party, "size")):
		out.append(str(probe(_member(party, i), "display")))
	return out


## Open the party screen through the real input action, not by instancing it.
## A screen that only appears when a test constructs it is not reachable by a
## player.
func _open_party_menu() -> void:
	await _tap("party_menu")
	var stack: Object = _find("ScreenStack")
	if stack == null:
		note("ScreenStack: ABSENT — no screen opened")
	else:
		note("screen open after pressing 'party_menu': %s" % probe(stack, "is_open"))
		var top: Variant = probe(stack, "top")
		note("top screen: %s" % (top.name if top is Node else top))
	await shot("party_menu")

	# Move the selection and photograph it again, so the judge can see whether
	# selection is visible at all.
	#
	# Held for several frames rather than one. A single-physics-frame press is
	# 1/60th of a second, which is shorter than any tap a person can make, and a
	# menu that required one would be unusable — so a one-frame press tests the
	# harness's timing rather than the menu's.
	await _tap("move_back")
	await shot("party_menu_moved")

	# The rename screen, reached the way a player reaches it. The API-level
	# rename earlier in this session proves the data layer supports it; this
	# proves a person can actually get there, which is the half the blind judge
	# said was missing.
	await _tap("move_right")
	var top_now: Variant = probe(stack, "top") if stack != null else null
	note("screen after pressing right on a pal: %s" % (top_now.name if top_now is Node else top_now))
	await shot("rename_screen")

	# TYPE, rather than opening the grid and walking away from it.
	#
	# The sharpest thing the last review found was that no player input in the
	# whole session ever changed party state: navigation was proven
	# controller-to-model, and every mutation went through a direct API call.
	# Pressing confirm on the grid is the difference between "the screen opens"
	# and "the screen works".
	var rename_screen: Object = _find("RenameScreen")
	note("characters in the name buffer before typing: '%s'" % probe(rename_screen, "typed_name"))
	for i in 3:
		await _tap("menu_confirm")
	note("characters in the name buffer after three presses: '%s'" % probe(rename_screen, "typed_name"))
	await shot("rename_typed")
	await _tap("menu_cancel")
	note("name after cancelling the rename: %s" % probe(_member(_find("Party"), 0), "display"))

	# Deploy a pal the player is not already out with, by pressing the button.
	var party_node: Object = _find("Party")
	note("active index before pressing Send out: %s" % field(party_node, "active_index"))
	await _tap("move_back")
	await _tap("menu_confirm")
	note("active index after pressing Send out: %s" % field(party_node, "active_index"))
	note("deployed pal is now: %s" % probe(probe(party_node, "active"), "display"))
	await shot("party_menu_deployed")

	await _tap("menu_cancel")
	if stack != null:
		note("screen open after 'menu_cancel': %s" % probe(stack, "is_open"))


## Catch a wild pal for real: walk to it, engage, weaken it, throw until it
## resolves, and report the party before and after.
##
## The first version of this session skipped all of that and logged
## `director reports caught: 5` — a counter printed by the system that owns it,
## immediately after five direct roster insertions. The blind judge called it
## "consistent with the counter simply counting adds" and refused the bullet.
## It was right: a number a system reports about itself is not evidence that the
## thing happened.
func _catch_one(party: Object) -> void:
	await _attempt_catch(party, false)


## The catch itself. Returns true if the party grew by it.
##
## `watch_screens` is for the catch made while the party is FULL: that one cannot
## grow the party, so the loop has to stop on something else — the director
## reporting a creature it could not keep, or a screen appearing. Without it the
## session would keep throwing orbs at a world the ceremony has just paused.
func _attempt_catch(party: Object, watch_screens: bool) -> bool:
	var director: Object = _find("EncounterDirector")
	var manager: Object = _find("CombatManager")
	var player: CharacterBody3D = _find("Player") as CharacterBody3D
	var rig: Node3D = _find("CameraRig") as Node3D
	if director == null or manager == null or player == null:
		note("cannot attempt a catch: director/manager/player missing")
		return false

	var wild: Node3D = _catchable_wild(director)
	if wild == null:
		note("no wild pal in the world to catch")
		return false
	var refusals_before: int = _refusals
	note("target: %s at %.0f, %.0f" % [wild.name, wild.global_position.x, wild.global_position.z])
	note("party size before the catch: %s" % probe(party, "size"))

	# Walk to it, then engage.
	for i in 1500:
		var to: Vector3 = wild.global_position - player.global_position
		to.y = 0.0
		if to.length() <= 4.0:
			break
		if rig != null:
			rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame
	await _tap("interact")
	note("fight started: %s" % probe(manager, "is_fighting"))
	if not bool(probe(manager, "is_fighting")):
		note("could not start a fight; the catch is unevidenced")
		return false

	# The hard rule, checked where it lives: a pal you already own cannot be
	# caught. CLAUDE.md states it and catch_math enforces it.
	var catch_math := load("res://scripts/combat/catch_math.gd")
	note("can a trainer-owned pal be caught? %s" % catch_math.can_be_caught(false, true))
	note("can a fainted wild pal be caught? %s" % catch_math.can_be_caught(true, false))
	note("can a healthy wild pal be caught? %s" % catch_math.can_be_caught(false, false))

	var foe: Object = probe(manager, "enemy")
	var before: int = int(probe(party, "size"))
	var throws := 0
	for attempt in 25:
		if not bool(probe(manager, "is_fighting")):
			break
		if watch_screens and (_refusals > refusals_before or _screen_open()):
			note("stopping the throws: the game has taken over (refusals=%d, screen open=%s)" % [
				_refusals - refusals_before, _screen_open()
			])
			break
		# Weakened directly rather than by fighting: this is evidence about
		# catching, and grinding it down through combat would be evidence about
		# combat. smoke_catching does the same for the same reason.
		if foe != null:
			foe.set("hp", float(foe.get("max_hp")) * 0.02)
		var aim: Object = probe(manager, "throw_aim")
		if aim != null and int(probe(manager, "orbs_left")) <= 1:
			aim.call("refill")
		var pal: Object = probe(manager, "active_pal")
		if pal != null:
			pal.set("hp", float(pal.get("max_hp")))
		if not await _throw_at(manager, player, rig, wild):
			continue
		throws += 1
		for i in 120:
			await physics_frame
			if int(probe(party, "size")) > before:
				break
			if watch_screens and (_refusals > refusals_before or _screen_open()):
				break
		if int(probe(party, "size")) > before:
			break
		if watch_screens and (_refusals > refusals_before or _screen_open()):
			break

	note("throws made: %d" % throws)
	note("fight outcome: %s" % probe(manager, "outcome"))
	note("party size after the catch: %s" % probe(party, "size"))
	var caught_member: Object = _member(party, before)
	if caught_member != null:
		note("caught creature is now party member %d: %s (%s)" % [
			before, probe(caught_member, "display"), field(caught_member, "species_id")
		])
	# Leave the fight so the rest of the session is not run inside one. Not waited
	# out when a screen is up: the ceremony pauses the tree, so the fight cannot
	# end until the screen does, and waiting here would deadlock the session.
	for i in 200:
		if watch_screens and _screen_open():
			break
		await physics_frame
		if not bool(probe(manager, "is_fighting")):
			break
	return int(probe(party, "size")) > before or _refusals > refusals_before


## The first wild creature that is actually there to be fought.
##
## A caught one is hidden and comes back on the director's respawn timer, so
## picking `wild_pals[0]` every time — which is what the party session did with
## one catch to make — would send the player to walk at something invisible.
func _catchable_wild(director: Object) -> Node3D:
	var wilds: Variant = probe(director, "wild_pals")
	if not (wilds is Array):
		return null
	for wild: Node3D in (wilds as Array):
		if is_instance_valid(wild) and wild.visible:
			return wild
	return null


## Wait for one to be back on the hillside. Six catches need more creatures than
## the world holds at once, so the session waits for the world to put them back
## rather than conjuring them.
func _wait_for_wild() -> void:
	var director: Object = _find("EncounterDirector")
	for i in 900:
		if _catchable_wild(director) != null:
			return
		await physics_frame
	note("waited 900 frames and no wild pal became available")


## Open the aim, point it at the creature, and release.
##
## The orb flies on a real arc, so aiming straight at the target undershoots by
## the drop over the flight — a player compensates by eye and this has to do it
## by arithmetic. Aimed through the camera rig rather than by handing the orb a
## direction, so a broken aim camera shows up here instead of being quietly
## worked around. Same approach `smoke_catching` uses, for the same reason.
func _throw_at(manager: Object, player: Node3D, rig: Node3D, wild: Node3D) -> bool:
	if not bool(probe(manager, "is_aiming")):
		await _tap("combat_throw")
	if not bool(probe(manager, "is_aiming")):
		return false

	var catch_cfg := load("res://scripts/combat/catch_math.gd")
	var cfg: Dictionary = catch_cfg.config().get("throw", {})
	var speed := float(cfg.get("speed", 17.0))
	var gravity := float(cfg.get("gravity", 14.0))
	var origin: Vector3 = player.global_position + Vector3.UP * float(cfg.get("spawn_height", 1.5))
	var centre: Vector3 = wild.call("centre") if wild.has_method("centre") else wild.global_position
	var to: Vector3 = centre - origin
	var flat := Vector2(to.x, to.z).length()
	if rig != null:
		rig.set("yaw", atan2(-to.x, -to.z))
		var flight := flat / maxf(speed, 0.01)
		rig.set("pitch", atan2(to.y + 0.5 * gravity * flight * flight, maxf(flat, 0.01)))
	for i in 4:
		await physics_frame
	await _tap("combat_throw")
	return true


## Press an action the way a person would, and let the game settle.
func _tap(action: String) -> void:
	Input.action_press(action)
	for i in 8:
		await physics_frame
	Input.action_release(action)
	for i in 14:
		await physics_frame


## --- probes ---------------------------------------------------------------
##
## Everything below refuses to crash. An absent method is a FACT about the
## build and belongs in the transcript; an exception is a truncated transcript
## that a reader cannot tell apart from a short clean run.

func _find(node_name: String) -> Object:
	if _world == null:
		return null
	var direct: Node = _world.get_node_or_null(NodePath(node_name))
	if direct != null:
		return direct
	var found: Array[Node] = _world.find_children(node_name, "", true, false)
	return found[0] if not found.is_empty() else null


func probe(target: Object, method: String, args: Array = []) -> Variant:
	if target == null:
		return "<no object>"
	if not target.has_method(method):
		return "<no method %s>" % method
	return target.callv(method, args)


func field(target: Object, property: String) -> Variant:
	if target == null:
		return "<no object>"
	var value: Variant = target.get(property)
	return value if value != null else "<no property %s>" % property


func _member(party: Object, index: int) -> Object:
	var got: Variant = probe(party, "at", [index])
	return got if got is Object else null


## Build a pal and offer it to the party. Kept here rather than in the party so
## the session does not depend on a convenience method the system might not have.
func _add_pal(party: Object, species_id: String) -> Variant:
	var species := load("res://scripts/pals/pal_species.gd")
	if species == null or not party.has_method("add"):
		return "<cannot add>"
	var instance: Variant = species.spawn(species_id)
	if instance == null:
		return "<spawn failed for %s>" % species_id
	# Deliberately NOT named here. The first version of this session set every
	# nickname as it added the pal, which made "nickname" indistinguishable from
	# "positional label" in the transcript — a blind reviewer read Pal1..Pal5,
	# matched them to the slot indices, and refused the bullet. A nickname is
	# only evidence when the player set it.
	return party.call("add", instance)


## --- recording ------------------------------------------------------------

## One observed fact. Printed as well as stored, so a crashed session still
## leaves everything it got as far as.
func note(line: String) -> void:
	_log.append(line)
	print("  %s" % line)
	# Flushed on every line, not at the end. A session killed by its timeout used
	# to leave fresh frames beside a stale transcript from an earlier run, and
	# nothing on disk said they came from different games. Writing as we go costs
	# nothing and makes a truncated transcript obviously truncated.
	_write()


## A numbered frame, for anything the judge has to look at rather than read.
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		note("frame '%s': not captured (headless)" % label)
		return
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		note("frame '%s': capture failed" % label)
		return
	_shots += 1
	var path := "res://shots/session_%s_%02d_%s.png" % [_system, _shots, label]
	image.save_png(path)
	note("frame '%s' -> %s" % [label, path])


func _write() -> void:
	var path := "res://shots/session_%s.log" % _system
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("could not write %s" % path)
		return
	file.store_string("\n".join(_log) + "\n")
	print("wrote %s (%d lines, %d frames)" % [path, _log.size(), _shots])


## Everything after `--`, so Godot's own arguments are not mistaken for ours.
func _requested_system() -> String:
	var args := OS.get_cmdline_user_args()
	return str(args[0]) if args.size() > 0 else ""
