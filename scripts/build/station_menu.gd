extends Node3D

## Altar's overview/upgrade menu on the unchanged paid BUILD_PIECE root.
## The existing Training consumer retains its own training transaction/UI.
const PROMPT := preload("res://scripts/world/interactable.gd")
const PANEL := preload("res://scripts/ui/craft_panel.gd")
const RULES := preload("res://scripts/build/station_rules.gd")
var _building: Node3D
var _panel: CanvasLayer
var _prompt: Node3D

func mount(building: Node3D) -> void:
	_building=building
	var cfg := RULES.config()
	if cfg.get("runtime_enabled") != true: return
	_prompt=PROMPT.new()
	_prompt.position=Vector3(-0.65,0.9,0)
	_prompt.call("configure","Altar upgrades and Charms",float(cfg.interaction_radius_m),true)
	_prompt.connect("activated",_open)
	add_child(_prompt)

func interaction_origin() -> Vector3:
	return _prompt.global_position if is_instance_valid(_prompt) else global_position

func _open() -> void:
	if not is_instance_valid(_building): return
	if not is_instance_valid(_panel):
		_panel=PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open_station",_building)

func _exit_tree() -> void:
	if is_instance_valid(_panel): _panel.queue_free()
