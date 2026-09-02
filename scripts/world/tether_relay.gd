extends Node3D

## SE23 — the Tether Relay Station, spec §3 Band 3 and §32 rung 3.
##
## The chapter's first mini-stronghold: a natural site partly industrialised,
## a compact traversal-and-combat site, and the rung of §32's reveal ladder
## where Team Tether stops being something Grandpa described and becomes a
## thing the player has walked into. It is NOT a dungeon — `SD17`'s Burrow
## Warrens is the dungeon, and this is deliberately a fraction of its size.
##
## WHAT THIS FILE OWNS, and what it does not:
##
##   * the compound — walls, the open gate, the yard
##   * the traversal — a ramp, a gantry and the raised apparatus pad
##   * the apparatus massing and the CONTROL CONSOLE
##   * the conduit runs converging on the pad, and their live/dead state
##   * the drained-ground skin around the site
##
## The people on it are `SE25`/`SE27`'s (`data/config/relay_site.json`,
## `data/config/trainers.json`); the authored drain is
## `terrain_playground.json`'s `drains` block; the map region is
## `map_landmarks.json`. Same split `old_quarry.gd` documents at its head, for
## the same reason: one file per kind of thing.
##
## ---------------------------------------------------------------------------
## THE HERO ASSET, AND WHY IT IS NOT HERE
## ---------------------------------------------------------------------------
##
## `docs/art/reference/14_Relay_Apparatus.png` is the owner-supplied board for
## the relay apparatus (2026-08-11, labelled Band 3 — drawn for this item).
## The apparatus is one of the THREE hero objects D24 reserves Meshy for. The
## generation is an OWNER-GATED task in the `art` lane and did not happen in
## this build. The owner authorised the generation on 2026-08-16 and the mesh is
## installed (D49): `apparatus.model` names it, `_build_apparatus` instantiates
## it under `ApparatusSeam` and fits it to `apparatus.height` by its own visual
## bounds.
##
## The PLACEHOLDER MASSING is still here below and is still reachable: it is the
## fallback taken whenever `model` is unset or its file is missing, and it is
## laid out as the board's own five labelled subassemblies in the board's own
## order. Nothing outside `ApparatusSeam` depends on any part of it except the
## console, which is found by the name `Console` and is built on BOTH paths --
## it is the thing the player presses and it was never part of the massing.
##
## ---------------------------------------------------------------------------
## WHY SO LITTLE OF THIS IS NEW CODE
## ---------------------------------------------------------------------------
##
## `severed_spokes.gd` already owns the whole Team Tether visual grammar —
## the pylon mesh fitting, the lit/dead pylon and conduit materials, the
## sagging spans, the ground-following wall runs, the medieval stone sheet and
## the oxblood faction accent. `old_quarry.gd` set the precedent of parenting
## an instance of that script and CALLING it rather than copying it (see its
## own header on the material bug that cost a render pass to find). This file
## does the same, for walls and pylons both. What is genuinely new here is the
## traversal geometry (pitched ramp colliders, raised decks), the apparatus
## massing, the console, and the drained-ground skin.

const SEVERED_SPOKES := preload("res://scripts/world/severed_spokes.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
## E-relay-dress: the same two helpers `props.gd` already uses for a loose
## prop's material fix and its optional faction retint — borrowed rather than
## reimplemented, for the same "a second copy gets it subtly wrong" reason
## this file's header gives for `severed_spokes.gd`. Used by the deck-prop,
## barrier and banner dressing below, none of which is a `props.json` cluster
## (those sit on real sampled ground; these sit on the raised pad or need this
## file's own local (s,t) frame), so it is placed and loaded locally instead.
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const BUILDING_PREFABS := preload("res://scripts/world/building_prefabs.gd")
const CONFIG_PATH := "res://data/config/tether_relay.json"

var _config: Dictionary = {}
var _world: Node3D = null
var _works: Node3D = null      ## the severed_spokes.gd instance we borrow from
var _centre := Vector2.ZERO
var _u := Vector2(1.0, 0.0)    ## along the approach bearing
var _p := Vector2(0.0, 1.0)    ## across it
var _console_prompt: Node3D = null
var _built := {"walls": 0, "decks": 0, "ramps": 0, "pylons": 0}
## SG46: the drained-ground skin and its material, held so the healing can fade
## them. Null on a build where `dead_ground.enabled` is false — after a terrain
## re-bake, this site's discolouration is baked and there is nothing to fade.
var _dead_ground: MeshInstance3D = null
var _dead_ground_material: StandardMaterial3D = null
var _healing: bool = false
var _healed: bool = false
var _heal_seconds: float = 0.0
var _heal_elapsed: float = 0.0
## E-relay-dress: the retint helper is stateful only for its own tint cache
## (`building_prefabs.gd::apply_retint`), so one lazily-built instance serves
## every dressing prop that carries a `retint` block, the same lazy pattern
## `props.gd::_prefabs` already uses.
var _prefabs: RefCounted = null


## `world` is only ever asked for `ground_height_at` — the same duck-typed
## climb `village.gd`, `old_quarry.gd` and `severed_spokes.gd` use (D09: never
## a raycast for ground).
func build(world: Node3D) -> bool:
	_config = _load_config()
	if _config.is_empty():
		push_warning("tether_relay.json missing or unreadable; the relay station does not stand")
		return false
	_world = world

	var site: Dictionary = _config.get("site", {})
	var centre: Array = site.get("centre", [])
	if centre.size() < 2:
		push_error("tether_relay.json has no site centre")
		return false
	_centre = Vector2(float(centre[0]), float(centre[1]))
	# The bearing is recorded in the config for auditability, but the axis
	# itself is the quarry's own stronghold bearing, normalised — the same
	# vector old_quarry.json's conduit run already walks. Deriving it from the
	# recorded degrees instead would let a rounded number in a comment quietly
	# rotate the whole site off the line it is supposed to be on.
	_u = Vector2(0.565, -0.826).normalized()
	_p = Vector2(-_u.y, _u.x)

	# Borrowed, not rewritten: see this file's header.
	_works = SEVERED_SPOKES.new()
	_works.name = "TetherWorks"
	add_child(_works)

	_build_walls()
	_build_gate()
	_build_decks()
	_build_ramps()
	_build_apparatus()
	_build_conduits()
	_build_cable_links()
	_build_dead_ground()
	_build_scorch_marks()
	_build_deck_props()
	_build_barrier()
	_build_banner()

	# A relay disabled before a save is still disabled after a reload: the
	# flag is the state, and the scene is rebuilt from it rather than
	# remembering anything of its own.
	if is_disabled():
		_kill_the_conduits()
		_sync_console()

	print("[relay] station at %.0f, %.0f: %d wall runs, %d decks, %d ramps, %d pylons%s" % [
		_centre.x, _centre.y, _built["walls"], _built["decks"], _built["ramps"],
		_built["pylons"], " (disabled)" if is_disabled() else ""])
	return true


## For tests and capture tools: what actually stood, so neither has to count
## nodes by name. Same contract `old_quarry.gd::stats()` offers.
func stats() -> Dictionary:
	var out := _built.duplicate()
	out["disabled"] = is_disabled()
	out["centre"] = _centre
	return out


## World XZ of a point authored in the site's own (s, t) frame. Public because
## a test that wants to stand the player on the gantry should ask the site
## where the gantry is rather than redo the trigonometry.
func world_of(local: Vector2) -> Vector2:
	return _centre + _u * local.x + _p * local.y


## The inverse of `world_of`: a world XZ point back in the site's own (s, t)
## frame. For anything that has to ask "how far INTO the compound is this" —
## the smoke test's gate check, most obviously, which cannot answer that from
## a distance alone because a walk that overshoots its target is still a walk
## that got in.
func local_of(at: Vector2) -> Vector2:
	var offset := at - _centre
	return Vector2(offset.dot(_u), offset.dot(_p))


func console_flag() -> String:
	return str(_console().get("flag", "relay_disabled"))


func is_disabled() -> bool:
	var progression := _progression()
	if progression == null:
		return false
	return bool(progression.call("has", console_flag()))


## --- the compound ----------------------------------------------------------


## Wall runs, through `severed_spokes.gd::_ground_wall` — a run that follows
## the ground it stands on instead of hanging over the dips at its ends, which
## is a failure `OF7` fixed once already in the boundary ring and which this
## file has no business meeting a second time. Visible masonry and collider are
## the same box there, so nothing here is an invisible wall.
func _build_walls() -> void:
	var holder := Node3D.new()
	holder.name = "Compound"
	add_child(holder)
	for entry: Variant in _config.get("walls", []):
		if not entry is Dictionary:
			continue
		var wall: Dictionary = entry
		var from := _local(wall.get("from", []))
		var to := _local(wall.get("to", []))
		if from == Vector2.INF or to == Vector2.INF:
			push_warning("a relay wall has no `from`/`to` — skipped")
			continue
		var a := world_of(from)
		var b := world_of(to)
		var span := a.distance_to(b)
		if span < 0.5:
			continue
		var axis := (b - a) / span
		# One segment per ~3m, so a run re-seats itself on the ground often
		# enough that a 6-degree shoulder never opens a gap under it.
		var segments := maxi(2, int(round(span / 3.0)))
		_works.call("_ground_wall", _world, holder, "Wall_%s" % str(wall.get("id", "x")),
			(a + b) * 0.5, axis, span, float(wall.get("height", 3.0)),
			float(wall.get("thickness", 1.4)), segments, _works.call("_stone_material"))
		_built["walls"] += 1


## The gate. Piers, a lintel and a faction-coloured band across it — and NO
## leaves. A severed spoke's gate is shut and that is its whole message; this
## one is open, because Team Tether does not expect anybody to walk up this
## road. `severed_spokes.gd::_build_sealed_gate` would give the geometry and
## the closed leaves together, and the leaves are exactly the part that must
## not be here, so the piers are built locally from its own `_stone_box` and
## `_add_box_collider` helpers instead.
func _build_gate() -> void:
	var gate: Dictionary = _config.get("gate", {})
	if gate.is_empty():
		return
	var at := _local(gate.get("at", []))
	if at == Vector2.INF:
		return
	var holder := Node3D.new()
	holder.name = "Gate"
	add_child(holder)

	var centre := world_of(at)
	var axis := _p  # the gate stands ACROSS the approach, so its span runs on t
	var opening := float(gate.get("opening", 6.8))
	var pier_w := float(gate.get("pier_width", 2.2))
	var pier_d := float(gate.get("pier_depth", 2.6))
	var pier_h := float(gate.get("pier_height", 7.2))
	var lintel_h := float(gate.get("lintel_height", 1.5))
	# +PI/2 so a box's local +X runs ALONG the axis: `rotation.y` maps local X
	# to (cos y, -sin y), which `atan2(x, y)` alone sends perpendicular. The
	# lintel spans the opening, so getting this backwards turns the gate ninety
	# degrees and the road walks straight past it. Same note, same reason, as
	# `_build_sealed_gate`'s.
	var yaw := atan2(axis.x, axis.y) + PI * 0.5

	var base := _ground(centre)
	if is_nan(base):
		return
	var offset := (opening + pier_w) * 0.5
	for side: float in [1.0, -1.0]:
		var spot := centre + axis * (offset * side)
		var ground := _ground(spot)
		if is_nan(ground):
			ground = base
		var pier: MeshInstance3D = _works.call("_stone_box", Vector3(pier_w, pier_h, pier_d))
		pier.name = "GatePier_%s" % ("a" if side > 0.0 else "b")
		pier.position = Vector3(spot.x, ground - 0.8 + pier_h * 0.5, spot.y)
		pier.rotation.y = yaw
		holder.add_child(pier)
		_works.call("_add_box_collider", holder, pier.position,
			Vector3(pier_w, pier_h, pier_d), yaw)

	var lintel: MeshInstance3D = _works.call("_stone_box",
		Vector3(opening + pier_w * 2.0, lintel_h, pier_d))
	lintel.name = "GateLintel"
	lintel.position = Vector3(centre.x, base - 0.8 + pier_h + lintel_h * 0.5, centre.y)
	lintel.rotation.y = yaw
	holder.add_child(lintel)

	# The faction band under the lintel: the one place on the compound that
	# says whose gate this is, in `palette.json`'s reserved oxblood.
	var band := MeshInstance3D.new()
	var band_mesh := BoxMesh.new()
	band_mesh.size = Vector3(opening + pier_w * 2.0, 0.55, pier_d * 0.55)
	band_mesh.material = _works.call("_tether_material")
	band.mesh = band_mesh
	band.name = "GateBand"
	band.position = Vector3(centre.x, base - 0.8 + pier_h - 0.3, centre.y)
	band.rotation.y = yaw
	holder.add_child(band)


## --- the traversal ---------------------------------------------------------


## Raised decks: a floor box on legs, with a collider that IS the floor box.
## `deck_y` is absolute world Y rather than a height over the ground, because
## a walkway whose pieces each floated over their own sampled ground would
## step up and down along its own length — the config says so too.
func _build_decks() -> void:
	var holder := Node3D.new()
	holder.name = "Decks"
	add_child(holder)
	for entry: Variant in _config.get("decks", []):
		if not entry is Dictionary:
			continue
		var deck: Dictionary = entry
		var at := _local(deck.get("at", []))
		var size := _local(deck.get("size", []))
		if at == Vector2.INF or size == Vector2.INF:
			continue
		var id := str(deck.get("id", "deck"))
		var top := float(deck.get("deck_y", 0.0))
		var centre := world_of(at)
		var yaw := atan2(_u.x, _u.y)
		# 0.4m of slab, its TOP at `deck_y`: a deck whose collider top sits
		# where the config says the floor is, so a player standing on it is
		# standing at the authored height and not 0.4m over it.
		var thickness := 0.4
		var mid := Vector3(centre.x, top - thickness * 0.5, centre.y)
		var slab: MeshInstance3D = _works.call("_stone_box",
			Vector3(size.x, thickness, size.y))
		slab.name = "Deck_%s" % id
		slab.position = mid
		slab.rotation.y = yaw
		holder.add_child(slab)
		_works.call("_add_box_collider", holder, mid, Vector3(size.x, thickness, size.y), yaw)

		# Legs, each running from its own sampled ground up to the slab. Solid
		# sides are what make the pad unreachable without the ramp, so a leg
		# that stops short of the ground is a hole in the traversal challenge.
		#
		# Which corners get one is configurable, and the gantry uses that: its
		# west end is where the ramp arrives, and a leg there stands INSIDE
		# the ramp's own width. The first build of this had exactly that bug
		# and the smoke test caught it as a player who climbed to within a
		# metre of the deck and stopped — walking into a pillar in the middle
		# of the only route to the console. The west end is carried by the
		# ramp structure it butts into instead.
		var half := size * 0.5
		var corners: Array = deck.get("legs", [[-1, -1], [1, -1], [-1, 1], [1, 1]])
		for raw: Variant in corners:
			var pair: Array = raw as Array if raw is Array else []
			if pair.size() < 2:
				continue
			var corner := Vector2(float(pair[0]), float(pair[1]))
			var spot := world_of(at + Vector2(half.x * corner.x, half.y * corner.y) * 0.82)
			var ground := _ground(spot)
			if is_nan(ground):
				continue
			var height := maxf(top - thickness - ground + 0.6, 0.4)
			var leg: MeshInstance3D = _works.call("_stone_box", Vector3(0.9, height, 0.9))
			leg.name = "Leg_%s_%.0f_%.0f" % [id, corner.x, corner.y]
			leg.position = Vector3(spot.x, ground - 0.3 + height * 0.5, spot.y)
			leg.rotation.y = yaw
			holder.add_child(leg)
			_works.call("_add_box_collider", holder, leg.position,
				Vector3(0.9, height, 0.9), yaw)
		_built["decks"] += 1


## The ramp up to the deck level. A pitched slab: a box rotated about the axis
## across its own run, with a collider carrying the same basis — the one piece
## of geometry here that `severed_spokes.gd`'s helpers cannot supply, because
## `_add_box_collider` only takes a yaw and a ramp needs a pitch.
func _build_ramps() -> void:
	var holder := Node3D.new()
	holder.name = "Ramps"
	add_child(holder)
	for entry: Variant in _config.get("ramps", []):
		if not entry is Dictionary:
			continue
		var ramp: Dictionary = entry
		var from := _local(ramp.get("from", []))
		var to := _local(ramp.get("to", []))
		if from == Vector2.INF or to == Vector2.INF:
			continue
		var foot_xz := world_of(from)
		var head_xz := world_of(to)
		var foot_y := _ground(foot_xz)
		if is_nan(foot_y):
			continue
		var head_y := float(ramp.get("deck_y", 0.0))
		var foot := Vector3(foot_xz.x, foot_y, foot_xz.y)
		var head := Vector3(head_xz.x, head_y, head_xz.y)
		var run := head - foot
		var length := run.length()
		if length < 1.0:
			continue
		var pitch := asin(clampf(run.y / length, -1.0, 1.0))
		if rad_to_deg(pitch) > 40.0:
			# 45 degrees is the player's own `floor_max_angle`; a ramp
			# authored at the limit is a ramp that sometimes refuses, which is
			# the worst possible failure for the one route to the console.
			push_warning("relay ramp '%s' is %.0f degrees — too steep to be reliably walkable"
				% [str(ramp.get("id", "ramp")), rad_to_deg(pitch)])
		var width := float(ramp.get("width", 3.0))
		var thickness := 0.5
		# Local X along the slope, local Y its surface normal, local Z across
		# it. Orthonormalised rather than trusted: a basis assembled from
		# cross products can drift a hair, and a non-orthonormal basis on a
		# StaticBody3D is a collider that quietly scales.
		var along := run / length
		var side := Vector3.UP.cross(along).normalized()
		var up := along.cross(side).normalized()
		var basis := Basis(along, up, along.cross(up)).orthonormalized()
		# Sunk half a thickness so the ramp's SURFACE runs foot-to-head, and a
		# further 0.12m so the foot meets the yard rather than presenting a lip
		# the player has to hop over.
		var mid := (foot + head) * 0.5 - up * (thickness * 0.5) - Vector3.UP * 0.12

		var slab := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(length + 0.6, thickness, width)
		mesh.material = _works.call("_stone_material")
		slab.mesh = mesh
		slab.name = "Ramp_%s" % str(ramp.get("id", "ramp"))
		slab.transform = Transform3D(basis, mid)
		holder.add_child(slab)

		var body := StaticBody3D.new()
		body.name = "RampCollision_%s" % str(ramp.get("id", "ramp"))
		body.transform = Transform3D(basis, mid)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(length + 0.6, thickness, width)
		shape.shape = box
		body.add_child(shape)
		holder.add_child(body)
		_built["ramps"] += 1


## --- the apparatus, and the seam it stands in ------------------------------


## *** THE HERO-ASSET SEAM. See this file's header and the config's own
## `_comment_apparatus` before changing anything under here. ***
##
## Everything below is PLACEHOLDER MASSING for
## `docs/art/reference/14_Relay_Apparatus.png`, which is owner-supplied, is
## one of D24's three Meshy hero objects, and was NOT generated in this build
## (no Meshy access; CLAUDE.md forbids improvising a hero object as final art).
## It is laid out as the board's own five labelled subassemblies so the swap
## is one-for-one, and it wears materials `severed_spokes.gd` already owns so
## it is honestly a placeholder rather than a second visual language.
##
## The only thing outside this node that anything else depends on is the child
## named `Console`.
func _build_apparatus() -> void:
	var apparatus: Dictionary = _config.get("apparatus", {})
	if apparatus.is_empty():
		return
	var at := _local(apparatus.get("at", []))
	if at == Vector2.INF:
		return
	var seam := Node3D.new()
	seam.name = "ApparatusSeam"
	add_child(seam)

	var centre := world_of(at)
	var deck_y := float(apparatus.get("deck_y", 0.0))
	var yaw := atan2(_u.x, _u.y)
	var massing: Dictionary = apparatus.get("massing", {})

	# THE SEAM, CLOSED. `model` names the generated hero mesh; when it is set,
	# it replaces the five massing subassemblies below and nothing else. The
	# console is still built by `_build_console` at its own authored spot — it
	# is the thing the player presses and it was never part of the massing —
	# and the body collider is still raised here, because "the player walks
	# around it rather than through it" is a property of the OBJECT, not of
	# whichever version of the object is standing.
	var model := str(apparatus.get("model", ""))
	if model != "" and ResourceLoader.exists(model):
		var scene := load(model) as PackedScene
		if scene != null:
			var instance := scene.instantiate() as Node3D
			if instance != null:
				instance.name = "Model"
				seam.add_child(instance)
				instance.rotation.y = yaw
				var tall := float(apparatus.get("height", 4.2))
				_fit_apparatus(instance, tall, Vector3(centre.x, deck_y, centre.y))
				_works.call("_add_box_collider", seam,
					Vector3(centre.x, deck_y + tall * 0.5, centre.y),
					Vector3(tall * 1.15, tall, tall * 1.15), yaw)
				_build_console(seam, apparatus)
				return
	var stone: StandardMaterial3D = _works.call("_stone_material")
	var faction: StandardMaterial3D = _works.call("_tether_material")
	var live: StandardMaterial3D = _works.call("_conduit_material", true)

	# 1. grounding base — the plinth and its splayed feet.
	var base: Dictionary = massing.get("grounding_base", {})
	var base_r := float(base.get("radius", 3.4))
	var base_h := float(base.get("height", 0.7))
	_cylinder(seam, "GroundingBase", Vector3(centre.x, deck_y + base_h * 0.5, centre.y),
		base_r, base_h, stone)
	var feet := int(base.get("feet", 6))
	var foot_l := float(base.get("foot_length", 1.6))
	for i in feet:
		var angle := TAU * float(i) / float(maxi(feet, 1))
		var dir := Vector2(cos(angle), sin(angle))
		var spot := centre + dir * (base_r + foot_l * 0.4)
		var foot := MeshInstance3D.new()
		var foot_mesh := BoxMesh.new()
		foot_mesh.size = Vector3(foot_l, 0.45, 0.7)
		foot_mesh.material = stone
		foot.mesh = foot_mesh
		foot.name = "GroundingFoot_%d" % i
		foot.position = Vector3(spot.x, deck_y + 0.22, spot.y)
		foot.rotation.y = -angle
		seam.add_child(foot)

	# 2. tether core — the central column.
	var core: Dictionary = massing.get("tether_core", {})
	var core_h := float(core.get("height", 6.4))
	_cylinder(seam, "TetherCore",
		Vector3(centre.x, deck_y + base_h + core_h * 0.5, centre.y),
		float(core.get("radius", 0.85)), core_h, faction)

	# 3. conductor rings — "core and rings serviceable" on the board.
	var rings: Dictionary = massing.get("conductor_ring", {})
	var ring_count := int(rings.get("rings", 3))
	var ring_r := float(rings.get("radius", 2.3))
	var ring_t := float(rings.get("thickness", 0.28))
	for i in ring_count:
		var y := deck_y + float(rings.get("lowest_y", 1.9)) + float(i) * float(rings.get("spacing", 1.5))
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = ring_r - ring_t
		torus.outer_radius = ring_r
		torus.material = live
		ring.mesh = torus
		ring.name = "ConductorRing_%d" % i
		ring.position = Vector3(centre.x, y, centre.y)
		seam.add_child(ring)

	# 4. conductor arms — "conductor arms and manifolds replaceable".
	var arms: Dictionary = massing.get("conductor_arms", {})
	var arm_count := int(arms.get("arms", 4))
	var arm_l := float(arms.get("length", 3.2))
	var arm_t := float(arms.get("thickness", 0.3))
	var arm_y := deck_y + float(arms.get("y", 3.1))
	for i in arm_count:
		var angle := TAU * float(i) / float(maxi(arm_count, 1)) + yaw
		var dir := Vector2(cos(angle), sin(angle))
		var spot := centre + dir * (arm_l * 0.5)
		var arm := MeshInstance3D.new()
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(arm_l, arm_t, arm_t)
		arm_mesh.material = faction
		arm.mesh = arm_mesh
		arm.name = "ConductorArm_%d" % i
		arm.position = Vector3(spot.x, arm_y, spot.y)
		arm.rotation.y = -angle
		seam.add_child(arm)

	# 5. output manifolds — where the conduit runs land.
	var manifolds: Dictionary = massing.get("output_manifolds", {})
	var manifold_count := int(manifolds.get("count", 4))
	var manifold_size := manifolds.get("size", [1.3, 1.5, 1.3]) as Array
	var manifold_r := float(manifolds.get("radius", 3.6))
	var size := Vector3(1.3, 1.5, 1.3)
	if manifold_size.size() >= 3:
		size = Vector3(float(manifold_size[0]), float(manifold_size[1]), float(manifold_size[2]))
	for i in manifold_count:
		var angle := TAU * float(i) / float(maxi(manifold_count, 1)) + yaw + PI * 0.25
		var dir := Vector2(cos(angle), sin(angle))
		var spot := centre + dir * manifold_r
		var manifold := MeshInstance3D.new()
		var manifold_mesh := BoxMesh.new()
		manifold_mesh.size = size
		manifold_mesh.material = faction
		manifold.mesh = manifold_mesh
		manifold.name = "OutputManifold_%d" % i
		manifold.position = Vector3(spot.x, deck_y + base_h + size.y * 0.5, spot.y)
		manifold.rotation.y = -angle
		seam.add_child(manifold)
		_works.call("_add_box_collider", seam, manifold.position, size, -angle)

	# The apparatus is solid: a box collider around the base and core, so the
	# player walks around it rather than through it.
	_works.call("_add_box_collider", seam,
		Vector3(centre.x, deck_y + (base_h + core_h) * 0.5, centre.y),
		Vector3(base_r * 1.5, base_h + core_h, base_r * 1.5), yaw)

	_build_console(seam, apparatus)


## The control console. The board details it down to individual routing
## levers; this is a cabinet with a lit face, and it is the ONE thing on this
## site the player presses a button on. Its node is named `Console` and found
## by that name, so the generated apparatus can bring its own.
## Stand a generated mesh at `foot`, at the authored height. A Meshy GLB comes
## back in the generator's units rather than metres, and its origin is wherever
## the exporter left it, so both the size and the footing are measured off the
## mesh's own visual bounds instead of trusted from its transform. Board 14's
## own scale guide puts a person at about this object's shoulder, which is what
## `apparatus.height` records.
func _fit_apparatus(instance: Node3D, tall: float, foot: Vector3) -> void:
	var bounds := _model_bounds(instance)
	if bounds.size.y <= 0.001:
		instance.position = foot
		return
	var factor := tall / bounds.size.y
	instance.scale = Vector3.ONE * factor
	instance.position = foot + Vector3(
		-bounds.get_center().x * factor,
		-bounds.position.y * factor,
		-bounds.get_center().z * factor)


func _model_bounds(instance: Node3D) -> AABB:
	var total := AABB()
	var seeded := false
	for child in instance.find_children("*", "VisualInstance3D", true, false):
		var visual := child as VisualInstance3D
		var here := instance.global_transform.affine_inverse() * visual.global_transform
		var box: AABB = here * visual.get_aabb()
		total = box if not seeded else total.merge(box)
		seeded = true
	return total


func _build_console(seam: Node3D, apparatus: Dictionary) -> void:
	var console: Dictionary = apparatus.get("console", {})
	if console.is_empty():
		return
	var at := _local(console.get("at", []))
	if at == Vector2.INF:
		return
	var spot := world_of(at)
	var deck_y := float(apparatus.get("deck_y", 0.0))
	var raw: Array = console.get("size", [1.6, 1.15, 0.9]) as Array
	var size := Vector3(1.6, 1.15, 0.9)
	if raw.size() >= 3:
		size = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	var yaw := atan2(_u.x, _u.y) + deg_to_rad(float(console.get("yaw_offset_deg", 180.0)))

	var holder := Node3D.new()
	holder.name = "Console"
	holder.position = Vector3(spot.x, deck_y, spot.y)
	seam.add_child(holder)

	var cabinet: MeshInstance3D = _works.call("_stone_box", size)
	cabinet.name = "Cabinet"
	cabinet.position = Vector3(0.0, size.y * 0.5, 0.0)
	cabinet.rotation.y = yaw
	holder.add_child(cabinet)

	# The face. Teal while live, and the reason the console is findable from
	# the gantry at all: everything else on this pad is stone and oxblood.
	var face := MeshInstance3D.new()
	var face_mesh := BoxMesh.new()
	face_mesh.size = Vector3(size.x * 0.72, size.y * 0.34, 0.12)
	face_mesh.material = _works.call("_conduit_material", true)
	face.mesh = face_mesh
	face.name = "Face"
	face.position = Vector3(0.0, size.y * 0.78, 0.0)
	face.rotation.y = yaw
	holder.add_child(face)

	_works.call("_add_box_collider", holder,
		Vector3(0.0, size.y * 0.5, 0.0), size, yaw)

	_console_prompt = INTERACTABLE.new()
	_console_prompt.name = "Interactable"
	_console_prompt.position = Vector3(0.0, size.y * 0.9, 0.0)
	_console_prompt.call("configure", str(console.get("label", "Disable the relay console")), 3.2, true)
	_console_prompt.connect("activated", _on_console_used)
	holder.add_child(_console_prompt)


## The one-way switch. Public and returning whether THIS call was the one that
## did it, so a test can press it twice without needing a second station —
## same shape and same reason as `burrow_warrens.gd::grant_clear_reward()`.
func disable_relay() -> bool:
	var progression := _progression()
	if progression == null:
		return false
	var console := _console()
	var gate := str(console.get("requires_flag", ""))
	if not gate.is_empty() and not bool(progression.call("has", gate)):
		_say(str(console.get("refused_message", "")))
		return false
	if bool(progression.call("has", console_flag())):
		return false
	progression.call("set_flag", console_flag())
	_kill_the_conduits()
	_sync_console()
	_say(str(console.get("done_message", "")))
	return true


func _on_console_used() -> void:
	disable_relay()


## Everything the relay was powering goes out. Done by MATERIAL IDENTITY
## rather than by node name: `severed_spokes.gd` caches exactly one lit pylon
## material, one dead one, one lit conduit material and one dead one, so every
## live surface on this site is literally the same object, and a node whose
## material IS the lit one is by definition a thing that was lit. Walking names
## instead would tie this to `_build_pylons`' private naming and break silently
## the day a span gets renamed.
func _kill_the_conduits() -> void:
	if _works == null:
		return
	var lit_pylon: Material = _works.call("_pylon_material", true)
	var dead_pylon: Material = _works.call("_pylon_material", false)
	var lit_conduit: Material = _works.call("_conduit_material", true)
	var dead_conduit: Material = _works.call("_conduit_material", false)
	for node: Node in _descendants(self):
		if not node is MeshInstance3D:
			continue
		var instance := node as MeshInstance3D
		if instance.material_override == lit_pylon:
			instance.material_override = dead_pylon
			continue
		# The spans and the apparatus rings carry their material on the MESH
		# (that is how `_conduit_segment` builds them), so an override is what
		# switches them off without touching the shared mesh resource.
		if instance.material_override == lit_conduit:
			instance.material_override = dead_conduit
			continue
		if instance.mesh != null and instance.mesh.get("material") == lit_conduit:
			instance.material_override = dead_conduit


## True once the conduits are dead — for the smoke test, which cannot read a
## material off a screenshot.
func lit_conduit_count() -> int:
	if _works == null:
		return 0
	var lit_pylon: Material = _works.call("_pylon_material", true)
	var lit_conduit: Material = _works.call("_conduit_material", true)
	var count := 0
	for node: Node in _descendants(self):
		if not node is MeshInstance3D:
			continue
		var instance := node as MeshInstance3D
		if instance.material_override != null:
			if instance.material_override == lit_pylon or instance.material_override == lit_conduit:
				count += 1
			continue
		if instance.mesh != null and instance.mesh.get("material") == lit_conduit:
			count += 1
	return count


## The prompt goes away for good once the flag is set. One-way means one-way:
## there is no re-enable, and a player who comes back finds a dead cabinet with
## nothing to press.
func _sync_console() -> void:
	if _console_prompt == null or not is_instance_valid(_console_prompt):
		return
	_console_prompt.call("set_enabled", not is_disabled())


## --- the conduit runs ------------------------------------------------------


## Three runs converging on the pad, on `SF33`'s pylon-and-span builder,
## borrowed the way `old_quarry.gd` borrows it — `_build_pylons` reads only a
## dictionary's `pylons` key, so each run goes in unchanged.
func _build_conduits() -> void:
	var conduits: Dictionary = _config.get("conduits", {})
	var runs: Array = conduits.get("runs", [])
	if runs.is_empty():
		return
	var height := float(conduits.get("height", 6.4))
	for entry: Variant in runs:
		if not entry is Dictionary:
			continue
		var run: Dictionary = entry
		var list: Array = run.get("list", [])
		if list.is_empty():
			continue
		# Authored in the site frame, handed to the builder in world metres.
		var world_list: Array = []
		for item: Variant in list:
			if not item is Dictionary:
				continue
			var pylon: Dictionary = (item as Dictionary).duplicate()
			var local := _local(pylon.get("at", []))
			if local == Vector2.INF:
				continue
			var at := world_of(local)
			pylon["at"] = [at.x, at.y]
			world_list.append(pylon)
		if world_list.is_empty():
			continue
		var holder := Node3D.new()
		holder.name = "Conduits_%s" % str(run.get("id", "run"))
		add_child(holder)
		_works.call("_build_pylons", _world, holder,
			{"pylons": {"height": height, "list": world_list}})
		_built["pylons"] += world_list.size()


## E3-RELAY-POPULATION follow-up (this pass): each conduit run above stops at
## its own LAST authored pylon, which sits several metres short of the
## apparatus centre by construction — the runs converge ON the site but never
## actually touch the object they power, which reads as pylons with nobody
## and nothing at the end of them. This adds exactly one more sagged span per
## listed run, from that run's own last pylon (its top-frame attach point, the
## same formula `severed_spokes.gd::_build_pylons` already uses) to a point on
## the apparatus's own footprint — `massing.grounding_base.radius` out from
## `apparatus.at`, toward whichever pylon is arriving, at half `apparatus.height`
## up from `deck_y`. Every number is read off this file's own `apparatus` and
## `conduits` blocks; nothing here is a guessed coordinate.
func _build_cable_links() -> void:
	var links: Dictionary = _config.get("cable_links", {})
	var run_ids: Array = links.get("runs", [])
	if run_ids.is_empty():
		return
	var apparatus: Dictionary = _config.get("apparatus", {})
	var app_at := _local(apparatus.get("at", []))
	if app_at == Vector2.INF:
		return
	var centre := world_of(app_at)
	var deck_y := float(apparatus.get("deck_y", 0.0))
	var tall := float(apparatus.get("height", 4.2))
	var massing: Dictionary = apparatus.get("massing", {})
	var base_r := float((massing.get("grounding_base", {}) as Dictionary).get("radius", 3.4))

	var conduits: Dictionary = _config.get("conduits", {})
	var height := float(conduits.get("height", 6.4))
	var runs: Array = conduits.get("runs", [])
	if runs.is_empty():
		return

	var holder := Node3D.new()
	holder.name = "CableLinks"
	add_child(holder)
	# The SAME cached lit-conduit material every span already carries, by
	# identity — so `_kill_the_conduits`' material-identity sweep turns these
	# off with everything else the moment the console goes quiet, with no
	# separate bookkeeping.
	var live: StandardMaterial3D = _works.call("_conduit_material", true)

	var index := 0
	for entry: Variant in runs:
		if not entry is Dictionary:
			continue
		var run: Dictionary = entry
		if not run_ids.has(str(run.get("id", ""))):
			continue
		var list: Array = run.get("list", [])
		if list.is_empty() or not list[list.size() - 1] is Dictionary:
			continue
		var last_local := _local((list[list.size() - 1] as Dictionary).get("at", []))
		if last_local == Vector2.INF:
			continue
		var pylon_xz := world_of(last_local)
		var ground := _ground(pylon_xz)
		if is_nan(ground):
			continue
		# Same base_y/attach-height formula `_build_pylons` uses, so this span's
		# OWN end genuinely lands where that pylon's cable frame is, not near it.
		var attach := Vector3(pylon_xz.x, ground - 0.22 + height * 0.66, pylon_xz.y)
		var dir := (pylon_xz - centre)
		if dir.length() < 0.01:
			dir = Vector2(_u.x, _u.y)
		dir = dir.normalized()
		var landing := Vector3(
			centre.x + dir.x * base_r, deck_y + tall * 0.5, centre.y + dir.y * base_r)
		_works.call("_conduit_span", holder, index, attach, landing, live, 0.6)
		index += 1


## --- the drained ground ----------------------------------------------------


## D41 at full strength, and an honest partial — the config's own
## `_comment_dead_ground` says why. The AUTHORED drain lives in
## `terrain_playground.json`'s `drains.stations` and this branch adds three
## entries there, the strongest at 1.0 against the quarry head station's 0.85.
## `scatter_rules.gd` reads that immediately at run time and the vegetation is
## already gone; the bake's colour and control maps are offline artefacts and
## have NOT been re-baked here (a sibling agent holds the terrain lease).
##
## This skin stands in for the missing bake and nothing else. Its alpha is
## `playground_heightfield.drain_factor()` itself, so it dies out on exactly
## the contour the bake will, and turning it off after a re-bake is one boolean
## in the config. It carries no collider and is on no layer: it is paint.
func _build_dead_ground() -> void:
	var config: Dictionary = _config.get("dead_ground", {})
	if not bool(config.get("enabled", false)):
		return
	var field: RefCounted = HEIGHTFIELD.new()
	if not field.has_method("drain_factor"):
		return
	var radius := float(config.get("radius", 46.0))
	var cell := maxf(float(config.get("cell", 3.0)), 1.0)
	var lift := float(config.get("lift", 0.09))
	var tint := Color(str(config.get("tint", "#a89d84")))
	var max_alpha := clampf(float(config.get("max_alpha", 0.72)), 0.0, 1.0)

	var steps := int(ceil(radius * 2.0 / cell))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wrote := false
	for i in steps:
		for j in steps:
			var quad: Array = []
			var any := false
			for corner: Vector2 in [Vector2(0.0, 0.0), Vector2(1.0, 0.0),
					Vector2(1.0, 1.0), Vector2(0.0, 1.0)]:
				var x := _centre.x - radius + (float(i) + corner.x) * cell
				var z := _centre.y - radius + (float(j) + corner.y) * cell
				var ground := _ground(Vector2(x, z))
				if is_nan(ground):
					quad.clear()
					break
				var alpha := float(field.call("drain_factor", x, z)) * max_alpha
				if alpha > 0.01:
					any = true
				quad.append([Vector3(x, ground + lift, z), alpha])
			if quad.size() < 4 or not any:
				continue
			for triangle: Array in [[0, 1, 2], [0, 2, 3]]:
				for index: int in triangle:
					var point: Array = quad[index]
					surface.set_color(Color(tint.r, tint.g, tint.b, float(point[1])))
					surface.add_vertex(point[0] as Vector3)
			wrote = true
	if not wrote:
		return
	surface.generate_normals()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(material)
	var skin := MeshInstance3D.new()
	skin.name = "DeadGround"
	skin.mesh = surface.commit()
	skin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(skin)
	_dead_ground = skin
	_dead_ground_material = material


## E3-RELAY-POPULATION (ralph/reports/audit/E-2026-08-31.md §E3): the hero
## hardware reads as hostile tech on its own, but the compound had no mark of
## anything having HAPPENED here — no scorch, no damage, nothing beyond static
## massing and the drained-ground skin `_build_dead_ground` above already
## paints. This is the difference between "an installation" and "an
## installation somebody has been fighting at, or that has been running long
## enough to scar its own ground" — small, irregular, charred patches at the
## points a working station would actually mark: right where a posted guard
## stands, and at the workstation the loose tools now sit at.
##
## Same no-new-asset shape `_build_dead_ground` already uses: a flat irregular
## polygon, painted rather than modelled, seeded per mark so two marks never
## trace the same silhouette. No collider and no shadow — it is paint on the
## ground, not an object standing on it.
func _build_scorch_marks() -> void:
	var marks: Array = _config.get("scorch_marks", [])
	if marks.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "ScorchMarks"
	add_child(holder)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness = 1.0
	material.metallic = 0.0
	for entry: Variant in marks:
		if not entry is Dictionary:
			continue
		var mark: Dictionary = entry
		var at := _local(mark.get("at", []))
		if at == Vector2.INF:
			continue
		var centre := world_of(at)
		# `deck_y` (optional): E-relay-dress's apparatus-pad ring. A mark under
		# the raised pad has no business sampling the REAL ground two-to-eight
		# metres below the slab — nobody standing on the platform could ever
		# see paint down there. When present this is the deck's own authored
		# top surface (the same value `decks[].deck_y` already uses), so the
		# scorch sits on the concrete the player actually walks on.
		var deck_y_raw: Variant = mark.get("deck_y", null)
		var y: float
		if deck_y_raw != null:
			y = float(deck_y_raw) + 0.03
		else:
			var ground := _ground(centre)
			if is_nan(ground):
				continue
			y = ground + 0.03
		var radius := float(mark.get("radius", 1.6))
		var id := str(mark.get("id", "mark"))
		_scorch_patch(holder, "Scorch_%s" % id, Vector3(centre.x, y, centre.y),
			radius, hash(id), material)


## One irregular, roughly-circular splat: a triangle fan whose rim wobbles
## per-vertex (0.55-1.0x the nominal radius) so it reads as burnt/cracked
## ground rather than a perfect painted disc. Seeded off the mark's own id, so
## re-running the world build produces the same shape rather than a new one
## every load.
func _scorch_patch(parent: Node3D, node_name: String, at: Vector3, radius: float,
		seed_value: int, material: StandardMaterial3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var segments := 10
	var colour := Color(0.05, 0.045, 0.04, 0.82)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim: Array[Vector3] = []
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		var r := radius * rng.randf_range(0.55, 1.0)
		rim.append(Vector3(cos(angle) * r, 0.0, sin(angle) * r))
	for i in segments:
		var a := rim[i]
		var b := rim[(i + 1) % segments]
		surface.set_color(colour)
		surface.add_vertex(Vector3.ZERO)
		surface.set_color(Color(colour.r, colour.g, colour.b, colour.a * 0.35))
		surface.add_vertex(a)
		surface.add_vertex(b)
	surface.generate_normals()
	surface.set_material(material)
	var patch := MeshInstance3D.new()
	patch.name = node_name
	patch.mesh = surface.commit()
	patch.position = at
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(patch)


## --- loose dressing (E-relay-dress) -----------------------------------------
##
## The occupation layer that is not people or the drained-ground/scorch skin:
## the platform's own loose gear, a barricade across the approach, and the
## site's one banner. None of it belongs in `props.json` — the platform sits
## at an absolute `deck_y` rather than sampled ground, and the barrier/banner
## are authored in this file's own local (s,t) frame the way everything else
## here is — so it is loaded and placed locally, through the exact same
## gltf/glb/obj loading `props.gd::place()` already established (the fallback
## order, the OBJ-as-bare-mesh wrap, the combined-AABB collider, the
## `retint`/dielectric-material treatment) rather than a second, subtly
## different copy of it.


## One prop scene, instantiated but not yet placed. `null` (with a warning) if
## `model` cannot be found under `dir` in any of the three formats this
## codebase's prop packs ship in.
func _load_dressing_scene(model: String, dir: String) -> Node3D:
	var gltf_path := "%s/%s.gltf" % [dir, model]
	var glb_path := "%s/%s.glb" % [dir, model]
	var obj_path := "%s/%s.obj" % [dir, model]
	var root: Node3D = null
	if ResourceLoader.exists(gltf_path):
		var packed := load(gltf_path) as PackedScene
		if packed != null:
			root = packed.instantiate()
	elif ResourceLoader.exists(glb_path):
		var packed := load(glb_path) as PackedScene
		if packed != null:
			root = packed.instantiate()
	elif ResourceLoader.exists(obj_path):
		var mesh := load(obj_path) as Mesh
		if mesh != null:
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			root = mi
	if root == null:
		push_warning("relay dressing prop missing: %s (looked under %s)" % [model, dir])
	return root


## One dressing prop from one spec, into `holder`. `deck_y`: null places it on
## sampled ground (minus `sink_m`, the same key `props.gd` uses); a float
## places it AT that absolute height instead (minus `sink_m`), for anything
## standing on the raised pad rather than the yard. Position and facing are
## both authored in this file's own local (s,t) frame — `yaw_offset_deg` is
## added to the site's own approach-facing yaw, the same convention the gate
## band, the console and the apparatus itself already use, rather than a raw
## world angle every entry would have to work out by hand.
func _place_dressing_prop(holder: Node3D, spec: Dictionary, deck_y: Variant) -> bool:
	var model := str(spec.get("model", ""))
	if model.is_empty():
		return false
	var at := _local(spec.get("at", []))
	if at == Vector2.INF:
		push_warning("relay dressing prop '%s' has no `at`" % model)
		return false
	var root := _load_dressing_scene(model, str(spec.get("dir", "res://assets/props/quaternius_fantasy")))
	if root == null:
		return false

	var world_xz := world_of(at)
	var sink := float(spec.get("sink_m", 0.0))
	var y: float
	if deck_y != null:
		y = float(deck_y) - sink
	else:
		var ground := _ground(world_xz)
		if is_nan(ground):
			push_warning("no ground under relay dressing prop '%s'" % model)
			return false
		y = ground - sink

	IMPORTED_MATERIALS.make_dielectric(root)
	root.name = str(spec.get("name", model))
	root.position = Vector3(world_xz.x, y, world_xz.y)
	var base_yaw := atan2(_u.x, _u.y)
	root.rotation = Vector3(
		deg_to_rad(float(spec.get("pitch_deg", 0.0))),
		base_yaw + deg_to_rad(float(spec.get("yaw_offset_deg", 0.0))),
		deg_to_rad(float(spec.get("roll_deg", 0.0))))
	var scale_factor := float(spec.get("scale", 1.0))
	root.scale = Vector3.ONE * scale_factor
	holder.add_child(root)

	var retint: Variant = spec.get("retint", {})
	if retint is Dictionary and not (retint as Dictionary).is_empty():
		if _prefabs == null:
			_prefabs = BUILDING_PREFABS.new()
		_prefabs.call("apply_retint", root, retint)

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root, meshes)
	if meshes.is_empty():
		push_warning("relay dressing prop '%s' has no mesh; placed with no collider" % model)
		return true
	var to_root_local := root.global_transform.affine_inverse()
	var aabb: AABB = to_root_local * (meshes[0].global_transform * meshes[0].get_aabb())
	for i in range(1, meshes.size()):
		aabb = aabb.merge(to_root_local * (meshes[i].global_transform * meshes[i].get_aabb()))
	var body := StaticBody3D.new()
	body.name = "%s_Collision" % root.name
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size * scale_factor
	shape.shape = box
	body.add_child(shape)
	body.position = root.global_transform * (aabb.position + aabb.size * 0.5)
	body.rotation = root.rotation
	holder.add_child(body)
	return true


func _collect_meshes(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, into)


## The work platform's own loose gear — one compact cluster in the pad's
## south-east corner, clear of the apparatus footprint and the console. See
## `deck_props._comment_deck_props` in the config for the exact clearances.
func _build_deck_props() -> void:
	var config: Dictionary = _config.get("deck_props", {})
	var list: Array = config.get("list", [])
	if list.is_empty():
		return
	var deck_y := float(config.get("deck_y", 10.0))
	var holder := Node3D.new()
	holder.name = "DeckProps"
	add_child(holder)
	for entry: Variant in list:
		if entry is Dictionary:
			_place_dressing_prop(holder, entry as Dictionary, deck_y)


## The barricade across the approach, short of the gate. See `barrier.
## _comment_barrier` in the config.
func _build_barrier() -> void:
	var config: Dictionary = _config.get("barrier", {})
	var list: Array = config.get("list", [])
	if list.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "Barrier"
	add_child(holder)
	for entry: Variant in list:
		if entry is Dictionary:
			_place_dressing_prop(holder, entry as Dictionary, null)


## The site's one banner. See `banner._why` in the config.
func _build_banner() -> void:
	var config: Dictionary = _config.get("banner", {})
	if config.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "Banner"
	add_child(holder)
	_place_dressing_prop(holder, config, null)


## SG46 / D41's third clause. The relay's machinery is dead, so the skin that
## stands in for the drained ground goes with it.
##
## This is the ONE part of the drained-ground grammar that can heal at run
## time, and it can only because of an accident of build order that D45 wrote
## down: the relay's stations were never baked into the terrain's colour and
## control maps (a sibling agent held the terrain lease), so its discolouration
## is this skin -- a runtime overlay whose alpha is drain_factor() -- rather
## than a texel. The quarry's stations WERE baked and cannot be undone without
## a re-bake, which SG46 is explicitly not allowed to run.
##
## The fade is the material's own albedo alpha, which multiplies the per-vertex
## alpha the drain contour is stored in, so the skin dies out preserving its
## shape rather than shrinking to a circle: the ground pales from what it was,
## everywhere at once, which is what "the tether let go" looks like.
##
## `seconds <= 0` snaps, for a save loaded with the flag already set.
func heal(seconds: float = 0.0) -> void:
	if _dead_ground == null or not is_instance_valid(_dead_ground):
		return
	if _healing:
		return
	if seconds <= 0.0:
		_finish_healing()
		return
	_healing = true
	_heal_seconds = seconds
	_heal_elapsed = 0.0
	set_process(true)


func _process(delta: float) -> void:
	if not _healing:
		set_process(false)
		return
	_heal_elapsed += delta
	var fraction := clampf(_heal_elapsed / maxf(_heal_seconds, 0.01), 0.0, 1.0)
	if _dead_ground_material != null:
		_dead_ground_material.albedo_color.a = 1.0 - fraction
	if fraction >= 1.0:
		_finish_healing()


func _finish_healing() -> void:
	_healing = false
	set_process(false)
	if _dead_ground_material != null:
		_dead_ground_material.albedo_color.a = 0.0
	if _dead_ground != null and is_instance_valid(_dead_ground):
		_dead_ground.visible = false
	_healed = true


## Whether the drained skin is still painting the ground. Read by SG46's own
## test, which has to prove the relay looks different after the Warden rather
## than trust that something called heal().
func dead_ground_visible() -> bool:
	return _dead_ground != null and is_instance_valid(_dead_ground) and _dead_ground.visible \
		and (_dead_ground_material == null or _dead_ground_material.albedo_color.a > 0.01)


func healed() -> bool:
	return _healed


## --- plumbing --------------------------------------------------------------


func _cylinder(parent: Node3D, node_name: String, at: Vector3, radius: float,
		height: float, material: StandardMaterial3D) -> void:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = material
	instance.mesh = mesh
	instance.name = node_name
	instance.position = at
	parent.add_child(instance)


func _console() -> Dictionary:
	return (_config.get("apparatus", {}) as Dictionary).get("console", {}) as Dictionary


func _ground(at: Vector2) -> float:
	if _world == null or not _world.has_method("ground_height_at"):
		return NAN
	return float(_world.call("ground_height_at", at.x, at.y))


func _local(raw: Variant) -> Vector2:
	var array: Array = raw as Array if raw is Array else []
	if array.size() < 2:
		return Vector2.INF
	return Vector2(float(array[0]), float(array[1]))


func _progression() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return null
	return game.get("progression") as RefCounted


func _say(message: String) -> void:
	if message.is_empty():
		return
	var game := get_node_or_null(^"/root/Game")
	if game != null and game.has_method("push_world_message"):
		game.call("push_world_message", message)


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in node.get_children():
		out.append(child)
		out.append_array(_descendants(child))
	return out


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
