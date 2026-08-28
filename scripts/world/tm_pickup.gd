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
	_prompt.position = Vector3.UP * (DISC_CENTRE_Y + 0.34)
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
##     stand in open meadow. At `DISC_RADIUS` plus the plinth this reads about
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
const DISC_RADIUS := 0.24
const DISC_THICKNESS := 0.055
const PLINTH_HEIGHT := 0.16
const SPIN_DEGREES_PER_SECOND := 22.0

## How far the disc's centre sits above the prop's own origin.
const DISC_CENTRE_Y := PLINTH_HEIGHT + DISC_RADIUS + 0.12

var _spinner: Node3D = null


func _build_visual() -> void:
	var colour: Color = _tms.call("colour", _tm_id) if _tms != null else Color(0.6, 0.6, 0.6)

	# The disc face. Bright, self-lit, and the TM's own type colour.
	var face := StandardMaterial3D.new()
	face.albedo_color = colour
	face.metallic = 0.1
	face.roughness = 0.42
	face.emission_enabled = true
	face.emission = colour
	face.emission_energy_multiplier = 1.1

	# The rim and the plinth: the same stone value every other planted prop in
	# this project uses, deliberately NOT the type colour, so the disc reads as
	# an inset plate rather than the whole object being one flat tint.
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("#544c42")
	stone.metallic = 0.0
	stone.roughness = 0.9

	# The mark punched through the icon is a starburst; here it is raised
	# instead of cut, because a hole in a 5 cm disc is invisible at any
	# distance a player reads this from and a proud boss catches light.
	var mark := StandardMaterial3D.new()
	mark.albedo_color = Color(1.0, 0.97, 0.9)
	mark.emission_enabled = true
	mark.emission = colour.lightened(0.55)
	mark.emission_energy_multiplier = 1.9
	mark.roughness = 0.35

	var plinth := MeshInstance3D.new()
	plinth.name = "Plinth"
	var plinth_mesh := CylinderMesh.new()
	plinth_mesh.top_radius = 0.16
	plinth_mesh.bottom_radius = 0.22
	plinth_mesh.height = PLINTH_HEIGHT
	plinth.mesh = plinth_mesh
	plinth.material_override = stone
	plinth.position = Vector3.UP * (PLINTH_HEIGHT * 0.5)
	add_child(plinth)

	# Everything that turns hangs off this, so the plinth stays put.
	_spinner = Node3D.new()
	_spinner.name = "Disc"
	_spinner.position = Vector3.UP * DISC_CENTRE_Y
	add_child(_spinner)

	# A cylinder's axis is +Y; tipping it a quarter turn about X stands it on
	# edge like a coin, which is the icon's own silhouette.
	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = DISC_RADIUS
	disc_mesh.bottom_radius = DISC_RADIUS
	disc_mesh.height = DISC_THICKNESS
	disc.mesh = disc_mesh
	disc.material_override = face
	disc.rotation.x = deg_to_rad(90.0)
	_spinner.add_child(disc)

	# The rim groove the icon draws as a cut line, as real geometry.
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = DISC_RADIUS * 0.94
	torus.outer_radius = DISC_RADIUS * 1.12
	rim.mesh = torus
	rim.material_override = stone
	rim.rotation.x = deg_to_rad(90.0)
	_spinner.add_child(rim)

	# The slot glyph: a centre boss and four short radial spokes, on both faces
	# so the prop is not blank from behind as it turns.
	for side in [1.0, -1.0]:
		var boss := MeshInstance3D.new()
		var boss_mesh := CylinderMesh.new()
		boss_mesh.top_radius = 0.052
		boss_mesh.bottom_radius = 0.052
		boss_mesh.height = 0.03
		boss.mesh = boss_mesh
		boss.material_override = mark
		boss.rotation.x = deg_to_rad(90.0)
		boss.position = Vector3(0.0, 0.0, side * (DISC_THICKNESS * 0.5 + 0.012))
		_spinner.add_child(boss)

		for spoke_index in 4:
			var spoke := MeshInstance3D.new()
			var spoke_mesh := BoxMesh.new()
			spoke_mesh.size = Vector3(0.028, 0.115, 0.018)
			spoke.mesh = spoke_mesh
			spoke.material_override = mark
			spoke.rotation.z = deg_to_rad(45.0 + 90.0 * float(spoke_index))
			var angle := deg_to_rad(45.0 + 90.0 * float(spoke_index))
			spoke.position = Vector3(
				-sin(angle) * 0.13, cos(angle) * 0.13,
				side * (DISC_THICKNESS * 0.5 + 0.006))
			_spinner.add_child(spoke)

	# Presence at distance and in the dark. Short range on purpose: this is a
	# prop that says "here", not a light source the level is lit by.
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = colour
	glow.light_energy = 1.15
	glow.omni_range = 4.0
	glow.position = Vector3.UP * DISC_CENTRE_Y
	add_child(glow)

	set_process(true)


func _process(delta: float) -> void:
	if _spinner == null or not is_instance_valid(_spinner):
		set_process(false)
		return
	_spinner.rotate_y(deg_to_rad(SPIN_DEGREES_PER_SECOND) * delta)


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
