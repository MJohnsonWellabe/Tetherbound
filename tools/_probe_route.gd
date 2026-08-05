extends SceneTree

const SCENE := "res://scenes/world/meadows_playground.tscn"
const POINTS := [
	Vector2(72, 124), Vector2(72, 128), Vector2(72, 132), Vector2(72, 134), Vector2(72, 136), Vector2(74, 124), Vector2(74, 128), Vector2(74, 132), Vector2(74, 134), Vector2(74, 136), Vector2(76, 124), Vector2(76, 128), Vector2(76, 132), Vector2(76, 134), Vector2(76, 136), Vector2(78, 124), Vector2(78, 128), Vector2(78, 132), Vector2(78, 134), Vector2(78, 136), Vector2(80, 124), Vector2(80, 128), Vector2(80, 132), Vector2(80, 134), Vector2(80, 136), Vector2(82, 124), Vector2(82, 128), Vector2(82, 132), Vector2(82, 134), Vector2(82, 136),
]

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame
	for p: Vector2 in POINTS:
		var h: float = float(world.call("ground_height_at", p.x, p.y))
		var step := 2.0
		var e: float = float(world.call("ground_height_at", p.x + step, p.y))
		var n: float = float(world.call("ground_height_at", p.x, p.y + step))
		var slope := rad_to_deg(atan2(Vector2(e - h, n - h).length(), step))
		print("(%6.1f,%6.1f)  y=%8.2f  slope=%5.1f deg" % [p.x, p.y, h, slope])
	quit(0)
