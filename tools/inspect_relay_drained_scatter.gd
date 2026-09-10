extends SceneTree

## Diagnostic-only inventory of baked drained placements intersecting the
## authored Relay pad, gantry, and ramp footprints.

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const RELAY := "res://data/config/tether_relay.json"
const CENTRE := Vector2(350.0, 3760.0)
const U := Vector2(0.5645764443, -0.8253807840)
const P := Vector2(0.8253807840, 0.5645764443)


func _init() -> void:
	var drained: Dictionary = {}
	BAKE.load_all("playground", drained)
	var hits: Array[Dictionary] = []
	for layer: String in drained:
		for placement: Dictionary in drained[layer]:
			var position: Vector3 = placement.get("position", Vector3.ZERO)
			var local := _local(Vector2(position.x, position.z))
			var footprint := _footprint(local)
			if footprint.is_empty():
				continue
			hits.append({
				"footprint": footprint,
				"layer": layer,
				"local": local,
				"model": str(placement.get("model", "")),
				"position": position,
				"scale": float(placement.get("scale", 1.0)),
			})
	hits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.footprint) < str(b.footprint) or (a.footprint == b.footprint and str(a.layer) < str(b.layer)))
	print("RELAY DRAINED STRUCTURE OVERLAPS ", JSON.stringify(hits))
	quit(0)


func _local(world: Vector2) -> Vector2:
	var offset := world - CENTRE
	return Vector2(offset.dot(U), offset.dot(P))


func _footprint(at: Vector2) -> String:
	# Player-radius padding around the exact authored slab envelopes.
	if at.x >= -6.4 and at.x <= 2.4 and at.y >= -13.0 and at.y <= -9.0:
		return "gantry"
	if at.x >= 1.6 and at.x <= 12.4 and at.y >= -14.4 and at.y <= -3.6:
		return "pad"
	# Conservative diagonal ramp capsule: projection along from -> to, then
	# perpendicular distance against half-width plus the player's radius.
	var start := Vector2(-12.5, -5.0)
	var finish := Vector2(-5.5, -11.5)
	var run := finish - start
	var along := clampf((at - start).dot(run) / run.length_squared(), 0.0, 1.0)
	if at.distance_to(start + run * along) <= 2.0:
		return "ramp"
	return ""
