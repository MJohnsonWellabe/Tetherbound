extends "D:/tetherbound/visual-acceptance-local/capture_flower_final.gd"

func _build_rows(spec: Dictionary) -> Array:
	var rows: Array = super._build_rows(spec)
	return [rows[1], {"id": "place_flower_preserved_transition", "label": "Ridgeline outer planting transition", "stands": [Vector3(-250, NAN, 6598)], "target": Vector3(0, NAN, 7000), "target_ground": 2.0, "times": ["day", "night"], "why": "world-space authored/regional planting blend edge"}]

func _boot_region(spec: Dictionary) -> bool:
	if not await super._boot_region(spec):
		return false
	for tier: Dictionary in _flowers:
		var material: ShaderMaterial = tier.material
		var raw_preserve: Variant = material.get_shader_parameter("composition_preserve_scatter")
		var preserve := false if raw_preserve == null else bool(raw_preserve)
		assert(preserve == (tier.name == "Cover_flowers"))
		if preserve:
			for key: String in ["item_size", "size_jitter", "density_gain", "drift_scale", "drift_contrast"]:
				assert(is_equal_approx(float(material.get_shader_parameter("composition_" + key)), float(tier.before[key])))
		print("FLOWER_AUTHORED_PRESERVATION_VERIFIED ", tier.name, " enabled=", preserve)
	return true
