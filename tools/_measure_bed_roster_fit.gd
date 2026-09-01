extends SceneTree

## BACKLOG-VISUAL-BED-ROSTER-FIT diagnostic. For every species in
## data/creatures/species.json, spawns a CreatureBody exactly the way
## creature_bed.gd::_sync_rest_body() does (REST_ANCHOR position,
## rotation.y = PI * 0.5, play_rest()), measures its render-space AABB via
## render_bounds.gd (same method tools/_diag_rest_roll_math.gd already uses
## and the FOLLOWUP-2026-09-01.md report trusted), and checks every corner of
## that box against the bed's rim ellipse instead of just comparing bounding
## rectangles -- a long diagonal creature can pass an x/z-extent check while
## still poking a corner past a genuinely elliptical rim.
##
## Headless-safe: no GPU render, geometry queries only (RenderBounds reads
## bind-pose mesh data through the skeleton chain, not animated bone poses --
## the same trusted method the prior session's diagnostic used).
##
##   godot --headless --path . --script tools/_measure_bed_roster_fit.gd -- [rim_x] [rim_z]

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var rim_x := float(args[0]) if args.size() > 0 else CREATURE_BED.RIM_RADIUS_X
	var rim_z := float(args[1]) if args.size() > 1 else CREATURE_BED.RIM_RADIUS_Z
	var force_pose := args[2] if args.size() > 2 else ""

	var species_ids: Array = SPECIES.table().keys() if args.size() <= 3 or args[3] == "" \
		else Array(String(args[3]).split(","))
	species_ids.sort()

	print("rim: RIM_RADIUS_X=%.3f RIM_RADIUS_Z=%.3f (ellipse %.2fm x %.2fm)"
		% [rim_x, rim_z, rim_x * 2.0, rim_z * 2.0])
	print("%-14s %8s %8s %8s %8s %8s %8s %8s" % [
		"species", "height", "roll", "aabb_x", "aabb_y", "aabb_z",
		"max_r/rim", "fit"])

	var worst_ratio := 0.0
	var worst_species := ""
	for species_id in species_ids:
		var body := CREATURE_SCENE.instantiate() as Node3D
		body.set_script(CREATURE_BODY)
		root.add_child(body)
		body.call("setup", species_id, false)
		await process_frame

		if force_pose.begins_with("roll:"):
			SPECIES.placeholder(species_id)["rest_roll_deg"] = float(force_pose.substr(5))
		var roll := float(SPECIES.placeholder(species_id).get("rest_roll_deg", 90.0))
		if force_pose == "faint":
			roll = 0.0

		body.position = CREATURE_BED.REST_ANCHOR
		body.rotation.y = PI * 0.5
		if force_pose == "faint":
			body.call("play_faint")
		else:
			body.call("play_rest")
		await process_frame
		await process_frame

		# Body-local AABB (post play_rest, which already rotated/repositioned
		# the model inside the body node) -- matches _diag_rest_roll_math.gd's
		# "body-space (self) AABB ... AFTER play_rest" measurement.
		var box: AABB = RENDER_BOUNDS.measure(body)

		var height: float = float(SPECIES.placeholder(species_id).get("height", 0.0))
		var fits := true
		var max_ratio := 0.0
		for corner_i in 8:
			var local_corner := box.position + Vector3(
				box.size.x * float(corner_i & 1),
				box.size.y * float((corner_i >> 1) & 1),
				box.size.z * float((corner_i >> 2) & 1))
			# body.rotation.y = PI/2 about the node's own origin (REST_ANCHOR is
			# a local offset applied via body.position, not a further pivot), so
			# world-space X/Z swap+negate from body-local X/Z. The ellipse test
			# only cares about magnitude, so square either way -- but do it
			# through the real rotation to stay honest about which axis is
			# which if that ever changes.
			var world_offset := Basis(Vector3.UP, PI * 0.5) * Vector3(local_corner.x, 0.0, local_corner.z)
			var wx := world_offset.x
			var wz := world_offset.z
			var ratio := sqrt(pow(wx / rim_x, 2.0) + pow(wz / rim_z, 2.0))
			max_ratio = maxf(max_ratio, ratio)
			if ratio > 1.0:
				fits = false

		print("%-14s %8.2f %8.1f %8.2f %8.2f %8.2f %8.2f %8s" % [
			species_id, height, roll, box.size.x, box.size.y, box.size.z,
			max_ratio, "OK" if fits else "OVERFLOW"])

		if max_ratio > worst_ratio:
			worst_ratio = max_ratio
			worst_species = species_id

		body.queue_free()
		await process_frame

	print("")
	print("worst: %s at %.2fx rim radius" % [worst_species, worst_ratio])
	quit(0)
