extends "res://tests/smoke_combat_camera.gd"

## F21#4 size matrix staged on prop-free ground. The smoke stages each pair
## where the encounter happened to be entered; the code-blind judge found the
## foe standing on/behind boulders there (the camera itself passed). Before
## the smoke's own `_capture_size_matrix()` reads the staging transform, this
## moves ally, foe and trainer by one shared offset to the nearest ground in
## the same encounter with no solid scatter near either actor or the space the
## camera looks across (`vegetation.gd::has_solid_scatter_near`), and a flat
## floor. DISCLOSED fixture move (proof rules v2); the matrix, its framing
## checks and the production rig are the smoke's, unchanged.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-method gl_compatibility \
##     --rendering-driver opengl3 --resolution 1920x1080 --script res://tools/capture_f21_matrix_clear.gd \
##     -- --matrix-dir=<fresh abs dir> --source-commit=<sha> --matrix-preset=Low

const CLEAR_RINGS_M := [0.0, 6.0, 12.0, 18.0, 24.0, 32.0, 40.0, 50.0]
const CLEAR_ANGLES := 16
## Clearance kept around each actor spot and the pair's midpoint.
const ACTOR_CLEAR_M := 4.0
const VIEW_CLEAR_M := 9.0
## Foe offset the smoke uses for the widest (giant/giant) pair, rounded up.
const PAIR_SPAN_M := 7.0
const MAX_STEP_M := 0.8


func _capture_size_matrix() -> void:
	var wants := false
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--matrix-dir="):
			wants = true
	if wants:
		await _move_to_clear_ground()
	await super._capture_size_matrix()


func _move_to_clear_ground() -> void:
	var vegetation := _world.get_node_or_null(^"Vegetation")
	if vegetation == null:
		print("CLEAR STAGE: no Vegetation node; staging left where the encounter was entered")
		return
	var origin := _ally.global_position
	for radius: float in CLEAR_RINGS_M:
		var steps := 1 if radius == 0.0 else CLEAR_ANGLES
		for k in steps:
			var a := TAU * float(k) / float(steps)
			var spot := origin + Vector3(sin(a), 0.0, cos(a)) * radius
			var foe_spot := spot + Vector3(PAIR_SPAN_M, 0.0, 0.0)
			var mid := (spot + foe_spot) * 0.5
			if bool(vegetation.call("has_solid_scatter_near", spot, ACTOR_CLEAR_M)) \
					or bool(vegetation.call("has_solid_scatter_near", foe_spot, ACTOR_CLEAR_M)) \
					or bool(vegetation.call("has_solid_scatter_near", mid, VIEW_CLEAR_M)):
				continue
			# Placed props (boulders, crates, fences) are not vegetation
			# scatter: probe the ground itself for anything standing on it.
			if _cluttered(mid, VIEW_CLEAR_M):
				continue
			var y0 := float(_world.call("ground_height_at", spot.x, spot.z))
			var y1 := float(_world.call("ground_height_at", foe_spot.x, foe_spot.z))
			if absf(y1 - y0) > MAX_STEP_M:
				continue
			var delta := Vector3(spot.x - origin.x, 0.0, spot.z - origin.z)
			for body: Node3D in [_ally, _wild, _player]:
				var p := body.global_position + delta
				p.y = float(_world.call("ground_height_at", p.x, p.z)) + (1.0 if body == _player else 0.05)
				body.global_position = p
				if body is CharacterBody3D:
					(body as CharacterBody3D).velocity = Vector3.ZERO
			print("CLEAR STAGE (disclosed fixture move): ally/foe/trainer moved %.1f m to %s; no solid scatter within %.1f m of either actor, and no collider standing above the terrain within %.1f m of the pair midpoint" % [
				delta.length(), str(spot), ACTOR_CLEAR_M, VIEW_CLEAR_M])
			for i in 30:
				await physics_frame
			return
	print("CLEAR STAGE: no clear ground within %.0f m; staging left where the encounter was entered" % CLEAR_RINGS_M.back())


## True when any collider other than the terrain stands more than CLUTTER_M
## above the terrain height on a 1 m grid within `half` of `centre`.
const CLUTTER_M := 0.35

func _cluttered(centre: Vector3, half: float) -> bool:
	var space := _player.get_world_3d().direct_space_state
	var skip: Array[RID] = []
	for body: Node in [_ally, _wild, _player]:
		if body is CollisionObject3D:
			skip.append((body as CollisionObject3D).get_rid())
	var steps := int(half)
	for ix in range(-steps, steps + 1):
		for iz in range(-steps, steps + 1):
			var x := centre.x + float(ix)
			var z := centre.z + float(iz)
			var ground := float(_world.call("ground_height_at", x, z))
			var query := PhysicsRayQueryParameters3D.create(Vector3(x, ground + 20.0, z), Vector3(x, ground - 2.0, z))
			query.exclude = skip
			var hit := space.intersect_ray(query)
			if not hit.is_empty() and (hit.position as Vector3).y > ground + CLUTTER_M:
				return true
	return false
