extends Node

## Where home is, and which beds are in it.
##
## GAME_DESIGN.md §16 does not say "a pal recovers in a pal bed". It says a pal
## recovers "in its physical pal bed AT HOME", and §20 lists the base's purpose
## as "safety, recovery, respawn". So there has to be something that knows which
## of the player's placed pieces is home, and that is this — one node, whose
## whole job is to turn a pile of placed structures into three answers:
##
##   * where home is
##   * which pal beds are at it
##   * which of those has room
##
## It OWNS NO BEDS. `structures.gd` already holds every placed piece, their nodes
## and their lifetimes, and its own header says a second list of beds somewhere
## else is a second list that can disagree with the first. This keeps only
## references, kept in step by the `station_placed` / `station_removing` signals
## `structures.gd` emits for exactly this, and re-checked for validity on every
## read.
##
## IT NEVER TOUCHES A PAL. Nothing here begins a rest, ends one, or knows what a
## pal is; it answers "which bed" and the caller does the rest. That separation
## is the same one `station.gd` insists on and for the same hard-rule reason
## (CLAUDE.md: pals do not perform base jobs) — a bed is somewhere a pal sleeps,
## and a thing that both chose a bed AND put a creature in it would be one
## refactor away from a work roster.
##
## No tree required: `bind()` and `register()` are public so a test can build a
## home out of loose `RestStation`s without a scene, which is how
## `tests/test_recovery.gd` exercises it.

const STATION := preload("res://scripts/building/station.gd")
## For `data/config/party.json`. Loaded through pal_instance so there is ONE
## reader of that file rather than two that can disagree about its defaults —
## the same reason `encounter_director` reaches for it this way.
const PAL := preload("res://scripts/pals/pal_instance.gd")

## Home moved, or appeared, or went away. `where` is `Vector3.INF` when there is
## no home at all, which is a state the game can genuinely be in for as long as
## the player has not built a bed.
signal home_changed(where: Vector3)

## Nowhere. A sentinel rather than `Vector3.ZERO`, because the world origin is a
## real place a bed could stand and "no home" must not be confused with "home is
## at the origin".
const NOWHERE := Vector3.INF

@export var structures_path: NodePath

var _structures: Node = null
## Rest stations, split by who they are for. Placement order is preserved, and
## that is load-bearing: see `home_bed()`.
var _player_beds: Array[Node] = []
var _pal_beds: Array[Node] = []

var _last_home: Vector3 = NOWHERE


func _ready() -> void:
	bind(get_node_or_null(structures_path))


## Point this at the thing that holds placed pieces.
##
## Everything already placed is picked up, not only what is placed from now on:
## `structures.load_data()` rebuilds a saved village during boot and may well
## have finished before this node was ready.
func bind(structures: Node) -> void:
	if _structures != null and is_instance_valid(_structures):
		if _structures.is_connected("station_placed", register):
			_structures.disconnect("station_placed", register)
		if _structures.is_connected("station_removing", forget):
			_structures.disconnect("station_removing", forget)
	_player_beds.clear()
	_pal_beds.clear()
	_structures = structures
	if _structures == null:
		return
	if _structures.has_signal("station_placed"):
		_structures.connect("station_placed", register)
	if _structures.has_signal("station_removing"):
		_structures.connect("station_removing", forget)
	if _structures.has_method("stations"):
		for station: Variant in _structures.call("stations", STATION.BEHAVIOUR_REST):
			register(station as Node)
	_announce()


## Take note of a bed. Public because the signal handler and a test are the same
## call, and because a scene that wires its beds some other way should not have
## to fake a signal.
##
## Anything that is not a rest station is ignored in silence — a campfire is
## announced through the same signal and is simply not this node's business.
func register(station: Node) -> bool:
	if station == null or not is_instance_valid(station):
		return false
	if str(station.get("behaviour")) != STATION.BEHAVIOUR_REST:
		return false
	if _player_beds.has(station) or _pal_beds.has(station):
		return false
	if bool(station.call("is_for_pals")):
		_pal_beds.append(station)
	else:
		_player_beds.append(station)
	_announce()
	return true


func forget(station: Node) -> void:
	_player_beds.erase(station)
	_pal_beds.erase(station)
	_announce()


## --- where home is --------------------------------------------------------

## The bed that makes this place home, or null.
##
## TWO BEDS: the most recently placed one wins, and a respawn-capable one beats
## one that is not. That is the rule every game in this genre already taught the
## player — you build a new bed, that is your new home — and it is the only
## answer that survives a reload for free: `structures.load_data()` replays
## placements in order, so "the last one placed" is the same bed tomorrow.
##
## ZERO BEDS: there is no home. Not "the player's spawn point", not "wherever
## they are standing" — nothing, and every caller is expected to say so out loud
## rather than quietly recovering pals in a field. §20's tutorial has the player
## build shelter, bed and campfire before anything else; this is what makes that
## sequence mean something.
func home_bed() -> Node:
	_prune()
	for i in range(_player_beds.size() - 1, -1, -1):
		if bool((_player_beds[i] as Node).call("is_respawn_point")):
			return _player_beds[i]
	return _player_beds.back() if not _player_beds.is_empty() else null


func has_home() -> bool:
	return home_bed() != null


## Where home is, or `NOWHERE`.
func home_point() -> Vector3:
	var bed := home_bed()
	return NOWHERE if bed == null else (bed.call("where") as Vector3)


## Where the player comes back to when they die. §22 and §20 both want one; M9
## owns player death, and this is the answer waiting for it.
##
## The same bed as `home_bed()` today, and a separate function anyway, because
## "where recovery happens" and "where you wake up" are two questions that a
## later design (a second house, a camp) could answer differently.
func respawn_point() -> Vector3:
	var bed := home_bed()
	if bed == null or not bool(bed.call("is_respawn_point")):
		return NOWHERE
	return bed.call("where") as Vector3


## Is this point inside home?
##
## `lenient` adds the leave-slack, and is for a caller asking "is this still
## home" about something already happening — without it, a trainer standing on
## the radius makes their pals stand up and lie down on alternate frames.
func is_at_home(point: Vector3, lenient: bool = false) -> bool:
	var here := home_point()
	if here == NOWHERE:
		return false
	var radius := home_radius()
	if lenient:
		radius += float(config().get("home_leave_slack", 5.0))
	return here.distance_to(point) <= radius


func home_radius() -> float:
	return maxf(1.0, float(config().get("home_radius", 16.0)))


## --- the beds -------------------------------------------------------------

## Every pal bed the player has placed, at home or not.
func pal_beds() -> Array:
	_prune()
	return _pal_beds.duplicate()


## The pal beds that are AT HOME, nearest first.
##
## A pal bed dropped halfway up a hill is not a recovery point, and this is where
## that is decided. It returns an empty list when there is no home at all, which
## is the honest answer: without a bed of your own there is no "home" for a pal
## bed to be at.
func pal_beds_at_home() -> Array:
	var here := home_point()
	if here == NOWHERE:
		return []
	var radius := home_radius()
	var found: Array = []
	for bed: Variant in pal_beds():
		if float((bed as Node).call("distance_to", here)) <= radius:
			found.append(bed)
	found.sort_custom(func(a: Node, b: Node) -> bool:
		return float(a.call("distance_to", here)) < float(b.call("distance_to", here)))
	return found


## A pal bed at home with room in it, or null.
##
## Capacity is one per bed by data (`pieces.json`), so five pals need five beds
## and this is what runs out. A caller that gets null is expected to tell the
## player to build another one — `station.gd`'s header settles why the answer is
## a refusal rather than a queue.
func free_pal_bed() -> Node:
	for bed: Variant in pal_beds_at_home():
		if bool((bed as Node).call("has_room")):
			return bed
	return null


## The pal bed nearest a point, within `radius`. What a save file's "this pal was
## resting HERE" is turned back into a bed with, since a bed is a node and a
## record can only carry a position.
func bed_nearest(point: Vector3, radius: float = 1.5) -> Node:
	var best: Node = null
	var best_distance := radius
	for bed: Variant in pal_beds():
		var distance := float((bed as Node).call("distance_to", point))
		if distance <= best_distance:
			best_distance = distance
			best = bed
	return best


## --- internals ------------------------------------------------------------

func config() -> Dictionary:
	return PAL.config().get("recovery", {})


## Drop beds whose pieces have been demolished.
##
## `station_removing` covers the ordinary case, but a structures node that is
## cleared wholesale — `load_data()` does exactly that — frees pieces in ways a
## listener should not have to predict. Indexed and untyped, for the reason
## `RestStation._prune()` gives: assigning a freed instance to a typed local is
## itself an error, so the obvious typed loop throws on the entry being removed.
func _prune() -> void:
	_player_beds = _live(_player_beds)
	_pal_beds = _live(_pal_beds)


func _live(beds: Array[Node]) -> Array[Node]:
	var out: Array[Node] = []
	for i in beds.size():
		if is_instance_valid(beds[i]):
			out.append(beds[i])
	return out


func _announce() -> void:
	var here := home_point()
	if here == _last_home:
		return
	_last_home = here
	home_changed.emit(here)
