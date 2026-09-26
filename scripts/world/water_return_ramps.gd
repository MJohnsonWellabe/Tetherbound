extends Node3D

## F13 `return_shortcuts` rows of kind `physical_ramp`: a durable, server-owned
## world change made visible. Each row authors a walk `path` (settlement ->
## ramp top -> ramp foot -> departure) and a `deck_span` naming the two path
## vertices the plank deck bridges. The deck carries the walker over a terrace
## scarp the bare ground cannot be walked down.
##
## Gating is the replicated world flag and nothing else: the host commits
## `unlock_flag` through the ordinary ledger (the Reedhaven dock repair), every
## peer receives it in its world flags, and every peer builds the same state
## from the same flag here. Before the flag only the driven pilings and a few
## loose planks stand (visibly unbuilt, no deck, no collision on the gap); after
## it the deck, stringers and railings appear with their collision. A live flag
## change, a rejoin snapshot and a loaded save all take the same path.
##
## Composed from the one village family already on the water: the Medieval kit's
## `Floor_WoodDark` planks (the Gull Rest signal platform) and `WoodenFence`
## railing (the First Shore dock gate), on rough Kenney log pilings.
const DECK_SCENE := preload("res://assets/buildings/quaternius_medieval/Floor_WoodDark.gltf")
const FENCE_SCENE := preload("res://assets/buildings/quaternius_medieval/Prop_WoodenFence_Single.gltf")
const LOG_SCENE := preload("res://assets/environment/nature/log.glb")
const MODULE_M := 2.0  # Floor_WoodDark is a 2 x 2 m slab.
const FENCE_LENGTH_M := 2.0641  # Prop_WoodenFence_Single raw X extent.
const FENCE_HEIGHT_M := 0.8381
const LOG_LENGTH_M := 0.71  # log.glb lies along its own Z.
const DECK_CLEARANCE_M := 0.1  # deck top over the ground at each end; well inside STEP_HEIGHT.
const DECK_THICKNESS_M := 0.3
const PILING_MIN_SPAN_M := 0.3
const WOOD_TINT := Color("6b5843")

var _world: Node3D
var _game: Node
var _ramps: Array[Dictionary] = []


func build(world: Node3D) -> void:
	add_to_group("progression_restore")
	_world = world
	_game = get_node("/root/Game")
	for row: Dictionary in world.config.get("return_shortcuts", []):
		if str(row.get("kind", "")) != "physical_ramp":
			continue
		var ramp := _compile(row)
		if ramp.is_empty():
			push_error("Water physical_ramp has no buildable deck: " + str(row.get("id", "")))
			continue
		var root := Node3D.new()
		root.name = str(row.id)
		root.add_to_group("water_return_ramp")
		add_child(root)
		ramp.root = root
		ramp.open = null
		_ramps.append(ramp)
	_refresh()


## A loaded save can close a ramp this scene already opened (or open one).
func restore_progression_from_game(_loaded_game: Node) -> void:
	for ramp: Dictionary in _ramps:
		ramp.open = null
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func is_open(id: String) -> bool:
	for ramp: Dictionary in _ramps:
		if str(ramp.id) == id:
			return ramp.open == true
	return false


func _refresh() -> void:
	if _game == null:
		return
	var flags: RefCounted = _game.world.flags
	for ramp: Dictionary in _ramps:
		var open := flags != null and bool(flags.has(str(ramp.flag)))
		if ramp.open != null and bool(ramp.open) == open:
			continue
		ramp.open = open
		var root: Node3D = ramp.root
		for child: Node in root.get_children():
			root.remove_child(child)
			child.queue_free()
		if open:
			_build_deck(ramp)
		else:
			_build_unbuilt(ramp)


## Deck geometry from the authored path. The deck ends sit on the baked ground
## (sampled here, not trusted from the row) plus DECK_CLEARANCE_M.
func _compile(row: Dictionary) -> Dictionary:
	var path: Array = row.get("path", [])
	var span: Array = row.get("deck_span", [])
	if span.size() != 2:
		return {}
	var from := int(span[0])
	var to := int(span[1])
	if from < 0 or to <= from or to >= path.size():
		return {}
	var a := _grounded(path[from])
	var b := _grounded(path[to])
	if not a.is_finite() or not b.is_finite():
		return {}
	a.y += DECK_CLEARANCE_M
	b.y += DECK_CLEARANCE_M
	var forward := (b - a).normalized()
	var right := forward.cross(Vector3.UP).normalized()
	var up := right.cross(forward).normalized()
	var modules := maxi(1, ceili(a.distance_to(b) / MODULE_M))
	return {"id": str(row.id), "flag": str(row.unlock_flag), "a": a, "b": b,
		"forward": forward, "right": right, "up": up, "length": a.distance_to(b),
		"modules": modules, "width": float(row.get("deck_width_m", MODULE_M))}


func _grounded(raw: Variant) -> Vector3:
	if not raw is Array or (raw as Array).size() < 3:
		return Vector3.INF
	var x := float(raw[0])
	var z := float(raw[2])
	var y: float = _world.ground_height_at(x, z)
	return Vector3(x, y, z) if is_finite(y) else Vector3.INF


func _build_deck(ramp: Dictionary) -> void:
	var root: Node3D = ramp.root
	var a: Vector3 = ramp.a
	var forward: Vector3 = ramp.forward
	var right: Vector3 = ramp.right
	var up: Vector3 = ramp.up
	var length: float = ramp.length
	var width: float = ramp.width
	var modules: int = ramp.modules
	var module_len := length / float(modules)
	var presentation: bool = not bool(_world.simulation_only)
	var body := StaticBody3D.new()
	body.name = "DeckBody"
	root.add_child(body)
	# One box under the whole walk surface: its top face IS the deck line.
	_add_box(body, Basis(right, up, -forward), a + forward * length * 0.5 - up * DECK_THICKNESS_M * 0.5,
		Vector3(width, DECK_THICKNESS_M, length))
	for index in modules:
		var centre := a + forward * module_len * (float(index) + 0.5)
		if presentation:
			var deck := DECK_SCENE.instantiate() as Node3D
			deck.name = "Deck_%d" % index
			deck.transform = Transform3D(
				Basis(right * (width / MODULE_M), up, -forward * (module_len / MODULE_M)), centre)
			root.add_child(deck)
			for side: float in [-1.0, 1.0]:
				# Stringers: a log under each deck edge, so the span reads as built.
				var stringer := _log(Basis(-right * 1.4, up * 1.4, forward * (module_len / LOG_LENGTH_M)),
					centre + right * side * (width * 0.5 - 0.15) - up * 0.14)
				stringer.name = "Stringer_%d_%s" % [index, "r" if side > 0.0 else "l"]
				root.add_child(stringer)
		# Railings leave the first and last module open as landings.
		if index == 0 or index == modules - 1:
			continue
		for side: float in [-1.0, 1.0]:
			var edge := centre + right * side * (width * 0.5 - 0.06)
			if presentation:
				var rail := FENCE_SCENE.instantiate() as Node3D
				rail.name = "Rail_%d_%s" % [index, "r" if side > 0.0 else "l"]
				# Sheared basis: rails follow the pitch, posts stay plumb.
				rail.transform = Transform3D(Basis(forward * (module_len / FENCE_LENGTH_M), Vector3.UP, right), edge)
				root.add_child(rail)
			# The railing is solid, as it looks.
			_add_box(body, Basis(right, up, -forward), edge + up * FENCE_HEIGHT_M * 0.5,
				Vector3(0.12, FENCE_HEIGHT_M, module_len))
	if presentation:
		_build_pilings(ramp, true)


## Before the repair: pilings already driven, planks stacked at the top and
## lying at the scarp foot. No deck, no collision -- nothing to walk on.
func _build_unbuilt(ramp: Dictionary) -> void:
	if bool(_world.simulation_only):
		return
	var root: Node3D = ramp.root
	_build_pilings(ramp, false)
	var a: Vector3 = ramp.a
	var b: Vector3 = ramp.b
	var forward: Vector3 = ramp.forward
	var flat := Vector3(forward.x, 0.0, forward.z).normalized()
	var side := flat.cross(Vector3.UP)
	var yaw := atan2(-flat.z, flat.x)
	for index in 3:
		var at := a - flat * 1.6 + side * 1.9
		at.y = float(_world.ground_height_at(at.x, at.z)) + 0.04 + 0.05 * float(index)
		var plank := DECK_SCENE.instantiate() as Node3D
		plank.name = "LoosePlank_%d" % index
		plank.transform = Transform3D(Basis(Vector3.UP, yaw + 0.12 * float(index))
			* Basis.from_scale(Vector3(1.0, 1.0, 0.45)), at)
		root.add_child(plank)
	var foot := a.lerp(b, 0.62) + side * 0.4
	foot.y = float(_world.ground_height_at(foot.x, foot.z)) + 0.03
	var fallen := DECK_SCENE.instantiate() as Node3D
	fallen.name = "FallenPlank"
	fallen.transform = Transform3D(Basis(Vector3.UP, yaw + 0.7) * Basis(Vector3.RIGHT, 0.08)
		* Basis.from_scale(Vector3(1.0, 1.0, 0.45)), foot)
	root.add_child(fallen)


func _build_pilings(ramp: Dictionary, deck_built: bool) -> void:
	var root: Node3D = ramp.root
	var a: Vector3 = ramp.a
	var forward: Vector3 = ramp.forward
	var right: Vector3 = ramp.right
	var up: Vector3 = ramp.up
	var width: float = ramp.width
	var modules: int = ramp.modules
	var module_len := float(ramp.length) / float(modules)
	for joint in modules + 1:
		for side: float in [-1.0, 1.0]:
			var top := a + forward * module_len * float(joint) + right * side * (width * 0.5 - 0.15) \
				- up * DECK_THICKNESS_M
			var ground: float = _world.ground_height_at(top.x, top.z)
			if not is_finite(ground) or top.y - ground < PILING_MIN_SPAN_M:
				continue
			# Unbuilt pilings stand a little proud of where the deck will sit.
			var head := top.y + (0.0 if deck_built else 0.25)
			var span := head - ground + 0.3
			var piling := _log(Basis(Vector3.RIGHT, -PI * 0.5).scaled(Vector3(1.4, span / LOG_LENGTH_M, 1.4)),
				Vector3(top.x, ground - 0.3 + span * 0.5, top.z))
			piling.name = "Piling_%d_%s" % [joint, "r" if side > 0.0 else "l"]
			root.add_child(piling)


func _log(basis: Basis, at: Vector3) -> Node3D:
	var log := LOG_SCENE.instantiate() as Node3D
	log.transform = Transform3D(basis, at)
	_tint(log)
	return log


## The Kenney log's cream vertex colours read as concrete without a plain wood
## override (same fix as the pond jetty's pilings).
func _tint(node: Node) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = _wood()
	for child: Node in node.get_children():
		_tint(child)


var _wood_material: StandardMaterial3D
func _wood() -> StandardMaterial3D:
	if _wood_material == null:
		_wood_material = StandardMaterial3D.new()
		_wood_material.albedo_color = WOOD_TINT
		_wood_material.roughness = 0.95
		_wood_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return _wood_material


func _add_box(body: StaticBody3D, basis: Basis, at: Vector3, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.transform = Transform3D(basis, at)
	body.add_child(shape)
