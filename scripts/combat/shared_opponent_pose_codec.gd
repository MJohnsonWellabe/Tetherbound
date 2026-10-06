extends RefCounted

## A pose carries the guest's ground geometry, not the host's AI/damage config.
## Keep the frozen host profile intact; only its wire presentation is projected.
const PROFILE_KEYS := ["telegraph_shape", "range", "inner_radius_m", "marker_radius_m",
	"cone_degrees", "lane_half_width_m", "lunge", "field_duration_s"]


static func encode_shape(shape: Dictionary) -> Dictionary:
	var out := shape.duplicate(true)
	var pattern: Variant = out.get("pattern")
	if pattern is Dictionary and pattern.get("profile") is Dictionary:
		var profile: Dictionary = {}
		for key: String in PROFILE_KEYS:
			if pattern.profile.has(key): profile[key] = pattern.profile[key]
		pattern["profile"] = profile
	return out
