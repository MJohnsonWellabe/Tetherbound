extends SceneTree

const SCENE := "res://scenes/world/meadows_playground.tscn"

func _init() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 60:
		await physics_frame
	var along := Vector2(-0.478692, 0.877983)
	var gate := Vector2(63.6, 7400.0)
	for dv in [0.0, 12.0, 20.0, 40.0, 60.0, 80.0, 100.0, 150.0, 200.0, 300.0, 500.0, 1000.0, 2000.0, 4000.0, 6466.6]:
		var d: float = dv
		var p: Vector2 = gate + along * d
		var h: float = float(world.call("ground_height_at", p.x, p.y))
		print("d=%.1f -> (%.1f,%.1f) ground_h=%s" % [d, p.x, p.y, str(h)])
	quit(0)
