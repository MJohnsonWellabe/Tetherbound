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

const CATALOGUE_PATH := "res://data/building/pieces.json"
const GRID := preload("res://scripts/building/build_grid.gd")

## This file used to own `user://structures.json` outright — its own path, its
## own version constant, its own refusal logic. It is now one CONTRIBUTOR to the
## single envelope `SaveManager` writes, under this key. See
## `autoload/save_manager.gd` for why there is only one file.
const SAVE_DOMAIN := "structures"

## Everything writes to slot 0 until there is a slot-picking screen to write
## anything else. Tunable; not a design decision.
const SAVE_SLOT := 0

## Placed pieces, in placement order. Each is the serialisable record and its
## live node together, so saving never has to walk the scene tree and read
## transforms back out of it.
var _placed: Array[Dictionary] = []

## How many pieces the last `load_data()` rebuilt. `load_saved()` reports it,
## because SaveManager hands state out and does not count what came back.
var _last_loaded: int = 0

var _catalogue: Dictionary = {}
## One material per source material name, shared across every piece that uses
## it — the same trick `vegetation._tints` uses, so two hundred walls hold two
## materials rather than four hundred.
var _materials: Dictionary = {}


func _ready() -> void:
	_catalogue = _load_catalogue()
	_register()


## Every piece the palette can offer, as `{id: definition}`.
func catalogue() -> Dictionary:
	return _catalogue


func definition(piece_id: String) -> Dictionary:
	return _catalogue.get(piece_id, {})


## Build one piece and keep it. Returns the node, or null if the id is unknown.
##
## `position` and `yaw` are taken as given — deciding WHERE a piece goes is
## `build_mode`'s job and validating it is `build_mode`'s job. This function
## places what it is told to, so that a load from disk and a fresh placement go
## down exactly the same path. A loader with its own placement code is a loader
## that drifts.
func place(piece_id: String, position: Vector3, yaw: float, storey: int = 0) -> Node3D:
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
	node.global_position = position
	node.rotation.y = yaw

	# The whole imported scene, not one extracted mesh: the kit's pieces are
	# multi-surface and an extracted first-mesh loses the trim.
	var art: Node3D = (load(model_path) as PackedScene).instantiate() as Node3D
	if art != null:
		node.add_child(art)
		_share_materials(art)

	node.add_child(_body(piece))

	var record := {
		"piece": piece_id,
		"x": position.x,
		"y": position.y,
		"z": position.z,
		"yaw_deg": rad_to_deg(yaw),
		"storey": storey,
	}
	_placed.append({"record": record, "node": node})
	return node


## Remove the piece nearest a point, within `radius`. Returns true if one went.
func remove_nearest(point: Vector3, radius: float) -> bool:
	var best := -1
	var best_distance := radius
	for i in _placed.size():
		var node: Node3D = _placed[i]["node"]
		if not is_instance_valid(node):
			continue
		var distance := node.global_position.distance_to(point)
		if distance <= best_distance:
			best_distance = distance
			best = i
	if best < 0:
		return false
	var doomed: Node3D = _placed[best]["node"]
	if is_instance_valid(doomed):
		doomed.queue_free()
	_placed.remove_at(best)
	return true


## Is anything already occupying this spot? Used to refuse a placement that
## would sit inside an existing piece.
##
## Compared by SNAPPED position rather than by collider overlap: two pieces on
## the same grid slot always land on exactly the same coordinates, so an exact
## comparison is both cheaper and more honest than a physics query that would
## also trip on a roof legitimately overhanging a wall.
func occupied(position: Vector3, yaw: float) -> bool:
	for entry: Dictionary in _placed:
		var record: Dictionary = entry["record"]
		if absf(record["x"] - position.x) < 0.05 \
				and absf(record["y"] - position.y) < 0.05 \
				and absf(record["z"] - position.z) < 0.05 \
				and absf(angle_difference(deg_to_rad(record["yaw_deg"]), yaw)) < 0.05:
			return true
	return false


func count() -> int:
	return _placed.size()


## Placement records only, for tests and for the save file.
func records() -> Array:
	var out: Array = []
	for entry: Dictionary in _placed:
		out.append((entry["record"] as Dictionary).duplicate())
	return out


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
			int(record.get("storey", 0))
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


func clear() -> void:
	for entry: Dictionary in _placed:
		var node: Node3D = entry["node"]
		if is_instance_valid(node):
			node.queue_free()
	_placed.clear()


## A static body carrying one box, sized from the piece's MEASURED bounds.
##
## The extents come from the catalogue, which a generator read off the model's
## own glTF accessors. Nobody typed them, because a collider that disagrees with
## its art is a wall you walk through or a floor with an invisible kerb, and both
## get reported as physics bugs rather than as data errors.
func _body(piece: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	var extents: Array = piece.get("collider_extents", [1.0, 1.0, 1.0])
	shape.size = Vector3(float(extents[0]), float(extents[1]), float(extents[2])) * 2.0
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var centre: Array = piece.get("collider_centre", [0.0, 0.0, 0.0])
	collider.position = Vector3(float(centre[0]), float(centre[1]), float(centre[2]))
	body.add_child(collider)
	return body


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
