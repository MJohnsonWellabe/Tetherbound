extends SceneTree

## `EV4-textures-lighting-remainder-3`: does `path_factor()` have real
## coverage gaps near route-convergence junctions, the mechanism
## `EV4-textures-lighting-remainder-2`'s own control-texture debug view
## narrowed the unmotivated dark patch to (grass-texture-ID cells punched
## into what should be solid path)? No scene load needed --
## `playground_heightfield.gd` is a pure `RefCounted` function of position.
##
##   godot --headless --path . --script tools/diag_path_factor_grid.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

## The two named viewpoints' near-camera ground, in world XZ. square-
## convergence: eye (2,-4), looking toward (10,-10) -- three routes meet
## here per the item's own text. the-rise-route: eye (27,-15), looking
## toward (45,-22).
const GRIDS := [
	{"name": "square-convergence", "x0": -2.0, "x1": 14.0, "z0": -16.0, "z1": -2.0},
	{"name": "the-rise-route", "x0": 20.0, "x1": 50.0, "z0": -28.0, "z1": -10.0},
]
const STEP := 0.5


func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	for entry: Variant in GRIDS:
		var g: Dictionary = entry
		print("--- %s (x:[%s,%s] z:[%s,%s]) ---" % [g["name"], g["x0"], g["x1"], g["z0"], g["z1"]])
		var x := float(g["x0"])
		while x <= float(g["x1"]):
			var line := "x=%6.1f  " % x
			var z := float(g["z0"])
			while z <= float(g["z1"]):
				var pf := float(field.call("path_factor", x, z))
				line += "%4.2f " % pf
				z += STEP
			print(line)
			x += STEP
	quit(0)
