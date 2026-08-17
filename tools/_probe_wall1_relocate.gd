extends SceneTree

## WALL1 fix candidate check: spawns.json's galecrest centre [55,-120] r12
## resolves (with the file's seeded rng, "wild_spawn_%d") to home
## (54.30, -124.15) -- only 3.15m from Captain Halder's hand-placed position
## at trainers.json [52.0, -122.0]. That is inside his own 0.36m capsule
## radius plus a creature/player capsule's own radius with no room to spare,
## and is the entire, sole cause of the CI-AGGRESSION / verify-aggression
## flake (see ralph/NOTES.md and tools/_probe_wedge_seam*.gd).
##
## Checks whether shifting the spawn centre west clears Halder by a safe
## margin AND keeps landing on walkable, gentle ground -- measured, not
## guessed, the same way trainers.json's own placement comments measure
## their sites.
##
##   godot --headless --path . --script tools/_probe_wall1_relocate.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const HALDER := Vector2(52.0, -122.0)
const BURROWBACK_CENTRE := Vector2(55.0, -145.0)
const BURROWBACK_RADIUS := 10.0

## Candidate new centres for the galecrest spawn, each paired with the
## resulting home if the same seeded rng draw applies (offset from the OLD
## centre carries over unchanged -- angle/distance are a function of the rng
## seed and draw order only, not of centre).
const OLD_CENTRE := Vector2(55.0, -120.0)
const HOME_OFFSET := Vector2(-0.6974, -4.1532)  # measured live home minus old centre

const CANDIDATES := [
	Vector2(40.0, -120.0),
	Vector2(35.0, -115.0),
	Vector2(38.0, -108.0),
]


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame

	var field := HEIGHTFIELD.new()

	for centre: Vector2 in CANDIDATES:
		var home := centre + HOME_OFFSET
		var dist_halder := home.distance_to(HALDER)
		var dist_burrowback := home.distance_to(BURROWBACK_CENTRE) - BURROWBACK_RADIUS
		print("")
		print("--- candidate centre=%s -> predicted home=%s ---" % [centre, home])
		print("  clearance from Halder: %.2fm" % dist_halder)
		print("  clearance from Burrowback's own radius: %.2fm" % dist_burrowback)

		# Slope sampled the way every other placement comment in this repo
		# measures it: central difference at 0.5m spacing, worst of a small
		# ring around the point rather than just the centre itself.
		var worst_slope := 0.0
		var pts := [Vector2.ZERO, Vector2(3, 0), Vector2(-3, 0), Vector2(0, 3), Vector2(0, -3)]
		for p: Vector2 in pts:
			var x: float = home.x + p.x
			var z: float = home.y + p.y
			var h_x0: float = float(field.call("height_at", x - 0.5, z))
			var h_x1: float = float(field.call("height_at", x + 0.5, z))
			var h_z0: float = float(field.call("height_at", x, z - 0.5))
			var h_z1: float = float(field.call("height_at", x, z + 0.5))
			var dx := (h_x1 - h_x0) / 1.0
			var dz := (h_z1 - h_z0) / 1.0
			var normal := Vector3(-dx, 1.0, -dz).normalized()
			var slope_deg := rad_to_deg(normal.angle_to(Vector3.UP))
			worst_slope = maxf(worst_slope, slope_deg)
		print("  worst slope over a 3m ring around home: %.1f deg" % worst_slope)

	quit(0)
