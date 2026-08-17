extends Node

## The one interact prompt, and the one place `interact` is read outside combat.
##
## Providers register themselves; every idle frame this asks each of them what
## it is offering, picks a winner with `prompt_arbiter.gd`, and publishes the
## line. Pressing the button activates whatever is currently winning.
##
## A provider is any object with two methods:
##
##   interaction_offer(from: Vector3) -> Dictionary   (see prompt_arbiter.gd)
##   interaction_activate() -> void
##
## Duck-typed rather than a base class because the two kinds of provider have
## nothing else in common: `interactable.gd` is a Node3D bolted to a body, and
## `encounter_director.gd` is a manager that answers for whichever wild creature
## happens to be nearest. Forcing one class on both would mean the director
## inheriting from a spatial node it is not.
##
## Reading input in one place matters more than it looks. Before this there was
## a single hardcoded prompt, so "who owns the interact button" was not a
## question. With Grandpa, three starters and a wild creature in one meadow it is the
## whole problem — two nodes each reading `is_action_just_pressed` means walking
## between Grandpa and a starter fires both.

const ARBITER := preload("res://scripts/world/prompt_arbiter.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

## Interactables find their arbiter through this rather than through an exported
## path, so a body can be spawned in code and dropped anywhere in the tree.
const GROUP := "interaction_arbiter"

signal prompt_changed(text: String)
## The winning offer was activated. Carries the provider so a listener (the
## sequence director) can tell which one without subscribing to every body.
signal activated(provider: Object)

@export var player_path: NodePath

var _player: Node3D = null
var _providers: Array = []
var _prompt: String = ""
var _winner: Dictionary = {}
var _winning_provider: Object = null

## Cleared while a conversation, a naming prompt or a fight owns the screen.
## The prompt goes with it: an "[X] Talk to Grandpa" line under an open dialogue
## box is an offer to press a button that is already doing something else.
var _enabled: bool = true


func _ready() -> void:
	add_to_group(GROUP)
	_player = get_node_or_null(player_path) as Node3D


## Late binding, for a player that is not reachable by a fixed path — the
## opening scene instances the world, so the arbiter above it cannot name the
## body inside it until the tree is up.
func set_player(player: Node3D) -> void:
	_player = player


func register(provider: Object) -> void:
	if provider == null or _providers.has(provider):
		return
	if not provider.has_method("interaction_offer") or not provider.has_method("interaction_activate"):
		push_error("%s registered as an interaction provider without the two methods" % provider)
		return
	_providers.append(provider)


func unregister(provider: Object) -> void:
	_providers.erase(provider)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		_publish("")
		_winner = {}
		_winning_provider = null


func enabled() -> bool:
	return _enabled


func prompt() -> String:
	return _prompt


## What is currently winning, for anything that needs more than the drawn line.
func winner() -> Dictionary:
	return _winner


## Which registered provider's offer is currently drawn, or null if nothing
## is. `EV9-double-prompt`: a provider that only wants to know "is the line
## on screen mine right now" (`combat_hud.gd`, deciding whether to mirror
## `encounter_director`'s prompt outside a fight) needs this rather than the
## formatted text, which carries no identity.
func winning_provider() -> Object:
	return _winning_provider


func _process(_delta: float) -> void:
	_recompute()


## Read on the physics tick, for the reason spelled out in
## encounter_director._physics_process: `is_action_just_pressed` is scoped to
## the frame the press landed in, and this and the combat manager must agree
## about which frame that was.
##
## UI-PAD2: `_enabled` only ever goes false for a conversation, a naming
## prompt or a fade (`sequence_director.gd::_refresh_lockout`) -- none of
## which is `build_menu.gd`, the one panel in this game that deliberately
## does not pause the tree. Without the `input_owner.gd` check too, pressing
## `interact` while browsing the build catalog could still fire whatever
## real-world interactable the player happened to be standing near (a door,
## an NPC, a wild creature) — invisible to the player, since their attention
## and the screen are both on the menu. This node is otherwise `PAUSABLE`
## (the default, unset here), so the six tree-pausing panels already stop it
## for free; this is the same non-pausing-panel gap `build_placer.gd` closed.
func _physics_process(_delta: float) -> void:
	if not _enabled:
		return
	if INPUT_OWNER.current(get_tree()) != null:
		return
	if not Input.is_action_just_pressed("interact"):
		return
	activate()


## Fire the winning offer. Returns whether anything was activated, so a caller
## driving this from a test can tell a refused press from a missed one.
func activate() -> bool:
	if not _enabled or _winning_provider == null:
		return false
	if not ARBITER.is_actionable(_winner):
		return false
	var provider := _winning_provider
	if not is_instance_valid(provider):
		_winning_provider = null
		return false
	provider.call("interaction_activate")
	activated.emit(provider)
	return true


func _recompute() -> void:
	if not _enabled:
		return
	if _player == null or not is_instance_valid(_player):
		_publish("")
		return

	var from := _player.global_position
	var offers: Array = []
	var owners: Array = []
	# Iterated over a copy: a provider that answers by despawning itself would
	# otherwise mutate the list mid-walk.
	for provider: Variant in _providers.duplicate():
		if provider == null or not is_instance_valid(provider):
			_providers.erase(provider)
			continue
		var offer: Variant = provider.call("interaction_offer", from)
		if not offer is Dictionary or (offer as Dictionary).is_empty():
			continue
		offers.append(offer)
		owners.append(provider)

	var index := ARBITER.choose_index(offers)
	_winner = {} if index < 0 else offers[index] as Dictionary
	_winning_provider = null if index < 0 else owners[index]
	_publish(ARBITER.format(_winner))


func _publish(text: String) -> void:
	if text == _prompt:
		return
	_prompt = text
	prompt_changed.emit(text)
