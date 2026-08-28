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
	_prompt.position = Vector3.UP * 0.5
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
	visible = false
	queue_free()


## A flat standing tablet, not key_pickup.gd's dropped-key shaft-and-ring --
## a TM is found knowledge, not a found object with a hand-holdable shape,
## so it reads better as something planted upright than something lying on
## the ground. Emissive for the same reason key_pickup.gd's key is: the
## Compatibility renderer's flat ambient leaves a purely-diffuse small prop
## unreadable at a distance (see that file's own material comment).
## TM-ORB asset paths and scale. The board's own scale note is 18-22cm; 0.20
## is the middle of it. The generated mesh measures ~1.899m across its
## bounding box, so the ratio below is what brings it to game scale -- stated
## as a measured source diameter rather than a magic number, so a re-export at
## a different scale is one edit.
const ORB_MESH_PATH := "res://assets/props/tm_orb/tm_orb.glb"
const ORB_SHELL_PATH := "res://assets/props/tm_orb/tm_orb_shell.png"
const ORB_EMISSIVE_MASK_PATH := "res://assets/props/tm_orb/tm_orb_emissive_mask.png"
const ORB_DIAMETER_M := 0.20
const ORB_SOURCE_DIAMETER_M := 1.899
const ORB_EMISSION_ENERGY := 1.6


func _build_visual() -> void:
	var colour: Color = _tms.call("colour", _tm_id) if _tms != null else Color(0.6, 0.6, 0.6)

	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.metallic = 0.05
	material.roughness = 0.5
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 0.9

	# TM-ORB, 2026-08-28. This was two BoxMeshes -- a 4cm slab with a 1cm rune
	# stuck to its face -- which is exactly what the owner's playtest called
	# "cardboard cards". Replaced with the orb generated from their reference
	# board (docs/art/reference/tm_orb_board.png, ledger entry in
	# docs/ASSET_LEDGER.md).
	#
	# ONE MESH, TEN MATERIALS. `tm_db.colour()` already returns a colour per
	# TM, and the board draws the ten type variants as hue swaps over one
	# body, so the mesh is shared and only the material differs -- the same
	# economy character_model.gd uses for villager palettes.
	#
	# The shell map has the core texels neutralised to greyscale and the core
	# rides the emissive mask, so tinting the core CANNOT drag the stone and
	# brass with it. Tinting the generated albedo directly would have.
	# A .glb imports as a PackedScene, NOT a Mesh. Assigning the loaded
	# resource straight to MeshInstance3D.mesh type-fails and renders
	# nothing at all -- silently, with no error in a release build. Found by
	# rendering this and getting an empty frame, which is why it is a
	# comment and not a bug.
	var orb: Node3D = null
	var packed: PackedScene = load(ORB_MESH_PATH) as PackedScene
	if packed != null:
		orb = packed.instantiate() as Node3D
	if orb == null:
		# Degrade to the old plain shape rather than to an invisible pickup.
		var fallback := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = ORB_DIAMETER_M * 0.5
		sphere.height = ORB_DIAMETER_M
		fallback.mesh = sphere
		fallback.material_override = _orb_material(colour)
		fallback.position = Vector3.UP * (ORB_DIAMETER_M * 0.5)
		add_child(fallback)
		push_warning("tm_pickup: %s did not load as a PackedScene" % ORB_MESH_PATH)
		return
	# The material rides on the instantiated MeshInstance3D children rather
	# than on the parent: material_override on a Node3D does nothing.
	var mat := _orb_material(colour)
	for child in orb.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = mat
	# The board's scale note is 18-22cm; the generated mesh measures 1.8998m
	# across its AABB, so it is scaled rather than trusted.
	orb.scale = Vector3.ONE * (ORB_DIAMETER_M / ORB_SOURCE_DIAMETER_M)
	orb.position = Vector3.UP * (ORB_DIAMETER_M * 0.5)
	add_child(orb)


## The orb's material: pale stone and brass from the shell map, with the type
## colour confined to the emissive core.
##
## `material` above is left as it was and is no longer used for the body --
## it stays because the fallback path below still wants a plain tinted
## material when the generated textures are missing.
func _orb_material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var shell: Texture2D = load(ORB_SHELL_PATH) if ResourceLoader.exists(ORB_SHELL_PATH) else null
	if shell == null:
		# Degrade to a tinted sphere rather than to nothing. An absent texture
		# should look plain, not invisible.
		mat.albedo_color = colour
		mat.metallic = 0.05
		mat.roughness = 0.5
		mat.emission_enabled = true
		mat.emission = colour
		mat.emission_energy_multiplier = 0.9
		return mat
	mat.albedo_texture = shell
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.metallic = 0.0
	mat.roughness = 0.8
	var mask: Texture2D = load(ORB_EMISSIVE_MASK_PATH) if ResourceLoader.exists(ORB_EMISSIVE_MASK_PATH) else null
	if mask != null:
		# The mask is the board's "emissive intensity (dynamic)" channel: the
		# generated glTF ships NO emissive at all -- its glow is painted into
		# albedo -- so this is authored rather than imported.
		mat.emission_enabled = true
		mat.emission_texture = mask
		mat.emission = colour
		mat.emission_energy_multiplier = ORB_EMISSION_ENERGY
		# MULTIPLY, not the default ADD. Godot's spatial shader computes
		# ADD as (emission + emission_tex) * energy, so the emission COLOUR
		# is emitted over the whole mesh and the texture only adds on top --
		# the mask gates nothing. Rendered as a green orb with a white core
		# before this line existed. MULTIPLY makes the mask what decides
		# where the colour appears, which is the point of having one.
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
