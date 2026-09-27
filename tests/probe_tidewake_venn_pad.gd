extends SceneTree

## F14#1 evidence tool (no assertions, writes nothing): find an open fight pad
## for Officer Venn near his current spot on the Veilfall exterior spine. The
## code-blind C3 judge failed his fight because the fight camera sat against
## the cliff wall. COMBAT §5: a terrain footprint that cannot fit the fight is
## an arena/level defect: move the encounter to an authored pad.
##
## For each candidate within --search-m of the current spot (2 m grid), sample
## the real baked ground on rings out to the camera distance. It reports the
## flattest candidates: arena disc (11 m) within ±--flat-m of the centre, and
## no ground more than --wall-m above the centre inside the camera ring.
##   godot --headless --path . --script tests/probe_tidewake_venn_pad.gd [-- --search-m=70] [--trainer=<id>]
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const ARENA_M := 11.0
const CAMERA_M := 16.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var search := 70.0
	var flat := 1.6
	var wall := 3.0
	var trainer := "water_trainer_venn"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--search-m="): search = float(arg.trim_prefix("--search-m="))
		elif arg.begins_with("--flat-m="): flat = float(arg.trim_prefix("--flat-m="))
		elif arg.begins_with("--wall-m="): wall = float(arg.trim_prefix("--wall-m="))
		elif arg.begins_with("--trainer="): trainer = arg.trim_prefix("--trainer=")
	await process_frame
	root.get_node("Game").current_realm = "water"
	var world: Node3D = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 1800:
		await process_frame
		if world.shell_build_complete():
			break
	var director: Node = world.get_node("EncounterDirector")
	var spec: Dictionary = director.trainer_specs.get(trainer, {})
	var at: Array = spec.get("position", [])
	var centre := Vector2(float(at[0]), float(at[2]))
	print("VENN PAD current spot ", at, " score ", _score(world, centre, flat, wall))
	var results: Array = []
	var x := -search
	while x <= search:
		var z := -search
		while z <= search:
			var p := centre + Vector2(x, z)
			if Vector2(x, z).length() <= search:
				var s := _score(world, p, flat, wall)
				if bool(s.ok):
					s["at"] = [snappedf(p.x, 0.01), snappedf(p.y, 0.01)]
					s["moved_m"] = snappedf(Vector2(x, z).length(), 0.1)
					results.append(s)
			z += 2.0
		x += 2.0
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.moved_m) < float(b.moved_m))
	print("VENN PAD %d open candidates within %.0f m" % [results.size(), search])
	for row: Dictionary in results.slice(0, 15):
		print("VENN PAD ", JSON.stringify(row))
	quit()


func _score(world: Node3D, p: Vector2, flat: float, wall: float) -> Dictionary:
	var h0 := float(world.ground_height_at(p.x, p.y))
	if not is_finite(h0) or h0 < 0.5:
		return {"ok": false}
	var worst_flat := 0.0
	var worst_wall := -INF
	for ring: float in [3.0, 6.0, 9.0, ARENA_M, 13.5, CAMERA_M]:
		for i in 16:
			var a := TAU * float(i) / 16.0
			var q := p + Vector2(cos(a), sin(a)) * ring
			var h := float(world.ground_height_at(q.x, q.y))
			if not is_finite(h):
				return {"ok": false}
			if ring <= ARENA_M:
				worst_flat = maxf(worst_flat, absf(h - h0))
			worst_wall = maxf(worst_wall, h - h0)
	return {"ok": worst_flat <= flat and worst_wall <= wall, "h": snappedf(h0, 0.01),
		"arena_dev_m": snappedf(worst_flat, 0.01), "max_rise_m": snappedf(worst_wall, 0.01)}
