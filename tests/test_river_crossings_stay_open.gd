extends "res://tests/test_case.gd"

## RIVER-GATE. The river divides the map everywhere, and stops dividing it at
## the one place a bridge stands — and the thing that makes that true is a
## HEIGHT, which nothing was checking.
##
## `D46` divides the Meadows with the river deliberately and pays one severed
## spoke for it: *"the only ground link between the near Meadows and the far
## bank is the Old Mill Crossing, which is shut until the Mill Bridge Gear is
## in the satchel."* `river.gd` enforces that at runtime with a chain of
## abutting `CarveFailsafe` volumes down the whole course — the channel is
## 10–18m deep with 70–81° walls and there is no swimming and no climbing, so a
## body that goes in is put back on the bank it came from.
##
## Those volumes span the crossing in PLAN. The middle 11.0m of the Old Mill
## Crossing's 18.4m span sits inside two of them, looked at from above. The
## crossing works anyway, and the only reason is vertical: a volume's ceiling is
## `lip_y - LIP_CLEARANCE`, and the deck stands 5.1m above that (measured, in
## the real baked world — `tools/_probe_river_gate.gd --mode=survey`). Nothing
## anywhere asserted that, and the two heights come from different places: the
## deck from the crossing's `flats` abutment pads, the ceiling from the river's
## own `depth`/`rim` at that reach.
##
## So this pins the relationship rather than either number. It is the shape of
## failure this repo keeps paying for — `tether_relay`'s `deck_y` was calibrated
## against a site that had since moved, and `smoke_boss.gd`'s `BARRIER_LIMIT_M`
## was 18m by config arithmetic and 28.3m when somebody finally measured it. A
## re-tune of the channel, the rim or the pads that closed this margin would
## make the crossing untraversable with a symptom — a body teleporting off a
## bridge, with `get_slide_collision()` naming nothing — that took `OW5-walk` a
## purpose-built teleport counter to see at all.
##
## WHAT IS TESTED WHERE. `tests/smoke_traversal.gd`'s `_check_gated_crossing`
## already walks a real body at both crossings, locked and unlocked, which is
## the only honest way to ask whether the gate gates. This file asks what a walk
## cannot: whether the chain holds along all 2,300m of course including the
## reaches no test will ever walk, and whether the deck's clearance over it is
## still there.

const RIVER := preload("res://scripts/world/river.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const PREFABS := preload("res://scripts/world/building_prefabs.gd")

## How finely the course and the deck are walked. Small against the 2.1m deck
## and the 12m shortest course segment, so nothing hides between two samples.
const STEP_M := 0.25

## The player capsule, `scenes/player/player.tscn`. Used to stand a body on
## things rather than to sample points in the air.
const PLAYER_RADIUS := 0.4


## The one duck-typed call `river.gd` makes of the world (D09 — never a
## raycast).
##
## Backed by the analytic heightfield, which is what the terrain bake is
## GENERATED from — `playground_world.ground_height_at` reads the baked
## Terrain3D data instead, and that needs a booted scene. The difference between
## the two is centimetres of bake quantisation, and every margin asserted below
## is metres, so it cannot flip an answer here. Where a number has to be exact
## it is measured against the real baked world by
## `tools/_probe_river_gate.gd --mode=survey` and recorded in D56, not asserted
## here.
class HeightfieldWorld extends Node3D:
	var field: RefCounted

	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x, z)


var _config: Dictionary
var _world: Node3D
var _river: Node3D
## Each built volume in world space: {centre, along, half_length, half_width,
## top, bottom} — the plan-view box plus the two y values that decide whether a
## body standing above it is inside it.
var _volumes: Array = []


func before_each() -> void:
	_config = HEIGHTFIELD.load_config()
	_world = HeightfieldWorld.new()
	_world.field = HEIGHTFIELD.new(_config)
	_river = RIVER.new()
	_river.call("build", _world)
	_volumes = _read_volumes(_river)


func after_each() -> void:
	# `free`, not `queue_free`: none of this is in a SceneTree, so there is no
	# frame for a queued free to happen on and it would leak to shutdown.
	_river.free()
	_world.free()
	_volumes = []


func test_the_chain_is_built_along_the_whole_course() -> void:
	assert_true(_volumes.size() > 0, "river.gd built no recovery volumes; nothing below means anything")
	var stats: Dictionary = _river.call("stats")
	assert_eq(int(stats.get("segments", 0)), _course().size() - 1,
		"every authored course segment should be covered by the chain")
	assert_eq(int(stats.get("failsafes", 0)), _volumes.size(),
		"river.gd reported a different number of volumes than it built")


## D46's division, asserted as the property it actually is: there is nowhere on
## the course a body can go in and not be put back. The chain is authored to
## abut (`end_fade: 0.0`) for exactly this reason, and a gap in it is a way
## across the river that no key opens.
func test_the_chain_has_no_gap_a_body_could_land_in() -> void:
	var course := _course()
	var uncovered: Array[Vector2] = []
	for i in course.size() - 1:
		var pa := _vec2((course[i] as Dictionary).get("at", []))
		var pb := _vec2((course[i + 1] as Dictionary).get("at", []))
		var length := pa.distance_to(pb)
		if length <= 0.001:
			continue
		for s in int(length / STEP_M) + 1:
			var at := pa.lerp(pb, minf(float(s) * STEP_M / length, 1.0))
			if not _covered_in_plan(at):
				uncovered.append(at)
	assert_true(uncovered.is_empty(),
		"%d point(s) on the river's own centreline are in no recovery volume, the first at (%.1f, %.1f) — a body that goes in there stays in" % [
			uncovered.size(), uncovered[0].x if not uncovered.is_empty() else 0.0,
			uncovered[0].y if not uncovered.is_empty() else 0.0])


## And the one exception the design asks for: the bridge. The whole run of the
## deck must stand ABOVE every volume it crosses over, or a body walking the
## span is picked up and put back on the near bank — the river becomes a
## one-way wall and Band 3 has no way through it in either lock state.
##
## The assertion is exact rather than tolerant: a volume's ceiling must be at or
## below the deck SURFACE, because the capsule stands on that surface and any
## ceiling above it is some part of a standing body inside the volume.
func test_the_crossing_deck_stands_clear_of_the_chain() -> void:
	var crossings := _crossings_on_the_river()
	assert_true(crossings.size() > 0,
		"no authored crossing sits on this river; D46's one ground link is missing")
	for crossing: Dictionary in crossings:
		var centre: Vector2 = crossing["centre"]
		var across: Vector2 = crossing["across"]
		var deck: float = crossing["deck_surface"]
		var span: float = crossing["span_half"]
		var margin := INF
		var worst := Vector2.ZERO
		for i in range(-int(span / STEP_M), int(span / STEP_M) + 1):
			var at := centre + across * (float(i) * STEP_M)
			for volume: Dictionary in _volumes:
				if not _in_plan(volume, at):
					continue
				var clearance: float = deck - float(volume["top"])
				if clearance < margin:
					margin = clearance
					worst = at
		if is_inf(margin):
			# Nothing under the deck at all is a fine outcome and not a
			# failure — it is what a crossing sited off the chain would look
			# like. Say so rather than silently passing an empty loop.
			print("    '%s': no recovery volume reaches under the deck at all" % crossing["id"])
			continue
		assert_true(margin > 0.0,
			"'%s': a recovery volume's ceiling stands %.2fm ABOVE the deck at (%.1f, %.1f) — a body walking the span is teleported back to the near bank" % [
				crossing["id"], -margin, worst.x, worst.y])
		print("    '%s': deck clears the chain by %.2fm at its tightest, (%.1f, %.1f)" % [
			crossing["id"], margin, worst.x, worst.y])


## The other half of the same statement, and the half that stops the first one
## being solved by deleting the chain: under that same deck, down in the water,
## the volumes must still be there. A bridge over a covered channel is a
## crossing; a bridge over an uncovered one is decoration on a hole in the wall.
func test_the_channel_under_the_bridge_is_still_covered() -> void:
	for crossing: Dictionary in _crossings_on_the_river():
		var centre: Vector2 = crossing["centre"]
		var across: Vector2 = crossing["across"]
		# The channel proper — `half_width`, the vertical-walled part — and not
		# the rim beyond it. A body on the rim is standing on the slope up to
		# the lip, above the volume's ceiling, and is meant to be: the ceiling
		# is measured DOWN from the lip precisely so that a player on the bank
		# is never inside one (`severed_spokes.LIP_CLEARANCE`).
		var clear: float = crossing["channel_half"]
		for i in range(-int(clear / STEP_M), int(clear / STEP_M) + 1):
			var at := centre + across * (float(i) * STEP_M)
			var bed: float = float(_world.call("ground_height_at", at.x, at.y)) + PLAYER_RADIUS
			var caught := false
			for volume: Dictionary in _volumes:
				if not _in_plan(volume, at):
					continue
				if bed >= float(volume["bottom"]) and bed <= float(volume["top"]):
					caught = true
			assert_true(caught,
				"'%s': a body on the channel floor %+.2fm across the gap, (%.1f, %.1f, %.1f), is in no recovery volume — it can drop off the bridge and stay in the river" % [
					crossing["id"], float(i) * STEP_M, at.x, bed, at.y])


## The South Bridge is 2,870m from this river and cuts its own gully. Nothing
## the river builds may reach it — `OW5C` measured that crossing at -9.1m
## locked and +23.3m unlocked, and a river volume arriving over it would change
## both without anything in this file's diff looking like it had.
func test_the_river_leaves_the_south_gully_alone() -> void:
	var south := Vector2.INF
	for entry: Variant in _config.get("crossings", []):
		if not entry is Dictionary or str((entry as Dictionary).get("id", "")) != "south_bridge":
			continue
		south = _vec2(((entry as Dictionary).get("carve", {}) as Dictionary).get("centre", []))
	assert_ne(south, Vector2.INF, "no `south_bridge` crossing in the config")
	assert_false(_covered_in_plan(south),
		"a river recovery volume covers the South Bridge at (%.1f, %.1f)" % [south.x, south.y])


## ------------------------------------------------------------------ helpers

func _course() -> Array:
	return ((_config.get("river", {}) as Dictionary).get("course", []) as Array)


## Every recovery volume the built river actually produced.
##
## Read off the nodes rather than recomputed from the config: the point of this
## file is that the things in the scene are right, and a second copy of the
## arithmetic would agree with a wrong first copy. Local transforms are world
## transforms here — the river node and its holder both sit at the origin —
## which is asserted rather than assumed.
func _read_volumes(river: Node3D) -> Array:
	assert_true(river.transform.is_equal_approx(Transform3D.IDENTITY),
		"the river node is transformed; the geometry read here is no longer world space")
	var out: Array = []
	for area: Node in _areas(river):
		var shape: CollisionShape3D = (area as Node3D).get_child(0) as CollisionShape3D
		if shape == null or not shape.shape is BoxShape3D:
			continue
		var size: Vector3 = (shape.shape as BoxShape3D).size
		var at: Vector3 = (area as Node3D).position
		# `_add_carve_failsafe` yaws by `atan2(axis.x, axis.y) + PI/2`, which
		# puts the box's local +X along the course. Undo it the same way rather
		# than re-deriving the course direction from the config.
		var yaw: float = (area as Node3D).rotation.y
		out.append({
			"centre": Vector2(at.x, at.z),
			"along": Vector2(cos(-yaw), sin(-yaw)),
			"half_length": size.x * 0.5,
			"half_width": size.z * 0.5,
			"top": at.y + size.y * 0.5,
			"bottom": at.y - size.y * 0.5,
		})
	return out


## Found by the `recover_to` meta, not by name.
##
## Every volume is named "CarveFailsafe" into one holder, and Godot's fast
## rename path turns each collision into `@CarveFailsafe@NNNN` — the same shape
## as the `@StaticBody3D@3458` collider `OW5-walk` logged at the Warrens. A name
## match, `==` or `begins_with`, finds exactly one volume per holder: it found 4
## of 19 in the probe that first wrote this, and every assertion below would
## have passed against a chain it had not looked at.
func _areas(node: Node) -> Array:
	var out: Array = []
	if node is Area3D and node.has_meta("recover_to"):
		out.append(node)
	for child: Node in node.get_children():
		out.append_array(_areas(child))
	return out


func _in_plan(volume: Dictionary, at: Vector2) -> bool:
	var to: Vector2 = at - (volume["centre"] as Vector2)
	var along: Vector2 = volume["along"]
	if absf(to.dot(along)) > float(volume["half_length"]):
		return false
	return absf(to.dot(Vector2(-along.y, along.x))) <= float(volume["half_width"])


func _covered_in_plan(at: Vector2) -> bool:
	for volume: Dictionary in _volumes:
		if _in_plan(volume, at):
			return true
	return false


## The authored crossings this river cuts the gap for, with the deck resolved
## the same way `gated_crossing.build` resolves it — from the crossing's own
## `crossings[]` entry and its bridge prefab's own collider list, never from a
## number written down here.
func _crossings_on_the_river() -> Array:
	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		return []
	var out: Array = []
	for entry: Variant in _config.get("crossings", []):
		if not entry is Dictionary:
			continue
		var crossing: Dictionary = entry
		# `channel` is the key a crossing uses when something ELSE cut its gap.
		# For the Old Mill Crossing that something else is this river, which is
		# exactly the set this file is about; `carve` means the crossing dug its
		# own and the river has no opinion on it.
		if not crossing.has("channel"):
			continue
		var gap: Dictionary = crossing["channel"]
		var centre := _vec2(gap.get("centre", []))
		if centre == Vector2.INF:
			continue
		var axis := Vector2.RIGHT.rotated(deg_to_rad(float(gap.get("axis_deg", 0.0))))
		var across := Vector2(-axis.y, axis.x)
		var reach: float = float(gap.get("half_width", 3.6)) + float(gap.get("rim", 3.4))

		var span_half := 0.0
		for box: Variant in prefabs.call("colliders",
				str((crossing.get("bridge", {}) as Dictionary).get("prefab", ""))):
			var at: Array = (box as Dictionary).get("at", [0.0, 0.0, 0.0])
			var size: Array = (box as Dictionary).get("size", [0.0, 0.0, 0.0])
			span_half = maxf(span_half, absf(float(at[0])) + float(size[0]) * 0.5)
		if span_half <= 0.0:
			continue

		# `gated_crossing.build`: the deck is seated on the higher of its two
		# abutment landings (village.gd's own `ground: "highest"` rule), and its
		# surface is 0.12 above that — `building_prefabs.json`'s deck slabs.
		# `call`, the same duck-typed climb `gated_crossing.gd` itself makes of
		# the world — never a raycast (D09).
		var near := centre - across * (reach + 1.0)
		var far := centre + across * (reach + 1.0)
		var near_ground := float(_world.call("ground_height_at", near.x, near.y))
		var far_ground := float(_world.call("ground_height_at", far.x, far.y))
		out.append({
			"id": str(crossing.get("id", "")),
			"centre": centre,
			"across": across,
			"span_half": span_half,
			"channel_half": float(gap.get("half_width", 3.6)),
			"deck_surface": maxf(near_ground, far_ground) + 0.12,
		})
	return out


func _vec2(raw: Variant) -> Vector2:
	if not raw is Array or (raw as Array).size() < 2:
		return Vector2.INF
	return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
