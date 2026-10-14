extends "res://tools/capture_stormwood_look.gd"

## Reuse the locked F41 glass view. Hold --look-candidate equal across both
## sides; only --scar-relief-preview differs. Full world setup remains.
const FIELD := preload("res://scripts/world/stormwood_glass_field.gd")
var _scar_preview := false


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--stands=glass") or not args.has("--no-aftermath"):
		push_error("Scar relief piece requires --stands=glass --no-aftermath")
		quit(2)
		return
	if not (args.has("--phases=calm") or args.has("--phases=break")):
		push_error("Scar relief piece requires one Calm or Break phase")
		quit(2)
		return
	_scar_preview = args.has("--scar-relief-preview")
	FIELD.capture_scar_relief_preview = _scar_preview
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIELD.CONFIG_PATH))
	if bool(cfg.get("scar_relief_candidate", {}).get("enabled", false)) and not _scar_preview:
		push_error("Scar relief is enabled in config but not requested in this capture")
		quit(2)
		return
	await super._run()


func _capture(frame_id: String, description: String, full_size: bool, extra: Dictionary = {}) -> void:
	var field := _world.get_node_or_null("GlassFieldPresentation")
	if field == null:
		_failures.append("production Glass Field missing")
		return
	var cfg: Dictionary = field.get("config")
	var scars := field.find_children("FusedStrikeScar", "MeshInstance3D", true, false)
	if scars.size() != (cfg.get("clusters", []) as Array).size() or scars.is_empty():
		_failures.append("production scar material coverage incomplete")
		return
	var expected := float(cfg.scar_relief_candidate.normal_strength) if _scar_preview else 0.0
	for node: MeshInstance3D in scars:
		var material := node.material_override as ShaderMaterial
		if material == null or material.shader != FIELD.SCAR_SHADER \
				or not is_equal_approx(float(material.get_shader_parameter("sw_normal_strength")), expected) \
				or float(material.get_shader_parameter("sw_detail_strength")) != 0.0 \
				or float(material.get_shader_parameter("sw_roughness_scale")) != 1.0:
			_failures.append("scar material does not match requested relief-only treatment")
			return
	await super._capture(frame_id, description, full_size, extra.merged({
		"scar_relief_preview": _scar_preview, "scar_materials_checked": scars.size(),
		"scar_normal_strength": expected,
		"glass_field_config_sha256": FileAccess.get_file_as_string(FIELD.CONFIG_PATH).sha256_text(),
		"scar_scope": "Existing fused-base surface shading only; full production world retained. No geometry, clearance, route or whole-item acceptance proof."
	}, true))
