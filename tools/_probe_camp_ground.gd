extends SceneTree
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
func _init() -> void:
	var f: RefCounted = HEIGHTFIELD.new()
	for p in [Vector2(348,919), Vector2(345,917), Vector2(351,921), Vector2(343.5,923.5),
			Vector2(331.5,911.5), Vector2(356,907), Vector2(361,908), Vector2(343,913),
			Vector2(338,908), Vector2(352,930)]:
		print("(%.1f, %.1f) h=%.2f" % [p.x, p.y, f.height_at(p.x, p.y)])
	quit(0)
