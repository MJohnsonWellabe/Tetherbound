extends SceneTree

## Where is the South Bridge gully failsafe, and where is the gully?
const SCENE := "res://scenes/world/meadows_playground.tscn"

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for _i in 240:
		await physics_frame
	for node in root.find_children("*", "Area3D", true, false):
		var area := node as Area3D
		if area == null or not str(area.name).begins_with("CarveFailsafe"):
			continue
		var owner_name := str(area.get_parent().get_parent().name) if area.get_parent() != null and area.get_parent().get_parent() != null else "?"
		var to: Vector3 = area.get_meta("recover_to", Vector3.ZERO)
		var shape := area.get_child(0) as CollisionShape3D
		var box := shape.shape as BoxShape3D if shape != null else null
		print("%-22s local=(%.1f, %.1f, %.1f)  GLOBAL=(%.1f, %.1f, %.1f)  size=%s  recover_to=(%.1f, %.1f, %.1f)" % [
			owner_name,
			area.position.x, area.position.y, area.position.z,
			area.global_position.x, area.global_position.y, area.global_position.z,
			str(box.size) if box != null else "?",
			to.x, to.y, to.z])
	quit(0)
