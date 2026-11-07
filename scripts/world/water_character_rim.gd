extends RefCounted

## NEAR6-TW (4 Nov 2026), P2-057 / F39#27 (GPU 5.48: "the characters read as
## backlit near-black figures on bare sand dunes"). `water_character_rim.json`,
## OFF by default: each Tidewake named NPC and trainer body gets the Stormwood
## character rim overlay (stormwood_character_rim.gd overlay()/dress(), reused)
## in a warm sand tone plus a soft front fill. Client presentation only.
const CONFIG := "res://data/config/water_character_rim.json"
const RIM := preload("res://scripts/world/stormwood_character_rim.gd")
static var _material: ShaderMaterial


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) \
		if FileAccess.file_exists(CONFIG) else {}
	return parsed if parsed is Dictionary else {}


static func apply(body: Node3D) -> bool:
	var cfg := settings()
	if not bool(cfg.get("enabled", false)) or not is_instance_valid(body):
		return false
	if _material == null:
		_material = RIM.overlay(cfg)
		_material.set_shader_parameter("fill_energy", float(cfg.get("fill_energy", 0.0)))
	RIM.dress(body, _material, true)
	return true
