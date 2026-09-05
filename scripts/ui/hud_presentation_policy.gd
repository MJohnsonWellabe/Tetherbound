extends RefCounted

## Presentation only; never changes input permissions, combat or progression.
static func resolve(world_mode: String, combat_active: bool, modal: bool, moment: bool) -> Dictionary:
	var mode := "modal" if modal else ("relays" if world_mode == "relays" else ("combat" if combat_active or world_mode == "combat" else "exploration"))
	return {"mode": mode, "exploration": mode == "exploration", "combat": mode == "combat",
		"party": mode in ["exploration", "relays", "modal"], "task": mode in ["exploration", "modal"] and not moment,
		"location": mode in ["exploration", "modal"] and not moment, "hotbar": mode == "exploration",
		"instruction": mode == "relays" and not moment, "prompt": mode in ["exploration", "relays"],
		"human_vitals": mode == "exploration", "minimap": mode in ["exploration", "modal"] and not moment}
