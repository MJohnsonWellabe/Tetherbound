extends SceneTree

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

func _init() -> void:
	var base_config := HEIGHTFIELD.load_config()
	var pts := [Vector2(57.86, 7410.54), Vector2(63.6, 7400.0), Vector2(58.0, 7411.0)]
	for hl in [40.0, 45.0, 53.0]:
		var config := base_config.duplicate(true)
		for entry: Variant in config["crossings"]:
			var d: Dictionary = entry as Dictionary
			if d.get("id", "") in ["sigil_gate_gorge_west", "sigil_gate_gorge_east"]:
				(d["carve"] as Dictionary)["half_length"] = hl
		var field: RefCounted = HEIGHTFIELD.new(config)
		for p in pts:
			var h: float = float(field.call("height_at", p.x, p.y))
			print("half_length %.1f at %v -> height_at = %.3f" % [hl, p, h])
	quit(0)
