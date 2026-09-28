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
## D103 / Stage B lane 3.B. See `_on_picked_up()`: this key is claimed through
## the world ledger now, not written here. OP-0905-18's catalyst-discoverability
## announcement moved with the grant to `ledger_rpc.gd::_apply_player_ops()`,
## which is peer-scoped -- see `item_cache_pickup.gd`'s identical note.
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
## F01#2/#3: where the Meadows gate key hangs. See `data/config/key_post.json`.
const POST_CONFIG_PATH := "res://data/config/key_post.json"

const FLAG_PREFIX := "pickup:"
## Compatibility for saves written before physical pickups recorded their own
## flags: consuming this key wrote the gate's durable flag instead.
const ROAD_GATE_OPEN_FLAG := "road_gate_open"

var _item_id: String = ""
var _label: String = ""
var _shape: String = "key"
var _visual: Node3D = null
var _prompt: Node3D = null
## D97: the realm this key's RECORD belongs to. Every ledger intent carries one
## explicitly and nothing here reads `Game.current_realm` -- two peers can stand
## in two realms at once, so the realm has to come from the thing being written.
## `pickup:<item>` is not itself realm-qualified (it never was), so this only
## stamps the intent; the default matches the one realm that places keys today.
var _realm_id: String = "meadows"
## True between submitting a `claim_pickup` and hearing back. See
## `item_cache_pickup.gd`'s own field for what it is for.
var _claiming := false
var _taken := false
## "ground" (lying in the grass, the original) or "post" (hanging from the peg
## of a post `build_post()` stands at the same spot).
var _mount: String = "ground"


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
func setup(item_id: String, label: String, shape: String = "key",
		realm_id: String = "meadows", mount: String = "ground") -> void:
	_item_id = item_id
	_label = label
	_shape = shape
	_realm_id = realm_id
	_mount = mount if mount == "post" and bool(post_config().get("enabled", false)) else "ground"
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
	var glow_height := -1.0
	if _mount == "post":
		glow_height = _hang_on_post()
	# OP-0830-2/OP-0830-3. Four blind rounds of shape, scale, metallic and
	# emission work on this prop (see `_build_visual()`'s own comments) each
	# ended with a critic calling it a small smear at range -- because every one
	# of them was trying to make an 18cm object legible in a meadow using the
	# object itself. The shared highlight is the lever those rounds kept naming
	# and none of them had: it does not depend on the key's silhouette, its
	# material, or the Compatibility renderer's ambient, and it is the SAME cue
	# the player learns on every other pickup in the game.
	PICKUP_GLOW.attach(self, _item_colour(), glow_height)
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 0.6
	_prompt.call("configure", _label, 2.4, true)
	_prompt.connect("activated", _on_picked_up)
	add_child(_prompt)
	LEDGER_CLAIM.listen(self, _on_delta_applied)
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
	_taken = true
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


static func post_config() -> Dictionary:
	var file := FileAccess.open(POST_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## F01#2/#3. The post the key hangs from: a plain weathered stake with a peg,
## built from primitives like the key itself. It is the world's, not the key's,
## so it stays standing (an empty peg) after the key node frees itself. `ground`
## is the world position at the post's foot.
static func build_post(parent: Node, ground: Vector3) -> Node3D:
	var cfg := post_config()
	var post := Node3D.new()
	post.name = "GateKeyPost"
	post.position = ground
	post.rotation.y = deg_to_rad(float(cfg.get("facing_yaw_deg", -90.0)))
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(str(cfg.get("post_colour", "#6b5a45")))
	wood.roughness = 0.9
	var height := float(cfg.get("post_height_m", 1.45))
	var width := float(cfg.get("post_width_m", 0.13))
	var stake := MeshInstance3D.new()
	var stake_box := BoxMesh.new()
	stake_box.size = Vector3(width, height, width)
	stake.mesh = stake_box
	stake.material_override = wood
	stake.position = Vector3(0.0, height * 0.5, -0.08)
	post.add_child(stake)
	var cap := MeshInstance3D.new()
	var cap_box := BoxMesh.new()
	cap_box.size = Vector3(width * 1.5, 0.05, width * 1.5)
	cap.mesh = cap_box
	cap.material_override = wood
	cap.position = Vector3(0.0, height + 0.025, -0.08)
	post.add_child(cap)
	var peg := MeshInstance3D.new()
	var peg_mesh := CylinderMesh.new()
	peg_mesh.top_radius = 0.02
	peg_mesh.bottom_radius = 0.02
	peg_mesh.height = float(cfg.get("peg_length_m", 0.16))
	peg.mesh = peg_mesh
	peg.material_override = wood
	peg.rotation.x = deg_to_rad(90.0)
	peg.position = Vector3(0.0, float(cfg.get("peg_height_m", 1.3)), -0.08 + width * 0.5 + peg_mesh.height * 0.5)
	post.add_child(peg)
	parent.add_child(post)
	return post


## Turns the lying key upright, ring on the peg and shaft hanging down, at the
## configured scale. Returns the height the shared glow should sit at: on the
## key, not on the ground under it.
func _hang_on_post() -> float:
	var cfg := post_config()
	rotation.y = deg_to_rad(float(cfg.get("facing_yaw_deg", -90.0)))
	var key_scale := float(cfg.get("key_scale", 2.0))
	var peg_y := float(cfg.get("peg_height_m", 1.3))
	var tip_z := -0.08 + float(cfg.get("post_width_m", 0.13)) * 0.5 + float(cfg.get("peg_length_m", 0.16)) - 0.03
	# The visual's shaft runs along local +X with the ring at x = -0.125; a
	# -90 degree turn about Z hangs the ring on top and the teeth at the bottom.
	# The ring (radius 0.06 before scaling) sits on the peg by its inner edge.
	_visual.rotation = Vector3(0.0, 0.0, deg_to_rad(-90.0))
	_visual.scale = Vector3.ONE * key_scale
	var ring_centre_y := peg_y - 0.028 * key_scale
	_visual.position = Vector3(0.0, ring_centre_y - 0.125 * key_scale, tip_z)
	return ring_centre_y - 0.1 * key_scale


func _item_colour() -> Color:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return Color(0.75, 0.65, 0.2)
	var items: RefCounted = game.get("items")
	return items.call("colour", _item_id) if items != null else Color(0.75, 0.65, 0.2)


## D103, Stage B lane 3.B. The satchel write and the `pickup:<id>` flag are the
## ledger's now: a `claim_pickup` INTENT goes up, and the committed delta
## carries both halves back -- the flag to every peer, the item to the one peer
## who won. Nothing here changes until that delta lands, so two players reaching
## the same key produce one key, and the loser sees it stay on the ground.
##
## Solo is unchanged in behaviour and in code path: a solo player is a host with
## nobody to tell, so `submit()` commits in-process and `_on_delta_applied()`
## has already run by the time this returns.
##
## The room check stays here, ahead of the intent: only this peer can see its
## own satchel, and a full one must still refuse visibly rather than spending
## the world's only copy of a key.
func _on_picked_up() -> void:
	if _taken or _claiming:
		return
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; a key was found but has nowhere to go")
		return
	var inventory: RefCounted = game.get("inventory")
	if not bool(inventory.call("has_room_for", _item_id, 1)):
		# INTERACT-SWEEP-0903: this comment used to claim "refused, visibly" and
		# then did no such thing -- the prompt just kept offering, which is not a
		# response to THIS press, it is the absence of one. A player who presses
		# on a full satchel saw nothing happen at all, indistinguishable from a
		# dropped press. `item_cache_pickup.gd`/`tm_pickup.gd`'s own refusal
		# already speaks; this now matches them instead of asserting it did.
		game.call("push_world_message", "Satchel is full.")
		return
	_claiming = true
	var verdict := LEDGER_CLAIM.submit(self, {
		"kind": "claim_pickup",
		"realm": _realm_id,
		"flag": flag_id(_item_id),
		"item": _item_id,
		"count": 1,
	})
	if not LEDGER_CLAIM.in_flight(verdict):
		_claiming = false


## Removal is driven by the delta, not by the intent -- see the header on
## `item_cache_pickup.gd::_on_delta_applied()`, which this deliberately mirrors
## rather than answering the same question a second way.
func _on_delta_applied(delta: Dictionary) -> void:
	if not LEDGER_CLAIM.sets_world_flag(delta, flag_id(_item_id)):
		return
	# `_taken` is checked after the flag, not before it: on a client
	# `ledger_rpc.gd::_rpc_delta` runs the `progression_restore` sweep before it
	# emits `delta_applied`, so this node can already be deactivated by the time
	# we arrive and the claim still has to be closed out.
	_claiming = false
	if not _taken:
		_deactivate()


## The transport is an autoload child at an identical path in every process, so
## it is already there when this node enters the tree. Connected here as well as
## in `setup()` because a caller that sets the node up BEFORE adding it to the
## tree would otherwise never hear a delta at all -- `listen()` is idempotent.
func _ready() -> void:
	LEDGER_CLAIM.listen(self, _on_delta_applied)
