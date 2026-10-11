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
	if _model_path != "" and ResourceLoader.exists(_model_path):
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


## Padded Helm's icon/canon: a stitched fiber crown, open underneath.
## Fresh presentation only; dispatch, pickup claims and highlighting belong
## to the existing factory/caller. All dimensions are local metres.
static func _create_padded_helm(definition: Dictionary) -> Node3D:
	var cfg: Dictionary = definition.get("world_identity", {})
	var rx := clampf(float(cfg.get("radius_x_m", 0.14)), 0.05, 0.5)
	var rz := clampf(float(cfg.get("radius_z_m", 0.13)), 0.05, 0.5)
	var height := clampf(float(cfg.get("crown_height_m", 0.145)), 0.05, 0.5)
	var lining := clampf(float(cfg.get("lining_thickness_m", 0.009)), 0.002, minf(rx, minf(rz, height)) * 0.25)
	var brim := clampf(float(cfg.get("brim_radius_m", 0.012)), 0.003, 0.04)
	var drop := clampf(float(cfg.get("strap_drop_m", 0.11)), 0.03, 0.3)
	var strap_width := clampf(float(cfg.get("strap_width_m", 0.016)), 0.005, 0.04)
	var strap_thickness := clampf(float(cfg.get("strap_thickness_m", 0.005)), 0.002, 0.015)
	var seam_radius := clampf(float(cfg.get("seam_radius_m", 0.003)), 0.001, 0.008)
	var stitch_width := clampf(float(cfg.get("stitch_width_m", 0.012)), 0.004, 0.025)
	var segments := clampi(int(cfg.get("radial_segments", 32)), 12, 48)
	var rings := clampi(int(cfg.get("crown_rings", 10)), 4, 16)
	var stitches := clampi(int(cfg.get("stitch_count", 9)), 3, 16)
	var cloth := _padded_helm_material(Color(str(definition.get("colour", "#7a5a35"))))
	var inner := _padded_helm_material(Color(str(cfg.get("lining_colour", "#433425"))))
	var padding := _padded_helm_material(Color(str(cfg.get("padding_colour", "#a48756"))))
	var thread := _padded_helm_material(Color(str(cfg.get("stitch_colour", "#d1b982"))))
	var strap := _padded_helm_material(Color(str(cfg.get("strap_colour", "#634b30"))))
	var root := Node3D.new()
	root.name = "PaddedHelmIdentity"
	# Two ellipsoidal surfaces make a real hollow crown. The rolled edge
	# joins their lower rims; neither surface fills the opening with a head.
	_padded_helm_mesh(root, _padded_helm_crown(rx, rz, height, segments, rings, false), cloth, Vector3.UP * drop)
	_padded_helm_mesh(root, _padded_helm_crown(rx - lining, rz - lining, height - lining, segments, rings, true), inner, Vector3.UP * drop)
	var rim := TorusMesh.new()
	rim.inner_radius = 1.0 - brim / rx
	rim.outer_radius = 1.0 + brim / rx
	rim.rings = segments
	rim.ring_segments = 8
	var rim_node := _padded_helm_mesh(root, rim, padding, Vector3.UP * drop)
	rim_node.scale = Vector3(rx, rx, rz)
	# Raised central seam follows the dome from front to back. The short
	# stitches cross it and remain geometry when the cap is seen obliquely.
	var seam_points: Array[Vector3] = []
	for index: int in range(rings * 2 + 1):
		var angle := PI * float(index) / float(rings * 2)
		seam_points.append(Vector3(0.0, drop + (height + seam_radius) * sin(angle), (rz + seam_radius) * cos(angle)))
	for index: int in range(seam_points.size() - 1):
		_padded_helm_join(root, padding, seam_points[index], seam_points[index + 1], seam_radius)
	for index: int in range(stitches):
		var angle := PI * float(index + 1) / float(stitches + 1)
		var at := Vector3(0.0, drop + (height + seam_radius * 2.0) * sin(angle), (rz + seam_radius * 2.0) * cos(angle))
		_padded_helm_join(root, thread, at - Vector3.RIGHT * stitch_width * 0.5, at + Vector3.RIGHT * stitch_width * 0.5, seam_radius * 0.5)
	# A narrow cloth chin strap hangs clear of the opening, rather than a
	# solid neck/base that would make this read as a mannequin head.
	var strap_points: Array[Vector3] = [Vector3(-rx * 0.92, drop, 0.0), Vector3(-rx * 0.84, drop * 0.3, 0.0),
		Vector3(-rx * 0.55, strap_thickness, 0.0), Vector3(rx * 0.55, strap_thickness, 0.0),
		Vector3(rx * 0.84, drop * 0.3, 0.0), Vector3(rx * 0.92, drop, 0.0)]
	for index: int in range(strap_points.size() - 1):
		var from := strap_points[index]
		var to := strap_points[index + 1]
		var strip := BoxMesh.new()
		strip.size = Vector3(strap_thickness, from.distance_to(to) + strap_thickness, strap_width)
		var part := _padded_helm_mesh(root, strip, strap, (from + to) * 0.5)
		part.basis = Basis(Quaternion(Vector3.UP, (to - from).normalized()))
	# Use local bounds: this API also serves callers before tree admission.
	var bounds := AABB()
	var first := true
	for child: MeshInstance3D in root.get_children():
		var local: AABB = child.transform * child.mesh.get_aabb()
		bounds = local if first else bounds.merge(local)
		first = false
	var shift := Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z)
	for child: Node3D in root.get_children(): child.position += shift
	return root


static func _padded_helm_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.95
	material.metallic = 0.0
	return material


static func _padded_helm_mesh(root: Node3D, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = at
	root.add_child(part)
	return part


static func _padded_helm_join(root: Node3D, material: Material, from: Vector3, to: Vector3, radius: float) -> void:
	var cord := CylinderMesh.new()
	cord.top_radius = radius
	cord.bottom_radius = radius
	cord.height = from.distance_to(to) + radius
	cord.radial_segments = 6
	cord.rings = 1
	var part := _padded_helm_mesh(root, cord, material, (from + to) * 0.5)
	part.basis = Basis(Quaternion(Vector3.UP, (to - from).normalized()))


static func _padded_helm_crown(rx: float, rz: float, height: float, segments: int, rings: int, inside: bool) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for ring: int in range(rings + 1):
		var latitude := PI * 0.5 * float(ring) / float(rings)
		for segment: int in range(segments + 1):
			var longitude := TAU * float(segment) / float(segments)
			var vertex := Vector3(rx * sin(latitude) * cos(longitude), height * cos(latitude), rz * sin(latitude) * sin(longitude))
			vertices.append(vertex)
			var normal := Vector3(vertex.x / (rx * rx), vertex.y / (height * height), vertex.z / (rz * rz)).normalized()
			normals.append(-normal if inside else normal)
			uv.append(Vector2(float(segment) / float(segments), float(ring) / float(rings)))
	for ring: int in range(rings):
		for segment: int in range(segments):
			var a := ring * (segments + 1) + segment
			var b := a + segments + 1
			var face := PackedInt32Array([a, b, b + 1])
			if ring > 0: face.append_array(PackedInt32Array([a, b + 1, a + 1]))
			if inside: face.reverse()
			indices.append_array(face)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
