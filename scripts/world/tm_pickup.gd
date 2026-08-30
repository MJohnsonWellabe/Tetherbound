extends Node3D

## A TM sitting in the world, picked up into the satchel.
##
## R4.4 originally argued the opposite: GAME_DESIGN.md 13's "not consumed
## after one teaching" was read as "a TM is permanent knowledge, not an
## object", so this set a `tm:<id>` progression flag and vanished. OF29
## overrules that on the owner's own words -- "I can pick up a TM but it needs
## to go in my inventory and then I see it's stats and choose who to teach it
## to." A thing you inspect and then spend on ONE creature is an item, not a
## flag, and there is nowhere but the satchel for an item to live. So this is
## now exactly key_pickup.gd's contract: `inventory.add`, and a full satchel
## REFUSES -- the prop stays in the world, still offering, rather than
## deleting a find the player cannot carry yet.
##
## The `tm:<id>` flag survives, with a narrower job: "this world pickup has
## been taken". `playground_world.gd::_place_tms()` reads it and skips
## placing an already-taken TM, which is what stops a reload from minting a
## fresh copy now that the pickup grants a real item. Old saves carrying that
## flag from before OF29 therefore keep their TM prop gone and get no free
## item -- see that function's own comment for the migration note.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")
const TM_DB := preload("res://scripts/creatures/tm_db.gd")

## progression_state flag ids for TMs live in this namespace so a TM id and
## an unrelated objective/completion flag can never collide in the one flat
## store SB9 documents. Set once the pickup is actually taken (OF29: "taken
## from the world", no longer "this move is teachable forever").
const FLAG_PREFIX := "tm:"

## A `kind: "tm"` item id is the SAME string as its data/moves/tms.json id
## (see items.json's own `_comment_tm`), so this prop hands `_tm_id` straight
## to the satchel with no mapping table to keep in step -- and
## tests/test_moves.gd asserts the two files agree in both directions.

var _tm_id: String = ""
var _tms: RefCounted = null
var _prompt: Node3D = null


func setup(tm_id: String) -> void:
	_tm_id = tm_id
	add_to_group("progression_restore")
	_tms = TM_DB.load_default()
	_build_visual()

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * (ORB_CENTRE_Y + 0.34)
	_prompt.call("configure", "Learn %s" % str(_tms.call("display_name", _tm_id)), 2.4, true)
	_prompt.connect("activated", _on_picked_up)
	add_child(_prompt)
	var game := get_node_or_null(^"/root/Game")
	if was_taken(game, _tm_id):
		_deactivate()


static func was_taken(game: Node, tm_id: String) -> bool:
	if game == null or tm_id == "":
		return false
	var progression: RefCounted = game.get("progression")
	return progression != null and bool(progression.call("has", FLAG_PREFIX + tm_id))


func restore_progression_from_game(game: Node) -> void:
	if was_taken(game, _tm_id):
		_deactivate()


func _deactivate() -> void:
	# Disable immediately; queue_free alone leaves one actionable frame.
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.call("set_enabled", false)
	PICKUP_GLOW.detach(self)
	visible = false
	queue_free()


## CONTENT-0828. Owner, after playing the shipped build: **"tms look awful."**
##
## What stood here was a 0.32 x 0.46 x 0.04 m flat box with a 0.16 m WHITE BOX
## stuck to its front as a "rune" -- two untextured primitives, knee high, in a
## world where the warrens' own rootstone deposits were given real rocks for
## exactly this complaint and `key_pickup.gd` has been through four blind
## rounds of shape, metallic, emission and size work. It was the last
## unaddressed placeholder on the world's pickup list.
##
## The specific defect, though, is not "primitive" -- everything here is
## primitive and that is the house style. It is that **the world prop and the
## icon were not the same object.** `tools/gen_item_icons.py::_icon_tm` draws a
## TM as a keyed DISC: a circle with a flat chord off the bottom, a rim groove
## and the taught move's own slot glyph punched through the middle. The satchel
## shows a disc, the shop row shows a disc, the detail panel shows a disc --
## and the thing the player actually walked up to and pressed a button on was a
## rectangle. So this is now the icon, built in three dimensions: a disc
## standing on edge in a rim, stamped with the same radial mark, on a small
## plinth so it is planted rather than floating.
##
## The lessons the other pickups already paid for are reused rather than
## re-learned:
##
##   * LOW metallic, real emission. `key_pickup.gd`'s own comment records why
##     -- a high-metallic StandardMaterial3D gets nearly all its colour from
##     specular environment reflection, which the Compatibility renderer's flat
##     ambient cannot supply, so it goes dark everywhere but the one facet
##     catching the sun. The disc's `colour` comes from `data/moves/tms.json`
##     (already per-TM, already tuned by type) and has to survive as diffuse.
##   * Size. The old prop was 0.46 m tall and two of the five TMs in the world
##     stand in open meadow. At the orb's diameter plus the plinth this reads about
##     0.8 m -- a waist-high marker, the same register as a signpost, which is
##     what a piece of found knowledge planted in the world should be.
##   * A light of its own, not just emission. `tm_earthshatter` and the
##     warrens-adjacent finds are met in shadow or at dusk; emission alone
##     paints the mesh but throws nothing, so the prop has no presence until
##     the player is already on top of it.
##
## The slow spin is the one thing here that is not borrowed. It is deliberate
## and it is what a static prop cannot do: at the distance where a player
## decides whether to walk over, a turning disc is the only cue that survives
## when the silhouette is 20 px wide. Five TM props exist in the whole world
## (`playground_world.gd::TM_AT`), so this is five rotation writes a frame.
## TM-ORB, 2026-08-28. The owner supplied a reference board and directed the
## generation (docs/art/reference/tm_orb_board.png, ledger entry in
## docs/ASSET_LEDGER.md), so the disc this file built is superseded by an orb.
##
## What the disc version got RIGHT is kept, because it was paid for and none of
## it is about the shape: the plinth, the slow spin, the short-range light, and
## the reasoning behind each. See the header above -- it is that lane's, and it
## still applies word for word to a sphere.
##
## Scale is the one number that changed with the shape. The board's own note is
## 18-22cm, which is the object's size in the fiction; a 20cm ball lying in the
## grass is a 20cm ball nobody finds, and the owner has separately reported
## creatures being lost in this same grass. So the orb is board-sized and
## PLINTHED, which is also how the board's own "Vendor / Display" panel draws
## it -- the object stays 20cm and the assembly reads waist-high.
const ORB_MESH_PATH := "res://assets/props/tm_orb/tm_orb.glb"
const ORB_SHELL_PATH := "res://assets/props/tm_orb/tm_orb_shell.png"
const ORB_EMISSIVE_MASK_PATH := "res://assets/props/tm_orb/tm_orb_emissive_mask.png"
const ORB_DIAMETER_M := 0.20
## Measured off the generated mesh's AABB (1.8998 x 1.9012 x 1.8607), stated
## rather than hidden as a magic ratio so a re-export at another scale is one
## edit.
const ORB_SOURCE_DIAMETER_M := 1.899
const ORB_EMISSION_ENERGY := 1.6
const PLINTH_HEIGHT := 0.16
const SPIN_DEGREES_PER_SECOND := 22.0
## Eye height for the assembly: plinth, then the orb sitting proud of it.
const ORB_CENTRE_Y := PLINTH_HEIGHT + ORB_DIAMETER_M * 0.5 - 0.02


var _spinner: Node3D = null


func _build_visual() -> void:
	var colour: Color = _tms.call("colour", _tm_id) if _tms != null else Color(0.6, 0.6, 0.6)

	# The plinth, unchanged from the disc version: the same stone value every
	# other planted prop uses, deliberately NOT the type colour, so the orb
	# reads as an object set on something rather than one flat tint.
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("#544c42")
	stone.metallic = 0.0
	stone.roughness = 0.9

	var plinth := MeshInstance3D.new()
	var plinth_mesh := CylinderMesh.new()
	plinth_mesh.top_radius = ORB_DIAMETER_M * 0.62
	plinth_mesh.bottom_radius = ORB_DIAMETER_M * 0.78
	plinth_mesh.height = PLINTH_HEIGHT
	plinth.mesh = plinth_mesh
	plinth.material_override = stone
	plinth.position = Vector3.UP * (PLINTH_HEIGHT * 0.5)
	add_child(plinth)

	_spinner = Node3D.new()
	_spinner.name = "Orb"
	_spinner.position = Vector3.UP * ORB_CENTRE_Y
	add_child(_spinner)

	# A .glb imports as a PackedScene, NOT a Mesh. Assigning the loaded
	# resource straight to MeshInstance3D.mesh type-fails and renders nothing
	# at all, silently -- found by rendering this and getting empty background.
	var orb: Node3D = null
	var packed: PackedScene = load(ORB_MESH_PATH) as PackedScene
	if packed != null:
		orb = packed.instantiate() as Node3D
	if orb == null:
		# Degrade to a plain tinted sphere rather than to an invisible pickup.
		var fallback := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = ORB_DIAMETER_M * 0.5
		sphere.height = ORB_DIAMETER_M
		fallback.mesh = sphere
		fallback.material_override = _orb_material(colour)
		_spinner.add_child(fallback)
		push_warning("tm_pickup: %s did not load as a PackedScene" % ORB_MESH_PATH)
	else:
		# material_override on the parent Node3D does nothing; it has to go on
		# the instantiated MeshInstance3D children.
		var mat := _orb_material(colour)
		for child in orb.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).material_override = mat
		orb.scale = Vector3.ONE * (ORB_DIAMETER_M / ORB_SOURCE_DIAMETER_M)
		_spinner.add_child(orb)

	# Presence at distance and in the dark, kept verbatim from the disc
	# version. Short range on purpose: this is a prop that says "here", not a
	# light source the level is lit by. Emission alone paints the mesh and
	# throws nothing under the Compatibility renderer, so without this the
	# prop has no presence until the player is already on top of it.
	# OP-0830-3. The header above argues for "a light of its own, not just
	# emission", and the argument was right about the PROBLEM -- emission paints
	# the mesh and throws nothing, so the prop had no presence until the player
	# was on top of it. It was wrong about the instrument. An `OmniLight3D` per
	# pickup does not survive contact with a world holding well over a hundred
	# of them under an open ROG performance defect (OP-0830-6), and it was one
	# of five different answers to the same question across five pickup scripts,
	# which is why the owner's report is that most world items do not read at
	# all.
	#
	# The shared highlight replaces it and keeps what the light was for: the
	# TM's own type colour, presence from a distance, and no dependence on the
	# Compatibility renderer's ambient. `height_override` puts the mote over the
	# plinth-and-orb assembly rather than over the ground it stands on.
	PICKUP_GLOW.attach(self, colour, ORB_CENTRE_Y + 0.95)

	set_process(true)


func _process(delta: float) -> void:
	if _spinner == null or not is_instance_valid(_spinner):
		set_process(false)
		return
	_spinner.rotate_y(deg_to_rad(SPIN_DEGREES_PER_SECOND) * delta)


## The orb's material: pale stone and brass from the shell map, with the TM's
## type colour confined to the emissive core.
func _orb_material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var shell: Texture2D = load(ORB_SHELL_PATH) if ResourceLoader.exists(ORB_SHELL_PATH) else null
	if shell == null:
		mat.albedo_color = colour
		mat.metallic = 0.05
		mat.roughness = 0.5
		mat.emission_enabled = true
		mat.emission = colour
		mat.emission_energy_multiplier = 0.9
		return mat
	mat.albedo_texture = shell
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	# LOW metallic, as the disc version's header argues: a high-metallic
	# StandardMaterial3D takes nearly all its colour from specular environment
	# reflection, which this renderer's flat ambient cannot supply, so it goes
	# dark everywhere but the facet catching the sun.
	mat.metallic = 0.0
	mat.roughness = 0.8
	var mask: Texture2D = load(ORB_EMISSIVE_MASK_PATH) if ResourceLoader.exists(ORB_EMISSIVE_MASK_PATH) else null
	if mask != null:
		mat.emission_enabled = true
		mat.emission_texture = mask
		mat.emission = colour
		mat.emission_energy_multiplier = ORB_EMISSION_ENERGY
		# MULTIPLY, not the default ADD. Godot computes ADD as
		# (emission + emission_tex) * energy, so the colour is emitted over the
		# WHOLE mesh and the texture only adds on top -- the mask gates
		# nothing. Rendered as a uniformly green orb with a blown-out core
		# before this line.
		mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	return mat


func _on_picked_up() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; a TM was found but has nowhere to go")
		return
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		push_error("no inventory; a TM was found but has nowhere to go")
		return
	if not bool(inventory.call("has_room_for", _tm_id, 1)):
		# Refused, visibly, same as key_pickup.gd/harvest_node.gd: the disc
		# stays planted and keeps offering rather than vanishing into a full
		# satchel. The flag below is deliberately NOT set on this path -- a
		# TM that is still in the world must not be recorded as taken.
		game.call("push_world_message", "Satchel is full.")
		return
	inventory.call("add", _tm_id, 1)
	var progression: RefCounted = game.get("progression")
	if progression != null:
		progression.call("set_flag", FLAG_PREFIX + _tm_id)
	_deactivate()
