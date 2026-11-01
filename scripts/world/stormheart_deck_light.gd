extends RefCounted

## deck_light_1101 lantern layout for stormheart_tree.gd (cause lane
## tb/cause-stormwood). Pure, so tests run without an imported tree.

## Tree-local lantern positions for deck_light_1101 (pure; tested).
static func poses(settings: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ring: Dictionary in settings.get("rings", []):
		var count := int(ring.get("count", 0))
		var radius := float(ring.get("radius_m", 20.0))
		var height := float(ring.get("height_m", 4.0))
		var phase := deg_to_rad(float(ring.get("phase_deg", 0.0)))
		for i in count:
			var a := phase + TAU * float(i) / float(maxi(1, count))
			out.append({"name": "%s_%d" % [str(ring.get("id", "ring")), i],
				"position": Vector3(cos(a) * radius, height, sin(a) * radius)})
	return out
