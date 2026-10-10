extends Node3D

## T3-PICKUPS. A one-time, non-renewable item find: the mechanism
## `key_pickup.gd` already proves (item_id -> satchel, a `pickup:<id>` flag
## that survives reload, refuse-not-vanish on a full satchel) with the one
## piece that doesn't generalise -- a literal key-shaped mesh -- swapped for
## a plain prop, loaded the same PackedScene-vs-Mesh way
## `harvest_node.gd::_build_visual()` and `props.gd::place()` already load
## every glTF in this project.
##
## Why not just call `key_pickup.gd` directly: its `setup(item_id, label)`
## really is generic (nothing in its persistence logic is key-specific), but
## `_build_visual()` hard-builds a shaft-and-ring key regardless of what
## `item_id` names. A permanent elixir sitting in the world as a brass key
## would read as a bug, not a find. This file exists ONLY to swap that one
## piece; the flag/inventory contract below is deliberately the same shape,
## not a second design.
##
## `data/items/items.json` has no `_comment` claiming every world item must
## be a `key_pickup`/`tm_pickup` -- both are already item-id-driven, both
## already coexist as separate one-time pickup props, and CLAUDE.md's own
## reuse rule is "prefer existing infrastructure", not "there may be only
## one file". No new inventory, currency, recipe or loot system is added:
## this is a third THIN PROP wired to the one satchel every pickup already
## shares.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")
## D103 / Stage B lane 3.B. See `_on_picked_up()`: this find is claimed through
## the world ledger now, not written here. OP-0905-18's catalyst-discoverability
## announcement moved with the grant to `ledger_rpc.gd::_apply_player_ops()`,
## which is peer-scoped -- the same reason `_on_delta_applied()` below cannot
## safely make it (every peer sees the flag delta; only one peer receives the
## `item_grant`).
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")

const FLAG_PREFIX := "cache:"
const PICKUP_SPECS := preload("res://scripts/net/pickup_spec_registry.gd")

## Only these records have an authored identity assembly. Other presentations
## (notably the accepted candy, mushroom and stat draughts) keep their own art.
const IDENTITY_STYLES := {
	"orb_basic": "orb_plain", "orb_greater": "orb_banded", "orb_prime": "orb_sprung",
	"tm_aqua_shot": "tm_nozzle", "tm_aerial_flash": "tm_wings",
	"tm_heavenfall": "tm_crown", "tm_thunder_break": "tm_fork", "tm_stormfall": "tm_storm",
	"travel_pack": "pack", "potion_small": "bottle_small",
	"potion_large": "bottle_large", "revive": "bottle_revive",
}
const IDENTITY_ORB := "res://assets/props/tm_orb/tm_orb.glb"
const IDENTITY_BOTTLE := "res://assets/props/stat_draughts/bottle_base.glb"
const IDENTITY_PACK := "res://assets/props/quaternius_fantasy/Bag.gltf"
const IDENTITY_BEDROLL := "res://assets/props/kenney_survival/bedroll-packed.glb"

## The ledger said no, with one sentence a player can act on and the machine tag
## behind it. The same surface `storage_container.gd::storage_refused` gives its
## own panel (lane 3.D): `ledger_claim.gd` already SHOWS the sentence, so nothing
## has to connect to this -- it exists so a caller that wants to know WHY (a
## test, or a future prompt that wants to say "somebody beat you to it" in its
## own voice) is not left reading HUD text.
signal claim_refused(code: String, reason: String)


var _item_id: String = ""
var _label: String = ""
var _model_path: String = ""
var _model_scale: float = 1.0
var _placement_id := ""
var _realm_id := "meadows"
var _count := 1
var _taken := false
var _visual: Node3D = null
var _presentation_anchor: Node3D = null
var _prompt: Node3D = null
## True between submitting a `claim_pickup` and hearing back. It is what tells
## "MY claim committed" from "somebody else's did" when the delta lands on both
## peers -- the only difference between the two is which player's satchel the
## ledger's own `item_grant` op was addressed to.
var _claiming := false


func setup(item_id: String, label: String, model_path: String, model_scale: float = 1.0,
		placement_id: String = "", realm_id: String = "meadows", count: int = 1) -> void:
	_item_id = item_id
	_label = label
	_model_path = model_path
	_model_scale = model_scale
	_placement_id = placement_id
	_realm_id = realm_id
	_count = maxi(1, count)
	PICKUP_SPECS.register(flag_id(_item_id, _placement_id, _realm_id), _item_id, _count)
	add_to_group("progression_restore")
	_build_visual()
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 0.6
	_prompt.call("configure", _label, 2.4, true)
	_prompt.connect("activated", _on_picked_up)
	add_child(_prompt)
	LEDGER_CLAIM.listen(self, _on_delta_applied)
	_listen_for_refusals()
	var game: Node = get_node_or_null(^"/root/Game") if is_inside_tree() else null
	if was_taken(game, _item_id, _placement_id, _realm_id):
		_deactivate()


## Keep main's public placement key and historic Meadows flag format.
## Non-Meadows locations are realm-qualified so stacked worlds stay isolated.
func _key() -> String:
	if _placement_id.is_empty():
		return _item_id
	return _placement_id if _realm_id == "meadows" else _realm_id + ":" + _placement_id


static func flag_id(item_id: String, placement_id: String = "", realm_id: String = "meadows") -> String:
	if not placement_id.is_empty():
		if realm_id == "meadows":
			return FLAG_PREFIX + placement_id
		return "%s%s:%s" % [FLAG_PREFIX, realm_id, placement_id]
	return FLAG_PREFIX + item_id


static func was_taken(game: Node, item_id: String, placement_id: String = "", realm_id: String = "meadows") -> bool:
	if game == null or item_id == "":
		return false
	var progression: RefCounted = game.get("progression")
	return progression != null and bool(progression.call("has", flag_id(item_id, placement_id, realm_id)))


func restore_progression_from_game(game: Node) -> void:
	if was_taken(game, _item_id, _placement_id, _realm_id):
		_deactivate()


func _deactivate() -> void:
	_taken = true
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.call("set_enabled", false)
	_detach_visual_glow()
	visible = false
	queue_free()


## Move presentation without moving the authored claim/interaction anchor.
## The unscaled emitter measures only the scaled item, excluding reward beams.
func set_visual_offset(offset: Vector3) -> void:
	if _visual == null or _taken or not offset.is_finite():
		return
	if _presentation_anchor == null:
		PICKUP_GLOW.detach(self)
		_presentation_anchor = Node3D.new()
		_presentation_anchor.name = "PickupPresentation"
		add_child(_presentation_anchor)
		_visual.reparent(_presentation_anchor, false)
		_presentation_anchor.tree_exiting.connect(_detach_visual_glow)
	_presentation_anchor.position = offset
	# Re-registering also marks the shared field dirty after a later offset.
	PICKUP_GLOW.attach(_presentation_anchor, _item_colour())


func _detach_visual_glow() -> void:
	PICKUP_GLOW.detach(self)
	if is_instance_valid(_presentation_anchor) and _presentation_anchor.is_inside_tree():
		PICKUP_GLOW.detach(_presentation_anchor)


## The find's own colour, from `data/items/items.json` -- the same source
## `key_pickup.gd::_item_colour()` reads, so two pickup props marking the same
## item can never disagree about what colour it is.
func _item_colour() -> Color:
	var game: Node = get_node_or_null(^"/root/Game") if is_inside_tree() else null
	if game == null:
		return Color(0.85, 0.72, 0.35)
	var items: RefCounted = game.get("items")
	return items.call("colour", _item_id) if items != null else Color(0.85, 0.72, 0.35)


## Same PackedScene-vs-Mesh branch harvest_node.gd::_build_visual() and
## props.gd::place() already use for this exact glTF pack -- a bare
## `load()` result assigned straight to `MeshInstance3D.mesh` type-fails
## silently on a multi-part scene.
func _build_visual() -> void:
	var game: Node = get_node_or_null(^"/root/Game") if is_inside_tree() else null
	var items: RefCounted = game.get("items") if game != null else null
	var definition: Dictionary = items.call("definition", _item_id) if items != null else {}
	if items == null and IDENTITY_STYLES.has(_item_id):
		var catalogue: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/items.json"))
		if catalogue is Dictionary:
			definition = (catalogue.get("items", {}) as Dictionary).get(_item_id, {}) as Dictionary
	_visual = create_identity_visual(_item_id, definition)
	if _visual == null and _model_path != "" and ResourceLoader.exists(_model_path):
		var resource: Resource = load(_model_path)
		if resource is PackedScene:
			var wrapper := Node3D.new()
			wrapper.add_child((resource as PackedScene).instantiate())
			wrapper.scale = Vector3.ONE * _model_scale
			_visual = wrapper
		elif resource is Mesh:
			var mesh := MeshInstance3D.new()
			mesh.mesh = resource as Mesh
			mesh.scale = Vector3.ONE * _model_scale
			_visual = mesh
	if _visual == null:
		var fallback := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.3
		fallback.mesh = box
		_visual = fallback
		push_warning("item_cache_pickup: '%s' did not load as a Mesh or PackedScene" % _model_path)
	add_child(_visual)

	# OP-0830-3. This used to carry an `OmniLight3D` of its own -- the
	# "short-range presence cue" tm_pickup.gd's header argues for, and the
	# reasoning was sound: a one-time find is met at dusk or in cover as often
	# as in the open. What was wrong with it is that it was THIS PROP'S answer.
	# Five pickup scripts each had a different one (or none), so whether a find
	# was visible depended on which script drew it, and the owner's report is
	# that most of them are not. It also does not scale: the world holds well
	# over a hundred pickups and OP-0830-6 is an open ROG performance defect, so
	# a light each is exactly the thing this lane's order rules out by name.
	#
	# Replaced by the shared highlight, which is two MultiMeshes for every
	# pickup in the game and rides ABOVE the grass canopy rather than trying to
	# out-shine it. The item's own colour still drives the tint, so a cache
	# still reads as its own find rather than as a generic marker.
	PICKUP_GLOW.attach(self, _item_colour())


## Pure presentation seam shared with TM and loose-item callers. Each call
## owns a fresh, unparented subtree, centred in X/Z and resting at Y=0, in
## metres. No Game lookup, claim, restore, highlight or harvest dependency.
## Missing installed art and unsupported records return null to the caller.
static func create_identity_visual(item_id: String, definition: Dictionary) -> Node3D:
	if not IDENTITY_STYLES.has(item_id):
		return null
	var style: String = IDENTITY_STYLES[item_id]
	var metadata: Dictionary = definition.get("world_identity", {}) as Dictionary
	var height := float(metadata.get("height_m", 0.40))
	var colour := Color(str(definition.get("colour", "#678ca0")))
	var accent := Color(str(metadata.get("accent_colour", "#d7bd77")))
	var root := Node3D.new()
	root.name = "ItemIdentity"
	var path := IDENTITY_ORB
	if style.begins_with("bottle"):
		path = IDENTITY_BOTTLE
	elif style == "pack":
		path = IDENTITY_PACK
	var body := _identity_scene(path, 0.30 if style != "pack" else 0.48)
	if body == null:
		root.free()
		return null
	root.add_child(body)
	var trim := _identity_material(accent)
	if style.begins_with("orb_"):
		_identity_tint(body, _identity_material(colour))
		if style != "orb_plain":
			_identity_ring(root, trim, Vector3(0.0, 0.15, 0.0), Vector3(PI * 0.5, 0.0, 0.0))
			_identity_ring(root, trim, Vector3(0.0, 0.15, 0.0), Vector3(0.0, 0.0, PI * 0.5))
		if style == "orb_sprung":
			_identity_ring(root, trim, Vector3(0.0, 0.15, 0.0), Vector3.ZERO)
			for side: float in [-1.0, 1.0]:
				_identity_box(root, trim, Vector3(0.055, 0.11, 0.075), Vector3(side * 0.16, 0.15, 0.0))
	elif style.begins_with("tm_"):
		_identity_tint(body, _identity_material(colour))
		# Move families have physical attachments, not just another core tint.
		match style:
			"tm_nozzle":
				var nozzle := CylinderMesh.new()
				nozzle.top_radius = 0.045
				nozzle.bottom_radius = 0.075
				nozzle.height = 0.20
				_identity_mesh(root, nozzle, trim, Vector3(0.0, 0.15, 0.17), Vector3(PI * 0.5, 0.0, 0.0))
			"tm_wings":
				for side: float in [-1.0, 1.0]:
					var wing := PrismMesh.new()
					wing.size = Vector3(0.20, 0.065, 0.14)
					_identity_mesh(root, wing, trim, Vector3(side * 0.19, 0.19, 0.0), Vector3(0.0, 0.0, side * 0.35))
			"tm_crown":
				_identity_ring(root, trim, Vector3(0.0, 0.26, 0.0), Vector3.ZERO)
				for x: float in [-0.11, 0.0, 0.11]:
					var point := CylinderMesh.new()
					point.top_radius = 0.0
					point.bottom_radius = 0.035
					point.height = 0.16 if x == 0.0 else 0.11
					_identity_mesh(root, point, trim, Vector3(x, 0.32, 0.0))
			"tm_fork":
				_identity_box(root, trim, Vector3(0.34, 0.045, 0.065), Vector3(0.0, 0.27, 0.0))
				for side: float in [-1.0, 1.0]:
					_identity_box(root, trim, Vector3(0.045, 0.15, 0.065), Vector3(side * 0.15, 0.33, 0.0))
			"tm_storm":
				for index: int in range(4):
					var angle := float(index) * PI * 0.5
					var fin := PrismMesh.new()
					fin.size = Vector3(0.09, 0.22, 0.16)
					_identity_mesh(root, fin, trim, Vector3(sin(angle) * 0.17, 0.21, cos(angle) * 0.17), Vector3(0.0, angle, 0.30))
	elif style == "pack":
		var roll := _identity_scene(IDENTITY_BEDROLL, 0.16)
		if roll == null:
			root.free()
			return null
		root.add_child(roll)
		roll.position = Vector3(0.0, 0.49, 0.0)
		var frame := _identity_material(Color("#796a48"))
		for side: float in [-1.0, 1.0]:
			_identity_box(root, frame, Vector3(0.035, 0.53, 0.035), Vector3(side * 0.15, 0.265, 0.14))
	else:
		# Keep the installed bottle's glass/cork materials. Solid collars and
		# embodied badges distinguish dose/restore without hiding the bottle.
		var dose := _identity_material(colour)
		_identity_ring(root, dose, Vector3(0.0, 0.12, 0.0), Vector3.ZERO, 0.11)
		if style == "bottle_large":
			_identity_ring(root, dose, Vector3(0.0, 0.19, 0.0), Vector3.ZERO, 0.12)
			_identity_box(root, trim, Vector3(0.16, 0.10, 0.025), Vector3(0.0, 0.155, 0.115))
		elif style == "bottle_revive":
			_identity_ring(root, trim, Vector3(0.0, 0.25, 0.0), Vector3.ZERO, 0.09)
			_identity_box(root, dose, Vector3(0.065, 0.19, 0.04), Vector3(0.0, 0.15, 0.12))
			_identity_box(root, dose, Vector3(0.19, 0.065, 0.04), Vector3(0.0, 0.15, 0.12))
	_identity_fit(root, height)
	return root


static func _identity_scene(path: String, height: float) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var scene := packed.instantiate()
	if not scene is Node3D:
		scene.free()
		return null
	var wrapper := Node3D.new()
	wrapper.add_child(scene)
	_identity_fit(wrapper, height)
	return wrapper


static func _identity_fit(root: Node3D, height: float) -> void:
	var bounds := AABB()
	var first := true
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var transform := mesh.transform
		var parent := mesh.get_parent()
		while parent != root and parent is Node3D:
			transform = (parent as Node3D).transform * transform
			parent = parent.get_parent()
		var local_bounds: AABB = transform * mesh.get_aabb()
		bounds = local_bounds if first else bounds.merge(local_bounds)
		first = false
	if first or bounds.size.y <= 0.0001:
		return
	var factor := clampf(height, 0.10, 1.0) / bounds.size.y
	var offset := Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z)
	for child: Node in root.get_children():
		if child is Node3D:
			var spatial := child as Node3D
			spatial.position = (spatial.position + offset) * factor
			spatial.scale *= factor


static func _identity_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.72
	return material


static func _identity_tint(root: Node3D, material: StandardMaterial3D) -> void:
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_override = material


static func _identity_mesh(root: Node3D, mesh: Mesh, material: Material, at: Vector3, rotation: Vector3 = Vector3.ZERO) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = at
	part.rotation = rotation
	root.add_child(part)


static func _identity_box(root: Node3D, material: Material, size: Vector3, at: Vector3) -> void:
	var box := BoxMesh.new()
	box.size = size
	_identity_mesh(root, box, material, at)


static func _identity_ring(root: Node3D, material: Material, at: Vector3, rotation: Vector3, radius: float = 0.165) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.018
	ring.outer_radius = radius + 0.018
	ring.rings = 16
	ring.ring_segments = 8
	_identity_mesh(root, ring, material, at, rotation)


## D103, Stage B lane 3.B. This used to grant the item and write the
## `cache:<id>` flag itself. Both are the ledger's now: a `claim_pickup` INTENT
## goes up, the host arbitrates it, and the committed delta carries the flag
## (world scope, every peer) and the `item_grant` (player scope, the one peer
## who won). Nothing here changes until that delta lands -- so two players
## reaching the same cache produce exactly one grant, and the loser sees the
## find simply stay where it is rather than a pickup that vanished and paid
## nothing.
##
## Solo is not a second path. `submit()` on a solo player is a host with nobody
## to tell: it commits in-process, emits the delta before it returns, and
## `_on_delta_applied()` below has already run by the time this function
## continues -- which is why `_taken` is re-checked rather than assumed.
##
## The satchel check stays HERE, before the intent. The host cannot see a
## client's satchel (`world_ledger.gd`'s header says so outright), so "is there
## room" is the one question only this peer can answer, and a full satchel must
## still refuse visibly rather than spending the world's only copy of a find.
func _on_picked_up() -> void:
	if _taken or _claiming:
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; a cache was found but has nowhere to go")
		return
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		push_error("no inventory; a cache was found but has nowhere to go")
		return
	if not bool(inventory.call("has_room_for", _item_id, _count)):
		# Refused, visibly, same as key_pickup.gd/harvest_node.gd: stays in
		# the world and keeps offering rather than vanishing into a full
		# satchel.
		game.call("push_world_message", "Satchel is full.")
		return
	_claiming = true
	var verdict := LEDGER_CLAIM.submit(self, {
		"kind": "claim_pickup",
		"realm": _realm_id,
		"flag": flag_id(_item_id, _placement_id, _realm_id),
		"item": _item_id,
		"count": _count,
	})
	if not LEDGER_CLAIM.in_flight(verdict):
		# A refusal we can act on now (`already_taken` from a race this peer
		# lost on the host, or an offline transport). `ledger_claim.gd::submit`
		# has already said the sentence; the find stays standing and keeps
		# offering.
		_claiming = false
		claim_refused.emit(str(verdict.get("code", "")), str(verdict.get("reason", "")))


## The committed delta. Host, client and solo all arrive here, which is the
## point: removal is driven by the delta, never by the intent, so a lost race
## looks like the pickup staying put and a won one looks exactly like it always
## did. The `item_grant` half was applied by `ledger_rpc.gd` before this fired.
func _on_delta_applied(delta: Dictionary) -> void:
	if not LEDGER_CLAIM.sets_world_flag(delta, flag_id(_item_id, _placement_id, _realm_id)):
		return
	# `_taken` is checked after the flag, not before it: on a client
	# `ledger_rpc.gd::_rpc_delta` runs the `progression_restore` sweep before it
	# emits `delta_applied`, so this node can already be deactivated by the time
	# we arrive and the claim still has to be closed out.
	_claiming = false
	if not _taken:
		_deactivate()


## A refusal that crossed the wire. A client's `submit()` only ever answers
## "pending", so `ledger_rpc.gd::intent_refused` is the ONLY way it hears
## `already_taken` -- and `_rpc_verdict` is addressed to the one peer whose
## intent it was, so a refusal arriving here is always ours. Gated on
## `_claiming` for the same reason `storage_container.gd` gates its own: only a
## node with a claim in flight has anything to drop.
func _on_intent_refused(kind: String, code: String, reason: String, _detail: Dictionary) -> void:
	if kind != "claim_pickup" or not _claiming:
		return
	_claiming = false
	claim_refused.emit(code, reason)


func _listen_for_refusals() -> void:
	var transport := LEDGER_CLAIM.transport(self)
	if transport == null:
		return
	if not transport.is_connected("intent_refused", _on_intent_refused):
		transport.connect("intent_refused", _on_intent_refused)


## The transport is an autoload child at an identical path in every process, so
## it is already there when this node enters the tree. Connected here as well as
## in `setup()` because a caller that sets the node up BEFORE adding it to the
## tree would otherwise never hear a delta at all -- `listen()` is idempotent.
func _ready() -> void:
	LEDGER_CLAIM.listen(self, _on_delta_applied)
	_listen_for_refusals()
	if _presentation_anchor != null and not _taken:
		PICKUP_GLOW.attach(_presentation_anchor, _item_colour())
