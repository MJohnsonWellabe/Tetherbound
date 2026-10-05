extends OmniLight3D

## F01#3 (reproof row3 night walk, code-blind judge): dark-clothed villagers
## standing against dark walls or trees -- Tam by the forge's stone, Maren under
## the trees -- lost their silhouette and face at 23:00 under Compatibility.
## A soft, unflickering, night-only fill parented to the villager, the same
## shape `camp_fill_light.gd` gives an unlit camp: no light by day, a short
## range so it lifts the person rather than the wall behind them, no shadows.
##
## Opted into per villager from `data/config/village_npcs.json`
## (`night_light: true` takes `night_light_default`; a dictionary overrides any
## of its fields). Every number is a tunable there.

var _world_look: Node = null
var _night_energy := 0.0


## The light for `spec`, or null when the villager did not opt in or the
## configured energy is zero. `defaults` is `night_light_default`.
static func settings_for(spec: Dictionary, defaults: Dictionary) -> Dictionary:
	var raw: Variant = spec.get("night_light", false)
	if raw is bool and raw == false:
		return {}
	var out := defaults.duplicate(true)
	if raw is Dictionary:
		for key: Variant in raw:
			if not str(key).begins_with("_"):
				out[key] = raw[key]
	if float(out.get("energy", 0.0)) <= 0.0:
		return {}
	return out


static func attach(npc: Node3D, settings: Dictionary) -> OmniLight3D:
	if npc == null or settings.is_empty():
		return null
	var light := load("res://scripts/world/villager_night_light.gd").new() as OmniLight3D
	light.name = "VillagerNightLight"
	var offset: Variant = settings.get("offset", [0.0, 1.5, 0.8])
	if offset is Array and (offset as Array).size() == 3:
		light.position = Vector3(float(offset[0]), float(offset[1]), float(offset[2]))
	light.light_color = Color(str(settings.get("colour", "#c9d6ee")))
	light.omni_range = float(settings.get("range", 2.2))
	light.omni_attenuation = float(settings.get("attenuation", 1.4))
	light.shadow_enabled = false
	light.set("_night_energy", float(settings.get("energy", 0.0)))
	light.light_energy = 0.0
	npc.add_child(light)
	return light


func _process(_delta: float) -> void:
	if _world_look == null or not is_instance_valid(_world_look):
		_world_look = get_tree().get_first_node_in_group(&"day_cycle")
	var dark := _world_look != null and _world_look.has_method("is_dark") \
		and bool(_world_look.call("is_dark"))
	light_energy = _night_energy if dark else 0.0
