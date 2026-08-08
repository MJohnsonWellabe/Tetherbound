extends RefCounted

## The player's pals. All of them, ever — there is nowhere else they can be.
##
## CLAUDE.md states it twice: "Player can own only five pals total" and "Never
## implement pal storage beyond five". Until this file, that rule existed only in
## prose. It now exists in one place in code, and every path that could ever
## acquire a pal — catching, gifts, quests, debug commands — has to come through
## add() to get one.
##
## THERE IS NO OVERFLOW. No box, no PC, no "temporarily holding" list, not even a
## private one. A sixth pal is not stored somewhere pending a decision; add()
## simply refuses, and MEADOWS_VERTICAL_SLICE.md M5 is what happens next — the
## caller presents the six and the player keeps five. The moment a sixth can sit
## anywhere in memory, the release ceremony stops being the only way to resolve a
## full party, and the design's one irreversible decision becomes optional.
##
## No nodes, so the party survives a scene change and can be tested headlessly.

const INSTANCE := preload("res://scripts/pals/pal_instance.gd")

## Five. Not in data/config/party.json, and not a variable, because it is a hard
## rule rather than a tunable. A config value can be edited; a const has to be
## argued with.
const MAX_PARTY := 5

## Why the last operation was refused, as a stable token. Empty after anything
## that succeeded.
##
## A token and not a sentence. The party has no business knowing how a refusal is
## worded, and a sentence written here is a sentence the UI cannot shorten for a
## toast, lengthen for the ceremony, or translate. The tokens are listed below so
## the UI has an exhaustive set to map.
const REFUSED_PARTY_FULL := "party_full"
const REFUSED_NOT_A_PAL := "not_a_pal"
const REFUSED_ALREADY_HELD := "already_held"
const REFUSED_NO_SUCH_MEMBER := "no_such_member"

## Which pal is deployed when a fight opens. §10: the player chooses which pal to
## deploy, so this is a stored choice rather than "whichever is first alive".
var active_index: int = 0

var _members: Array = []
var _refusal: String = ""


## Take a pal. Returns false and keeps the party untouched when it is full.
##
## The refusal is the interesting case, not the success: MEADOWS_VERTICAL_SLICE
## M5 hangs off it, and D08 already establishes that catching costs you
## something. The caller is expected to check last_refusal() and, on
## REFUSED_PARTY_FULL, open the keep/release ceremony rather than dropping the
## capture on the floor.
func add(instance: RefCounted) -> bool:
	if instance == null:
		_refusal = REFUSED_NOT_A_PAL
		return false
	if _members.has(instance):
		# The same instance twice would give the player two entries backed by one
		# creature: heal one and the other's bar moves too.
		_refusal = REFUSED_ALREADY_HELD
		return false
	if is_full():
		_refusal = REFUSED_PARTY_FULL
		return false
	_members.append(instance)
	_refusal = ""
	return true


func last_refusal() -> String:
	return _refusal


func size() -> int:
	return _members.size()


func capacity() -> int:
	return MAX_PARTY


func is_full() -> bool:
	return _members.size() >= MAX_PARTY


func is_empty() -> bool:
	return _members.is_empty()


## A COPY of the roster. Deliberately not the live array: an Array is passed by
## reference in GDScript, so handing the real one out would let any caller
## append a sixth pal without going anywhere near add(), and the one rule this
## file exists to enforce would be enforced only by politeness.
func members() -> Array:
	return _members.duplicate()


func at(index: int) -> RefCounted:
	if index < 0 or index >= _members.size():
		return null
	return _members[index]


func active() -> RefCounted:
	return at(active_index)


func index_of(instance: RefCounted) -> int:
	return _members.find(instance)


## Remove a pal permanently. §10: released pals are permanently gone, so there is
## no undo here and no second list for them to land in.
func remove_at(index: int) -> bool:
	if index < 0 or index >= _members.size():
		_refusal = REFUSED_NO_SUCH_MEMBER
		return false
	_members.remove_at(index)
	# Keep pointing at the same PAL where possible, rather than the same slot.
	# Releasing the pal above the active one and finding a different creature
	# deployed on the next fight is the kind of surprise that gets read as the
	# game having released the wrong one.
	if _members.is_empty():
		active_index = 0
	elif index < active_index:
		active_index -= 1
	else:
		active_index = mini(active_index, _members.size() - 1)
	_refusal = ""
	return true


## Choose the pal to deploy. Refuses an out-of-range index rather than clamping:
## a clamp turns a wrong index into a silently wrong creature in a fight, and
## nobody reports that as a bug — they report that the game deployed the wrong
## pal, once, and cannot reproduce it.
func set_active(index: int) -> bool:
	if index < 0 or index >= _members.size():
		_refusal = REFUSED_NO_SUCH_MEMBER
		return false
	active_index = index
	_refusal = ""
	return true


## Move to the next pal, wrapping. What a shoulder button on the Ally is wired
## to; controller-first means switching cannot require pointing at a slot.
func cycle_active(step: int = 1) -> bool:
	if _members.is_empty():
		_refusal = REFUSED_NO_SUCH_MEMBER
		return false
	return set_active(posmod(active_index + step, _members.size()))


func clear() -> void:
	_members.clear()
	active_index = 0
	_refusal = ""


## --- who can still fight --------------------------------------------------
##
## GAME_DESIGN.md §16 makes a fainted pal "unavailable", and by M6 four separate
## systems need to ask about it: the engage prompt, the Switch command, the party
## menu and pal recovery. These are the questions, answered once.
##
## READ-ONLY, and deliberately so. `set_active()` is NOT taught to refuse a
## fainted pal: a save being restored can legitimately point at one, and a party
## whose loader could refuse its own record is a party that loses a pal to a
## faint. Whether a downed creature may be SENT OUT is a question for whoever is
## sending it, and `combat_manager.Switchboard` and `party_screen` both already
## ask it.


## The members that could still be deployed.
func standing() -> Array:
	return standing_in(_members)


## True when the player owns pals and every one of them is down.
##
## An empty party is NOT all-down. Owning nothing and having lost everything are
## different situations with different things to say to the player, and a caller
## that could not tell them apart would tell a new player to go and rest pals
## they do not have.
func all_down() -> bool:
	return none_standing(_members)


func first_standing_index() -> int:
	for i in _members.size():
		var pal: RefCounted = _members[i]
		if pal != null and not bool(pal.get("fainted")):
			return i
	return -1


## The same two questions over a roster that came out of `members()`.
##
## Static, because the roster is what most callers already hold: `party_manager`
## forwards `members()` and not much else, so anything holding the manager rather
## than the party can still ask without a new forwarder being added for each one.
static func standing_in(roster: Array) -> Array:
	var out: Array = []
	for entry: Variant in roster:
		var pal: RefCounted = entry as RefCounted
		if pal != null and not bool(pal.get("fainted")):
			out.append(pal)
	return out


static func none_standing(roster: Array) -> bool:
	return not roster.is_empty() and standing_in(roster).is_empty()


## --- persistence ----------------------------------------------------------

## The serialisable form, and the primary one (structures.gd, same discipline).
##
## The party owns no save path and no version number. autoload/save_manager.gd
## keeps one envelope and one version for the whole game and asks systems to
## register a domain into it; this Array is that domain's payload, and whoever
## holds the party is the one that registers it.
func to_records() -> Array:
	var out: Array = []
	for i in _members.size():
		var record: Dictionary = (_members[i] as RefCounted).to_record()
		# Which pal was deployed is part of the player's state, not decoration.
		# Carried on the member rather than beside the array so that the whole
		# party is still exactly one Array of records.
		record["active"] = i == active_index
		out.append(record)
	return out


## Rebuild a party from records.
##
## Stops at MAX_PARTY however many records it is given. A save file is a text
## file on a Windows machine and will eventually be hand-edited, copied between
## builds, or written by a bug; a loader that trusts its length is a loader that
## can produce the six-pal party the whole design forbids.
static func from_records(records: Array) -> RefCounted:
	var party: RefCounted = (load("res://scripts/pals/party.gd") as GDScript).new()
	var restored_active := 0
	for entry: Variant in records:
		if not entry is Dictionary:
			continue
		var record: Dictionary = entry
		var instance: RefCounted = INSTANCE.from_record(record)
		if instance == null:
			continue
		if not party.add(instance):
			push_warning("party save holds more than %d pals; the rest are ignored" % MAX_PARTY)
			break
		if bool(record.get("active", false)):
			restored_active = party.size() - 1
	if party.size() > 0:
		party.set_active(restored_active)
	return party
