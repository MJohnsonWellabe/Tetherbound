extends SceneTree

## Scratch diagnostic (not committed as a test). Boots the same scene the
## warrens smoke test does, quietens the residents the same way, opens the
## branch the same way, then dumps every node whose global AABB overlaps the
## den->vault passage volume, to find out what is physically sitting there.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if warrens == null:
		print("no BurrowWarrens node")
		quit(1)
		return

	var game := root.get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null

	# Passage centre/box, den->vault, in LOCAL warrens space (from
	# burrow_warrens.json: den at (0,40) size(16,14), vault at (15,40) size(8,8)).
	# Computed the same way _build_passages() does.
	var den_edge := 0.0 + 16.0 * 0.5   # 8.0
	var vault_edge := 15.0 - 8.0 * 0.5  # 11.0
	var mid := (den_edge + vault_edge) * 0.5
	print("passage local x in [%.2f, %.2f], centred at x=%.2f, z=40" % [den_edge, vault_edge, mid])

	# Dump every relevant body BEFORE clearing.
	_dump_overlap(warrens, "BEFORE CLEAR")

	progression.call("set_flag", "warrens_cleared", false)
	warrens.call("grant_clear_reward")
	for i in 90:
		await physics_frame
	print("branch_is_open = %s" % warrens.call("branch_is_open"))
	_dump_overlap(warrens, "AFTER CLEAR")

	quit(0)


func _dump_overlap(warrens: Node3D, label: String) -> void:
	print("--- %s ---" % label)
	_walk(warrens, warrens)


func _walk(node: Node, warrens: Node3D) -> void:
	if node is Node3D:
		var n3: Node3D = node as Node3D
		var local: Vector3 = warrens.to_local(n3.global_position)
		# Passage box roughly x in [6,13], z in [36,44], generous margin.
		if local.x > 5.0 and local.x < 14.0 and local.z > 35.0 and local.z < 45.0:
			var extra := ""
			if node is CollisionShape3D:
				var shp: Shape3D = (node as CollisionShape3D).shape
				extra = " shape=%s disabled=%s" % [shp, (node as CollisionShape3D).disabled]
			print("  %s (%s) local=(%.2f,%.2f,%.2f) global=(%.2f,%.2f,%.2f)%s" % [
				node.get_path(), node.get_class(), local.x, local.y, local.z,
				n3.global_position.x, n3.global_position.y, n3.global_position.z, extra])
	for child in node.get_children():
		_walk(child, warrens)
