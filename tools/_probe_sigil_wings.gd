extends SceneTree

## Why does the LOCKED Sigil Gate leak at exactly +6.0m off centre, north->south,
## and nowhere else?
##
## `smoke_traversal.gd`'s barrier-span check measures the colliders projected
## onto the causeway's ACROSS axis only. It is blind to Y. Each wing takes its
## own ground height (`road_gate.gd::_build_wings`), so a wing sitting on lower
## ground has a lower top -- and a player arriving from higher ground walks over
## it while the across-axis span still reads contiguous.
##
## This prints the numbers that confirm or kill that: terrain height across the
## causeway, every wing's world-Y bottom and top, and the two +6.0m start points
## the test actually uses.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const START_BACK := 12.0

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var gate: Node3D = world.get_node_or_null(^"SigilGate") as Node3D
	if gate == null:
		print("no SigilGate")
		quit(1)
		return

	var gate_xz := Vector2(gate.global_position.x, gate.global_position.z)
	var across := Vector2(gate.global_transform.basis.x.x, gate.global_transform.basis.x.z).normalized()
	var along := Vector2(-across.y, across.x)
	if along.y < 0.0:
		along = -along
	var gate_ground: float = float(world.call("ground_height_at", gate_xz.x, gate_xz.y))
	print("gate at (%.1f, %.1f)  y=%.2f  ground=%.2f" % [gate_xz.x, gate_xz.y, gate.global_position.y, gate_ground])
	print("across=(%.3f,%.3f)  along=(%.3f,%.3f)" % [across.x, across.y, along.x, along.y])

	print("=== colliders the gate owns (offset span, world y bottom..top) ===")
	for child in gate.get_children():
		if not (child is StaticBody3D):
			continue
		var sb := child as StaticBody3D
		for sub in sb.get_children():
			var cs := sub as CollisionShape3D
			if cs == null:
				continue
			var cb := cs.shape as BoxShape3D
			if cb == null:
				continue
			var cx: float = sb.position.x + cs.position.x
			var cy: float = gate.global_position.y + sb.position.y + cs.position.y
			var at: Vector2 = gate_xz + across * cx
			var g: float = float(world.call("ground_height_at", at.x, at.y))
			print("  %-26s offset %+7.2f (%+7.2f..%+7.2f)  y %.2f..%.2f  ground under centre %s  disabled=%s" % [
				sb.name, cx, cx - cb.size.x * 0.5, cx + cb.size.x * 0.5,
				cy - cb.size.y * 0.5, cy + cb.size.y * 0.5,
				("NaN" if is_nan(g) else "%.2f" % g), str(cs.disabled)])

	print("=== terrain across the causeway (offset -22..22) ===")
	var o := -22.0
	while o <= 22.001:
		var at: Vector2 = gate_xz + across * o
		var g: float = float(world.call("ground_height_at", at.x, at.y))
		print("  offset %+7.2f  ground %s" % [o, ("NaN" if is_nan(g) else "%.2f" % g)])
		o += 1.0

	print("=== the walk start points the test uses at +/-6.0m ===")
	for offset: float in [6.0, -6.0]:
		for forward: bool in [true, false]:
			var travel: Vector2 = along if forward else -along
			var s: Vector2 = gate_xz + across * offset - travel * START_BACK
			var g: float = float(world.call("ground_height_at", s.x, s.y))
			print("  offset %+5.1f  %s: start (%.1f,%.1f) ground %s  player spawns at y %s" % [
				offset, ("south->north" if forward else "north->south"), s.x, s.y,
				("NaN" if is_nan(g) else "%.2f" % g),
				("NaN" if is_nan(g) else "%.2f" % (g + 1.0))])
	quit(0)
