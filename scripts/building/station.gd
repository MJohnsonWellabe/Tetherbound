extends RefCounted

## A placed piece that DOES something.
##
## `pieces.json` used to carry a comment explaining why the campfire, the beds,
## the workbench, storage and the berry plot were absent from the M8 build set:
## "each is a station with behaviour, not a piece of geometry." That was true and
## it was also a dead end, because it left the six pieces waiting on a thing
## nobody had written. This file is that thing.
##
## THE HOOK, in one sentence: a piece definition may carry a `station` block; a
## piece placed from such a definition gets one of the classes below attached as
## a child node named `Station`, and `structures.gd` saves whatever that station
## says its state is alongside the placement. Nothing else changes. A station is
## a normal piece — same grid, same anchor, same collider, same catalogue, same
## record — that happens to answer questions afterwards.
##
## Deliberately static and node-free at the top level, like `build_grid.gd`: the
## dispatch and the record merging are arithmetic on dictionaries and are unit
## testable without a scene. Only the stations themselves are Nodes, and they are
## Nodes for one reason — signals and lifetime. A station has to be freed exactly
## when its piece is, and a `RefCounted` held by a record would outlive the wall
## it belongs to.
##
## PALS DO NOT PERFORM BASE JOBS. This is a `CLAUDE.md` hard rule and it is the
## rule this file is most likely to break by accident, because "buildings with
## behaviour" is the exact shape of a work-station system. So, explicitly:
##
##   - A pal bed is somewhere a pal RESTS. It has no output, no work timer, no
##     production, no assignment and no throughput.
##   - No station may ever ask a pal to do anything. `begin_rest()` is called BY
##     whoever owns pal recovery, into the bed; the bed never reaches out.
##   - If a station ever needs a verb like `assign()`, `work()`, `produce()` or
##     `staff()`, the rule has been broken and the design decision has to go back
##     to the owner rather than into this file.
##
## COSTS ARE NOT HERE, AND THIS IS THE SEAM. `GAME_DESIGN.md` §20 has building
## consume Wood/Stone/Fiber, and D12 records why nothing consumes anything yet:
## there is no inventory to spend from. When there is one, the cost belongs on
## the piece definition in `pieces.json` beside `model` and `anchor`, and the
## check belongs in `build_mode._check()` beside "too far away" and "ground is
## too uneven" — because a refusal the player must read is a placement refusal,
## not a station concern. No currency is invented here and no empty `cost` key is
## left lying around to be mistaken for a working one.


## The child node a station is attached as. One name, so `of()` and the tests and
## anything else looking for one all agree.
const NODE_NAME := "Station"

## Where a station's block lives in a piece definition, and where its saved state
## lives in a placement record. The same word in both places on purpose: they are
## the two halves of one thing, and a reader who finds one should be able to
## guess the other.
const KEY := "station"

## The behaviours that exist. A piece naming anything else is a data error and is
## reported as one rather than placing a piece that silently does nothing.
const BEHAVIOUR_REST := "rest"
const BEHAVIOUR_HEARTH := "hearth"

## STILL TO COME, and deliberately not stubbed. An empty station that places and
## does nothing is worse than no station: it looks finished in a palette, passes
## every test, and is the "written and never called" shape this project keeps
## getting bitten by. Each of these is one entry in the match below plus a class,
## on the day the system it feeds exists:
##
##   - `workbench`  — M8. Waiting on crafting recipes; a bench with nothing to
##                    craft is a decoration with extra steps.
##   - `storage`    — M9. Waiting on the slot/stack inventory container, which is
##                    being built now; a chest is a view onto one, not a new one.
##   - `berry_plot` — M8/§21 farming. Waiting on plant/grow/harvest and a berry
##                    item to yield.


## Build the station a piece definition asks for, or null if it asks for none.
##
## Takes the whole definition rather than the `station` block, so that a caller
## never has to know the key — `place()` hands over what it already has and gets
## back either a node to attach or nothing.
static func create(definition: Dictionary) -> Node:
	var config := config_of(definition)
	if config.is_empty():
		return null
	var behaviour := str(config.get("behaviour", ""))
	var station: Node = null
	match behaviour:
		BEHAVIOUR_REST:
			station = RestStation.new()
		BEHAVIOUR_HEARTH:
			station = Hearth.new()
		_:
			push_error("build piece asks for station behaviour '%s', which does not exist" % behaviour)
			return null
	station.name = NODE_NAME
	return station


## A piece definition's station block, or empty for a piece that is only
## geometry. Type-checked rather than cast, because the catalogue is a JSON file
## a human edits and `"station": true` should read as "no station" rather than
## crash the placement of a wall three pieces later.
static func config_of(definition: Dictionary) -> Dictionary:
	var config: Variant = definition.get(KEY, {})
	return (config as Dictionary).duplicate(true) if config is Dictionary else {}


## The station on a placed piece, or null for the twenty-eight that are geometry.
static func of(piece_node: Node) -> Node:
	if piece_node == null or not is_instance_valid(piece_node):
		return null
	return piece_node.get_node_or_null(NodePath(NODE_NAME))


## Put a station's live state into a placement record, and take it back out.
##
## Pure dictionary work, kept here rather than in `structures.gd` so that the two
## directions sit next to each other and cannot drift: the whole failure mode of
## a save is one side writing a key the other side does not read.
##
## A record only grows the key when there is something to say. A wall's record is
## byte-for-byte what it was before stations existed, which is what keeps the
## twenty-eight existing pieces a non-event.
static func write_record(record: Dictionary, station: Node) -> Dictionary:
	var out := record.duplicate(true)
	out.erase(KEY)
	if station == null or not is_instance_valid(station):
		return out
	var state: Dictionary = station.call("save_state")
	if not state.is_empty():
		out[KEY] = state
	return out


## The state a record carries for its station. Empty for a piece that has none,
## and empty for a station that saves nothing — both mean "take the defaults from
## the catalogue", which is exactly right.
static func read_record(record: Dictionary) -> Dictionary:
	var state: Variant = record.get(KEY, {})
	return (state as Dictionary).duplicate(true) if state is Dictionary else {}


## --- the stations ---------------------------------------------------------


## What every station is: a thing in the world, with a position, that can be
## asked what it is, told to persist itself, and told to clean up.
class Station extends Node:

	## Emitted immediately before the piece goes away, while the station is still
	## valid. Anything holding on to a station listens to this rather than
	## discovering the hard way that its bed has been deleted.
	signal removed()

	var piece_id: String = ""
	var behaviour: String = ""
	var config: Dictionary = {}

	## Where the piece was placed, in world space.
	##
	## STORED, not read back off the node. `Node3D.global_position` needs the
	## node to be inside the scene tree and returns a silent (0,0,0) when it is
	## not, so a station that asked its parent every time would answer "the
	## world origin" for every bed in a tool script or a test. It is also simply
	## true: a placed piece never moves.
	var origin: Vector3 = Vector3.ZERO

	func setup(id: String, station_config: Dictionary, at: Vector3) -> void:
		piece_id = id
		config = station_config.duplicate(true)
		behaviour = str(config.get("behaviour", ""))
		origin = at
		_configured()

	## Subclass hook, run once the config and origin are in place.
	func _configured() -> void:
		pass

	## The place in the world this station is, so something can ask "is a pal
	## resting HERE" rather than "is a pal resting at bed index 3".
	func where() -> Vector3:
		return origin

	func distance_to(point: Vector3) -> float:
		return origin.distance_to(point)

	## What the save file carries for this station beyond its placement.
	##
	## Most stations return nothing, and that is not a gap: the piece id is in
	## the record, the piece id names the definition, and the definition names
	## the behaviour — so a bed comes back a bed with no help. This is only for
	## state the PLAYER changed after placing it, which the catalogue cannot know.
	func save_state() -> Dictionary:
		return {}

	func load_state(_state: Dictionary) -> void:
		pass

	## The piece is being removed. Undo everything this station did, while the
	## node is still alive to do it with.
	func release() -> void:
		_release()
		removed.emit()

	func _release() -> void:
		pass


## A bed. Somewhere a pal — or the trainer — lies down and recovers.
##
## `MEADOWS_VERTICAL_SLICE.md` M6 wants a pal bed, home recovery and visible pal
## rest behaviour. This is the first of those three and only the first: the bed
## knows WHO is resting on it and WHERE, and says so. It does not know what
## resting does, because recovery rules live with pal state and belong to
## whoever owns that.
##
## CAPACITY IS ONE, and it is data (`capacity` in the piece's station block).
## Five pals therefore need five pal beds. The alternative — one bed the whole
## party shares — was rejected for three reasons: `GAME_DESIGN.md` §20 lists
## "pal beds" plural among the base's categories; a bed with a queue is a
## facility with throughput, which is the first step towards the base-jobs
## thinking the hard rules forbid; and a base that visibly grows a bed per pal
## is the cheapest legible reward building has. Overflow is a refusal with a
## token, not a wait list — `REFUSED_FULL` is how the recovery system learns to
## tell the player to build another bed.
class RestStation extends Station:

	## The two halves of "visible pal rest behavior". A rest animation, a
	## recovery tick and a HUD line all hang off these and none of them belong
	## here.
	signal rest_began(occupant: Object)
	signal rest_ended(occupant: Object, reason: String)

	const REASON_DONE := "done"
	## The bed was deleted out from under a sleeper. Everyone resting is woken
	## with this before the node is freed, so nothing is left holding a bed that
	## no longer exists.
	const REASON_REMOVED := "removed"

	## Refusal tokens, not sentences — `party.gd` established the idiom and the
	## reason holds: the bed has no business knowing how a refusal is worded.
	const REFUSED_FULL := "station_full"
	const REFUSED_ALREADY := "already_resting"
	const REFUSED_NOBODY := "nobody"
	const REFUSED_WRONG_SLEEPER := "wrong_sleeper"

	const FOR_PAL := "pal"
	const FOR_PLAYER := "player"

	var capacity: int = 1
	## Who this bed is for. A pal bed is not the trainer's bed and the trainer's
	## bed is not a pal's; §20 lists them as two categories and the tutorial
	## builds the human one.
	var rests: String = FOR_PAL
	## Player beds are the respawn point. §20: the base is for "safety, recovery,
	## respawn and rest".
	var respawn: bool = false

	var _occupants: Array = []
	var _refusal: String = ""

	func _configured() -> void:
		capacity = maxi(1, int(config.get("capacity", 1)))
		rests = str(config.get("rests", FOR_PAL))
		respawn = bool(config.get("respawn", false))

	func is_for_pals() -> bool:
		return rests == FOR_PAL

	func is_respawn_point() -> bool:
		return respawn

	## Where a sleeper should actually be put. The bed's own spot for the first
	## occupant; offset along X for any further ones, so a bed built with a
	## capacity above one does not stack its sleepers inside each other.
	func rest_point(index: int = 0) -> Vector3:
		if index <= 0:
			return origin
		return origin + Vector3(float(index) * 0.6, 0.0, 0.0)

	func occupant_count() -> int:
		_prune()
		return _occupants.size()

	func has_room() -> bool:
		return occupant_count() < capacity

	func occupants() -> Array:
		_prune()
		return _occupants.duplicate()

	func is_resting(occupant: Object) -> bool:
		_prune()
		return _occupants.has(occupant)

	## Why the last call was refused, as a stable token. Empty after a success.
	func last_refusal() -> String:
		return _refusal

	## Somebody lies down. Returns false and changes nothing if they cannot.
	##
	## Called INTO the bed by whatever owns the sleeper. The bed never reaches
	## out and tells a pal to rest — see the hard-rule note at the top of this
	## file.
	func begin_rest(occupant: Object) -> bool:
		_refusal = ""
		if occupant == null or not is_instance_valid(occupant):
			_refusal = REFUSED_NOBODY
			return false
		_prune()
		if _occupants.has(occupant):
			_refusal = REFUSED_ALREADY
			return false
		if _occupants.size() >= capacity:
			_refusal = REFUSED_FULL
			return false
		_occupants.append(occupant)
		rest_began.emit(occupant)
		return true

	func end_rest(occupant: Object, reason: String = REASON_DONE) -> bool:
		_refusal = ""
		_prune()
		var at := _occupants.find(occupant)
		if at < 0:
			_refusal = REFUSED_NOBODY
			return false
		_occupants.remove_at(at)
		rest_ended.emit(occupant, reason)
		return true

	## Wake everybody. Used when the bed is removed, and available to whoever
	## owns morning.
	func vacate_all(reason: String = REASON_DONE) -> int:
		_prune()
		var woken := _occupants.duplicate()
		_occupants.clear()
		for i in woken.size():
			rest_ended.emit(woken[i], reason)
		return woken.size()

	## A bed deleted under a sleeping pal. The pal is woken first, with a reason
	## that says why, and only then does the node go. Nothing is left holding a
	## reference to a freed bed, which is the crash this method exists to
	## prevent.
	func _release() -> void:
		vacate_all(REASON_REMOVED)

	## Occupancy is RUNTIME state and is deliberately not in `save_state()`.
	## Nothing is asleep at the moment a save is loaded: the pals themselves come
	## back through the party domain, as records rather than as the objects that
	## were in this array, so a persisted occupant would restore a reference to
	## something that no longer exists.

	## Drop occupants that no longer exist — a sleeper despawned by something
	## else must not hold a bed open forever, because nothing will come to wake
	## it.
	##
	## Indexed, and with no typed loop variable, on purpose: assigning a freed
	## instance to a `var x: Object` is itself an error in GDScript, so the
	## obvious `for occupant: Object in _occupants` throws on exactly the entry
	## this function exists to remove.
	func _prune() -> void:
		var live: Array = []
		for i in _occupants.size():
			if is_instance_valid(_occupants[i]):
				live.append(_occupants[i])
		if live.size() != _occupants.size():
			_occupants = live


## A campfire. Light now, cooking later.
##
## §20's early tutorial is shelter, bed, campfire, rest, and the campfire's job
## in that sequence is to make the shelter read as inhabited after dark. So the
## behaviour is the one thing a fire actually does on its own: it burns, it lights
## the ground around it, and it can go out.
##
## The flame is a node inside the piece's own art, named by the definition, and
## `set_lit()` shows or hides it along with the light. That is why this station
## is worth having at all rather than being a comment: an unlit campfire is
## visibly a cold ring of stones, and a lit one lights the room, and both states
## survive a reload.
##
## COOKING IS NOT HERE — M9 owns food, and a `cook()` on a fire with no recipes
## and no ingredients would be the empty-station pattern this file refuses.
class Hearth extends Station:

	signal lit_changed(is_lit: bool)

	## Metres. Tunable; it is set from the piece definition and nothing reads it
	## except the light below.
	var light_radius: float = 6.0

	var _lit: bool = true
	## The art's flame — the visible fire and its light, together, so one
	## visibility flag turns the whole thing on and off.
	var _flame: Node3D = null

	func _configured() -> void:
		light_radius = float(config.get("light_radius", 6.0))
		_flame = _find_flame(str(config.get("flame_node", "Flame")))
		_apply(bool(config.get("lit_on_place", true)))

	func is_lit() -> bool:
		return _lit

	func set_lit(value: bool) -> void:
		if value == _lit:
			return
		_apply(value)
		lit_changed.emit(_lit)

	func save_state() -> Dictionary:
		return {"lit": _lit}

	## A fire the player put out stays out across a reload. This is the whole
	## reason a record carries station state: the catalogue knows a campfire
	## starts lit, and only the save file knows this one is not.
	func load_state(state: Dictionary) -> void:
		set_lit(bool(state.get("lit", _lit)))

	## Nothing to undo on removal: the light is a child of the art and goes with
	## it. Left explicit so that a future hearth that DOES register something —
	## a cooking timer, a warmth volume — has an obvious place to unregister it.
	func _release() -> void:
		pass

	func _apply(value: bool) -> void:
		_lit = value
		if _flame != null and is_instance_valid(_flame):
			_flame.visible = _lit
			for light in _flame.find_children("*", "OmniLight3D", true, false):
				(light as OmniLight3D).omni_range = light_radius

	## Searched from the PIECE, not from this node: the station is a sibling of
	## the art, both children of the placed piece. `find_child` walks the node
	## tree rather than the scene tree, so this works before the piece is added
	## to a running world.
	func _find_flame(flame_name: String) -> Node3D:
		var piece := get_parent()
		if piece == null or flame_name.is_empty():
			return null
		return piece.find_child(flame_name, true, false) as Node3D
