extends Node3D

## Everything the player has built.
##
## Owns the placed pieces, their nodes, their colliders and their save file.
## Nothing else creates or destroys a structure.
##
## DELIBERATELY NOT MULTIMESH, which is how the scatter draws its eighteen
## thousand props next door. Four reasons, each fatal on its own:
##
##   1. Removal. `MultiMesh` is a flat transform array; deleting instance *i*
##      means rewriting every transform after it. `vegetation.build()` handles
##      change by freeing every child and rebuilding — fine for a scatter that
##      changes never, absurd for a wall the player is deleting by hand.
##   2. Colliders. The scatter's shape is a CYLINDER approximation, sized "tall
##      enough to stop a camera at head height" — right for a tree trunk and
##      wrong for a 2x3x0.4m wall you must not walk through or a floor you must
##      stand on.
##   3. Identity. A MultiMesh instance is an index. It cannot be raycast-picked,
##      highlighted, or made the parent of a door's AnimationPlayer.
##   4. `vegetation._mesh_for()` keeps only the FIRST mesh in a model and warns
##      about the rest. 136 of the kit's 176 models carry a second wood-trim
##      surface, so routing walls through it would silently strip their trim.
##
## A village is a few hundred draw calls. The meadow beside it is several
## thousand instances. If it ever does bite, the right move is freezing a
## FINISHED building into one baked mesh — not starting there and losing the
## ability to delete a wall.
##
## Reason 3 above — identity — is also what lets a piece DO something. A piece
## whose definition carries a `station` block gets a behaviour node attached here
## when it is placed, saved with its placement, rebuilt on load, and released
## before it is destroyed. See `scripts/building/station.gd`. Everything else
## about such a piece is ordinary, which is the point: a bed is a wall that
## answers questions, not a special case with its own placement rules.

const CATALOGUE_PATH := "res://data/building/pieces.json"
const GRID := preload("res://scripts/building/build_grid.gd")
const STATION := preload("res://scripts/building/station.gd")

## This file used to own `user://structures.json` outright — its own path, its
## own version constant, its own refusal logic. It is now one CONTRIBUTOR to the
## single envelope `SaveManager` writes, under this key. See
## `autoload/save_manager.gd` for why there is only one file.
const SAVE_DOMAIN := "structures"

## Everything writes to slot 0 until there is a slot-picking screen to write
## anything else. Tunable; not a design decision.
const SAVE_SLOT := 0

## A piece with behaviour has just been built, or is about to be destroyed.
##
## Emitted rather than polled so that a system which cares about beds — pal
## recovery, respawn — can react to one appearing instead of rescanning the
## whole village every frame. `station_removing` fires while the station is
## still valid and before anything is freed, which is the only moment a listener
## can safely let go of it.
signal station_placed(station: Node)
signal station_removing(station: Node)

## Placed pieces, in placement order. Each is the serialisable record, its live
## node and its station (or null) together, so saving never has to walk the
## scene tree and read transforms back out of it.
var _placed: Array[Dictionary] = []

## How many pieces the last `load_data()` rebuilt. `load_saved()` reports it,
## because SaveManager hands state out and does not count what came back.
var _last_loaded: int = 0

## The piece id `remove_nearest()` last took out. Read by build mode to refund it.
var _last_removed: String = ""

var _catalogue: Dictionary = {}
## One material per source material name, shared across every piece that uses
## it — the same trick `vegetation._tints` uses, so two hundred walls hold two
## materials rather than four hundred.
var _materials: Dictionary = {}


func _ready() -> void:
	_ensure_catalogue()
	_register()


## Every piece the palette can offer, as `{id: definition}`.
func catalogue() -> Dictionary:
	_ensure_catalogue()
	return _catalogue


func definition(piece_id: String) -> Dictionary:
	_ensure_catalogue()
	return _catalogue.get(piece_id, {})


## Where a piece hangs relative to the point it was snapped to, in its OWN frame.
##
## Zero for the thirty pieces that sit on their own origin. Non-zero for the two
## door leaves, whose origin is the hinge edge of the leaf rather than the middle
## of the doorway — see `_comment_opening` in `pieces.json` for the measurement.
## Static and taking a definition, so build mode can offset its ghost by the same
## number without owning a structures node.
static func hang_offset(piece: Dictionary) -> Vector3:
	var entry: Variant = piece.get("hangs", null)
	if not entry is Array or (entry as Array).size() < 3:
		return Vector3.ZERO
	var values: Array = entry
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


## Does this piece hang IN an opening rather than beside one? True for a door
## leaf. Used so a leaf and the doorway it belongs in may share a grid slot.
static func hangs_in_an_opening(piece: Dictionary) -> bool:
	return piece.has("hangs")


## Does this piece HAVE an opening a leaf can hang in? True for the two doorway
## walls and the two door frames.
static func is_an_opening(piece: Dictionary) -> bool:
	return bool(piece.get("opening", false))


## What a piece costs, as `{item_id: count}`.
##
## Read from the catalogue and COPIED, never handed out live: a palette that got
## the real dictionary could edit the price of a wall by accident, and building
## would quietly become free.
##
## Note what this function does NOT do: it does not spend anything and it does
## not refuse anything. `place()` is the one door a fresh placement and a load
## from disk both go through, and charging in here would charge for every piece
## in the save file every time the game boots. The spending lives in
## `build_mode`, with the refusal the player reads.
func cost_of(piece_id: String) -> Dictionary:
	var entry: Variant = definition(piece_id).get("cost", {})
	var out: Dictionary = {}
	if entry is Dictionary:
		for item: String in (entry as Dictionary).keys():
			var count := int((entry as Dictionary)[item])
			if count > 0:
				out[item] = count
	return out


## Read the catalogue if it has not been read, rather than only in `_ready()`.
##
## `_ready()` never runs for a structures node that has not been handed to a
## running tree, and there are two such callers already: `tools/preview_build.gd`
## builds one to photograph, and a test builds one to place into. Both would
## otherwise get "no build piece called ..." for every id in the file — an empty
## catalogue that reads as a missing data file.
func _ensure_catalogue() -> void:
	if _catalogue.is_empty():
		_catalogue = _load_catalogue()


## Build one piece and keep it. Returns the node, or null if the id is unknown.
##
## `position` and `yaw` are taken as given — deciding WHERE a piece goes is
## `build_mode`'s job and validating it is `build_mode`'s job. This function
## places what it is told to, so that a load from disk and a fresh placement go
## down exactly the same path. A loader with its own placement code is a loader
## that drifts.
##
## `station_state` is what a previously-saved station said about itself, and is
## empty for a fresh placement — the same argument the loader passes back in, so
## that a reloaded campfire and a newly-lit one are built by one function.
func place(
	piece_id: String,
	position: Vector3,
	yaw: float,
	storey: int = 0,
	station_state: Dictionary = {},
	fixed: bool = false
) -> Node3D:
	var piece := definition(piece_id)
	if piece.is_empty():
		push_error("no build piece called '%s'" % piece_id)
		return null

	var model_path := str(piece.get("model", ""))
	if not ResourceLoader.exists(model_path):
		push_error("build piece '%s' names a model at %s that does not exist" % [piece_id, model_path])
		return null

	var node := Node3D.new()
	node.name = "%s_%d" % [piece_id, _placed.size()]
	add_child(node)
	# `global_position` requires the node to be inside the scene tree and returns
	# a silent (0,0,0) when it is not, so a structures node built outside a
	# running world — a preview tool, a test — would stack every piece on the
	# origin. `position` is the same coordinate whenever this node is itself at
	# the origin, which is how the scene ships and how every such caller builds
	# one.
	# WHERE THE PIECE ACTUALLY GOES is not always where it was snapped to.
	#
	# A door leaf's origin is its HINGE, not its centre, and the doorway it hangs
	# in is snapped to the middle of a cell edge. Placing the leaf at that point
	# hangs it half a leaf-width to one side, over the pier, which is precisely
	# the "half offset" the owner reported on the pre-built houses. `hangs` is
	# that correction, measured, in the piece's OWN frame — so it turns with the
	# piece and is right on all four edges of a cell.
	#
	# The RECORD keeps the snapped point, not this one. The grid coordinate is
	# what `occupied()` compares and what a save file should carry, and applying
	# the offset here rather than there means a reload runs it exactly once.
	var world_at := position + Basis(Vector3.UP, yaw) * hang_offset(piece)
	if is_inside_tree():
		node.global_position = world_at
	else:
		node.position = world_at
	node.rotation.y = yaw

	# The whole imported scene, not one extracted mesh: the kit's pieces are
	# multi-surface and an extracted first-mesh loses the trim.
	var art: Node3D = (load(model_path) as PackedScene).instantiate() as Node3D
	if art != null:
		node.add_child(art)
		_share_materials(art)

	node.add_child(_body(piece))

	# The behaviour hook. Attached AFTER the art, because a station may need to
	# find a node inside it — the campfire's flame is named by the definition and
	# located in the model.
	var station: Node = STATION.create(piece)
	if station != null:
		node.add_child(station)
		# The station is told where the piece REALLY is and which way it faces.
		# A door cannot decide which way to swing without the second: "away from
		# the player" is a question in the piece's own local frame.
		station.call("setup", piece_id, STATION.config_of(piece), world_at, yaw)
		if not station_state.is_empty():
			station.call("load_state", station_state)

	var record := {
		"piece": piece_id,
		"x": position.x,
		"y": position.y,
		"z": position.z,
		"yaw_deg": rad_to_deg(yaw),
		"storey": storey,
	}
	_placed.append({"record": record, "node": node, "station": station, "fixed": fixed})
	if station != null:
		station_placed.emit(station)
	return node


## A piece the WORLD owns rather than the player.
##
## Identical to `place()` in every way that reaches the screen — same grid, same
## art, same measured collider, same station — and different in exactly three
## ways that reach the save file and the build tool: it is not in `records()`, it
## is not counted by `count()`, and `remove_nearest()` will not take it down.
##
## The one thing that needs this is the door hung in a pre-built cottage. The
## settlement is content, drawn by the scatter next door from
## `data/config/settlement.json`; a door in it has to be a real node with a real
## station or it cannot open, but it must not turn up in the player's save as
## something they built and can demolish for a refund of materials they never
## paid. `clear()` leaves these standing for the same reason: a load wipes what
## the player put up, and Grandpa's front door is not that.
func place_fixed(
	piece_id: String, position: Vector3, yaw: float, storey: int = 0
) -> Node3D:
	return place(piece_id, position, yaw, storey, {}, true)


## Remove the piece nearest a point, within `radius`. Returns true if one went.
##
## Distance is measured against the RECORD, not against the node's
## `global_position`. The record is where the piece was told to go, it is exact,
## and `occupied()` two functions down already compares records for the same
## reason — asking the node instead means asking the physics/transform state,
## which is empty for a node not inside a running tree.
func remove_nearest(point: Vector3, radius: float) -> bool:
	var best := nearest_index(point, radius)
	if best < 0:
		_last_removed = ""
		return false
	_last_removed = str((_placed[best]["record"] as Dictionary).get("piece", ""))
	_demolish(_placed[best])
	_placed.remove_at(best)
	return true


## Which placed piece is nearest a point, as an index, or -1.
##
## Split out of `remove_nearest` so that build mode can ask WHAT it is about to
## delete before deleting it — a chest with something in it is refused, and a
## refund has to know what it is refunding.
func nearest_index(point: Vector3, radius: float) -> int:
	var best := -1
	var best_distance := radius
	for i in _placed.size():
		# A world-owned piece is not the player's to find here. `nearest_index` is
		# what removal and refunds run through, and the build tool must not be able
		# to demolish a pre-built cottage's door for materials nobody paid.
		if bool(_placed[i].get("fixed", false)):
			continue
		var distance := _position_of(_placed[i]["record"]).distance_to(point)
		if distance <= best_distance:
			best_distance = distance
			best = i
	return best


## The piece id of the nearest placement, or "" if there is none in range.
func nearest_piece(point: Vector3, radius: float) -> String:
	var at := nearest_index(point, radius)
	return "" if at < 0 else str((_placed[at]["record"] as Dictionary).get("piece", ""))


## The station on the nearest placement, or null. What build mode asks before it
## deletes something that might be holding the player's belongings.
func nearest_placed_station(point: Vector3, radius: float) -> Node:
	var at := nearest_index(point, radius)
	if at < 0:
		return null
	var station: Node = _placed[at].get("station")
	return station if station != null and is_instance_valid(station) else null


## What `remove_nearest` last took out, so a refund knows what it is refunding.
## Empty after a removal that found nothing.
func last_removed() -> String:
	return _last_removed


## Take one placed entry out of the world, station and all.
##
## The station is released BEFORE the node is freed, while it is still valid: a
## pal asleep in a bed the player has just deleted has to be woken by the bed, or
## it is left holding a reference to a freed node, which is a crash waiting for
## the next time anything asks it where it is sleeping.
func _demolish(entry: Dictionary) -> void:
	var station: Node = entry.get("station")
	if station != null and is_instance_valid(station):
		station_removing.emit(station)
		station.call("release")
	var node: Node3D = entry["node"]
	if is_instance_valid(node):
		node.queue_free()


func _position_of(record: Dictionary) -> Vector3:
	return Vector3(float(record["x"]), float(record["y"]), float(record["z"]))


## Is anything already occupying this spot? Used to refuse a placement that
## would sit inside an existing piece.
##
## Compared by SNAPPED position rather than by collider overlap: two pieces on
## the same grid slot always land on exactly the same coordinates, so an exact
## comparison is both cheaper and more honest than a physics query that would
## also trip on a roof legitimately overhanging a wall.
## A DOOR AND ITS DOORWAY ARE THE ONE PAIR ALLOWED TO SHARE A SLOT, which is why
## this takes the piece id at all. They are two models of one thing — the kit
## splits every doorway into the wall with the hole and the leaf that hangs in it
## — and they snap to the same edge of the same cell by construction. Without
## this exception the player can place a doorway and is then told "something is
## already there" when they try to hang a door in it, which makes the two door
## pieces in the palette unusable together and is not a rule anybody chose.
func occupied(position: Vector3, yaw: float, piece_id: String = "") -> bool:
	var incoming := definition(piece_id)
	for entry: Dictionary in _placed:
		var record: Dictionary = entry["record"]
		if absf(record["x"] - position.x) < 0.05 \
				and absf(record["y"] - position.y) < 0.05 \
				and absf(record["z"] - position.z) < 0.05 \
				and absf(angle_difference(deg_to_rad(record["yaw_deg"]), yaw)) < 0.05:
			var sitting := definition(str(record.get("piece", "")))
			if hangs_in_an_opening(incoming) and is_an_opening(sitting):
				continue
			if is_an_opening(incoming) and hangs_in_an_opening(sitting):
				continue
			return true
	return false


## How many pieces the PLAYER has built. World-owned pieces are excluded: they
## are content, they are not in the save file, and `clear()` does not take them
## down, so counting them here would mean `clear()` visibly failed to clear.
func count() -> int:
	var total := 0
	for entry: Dictionary in _placed:
		if not bool(entry.get("fixed", false)):
			total += 1
	return total


## Placement records only, for tests and for the save file.
##
## A station's state is merged in HERE rather than kept up to date in the record
## as it changes. The record is the placement — where and which — and it is
## written once; the station's state moves while the player plays, and reading it
## at the moment of saving is the only way it cannot be stale.
func records() -> Array:
	var out: Array = []
	for entry: Dictionary in _placed:
		if bool(entry.get("fixed", false)):
			continue
		out.append(STATION.write_record(entry["record"] as Dictionary, entry.get("station")))
	return out


## --- stations -------------------------------------------------------------
##
## The world's answer to "where can a pal sleep" and "which campfire is that".
## Queried rather than registered elsewhere: `structures.gd` already owns every
## placed piece and their lifetimes, and a second list of beds somewhere else is
## a second list that can disagree with this one about which beds exist.


## Every placed station, optionally only those of one behaviour.
func stations(behaviour: String = "") -> Array:
	var out: Array = []
	for entry: Dictionary in _placed:
		var station: Node = entry.get("station")
		if station == null or not is_instance_valid(station):
			continue
		if behaviour.is_empty() or str(station.get("behaviour")) == behaviour:
			out.append(station)
	return out


## The station on a placed piece, or null if that piece is only geometry.
func station_of(piece_node: Node) -> Node:
	return STATION.of(piece_node)


## The nearest station to a point, within `radius`. Null if there is none.
##
## This is how "is a pal resting here" gets asked: find the nearest pal bed to
## where the pal is standing, then ask the bed.
func nearest_station(point: Vector3, radius: float, behaviour: String = "") -> Node:
	var best: Node = null
	var best_distance := radius
	for station: Node in stations(behaviour):
		var distance: float = float(station.call("distance_to", point))
		if distance <= best_distance:
			best_distance = distance
			best = station
	return best


## --- the `structures` save domain -----------------------------------------
##
## Write to `user://`, never `res://`. That is SaveManager's rule now, but the
## reason was found here and is worth keeping where it was learnt: the obvious
## place to put placed pieces is `data/config/vegetation.json`, beside the
## authored landmarks whose record shape they resemble. That file is read-only
## content, memoised in a `static var` by `scatter_rules.config()`, so a runtime
## write would not even be seen by the process that made it.


## What goes under the `structures` key of the save envelope.
func save_data() -> Dictionary:
	return {"pieces": records()}


## Rebuild from a saved envelope.
##
## Everything goes through `place()`, so a loaded wall is constructed by the same
## code as a placed one and cannot end up subtly different from it.
func load_data(data: Dictionary) -> void:
	clear()
	_last_loaded = 0
	for entry: Variant in data.get("pieces", []):
		var record: Dictionary = entry
		var node := place(
			str(record.get("piece", "")),
			Vector3(float(record.get("x", 0.0)), float(record.get("y", 0.0)), float(record.get("z", 0.0))),
			deg_to_rad(float(record.get("yaw_deg", 0.0))),
			int(record.get("storey", 0)),
			STATION.read_record(record)
		)
		if node != null:
			_last_loaded += 1


## Save the whole game, of which structures are one part.
##
## Kept because build mode and the smoke test say "save the buildings" and that
## should stay the sentence they can write. It is no longer a private file.
func save() -> bool:
	var manager := _save_manager()
	if manager == null:
		return false
	return bool(manager.call("save", SAVE_SLOT))


## Load the whole game. Returns how many pieces came back.
func load_saved() -> int:
	_last_loaded = 0
	var manager := _save_manager()
	if manager == null:
		return 0
	if not bool(manager.call("load_slot", SAVE_SLOT)):
		return 0
	return _last_loaded


## Found by path rather than by the global autoload identifier, so that a scene
## opened without the singleton — a tool script, an isolated test harness —
## degrades to "cannot save" instead of failing to parse.
func _save_manager() -> Node:
	var manager := get_node_or_null(^"/root/SaveManager")
	if manager == null:
		push_error("no SaveManager autoload; structures cannot be saved or loaded")
		return null
	# Re-registering here, not only in `_ready()`, because under `--script` the
	# autoloads are attached to the tree AFTER the script's `_init()` returns —
	# and the smokes build their world inside `_init()`. Their `_ready()` runs
	# with no singleton to register with. `register()` is idempotent for exactly
	# this reason.
	_register(manager)
	return manager


func _register(manager: Node = null) -> void:
	if manager == null:
		manager = get_node_or_null(^"/root/SaveManager")
	if manager != null:
		manager.call("register", SAVE_DOMAIN, self)


## Take down everything the PLAYER built.
##
## World-owned pieces survive, which is what makes them world-owned: `load_data()`
## clears before it rebuilds from the save, and a door hung in Grandpa's cottage
## by the world is not in that save and must not disappear when one is loaded.
func clear() -> void:
	var kept: Array[Dictionary] = []
	for entry: Dictionary in _placed:
		if bool(entry.get("fixed", false)):
			kept.append(entry)
			continue
		_demolish(entry)
	_placed = kept


## A static body carrying the piece's MEASURED collision.
##
## The extents come from the catalogue, which a generator read off the model's
## own glTF accessors. Nobody typed them, because a collider that disagrees with
## its art is a wall you walk through or a floor with an invisible kerb, and both
## get reported as physics bugs rather than as data errors.
##
## ONE BOX IS NOT ENOUGH FOR A PIECE WITH A HOLE IN IT, and that was the quieter
## half of "there's no way to open doors": a doorway wall's measured bound is 2m
## x 3.12m of solid box, and a bounding box has no doorway in it. Every doorway
## in the game — placed or authored — was sealed shut, which makes an opening
## door theatre. So a piece may carry `collider_boxes`, piers and a lintel, and
## gets one shape per box; `collider_centre`/`collider_extents` stay as the single
## measured bound for the solid pieces and for the settlement renderer next door,
## which reads them.
func _body(piece: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new()
	for box: Dictionary in collider_boxes(piece):
		var shape := BoxShape3D.new()
		var extents: Array = box["extents"]
		shape.size = Vector3(float(extents[0]), float(extents[1]), float(extents[2])) * 2.0
		var collider := CollisionShape3D.new()
		collider.shape = shape
		var centre: Array = box["centre"]
		collider.position = Vector3(float(centre[0]), float(centre[1]), float(centre[2]))
		body.add_child(collider)
	return body


## Every box a piece's collision is made of, as `[{centre, extents}]`.
##
## One entry for a solid piece, three for a doorway. Static, and the same shape
## either way, so a caller never has to ask which kind it is holding —
## `scripts/building/doors.gd` rebuilds the settlement's doorway collision from
## exactly this list.
static func collider_boxes(piece: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var boxes: Variant = piece.get("collider_boxes", null)
	if boxes is Array:
		for entry: Variant in boxes as Array:
			if entry is Dictionary and (entry as Dictionary).has("centre") \
					and (entry as Dictionary).has("extents"):
				out.append({
					"centre": (entry as Dictionary)["centre"],
					"extents": (entry as Dictionary)["extents"],
				})
	if out.is_empty():
		out.append({
			"centre": piece.get("collider_centre", [0.0, 0.0, 0.0]),
			"extents": piece.get("collider_extents", [1.0, 1.0, 1.0]),
		})
	return out


## Point every mesh at one shared material per source material name.
##
## Without this, two hundred walls instantiate two hundred copies of the same
## plaster material and the renderer treats each as its own state change.
func _share_materials(art: Node3D) -> void:
	for node in art.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var material: Material = mesh.mesh.surface_get_material(surface)
			if material == null:
				continue
			var key := material.resource_name if material.resource_name != "" else str(material.get_instance_id())
			if not _materials.has(key):
				_materials[key] = material
			mesh.set_surface_override_material(surface, _materials[key])


func _load_catalogue() -> Dictionary:
	var file := FileAccess.open(CATALOGUE_PATH, FileAccess.READ)
	if file == null:
		push_error("build catalogue missing: %s" % CATALOGUE_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("build catalogue is not readable: %s" % CATALOGUE_PATH)
		return {}
	var out: Dictionary = {}
	for id: String in (parsed as Dictionary).get("pieces", {}).keys():
		if not id.begins_with("_"):
			out[id] = (parsed as Dictionary)["pieces"][id]
	return out
