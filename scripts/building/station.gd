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
## COSTS ARE NOT HERE, AND THIS WAS THE SEAM. `GAME_DESIGN.md` §20 has building
## consume Wood/Stone/Fiber, and this file used to record why nothing did: there
## was no inventory to spend from. There is one now. The cost sits on the piece
## definition in `pieces.json` beside `model` and `anchor`, and the check sits in
## `build_mode._check()` beside "too far away" and "ground is too uneven" —
## because a refusal the player must read is a placement refusal, not a station
## concern. Nothing about that arrived in this file, which is the point of having
## called the seam in advance.
##
## WHAT A STATION MAY SPEND IS DIFFERENT, and three of the stations below do it:
## a workbench spends materials to make a tool, a berry plot spends a berry to
## plant one. Those are the STATION'S OWN transaction rather than the price of
## putting it down, and each takes the inventory as an argument rather than going
## looking for one — so a station can be exercised with a bag built by a test and
## never has to know where the real one lives.


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
const BEHAVIOUR_WORKBENCH := "workbench"
const BEHAVIOUR_STORAGE := "storage"
const BEHAVIOUR_BERRY_PLOT := "berry_plot"

## The three above this line used to be a "still to come" list, deliberately not
## stubbed, because "an empty station that places and does nothing is worse than
## no station: it looks finished in a palette, passes every test, and is the
## 'written and never called' shape this project keeps getting bitten by." Each
## waited on something real, and each of those things now exists:
##
##   - `workbench`  — waited on crafting recipes. `data/recipes/crafting.json`.
##                    It also repairs, which §19 asks for and which needs no
##                    recipes at all.
##   - `storage`    — waited on the slot/stack inventory container.
##                    `scripts/items/inventory.gd`. A chest is a VIEW onto one of
##                    those, never a second kind of container.
##   - `berry_plot` — waited on plant/grow/harvest and a berry item to yield.
##                    `berries` is in items.json and the growth is below.
##
## The list is kept rather than deleted because the bar it set is the one any
## future station has to clear.

## The inventory a chest is made of, and the item table a recipe is priced in.
##
## `preload` at the top of the file rather than inside the classes: an inner
## class that preloads its own copy is a second reference to the same script, and
## the whole point of a chest holding an `inventory.gd` is that there is exactly
## one kind of container in this game.
const INVENTORY := preload("res://scripts/items/inventory.gd")

## Where the workbench's recipes come from. Data, not code, for the reason
## CLAUDE.md gives: what a thing costs will vary and must be rebalanceable
## without touching a line of this file.
const RECIPES_PATH := "res://data/recipes/crafting.json"


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
		BEHAVIOUR_WORKBENCH:
			station = Workbench.new()
		BEHAVIOUR_STORAGE:
			station = Storage.new()
		BEHAVIOUR_BERRY_PLOT:
			station = BerryPlot.new()
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


## A workbench. Where tools are made and where they are mended.
##
## §19 gives it two jobs and this class does both:
##
##   1. REPAIR, and it is FREE. "Tools have durability; repair for free at
##      appropriate station." The station is a PLACE, not a price, so `repair()`
##      takes no cost argument and does no partial restore — `item_stack.repair()`
##      already knows what repairing means and this only decides where it may
##      happen.
##   2. CRAFT, from `data/recipes/crafting.json`. Five recipes, all of them a
##      tool, all of them priced in Wood/Stone/Fiber.
##
## THE RULE THIS CLASS WAS NEARLY THE BREACH OF: "Do not ship a workbench that
## places and does nothing." A bench with no recipes is a decoration with extra
## steps, and it would have been very easy to put one down and call the milestone
## finished. So there are recipes, and there is a repair, and both are exercised
## by `tests/test_build_costs.gd`.
##
## PALS DO NOT WORK HERE. There is no `assign`, no `staff`, no worker slot and no
## throughput. `craft()` is the TRAINER'S verb: it takes an inventory and spends
## from it, it happens instantly, and there is nothing for a creature to be put
## into. `GAME_DESIGN.md` §20: "Pals do not work jobs."
class Workbench extends Station:

	signal crafted(recipe_id: String, item_id: String, count: int)
	signal repaired(slot: int)

	## Refusal tokens, not sentences. `party.gd`'s idiom.
	const REFUSED_NO_RECIPE := "no_such_recipe"
	const REFUSED_WRONG_STATION := "wrong_station"
	const REFUSED_NO_INVENTORY := "no_inventory"
	const REFUSED_NOT_ENOUGH := "not_enough"
	const REFUSED_NO_ROOM := "no_room"
	const REFUSED_NOTHING_TO_MEND := "nothing_to_mend"

	static var _recipe_table: Dictionary = {}

	var _refusal: String = ""

	func last_refusal() -> String:
		return _refusal

	## Every recipe this bench can make, as `{recipe_id: recipe}`.
	##
	## Filtered by the recipe's own `station` key against this piece's id, so a
	## later forge or cooking fire is a data entry rather than a code change, and
	## so a recipe that names a station nobody built simply does not appear.
	func recipes() -> Dictionary:
		var out: Dictionary = {}
		for id: String in recipe_table().keys():
			var recipe: Dictionary = recipe_table()[id]
			if str(recipe.get("station", "")) == piece_id:
				out[id] = recipe
		return out

	func recipe(recipe_id: String) -> Dictionary:
		var entry: Variant = recipes().get(recipe_id, {})
		return entry if entry is Dictionary else {}

	## What a recipe costs, as `{item_id: count}`.
	func costs(recipe_id: String) -> Dictionary:
		var entry: Variant = recipe(recipe_id).get("costs", {})
		var out: Dictionary = {}
		if entry is Dictionary:
			for item: String in (entry as Dictionary).keys():
				out[item] = int((entry as Dictionary)[item])
		return out

	## What is missing before `purse` could pay, as `{item_id: shortfall}`. Empty
	## means it can. Separate from `can_craft()` because a palette wants to draw
	## "3 more Wood", not "no".
	func shortfall(purse: Object, recipe_id: String) -> Dictionary:
		var out: Dictionary = {}
		if purse == null or not purse.has_method("count_of"):
			return out
		for item: String in costs(recipe_id).keys():
			var short: int = int(costs(recipe_id)[item]) - int(purse.call("count_of", item))
			if short > 0:
				out[item] = short
		return out

	func can_craft(purse: Object, recipe_id: String) -> bool:
		_refusal = ""
		if recipe(recipe_id).is_empty():
			_refusal = REFUSED_NO_RECIPE if not recipe_table().has(recipe_id) else REFUSED_WRONG_STATION
			return false
		if purse == null or not purse.has_method("count_of"):
			_refusal = REFUSED_NO_INVENTORY
			return false
		if not shortfall(purse, recipe_id).is_empty():
			_refusal = REFUSED_NOT_ENOUGH
			return false
		return true

	## Make one. ALL OR NOTHING, the same discipline `inventory.add()` keeps: the
	## materials are only spent once the output is known to fit, so a full bag
	## cannot eat the wood and hand back nothing.
	func craft(purse: Object, recipe_id: String) -> bool:
		if not can_craft(purse, recipe_id):
			return false
		var made := str(recipe(recipe_id).get("makes", ""))
		var count := maxi(1, int(recipe(recipe_id).get("count", 1)))
		if not bool(purse.call("add", made, count)):
			_refusal = REFUSED_NO_ROOM
			return false
		for item: String in costs(recipe_id).keys():
			if not bool(purse.call("remove", item, int(costs(recipe_id)[item]))):
				# Cannot happen after the shortfall check, and is handled anyway:
				# taking the tool back is cheaper than shipping a duplication bug.
				purse.call("remove", made, count)
				_refusal = REFUSED_NOT_ENOUGH
				return false
		crafted.emit(recipe_id, made, count)
		return true

	## Free repair, §19. `bag` is the `inventory.gd` instance, because a slot index
	## is meaningless to anything else.
	func repair(bag: Object, slot: int) -> bool:
		_refusal = ""
		if bag == null or not bag.has_method("repair"):
			_refusal = REFUSED_NO_INVENTORY
			return false
		if not bool(bag.call("repair", slot)):
			_refusal = str(bag.call("last_refusal"))
			return false
		repaired.emit(slot)
		return true

	## Mend everything worn in one go. Returns how many tools were mended.
	##
	## Because free repair with a per-slot click is a chore that teaches nothing:
	## the interesting decision is whether to walk back to the bench, and that
	## decision is already made by the time the player is standing at it.
	func repair_all(bag: Object) -> int:
		_refusal = ""
		if bag == null or not bag.has_method("slots"):
			_refusal = REFUSED_NO_INVENTORY
			return 0
		var mended := 0
		var slots: Array = bag.call("slots")
		for i in slots.size():
			var stack: Variant = slots[i]
			if stack == null:
				continue
			var held: RefCounted = stack
			if not bool(held.call("is_durable")):
				continue
			if int(held.get("durability")) >= int(held.call("max_durability")):
				continue
			if bool(bag.call("repair", i)):
				mended += 1
				repaired.emit(i)
		if mended == 0:
			_refusal = REFUSED_NOTHING_TO_MEND
		return mended

	## A bench holds no state of its own: what it can make is in the catalogue and
	## what it has made is in the player's bag. `save_state()` is left at the
	## Station default deliberately, so a reloaded bench is byte-for-byte a fresh
	## one — which is exactly right and is why there is no override here.

	## Memoised on the script, like `item_defs.table()`, so five recipes are
	## parsed once however many benches the player builds.
	static func recipe_table() -> Dictionary:
		if not _recipe_table.is_empty():
			return _recipe_table
		var file := FileAccess.open(RECIPES_PATH, FileAccess.READ)
		if file == null:
			push_error("recipes missing at %s" % RECIPES_PATH)
			return {}
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not parsed is Dictionary:
			push_error("recipes are not readable: %s" % RECIPES_PATH)
			return {}
		var out: Dictionary = {}
		var entries: Variant = (parsed as Dictionary).get("recipes", {})
		if entries is Dictionary:
			for id: String in (entries as Dictionary).keys():
				if not id.begins_with("_"):
					out[id] = (entries as Dictionary)[id]
		_recipe_table = out
		return _recipe_table


## A chest. Somewhere to put things down.
##
## §20 lists "storage" among what a base is for, and this is that and nothing
## more: a second `inventory.gd` with its own slot count, sitting in the world.
##
## IT CANNOT HOLD A CREATURE, AND THAT IS STRUCTURAL RATHER THAN MISSING.
## CLAUDE.md: "Player can own only five pals total. Never implement pal storage
## beyond five." A chest is the single most obvious place that rule dies, so:
##
##   1. THE ONLY WAY IN IS `put(item_id: String, count: int)`. There is no
##      overload that takes an Object, a Node, a pal instance or a record. A
##      `String` is not a creature and cannot be made into one.
##   2. That String goes straight to `inventory.add()`, which REFUSES any id that
##      is not in `data/items/items.json` — `REFUSED_UNKNOWN_ITEM`. Nothing else
##      can put a stack in.
##   3. `items.json` contains no creature and, by its own header, may not: "Items
##      never name a creature... an item that could hold a pal id is the first
##      half of a pal box." `tests/test_build_costs.gd` asserts the item table and
##      the species table are disjoint, so adding a `pal_bruno` item is a red
##      build.
##   4. This class has no `store`, `deposit`, `withdraw` or `release` verb that
##      takes anything but an item id, and the same test asserts that too.
##
## So a pal cannot get in through a wrong argument, a stale id, a save file or a
## data edit. It would take a new method, and that method would fail the tests
## that exist to stop somebody writing it.
class Storage extends Station:

	signal changed()
	## The contents at the moment the chest is destroyed, so they are ANNOUNCED
	## rather than silently deleted. Whoever owns death satchels (§22) can catch
	## this; `build_mode` refuses to remove a chest that still has something in it,
	## which is the cheaper half of the same problem.
	signal emptied(records: Array)

	const REFUSED_NO_ROOM := "no_room"
	const REFUSED_NOT_HELD := "not_held"

	## Slots in the chest. TUNABLE, and it lives in the piece's station block in
	## `pieces.json` rather than here.
	var capacity: int = 12

	var _items: RefCounted = null
	var _refusal: String = ""

	func _configured() -> void:
		capacity = maxi(1, int(config.get("capacity", 12)))
		_items = INVENTORY.new(capacity)

	## The chest's inventory itself, so a UI can drive it with the same code it
	## drives the trainer's with. A chest is a VIEW onto an inventory, never a
	## second kind of container — which is the whole reason `inventory.gd` has a
	## `slots` argument.
	func contents() -> RefCounted:
		return _items

	func slot_count() -> int:
		return 0 if _items == null else int(_items.call("slot_count"))

	func is_empty() -> bool:
		return _items == null or bool(_items.call("is_empty"))

	func count_of(item_id: String) -> int:
		return 0 if _items == null else int(_items.call("count_of", item_id))

	func last_refusal() -> String:
		return _refusal

	## Put items in. `item_id` is a String and there is no other way in — see the
	## numbered note above this class.
	func put(item_id: String, count: int = 1) -> bool:
		_refusal = ""
		if _items == null:
			_refusal = REFUSED_NO_ROOM
			return false
		if not bool(_items.call("add", item_id, count)):
			_refusal = str(_items.call("last_refusal"))
			return false
		changed.emit()
		return true

	## Take items out.
	func take(item_id: String, count: int = 1) -> bool:
		_refusal = ""
		if _items == null:
			_refusal = REFUSED_NOT_HELD
			return false
		if not bool(_items.call("remove", item_id, count)):
			_refusal = str(_items.call("last_refusal"))
			return false
		changed.emit()
		return true

	## Move a stack across from a bag, keeping its durability — the path a
	## 40%-worn axe has to travel to end up in a chest still 40% worn.
	func stow(stack: RefCounted) -> bool:
		_refusal = ""
		if _items == null or stack == null:
			_refusal = REFUSED_NO_ROOM
			return false
		if not bool(_items.call("place", stack)):
			_refusal = str(_items.call("last_refusal"))
			return false
		changed.emit()
		return true

	func save_state() -> Dictionary:
		if _items == null:
			return {}
		var records: Array = _items.call("to_records")
		return {} if records.is_empty() else {"items": records}

	func load_state(state: Dictionary) -> void:
		var records: Variant = state.get("items", [])
		if not records is Array:
			return
		_items = INVENTORY.from_records(records as Array, capacity)
		changed.emit()

	func _release() -> void:
		if _items == null:
			return
		var records: Array = _items.call("to_records")
		if not records.is_empty():
			push_warning("a storage station was removed holding %d stack(s)" % records.size())
			emptied.emit(records)


## A berry plot. §21: "Plant → wait → harvest. No watering chores."
##
## Three states and no more: nothing planted, growing, ripe. There is no water
## meter, no fertiliser, no soil quality and no season — §21 says so in as many
## words, and every one of those is a chore looking for a system to live in.
##
## IT KEEPS GROWING AFTER A HARVEST. Picking it returns the plot to GROWING
## rather than to EMPTY, so a plot is planted once and then visited. Replanting
## after every pick is precisely the watering chore §21 rules out, and a standing
## supply of berries is what makes the plot worth its build cost when the meadow
## already has 195 wild berry bushes in it.
##
## GROWTH IS WALL-CLOCK-FREE. It advances while the game is running and not while
## it is closed, because the alternative — crediting real elapsed time on load —
## is a system that has to be right about clock changes, and a player who comes
## back to a ripe plot they did not watch grow has learnt nothing about the
## timer. The half-grown state itself DOES survive a reload, which is the part
## that matters: `save_state()` writes the seconds.
##
## NO PAL TENDS IT. There is no assignment, no worker and no speed-up for having
## a creature nearby. CLAUDE.md: "Pals do not perform base jobs."
class BerryPlot extends Station:

	signal planted()
	signal ripened()
	signal picked(item_id: String, count: int)

	const STATE_EMPTY := "empty"
	const STATE_GROWING := "growing"
	const STATE_RIPE := "ripe"

	const REFUSED_ALREADY_PLANTED := "already_planted"
	const REFUSED_NOTHING_PLANTED := "nothing_planted"
	const REFUSED_NOT_RIPE := "not_ripe"
	const REFUSED_NO_INVENTORY := "no_inventory"
	const REFUSED_NO_SEED := "no_seed"
	const REFUSED_NO_ROOM := "no_room"

	## ALL TUNABLE, all from the piece's station block in `pieces.json`.
	var seed_item: String = "berries"
	var seed_count: int = 1
	var crop_item: String = "berries"
	var crop_count: int = 6
	var grow_seconds: float = 240.0
	## Fraction of the growth after which the plot stops looking like sprouts and
	## starts looking like bushes.
	var sprout_until: float = 0.4

	var _state: String = STATE_EMPTY
	var _grown: float = 0.0
	var _refusal: String = ""

	var _seedling: Node3D = null
	var _growing: Node3D = null
	var _ripe: Node3D = null

	func _configured() -> void:
		seed_item = str(config.get("seed_item", seed_item))
		seed_count = maxi(0, int(config.get("seed_count", seed_count)))
		crop_item = str(config.get("crop_item", crop_item))
		crop_count = maxi(1, int(config.get("crop_count", crop_count)))
		grow_seconds = maxf(1.0, float(config.get("grow_seconds", grow_seconds)))
		sprout_until = clampf(float(config.get("sprout_until", sprout_until)), 0.0, 1.0)
		_seedling = _stage(str(config.get("seedling_node", "Seedling")))
		_growing = _stage(str(config.get("growing_node", "Growing")))
		_ripe = _stage(str(config.get("ripe_node", "Ripe")))
		_show()

	func state() -> String:
		return _state

	func is_ripe() -> bool:
		return _state == STATE_RIPE

	func is_planted() -> bool:
		return _state != STATE_EMPTY

	## 0.0 to 1.0. What a progress ring draws, and what makes "half-grown" a thing
	## anybody can check.
	func growth() -> float:
		if _state == STATE_RIPE:
			return 1.0
		if _state == STATE_EMPTY:
			return 0.0
		return clampf(_grown / grow_seconds, 0.0, 1.0)

	func seconds_left() -> float:
		return 0.0 if _state != STATE_GROWING else maxf(0.0, grow_seconds - _grown)

	func last_refusal() -> String:
		return _refusal

	## Plant it. `purse` pays the seed — an inventory, or anything answering
	## `count_of`/`remove`. A plot whose `seed_count` is zero can be planted with
	## no purse at all, which is the seam a tutorial or a gift would use.
	func plant(purse: Object = null) -> bool:
		_refusal = ""
		if _state != STATE_EMPTY:
			_refusal = REFUSED_ALREADY_PLANTED
			return false
		if seed_count > 0:
			if purse == null or not purse.has_method("remove"):
				_refusal = REFUSED_NO_INVENTORY
				return false
			if int(purse.call("count_of", seed_item)) < seed_count:
				_refusal = REFUSED_NO_SEED
				return false
			if not bool(purse.call("remove", seed_item, seed_count)):
				_refusal = REFUSED_NO_SEED
				return false
		_state = STATE_GROWING
		_grown = 0.0
		_show()
		planted.emit()
		return true

	## Pick it. Returns the plot to GROWING, not to EMPTY — see the class note.
	func pick(purse: Object) -> bool:
		_refusal = ""
		if _state == STATE_EMPTY:
			_refusal = REFUSED_NOTHING_PLANTED
			return false
		if _state != STATE_RIPE:
			_refusal = REFUSED_NOT_RIPE
			return false
		if purse == null or not purse.has_method("add"):
			_refusal = REFUSED_NO_INVENTORY
			return false
		if not bool(purse.call("add", crop_item, crop_count)):
			# Refused BEFORE the crop is cleared, so a full bag costs the player a
			# walk rather than the harvest.
			_refusal = REFUSED_NO_ROOM
			return false
		_state = STATE_GROWING
		_grown = 0.0
		_show()
		picked.emit(crop_item, crop_count)
		return true

	## Dig it up. The only way back to EMPTY, and it returns nothing: the seed is
	## in the ground.
	func clear_plot() -> bool:
		_refusal = ""
		if _state == STATE_EMPTY:
			_refusal = REFUSED_NOTHING_PLANTED
			return false
		_state = STATE_EMPTY
		_grown = 0.0
		_show()
		return true

	func _process(delta: float) -> void:
		tick(delta)

	## Advance the crop. Split out from `_process` so a test can grow four minutes
	## in one call without a tree or a clock — `save_director.tick()` keeps the
	## same seam for the same reason.
	func tick(delta: float) -> void:
		if _state != STATE_GROWING or delta <= 0.0:
			return
		var was := growth()
		_grown += delta
		if _grown >= grow_seconds:
			_state = STATE_RIPE
			_show()
			ripened.emit()
			return
		# Only when the plot crosses from sprouts to bushes, rather than every
		# frame: `_show()` walks three nodes and this runs on every plot the player
		# has built.
		if was < sprout_until and growth() >= sprout_until:
			_show()

	## Exactly one stage visible, the same way the campfire's `Flame` is one
	## visibility flag. This is what makes a half-grown plot LOOK half-grown,
	## including after a reload.
	func _show() -> void:
		var stage := STATE_EMPTY if _state == STATE_EMPTY else _state
		_visible(_seedling, stage == STATE_GROWING and growth() < sprout_until)
		_visible(_growing, stage == STATE_GROWING and growth() >= sprout_until)
		_visible(_ripe, stage == STATE_RIPE)

	func _visible(node: Node3D, value: bool) -> void:
		if node != null and is_instance_valid(node):
			node.visible = value

	## Searched from the PIECE, not from this node: the station is a sibling of the
	## art, both children of the placed piece. Same as `Hearth._find_flame`, and
	## `find_child` walks the node tree rather than the scene tree, so it works
	## before the piece is added to a running world.
	func _stage(stage_name: String) -> Node3D:
		var piece := get_parent()
		if piece == null or stage_name.is_empty():
			return null
		return piece.find_child(stage_name, true, false) as Node3D

	## A HALF-GROWN PLOT COMES BACK HALF-GROWN. This is the whole reason a record
	## carries station state: the catalogue knows a plot is empty, and only the
	## save file knows this one is three minutes into a four-minute crop.
	func save_state() -> Dictionary:
		if _state == STATE_EMPTY:
			return {}
		return {"crop": _state, "grown": snappedf(_grown, 0.1)}

	func load_state(state: Dictionary) -> void:
		var crop := str(state.get("crop", STATE_EMPTY))
		if not [STATE_EMPTY, STATE_GROWING, STATE_RIPE].has(crop):
			crop = STATE_EMPTY
		_state = crop
		_grown = clampf(float(state.get("grown", 0.0)), 0.0, grow_seconds)
		if _state == STATE_RIPE:
			_grown = grow_seconds
		_show()
