extends RefCounted

## MEADOWS_VERTICAL_SLICE.md M5: a sixth pal has been caught, and one of six has
## to go.
##
## This is the decision itself, with no UI attached. It exists as its own object
## because the decision has a shape — six candidates, exactly one choice, exactly
## one irreversible resolution — and that shape has to be true whether it is
## driven by the ceremony scene, a controller shortcut, a debug command or a
## test.
##
## THE SIXTH PAL IS NOT STORED ANYWHERE. Read the header of party.gd: there is no
## box, no PC, no "temporarily holding" list, not even a private one. `_newcomer`
## below is a plain reference on this object, alive for exactly as long as the
## player is deciding, and it is never appended to an array that outlives the
## decision — candidates() builds its Array fresh on every call and hands out a
## copy. The next person here will be tempted to add a `pending` list on the
## party or a static `_in_flight` on this file so the ceremony can be reopened
## later. Do not. The moment a sixth pal can sit somewhere in memory, the
## ceremony stops being the only way to resolve a full party and the design's one
## irreversible decision quietly becomes optional.
##
## Resolution is one-way and one-shot on purpose. §10 says a released pal is
## permanently gone; a ceremony that can be run twice loses two pals, and one
## that can be undone loses the weight of the choice.
##
## No nodes, so it is testable headlessly and survives whatever scene the
## ceremony is drawn in.

const INSTANCE := preload("res://scripts/pals/pal_instance.gd")

## Why the last operation was refused, as a stable token — same discipline as
## party.gd, and for the same reason: the UI decides the wording, not this file.
const REFUSED_NOT_A_CANDIDATE := "not_a_candidate"
const REFUSED_NONE_CHOSEN := "none_chosen"
const REFUSED_ALREADY_RESOLVED := "already_resolved"

var _party: RefCounted = null

## The pal with nowhere to go. A plain reference, deliberately: see the header.
var _newcomer: RefCounted = null

## The five party members as they stood when the ceremony opened, so the indices
## the player is looking at cannot shift under them mid-decision. A copy, from
## party.members(), which already hands out a copy.
var _roster: Array = []

var _chosen: int = -1
var _resolved: bool = false
var _refusal: String = ""


## Open a ceremony, or return null if there is nothing to decide.
##
## Null — rather than an empty ceremony — for a party with room, because a
## ceremony that opens on a party of four is a dialog asking the player to give
## up a pal for no reason. The caller's flow is: add() refused with
## REFUSED_PARTY_FULL, so open one; anything else is a different bug.
##
## Also null for a newcomer the party already holds. That would present the same
## creature twice and let the player "release" a pal into itself.
static func open(party: RefCounted, newcomer: RefCounted) -> RefCounted:
	if party == null or not _is_pal(newcomer):
		return null
	if not party.is_full():
		return null
	if party.index_of(newcomer) >= 0:
		return null
	var ceremony: RefCounted = (load("res://scripts/pals/release_ceremony.gd") as GDScript).new()
	ceremony._party = party
	ceremony._newcomer = newcomer
	ceremony._roster = party.members()
	return ceremony


## Duck-typed rather than a script-identity check. What this actually needs from
## a candidate is what summary() reads off it; a check on those is a check on the
## thing that would break, and it does not care whether the instance arrived via
## preload or load.
static func _is_pal(candidate: RefCounted) -> bool:
	if candidate == null:
		return false
	return candidate.has_method("display") and candidate.has_method("to_record")


## --- what is on offer -----------------------------------------------------

## The six, party first in party order, newcomer LAST.
##
## Last and not first: the party is the thing the player knows, and the arriving
## creature is the interruption. Built fresh each call and returned by value, so
## nothing here is a list the newcomer lives in.
func candidates() -> Array:
	var out: Array = _roster.duplicate()
	out.append(_newcomer)
	return out


func count() -> int:
	return _roster.size() + 1


func newcomer_index() -> int:
	return count() - 1


func is_newcomer(index: int) -> bool:
	return index == newcomer_index()


func at(index: int) -> RefCounted:
	if index < 0 or index >= count():
		return null
	if is_newcomer(index):
		return _newcomer
	return _roster[index]


## What each candidate is, as data.
##
## The ceremony scene needs to say what is being given up without re-deriving it
## from the instance, and the evidence session needs the same facts in its
## transcript. A Dictionary rather than a sentence, for the reason
## pal_instance.appraisal() gives about its own: the ceremony and the party menu
## present the same facts very differently.
##
## Everything here is read straight off pal_instance. Nothing is invented, and
## nothing is formatted — no "Lv. 12", no rounded HP. For stars and stat ratios,
## call appraisal() on at(index); this deliberately does not restate it.
func summary(index: int) -> Dictionary:
	var pal: RefCounted = at(index)
	if pal == null:
		return {}
	return {
		# display() already resolves nickname-or-species-name, which is exactly
		# the name the player should be saying goodbye to.
		"name": pal.display(),
		"species": pal.species_id,
		"level": pal.level,
		"xp": pal.xp,
		"hp": pal.hp,
		"max_hp": pal.max_hp,
		"trait_id": pal.trait_id,
		"newcomer": is_newcomer(index),
	}


## --- the choice -----------------------------------------------------------

## Mark which one is to be released. Reversible until resolve(); nothing has
## happened to the party yet.
func choose(index: int) -> bool:
	if _resolved:
		_refusal = REFUSED_ALREADY_RESOLVED
		return false
	if index < 0 or index >= count():
		# Refused, not clamped. A clamp turns a mis-sent index into a real
		# creature being released, and that is the one mistake in this file that
		# cannot be taken back.
		_refusal = REFUSED_NOT_A_CANDIDATE
		return false
	_chosen = index
	_refusal = ""
	return true


func chosen_index() -> int:
	return _chosen


func chosen() -> RefCounted:
	return at(_chosen) if _chosen >= 0 else null


func clear_choice() -> void:
	# Does not un-resolve. Backing out of a highlighted choice is free; backing
	# out of a release is not a thing.
	_chosen = -1
	_refusal = ""


func resolved() -> bool:
	return _resolved


func last_refusal() -> String:
	return _refusal


## --- the irreversible bit -------------------------------------------------

## Carry out the release. Returns {"released": RefCounted, "kept": Array}, or an
## empty Dictionary with last_refusal() set.
##
## Either branch ends with the party at exactly MAX_PARTY, and the released
## instance comes back so the caller can name it in the goodbye rather than
## saying "the pal was released".
func resolve() -> Dictionary:
	if _resolved:
		# Not idempotent-with-the-same-answer: a second call must not be able to
		# cost a second pal, and it must not look like it succeeded either.
		_refusal = REFUSED_ALREADY_RESOLVED
		return {}
	if _chosen < 0:
		_refusal = REFUSED_NONE_CHOSEN
		return {}

	var released: RefCounted = at(_chosen)

	if is_newcomer(_chosen):
		# Nothing to do to the party. The newcomer was never in it — it has been
		# held on this object and is about to be dropped — so "releasing" it is
		# simply not keeping it, and the five stay exactly as they were.
		_resolved = true
		_refusal = ""
		return {"released": released, "kept": _party.members()}

	# The index the player chose is an index into the snapshot taken at open().
	# Ask the party where that CREATURE is now rather than trusting the position,
	# so a party that moved underneath the ceremony releases the pal that was
	# picked or nothing at all — never a different one.
	var index: int = _party.index_of(released)
	# Captured before the removal so the restore path below can put the deployed
	# pal back on the same creature.
	var was_active: RefCounted = _party.active()
	if not _party.remove_at(index):
		_refusal = _party.last_refusal()
		return {}

	if not _party.add(_newcomer):
		# Should be unreachable: the party has just gone to four, and the
		# newcomer is neither null nor already held (open() checked both). It is
		# handled anyway because the alternative failure is the party losing BOTH
		# pals, and a ceremony that refuses is much better than one that eats the
		# creature the player chose to keep.
		var token: String = _party.last_refusal()
		_put_back(released, index, was_active)
		_refusal = token
		return {}

	_resolved = true
	_refusal = ""
	return {"released": released, "kept": _party.members()}


## Undo a removal, in order, using only the party's public surface.
##
## party.gd has no insert_at — deliberately, since nothing in the game reorders a
## party — so restoring the position means rebuilding the roster. Only ever
## reached from the unreachable branch above; it exists so that branch can be
## honest instead of approximate.
func _put_back(member: RefCounted, index: int, was_active: RefCounted) -> void:
	var roster: Array = _party.members()
	roster.insert(clampi(index, 0, roster.size()), member)
	_party.clear()
	for pal: Variant in roster:
		_party.add(pal as RefCounted)
	var active: int = _party.index_of(was_active)
	if active >= 0:
		_party.set_active(active)
