extends Node3D

## SA4 — the seven old roads out of the Meadows, and what severed each of them.
##
## Spec §1E asks for seven outward routes so the Meadows does not read as an
## island. §29 is what stops that being seven dead ends: "Team Tether did not
## build seven random dead-end roads. They severed existing connections." So
## every spoke here is a ROAD FIRST — a real polyline in
## `terrain_playground.json`'s new `spokes` section, unioned into the path
## network by `playground_heightfield.road_polylines()`, which means the bake
## paints the same trodden soil along it that the village's own four routes
## get, the scatter keeps grass and trees off it, and path-anchored stone
## follows it out. Only then does something stand at the end of it.
##
## HARD RULE, from the backlog item and §19: none of this may ever explain
## itself with UI text. There is no prompt, no "Biome Locked", no interactable
## anywhere in this file. The only words on a spoke are on a fingerpost, and
## they name the place the road used to go, never its condition.
##
## What each kind is made of, and why nothing here is new vocabulary (D24):
##
##   `gorge` / `collapsed_bridge`  The blocker is the TERRAIN. Both carry a
##     `carve` block that `playground_heightfield._spoke_carve` cuts into the
##     heightfield at bake time, 11-16m deep with 57-66 degree walls — well
##     past the player's 45-degree `floor_max_angle`, so the ground itself
##     refuses. This file only dresses the lip: tumbled kerbstones off the
##     broken roadbed, and for the bridge two masonry abutments facing each
##     other across the channel with nothing between them.
##
##   `rockslide`  Props and collision, no terrain change and therefore no
##     re-bake. `Rock_Medium_*` from the one nature family, scaled far past
##     the meadow scatter's own ceiling so they read as slide debris rather
##     than as meadow stones, each with its own collider, over a buried
##     continuous barrier that closes the gaps between them. §1E allows
##     invisible collision "as support for visible boundaries, not as the only
##     boundary" — the barrier's top sits below the pile's own silhouette, so
##     it is never what the player sees, only what they cannot walk through.
##
## Masonry is the Quaternius medieval kit's `T_UnevenBrick` sheet, the same
## one `world_perimeter.gd`, `grandpa_house.gd` and every buildable already
## use. Rocks are the same three `Rock_Medium_*` meshes the vegetation scatter
## and the boundary's rock-formation style already place. No new asset, no
## generation.

const SPOKE_CONFIG := "res://data/config/terrain_playground.json"
const PALETTE_CONFIG := "res://data/config/palette.json"
const SIGNPOST := preload("res://scripts/world/signpost.gd")

const ROCK_MESHES := [
	preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
]
## The `Rock_Medium_*` meshes stand about this tall at scale 1, measured the
## same way `world_perimeter.gd` measures them. Used to seat a block so it sits
## IN the ground rather than tangent to it.
const ROCK_MODEL_HEIGHT := 2.2

const STONE_ALBEDO := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png")
const STONE_NORMAL := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png")
const STONE_ROUGHNESS := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png")
const STONE_TILE := 3.2

## How far below the lower of a carve's two lips its failsafe volume stops. Big
## enough that a player standing ON the lip is never inside it, small enough
## that a player who has gone over is always inside it. TUNABLE.
const LIP_CLEARANCE := 3.0

## How far back from a carve's outer rim the player is put when the failsafe
## catches them. Far enough that they are standing on flat road, not on the
## rim's own slope. TUNABLE.
const RECOVERY_CLEARANCE := 6.0

## A tumbled kerbstone off the broken roadbed. Small, and small on purpose:
## these are the edge of a road, not boulders.
const KERB_SIZE := Vector3(0.9, 0.42, 0.62)

var _built: Array[String] = []
var _stone_material_cache: StandardMaterial3D = null
var _tether_material_cache: StandardMaterial3D = null


## `world` is only ever asked for `ground_height_at` — the same duck-typed
## climb `village.gd` and `road_gate.gd` use, and never a raycast (D09).
func build(world: Node3D) -> void:
	var config := _load_config()
	var routes: Array = config.get("routes", [])
	if routes.is_empty():
		push_warning("no `spokes.routes` in %s; the Meadows has no outward roads" % SPOKE_CONFIG)
		return
	var seed_value := int(config.get("seed", 0))

	for entry: Variant in routes:
		if not entry is Dictionary:
			continue
		var spoke: Dictionary = entry as Dictionary
		var id := str(spoke.get("id", ""))
		if id.is_empty():
			push_warning("a spoke entry has no `id` — skipped")
			continue
		if not bool(spoke.get("built", false)):
			continue
		var holder := Node3D.new()
		holder.name = "Spoke_%s" % id
		add_child(holder)
		_build_blocker(world, holder, spoke, seed_value)
		_build_sign(world, spoke, id)
		_built.append(id)


## Which spokes actually stood, for the boot log and for tests.
func built() -> Array[String]:
	return _built


func _build_blocker(world: Node3D, holder: Node3D, spoke: Dictionary, seed_value: int) -> void:
	var blocker: Dictionary = spoke.get("blocker", {})
	var kind := str(blocker.get("kind", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + hash(str(spoke.get("id", "")))
	match kind:
		"gorge":
			_build_gorge_lip(world, holder, blocker, rng)
		"collapsed_bridge":
			_build_collapsed_bridge(world, holder, blocker, rng)
		"rockslide":
			_build_rockslide(world, holder, blocker, rng)
		"sealed_road":
			_build_sealed_road(world, holder, blocker, rng)
		"sealed_gate":
			_build_sealed_gate(world, holder, blocker)
		"fallen_roadbed":
			_build_fallen_roadbed(world, holder, blocker, rng)
		_:
			push_warning("spoke blocker kind '%s' is authored but has no builder yet" % kind)

	# Any blocker whose blocker IS a trench can drop the player into it, so the
	# failsafe is hung off the carve rather than off the kind — see
	# `_add_carve_failsafe`. It recovers to the spoke's own road end.
	var carve: Dictionary = blocker.get("carve", {})
	var road: Array = spoke.get("road", [])
	if not carve.is_empty() and road.size() >= 2:
		_add_carve_failsafe(world, holder, carve, road)


## The carve is the blocker; this is the broken roadbed at its edge. Stones
## tipped along the near lip, and (for the gorge) the same again on the far
## lip so the road visibly RESUMES across the gap — §29's "distant land",
## close enough to read.
func _build_gorge_lip(world: Node3D, holder: Node3D, blocker: Dictionary, rng: RandomNumberGenerator) -> void:
	var carve: Dictionary = blocker.get("carve", {})
	var centre := _vec2(carve.get("centre", []))
	if centre == Vector2.INF:
		return
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var across := Vector2(-axis.y, axis.x)
	var lip: float = float(carve.get("half_width", 9.0)) + float(carve.get("rim", 7.0)) * 0.85
	var span := float(blocker.get("lip_span", 11.0))
	var count := int(blocker.get("lip_stones", 9))
	var sides: Array = [1.0, -1.0] if bool(blocker.get("far_lip", false)) else [1.0]
	var transforms: Array = []
	for side: float in sides:
		for i in count:
			var along := (rng.randf() - 0.5) * 2.0 * span
			var out := lip + rng.randf_range(-0.9, 1.4)
			var at := centre + axis * along + across * (out * side)
			var ground := float(world.call("ground_height_at", at.x, at.y))
			if is_nan(ground):
				continue
			var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
			basis = basis.rotated(axis3(axis), rng.randf_range(-0.55, 0.55))
			basis = basis.scaled(Vector3.ONE * rng.randf_range(0.85, 1.35))
			transforms.append(Transform3D(basis, Vector3(at.x, ground - 0.12, at.y)))
	if transforms.is_empty():
		return
	_batch_boxes(holder, "LipStones", KERB_SIZE, transforms)


## Two abutments and no deck. The gap between them is the carve; nothing this
## function places is walkable, and nothing bridges.
func _build_collapsed_bridge(world: Node3D, holder: Node3D, blocker: Dictionary, rng: RandomNumberGenerator) -> void:
	var carve: Dictionary = blocker.get("carve", {})
	var centre := _vec2(carve.get("centre", []))
	if centre == Vector2.INF:
		return
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var across := Vector2(-axis.y, axis.x)
	var size: Dictionary = blocker.get("abutment", {})
	var width := float(size.get("width", 5.4))
	var depth := float(size.get("depth", 3.2))
	var height := float(size.get("height", 3.1))
	var stand: float = float(carve.get("half_width", 6.0)) + float(carve.get("rim", 5.0)) * 0.55

	# +PI/2 so the abutment's `width` runs along the lip and its `depth` along the
	# road, and so the fallen beam (long in local Z) points ACROSS the gap and
	# tips into it about local X. Without it both are rotated ninety degrees:
	# stage 1 wrote this line before the scene had ever been booted.
	var yaw := atan2(axis.x, axis.y) + PI * 0.5
	for side: float in [1.0, -1.0]:
		var at := centre + across * (stand * side)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var block := _stone_box(Vector3(width, height, depth))
		block.name = "Abutment_%s" % ("near" if side > 0.0 else "far")
		block.position = Vector3(at.x, ground - 0.9 + height * 0.5, at.y)
		block.rotation.y = yaw
		holder.add_child(block)
		_add_box_collider(holder, block.position, Vector3(width, height, depth), yaw)

	if bool(blocker.get("fallen_beam", true)):
		var at := centre + across * (stand * 0.55)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if not is_nan(ground):
			var beam := _stone_box(Vector3(0.55, 0.42, 6.2))
			beam.name = "FallenDeck"
			beam.position = Vector3(at.x, ground + 0.9, at.y)
			beam.rotation.y = yaw
			beam.rotate_object_local(Vector3.RIGHT, deg_to_rad(38.0))
			holder.add_child(beam)

	_build_gorge_lip(world, holder, blocker, rng)


## The one blocker that needs no terrain change: a slide of mountain rock
## lying across the trail, over a buried barrier that closes the gaps.
func _build_rockslide(world: Node3D, holder: Node3D, blocker: Dictionary, rng: RandomNumberGenerator) -> void:
	var centre := _vec2(blocker.get("centre", []))
	if centre == Vector2.INF:
		return
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(blocker.get("axis_deg", 0.0))))
	var across := Vector2(-axis.y, axis.x)
	var span := float(blocker.get("span", 24.0))
	var half := span * 0.5

	var blocks := int(blocker.get("blocks", 13))
	var scale_min := float(blocker.get("block_scale_min", 1.8))
	var scale_max := float(blocker.get("block_scale_max", 3.6))
	for i in blocks:
		# Spread the big stones evenly across the trail rather than randomly:
		# a random draw leaves holes, and a hole in a rockslide is a route.
		var t := (float(i) + rng.randf_range(0.25, 0.75)) / float(blocks)
		var along := lerpf(-half, half, t)
		var at := centre + axis * along + across * rng.randf_range(-2.2, 2.2)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var scale := rng.randf_range(scale_min, scale_max)
		var rock := MeshInstance3D.new()
		rock.name = "Slide_%d" % i
		rock.mesh = _rock_mesh(rng.randi() % ROCK_MESHES.size())
		rock.scale = Vector3.ONE * scale
		rock.rotation.y = rng.randf_range(0.0, TAU)
		rock.rotate_object_local(Vector3.RIGHT, rng.randf_range(-0.35, 0.35))
		# Bury a fifth of each block, the way the mound anchors do, so the
		# slide sits in the hillside instead of resting on it.
		rock.position = Vector3(at.x, ground - ROCK_MODEL_HEIGHT * scale * 0.2, at.y)
		holder.add_child(rock)

	var rubble := int(blocker.get("rubble", 18))
	var rubble_min := float(blocker.get("rubble_scale_min", 0.3))
	var rubble_max := float(blocker.get("rubble_scale_max", 0.9))
	for i in rubble:
		var at := centre + axis * rng.randf_range(-half * 1.25, half * 1.25) \
			+ across * rng.randf_range(-6.5, 6.5)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var scale := rng.randf_range(rubble_min, rubble_max)
		var stone := MeshInstance3D.new()
		stone.name = "Rubble_%d" % i
		stone.mesh = _rock_mesh(rng.randi() % ROCK_MESHES.size())
		stone.scale = Vector3.ONE * scale
		stone.rotation.y = rng.randf_range(0.0, TAU)
		stone.position = Vector3(at.x, ground - ROCK_MODEL_HEIGHT * scale * 0.25, at.y)
		holder.add_child(stone)

	# The buried barrier. Segmented so it follows the ground the pile lies on
	# rather than hanging over a dip at one end, exactly the failure OF7 fixed
	# in the boundary ring.
	var barrier_height := float(blocker.get("barrier_height", 4.2))
	var thickness := float(blocker.get("barrier_thickness", 3.6))
	var segments := 8
	var yaw := atan2(axis.x, axis.y) + PI * 0.5
	for i in segments:
		var t := (float(i) + 0.5) / float(segments)
		var at := centre + axis * lerpf(-half, half, t)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var length := span / float(segments) + 1.2
		var mid := Vector3(at.x, ground - 1.0 + barrier_height * 0.5, at.y)
		_add_box_collider(holder, mid, Vector3(length, barrier_height, thickness), yaw)


## A trench that stops the player by swallowing them is not a blocker, it is a
## soft-lock. The stage-2 probe caught exactly that: walked at the river gorge,
## the player did not cross it — they went over the lip, fell 12m, and came to
## rest on the floor at y=-30.7 inside 66-degree walls with no way out. The
## storm ravine did the same at y=-9.5. `world_perimeter.gd`'s own failsafe
## cannot help: its plane is at KILL_PLANE_Y, far below both floors, and the
## map's legitimate low ground now reaches -37m, so no single global plane can
## tell a gorge floor from a valley.
##
## So each carve that a player can fall into gets the SAME mechanism scoped to
## itself — spec §1E's "backup kill/respawn volume ... only as a failsafe",
## applied to a hole the design deliberately dug. It returns the player to the
## end of that spoke's own road rather than to the village: they slipped at the
## edge and scrambled back from it, which is a smaller lie than waking up in
## the square. Opt-in per carve (`"failsafe": true`) rather than automatic,
## because a notch cut into a hillside flank has natural ground at the same
## altitude beside it and a blanket volume there would catch honest walking.
func _add_carve_failsafe(world: Node3D, holder: Node3D, carve: Dictionary, road: Array) -> void:
	if not bool(carve.get("failsafe", false)):
		return
	var centre := _vec2(carve.get("centre", []))
	if centre == Vector2.INF:
		return
	var floor_y := float(world.call("ground_height_at", centre.x, centre.y))
	if is_nan(floor_y):
		push_warning("carve failsafe at %s has no ground to measure; skipped" % centre)
		return
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var recover_to := _recovery_point(carve, centre, axis, road)
	var recover_y := float(world.call("ground_height_at", recover_to.x, recover_to.y))
	if is_nan(recover_y):
		push_warning("carve failsafe at %s has nowhere to put the player back; skipped" % centre)
		return
	var half_length := float(carve.get("half_length", 40.0)) + float(carve.get("end_fade", 16.0))
	# Narrower than the full rim on purpose: the volume must sit between the
	# walls, never under the lip a player is legitimately standing on.
	var half_width := float(carve.get("half_width", 6.0)) + float(carve.get("rim", 5.0)) * 0.4
	# The ceiling is measured DOWN FROM THE LIP, not up from the floor sample.
	# First attempt put it at floor + 3m and the gorge failsafe never fired:
	# its floor rises along its own axis, so a body that slid a few metres
	# downstream came to rest at exactly the box's top edge. The lip is the
	# thing that must stay clear, so let the lip define the clearance and let
	# the box swallow everything below it.
	var across := Vector2(-axis.y, axis.x)
	var reach: float = float(carve.get("half_width", 6.0)) + float(carve.get("rim", 5.0))
	var lip_y := INF
	for side: float in [1.0, -1.0]:
		var at := centre + across * (reach * side)
		var sample := float(world.call("ground_height_at", at.x, at.y))
		if not is_nan(sample):
			lip_y = minf(lip_y, sample)
	if is_inf(lip_y):
		lip_y = floor_y + float(carve.get("depth", 12.0))
	var top := lip_y - LIP_CLEARANCE
	var bottom: float = floor_y - float(carve.get("depth", 12.0))
	var height: float = maxf(top - bottom, 2.0)
	var mid_y := bottom + height * 0.5

	var area := Area3D.new()
	area.name = "CarveFailsafe"
	area.position = Vector3(centre.x, mid_y, centre.y)
	area.rotation.y = atan2(axis.x, axis.y) + PI * 0.5
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half_length * 2.0, height, half_width * 2.0)
	shape.shape = box
	area.add_child(shape)
	area.set_meta("recover_to", Vector3(recover_to.x, recover_y + 1.0, recover_to.y))
	area.body_entered.connect(_on_carve_failsafe_entered.bind(area))
	holder.add_child(area)


## Where a player who went over the edge is put back. NOT the road's last node:
## both trenches are centred a few metres BEYOND their road's end, so that node
## is itself inside the carve — the first version recovered to it, dropped the
## player straight back into the gorge, and because they never left the volume
## `body_entered` never fired again. So walk back up the road's own last leg
## until the point is clear of the far rim with room to spare, and put them
## there: on their own road, facing the thing that stopped them.
func _recovery_point(carve: Dictionary, centre: Vector2, axis: Vector2, road: Array) -> Vector2:
	var last := _vec2(road[road.size() - 1])
	var prev := _vec2(road[road.size() - 2])
	if last == Vector2.INF or prev == Vector2.INF or last.is_equal_approx(prev):
		return last
	var back := (prev - last).normalized()
	var across := Vector2(-axis.y, axis.x)
	var clear: float = float(carve.get("half_width", 6.0)) + float(carve.get("rim", 5.0)) + RECOVERY_CLEARANCE
	var at := last
	for step in 40:
		if absf((at - centre).dot(across)) >= clear:
			return at
		at += back
	return at


func _on_carve_failsafe_entered(body: Node3D, area: Area3D) -> void:
	if not body is CharacterBody3D or body.name != "Player":
		return
	var to: Vector3 = area.get_meta("recover_to", Vector3.ZERO)
	print("[severed_spokes] player went over the edge at %.0f, %.0f, %.0f -- back to the road" % [
		body.global_position.x, body.global_position.y, body.global_position.z
	])
	body.global_position = to
	(body as CharacterBody3D).velocity = Vector3.ZERO


## Team Tether's own seal, and the only blocker on the map that is somebody's
## WORK rather than weather or rock — so it is the only one that may not be
## stone tumbled by accident. It is still built entirely out of vocabulary the
## boundary already owns (D24): a fieldstone wall run shut across the road on
## `world_perimeter._build_stonework`'s proportions, with uprights standing
## proud of it in `palette.json`'s `tether_oxblood`. That colour is reserved —
## "Team Tether banners, equipment and uniforms, never on friendly or neutral
## elements" — which is exactly what lets this say WHO sealed the road without
## a word of text on it.
func _build_sealed_road(world: Node3D, holder: Node3D, blocker: Dictionary, _rng: RandomNumberGenerator) -> void:
	var centre := _vec2(blocker.get("centre", []))
	if centre == Vector2.INF:
		return
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(blocker.get("axis_deg", 0.0))))
	var span := float(blocker.get("span", 21.0))
	var height := float(blocker.get("wall_height", 3.4))
	var thickness := float(blocker.get("wall_thickness", 1.5))
	_ground_wall(world, holder, "Seal", centre, axis, span, height, thickness, 7, _stone_material())

	# The uprights. They carry the faction colour and they are the reason this
	# reads as a seal and not as a field wall someone left across a lane.
	var piers := int(blocker.get("piers", 5))
	var pier_height := float(blocker.get("pier_height", 4.6))
	var marker := float(blocker.get("marker_height", 1.5))
	var yaw := atan2(axis.x, axis.y) + PI * 0.5
	for i in piers:
		var t := (float(i) + 0.5) / float(piers)
		var at := centre + axis * lerpf(-span * 0.5, span * 0.5, t)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var shaft := _stone_box(Vector3(0.82, pier_height, 0.82))
		shaft.name = "SealPier_%d" % i
		shaft.position = Vector3(at.x, ground - 0.5 + pier_height * 0.5, at.y)
		shaft.rotation.y = yaw
		holder.add_child(shaft)
		var cap := MeshInstance3D.new()
		var cap_mesh := BoxMesh.new()
		cap_mesh.size = Vector3(1.02, marker, 1.02)
		cap_mesh.material = _tether_material()
		cap.mesh = cap_mesh
		cap.name = "SealMarker_%d" % i
		cap.position = Vector3(at.x, ground - 0.5 + pier_height + marker * 0.5, at.y)
		cap.rotation.y = yaw
		holder.add_child(cap)
		_add_box_collider(holder, shaft.position, Vector3(0.82, pier_height, 0.82), yaw)


## A gate, not a wall. The road runs THROUGH the arch — that is the whole point
## of §1E's "ancient stone gate/road" — and the leaf does not open. Piers on
## `world_perimeter.gd`'s own PIER_* proportions, a lintel across them, a pair
## of closed leaves filling the opening, and wall stubs running out either side
## so the arch is a gate in something rather than a frame standing in grass.
func _build_sealed_gate(world: Node3D, holder: Node3D, blocker: Dictionary) -> void:
	var centre := _vec2(blocker.get("centre", []))
	if centre == Vector2.INF:
		return
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(blocker.get("axis_deg", 0.0))))
	var opening := float(blocker.get("opening", 6.4))
	var pier_w := float(blocker.get("pier_width", 2.2))
	var pier_d := float(blocker.get("pier_depth", 2.6))
	var pier_h := float(blocker.get("pier_height", 7.2))
	var lintel_h := float(blocker.get("lintel_height", 1.5))
	# +PI/2 so the box's local +X runs ALONG the axis: rotation.y maps local X to
	# (cos y, -sin y), which atan2(x, y) alone sends perpendicular. The lintel and
	# the leaves both span the opening, so getting this backwards turns the gate
	# ninety degrees and the road walks straight past it.
	var yaw := atan2(axis.x, axis.y) + PI * 0.5

	var base := float(world.call("ground_height_at", centre.x, centre.y))
	if is_nan(base):
		return
	var offset := (opening + pier_w) * 0.5
	for side: float in [1.0, -1.0]:
		var at := centre + axis * (offset * side)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			ground = base
		var pier := _stone_box(Vector3(pier_w, pier_h, pier_d))
		pier.name = "GatePier_%s" % ("a" if side > 0.0 else "b")
		pier.position = Vector3(at.x, ground - 0.8 + pier_h * 0.5, at.y)
		pier.rotation.y = yaw
		holder.add_child(pier)
		_add_box_collider(holder, pier.position, Vector3(pier_w, pier_h, pier_d), yaw)

	# The lintel rides on top of both piers, so it is sampled from the pier
	# tops rather than from the ground under the middle of the opening.
	var lintel := _stone_box(Vector3(opening + pier_w * 2.0, lintel_h, pier_d))
	lintel.name = "GateLintel"
	lintel.position = Vector3(centre.x, base - 0.8 + pier_h + lintel_h * 0.5, centre.y)
	lintel.rotation.y = yaw
	holder.add_child(lintel)

	# The leaves. Shut, and shut is the whole message: the road is intact, the
	# gate is intact, and it does not open.
	var leaf_h := pier_h * 0.78
	for side: float in [1.0, -1.0]:
		var at := centre + axis * (opening * 0.25 * side)
		var leaf := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(opening * 0.5 - 0.12, leaf_h, 0.55)
		mesh.material = _tether_material()
		leaf.mesh = mesh
		leaf.name = "GateLeaf_%s" % ("a" if side > 0.0 else "b")
		leaf.position = Vector3(at.x, base - 0.5 + leaf_h * 0.5, at.y)
		leaf.rotation.y = yaw
		holder.add_child(leaf)
	_add_box_collider(holder, Vector3(centre.x, base - 0.5 + leaf_h * 0.5, centre.y),
		Vector3(opening, leaf_h, 0.9), yaw)

	# Wall stubs out to `span`, one either side, starting where the piers end.
	var span := float(blocker.get("span", 19.0))
	var wall_h := float(blocker.get("wall_height", 4.2))
	var wall_t := float(blocker.get("wall_thickness", 1.7))
	var inner := offset + pier_w * 0.5
	var run := maxf(span * 0.5 - inner, 2.0)
	for side: float in [1.0, -1.0]:
		var stub_centre := centre + axis * ((inner + run * 0.5) * side)
		_ground_wall(world, holder, "GateWall_%s" % ("a" if side > 0.0 else "b"),
			stub_centre, axis, run, wall_h, wall_t, 3, _stone_material())


## The roadbed has fallen away. The blocker is the notch in the flank (a carve,
## like the gorge's, but short and narrow); this only dresses the break. A
## fallen roadbed is a GAP, not a pile — the two rockslides on this map are
## already the pile, and a third would be one mechanism in three hats.
func _build_fallen_roadbed(world: Node3D, holder: Node3D, blocker: Dictionary, rng: RandomNumberGenerator) -> void:
	var carve: Dictionary = blocker.get("carve", {})
	var centre := _vec2(carve.get("centre", []))
	if centre == Vector2.INF:
		return
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var across := Vector2(-axis.y, axis.x)
	var lip: float = float(carve.get("half_width", 5.0)) + float(carve.get("rim", 4.0)) * 0.85

	# Which way is uphill: the shelf was cut into a slope, so the retaining
	# wall belongs on the high side. Sampled from the ground, not configured,
	# so moving the spoke cannot silently put the revetment in mid-air.
	var probe := 6.0
	var up := float(world.call("ground_height_at", (centre + axis * probe).x, (centre + axis * probe).y))
	var down := float(world.call("ground_height_at", (centre - axis * probe).x, (centre - axis * probe).y))
	var uphill: float = 1.0 if (not is_nan(up) and not is_nan(down) and up >= down) else -1.0

	# The revetment runs back along the road from the break and stops with a
	# broken end. Its own kerb goes over the edge with the roadbed.
	var length := float(blocker.get("revetment_length", 14.0))
	var height := float(blocker.get("revetment_height", 1.6))
	var thickness := float(blocker.get("revetment_thickness", 1.1))
	var start := centre + across * lip + axis * (uphill * 3.4)
	var wall_centre := start + across * (length * 0.5)
	_ground_wall(world, holder, "Revetment", wall_centre, across, length, height, thickness, 5,
		_stone_material())

	# The masonry that went with the roadbed, lying below the notch.
	var scree := int(blocker.get("scree", 14))
	var scree_min := float(blocker.get("scree_scale_min", 0.35))
	var scree_max := float(blocker.get("scree_scale_max", 1.1))
	for i in scree:
		var at := centre + across * rng.randf_range(-lip * 0.6, lip * 0.6) \
			+ axis * (-uphill * rng.randf_range(lip * 0.4, lip * 1.9))
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var scale := rng.randf_range(scree_min, scree_max)
		var stone := MeshInstance3D.new()
		stone.name = "Scree_%d" % i
		stone.mesh = _rock_mesh(rng.randi() % ROCK_MESHES.size())
		stone.scale = Vector3.ONE * scale
		stone.rotation.y = rng.randf_range(0.0, TAU)
		stone.position = Vector3(at.x, ground - ROCK_MODEL_HEIGHT * scale * 0.25, at.y)
		holder.add_child(stone)

	_build_gorge_lip(world, holder, blocker, rng)


## A wall run that follows the ground it stands on instead of hanging over the
## dips at its ends — the failure OF7 fixed once already in the boundary ring.
## Visible masonry and its collider are the same box, so nothing here is an
## invisible wall.
func _ground_wall(world: Node3D, holder: Node3D, node_name: String, centre: Vector2,
		axis: Vector2, span: float, height: float, thickness: float, segments: int,
		material: StandardMaterial3D) -> void:
	var yaw := atan2(axis.x, axis.y) + PI * 0.5
	var length := span / float(segments) + 0.4
	for i in segments:
		var t := (float(i) + 0.5) / float(segments)
		var at := centre + axis * lerpf(-span * 0.5, span * 0.5, t)
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var mid := Vector3(at.x, ground - 0.7 + height * 0.5, at.y)
		var block := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(length, height, thickness)
		mesh.material = material
		block.mesh = mesh
		block.name = "%s_%d" % [node_name, i]
		block.position = mid
		block.rotation.y = yaw
		holder.add_child(block)
		_add_box_collider(holder, mid, Vector3(length, height, thickness), yaw)


## Old signage, §29's own word for it. One arm, one destination, through
## `signpost.gd`'s `routes_override` — the same object `paths.trailheads`
## already plants at the Rise road's end. It names where the road WENT. It
## says nothing about why you cannot follow it; the gorge says that.
func _build_sign(world: Node3D, spoke: Dictionary, id: String) -> void:
	var sign_data: Dictionary = spoke.get("sign", {})
	if sign_data.is_empty():
		return
	var at := _vec2(sign_data.get("at", []))
	var label := str(sign_data.get("label", ""))
	var points: Array = sign_data.get("points", [])
	if at == Vector2.INF or label.is_empty() or points.size() < 2:
		push_warning("spoke %s has a malformed `sign` — skipped" % id)
		return
	var post: Node3D = SIGNPOST.new()
	post.name = "SpokeSign_%s" % id
	add_child(post)
	post.call("build", world, at, [{"label": label, "points": points}])


func _rock_mesh(index: int) -> Mesh:
	var scene: PackedScene = ROCK_MESHES[index]
	var root: Node = scene.instantiate()
	var found: Mesh = null
	for child: Node in _all_children(root):
		if child is MeshInstance3D:
			found = (child as MeshInstance3D).mesh
			break
	root.queue_free()
	return found


func _all_children(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child: Node in node.get_children():
		out.append_array(_all_children(child))
	return out


func _stone_box(size: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _stone_material()
	instance.mesh = mesh
	return instance


## One MultiMesh for every kerbstone on a lip: they are identical boxes and
## there can be twenty of them, which is one draw call's worth of work, not
## twenty nodes'. Same reasoning `vegetation.gd` and `world_perimeter.gd` use.
func _batch_boxes(parent: Node3D, node_name: String, size: Vector3, transforms: Array) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _stone_material()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi
	parent.add_child(instance)


func _add_box_collider(parent: Node3D, mid: Vector3, size: Vector3, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Collision"
	body.position = mid
	body.rotation.y = yaw
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)


func _stone_material() -> StandardMaterial3D:
	if _stone_material_cache != null:
		return _stone_material_cache
	var material := StandardMaterial3D.new()
	material.albedo_texture = STONE_ALBEDO
	material.normal_enabled = true
	material.normal_texture = STONE_NORMAL
	material.roughness_texture = STONE_ROUGHNESS
	material.uv1_scale = Vector3(STONE_TILE, STONE_TILE, STONE_TILE)
	material.uv1_triplanar = true
	_stone_material_cache = material
	return material


## `palette.json`'s `tether_oxblood`, read from the palette rather than typed in
## here so the faction colour cannot drift between the seal, the banners and the
## Warden's badge. It is the reserved danger accent — "Team Tether banners,
## equipment and uniforms, never on friendly or neutral elements" — so it is the
## whole of the story on the two blockers Team Tether built themselves. Rough,
## unlit-ish paint on stone: high roughness, no metal.
func _tether_material() -> StandardMaterial3D:
	if _tether_material_cache != null:
		return _tether_material_cache
	var colour := Color(0.2, 0.133, 0.157)
	var file := FileAccess.open(PALETTE_CONFIG, FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			for section: Variant in (parsed as Dictionary).values():
				if section is Dictionary and (section as Dictionary).has("tether_oxblood"):
					colour = Color(str((section as Dictionary)["tether_oxblood"]))
					break
	else:
		push_warning("cannot read %s; the seal falls back to a hard-coded oxblood" % PALETTE_CONFIG)
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.86
	material.metallic = 0.0
	_tether_material_cache = material
	return material


func _vec2(raw: Variant) -> Vector2:
	var array: Array = raw as Array if raw is Array else []
	if array.size() < 2:
		return Vector2.INF
	return Vector2(float(array[0]), float(array[1]))


## The world-space axis a lip stone is tipped about: the carve's own direction,
## flattened into the XZ plane.
func axis3(axis: Vector2) -> Vector3:
	return Vector3(axis.x, 0.0, axis.y).normalized()


func _load_config() -> Dictionary:
	var file := FileAccess.open(SPOKE_CONFIG, FileAccess.READ)
	if file == null:
		push_error("cannot read %s" % SPOKE_CONFIG)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	return (parsed as Dictionary).get("spokes", {})
