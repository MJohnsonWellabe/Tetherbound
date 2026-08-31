extends Node3D

## SA7: a simple physical gate on the road out of the village, with an easy
## key nearby. Owner directive, 2026-08-11 — near-field and low-stakes, so the
## player understands early that gated things have keys, well before `SC14`'s
## real combat-gated crossing hours in.
##
## The leaf is the `road_gate_leaf` prefab — the Medieval kit's own fence
## segments, two wide and two courses tall, through the same composer every
## building in the settlement uses (EV6 retired the farm pack this gate's
## Fence2 came from, and D24 wants one family anyway; the same rustic
## fencing the player has already walked past as `fence_run`). Locked/open
## are two static poses of the one leaf — a closed panel across the road vs.
## the same panel swung parallel to it — since no animation rig exists for
## it and grandpa_house.gd already sets the precedent of a gate with no
## animation, its feedback carried by something else (there, the
## conversation; here, the panel's own re-pose plus a line of dialogue).

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const LEAF_PREFAB := "road_gate_leaf"
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const TETHER_SIGIL := preload("res://scripts/world/tether_sigil.gd")
## The same stone set and the same measured tile the Hall's own walls use
## (`stronghold.gd`'s STONE_* / STONE_TILE), so the checkpoint reads as an
## outpost of the building at the end of the road rather than as its own idea.
const STONE_ALBEDO := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png")
const STONE_NORMAL := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png")
const STONE_ROUGHNESS := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png")
const STONE_TILE := 0.28
const ITEM_GATE := preload("res://scripts/world/item_gate.gd")
const SEVERED_SPOKES := preload("res://scripts/world/severed_spokes.gd")
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"

const KEY_ITEM_ID := "castle_gate_key"
const FLAG_ID := "road_gate_open"
const LOCKED_CONVERSATION := "road_gate_locked"
const UNLOCKED_CONVERSATION := "road_gate_unlocked"

## SF34: this file is the gate BODY — leaf, lock, collision, prompt, re-pose —
## and the only things that ever differed between two physical gates are the
## five values below. They default to the village road gate this script was
## written for, so nothing that already builds one changes; the Meadows Hall
## approach (`playground_world._build_sigil_gate()`) sets them before `build()`
## and gets the same body with three Sigils as its key. A second script would
## have been a second copy of the lock-material and prefab-holder bugs this
## file's own comments record fighting.
var key_item_ids: Variant = KEY_ITEM_ID
var flag_id := FLAG_ID
var locked_conversation := LOCKED_CONVERSATION
var unlocked_conversation := UNLOCKED_CONVERSATION
var prompt_text := "Try the gate"
## SIGIL-SEAL. How far either side of centre this gate must actually seal, in
## metres. 0.0 (the default, and the village road gate's value) means "the leaf
## is the whole barrier" -- correct there, because that gate stands in a fence
## line that already runs off both its ends.
##
## The Meadows Hall approach has no such fence line. It stands alone on the
## causeway between `terrain_playground.json`'s two `sigil_gate_gorge_*` carves,
## and the leaf prefab is 4.06m wide against a causeway measured at 14.1m -- so
## the locked gate had 10m of open grass beside it and a player simply walked
## round. `smoke_traversal.gd` walks exactly that: at +3.0m and +6.0m off centre
## it got 22.9m past a LOCKED gate.
##
## Set above the causeway half-width so the wings bury their ends in the gorge
## rims rather than stopping flush with a walkable edge.
var seal_half_width := 0.0

## T1-HALL-3 / JUDGE-5 D4, ranked 8th of sixteen and read blind as: the "sigil
## gate" "has NEITHER sigil NOR gate ... a three-rail farm fence with a small
## yellow padlock. No sigil, no banner, no gatehouse, no Team Tether mark of any
## kind. Nothing tells the player they have crossed into hostile ground."
##
## That is a fair description of `road_gate_leaf` -- which is correct for the
## VILLAGE road gate this script was written for, and wrong for the threshold of
## the chapter's final location. Opt-in rather than automatic, and defaulted OFF,
## so the village gate is untouched: only the caller that knows it is building
## Team Tether's checkpoint asks for Team Tether's dressing.
##
## What it adds is deliberately the smallest thing that answers both halves of
## the finding -- two stone piers and a lintel (a GATE, not a fence), and a
## sigil banner on each pier (the MARK, shared with the Hall's own banners
## through `tether_sigil.gd`). It is built from boxes in the same masonry
## vocabulary the Hall uses; no new asset, no Meshy generation.
var faction_dressing := false

## GATE-F-LEG-S10CDE. Ids of `terrain_playground.json` `crossings[]` entries
## whose OWN `carve` this gate should hang a fall-in failsafe on, the same
## `severed_spokes.gd::_add_carve_failsafe` mechanism `gated_crossing.gd`
## already uses for the South Bridge and the storm road spoke. Opt-in and
## empty by default -- the village road gate stands in open ground and has
## no gorge of its own to guard.
##
## Found needing this the hard way: `sigil_gate_gorge_west`/`_east` and their
## `_west_wing`/`_east_wing` extensions (all four, `sigil_gate_gorge_*` in
## that file) are pure terrain carves -- `playground_heightfield.gd` reads
## them for the analytic height, and nothing else in the game ever reads
## their `carve.failsafe` field, because `severed_spokes.gd::_add_carve_
## failsafe` is only ever called from that script's OWN spoke-processing
## loop, and `gated_crossing.gd`'s own call only fires for a crossing that
## script itself builds a bridge/leaf for (south_bridge, old_mill_crossing)
## -- these four are neither. A player who slides into one of them (11m
## deep, ~72 degrees of wall, well past `floor_max_angle`) has no scripted
## way out at all: `stick_navigator.gd`'s own stall/detour/backoff logic
## cannot escape a hole nothing built a rescue for, and it burns its entire
## walk budget finding that out (reproduced twice, S10c and S10d both
## pinned at the SAME world position, ~7km into a walk with 121 m/s
## `_clamp_runaway_velocity` warnings firing every physics frame and zero
## net displacement -- consistent with the body caught between the carve's
## own walls, never falling far enough to reach `world_perimeter.gd`'s deep
## kill plane).
var gorge_carve_ids: Array = []
## The reserved oxblood, in the render-space-corrected value `stronghold.gd`'s
## `BANNER_COLOUR` header explains at length -- blue below green so no light
## level can push it to magenta (D6).
const FACTION_CLOTH := Color("#6b2a20")
const PIER_W := 1.5
const PIER_D := 1.5
const PIER_H := 6.2
const LINTEL_H := 0.9

var _mesh: Node3D = null
var _shape: CollisionShape3D = null
var _prompt: Node3D = null
var _lock: MeshInstance3D = null
var _open := false
## SB10's generic gate logic — the item(s) and flag are this gate's own, the
## mesh/collision/prompt above stay this file's job. Built in `build()` rather
## than here so the caller's overrides above are the ones it reads.
var _gate: RefCounted = null


## `world` only for `ground_height_at` — the same duck-typed climb
## village.gd's own `_ground_height` uses, so this does not need a direct
## reference to playground_world.gd.
func build(world: Node3D, at: Vector2, yaw_deg: float) -> void:
	_gate = ITEM_GATE.new(key_item_ids, flag_id)
	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		push_error("no building recipes; the road gate cannot build its leaf")
		return
	# building_prefabs.gd caches an un-parented Node3D template tree per
	# prefab name; without a real SceneTree parent it leaks RenderingServer
	# resources at engine shutdown (see building_prefabs.gd's own header on
	# `_holder` — reproduced as a real crash: hundreds of "leaked" GL buffers
	# followed by a heap-corrupting SIGABRT in the exported build, absent
	# once every `BuildingPrefabs` caller parks its templates).
	var template_holder := Node3D.new()
	template_holder.name = "PrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	prefabs.call("set_template_holder", template_holder)
	var leaf: Node3D = prefabs.call("instantiate", LEAF_PREFAB)
	if leaf == null:
		push_error("road gate leaf prefab missing: %s" % LEAF_PREFAB)
		return
	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the road gate at %.0f, %.0f" % [at.x, at.y])
		return

	position = Vector3(at.x, ground - 0.05, at.y)
	rotation.y = deg_to_rad(yaw_deg)

	_mesh = leaf
	_mesh.name = "GateMesh"
	add_child(_mesh)

	var aabb: AABB = prefabs.call("combined_aabb", _mesh)

	# A padlock at the panel's own centre. `Fence2` is decorative fencing
	# everywhere else it's placed (village.json) — with no leaf, hinge or
	# hardware of its own, one more length of it read as ordinary property
	# fencing rather than as something deliberately shut, per the blind
	# pass's own finding. Round 1 tried a single near-black box and a
	# second blind round called it out for blending straight into the
	# fence's own dark pickets — same hue, same value, same flat panel
	# plane. Round 2 (this round's own first attempt, caught by rendering
	# and zooming into the actual frame rather than trusting the change)
	# tried a lighter albedo at `metallic = 0.85` and it rendered dark and
	# flat anyway — a highly metallic `StandardMaterial3D` gets almost all
	# its visible colour from specular environment reflection, which the
	# Compatibility renderer's flat ambient here can't supply, so it reads
	# as a near-black silhouette regardless of `albedo_color`. Both lock
	# attempts and the key's own dark read (see `key_pickup.gd`) share this
	# one root cause. Low metallic instead, so the albedo's own diffuse
	# colour is what actually shows, plus a body-plus-shackle silhouette
	# (a box with a ring sunk halfway into it, so only the top loop shows)
	# instead of one more rectangle among the panel's own pickets. A child
	# of `_mesh` so it swings open with the panel rather than needing its
	# own re-pose.
	_lock = MeshInstance3D.new()
	_lock.name = "Lock"
	var lock_body := BoxMesh.new()
	lock_body.size = Vector3(0.16, 0.14, 0.06)
	_lock.mesh = lock_body
	var lock_material := StandardMaterial3D.new()
	lock_material.albedo_color = Color(0.72, 0.56, 0.24)
	lock_material.metallic = 0.15
	lock_material.roughness = 0.4
	_lock.material_override = lock_material
	# Pushed out past the panel's own face (not centred in its thickness,
	# round 1's placement) so the lock's silhouette breaks the fence's
	# outline instead of sitting flush inside it. NEGATIVE local Z: a
	# same-day diagnostic pass (unshaded magenta + a debug print of the
	# real aabb/position) found round 2's own +Z placement rendering a
	# bare sliver through one picket gap, on the far side of the panel
	# from `capture_road_gate.gd`'s own approach viewpoints — the panel's
	# camera-facing side is -Z here, not +Z.
	_lock.position = Vector3(
		0.0, aabb.position.y + aabb.size.y * 0.55, -(aabb.size.z * 0.5 + 0.03))
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
	box.size = aabb.size
	_shape.shape = box
	body.add_child(_shape)
	body.position = Vector3(0.0, aabb.size.y * 0.5, 0.0)
	add_child(body)

	_build_wings(world, prefabs, at, aabb)
	if faction_dressing:
		_build_faction_gatehouse(aabb)
	if not gorge_carve_ids.is_empty():
		_hang_gorge_failsafes(world, at)

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3(0.0, 1.2, 0.0)
	# Wider than the fence's own thin collision box: at full scale (no
	# `scale` factor is applied here, unlike `village.json`'s fences, since
	# a road gate wants to read as a real obstacle rather than a knee-high
	# rail) an approach from an angle can be stopped by the panel's face
	# well outside a tighter radius, and the interaction should not demand a
	# more perpendicular approach than a locked gate reasonably does.
	_prompt.call("configure", prompt_text, 4.0, true)
	_prompt.connect("activated", _on_tried)
	add_child(_prompt)

	# SB10: a gate the player already opened stays open across a reload —
	# `_gate`'s flag is the source of truth, not the fresh `_open := false`
	# above. Silent: no dialogue, no item to consume, just the resting pose.
	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null and _gate.is_open(progression):
		_unlock()


## SIGIL-SEAL. Fence the causeway either side of the leaf, out to
## `seal_half_width`, using the SAME prefab the leaf is made from -- so the
## barrier reads as one built thing rather than as a gate with invisible walls
## bolted to it. Nothing here is a child of `_mesh`: these are the wall, not
## the gate, and they must NOT swing away when the leaf does. That is how a
## real gate works, and `smoke_traversal.gd`'s unlocked walk goes through the
## centre, which the opened leaf clears.
##
## Each panel takes its own ground height rather than the gate's: the causeway
## is not flat, and a wing pinned to the gate's y left a gap under its
## downhill end big enough to walk through -- which is the same defect one
## step smaller.
## SIGIL-SEAL, second pass. Sizing each wing's COLLIDER from the ground under
## its own centre is what let the locked gate leak at +6.0m off centre.
##
## Measured on the built world (`tools/_probe_sigil_wings.gd`): the causeway
## falls -1.09m -> -3.71m over the first ten metres of the +1 side, so
## consecutive wings step down almost a metre each. At the +6.10m seam between
## wing 0 and wing 1 that left wing 1's top standing 0.84m above local terrain
## and wing 0's bottom floating 0.32m above it -- a wall the player simply
## stepped over. `smoke_traversal.gd`'s span check could not see it, because it
## projects the colliders onto the across-axis and is blind to Y: the barrier
## read as a contiguous -18.29m..18.29m the whole time it was being walked past.
##
## The -1 side passed throughout for no better reason than that its terrain is
## nearly flat there (-0.43m to -1.39m over the same ten metres). A seal that
## holds only where the ground happens to be level is not a seal.
##
## So the collider is now sized from the wing's WHOLE FOOTPRINT rather than one
## sample: bottom below the lowest ground it spans, top a full panel-height
## above the highest. The visible panel still sits on the centre height -- it is
## the wall's appearance, and stretching it would look worse than it reads.
##
## Note this is deliberately NOT "bury the box downward". A fixed-size box
## pushed down lowers its top by exactly as much as its bottom, which makes the
## walk-over easier, not harder; that was tried and measured at no effect.
const WING_FOOTPRINT_SAMPLES := 5
## How far below the lowest ground the wing spans to sink its base, so a dip
## between two samples cannot open a gap underneath it.
const WING_BURY_M := 1.0


func _build_wings(world: Node3D, prefabs: RefCounted, at: Vector2, aabb: AABB) -> void:
	var panel_width: float = aabb.size.x
	if seal_half_width <= 0.0 or panel_width <= 0.0:
		return
	var yaw := rotation.y
	var half_leaf := panel_width * 0.5
	var per_side: int = int(ceil((seal_half_width - half_leaf) / panel_width))
	for side: int in [-1, 1]:
		for i in range(per_side):
			var offset: float = float(side) * (half_leaf + panel_width * (float(i) + 0.5))
			var world_x: float = at.x + cos(yaw) * offset
			var world_z: float = at.y - sin(yaw) * offset
			var ground: float = float(world.call("ground_height_at", world_x, world_z))
			if is_nan(ground):
				# Off the causeway and over the gorge -- the fall does the
				# sealing there, and a panel with no ground under it would
				# hang in the air looking like a mistake.
				continue
			# The ground this wing actually spans, not just the point under its
			# middle. Samples that come back NaN are over the gorge and are
			# skipped rather than poisoning the min/max.
			var lowest := ground
			var highest := ground
			for s in WING_FOOTPRINT_SAMPLES:
				var t: float = -0.5 + float(s) / float(WING_FOOTPRINT_SAMPLES - 1)
				var sample_offset: float = offset + panel_width * t
				var sx: float = at.x + cos(yaw) * sample_offset
				var sz: float = at.y - sin(yaw) * sample_offset
				var g: float = float(world.call("ground_height_at", sx, sz))
				if is_nan(g):
					continue
				lowest = minf(lowest, g)
				highest = maxf(highest, g)
			var wing: Node3D = prefabs.call("instantiate", LEAF_PREFAB)
			if wing == null:
				continue
			wing.name = "GateWing%d_%d" % [side, i]
			wing.position = Vector3(offset, ground - (position.y), 0.0)
			add_child(wing)
			var bottom: float = lowest - WING_BURY_M
			var top: float = highest + aabb.size.y
			var wing_body := StaticBody3D.new()
			wing_body.name = "GateWingCollision%d_%d" % [side, i]
			var wing_shape := CollisionShape3D.new()
			var wing_box := BoxShape3D.new()
			wing_box.size = Vector3(aabb.size.x, top - bottom, aabb.size.z)
			wing_shape.shape = wing_box
			wing_body.add_child(wing_shape)
			wing_body.position = Vector3(
				offset, (bottom + top) * 0.5 - (position.y), 0.0)
			add_child(wing_body)


func is_open() -> bool:
	return _open


## GATE-F-LEG-S10CDE. One `severed_spokes.gd` failsafe volume per id in
## `gorge_carve_ids`, reading each entry's own `carve` straight out of
## `terrain_playground.json`'s `crossings[]` -- see that var's own comment for
## why nothing else in the game already does this for these four. Recovery
## road is a two-point stub, `[carve's own centre, this gate's own position]`
## -- `_recovery_point` (severed_spokes.gd) only needs a "back" direction and
## a point to walk forward from until clear of the carve's rim, and the
## gate's own position is the one place every one of these four carves
## exists to guard, so it is always a safe, meaningful landing regardless of
## which of the four caught the fall.
func _hang_gorge_failsafes(world: Node3D, at: Vector2) -> void:
	var config := _load_terrain_config()
	var by_id: Dictionary = {}
	for entry: Variant in (config.get("crossings", []) as Array):
		if entry is Dictionary:
			by_id[str((entry as Dictionary).get("id", ""))] = entry
	for raw_id: Variant in gorge_carve_ids:
		var id := str(raw_id)
		var entry: Dictionary = by_id.get(id, {}) as Dictionary
		var carve: Dictionary = entry.get("carve", {}) as Dictionary
		if carve.is_empty():
			push_warning("road_gate.gd: no crossings[] carve named '%s'; no failsafe hung" % id)
			continue
		var centre_raw: Array = carve.get("centre", [])
		if centre_raw.size() < 2:
			continue
		var centre := Vector2(float(centre_raw[0]), float(centre_raw[1]))
		if centre.is_equal_approx(at):
			continue
		var spokes: Node3D = SEVERED_SPOKES.new()
		spokes.name = "GorgeFailsafe_%s" % id
		# See `gated_crossing.gd::_hang_failsafe`'s own comment on why this
		# must be top_level: `_add_carve_failsafe` places its volume in WORLD
		# coordinates via plain `position`, which is only correct for a node
		# with no inherited transform of its own -- this gate's own `position`/
		# `rotation.y` (set in `build()` above) would otherwise displace it.
		spokes.top_level = true
		add_child(spokes)
		var road := [[centre.x, centre.y], [at.x, at.y]]
		spokes.call("_add_carve_failsafe", world, spokes, carve, road)


func _load_terrain_config() -> Dictionary:
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## SG46. The Warden falls, the machinery dies, and the region's keyed gates
## stop being gates -- §9's "barriers deactivate". The flag itself is set by
## `meadow_healing.gd` (this gate's OWN flag, the same one the key sets), so a
## reload opens it through `_gate.is_open()` in `build()` above for the ordinary
## reason; this call is only what makes the panel swing on the frame it
## happens rather than on the next load. Idempotent.
func open_permanently() -> void:
	if _open:
		return
	_unlock()


func _on_tried() -> void:
	if _open:
		return
	var game := get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	var progression: RefCounted = game.get("progression") if game != null else null

	if inventory != null and progression != null and _gate.try_open(inventory, progression):
		_unlock()
		_say(unlocked_conversation)
	else:
		_say(locked_conversation)


func _unlock() -> void:
	_open = true
	_shape.disabled = true
	_lock.visible = false
	# Swing the same panel parallel to the road it was blocking — an instant
	# re-pose rather than an animation, this file's own header explains why.
	_mesh.rotation.y += deg_to_rad(90.0)
	_prompt.call("set_enabled", false)


## Same lookup village_npcs.gd's `_on_greeted` uses: the "dialogue_panel"
## group rather than an exported path, so this does not need to know where
## sequence_director.gd hung the panel.
func _say(conversation_id: String) -> void:
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		push_warning("no node in the 'dialogue_panel' group; the gate has nothing to say")
		return
	if bool(panel.call("is_open")):
		return
	panel.call("start", conversation_id)


## --- Team Tether's checkpoint (JUDGE-5 D4) -----------------------------------

## Turn the leaf into a threshold. See `faction_dressing` above for the finding
## this answers and why it is opt-in.
##
## Nothing here is a child of `_mesh`: the piers, the lintel and the banners are
## the GATEHOUSE and must stand still when the leaf swings, exactly as
## `_build_wings` already documents for the wings. Nothing here carries a
## collider either -- the leaf and the wings already seal this line, and a pier
## with a body on it would be a new thing for `smoke_traversal.gd`'s walk to
## catch on either side of a gate the player is meant to pass through.
func _build_faction_gatehouse(aabb: AABB) -> void:
	var half := aabb.size.x * 0.5 + PIER_W * 0.5
	# The Hall's own curtain tone AND its actual stone, triplanar at the same
	# measured tile. The first cut set only `albedo_color` and the frame showed
	# exactly what that is: two smooth pale slabs reading as painted concrete
	# beside a fully textured world -- the "white maquette" failure
	# HALL_DESIGN sec5 diagnoses at length ("a flat colour at any value cannot
	# produce coursing"), reintroduced at the one object in the chapter whose
	# whole job is to say "you have crossed into hostile ground". Triplanar
	# because these are BoxMeshes with box UVs; the Hall's own kit is mapped the
	# same way for the same reason.
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("#9c9083")
	stone.albedo_texture = STONE_ALBEDO
	stone.normal_enabled = true
	stone.normal_texture = STONE_NORMAL
	stone.roughness_texture = STONE_ROUGHNESS
	stone.uv1_triplanar = true
	stone.uv1_scale = Vector3.ONE * STONE_TILE
	stone.roughness = 0.95
	var timber := StandardMaterial3D.new()
	timber.albedo_color = Color("#5d4529")
	timber.albedo_texture = STONE_ALBEDO
	timber.uv1_triplanar = true
	timber.uv1_scale = Vector3.ONE * STONE_TILE * 1.4
	timber.roughness = 0.95

	for side: float in [-1.0, 1.0]:
		var pier := MeshInstance3D.new()
		pier.name = "GatePier%s" % ("L" if side < 0.0 else "R")
		var pier_box := BoxMesh.new()
		# Sunk a metre so an uneven causeway cannot open a gap under a pier --
		# the same reason `_build_wings` buries its wing bases.
		pier_box.size = Vector3(PIER_W, PIER_H + 1.0, PIER_D)
		pier.mesh = pier_box
		pier.material_override = stone
		pier.position = Vector3(side * half, (PIER_H + 1.0) * 0.5 - 1.0, 0.0)
		add_child(pier)

		# A capstone, proud on all four faces: the one cheap cue that reads as
		# dressed masonry rather than as an extruded box.
		var cap := MeshInstance3D.new()
		cap.name = "GatePierCap%s" % ("L" if side < 0.0 else "R")
		var cap_box := BoxMesh.new()
		cap_box.size = Vector3(PIER_W + 0.34, 0.34, PIER_D + 0.34)
		cap.mesh = cap_box
		cap.material_override = stone
		cap.position = Vector3(side * half, PIER_H + 0.17, 0.0)
		add_child(cap)

		_hang_sigil_banner(Vector3(side * half, PIER_H - 0.55, -PIER_D * 0.5 - 0.05))

	# The lintel across the top: this is what makes the thing a GATE in
	# silhouette instead of a fence with two posts beside it.
	var lintel := MeshInstance3D.new()
	lintel.name = "GateLintel"
	var lintel_box := BoxMesh.new()
	lintel_box.size = Vector3(half * 2.0 + PIER_W, LINTEL_H, PIER_D * 0.62)
	lintel.mesh = lintel_box
	lintel.material_override = timber
	lintel.position = Vector3(0.0, PIER_H - LINTEL_H * 0.5 - 0.4, 0.0)
	add_child(lintel)


## The same three-box banner the Hall hangs (body, selvage edges, two tails),
## wearing the shared compass sigil. Kept small and local rather than reaching
## into `stronghold.gd`: that file's `_hang_banner` is bound to the Hall's own
## floor/skirt frame, and this gate is 160 m away on open ground.
const GATE_BANNER_W := 1.05
const GATE_BANNER_H := 2.6
const GATE_BANNER_T := 0.06
func _hang_sigil_banner(at: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "SigilBanner"
	holder.position = at
	add_child(holder)

	var cloth := TETHER_SIGIL.cloth_material(FACTION_CLOTH)
	var body_h := GATE_BANNER_H * 0.74
	var panel := MeshInstance3D.new()
	panel.name = "BannerCloth"
	var panel_box := BoxMesh.new()
	panel_box.size = Vector3(GATE_BANNER_W, body_h, GATE_BANNER_T)
	panel.mesh = panel_box
	panel.material_override = cloth
	panel.position = Vector3(0.0, -body_h * 0.5, 0.0)
	holder.add_child(panel)

	# The mark, on its own quad. See `tether_sigil.gd::cloth_material` for why it
	# is not baked into the panel's material. The banner hangs on the pier's -Z
	# face, which is the side the road arrives from, so that is its outward
	# normal in this holder's frame.
	# Bleached linen, not cloth-plus-6%. `tether_sigil.gd`'s field went
	# transparent in T1-HALL-4, so this colour tints the MARK rather than a
	# lightened panel behind it; see `stronghold.gd::_hang_banner`'s matching
	# note. The gate and the Hall must keep saying the same thing in the same
	# tone, which is the whole reason the device lives in one file.
	var device := TETHER_SIGIL.device(
		Vector2(GATE_BANNER_W * 0.66, body_h * 0.6),
		FACTION_CLOTH.lerp(Color("#e8ddc4"), 0.86),
		Vector3.FORWARD, GATE_BANNER_T * 0.62)
	device.position += Vector3(0.0, -body_h * 0.46, 0.0)
	holder.add_child(device)

	var tail_h := GATE_BANNER_H - body_h
	for side: float in [-1.0, 1.0]:
		var tail := MeshInstance3D.new()
		tail.name = "BannerTail"
		var tail_box := BoxMesh.new()
		tail_box.size = Vector3(GATE_BANNER_W * 0.42, tail_h, GATE_BANNER_T)
		tail.mesh = tail_box
		tail.material_override = cloth
		tail.position = Vector3(side * GATE_BANNER_W * 0.29, -body_h - tail_h * 0.5, 0.0)
		holder.add_child(tail)
