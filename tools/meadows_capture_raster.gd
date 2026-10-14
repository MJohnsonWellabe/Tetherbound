extends RefCounted

## Same exact numeric validation as Stormwood's c41bbe3c7e raster repair.
## JSON dimensions are floats and native dimensions are ints. Validate before
## conversion so fractions, non-numbers and invalid dimensions cannot match.
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


static func matches_preset(camera_set: Dictionary, preset: String, observed: Variant) -> bool:
	var resolutions: Variant = camera_set.get("resolution_by_preset")
	if not resolutions is Dictionary:
		return false
	var expected := exact_size(resolutions.get(preset))
	return expected != Vector2i.ZERO and exact_size(observed) == expected
