extends Node3D

## The doors of the world: the button that opens one, and the ones the world
## already built.
##
## Two jobs, and they are here together because they are two halves of one
## complaint. The owner played and said: "On the pre built houses, there's no way
## to open doors and you have the doors placed in entirely the wrong place."
##
##   1. NOTHING READ `interact` FOR A DOOR. `station.gd` gives a placed door the
##      behaviour; something has to press it. That is this file's
##      `_physics_process`, and it is the whole of the input side.
##   2. THE PRE-BUILT HOUSES HAD NO REAL DOORS AT ALL. Every cottage in
##      `data/config/settlement.json` is drawn by the scatter as static
##      instances, and a static instance cannot open. Its door leaf was a mesh
##      emitted at the doorway wall's own origin, which is where the second half
##      of the complaint comes from as well — see `_comment_opening` in
##      `pieces.json` for the measurement. So the settlement no longer draws door
##      leaves at all: it draws the doorway, and this file hangs a real, placed,
##      station-carrying door in it.
##
## NOTHING IN `scripts/world/` IS MODIFIED. `scatter_rules.gd` is READ — its own
## expansion is asked where the settlement's doorways are, so there is not a
## second copy of the layout maths here to drift from the first. That is the same
## discipline `scatter_rules` itself keeps about `pieces.json`, in the opposite
## direction.
##
## THE DOORWAY'S COLLISION IS REBUILT, and this is the one genuinely invasive
## thing here, so it is stated plainly. The settlement's collision is one box per
## piece, taken from the catalogue's measured bounds — right for a wall, and a
## sealed doorway for a wall with a hole in it. Every pre-built cottage in the
## Meadows was shut: not "the door does not open" but "the doorway is solid, and
## the player has never been inside one of these houses." A box has no hole in
## it, so the shapes for the doorway walls are replaced, here, at load, with the
## piers and lintel `pieces.json` now measures. Same body, same node name, same
## count of pieces; only the shapes change. If the body is not found, nothing is
## touched and a warning says so.
##
## MOUNTED BY `build_mode._mount_field_systems()`, for the reason that function
## already gives about `Harvestable` and `Tools`: it belongs in
## `scenes/world/meadows_playground.tscn` beside `Structures`, and the milestone
## that wrote it did not own that file. Adding it to the scene properly is a
## scene edit and the deletion of four lines, in either order.

const RULES := preload("res://scripts/world/scatter_rules.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const STRUCTURES := preload("res://scripts/building/structures.gd")
const STATION := preload("res://scripts/building/station.gd")
const CONFIG_PATH := "res://data/config/building.json"

## The scatter layer the settlement is drawn by, and the node it draws into.
const BUILDINGS_LAYER := "buildings"
const VEGETATION_NODE := "Vegetation"

## Which piece a room hangs in its doorway, in `settlement.json`.
##
## Deliberately NOT the key `scatter_rules._expand_room()` reads. That one is
## `door_leaf`, and it makes the scatter draw a STATIC leaf; a room that names
## both would get two doors in one doorway, one of them unopenable. Renaming the
## key in the data is how the settlement handed its doors over to this file.
const ROOM_LEAF_KEY := "door_hangs"

## The surround that goes round the leaf, also in `settlement.json`.
##
## A third piece rather than a nicety: the kit's hole is 1.305m wide and its leaf
## is 1.120m, so a leaf on its own leaves nine centimetres of daylight down each
## jamb and a hand's width of sky under the arch. From inside a cottage that
## reads as a badly fitted door, which is what the first render of this fix
## showed. The frame covers the reveal. It is optional — a room that names none
## gets a bare doorway, which is right for a barn.
const ROOM_FRAME_KEY := "door_frame"

## Process frames to wait for the scatter before giving up on it. Generous: the
## world awaits frames of its own before it starts, the terrain streams, and a
## door that never gets hung is a silent failure, so this errs towards waiting.
const INSTALL_FRAMES := 600

## A door has opened or shut somewhere in the world. For a sound, a prompt, or a
## pal that should not be able to follow you through a shut one.
signal door_toggled(station: Node, is_open: bool)

var _player: Node3D = null
var _structures: Node3D = null
var _build: Node = null
var _combat: Node = null

## Metres. TUNABLE, from `data/config/building.json`. Measured from the trainer
## to the door's HINGE, which is at one edge of a 1.1m leaf, so this has to cover
## standing in front of the far side of the door as well as the near one.
var _reach: float = 3.0

var _hung: int = 0
var _installed: bool = false


func _ready() -> void:
	_load_config()
	# Deferred and then given a frame: the world builds its terrain, water and
	# scatter inside its own `_ready()`, which runs after this node's.
	_install.call_deferred()


func bind(player: Node3D, structures: Node3D, build: Node, combat: Node) -> void:
	_player = player
	_structures = structures
	_build = build
	_combat = combat


## How many doors the world hung. Read by the smoke and by the preview tool.
func hung() -> int:
	return _hung


## --- the button -------------------------------------------------------------


## Read in `_physics_process`, never `_process`.
##
## `build_mode` records the cost of getting this wrong, and it applies exactly
## here: `Input.is_action_just_pressed()` is scoped to the frame the press was
## recorded in, and `satchel.gd` and `encounter_director.gd` both read `interact`
## from `_physics_process` already. A third reader in `_process` would sometimes
## see a different half of one press from the other two.
##
## `interact` is the EXISTING action — E on the keyboard, gamepad button 2 in
## `project.godot`. No new binding was added and none is needed: opening a door
## is the same verb as picking up a satchel or talking to something, and giving
## it its own button would be the first step towards a keyboard nobody can hold.
func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or _structures == null:
		return
	if not Input.is_action_just_pressed("interact"):
		return
	# Not while a ghost is up: `interact` in build mode is aiming at a piece, not
	# at a door, and a door swinging open behind the preview reads as a bug.
	if _build != null and is_instance_valid(_build) and bool(_build.call("is_open")):
		return
	if _combat != null and is_instance_valid(_combat) and bool(_combat.call("is_fighting")):
		return
	open_nearest(_player.global_position)


## Open or shut whichever door is nearest `from`, if one is in reach.
##
## Public and taking the point, rather than reading the player itself, so a test
## and the preview tool can work a door without an input event or a trainer.
func open_nearest(from: Vector3) -> Node:
	if _structures == null:
		return null
	var door: Node = _structures.call("nearest_station", from, _reach, STATION.BEHAVIOUR_DOOR)
	if door == null or not is_instance_valid(door):
		return null
	# `from` goes in as well as being the search point, because it decides which
	# way the leaf travels: away from whoever opened it, from either side.
	if bool(door.call("toggle", from)):
		door_toggled.emit(door, bool(door.call("is_open")))
	return door


## --- the doors the world already built --------------------------------------


func _install() -> void:
	if _installed:
		return
	_installed = true

	# WAITED FOR, not assumed. `playground_world._ready()` awaits two process
	# frames before it builds anything, and the scatter is the last thing it
	# builds — so a single deferred call lands in a world with no settlement in
	# it yet, finds no doorways, and hangs nothing. That is exactly what the
	# first run of this did: the node existed, the count was zero, and nothing
	# said why. `Vegetation` appearing WITH children is the signal that the
	# scatter has run, because `vegetation.build()` is synchronous once the node
	# is in the tree.
	var vegetation: Node = null
	for i in INSTALL_FRAMES:
		await get_tree().process_frame
		if _structures == null or not is_instance_valid(_structures) or get_parent() == null:
			return
		var found: Node = get_parent().get_node_or_null(NodePath(VEGETATION_NODE))
		if found != null and found.get_child_count() > 0:
			vegetation = found
			break
	if vegetation == null:
		# A world with no scatter has no authored settlement in it either — a
		# preview tool, a test harness. Not an error.
		return

	var layer: Dictionary = _layer()
	if layer.is_empty():
		push_warning("vegetation.json has no '%s' layer; the settlement has no doors" % BUILDINGS_LAYER)
		return

	# THE SAME HEIGHTFIELD THE SCATTER USED, built the same way from the same
	# config, so a door lands on the pad its cottage stands on. `vegetation.build()`
	# constructs one exactly like this; it is deterministic from
	# `terrain_playground.json` and holds no world state.
	var field: RefCounted = HEIGHTFIELD.new()

	var by_model: Dictionary = {}
	for site: Variant in layer.get("sites", []):
		var name := str(site)
		var leaf := _room_piece(name, ROOM_LEAF_KEY)
		var frame := _room_piece(name, ROOM_FRAME_KEY)
		# One site at a time, so the doorways that come back are known to belong
		# to this site and can be given the leaf ITS rooms asked for. Expanding
		# the whole layer at once returns a flat list with no site on it.
		var one := {"sites": [name], "clear_radius": layer.get("clear_radius", 0.0)}
		for entry: Variant in RULES.buildings_for(one, field):
			var placement: Dictionary = entry
			var model := str(placement["model"])
			var piece := _piece_for(model)
			if piece.is_empty() or not STRUCTURES.is_an_opening(piece):
				continue
			if not by_model.has(model):
				by_model[model] = []
			(by_model[model] as Array).append(placement)
			if not frame.is_empty():
				_structures.call(
					"place_fixed", frame, placement["position"] as Vector3, float(placement["yaw"])
				)
			if leaf.is_empty():
				continue
			# `place_fixed` takes the SNAPPED point — the doorway's own — and
			# applies the leaf's `hangs` offset itself, exactly as it does for a
			# door the player hangs. One code path, one offset, one chance to be
			# wrong about it.
			if _structures.call(
				"place_fixed", leaf, placement["position"] as Vector3, float(placement["yaw"])
			) != null:
				_hung += 1

	_unseal(vegetation, by_model)
	if _hung > 0:
		print("[doors] hung %d door(s) in the settlement" % _hung)


## Replace the sealed box over each authored doorway with piers and a lintel.
##
## See the header. The catalogue's `collider_boxes` is the source for both this
## and `structures._body()`, so a placed doorway and an authored one are solid in
## exactly the same places.
func _unseal(vegetation: Node, by_model: Dictionary) -> void:
	for model: String in by_model.keys():
		var piece := _piece_for(model)
		var boxes := STRUCTURES.collider_boxes(piece)
		if boxes.size() <= 1:
			continue
		var body_name := "%s_Collision" % model.get_file().get_basename()
		var body: Node = vegetation.get_node_or_null(NodePath(body_name))
		if body == null:
			push_warning("no %s under %s; that doorway stays sealed" % [body_name, VEGETATION_NODE])
			continue
		for child in body.get_children():
			body.remove_child(child)
			child.queue_free()
		for entry: Variant in by_model[model]:
			var placement: Dictionary = entry
			var scale := float(placement.get("scale", 1.0))
			var basis := Basis(Vector3.UP, float(placement["yaw"]))
			for box: Dictionary in boxes:
				var extents: Array = box["extents"]
				var centre: Array = box["centre"]
				var shape := BoxShape3D.new()
				shape.size = Vector3(
					float(extents[0]), float(extents[1]), float(extents[2])
				) * 2.0 * scale
				var node := CollisionShape3D.new()
				node.shape = shape
				var offset := Vector3(float(centre[0]), float(centre[1]), float(centre[2]))
				node.transform = Transform3D(
					basis, (placement["position"] as Vector3) + basis * (offset * scale)
				)
				body.add_child(node)


## What a site's rooms name under `key` — the leaf, or the frame — from
## `settlement.json`.
##
## A site with several rooms that disagree is a data error rather than a choice —
## the settlement has one door per site and always has — so the first answer wins
## and the disagreement is said out loud.
func _room_piece(site_name: String, key: String) -> String:
	var sites: Dictionary = RULES.settlement().get("sites", {})
	var site: Variant = sites.get(site_name, {})
	if not site is Dictionary:
		return ""
	var chosen := ""
	for entry: Variant in (site as Dictionary).get("rooms", []):
		if not entry is Dictionary:
			continue
		var named := str((entry as Dictionary).get(key, ""))
		if named.is_empty():
			continue
		if chosen.is_empty():
			chosen = named
		elif chosen != named:
			push_warning("site '%s' names two different '%s' pieces; using '%s'" % [site_name, key, chosen])
	return chosen


func _piece_for(model_path: String) -> Dictionary:
	for id: String in RULES.pieces().keys():
		if id.begins_with("_"):
			continue
		var entry: Variant = RULES.pieces()[id]
		if entry is Dictionary and str((entry as Dictionary).get("model", "")) == model_path:
			return entry
	return {}


func _layer() -> Dictionary:
	var layers: Variant = RULES.config().get("layers", {})
	if not layers is Dictionary:
		return {}
	var layer: Variant = (layers as Dictionary).get(BUILDINGS_LAYER, {})
	return layer if layer is Dictionary else {}


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_reach = float((parsed as Dictionary).get("door_reach", _reach))
