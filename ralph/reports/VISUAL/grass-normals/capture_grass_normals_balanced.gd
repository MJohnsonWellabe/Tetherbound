extends "D:/tetherbound/visual-acceptance-local/capture_grass_normals.gd"
## One bounded revision: preserve upright lighting while reducing grass tint
## in linear colour space. Production files are still unchanged.
func _boot_region(spec: Dictionary) -> bool:
	if not await super._boot_region(spec):
		return false
	if _region == "cloudreach":
		_candidate_code = _candidate_code.replace(
			"vec3 colour = mix(tint_base, tint_tip, smoothstep(0.0, 1.0, v_t));",
			"vec3 colour = mix(tint_base, tint_tip, smoothstep(0.0, 1.0, v_t)) * (camera_clearance ? 0.65 : 1.0);")
	else:
		_candidate_code = _candidate_code.replace("vec3 root = tint_base *", "vec3 root = tint_base * 0.65 *")
		_candidate_code = _candidate_code.replace("mix(root, tint_tip,", "mix(root, tint_tip * 0.65,")
		_candidate_code = _candidate_code.replace("mix(tint_tip, drain_tint,", "mix(tint_tip * 0.65, drain_tint,")
	print("GRASS_BALANCED_PROBE ", _candidate_code.sha256_text(), " tint_gain_linear=0.65")
	return true
