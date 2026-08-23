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
const PERF := preload("res://scripts/world/performance_config.gd")
const PERF_TRACE := preload("res://scripts/world/perf_trace.gd")

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
## PERF-2. `register()`/`unregister()` used to test/remove membership with
## `Array.has()`/`Array.erase()` alone, both O(n) linear scans over
## `_providers`. Registration happens once per `Interactable._ready()`
## (`interactable.gd::_attach()`), and HARVEST-ALL made ~19,193 scatter
## placements (every harvestable tree/rock) each carry one -- registering
## them all in a tight boot-time burst made every `has()` scan longer than
## the last, an O(n^2) wall that measured as 5.75s of `vegetation.gd::
## build()`'s 6.2s `build_batches_total` in isolation (`tools/
## _probe_veg_boot_phases.gd`, this box, bake already fresh -- so this was
## the actual bottleneck, not `Node.new()`/`add_child()` cost as the task
## brief assumed going in). This mirrors `_providers` as a real O(1)
## membership index; `_providers` itself is UNCHANGED in type, order or
## iteration (`_recompute()` still walks the Array, which is what fixed
## iteration order for `prompt_arbiter.gd`'s tie-breaking depends on) --
## this only ever answers "is it already in there".
var _provider_set: Dictionary = {}

## --- PERF-ROG / OP23-01: the spatial index -----------------------------------
##
## `_recompute()` ran `interaction_offer()` on EVERY registered provider, every
## frame. Measured on the real corridor by `tools/perf_profile.gd`: 24,461
## providers, 15.6ms of pure method-call cost per frame, to find the two that
## were actually in range -- 1,221 ms of work per wall-clock second, more than a
## whole CPU second per second, and by a factor of sixty the largest per-frame
## cost anywhere in the game. That is OP23-01's "feels like ten frames per
## second": the frame cannot finish inside its budget no matter what the GPU
## does. 24,398 of those providers are `vegetation.gd::_spawn_harvest_point()`
## gather points -- one per harvestable scattered tree or rock -- and every one
## of them is a fixed point in the world that the player is nowhere near.
##
## PERF-2 already fixed the O(n^2) REGISTRATION cost this same population caused
## at boot (see `_provider_set` above). This is the other half: the O(n) POLL.
##
## A uniform 2D grid over x/z. Providers that are `Node3D` live in the cell
## their position falls in; providers that are not (`encounter_director.gd`,
## `riding_controller.gd` -- managers that answer for whatever is nearest, and
## have no position of their own) go in `_loose` and are polled every frame as
## before, because there are two of them.
##
## THE RESULT IS IDENTICAL, not merely similar, and that is the point:
##
## - No offer is lost. A provider only ever returns an offer when the player is
##   inside its own `radius`, so querying every cell within `_query_radius` --
##   a running maximum of every registered provider's radius, which only ever
##   grows -- returns a strict SUPERSET of everything that could offer.
## - Tie-breaking is unchanged. `prompt_arbiter.gd` breaks a priority-and-
##   distance tie in favour of whichever provider registered first, so the
##   candidates are sorted back into registration order before they are offered
##   to it. `_provider_set` holds each provider's registration ordinal for
##   exactly this (it held a placeholder `true` before).
##
## Movement is handled by the engine rather than by polling: `interactable.gd`
## turns on `set_notify_transform(true)` and calls `reindex()` from
## `NOTIFICATION_TRANSFORM_CHANGED`, so a prompt bolted to a walking NPC
## re-buckets itself the moment it actually moves and a gather point standing
## still costs nothing at all.

## Grid cell edge, metres. Tunable in `data/config/performance.json`.
##
## Only the constant factor is sensitive to this: too small and the query walks
## more mostly-empty cells than it needs to, too large and each cell holds more
## providers than the query needed to look at. Anything in the same order as the
## largest prompt radius (4.0m today) is fine; the default is a comfortable
## multiple of it.
var _cell_m: float = 8.0

## cell (Vector2i) -> Array of providers whose position falls in it.
var _cells: Dictionary = {}
## provider -> the cell it is currently filed under.
var _cell_of: Dictionary = {}
## Providers with no position of their own; polled every frame.
var _loose: Array = []
## Half-extent of the cell query, metres: the largest `radius` any registered
## provider has ever declared. Only ever grows -- a provider whose radius
## shrinks would otherwise need every other provider's radius rechecked to
## know whether the maximum came down, and over-querying by a few metres costs
## a handful of empty dictionary lookups.
var _query_radius: float = 0.0
## Registration counter, handed out by `register()`.
var _next_ordinal: int = 0

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
	_cell_m = maxf(1.0, float(PERF.config().get("interaction_grid_cell_m", 8.0)))


## Late binding, for a player that is not reachable by a fixed path — the
## opening scene instances the world, so the arbiter above it cannot name the
## body inside it until the tree is up.
func set_player(player: Node3D) -> void:
	_player = player


func register(provider: Object) -> void:
	if provider == null or _provider_set.has(provider):
		return
	if not provider.has_method("interaction_offer") or not provider.has_method("interaction_activate"):
		push_error("%s registered as an interaction provider without the two methods" % provider)
		return
	_providers.append(provider)
	_provider_set[provider] = _next_ordinal
	_next_ordinal += 1
	_index(provider)


func unregister(provider: Object) -> void:
	_providers.erase(provider)
	_provider_set.erase(provider)
	_deindex(provider)


## Re-file a provider that has moved. Called by `interactable.gd` from
## `NOTIFICATION_TRANSFORM_CHANGED` and whenever its `radius` is written, so a
## prompt on a moving body stays in the right cell without anything polling for
## it. Safe to call on an unregistered provider, which is what makes it safe to
## call from a setter that can run before `_ready()`.
func reindex(provider: Object) -> void:
	if provider == null or not _provider_set.has(provider):
		return
	_deindex(provider)
	_index(provider)


func _cell_for(spot: Vector3) -> Vector2i:
	return Vector2i(int(floorf(spot.x / _cell_m)), int(floorf(spot.z / _cell_m)))


func _index(provider: Object) -> void:
	# `radius` is read whether or not the provider is placeable: a loose
	# provider with a big radius does not widen the query (it is always polled)
	# but reading it uniformly keeps the maximum honest if one ever gains a
	# position.
	var declared: Variant = provider.get("radius")
	if declared is float or declared is int:
		_query_radius = maxf(_query_radius, float(declared))
	var node := provider as Node3D
	if node == null or not node.is_inside_tree():
		if not _loose.has(provider):
			_loose.append(provider)
		return
	var cell := _cell_for(node.global_position)
	var bucket: Array = _cells.get(cell, [])
	bucket.append(provider)
	_cells[cell] = bucket
	_cell_of[provider] = cell


func _deindex(provider: Object) -> void:
	if _cell_of.has(provider):
		var cell: Vector2i = _cell_of[provider]
		var bucket: Array = _cells.get(cell, [])
		bucket.erase(provider)
		if bucket.is_empty():
			_cells.erase(cell)
		else:
			_cells[cell] = bucket
		_cell_of.erase(provider)
	else:
		_loose.erase(provider)


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
	if not PERF_TRACE.enabled:
		_recompute()
		return
	var t0 := Time.get_ticks_usec()
	_recompute()
	PERF_TRACE.record("interaction arbiter", Time.get_ticks_usec() - t0)


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
	# otherwise mutate the list mid-walk. `_candidates()` already returns a
	# fresh Array, so the copy that used to be taken here is now free.
	for provider: Variant in _candidates(from):
		if provider == null or not is_instance_valid(provider):
			_forget(provider)
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


## Every provider that could possibly offer from `from`, in registration order.
##
## Registration order is not cosmetic: `prompt_arbiter.gd::choose_index()`
## resolves a priority-and-distance tie by taking the earliest entry, so a grid
## walk that returned the same providers in cell order would silently change
## which of two identical side-by-side berry bushes owns the prompt. The sort is
## over a handful of entries -- two loose providers plus whatever is in the nine
## or so cells around the player -- not over the population.
func _candidates(from: Vector3) -> Array:
	var found: Array = _loose.duplicate()
	var reach: int = int(ceilf(_query_radius / _cell_m))
	var centre := _cell_for(from)
	for dx in range(-reach, reach + 1):
		for dz in range(-reach, reach + 1):
			var bucket: Variant = _cells.get(Vector2i(centre.x + dx, centre.y + dz))
			if bucket is Array:
				found.append_array(bucket as Array)
	if found.size() > 1:
		found.sort_custom(_by_registration)
	return found


func _by_registration(a: Variant, b: Variant) -> bool:
	return int(_provider_set.get(a, 0)) < int(_provider_set.get(b, 0))


## Drop a provider that has been freed without unregistering. The old loop
## walked every provider every frame and could prune anywhere; this one only
## visits providers near the player, so a freed provider elsewhere is simply
## never looked at again -- which is fine, because `interactable.gd::
## _exit_tree()` unregisters on the way out and `queue_free()` always exits the
## tree first. This stays as the belt to that braces.
func _forget(provider: Variant) -> void:
	_providers.erase(provider)
	_provider_set.erase(provider)
	if provider is Object:
		_deindex(provider as Object)
	else:
		_loose.erase(provider)


func _publish(text: String) -> void:
	if text == _prompt:
		return
	_prompt = text
	prompt_changed.emit(text)
