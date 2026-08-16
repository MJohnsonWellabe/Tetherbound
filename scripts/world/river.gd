extends Node3D

## SE21 — the river's one piece of runtime machinery: getting a player who
## walked into it back out.
##
## Everything a player SEES about the river is built somewhere else, on
## purpose. `playground_heightfield._river_carve` cuts the channel (so the
## terrain bake, the scatter and every ground query agree about it without
## asking this file anything), and `water.gd` lays the surface and the banks
## in the water layer where the pond and the stream already live. What is left
## is the one thing neither of those can own: the channel is 10–18m deep with
## 70–81° walls (measured, `tools/_probe_river.gd`) and this project has no
## swimming and no climbing, so a player who goes in is stuck exactly the way
## SA4's own probe found a body stuck in the storm ravine.
##
## So this hangs `severed_spokes.gd`'s carve failsafe — the same recovery
## volume, the same measurement of the ceiling down from the lip that took two
## attempts to get right there — over every segment of the course. One box per
## segment rather than one for the river, because the volume is a straight box
## and the course bends; a single box around a 340m polyline would swallow
## half the meadow either side of it.
##
## Recovery is always to the VILLAGE side, and the reason is south_bridge.gd's:
## putting a player who fell in back on the far bank is not a failsafe, it is a
## free crossing. Fall in, wake up on the side you started from, walk to the
## Old Mill Crossing like everyone else.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SEVERED_SPOKES := preload("res://scripts/world/severed_spokes.gd")

## The point "the village side" is measured against. Every crossing on this
## map resolves which way is home from the road that leads to it; the river
## crosses no road for most of its length, so it takes the square itself.
const VILLAGE := Vector2(10.0, -10.0)

## How far back from the channel the recovery road's far end sits, as a
## multiple of the local channel reach — far enough that `_recovery_point`'s
## walk back always clears the rim.
const RECOVERY_BACK := 4.0

var _stats := {"segments": 0, "failsafes": 0}


## `world` is only ever asked for `ground_height_at`, the same duck-typed
## climb `village.gd`, `south_bridge.gd` and `severed_spokes.gd` all use, and
## never a raycast (D09).
func build(world: Node3D) -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	var river: Dictionary = config.get("river", {})
	var course: Array = river.get("course", [])
	if course.size() < 2:
		return
	if not bool(river.get("failsafe", false)):
		return

	var spokes: Node3D = SEVERED_SPOKES.new()
	spokes.name = "RiverFailsafes"
	add_child(spokes)

	for i in course.size() - 1:
		var a: Dictionary = course[i]
		var b: Dictionary = course[i + 1]
		var pa := _vec2(a.get("at", []))
		var pb := _vec2(b.get("at", []))
		var length := pa.distance_to(pb)
		if length <= 0.001:
			continue
		_stats["segments"] += 1
		var centre := (pa + pb) * 0.5
		var along := (pb - pa) / length
		var across := Vector2(-along.y, along.x)
		# Point `across` at the village side, whichever side that is for this
		# segment — the course bends, so it is not the same sign end to end.
		if (VILLAGE - centre).dot(across) < 0.0:
			across = -across
		# The widest cross-section of the two ends, so the box between the
		# walls is sized to the wider one and never leaves a sliver of
		# channel outside it.
		var half_width: float = maxf(float(a.get("half_width", 9.0)), float(b.get("half_width", 9.0)))
		var rim: float = maxf(float(a.get("rim", 5.0)), float(b.get("rim", 5.0)))
		var depth: float = maxf(float(a.get("depth", 10.0)), float(b.get("depth", 10.0)))
		var carve := {
			"centre": [centre.x, centre.y],
			"axis_deg": rad_to_deg(atan2(along.y, along.x)),
			# Half the segment with no end fade: consecutive volumes have to
			# ABUT, or a player lands in the gap between two boxes and the
			# failsafe that exists for exactly that never fires.
			"half_length": length * 0.5,
			"end_fade": 0.0,
			"half_width": half_width,
			"rim": rim,
			"depth": depth,
			"failsafe": true,
		}
		var reach := half_width + rim
		var road := [
			[centre.x + across.x * reach * RECOVERY_BACK, centre.y + across.y * reach * RECOVERY_BACK],
			[centre.x + across.x * (reach + 1.0), centre.y + across.y * (reach + 1.0)],
		]
		var before: int = spokes.get_child_count()
		spokes.call("_add_carve_failsafe", world, spokes, carve, road)
		if spokes.get_child_count() > before:
			_stats["failsafes"] += 1

	print("[river] %d course segments, %d recovery volumes" % [
		_stats["segments"], _stats["failsafes"]])


func stats() -> Dictionary:
	return _stats


func _vec2(raw: Variant) -> Vector2:
	if not raw is Array or (raw as Array).size() < 2:
		return Vector2.ZERO
	return Vector2(float((raw as Array)[0]), float((raw as Array)[1]))
