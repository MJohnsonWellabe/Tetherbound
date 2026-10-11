extends "res://tests/smoke_move_effects_library.gd"

## F35#3 capture on a slow host: four ultimates fired on one frame, beats timed
## by GAME frames instead of wall clock. The smoke's own four-at-once case ends
## on wall time, so under llvmpipe (~1 s/frame) it drew 3 frames and no effect
## reached contact. Run this with --fixed-fps so each rendered frame advances a
## fixed game step; the presentation then plays out in full, only slower in
## real time (disclosed slow-host budget scaling, proof rules v2). Assertions
## and launch path are the smoke's; only the clock the beats read changes.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-method gl_compatibility \
##     --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
##     --script res://tools/capture_f35_four_contact.gd -- --batch=ultimates \
##     --simultaneous=ultimate_terrapup,ultimate_ripplet,ultimate_galewisp,ultimate_veridian --out=<fresh dir>

func _exercise_simultaneous(cfg: Dictionary) -> void:
	var lanes := [-4.5, -1.5, 1.5, 4.5]
	var origins: Array[Vector3] = []
	var bodies: Array[Node3D] = []
	for i in _simultaneous.size():
		var move_id := str(_simultaneous[i])
		if not _moves.has(move_id): _failures.append("Simultaneous ultimate without move " + move_id); return
		var case := {"id": move_id}
		var species := move_id.trim_prefix("ultimate_")
		if bool(_moves[move_id].get("ultimate", {}).get("unique", false)) and _species_has_model(species):
			case["attacker_species"] = species
		var from := _attacker_origin(case, move_id, float(lanes[i % lanes.size()]))
		if not from.is_finite(): _failures.append("Attacker model missing " + move_id); return
		origins.append(from)
		bodies.append(_current_attacker)
	for body: Node3D in bodies: body.visible = true
	var camera := get_root().get_viewport().get_camera_3d()
	if camera != null:
		var centre := _arena.to_global(Vector3((float(_scenarios.get("stage", {}).get("attacker_x", -3.4)) + _target_x) * 0.5, 1.6, 0.0))
		camera.global_position = centre + _arena.global_basis * Vector3(-13.0, 8.0, 5.0)
		camera.look_at(centre, Vector3.UP)
	var to := _target.global_position + Vector3.UP * float(_target.call("body_height")) * 0.5
	var duration := 0.0
	var arrivals := [0]
	var arrived_at := [-1.0]
	var travel := minf(float(cfg.travel_seconds), 1.2)
	for i in _simultaneous.size():
		var move_id := str(_simultaneous[i])
		var move: Dictionary = _moves[move_id]
		var signature: Dictionary = move.get("ultimate", {})
		duration = maxf(duration, float(signature.get("presentation_seconds", 2.4)))
		var binding := {"character_id": "f35-four-%d" % i, "creature_uid": "f35-four-%d-attacker" % i,
			"encounter_id": "f35-four", "generation": 1, "action": i + 1}
		var spec := {"slot": "ultimate", "move_id": move_id, "action_id": "f35-four:%d" % (i + 1),
			"actor_binding": binding, "mastery_rank": 1, "breakthrough_count": 0,
			"ultimate": signature.duplicate(true), "vfx": move.get("vfx", {}).duplicate(true)}
		var context := {"current_actor": binding, "travel_seconds": travel,
			"recipient_character_id": "f35-four-%d" % i, "source_ground": _ground_point(_arena.to_local(origins[i]).x, float(lanes[i % lanes.size()])),
			"target_ground": _ground_point(_target_x, 0.0)}
		var effect: Node3D = ULTIMATES.launch(_arena, origins[i], to, spec, context)
		if effect == null: _failures.append("Simultaneous launch refused " + move_id); continue
		effect.connect("arrived", func() -> void: arrivals[0] += 1)
		if bodies[i].has_method("play_attack"): bodies[i].call("play_attack")
	# Game-time beats: travel midpoint, contact (+0.1 s after travel), peak and late.
	var beats := {"travel": travel * 0.5, "contact": travel + 0.1, "peak": travel + 0.45, "late": duration - 0.3}
	var captured := {}
	var elapsed := 0.0
	var frames := 0
	while elapsed < duration + 0.4:
		await process_frame
		elapsed += get_root().get_process_delta_time()
		frames += 1
		await RenderingServer.frame_post_draw
		for beat: String in beats:
			if captured.has(beat) or elapsed < float(beats[beat]): continue
			var path := _out.path_join("four-ultimates-%s.png" % beat)
			if root.get_texture().get_image().save_png(path) != OK: _failures.append("Capture failed " + path)
			captured[beat] = {"game_seconds": elapsed, "arrivals": arrivals[0]}
			print("F35 four beat %s at game %.2fs arrivals=%d" % [beat, elapsed, arrivals[0]])
	if captured.size() != beats.size(): _failures.append("Incomplete four-ultimate frames")
	if int(arrivals[0]) != _simultaneous.size(): _failures.append("Four-ultimate arrivals %d" % arrivals[0])
	_records.append({"id": "four_simultaneous_game_clock", "moves": _simultaneous, "presentation_seconds": duration,
		"captures": captured, "arrivals": arrivals[0], "frames": frames, "clock": "game (--fixed-fps)"})
	print("F35 four simultaneous (game clock) frames=%d arrivals=%d" % [frames, arrivals[0]])
