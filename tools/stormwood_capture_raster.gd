extends RefCounted

## JSON dimensions are floats; native dimensions are ints. Compare an exact
## integer raster after validating numeric input, never rounded or truncated.
static func exact_size(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value if value.x > 0 and value.y > 0 else Vector2i.ZERO
	if not value is Array or value.size() != 2:
		return Vector2i.ZERO
	for component: Variant in value:
		if typeof(component) not in [TYPE_INT, TYPE_FLOAT]:
			return Vector2i.ZERO
		var number := float(component)
		if not is_finite(number) or number <= 0.0 or number > 2147483647.0 or floor(number) != number:
			return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))


static func matches_size(observed: Variant, expected: Vector2i) -> bool:
	return expected.x > 0 and expected.y > 0 and exact_size(observed) == expected


static func exact_mode(observed: Variant, expected: int) -> bool:
	return typeof(observed) in [TYPE_INT, TYPE_FLOAT] and float(observed) == float(expected)


static func matches_viewport(observed: Dictionary, expected: Vector2i) -> bool:
	return matches_size(observed.get("window_size"), expected) \
		and matches_size(observed.get("viewport_size"), expected) \
		and matches_size(observed.get("texture_size"), expected) \
		and exact_mode(observed.get("window_mode"), Window.MODE_EXCLUSIVE_FULLSCREEN) \
		and exact_mode(observed.get("content_scale_mode"), Window.CONTENT_SCALE_MODE_DISABLED)
