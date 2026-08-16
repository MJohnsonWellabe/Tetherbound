extends Node3D

## SC14/SE22 — one authored crossing over one authored gap, shut until the
## player has the thing that opens it.
##
## Written for the South Bridge (spec §3's Gate 1) and generalised in place
## when the Old Mill Crossing (§3 Band 3) turned out to need every line of it:
## the deeper Meadows is visible across an old crossing the player can walk to
## at any level and cannot cross, and beating the gate's owner yields the key.
## This file is the mechanism a key operates, and it is a mechanism and not a
## message. Subclasses (`south_bridge.gd`, `mill_crossing.gd`) supply three
## ids and, if they have any, their own local dressing.
##
## HARD RULE, from the backlog items and the spec: *"never explains itself
## with UI text."* There is no dialogue here — `road_gate.gd` says a line
## because `SA7` is a tutorial for the idea that gated things have keys, and
## these are the real gates, hours later, where the world has already taught
## it. A locked attempt gets a physical answer: the leaf jars against its lock
## and settles back. The only words anywhere near a crossing are on the
## fingerposts, and they name destinations, never conditions — the same rule
## the seven severed spokes carry.
##
## Geography is authored, not invented here. `terrain_playground.json`'s
## `crossings[]` entry owns the road, the gap and the bridge's offsets
## together, so this script cannot drift from the ground the bake actually
## cut: the span is placed from the gap's own centre and axis, and sized to
## it (see `data/config/building_prefabs.json`'s `south_bridge`).
##
## What is reused rather than re-derived:
##   * `item_gate.gd` (`SB10`) for "does the player have what it takes, and has
##     this gate already been opened" — including the flag-backed persistence
##     that means a bridge opened before a save is still open after a reload.
##   * `building_prefabs.gd` for the span and the leaf, same composer the whole
##     settlement is built with (D24, one village family).
##   * `severed_spokes.gd`'s carve failsafe for a player who goes over the
##     edge. See `_hang_failsafe` for the one thing that had to be different.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const ITEM_GATE := preload("res://scripts/world/item_gate.gd")
const SEVERED_SPOKES := preload("res://scripts/world/severed_spokes.gd")
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"

## Which `crossings[]` entry this is, what opens it, and the flag that
## remembers it was opened. Set by a subclass through `_init`; a bare
## `gated_crossing` still builds the South Bridge, which is the one this file
## was written as.
var crossing_id := "south_bridge"
var key_item_id := "south_bridge_key"
var flag_id := "south_bridge_open"

## How far back from the carve centre the failsafe's recovery road ends, as a
## multiple of the carve's own outer reach. Only ever on the VILLAGE side —
## see `_hang_failsafe`.
const RECOVERY_BACK := 3.6

## The locked leaf's answer to a player without the key: a few degrees of
## travel and back, twice. Physical feedback, no words. TUNABLE.
const JAR_DEGREES := 4.0
const JAR_SECONDS := 0.09

var _crossing: Dictionary = {}
var _centre := Vector2.INF
## Unit vector pointing from the village side of the gully toward the deeper
## side — the bridge's own run. Resolved once in `build()` from the road's own
## start point, so nothing downstream has to know which compass direction
## "deeper" happens to be this chapter.
var _across := Vector2.ZERO
var _mesh: Node3D = null
var _shape: CollisionShape3D = null
var _prompt: Node3D = null
var _lock: MeshInstance3D = null
var _open := false
var _leaf_rest_yaw := 0.0
var _jarring := false
var _gate: RefCounted = null


func _init(id: String = "", key_item: String = "", flag: String = "") -> void:
	if id != "":
		crossing_id = id
	if key_item != "":
		key_item_id = key_item
	if flag != "":
		flag_id = flag
	_gate = ITEM_GATE.new(key_item_id, flag_id)


## `world` is only ever asked for `ground_height_at` — the same duck-typed
## climb `village.gd`, `road_gate.gd` and `severed_spokes.gd` all use, and
## never a raycast (D09).
func build(world: Node3D) -> void:
	_crossing = _load_crossing()
	if _crossing.is_empty():
		push_error("no `crossings` entry '%s' in %s; %s has no gap to span" % [
			crossing_id, TERRAIN_CONFIG, name])
		return
	# `carve` when this crossing cut its own gap (the south gully), `channel`
	# when something else did and the entry only restates the shape — SE21's
	# river cuts the Old Mill Crossing's gap, and an entry with a `carve` key
	# would have `_crossing_carve` dig a second trench through it.
	var carve: Dictionary = _crossing.get("carve", _crossing.get("channel", {}))
	var bridge: Dictionary = _crossing.get("bridge", {})
	var centre := _vec2(carve.get("centre", []))
	if centre == Vector2.INF:
		push_error("the '%s' crossing's carve has no centre" % crossing_id)
		return

	# The trench runs along `axis`; the bridge runs `across` it, and the
	# village is on whichever side of the trench the road came in from.
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var across := Vector2(-axis.y, axis.x)
	if _road_start().distance_to(centre + across) < _road_start().distance_to(centre - across):
		across = -across
	# `across` now points from the village toward the deeper side, so
	# `-across` is always "back the way you came" for the rest of this file.
	_centre = centre
	_across = across

	var reach: float = float(carve.get("half_width", 3.6)) + float(carve.get("rim", 3.4))
	var near_landing := centre - across * (reach + 1.0)
	var far_landing := centre + across * (reach + 1.0)
	var near_ground: float = float(world.call("ground_height_at", near_landing.x, near_landing.y))
	var far_ground: float = float(world.call("ground_height_at", far_landing.x, far_landing.y))
	if is_nan(near_ground) or is_nan(far_ground):
		push_error("no ground at %s's abutments; the span has nothing to stand on" % name)
		return
	# The two abutments are levelled to one authored height by their own
	# `flats` pads (terrain_playground.json), so these two samples should agree
	# to within centimetres. Taking the higher of the two anyway is
	# village.gd's own `ground: "highest"` rule, and it fails visibly (a deck
	# hovering at one end) rather than invisibly (a deck buried at the other)
	# if a future re-tune ever breaks that agreement.
	var deck_ground := maxf(near_ground, far_ground)

	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		push_error("no building recipes; %s cannot build its span" % name)
		return
	# See building_prefabs.gd's own header on `_holder`: an un-parented
	# template tree leaks RenderingServer resources at shutdown, which showed
	# up once as a heap-corrupting SIGABRT in an exported build.
	var template_holder := Node3D.new()
	template_holder.name = "PrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	prefabs.call("set_template_holder", template_holder)

	position = Vector3(centre.x, deck_ground, centre.y)
	# A Node3D's local +X maps to world (cos y, -sin y) in XZ, and the prefab's
	# deck runs along its own local +X — so this points the span across the
	# trench rather than along it.
	rotation.y = atan2(-across.y, across.x)

	var span: Node3D = prefabs.call("instantiate", str(bridge.get("prefab", "south_bridge")))
	if span == null:
		push_error("bridge prefab missing: %s" % bridge.get("prefab", "south_bridge"))
		return
	span.name = "Span"
	add_child(span)
	_add_prefab_colliders(prefabs, span, str(bridge.get("prefab", "south_bridge")))

	_build_gate(prefabs, bridge)
	_hang_failsafe(world, carve, centre, across, reach)
	# Whatever else stands at this particular crossing — the mill, for one.
	_build_extras(world, prefabs, deck_ground)

	# SB10: a gate the player already opened stays open across a reload — the
	# flag is the source of truth, not the fresh `_open := false` above.
	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null and _gate.is_open(progression):
		_unlock()


func is_open() -> bool:
	return _open


## What the interact prompt reads. Deliberately about the OBJECT, never about
## the condition — "Try the bridge gate", not "Locked: needs a key".
func prompt_label() -> String:
	return "Try the bridge gate"


## Anything this particular crossing has besides a span and a gate. The base
## crossing has none; `mill_crossing.gd` stands a mill on the bank here.
func _build_extras(_world: Node3D, _prefabs: RefCounted, _deck_ground: float) -> void:
	pass


## Where the span sits, in world metres — for tests and capture tools, so
## neither has to re-derive it from the carve.
func crossing_centre() -> Vector2:
	return _centre


## A point `distance` metres back from the crossing on the VILLAGE side.
## Exposed so a test can drive a real walk at the gate without re-deriving
## which side of the gully the village is on — the one piece of this geometry
## that is resolved at build time rather than authored.
func near_point(distance: float) -> Vector2:
	return _centre - _across * distance


## The same, on the deeper side.
func far_point(distance: float) -> Vector2:
	return _centre + _across * distance


## Whether `spot` is on the deeper side of the gully, and by how far. Negative
## on the village side. The one honest way to ask "did they get across".
func depth_past_crossing(spot: Vector2) -> float:
	return (spot - _centre).dot(_across)


## The prefab authors its own colliders (`building_prefabs.json`), in the
## prefab's own local frame — this is the same walk `village.gd` does over
## them, kept here rather than reached for through village.gd because that
## file places settlement structures from `village.json` and these are not
## ones. Used for the span, and by `mill_crossing.gd` for the mill.
func _add_prefab_colliders(prefabs: RefCounted, span: Node3D, prefab_name: String) -> void:
	var boxes: Array = prefabs.call("colliders", prefab_name)
	if boxes.is_empty():
		# Falling back to one AABB box would seal the whole span end to end,
		# including the rails' airspace — walkable, but the player would step
		# up onto a slab a metre above the deck. Say so instead.
		push_warning("prefab '%s' authored no colliders; nothing about it is solid" % prefab_name)
		return
	var body := StaticBody3D.new()
	body.name = "SpanCollision"
	for entry: Variant in boxes:
		var spec: Dictionary = entry
		var at: Array = spec.get("at", [0.0, 0.0, 0.0])
		var size: Array = spec.get("size", [1.0, 1.0, 1.0])
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(float(size[0]), float(size[1]), float(size[2]))
		shape.shape = box
		shape.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
		body.add_child(shape)
	span.add_child(body)


## The leaf across the near landing, its lock, and the prompt that tries it.
## Deliberately the same three parts `road_gate.gd` builds, for the same
## reasons its own comments give at length — a bare fence panel reads as
## property fencing rather than as something deliberately shut, and a highly
## metallic lock renders as a black silhouette under `gl_compatibility`.
func _build_gate(prefabs: RefCounted, bridge: Dictionary) -> void:
	var leaf: Node3D = prefabs.call("instantiate", str(bridge.get("gate_prefab", "south_bridge_gate")))
	if leaf == null:
		push_error("gate prefab missing: %s" % bridge.get("gate_prefab", "south_bridge_gate"))
		return
	# Local metres in this node's own frame: -X is back toward the village
	# (the span's local +X was aimed at `across` in `build`), and the deck
	# surface is 0.12 above the ground the span was seated on.
	var offset := -absf(float(bridge.get("gate_offset", 7.4)))
	_mesh = leaf
	_mesh.name = "GateLeaf"
	# Yawed a quarter turn out of the span's own axis so the panel stands
	# ACROSS the deck rather than along it.
	_mesh.rotation.y = deg_to_rad(90.0)
	_mesh.position = Vector3(offset, 0.12, 0.0)
	_leaf_rest_yaw = _mesh.rotation.y
	add_child(_mesh)

	var aabb: AABB = prefabs.call("combined_aabb", _mesh)

	_lock = MeshInstance3D.new()
	_lock.name = "Lock"
	var lock_body := BoxMesh.new()
	lock_body.size = Vector3(0.16, 0.14, 0.06)
	_lock.mesh = lock_body
	var lock_material := StandardMaterial3D.new()
	lock_material.albedo_color = Color(0.72, 0.56, 0.24)
	# Low metallic on purpose: see road_gate.gd's own two failed attempts.
	# A highly metallic StandardMaterial3D takes almost all of its visible
	# colour from specular environment reflection, which the Compatibility
	# renderer's flat ambient here cannot supply, so it renders near-black
	# whatever its albedo says.
	lock_material.metallic = 0.15
	lock_material.roughness = 0.4
	_lock.material_override = lock_material
	_lock.position = Vector3(0.0, aabb.position.y + aabb.size.y * 0.55, -(aabb.size.z * 0.5 + 0.03))
	_mesh.add_child(_lock)

	var shackle := MeshInstance3D.new()
	shackle.name = "Shackle"
	var shackle_ring := TorusMesh.new()
	shackle_ring.inner_radius = 0.035
	shackle_ring.outer_radius = 0.06
	shackle.mesh = shackle_ring
	shackle.material_override = lock_material
	shackle.rotation.x = deg_to_rad(90.0)
	shackle.position = Vector3(0.0, lock_body.size.y * 0.5, 0.0)
	_lock.add_child(shackle)

	var body := StaticBody3D.new()
	body.name = "GateCollision"
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Wider than the leaf itself and tall enough not to be vaulted: the deck
	# is 2.1m between its rails and the panel is 2.05m, so a box matched to
	# the panel alone would leave a person-width gap at each rail.
	box.size = Vector3(0.4, 1.9, 2.6)
	_shape.shape = box
	body.add_child(_shape)
	body.position = Vector3(offset, 0.12 + 0.95, 0.0)
	add_child(body)

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3(offset, 1.3, 0.0)
	# Same 4.0m radius road_gate.gd settled on, and for its reason: at full
	# scale an approach from an angle is stopped by the panel's face well
	# outside a tighter radius.
	_prompt.call("configure", prompt_label(), 4.0, true)
	_prompt.connect("activated", _on_tried)
	add_child(_prompt)


## `severed_spokes.gd`'s own recovery volume, reused rather than re-derived:
## the geometry (a box between the walls, its ceiling measured down from the
## lip so a body resting on a sloping floor is still inside it) took two
## attempts to get right there and there is no second version of it worth
## having.
##
## The ONE thing that had to be different is where it puts the player back.
## `_recovery_point` walks back along the road it is handed until it is clear
## of the carve, so handing it this crossing's real road — which continues to
## the far side — would recover a player who fell in to the far lip. That is
## not a failsafe, it is a free crossing: fall in the gully, wake up past the
## gate. So the road passed here is a two-point stub on the VILLAGE side only,
## built from the carve's own geometry. A player who goes over from the far
## side after opening the bridge is put back on the near side too; that is a
## walk back over their own open bridge, which is the harmless direction for
## this to be wrong in.
func _hang_failsafe(world: Node3D, carve: Dictionary, centre: Vector2, across: Vector2, reach: float) -> void:
	if not bool(carve.get("failsafe", false)):
		return
	var spokes: Node3D = SEVERED_SPOKES.new()
	spokes.name = "GullyFailsafe"
	add_child(spokes)
	var village_side := [
		[centre.x - across.x * reach * RECOVERY_BACK, centre.y - across.y * reach * RECOVERY_BACK],
		[centre.x - across.x * (reach + 1.0), centre.y - across.y * (reach + 1.0)],
	]
	spokes.call("_add_carve_failsafe", world, spokes, carve, village_side)


func _on_tried() -> void:
	if _open:
		return
	var game := get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	var progression: RefCounted = game.get("progression") if game != null else null

	if inventory != null and progression != null and _gate.try_open(inventory, progression):
		_unlock()
	else:
		_jar()


func _unlock() -> void:
	_open = true
	if _shape != null:
		_shape.disabled = true
	if _lock != null:
		_lock.visible = false
	if _mesh != null:
		# Swung parallel to the deck it was blocking — an instant re-pose
		# rather than an animation, the same call road_gate.gd makes and for
		# the same reason: no rig exists for this leaf, and the feedback is
		# carried by the pose plus the lock coming off.
		_mesh.rotation.y = _leaf_rest_yaw + deg_to_rad(90.0)
	if _prompt != null:
		_prompt.call("set_enabled", false)


## The locked answer. No dialogue, no HUD line, no "you need a key" — the leaf
## moves the couple of degrees its lock allows and stops. A player who tries it
## twice learns the same thing a player who tries a locked door twice learns.
func _jar() -> void:
	if _mesh == null or _jarring:
		return
	_jarring = true
	var travel := deg_to_rad(JAR_DEGREES)
	var tween := create_tween()
	tween.tween_property(_mesh, "rotation:y", _leaf_rest_yaw + travel, JAR_SECONDS)
	tween.tween_property(_mesh, "rotation:y", _leaf_rest_yaw - travel * 0.5, JAR_SECONDS)
	tween.tween_property(_mesh, "rotation:y", _leaf_rest_yaw, JAR_SECONDS)
	tween.finished.connect(func() -> void: _jarring = false)


func _road_start() -> Vector2:
	var road: Array = _crossing.get("road", [])
	if road.is_empty():
		return Vector2.ZERO
	return _vec2(road[0])


func _load_crossing() -> Dictionary:
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	for entry: Variant in (parsed as Dictionary).get("crossings", []):
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == crossing_id:
			return entry as Dictionary
	return {}


func _vec2(raw: Variant) -> Vector2:
	if not raw is Array or (raw as Array).size() < 2:
		return Vector2.INF
	return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
