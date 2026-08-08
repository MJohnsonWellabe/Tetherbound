extends RefCounted

## An opposing trainer's team, and the order it comes out in.
##
## `GAME_DESIGN.md` §14: "Trainer fights are team-vs-team." This is the other
## team.
##
## No nodes, no arena, no timers. Everything a trainer battle DECIDES — who is
## out, whether anyone is left, what the tether on the current creature does to
## its timings, what happens when the player breaks off — is decidable from a
## list and an index, so it lives here and can be proven headlessly, per D02.
## `scripts/trainers/tether_trainer.gd` adds only the presentation: the bodies,
## the send-out animation, the pause between creatures.
##
## Same object-rather-than-loose-fields decision as `CombatManager.Switchboard`
## and `EncounterDirector.Hunt`, and for the same reason.
##
## THIS IS NOT A PARTY, and it must never become one.
##
## `party.gd` caps the roster at five and refuses a sixth, because CLAUDE.md says
## the PLAYER can own five pals total. That rule is about the player. An opposing
## trainer's creatures are not owned by the player, are never stored by the
## player, cannot be caught by the player (that is the hard rule this file's
## siblings enforce), and are destroyed with the trainer when the scene ends.
## Giving this a cap would be cargo-culting D13 onto the one place it does not
## apply; giving the PLAYER a route into this list would be breaking it. There is
## no such route: nothing here returns a member to any caller that could keep it,
## and `catch_math.can_be_caught(_, already_owned: true)` refuses the only verb
## that could.

const SPECIES := preload("res://scripts/pals/pal_species.gd")
const DATA := preload("res://scripts/trainers/tether_data.gd")

## Refusal tokens, in `party.gd`'s idiom: a stable token, never a sentence.
const REFUSED_NO_TEAM := "no_team"
const REFUSED_BEATEN := "beaten"
const REFUSED_UNKNOWN_SPECIES := "unknown_species"

## The authored entries, index-aligned with `_members`. Kept so the tether grade
## for the creature currently out can be looked up without a second index.
var _entries: Array = []
var _members: Array = []
var _index: int = 0
var _refusal: String = ""


## Build a team from a trainer definition.
##
## Returns a battle with an empty team rather than null for a definition with no
## `team`, so the caller gets a `last_refusal()` to report instead of a crash on
## a data typo.
static func from_definition(definition: Dictionary) -> RefCounted:
	var battle: RefCounted = (load("res://scripts/trainers/trainer_battle.gd") as GDScript).new()
	var entries: Array = definition.get("team", [])
	for entry: Variant in entries:
		if not (entry is Dictionary):
			continue
		var spec: Dictionary = entry
		var id := str(spec.get("species", ""))
		if not SPECIES.has(id):
			push_error("trainer '%s' fields '%s', which is not in species.json" % [
				str(definition.get("id", "?")), id
			])
			battle._refusal = REFUSED_UNKNOWN_SPECIES
			continue
		var instance: RefCounted = SPECIES.spawn(id, 0.0)
		if instance == null:
			battle._refusal = REFUSED_UNKNOWN_SPECIES
			continue

		# NO TRAIT, DELIBERATELY.
		#
		# `pal_species.spawn()` rolls one for every creature it makes, which is
		# right for a wild catch and wrong here: traits span roughly 0.86 to 1.18
		# on a stat, so a Warden whose heavy rolls Fierce and a Warden whose heavy
		# rolls Brittle are two different fights, and the player cannot tell which
		# one they are being asked to beat. A boss has to be the same boss on the
		# fourth attempt as on the first, or "meaningful difficulty" is not
		# something anyone can learn.
		instance.assign_trait("")
		instance.set_level(maxi(1, int(spec.get("level", 1))))
		battle._entries.append(spec)
		battle._members.append(instance)
	if battle._members.is_empty():
		battle._refusal = REFUSED_NO_TEAM
	return battle


func size() -> int:
	return _members.size()


func last_refusal() -> String:
	return _refusal


## A COPY, for the same reason `party.members()` returns one: an Array is passed
## by reference, and a caller holding the live list could append to a roster this
## file is supposed to own.
func members() -> Array:
	return _members.duplicate()


func at(index: int) -> RefCounted:
	if index < 0 or index >= _members.size():
		return null
	return _members[index]


func current_index() -> int:
	return _index


func current() -> RefCounted:
	return at(_index)


## The tether grade the creature at `index` is wearing, resolved through
## `tether_data`. Data, not a field on the instance: the tether is a property of
## how this trainer is FIELDING the creature, not of the creature.
func grade_at(index: int) -> Dictionary:
	if index < 0 or index >= _entries.size():
		return DATA.tether_grade("none")
	return DATA.tether_grade(str((_entries[index] as Dictionary).get("tether", "none")))


func grade() -> Dictionary:
	return grade_at(_index)


func standing() -> int:
	var count := 0
	for entry: Variant in _members:
		var pal: RefCounted = entry as RefCounted
		if pal != null and not bool(pal.get("fainted")):
			count += 1
	return count


## Every creature this trainer owns is down. The trainer is beaten.
func is_beaten() -> bool:
	return not _members.is_empty() and standing() == 0


## Point at the first creature that can still fight, from the top of the list.
##
## Used when a battle opens. Deliberately from the TOP rather than resuming where
## the last attempt left off: `restore()` is what a broken-off battle gets, and
## the whole difficulty argument in `warden_meadows.json` depends on the team
## being whole and in order every time the player accepts.
func open() -> bool:
	_index = 0
	if _members.is_empty():
		_refusal = REFUSED_NO_TEAM
		return false
	if is_beaten():
		_refusal = REFUSED_BEATEN
		return false
	while _index < _members.size() and bool((_members[_index] as RefCounted).get("fainted")):
		_index += 1
	_refusal = ""
	return _index < _members.size()


## Move to the next creature that can still fight. False when there is none,
## which is how a battle ends.
##
## Steps FORWARD only. A trainer does not send a creature back out after it has
## been knocked down, and a wrap would do exactly that in a team whose first
## member is somehow still standing.
func advance() -> bool:
	var next := _index + 1
	while next < _members.size():
		var pal: RefCounted = _members[next] as RefCounted
		if pal != null and not bool(pal.get("fainted")):
			_index = next
			_refusal = ""
			return true
		next += 1
	_refusal = REFUSED_BEATEN
	return false


## Put the whole team back on its feet at full health.
##
## Called when the player breaks off — runs, or has their deployed pal knocked
## out — if `flow.restore_on_disengage` is set. See `data/config/trainers.json`:
## this is a difficulty mechanic, not a convenience. Without it, any trainer is
## beatable by attrition across unlimited attempts and the fight is a patience
## test rather than a fight.
##
## `heal_fully()` rather than `revive()`, and that is safe here for the one
## reason it is not safe on a party member: §16's "a fainted pal does not
## auto-revive" is a rule about the pals the PLAYER owns, and `heal_fully()`'s
## own docstring names itself the WORLD's reset for a body that is about to be a
## different individual. An opposing trainer's team is exactly that.
func restore() -> void:
	for entry: Variant in _members:
		var pal: RefCounted = entry as RefCounted
		if pal != null:
			pal.heal_fully()
	_index = 0
	_refusal = ""


## How the team reads in one line, for a prompt or a transcript: "2 of 3 left".
func standing_summary() -> String:
	return "%d of %d" % [standing(), size()]
