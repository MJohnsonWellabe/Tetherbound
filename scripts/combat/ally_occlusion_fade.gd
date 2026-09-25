extends RefCounted

## MEADOWS-VISUAL-PASS, the fight-framing gap three blind rounds ranked first:
## a large ally standing between the lens and a small foe hides the foe. The
## neutral tracker's 35-degree composition cannot clear a 3.85m Terrapup from a
## 2m Bramblebun two metres ahead of it.
##
## The first answer (owner-delegated, round 5) is `combat_manager.gd` swinging
## the neutral tracker wider while the foe is hidden. That rotates the camera
## basis camera-relative movement reads, exactly as the neutral tracker already
## does within COMBAT section 5's automatic framing; manual look still wins.
## This file is the fallback: when the swing cannot clear the foe within
## `dither_after_s`, the ally's meshes fade to
## `camera.occlusion_fade.transparency` and come back when the foe is clear.
## Collision and every other peer are untouched; local presentation only.
##
## "Covers" is measured against an ellipsoid inscribed in the ally's rendered
## bounds, not the bounds box itself: a box over-reports the empty corners
## around a rounded body, which is what sank the earlier screen-rect measure.

## Heights up the foe's body (fractions of its rendered height) that are
## tested. The foe counts as hidden when at least `hidden_points` of them are.
const SAMPLE_HEIGHTS := [0.25, 0.5, 0.8]


## True when the segment from `eye` to `point` passes through the ellipsoid
## inscribed in `bounds`, which is expressed in `model`'s local space.
static func segment_hits_ellipsoid(eye: Vector3, point: Vector3, model: Transform3D, bounds: AABB) -> bool:
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or bounds.size.z <= 0.0:
		return false
	var inverse := model.affine_inverse()
	var centre := bounds.get_center()
	var half := bounds.size * 0.5
	var a := (inverse * eye - centre) / half
	var b := (inverse * point - centre) / half
	# Segment against the unit sphere.
	var d := b - a
	var qa := d.dot(d)
	if qa <= 0.000001:
		return a.length_squared() <= 1.0
	var qb := 2.0 * a.dot(d)
	var qc := a.dot(a) - 1.0
	var disc := qb * qb - 4.0 * qa * qc
	if disc < 0.0:
		return false
	var root := sqrt(disc)
	var t0 := (-qb - root) / (2.0 * qa)
	var t1 := (-qb + root) / (2.0 * qa)
	return t1 >= 0.0 and t0 <= 1.0


## How many of the foe's sample points the ally hides from `eye`.
static func hidden_points(eye: Vector3, foe_base: Vector3, foe_height: float,
		ally_model: Transform3D, ally_bounds: AABB) -> int:
	var count := 0
	for fraction: float in SAMPLE_HEIGHTS:
		var point := foe_base + Vector3.UP * foe_height * fraction
		if segment_hits_ellipsoid(eye, point, ally_model, ally_bounds):
			count += 1
	return count


## Fades every BaseMaterial3D surface under `root` to `amount` (0 opaque,
## 1 invisible), seen from `eye`.
##
## Screen-door dither, not alpha. GeometryInstance3D.transparency is ignored by
## the shipped Compatibility renderer (measured: an opaque box stayed opaque),
## and an alpha blend was rendered in a real fight and read as a double
## exposure -- the creature's own far-side face drew through its back. A
## dithered surface stays in the opaque pass with a real depth write, so the
## body keeps its own occlusion and simply leaves holes the foe shows through.
## Godot's OBJECT_DITHER fades by the object origin's distance from the
## camera, so `max` is set to that distance over the wanted coverage each tick.
##
## Each surface gets a copy of whatever material it shows now, kept in
## `state`; `amount` 0 hands each surface back the override it had, unless
## something else (a colourway swap, a night floor) replaced the copy
## meanwhile, in which case theirs stands.
static func apply(root: Node, amount: float, state: Dictionary, eye: Vector3 = Vector3.ZERO) -> void:
	if amount <= 0.0:
		restore(state)
		return
	if root == null or not is_instance_valid(root):
		return
	_fade_node(root, clampf(amount, 0.0, 0.95), state, eye)


static func restore(state: Dictionary) -> void:
	for key: Variant in state.keys():
		var entry: Dictionary = state[key]
		var mesh: MeshInstance3D = instance_from_id(int(entry["mesh"])) as MeshInstance3D
		if mesh != null and is_instance_valid(mesh):
			var surface := int(entry["surface"])
			if surface < mesh.get_surface_override_material_count() \
					and mesh.get_surface_override_material(surface) == entry["faded"]:
				mesh.set_surface_override_material(surface, entry["original"])
	state.clear()


## Coverage `1 - amount` at `distance`: OBJECT_DITHER draws
## clamp((d - min) / (max - min)) of the pixels.
static func dither_max_distance(distance: float, amount: float) -> float:
	return maxf(distance, 0.01) / maxf(1.0 - amount, 0.05)


static func _fade_node(node: Node, amount: float, state: Dictionary, eye: Vector3) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var distance := mesh.global_position.distance_to(eye) if mesh.is_inside_tree() else 1.0
		for surface in (mesh.mesh.get_surface_count() if mesh.mesh != null else 0):
			var key := "%d:%d" % [mesh.get_instance_id(), surface]
			var active := mesh.get_active_material(surface)
			var entry: Dictionary = state.get(key, {})
			if entry.is_empty() or active != entry["faded"]:
				# First fade, or someone swapped the surface since: derive a
				# fresh copy from what it shows now.
				if not (active is BaseMaterial3D):
					continue
				var faded := (active as BaseMaterial3D).duplicate() as BaseMaterial3D
				faded.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_OBJECT_DITHER
				faded.distance_fade_min_distance = 0.0
				entry = {"mesh": mesh.get_instance_id(), "surface": surface,
					"original": mesh.get_surface_override_material(surface), "faded": faded}
				state[key] = entry
				mesh.set_surface_override_material(surface, faded)
			(entry["faded"] as BaseMaterial3D).distance_fade_max_distance = dither_max_distance(distance, amount)
	for child in node.get_children():
		_fade_node(child, amount, state, eye)
