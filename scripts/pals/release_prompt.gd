extends Node

## The thing that notices a sixth pal has nowhere to go, and opens the ceremony.
##
## `EncounterDirector` emits `caught_refused(token, instance)` and deliberately
## does not act on it — a director that decided what to do about a full party
## would be a second place the five-pal rule is interpreted (D13). This node is
## the one place that translates that refusal into a decision the player makes.
##
## It holds no pal of its own. The newcomer travels from the director's signal
## straight into the ceremony object, which holds it for the length of one
## decision and then either hands it to the party or lets it go. There is no
## overflow anywhere, including here — see the header of `party.gd`, which
## explains why a "pending" reference that outlives the decision would quietly
## make the ceremony optional.

const CEREMONY := preload("res://scripts/pals/release_ceremony.gd")
const PARTY := preload("res://scripts/pals/party.gd")

@export var encounter_path: NodePath
@export var party_path: NodePath
@export var screen_stack_path: NodePath
@export var release_screen_path: NodePath

## Emitted when the ceremony opens and when it finishes. Nothing in the game
## listens yet; they exist because the evidence session needs to be able to say
## *when* the ceremony happened relative to everything else, and reading a
## signal is the only way to do that without polling.
signal ceremony_opened(newcomer_name: String)
signal ceremony_closed(released_name: String)

var _encounter: Node = null
var _party: Node = null
var _stack: Node = null
var _screen: Control = null

## The depth the screen stack was at when the ceremony opened, so closing it
## takes off exactly the screens the ceremony put on and not whatever was
## underneath. Identifying the screens by node instead would mean this file
## knowing how many screens the ceremony is made of, which is the UI's business.
var _depth_before: int = 0

var _ceremony: RefCounted = null

## The last pal to leave, by name. A fact the session can log after the screens
## are gone. Empty until one has.
var _last_released: String = ""


func _ready() -> void:
	_encounter = get_node_or_null(encounter_path)
	_party = get_node_or_null(party_path)
	_stack = get_node_or_null(screen_stack_path)
	_screen = get_node_or_null(release_screen_path) as Control

	if _encounter != null and _encounter.has_signal("caught_refused"):
		_encounter.connect("caught_refused", _on_caught_refused)
	else:
		push_warning("release_prompt has no encounter director; a full party will refuse silently")

	if _screen != null and _screen.has_signal("ceremony_resolved"):
		_screen.connect("ceremony_resolved", _on_ceremony_resolved)


## A catch the party would not take.
##
## Only `party_full` opens the ceremony. The other refusal tokens mean something
## went wrong rather than something has to be decided — a null instance, or one
## the party already holds — and answering them with a keep-one-release-one
## screen would ask the player to give up a pal to fix a bug.
func _on_caught_refused(token: String, instance: RefCounted) -> void:
	if token != PARTY.REFUSED_PARTY_FULL:
		push_warning("catch refused with '%s'; not a case the ceremony resolves" % token)
		return
	if _party == null or _screen == null or _stack == null:
		push_error("a sixth pal was caught and the release ceremony is not wired up; it is lost")
		return

	var party: RefCounted = _party.get("party") as RefCounted
	if party == null:
		push_error("release_prompt could not reach the party object")
		return

	_ceremony = CEREMONY.open(party, instance)
	if _ceremony == null:
		push_error("the ceremony refused to open for %s" % instance.species_id)
		return

	_screen.call("set_ceremony", _ceremony)
	_depth_before = int(_stack.call("depth"))
	_stack.call("push", _screen)
	ceremony_opened.emit(str(instance.call("display")))


## One pal has gone. Write the save before anything else can happen.
##
## "Released pal leaves permanently" (M5) is a claim about the file on disk, not
## about an array in memory. Saving here rather than at the next autosave means
## the only window in which a crash could bring the released pal back is the few
## milliseconds inside `save()` — rather than the whole rest of the session,
## which is a window wide enough that a player would eventually find it.
func _on_ceremony_resolved(released_name: String) -> void:
	_last_released = released_name
	_close_screens()
	if _party != null and _party.has_method("save"):
		_party.call("save")
	_ceremony = null
	ceremony_closed.emit(released_name)


func _close_screens() -> void:
	if _stack == null:
		return
	# Pop by DEPTH, not by identity. The ceremony is one screen or two depending
	# on where the player got to, and popping "until the release screen is off"
	# would need this file to know which node that is on a stack it does not own.
	var guard := 8
	while int(_stack.call("depth")) > _depth_before and guard > 0:
		_stack.call("pop")
		guard -= 1


## --- what the session reads ------------------------------------------------

func is_open() -> bool:
	return _ceremony != null


func ceremony() -> RefCounted:
	return _ceremony


func last_released() -> String:
	return _last_released
