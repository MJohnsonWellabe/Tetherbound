extends SceneTree

## F14#0 C3 (Tidecoil): the reef-edge site sits at the foot of Deep Watch's
## 12 m sea cliff, so the fight camera behind the landward ally meets rock.
## Samples the shipped Water heightfield around the Deep Watch arrival
## landing and prints shallow-water stands (ground 0.3-1.4 m under the sea
## surface) whose 5 m ring stays shallow and whose landward side stays low
## for 18 m, i.e. the arm has open beach behind the ally. Read-only.
##   godot --headless --path . --script tools/probe_tidewake_tidecoil_stand.gd

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const LANDING := Vector2(1260.0, 3403.0)
const SEARCH_R := 70.0
const STEP := 2.0
const RING := 5.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	var world: Node3D = WORLD.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 1500:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	var rows: Array = []
	var x := -SEARCH_R
	while x <= SEARCH_R:
		var z := -SEARCH_R
		while z <= SEARCH_R:
			var c := LANDING + Vector2(x, z)
			var h0 := float(world.call("ground_height_at", c.x, c.y))
			if h0 > -0.3 or h0 < -1.4:
				z += STEP
				continue
			var lo := h0
			var hi := h0
			for k in 16:
				var a := TAU * float(k) / 16.0
				var h := float(world.call("ground_height_at", c.x + cos(a) * RING, c.y + sin(a) * RING))
				lo = minf(lo, h)
				hi = maxf(hi, h)
			# Landward: toward the landing; the camera sits behind an ally on that side.
			var inland := (LANDING - c).normalized()
			var back_hi := -INF
			for d: float in [6.0, 10.0, 14.0, 18.0]:
				var p: Vector2 = c + inland * d
				back_hi = maxf(back_hi, float(world.call("ground_height_at", p.x, p.y)))
			rows.append({"at": c, "h": h0, "lo": lo, "hi": hi, "back_hi": back_hi,
				"from_landing": c.distance_to(LANDING)})
			z += STEP
		x += STEP
	rows = rows.filter(func(r: Dictionary) -> bool:
		return float(r.lo) > -2.2 and float(r.back_hi) < 4.0 and float(r.from_landing) > 18.0)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.hi) - float(a.lo) + float(a.back_hi) * 0.2 < float(b.hi) - float(b.lo) + float(b.back_hi) * 0.2)
	print("candidates=%d" % rows.size())
	for row: Dictionary in rows.slice(0, 30):
		print("STAND at=(%.1f, %.1f) h=%.2f ring=[%.2f,%.2f] back_hi=%.2f from_landing=%.1f" % [
			row.at.x, row.at.y, row.h, row.lo, row.hi, row.back_hi, row.from_landing])
	quit(0)
