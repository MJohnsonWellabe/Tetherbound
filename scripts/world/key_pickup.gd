extends Node3D

## A one-time physical pickup: an item sitting on the ground that joins the
## satchel and never comes back. Same shape as harvest_node.gd (a visible
## prop, an interact prompt, an item) minus the respawn timer — a harvest
## node is a renewable resource, a found key is neither, and its item id
## consuming itself (`road_gate.gd::_on_tried`) is what removes it from play,
## not this script.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
## OP-0830-3: the one shared pickup highlight. See scripts/world/pickup_glow.gd.
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")

const FLAG_PREFIX := "pickup:"
## Compatibility for saves written before physical pickups recorded their own
## flags: consuming this key wrote the gate's durable flag instead.
const ROAD_GATE_OPEN_FLAG := "road_gate_open"

var _item_id: String = ""
var _label: String = ""
var _shape: String = "key"
var _visual: Node3D = null
var _prompt: Node3D = null


## `shape` picks the primitive `_build_visual()` builds: "key" (default, the
## original shaft-and-ring, unchanged for `castle_gate_key`) or "stone" (a
## faceted emissive sphere, D71/T3-SUNSTONE) -- a key-shaped Sunstone would
## read as the wrong object entirely, and this class already knows how to
## build a found-object prop, so a shape hint here beats either a bespoke
## sibling script or forcing every future non-key pickup through key geometry.
## The faceted-sphere technique itself is not new: it is
## `burrow_warrens.gd::_build_prize`'s own gem, stripped of the plinth and
## room light that prop's DARK CHAMBER specifically needed and this one, sitting
## in open daylight, does not.
func setup(item_id: String, label: String, shape: String = "key") -> void:
	_item_id = item_id
	_label = label
	_shape = shape
	add_to_group("progression_restore")
	# The shaft lies along local +X with no yaw ever applied at the call
	# site (`playground_world.gd` sets `position` only) — so on the road
	# gate's own key, the player's actual approach looked almost straight
	# down the shaft's long axis, presenting its narrowest cross-section
	# rather than its length. A blind pass on round 2's shape/material
	# fixes still called it "an anonymous... speck" for exactly this
	# reason: no silhouette change or material fix helps an object that is
	# being viewed edge-on. A fixed off-axis yaw — a plausible "dropped,
	# not placed" angle — keeps the shaft and ring broadside to a
	# road-aligned approach instead of end-on to it. Only meaningful for the
	# "key" shape; "stone" is round and does not care.
	rotation.y = deg_to_rad(50.0)
	_build_visual()
	# OP-0830-2/OP-0830-3. Four blind rounds of shape, scale, metallic and
	# emission work on this prop (see `_build_visual()`'s own comments) each
	# ended with a critic calling it a small smear at range -- because every one
	# of them was trying to make an 18cm object legible in a meadow using the
	# object itself. The shared highlight is the lever those rounds kept naming
	# and none of them had: it does not depend on the key's silhouette, its
	# material, or the Compatibility renderer's ambient, and it is the SAME cue
	# the player learns on every other pickup in the game.
	PICKUP_GLOW.attach(self, _item_colour())
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 0.6
	_prompt.call("configure", _label, 2.4, true)
	_prompt.connect("activated", _on_picked_up)
	add_child(_prompt)
	var game := get_node_or_null(^"/root/Game")
	if was_taken(game, _item_id):
		_deactivate()


static func flag_id(item_id: String) -> String:
	return FLAG_PREFIX + item_id


## New saves use pickup:<id>. Inventory/gate state are conservative migration
## evidence for the one Meadows key that existed before this flag was added.
static func was_taken(game: Node, item_id: String) -> bool:
	if game == null or item_id == "":
		return false
	var progression: RefCounted = game.get("progression")
	if progression != null:
		if bool(progression.call("has", flag_id(item_id))):
			return true
		if item_id == "castle_gate_key" and bool(progression.call("has", ROAD_GATE_OPEN_FLAG)):
			return true
	var inventory: RefCounted = game.get("inventory")
	return inventory != null and int(inventory.call("count", item_id)) > 0


func restore_progression_from_game(game: Node) -> void:
	if was_taken(game, _item_id):
		_deactivate()


func _deactivate() -> void:
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.call("set_enabled", false)
	PICKUP_GLOW.detach(self)
	visible = false
	queue_free()


func _build_visual() -> void:
	if _shape == "stone":
		_build_stone_visual()
		return
	# A real key's own proportions (a thin shaft plus a ring), not the
	# low-mound-in-slot-colour placeholder harvest_node.gd uses for a
	# resource pile — the blind visual-judge pass named that shape (and the
	# 0.28m box it used to be, a third of a fence panel's height) as reading
	# as a crate rather than anything meant to be picked up specifically.
	# Still built from primitives, still tinted from the item's own
	# `colour`, so this stays an honest placeholder rather than new art.
	#
	# Round 1 shrank this to real key scale and a second blind round
	# confirmed the SCALE was right but called the shape unresolved —
	# "an anonymous yellow dot," the ring's hole too small to read as a
	# hole under software rendering. This round's own first attempt (widen
	# the ring, add teeth, but leave `metallic` at 0.75) rendered as a dark
	# muddy "comma-shaped blob with one specular highlight" per a fresh
	# blind pass — a high-metallic `StandardMaterial3D` gets nearly all its
	# visible colour from specular environment reflection, which the
	# Compatibility renderer's flat ambient here can't supply, so it goes
	# dark almost everywhere except the one facet catching the sun directly.
	# Low metallic instead, so `castle_gate_key`'s own bright gold
	# `colour` (`items.json`, `#c9a227`) actually reads as its diffuse
	# albedo rather than being swallowed. The shape change (wider ring
	# hole, asymmetric tip teeth) stays — it was never tested against a
	# material that could show it.
	var material := StandardMaterial3D.new()
	material.albedo_color = _item_colour()
	material.metallic = 0.1
	material.roughness = 0.45
	# A fresh blind pass on the enlarged, correctly-oriented key still
	# called it a "small curled yellow smear" at native resolution and
	# named the specific missing lever: "no rim light, outline shader, or
	# contrast pass... relies entirely on colour difference." `orb.gd`
	# already establishes glow as this project's own visual language for
	# a found/thrown item worth noticing (SA7's backlog entry cites its
	# halo and trail); a modest emissive boost on the key is the same
	# lever, not a new one, and does not depend on the Compatibility
	# renderer's weak ambient the way the metallic fix above had to work
	# around.
	material.emission_enabled = true
	material.emission = _item_colour()
	material.emission_energy_multiplier = 0.8

	# A genuine blind pass on the orientation fix above (round 3) still
	# called this "a curled/hooked yellow squiggle... does not read as a
	# key even in close-up" — at ~20px on screen even a correctly-lit,
	# correctly-oriented, correctly-shaped object can lose its silhouette
	# to software-rendering blur. `items.json`'s own flavour text calls
	# this "heavy and old," which gives room to size it as a big
	# castle-style key rather than a small modern one without re-triggering
	# the original "0.28m box read as a crate" complaint — that was 3x
	# this size and had no shape at all, just a slot-coloured mound.
	var shaft := MeshInstance3D.new()
	var shaft_box := BoxMesh.new()
	shaft_box.size = Vector3(0.13, 0.02, 0.035)
	shaft.mesh = shaft_box
	shaft.material_override = material
	shaft.position = Vector3.UP * 0.03
	_visual = shaft
	add_child(_visual)

	for i in 2:
		var tooth := MeshInstance3D.new()
		var tooth_box := BoxMesh.new()
		tooth_box.size = Vector3(0.018, 0.018, 0.035)
		tooth.mesh = tooth_box
		tooth.material_override = material
		tooth.position = Vector3(0.034 + i * 0.024, -0.019, 0.0)
		shaft.add_child(tooth)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.028
	torus.outer_radius = 0.06
	ring.mesh = torus
	ring.material_override = material
	ring.rotation.x = deg_to_rad(90.0)
	ring.position = Vector3(-0.125, 0.0, 0.0)
	_visual.add_child(ring)


## A faceted emissive stone, resting directly on the ground with no plinth or
## dedicated light -- `burrow_warrens.gd::_build_prize`'s gem sits in a dark
## dungeon room that needs its own light source to read at all; this one sits
## in open Meadows daylight and does not. Low radial/ring segment counts for
## the same reason that prop uses them: an emissive surface ignores its own
## normals at uniform lighting, so cutting the segment counts is what gives
## flat renderer ambient something to shade differently across the surface.
func _build_stone_visual() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = _item_colour()
	material.metallic = 0.0
	material.roughness = 0.35
	material.emission_enabled = true
	material.emission = _item_colour()
	material.emission_energy_multiplier = 1.1

	var gem := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	sphere.radial_segments = 7
	sphere.rings = 4
	gem.mesh = sphere
	gem.material_override = material
	gem.position = Vector3.UP * 0.16
	_visual = gem
	add_child(_visual)


func _item_colour() -> Color:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return Color(0.75, 0.65, 0.2)
	var items: RefCounted = game.get("items")
	return items.call("colour", _item_id) if items != null else Color(0.75, 0.65, 0.2)


func _on_picked_up() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; a key was found but has nowhere to go")
		return
	var inventory: RefCounted = game.get("inventory")
	if not bool(inventory.call("has_room_for", _item_id, 1)):
		# Refused, visibly, same as harvest_node.gd: the key stays on the
		# ground and keeps offering rather than vanishing into a full satchel.
		return
	inventory.call("add", _item_id, 1)
	var progression: RefCounted = game.get("progression")
	if progression != null:
		progression.call("set_flag", flag_id(_item_id))
	_deactivate()
