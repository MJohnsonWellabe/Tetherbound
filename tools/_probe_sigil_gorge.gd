extends SceneTree
## GATE-D5 REQUEST 2. Does the Sigil gate's new flanking gorge stop a player
## walking around it, WITHOUT severing the only road to the finale?
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const GATE := Vector2(63.6, 7400.0)

func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new(HEIGHTFIELD.load_config())
	# Trench axis, from +x, matching _prepare_carve's Vector2.RIGHT.rotated().
	var u := Vector2.RIGHT.rotated(deg_to_rad(28.6))
	print("along the trench axis (0 = the gate, +/- = out along the flanks):")
	print("  %8s %10s %10s" % ["offset_m", "height", "vs gate"])
	var gate_h: float = field.height_at(GATE.x, GATE.y)
	var worst := 0.0
	var causeway := 0.0
	for off in [-140, -120, -100, -80, -61, -40, -25, -14, -7, 0, 7, 14, 25, 40, 61, 80, 100, 120, 140]:
		var p := GATE + u * float(off)
		var h: float = field.height_at(p.x, p.y)
		var drop: float = gate_h - h
		if absf(float(off)) <= 7.0:
			causeway = maxf(causeway, drop)
		else:
			worst = maxf(worst, drop)
		print("  %8d %10.2f %10.2f" % [off, h, drop])
	print("")
	print("causeway drop within +/-7m of the gate: %.2f m  (must stay near 0 -- the road passes here)" % causeway)
	print("deepest drop out on the flanks:         %.2f m  (must be deep enough to refuse a detour)" % worst)
	quit(0)
