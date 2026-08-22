extends Node3D

## RG9, owner directive: "You shouldn't be able to gather a standing tree.
## You should have to chop it. Then it becomes downed wood. Then you gather
## that. Same for stone." This is the SECOND stage: what a chop
## (`vegetation_harvest_point.gd::_on_gathered()`, via `vegetation.gd::fell()`)
## stands where a tree or rock used to be. It is a plain pickup -- bare-handed,
## no tool gate, no durability -- because the tool already did its job at the
## chop. Gathering it is what actually pays the resource into the satchel.
##
## Visually the WOODPILE moved here from `vegetation_harvest_point.gd`, which
## used to build one on a still-standing tree (OW7's fix for "wood to pick up
## doesn't look like wood"). That reasoning belongs to the felled stage now: a
## living tree should not have a pile of cut logs sitting at its base, but
## downed wood on the ground is exactly what a pile of cut logs is. Stone gets
## a small rubble mound instead of the standing rock's own mesh -- the rock
## that WAS there is gone (`harvest_permanently()` removed it), so there is no
## "the rock itself" to stand on any more the way there was for the standing
## stage.
##
## RG10 (owner directive, superseding R2.3's glint entirely): no marker sits
## on this either. The pile/mound IS the affordance.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")
const HOME_PROGRESS := preload("res://scripts/build/home_progress.gd")

## OW7. The woodpile: three Kenney logs, already in the build and already
## ledgered for their log shapes (`water.gd` stands the same mesh on end for
## the jetty's pilings), so this adds no asset and joins no new family (D24).
##
## `log.glb` measures 0.234 x 0.173 x 0.710m and sits on its own y=0, lying
## along local Z. Two on the ground and one in the groove between them is the
## universally readable firewood stack, and at ~0.35m tall it is knee-high
## next to a 4-7m tree — present without competing with it.
const LOG_MODEL := "res://assets/environment/nature/log.glb"
## EXPEDITION-REST. Fiber's own felled form. Without this a cut bundle of plant
## fibre fell through to `_build_rubble()` and the player picked their cordage
## off a pile of grey stone chunks -- the same defect
## vegetation_harvest_point.gd's own header records for wood ("wood to pick up
## doesn't look like wood"), which took an owner playtest to catch the first
## time. Wheat rather than a generic grass tuft because the pickup is CUT
## material lying on the ground, not a plant still growing there.
const FIBER_MODEL := "res://assets/environment/stylized_nature/Grass_Wheat.gltf"
const LOG_RISE := 0.173

## The pack's logs ship untextured, as a pale cream on both surfaces — the
## same flat near-white that made `water.gd`'s pilings read as concrete posts
## until it tinted them. Bark and cut face are separate surfaces here, so they
## get separate colours rather than one override over both: the pale END
## GRAIN against dark bark is the cue that says sawn wood rather than branch
## litter, and it is the whole reason this reads as a resource. TUNABLE.
const BARK_COLOUR := Color("#5d452e")
const CUT_COLOUR := Color("#c2a172")

## No vendored "rubble" mesh exists (D24: no new asset family for one prop),
## so felled stone is a small cluster of primitive boulders in the stone
## layer's own tone rather than a fifth Meshy generation for one pickup.
## TUNABLE.
const RUBBLE_COLOUR := Color("#8a8a86")

var _item_id: String = ""
var _amount: int = 0
var _felled_key: String = ""
var _prompt: Node3D = null


func setup(spec: Dictionary) -> void:
	_item_id = str(spec.get("item", "wood"))
	_amount = int(spec.get("amount", 1))
	_felled_key = str(spec.get("felled_key", ""))

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 0.5
	_prompt.call("configure", "Pick up", 2.4, true)
	_prompt.connect("activated", _on_gathered)
	add_child(_prompt)

	add_child(_build_visual())


## Read-only identity for a controller route that must collect the specific
## pile it just created without reading a private backing field.
func resource_item() -> String:
	return _item_id


func resource_amount() -> int:
	return _amount


func _build_visual() -> Node3D:
	if _item_id == "wood":
		return _build_woodpile()
	if _item_id == "fiber":
		return _build_bundle()
	return _build_rubble()


## Built from the PackedScene the glTF actually imports as, never assigned
## straight to a `mesh` property: that is the OF20 trap, where every authored
## harvest node silently rendered nothing for weeks because a PackedScene
## assigned to a Mesh-typed property fails without raising anything.
func _build_woodpile() -> Node3D:
	var pile := Node3D.new()
	pile.name = "Woodpile"
	if not ResourceLoader.exists(LOG_MODEL):
		push_warning("log model %s missing; the felled wood stands on nothing" % LOG_MODEL)
		return pile
	var packed: PackedScene = load(LOG_MODEL) as PackedScene
	if packed == null:
		push_warning("log model %s did not load as a PackedScene; the felled wood stands on nothing" % LOG_MODEL)
		return pile

	var bearing := float(hash(position) & 0xFFFFFF) / float(0xFFFFFF) * TAU
	# Two logs on the ground either side of the centreline, one resting in the
	# groove between them. The small yaw offsets stop the stack reading as a
	# manufactured object -- these are logs somebody dropped, not a woodshed.
	for spec: Array in [
		[Vector3(-0.14, 0.0, 0.0), 0.0],
		[Vector3(0.15, 0.0, 0.03), 0.06],
		[Vector3(0.005, LOG_RISE, -0.02), -0.11],
	]:
		var log_node := packed.instantiate() as Node3D
		if log_node == null:
			continue
		log_node.transform = Transform3D(
			Basis(Vector3.UP, bearing + float(spec[1])),
			(spec[0] as Vector3).rotated(Vector3.UP, bearing)
		)
		_paint_wood(log_node)
		pile.add_child(log_node)
	# A woodpile's own shadow is what sets it on the ground rather than over
	# it -- the same rule vegetation.gd applies to its solid layers, and the
	# opposite of the one it applies to grass.
	for child: Node in _mesh_nodes(pile):
		(child as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return pile


## No vendored rubble/broken-stone mesh exists anywhere in the build (D24), so
## this stands in with three small `BoxMesh` chunks, irregularly scaled and
## yawed -- an honest placeholder shape rather than a fifth Meshy generation
## for one pickup. RG11 ("stones look like white paper") is the item that owns
## whether stone reads well at all; this only needs to say "there is a
## resource here", the same bar `harvest_node.gd::_box_visual()` sets for its
## own no-model fallback.
## A cut bundle: three stooks leaned together, same PackedScene discipline as
## `_build_woodpile` (never assign the glTF straight to a `mesh` property --
## that is the OF20 trap this file's woodpile comment records). Falls back to
## rubble if the model is missing, so a bad asset path degrades to something
## visible rather than to nothing at all.
func _build_bundle() -> Node3D:
	if not ResourceLoader.exists(FIBER_MODEL):
		push_warning("fiber model %s missing; the felled fiber falls back to rubble" % FIBER_MODEL)
		return _build_rubble()
	var packed: PackedScene = load(FIBER_MODEL) as PackedScene
	if packed == null:
		push_warning("fiber model %s did not load as a PackedScene; falling back to rubble" % FIBER_MODEL)
		return _build_rubble()

	var bundle := Node3D.new()
	bundle.name = "FiberBundle"
	var bearing := float(hash(position) & 0xFFFFFF) / float(0xFFFFFF) * TAU
	# Leaned in against each other rather than stood upright: cut stalks that
	# somebody set down, which is what this pickup is.
	for spec: Array in [
		[Vector3(-0.12, 0.0, 0.02), 0.22, 0.0],
		[Vector3(0.13, 0.0, -0.04), -0.19, 1.9],
		[Vector3(0.0, 0.0, 0.11), 0.08, 3.7],
	]:
		var stook := packed.instantiate() as Node3D
		if stook == null:
			continue
		stook.position = (spec[0] as Vector3).rotated(Vector3.UP, bearing)
		stook.rotation = Vector3(float(spec[1]), bearing + float(spec[2]), 0.0)
		stook.scale = Vector3.ONE * 0.75
		bundle.add_child(stook)
	return bundle


func _build_rubble() -> Node3D:
	var mound := Node3D.new()
	mound.name = "Rubble"
	var material := StandardMaterial3D.new()
	material.albedo_color = RUBBLE_COLOUR
	material.roughness = 0.95
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED

	var bearing := float(hash(position) & 0xFFFFFF) / float(0xFFFFFF) * TAU
	for spec: Array in [
		[Vector3(-0.10, 0.0, 0.02), Vector3(0.22, 0.16, 0.20), 0.0],
		[Vector3(0.11, 0.0, -0.05), Vector3(0.18, 0.13, 0.16), 0.7],
		[Vector3(0.01, 0.10, 0.06), Vector3(0.14, 0.11, 0.13), 1.4],
	]:
		var chunk := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = spec[1]
		chunk.mesh = box
		chunk.material_override = material
		chunk.position = (spec[0] as Vector3).rotated(Vector3.UP, bearing)
		chunk.rotation = Vector3(0.15, bearing + float(spec[2]), 0.1)
		chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mound.add_child(chunk)
	return mound


## Bark on one surface, sawn end grain on the other, per surface rather than
## with a `material_override` -- an override replaces the material on EVERY
## surface at once, which would flatten the cut faces back into the bark and
## throw away the only cue that says this wood was worked.
func _paint_wood(root: Node) -> void:
	for node: Node in _mesh_nodes(root):
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var material := StandardMaterial3D.new()
			var source := mesh.surface_get_material(surface) as StandardMaterial3D
			# The pack marks bark and cut face only by albedo, and the bark is
			# the darker of the two. Reading the source rather than assuming an
			# index keeps this correct if the kit reorders its surfaces.
			var is_cut := source != null and source.albedo_color.get_luminance() > 0.9
			material.albedo_color = CUT_COLOUR if is_cut else BARK_COLOUR
			material.roughness = 0.92
			material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			instance.set_surface_override_material(surface, material)


func _mesh_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			out.append(node)
		for child in node.get_children():
			stack.append(child)
	return out


## Bare-handed, always -- the tool already gated the CHOP that stood this
## pickup here (`vegetation_harvest_point.gd::_on_gathered()`). A full
## satchel refuses visibly: the pile stays and keeps offering, the same
## "your satchel is full" pattern every other gather point in the game uses.
func _on_gathered() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; gathered %s into nothing" % _item_id)
		return
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		return
	if not bool(inventory.call("has_room_for", _item_id, _amount)):
		return
	inventory.call("add", _item_id, _amount)
	# Owner feedback: the pickup must visibly say what entered the satchel. Use
	# Game's existing one-shot world-message seam so gathering does not reach
	# into a HUD node directly.
	var items: RefCounted = game.get("items")
	var item_name := str(items.call("item_name", _item_id)) if items != null else _item_id.capitalize()
	game.call("push_world_message", "+%d %s" % [_amount, item_name])
	# GATEB-FLAGS: `home_materials_gathered` -- felled wood/stone piles are the
	# main way the satchel actually fills for the tutorial home, same check as
	# harvest_node.gd's own gather completion.
	HOME_PROGRESS.maybe_set_materials_gathered(game)

	var vegetation := get_parent()
	if vegetation != null and vegetation.has_method("clear_felled") and not _felled_key.is_empty():
		vegetation.call("clear_felled", _felled_key)
	queue_free()


func _ready() -> void:
	# So a tool swing can find this without knowing which of the harvest
	# scripts drew it (`harvest_logic.gd::GROUP`) -- the same convention the
	# standing point and the authored tutorial spots both already follow.
	add_to_group(HARVEST_LOGIC.GROUP)


## Gather this pickup, the same as pressing the interact prompt on it.
##
## Public so a tool swing (`scripts/player/tool_hold.gd`) can drive the exact
## same path the prompt drives -- one gather implementation, two ways to
## reach it, matching `vegetation_harvest_point.gd`/`harvest_node.gd`'s own
## `gather()`.
func gather(_equipped_tool: Variant = null) -> void:
	_on_gathered()
