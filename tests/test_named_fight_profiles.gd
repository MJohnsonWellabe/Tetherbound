extends "res://tests/test_case.gd"

# ROADMAP Phase 1 item 7: "Make named fights distinct." Its instruction is to
# audit against BOSSES and "reuse the per-body combat override in
# `scripts/creatures/wild_creature.gd` and trainer/member data rather than
# branching combat manager behavior".
#
# BOSSES §2 is the contract: every named encounter answers Look, Do and Change,
# and "a name, larger scale and more HP do not satisfy" it. The "Do" it
# authors is a named behaviour PROFILE -- WALL, CHARGER, ACE -- written into
# the fight's own row.
#
# The audit's actual finding was that the Meadows fights already match the
# contract, which is only worth anything if it STAYS matched. BOSSES is prose;
# the profiles are data; nothing connected them. This is that connection.
#
# It deliberately does NOT demand a profile from every trainer. BOSSES calls
# `quarry_picket_dorn` a "quarry gate baseline" and `warrens_watch_pell` a
# "cave-door composition" on purpose, and says trainer ladders "normally remain
# sequential team fights; they do not acquire artificial boss phases". Requiring
# a profile everywhere would contradict the document it is meant to enforce.

## BOSSES is the contract, and CI cannot read it: every job's sparse checkout
## excludes `/docs/`, so `res://docs/design/BOSSES.md` is simply absent there
## (`docs/.gdignore` keeps Godot out of it locally as well). No test in this
## repository reads a design document, and this one found out why by failing in
## CI after passing locally.
##
## So the contract is TRANSCRIBED below, and the data checks run off the
## transcription -- in CI too, where they matter most. When the document IS
## readable, which is any ordinary local run, a further test compares the
## transcription against the real rows, so the copy cannot quietly drift from
## the source it claims to enforce.
const BOSSES := "res://docs/design/BOSSES.md"

## The profile names BOSSES authors. A row naming one of these is claiming an
## authored behaviour, which the data then has to carry.
const PROFILES := ["WALL", "CHARGER", "ACE", "DIVER", "CURRENT"]

## Meadows fights whose BOSSES row names a profile, and which therefore must
## carry an authored per-member override in trainer data.
const MEADOWS_PROFILED := ["relay_captain", "captain_riverwatch", "captain_field",
	"captain_ridge", "stronghold_elite", "warden_aldis"]

## The sequences BOSSES writes, transcribed from its Meadows tables. Verified
## against the document itself by
## `test_the_transcribed_sequences_match_bosses` whenever docs are present.
## `relay_captain` names one creature's profile in prose rather than a sequence
## ("Tuskroot CHARGER; crossing payoff"), so it carries no row here and is held
## by the at-least-one check instead.
const MEADOWS_SEQUENCES := {
	"captain_riverwatch": ["WALL", "baseline", "CURRENT"],
	"captain_field": ["baseline", "CHARGER", "CURRENT"],
	"captain_ridge": ["baseline", "baseline", "DIVER"],
	"stronghold_elite": ["DIVER", "baseline", "WALL"],
	"warden_aldis": ["WALL", "DIVER", "CURRENT", "CHARGER", "ACE"],
}


func _bosses_text() -> String:
	return FileAccess.get_file_as_string(BOSSES)


const BANDS_DIR := "res://data/config/bands"


## Band folders are named by region, not by number-plus-feature, and they get
## renamed when a band is re-themed. Scan the directory rather than pinning a
## list that goes stale silently and makes this test pass vacuously.
func _trainer_paths() -> Array[String]:
	var paths: Array[String] = []
	for band: String in DirAccess.get_directories_at(BANDS_DIR):
		var path := "%s/%s/trainers.json" % [BANDS_DIR, band]
		if FileAccess.file_exists(path):
			paths.append(path)
	paths.sort()
	return paths


func _trainer(id: String) -> Dictionary:
	for path: String in _trainer_paths():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var rows: Variant = parsed
		if parsed is Dictionary:
			rows = (parsed as Dictionary).get("trainers", [])
		if rows is not Array:
			continue
		for raw: Variant in (rows as Array):
			if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
				return raw as Dictionary
	return {}


func _member_rows(trainer: Dictionary) -> Array:
	for key: String in ["creatures", "team", "members"]:
		var rows: Variant = trainer.get(key, [])
		if rows is Array and not (rows as Array).is_empty():
			return rows as Array
	return []


func test_bosses_still_names_the_meadows_profiled_fights() -> void:
	# If a fight is renamed or its row loses its profile, this catches it before
	# the data check below starts passing vacuously.
	assert_false(_trainer_paths().is_empty(),
		"no band trainers.json found; the rest of this file would pass vacuously")
	var text := _bosses_text()
	if text.is_empty():
		return  # Documented above: CI's sparse checkout excludes /docs/.
	for id: String in MEADOWS_PROFILED:
		assert_true(text.contains("`%s`" % id),
			"BOSSES no longer names '%s'; this list is stale" % id)


func test_every_profiled_meadows_fight_carries_an_authored_override() -> void:
	# The contract's "Do": a profiled fight must differ from an ordinary one in
	# authored data, not in a branch somewhere in the combat manager.
	for id: String in MEADOWS_PROFILED:
		var trainer := _trainer(id)
		assert_false(trainer.is_empty(), "named fight '%s' is not in any band's trainer data" % id)
		var authored := false
		for raw: Variant in _member_rows(trainer):
			if raw is not Dictionary:
				continue
			var member := raw as Dictionary
			if member.has("combat") or member.has("combat_override") or member.has("profile"):
				authored = true
		assert_true(authored,
			"BOSSES gives '%s' a named behaviour profile, but not one of its members carries an "
			% id + "authored override -- the fight is a name and more HP, which §2 says is not enough")


func test_every_profiled_meadows_fight_changes_something_afterwards() -> void:
	# The contract's "Change": a defeat flag at minimum, so route, reward or
	# world state can key on it.
	for id: String in MEADOWS_PROFILED:
		var trainer := _trainer(id)
		if trainer.is_empty():
			continue
		var reward: Dictionary = trainer.get("reward", {}) as Dictionary
		var changes := not str(trainer.get("defeat_flag", "")).is_empty() \
			or not (reward.get("flags", []) as Array).is_empty()
		assert_true(changes,
			"named fight '%s' changes nothing afterwards: no defeat flag and no reward flags" % id)


func test_a_baseline_gate_is_not_required_to_be_a_boss() -> void:
	# The guard that keeps this test honest. BOSSES calls these baselines and
	# compositions deliberately, and says trainer ladders do not acquire
	# artificial boss phases. A future edit that "fixes" them by demanding
	# profiles would be contradicting the contract, not enforcing it.
	var text := _bosses_text()
	if text.is_empty():
		return  # Documented above: CI's sparse checkout excludes /docs/.
	assert_true(text.contains("quarry gate baseline"),
		"BOSSES still calls the quarry picket a baseline; it is not owed a boss profile")
	assert_true(text.contains("do not acquire artificial boss phases"),
		"BOSSES still exempts trainer ladders from boss phases")


## The profile sequence BOSSES writes in a fight's row, e.g. "WALL -> baseline
## -> CURRENT", as an array of PROFILES entries and the literal "baseline".
## Returns empty for a row that does not write a sequence -- `relay_captain`
## names one creature's profile in prose instead, and is covered by the
## at-least-one check above rather than positionally.
func _bosses_sequence(id: String) -> Array[String]:
	var sequence: Array[String] = []
	for line: String in _bosses_text().split("\n"):
		if not line.contains("`%s`" % id) or not line.begins_with("|"):
			continue
		var cells := line.split("|")
		var note := str(cells[cells.size() - 2]).strip_edges()
		if not note.contains("\u2192"):
			continue
		for raw: String in note.split(";")[0].split("\u2192"):
			var token := raw.strip_edges()
			# A row's last step often carries trailing prose, as in
			# "ACE final exam", so match the leading word rather than the cell.
			var word := token.split(" ")[0].strip_edges()
			if PROFILES.has(word) or word == "baseline":
				sequence.append(word)
		break
	return sequence


## The sequence the data is held to: the transcription, which exists in CI.
func _profile_sequence(id: String) -> Array[String]:
	var sequence: Array[String] = []
	for raw: Variant in (MEADOWS_SEQUENCES.get(id, []) as Array):
		sequence.append(str(raw))
	return sequence


func test_the_transcribed_sequences_match_bosses() -> void:
	# Only runs where docs are checked out. It is the one check that can catch
	# the transcription drifting from the document, so when it cannot run it
	# says so rather than passing quietly.
	if _bosses_text().is_empty():
		assert_true(true,
			"BOSSES.md is not in this checkout (CI excludes /docs/); the transcribed "
			+ "sequences are enforced against data, but not against the document here")
		return
	for id: String in MEADOWS_SEQUENCES:
		assert_eq(_bosses_sequence(id), _profile_sequence(id),
			"the transcribed sequence for '%s' no longer matches its BOSSES row" % id)


func test_the_profile_sequence_lands_on_the_creatures_bosses_names() -> void:
	# The stronger half of "Do". "At least one override somewhere" would pass a
	# fight whose WALL opener is actually its closer. BOSSES writes the order --
	# WALL first, a baseline in the middle -- and the order is what the player
	# meets. A row's baseline slot must stay a baseline: if every member were
	# overridden the authored contrast would be gone.
	var checked := 0
	for id: String in MEADOWS_PROFILED:
		var sequence := _profile_sequence(id)
		if sequence.is_empty():
			continue
		var trainer := _trainer(id)
		var members := _member_rows(trainer)
		assert_eq(members.size(), sequence.size(),
			"BOSSES gives '%s' a %d-step sequence but its team has %d members"
			% [id, sequence.size(), members.size()])
		if members.size() != sequence.size():
			continue
		checked += 1
		for index: int in range(sequence.size()):
			var member: Dictionary = members[index] as Dictionary
			var overridden := _authors_a_profile(member)
			if sequence[index] == "baseline":
				assert_false(overridden,
					"BOSSES makes '%s' step %d a baseline, the contrast its named steps are read against, but the data overrides it"
					% [id, index + 1])
			else:
				assert_true(overridden,
					"BOSSES makes '%s' step %d %s, but that member carries no authored override"
					% [id, index + 1, sequence[index]])
	assert_true(checked >= 3,
		"only %d sequenced Meadows rows were checked; the row format changed and this test has gone quiet"
		% checked)


## Keys BOSSES §2.1 step 3's chapter clamp may author on a BASELINE member: it
## raises tell/recovery to the post-South-Bridge floor (.9/.75 s) and changes
## nothing else, so a block made only of these (and `_` notes) is still a
## baseline, not a profile.
const CLAMP_ONLY_KEYS := ["telegraph", "recovery"]


func _authors_a_profile(member: Dictionary) -> bool:
	if member.has("combat_override") or member.has("profile"):
		return true
	var combat: Dictionary = member.get("combat", {}) as Dictionary
	for key: Variant in combat.keys():
		var name := str(key)
		if not name.begins_with("_") and not CLAMP_ONLY_KEYS.has(name):
			return true
	return false


## Keys a profile's shape is NOT made of. `power` scales with the fight's level
## band, so two WALLs at different levels legitimately differ there; `moves` and
## comment keys are not behaviour timings at all.
const SHAPE_EXCLUDED := ["power", "moves", "level", "species"]


func _shape(member: Dictionary) -> Dictionary:
	var combat: Dictionary = member.get("combat", {}) as Dictionary
	var shape := {}
	for key: Variant in combat.keys():
		var name := str(key)
		if name.begins_with("_") or SHAPE_EXCLUDED.has(name):
			continue
		shape[name] = combat[key]
	return shape


func test_a_profile_means_the_same_thing_in_every_fight_that_uses_it() -> void:
	# The point of naming a profile is that the player learns it once. A WALL
	# that telegraphs at 0.85s in the Hall and 0.5s at the river is not a
	# profile, it is two fights wearing one word. This pins the shapes that are
	# already shared -- timings, ranges, poise -- while leaving `power` free to
	# follow the level band.
	#
	# This invariant is derived from the current data, not from a line in
	# BOSSES. If a fight is meant to hold a genuinely different WALL, the answer
	# is a new profile name in its row, not a second set of numbers under the
	# old one -- but that is the owner's call, and this test failing is how the
	# question gets asked rather than lost.
	var first_seen := {}
	var compared := 0
	for id: String in MEADOWS_PROFILED:
		var sequence := _profile_sequence(id)
		var members := _member_rows(_trainer(id))
		if sequence.is_empty() or members.size() != sequence.size():
			continue
		for index: int in range(sequence.size()):
			var profile := sequence[index]
			if profile == "baseline":
				continue
			var shape := _shape(members[index] as Dictionary)
			if not first_seen.has(profile):
				first_seen[profile] = {"shape": shape, "fight": id}
				continue
			compared += 1
			var previous: Dictionary = first_seen[profile] as Dictionary
			assert_eq(shape, previous["shape"],
				"%s means one thing in '%s' and another in '%s'; give the second one its own profile name in BOSSES or match the first"
				% [profile, previous["fight"], id])
	assert_true(compared >= 3,
		"only %d profile reuses were compared; the rows changed and this test has gone quiet" % compared)


## Minimum tells BOSSES writes into the profile rows themselves, so the player
## can read the named attack at the normal camera (F04). CHARGER: "Tuskroot
## closes 7 m after a .8 s minimum full-body charge cue" (Vance) and "7 m lunge,
## .8 s visible charge floor" (the Warden's Meadowhart). ACE: the Warden's
## Tuskroot has a "1.1 s signature tell". COMBAT's general floors (baseline
## .80 s, heavy 1.10 s) say the same. DIVER is not held here: BOSSES authors its
## ".4 s strike tell" behind a positional entry as the read.
const TELL_FLOORS := {"CHARGER": 0.8, "ACE": 1.1}

## `relay_captain` names its CHARGER in prose ("Tuskroot is the ace and CHARGER
## target"), not as a sequence; its third member carries that profile.
const PROSE_PROFILES := {"relay_captain": {2: "CHARGER"}}


func test_named_attacks_keep_the_tell_bosses_writes_for_their_profile() -> void:
	var checked := 0
	for id: String in MEADOWS_PROFILED:
		var members := _member_rows(_trainer(id))
		var by_index := {}
		var sequence := _profile_sequence(id)
		if sequence.size() == members.size():
			for index: int in range(sequence.size()):
				by_index[index] = sequence[index]
		for index: Variant in (PROSE_PROFILES.get(id, {}) as Dictionary).keys():
			by_index[int(index)] = (PROSE_PROFILES[id] as Dictionary)[index]
		for index: Variant in by_index.keys():
			var profile := str(by_index[index])
			if not TELL_FLOORS.has(profile) or int(index) >= members.size():
				continue
			var combat: Dictionary = (members[int(index)] as Dictionary).get("combat", {}) as Dictionary
			assert_true(combat.has("telegraph"),
				"'%s' member %d is %s but authors no telegraph" % [id, int(index) + 1, profile])
			checked += 1
			assert_true(float(combat.get("telegraph", 0.0)) >= float(TELL_FLOORS[profile]) - 0.0001,
				"'%s' member %d is %s with a %.2fs tell; BOSSES writes at least %.2fs so it reads at the normal camera"
				% [id, int(index) + 1, profile, float(combat.get("telegraph", 0.0)), float(TELL_FLOORS[profile])])
	assert_true(checked >= 4,
		"only %d CHARGER/ACE members were checked; the rows changed and this test has gone quiet" % checked)
