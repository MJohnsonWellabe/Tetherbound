extends RefCounted

## Personal save data, deliberately separate from session packet ownership and
## revisions. A corrupt aquatic payload rejects the complete pose at the seam.
static func sanitise(raw: Variant) -> Dictionary:
	if not raw is Dictionary or raw.get("version") != 1:
		return {}
	for key in ["health_fraction", "stamina_fraction"]:
		var value: Variant = raw.get(key)
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0.0 or float(value) > 1.0:
			return {}
	var mode: Variant = raw.get("mode")
	if not (mode is float or mode is int) or not is_finite(float(mode)) or float(mode) != floorf(float(mode)) or int(mode) not in [0, 1, 2, 3]:
		return {}
	var anchor: Variant = raw.get("safe_anchor")
	if not anchor is Array or anchor.size() not in [0, 3]:
		return {}
	for value: Variant in anchor:
		if not (value is float or value is int) or not is_finite(float(value)):
			return {}
	var clean := {"version": 1, "mode": int(mode), "health_fraction": float(raw.health_fraction),
		"stamina_fraction": float(raw.stamina_fraction), "safe_anchor": anchor.duplicate()}
	if raw.has("mount"):
		var mount: Variant = raw.mount
		if not mount is Dictionary or not mount.get("species_id") is String:
			return {}
		var index: Variant = mount.get("party_index")
		if not (index is int or index is float) or not is_finite(float(index)) \
				or float(index) != floorf(float(index)) or int(index) < 0 or int(index) >= 5:
			return {}
		var position: Variant = mount.get("position")
		if not position is Array or position.size() != 3:
			return {}
		for value: Variant in position:
			if not (value is int or value is float) or not is_finite(float(value)):
				return {}
		clean.mount = {"party_index": int(index), "species_id": str(mount.species_id), "position": position.duplicate()}
	return clean
