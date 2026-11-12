extends Node

## F39#17 `restored_sea_1112` (water_current_flow_visual.json, OFF until judged).
## WORLD §6.5: when the Guardian is freed "the currents return". Until now the
## only thing that showed it was calmer foam streaks: "the three frames are the
## same picture; restoration has no visible environmental effect" (3/3). While
## `water_currents_restored` is set this gives the sea its restored look
## (clearer, brighter shallows and a calmer surface, as shader values on the
## existing sea material) and clears the drifting debris from the lanes; the
## buoys stay. It reads the same replicated world fact as the foam view, so
## load, reload and every peer show the same state. No physics, route, save or
## authority change.
const CONFIG := "res://data/config/water_current_flow_visual.json"
const RESTORED_FLAG := "water_currents_restored"
const POLL_SECONDS := 1.0

var _flags: RefCounted
var _sea: ShaderMaterial
var _markers: Node
var _cfg: Dictionary = {}
var _live: Dictionary = {}
var _restored := false
var _poll := 0.0


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var cfg: Variant = (parsed as Dictionary).get("restored_sea_1112", {}) if parsed is Dictionary else {}
	return cfg if cfg is Dictionary and bool((cfg as Dictionary).get("enabled", false)) else {}


## Null when the flag is off or the sea is not built.
static func attach(parent: Node, surface: Node, markers: Node, flags: RefCounted) -> Node:
	var cfg := settings()
	var geometry := surface as GeometryInstance3D
	if cfg.is_empty() or geometry == null or not geometry.material_override is ShaderMaterial:
		return null
	var node: Node = (load("res://scripts/world/water_restored_sea.gd") as GDScript).new()
	node.name = "WaterRestoredSea"
	node.call("setup", cfg, geometry.material_override, markers, flags)
	parent.add_child(node)
	return node


func setup(cfg: Dictionary, sea: ShaderMaterial, markers: Node, flags: RefCounted) -> void:
	_cfg = cfg
	_sea = sea
	_markers = markers
	_flags = flags
	for key: String in sea_values():
		_live[key] = _sea.get_shader_parameter(key)
	_apply(_flags != null and bool(_flags.has(RESTORED_FLAG)))


## The restored state's sea values (colours as Color).
func sea_values() -> Dictionary:
	var out := {}
	var raw: Dictionary = _cfg.get("water", {})
	for key: String in raw:
		if not key.begins_with("_"):
			out[key] = Color(str(raw[key])) if raw[key] is String else raw[key]
	return out


func is_restored_look() -> bool:
	return _restored


func _process(delta: float) -> void:
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = POLL_SECONDS
	var restored: bool = _flags != null and bool(_flags.has(RESTORED_FLAG))
	if restored != _restored:
		_apply(restored)


func _apply(restored: bool) -> void:
	_restored = restored
	var values := sea_values()
	for key: String in values:
		_sea.set_shader_parameter(key, values[key] if restored else _live[key])
	if not bool(_cfg.get("clear_debris", true)) or not is_instance_valid(_markers):
		return
	# Drifting logs and weed mats are the debris of a choked channel; the
	# anchored buoys are the lane markers and stay.
	for drifter: Dictionary in _markers.get("_drifters"):
		var node: Variant = drifter.get("node")
		if node is Node3D and is_instance_valid(node) and not bool(drifter.get("anchored", false)):
			(node as Node3D).visible = not restored
